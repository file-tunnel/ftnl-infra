# shellcheck shell=bash
set -euo pipefail

./scripts/validate.sh
./scripts/gitops-plan.sh

rendered_dir="$(mktemp -d)"
cleanup() {
  rm -f \
    "$rendered_dir/argocd.yaml" \
    "$rendered_dir/foundation.yaml" \
    "$rendered_dir/backend.yaml" \
    "$rendered_dir/portal.yaml"
  rmdir "$rendered_dir"
}
trap cleanup EXIT

kustomize build argocd/apps >"$rendered_dir/argocd.yaml"
kustomize build kubernetes/foundation >"$rendered_dir/foundation.yaml"
kustomize build kubernetes/backend >"$rendered_dir/backend.yaml"
kustomize build kubernetes/portal >"$rendered_dir/portal.yaml"
kubeconform -strict -summary -ignore-missing-schemas "$rendered_dir"
