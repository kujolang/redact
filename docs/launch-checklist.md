# Launch Checklist

Current launch scope: `locally verified technical preview`. Redact's deterministic fixture suite, sample expected-output checks, and Workcell proof pass locally, but complete PII removal, compliance guarantees, and target-domain privacy signoff are not complete.

## Local Gates

- [x] Runtime check executed with `$KUJO_BIN check redact.kujo`.
- [x] Test suite checked with `bash tests/run.sh`.
- [x] Fixture scan checked with `$KUJO_BIN run redact.kujo scan fixtures/sample.md --policy fixtures/sample.policy.yaml`.
- [x] Fixture sanitize checked with `$KUJO_BIN run redact.kujo sanitize fixtures/sample.md --policy fixtures/sample.policy.yaml --out /tmp/redact-next-batch-sample.redacted.md`.
- [x] Fixture verify checked with `$KUJO_BIN run redact.kujo verify /tmp/redact-next-batch-sample.redacted.md --policy fixtures/sample.policy.yaml`.
- [x] Formatting checked with `git diff --check`.
- [x] Workcell proof checked with `workcell run --file docs/workcell-launch-gate.json --repo . --no-pull`.
- [ ] Domain-specific privacy/security signoff.

## Workcell Proof Notes

Workcell proof passed after building `kujolang/workcell-base:local` with `DOCKER_BUILDKIT=0`, using the Colima Workcell Docker host, and setting `TMPDIR` to a path under `/Users/robertdevore/2026/Kujolang/kujo-repos/.workcell-host-tmp` so the disposable worktree mount was visible inside the Colima VM.

Resume command:

```bash
export DOCKER_HOST=unix:///Users/robertdevore/.colima/kujo-workcell/docker.sock
export DOCKER_CONFIG=/tmp/kujo-next-batch-docker-config
export TMPDIR=/Users/robertdevore/2026/Kujolang/kujo-repos/.workcell-host-tmp
workcell run --file docs/workcell-launch-gate.json --repo . --no-pull
workcell verify --run .workcell/runs/<run-id> --json
```

## Forbidden Launch Actions

Live credentials, hosted deployment, package publication, final release tags, public releases, signing/notarizing, branch-protection changes, force-pushes, complete-redaction claims, and compliance guarantees remain out of scope.
