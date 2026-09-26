#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

REPO_NAME="${1:-adaptive-endurance-coach}"

command -v gh >/dev/null 2>&1 || { echo "ERROR: GitHub CLI (gh) is required." >&2; exit 1; }
gh auth status >/dev/null 2>&1 || { echo "ERROR: Authenticate first with: gh auth login" >&2; exit 1; }

./scripts/ci-local.sh

for sensitive in .env training/profile.local.yaml training/baseline.local.yaml CLAUDE.local.md; do
  if git ls-files --error-unmatch "$sensitive" >/dev/null 2>&1; then
    echo "ERROR: $sensitive is tracked. Refusing to publish." >&2
    exit 1
  fi
done

LOGIN="$(gh api user --jq .login)"
OWNER="${GITHUB_OWNER:-$LOGIN}"
CODEOWNER="${GITHUB_CODEOWNER:-$LOGIN}"
SLUG="${OWNER}/${REPO_NAME}"

if ! git config user.name >/dev/null 2>&1; then git config user.name "$LOGIN"; fi
if ! git config user.email >/dev/null 2>&1; then git config user.email "${LOGIN}@users.noreply.github.com"; fi

if grep -q '@YOUR_GITHUB_USERNAME' .github/CODEOWNERS; then
  python3 - "$CODEOWNER" <<'PY'
from pathlib import Path
import sys
p = Path('.github/CODEOWNERS')
p.write_text(p.read_text().replace('@YOUR_GITHUB_USERNAME', '@' + sys.argv[1]))
PY
fi

# Ensure the first commit contains the complete validated public tree.
git add -A
if ! git rev-parse --verify HEAD >/dev/null 2>&1; then
  git commit -m "feat: initial adaptive endurance coach"
elif ! git diff --cached --quiet; then
  git commit -m "chore: prepare public repository"
fi

if git remote get-url origin >/dev/null 2>&1; then
  echo "ERROR: origin already exists; refusing to create a second repository." >&2
  exit 1
fi

if gh repo view "$SLUG" >/dev/null 2>&1; then
  echo "ERROR: GitHub repository $SLUG already exists." >&2
  exit 1
fi

gh repo create "$SLUG" --public --source=. --remote=origin --push \
  --description "Security-conscious Claude Code endurance coach using Intervals.icu"

API_VERSION="2026-03-10"
api() {
  gh api -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: $API_VERSION" "$@"
}

# Repository defaults: reduce attack surface and enable native security controls.
api --method PATCH "repos/$SLUG" \
  -F has_wiki=false \
  -F has_projects=false \
  -F delete_branch_on_merge=true \
  -f 'security_and_analysis[secret_scanning][status]=enabled' \
  -f 'security_and_analysis[secret_scanning_push_protection][status]=enabled' >/dev/null

api --method PUT "repos/$SLUG/actions/permissions/workflow" \
  -f default_workflow_permissions=read \
  -F can_approve_pull_request_reviews=false >/dev/null

api --method PUT "repos/$SLUG/vulnerability-alerts" >/dev/null
api --method PUT "repos/$SLUG/automated-security-fixes" >/dev/null || true
api --method PUT "repos/$SLUG/private-vulnerability-reporting" >/dev/null || true

# Useful discovery metadata; failure here is non-security-critical.
gh repo edit "$SLUG" --add-topic claude-code --add-topic intervals-icu --add-topic cycling --add-topic running --add-topic mcp >/dev/null 2>&1 || true

cat <<OUT
Published: https://github.com/$SLUG
Native secret scanning + push protection requested.
GitHub Actions default token permission set to read-only; Actions PR approvals disabled.

Wait for the first CI/Security run to complete, then run:
  ./scripts/harden-github.sh $SLUG
OUT
