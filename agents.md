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
- Keep `env/enc/*.env.enc` as SOPS ciphertext and `env/dec/` ignored. Never put
  plaintext secret values in patches or command arguments; use `just edit`.
- Preserve the one-source ownership contract in `env/ownership.toml`. Runtime
  Fiducia values must use the guarded ExternalSecret key convention.
- Core generates additive DDL; this repository owns migration review, RLS,
  explicit grants, and provider apply policy.
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

## Repository-local Git worktrees

- Create or use a Git worktree only when the human operator explicitly authorizes it for the current task. Concurrency or a dirty checkout is not permission by itself.
- Put every authorized worktree at `<repository-root>/tmp/worktrees/<name>`; from the repository root, use `./tmp/worktrees/<name>`. Never place worktrees beside repositories or organization directories.
- Keep `tmp`, `temp`, `tmp/worktrees`, and `temp/worktrees` ignored in the repository-root `.gitignore`. Do not commit files from those directories.
- Relocate or remove a worktree only when the operator explicitly requests it. Before removal, preserve and publish intended changes, verify its commit is represented on the target branch, and confirm there are no tracked, untracked, ignored-sensitive, or in-use files that must survive. Remove it with `git worktree remove <path>` without `--force`; never delete a worktree directory with `rm`.
