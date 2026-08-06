#!/bin/bash
# Calculate total and per-layer line coverage from an lcov.info file.
#
# Output is strictly `key=value` lines, one per line, so a caller can pipe it
# straight into $GITHUB_OUTPUT or `eval` it. Anything human-readable belongs in
# the caller, not here -- this script used to print banner lines that the
# workflow then fed into $GITHUB_OUTPUT as malformed keys.
#
# Every coverage-eligible line is attributed to exactly one bucket, and the
# bucket line counts sum to total_lines. `unclassified_lines` is the escape
# hatch: a non-zero value means a new top-level directory appeared under lib/
# that no bucket claims, and the threshold gate treats that as a failure rather
# than letting the layer table quietly stop reconciling with the total.
#
# The generated-file exclusions below duplicate the `lcov --remove` filter in
# .github/workflows/test.yml on purpose. CI needs that lcov pass anyway to feed
# genhtml and Codecov, but lcov is not installed on a typical dev machine, so
# applying the same filter here is what lets a developer reproduce the exact CI
# numbers with nothing but awk. Applying it to an already-filtered file is a
# no-op, so running it after CI's lcov pass changes nothing. Keep the two lists
# in sync.

set -euo pipefail

LCOV_FILE="${1:-coverage/lcov.info}"

if [ ! -f "$LCOV_FILE" ]; then
  echo "Error: lcov file not found at $LCOV_FILE" >&2
  exit 1
fi

awk '
  function excluded(f) {
    return (f ~ /\.g\.dart$/       ||
            f ~ /\.freezed\.dart$/ ||
            f ~ /\.config\.dart$/  ||
            f ~ /\/generated\//    ||
            f ~ /\/l10n\//         ||
            f ~ /(^|\/)main\.dart$/          ||
            f ~ /_test\.dart$/               ||
            f ~ /(^|\/)test_helpers\.dart$/  ||
            f ~ /(^|\/)test_fixtures\.dart$/ ||
            f ~ /(^|\/)test\//)
  }

  function bucket(f) {
    if (f ~ /\/features\/[^\/]+\/domain\//)       return "domain"
    if (f ~ /\/features\/[^\/]+\/data\//)         return "data"
    if (f ~ /\/features\/[^\/]+\/presentation\//) return "presentation"
    if (f ~ /\/core\//)                           return "core"
    if (f ~ /\/shared\//)                         return "shared"
    return "unclassified"
  }

  function pct(c, t) { return t > 0 ? sprintf("%.1f", c / t * 100) : "0.0" }

  function emit(key, c, t) {
    printf "%s=%s\n",           key, pct(c, t)
    printf "%s_display=%s%%\n", key, pct(c, t)
    printf "%s_lines=%d\n",     key, t
    printf "%s_covered=%d\n",   key, c
  }

  /^SF:/ {
    file = substr($0, 4)
    skip = excluded(file)
    b    = bucket(file)
    next
  }

  /^DA:/ {
    if (skip) next
    split($0, parts, ",")
    lines[b]++
    lines["total"]++
    if (parts[2] != "0" && parts[2] != "") {
      hits[b]++
      hits["total"]++
    }
    next
  }

  # Guard against a malformed record leaking DA lines into the previous file s
  # bucket: until the next SF: line, attribute nothing.
  /^end_of_record/ { skip = 1; next }

  END {
    n = split("total domain data presentation core shared unclassified", order, " ")
    for (i = 1; i <= n; i++) {
      k = order[i]
      emit(k, hits[k] + 0, lines[k] + 0)
    }
  }
' "$LCOV_FILE"
