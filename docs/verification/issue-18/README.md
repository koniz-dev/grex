# Issue #18 — Expenses in a non-group currency are silently dropped from all balances

Verification evidence. Commands run on macOS against branch
`issue-18-constrain-currency-to-group`.

**Verdict: NEEDS-HUMAN.** Criteria 1–6 PASS. Criteria 7 and 8 are marked
`(human)` in the issue and cannot be driven by this repo's tooling.

## Criteria

| # | Criterion | Result | Evidence |
|---|---|---|---|
| 1 | Creating an expense cannot produce a currency mismatch — widget test on `CreateExpensePage` + repository test | PASS | [expenses-tests.log](expenses-tests.log) |
| 2 | Editing cannot change currency away from the group's — same against `EditExpensePage` | PASS | [expenses-tests.log](expenses-tests.log) |
| 3 | Payments constrained identically | PASS | [payments-tests.log](payments-tests.log) |
| 4 | A balances test covers the mismatch explicitly — no path leaves a row recorded-but-ignored | PASS | [balances-tests.log](balances-tests.log) |
| 5 | `dart format --set-exit-if-changed .` clean, `flutter analyze` 0, `flutter test` green | PASS | exit 0; [analyze.log](analyze.log); 1352 passed / 0 failed |
| 6 | Coverage gate passes | PASS | [coverage-gate.log](coverage-gate.log), exit 0 |
| 7 | **(human)** DB-level `CHECK`/trigger against a real Supabase project | NOT DONE | see below |
| 8 | **(human)** Decision on pre-existing mismatched rows in a live database | NOT DONE | see below |

## What was changed

The UI invited a choice the balance engine then discarded. Three identical
free dropdowns over all ten supported currencies are replaced by a single
shared `GroupCurrencyField`, which displays the group's currency and offers
nothing else:

- `create_expense_page.dart`
- `edit_expense_page.dart`
- `create_payment_page.dart`

The form is not the only way a row reaches the table, so the repositories now
refuse a mismatch too — `_checkCurrencyMatchesGroup` reads the owning group's
currency and returns `ExpenseCurrencyMismatchFailure` /
`PaymentCurrencyMismatchFailure`. Wired into `createExpense`, `updateExpense`
and `createPayment`.

## Tests added

| File | Covers |
|---|---|
| `test/features/expenses/presentation/pages/expense_currency_locked_test.dart` | Criteria 1, 2 — neither page offers any of the other nine currencies; tapping the field opens no menu |
| `test/features/payments/presentation/pages/payment_currency_locked_test.dart` | Criterion 3 — same for `CreatePaymentPage` |
| `test/features/expenses/data/repositories/supabase_expense_repository_currency_test.dart` | Criterion 1 — create and update reject a mismatch and never write |
| `test/features/payments/data/repositories/supabase_payment_repository_currency_test.dart` | Criterion 3 — create rejects a mismatch and never writes |
| `test/features/balances/data/balance_currency_exclusion_test.dart` | Criterion 4 — a row the balance engine would ignore cannot be created, and the group currency itself is never rejected |

The widget tests assert the negative directly: for each of the nine currencies
that is *not* the group's, the label `"<CODE> <SYMBOL>"` must not appear
anywhere in the tree. That is what would have caught the original bug.

Criterion 4's file also asserts the converse — an expense **in** the group
currency gets past the guard (it then fails on a deliberately-throwing insert
stub). Without that, a guard that rejected everything would have passed.

### Note on the existing page tests

`create_payment_page_test.dart`, `edit_expense_page_test.dart` and the other
pre-existing page tests are **all skipped**, and were before this change:

```
Skip: TODO(mock-migration): manual `class MockPaymentBloc extends Mock implements
PaymentBloc` pattern broken under mockito null-safety.
```

They never ran, so extending them would have produced tests that never run.
The new files use the working `bloc_test` + `mocktail` template that
`group_list_page_test.dart` established, and they do run. Migrating the skipped
files is pre-existing debt and out of scope here.

A shared `test/helpers/postgrest_fakes.dart` was added for the repository
tests: Supabase builders are awaited directly, so a terminal `.maybeSingle()`
has to satisfy both `PostgrestTransformBuilder<T>` and `Future<T>`, which a mock
cannot express. `supabase_user_repository_test.dart` has its own private copy of
the same fake; consolidating the two was left alone rather than touching a
passing test file.

## Coverage

Gate passes, and the change raises three layers:

| Layer | Before | After |
|---|---|---|
| Total | 30.5% | 33.7% |
| Data | 18.6% | 23.8% |
| Presentation | 36.7% | 40.9% |

Baselines are left untouched — they are the enforced floor, and the rule is to
raise them only once **both** environments confirm the higher number.

## What is NOT fixed — criteria 7 and 8

**Criterion 7 — no database-level guard.** The constraint lives in the Dart
client only. Anything writing to `expenses` or `payments` outside this app —
the Supabase dashboard, SQL, a future service — can still insert a mismatched
row, and it will still vanish from balances. `flutter test` mocks
`SupabaseClient` and never executes a migration, so a `CHECK`/trigger cannot be
written or verified from this session. This needs a real Supabase project.

**Criterion 8 — existing data is untouched.** Any row already in a live database
whose currency differs from its group's is still there and still invisible to
balances. This change does not migrate, convert, or report on it. Agent tooling
has no access to production data.

Both are why this issue goes to `status:needs-uat` rather than closed.

## Also not covered

- **The SQL filter itself.** `calculate_group_balances` is asserted only by
  reading `00009_create_database_functions.sql`; no test executes it.
- **Real device interaction.** The currency field's appearance was verified via
  widget tests, not a running app or a golden.
