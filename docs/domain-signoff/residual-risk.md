# Residual Risk Statement

Even when the synthetic verifier output is `low`, unmatched or inferable
sensitive content may remain. Deterministic coverage is limited to documented
patterns and configured dictionaries. Audit metadata, policy names, paths,
hashes, and category counts may disclose operational facts. Human review can
also fail.

Residual risk must be assessed against the intended recipients, data domain,
threat model, audit storage, retention, incident response, and consequences of
disclosure. Redact 1.0 does not make that decision and does not certify the
result.
