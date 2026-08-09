# Redact 1.0.0 Release Checklist

This checklist prepares an exact commit for human-approved tagging. Passing it
does not certify complete redaction, compliance, or arbitrary-domain fitness.

## Repository and product

- [x] Product version surfaces declare `1.0.0`.
- [x] MIT `LICENSE`, `VERSION`, `RUNTIME_VERSION`, `kennel.toml`,
  `CONTRIBUTING.md`, and `SECURITY.md` exist.
- [x] README contains stable onboarding, badges, scope, limitations, examples,
  CLI/JSON/exit-code contracts, and compatibility policy.
- [x] `-` stdin is explicitly rejected and documented as post-1.0.
- [x] Synthetic examples cover every stable command and transformation family.
- [x] Product and schema versions remain independent.

## Privacy and security

- [x] Adversarial tests cover patterns, dictionaries, overlap, repetition,
  Unicode/confusables within scope, malformed policies, path/symlink/traversal,
  overwrite prevention, size limits, malformed UTF-8, audit leakage,
  determinism, pack boundaries, and unsafe-original isolation.
- [x] Default policy snapshots omit configured terms and role names.
- [x] Synthetic domain-signoff evidence and residual risks are prepared.
- [ ] Authorized human privacy/security owner approves the target domain.
- [ ] Release owner confirms audit storage, access, retention, and destruction
  procedures for the intended deployment.

## Exact candidate gates

- [ ] `bash scripts/verify-all.sh` passes on the final commit.
- [ ] Required fixture commands pass with released Kujo 1.0.0.
- [ ] Markdown link audit reports zero broken local links.
- [ ] Kennel validation passes.
- [ ] ShipCheck gate exits `0` with no release-blocking finding.
- [ ] Workcell proof passes for the exact final commit.
- [ ] `workcell verify --run <run-dir> --json` verifies that proof receipt.
- [ ] Hosted Verification workflow passes for the exact final commit.
- [ ] Working tree is clean and the preparation branch is pushed.

## Human release approval

- [ ] Human reviewers approve the exact commit SHA and domain signoff.
- [ ] Release notes in [v1.0.0.md](releases/v1.0.0.md) are approved.
- [ ] The release owner follows [release-process.md](release-process.md).
- [ ] Only after approval, an authorized human creates `v1.0.0` on the approved
  SHA and reviews the tag-triggered artifacts.
- [ ] Only after artifact/checksum review, an authorized human creates the
  GitHub release and performs the installation smoke.

No checklist item authorizes an agent to tag, publish, deploy, bypass hosted
controls, or record human signoff.
