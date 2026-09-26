#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [ "${SKIP_UVX_CHECK:-0}" != "1" ] && ! command -v uvx >/dev/null 2>&1; then
  echo "uv/uvx was not found. On macOS: brew install uv" >&2
  exit 1
fi

if [ "${NON_INTERACTIVE:-0}" = "1" ]; then
  ATHLETE_ID="${INTERVALS_ICU_ATHLETE_ID:-}"
  API_KEY="${INTERVALS_ICU_API_KEY:-}"
else
  printf "Intervals.icu Athlete ID (for example i123456): "
  read -r ATHLETE_ID
  printf "Intervals.icu API key (input hidden): "
  read -r -s API_KEY
  printf "\n"
fi

if [ -z "${ATHLETE_ID:-}" ] || [ -z "${API_KEY:-}" ]; then
  echo "Athlete ID and API key are required." >&2
  exit 1
fi

case "$ATHLETE_ID" in
  *[!A-Za-z0-9_-]*) echo "Athlete ID contains unexpected characters." >&2; exit 1 ;;
esac
case "$API_KEY" in
  *[!A-Za-z0-9._-]*) echo "API key contains unexpected characters." >&2; exit 1 ;;
esac

umask 077
cat > .env <<ENVEOF
INTERVALS_ICU_API_KEY=$API_KEY
INTERVALS_ICU_ATHLETE_ID=$ATHLETE_ID
ENVEOF
chmod 600 .env

if [ ! -f training/profile.local.yaml ]; then
  cp training/profile.example.yaml training/profile.local.yaml
  chmod 600 training/profile.local.yaml
fi

if [ "${SKIP_NETWORK_CHECK:-0}" != "1" ]; then
  echo "Checking pinned MCP package availability..."
  # This downloads only the public pinned package; no athlete credentials are sent.
  ./scripts/run-mcp.sh --help >/dev/null 2>&1 || true
fi

cat <<'OUT'
Setup complete.
- Personal credentials: .env (gitignored, mode 600)
- Personal training profile: training/profile.local.yaml (gitignored)
- Connect MyWhoosh to Intervals.icu separately; do not store MyWhoosh credentials here.
- Start local Claude Code with ./start.sh
OUT
