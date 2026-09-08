# Shared Auth dual-provider topology

This source-only DEN-2843 contract binds File Tunnel customer servers only to customer Supabase/Neon auth databases and admin servers only to admin databases. Both providers are required; admin/sensitive operations are strict-paired and disagreement denies.

The dedicated `file-tunnel` Supabase organization is the target. Shared `oresoftware` placement is an explicit expiring waiver with isolated `file_tunnel` schema only; Neon remains dedicated.

Customer web/API remain blocked until their legacy Shared Auth dependency is replaced with the pinned service client and exact realm tests pass. Both admin repositories are README-only stubs and remain blocked. Applications authorize only canonical Shared Auth principals; startup never owns DDL.

```sh
node shared-auth/validate.mjs
```
