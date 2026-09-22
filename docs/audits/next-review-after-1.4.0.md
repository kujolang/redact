# Redact next review after Kujo 1.4.0 hardening

This is a prioritized backlog, not a release approval. Redact remains a
bounded local review aid; a human owner must approve any real data domain.
The previous [review](next-review-2026-09-22.md) records the original six
proposals. The implementation and synthetic tests in this pass address pack
publication, bounded no-follow reads and the explicit same-host threat model,
dictionary cost, narrow policy parsing, clean-install coverage, and the
[format decision](../formats-next-major.md). Keep the following open:

1. **P1 — Exact candidate evidence.** Obtain a successful Workcell proof and
   receipt on an AppArmor-capable host, then confirm ShipCheck and the hosted
   Linux/macOS/Windows Verification matrix succeeded at that same SHA. Do not
   substitute local success for a platform that did not execute. Retain
   receipts outside Git.
2. **P1 — Domain-specific approval.** Have authorized privacy/security owners
   run the [unsigned checklist](../domain-signoff/checklist.md) on each real
   deployment domain, review residual false negatives and audit retention,
   and approve the exact SHA. An agent cannot issue that approval.
3. **P1 — Close the independent security scan gap.** The previously attempted
   canonical Codex Security plugin could not start due to its missing Python
   TOML dependency; a later attempt failed during module import on an
   unsupported `type | None` operation before creating a scan. Repair the
   plugin's Python environment and retry the exact-commit scan; examine any
   validated findings before making a broad security claim.
4. **P2 — Reviewed audit repair and publication identity.** Pack audits now
   record pending hashes and provide a read-only reconciliation check for
   interruptions or changed outputs. A matching pending hash cannot prove
   whether Redact or a colliding actor published the destination. If automatic
   repair is desired, design a verifiable publication-identity boundary and
   human-approved recovery workflow first; never delete published user data.
5. **P2 — Performance envelope across platforms.** The
   [synthetic Kujo 1.4.0 measurement](performance-1.4.0.md) covers five
   workloads on one local machine; the hosted install matrix also logs the
   four boundary workloads across supported systems; Windows uses peak
   working-set measurement, which is not identical to POSIX `ru_maxrss`.
   Measure other accepted Unicode/term combinations,
   replacement expansion, aggregate pack work beyond sixteen members, and
   actual deployments before setting any service-level budget.
6. **P2 — Future structured formats.** If demand warrants CSV, JSON, recursive
   packs or bounded stdin, implement only after the explicit syntax, audit,
   security and version criteria in the [format proposal](../formats-next-major.md)
   are approved. None is a Redact 1.x capability.

No planned action permits an agent to tag, publish or self-approve a release.
