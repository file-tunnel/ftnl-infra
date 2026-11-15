#!/usr/bin/env bash
set -euo pipefail
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd -- "$script_dir/.." && pwd)"
tmp="$(mktemp -d)"
cleanup() {
  rm -f -- "$tmp/kubernetes/backend/kustomization.yaml" \
    "$tmp/kubernetes/backend/kustomization.yaml.bak" \
    "$tmp/kubernetes/portal/kustomization.yaml" \
    "$tmp/outside.yaml" "$tmp/outside-dir/kustomization.yaml"
  if [[ -L "$tmp/kubernetes/backend" ]]; then
    rm -f -- "$tmp/kubernetes/backend"
  fi
  rmdir -- "$tmp/outside-dir" 2>/dev/null || true
  rmdir -- "$tmp/kubernetes/backend" 2>/dev/null || true
  rmdir -- "$tmp/kubernetes/portal" 2>/dev/null || true
  rmdir -- "$tmp/kubernetes" "$tmp"
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
if bash "$root/scripts/promote-image.sh" backend "$digest" --unexpected; then
  echo "accepted unknown flag" >&2
  exit 1
fi
if bash "$root/scripts/promote-image.sh" backend "$digest" --dry-run extra; then
  echo "accepted extra argument" >&2
  exit 1
fi
bash "$root/scripts/promote-image.sh" backend "$digest"
grep -Fq "digest: $digest" kubernetes/backend/kustomization.yaml
[[ "$(find kubernetes/backend -name '.ftnl-promotion.*' | wc -l)" -eq 0 ]]
[[ "$(sha256sum kubernetes/portal/kustomization.yaml | cut -d ' ' -f 1)" != "" ]]

# Refuse duplicate or missing markers without touching the manifest.
printf '    digest: %s\n' "$digest" >>kubernetes/backend/kustomization.yaml
original="$(sha256sum kubernetes/backend/kustomization.yaml | cut -d ' ' -f 1)"
if bash "$root/scripts/promote-image.sh" backend "$digest"; then
  echo "accepted duplicate manifest digest" >&2
  exit 1
fi
[[ "$(sha256sum kubernetes/backend/kustomization.yaml | cut -d ' ' -f 1)" == "$original" ]]
sed -i.bak '/digest: sha256:/d' kubernetes/backend/kustomization.yaml
if bash "$root/scripts/promote-image.sh" backend "$digest"; then
  echo "accepted manifest without digest" >&2
  exit 1
fi

# A symlink must never permit the tool to mutate a file outside the checkout.
cp "$root/kubernetes/backend/kustomization.yaml" "$tmp/outside.yaml"
rm -f kubernetes/backend/kustomization.yaml
ln -s "$tmp/outside.yaml" kubernetes/backend/kustomization.yaml
original="$(sha256sum "$tmp/outside.yaml" | cut -d ' ' -f 1)"
if bash "$root/scripts/promote-image.sh" backend "$digest"; then
  echo "followed symlinked manifest" >&2
  exit 1
fi
[[ "$(sha256sum "$tmp/outside.yaml" | cut -d ' ' -f 1)" == "$original" ]]
rm kubernetes/backend/kustomization.yaml
rm -f kubernetes/backend/kustomization.yaml.bak
rmdir kubernetes/backend
mkdir -p "$tmp/outside-dir"
cp "$root/kubernetes/backend/kustomization.yaml" "$tmp/outside-dir/kustomization.yaml"
ln -s "$tmp/outside-dir" kubernetes/backend
if bash "$root/scripts/promote-image.sh" backend "$digest"; then
  echo "followed symlinked manifest directory" >&2
  exit 1
fi
[[ "$(sha256sum "$tmp/outside-dir/kustomization.yaml" | cut -d ' ' -f 1)" == "$original" ]]

echo "promote-image regressions passed"
