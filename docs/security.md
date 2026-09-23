# Redact Security and Privacy Boundary

## Intended use

Redact 1.0 reduces policy-defined sensitive-text exposure in local `.txt` and
`.md` files. It is a review aid. It does not guarantee complete detection or
removal, legal or regulatory compliance, fitness for every domain, or safety of
unreviewed output. Domain-specific human privacy/security signoff is required
before sensitive production use.

## Local and offline operation

The stable pipeline makes no AI-provider or network calls. `src/ai_provider.kujo`
is an uninvoked future interface description, not a detection capability.
`ai_assist: true` is rejected. Do not describe Redact as AI-powered.

Inputs must be local, regular UTF-8 `.txt` or `.md` files no larger than
1,048,576 bytes. Transformed output is limited to 2,097,152 bytes. Symbolic-link
components, traversal segments, malformed UTF-8, unsupported extensions,
source/output or active-policy/output aliases, special output files, and unsafe audit or pack paths fail
closed. Audit validation covers the derived run directory, including an existing
`runs` component. On POSIX, symlink inspection uses the actual filename spelling,
including literal backslashes. The system `/tmp` and `/var` aliases remain
accepted as before.
Input and policy text are read through Kujo 1.5's bounded handle-relative
`read_file_beneath`, which holds the parent directory, rejects final symlinks
and nonregular files, and applies the byte limit to that open handle. The
preceding path checks still reject explicit symlink components. Replacing a
path's parent before the held directory is opened, mutation of file contents
by another process, and concurrent changes to output/audit parents remain
outside this local-tool boundary. A synthetic hard-link output regression
verifies atomic replacement does not modify the source inode; Redact does not
attempt to prohibit hard-linked source files or guarantee inode isolation
against a hostile same-host actor.

Pack uses Kujo 1.5's private sibling staging directory and atomic no-replace
directory publication on macOS, Linux, and Windows. A processing or publish
failure cannot expose a partly written requested pack directory. A partial
audit may still remain, and writes after publication are not a joint atomic
transaction with the pack. Each member's audit records a pending final-path
hash before publication and switches to published only after output manifests
are written. If audit finalization fails, pack JSON reports `published: true`,
`auditComplete: false`, and a nonzero exit; do not discard the published output
or assume an incomplete audit is complete. The read-only
`python3 scripts/reconcile-pack-audits.py --audit-dir PATH` checks member hashes
and reports `matching_pending`, `recoverable_published`, `not_published`, or
`needs_review` without changing either output or audit. Matching a pending
hash cannot prove Redact published the directory: a pre-existing collision
might have identical bytes. An audit and pack still have no joint
transaction. Hostile writers on the same host are not an established security
boundary.

The output limit counts UTF-8 bytes, not Unicode scalars. Each projected
replacement is checked before allocation, and output is checked before the
verifier runs. Oversized intermediate transformations fail without writing the
output; a partial audit can remain. This bounds expansion, not total CPU time
for every accepted dictionary/document combination.

## Stdin boundary

Redact 1.0 rejects `-`. It has no implemented or tested bounded multiline
stdin path with explicit EOF, read-error, and size-limit behavior. A naive
line-oriented loop would risk truncation, ambiguity, or unbounded behavior.
Use a controlled local file; stdin remains a separately reviewed future
feature, regardless of the pinned runtime version.

## Policy boundary

`redact-policy/v1` accepts top-level scalars, the documented `terms` lists, and
the documented `roles` scalar mapping. Unknown fields, arbitrary nesting,
flow-style objects/arrays, anchors, aliases, tags, inline comments, quoted
escape sequences, multiline scalars, tabs,
duplicate top-level keys, and unsupported actions fail with a policy error.
Policy files are limited to 262,144 bytes and must be regular, non-symlinked,
traversal-free paths. At most 2,048 configured terms are accepted. When
context-sensitive Unicode matching is needed, Redact rejects document/term
combinations requiring more than 2,000,000 scalar-candidate work units. These
are conservative deterministic admission limits, not a wall-clock guarantee.

Policy dictionaries are security-critical configuration. False negatives can
result from missing terms, confusables, unsupported formats, misspellings, or
domain language. False positives can remove useful content. Review policies and
sanitized results together.

## Audit handling

Default audits exclude raw detected values. Detection events store a SHA-256
value hash, category, detector, spans, confidence, reason, and action. The safe
policy snapshot stores actions, dictionary/role counts, and a source-policy
hash—not dictionary entries or role names.

Audits may still expose sensitive metadata through source/output paths, policy
names, timing, hashes, counts, category presence, transformations, and residual
risk. Store audit directories locally with restrictive access, exclude them
from source control and backups unless reviewed, and apply an appropriate
retention policy.

`--unsafe-store-originals` intentionally places raw matched values in
`detections.jsonl`. The run is visibly marked and warned, but Redact cannot
secure it on your behalf. Never use this flag as a routine workflow, in CI, in
shared storage, or for sensitive production material. Isolate and remove such
runs promptly.

## Detection limitations

Detectors are deterministic patterns and exact configured dictionaries. They
do not provide semantic classification, general Unicode normalization,
homoglyph detection, exhaustive international phone/domain/date/money formats,
contextual re-identification analysis, or discovery of arbitrary secrets.
Luhn rejection only means a number is not classified as a credit-card
candidate; it is not proof that the number is safe.

The verifier re-runs the supported deterministic detector and configured-term
checks. A `low` result means no supported verifier rule fired. It does not mean
zero residual privacy risk.

## Threats not solved

Redact does not defend against compromised hosts, malicious local users, unsafe
permissions, filesystem races outside the checked boundary, mutable hard-linked inputs,
unrecognized encodings, inference from retained context, screenshots, copied
audit artifacts, policy tampering, or a human distributing unreviewed output.

## Required approval

Complete the synthetic [domain-signoff evidence pack](domain-signoff/README.md),
adapt it to the intended domain with authorized non-repository evidence, and
obtain named human privacy/security approval. The repository deliberately
leaves that checklist unsigned.

For vulnerability reporting, use [SECURITY.md](../SECURITY.md).
