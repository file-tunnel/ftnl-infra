#!/usr/bin/env bash
set -euo pipefail

component="${1:-}"
digest="${2:-}"
case "$component" in
  backend) file="kubernetes/backend/kustomization.yaml" ;;
  portal) file="kubernetes/portal/kustomization.yaml" ;;
  *)
    echo "usage: $0 backend|portal sha256:<64 hex>" >&2
    exit 2
    ;;
esac

if [[ ! "$digest" =~ ^sha256:[a-f0-9]{64}$ ]] ||
  [[ "$digest" == "sha256:0000000000000000000000000000000000000000000000000000000000000000" ]]; then
  echo "digest must be a non-zero sha256 OCI digest" >&2
  exit 2
fi

perl -0pi -e "s#digest: sha256:[a-f0-9]{64}#digest: $digest#" "$file"
echo "Promoted $component to $digest in $file"
