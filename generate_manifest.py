#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
generate_manifest.py
====================
Regenerate `manifest.json` for the jihati-content repository.

It scans the `jihati/` folder, computes a SHA-256 hash and byte size for
every `*.json` file, and writes a fresh manifest. Run this every time you
change any content file so the manifest always stays consistent.

Usage
-----
    python generate_manifest.py                  # auto-increment contentVersion
    python generate_manifest.py --version 5      # set contentVersion explicitly
    python generate_manifest.py --base-url "https://cdn.jsdelivr.net/gh/USER/jihati-content@content-v5/"

Notes
-----
- Files whose name contains "copy" are treated as drafts and skipped.
- Run from the repository root (the folder that contains `manifest.json`).
"""

import argparse
import datetime
import hashlib
import json
import os

ROOT = os.path.dirname(os.path.abspath(__file__))
CONTENT_DIR = "jihati"
MANIFEST_PATH = os.path.join(ROOT, "manifest.json")


def sha256_of(path: str) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(8192), b""):
            h.update(chunk)
    return h.hexdigest()


def collect_files() -> list:
    base = os.path.join(ROOT, CONTENT_DIR)
    items = []
    for name in sorted(os.listdir(base)):
        if not name.endswith(".json"):
            continue
        if "copy" in name.lower():  # skip drafts
            continue
        full = os.path.join(base, name)
        items.append({
            "path": f"{CONTENT_DIR}/{name}",
            "sha256": sha256_of(full),
            "bytes": os.path.getsize(full),
        })
    items.sort(key=lambda x: x["path"])
    return items


def current_version() -> int:
    if os.path.exists(MANIFEST_PATH):
        try:
            with open(MANIFEST_PATH, encoding="utf-8") as f:
                return int(json.load(f).get("contentVersion", 0))
        except Exception:
            return 0
    return 0


def main():
    ap = argparse.ArgumentParser(description="Regenerate manifest.json")
    ap.add_argument("--version", type=int, default=None,
                    help="contentVersion (default: previous + 1)")
    ap.add_argument("--base-url", type=str, default=None,
                    help="Override baseUrl (jsDelivr/CDN). Keeps previous if omitted.")
    args = ap.parse_args()

    prev_base = None
    if os.path.exists(MANIFEST_PATH):
        try:
            with open(MANIFEST_PATH, encoding="utf-8") as f:
                prev_base = json.load(f).get("baseUrl")
        except Exception:
            prev_base = None

    version = args.version if args.version is not None else current_version() + 1
    base_url = args.base_url or prev_base or \
        "https://cdn.jsdelivr.net/gh/USERNAME/jihati-content@content-v1/"

    files = collect_files()
    manifest = {
        "contentVersion": version,
        "generatedAt": datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%S"),
        "baseUrl": base_url,
        "fileCount": len(files),
        "files": files,
    }
    with open(MANIFEST_PATH, "w", encoding="utf-8") as w:
        json.dump(manifest, w, ensure_ascii=False, indent=2)
        w.write("\n")

    print(f"manifest.json updated -> contentVersion={version}, fileCount={len(files)}")
    print(f"baseUrl: {base_url}")


if __name__ == "__main__":
    main()
