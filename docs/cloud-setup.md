# Claude Code Cloud Setup

Claude Code cloud sessions can work directly from this GitHub repository. Keep personal data out of Git.

## Required protected environment variables

- `INTERVALS_ICU_API_KEY`
- `INTERVALS_ICU_ATHLETE_ID`

Optional:

- `ATHLETE_PROFILE_B64`: base64-encoded contents of `training/profile.local.yaml`

Generate the optional profile value locally with:

```bash
./scripts/export-cloud-profile.sh
```

Treat the output as private athlete data. Store it only in a protected cloud environment variable/secret.

## Setup command

Use this repository setup command in the Claude Code cloud environment:

```bash
./scripts/cloud-setup.sh
```

The cloud sandbox needs outbound package access to PyPI for the pinned MCP package (`pypi.org` / `files.pythonhosted.org`) unless the package is already cached in the environment.

The project MCP configuration is committed in `.mcp.json`; secrets are referenced only through environment placeholders.
