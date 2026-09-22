# Redact follow-up review — 2026-09-22

Status: candidate work for a future session, not a release approval or a claim
of enterprise-wide fitness. Review based on the current local implementation,
tests, contracts, and the prior [hardening audit](repository-hardening.md).
Redact remains a bounded, deterministic review aid. No agent may sign off a
real data domain on behalf of its privacy/security owners.

## This pass

- Confirmed the root `redact.kujo` is the required public entrypoint and
  `VERSION`, `RUNTIME_VERSION`, `kujo.toml`, `kennel.toml`, licensing, security,
  and contributor files are package or repository contracts. Implementation
  belongs in `src/`; tests, policies, examples, scripts, and docs retain their
  separate roles. Moving these root contracts under `src/` would break source
  installs, release tooling, or published invocation examples.
- The ignored `transcript.policy.yaml`, `transcript.report.json`, and
  `redact-transcript-audit/` are local, untracked user artifacts, not files to
  relocate or commit. Keep them out of package artifacts; do not delete them
  without the owner's instruction.
- Added preflight validation of supported pack members and rejection of empty
  packs. The process still checks each file again at use time. This prevents
  predictable bad members from causing a partly populated output directory,
  but does not make pack creation transactional.

## Prioritized next-session work

1. **P1 — Transactional pack publication.** `src/cli.kujo` currently creates
   the final pack directory before all transformations finish; a later read,
   verifier, audit, or write failure can leave a partial pack. Design a
   same-filesystem staging directory and atomic publish, with safe cleanup and
   explicit behavior when the destination appears concurrently. Test late
   failures, collisions, cleanup, permissions, and audit consistency. Do not
   claim atomicity until the pinned Kujo runtime's directory-rename semantics
   and cross-platform behavior are verified.
2. **P1 — Filesystem adversary model.** `src/document.kujo` compares path
   strings and normalized absolute paths but does not prove inode identity;
   `docs/security.md` explicitly excludes hard-link aliases and races. Define
   whether hostile same-host writers are in scope and investigate a portable
   file-identity / no-follow / exclusive-create interface in Kujo before
   promising protection. Synthetic adversarial regression tests are required.
3. **P1 — CPU and memory budgets for configured dictionaries.**
   `src/detect.kujo` scans Unicode scalar candidates for each configured term,
   and `src/transform.kujo` replaces whole-document occurrences per distinct
   value. Input and policy byte caps do not establish a CPU cap. Benchmark
   adversarial valid 1 MiB documents and 256 KiB policies under Kujo 1.0.0;
   preserve contextual Unicode matching and deterministic output when
   optimizing. Measure end-to-end time and peak memory against the existing
   [performance baseline](performance.json).
4. **P2 — Policy syntax contract and parser fuzzing.** `src/policy.kujo`
   implements a deliberately narrow YAML subset via line parsing. Expand
   malformed-scalar, quoting, comment, Unicode, and duplicate-key test matrices
   before contemplating any YAML feature expansion. Unsupported constructs
   must continue to fail closed; a general parser would need a new security
   review and compatibility decision.
5. **P2 — Practical adoption and evidence.** Test install instructions from a
   clean source artifact on supported platforms; collect current hosted CI,
   Workcell receipt, and ShipCheck evidence for an exact candidate SHA.
   Publish transparent performance/detection examples with synthetic values,
   coverage boundaries, and a clear path from Redact to the Kujo documentation.
   Have domain owners run the unsigned signoff process for each real use case.
6. **P2 — Format expansion only after contract design.** CSV, JSON, nested
   directories, and bounded stdin may broaden usefulness, but need precise
   preservation, escaping, streaming, partial-failure, audit, and schema rules.
   Do not silently treat structured data as plain text or promise semantic PII
   detection. Decide separately which belongs in a new schema/product major.

## Release decision

Passing local tests alone does not establish production readiness or universal
usefulness. Human domain approval, exact-commit Workcell proof, and hosted
verification remain open as specified in the [launch checklist](../launch-checklist.md).
The canonical Codex Security scan could not start in this environment because
its plugin process lacked `tomllib` and `tomli`; the local source review here is
not a replacement for a completed independent security scan. Retry the scan
in a repaired environment before claiming comprehensive coverage.
