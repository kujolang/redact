#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KUJO_BIN="${KUJO_BIN:-kujo}"
TEST_TMP="$(mktemp -d /tmp/redact-cli-regression.XXXXXX)"
cleanup() {
  case "$TEST_TMP" in
    /tmp/redact-cli-regression.*) rm -rf -- "$TEST_TMP" ;;
  esac
}
trap cleanup EXIT
cd "$ROOT"

printf 'Synthetic private note\n' > "$TEST_TMP/note.MD"
failures=0
"$KUJO_BIN" run redact.kujo sanitize "$TEST_TMP/note.MD" --policy basic \
  --audit-dir "$TEST_TMP/uppercase-audit" > "$TEST_TMP/uppercase.json"
if test "$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["output"])' "$TEST_TMP/uppercase.json")" = "$TEST_TMP/note.redacted.MD" &&
   test -f "$TEST_TMP/note.redacted.MD" &&
   "$KUJO_BIN" run redact.kujo verify "$TEST_TMP/note.redacted.MD" --policy basic \
     --audit-dir "$TEST_TMP/uppercase-verify" >/dev/null; then
  :
else
  echo 'FAIL: default output of uppercase .MD input cannot be verified' >&2
  failures=$((failures + 1))
fi

printf 'Synthetic text note\n' > "$TEST_TMP/note.TXT"
"$KUJO_BIN" run redact.kujo sanitize "$TEST_TMP/note.TXT" --policy basic \
  --audit-dir "$TEST_TMP/uppercase-txt-audit" > "$TEST_TMP/uppercase-txt.json"
test -f "$TEST_TMP/note.redacted.TXT"
"$KUJO_BIN" run redact.kujo verify "$TEST_TMP/note.redacted.TXT" --policy basic \
  --audit-dir "$TEST_TMP/uppercase-txt-verify" >/dev/null

printf 'schemaVersion: redact-policy/v1\nname: synthetic-policy\n' > "$TEST_TMP/active.policy.yaml"
if "$KUJO_BIN" run redact.kujo sanitize "$TEST_TMP/note.MD" --policy "$TEST_TMP/active.policy.yaml" \
  --out "$TEST_TMP/active.policy.yaml" --audit-dir "$TEST_TMP/policy-audit" > "$TEST_TMP/policy-out" 2>&1; then
  echo 'FAIL: sanitize overwrote its policy' >&2
  failures=$((failures + 1))
else
  grep -Fq 'policy file' "$TEST_TMP/policy-out"
  grep -Fq 'name: synthetic-policy' "$TEST_TMP/active.policy.yaml"
  test ! -e "$TEST_TMP/policy-audit"
fi
if "$KUJO_BIN" run redact.kujo sanitize "$TEST_TMP/note.MD" --policy "$TEST_TMP/active.policy.yaml" \
  --out "$TEST_TMP/./active.policy.yaml" --audit-dir "$TEST_TMP/alias-audit" > "$TEST_TMP/alias-out" 2>&1; then
  echo 'FAIL: sanitize overwrote its policy through a path alias' >&2
  failures=$((failures + 1))
else
  grep -Fq 'policy file' "$TEST_TMP/alias-out"
  grep -Fq 'name: synthetic-policy' "$TEST_TMP/active.policy.yaml"
  test ! -e "$TEST_TMP/alias-audit"
fi
test "$failures" -eq 0
echo 'Uppercase default output and policy overwrite regressions passed'
