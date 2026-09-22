#!/usr/bin/env python3
"""Read-only reconciliation of interrupted pack publication audit intents."""

import argparse
import hashlib
import json
import os
from pathlib import Path
import stat

MAX_OUTPUT = 2_097_152
MAX_MANIFEST = 16_384


def bounded_regular(path, limit):
    if path.is_symlink():
        raise ValueError("symbolic links are not reconciliation inputs")
    flags = os.O_RDONLY | getattr(os, "O_BINARY", 0) | getattr(os, "O_NOFOLLOW", 0)
    descriptor = os.open(path, flags)
    try:
        if not stat.S_ISREG(os.fstat(descriptor).st_mode):
            raise ValueError("not a regular file")
        data = os.read(descriptor, limit + 1)
        if len(data) > limit:
            raise ValueError("file exceeds reconciliation limit")
        return data
    finally:
        os.close(descriptor)


def manifest(path):
    return json.loads(bounded_regular(path, MAX_MANIFEST))


def classify(run):
    intent = manifest(run / "pack-publication.json")
    if (intent.get("schemaVersion") != "redact-pack-publication/v1"
            or intent.get("status") not in ("pending", "published")):
        return "needs_review"
    target = Path(intent["output_path"])
    if target.is_symlink() or not target.is_file():
        return "not_published" if intent.get("status") == "pending" else "needs_review"
    try:
        data = bounded_regular(target, MAX_OUTPUT)
    except (OSError, ValueError):
        return "needs_review"
    digest = hashlib.sha256(data).hexdigest()
    if digest != intent.get("content_hash") or len(data.decode("utf-8")) != intent.get("length"):
        return "needs_review"
    if intent["status"] == "pending":
        # A colliding pre-existing directory can have the same bytes. The
        # pending intent alone cannot prove Redact published this output.
        return "matching_pending"
    try:
        output = manifest(run / "output-manifest.json")
        hashes = manifest(run / "hashes.json")
    except (OSError, ValueError, json.JSONDecodeError):
        return "recoverable_published"
    if (output.get("output_path") != str(target) or output.get("length") != len(data.decode("utf-8"))
            or output.get("content_hash") != digest or hashes.get("output") != digest):
        return "needs_review"
    return "complete"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--audit-dir", required=True, type=Path)
    parser.add_argument("--json", action="store_true", help="include run paths (sensitive metadata)")
    args = parser.parse_args()
    runs = args.audit_dir / "runs"
    if runs.is_symlink() or not runs.is_dir():
        parser.error("audit runs directory must exist and not be a symlink")
    results = []
    for run in sorted(runs.iterdir()):
        if run.is_symlink() or not run.is_dir() or not (run / "pack-publication.json").exists():
            continue
        try:
            status = classify(run)
        except (OSError, ValueError, UnicodeError, KeyError, TypeError, json.JSONDecodeError):
            status = "needs_review"
        results.append({"run": run.name, "status": status})
    counts = {key: sum(result["status"] == key for result in results)
              for key in ("complete", "matching_pending", "recoverable_published", "not_published", "needs_review")}
    print(json.dumps({"schemaVersion": "redact-pack-reconciliation/v1", "counts": counts,
                      **({"runs": results} if args.json else {})}, sort_keys=True))
    return 1 if counts["needs_review"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
