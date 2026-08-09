#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KUJO_BIN="${KUJO_BIN:-/Users/robertdevore/2026/Kujolang/kujo-repos/kujo/target/release/kujo}"
TEST_TMP="$(mktemp -d /tmp/redact-examples.XXXXXX)"

cleanup() {
  case "$TEST_TMP" in
    /tmp/redact-examples.*) rm -rf -- "$TEST_TMP" ;;
  esac
}
trap cleanup EXIT

cd "$ROOT"

"$KUJO_BIN" run redact.kujo scan examples/synthetic-note.md --policy examples/policy.yaml --audit-dir "$TEST_TMP/scan-audit" > "$TEST_TMP/scan.json"
jq -e '.command == "scan" and .detections >= 10 and .categories.emails >= 1 and .categories.payment_details == 1' "$TEST_TMP/scan.json" >/dev/null

"$KUJO_BIN" run redact.kujo sanitize examples/synthetic-note.md --policy examples/policy.yaml --out "$TEST_TMP/synthetic-note.redacted.md" --audit-dir "$TEST_TMP/sanitize-audit" > "$TEST_TMP/sanitize.json"
jq -e '.command == "sanitize" and .risk_score == "low"' "$TEST_TMP/sanitize.json" >/dev/null
grep -Fq '[RESEARCH_LEAD]' "$TEST_TMP/synthetic-note.redacted.md"
grep -Fq '[COMPANY_A]' "$TEST_TMP/synthetic-note.redacted.md"
grep -Fq '[CUSTOMER_A]' "$TEST_TMP/synthetic-note.redacted.md"
grep -Fq '[PRODUCT_A]' "$TEST_TMP/synthetic-note.redacted.md"
grep -Fq '[MID_FIVE_FIGURE_AMOUNT]' "$TEST_TMP/synthetic-note.redacted.md"
grep -Fq 'upcoming internal milestone' "$TEST_TMP/synthetic-note.redacted.md"
grep -Fq 'sensitive internal strategy' "$TEST_TMP/synthetic-note.redacted.md"
grep -Fq '4111 1111 1111 1112' "$TEST_TMP/synthetic-note.redacted.md"

"$KUJO_BIN" run redact.kujo verify "$TEST_TMP/synthetic-note.redacted.md" --policy examples/policy.yaml --audit-dir "$TEST_TMP/verify-audit" > "$TEST_TMP/verify.json"
jq -e '.risk_score == "low"' "$TEST_TMP/verify.json" >/dev/null

"$KUJO_BIN" run redact.kujo sanitize examples/transformations.txt --policy examples/policy.yaml --out "$TEST_TMP/transformations.redacted.txt" --audit-dir "$TEST_TMP/transform-audit" >/dev/null
grep -Fq '[RESEARCH_LEAD]' "$TEST_TMP/transformations.redacted.txt"
grep -Fq '[EMAIL_1]' "$TEST_TMP/transformations.redacted.txt"
grep -Fq '[MID_FIVE_FIGURE_AMOUNT]' "$TEST_TMP/transformations.redacted.txt"

"$KUJO_BIN" run redact.kujo pack examples/pack --policy examples/policy.yaml --out "$TEST_TMP/pack-a" --audit-dir "$TEST_TMP/pack-audit-a" > "$TEST_TMP/pack-a.json"
"$KUJO_BIN" run redact.kujo pack examples/pack --policy examples/policy.yaml --out "$TEST_TMP/pack-b" --audit-dir "$TEST_TMP/pack-audit-b" > "$TEST_TMP/pack-b.json"
jq -e '.command == "pack" and .processed == 2 and .failed == 0' "$TEST_TMP/pack-a.json" >/dev/null
diff -ru "$TEST_TMP/pack-a" "$TEST_TMP/pack-b"

if "$KUJO_BIN" run redact.kujo scan examples/synthetic-note.md --policy examples/unsupported-nested-policy.yaml --audit-dir "$TEST_TMP/nested-audit" > "$TEST_TMP/nested.out" 2>&1; then
  echo "unsupported nested example unexpectedly succeeded" >&2
  exit 1
fi
grep -Fq 'unexpected indentation or nested YAML structure' "$TEST_TMP/nested.out"

if printf '%s\n' 'synthetic@example.com' | "$KUJO_BIN" run redact.kujo scan - --policy examples/policy.yaml --audit-dir "$TEST_TMP/stdin-audit" > "$TEST_TMP/stdin.out" 2>&1; then
  echo "stdin example unexpectedly succeeded" >&2
  exit 1
fi
grep -Fq "stdin input ('-') is not supported" "$TEST_TMP/stdin.out"

echo "Synthetic examples and pack smoke tests passed"
