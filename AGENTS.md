# Redact Agent Instructions

Redact 1.x is a deterministic local redaction aid. Never claim complete PII
detection, guaranteed sensitive-value removal, legal/regulatory compliance,
arbitrary-domain fitness, replacement of human review, production certification,
or AI semantic detection.

## Required reading

- `README.md`
- `CHANGELOG.md`
- `SECURITY.md`
- `docs/security.md`
- `docs/architecture.md`
- `docs/launch-checklist.md`
- `docs/release-process.md`
- `docs/domain-signoff/README.md`
- `redact.kujo`, `src/*.kujo`, and relevant tests

## Validation

Use the released Kujo runtime identified by `RUNTIME_VERSION`.

```bash
export KUJO_BIN=/Users/robertdevore/2026/Kujolang/kujo-repos/kujo/target/release/kujo
"$KUJO_BIN" --version
bash scripts/verify-all.sh
```

An exact release candidate also requires Workcell proof plus receipt
verification, ShipCheck exit code `0`, and a passing hosted Verification run.

## Evidence and safety

- Use only synthetic values in fixtures, tests, examples, and committed proof.
- Do not commit `.redact/runs`, sanitized packs, transcripts, generated release
  artifacts, reports, Workcell evidence, or temporary files.
- Treat audit paths, hashes, policy names, and counts as sensitive metadata.
- `--unsafe-store-originals` is hazardous and never a normal workflow.
- Unsupported YAML must fail clearly; never broaden it silently.
- Human domain privacy/security signoff cannot be self-approved by an agent.

## Prohibited without approval

Do not use live provider credentials, publish packages, create or push release
tags, create GitHub releases, deploy services, modify branch protection, bypass
hosted controls, force-push, rewrite history, or make compliance guarantees.
