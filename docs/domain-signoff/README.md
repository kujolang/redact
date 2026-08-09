# Synthetic Domain-Signoff Evidence Pack

Status: evidence prepared; human privacy/security approval not granted.

This pack gives an authorized reviewer a reproducible starting point for a
specific deployment domain. It is synthetic and cannot substitute for testing
authorized representative domain data under the organization's own handling
rules.

- [Test corpus](test-corpus.md)
- [Expected detections](expected-detections.md)
- [Accepted limitations](limitations.md)
- [Synthetic verifier output](verifier-output.json)
- [Residual risk](residual-risk.md)
- [Human checklist](checklist.md)

Reproduce the synthetic evidence with:

```bash
export KUJO_BIN=/path/to/kujo-1.0.0/target/release/kujo
bash tests/run.sh
bash tests/examples_smoke.sh
```

Do not commit real domain samples, customer material, credentials, audit runs,
or reviewer identity evidence. Store any authorized domain evidence in the
approved restricted system and reference its external review record in the
human release approval.
