# Issue #25 — `recalculateSplit` corrupts share ratios and throws for exact

Verification evidence. Commands run on macOS against branch
`issue-25-recalculate-split`.

## Criteria

| # | Criterion | Result | Evidence |
|---|---|---|---|
| 1 | `recalculateSplit(200)` on a 3:1 shares split of 100.00 returns `a=150.00, b=50.00` | PASS | [calculator-tests.log](calculator-tests.log) |
| 2 | Ratios survive 100 → 200 → 50 → 100, returning the original 75.00/25.00 in cents | PASS | [calculator-tests.log](calculator-tests.log) |
| 3 | `exact` scales proportionally, or fails with a documented caught error | PASS — scales | see below |
| 4 | Every method's result sums to `newTotalAmount` exactly in minor units; sweep extended | PASS | `conservation sweep recalculateSplit …` |
| 5 | Callers handle whatever criterion 3 chose | PASS — **but the premise was wrong** | see below |
| 6 | `flutter analyze` 0, `dart format` clean, `flutter test` green, no new `skip:` | PASS | [analyze.log](analyze.log); 1358 passed / 0 failed |
| 7 | No assertion added uses a tolerance greater than 0 on a money total | PASS | all comparisons are integer cents |

## The defect

`ExpenseParticipant` records only the amount and percentage each person ended up
with — not the share counts or exact amounts that produced them — so the
original configuration is unrecoverable after the fact. The old code tried
anyway, inferring share counts from rounded percentages against
`currentParticipants.length * 1`, i.e. assuming one share each:

```dart
final totalShares = currentParticipants.length * 1; // Default to 1 share each
data['shares'] = max(1, (participant.sharePercentage / 100 * totalShares).round());
```

For 3:1 that is `round(0.75 × 2) = 2` and `round(0.25 × 2) = 1` — a 3:1 split
silently became 2:1 on the first amount change. Measured before the fix:

```
shares 3:1 on 100.00   -> a=75.00, b=25.00     (correct)
recalculate to 200.00  -> a=133.33, b=66.67    (expected a=150.00, b=50.00)
```

For `exact` it fed the **old** amounts against the **new** total, which cannot
sum correctly by construction, so it threw out of `calculateSplit`:

```
exact {a: 60, b: 40} on 100.00
recalculate to 200.00  -> ArgumentError: Exact amounts must sum to total amount.
                          Expected: 200.0, Got: 100.0
```

## The fix, and what criterion 3 chose

What *is* recoverable is each participant's **proportion** of the total. Every
method except `equal` now rescales the existing shares to the new total in
integer minor units, with the last participant absorbing the rounding
remainder. `equal` re-splits equally, which is what it means.

Criterion 3 offered "scale proportionally, or fail with a documented caught
error". **Scaling was chosen**: an amount change is an edit, not a
reconfiguration, and proportional scaling is what the `exact` branch's own
comment already said it intended ("For exact amounts, we need to scale
proportionally") without doing it. `{60, 40}` on 100 recalculated to 200 gives
`{120, 80}`. Failing instead would have required a caller to handle it, and
there is no caller (below).

This also removes the `dart:math` import, whose only use was the `max` in the
deleted reconstruction.

## Criterion 5's premise was wrong

The criterion — which I wrote when filing this issue — says
"`edit_expense_page.dart` calls `recalculateSplit`". **It does not.**

```
$ grep -rn "recalculateSplit" lib/ test/
lib/features/expenses/domain/utils/expense_calculator.dart
test/features/expenses/domain/utils/expense_calculator_test.dart
```

`edit_expense_page.dart` calls `splitEqually`, `getDefaultParticipantData`,
`validateSplitConfiguration` and `calculateSplit` — never `recalculateSplit`.
The function has **no callers in `lib/` at all**; it is currently unreferenced
production code, in the same category as audit finding F11.

So there is nothing for a caller to handle, and the criterion passes vacuously.
That is worth being blunt about: fixing this changed no behaviour any user can
currently reach. It was still worth fixing — the function is public API of a
domain utility and would have been a landmine for whoever wired it up — but
whether it should be wired up or deleted is a separate decision, filed
separately.

## The sweep

Criterion 4's sweep runs every total from 0.01 to 1000.00 against 1 to 12
participants for all four methods, seeded from an uneven (1:2:3:…) split so the
proportions being preserved are not all identical, and asserts the result sums
to the new total exactly as integer cents. 4.8M cases; the seed is built once
per participant count rather than per total, which took the file from 41s to
19s.

## Coverage

Gate passes ([coverage-gate.log](coverage-gate.log), exit 0). Baselines
untouched.

## Not covered

- **No UI verification.** There is no caller, so there is no screen to drive.
- **`ExpenseParticipant` still does not persist the split configuration.** The
  fix preserves proportions, which is the best that can be done from what is
  stored. A split that was originally 3:1 is indistinguishable from one that
  was originally 75%/25% or exact 75.00/25.00 — all three now behave
  identically under recalculation. If the distinction ever matters, the
  configuration has to be stored, which is a schema change and well out of
  scope.
