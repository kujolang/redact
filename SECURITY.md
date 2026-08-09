# Redact Security Policy

Redact is a deterministic review aid, not a guarantee that every sensitive
value is found or removed. Before use, read the full
[security and privacy boundary](docs/security.md).

## Reporting a vulnerability

Do not include personal data, credentials, confidential inputs, or generated
audit directories in a public issue. Use GitHub's private security advisory
flow for the `kujolang/redact` repository. Include a minimal synthetic
reproduction, affected version, and expected safe behavior.

## Supported version

Redact 1.x receives security fixes. Older 0.x snapshots are unsupported.
Security fixes may narrow accepted inputs or reject previously accepted
ambiguous policy structures when required to preserve the documented safety
boundary.
