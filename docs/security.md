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
source/output aliases, and unsafe audit or pack paths fail closed.

## Stdin boundary

Redact 1.0 rejects `-`. Released Kujo 1.0.0 provides only line-oriented
`input()` and does not distinguish EOF from a read failure or enforce a bounded
multiline read. A loop over that primitive would risk truncation, ambiguity, or
unbounded behavior. Use a controlled local file. Stdin remains a post-1.0
non-goal until the runtime offers a safe primitive.

## Policy boundary

`redact-policy/v1` accepts top-level scalars, the documented `terms` lists, and
the documented `roles` scalar mapping. Unknown fields, arbitrary nesting,
flow-style objects/arrays, anchors, aliases, tags, multiline scalars, tabs,
duplicate top-level keys, and unsupported actions fail with a policy error.
Policy files are limited to 262,144 bytes and must be regular, non-symlinked,
traversal-free paths.

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
permissions, filesystem races outside the checked boundary, hard-link aliases,
unrecognized encodings, inference from retained context, screenshots, copied
audit artifacts, policy tampering, or a human distributing unreviewed output.

## Required approval

Complete the synthetic [domain-signoff evidence pack](domain-signoff/README.md),
adapt it to the intended domain with authorized non-repository evidence, and
obtain named human privacy/security approval. The repository deliberately
leaves that checklist unsigned.

For vulnerability reporting, use [SECURITY.md](../SECURITY.md).
