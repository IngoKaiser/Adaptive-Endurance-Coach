#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
status=0

if command -v python3 >/dev/null 2>&1; then
  echo "OK: python3 -> $(command -v python3)"
else
  echo "MISSING: python3"
  status=1
fi

if [ "${REQUIRE_UVX:-1}" = "1" ]; then
  if command -v uvx >/dev/null 2>&1; then echo "OK: uvx -> $(command -v uvx)"; else echo "MISSING: uvx"; status=1; fi
fi

if [ "${REQUIRE_CLAUDE:-1}" = "1" ]; then
  if command -v claude >/dev/null 2>&1; then echo "OK: claude -> $(command -v claude)"; else echo "MISSING: claude"; status=1; fi
fi

if [ -f .env ]; then
  echo "OK: .env exists"
  set -a
  # shellcheck disable=SC1091
  . ./.env
  set +a
  [ -n "${INTERVALS_ICU_API_KEY:-}" ] || { echo "MISSING: API key"; status=1; }
  [ -n "${INTERVALS_ICU_ATHLETE_ID:-}" ] || { echo "MISSING: Athlete ID"; status=1; }
else
  echo "MISSING: .env"
  status=1
fi

if [ -f training/profile.local.yaml ]; then
  echo "OK: personal profile exists and is gitignored"
else
  echo "INFO: no personal profile; public template will be used only as schema"
fi

python3 scripts/validate_project.py --public-tree || status=1
exit "$status"
