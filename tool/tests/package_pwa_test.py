import importlib.util
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('package_pwa', ROOT / 'tool/package_pwa.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

class PackagePwaTest(unittest.TestCase):
    def test_complete_release_is_reproducible_and_uses_integrity_hashes(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            for name in ['index.html', 'flutter_bootstrap.js', 'main.dart.js', 'manifest.json', 'pwa-client.js']:
                (root / name).write_text('<html><head></head></html>' if name == 'index.html' else '{}')
            (root / 'canvaskit').mkdir()
            (root / 'canvaskit/canvaskit.wasm').write_bytes(b'renderer')
            template = ROOT / 'web/pwa-worker.js'
            first = module.package(root, template)
            self.assertEqual(first, module.package(root, template))
            self.assertIn('colmeia-release', (root / 'index.html').read_text())
            self.assertNotIn('__PWA_FILES__', (root / 'pwa-worker.js').read_text())
            (root / 'main.dart.js').write_text('changed')
            self.assertNotEqual(first['version'], module.package(root, template)['version'])
    def test_incomplete_release_is_rejected(self):
        with tempfile.TemporaryDirectory() as folder:
            with self.assertRaises(ValueError):
                module.package(Path(folder), ROOT / 'web/pwa-worker.js')

if __name__ == '__main__':
    unittest.main()
