#!/bin/bash
# run_bedrock-aws-profiles-setup.sh — Runs on every `chezmoi apply`
# Ensures the bedrock-access AWS profiles (user/secondary/tertiary/quaternary/
# quinary) exist in ~/.aws with their IAM keys (+ region for the Bedrock ones).
# Secrets are pulled from Bitwarden at apply time, NEVER stored in this repo.
# No-op on steady state: a cheap `aws configure get` probe runs first, and
# Bitwarden is only touched when a profile is actually missing.

set -euo pipefail

REGION="us-east-1"
# All profiles this script manages.
ALL_PROFILES=(
    bedrock-access-user
    bedrock-access-secondary
    bedrock-access-tertiary
    bedrock-access-quaternary
    bedrock-access-quinary
)
# Only these get region=us-east-1 pinned. bedrock-access-user intentionally
# keeps NO region (pi=us-west-2 / codex=us-east-2 / settings.json set it per-use).
REGION_PROFILES=(
    bedrock-access-secondary
    bedrock-access-tertiary
    bedrock-access-quaternary
    bedrock-access-quinary
)

in_list() {
    # in_list <needle> <haystack...>
    local needle="$1"; shift
    local item
    for item in "$@"; do
        [ "$item" = "$needle" ] && return 0
    done
    return 1
}

# ── Guard clauses ────────────────────────────────────────────────────

if ! command -v aws &>/dev/null; then
    echo "[bedrock-aws] aws CLI not found on PATH, skipping"
    exit 0
fi

# ── Cheap probe: which profiles are missing a key? (no bw needed) ─────

MISSING=()
for p in "${ALL_PROFILES[@]}"; do
    if ! aws configure get aws_access_key_id --profile "$p" &>/dev/null; then
        MISSING+=("$p")
    fi
done

# Ensure region is set for the Bedrock profiles that DO already exist
# (also cheap; only writes when the value differs).
for p in "${REGION_PROFILES[@]}"; do
    if in_list "$p" "${MISSING[@]:-}"; then
        continue  # will be handled after fetching below
    fi
    if [ "$(aws configure get region --profile "$p" 2>/dev/null || true)" != "$REGION" ]; then
        aws configure set region "$REGION" --profile "$p"
        echo "[bedrock-aws] set region=$REGION for $p"
    fi
done

if [ ${#MISSING[@]} -eq 0 ]; then
    echo "[bedrock-aws] all profiles present, nothing to fetch"
    exit 0
fi

# ── We need Bitwarden. Guard bw + jq + an unlocked vault. ────────────

if ! command -v bw &>/dev/null; then
    echo "[bedrock-aws] bw not installed; missing profiles: ${MISSING[*]}"
    echo "[bedrock-aws] install it (npm install -g @bitwarden/cli), then: bwu && chezmoi apply"
    exit 0
fi

if ! command -v jq &>/dev/null; then
    echo "[bedrock-aws] jq not found on PATH, skipping (missing: ${MISSING[*]})"
    exit 0
fi

if [ -z "${BW_SESSION:-}" ] || [ "$(bw status 2>/dev/null | jq -r '.status' 2>/dev/null)" != "unlocked" ]; then
    echo "[bedrock-aws] Bitwarden locked or BW_SESSION unset; missing: ${MISSING[*]}"
    echo "[bedrock-aws] run: bwu && chezmoi apply"
    exit 0
fi

# ── Populate each missing profile from Bitwarden ─────────────────────

for p in "${MISSING[@]}"; do
    AKID="$(bw get username "$p" 2>/dev/null || true)"
    SECRET="$(bw get password "$p" 2>/dev/null || true)"
    if [ -z "$AKID" ] || [ -z "$SECRET" ]; then
        echo "[bedrock-aws] WARNING: could not fetch $p from Bitwarden (continuing)"
        continue
    fi
    aws configure set aws_access_key_id     "$AKID"   --profile "$p"
    aws configure set aws_secret_access_key "$SECRET" --profile "$p"
    if in_list "$p" "${REGION_PROFILES[@]}"; then
        aws configure set region "$REGION" --profile "$p"
    fi
    echo "[bedrock-aws] configured $p"
done

echo "[bedrock-aws] Done"
exit 0
