# Supabase migrations

Commit timestamp-prefixed SQL migrations here. Every migration that creates a
table in `public` must enable row-level security for that table in the same
file, define explicit policies and grants, and pass
`scripts/check-supabase-migrations.py`.

`ftnl-lib-core` generates deterministic additive PostgreSQL DDL and ORM plans.
This infrastructure repository owns reviewing that output, converting it into
an immutable migration, and applying it to Supabase. Supabase's Data API—not
either repository—generates REST endpoints from exposed schemas.
