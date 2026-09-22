# Five reproduced Redact regressions

These failures were observed on `91658d5` with released Kujo 1.4.0 using
synthetic data. The corrected checks live in `tests/bug_regressions.kujo` and
`tests/cli_bug_regressions.sh`, both included in `tests/run.sh`.

| Failure on `91658d5` | Correct behavior and regression |
| --- | --- |
| `ai_assist: "false"` parsed successfully as a boolean, even though quoted YAML is a string. | Reject quoted policy safety booleans; keep literal `false` valid. |
| An unquoted list mapping `- Customer: Internal` parsed as a literal configured term. | Reject mapping syntax; allow the quoted literal `"Customer: Internal"`. |
| For `x2025-01-01 2025-01-01`, the date regex matched at scalar 12 but the detection claimed scalar 1 (the earlier embedded occurrence). Phone and card match spans had the same defect. | Derive spans from the regex match boundaries; test all three detector families. |
| Sanitizing `note.MD` without `--out` wrote `note.MD.redacted`, which `verify` refuses as an unsupported extension. | Write `note.redacted.MD` and successfully verify it. |
| Sanitizing with `--out` set to the active policy path succeeded and replaced the policy file. | Reject the existing policy-file alias before creating an audit or writing output. |

Reproduce the original failures in an isolated checkout of `91658d5` by
copying the two synthetic regression tests into its `tests/` directory and
running them with `KUJO_BIN` set to the released Kujo 1.4.0 executable. The
Kujo test fails at the quoted-boolean assertion, and the CLI test reports both
the unverifiable uppercase output and the overwritten policy. On the fixed
candidate, run `bash scripts/verify-all.sh` and
`python3 scripts/install-smoke.py` with the same `KUJO_BIN`. These tests prove
the listed cases, not complete redaction or absence of unrelated defects.
