# Redact Architecture

Redact is a Kujo 1.0 command-line package with a root entrypoint, source modules,
synthetic fixtures/examples, deterministic tests, and local-only artifacts.

## Pipeline

```text
validate policy and paths
  -> load bounded UTF-8 .txt/.md
  -> deterministic detect
  -> policy decision
  -> transform
  -> deterministic verify
  -> bounded file or sorted pack output
  -> local safe-by-default audit at each executed stage
```

Stdin and provider calls are outside this pipeline.

## Modules

- `src/cli.kujo`: command, flag, JSON, exit-code, pack, and output contracts.
- `src/document.kujo`: supported extensions, size limits, UTF-8 loading, and
  source/output safety.
- `src/policy.kujo`: strict `redact-policy/v1` parsing and action validation.
- `src/detect.kujo`: deterministic patterns, Luhn validation, and configured
  case-insensitive longest-first terms.
- `src/transform.kujo`: stable replacements and transformation events.
- `src/verify.kujo`: post-transform deterministic residual-risk checks.
- `src/audit.kujo`: unique run directories and raw-free default artifacts.
- `src/version.kujo`: product and schema identities.
- `src/ai_provider.kujo`: uninvoked future adapter contract only.

## Stable envelopes

The document envelope contains `source_path`, `input_type`, `content`,
`content_hash`, `metadata`, and `warnings`. Detection objects contain
`detector_id`, `category`, spans, `matched_value_hash`, confidence, reason,
suggested action, and an in-memory value. The value is required for local
transformation and is omitted from default audits.

Transformations consume detections; they do not independently discover values.
Repeated exact values use a stable replacement. Configured terms are evaluated
longest-first to prevent shorter configured terms from corrupting overlapping
phrases. Pack inputs are sorted by filename and processed non-recursively.

## Versioned contracts

Product version `1.0.0` is independent of:

- `redact-policy/v1`;
- `redact-cli-output/v1`;
- `redact-verifier/v1`;
- `redact-audit/v1`;
- `redact-input-manifest/v1` and `redact-output-manifest/v1`; and
- `redact-policy-snapshot/v1`.

Schema majors change only for breaking contract changes. Product releases may
add fields while preserving a schema major.

## Failure ordering

The CLI loads and validates a policy, validates the audit target, then validates
the input. Sanitize validates the output before creating its audit run. Policy,
path, type, size, and read failures stop before transformation or output writes.
Oversized transformed output stops before the output write; a partial raw-free
audit may remain and is subject to normal audit protection.

Verify returns exit `1` when supported leakage checks remain. Sanitize returns
exit `1` for residual risk only when the selected `--fail-on-risk` threshold is
met. Pack rejects existing output directories to avoid stale or mixed packs.

## Extension rules

New detectors must remain deterministic, document false-positive/false-negative
behavior, add synthetic adversarial tests, preserve raw-free audits, and extend
the verifier where appropriate. New input types, YAML structures, AI adapters,
network behavior, or schema majors are not compatible 1.x additions without an
explicit contract and security review.
