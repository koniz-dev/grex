#!/bin/bash
# Enforce the coverage baseline and render the PR comment table.
#
# Exits 0 when every layer is at or above its baseline, 1 otherwise. The
# markdown table goes to stdout so the caller can drop it straight into a PR
# comment; the pass/fail verdict travels in the exit status, not in the text.
#
# Usage:
#   check_coverage_thresholds.sh [lcov.info] [baseline.env]
#
# Overriding a threshold for a one-off check (used by the acceptance evidence
# to prove the gate actually bites) is just an environment variable:
#   BASELINE_CORE=99 ./check_coverage_thresholds.sh coverage/lcov.info

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LCOV_FILE="${1:-coverage/lcov.info}"
BASELINE_FILE="${2:-$SCRIPT_DIR/coverage_baseline.env}"

if [ ! -f "$BASELINE_FILE" ]; then
  echo "Error: baseline file not found at $BASELINE_FILE" >&2
  exit 1
fi

# Baselines exported by the caller win over the committed file, so a one-off
# check can override a single threshold without editing anything. Snapshot them
# before sourcing, then put them back.
overrides="$(env | grep -E '^BASELINE_[A-Z]+=[0-9]+$' || true)"
# shellcheck disable=SC1090
source "$BASELINE_FILE"
if [ -n "$overrides" ]; then
  while IFS= read -r assignment; do
    export "${assignment?}"
  done <<< "$overrides"
fi

# calculate_layer_coverage.sh emits only key=value lines, so eval is safe here
# and keeps the two scripts from drifting on how a layer is defined.
eval "$("$SCRIPT_DIR/calculate_layer_coverage.sh" "$LCOV_FILE")"

failed=0
rows=""

# awk rather than bc: both are present on the runner, but only awk is
# guaranteed on a bare macOS dev machine, and the rest of this tooling is awk.
above() { awk -v a="$1" -v b="$2" 'BEGIN { exit !(a >= b) }'; }

check() {
  local name="$1" actual="$2" baseline="$3" target="$4" mark
  if above "$actual" "$baseline"; then
    mark="✅"
  else
    mark="❌"
    failed=1
    echo "FAIL: $name coverage ${actual}% is below the ${baseline}% baseline" >&2
  fi
  rows+="| **${name}** | ${actual}% | ${baseline}% | ${target}% | ${mark} |"$'\n'
}

check "Total"        "$total"        "$BASELINE_TOTAL"        "$TARGET_TOTAL"
check "Domain"       "$domain"       "$BASELINE_DOMAIN"       "$TARGET_DOMAIN"
check "Data"         "$data"         "$BASELINE_DATA"         "$TARGET_DATA"
check "Presentation" "$presentation" "$BASELINE_PRESENTATION" "$TARGET_PRESENTATION"
check "Core"         "$core"         "$BASELINE_CORE"         "$TARGET_CORE"
check "Shared"       "$shared"       "$BASELINE_SHARED"       "$TARGET_SHARED"

# The layer rows must account for every measured line. If they stop summing to
# the total, the table has silently become unreconcilable -- which is the exact
# defect that let lib/shared/ go unreported -- so fail loudly instead.
sum=$((domain_lines + data_lines + presentation_lines + core_lines + shared_lines))
if [ "$unclassified_lines" -ne 0 ]; then
  failed=1
  echo "FAIL: ${unclassified_lines} covered lines belong to no layer." >&2
  echo "      A new directory under lib/ needs a bucket in calculate_layer_coverage.sh." >&2
fi
if [ "$sum" -ne "$total_lines" ]; then
  failed=1
  echo "FAIL: layer lines ($sum) do not sum to total lines ($total_lines)." >&2
fi

if [ "$failed" -eq 0 ]; then
  status="✅ Passing"
else
  status="❌ Failing"
fi

cat <<EOF
**Coverage:** ${total}%
**Status:** ${status}

| Layer | Coverage | Baseline | Target | Status |
|-------|----------|----------|--------|--------|
${rows}
<sub>Baseline is the enforced gate and lives in \`scripts/linux/testing/coverage_baseline.env\`. Target is the long-term goal and is not enforced. ${total_covered} of ${total_lines} lines covered.</sub>
EOF

exit "$failed"
