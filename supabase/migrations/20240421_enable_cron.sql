-- Enable the pg_cron extension (requires superuser privileges)
create extension if not exists pg_cron schema public;

-- Grant usage to postgres
grant usage on schema cron to postgres;

-- Grant execute on all functions in schema cron to postgres
grant execute on all functions in schema cron to postgres; 