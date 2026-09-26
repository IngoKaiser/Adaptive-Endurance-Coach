#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

if [ ! -f .env ]; then
  echo "Missing .env. Run ./scripts/setup.sh first." >&2
  exit 1
fi

set -a
# shellcheck disable=SC1091
. ./.env
set +a

if [ -z "${INTERVALS_ICU_API_KEY:-}" ] || [ -z "${INTERVALS_ICU_ATHLETE_ID:-}" ]; then
  echo "Intervals.icu credentials are missing from .env." >&2
  exit 1
fi

exec claude
