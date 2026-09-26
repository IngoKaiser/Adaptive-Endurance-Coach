#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# Claude Code cloud should provide INTERVALS_ICU_API_KEY and
# INTERVALS_ICU_ATHLETE_ID as protected environment secrets.
: "${INTERVALS_ICU_API_KEY:?Set INTERVALS_ICU_API_KEY as a cloud secret}"
: "${INTERVALS_ICU_ATHLETE_ID:?Set INTERVALS_ICU_ATHLETE_ID as a cloud secret}"

if [ -n "${ATHLETE_PROFILE_B64:-}" ]; then
  umask 077
  printf '%s' "$ATHLETE_PROFILE_B64" | base64 --decode > training/profile.local.yaml
  chmod 600 training/profile.local.yaml
fi

if ! command -v uvx >/dev/null 2>&1; then
  echo "uvx is not installed in this cloud image. Install uv in the cloud environment setup before starting the session." >&2
  exit 127
fi

python3 scripts/validate_project.py --public-tree
