# Adaptive Endurance Coach for Claude Code

A security-conscious Claude Code project for planning **indoor cycling, outdoor cycling and running** through **Intervals.icu**, with MyWhoosh used only to execute structured indoor bike workouts on a Wahoo KICKR.

## Architecture

```text
Garmin / Wahoo / MyWhoosh completed activities
                    |
                    v
                  Strava
                    |
                    v
              Intervals.icu <----> Claude Code
                    |
                    +-> planned cycling workouts -> MyWhoosh -> KICKR
```

**Strava is the single completed-activity aggregator. Intervals.icu is the coach-facing planning and analysis system of record.** Claude reads all endurance activities from Intervals.icu before adapting the plan, so a hard run or outdoor ride is not ignored when the next bike session is scheduled. Garmin, Wahoo, Strava and MyWhoosh passwords are never stored in the project.

A planning freshness gate checks recent Intervals.icu activity history before calendar changes. If the athlete reports a newer Strava activity that has not yet reached Intervals.icu, the coach treats the dataset as stale instead of assuming a rest day. See `docs/data-flow.md`.

## Public-repository privacy model

This repository is intentionally safe to publish **without personal athlete data**.

Tracked public files contain only templates and rules. These are gitignored and must stay private:

- `.env` — Intervals.icu credentials
- `training/profile.local.yaml` — FTP, HR baselines, device details, availability and personal preferences
- `CLAUDE.local.md` — optional private instructions

`training/profile.example.yaml` is only a public schema. Never put real API keys, passwords, health metrics or family/calendar details into tracked files.

## Local setup

Prerequisites: `uv`/`uvx`, Intervals.icu athlete ID + API key, and one Claude front end (see "Running the coach" below — the Claude Code CLI is only one option, not a requirement).

```bash
./scripts/setup.sh
```

Then edit:

```text
training/profile.local.yaml
```

Connect MyWhoosh to Intervals.icu through MyWhoosh's normal Connections flow; no MyWhoosh password belongs in this project.

`setup.sh` only writes `.env` and your local profile; it does not install or require any particular Claude front end.

## Running the coach

The project only needs something that can read `CLAUDE.md`, start the MCP server from `.mcp.json`, and run the skills in `.claude/skills/`. Pick whichever front end you have — no option is required over another.

### Option A: Claude Code CLI (terminal)

```bash
./start.sh
```

This execs `claude` in the project root, which loads `CLAUDE.md`, `.mcp.json` and the skills automatically.

### Option B: Claude Desktop app or claude.ai/code — no CLI install needed

1. Open this project folder as a project in the Claude Desktop app's Code tab, or in claude.ai/code.
2. Both read `CLAUDE.md` and `.mcp.json` the same way the CLI does: the `intervals-icu` MCP server starts from the committed config, and `.claude/skills/` provides the same `/plan-week`, `/today`, `/reschedule` and `/review-week` commands.
3. Make sure `.env` (created by `./scripts/setup.sh`) exists in that session's own project checkout before opening it, so the MCP server can read your Intervals.icu credentials.

**Each new Code-tab / claude.ai/code session may open its own git worktree**, not the same folder every time. `.env` and `training/profile.local.yaml` are gitignored and are *not* copied into a new worktree automatically, so the first time you use a new session/worktree, run `./scripts/setup.sh` there again (or copy the two files over) before expecting `intervals-icu` to connect with real credentials.

`scripts/doctor.sh` checks for the `claude` CLI binary by default; when running through the Desktop app or claude.ai/code instead, use `REQUIRE_CLAUDE=0 ./scripts/doctor.sh`.

Either way: verify `/mcp` first, then use `/plan-week`, `/today`, `/reschedule` or `/review-week`.

## Claude Code Cloud

Use the public GitHub repository with Claude Code cloud sessions. Put `INTERVALS_ICU_API_KEY` and `INTERVALS_ICU_ATHLETE_ID` in protected cloud environment variables. Optionally provide the personal profile as `ATHLETE_PROFILE_B64`.

See `docs/cloud-setup.md`.

## Security / CI

The repository includes:

- zero-dependency repository policy + secret checks;
- unit tests for MCP configuration, privacy boundaries and multisport rules;
- an end-to-end bootstrap smoke test using dummy credentials only;
- ShellCheck and shell syntax checks;
- CodeQL scanning for Python and GitHub Actions workflows;
- exact SHA pinning for all GitHub Actions;
- exact version pinning for the community `intervals-icu-mcp` dependency;
- weekly dependency auditing with `pip-audit`;
- Dependabot for GitHub Actions and Python dependency updates;
- minimal GitHub Actions permissions and `persist-credentials: false` on checkouts.

Run locally:

```bash
./scripts/ci-local.sh
```

No real Intervals.icu credentials are used in CI. Live API end-to-end tests are deliberately excluded from a public repository to avoid exposing athlete data or secrets to pull-request workflows.

## Baseline logic

The coach starts with observed data, not guessed heart-rate formulas. Resting HR, max HR and threshold HR may remain unknown during the initial baseline phase. Garmin-derived values may be supplied by the user when useful; running and cycling zones remain sport-specific.

See `training/initial-assessment.md`.

## MCP dependency

The project uses the community `intervals-icu-mcp` package and pins it in `requirements-mcp.txt`. `scripts/run-mcp.sh` executes exactly that pinned version with `INTERVALS_ICU_DELETE_MODE=safe` supplied by `.mcp.json`.

### Corporate TLS proxy (e.g. Zscaler)

Behind a TLS-intercepting proxy, MCP calls fail with `CERTIFICATE_VERIFY_FAILED` because Python's bundled `certifi` store does not contain the proxy's root CA. The proxy is a property of the machine, not of this project, so the fix lives at machine/user level and applies to every MCP launch path, worktree and project:

1. Build a CA bundle (certifi + proxy root CA from the macOS keychain) at `~/.config/zscaler/ca-bundle.pem`:
   `./scripts/build-ca-bundle.sh`
2. Add it to the `env` block of the user-level `~/.claude/settings.json`, so Claude Code passes it to every MCP server it starts:
   `"env": { "SSL_CERT_FILE": "/Users/<you>/.config/zscaler/ca-bundle.pem", "REQUESTS_CA_BUNDLE": "/Users/<you>/.config/zscaler/ca-bundle.pem" }`
3. Restart the Claude app and verify with `./scripts/doctor.sh`.

The bundle is a superset of certifi, so it also works off the corporate network. Rerun step 1 if the proxy rotates its root CA; `doctor.sh` reports TLS failures explicitly and warns when the bundle is older than 90 days. `run-mcp.sh` logs the CA bundle in use to stderr at startup.

## Publishing

After creating a public GitHub repository, replace `@YOUR_GITHUB_USERNAME` in `.github/CODEOWNERS`, enable branch/ruleset protection for `main`, require the `CI` checks, and keep secret scanning/push protection enabled.

## Disclaimer

This is a personal training-planning automation project, not medical software. Wearable metrics are contextual training inputs, not diagnoses.
