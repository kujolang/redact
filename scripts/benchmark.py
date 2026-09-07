#!/usr/bin/env python3
"""Offline, synthetic sanitize benchmark; timings are evidence, not CI gates."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import statistics
import subprocess
import tempfile
import time

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--repo", type=Path, default=Path(__file__).resolve().parent.parent)
parser.add_argument("--workload", choices=["emails", "dictionary"], default="emails")
parser.add_argument("--samples", type=int, default=3)
parser.add_argument("--emails", type=int, default=100)
args = parser.parse_args()
if not 1 <= args.samples <= 20 or not 1 <= args.emails <= 1000:
    parser.error("samples must be 1..20 and emails 1..1000")
repo = args.repo.resolve()
kujo = os.environ.get("KUJO_BIN", str(repo.parent / "kujo/target/release/kujo"))
measurements = []
hashes = set()
with tempfile.TemporaryDirectory(prefix="redact-benchmark-") as tmp:
    root = Path(tmp).resolve()
    source = root / "synthetic.md"
    policy = "basic"
    text = "".join(f"member{i}@example.org\n" for i in range(args.emails))
    expected_detections = args.emails + 1
    if args.workload == "dictionary":
        text = "ordinary note. " * 500 + "SyntheticPerson\n"
        policy = str(root / "policy.yaml")
        Path(policy).write_text("schemaVersion: redact-policy/v1\nname: benchmark\nterms:\n  person_names:\n    - SyntheticPerson\n    - AbsentPerson\n", encoding="utf-8")
        expected_detections = 1
    source.write_text(text, encoding="utf-8")
    for i in range(args.samples):
        output = root / f"output-{i}.md"
        start = time.perf_counter()
        result = subprocess.run([kujo, "run", "redact.kujo", "sanitize", str(source),
                                 "--policy", policy, "--out", str(output),
                                 "--audit-dir", str(root / f"audit-{i}")],
                                cwd=repo, capture_output=True, text=True, timeout=120)
        elapsed = time.perf_counter() - start
        if result.returncode:
            raise RuntimeError(result.stdout + result.stderr)
        receipt = json.loads(result.stdout)
        assert receipt["detections"] == expected_detections, receipt
        assert receipt["risk_score"] == "low", receipt
        data = output.read_bytes()
        hashes.add(hashlib.sha256(data).hexdigest())
        measurements.append(elapsed)
    assert len(hashes) == 1, "nondeterministic output"
    print(json.dumps({"workload": args.workload, "emails": args.emails if args.workload == "emails" else 0,
                      "input_bytes": source.stat().st_size, "output_bytes": len(data),
                      "runtime": subprocess.check_output([kujo, "--version"], text=True).strip(),
                      "samples_seconds": measurements, "median_seconds": statistics.median(measurements),
                      "output_sha256": next(iter(hashes))}, indent=2))
