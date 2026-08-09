# File Tunnel GitOps boundaries

## Kubernetes and Argo CD

`ftnl-infra` owns the application graph, immutable image digests, namespace
security, networking, External Secrets, and rollout prerequisites. The
`ORESoftware/k8s-cluster` repository owns platform services and the one-file
registration that points Argo CD here. Application implementations remain in
their source repositories.

Foundation may auto-sync. Backend and web-server applications remain manual
until nonzero image digests, object storage, quarantine scanning, expiry,
database migrations, ExternalSecret readiness, and rollback evidence exist.

## Supabase

Responsibility is deliberately split:

- `ftnl-lib-core` validates canonical JSON Schema and generates deterministic,
  additive PostgreSQL DDL plus ORM/query plans.
- `ftnl-infra` reviews generated DDL, stores timestamped migrations, enforces
  RLS/grant policy, and owns the protected apply workflow.
- Supabase Data API generates REST endpoints from explicitly exposed schemas.
  File Tunnel does not maintain a second REST generator in core or infra.

The hosted project must be created as `file-tunnel-main-sb-project` in the
`file-tunnel` organization, Americas region, Free plan. Enable Data API, disable
automatic exposure of new tables, and enable automatic RLS. These hosted flags
must be verified in the dashboard because `supabase/config.toml` is local CLI
configuration, not proof of remote dashboard state.

Every public-table migration must enable RLS in the same file. Broad
`GRANT ALL` to `anon` or `authenticated` is rejected. Production migration runs
only from `main`, uses the protected `production` environment, decrypts SOPS in
memory, and requires a Supabase management access token and database password;
the Data API secret key is not a substitute for either credential.

## Cloudflare

`cloudflare/projects.toml` is the cross-repository deployment inventory.
Worker source, tests, and `wrangler.toml` stay with each worker-owning source
repository. That repository builds and uploads the worker; `ftnl-infra` owns
production environment policy, domains, promotion order, and evidence.

Cloudflare deployment needs a narrowly scoped API token stored only in SOPS
and the protected CI environment. Pull requests must produce a dry-run artifact
from the source repository. Production deploys run from a reviewed immutable
commit, use GitHub environment protection, and record worker version/route/DNS
identifiers without echoing the token.

The current inventory marks DNS ownership but does not invent a target address:
the API and upload records can be applied only after the cluster ingress target
is known. Until then, DNS/provider apply is intentionally blocked rather than
creating placeholder records.

## Promotion sequence

1. Core schema/code/DDL checks pass.
2. A reviewed Supabase migration lands and applies; RLS and grants are verified.
3. Runtime secrets are promoted to Fiducia and ExternalSecrets become Ready.
4. Application images are built, tested, scanned, and pinned by digest.
5. Cloudflare worker dry-runs and DNS plans are reviewed.
6. Argo CD child sync is enabled manually, then live probes and rollback are
   recorded before automation is broadened.
