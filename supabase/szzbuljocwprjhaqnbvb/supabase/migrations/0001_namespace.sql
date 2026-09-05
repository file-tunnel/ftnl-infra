-- file-tunnel: isolated namespace inside the shared auth project
create schema if not exists file_tunnel;
revoke all on schema file_tunnel from public;
