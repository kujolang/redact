# Redact Release Process

## Preconditions

An authorized human identifies the exact candidate SHA, confirms the working
tree is clean, reviews the [launch checklist](launch-checklist.md), and signs
the target-domain [privacy/security checklist](domain-signoff/checklist.md).
Use Kujo v1.0.0 commit
`2b3e07d398016e92008d8399e79c441e012dce38`.

```bash
git switch codex/redact-v1-release-prep
git pull --ff-only
export KUJO_BIN=/Users/robertdevore/2026/Kujolang/kujo-repos/kujo/target/release/kujo
test "$("$KUJO_BIN" --version)" = "kujo 1.0.0"
test "$(git -C ../kujo rev-parse v1.0.0^{commit})" = "$(cat RUNTIME_VERSION)"
bash scripts/verify-all.sh
git status --short
git rev-parse HEAD
```

Record the candidate SHA. Re-run the fixture commands from [AGENTS.md](../AGENTS.md)
if `verify-all` output is not retained by the reviewer.

## Workcell proof and receipt

Workcell must prove the exact committed candidate, not an uncommitted worktree.
Use the documented local Docker host when required:

```bash
export DOCKER_HOST=unix:///Users/robertdevore/.colima/kujo-workcell/docker.sock
export DOCKER_CONFIG=/tmp/redact-v1-docker-config
export TMPDIR=/Users/robertdevore/2026/Kujolang/kujo-repos/.workcell-host-tmp
workcell run --file docs/workcell-launch-gate.json --repo . --no-pull
workcell verify --run .workcell/runs/<run-id> --json
```

Confirm the receipt source commit equals the candidate SHA. Do not commit
`.workcell/` evidence. If the job cannot start, record the run/tool state,
closest passing local evidence, required human infrastructure action, and the
safe resume commands above; local evidence does not replace the receipt.

## Hosted Verification

Open the branch's latest
[Verification run](https://github.com/kujolang/redact/actions/workflows/verification.yml).
Confirm its `head_sha` equals the candidate and every step started and passed.
If organization or runner controls stop the job before steps start, do not
bypass them. Record the workflow/run URL, job state, confirmation that no steps
started, closest passing local gate, the repository/organization owner action
needed to enable the runner, and this safe resume command:

```bash
gh workflow run verification.yml --ref codex/redact-v1-release-prep
```

## Candidate artifacts

Before tagging, a reviewer may build disposable artifacts from the committed
SHA outside the repository:

```bash
candidate_sha="$(git rev-parse HEAD)"
artifact_dir="$(mktemp -d /tmp/redact-v1-artifacts.XXXXXX)"
scripts/build-release-artifacts.sh "$artifact_dir" "$candidate_sha"
cd "$artifact_dir"
shasum -a 256 -c redact-1.0.0-checksums.txt
```

Expected files are:

- `redact-1.0.0-source.tar.gz`;
- `redact-1.0.0-package.zip`;
- `redact-1.0.0-provenance.json`; and
- `redact-1.0.0-checksums.txt`.

The tag-triggered `release-artifacts` workflow runs the real Verification
workflow first and uploads the same source/package artifact shapes. It has
read-only repository permissions and does not create a GitHub release or
publish to Kennel. Pushing a preparation branch cannot trigger it.

## Human-approved tag and release

Only after all approvals, an authorized human may run:

```bash
candidate_sha="<approved exact SHA>"
test "$(git rev-parse "$candidate_sha^{commit}")" = "$candidate_sha"
git tag -a v1.0.0 "$candidate_sha" -m "Redact v1.0.0"
git push origin v1.0.0
```

Review the tag-triggered workflow and checksums. Prepare the GitHub release from
[`docs/releases/v1.0.0.md`](releases/v1.0.0.md), attach only verified artifacts,
and create the release only after a second human confirms the tag SHA and
checksums. Kennel publication is a separate human-authorized action and is not
part of this workflow.

## Post-release installation smoke

Extract a verified artifact into a new temporary directory and run:

```bash
"$KUJO_BIN" run redact.kujo version
"$KUJO_BIN" run redact.kujo scan fixtures/sample.md --policy fixtures/sample.policy.yaml --audit-dir /tmp/redact-v1-install-audit
```

Confirm `redact 1.0.0`, successful JSON output, no network/provider access, and
raw-free default audit artifacts.

## Rollback and correction

Do not force-move or reuse a published tag. If failure occurs before the GitHub
release, stop and leave the failed workflow receipt for review. If a release is
already public, mark it affected, preserve provenance, correct the issue on a
new branch, and publish a new patch version after the same gates. Remove or
yank artifacts only through an explicit repository-owner incident decision;
never silently replace checksummed assets.
