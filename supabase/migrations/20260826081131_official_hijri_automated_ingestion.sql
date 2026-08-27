-- Automated ingestion audit trail for official Pakistan Hijri records.
create table if not exists public.official_hijri_ingestion_runs (
  id bigint generated always as identity primary key,
  started_at timestamptz not null default now(),
  completed_at timestamptz,
  outcome text not null check (outcome in ('started', 'stored', 'skipped', 'failed')),
  message text not null,
  source_url text,
  hijri_year integer,
  hijri_month integer,
  starts_on date,
  details jsonb not null default '{}'::jsonb
);
alter table public.official_hijri_ingestion_runs enable row level security;
comment on table public.official_hijri_ingestion_runs is 'Private audit log for the trusted official Hijri feed ingestion job.';

-- Create Vault secrets before deploying: official_hijri_project_url and
-- official_hijri_service_role_key. This keeps secrets out of app code and Git.
do $$
declare project_url text; service_role_key text;
begin
  select decrypted_secret into project_url from vault.decrypted_secrets where name = 'official_hijri_project_url';
  select decrypted_secret into service_role_key from vault.decrypted_secrets where name = 'official_hijri_service_role_key';
  if project_url is null or service_role_key is null then
    raise notice 'Official Hijri cron job not scheduled: add Vault secrets first.';
    return;
  end if;
  if not exists (select 1 from cron.job where jobname = 'ingest-official-hijri-daily') then
    perform cron.schedule(
      'ingest-official-hijri-daily',
      '15 16 * * *',
      format(
        $sql$select net.http_post(url := %L, headers := jsonb_build_object('Content-Type', 'application/json', 'Authorization', 'Bearer ' || %L), body := '{}'::jsonb, timeout_milliseconds := 10000);$sql$,
        project_url || '/functions/v1/ingest-official-hijri', service_role_key
      )
    );
  end if;
end $$;
