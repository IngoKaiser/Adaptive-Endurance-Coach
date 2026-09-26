#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FILE="$ROOT/training/profile.local.yaml"
if [ ! -f "$FILE" ]; then
  echo "Missing training/profile.local.yaml. Run ./scripts/setup.sh first." >&2
  exit 1
fi
base64 < "$FILE" | tr -d '\n'
printf '\n'
