#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KUJO_BIN="${KUJO_BIN:-kujo}"
TEST_TMP="$(mktemp -d /tmp/redact-security.XXXXXX)"

cleanup() {
  case "$TEST_TMP" in
    /tmp/redact-security.*) rm -rf -- "$TEST_TMP" ;;
  esac
}
trap cleanup EXIT

cd "$ROOT"

expect_failure() {
  local expected="$1" name="$2"
  shift 2
  if "$@" > "$TEST_TMP/$name.out" 2>&1; then
    echo "$name unexpectedly succeeded" >&2
    exit 1
  fi
  grep -Fq -- "$expected" "$TEST_TMP/$name.out"
}

expect_failure "stdin input ('-') is not supported" stdin \
  "$KUJO_BIN" run redact.kujo scan - --policy fixtures/sample.policy.yaml --audit-dir "$TEST_TMP/stdin-audit"
test ! -e "$TEST_TMP/stdin-audit"

expect_failure "path traversal segments" traversal \
  "$KUJO_BIN" run redact.kujo scan fixtures/../fixtures/sample.md --policy fixtures/sample.policy.yaml --audit-dir "$TEST_TMP/traversal-audit"

ln -s "$ROOT/fixtures/sample.md" "$TEST_TMP/input-link.md"
expect_failure "symbolic links" input-symlink \
  "$KUJO_BIN" run redact.kujo scan "$TEST_TMP/input-link.md" --policy fixtures/sample.policy.yaml --audit-dir "$TEST_TMP/symlink-audit"

ln -s "$ROOT/fixtures/sample.policy.yaml" "$TEST_TMP/policy-link.yaml"
expect_failure "policy path must not contain symbolic links" policy-symlink \
  "$KUJO_BIN" run redact.kujo scan fixtures/sample.md --policy "$TEST_TMP/policy-link.yaml" --audit-dir "$TEST_TMP/policy-link-audit"

expect_failure "policy path must not contain path traversal segments" policy-traversal \
  "$KUJO_BIN" run redact.kujo scan fixtures/sample.md --policy fixtures/../fixtures/sample.policy.yaml --audit-dir "$TEST_TMP/policy-traversal-audit"

head -c 262145 /dev/zero | tr '\0' 'A' > "$TEST_TMP/oversized-policy.yaml"
expect_failure "policy exceeds the 262144-byte" oversized-policy \
  "$KUJO_BIN" run redact.kujo scan fixtures/sample.md --policy "$TEST_TMP/oversized-policy.yaml" --audit-dir "$TEST_TMP/oversized-policy-audit"

expect_failure "refusing to overwrite the source file" overwrite \
  "$KUJO_BIN" run redact.kujo sanitize fixtures/sample.md --policy fixtures/sample.policy.yaml --out fixtures/sample.md --audit-dir "$TEST_TMP/overwrite-audit"

ln -s "$TEST_TMP/symlink-target.md" "$TEST_TMP/output-link.md"
expect_failure "output path must not contain symbolic links" output-symlink \
  "$KUJO_BIN" run redact.kujo sanitize fixtures/sample.md --policy fixtures/sample.policy.yaml --out "$TEST_TMP/output-link.md" --audit-dir "$TEST_TMP/output-link-audit"

mkdir "$TEST_TMP/real-audit"
ln -s "$TEST_TMP/real-audit" "$TEST_TMP/audit-link"
expect_failure "audit directory must not contain symbolic links" audit-symlink \
  "$KUJO_BIN" run redact.kujo scan fixtures/sample.md --policy fixtures/sample.policy.yaml --audit-dir "$TEST_TMP/audit-link"

head -c 1048577 /dev/zero | tr '\0' 'A' > "$TEST_TMP/oversized.md"
expect_failure "input exceeds the 1048576-byte" oversized-input \
  "$KUJO_BIN" run redact.kujo scan "$TEST_TMP/oversized.md" --policy fixtures/sample.policy.yaml --audit-dir "$TEST_TMP/oversized-audit"

mkdir "$TEST_TMP/pack-input" "$TEST_TMP/empty-pack"
printf '%s\n' 'Synthetic example' > "$TEST_TMP/pack-input/a.txt"
cp "$TEST_TMP/oversized.md" "$TEST_TMP/pack-input/z.md"
expect_failure "input exceeds the 1048576-byte" pack-preflight \
  "$KUJO_BIN" run redact.kujo pack "$TEST_TMP/pack-input" --policy fixtures/sample.policy.yaml --out "$TEST_TMP/invalid-pack" --audit-dir "$TEST_TMP/pack-audit"
test ! -e "$TEST_TMP/invalid-pack"
test ! -e "$TEST_TMP/pack-audit"
expect_failure "no supported .txt or .md files" empty-pack \
  "$KUJO_BIN" run redact.kujo pack "$TEST_TMP/empty-pack" --policy fixtures/sample.policy.yaml --out "$TEST_TMP/empty-output" --audit-dir "$TEST_TMP/empty-audit"
test ! -e "$TEST_TMP/empty-output"
ln -s "$ROOT/fixtures/sample.md" "$TEST_TMP/pack-input/b.md"
expect_failure "pack member must not contain symbolic links" pack-symlink \
  "$KUJO_BIN" run redact.kujo pack "$TEST_TMP/pack-input" --policy fixtures/sample.policy.yaml --out "$TEST_TMP/link-pack" --audit-dir "$TEST_TMP/link-audit"
test ! -e "$TEST_TMP/link-pack"

mkdir "$TEST_TMP/count-pack" "$TEST_TMP/bytes-pack"
for member in $(seq -w 0 256); do
  printf 'synthetic note\n' > "$TEST_TMP/count-pack/$member.txt"
done
expect_failure '256-file limit' pack-count \
  "$KUJO_BIN" run redact.kujo pack "$TEST_TMP/count-pack" --policy basic \
    --out "$TEST_TMP/count-output" --audit-dir "$TEST_TMP/count-audit"
test ! -e "$TEST_TMP/count-output" && test ! -e "$TEST_TMP/count-audit"
for member in $(seq -w 0 16); do
  head -c 1048576 /dev/zero | tr '\0' 'x' > "$TEST_TMP/bytes-pack/$member.txt"
done
expect_failure '16777216-byte aggregate input limit' pack-bytes \
  "$KUJO_BIN" run redact.kujo pack "$TEST_TMP/bytes-pack" --policy basic \
    --out "$TEST_TMP/bytes-output" --audit-dir "$TEST_TMP/bytes-audit"
test ! -e "$TEST_TMP/bytes-output" && test ! -e "$TEST_TMP/bytes-audit"

# A later transformation failure must not expose the earlier completed member.
printf '%s\n' 'schemaVersion: redact-policy/v1' 'name: late-failure' 'person_names: role-preserve' 'terms:' \
  '  person_names:' '    - x' 'roles:' > "$TEST_TMP/late.policy.yaml"
printf '  x: ' >> "$TEST_TMP/late.policy.yaml"
head -c 8000 /dev/zero | tr '\0' 'A' >> "$TEST_TMP/late.policy.yaml"
printf '\n' >> "$TEST_TMP/late.policy.yaml"
mkdir "$TEST_TMP/late-input"
printf '%s\n' 'ordinary synthetic note' > "$TEST_TMP/late-input/a.txt"
head -c 300 /dev/zero | tr '\0' 'x' > "$TEST_TMP/late-input/z.txt"
expect_failure 'no output directory was published' late-pack \
  "$KUJO_BIN" run redact.kujo pack "$TEST_TMP/late-input" --policy "$TEST_TMP/late.policy.yaml" \
    --out "$TEST_TMP/late-output" --audit-dir "$TEST_TMP/late-audit"
test ! -e "$TEST_TMP/late-output"
test -z "$(find "$TEST_TMP" -maxdepth 1 -name '.redact-pack-*' -print)"
sed -n '/^{/,$p' "$TEST_TMP/late-pack.out" | \
  jq -e '.published == false and .processed == 0 and .staged == 1 and .failed == 1' >/dev/null
test -z "$(find "$TEST_TMP/late-audit" -name output-manifest.json -print)"

mkdir "$TEST_TMP/collision-output"
printf '%s\n' 'keep me' > "$TEST_TMP/collision-output/owner.txt"
expect_failure 'already exists' pack-collision \
  "$KUJO_BIN" run redact.kujo pack "$TEST_TMP/late-input" --policy fixtures/sample.policy.yaml \
    --out "$TEST_TMP/collision-output" --audit-dir "$TEST_TMP/collision-audit"
test "$(cat "$TEST_TMP/collision-output/owner.txt")" = 'keep me'
test -z "$(find "$TEST_TMP" -maxdepth 1 -name '.redact-pack-*' -print)"

mkdir "$TEST_TMP/locked-parent"
chmod 500 "$TEST_TMP/locked-parent"
expect_failure 'cannot create private pack staging directory' pack-permission \
  "$KUJO_BIN" run redact.kujo pack examples/pack --policy fixtures/sample.policy.yaml \
    --out "$TEST_TMP/locked-parent/pack" --audit-dir "$TEST_TMP/permission-audit"
chmod 700 "$TEST_TMP/locked-parent"
test ! -e "$TEST_TMP/locked-parent/pack"

printf '\377' > "$TEST_TMP/invalid-utf8.md"
expect_failure "file is not valid UTF-8 or cannot be read" invalid-utf8 \
  "$KUJO_BIN" run redact.kujo scan "$TEST_TMP/invalid-utf8.md" --policy fixtures/sample.policy.yaml --audit-dir "$TEST_TMP/utf8-audit"

printf '%s' 'normal output' > "$TEST_TMP/normal-output.txt"
head -c 2097153 /dev/zero | tr '\0' 'A' > "$TEST_TMP/oversized-output.txt"
"$KUJO_BIN" run tests/output_size_test.kujo "$TEST_TMP/normal-output.txt" "$TEST_TMP/oversized-output.txt" > "$TEST_TMP/output-size.out"
grep -Fq 'output size guard passed' "$TEST_TMP/output-size.out"

"$KUJO_BIN" run redact.kujo scan examples/synthetic-note.md --policy examples/policy.yaml --audit-dir "$TEST_TMP/safe-audit" > "$TEST_TMP/safe-scan.json"
if grep -R -F -e 'Morgan Example' -e 'morgan@example.com' -e 'sk-EXAMPLE1234567890' "$TEST_TMP/safe-audit"; then
  echo "default audit leaked a raw configured or detected value" >&2
  exit 1
fi
grep -R -Fq 'sourcePolicySha256:' "$TEST_TMP/safe-audit"
grep -R -Fq '"unsafeOriginalsStored": false' "$TEST_TMP/safe-audit"

"$KUJO_BIN" run redact.kujo scan examples/synthetic-note.md --policy examples/policy.yaml --unsafe-store-originals --audit-dir "$TEST_TMP/unsafe-audit" > "$TEST_TMP/unsafe-scan.json"
jq -e '.unsafeOriginalsStored == true' "$TEST_TMP/unsafe-scan.json" >/dev/null
grep -R -Fq 'Morgan Example' "$TEST_TMP/unsafe-audit"
grep -R -Fq 'DANGER: --unsafe-store-originals' "$TEST_TMP/unsafe-audit"

expect_failure "--unsafe-store-originals is only valid" unsafe-verify \
  "$KUJO_BIN" run redact.kujo verify fixtures/sample.redacted.md --policy fixtures/sample.policy.yaml --unsafe-store-originals --audit-dir "$TEST_TMP/unsafe-verify-audit"

"$KUJO_BIN" run redact.kujo sanitize fixtures/sample.md --policy fixtures/sample.policy.yaml --out "$TEST_TMP/deterministic-a.md" --audit-dir "$TEST_TMP/deterministic-audit-a" >/dev/null
"$KUJO_BIN" run redact.kujo sanitize fixtures/sample.md --policy fixtures/sample.policy.yaml --out "$TEST_TMP/deterministic-b.md" --audit-dir "$TEST_TMP/deterministic-audit-b" >/dev/null
diff -u "$TEST_TMP/deterministic-a.md" "$TEST_TMP/deterministic-b.md"

echo "Security, path, size, UTF-8, audit, and determinism contracts passed"
