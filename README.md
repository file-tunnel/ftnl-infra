# ftnl-infra

GitOps app-of-apps for File Tunnel, designed to interoperate with
[`ORESoftware/k8s-cluster`](https://github.com/ORESoftware/k8s-cluster).

That cluster repository keeps Argo CD application registrations under
`remote/argocd/apps/` and currently tracks its `dev` branch. This repository
keeps File Tunnel's own application graph and Kubernetes desired state
separate, so platform releases do not copy manifests into the cluster repo.

## Bootstrap contract

Copy or Kustomize
[`interop/k8s-cluster/file-tunnel.application.yaml`](interop/k8s-cluster/file-tunnel.application.yaml)
into `ORESoftware/k8s-cluster/remote/argocd/apps/`. That single root
Application points Argo CD at `argocd/apps/` here.

The root creates:

- the restricted `file-tunnel` Argo CD project;
- `ftnl-foundation` for namespace, quotas, limits, and default-deny policy;
- `ftnl-backend-api` for the Rust control/data plane;
- `ftnl-web-server` for the mobile upload portal.

Children are intentionally manual until immutable GHCR image digests replace
the all-zero bootstrap digests. `scripts/promote-image.sh` is the only supported
promotion path. Once persistence, object storage, malware quarantine, expiry
sweeping, and secrets are configured, operators may opt the children into
automated sync.

Before enabling a child Application, either allow public visibility for the
organization's GHCR packages or provision a read-only GHCR pull credential
through the cluster's secret manager. The manifests never embed registry
credentials.

## Repository layout

```text
argocd/apps/                 child Application and AppProject resources
interop/k8s-cluster/         one-file registration for ORESoftware/k8s-cluster
kubernetes/foundation/       namespace security and resource boundaries
kubernetes/backend/          API Deployment, Service, Ingress, NetworkPolicy
kubernetes/portal/           portal Deployment, Service, Ingress, NetworkPolicy
scripts/                     validation and immutable image promotion
cloudflare/                  cross-repository Worker and DNS ownership
env/                         SOPS schema, ciphertext, and source ownership
supabase/                    CLI parity and reviewed SQL migrations
docs/                        secret delivery and provider GitOps boundaries
```

## Validate

```bash
nix develop --command agent-check
```

This renders every Kustomize tree into a temporary directory and validates it
with the Nix-pinned `kubeconform`; no cluster credentials are needed.

It also validates SOPS/plaintext hygiene, one-source environment ownership,
Supabase RLS migration policy, and credential-free Cloudflare/Supabase plans.
See [`docs/environment-secrets.md`](docs/environment-secrets.md) and
[`docs/gitops.md`](docs/gitops.md) before adding credentials or enabling a
provider apply workflow.

The deployment uses the existing cluster conventions: Argo CD, Kustomize,
NGINX Ingress, cert-manager's `letsencrypt-prod` issuer, External Secrets backed
by Fiducia KV, and a `dev` cluster registration. No plaintext Secret is
committed.

MIT licensed.
