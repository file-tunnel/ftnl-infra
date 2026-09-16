# Neon modules-first migration

This change reorganizes Terraform only. CI must not apply, import, destroy, or recreate Neon resources.

## Canonical layout

- reusable resources: `modules/neon/terraform`
- provider-native descriptor: `modules/neon/neon.ts`
- roots: `environments/preview`, `environments/staging`, `environments/production`
- credential: `NEON_API_KEY` from the reviewed ores-sops/runtime environment, never Git.

The legacy `~> 0.6` provider constraint is narrowed to exact `0.6.3`, the latest release inside that already-admitted compatibility line. This migration intentionally does not jump to a newer Neon provider API.

## Production state addresses

Legacy addresses:

- `neon_project.prod`
- `neon_role.app`
- `neon_role.auth`
- `neon_database.canonical`
- `neon_database.auth`

Canonical addresses:

- `module.neon.neon_project.prod`
- `module.neon.neon_role.app`
- `module.neon.neon_role.auth`
- `module.neon.neon_database.canonical`
- `module.neon.neon_database.auth`

`environments/production/main.tf` contains Terraform `moved` blocks for all five transitions. Before the first production apply, initialize that root against the same production state backend/workspace as the legacy configuration and review the plan. It must show moves only and zero destroy/create replacements.

If manual state surgery is required instead, take a `terraform state pull` backup outside the repository and then, against the same state, use:

```sh
terraform state mv 'neon_project.prod' 'module.neon.neon_project.prod'
terraform state mv 'neon_role.app' 'module.neon.neon_role.app'
terraform state mv 'neon_role.auth' 'module.neon.neon_role.auth'
terraform state mv 'neon_database.canonical' 'module.neon.neon_database.canonical'
terraform state mv 'neon_database.auth' 'module.neon.neon_database.auth'
```

Stop if a source is absent or a destination already exists. Do not guess resource IDs; imports require a separate reviewed recovery plan.

## Credential-free CI

CI may run formatting, `terraform init -backend=false`, and `terraform validate`. Production plan/apply remains an explicit operator action.
