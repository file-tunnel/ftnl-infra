#!/usr/bin/env bash
set -euo pipefail

component="${1:-}"
digest="${2:-}"
mode="${3:-}"
if (($# < 2 || $# > 3)) || [[ -n "$mode" && "$mode" != "--dry-run" ]]; then
  echo "usage: $0 backend|portal sha256:<64 lowercase hex> [--dry-run]" >&2
  exit 2
fi

case "$component" in
  backend) file="kubernetes/backend/kustomization.yaml" ;;
  portal) file="kubernetes/portal/kustomization.yaml" ;;
  *)
    echo "unknown component: expected backend or portal" >&2
    exit 2
    ;;
esac

if [[ ! "$digest" =~ ^sha256:[a-f0-9]{64}$ ]] ||
  [[ "$digest" == "sha256:$(printf '%064d' 0)" ]]; then
  echo "digest must be a non-zero lowercase sha256 OCI digest" >&2
  exit 2
fi

# Do not follow a repository manifest or parent path that is a symlink. In
# particular, in-place editors may otherwise overwrite a file outside this
# checkout. A successful promotion must only replace the selected manifest.
if [[ -L kubernetes || -L "$(dirname -- "$file")" || -L "$file" ]]; then
  echo "refusing symlinked image manifest path: $file" >&2
  exit 1
fi
if [[ ! -f "$file" ]]; then
  echo "missing image manifest: $file" >&2
  exit 1
fi

# Reject zero or multiple canonical digest records, including manifests that
# have changed schema. A dry-run applies exactly the same validation.
count=$(grep -Ec '^[[:space:]]*digest: sha256:[a-f0-9]{64}$' "$file" || true)
if [[ "$count" != 1 ]]; then
  echo "expected exactly one image digest in $file (found $count)" >&2
  exit 1
fi
if [[ "$mode" == "--dry-run" ]]; then
  echo "Would promote $component to $digest in $file"
  exit 0
fi

# Work in the manifest's directory so the final rename is atomic. Preserve
# the original file mode and remove the temporary file on any failure.
tmp=$(mktemp "$(dirname -- "$file")/.ftnl-promotion.XXXXXX")
cleanup() { rm -f -- "$tmp"; }
trap cleanup EXIT
cp -p -- "$file" "$tmp"
FTNL_PROMOTION_DIGEST="$digest" perl -0pi -e 's#(^[[:space:]]*digest: )sha256:[a-f0-9]{64}$#$1$ENV{FTNL_PROMOTION_DIGEST}#m' "$tmp"
mv -f -- "$tmp" "$file"
trap - EXIT
echo "Promoted $component to $digest in $file"
