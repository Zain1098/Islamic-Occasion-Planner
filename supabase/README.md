# Official Hijri ingestion

`ingest-official-hijri` runs daily at 21:15 Pakistan time (16:15 UTC) after the migration is applied. It only upserts a record when a MoRA feed and a Radio Pakistan feed agree on the Hijri year, month, and Pakistan start date.

## Required one-time configuration

1. In Supabase Vault, create `official_hijri_project_url` and `official_hijri_service_role_key`. Re-run the scheduling block if the migration was applied before those secrets existed.
2. Set Edge Function secrets `RUET_E_HILAL_MORA_FEED_URL` and `RUET_E_HILAL_RADIO_PAKISTAN_FEED_URL`. Each must be a maintained HTTPS JSON endpoint that returns its source's latest Central Ruet-e-Hilal announcement. The function rejects records unless the embedded `sourceUrl` belongs to `mora.gov.pk` or `radio.gov.pk` respectively.
3. Deploy the migration, then deploy the function with `supabase functions deploy ingest-official-hijri`.

The feed must return this shape (or wrap it in `data`):

```json
{
  "hijriYear": 1448,
  "hijriMonth": 9,
  "startsOn": "2027-02-08",
  "announcedAt": "2027-02-07T15:00:00Z",
  "authorityName": "Central Ruet-e-Hilal Committee Pakistan",
  "sourceUrl": "https://example.gov.pk/announcement",
  "countryCode": "PK",
  "status": "confirmed"
}
```

Any other authority, country, status, malformed date, source domain, or a disagreement between the two sources is rejected or skipped and recorded in the private ingestion audit log. The Android app continues to show its calculated fallback until it retrieves a confirmed stored record.
