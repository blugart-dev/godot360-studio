"""Prevent mislabelled release artifacts and drifting product version strings."""
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))
from package_addon import package_readme, release_label, release_version


class PackageReleaseChecks(unittest.TestCase):
    def fixture(self, root, version, label):
        addon = root / "addons/godot360"
        addon.mkdir(parents=True)
        files = {
            "plugin.cfg": '[plugin]\nversion="' + version + '"\n',
            "spherical_metadata.gd": 'const SOFTWARE = "Godot360 Studio ' + version + '"\n',
            "studio_layout.gd": 'credit.tooltip_text = "Godot360 Studio · ' + label + '"\n',
            "README.md": '**Version ' + version + ' — release information.**\n',
        }
        for name, text in files.items():
            (addon / name).write_text(text, encoding="utf-8")
        return addon

    def test_development_candidate_and_stable_identity(self):
        for version, label in [("0.8.0", "Development version 0.8.0"),
                               ("1.0.0-rc.1", "Release candidate 1.0.0-rc.1"),
                               ("1.0.0", "Version 1.0.0")]:
            with self.subTest(version=version), tempfile.TemporaryDirectory() as temp:
                root = Path(temp)
                self.fixture(root, version, label)
                self.assertEqual(release_version(root), version)

    def test_artifact_status_matches_release_channel(self):
        development = package_readme("0.8.0")
        candidate = package_readme("1.0.0-rc.1")
        stable = package_readme("1.0.0")
        self.assertIn("pre-1.0 development build", development)
        self.assertIn("Release candidate 1.0.0-rc.1", candidate)
        self.assertIn("Stable release acceptance is pending", candidate)
        self.assertNotIn("development build", candidate)
        self.assertIn("Godot360 Studio 1.0.0.", stable)
        self.assertNotIn("candidate", stable)
        self.assertNotIn("development", stable)
        self.assertNotIn("{release_status}", stable)

    def test_reject_invalid_or_ambiguous_versions(self):
        for value in ["1.0", "01.0.0", "1.00.0", "1.0.00", "1.0.0-rc.0", "1.0.0-rc.01",
                      "1.0.0-rc", "1.0.0-rc.x", "1.0.0\n", "1.0.0/rc.1", "<1.0.0>"]:
            with self.subTest(version=value), self.assertRaises(AssertionError):
                release_label(value)

    def test_reject_duplicate_plugin_versions(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            addon = self.fixture(root, "1.0.0-rc.1", "Release candidate 1.0.0-rc.1")
            with (addon / "plugin.cfg").open("a", encoding="utf-8") as target:
                target.write('version="1.0.0"\n')
            with self.assertRaisesRegex(AssertionError, "Expected one"):
                release_version(root)

    def test_reject_metadata_panel_and_readme_drift(self):
        for name in ["spherical_metadata.gd", "studio_layout.gd", "README.md"]:
            with self.subTest(file=name), tempfile.TemporaryDirectory() as temp:
                root = Path(temp)
                addon = self.fixture(root, "1.0.0-rc.1", "Release candidate 1.0.0-rc.1")
                path = addon / name
                path.write_text(path.read_text(encoding="utf-8").replace("1.0.0-rc.1", "0.8.0"), encoding="utf-8")
                with self.assertRaises(AssertionError):
                    release_version(root)

    def test_reject_stable_label_on_candidate_panel(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            self.fixture(root, "1.0.0-rc.1", "Version 1.0.0-rc.1")
            with self.assertRaisesRegex(AssertionError, "Panel version or release label"):
                release_version(root)


if __name__ == "__main__":
    unittest.main()
