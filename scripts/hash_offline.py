#!/usr/bin/env python3
import json
import hashlib
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MANIFEST = ROOT / 'offline' / 'manifest.json'


def sha256_file(p: Path) -> str:
    h = hashlib.sha256()
    with p.open('rb') as f:
        for chunk in iter(lambda: f.read(8192), b''):
            h.update(chunk)
    return h.hexdigest()


def main():
    if not MANIFEST.exists():
        raise SystemExit(f"Manifest not found: {MANIFEST}")

    data = json.loads(MANIFEST.read_text(encoding='utf-8'))
    hashes = data.setdefault('hashes', {})

    files = []
    content = data.get('content', {})
    for k, rel in content.items():
        files.append(rel)
    media = data.get('media', {})
    for group in media.values():
        files.extend(group)

    updated = 0
    for rel in files:
        p = ROOT / rel
        if p.exists():
            digest = sha256_file(p)
            if hashes.get(rel) != digest:
                hashes[rel] = digest
                updated += 1
        else:
            # leave placeholder as-is
            pass

    if updated:
        MANIFEST.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding='utf-8')
        print(f"Updated {updated} hash entries")
    else:
        print("No changes")


if __name__ == '__main__':
    main()