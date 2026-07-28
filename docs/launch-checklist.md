# Launch Checklist

Current launch scope: `locally verified technical preview`. Redact's deterministic fixture suite and sample expected-output checks pass locally, but complete PII removal, compliance guarantees, target-domain privacy signoff, and Workcell proof are not complete.

## Local Gates

- [x] Runtime check executed with `$KUJO_BIN check redact.kujo`.
- [x] Test suite checked with `bash tests/run.sh`.
- [x] Fixture scan checked with `$KUJO_BIN run redact.kujo scan fixtures/sample.md --policy fixtures/sample.policy.yaml`.
- [x] Fixture sanitize checked with `$KUJO_BIN run redact.kujo sanitize fixtures/sample.md --policy fixtures/sample.policy.yaml --out /tmp/redact-next-batch-sample.redacted.md`.
- [x] Fixture verify checked with `$KUJO_BIN run redact.kujo verify /tmp/redact-next-batch-sample.redacted.md --policy fixtures/sample.policy.yaml`.
- [x] Formatting checked with `git diff --check`.
- [ ] Workcell proof checked with `workcell run --file docs/workcell-launch-gate.json --repo .`.
- [ ] Domain-specific privacy/security signoff.

## Current External Blocker

Workcell proof is blocked by the local Docker image build/pull path. The Workcell base image could not be fetched from Docker Hub because `auth.docker.io` timed out.

Closest equivalent proof: Redact deterministic tests and fixture scan/sanitize/verify checks.

Safe resume command:

```bash
cd /Users/robertdevore/2026/Kujolang/kujo-repos/workcell
DOCKER_HOST=unix:///Users/robertdevore/.colima/kujo-workcell/docker.sock docker build --tag kujolang/workcell-base:local docker/
cd /Users/robertdevore/2026/Kujolang/kujo-repos/redact
workcell run --file docs/workcell-launch-gate.json --repo .
```

## Forbidden Launch Actions

Live credentials, hosted deployment, package publication, final release tags, public releases, signing/notarizing, branch-protection changes, force-pushes, complete-redaction claims, and compliance guarantees remain out of scope.
