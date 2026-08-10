# Issue #15 — Coverage silently omits files no test imports

Verification evidence for the coverage aggregator.
Commands run on macOS against branch `issue-15-coverage-aggregator`;
CI figures from the Tests run on PR #26.

## Criteria

| # | Criterion | Result | Evidence |
|---|---|---|---|
| 1 | Every eligible `.dart` under `lib/` appears in `lcov.info`, verified by a check that diffs the file list against `SF:` entries and reports an empty difference | PASS with a documented exception | [completeness-check.log](completeness-check.log) — see below |
| 2 | `lib/shared/widgets/language_switcher.dart` appears, with its uncovered lines counted | PASS | [language-switcher-lcov.log](language-switcher-lcov.log) |
| 3 | The aggregator is generated or verified by a committed script, not hand-maintained; a test fails if it is stale | PASS | `tool/generate_coverage_aggregator.dart`; staleness proof below |
| 4 | `BASELINE_*` re-derived by the `min(observed) - 1.0` rule from #14, gate exits 0 | PASS | [coverage-gate-local.log](coverage-gate-local.log), exit 0 |
| 5 | Before/after numbers recorded in the PR body with the drop explained per layer | PASS | PR #26 |
| 6 | `dart format --set-exit-if-changed .` clean, `flutter analyze` 0 issues, `flutter test --exclude-tags golden` green | PASS | format exit 0; "No issues found!"; 1334 passed / 0 failed |

## Criterion 1 could not be met as literally written

It asks for an **empty** difference between eligible files and `SF:` entries.
36 files can never appear in `lcov.info`, no matter what imports them, because
they contain no executable lines and the VM therefore emits no `DA:` records.
Verified by reading them rather than assuming:

| Kind | Example | What is in it |
|---|---|---|
| Barrel | `lib/features/auth/domain/entities/entities.dart` | `library;` plus 4 `export` lines |
| Abstract interface | `lib/features/auth/domain/repositories/auth_repository.dart` | 154 lines of method declarations, no bodies |
| Const holder | `lib/core/storage/storage_version.dart` | 4 `static const` fields |
| Token barrel | `lib/shared/theme/design_tokens.dart` | 10 `export` lines |

So the check enforces the honest version of the criterion: everything eligible
must be present **except** files with nothing to execute, which are listed in
`scripts/linux/testing/coverage_declaration_only.txt` — generated with
`--update`, not hand-written.

`check_coverage_completeness.sh` fails on three distinct drifts: a file missing
that is not on the list, a listed file that starts producing coverage, and a
listed file that no longer exists. It runs inside `check_coverage_thresholds.sh`,
so the gate refuses to publish a percentage whose denominator has a hole in it.

Current state — 286 eligible, 36 with no executable lines, **0 unmeasured**.

## The check actually bites

Deleting one real file's record from an lcov and re-running (this is exactly the
original bug, reproduced):

```
FAIL: these files under lib/ are missing from .../lcov_holed.info:
        lib/shared/widgets/language_switcher.dart
      They are not being measured at all, so every layer percentage
      above is optimistic. Regenerate the coverage aggregator:
        dart run tool/generate_coverage_aggregator.dart
```

Exit 1 from the completeness check, and exit 1 from the whole gate.
See [completeness-catches-hole.log](completeness-catches-hole.log).

## The staleness test bites

Adding an un-imported file under `lib/` turns the suite red:

```
Which: at location [70] is 'package:grex/core/utils/validators.dart'
       instead of 'package:grex/core/utils/tmp_escapee.dart'
The coverage aggregator is stale, so some libraries are missing from lcov.info
and every layer percentage reads higher than the truth. Regenerate it with:
  dart run tool/generate_coverage_aggregator.dart
```

`--check` mode exits 1 when stale and 0 when fresh, confirmed both ways.

The rules live in `tool/coverage_aggregator.dart`, which the **generated test
imports**, so the generator and its staleness check share one definition of
"coverage-eligible" and cannot drift apart.

## Numbers

1112 lines entered the denominator (15584 → 16696). 65 files that no test
imported were absent from lcov entirely — not counted as 0%, simply missing.

| Layer | Before (min) | After (min) | New baseline | Moved |
|---|---|---|---|---|
| Total | 32.3 | 30.5 | 29 | −1.8 |
| Domain | 53.1 | 53.4 | 52 | +0.3 |
| Data | 18.9 | 18.6 | 17 | −0.3 |
| Presentation | 37.0 | 36.7 | 35 | −0.3 |
| Core | 14.0 | 11.7 | 10 | −2.3 |
| Shared | 47.8 | 35.5 | 34 | −12.3 |

`core` and `shared` fell hardest because that is where the unimported files were
concentrated — `lib/core/performance/`, `lib/core/utils/`, and the shared
widgets. `domain` rose slightly: the aggregator loads barrel files whose
exported libraries were already covered.

### The local/CI divergence is gone

That was the second half of the issue. Observed per layer:

| Layer | Local (2 runs) | CI | Agree? |
|---|---|---|---|
| Total | 30.6, 30.6 | 30.5 | within 0.1 |
| Domain | 54.0, 54.0 | 53.4 | within 0.6 |
| Data | 18.6, 18.6 | 18.6 | exact |
| Presentation | 36.7, 36.7 | 36.7 | exact |
| Core | 11.7, 11.7 | 11.7 | exact |
| **Shared** | **35.5, 35.5** | **35.5** | **exact** |

`shared` was the 12-point offender (47.8 local vs 60.2 CI) and now reads
identically in both. Four of six layers match exactly.

### Why the domain baseline is 52, not 53

Local said 54.0 and CI said 53.4. A local-only reading would have set 53, which
passes that CI run by 0.4 points — against the 0.9 points of run-to-run drift
`coverage_baseline.env` already records for this exact layer. That is the trap
#14 fell into, so the rule was applied to `min(observed)` across both
environments: `floor(53.4 − 1.0) = 52`.

## Note on lowered baselines

Every baseline except `domain` moved down. `coverage_baseline.env` forbids
lowering a baseline to turn a red build green, and permits it only "when a
measurement changes meaning" — which is precisely this change, and the reason is
recorded in that file alongside the numbers.

## Not covered here

- **Whether the aggregator slows the suite.** Not measured; the full run was
  ~2m57s before and after, so any effect is within noise.
- **The `lcov --remove` filter in `test.yml`.** It is a third copy of the
  exclusion rules, now pointed at from both other copies, but unifying the three
  was out of scope.
