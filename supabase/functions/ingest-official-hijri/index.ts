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

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}

function readRecord(value: unknown): FeedRecord {
  const raw = (value as { data?: unknown }).data ?? value;
  if (raw === null || typeof raw !== 'object') throw new Error('Feed record is missing.');
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
  if (!Number.isInteger(record.hijriYear) || !Number.isInteger(record.hijriMonth) ||
      record.hijriMonth < 1 || record.hijriMonth > 12 ||
      !/^\d{4}-\d{2}-\d{2}$/.test(record.startsOn) ||
      Number.isNaN(Date.parse(record.announcedAt)) ||
      record.authorityName !== requiredAuthority || record.countryCode !== 'PK' ||
      record.status !== 'confirmed' || !URL.canParse(record.sourceUrl) ||
      new URL(record.sourceUrl).protocol !== 'https:') {
    throw new Error('Feed record did not pass the official confirmation checks.');
  }
  return record;
}

Deno.serve(async (request) => {
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  const projectUrl = Deno.env.get('SUPABASE_URL');
  const feedUrl = Deno.env.get('RUET_E_HILAL_FEED_URL');
  if (!serviceRoleKey || !projectUrl || !feedUrl) {
    return json({ error: 'Function configuration is incomplete.' }, 500);
  }
  if (request.headers.get('Authorization') !== `Bearer ${serviceRoleKey}`) {
    return json({ error: 'Unauthorized.' }, 401);
  }

  let record: FeedRecord | undefined;
  try {
    const response = await fetch(feedUrl, { headers: { Accept: 'application/json' } });
    if (!response.ok) throw new Error(`Trusted feed returned ${response.status}.`);
    record = readRecord(await response.json());
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
    await log(projectUrl, serviceRoleKey, 'stored', 'Confirmed official Hijri month stored.', record);
    return json({ stored: true, hijriYear: record.hijriYear, hijriMonth: record.hijriMonth });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown ingestion error.';
    await log(projectUrl, serviceRoleKey, 'failed', message, record).catch(() => undefined);
    return json({ stored: false, error: message }, 422);
  }
});

async function log(projectUrl: string, key: string, outcome: string, message: string, record?: FeedRecord) {
  await fetch(`${projectUrl}/rest/v1/official_hijri_ingestion_runs`, {
    method: 'POST',
    headers: { apikey: key, Authorization: `Bearer ${key}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ outcome, message, completed_at: new Date().toISOString(), source_url: record?.sourceUrl, hijri_year: record?.hijriYear, hijri_month: record?.hijriMonth, starts_on: record?.startsOn ?? null }),
  });
}
