#!/usr/bin/env python3
"""Exercise real public checks using bounded, in-memory hostile changes."""
import json
import unittest
from unittest.mock import patch
import check_public_surface as gate

FILES = gate.collect()


class PublicSurfaceTests(unittest.TestCase):
    def test_clean_graph(self):
        self.assertEqual(gate.surface_errors(FILES), [])

    def reject(self, mutate, expected):
        files = dict(FILES)
        mutate(files)
        self.assertTrue(any(expected in item for item in gate.surface_errors(files)), expected)

    def test_original_private_name_text(self):
        sentinel = 'synthetic-private-token'
        with patch.object(gate, 'FORBIDDEN_HASHES', gate.FORBIDDEN_HASHES | {gate.digest(sentinel.encode())}):
            self.reject(lambda f: f.update({'README.md': f['README.md'] + b'\n' + sentinel.encode()}), 'private name in text')

    def test_original_private_name_path(self):
        sentinel = 'synthetic-private-token'
        with patch.object(gate, 'FORBIDDEN_HASHES', gate.FORBIDDEN_HASHES | {gate.digest(sentinel.encode())}):
            self.reject(lambda f: f.update({sentinel + '.md': b'example'}), 'private name in path')

    def test_original_private_name_set_removed(self):
        with patch.object(gate, 'FORBIDDEN_HASHES', set()):
            self.assertTrue(any('original private-name patterns' in x for x in gate.surface_errors(FILES)))

    def test_internal_path(self):
        self.reject(lambda f: f.update({'Tests/' + 'p' + 'd999-example.swift': b'example'}), 'internal identifier in path')

    def test_internal_content(self):
        self.reject(lambda f: f.update({'README.md': f['README.md'] + b'\n' + b'P' + b'D999 note'}), 'internal identifier in text')

    def test_private_coordination_file(self):
        self.reject(lambda f: f.update({'WORKLOG.md': b'coordination'}), 'private coordination file')

    def test_machine_path(self):
        self.reject(lambda f: f.update({'README.md': f['README.md'] + b'\n/' + b'Users/example/private/'}), 'private machine path')

    def test_nonascii_machine_path(self):
        self.reject(lambda f: f.update({'README.md': f['README.md'] + ('\n/' + 'Users/测试用户/private/').encode()}), 'private machine path')

    def test_private_temporary_path(self):
        self.reject(lambda f: f.update({'README.md': f['README.md'] + b'\n/private/' + b'tmp/kdna-fixture'}), 'private machine path')

    def test_placeholder_identity(self):
        self.reject(lambda f: f.update({'README.md': f['README.md'] + b'\nAuthor <test@' + b'example.invalid>'}), 'placeholder identity')

    def test_owned_generation_label(self):
        self.reject(lambda f: f.update({'README.md': f['README.md'] + b'\nKDNA-' + b'v' + b'9'}), 'owned generation label')

    def test_platform_exception_is_narrow(self):
        self.reject(lambda f: f.update({'Package.swift': f['Package.swift'] + b'\nlet label = "' + b'v' + b'9"'}), 'owned generation label')

    def test_frozen_source_change(self):
        key = 'Sources/KDNAAppShared/ReadPresentation.swift'
        self.reject(lambda f: f.update({key: f[key] + b'\n// changed'}), 'frozen native bytes differ')

    def test_frozen_binary_change(self):
        key = 'Tests/KDNAAppSharedTests/Fixtures/Components/full-trio.kdna'
        self.reject(lambda f: f.update({key: f[key] + b'x'}), 'frozen native bytes differ')

    def test_missing_fixture(self):
        key = 'Tests/KDNAAppSharedTests/Fixtures/Components/full-trio.kdna'
        self.reject(lambda f: f.pop(key), 'frozen native input inventory differs')

    def test_history_missing(self):
        self.reject(lambda f: f.pop('retired/README.md'), 'historical bytes differ')

    def test_local_dependency(self):
        self.reject(lambda f: f.update({'Package.swift': f['Package.swift'].replace(b'url:', b'path:')}), 'public package must pin the exact remote Core revision')

    def test_moving_dependency(self):
        self.reject(lambda f: f.update({'Package.swift': f['Package.swift'].replace(b'revision:', b'branch:')}), 'public package must pin the exact remote Core revision')

    def test_lockfile_mismatch(self):
        self.reject(lambda f: f.update({'Package.resolved': b'{"pins":[],"version":2}'}), 'resolved Core input must match')

    def test_retired_api_reenabled(self):
        self.reject(lambda f: f.update({'Package.swift': f['Package.swift'].replace(b'exclude: ["AuthorizationPresentation.swift"]', b'exclude: []')}), 'retired authorization surfaces must stay excluded')

    def test_missing_ci_entry(self):
        key = '.github/workflows/ci.yml'
        self.reject(lambda f: f.update({key: f[key].replace(b'python3 scripts/verify_native.py', b'echo skipped')}), 'CI must execute python3 scripts/verify_native.py')

    def test_missing_ios(self):
        key = '.github/workflows/ci.yml'
        self.reject(lambda f: f.update({key: f[key].replace(b' --ios', b'')}), 'CI must retain generic iOS compilation')

    def test_changed_context(self):
        key = '.github/workflows/ci.yml'
        self.reject(lambda f: f.update({key: f[key].replace(b'  build:', b'  replacement:')}), 'required build context must remain unchanged')

    def test_partial_tests(self):
        key = 'scripts/verify_native.py'
        self.reject(lambda f: f.update({key: f[key].replace(b"['swift', 'test'", b"['swift', 'test', '--filter', 'ReadPresentationTests'")}), 'native verification must run the complete suite')

    def test_missing_test_command(self):
        key = 'scripts/verify_native.py'
        self.reject(lambda f: f.update({key: f[key].replace(b"['swift', 'test'", b"['echo', 'test'")}), 'native verification must execute swift test')

    def test_missing_release_consumer(self):
        key = 'scripts/verify_native.py'
        self.reject(lambda f: f.update({key: f[key].replace(b"['debug', 'release']", b"['debug']")}), 'consumer must run in debug and release')

    def test_negative_compile_cannot_succeed(self):
        key = 'scripts/verify_native.py'
        self.reject(lambda f: f.update({key: f[key].replace(b'result.returncode == 0', b'result.returncode == 999')}), 'retired API compilation must fail')

    def test_no_body_copy_assertion_required(self):
        key = 'scripts/verify_native.py'
        self.reject(lambda f: f.update({key: f[key].replace(b'precondition(object[key] == nil)', b'print(key)')}), 'consumer must check the public no-body-copy boundary')


if __name__ == '__main__':
    unittest.main(verbosity=2)
