# GitHub Publication & Hardening

This repository is designed to be public. Personal athlete data and credentials must remain outside Git.

## One-command publication

Prerequisites:

- GitHub CLI (`gh`)
- `gh auth login` completed with permission to create repositories and manage repository settings

From the repository root:

```bash
./scripts/publish-github.sh adaptive-endurance-coach
```

The script:

1. runs local validation, unit tests, shell checks and the E2E bootstrap smoke test;
2. resolves the authenticated GitHub user and replaces the CODEOWNERS placeholder;
3. refuses publication if `.env`, `training/profile.local.yaml` or `CLAUDE.local.md` is tracked;
4. creates a **public** GitHub repository and pushes `main`;
5. enables GitHub secret scanning and push protection;
6. sets GitHub Actions' default token permission to read-only and prevents Actions from approving pull requests;
7. disables the unused wiki/projects features and enables delete-branch-on-merge.

If publishing to an organization, set `GITHUB_OWNER`. If CODEOWNERS should point to a different user, set `GITHUB_CODEOWNER`.

```bash
GITHUB_OWNER=my-org GITHUB_CODEOWNER=my-user ./scripts/publish-github.sh adaptive-endurance-coach
```

## Branch protection

GitHub requires required-status-check contexts to exist before they are useful as protection rules. After the first `CI` and `Security` workflows have completed successfully on `main`, run:

```bash
./scripts/harden-github.sh OWNER/adaptive-endurance-coach
```

It protects `main` by requiring the core CI/security-policy checks to be current, requiring linear history and conversation resolution, and preventing force-pushes/deletion.

For a solo personal project, the script does **not** require an approving review. If collaborators are added later, consider a GitHub ruleset requiring pull requests and at least one independent approval.

## Security model

### Secrets

Never commit:

- `INTERVALS_ICU_API_KEY`
- `INTERVALS_ICU_ATHLETE_ID` when it is treated as private account metadata
- athlete health/performance baselines
- personal availability/calendar details
- Garmin, Strava, Wahoo or MyWhoosh credentials

Use Claude Code Cloud / GitHub protected secrets or local `.env` files instead.

### CI exposure

CI deliberately uses no real athlete credentials. Pull-request workflows can therefore run against untrusted contributions without exposing an Intervals.icu account. There is no live-account E2E test in GitHub Actions.

### Supply chain

All GitHub Actions are pinned to immutable full commit SHAs. The Intervals.icu MCP package is pinned exactly in `requirements-mcp.txt`. Dependabot proposes updates; `pip-audit` checks Python dependencies weekly; CodeQL scans repository Python and workflow code.

### MCP network boundary

The Intervals.icu MCP is launched as a local/Claude-session `stdio` process. Do not expose the community MCP's HTTP transport directly to the public internet without adding a separate authenticated gateway.
