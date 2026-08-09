#!/usr/bin/env bash
set -euo pipefail

name="${1:?usage: promote-secrets.sh ENVIRONMENT}"
ciphertext="env/enc/${name}.env.enc"

if [[ ! -f "$ciphertext" ]]; then
  echo "missing $ciphertext; create it with: just edit $name" >&2
  exit 1
fi

python3 scripts/validate-env.py
cat <<EOF
Validated $ciphertext without printing values.

Promotion is intentionally not automatic. A reviewed operator workflow must:
  1. decrypt the SOPS bundle in memory;
  2. write only the approved runtime subset to Fiducia KV keys under
     k8s/file-tunnel/<workload>/<ENV_VAR>;
  3. keep Cloudflare and Supabase deployment-only credentials out of pods;
  4. verify ExternalSecret Ready conditions without printing Secret data;
  5. record provider/project identifiers and checksums, never values.
EOF
