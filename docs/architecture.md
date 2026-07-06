# Redact Architecture

Redact is organized as replaceable Kujo modules under `.kujo/src`.

## Pipeline

```text
input -> extract -> detect -> apply policy -> transform -> verify -> export
                         \-> audit ledger at every step
```

## Core Contracts

- Input adapter and extractor: `.kujo/src/document.kujo` returns a document envelope with `source_path`, `input_type`, `content`, `content_hash`, `metadata`, and `warnings`.
- Detector: `.kujo/src/detect.kujo` returns detection objects with `detector_id`, `category`, `span_start`, `span_end`, `matched_value_hash`, `confidence`, `reason`, and `suggested_action`.
- Policy engine: `.kujo/src/policy.kujo` loads YAML policy actions and configured term dictionaries.
- Transformer: `.kujo/src/transform.kujo` consumes detector output plus policy decisions. It does not independently scan for new sensitive values.
- Verifier: `.kujo/src/verify.kujo` performs deterministic post-transform leakage checks and emits a risk report.
- Audit ledger: `.kujo/src/audit.kujo` writes local JSON and JSONL artifacts without raw sensitive values by default.
- AI provider: `.kujo/src/ai_provider.kujo` defines the future provider log contract without making model calls.

## Folder Structure

```text
.kujo/redact.kujo          CLI entrypoint
.kujo/src/*.kujo           adapters, policy, detectors, transforms, verify, audit
.kujo/redact_tests.kujo    native Kujo unit snapshot test
policies/*.yaml            built-in MVP policies
fixtures/*                 sample input, policy, expected redaction
tests/run.sh               check plus end-to-end test runner
docs/architecture.md       module contracts and extension notes
```

## Policy Schema

Policies are flat YAML files with a required `name`, category action fields, boolean safety fields, optional configured dictionaries, and optional role mappings.

Supported category actions are `remove`, `placeholder`, `role-preserve`, `generalize`, `range`, and `date-generalize`.

Dictionary keys may use the canonical shape:

```yaml
terms:
  person_names:
  - Robert
```

or the legacy local fixture aliases `person_dictionary`, `company_dictionary`, `customer_dictionary`, `product_dictionary`, and `strategy_terms`.

## Audit Event Schema

Detection audit events contain:

```text
detector_id, category, span_start, span_end, matched_value_hash,
confidence, reason, suggested_action
```

Decision events contain:

```text
category, detector_id, matched_value_hash, action, replacement, reason
```

Transformation events contain:

```text
category, matched_value_hash, replacement, occurrences, span_start, span_end
```

Raw originals are excluded unless `--unsafe-store-originals` is explicitly passed.

## Interfaces

Detector modules accept a document envelope plus policy and return `{"ok": true, "detections": [...]}`. A future detector can be registered by returning the same detection object shape.

Transformer modules accept a document envelope, detections, and policy. They return a new document envelope plus decision and transformation event arrays.

Verifier modules accept a document envelope and policy. They return `risk_score`, `reason`, remaining deterministic leakage counts, and warnings.

AI providers must implement stage-specific calls behind the future provider contract in `.kujo/src/ai_provider.kujo`. Every future call must log provider, model, endpoint type, prompt template id/version, input hash, output hash, policy, stage, invocation reason, and whether original, partially redacted, or fully redacted content was exposed.

## Adding Modules

New adapters, detectors, transformers, verifiers, exporters, and AI providers should be added as separate `.kujo/src/*` modules and wired through the CLI/pipeline boundary. The pipeline should depend on stable envelopes, not concrete implementation details.

## Failure Behavior

Policy load failure stops before transformation. Unsupported input returns a clear error. Audit setup happens before detector output is emitted. Individual detector expansion should return warnings instead of forcing the whole run to fail unless the policy introduces a hard-stop mode.
