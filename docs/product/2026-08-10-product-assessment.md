# Product Assessment — 2026-08-10

Scope: whether the problem Grex solves is real, which parts of the current
feature set carry that value, and where the product should go next. Every claim
about the code below was checked against the working tree at commit `3b259eb`.

This is a direction document, not a work queue. Anything here that becomes work
becomes a GitHub issue; issues are the source of truth.

## Verdict

The problem is real. **The part of it Grex has invested most in is not.**

Splitting one bill is not a problem worth an app — a calculator does it in
fifteen seconds, and in practice most splits are equal. The split-method matrix
(`equal` / `percentage` / `exact` / `shares`) in
[expense_calculator.dart](../../lib/features/expenses/domain/utils/expense_calculator.dart)
is table stakes. It is what makes the app credible, not what makes it worth
installing.

What is worth an app is what accumulates over **time** and across **people**:

1. **Memory.** A four-day trip, six people, twenty expenses, a different payer
   each time. Nobody can hold that. This is where an app beats a calculator.
2. **Netting.** Six people owing each other pairwise produces ~15 transfers;
   netting reduces it to 4.
   [`generate_settlement_plan`](../../supabase/migrations/00009_create_database_functions.sql#L164)
   is the single highest-value thing in this repository.
3. **A shared source of truth**, so nobody has to chase anyone verbally. This is
   social value, not arithmetic value — the app plays debt collector so a person
   doesn't have to.
4. **Friction at payment time.** Knowing you owe 340k does not move money.
   Opening a banking app, typing an account number and an amount does.

## Where the code sits against that

| What actually hurts | State in the repo |
|---|---|
| Netting / settlement plan | Present, greedy in SQL — sound |
| Ledger over time | Present (expenses + payments + balances) |
| Multi-currency for overseas trips | **Absent, and actively wrong — see below** |
| Recurring expenses (rent, utilities, internet) | Absent |
| Debt reminders / notifications | Absent |
| Onboarding people who will not install an app | Absent — every member must be a registered user |
| One-tap settlement (VietQR / bank deep link) | Absent |
| Receipt capture | Absent |

The two situations that actually make someone need this app — **an overseas
trip** and **a shared household paying monthly bills** — are the two the current
build serves worst. The first produces wrong numbers; the second has no
recurring expenses and no reminders.

## The multi-currency defect

Not a missing feature — a data-correctness bug, and more serious than F1–F3 in
the [code audit](../audit/2026-08-04-code-audit.md) because it fails silently.

- Expense creation and editing offer a currency dropdown with 10 currencies
  ([create_expense_page.dart:244](../../lib/features/expenses/presentation/pages/create_expense_page.dart#L244),
  [edit_expense_page.dart:428](../../lib/features/expenses/presentation/pages/edit_expense_page.dart#L428);
  list in [currency_formatter.dart:181](../../lib/shared/utils/currency_formatter.dart#L181)).
- Nothing constrains that choice to the group's `primary_currency`, and the
  `expenses` table only checks the ISO-4217 shape
  ([00005](../../supabase/migrations/00005_create_expenses_table.sql#L38)).
- [`calculate_group_balances`](../../supabase/migrations/00009_create_database_functions.sql#L38)
  filters every CTE on `e.currency = group_currency`.

Result: an expense recorded in a non-primary currency appears in the expense
list, appears in exports, and contributes **nothing** to anybody's balance. No
error, no warning. The group silently under-counts what it owes.

Tracked as an issue; see the tracker for current state.

## Direction

Do not compete with Splitwise/Tricount on an identical feature list. Pick one
wedge and go deep.

### Wedge 1 — One-tap settlement (strongest for the VN market)

Turn a settlement plan row into a VietQR code or a bank deep link, prefilled
with the recipient's account and the exact amount. Splitwise cannot follow here;
their settle-up is tied to Venmo/PayPal.

This is the wedge that closes the loop — it moves the app from *a record of who
owes what* to *the thing that gets people paid*. Everything else in this
category is a ledger; almost nothing is a closer.

### Wedge 2 — Remove the account barrier

Let a group creator add members as plain names, and share the group by a link
that works without signing in. Requiring six people to install an app and
register is the number one reason products in this category die inside a friend
group. Only the person who cares needs an account.

### Wedge 3 — Do currency properly (only if trips are the chosen segment)

Store the FX rate at the moment of the expense, hold balances in one functional
currency, and display both. This subsumes the defect above. It is a real
feature, not a fix — it needs a rate source, a rate-staleness policy, and a
decision about who absorbs FX drift between spend and settlement.

### Wedge 4 — Recurring + reminders (only if shared households are the segment)

Monthly rent, utilities, internet: define once, generate automatically, notify.
Different product shape from trips — steadier, lower engagement, higher
retention.

Wedges 3 and 4 are alternatives, not a sequence. They serve different segments
and pull the product in different directions; choosing both is choosing neither.

## Open question for the maintainer

Which segment is Grex for — trips, or shared households? Nearly every roadmap
decision below the wedge level depends on that answer, and it has not been
written down anywhere in this repository.
