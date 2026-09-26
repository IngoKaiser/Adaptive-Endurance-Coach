# Publishing and GitHub Hardening

This repository is designed to be public. Personal athlete data and credentials must remain outside Git.

## Publish

Prerequisites: GitHub CLI (`gh`) installed and authenticated.

```bash
./scripts/publish-github.sh adaptive-endurance-coach
```

The script runs the local CI suite before creating a public repository and refuses to publish if the worktree contains tracked local-profile/secret files.

## Repository settings after the first CI run

In **Settings -> Code security and analysis / Advanced Security**, keep these enabled for the public repository:

- Dependency graph
- Dependabot alerts
- Dependabot security updates
- Secret scanning
- Push protection
- Code scanning / CodeQL
- Private vulnerability reporting

Public repositories currently receive GitHub secret scanning/push protection and CodeQL capabilities without requiring secrets in Actions.

## Main branch protection

After the initial push has produced the workflow checks, create a ruleset for `main`:

- block force pushes and deletion;
- require a pull request before merge for collaborative changes;
- require the `validate` and `e2e-smoke` CI jobs;
- require branches to be up to date before merge;
- do not allow bypass except repository administration when genuinely needed.

For a one-person repository, required approving reviews are optional; mandatory CI is the important control.

## Public repository threat model

Pull requests from forks can execute repository test code on GitHub-hosted runners. Therefore:

- CI never receives Intervals.icu or athlete secrets;
- no `pull_request_target` workflow is allowed;
- checkout credentials are not persisted;
- workflow permissions are explicit and minimal;
- live API end-to-end tests are not run on pull requests;
- external Actions are pinned to immutable full commit SHAs.

## Live integration test

A real Garmin/Wahoo -> aggregator -> Intervals.icu propagation test uses private athlete data and therefore remains a manual acceptance test documented in `docs/data-flow.md`, not a public CI test.
