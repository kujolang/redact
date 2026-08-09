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

Redact requires the released Kujo 1.0.0 runtime at commit
`2b3e07d398016e92008d8399e79c441e012dce38`.

```bash
git clone https://github.com/kujolang/redact.git
cd redact
export KUJO_BIN=/path/to/kujo-1.0.0/target/release/kujo
"$KUJO_BIN" --version
"$KUJO_BIN" run redact.kujo version
```

Expected versions are `kujo 1.0.0` and `redact 1.0.0`. Kennel consumers use
`kennel.toml`; no registry publication is required for a source checkout.

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
- UTF-8 text accepted by Kujo 1.0.0;
- `redact-policy/v1`, the documented flat-YAML policy subset;
- deterministic categories and configured term dictionaries;
- `remove`, `placeholder`, `role-preserve`, `generalize`, `range`, and
  `date-generalize` transformations;
- deterministic post-transformation leakage verification;
- protected local audit artifacts without raw matches by default;
- deterministic, non-recursive folder pack generation;
- documented CLI, JSON schema, and exit-code behavior; and
- offline execution without AI-provider calls.

Symbolic-link paths, traversal segments, source overwrites, oversized inputs or
outputs, malformed UTF-8, unsupported extensions, and ambiguous policy YAML
fail closed. Pack output must be a new directory.

### Supported inputs and stdin decision

Only local `.txt` and `.md` file paths are supported. `-` stdin is explicitly
not supported in Redact 1.0.0. Kujo 1.0.0 exposes only a line-oriented
`input()` primitive; EOF and read errors are not distinguishable and there is
no bounded multiline read. Redact therefore rejects `-` rather than advertise
an unsafe or incomplete contract. Bounded multiline stdin is a post-1.0
enhancement contingent on a suitable runtime API.

## Policy Contract

Every policy declares `schemaVersion: redact-policy/v1`, a non-empty `name`,
category actions, boolean safety fields, and optional `terms` and `roles`
mappings. The supported structure is shown in
[`examples/policy.yaml`](examples/policy.yaml).

Policy files are limited to 262,144 bytes and must pass the same regular-file,
traversal, and symbolic-link checks as inputs.

Supported configured dictionaries are `person_names`, `company_names`,
`customer_names`, `product_names`, and `launch_strategy`. Legacy top-level
aliases (`person_dictionary`, `company_dictionary`, `customer_dictionary`,
`product_dictionary`, and `strategy_terms`) remain readable in 1.x, but new
policies should use `terms`.

Nested objects beyond `terms` and `roles`, flow collections, anchors, aliases,
tags, multiline scalars, tabs, duplicate top-level keys, and unknown fields are
unsupported and fail with a line-specific policy error. `ai_assist` and
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
export KUJO_BIN=/path/to/kujo-1.0.0/target/release/kujo
bash tests/run.sh
bash scripts/verify-all.sh
```

The full gate checks all Kujo sources, deterministic and adversarial tests,
fixture commands, examples, product-version consistency, formatting, lint,
local Markdown links, generated-artifact hygiene, Kennel validation, and
ShipCheck. Release candidates additionally require the
[Workcell proof and hosted CI receipt](docs/release-process.md).

## Compatibility and Upgrades

Redact 1.x requires Kujo 1.0.0 or newer behavior compatible with the pinned
runtime commit in `RUNTIME_VERSION`. The CLI command names, documented exit
codes, `redact-policy/v1`, audit schemas, and JSON schema majors are stable
within 1.x. Additive fields may appear. Breaking contract changes require a
new schema major and release notes; product versions do not silently replace
schema versions.

Policies from 0.1.x must add `schemaVersion: redact-policy/v1` and conform to
the strict subset. See [CHANGELOG.md](CHANGELOG.md) and the
[release process](docs/release-process.md).
