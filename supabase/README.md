# Official Hijri ingestion

`ingest-official-hijri` runs daily at 21:15 Pakistan time (16:15 UTC) after the migration is applied. It accepts one trusted JSON feed and only upserts a record when all fields pass validation.

## Required one-time configuration

1. In Supabase Vault, create `official_hijri_project_url` and `official_hijri_service_role_key`. Re-run the scheduling block if the migration was applied before those secrets existed.
2. Set the Edge Function secret `RUET_E_HILAL_FEED_URL` to a maintained HTTPS endpoint controlled by, or directly republishing, the Central Ruet-e-Hilal Committee Pakistan announcement.
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

Any other authority, country, status, malformed date, or non-HTTPS source is rejected and recorded as a failed ingestion run. The Android app continues to show its calculated fallback until it retrieves a confirmed stored record.
