# Neon for file-tunnel

Neon is 1:1 with the GitHub org (`org-file-tunnel` planned). `neon/file-tunnel-prod/terraform/` declares the
project, branches, roles and the two databases (`canonical`, `auth`) with the Neon Terraform provider; the
`neon-preview.yml` workflow creates a `preview/pr-<n>` branch per PR and runs `dpm plan` only (apply is human-gated).
Neon never ingests schema from git — migrations come from `ftnl-orm-core` via dpm.
