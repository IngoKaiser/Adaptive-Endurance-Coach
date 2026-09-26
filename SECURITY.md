# Security Policy

## Scope

This repository contains public configuration and automation for an AI-assisted endurance-training workflow. It must never contain real athlete API keys, passwords, personal health metrics or private calendar details.

## Reporting

If you find a vulnerability, do not open a public issue containing credentials or private athlete data. Use GitHub's private vulnerability reporting feature if enabled, or contact the repository owner privately.

## Credential handling

- Intervals.icu credentials belong in `.env` locally or in protected Claude Code cloud environment secrets.
- `training/profile.local.yaml` contains personal athlete data and is gitignored.
- MyWhoosh credentials are not needed and must not be stored here.
- The MCP server stays in `INTERVALS_ICU_DELETE_MODE=safe`.
- If a secret is ever committed, revoke/rotate it immediately; deleting a Git commit is not sufficient protection by itself.

## Supply-chain controls

- GitHub Actions are pinned to full commit SHAs.
- The community Intervals.icu MCP dependency is pinned to an exact version in `requirements-mcp.txt`.
- Dependabot monitors GitHub Actions and the MCP package pin.
- Scheduled dependency auditing resolves and scans the MCP dependency graph.
- CodeQL scans Python and GitHub Actions workflows.

The Intervals.icu MCP used by this project is community software and is not an official Intervals.icu component.
