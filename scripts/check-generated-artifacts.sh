#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

tracked_ignored="$(git ls-files -ci --exclude-from=config/kujo-tool-artifacts.gitignore)"
if [[ -n "$tracked_ignored" ]]; then
  echo "Tracked generated artifacts detected:" >&2
  printf '%s\n' "$tracked_ignored" >&2
  exit 1
fi

if git ls-files | grep -E '(^|/)(\.redact|\.workcell|\.kennel_tmp|kennel_packages|dist|out|tmp)/|redact-[0-9]+\.[0-9]+\.[0-9]+-(source|package)|checksums\.txt$'; then
  echo "Release or runtime artifacts must not be committed" >&2
  exit 1
fi

bash .github/scripts/check-kujo-tool-artifacts.sh HEAD HEAD
echo "Generated-artifact hygiene passed"
