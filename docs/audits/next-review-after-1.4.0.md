# Redact next review after Kujo 1.4.0 hardening

This is a prioritized backlog, not a release approval. Redact remains a
bounded local review aid; a human owner must approve any real data domain.
The previous [review](next-review-2026-09-22.md) records the original six
proposals. The implementation and synthetic tests in this pass address pack
publication, bounded no-follow reads and the explicit same-host threat model,
dictionary cost, narrow policy parsing, clean-install coverage, and the
[format decision](../formats-next-major.md). Keep the following open:

1. **P1 — Exact candidate evidence.** Verify Workcell receipt and ShipCheck
   against the final commit, then confirm the hosted Linux/macOS/Windows
   Verification matrix succeeded at that same SHA. Do not substitute local
   success for a platform that did not execute. Retain receipts outside Git.
2. **P1 — Domain-specific approval.** Have authorized privacy/security owners
   run the [unsigned checklist](../domain-signoff/checklist.md) on each real
   deployment domain, review residual false negatives and audit retention,
   and approve the exact SHA. An agent cannot issue that approval.
3. **P1 — Close the independent security scan gap.** The previously attempted
   canonical Codex Security plugin could not start due to its missing Python
   TOML dependency. Retry with a repaired plugin environment; examine any
   validated findings before making a broad security claim.
4. **P2 — Adversarial output/audit consistency.** Pack members stage before an
   atomic no-replace directory publish. Audit runs are deliberately outside
   that transaction, and final-path output audit entries are written after
   publication. Consider an audit reconciliation record for interruptions or
   full disks after publication; test recovery without deleting published data.
5. **P2 — Performance envelope across platforms.** The
   [synthetic Kujo 1.4.0 measurement](performance-1.4.0.md) is one local
   machine and two workloads. Measure worst-case accepted Unicode,
   replacement-heavy text, large term sets, and aggregate pack work on each
   supported platform before setting any service-level budget.
6. **P2 — Future structured formats.** If demand warrants CSV, JSON, recursive
   packs or bounded stdin, implement only after the explicit syntax, audit,
   security and version criteria in the [format proposal](../formats-next-major.md)
   are approved. None is a Redact 1.x capability.

No planned action permits an agent to tag, publish or self-approve a release.
