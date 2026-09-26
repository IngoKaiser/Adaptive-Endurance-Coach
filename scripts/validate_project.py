#!/usr/bin/env python3
"""Zero-dependency repository security and consistency checks."""
from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FULL_SHA = re.compile(r"^[0-9a-f]{40}$")
USES_RE = re.compile(r"^\s*-?\s*uses:\s*([^\s#]+)", re.MULTILINE)
SENSITIVE_TRACKED = {
    ".env",
    "training/profile.local.yaml",
    "training/baseline.local.yaml",
    "CLAUDE.local.md",
}


def fail(msg: str) -> None:
    print(f"ERROR: {msg}", file=sys.stderr)
    raise SystemExit(1)


def tracked_files() -> list[str]:
    try:
        out = subprocess.check_output(["git", "ls-files"], cwd=ROOT, text=True, stderr=subprocess.DEVNULL)
    except (subprocess.CalledProcessError, FileNotFoundError):
        return []
    return [x for x in out.splitlines() if x]


def check_sensitive_files_not_tracked(files: list[str]) -> None:
    bad = sorted(SENSITIVE_TRACKED.intersection(files))
    if bad:
        fail(f"sensitive/local files are tracked: {', '.join(bad)}")


def check_mcp_config() -> None:
    cfg = json.loads((ROOT / ".mcp.json").read_text())
    server = cfg["mcpServers"]["intervals-icu"]
    if server.get("command") != "./scripts/run-mcp.sh":
        fail(".mcp.json must invoke the pinned wrapper scripts/run-mcp.sh")
    env = server.get("env", {})
    if env.get("INTERVALS_ICU_API_KEY") != "${INTERVALS_ICU_API_KEY}":
        fail("API key must be an environment placeholder")
    if env.get("INTERVALS_ICU_ATHLETE_ID") != "${INTERVALS_ICU_ATHLETE_ID}":
        fail("athlete ID must be an environment placeholder")
    if env.get("INTERVALS_ICU_DELETE_MODE") != "safe":
        fail("delete mode must remain safe")


def check_data_flow_policy() -> None:
    flow = (ROOT / "docs/data-flow.md").read_text().lower()
    rules = (ROOT / "training/coaching-rules.md").read_text().lower()
    for required in ("intervals.icu", "strava", "running", "outdoor cycling", "mywhoosh"):
        if required not in flow:
            fail(f"data flow must cover {required}")
    if "strava is the single upstream" not in flow:
        fail("Strava must remain the canonical completed-activity aggregator")
    if "planning freshness gate" not in flow:
        fail("data flow must define a planning freshness gate")
    if "one-time" not in flow or "propagation" not in flow:
        fail("data flow must document the one-time propagation verification")
    if "one canonical ingestion path" not in rules:
        fail("coaching rules must prevent duplicate activity ingestion")


def check_dependency_pin() -> None:
    text = (ROOT / "requirements-mcp.txt").read_text().strip()
    if not re.fullmatch(r"intervals-icu-mcp==\d+\.\d+\.\d+", text):
        fail("requirements-mcp.txt must contain one exact intervals-icu-mcp version pin")


def check_workflows() -> None:
    for path in sorted((ROOT / ".github/workflows").glob("*.y*ml")):
        text = path.read_text()
        if "pull_request_target:" in text:
            fail(f"{path.relative_to(ROOT)} uses pull_request_target")
        for use in USES_RE.findall(text):
            if use.startswith("./"):
                continue
            if "@" not in use:
                fail(f"unversioned action in {path.relative_to(ROOT)}: {use}")
            ref = use.rsplit("@", 1)[1]
            if not FULL_SHA.fullmatch(ref):
                fail(f"action is not pinned to a full commit SHA in {path.relative_to(ROOT)}: {use}")
        if "permissions:" not in text:
            fail(f"workflow lacks explicit permissions: {path.relative_to(ROOT)}")
        if "actions/checkout@" in text and "persist-credentials: false" not in text:
            fail(f"checkout must disable persisted credentials: {path.relative_to(ROOT)}")


def check_literal_secrets(files: list[str]) -> None:
    # Deliberately narrow to avoid false positives from immutable action SHAs
    # and shell parameter checks such as ${INTERVALS_ICU_API_KEY:?message}.
    assignment_patterns = [
        re.compile(r"^\s*INTERVALS_ICU_API_KEY\s*=\s*[\"']?([^\s\"']+)", re.MULTILINE),
        re.compile(r"[\"']INTERVALS_ICU_API_KEY[\"']\s*:\s*[\"']([^\"']+)[\"']"),
    ]
    allowed = {"replace_me", "${INTERVALS_ICU_API_KEY}", "your-api-key-here", "your_api_key_here"}
    for rel in files:
        path = ROOT / rel
        if not path.is_file() or path.stat().st_size > 1_000_000:
            continue
        try:
            text = path.read_text(errors="strict")
        except (UnicodeDecodeError, OSError):
            continue
        for pattern in assignment_patterns:
            for match in pattern.finditer(text):
                value = match.group(1).strip()
                if value not in allowed and not value.startswith("$"):
                    fail(f"possible Intervals.icu API key committed in {rel}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--public-tree", action="store_true", help="validate the public/trackable repository tree")
    parser.parse_args()
    files = tracked_files()
    check_sensitive_files_not_tracked(files)
    check_mcp_config()
    check_data_flow_policy()
    check_dependency_pin()
    check_workflows()
    check_literal_secrets(files)
    print("Repository validation: OK")


if __name__ == "__main__":
    main()
