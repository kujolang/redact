#!/usr/bin/env python3
"""Synthetic filesystem regressions; bounded subprocesses prevent FIFO hangs."""
from concurrent.futures import ThreadPoolExecutor
import json
import os
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parent.parent
KUJO = os.environ.get("KUJO_BIN", str(ROOT.parent / "kujo/target/release/kujo"))


def run(*args):
    return subprocess.run([KUJO, "run", "redact.kujo", *map(str, args)], cwd=ROOT,
                          capture_output=True, text=True, timeout=20)


with tempfile.TemporaryDirectory(prefix="redact-hardening-") as tmp:
    base = Path(tmp).resolve()
    source = base / "source.md"
    source.write_text("synthetic@example.org\n", encoding="utf-8")
    outside = base / "outside"
    outside.mkdir()
    audit = base / "audit"
    audit.mkdir()
    (audit / "runs").symlink_to(outside, target_is_directory=True)
    result = run("scan", source, "--audit-dir", audit)
    assert result.returncode == 1 and "symbolic links" in result.stdout, result.stdout
    assert not list(outside.iterdir()), "audit escaped through runs symlink"

    link = base / "link\\name.md"
    link.symlink_to(source)
    result = run("scan", link, "--audit-dir", base / "link-audit")
    assert result.returncode == 1 and "symbolic links" in result.stdout, result.stdout
    assert not (base / "link-audit").exists()

    # A real POSIX backslash filename remains supported; check actual spelling.
    regular = base / "regular\\name.md"
    regular.write_text("ordinary text", encoding="utf-8")
    result = run("scan", regular, "--audit-dir", base / "regular-audit")
    assert result.returncode == 0, result.stdout
    assert json.loads(result.stdout)["detections"] == 0

    for target in ("input", "policy", "output"):
        fifo = base / (target + ".md")
        os.mkfifo(fifo)
        args = ["sanitize", source, "--out", base / "result.md", "--audit-dir", base / (target + "-audit")]
        if target == "input":
            args[1] = fifo
        elif target == "policy":
            args.extend(["--policy", fifo])
        else:
            args[3] = fifo
        result = run(*args)
        assert result.returncode == 1 and "regular file" in result.stdout, (target, result.stdout)
        assert fifo.is_fifo(), "special output file was replaced"

    named_policy = base / "named.yaml"
    named_policy.write_text('schemaVersion: redact-policy/v1\nname: "true"\n', encoding="utf-8")
    result = run("scan", source, "--policy", named_policy, "--audit-dir", base / "named-audit")
    assert result.returncode == 0, result.stdout
    named_receipt = json.loads(result.stdout)
    assert named_receipt["policy"] == "true"
    snapshot = (Path(named_receipt["audit_dir"]) / "policy.snapshot.yaml").read_text()
    assert 'name: "true"\n' in snapshot, "snapshot changed a string name into YAML boolean"

    expanded = base / "expansion.md"
    expanded.write_text("x" * 300, encoding="utf-8")
    policy = base / "expansion.yaml"
    policy.write_text("schemaVersion: redact-policy/v1\nname: expansion\nperson_names: role-preserve\nterms:\n  person_names:\n    - x\nroles:\n  x: " + "🚀" * 2000 + "\n", encoding="utf-8")
    preserved = base / "preserved.md"
    preserved.write_text("previous output", encoding="utf-8")
    result = run("sanitize", expanded, "--policy", policy, "--out", preserved,
                 "--audit-dir", base / "expansion-audit")
    assert result.returncode == 1 and "2097152-byte" in result.stdout, result.stdout
    assert preserved.read_text() == "previous output", "failed expansion replaced output"

    def scan_once(_):
        result = run("scan", source, "--audit-dir", base / "concurrent-audit")
        assert result.returncode == 0, result.stdout
        return Path(json.loads(result.stdout)["audit_dir"])

    with ThreadPoolExecutor(max_workers=4) as pool:
        runs = list(pool.map(scan_once, range(4)))
    assert len(set(runs)) == 4, "concurrent scans shared a run"
    for directory in runs:
        assert json.loads((directory / "run.json").read_text())["command"] == "scan"
        for line in (directory / "detections.jsonl").read_text().splitlines():
            assert "original" not in json.loads(line), "concurrent default audit leaked raw value"

print("Hardening filesystem, expansion, and concurrent audit contracts passed")
