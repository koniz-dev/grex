# Issue #37 — Split arithmetic hardcodes 100 minor units

Verification evidence. Commands run on macOS against branch
`issue-37-currency-minor-units`.

**Verdict: NEEDS-HUMAN.** Criteria 1–7 PASS. Criteria 8 and 9 are `(human)`.

## Criteria

| # | Criterion | Result | Evidence |
|---|---|---|---|
| 1 | Split arithmetic is currency-aware; the four `split*` functions and the minor-unit helpers take the currency | PASS | [expenses-tests.log](expenses-tests.log) |
| 2 | 100,000 VND three ways is whole đồng summing to 100,000; same for 10,000 JPY and KRW | PASS | `zero-decimal currencies` group |
| 3 | Two-decimal currencies unchanged; existing USD/EUR tests pass untouched | PASS | all 36 pre-existing assertions unchanged |
| 4 | Three-decimal currencies round-trip or are rejected — not silently 2-decimal | PASS — they round-trip | `three-decimal currencies` group |
| 5 | Property test: sum equals total **and** every share is a whole minor unit | PASS | `minor-unit property sweep` |
| 6 | One source of truth for the exponent in Dart | PASS | `CurrencyFormatter.getCurrencyPrecision` |
| 7 | format clean, analyze 0, `flutter test` green, coverage gate | PASS | 1409 passed / 0 failed; gate exit 0 |
| 8 | **(human)** align the Dart table with `get_currency_decimal_places`; decide the SQL function's fate | NOT DONE | needs a live Supabase project |
| 9 | **(human)** decision on rows already persisted with fractional minor units | NOT DONE | no access to production data |

## The fix

`_toCents` / `_fromCents` became `_toMinorUnits` / `_fromMinorUnits`, scaled by
`pow(10, CurrencyFormatter.getCurrencyPrecision(currency))` instead of a
hardcoded `100`. All four `split*` functions plus `validateSplit`,
`calculateSplit`, `validateSplitConfiguration` and `recalculateSplit` now take a
required `currency`.

**Required, not defaulted.** A default would have silently reintroduced the bug
for any caller that forgot; making it required turned the compiler into the
checklist, and it found all 10 call sites in `lib/` immediately.

## Criterion 6 — one table, not two

The exponent lives only in `CurrencyFormatter._getDecimalDigits`, reached
through the existing public `getCurrencyPrecision`. The calculator deliberately
keeps no list of its own — two lists drift, and that drift *is* this bug.

That table was also widened to match `get_currency_decimal_places` in
`00013_create_currency_validation.sql`: it previously knew only VND/JPY/KRW as
zero-decimal and nothing about three-decimal currencies, so BHD and KWD were
silently 2-decimal — exactly what criterion 4 forbids.

| Exponent | Currencies |
|---|---|
| 0 | JPY, KRW, VND, IDR, CLP, PYG, UGX, RWF, KMF, GNF, MGA, XOF, XAF |
| 3 | BHD, IQD, JOD, KWD, LYD, OMR, TND |
| 2 | everything else |

## The new tests fail against the old behaviour

The check that matters. Reverting only `_minorUnitScale` to a constant `100` and
re-running turns **9 of the new tests red**, and restoring it returns them green:

```
minor-unit property sweep every share is a whole number of minor units [E]
three-decimal currencies BHD round-trips at thousandth precision [E]
three-decimal currencies KWD round-trips at thousandth precision [E]
three-decimal currencies OMR round-trips at thousandth precision [E]
zero-decimal currencies JPY shares are whole units and sum to the total [E]
zero-decimal currencies KRW shares are whole units and sum to the total [E]
zero-decimal currencies VND 100,000 three ways is 33334 / 33333 / 33333 [E]
zero-decimal currencies VND shares are whole units and sum to the total [E]
zero-decimal currencies the leftover unit is one dong, not one hundredth of one [E]
```

Measured behaviour, before and after, for the issue's own reproduction:

| | shares | on screen |
|---|---|---|
| Before | 33333.34 / 33333.33 / 33333.33 | "33.333 ₫" ×3, summing to 99,999 |
| After | 33334 / 33333 / 33333 | whole đồng, summing to 100,000 |

## Criterion 3 — nothing regressed for two-decimal currencies

All 36 pre-existing calculator tests pass with **no assertion changed**; the only
edit was adding `currency: 'USD'` to each call, which the new required parameter
forces. That includes #4's leftover-cent distribution (14.29 ×4 / 14.28 ×3) and
the 0.01–1000.00 × 1–12 conservation sweep.

## A flaky full-suite run, recorded rather than hidden

One full-suite run reported `1406 +3 failures` and took 9m29s against a normal
3m15s. Two subsequent runs were clean at 1409 passed / 0 failed. The slowdown
points at machine contention rather than a real failure, but **I did not capture
which three tests failed**, so I cannot prove that. Recording it because a
reader deserves to know a red run happened, and because if it recurs the
starting point matters.

## Coverage

Gate passes; Domain rises 58.0% → 58.2%. Baselines untouched.

## Not covered

- **Criteria 8 and 9.** The Dart table now *mirrors* the SQL function but nothing
  enforces that; aligning them for real, and deciding whether
  `get_currency_decimal_places` becomes the single source or is dropped as dead
  code (it is currently called only from `supabase/tests/`), needs a live
  Supabase project.
- **Rows already stored with fractional minor units** are untouched. A VND
  expense split before this change still holds 33333.34 in the database.
- **No UI verification.** The display layer already rendered VND with zero
  decimals correctly; this fixes what is computed and stored, verified by unit
  test, not by a screenshot.
