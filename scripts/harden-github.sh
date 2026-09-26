#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
command -v gh >/dev/null 2>&1 || { echo "ERROR: GitHub CLI (gh) is required." >&2; exit 1; }
gh auth status >/dev/null 2>&1 || { echo "ERROR: Authenticate first with: gh auth login" >&2; exit 1; }

if [[ $# -gt 0 ]]; then
  REPO="$1"
else
  REPO="$(gh repo view --json nameWithOwner --jq .nameWithOwner)"
fi

API_VERSION="2026-03-10"
TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

# Configure only checks that run on every PR, including fork PRs. CodeQL is
# intentionally not required because its SARIF-write job is skipped for forks.
cat > "$TMP" <<'JSON'
{
  "required_status_checks": {
    "strict": true,
    "contexts": [
      "Validate & Unit Tests",
      "End-to-End Smoke",
      "Repository Policy",
      "Workflow Security",
      "Dependency Review"
    ]
  },
  "enforce_admins": false,
  "required_pull_request_reviews": null,
  "restrictions": null,
  "required_linear_history": true,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "block_creations": false,
  "required_conversation_resolution": true,
  "lock_branch": false,
  "allow_fork_syncing": true
}
JSON

gh api \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: $API_VERSION" \
  --method PUT "repos/$REPO/branches/main/protection" \
  --input "$TMP" >/dev/null

cat <<OUT
Branch protection applied to $REPO:main
Required checks:
- Validate & Unit Tests
- End-to-End Smoke
- Repository Policy
- Workflow Security
- Dependency Review
OUT
