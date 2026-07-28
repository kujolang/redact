# Redact Agent Instructions

Redact is a local deterministic anonymization pipeline. Treat it as a reviewable redaction aid, not a guarantee that no sensitive data remains.

## Required Reading

- `README.md`
- `docs/security.md`
- `docs/architecture.md`
- `docs/launch-checklist.md`
- `redact.kujo`
- Relevant `src/*.kujo` and `tests/*.kujo`

## Validation

Set `KUJO_BIN` to the intended Kujo runtime.

```bash
"$KUJO_BIN" check redact.kujo
bash tests/run.sh
"$KUJO_BIN" run redact.kujo scan fixtures/sample.md --policy fixtures/sample.policy.yaml
"$KUJO_BIN" run redact.kujo sanitize fixtures/sample.md --policy fixtures/sample.policy.yaml --out /tmp/redact-sample.redacted.md
"$KUJO_BIN" run redact.kujo verify /tmp/redact-sample.redacted.md --policy fixtures/sample.policy.yaml
git diff --check
```

## Evidence Rules

- Preserve verifier reports, audit paths, policy snapshots, and command logs for launch proof.
- Do not commit `.redact/runs/` or generated redacted packs unless the task explicitly asks for a proof fixture.
- Workcell proof is required for this launch batch unless a blocker receipt documents the Docker/host blocker and closest equivalent proof.

## Prohibited Without Approval

Do not use live AI/provider credentials, publish packages, create public releases, push final tags, deploy hosted services, alter branch protection, force-push, rewrite history, or claim complete PII removal/compliance guarantees.
