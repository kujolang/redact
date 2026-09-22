# Redact

![Version 1.0.0](https://img.shields.io/badge/version-1.0.0-blue.svg)
[![MIT License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Built with Kujo](https://img.shields.io/badge/built%20with-Kujo-6f42c1.svg)](https://github.com/kujolang/kujo)
[![Verification](https://github.com/kujolang/redact/actions/workflows/verification.yml/badge.svg)](https://github.com/kujolang/redact/actions/workflows/verification.yml)

Redact 1.0.0 is a deterministic, local-first redaction aid for `.txt` and
`.md` files. It applies a documented policy subset, configured sensitive-term
dictionaries, pattern detectors, transformations, leakage verification, local
audit artifacts, and deterministic folder packs without AI-provider or network
calls.

Redact does not promise complete PII detection or guaranteed removal of every
sensitive value. It is not legal or regulatory compliance software, a
replacement for human review, or production certification for arbitrary
confidential data. Domain-specific privacy and security signoff is required
before sensitive production use.

## Install

Redact requires the released Kujo 1.4.0 runtime at commit
`266a8902068a14c3d17f803bef467dc28f1fe162`.
Download the matching platform archive and checksum from the
[Kujo v1.4.0 release](https://github.com/kujolang/kujo/releases/tag/v1.4.0),
verify its SHA-256, and extract the `kujo` executable (`kujo.exe` on Windows).

```bash
git clone https://github.com/kujolang/redact.git
cd redact
export KUJO_BIN=/absolute/path/to/extracted/kujo
"$KUJO_BIN" --version
"$KUJO_BIN" run redact.kujo version
```

Expected versions are `kujo 1.4.0` and `redact 1.0.0`. Kennel consumers use
`kennel.toml`; no registry publication is required for a source checkout.
Windows users can set `$env:KUJO_BIN` to the extracted `kujo.exe` path.
To learn the language behind this example, start with the
[Kujo language documentation](https://docs.kujolang.ai/) and
[runtime source](https://github.com/kujolang/kujo).

## Quick Start

The bundled fixture is synthetic.

```bash
"$KUJO_BIN" run redact.kujo scan \
  fixtures/sample.md \
  --policy fixtures/sample.policy.yaml

"$KUJO_BIN" run redact.kujo sanitize \
  fixtures/sample.md \
  --policy fixtures/sample.policy.yaml \
  --out /tmp/redact-sample.redacted.md

"$KUJO_BIN" run redact.kujo verify \
  /tmp/redact-sample.redacted.md \
  --policy fixtures/sample.policy.yaml
```

Review the sanitized file and its audit run before sharing either one.

## Stable 1.0 Scope

Redact 1.0 is stable for:

- local regular `.txt` and `.md` files up to 1,048,576 bytes;
- UTF-8 text accepted by Kujo 1.4.0;
- `redact-policy/v1`, the documented flat-YAML policy subset;
- deterministic categories and configured term dictionaries;
- `remove`, `placeholder`, `role-preserve`, `generalize`, `range`, and
  `date-generalize` transformations;
- deterministic post-transformation leakage verification;
- protected local audit artifacts without raw matches by default;
- deterministic, non-recursive folder pack generation;
- documented CLI, JSON schema, and exit-code behavior; and
- offline execution without AI-provider calls.

Output expansion is checked against the 2,097,152-byte UTF-8 limit before
allocating each replacement result and before verification. A transformation
whose intermediate result exceeds that limit fails, even if a later rule
could shrink it.

Symbolic-link paths, traversal segments, source overwrites, oversized inputs or
outputs, malformed UTF-8, unsupported extensions, and ambiguous policy YAML
fail closed. Pack output must be a new directory.

### Supported inputs and stdin decision

Only local `.txt` and `.md` file paths are supported. `-` stdin is explicitly
not supported in Redact 1.0.0. Redact has no implemented, tested bounded
multiline stdin contract; it rejects `-` rather than risk truncation or
ambiguous EOF/read failures. Stdin remains a separate future feature that
requires a suitable runtime API and explicit tests.

## Policy Contract

Every policy declares `schemaVersion: redact-policy/v1`, a non-empty `name`,
category actions, boolean safety fields, and optional `terms` and `roles`
mappings. The supported structure is shown in
[`examples/policy.yaml`](examples/policy.yaml).

Policy names must be non-empty strings, and category mappings require a colon.
Ambiguous plain names (booleans, null-like words, and numbers) must be quoted.

Policy files are limited to 262,144 bytes and must pass the same regular-file,
traversal, and symbolic-link checks as inputs.
At most 2,048 configured terms are accepted. Unicode candidate matching also
uses a 2,000,000 scalar-candidate work budget; inputs/policies exceeding that
combination fail with a resource-limit error, not a low-risk verification.

Supported configured dictionaries are `person_names`, `company_names`,
`customer_names`, `product_names`, and `launch_strategy`. Legacy top-level
aliases (`person_dictionary`, `company_dictionary`, `customer_dictionary`,
`product_dictionary`, and `strategy_terms`) remain readable in 1.x, but new
policies should use `terms`.

Nested objects beyond `terms` and `roles`, flow collections, anchors, aliases,
tags, multiline scalars, tabs, duplicate top-level keys, and unknown fields are
unsupported and fail with a line-specific policy error. Inline comments and
quoted escape sequences are unsupported; a `#` inside a quoted scalar is a
literal value. `ai_assist` and
`write_entity_map` must be `false` in 1.0.

## Detection Categories

Deterministic detectors cover:

- email addresses;
- phone-like values with 10–15 digits;
- HTTP(S) URLs and the documented common-domain suffix set;
- credit-card candidates that pass Luhn validation;
- documented API-key and token patterns;
- ISO and English month-name dates;
- dollar-denominated money amounts; and
- configured people, companies, customers, products, and strategy phrases.

Configured term matching is case-insensitive and longest-term-first. Unicode
text is preserved, but Redact does not perform general Unicode normalization,
homoglyph/confusable resolution, semantic entity recognition, or exhaustive
international format detection. Invalid-Luhn numeric strings intentionally
remain unless another configured rule covers them. These are review boundaries,
not assurances that an unmatched value is safe.

## Transformation Strategies

| Strategy | Stable behavior |
| --- | --- |
| `remove` | Replaces the matched value with an empty string. |
| `placeholder` | Uses stable category placeholders such as `[EMAIL_1]`. |
| `role-preserve` | Uses a configured role, otherwise a person placeholder. |
| `generalize` | Replaces dates or strategy phrases with fixed general text. |
| `range` | Replaces dollar amounts with a deterministic magnitude bucket. |
| `date-generalize` | Maps exact dates to the stable date generalization. |

Repeated exact values reuse the same replacement. Folder entries are sorted
before pack processing so output content and ordering are deterministic.
Pack validates supported members and rejects empty packs. It builds output in
a private directory beside the destination, then uses Kujo 1.4's atomic
no-replace directory publication: the requested destination is either absent
or contains the completed pack. Processing or publication failures do not
publish a partial pack. An audit run may remain incomplete after failure;
successful pack audits identify the published paths. Concurrent hostile
filesystem modification is outside the supported boundary. Pack checks each
eligible input again during processing to reapply normal safety checks.
The pack summary includes `published`, `auditComplete`, and `auditFailed`.
If audit finalization fails after publication, the command returns `1` while
leaving the published pack intact; use the read-only reconciliation check
described below before relying on the audit.

## CLI Reference

```text
redact scan <input> --policy <policy> [--audit-dir <dir>]
redact sanitize <input> --policy <policy> [--out <path>] [--fail-on-risk medium|high] [--audit-dir <dir>]
redact verify <input> --policy <policy> [--audit-dir <dir>]
redact pack <folder> --policy <policy> [--out <new-dir>] [--audit-dir <dir>]
redact version
redact help
```

Run these through `"$KUJO_BIN" run redact.kujo ...`.

Successful command output is JSON. Scan, sanitize, and pack summaries use
`schemaVersion: redact-cli-output/v1` and `productVersion: 1.0.0`. Verify uses
`schemaVersion: redact-verifier/v1`. Consumers may rely on documented fields
and must ignore unknown additive fields within the same schema major version.

Exit codes are:

- `0`: command succeeded; verify found no deterministic residual pattern;
- `1`: policy, input, path, I/O, size, pack, requested risk-threshold, or
  verification-risk failure; and
- `2`: missing arguments, unknown command, or other usage error.

`scan` returns `0` when it reports detections. `verify` returns `1` when its
risk score is `high`. `sanitize` returns `1` for risk only when
`--fail-on-risk` requests that threshold.

## Audit Artifacts

Scan, sanitize, and verify create a unique local run under
`.redact/runs/<timestamp>-<id>/` by default:

```text
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

Default detection events store hashes, classifications, spans, and replacement
decisions—not raw matched values. The policy snapshot stores actions, counts,
and a source-policy hash, not dictionary entries or role names. Audit metadata
still includes local paths, policy names, hashes, counts, timing, and output
information that may itself be sensitive. Keep audit directories protected,
local, access-restricted, and out of version control.

`--unsafe-store-originals` writes raw detections into that run's
`detections.jsonl`, marks `unsafeOriginalsStored: true`, and writes a danger
warning. It is a hazardous debugging escape hatch, never a normal workflow.
Isolate the run and delete it after the minimum review.

## Security and Privacy Limitations

Redact cannot defend against a compromised host, unsafe filesystem permissions,
undiscovered data classes, inference from retained context, confusable Unicode,
policy omissions, or human sharing of unreviewed output. It makes no compliance,
fitness, complete-removal, or arbitrary-domain certification claim.

Read [SECURITY.md](SECURITY.md), the detailed
[security boundary](docs/security.md), and the unapproved
[domain-signoff evidence](docs/domain-signoff/README.md) before sensitive use.
Final human domain signoff remains external to this repository.

## Examples

[`examples/README.md`](examples/README.md) contains copyable synthetic examples
for scan, sanitize, verify, pack, dictionaries, every transformation family,
machine-readable output, expected policy failure, and the explicit stdin
rejection. No example contains real personal or customer data or live secrets.

## Verification

```bash
export KUJO_BIN=/absolute/path/to/extracted/kujo
bash tests/run.sh
bash scripts/verify-all.sh
```

A runtime version mismatch fails before the test workload starts. For repeatable
synthetic performance measurements, run `python3 scripts/benchmark.py`; the
`--workload max-dictionary --samples 1` case checks a 1 MiB input against a
near-256 KiB policy. `repeated-dictionary`, `unicode-dictionary`,
`unicode-mixed`, `replacement-expansion`, `pack-batch`, and `pack-extended`
exercise frequent terms, contextual Unicode across policy categories,
bounded output expansion, and 1–2 MiB multi-file packs. Each reports time
and process peak memory where the host provides it. Timings
are observational, while output determinism and size contracts are CI gates.
The [Kujo 1.4.0 synthetic comparison](docs/audits/performance-1.4.0.md)
records the measured limits and the historical baseline's version difference.

The full gate checks all Kujo sources, deterministic and adversarial tests,
fixture commands, examples, product-version consistency, formatting, lint,
local Markdown links, generated-artifact hygiene, Kennel validation, and
ShipCheck. Release candidates additionally require the
[Workcell proof and hosted CI receipt](docs/release-process.md).
The hosted Verification workflow also install-smokes a clean committed source
archive on Linux, macOS, and Windows against checksum-verified Kujo 1.4.0
release binaries. Locally, `python3 scripts/install-smoke.py` uses `KUJO_BIN`
if set, or downloads and verifies the platform's official release asset.
After a pack interruption, the read-only
`python3 scripts/reconcile-pack-audits.py --audit-dir /path/to/audit` reports
whether published members match the pending or completed audit hashes. It
never repairs, removes, or certifies the output; retain both for review.

The [next review backlog](docs/audits/next-review-after-1.4.0.md) separates
remaining candidate work from verified behavior and release-only approvals;
the [prior review](docs/audits/next-review-2026-09-22.md) preserves the original proposals.
The [structured-input contract](docs/formats-next-major.md) describes the
requirements for potential CSV, JSON, recursive-pack and stdin additions;
none is implemented in 1.x.

## Compatibility and Upgrades

Redact 1.x currently requires Kujo 1.4.0 at the pinned release commit in
`RUNTIME_VERSION`. The version gate rejects other runtimes until they have
been deliberately validated. The CLI command names, documented exit
codes, `redact-policy/v1`, audit schemas, and JSON schema majors are stable
within 1.x. Additive fields may appear. Breaking contract changes require a
new schema major and release notes; product versions do not silently replace
schema versions.

Policies from 0.1.x must add `schemaVersion: redact-policy/v1` and conform to
the strict subset. See [CHANGELOG.md](CHANGELOG.md) and the
[release process](docs/release-process.md).
