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

if [ "${REQUIRE_UVX:-1}" = "1" ] && command -v uvx >/dev/null 2>&1 && [ -n "${INTERVALS_ICU_API_KEY:-}" ]; then
  bundle="$HOME/.config/zscaler/ca-bundle.pem"
  if [ -n "${SSL_CERT_FILE:-}" ]; then
    echo "INFO: SSL_CERT_FILE=$SSL_CERT_FILE"
  elif [ -f "$bundle" ]; then
    echo "INFO: SSL_CERT_FILE unset in this shell; testing with $bundle"
    export SSL_CERT_FILE="$bundle"
  fi
  if [ -n "${SSL_CERT_FILE:-}" ] && [ -n "$(find "$SSL_CERT_FILE" -mtime +90 2>/dev/null)" ]; then
    echo "WARN: CA bundle older than 90 days; rerun scripts/build-ca-bundle.sh"
  fi
  # The key is read from the environment, never passed on the command line.
  uvx --from "$(head -n 1 requirements-mcp.txt)" python - <<'PY' || status=1
import os, ssl, httpx
url = f"https://intervals.icu/api/v1/athlete/{os.environ.get('INTERVALS_ICU_ATHLETE_ID', '0')}"
try:
    r = httpx.get(url, auth=("API_KEY", os.environ["INTERVALS_ICU_API_KEY"]), timeout=15)
except httpx.ConnectError as e:
    if isinstance(e.__cause__, ssl.SSLCertVerificationError) or "CERTIFICATE_VERIFY_FAILED" in str(e):
        print("FAIL: TLS certificate not trusted (proxy?). Run scripts/build-ca-bundle.sh and set SSL_CERT_FILE.")
    else:
        print(f"FAIL: cannot connect to intervals.icu: {e}")
    raise SystemExit(1)
if r.status_code == 200:
    print("OK: intervals.icu API reachable and authenticated")
elif r.status_code in (401, 403):
    print(f"FAIL: TLS OK, but API rejected credentials (HTTP {r.status_code})")
    raise SystemExit(1)
else:
    print(f"FAIL: unexpected HTTP {r.status_code} from intervals.icu")
    raise SystemExit(1)
PY
fi

if [ -f training/profile.local.yaml ]; then
  echo "OK: personal profile exists and is gitignored"
else
  echo "INFO: no personal profile; public template will be used only as schema"
fi

python3 scripts/validate_project.py --public-tree || status=1
exit "$status"
