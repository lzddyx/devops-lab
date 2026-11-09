"""Offline regression cases. Run: python3 -m unittest discover -s deploy -p 'test_*.py'."""
import importlib.util
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location('verify_base_image', Path(__file__).with_name('verify-base-image.py'))
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
verify = module.verify

REFERENCE = 'public.ecr.aws/docker/library/eclipse-temurin@sha256:5bdb2989179defb8abd386a97b34407ebeccf9fdae11838576983254b5e8e5e2'
MANIFEST = REFERENCE.split('@')[1]
CONFIG = 'sha256:cd9edca13a4c03d1cacfde0cab66cdfbbcb44dcf1c7a1f3a5f800cc6e5c2b6ec'


class ImageVerificationTests(unittest.TestCase):
    def metadata(self, **changes):
        return dict({'Id': CONFIG, 'RepoDigests': [REFERENCE], 'Os': 'linux', 'Architecture': 'arm64'}, **changes)

    def test_classic_store(self):
        verify(self.metadata(), REFERENCE, CONFIG)

    def test_containerd_store(self):
        verify(self.metadata(Id=MANIFEST, Descriptor={'digest': MANIFEST}), REFERENCE, CONFIG)

    def test_null_descriptor(self):
        verify(self.metadata(Descriptor=None), REFERENCE, CONFIG)

    def test_reject_unverified_metadata(self):
        cases = {
            'unknown ID': {'Id': 'sha256:bad'},
            'wrong repository': {'RepoDigests': ['other@' + MANIFEST]},
            'wrong digest': {'RepoDigests': [REFERENCE[:-1] + '0']},
            'missing digest': {'RepoDigests': None},
            'wrong architecture': {'Architecture': 'amd64'},
            'wrong descriptor': {'Descriptor': {'digest': 'sha256:bad'}},
            'empty descriptor': {'Descriptor': {}},
            'malformed descriptor': {'Descriptor': 'bad'},
        }
        for name, changes in cases.items():
            with self.subTest(name=name), self.assertRaises(ValueError):
                verify(self.metadata(**changes), REFERENCE, CONFIG)


if __name__ == '__main__':
    unittest.main()
