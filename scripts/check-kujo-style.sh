#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KUJO_BIN="${KUJO_BIN:-kujo}"
cd "$ROOT"

while IFS= read -r file; do
  "$KUJO_BIN" format --check "$file"
  "$KUJO_BIN" lint "$file"
done < <(find . -type f -name '*.kujo' -not -path './.git/*' | sort)

echo "Kujo formatting and lint passed"
