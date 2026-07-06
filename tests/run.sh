#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KUJO="${KUJO:-/Users/robertdevore/2026/Kujolang/kujo-repos/kujo/target/release/kujo}"

cd "$ROOT"

"$KUJO" check redact.kujo
"$KUJO" run tests/redact_tests.kujo

rm -rf .redact-test sample.redacted.md
"$KUJO" run redact.kujo sanitize fixtures/sample.md --policy fixtures/sample.policy.yaml --out sample.redacted.md --audit-dir .redact-test >/tmp/redact-cli-test.json
diff -u fixtures/sample.redacted.md sample.redacted.md
"$KUJO" run redact.kujo verify sample.redacted.md --policy fixtures/sample.policy.yaml --audit-dir .redact-test >/tmp/redact-verify-test.json
grep -q '"risk_score": "low"' /tmp/redact-verify-test.json

rm -f sample.redacted.md
rm -rf .redact-test

echo "redact integration tests passed"
