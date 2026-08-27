type SourceName = 'mora' | 'radio_pakistan';

type FeedRecord = {
  hijriYear: number;
  hijriMonth: number;
  startsOn: string;
  announcedAt: string;
  authorityName: string;
  sourceUrl: string;
  countryCode: string;
  status: string;
};

const requiredAuthority = 'Central Ruet-e-Hilal Committee Pakistan';
const sourceHosts: Record<SourceName, readonly string[]> = {
  mora: ['mora.gov.pk', 'www.mora.gov.pk'],
  radio_pakistan: ['radio.gov.pk', 'www.radio.gov.pk', 'new.radio.gov.pk'],
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}

function readRecord(value: unknown, source: SourceName): FeedRecord {
  const raw = (value as { data?: unknown }).data ?? value;
  if (raw === null || typeof raw !== 'object') throw new Error(`${source} feed record is missing.`);
  const item = raw as Record<string, unknown>;
  const record: FeedRecord = {
    hijriYear: Number(item.hijriYear),
    hijriMonth: Number(item.hijriMonth),
    startsOn: String(item.startsOn ?? ''),
    announcedAt: String(item.announcedAt ?? ''),
    authorityName: String(item.authorityName ?? ''),
    sourceUrl: String(item.sourceUrl ?? ''),
    countryCode: String(item.countryCode ?? ''),
    status: String(item.status ?? ''),
  };
  const parsedUrl = URL.canParse(record.sourceUrl) ? new URL(record.sourceUrl) : undefined;
  if (!Number.isInteger(record.hijriYear) || !Number.isInteger(record.hijriMonth) ||
      record.hijriMonth < 1 || record.hijriMonth > 12 ||
      !/^\d{4}-\d{2}-\d{2}$/.test(record.startsOn) ||
      Number.isNaN(Date.parse(record.announcedAt)) ||
      record.authorityName !== requiredAuthority || record.countryCode !== 'PK' ||
      record.status !== 'confirmed' || !parsedUrl || parsedUrl.protocol !== 'https:' ||
      !sourceHosts[source].includes(parsedUrl.hostname.toLowerCase())) {
    throw new Error(`${source} feed record did not pass the official confirmation checks.`);
  }
  return record;
}

async function fetchRecord(url: string, source: SourceName): Promise<FeedRecord> {
  const response = await fetch(url, {
    headers: { Accept: 'application/json' },
    signal: AbortSignal.timeout(10_000),
  });
  if (!response.ok) throw new Error(`${source} feed returned ${response.status}.`);
  return readRecord(await response.json(), source);
}

async function requestRecords(request: Request): Promise<{ mora: FeedRecord; radio: FeedRecord }> {
  const body = await request.json().catch(() => ({})) as Record<string, unknown>;
  if (body.mora !== undefined || body.radio !== undefined) {
    return {
      mora: readRecord(body.mora, 'mora'),
      radio: readRecord(body.radio, 'radio_pakistan'),
    };
  }
  const moraFeedUrl = Deno.env.get('RUET_E_HILAL_MORA_FEED_URL');
  const radioFeedUrl = Deno.env.get('RUET_E_HILAL_RADIO_PAKISTAN_FEED_URL');
  if (!moraFeedUrl || !radioFeedUrl) {
    throw new Error('No verified ingestion payload or feed configuration is available.');
  }
  const [mora, radio] = await Promise.all([
    fetchRecord(moraFeedUrl, 'mora'),
    fetchRecord(radioFeedUrl, 'radio_pakistan'),
  ]);
  return { mora, radio };
}

function matches(primary: FeedRecord, secondary: FeedRecord) {
  return primary.hijriYear === secondary.hijriYear &&
    primary.hijriMonth === secondary.hijriMonth &&
    primary.startsOn === secondary.startsOn;
}

Deno.serve(async (request) => {
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  const projectUrl = Deno.env.get('SUPABASE_URL');
  const cronToken = Deno.env.get('OFFICIAL_HIJRI_CRON_TOKEN');
  if (!serviceRoleKey || !projectUrl || !cronToken) {
    return json({ error: 'Function configuration is incomplete.' }, 500);
  }
  const authorization = request.headers.get('Authorization');
  if (authorization !== `Bearer ${serviceRoleKey}` && authorization !== `Bearer ${cronToken}`) {
    return json({ error: 'Unauthorized.' }, 401);
  }

  let record: FeedRecord | undefined;
  try {
    const { mora, radio } = await requestRecords(request);
    if (!matches(mora, radio)) {
      const message = 'MoRA and Radio Pakistan records do not agree; no official date was stored.';
      await log(projectUrl, serviceRoleKey, 'skipped', message, mora, {
        radio_source_url: radio.sourceUrl,
        radio_hijri_year: radio.hijriYear,
        radio_hijri_month: radio.hijriMonth,
        radio_starts_on: radio.startsOn,
      });
      return json({ stored: false, status: 'skipped', reason: 'sources_disagree' });
    }
    record = mora;
    const databaseResponse = await fetch(
      `${projectUrl}/rest/v1/official_hijri_months?on_conflict=country_code,hijri_year,hijri_month`,
      {
        method: 'POST',
        headers: {
          apikey: serviceRoleKey,
          Authorization: `Bearer ${serviceRoleKey}`,
          'Content-Type': 'application/json',
          Prefer: 'resolution=merge-duplicates,return=minimal',
        },
        body: JSON.stringify({
          country_code: record.countryCode,
          hijri_year: record.hijriYear,
          hijri_month: record.hijriMonth,
          starts_on: record.startsOn,
          announced_at: record.announcedAt,
          authority_name: record.authorityName,
          source_url: record.sourceUrl,
          status: 'confirmed',
        }),
      },
    );
    if (!databaseResponse.ok) throw new Error(`Database write returned ${databaseResponse.status}.`);
    await log(projectUrl, serviceRoleKey, 'stored', 'Matching MoRA and Radio Pakistan confirmation stored.', record, {
      radio_source_url: radio.sourceUrl,
    });
    return json({ stored: true, hijriYear: record.hijriYear, hijriMonth: record.hijriMonth });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown ingestion error.';
    await log(projectUrl, serviceRoleKey, 'failed', message, record).catch(() => undefined);
    return json({ stored: false, error: message }, 422);
  }
});

async function log(
  projectUrl: string,
  key: string,
  outcome: string,
  message: string,
  record?: FeedRecord,
  details: Record<string, unknown> = {},
) {
  await fetch(`${projectUrl}/rest/v1/official_hijri_ingestion_runs`, {
    method: 'POST',
    headers: { apikey: key, Authorization: `Bearer ${key}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({
      outcome,
      message,
      completed_at: new Date().toISOString(),
      source_url: record?.sourceUrl,
      hijri_year: record?.hijriYear,
      hijri_month: record?.hijriMonth,
      starts_on: record?.startsOn ?? null,
      details,
    }),
  });
}
