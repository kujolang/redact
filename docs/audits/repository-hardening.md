# Redact repository hardening — 2026-09-07

## Repository and scope

- Repository: `kujolang/redact`; branch: `main`.
- Starting SHA: `d58facf61df5e643a26f3e5f4bb705731237226e` (clean worktree).
- Ending implementation SHA: b398462716ae6ec13e9d2c0ff2e83998623384c9. The subsequent report-only
  commit records this receipt; its identity is available with
  `git log -1 --format=%H -- docs/audits/repository-hardening.md`.
- Purpose: offline, deterministic, policy-driven redaction of bounded local text
  and Markdown, with verification, local audits, and sorted nonrecursive packs.
- Runtime: Kujo release commit `2b3e07d398016e92008d8399e79c441e012dce38`.
  No package dependencies. Verification integrates Kennel
  `6df043c3ba0bde4445cc8f8f7d4c01c60c9c6d7e` and ShipCheck
  `2768e3040e766b0befd354db4427afc4c7a81899`, matching hosted CI.

Reviewed the entrypoint, all ten implementation modules, tests, examples,
fixtures, policies, manifests, scripts, workflows, and architecture/security/
release documentation. An independent offline security reviewer inspected the
implementation, tests and workflows, then reviewed the changes. The documented
shared-host races, hardlinks, Unicode confusables and domain coverage limitations
remain explicit exclusions from security guarantees.

## Baseline

The first `bash scripts/verify-all.sh` used the machine's default Kujo 1.3.1.
Source checks, unit, CLI, policy, security and example suites passed; the gate
then failed its exact Kujo 1.0.0 version assertion. This was an environment
mismatch, not a newly introduced failure. No assertion or gate was relaxed.

The published Kujo v1.0.0 macOS x64 runtime was downloaded from the official
release. Its tag resolves to the exact commit in RUNTIME_VERSION. The published
archive SHA-256 verified as
`a264f214ec8f5afbf4720c5ac8803fffd7e504c722970245327fd910f8c1474f`;
the extracted executable SHA-256 is
`5052c5699db6bc502954cf9f6bb5bdc17ae1d2551e3609a485fefe059fb11321`.
It reports `kujo 1.0.0`. A local locked source build was also attempted, then
stopped after the verified released binary became available; it is not claimed
as a passing build. Pinned runtime source was inspected for builtin semantics.

The baseline was preserved in a separate local clone at the starting SHA; pinned
gate-tool snapshots were extracted without modifying sibling repositories.
The complete baseline gate passed on the released runtime: unit/adversarial/CLI/
examples, formatting/lint, links, artifact hygiene, Kennel and ShipCheck
(16/16 checks, zero warnings). The same complete gate passed after implementation.

The starting commit's hosted Verification had already passed:
[baseline run](https://github.com/kujolang/redact/actions/runs/31530087081).
This is historical baseline evidence, not proof for the changed commit.

## Findings

| ID | Priority | Area | Finding and evidence | Action | Status |
| --- | --- | --- | --- | --- | --- |
| R1 | P1 | Filesystem | CLI checked audit root, then `audit_start` appended unchecked `runs/<id>`. Synthetic `runs` symlink redirected baseline writes. | Validate full derived run path and propagate failure in all commands. | Fixed; negative regression. |
| R2 | P1 | Filesystem | Symlink inspection rewrote POSIX backslashes while reads/writes used literal names. | Inspect the actual spelling; retain ordinary backslash filenames. | Fixed; deny symlink and allow regular-file regressions. |
| R3 | P1 | Resource/correctness | Expansion was allocated and verified before size validation; runtime `len` counts scalars, not UTF-8 bytes. | Check projected bytes before each replacement and check output before verification. | Fixed; Unicode cap, expansion and preserved-output regressions. |
| R4 | P1 | Performance | Two selection sorts nested linear membership scans, giving cubic comparison work; string search and replacement copied unnecessarily. | Shared stable merge ordering, native literal search/replacement, exact-key detection membership and shared native digit filtering. | Fixed; output equivalence and measured workloads. |
| R5 | P1 | Performance | Configured matching repeatedly materialized the entire source string through Kujo 1.0 `substring`. | Materialize scalars once when dictionaries exist; slice only candidate spans. | Fixed; context-sensitive Unicode regression and measured dictionary workload. |
| R6 | P2 | Filesystem | Existing special output files could be replaced by atomic output writes. | Reject nonregular output targets. | Fixed; FIFO remains intact. |
| R7 | P2 | Policy | Nonstring/collection names and missing category colons were accepted; snapshot names were unescaped. | Validate scalar shape/type and colon; preserve quoted string names and quote snapshot names. | Fixed; positive/negative parser regressions. |
| R8 | P2 | Developer workflow | Runtime version mismatch was detected after the expensive test workload. | Run the existing version gate first. | Fixed; no weakened version check. |

## Changes implemented and compatibility

**Filesystem boundaries:** `src/util.kujo`, `src/audit.kujo`, `src/document.kujo`
and `src/cli.kujo` now check the path that is actually used, including derived
audit descendants. `tests/hardening_contract.py` exercises symlink escape,
literal names, FIFO inputs/policies/outputs, failed expansion, and simultaneous
scan runs. The four concurrent scans must produce four distinct valid, raw-free
audit runs. The trusted system `/tmp` and `/var` aliases remain accepted.

**Output expansion:** `utf8_size` derives byte length from the pinned runtime's
native Base64 encoding and padding. This avoids file I/O and compensates for the
runtime's character-counting `len`. Only the temporary encoding is retained
during measurement. Transformation tracks byte size and rejects projected growth
before constructing it. The CLI handles `{ok: false, error: ...}` from the
transformer before reading its document and runs the verifier only after the
size check. `tests/hardening_tests.kujo` checks empty/padded/multibyte lengths,
the exact 2 MiB boundary, one character over it, and repeated long Unicode roles.
Intermediate output above the limit now fails even if a later rule could shrink
it; this is an intentional resource-safety restriction.

**Efficient deterministic processing:** `src/util.kujo`, `src/detect.kujo` and
`src/transform.kujo` share stable descending-length ordering. Equal lengths keep
original detector/category precedence. Exact-string dictionary membership
preserves deduplication behavior. Native `index_of` returns scalar offsets and
native `replace` performs literal replacement, matching the former helpers.
Duplicate ASCII digit filters now share native replacement, and role tokens use
native uppercase/separator replacement. Regression coverage includes non-ASCII
digits, expanding uppercase characters and a 50,000-digit amount. The pinned
runtime and Rust uppercase implementation were checked for equivalence.
The dictionary character array is created only when a dictionary is present
and is shared across category passes. It adds O(document scalars) temporary
storage to remove repeated full-document character copies; no memory reduction
percentage is claimed. Matching still lowercases each original candidate, which
matters for Greek final sigma (`ΟΣ` within `ΟΣΑ`). A whole-document lowercase
shortcut was rejected during review and is not in the implementation.

The unchanged fixture snapshot and the new ordering, Unicode, literal-replacement
and boundary tests are exercised by `tests/run.sh` and therefore existing CI.
`src/audit.kujo` also reuses a computed output hash for its two manifest fields.
The standalone `scripts/benchmark.py` preserves timing samples and checks output
hash determinism; it is intentionally not a noisy wall-clock CI budget.

**Policy and documentation:** `src/policy.kujo` rejects malformed name scalars
and missing category colons, retaining valid quoted names. Audit snapshots quote
the name as a YAML-compatible JSON string so it cannot become a boolean or collection. README, architecture,
security docs and changelog describe the changed failure behavior. No unrelated
documentation rewrite, dependency substitution, dead-code removal or schema
redesign was justified. The documented, exported future AI contract is retained.

Contract impact:

- CLI command names, flags, successful envelopes and documented exit codes unchanged.
- No schema major, serialization field, configuration field or environment-variable change.
- Exported transformer and audit initializer can now return the established error
  envelope for oversized expansion or invalid derived paths; callers must inspect
  `ok`. Signatures are unchanged and CLI propagation is covered.
- Previously unsafe symlink/special-output targets, malformed policy scalars and
  oversized UTF-8/intermediate outputs are rejected. Valid fixtures remain identical.
- Audit manifest `length` fields retain their existing scalar-count semantics;
  byte limits use the separate size helper and do not silently redefine fields.
- Known external documentation consumers use the existing CLI and remain compatible.

## Performance and efficiency

| Workload (3 samples per revision) | Input bytes | Output bytes, unchanged | Baseline median | Final median |
| --- | ---: | ---: | ---: | ---: |
| emails | 2,090 | 1,092 | 8.737s | 5.680s |
| dictionary | 7,516 | 7,511 | 2.582s | 1.826s |

The emails workload contains 100 distinct emails and a repeated domain. The
dictionary workload contains 7,516 bytes with one configured hit and one absent
term. All before/after output SHA-256 values match. Raw samples, hashes and
version identities are retained in [performance.json](performance.json).

These are local end-to-end sanitize timings including runtime startup, detection,
transformation, verification, output and audit writes. They are workload-specific,
not universal throughput claims. Both workloads compare the same pinned runtime,
policy/input and benchmark script against the baseline and final source. The
script validates detection count, low verifier risk and deterministic output hash.

Algorithmic evidence: stable ordering removes cubic comparison work. Native
literal search and replacement eliminate interpreted character scans and repeated
output concatenation. Candidate slices remove repeated full-document Unicode
materialization. There is no application-level network, subprocess, model call,
retry queue, cache or persistent in-memory service state. Resource limits remain
1 MiB input, 256 KiB policy and 2 MiB output; pack files process sequentially.
Audits intentionally accumulate on disk and require the documented retention
policy. Very large dictionaries still require work proportional to their terms
and candidate lengths; no universal CPU or process-RSS bound is asserted.

No model-token metric applies: Redact makes no model calls or prompt/schema
registrations. Agent instructions are already compact. Successful commands emit
small JSON receipts and keep detailed evidence in local audit files; pack success
already suppresses per-file receipts. No information was removed to reduce
output. Dependency count remains zero before and after. Binary/build-size and
model-token percentage claims would be misleading and are omitted.

## Security and supply chain

Reviewed policy parsing, local-file type/size/UTF-8 checks, path spelling and
symlinks, source aliases, output writes, derived audit paths, raw-value handling,
transformation growth, deterministic ordering, failure paths, concurrent audit
creation and pack boundaries. Default audit detections stay raw-free; explicit
unsafe-original mode and metadata sensitivity remain documented. No network,
provider execution, shell evaluation or deserialization capability was added.

Package manifests contain no dependencies. CI actions, runtime and gate-tool
revisions are pinned; workflows use read-only repository permissions, quoted
shell inputs, locked runtime builds and verification before release artifacts.
The Kujo runtime's transitive dependencies were not upgraded or certified free
of advisories in this repository pass. No supported scope was removed.

The security scan artifacts retain the four baseline security/resource findings,
source evidence and reviewed boundaries in the local evidence directory. They
are baseline findings remediated here, not an assertion of open vulnerabilities
at the ending implementation SHA. TAC advisory could not be verified because
the connector was disconnected; the local audit and independent review completed.

## Cross-repository follow-ups and remaining work

No other repository must change to use these improvements. The pinned runtime
remains supported without an ecosystem migration. A native UTF-8 byte-length
primitive could remove the temporary Base64 size calculation in a future runtime;
this is optional, not a correctness dependency or requested sibling change.

- P0/P1: no unresolved issue established by this pass.
- P2: no mandatory implementation follow-up.
- Needs more evidence: performance budgets for real domain dictionaries; the
  synthetic benchmark is reproducible but does not justify a universal time gate.
- Not worth changing here: retained exported future AI contract, documented
  detection limitations, and the runtime's broad transitive dependency surface.
- Human domain signoff and release-only Workcell proof/tag approvals are separate
  release processes. This audit does not grant them or publish a release.

## Verification receipt

The following commands ran successfully unless explicitly marked otherwise.
Here `E` is the evidence directory below, `K=$E/released/kujo`, and the
repository working directory is Redact unless another directory is stated.

```bash
# Runtime provenance
git -C ../kujo rev-parse 'v1.0.0^{commit}'
# In $E/released, after downloading the official v1.0.0 archive/checksum:
shasum -a 256 -c kujo-v1.0.0-macos-x64.tar.gz.sha256
"$K" --version
shasum -a 256 "$K"

# Passed at the starting SHA in $E/baseline, and after implementation in Redact:
KUJO_BIN="$K" KENNEL_REPO="$E/kennel" SHIPCHECK_REPO="$E/shipcheck" bash scripts/verify-all.sh

# Three samples each, sequentially; all four commands passed:
KUJO_BIN="$K" python3 scripts/benchmark.py --repo "$E/baseline"
KUJO_BIN="$K" python3 scripts/benchmark.py --repo "$E/baseline" --workload dictionary
KUJO_BIN="$K" python3 scripts/benchmark.py
KUJO_BIN="$K" python3 scripts/benchmark.py --workload dictionary

python3 -m py_compile scripts/benchmark.py tests/hardening_contract.py
git diff --check
bash scripts/build-release-artifacts.sh "$E/artifacts-a" HEAD
bash scripts/build-release-artifacts.sh "$E/artifacts-b" HEAD
diff -r "$E/artifacts-a" "$E/artifacts-b"

# Extracted source artifact at implementation SHA; version and scan passed:
"$K" run redact.kujo version
"$K" run redact.kujo scan fixtures/sample.md --policy fixtures/sample.policy.yaml --audit-dir "$E/install-audit"
```

The full gate includes every source check, unit and hardening test, CLI/policy/
security/example shell suite, product-version consistency, formatting/lint,
Markdown links, Git whitespace and artifact hygiene, Kennel validation and
ShipCheck (16/16 passed, no warnings). Artifact builds verify their own checksums;
the two complete artifact directories were byte-identical. The installation
scan returned the expected schema, detections and safe-original flag.

Expected/recovered failures: the original default-runtime gate and the explicit
runtime-mismatch check exit 1 on Kujo 1.3.1. The new filesystem regression fails
against baseline audit descendant handling and passes after the fix. The
superseded local source build was stopped (exit 143), not reported as passed.
A trailing blank line introduced during formatting was removed; the final
formatter and `git diff --check` pass.

A canonical source-backed security scan was finalized successfully with
`finalize_scan_contract.py --scan-dir "$E/security-scan" --source-root "$E/baseline"`.
The generated report and canonical JSON are retained locally. Subsequent exact
commit/remote/hosted receipts are recorded in the Strata session handoff.


Evidence directory: /private/tmp/redact-hardening.MCcn2J. Logs are local artifacts, not source
or raw user data. All new test material is synthetic. No sibling source was
modified. No release tag, package publication or deployment was performed.
