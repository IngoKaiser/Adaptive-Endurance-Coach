#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SPEC_FILE="$ROOT/requirements-mcp.txt"
ENV_FILE="$ROOT/.env"

if [ -z "${INTERVALS_ICU_API_KEY:-}" ] && [ -f "$ENV_FILE" ]; then
  set -a
  # shellcheck disable=SC1090
  . "$ENV_FILE"
  set +a
fi

if ! command -v uvx >/dev/null 2>&1; then
  echo "uvx is required. Install uv first: https://docs.astral.sh/uv/" >&2
  exit 127
fi

if [ ! -f "$SPEC_FILE" ]; then
  echo "Missing $SPEC_FILE" >&2
  exit 2
fi

SPEC="$(grep -E '^intervals-icu-mcp==[0-9]+\.[0-9]+\.[0-9]+$' "$SPEC_FILE" | head -n 1 || true)"
if [ -z "$SPEC" ]; then
  echo "requirements-mcp.txt must pin intervals-icu-mcp to an exact version." >&2
  exit 2
fi

exec uvx --from "$SPEC" intervals-icu-mcp "$@"
