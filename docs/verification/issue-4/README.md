# Issue #4 — Expense split math loses cents and throws on fractional amounts

Verification evidence for the integer-minor-unit rewrite of `ExpenseCalculator`.
All commands run on macOS against the branch `issue-4-integer-cent-split`.

## Criteria

| # | Criterion | Result | Evidence |
|---|---|---|---|
| 1 | `flutter test test/features/expenses/domain/utils/expense_calculator_test.dart` passes and contains a property test sweeping 0.01–1000.00 × 1–12 participants for all four split methods | PASS | [calculator-tests.log](calculator-tests.log); sweep in the `conservation sweep` group |
| 2 | Every (total, count) pair: `splitEqually` sums to the total exactly in minor units, compared as integers | PASS | `conservation sweep splitEqually …` — 100,000 totals × 12 counts, `expect(_sumCents(result), equals(cents))` |
| 3 | `splitEqually(100.00, 7 ids)` returns a deterministic distribution of the leftover cents summing to exactly 100.00 | PASS | [criteria-3-4-5.log](criteria-3-4-5.log) |
| 4 | `splitByExactAmounts(10.00, {a: 5.50, b: 4.50})` returns those amounts and does not throw | PASS | [criteria-3-4-5.log](criteria-3-4-5.log) |
| 5 | `validateSplit(10.00, {3.34, 3.33, 3.33})` returns `true` | PASS | [criteria-3-4-5.log](criteria-3-4-5.log) |
| 6 | Full `flutter test` passes with no test newly marked `skip:`; `flutter analyze` reports 0 issues | PASS | [full-suite.log](full-suite.log), [analyze.log](analyze.log) |
| 7 | No assertion in the money tests uses a tolerance greater than 0 on a total | PASS | No `closeTo` remains in the file; totals compared as integer cents |

## Criterion 3 — the stated example is arithmetically impossible

The criterion asks for "six shares of 14.29 and one of 14.28". That sums to
**100.02**, not 100.00, so no implementation can produce it. 10000 cents over 7
is 1428 base with 4 cents left over, so the only conserving distributions have
**four** shares of 14.29 and three of 14.28.

The criterion's parenthetical — "or any deterministic distribution of the
leftover cents, summing to exactly 100.00" — is what was verified:

```
splitEqually(100.00, 7 ids) = {user1: 14.29, user2: 14.29, user3: 14.29,
                               user4: 14.29, user5: 14.28, user6: 14.28,
                               user7: 14.28}
sum in cents = 10000
```

## The tests fail against the old calculator

The audit's F13 finding was that the suite was written around the defects, so
the new tests were run against the **pre-fix** `expense_calculator.dart` to prove
they actually pin the behaviour. Eight tests fail there and all pass after the
fix — see [tests-against-old-calculator.log](tests-against-old-calculator.log):

```
ExpenseCalculator conservation sweep splitByExactAmounts round-trips an equal split [E]
ExpenseCalculator conservation sweep splitEqually conserves the total for every total and count [E]
ExpenseCalculator conservation sweep validateSplit accepts every conserving split [E]
ExpenseCalculator splitByExactAmounts should accept amounts with cents in them [E]
ExpenseCalculator splitEqually should conserve the total exactly when it does not divide [E]
ExpenseCalculator splitEqually should conserve the total for the counts that used to fail [E]
ExpenseCalculator splitEqually should hand out leftover cents deterministically [E]
ExpenseCalculator validateSplit should validate a split whose shares carry cents [E]
```

The `splitByPercentage` and `splitByShares` sweeps pass both before and after:
those two already conserved the total via last-participant absorption. Their
conversion to minor units is a consistency change, not a defect fix, and the
sweep is what demonstrates it preserved behaviour.

## Full suite and coverage

`flutter test`: **1322 passed, 572 skipped, 0 failed**. The 572 skips are the
pre-existing baseline; this branch adds none (`git diff HEAD -- test/ | grep
'^+.*skip:'` returns 0 lines).

`flutter analyze`: **No issues found!**

Coverage gate ([coverage.log](coverage.log)) passes, with Domain rising to 54.1%
against its 52% baseline:

| Layer | Coverage | Baseline | Status |
|-------|----------|----------|--------|
| Total | 32.7% | 31% | PASS |
| Domain | 54.1% | 52% | PASS |
| Data | 18.9% | 17% | PASS |
| Presentation | 37.0% | 36% | PASS |
| Core | 14.0% | 13% | PASS |
| Shared | 60.2% | 46% | PASS |

Baselines were left unchanged: the gains are within the existing headroom and
no baseline was lowered.

## Not covered here

- **Server-side tolerance.** `validate_expense_split()` in
  [00009_create_database_functions.sql](../../../supabase/migrations/00009_create_database_functions.sql)
  still carries the same 0.01 tolerance. Out of scope per the issue.
- **F6 (`recalculateSplit` corrupting share ratios).** Depends on this landing
  and is to be filed separately.
- **No UI screenshot.** The change is pure domain arithmetic with no visual
  surface of its own; the split figures it feeds are covered by the unit tests
  above rather than by a golden.
