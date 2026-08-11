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

expect_usage_error() {
  local expected="$1" name="$2"
  shift 2
  local status
  if "$@" > "$TEST_TMP/$name.out" 2>&1; then
    status=0
  else
    status=$?
  fi
  if [[ "$status" -ne 2 ]]; then
    echo "$name returned $status instead of usage exit 2" >&2
    exit 1
  fi
  grep -Fq -- "$expected" "$TEST_TMP/$name.out"
}

test "$("$KUJO_BIN" run redact.kujo version)" = "redact 1.0.0"
"$KUJO_BIN" run redact.kujo help > "$TEST_TMP/help.txt"
grep -Fq "stdin is not supported in 1.0" "$TEST_TMP/help.txt"

expect_usage_error "unknown command: inspect" unknown-command \
  "$KUJO_BIN" run redact.kujo inspect
expect_usage_error "unexpected positional argument" extra-positional \
  "$KUJO_BIN" run redact.kujo scan fixtures/sample.md fixtures/sample.md
expect_usage_error "unknown option: --mystery" unknown-option \
  "$KUJO_BIN" run redact.kujo scan fixtures/sample.md --mystery value
expect_usage_error "option requires a value: --out" missing-option-value \
  "$KUJO_BIN" run redact.kujo sanitize fixtures/sample.md --out
expect_usage_error "option --out is not valid for scan" inapplicable-option \
  "$KUJO_BIN" run redact.kujo scan fixtures/sample.md --out "$TEST_TMP/ignored.md"
expect_usage_error "--fail-on-risk must be medium or high" invalid-risk-threshold \
  "$KUJO_BIN" run redact.kujo sanitize fixtures/sample.md --fail-on-risk urgent

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
