import { latestRecord } from './_lib/hijri.js';

export default async function handler(request, response) {
  const cronSecret = process.env.CRON_SECRET;
  const ingestionUrl = process.env.SUPABASE_INGEST_URL;
  if (!cronSecret || !ingestionUrl) {
    return response.status(500).json({ error: 'Cron configuration is incomplete.' });
  }
  if (request.headers.authorization !== `Bearer ${cronSecret}`) {
    return response.status(401).json({ error: 'Unauthorized.' });
  }
  let mora;
  let radio;
  try {
    [mora, radio] = await Promise.all([
      latestRecord('mora'),
      latestRecord('radio_pakistan'),
    ]);
  } catch (_) {
    return response.status(503).json({ status: 'skipped', reason: 'publisher_unavailable' });
  }
  if (!mora || !radio) {
    return response.status(204).end();
  }
  const upstream = await fetch(ingestionUrl, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${cronSecret}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ mora, radio }),
    signal: AbortSignal.timeout(10_000),
  });
  const body = await upstream.text();
  return response.status(upstream.status).send(body);
}
