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

# Opt-in for networks with a TLS-intercepting corporate proxy (e.g. Zscaler),
# where Python's bundled certifi CA store does not trust the proxy's
# injected root certificate. Pinned separately from requirements-mcp.txt,
# which must contain only the intervals-icu-mcp pin (see
# scripts/validate_project.py). Set MCP_TRUST_SYSTEM_CERTS=1 in .env to
# enable; it makes Python trust the OS certificate store instead of certifi.
PIP_SYSTEM_CERTS_SPEC="pip-system-certs==5.3"
WITH_ARGS=()
if [ "${MCP_TRUST_SYSTEM_CERTS:-0}" = "1" ]; then
  WITH_ARGS=(--with "$PIP_SYSTEM_CERTS_SPEC")
fi

exec uvx --from "$SPEC" "${WITH_ARGS[@]}" intervals-icu-mcp "$@"
