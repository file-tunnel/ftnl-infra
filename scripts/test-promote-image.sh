#!/usr/bin/env bash
set -euo pipefail
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd -- "$script_dir/.." && pwd)"
tmp="$(mktemp -d)"
cleanup() {
  rm -f "$tmp/kubernetes/backend/kustomization.yaml" \
        "$tmp/kubernetes/backend/kustomization.yaml.bak" \
        "$tmp/kubernetes/portal/kustomization.yaml"
  rmdir "$tmp/kubernetes/backend" "$tmp/kubernetes/portal" "$tmp/kubernetes" "$tmp"
}
trap cleanup EXIT
mkdir -p "$tmp/kubernetes/backend" "$tmp/kubernetes/portal"
cp "$root/kubernetes/backend/kustomization.yaml" "$tmp/kubernetes/backend/kustomization.yaml"
cp "$root/kubernetes/portal/kustomization.yaml" "$tmp/kubernetes/portal/kustomization.yaml"
cd "$tmp"
digest="sha256:$(printf 'a%.0s' {1..64})"
original="$(sha256sum kubernetes/backend/kustomization.yaml | cut -d ' ' -f 1)"
bash "$root/scripts/promote-image.sh" backend "$digest" --dry-run
[[ "$(sha256sum kubernetes/backend/kustomization.yaml | cut -d ' ' -f 1)" == "$original" ]]
if bash "$root/scripts/promote-image.sh" backend "sha256:invalid"; then
  echo "accepted invalid digest" >&2
  exit 1
fi
bash "$root/scripts/promote-image.sh" backend "$digest"
grep -Fq "digest: $digest" kubernetes/backend/kustomization.yaml
[[ "$(sha256sum kubernetes/portal/kustomization.yaml | cut -d ' ' -f 1)" != "" ]]
sed -i.bak '/digest: sha256:/d' kubernetes/backend/kustomization.yaml
if bash "$root/scripts/promote-image.sh" backend "$digest"; then
  echo "accepted manifest without digest" >&2
  exit 1
fi
