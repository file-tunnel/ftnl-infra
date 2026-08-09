# File Tunnel infrastructure tasks. Secret-file mechanics are delegated to
# ores-sops so the implementation stays consistent with the wider fleet.

set shell := ["bash", "-euo", "pipefail", "-c"]
set dotenv-load := false

_default:
    @just --list --unsorted

# Decrypt env/enc/<name>.env.enc into ignored env/dec and activate ./.env.
use name:
    @ores-sops use {{ name }}

# Show encrypted/decrypted environment state without printing secret values.
status:
    @ores-sops status

# Edit SOPS ciphertext in place. Plaintext is held by the editor process.
edit name:
    @ores-sops edit {{ name }}

# Encrypt an ignored env/dec/<name>.env after local editing.
encrypt name:
    @ores-sops encrypt {{ name }}

# Show which keys changed without exposing their values.
diff name:
    @ores-sops diff {{ name }}

# Refresh the active ignored plaintext environment after a pull.
refresh:
    @ores-sops refresh

# Remove ignored plaintext and the root .env link.
lock:
    @ores-sops lock

# Validate ownership, tracked-file hygiene, manifests, workflows, and plans.
check:
    @agent-check

# Produce credential-free Cloudflare and Supabase deployment plans.
gitops-plan:
    @./scripts/gitops-plan.sh

# Print the exact reviewed promotion boundary; it does not mutate providers.
promote-secrets name="prod":
    @./scripts/promote-secrets.sh {{ name }}
