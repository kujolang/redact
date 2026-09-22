# Structured-input contract proposal

Status: design decision only. Redact 1.x still accepts local `.txt` and `.md`
files and nonrecursive packs. No new parser, network dependency, or detection
claim is authorized by this document.

## Compatibility boundary

CSV, JSON, and recursive packs require a new product major and input/audit
schema majors. Existing `redact-policy/v1` actions and deterministic detectors
can be reused only where their meaning remains exact. A new format cannot be
advertised merely by treating its serialized bytes as plain text: escaping and
structure would otherwise change, and raw values could cross cell/key boundaries.
Bounded stdin could be an additive future CLI command only after Kujo exposes a
tested bounded multiline read with distinct EOF and I/O errors. It needs an
explicit `--input-type text|markdown`, a size limit, a non-path audit source
label, and a deliberate policy for audit metadata. Until those conditions
exist, `-` remains rejected; no fallback to line-oriented `input()` is safe.

## CSV

- Specify UTF-8, delimiter/quote/CRLF handling and a bounded dialect before
  implementation. Reject invalid quoting, oversized records and unknown
  encodings; do not autodetect spreadsheet formulas or encodings.
- Preserve row/column order and quoted-field semantics. Detect and transform
  only decoded cell content, then re-escape each changed cell. Unselected
  cells remain byte-identical where practicable; otherwise document canonical
  serialization and test it as a breaking output contract.
- Formula injection must not be introduced by a replacement. Document the
  recipient spreadsheet threat model separately from privacy detection.
- Audit fields need row/column coordinates rather than text-only scalar spans.

## JSON

- Define whether keys and numbers are ever in scope; the conservative first
  contract transforms string values only. Reject duplicate keys and excessive
  nesting rather than silently choosing one interpretation.
- Preserve primitive types and array order. String replacements must be JSON
  escaped and produce parseable output; define whether key ordering and
  whitespace are preserved or canonicalized before shipping.
- Audit references use a stable escaped JSON Pointer plus value-local offsets.
  Bounded parsing/serialization must enforce the existing input/output byte
  limits before allocation and publication.

## Recursive packs

- Specify an explicit `--recursive` flag and deterministic normalized relative
  paths. Reject traversal, symlinks, cycles, special files, duplicate/colliding
  names, and output directories under the input tree.
- Cap file count, nesting, aggregate bytes, audit volume, and elapsed work;
  per-file limits alone do not bound a tree.
- Stage and atomically publish the complete destination using the current
  no-replace directory primitive. Tests must cover late failure and cleanup;
  audit references must point to final relative paths.

## Release criteria

Each format needs synthetic round-trip tests, malformed-input fuzz matrices,
determinism checks, cross-platform path/encoding tests, leakage-verifier parity,
memory/CPU evidence, and a specific privacy/security review. New schema majors
and migration notes must precede any implementation claim. Human domain
approval remains external, and a low verifier score remains only a bounded
deterministic observation.
