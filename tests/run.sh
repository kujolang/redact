#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KUJO_BIN="${KUJO_BIN:-${KUJO:-/Users/robertdevore/2026/Kujolang/kujo-repos/kujo/target/release/kujo}}"
export KUJO_BIN

cd "$ROOT"

"$KUJO_BIN" check redact.kujo
while IFS= read -r file; do
  "$KUJO_BIN" check "$file"
done < <(find src tests -type f -name '*.kujo' | sort)

"$KUJO_BIN" run tests/redact_tests.kujo
bash tests/cli_contract.sh
bash tests/policy_adversarial.sh
bash tests/security_adversarial.sh
bash tests/examples_smoke.sh
bash scripts/check-version-consistency.sh

echo "Redact deterministic test suite passed"
