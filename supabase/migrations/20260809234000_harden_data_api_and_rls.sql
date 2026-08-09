-- Keep the REST surface separate from internal application tables. Data API
-- roles receive schema usage only; table/function grants remain explicit in
-- the migration that creates each API object.
create schema if not exists api;
grant usage on schema api to anon, authenticated;

alter default privileges for role postgres in schema public
  revoke select, insert, update, delete on tables from anon, authenticated, service_role;
alter default privileges for role postgres in schema public
  revoke usage, select on sequences from anon, authenticated, service_role;
alter default privileges for role postgres in schema public
  revoke execute on functions from anon, authenticated, service_role;
alter default privileges for role postgres in schema public
  revoke execute on functions from public;

alter default privileges for role postgres in schema api
  revoke select, insert, update, delete on tables from anon, authenticated, service_role;
alter default privileges for role postgres in schema api
  revoke usage, select on sequences from anon, authenticated, service_role;
alter default privileges for role postgres in schema api
  revoke execute on functions from anon, authenticated, service_role;
alter default privileges for role postgres in schema api
  revoke execute on functions from public;

-- Based on Supabase's documented auto-RLS event trigger, extended to the
-- dedicated API schema. Existing migrations must still enable RLS explicitly.
create or replace function rls_auto_enable()
returns event_trigger
language plpgsql
security definer
set search_path = pg_catalog
as $$
declare
  cmd record;
begin
  for cmd in
    select *
      from pg_event_trigger_ddl_commands()
     where command_tag in ('CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO')
       and object_type in ('table', 'partitioned table')
  loop
    if cmd.schema_name is not null
       and cmd.schema_name in ('public', 'api')
       and cmd.schema_name not in ('pg_catalog', 'information_schema')
       and cmd.schema_name not like 'pg_toast%'
       and cmd.schema_name not like 'pg_temp%'
    then
      -- Deliberately fail the originating DDL transaction if RLS cannot be
      -- enabled. Logging and continuing would permit an unprotected table.
      execute format(
        'alter table if exists %s enable row level security',
        cmd.object_identity
      );
      raise log 'rls_auto_enable: enabled RLS on %', cmd.object_identity;
    else
      raise log 'rls_auto_enable: skipped % in schema %', cmd.object_identity, cmd.schema_name;
    end if;
  end loop;
end;
$$;

drop event trigger if exists ensure_rls;
create event trigger ensure_rls
  on ddl_command_end
  when tag in ('CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO')
  execute function rls_auto_enable();
