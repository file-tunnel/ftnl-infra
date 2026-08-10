# Environment and secret ownership

File Tunnel uses three distinct layers. They are complementary, not competing
copies of the same secret.

1. `env/enc/*.env.enc` is the Git source of record for reviewed provider and
   environment values. It is SOPS ciphertext encrypted to explicit age
   recipients. `env/dec/` and the root `.env` link are ignored plaintext for
   local operator use only.
2. Fiducia KV is the runtime source for application secrets. A reviewed
   promotion copies only the runtime subset from decrypted SOPS memory into
   keys shaped as `k8s/file-tunnel/<workload>/<ENV_VAR>`.
3. External Secrets materializes those Fiducia values as namespace-scoped
   Kubernetes Secrets. Pods consume the generated Secret via `envFrom`; secret
   data never appears in a manifest or Argo CD diff.

`env/ownership.toml` assigns one source of record and one delivery path to each
variable. `scripts/validate-env.py` rejects duplicate ownership, invalid names,
tracked plaintext, and ciphertext whose key set drifts from the manifest.

## Local workflow

```bash
nix develop
just edit prod
just status
just check
just lock
```

`just edit prod` is the only appropriate place to enter a rotated production
credential. Do not paste credentials into a patch, command argument, ticket,
chat, CI log, or Git commit message. Dotenv variable names remain readable in
SOPS ciphertext; only their values are encrypted.

## Runtime promotion

`just promote-secrets prod` validates and prints the promotion boundary. It
does not mutate Fiducia or Kubernetes. Production promotion needs a protected,
reviewed operator workflow that decrypts in memory, writes only the declared
runtime subset, and records key names and ciphertext checksums without values.

Before enabling either Argo CD child application, verify:

- `ClusterSecretStore/dd-fiducia-kv` is Ready;
- the `file-tunnel` namespace has `dd.dev/fiducia-kv-secrets=enabled`;
- each `ExternalSecret` is Ready without reading or printing the generated
  Secret;
- the Stakater reloader controller is available for secret rotations;
- no pod receives Cloudflare or Supabase management credentials.

The SOPS age private keys are not committed. GitHub Actions uses a dedicated
recipient whose private identity is stored as `SOPS_AGE_KEY` in the protected
`production` GitHub environment; it never reuses an operator private key.

The production Supabase bundle also carries a dedicated Management API access
token and database password for reviewed migration applies. The access token
expires on 2026-09-08. Rotate it before expiry, update the ciphertext with
`just edit prod`, merge the reviewed ciphertext, and revoke the superseded
token only after the production workflow succeeds.
