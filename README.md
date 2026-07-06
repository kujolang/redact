# Redact

Redact is a local-first deterministic anonymization pipeline written in Kujo.
It converts sensitive text and Markdown into model-ready context while writing a full local audit trail.

## Usage

```bash
kujo run redact.kujo scan fixtures/sample.md --policy fixtures/sample.policy.yaml
kujo run redact.kujo sanitize fixtures/sample.md --policy fixtures/sample.policy.yaml --out sample.redacted.md
kujo run redact.kujo verify sample.redacted.md --policy fixtures/sample.policy.yaml
kujo run redact.kujo pack ./notes --policy external-safe --out redacted-pack
```

The CLI command is `kujo`; Redact's entrypoint lives at `redact.kujo` in the repository root.

## MVP Capabilities

- Inputs: `.txt`, `.md`, and the `-` stdin contract. Current Kujo VM builds do not expose a stdin read primitive, so `-` returns a clear unsupported-runtime error instead of silently doing the wrong thing.
- Policy: flat YAML policies with category actions, configured term dictionaries, and optional role mappings.
- Detection: deterministic email, phone, URL/domain, credit card with Luhn validation, API key/token, money, date, configured person/company/customer/product names, and strategy phrases.
- Transformation: `remove`, `placeholder`, `role-preserve`, `generalize`, `range`, and `date-generalize`.
- Verification: deterministic leakage checks with `low` or `high` risk output.
- Audit: JSON and JSONL run artifacts under `.redact/runs/<timestamp>/`.
- AI: stubbed provider contract only. AI is optional, isolated, and not invoked by the MVP.

## Audit Files

Each scan, sanitize, or verify run writes:

```text
.redact/runs/<timestamp>/
  run.json
  input-manifest.json
  detections.jsonl
  decisions.jsonl
  transformations.jsonl
  verifier-report.json
  policy.snapshot.yaml
  output-manifest.json
  hashes.json
  warnings.jsonl
```

Raw sensitive values are not written to audit logs by default. `--unsafe-store-originals` exists for local debugging and is dangerous.

## Tests

```bash
bash tests/run.sh
```
