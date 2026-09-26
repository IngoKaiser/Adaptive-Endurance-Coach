#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
python3 scripts/validate_project.py --public-tree
python3 -m unittest discover -s tests -p 'test_*.py' -v
bash -n start.sh scripts/*.sh tests/*.sh
if command -v shellcheck >/dev/null 2>&1; then
  shellcheck start.sh scripts/*.sh tests/*.sh
else
  echo "INFO: shellcheck not installed; CI will run it."
fi
./tests/e2e_smoke.sh
