#!/usr/bin/env python3
"""Offline, synthetic sanitize benchmark; timings are evidence, not CI gates."""
import argparse
import hashlib
import json
import os
from pathlib import Path
try:
    import resource
except ImportError:
    resource = None
import statistics
import subprocess
import tempfile
import threading
import time


def windows_peak_sampler(process, stop, peak):
    """Read the child's OS-maintained peak working set while its handle lives."""
    import ctypes
    from ctypes import wintypes

    class MemoryCounters(ctypes.Structure):
        _fields_ = [("cb", wintypes.DWORD), ("PageFaultCount", wintypes.DWORD),
                   ("PeakWorkingSetSize", ctypes.c_size_t), ("WorkingSetSize", ctypes.c_size_t),
                   ("QuotaPeakPagedPoolUsage", ctypes.c_size_t),
                   ("QuotaPagedPoolUsage", ctypes.c_size_t),
                   ("QuotaPeakNonPagedPoolUsage", ctypes.c_size_t),
                   ("QuotaNonPagedPoolUsage", ctypes.c_size_t),
                   ("PagefileUsage", ctypes.c_size_t),
                   ("PeakPagefileUsage", ctypes.c_size_t)]

    kernel = ctypes.WinDLL("kernel32", use_last_error=True)
    psapi = ctypes.WinDLL("psapi", use_last_error=True)
    kernel.OpenProcess.argtypes = [wintypes.DWORD, wintypes.BOOL, wintypes.DWORD]
    kernel.OpenProcess.restype = ctypes.c_void_p
    kernel.CloseHandle.argtypes = [ctypes.c_void_p]
    psapi.GetProcessMemoryInfo.argtypes = [ctypes.c_void_p, ctypes.c_void_p, wintypes.DWORD]
    handle = kernel.OpenProcess(0x1000, False, process.pid)  # PROCESS_QUERY_LIMITED_INFORMATION
    if not handle:
        return
    try:
        while True:
            counters = MemoryCounters()
            counters.cb = ctypes.sizeof(counters)
            if psapi.GetProcessMemoryInfo(handle, ctypes.byref(counters), counters.cb):
                peak[0] = max(peak[0], counters.PeakWorkingSetSize)
            if stop.wait(0.02):
                break
    finally:
        kernel.CloseHandle(handle)

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--repo", type=Path, default=Path(__file__).resolve().parent.parent)
parser.add_argument("--workload", choices=["emails", "dictionary", "max-dictionary",
                                         "repeated-dictionary", "unicode-dictionary", "unicode-mixed",
                                         "replacement-expansion", "pack-batch", "pack-extended"], default="emails")
parser.add_argument("--samples", type=int, default=3)
parser.add_argument("--emails", type=int, default=100)
parser.add_argument("--timeout", type=int, default=120, help="per-run timeout in seconds")
args = parser.parse_args()
if not 1 <= args.samples <= 20 or not 1 <= args.emails <= 1000 or not 1 <= args.timeout <= 300:
    parser.error("samples must be 1..20, emails 1..1000, timeout 1..300")
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
    if args.workload == "max-dictionary":
        # Valid upper-bound fixture: 1 MiB source and a near-256 KiB policy.
        # Every configured term is absent, making the search budget visible.
        text = ("ordinary synthetic note. " * 50000)[:1048576]
        policy = str(root / "policy.yaml")
        terms = "".join(f"    - AbsentTerm{i:04d}" + "X" * 220 + "\n" for i in range(1050))
        Path(policy).write_text("schemaVersion: redact-policy/v1\nname: benchmark-max\nterms:\n  person_names:\n" + terms, encoding="utf-8")
        assert Path(policy).stat().st_size <= 262144
        expected_detections = 0
    if args.workload == "repeated-dictionary":
        # Maximal valid input with many copies of one configured ASCII term.
        text = "SyntheticPerson " * 65536
        policy = str(root / "policy.yaml")
        Path(policy).write_text("schemaVersion: redact-policy/v1\nname: benchmark-repeated\nterms:\n  person_names:\n    - SyntheticPerson\n", encoding="utf-8")
        expected_detections = 1
    if args.workload == "unicode-dictionary":
        # Accepted candidate budget: 524,288 scalars * one absent scalar.
        text = "α" * 524288
        policy = str(root / "policy.yaml")
        Path(policy).write_text("schemaVersion: redact-policy/v1\nname: benchmark-unicode\nterms:\n  person_names:\n    - Ω\n", encoding="utf-8")
        expected_detections = 0
    if args.workload == "unicode-mixed":
        # Two categories exercise the aggregate scalar-candidate work budget.
        text = "α" * 262144
        policy = str(root / "policy.yaml")
        Path(policy).write_text("schemaVersion: redact-policy/v1\nname: benchmark-unicode-mixed\nterms:\n  person_names:\n    - Ω\n  company_names:\n    - Σ\n", encoding="utf-8")
        expected_detections = 0
    if args.workload == "replacement-expansion":
        # Accepted 280,000-byte input expands to 1,540,000 bytes, below the 2 MiB limit.
        text = "A " * 140000
        policy = str(root / "policy.yaml")
        Path(policy).write_text("schemaVersion: redact-policy/v1\nname: benchmark-expansion\nterms:\n  person_names:\n    - A\n", encoding="utf-8")
        expected_detections = 1
    if args.workload in ("pack-batch", "pack-extended"):
        source = root / "pack-input"
        source.mkdir()
        for member in range(32 if args.workload == "pack-extended" else 16):
            (source / f"note-{member:02d}.txt").write_text("ordinary synthetic note. " * 2621 + "x" * 11, encoding="utf-8")
        input_bytes = sum(path.stat().st_size for path in source.iterdir())
    else:
        source.write_text(text, encoding="utf-8")
        input_bytes = source.stat().st_size
    for i in range(args.samples):
        output = root / (f"pack-{i}" if args.workload in ("pack-batch", "pack-extended") else f"output-{i}.md")
        start = time.perf_counter()
        command = "pack" if args.workload in ("pack-batch", "pack-extended") else "sanitize"
        process = subprocess.Popen([kujo, "run", "redact.kujo", command, str(source),
                                    "--policy", policy, "--out", str(output),
                                    "--audit-dir", str(root / f"audit-{i}")],
                                   cwd=repo, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        stop = threading.Event()
        windows_peak = [0]
        sampler = None
        if os.name == "nt":
            sampler = threading.Thread(target=windows_peak_sampler, args=(process, stop, windows_peak),
                                       daemon=True)
            sampler.start()
        try:
            stdout, stderr = process.communicate(timeout=args.timeout)
        except subprocess.TimeoutExpired:
            process.kill()
            process.communicate()
            raise
        finally:
            stop.set()
            if sampler:
                sampler.join(timeout=2)
        elapsed = time.perf_counter() - start
        peak_rss = resource.getrusage(resource.RUSAGE_CHILDREN).ru_maxrss if resource else (windows_peak[0] or None)
        if os.name == "nt" and peak_rss is None:
            raise RuntimeError("Windows peak working set could not be measured")
        if peak_rss is not None and os.name == "posix" and os.uname().sysname == "Linux":
            peak_rss *= 1024
        if process.returncode:
            raise RuntimeError(stdout + stderr)
        receipt = json.loads(stdout)
        if args.workload in ("pack-batch", "pack-extended"):
            assert receipt["processed"] == (32 if args.workload == "pack-extended" else 16) and receipt["auditComplete"], receipt
            members = sorted(output.iterdir())
            data = b"".join(path.name.encode() + b"\0" + path.read_bytes() for path in members)
            output_bytes = sum(path.stat().st_size for path in members)
        else:
            assert receipt["detections"] == expected_detections, receipt
            assert receipt["risk_score"] == "low", receipt
            data = output.read_bytes()
            output_bytes = len(data)
            if args.workload == "replacement-expansion":
                assert data == ("[PERSON_1] " * 140000).encode(), "unexpected expanded output"
        hashes.add(hashlib.sha256(data).hexdigest())
        measurements.append(elapsed)
    assert len(hashes) == 1, "nondeterministic output"
    print(json.dumps({"workload": args.workload, "emails": args.emails if args.workload == "emails" else 0,
                      "input_bytes": input_bytes, "output_bytes": output_bytes,
                      "runtime": subprocess.check_output([kujo, "--version"], text=True).strip(),
                      "policy_bytes": Path(policy).stat().st_size if policy != "basic" else None,
                      "peak_child_rss_bytes": peak_rss,
                      "peak_memory_basis": "windows_peak_working_set" if os.name == "nt" else "child_maxrss",
                      "samples_seconds": measurements, "median_seconds": statistics.median(measurements),
                      "output_sha256": next(iter(hashes))}, indent=2))
