# Changelog

All notable Redact changes are documented here. Product versions and schema
versions are independent contracts.

## [Unreleased]

- Fixed ten validated CLI, policy parsing, overlap transformation, content-hash,
  and money-bucketing defects; added regression coverage for each failure class.

## [1.0.0] - 2026-08-08

- Declared the stable local `.txt`/`.md`, `redact-policy/v1`, deterministic
  detector, configured dictionary, transformation, verifier, audit, pack, CLI,
  JSON, exit-code, and offline/no-AI scope.
- Rejected `-` stdin explicitly because released Kujo 1.0.0 lacks a safe
  bounded multiline stdin primitive with distinguishable EOF/read failures.
- Added strict policy failures, input/output limits, path and symlink checks,
  overwrite prevention, deterministic pack ordering, and safe audit snapshots.
- Added canonical MIT licensing, Kennel metadata, examples, adversarial tests,
  domain-signoff evidence, release mechanics, real CI, and release gates.
- Retained the explicit limitation that Redact is a review aid, not complete
  PII detection, a privacy guarantee, compliance software, or domain approval.

## [0.1.0] - 2026-07-28

- Introduced the local deterministic technical-preview pipeline and initial
  scan, sanitize, verify, pack, policy, audit, and fixture behavior.

[1.0.0]: https://github.com/kujolang/redact/compare/v0.1.0...v1.0.0
[0.1.0]: https://github.com/kujolang/redact/releases/tag/v0.1.0
