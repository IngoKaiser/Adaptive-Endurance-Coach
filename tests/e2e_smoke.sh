#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Copy without .git so the test checks runtime setup, not repository metadata.
tar -C "$ROOT" --exclude=.git --exclude=.env --exclude='training/*.local.yaml' -cf - . | tar -C "$TMP" -xf -
cd "$TMP"

export NON_INTERACTIVE=1
export SKIP_NETWORK_CHECK=1
export SKIP_UVX_CHECK=1
export INTERVALS_ICU_API_KEY="ci_dummy_key_123456"
export INTERVALS_ICU_ATHLETE_ID="i123456"
./scripts/setup.sh >/tmp/adaptive-endurance-setup.log

[ -f .env ]
[ -f training/profile.local.yaml ]
[ "$(stat -c '%a' .env)" = "600" ]

grep -q '^INTERVALS_ICU_API_KEY=ci_dummy_key_123456$' .env
! grep -R --exclude=.env --exclude='*.local.yaml' -q 'ci_dummy_key_123456' .

REQUIRE_CLAUDE=0 REQUIRE_UVX=0 ./scripts/doctor.sh >/tmp/adaptive-endurance-doctor.log
