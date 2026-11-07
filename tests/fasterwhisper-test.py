import importlib.util
import pathlib
import subprocess
import tempfile
import unittest
from unittest.mock import patch

ROOT = pathlib.Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('transcribe', ROOT / 'fasterwhisper/transcribe.py')
app = importlib.util.module_from_spec(spec)
spec.loader.exec_module(app)


class FasterWhisperTests(unittest.TestCase):
    def test_default_does_not_listen(self):
        result = subprocess.run(['python3', str(ROOT / 'fasterwhisper/transcribe.py')], capture_output=True, text=True)
        self.assertEqual(result.returncode, 2)
        self.assertIn('--listen', result.stderr)

    def test_help_does_not_load_model(self):
        result = subprocess.run(['python3', str(ROOT / 'fasterwhisper/transcribe.py'), '--help'], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0)
        self.assertIn('--file', result.stdout)

    def test_default_monitor_follows_output(self):
        with patch.object(app, 'pulse', side_effect=['1\tspeaker.monitor\tmodule', 'speaker']):
            self.assertEqual(app.resolve_source(None), 'speaker.monitor')

    def test_rejects_microphone_and_unknown_source(self):
        for source in ['microphone', 'missing.monitor']:
            with self.subTest(source=source), patch.object(app, 'pulse', return_value='1\tspeaker.monitor\tmodule'):
                with self.assertRaises(ValueError):
                    app.resolve_source(source)

    def test_explicit_monitor(self):
        with patch.object(app, 'pulse', return_value='1\tusb.monitor\tmodule'):
            self.assertEqual(app.resolve_source('usb.monitor'), 'usb.monitor')

    def test_installer_preview_and_help_preserve_home(self):
        import os
        with tempfile.TemporaryDirectory() as home:
            env = dict(os.environ, HOME=home, XDG_DATA_HOME=home + '/data')
            for args in [[], ['--help']]:
                result = subprocess.run(['bash', str(ROOT / 'fasterwhisper.sh'), *args], env=env, capture_output=True, text=True)
                self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(list(pathlib.Path(home).iterdir()), [])

    def test_installer_rejects_unknown_arguments(self):
        result = subprocess.run(['bash', str(ROOT / 'fasterwhisper.sh'), '--wrong'], capture_output=True, text=True)
        self.assertEqual(result.returncode, 2)

    def test_rejects_inapplicable_options_before_loading(self):
        for args in [
            ['--sources', '--source', 'missing.monitor'],
            ['--file', 'example.wav', '--source', 'microphone'],
            ['--check', '--language', 'es'],
            ['--sources', '--language', 'en'],
        ]:
            with self.subTest(args=args):
                result = subprocess.run(['python3', str(ROOT / 'fasterwhisper/transcribe.py'), *args], capture_output=True, text=True)
                self.assertEqual(result.returncode, 2)
                self.assertEqual(result.stdout, '')

    def test_bad_download_preserves_home_and_allows_retry(self):
        import os
        with tempfile.TemporaryDirectory() as directory:
            home = pathlib.Path(directory)
            binaries = home / 'bin'
            binaries.mkdir()
            for name, script in {
                'python3': 'exit 0', 'pactl': 'exit 0', 'parec': 'exit 99',
                'uname': "echo 'Linux x86_64'",
                'curl': 'while [ "$1" != "-o" ]; do shift; done; printf invalid > "$2"',
            }.items():
                target = binaries / name
                target.write_text('#!/bin/sh\n' + script + '\n')
                target.chmod(0o755)
            env = dict(os.environ, HOME=directory, TMPDIR=directory,
                       XDG_DATA_HOME=str(home / 'data'), XDG_CACHE_HOME=str(home / 'cache'),
                       PATH=str(binaries) + ':' + os.environ['PATH'])
            before = sorted(str(p.relative_to(home)) for p in home.rglob('*'))
            for _ in range(2):
                result = subprocess.run(['bash', str(ROOT / 'fasterwhisper.sh'), '--apply'], env=env, capture_output=True, text=True)
                self.assertEqual(result.returncode, 1)
                self.assertIn('checksum', result.stderr)
                self.assertEqual(before, sorted(str(p.relative_to(home)) for p in home.rglob('*')))


if __name__ == '__main__':
    unittest.main()
