#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KUJO_BIN="${KUJO_BIN:-/Users/robertdevore/2026/Kujolang/kujo-repos/kujo/target/release/kujo}"
TEST_TMP="$(mktemp -d /tmp/redact-cli.XXXXXX)"

cleanup() {
  case "$TEST_TMP" in
    /tmp/redact-cli.*) rm -rf -- "$TEST_TMP" ;;
  esac
}
trap cleanup EXIT

cd "$ROOT"

test "$("$KUJO_BIN" run redact.kujo version)" = "redact 1.0.0"
"$KUJO_BIN" run redact.kujo help > "$TEST_TMP/help.txt"
grep -Fq "stdin is not supported in 1.0" "$TEST_TMP/help.txt"

"$KUJO_BIN" run redact.kujo scan fixtures/sample.md \
  --policy fixtures/sample.policy.yaml \
  --audit-dir "$TEST_TMP/scan-audit" > "$TEST_TMP/scan.json"
jq -e '.schemaVersion == "redact-cli-output/v1" and .productVersion == "1.0.0" and .command == "scan" and .detections > 0' "$TEST_TMP/scan.json" >/dev/null

"$KUJO_BIN" run redact.kujo sanitize fixtures/sample.md \
  --policy fixtures/sample.policy.yaml \
  --out "$TEST_TMP/sample.redacted.md" \
  --audit-dir "$TEST_TMP/sanitize-audit" > "$TEST_TMP/sanitize.json"
diff -u fixtures/sample.redacted.md "$TEST_TMP/sample.redacted.md"
jq -e '.risk_score == "low" and .unsafeOriginalsStored == false' "$TEST_TMP/sanitize.json" >/dev/null

"$KUJO_BIN" run redact.kujo verify "$TEST_TMP/sample.redacted.md" \
  --policy fixtures/sample.policy.yaml \
  --audit-dir "$TEST_TMP/verify-audit" > "$TEST_TMP/verify.json"
jq -e '.schemaVersion == "redact-verifier/v1" and .productVersion == "1.0.0" and .risk_score == "low" and .remaining_payment_details == 0 and .remaining_exact_dates == 0 and .remaining_money_amounts == 0' "$TEST_TMP/verify.json" >/dev/null

if "$KUJO_BIN" run redact.kujo verify fixtures/sample.md \
  --policy fixtures/sample.policy.yaml \
  --audit-dir "$TEST_TMP/raw-verify-audit" > "$TEST_TMP/raw-verify.json"; then
  echo "raw verify unexpectedly returned success" >&2
  exit 1
fi
jq -e '.risk_score == "high"' "$TEST_TMP/raw-verify.json" >/dev/null

echo "CLI and JSON/exit-code contracts passed"
