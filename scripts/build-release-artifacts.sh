#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_DIR="${1:-}"
SOURCE_REF="${2:-HEAD}"
VERSION="$(tr -d '[:space:]' < "$ROOT/VERSION")"

if [[ -z "$OUTPUT_DIR" ]]; then
  echo "usage: $0 OUTPUT_DIR [GIT_REF]" >&2
  exit 2
fi
if [[ -e "$OUTPUT_DIR" ]]; then
  echo "release output already exists: $OUTPUT_DIR" >&2
  exit 2
fi
if [[ "$(git -C "$ROOT" show "$SOURCE_REF:VERSION" | tr -d '[:space:]')" != "$VERSION" ]]; then
  echo "release ref VERSION does not match $VERSION" >&2
  exit 2
fi

COMMIT="$(git -C "$ROOT" rev-parse "$SOURCE_REF^{commit}")"
RUNTIME_COMMIT="$(tr -d '[:space:]' < "$ROOT/RUNTIME_VERSION")"
ARCHIVE="redact-$VERSION-source.tar.gz"
PACKAGE="redact-$VERSION-package.zip"
PROVENANCE="redact-$VERSION-provenance.json"
CHECKSUMS="redact-$VERSION-checksums.txt"

mkdir "$OUTPUT_DIR"
git -C "$ROOT" archive --format=tar --prefix="redact-$VERSION/" "$SOURCE_REF" | gzip -n > "$OUTPUT_DIR/$ARCHIVE"
git -C "$ROOT" archive --format=zip --prefix="redact-$VERSION/" "$SOURCE_REF" > "$OUTPUT_DIR/$PACKAGE"

jq -n \
  --arg version "$VERSION" \
  --arg tag "v$VERSION" \
  --arg commit "$COMMIT" \
  --arg runtimeCommit "$RUNTIME_COMMIT" \
  --arg sourceArchive "$ARCHIVE" \
  --arg packageArchive "$PACKAGE" \
  '{schemaVersion:"redact-release-provenance/v1",product:"Redact",version:$version,tag:$tag,commit:$commit,kujoRuntimeCommit:$runtimeCommit,sourceArchive:$sourceArchive,packageArchive:$packageArchive}' \
  > "$OUTPUT_DIR/$PROVENANCE"

(
  cd "$OUTPUT_DIR"
  shasum -a 256 "$ARCHIVE" "$PACKAGE" "$PROVENANCE" > "$CHECKSUMS"
  shasum -a 256 -c "$CHECKSUMS"
)

printf '%s\n' "$OUTPUT_DIR/$ARCHIVE" "$OUTPUT_DIR/$PACKAGE" "$OUTPUT_DIR/$PROVENANCE" "$OUTPUT_DIR/$CHECKSUMS"
