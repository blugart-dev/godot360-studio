"""Regression checks for source/privacy/link/provenance failures before publication."""
import hashlib
import json
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
from repository_review import review


class RepositoryReviewChecks(unittest.TestCase):
    def check_files(self, files):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            for name, content in files.items():
                path = root / name
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_bytes(content if isinstance(content, bytes) else content.encode())
            return review(root, list(files))

    def test_portable_links_and_code_examples(self):
        result = self.check_files({'README.md': '# Read me\n[Guide](docs/guide.md#setup)\n'
                                  '```sh\n[example](missing.md)\n```\n`[inline](missing.md)`\n',
                                  'docs/guide.md': '# Setup\n[Home](../README.md#read-me)\n'})
        self.assertTrue(result['ok'], result['issues'])
        self.assertEqual(result['local_links_checked'], 2)

    def test_missing_public_file_even_if_it_exists_locally(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            (root / 'README.md').write_text('[Local](private.md)')
            (root / 'private.md').write_text('ignored local file')
            self.assertFalse(review(root, ['README.md'])['ok'])

    def test_missing_anchor_and_wrong_case(self):
        result = self.check_files({'README.md': '[A](guide.md#missing) [B](Guide.md)',
                                  'guide.md': '# Setup\n'})
        self.assertEqual(len(result['issues']), 2)

    def test_private_paths_and_credentials_are_redacted(self):
        private = 'C:' + '/Users/' + 'example-person/project/file'
        credential = 'gh' + 'p_' + 'a' * 36
        result = self.check_files({'README.md': private + '\n' + credential})
        self.assertEqual(len(result['issues']), 2)
        serialized = json.dumps(result)
        self.assertNotIn(private, serialized)
        self.assertNotIn(credential, serialized)

    def test_provenance_rejects_changed_media(self):
        original = b'original test image'
        manifest = json.dumps({'files': {'still.jpg': {'bytes': len(original),
                              'sha256': hashlib.sha256(original).hexdigest()}}})
        result = self.check_files({'docs/media/still.jpg': b'changed test image',
                                  'docs/media/provenance.json': manifest})
        self.assertFalse(result['ok'])
        self.assertEqual(result['media_hashes_checked'], 1)

    def test_local_files_and_invalid_source(self):
        result = self.check_files({'.godot360/settings.cfg': 'private=true\n',
                                  'tools/broken.py': 'def broken(',
                                  'orphan.gd.uid': 'uid://abc123\n'})
        self.assertEqual(len(result['issues']), 3)

    def test_resource_case_must_match(self):
        result = self.check_files({'scene.tscn': '[ext_resource path="res://Code.gd"]',
                                  'code.gd': 'extends Node\n'})
        self.assertFalse(result['ok'])


if __name__ == '__main__':
    unittest.main()
