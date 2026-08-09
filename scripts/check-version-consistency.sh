#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KUJO_BIN="${KUJO_BIN:-/Users/robertdevore/2026/Kujolang/kujo-repos/kujo/target/release/kujo}"
VERSION="$(tr -d '[:space:]' < "$ROOT/VERSION")"
RELEASED_KUJO_COMMIT="2b3e07d398016e92008d8399e79c441e012dce38"

toml_value() {
  local file="$1" section="$2" key="$3"
  awk -v section="[$section]" -v key="$key" '
    $0 == section { active = 1; next }
    active && /^\[/ { active = 0 }
    active && $0 ~ "^" key "[[:space:]]*=" {
      value = $0
      sub("^[^=]*=[[:space:]]*", "", value)
      gsub(/^\"|\"$/, "", value)
      print value
    }
  ' "$file"
}

[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
test "$(toml_value "$ROOT/kujo.toml" package version)" = "$VERSION"
test "$(toml_value "$ROOT/kennel.toml" package version)" = "$VERSION"
test "$(toml_value "$ROOT/kennel.toml" package.status stage)" = "production"
test "$(toml_value "$ROOT/kennel.toml" package.status stability)" = "stable"
test "$(toml_value "$ROOT/kennel.toml" package.status public_api)" = "true"
test "$(toml_value "$ROOT/kennel.toml" kujo minimum_version)" = "1.0.0"
test "$(tr -d '[:space:]' < "$ROOT/RUNTIME_VERSION")" = "$RELEASED_KUJO_COMMIT"
test "$("$KUJO_BIN" --version)" = "kujo 1.0.0"
test "$(cd "$ROOT" && "$KUJO_BIN" run redact.kujo version)" = "redact $VERSION"
grep -Fq "export PRODUCT_VERSION := \"$VERSION\"" "$ROOT/src/version.kujo"
grep -Eq "^## \[$VERSION\] - [0-9]{4}-[0-9]{2}-[0-9]{2}$" "$ROOT/CHANGELOG.md"
grep -Fq "version-$VERSION" "$ROOT/README.md"
grep -Fq "redact-$VERSION-source.tar.gz" "$ROOT/docs/release-process.md"
grep -Fq "redact-$VERSION-checksums.txt" "$ROOT/docs/release-process.md"
legacy_versions="$(grep -R -n '0\.1\.0' "$ROOT" \
  --exclude-dir=.git \
  --exclude-dir=.redact \
  --exclude-dir=redact-audit \
  --exclude-dir=redact-transcript-audit \
  --exclude-dir=.workcell \
  --exclude-dir=.loop-engineering \
  --exclude='transcript*' \
  --exclude=CHANGELOG.md || true)"
if [[ -n "$legacy_versions" ]]; then
  printf '%s\n' "$legacy_versions" >&2
  echo "Unexpected legacy product version outside CHANGELOG.md" >&2
  exit 1
fi

echo "Version consistency passed: Redact $VERSION on Kujo $RELEASED_KUJO_COMMIT"
