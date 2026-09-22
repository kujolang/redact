#!/usr/bin/env python3
"""Synthetic, read-only pack-audit reconciliation contracts."""

import hashlib
import importlib.util
import json
from pathlib import Path
import tempfile

ROOT = Path(__file__).resolve().parent.parent
spec = importlib.util.spec_from_file_location("reconcile_pack", ROOT / "scripts/reconcile-pack-audits.py")
reconcile = importlib.util.module_from_spec(spec)
spec.loader.exec_module(reconcile)

with tempfile.TemporaryDirectory(prefix="redact-reconcile-tests-") as temp:
    directory = Path(temp)
    run = directory / "audit" / "runs" / "synthetic-run"
    run.mkdir(parents=True)
    output = directory / "member.txt"
    output.write_text("synthetic member", encoding="utf-8")
    digest = hashlib.sha256(output.read_bytes()).hexdigest()
    intent = {"schemaVersion": "redact-pack-publication/v1", "status": "pending",
              "output_path": str(output), "content_hash": digest, "length": 16}
    path = run / "pack-publication.json"
    path.write_text(json.dumps(intent), encoding="utf-8")
    assert reconcile.classify(run) == "matching_pending", "matching bytes cannot prove publish"
    assert output.read_text(encoding="utf-8") == "synthetic member"
    intent["status"] = "published"
    path.write_text(json.dumps(intent), encoding="utf-8")
    assert reconcile.classify(run) == "recoverable_published"
    (run / "output-manifest.json").write_text(json.dumps({"output_path": str(output),
        "content_hash": digest, "length": 16}), encoding="utf-8")
    (run / "hashes.json").write_text(json.dumps({"output": digest}), encoding="utf-8")
    assert reconcile.classify(run) == "complete"
    output.write_text("changed member", encoding="utf-8")
    assert reconcile.classify(run) == "needs_review"
    assert output.read_text(encoding="utf-8") == "changed member", "reconciliation changed output"

print("Pack audit reconciliation contracts passed")
