# Contributing

1. Never commit `.env`, `training/*.local.yaml`, exported athlete data, FIT files or screenshots containing personal metrics.
2. Run `./scripts/ci-local.sh` before opening a pull request.
3. Keep GitHub Actions pinned to full 40-character commit SHAs.
4. Keep the Intervals.icu MCP pinned to an exact version.
5. Do not weaken `INTERVALS_ICU_DELETE_MODE=safe` in the public template.
6. Changes to coaching rules should preserve the distinction between cycling and running intensity zones.
