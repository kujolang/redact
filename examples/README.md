# Redact Synthetic Examples

All values in this directory are invented for testing. The card number is a
standard non-live Luhn test value, the invalid card-like number is intentionally
retained, `example.com` is reserved for documentation, and the token is fake.

Set the released runtime once:

```bash
export KUJO_BIN=/path/to/kujo-1.0.0/target/release/kujo
```

## Scan and JSON output

```bash
"$KUJO_BIN" run redact.kujo scan \
  examples/synthetic-note.md \
  --policy examples/policy.yaml \
  --audit-dir /tmp/redact-example-scan
```

The JSON shape includes `schemaVersion`, `productVersion`, `command`,
`detections`, category counts, and the audit path. Detection counts are not a
privacy guarantee.

## Sanitize and verify

```bash
"$KUJO_BIN" run redact.kujo sanitize \
  examples/synthetic-note.md \
  --policy examples/policy.yaml \
  --out /tmp/synthetic-note.redacted.md \
  --audit-dir /tmp/redact-example-sanitize

"$KUJO_BIN" run redact.kujo verify \
  /tmp/synthetic-note.redacted.md \
  --policy examples/policy.yaml \
  --audit-dir /tmp/redact-example-verify
```

Expected output contains role, company, customer, product, email, domain,
money, date, and strategy replacements; phone, valid test card, and fake token
matches are removed. The invalid-Luhn number remains to demonstrate a known
boundary requiring human review.

## Transformation families

```bash
"$KUJO_BIN" run redact.kujo sanitize \
  examples/transformations.txt \
  --policy examples/policy.yaml \
  --out /tmp/transformations.redacted.txt \
  --audit-dir /tmp/redact-example-transformations
```

This demonstrates `remove`, `placeholder`, `role-preserve`, `generalize`,
`range`, and `date-generalize`.

## Deterministic pack

```bash
"$KUJO_BIN" run redact.kujo pack \
  examples/pack \
  --policy examples/policy.yaml \
  --out /tmp/redact-example-pack \
  --audit-dir /tmp/redact-example-pack-audit
```

The output directory must not already exist. The JSON summary reports two
processed files and zero failures.

## Expected safe policy failure

```bash
"$KUJO_BIN" run redact.kujo scan \
  examples/synthetic-note.md \
  --policy examples/unsupported-nested-policy.yaml
```

Expected: exit `1` with an `unexpected indentation or nested YAML structure`
error. Redact does not guess at unsupported policy meaning.

## Stdin is intentionally unsupported

```bash
printf '%s\n' 'synthetic@example.com' | \
  "$KUJO_BIN" run redact.kujo scan - --policy examples/policy.yaml
```

Expected: exit `1` stating that `-` is not supported in Redact 1.0. Use a
bounded local `.txt` or `.md` file instead.

Run every example with `bash tests/examples_smoke.sh`.
