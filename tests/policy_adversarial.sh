#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KUJO_BIN="${KUJO_BIN:-/Users/robertdevore/2026/Kujolang/kujo-repos/kujo/target/release/kujo}"
TEST_TMP="$(mktemp -d /tmp/redact-policy.XXXXXX)"

cleanup() {
  case "$TEST_TMP" in
    /tmp/redact-policy.*) rm -rf -- "$TEST_TMP" ;;
  esac
}
trap cleanup EXIT

cd "$ROOT"

expect_policy_failure() {
  local policy="$1" expected="$2" name="$3"
  if "$KUJO_BIN" run redact.kujo scan fixtures/sample.md --policy "$policy" --audit-dir "$TEST_TMP/audit-$name" > "$TEST_TMP/$name.out" 2>&1; then
    echo "$name policy unexpectedly succeeded" >&2
    exit 1
  fi
  grep -Fq "$expected" "$TEST_TMP/$name.out"
}

expect_policy_failure fixtures/unsupported-nested.policy.yaml "unexpected indentation or nested YAML structure" nested
expect_policy_failure fixtures/malformed.policy.yaml "expected a top-level key and value" malformed

cp fixtures/sample.policy.yaml "$TEST_TMP/unknown.yaml"
printf '%s\n' 'unknown_contract: enabled' >> "$TEST_TMP/unknown.yaml"
expect_policy_failure "$TEST_TMP/unknown.yaml" "unsupported top-level key" unknown

sed 's/emails: placeholder/emails: explode/' fixtures/sample.policy.yaml > "$TEST_TMP/action.yaml"
expect_policy_failure "$TEST_TMP/action.yaml" "unsupported action for emails" action

sed 's/ai_assist: false/ai_assist: true/' fixtures/sample.policy.yaml > "$TEST_TMP/ai.yaml"
expect_policy_failure "$TEST_TMP/ai.yaml" "ai_assist is not supported" ai

sed 's/schemaVersion: redact-policy\/v1/schemaVersion: redact-policy\/v2/' fixtures/sample.policy.yaml > "$TEST_TMP/schema.yaml"
expect_policy_failure "$TEST_TMP/schema.yaml" "policy schemaVersion must be redact-policy/v1" schema

cp fixtures/sample.policy.yaml "$TEST_TMP/duplicate.yaml"
printf '%s\n' 'name: duplicate' >> "$TEST_TMP/duplicate.yaml"
expect_policy_failure "$TEST_TMP/duplicate.yaml" "duplicate top-level key" duplicate

printf '%s\n' \
  'schemaVersion: redact-policy/v1' \
  'name: anchored' \
  'terms: &shared' > "$TEST_TMP/anchor.yaml"
expect_policy_failure "$TEST_TMP/anchor.yaml" "unsupported YAML structure or feature" anchor

printf '%s\n' \
  'schemaVersion: redact-policy/v1' \
  'name: flow' \
  'terms: {person_names: [Synthetic Person]}' > "$TEST_TMP/flow.yaml"
expect_policy_failure "$TEST_TMP/flow.yaml" "terms must use the documented indented mapping form" flow

echo "Policy failure and adversarial contracts passed"
