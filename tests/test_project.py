import json
import pathlib
import re
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]


class ProjectConfigTests(unittest.TestCase):
    def test_mcp_uses_safe_wrapper_and_env_placeholders(self):
        cfg = json.loads((ROOT / ".mcp.json").read_text())
        server = cfg["mcpServers"]["intervals-icu"]
        self.assertEqual(server["command"], "./scripts/run-mcp.sh")
        self.assertEqual(server["env"]["INTERVALS_ICU_DELETE_MODE"], "safe")
        self.assertEqual(server["env"]["INTERVALS_ICU_API_KEY"], "${INTERVALS_ICU_API_KEY}")

    def test_mcp_dependency_is_exactly_pinned(self):
        spec = (ROOT / "requirements-mcp.txt").read_text().strip()
        self.assertRegex(spec, r"^intervals-icu-mcp==\d+\.\d+\.\d+$")

    def test_personal_profile_is_ignored(self):
        ignore = (ROOT / ".gitignore").read_text()
        self.assertIn("training/*.local.yaml", ignore)
        self.assertNotIn("277", (ROOT / "training/profile.example.yaml").read_text())

    def test_multisport_rules_cover_running_and_outdoor_cycling(self):
        rules = (ROOT / "training/coaching-rules.md").read_text().lower()
        self.assertIn("running", rules)
        self.assertIn("outdoor cycling", rules)
        self.assertIn("avoid consecutive hard days", rules)

    def test_strava_is_canonical_completed_activity_aggregator(self):
        flow = (ROOT / "docs/data-flow.md").read_text().lower()
        profile = (ROOT / "training/profile.example.yaml").read_text().lower()
        self.assertIn("strava is the single upstream", flow)
        self.assertIn("garmin/wahoo/mywhoosh -> strava -> intervals.icu", profile)
        self.assertIn('completed_activity_aggregator: "strava"', profile)

    def test_activity_flow_checks_propagation_and_freshness(self):
        flow = (ROOT / "docs/data-flow.md").read_text().lower()
        rules = (ROOT / "training/coaching-rules.md").read_text().lower()
        self.assertIn("one-time propagation check", flow)
        self.assertIn("planning freshness gate", flow)
        self.assertIn("running", flow)
        self.assertIn("outdoor cycling", flow)
        self.assertIn("mywhoosh", flow)
        self.assertIn("one canonical ingestion path", rules)

    def test_direct_source_credentials_are_not_required(self):
        profile = (ROOT / "training/profile.example.yaml").read_text().lower()
        env = (ROOT / ".env.example").read_text().lower()
        self.assertIn("direct_source_credentials_in_coach: false", profile)
        self.assertNotIn("strava_client_secret", env)
        self.assertNotIn("garmin_password", env)
        self.assertNotIn("wahoo_password", env)
        self.assertNotIn("mywhoosh_password", env)

    def test_wellness_boundary_is_explicit(self):
        flow = (ROOT / "docs/data-flow.md").read_text().lower()
        self.assertIn("wellness-data boundary", flow)
        self.assertIn("resting hr", flow)
        self.assertIn("hrv", flow)
        self.assertIn("remain unknown rather than guessed", flow)

    def test_no_hardcoded_api_key_in_mcp_json(self):
        text = (ROOT / ".mcp.json").read_text()
        self.assertNotRegex(text, r'INTERVALS_ICU_API_KEY"\s*:\s*"(?!\$\{)')


if __name__ == "__main__":
    unittest.main()
