# File Tunnel infrastructure agent instructions

These instructions apply to this repository and every directory beneath it.

## Repository role

- This repository owns File Tunnel's Argo CD and Kubernetes desired state.
- Keep the platform registration boundary with `ORESoftware/k8s-cluster`
  explicit; do not copy application implementation into this repository.
- Preserve restricted namespaces, quotas, limits, default-deny networking,
  immutable image digests, and manual bootstrap sync until documented
  persistence, object storage, quarantine, expiry, and secret prerequisites
  are satisfied.
- Never embed registry credentials, cloud credentials, capabilities, pairing
  secrets, or plaintext Kubernetes Secrets.
- Do not apply manifests to a live cluster unless the user explicitly requests
  that external change.

## Validation

- Run `nix develop --command agent-check` before completing a change.
- Keep Kustomize rendering and strict kubeconform validation offline and
  credential-free.
- Use `scripts/promote-image.sh` for image digest promotion.

## Git workflow

- Keep changes focused and reviewable.
- Pull and merge remote work before pushing; avoid git rebase in favor of git merge.
- Never discard unrelated or uncommitted user work.
