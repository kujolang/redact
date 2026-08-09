# Synthetic Test Corpus

The committed corpus is:

- [`fixtures/sample.md`](../../fixtures/sample.md): all core deterministic
  families and configured terms;
- [`examples/synthetic-note.md`](../../examples/synthetic-note.md): email,
  phone, URL/domain, valid/invalid Luhn, fake token, date, money, five configured
  dictionary categories, and a strategy phrase;
- [`examples/transformations.txt`](../../examples/transformations.txt): each
  transformation family;
- [`tests/redact_tests.kujo`](../../tests/redact_tests.kujo): mixed case,
  Unicode configured text, a confusable near-miss, overlap, repetition,
  deterministic ordering, verifier high/low, and policy failures;
- [`tests/policy_adversarial.sh`](../../tests/policy_adversarial.sh): malformed,
  nested, duplicate, anchored, flow-style, unknown, wrong-schema, unsupported
  action, and AI-enabled policy failures; and
- [`tests/security_adversarial.sh`](../../tests/security_adversarial.sh): stdin,
  traversal, symlink, overwrite, size, malformed UTF-8, audit leakage,
  unsafe-original isolation, and deterministic output tests.

Every value is synthetic. The corpus is documentation of exercised behavior,
not evidence of coverage for a real deployment domain.
