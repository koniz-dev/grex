#!/bin/bash
# Fail when a file under lib/ is missing from lcov.info for any reason other
# than having nothing to execute.
#
# `flutter test --coverage` instruments only the libraries a run loads, so a
# file no test imports is absent from lcov.info entirely rather than reported as
# 0%. It never reaches the denominator, and every layer percentage comes out
# higher than the truth. test/coverage_all_test.dart now imports every eligible
# library to close that hole; this script is what stops it reopening.
#
# Some files legitimately produce no coverage records at all, because they hold
# no executable lines: barrel files that only re-export, abstract interfaces
# whose methods have no bodies, and classes of nothing but `static const`. The
# VM emits no DA: records for those, so they cannot appear in lcov no matter
# what imports them. They are listed in coverage_declaration_only.txt, which is
# generated, not hand-written.
#
# Usage:
#   check_coverage_completeness.sh [lcov.info]           # verify, exit 1 on drift
#   check_coverage_completeness.sh [lcov.info] --update  # regenerate the list
#
# Regenerate after adding or gutting a barrel/interface file, and commit the
# result -- the diff is the record of which files stopped carrying code.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
LCOV_FILE="${1:-coverage/lcov.info}"
MODE="${2:-check}"
EXEMPT_FILE="$SCRIPT_DIR/coverage_declaration_only.txt"

if [ ! -f "$LCOV_FILE" ]; then
  echo "Error: lcov file not found at $LCOV_FILE" >&2
  exit 1
fi

# Identical to excluded() in calculate_layer_coverage.sh and to the
# `lcov --remove` filter in .github/workflows/test.yml. Keep all three in sync.
eligible="$(mktemp)"
present="$(mktemp)"
missing="$(mktemp)"
trap 'rm -f "$eligible" "$present" "$missing"' EXIT

(cd "$REPO_ROOT" && find lib -name '*.dart') \
  | grep -vE '\.g\.dart$|\.freezed\.dart$|\.config\.dart$|/generated/|/l10n/|(^|/)main\.dart$|_test\.dart$|(^|/)test_helpers\.dart$|(^|/)test_fixtures\.dart$|(^|/)test/' \
  | sort > "$eligible"

grep '^SF:' "$LCOV_FILE" | sed 's|^SF:||' | sort -u > "$present"

comm -23 "$eligible" "$present" > "$missing"

if [ "$MODE" = "--update" ]; then
  {
    echo "# Files under lib/ that produce no coverage records because they hold"
    echo "# no executable lines: barrel files that only re-export, abstract"
    echo "# interfaces with no method bodies, and static-const-only classes."
    echo "#"
    echo "# GENERATED -- regenerate with:"
    echo "#   scripts/linux/testing/check_coverage_completeness.sh coverage/lcov.info --update"
    echo "#"
    echo "# Anything absent from lcov and NOT listed here is a measurement hole"
    echo "# and fails the gate."
    cat "$missing"
  } > "$EXEMPT_FILE"
  echo "Wrote $EXEMPT_FILE ($(wc -l < "$missing" | tr -d ' ') entries)."
  exit 0
fi

if [ ! -f "$EXEMPT_FILE" ]; then
  echo "Error: $EXEMPT_FILE not found. Generate it with --update." >&2
  exit 1
fi

exempt="$(mktemp)"
trap 'rm -f "$eligible" "$present" "$missing" "$exempt"' EXIT
grep -vE '^\s*#|^\s*$' "$EXEMPT_FILE" | sort > "$exempt"

failed=0

unexpected="$(comm -23 "$missing" "$exempt")"
if [ -n "$unexpected" ]; then
  failed=1
  echo "FAIL: these files under lib/ are missing from $LCOV_FILE:" >&2
  echo "$unexpected" | sed 's/^/        /' >&2
  echo "      They are not being measured at all, so every layer percentage" >&2
  echo "      above is optimistic. Regenerate the coverage aggregator:" >&2
  echo "        dart run tool/generate_coverage_aggregator.dart" >&2
fi

resurrected="$(comm -12 "$exempt" "$present")"
if [ -n "$resurrected" ]; then
  failed=1
  echo "FAIL: these files are listed as having no executable lines, but now" >&2
  echo "      appear in $LCOV_FILE:" >&2
  echo "$resurrected" | sed 's/^/        /' >&2
  echo "      Refresh the list with --update and commit it." >&2
fi

vanished="$(comm -13 "$eligible" "$exempt")"
if [ -n "$vanished" ]; then
  failed=1
  echo "FAIL: these files are listed as having no executable lines, but no" >&2
  echo "      longer exist under lib/:" >&2
  echo "$vanished" | sed 's/^/        /' >&2
  echo "      Refresh the list with --update and commit it." >&2
fi

if [ "$failed" -eq 0 ]; then
  echo "Coverage completeness: $(wc -l < "$eligible" | tr -d ' ') eligible files, $(wc -l < "$exempt" | tr -d ' ') with no executable lines, 0 unmeasured."
fi

exit "$failed"
