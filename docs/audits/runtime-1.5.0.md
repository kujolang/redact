# Kujo 1.5.0 Compatibility Review

Date: 2026-09-23

Redact 1.x requires the official Kujo 1.5.0 release at source commit
`cc2d7dbb59a8dc05f00d629e100932f56f4062f6`. The GitHub release is a published,
non-prerelease release with a verified signed tag. The runtime identity is
pinned in `RUNTIME_VERSION`; the version gate additionally requires the binary
to report `kujo 1.5.0`.

The compatibility gate covers:

- deterministic, adversarial, fixture, example, parser, Unicode, pack, and
  regression tests;
- formatting and linting of every Kujo source file;
- product and runtime version consistency;
- clean committed-source installation on Linux, macOS, and Windows using
  checksum-verified official Kujo 1.5.0 release archives;
- Kennel package validation, ShipCheck release checks, local link checks, and
  generated-artifact hygiene; and
- an isolated Workcell candidate-metadata proof for the exact source commit.

Run the local gate with an official Kujo 1.5.0 binary:

```bash
export KUJO_BIN=/absolute/path/to/kujo
bash scripts/verify-all.sh
python3 scripts/install-smoke.py
```

The historical Kujo 1.4.0 performance measurements remain in
[`performance-1.4.0.md`](performance-1.4.0.md). They are retained as evidence,
not presented as Kujo 1.5.0 measurements. A one-sample compatibility run kept
the historical deterministic output hashes for the Unicode dictionary
(`6e578d7c4e327402b11e541f7a6b41e915523d8bce6e078fa19678ead42c83e7`) and
1,000-email
(`e4b768f1264bca392727fa932b45f09d5de9b2d44646f678f3c4f90bb7b3ea31`)
workloads. These hashes demonstrate output compatibility, not a statistically
valid performance comparison. Re-run multiple samples on controlled hardware
before making runtime-specific performance claims.
