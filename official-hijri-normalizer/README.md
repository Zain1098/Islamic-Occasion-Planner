# Official Hijri normalizer

This Vercel service exposes two read-only JSON endpoints:

- `/api/mora-feed`
- `/api/radio-pakistan-feed`

Each endpoint discovers recent publisher links, reads only its own publisher domain, and returns a record only when it finds an announcement from the Central Ruet-e-Hilal Committee Pakistan with a Hijri year/month, publication time, and an explicit Gregorian start date. It returns `404` or `503` instead of guessing.

The Vercel cron reads both source parsers in the same protected service and sends the two records to Supabase. Supabase writes a `confirmed` Pakistan record only when both records agree on Hijri year, Hijri month, and `startsOn`.

## Vercel configuration

No secret is required for the default public source URLs. If a publisher changes its listing page, set either optional server-only variable:

- `MORA_NEWS_URL`
- `RADIO_PAKISTAN_NEWS_URL`

Vercel Cron invokes `/api/run-ingestion` every day at 16:15 UTC (21:15 Pakistan time). It needs server-only `CRON_SECRET` and `SUPABASE_INGEST_URL` variables. `CRON_SECRET` must match the Supabase Edge Function's `OFFICIAL_HIJRI_CRON_TOKEN` secret.

After deployment, configure these Supabase Edge Function secrets with the production Vercel URLs:

- `RUET_E_HILAL_MORA_FEED_URL=https://<vercel-domain>/api/mora-feed`
- `RUET_E_HILAL_RADIO_PAKISTAN_FEED_URL=https://<vercel-domain>/api/radio-pakistan-feed`

No user plans, budgets, savings, reminder data, or backup contents are sent to this service.
