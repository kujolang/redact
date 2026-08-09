#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KUJO_BIN="${KUJO_BIN:-/Users/robertdevore/2026/Kujolang/kujo-repos/kujo/target/release/kujo}"
KENNEL_REPO="${KENNEL_REPO:-$ROOT/../kennel}"
SHIPCHECK_REPO="${SHIPCHECK_REPO:-$ROOT/../shipcheck}"
export KUJO_BIN

cd "$ROOT"

"$KUJO_BIN" --version
bash tests/run.sh
bash scripts/check-kujo-style.sh
python3 scripts/check-markdown-links.py
git diff --check
bash scripts/check-generated-artifacts.sh
"$KUJO_BIN" run "$KENNEL_REPO/kennel.kujo" --interpreter -- validate --project-dir "$ROOT"
"$KUJO_BIN" run "$SHIPCHECK_REPO/shipcheck.kujo" gate --dir "$ROOT" --format json

echo "All Redact release-preparation gates passed"
