# Changelog

All notable Redact changes are documented here. Product versions and schema
versions are independent contracts.

## [Unreleased]

- Record pack publication intent before atomic publish and provide read-only
  audit reconciliation for interruptions without touching published members.
- Use bounded no-follow input reads and Kujo 1.4's constant-time byte length;
  accelerate ASCII dictionary matching without changing Unicode behavior and
  reject excessive configured-term / Unicode-candidate work.
- Tighten ambiguous policy scalars and add malformed/Unicode parser matrices;
  document structured-input compatibility design without enabling new types.
- Stage packs privately and publish complete output with Kujo 1.4's atomic
  no-replace directory operation; keep final output paths in successful audits.
- Require the released Kujo 1.4.0 runtime across the version gate, Kennel
  minimum, CI, Workcell proof, and user documentation; adopt its formatter.
- Validate supported pack members before output creation, reject empty packs,
  and test invalid-member handling without partial output.
- Validate derived audit paths and literal POSIX filenames, reject special
  output files, and enforce UTF-8 output bounds before replacement allocation.
- Preserve stable ordering with merge sorting, exact detection membership, and
  native literal search/replacement; add synthetic hardening regressions and a
  reproducible end-to-end benchmark.
- Reject malformed policy names and missing dictionary-category colons, and
  fail runtime version mismatches before running the verification workload.

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
