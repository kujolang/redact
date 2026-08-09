# Contributing to Redact

Redact accepts focused changes that preserve its deterministic, local-first,
review-aid boundary. Read [SECURITY.md](SECURITY.md) before adding detectors,
policy features, audit fields, or file-system behavior.

## Development setup

Use Kujo 1.0.0 at the commit recorded in `RUNTIME_VERSION` (see
[compatibility and upgrades](README.md#compatibility-and-upgrades)):

```bash
export KUJO_BIN=/path/to/kujo-1.0.0/target/release/kujo
"$KUJO_BIN" --version
bash scripts/verify-all.sh
```

## Change requirements

- Add deterministic synthetic tests for behavior changes.
- Never add real personal data, credentials, customer content, or production
  secrets to fixtures, examples, logs, or audit artifacts.
- Keep product and schema versions independent.
- Reject unsupported policy structures explicitly.
- Document new false-positive and false-negative boundaries.
- Do not weaken path, size, symlink, overwrite, or audit-leakage controls.
- Run `bash scripts/verify-all.sh` and `git diff --check` before review.

Security-sensitive reports should follow [SECURITY.md](SECURITY.md), not a
public issue.
