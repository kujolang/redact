# Redact Security and Sensitive-Data Policy

## Intended scope

Redact reduces deterministic, policy-defined sensitive-text exposure in local
files. It is not a guarantee that every secret, identifier, or re-identification
risk is removed. Review sanitized output before sharing it outside the trusted
workspace.

## Data handling

- Inputs, outputs, and audit artifacts remain local; the MVP makes no AI or
  network calls.
- Default audit events store hashes and classifications, not raw matched values.
- `--unsafe-store-originals` is for short-lived local debugging only. Never use
  it for production, shared artifacts, or untrusted storage.
- The current runtime cannot read stdin safely, so `-` fails explicitly. Pass a
  controlled file path instead.

## Operational boundaries

Use a dedicated output path and inspect it before replacing a source file. Keep
the `.redact` audit directory out of source control and restrict local access to
it. Policies support only the documented flat YAML subset; do not rely on nested
YAML semantics, anchors, tags, or provider-side enrichment.

## Threats not solved

Redact does not defend against a compromised host, malicious filesystem
permissions, undiscovered data classes, inference from retained context, or a
human sharing unreviewed output. AI enrichment is an explicit future adapter,
not an MVP capability.
