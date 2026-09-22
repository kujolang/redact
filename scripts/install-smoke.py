#!/usr/bin/env python3
"""Install-smoke the committed source archive with a verified Kujo 1.4 binary."""
import argparse
import hashlib
import os
from pathlib import Path
import platform
import subprocess
import sys
import tarfile
import tempfile
import zipfile

ROOT = Path(__file__).resolve().parent.parent
RELEASE = "v1.4.0"
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--benchmarks", action="store_true", help="log bounded synthetic cross-platform timings")
args = parser.parse_args()


def run(*args, cwd=ROOT, timeout=120):
    result = subprocess.run([str(arg) for arg in args], cwd=cwd,
                            capture_output=True, text=True, timeout=timeout)
    if result.returncode:
        raise RuntimeError(f"{' '.join(map(str, args[:3]))}: {result.stdout}{result.stderr}")
    return result.stdout


def safe_members(names):
    for name in names:
        parts = Path(name).parts
        if Path(name).is_absolute() or ".." in parts or not parts:
            raise RuntimeError(f"unsafe archive path: {name}")


def runtime(root):
    if os.environ.get("KUJO_BIN"):
        return Path(os.environ["KUJO_BIN"]).resolve()
    system = platform.system().lower()
    architecture = "arm64" if platform.machine().lower() in ("arm64", "aarch64") else "x64"
    if system not in ("darwin", "linux", "windows"):
        raise RuntimeError("unsupported install-smoke platform")
    system = "macos" if system == "darwin" else system
    suffix = "zip" if system == "windows" else "tar.gz"
    archive_name = f"kujo-{RELEASE}-{system}-{architecture}.{suffix}"
    run("gh", "release", "download", RELEASE, "-R", "kujolang/kujo", "-D", root,
        "-p", archive_name, "-p", archive_name + ".sha256", timeout=180)
    archive = root / archive_name
    expected = (root / (archive_name + ".sha256")).read_text().split()[0]
    if hashlib.sha256(archive.read_bytes()).hexdigest() != expected:
        raise RuntimeError("Kujo release archive checksum mismatch")
    unpacked = root / "runtime"
    unpacked.mkdir()
    if suffix == "zip":
        with zipfile.ZipFile(archive) as package:
            safe_members(package.namelist())
            package.extractall(unpacked)
    else:
        with tarfile.open(archive) as package:
            members = package.getmembers()
            safe_members(member.name for member in members)
            if not all(member.isfile() or member.isdir() for member in members):
                raise RuntimeError("unexpected Kujo archive member type")
            package.extractall(unpacked)
    binary = unpacked / ("kujo.exe" if system == "windows" else "kujo")
    if not binary.is_file():
        raise RuntimeError("Kujo executable absent from verified archive")
    return binary


with tempfile.TemporaryDirectory(prefix="redact-install-smoke-") as tmp:
    base = Path(tmp)
    source_zip = base / "redact-source.zip"
    run("git", "archive", "--format=zip", "-o", source_zip, "HEAD")
    checkout = base / "source"
    checkout.mkdir()
    with zipfile.ZipFile(source_zip) as package:
        safe_members(package.namelist())
        package.extractall(checkout)
    kujo = runtime(base)
    assert run(kujo, "--version").strip() == "kujo 1.4.0"
    assert run(kujo, "run", "redact.kujo", "version", cwd=checkout).strip() == "redact 1.0.0"
    audit = base / "audit"
    run(kujo, "run", "redact.kujo", "scan", "fixtures/sample.md", "--policy",
        "fixtures/sample.policy.yaml", "--audit-dir", audit, cwd=checkout)
    output = base / "sanitized.md"
    run(kujo, "run", "redact.kujo", "sanitize", "fixtures/sample.md", "--policy",
        "fixtures/sample.policy.yaml", "--out", output, "--audit-dir", audit, cwd=checkout)
    assert output.read_bytes() == (checkout / "fixtures/sample.redacted.md").read_bytes()
    run(kujo, "run", "redact.kujo", "verify", output, "--policy",
        "fixtures/sample.policy.yaml", "--audit-dir", audit, cwd=checkout)
    pack = base / "pack"
    run(kujo, "run", "redact.kujo", "pack", "examples/pack", "--policy",
        "examples/policy.yaml", "--out", pack, "--audit-dir", audit, cwd=checkout)
    assert len(list(pack.iterdir())) == 2
    print(f"Clean source-archive install smoke passed on {platform.system()} with Kujo 1.4.0")
    if args.benchmarks:
        for workload in ("max-dictionary", "repeated-dictionary", "unicode-dictionary", "pack-batch"):
            measured = subprocess.run([sys.executable, str(checkout / "scripts/benchmark.py"),
                                       "--repo", str(checkout), "--workload", workload,
                                       "--samples", "1", "--timeout", "120"],
                                      env={**os.environ, "KUJO_BIN": str(kujo)},
                                      cwd=checkout, capture_output=True, text=True, timeout=180)
            if measured.returncode:
                raise RuntimeError(f"{workload} benchmark failed: {measured.stdout}{measured.stderr}")
            print(measured.stdout, flush=True)
