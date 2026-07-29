# shellcheck shell=bash
set -euo pipefail

./scripts/validate.sh

rendered_dir="$(mktemp -d)"
trap 'rm -rf "$rendered_dir"' EXIT

kustomize build argocd/apps >"$rendered_dir/argocd.yaml"
kustomize build kubernetes/foundation >"$rendered_dir/foundation.yaml"
kustomize build kubernetes/backend >"$rendered_dir/backend.yaml"
kustomize build kubernetes/portal >"$rendered_dir/portal.yaml"
kubeconform -strict -summary -ignore-missing-schemas "$rendered_dir"
