# Issue #29 — `recalculateSplit` has no callers: wire it up or delete it

Verification evidence. Commands run on macOS against branch
`issue-29-recalculate-split-fate`.

## Criteria

| # | Criterion | Result | Evidence |
|---|---|---|---|
| 1 | Determine what `edit_expense_page.dart` does when only the amount changes on a non-equal split, and record it | PASS | see below |
| 2 | Either `recalculateSplit` has a caller in `lib/` with a test covering the amount-edit path, or it is deleted | PASS — wired up | [amount-change-tests.log](amount-change-tests.log) |
| 3 | If wiring it up reveals the page silently changes ratios, file that separately as a `type:bug` | PASS — filed, **with a deviation, see below** | |
| 4 | `dart format` clean, `flutter analyze` 0, `flutter test` green, no new `skip:` | PASS | [analyze.log](analyze.log); 1366 passed / 0 failed |
| 5 | Coverage gate passes | PASS | [coverage-gate.log](coverage-gate.log), exit 0 |

## Criterion 1 — observed behaviour, and it is worse than the issue guessed

The issue anticipated that the page "silently re-splits some other way". What
actually happens is a **hard block**.

`_updateSplitCalculation()` ran on every amount keystroke and rebuilt the split
from `ExpenseCalculator.getDefaultParticipantData`, whose defaults are one share
each, an even percentage, and — for `exact` — **`0.0`**.

`_determineSplitMethod` classifies any non-equal split as `exact`, so a 3:1
split of 100.00 edited to 200.00 reset both shares to 0.00 and the form then
rejected itself. Observed on screen, by driving the real widget:

```
Split configuration error: Exact amounts must sum to total amount (0.00 ≠ 200.00)
```

The Save button fired no `ExpenseUpdateRequested` at all. **The expense could
not be saved**, at any amount, until the user manually retyped every share.

Before/after for the 3:1 split of 100.00 edited to 200.00, as criterion 1 asks:

| | A (was 75.00) | B (was 25.00) | Saveable? |
|---|---|---|---|
| Before this change | 0.00 | 0.00 | **No** — split validation error |
| After this change | 150.00 | 50.00 | Yes |

## Criterion 2 — wired up, not deleted

Deleting would have been wrong once criterion 1 turned up a live defect that
this exact function fixes.

`_rescaleSplitToAmount()` now handles the amount field and calls
`recalculateSplit`, preserving each participant's proportion.
`_updateSplitCalculation()` is untouched and still handles the split-method and
participant-selection changes, where resetting to defaults **is** correct — a
distinction the old code did not draw.

Three widget tests cover the path end to end by capturing the
`ExpenseUpdateRequested` the page sends to a mocked bloc:

- the 3:1 split stays 3:1 (150.00 / 50.00)
- an amount that does not divide still conserves exactly (100.01 → 10001 cents)
- no split validation error appears after an amount edit

The first and third fail against the pre-change page — the first because no
save event is emitted at all, which is how the hard block was found.

## Criterion 3 — filed, and a deviation I should flag

The criterion says to file the discovered defect "rather than folding it in
here". I filed it, but I **did** fix it here, because the two are not
separable: criterion 2's only non-deletion option is to give `recalculateSplit`
a caller, and the sole sensible caller is the amount-edit path — so wiring it up
*is* the fix. Splitting them would have meant either deleting a function that a
just-filed bug requires, or landing a caller that still resets the split to
zeros.

The bug is filed anyway so the tracker records that this shipped as a
user-facing fix and not merely as dead-code cleanup, and it is closed by this
PR rather than left open.

## Coverage

Gate passes; Presentation rises 40.9% → 41.8% and Domain 56.2% → 56.6%.
Baselines untouched.

## Not covered

- **A real device.** Verified through widget tests against a mocked
  `ExpenseBloc`, not a running app. Nothing here proves how the rescaled numbers
  look on screen as the user types.
- **`create_expense_page.dart`.** It has no pre-existing split to preserve, so
  resetting to defaults on an amount change is correct there and it is
  unchanged.
- **The `shares` display.** `_participantSplitData` keeps its `'shares': 1`
  placeholder; rescaling updates `amount` and `percentage` only. That matches
  what `_determineSplitMethod` can actually recover — the original share counts
  are not stored anywhere, which is the limitation recorded in #25.
