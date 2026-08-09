#!/usr/bin/env bash
set -euo pipefail

python3 scripts/validate-env.py
python3 scripts/check-supabase-migrations.py

for path in argocd/apps kubernetes/foundation kubernetes/backend kubernetes/portal; do
  kustomize build "$path" >/dev/null
done

# These checks are deliberately credential-free. Provider mutations belong to
# protected deployment environments after a reviewed plan has been attached.
python3 - <<'PY'
import tomllib
from pathlib import Path

for path in (Path("cloudflare/projects.toml"), Path("supabase/config.toml")):
    tomllib.loads(path.read_text())
    print(f"parsed {path}")
PY

echo "GitOps plan valid; no provider or cluster mutation was attempted."
