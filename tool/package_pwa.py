"""Package an existing Flutter release for offline installation (standard library only)."""
import argparse
import hashlib
import json
import re
from pathlib import Path

EXCLUDED = {"pwa-worker.js", "flutter_service_worker.js", "pwa-release.json", ".last_build_id"}

def package(root: Path, worker_template: Path) -> dict:
    root = root.resolve()
    required = ["index.html", "flutter_bootstrap.js", "main.dart.js", "manifest.json", "pwa-client.js"]
    for name in required:
        if not (root / name).is_file():
            raise ValueError(f"Missing release file: {name}")
    if not (root / "canvaskit").is_dir():
        raise ValueError("A local CanvasKit renderer is required")
    index_path = root / "index.html"
    index = re.sub(r'<meta name="colmeia-release" content="[a-f0-9]+">\n?', '', index_path.read_text(encoding="utf-8"))
    paths = sorted(p for p in root.rglob("*") if p.is_file() and p.name not in EXCLUDED and not p.name.endswith('.map'))
    for path in paths:
        if path.is_symlink() or not path.resolve().is_relative_to(root):
            raise ValueError("Release must not contain external links")
        if path.suffix in {'.env', '.pem', '.key'} and path.relative_to(root).as_posix() != 'assets/assets/env/default.env':
            raise ValueError(f"Unexpected private configuration in release: {path.name}")
    hashes = [(p.relative_to(root).as_posix(), hashlib.sha256(index.encode() if p == index_path else p.read_bytes()).hexdigest()) for p in paths]
    release = hashlib.sha256(json.dumps(hashes).encode() + worker_template.read_bytes()).hexdigest()[:20]
    index_path.write_text(index.replace('</head>', f'<meta name="colmeia-release" content="{release}">\n</head>'), encoding="utf-8")
    files = [{"url": p.relative_to(root).as_posix(), "sha256": hashlib.sha256(p.read_bytes()).hexdigest()} for p in paths]
    worker = worker_template.read_text(encoding="utf-8").replace("__PWA_RELEASE__", release).replace("__PWA_FILES__", json.dumps(files, separators=(',', ':')))
    (root / "pwa-worker.js").write_text(worker, encoding="utf-8")
    result = {"version": release, "files": len(files), "bytes": sum(p.stat().st_size for p in paths)}
    (root / "pwa-release.json").write_text(json.dumps(result, indent=2) + '\n', encoding="utf-8")
    return result

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--directory', type=Path, default=Path('build/web'))
    args = parser.parse_args()
    print(json.dumps(package(args.directory, Path(__file__).resolve().parents[1] / 'web/pwa-worker.js')))
