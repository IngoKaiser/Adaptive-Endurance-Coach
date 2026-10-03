#!/usr/bin/env bash
# Builds a CA bundle for TLS-intercepting proxies (e.g. Zscaler): the certifi
# roots used by the pinned MCP plus the proxy root CA from the macOS keychain.
# Because it is a superset of certifi, it also works off the corporate network.
# Point SSL_CERT_FILE at the output (see README, "Corporate TLS proxy").
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SPEC="$(head -n 1 "$ROOT/requirements-mcp.txt")"
OUT="${CA_BUNDLE_PATH:-$HOME/.config/zscaler/ca-bundle.pem}"
CA_NAME="${PROXY_CA_NAME:-Zscaler}"

if ! command -v security >/dev/null 2>&1; then
  echo "This script reads the proxy CA from the macOS keychain; 'security' not found." >&2
  exit 2
fi

proxy_pem="$(security find-certificate -a -c "$CA_NAME" -p 2>/dev/null || true)"
proxy_count="$(printf '%s\n' "$proxy_pem" | grep -c 'BEGIN CERTIFICATE' || true)"
if [ "$proxy_count" -eq 0 ]; then
  echo "No certificate matching '$CA_NAME' found in the keychain search list." >&2
  exit 1
fi

certifi_path="$(uvx --from "$SPEC" python -c 'import certifi; print(certifi.where())')"

mkdir -p "$(dirname "$OUT")"
tmp="$(mktemp "$OUT.XXXXXX")"
{ cat "$certifi_path"; printf '\n%s\n' "$proxy_pem"; } > "$tmp"
chmod 644 "$tmp"
mv "$tmp" "$OUT"

echo "Wrote $OUT (certifi + $proxy_count '$CA_NAME' certificate(s))."
