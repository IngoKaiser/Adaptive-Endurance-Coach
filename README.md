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

Prerequisites: Claude Code, `uv`/`uvx`, Intervals.icu athlete ID + API key.

```bash
./scripts/setup.sh
```

Then edit:

```text
training/profile.local.yaml
```

Connect MyWhoosh to Intervals.icu through MyWhoosh's normal Connections flow; no MyWhoosh password belongs in this project.

Start:

```bash
./start.sh
```

Inside Claude Code verify `/mcp`, then use `/plan-week`, `/today`, `/reschedule` or `/review-week`.

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

## Publishing

After creating a public GitHub repository, replace `@YOUR_GITHUB_USERNAME` in `.github/CODEOWNERS`, enable branch/ruleset protection for `main`, require the `CI` checks, and keep secret scanning/push protection enabled.

## Disclaimer

This is a personal training-planning automation project, not medical software. Wearable metrics are contextual training inputs, not diagnoses.
