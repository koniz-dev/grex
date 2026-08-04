# Code Audit — 2026-08-04

Scope: architecture and dependency wiring, expense-split money math, secrets
handling, build reproducibility, dead code, docs accuracy. Every finding below
was reproduced against the working tree at commit `fd75d4e`, not inferred from
reading alone.

## Baseline

| Check | Result |
|---|---|
| `flutter analyze` | **0 issues** (after `flutter pub get` — see F5) |
| `flutter test` | Passes; 48 `skip:` markers across the suite |
| Test files | 160 (`test/` + `integration_test/`) |
| Dart files in `lib/` | 293 |

## Findings

| # | Severity | Area | Finding |
|---|---|---|---|
| F1 | **Critical** | Money math | `splitEqually` does not conserve the total; equal-split expenses are rejected or silently lose cents |
| F2 | **Critical** | Money math | `splitByExactAmounts` throws on any amount with cents — `SplitMethod.exact` is unusable |
| F3 | **High** | Money math | `validateSplit` truncates every share with `.toInt()`; returns `false` for correct splits |
| F4 | **High** | Secrets | `.env` is bundled as a Flutter asset while `.env.example` and a rotation script populate `SUPABASE_SERVICE_ROLE_KEY` into it |
| F5 | **High** | Build | A fresh clone cannot build: `.env` is gitignored but declared as a required asset |
| F6 | **Medium** | Money math | `recalculateSplit` corrupts share ratios and throws for `exact` when the amount changes |
| F7 | **Medium** | Dead code | The entire Dio network layer is unreferenced but documented as a feature |
| F8 | **Medium** | DI | `AuthRepository` is instantiated twice (GetIt + Riverpod), each with its own auth-stream subscription |
| F9 | **Medium** | DI | `AuthNotifier` reaches into `GetIt.instance<UserRepository>()`, defeating provider overrides in tests |
| F10 | **Low** | Leak | `goRouterProvider`'s `ValueNotifier` is never disposed |
| F11 | **Low** | Dead code | ~10 unreferenced services/utils/example screens ship in `lib/` |
| F12 | **Low** | Build hygiene | Generated l10n Dart files are committed and had drifted from the ARB sources |
| F13 | **Low** | Tests | Money tests use integer amounts and a 2-cent tolerance, which is why F1–F3 went unnoticed |

---

### F1 — `splitEqually` does not conserve the total (Critical)

[expense_calculator.dart](../../lib/features/expenses/domain/utils/expense_calculator.dart)

Two defects compound:

1. The remainder-distribution loop is guarded by `remainder > 0`, but `remainder`
   is never decremented inside the loop. If the loop ever ran it would add `0.01`
   to **every** participant instead of to the first `remainder / 0.01` of them.
2. It cannot run in practice: the guard `remainderPerParticipant > 0` computes
   `round(remainder / count)` to two decimals, which is `0.00` for the small
   remainders that actually occur. So the remainder is simply dropped.

Measured — sum of returned shares vs the requested total:

```
total=10.00  n=3  -> 9.99    (-0.01)
total=10.00  n=6  -> 10.02   (+0.02)
total=10.00  n=7  -> 10.01   (+0.01)
total=100.00 n=3  -> 99.99   (-0.01)
total=100.00 n=6  -> 100.02  (+0.02)
total=100.00 n=7  -> 100.03  (+0.03)
total=0.10   n=7  -> 0.07    (-0.03)
total=99.99  n=7  -> 99.96   (-0.03)
```

16 of 20 sampled (total, participant-count) pairs mismatch.

**User-visible impact.** `SupabaseExpenseRepository._validateSplitTotals`
rejects any split whose sum differs from the expense amount by more than
`0.01`. So splitting **100.00 equally among 6 or 7 people fails outright** with
`InvalidSplitFailure: Split total (100.02) does not match expense amount
(100.0)`. Cases that are off by exactly one cent slip past the guard and get
persisted, so group balances never settle to zero.

The same tolerance exists server-side in `validate_expense_split()`
([00009](../../supabase/migrations/00009_create_database_functions.sql)).

**Fix direction:** do the arithmetic in integer minor units (cents), then hand
out the `total_cents % count` leftover cents one each to the first N
participants — deterministically ordered — and never round a per-share float.

### F2 — `splitByExactAmounts` throws on any amount with cents (Critical)

```dart
final totalExactAmounts = exactAmounts.values.fold(
  0,
  (sum, amount) => (sum + amount).toInt(),   // truncates on every step
);
```

`{5.50, 4.50}` against a total of `10.00` folds to `9`, so the function throws
`ArgumentError: Exact amounts must sum to total amount. Expected: 10.0, Got: 9`.
Only whole-currency amounts survive.

Worse, the UI pre-check `validateSplitConfiguration` sums correctly with
doubles, so the form reports **valid** and the failure surfaces later from
`calculateSplit`. Reproduced directly.

### F3 — `validateSplit` truncates every share (High)

```dart
final totalSplit = splitAmounts.values.fold(0, (sum, amount) => sum + amount.toInt());
```

`validateSplit(totalAmount: 10.00, splitAmounts: {3.34, 3.33, 3.33})` returns
**`false`** — the shares sum to exactly `10.00`. The function is only correct
when every share is a whole number.

### F4 — `.env` is bundled into the app while documenting a service-role key (High)

`pubspec.yaml` declares `.env` in `flutter: assets:`. Flutter assets are shipped
inside the APK/IPA and, for web builds, served at a public URL.

Meanwhile `.env.example:74` documents `SUPABASE_SERVICE_ROLE_KEY=` with the
comment *"Keep this secret! Only use on server-side"*,
[supabase/README.md:38](../../supabase/README.md) shows it filled in with a real
looking JWT, and
`scripts/windows/database/utils/rotate-api-keys.ps1:229` **writes the freshly
rotated service-role key into `.env`**.

The service-role key bypasses every RLS policy in the database.

**Current state:** `SUPABASE_SERVICE_ROLE_KEY` is empty in the local `.env` and
no Dart code reads it, so nothing is leaking today. This is a latent footgun,
not an active breach — but the rotation script will arm it the first time anyone
runs it.

**Fix direction:** remove `SUPABASE_SERVICE_ROLE_KEY` from `.env` / `.env.example`
entirely and keep it in a server-only location; or stop bundling `.env` as an
asset and pass client config via `--dart-define`. Add a CI check that fails if a
bundled asset contains a `service_role` JWT.

### F5 — A fresh clone cannot build (High)

`.env` is gitignored (`.gitignore:51`) but declared as a required Flutter asset.
Verified by moving `.env` aside and building:

```
Error detected in pubspec.yaml:
No file or variants found for asset: .env.
Target copy_flutter_bundle failed: Exception: Failed to bundle asset files.
```

The build fails before Dart runs, so `_ConfigErrorApp` — the friendly
"Configuration error" screen in `main.dart` — is unreachable for this case, and
the `pubspec.yaml` comment *"The .env file is optional - the app works with
`--dart-define` flags too"* is false as written.

Related: `flutter analyze --no-pub` on a stale `.dart_tool/` reported 6 phantom
`google_sign_in` resolution errors. `flutter pub get` clears them. Anyone
diagnosing "the project doesn't compile" should run `pub get` first.

**Fix direction:** commit an empty placeholder `.env` (values from
`--dart-define` still win via `EnvConfig`'s fallback chain), or drop `.env` from
the asset list and make `--dart-define` the documented path.

### F6 — `recalculateSplit` corrupts the split when the amount changes (Medium)

For `SplitMethod.shares` it reconstructs share counts from percentages against
`currentParticipants.length * 1`, discarding the original weights:

```
shares 3:1 on 100.00  -> a=75.00, b=25.00      (correct)
change amount to 200  -> a=133.33, b=66.67     (expected a=150.00, b=50.00)
```

For `SplitMethod.exact` it passes the **old** amounts against the **new** total,
which then trips F2's validation and throws.

### F7 — The Dio network layer is dead code (Medium)

`apiClientProvider` has zero references outside its own definition. Every
repository talks to `SupabaseClient` directly. Unreferenced as a result:
`api_client.dart`, all six interceptors (`auth`, `error`, `logging`,
`api_logging`, `cache`, `performance`), and `api_endpoints.dart`.

Consequences beyond the wasted code:

- `main.dart` spends a block copying access/refresh tokens into secure storage
  with the comment *"so AuthInterceptor can attach Bearer token to API
  requests"* — for an interceptor nothing instantiates.
- The header redaction logic in `api_logging_interceptor.dart` protects nothing.
- `README.md` and `design-decisions.md` advertise the network layer as a
  working feature.

**Fix direction:** either delete the layer and the token-sync block, or keep it
explicitly labelled as scaffolding for future non-Supabase APIs. Do not leave it
documented as active.

### F8 / F9 / F10 — DI seam defects (Medium / Medium / Low)

See [state-management.md](../architecture/state-management.md#known-issues-in-the-current-wiring)
for the details and fixes.

### F11 — Unreferenced code in `lib/` (Low)

No references outside their own file: `OptimizedSessionService`,
`SimpleSessionService`, `RetryService`, `LazyLoader`, `PaginationHelper`,
`Debouncer`, `BreadcrumbNavigation`, `logging_examples.dart`,
`FeatureFlagsExampleScreen`, `CacheInterceptor`. Two session-service
implementations exist while only `SecureSessionService` is registered.

### F12 — Committed generated l10n had drifted (Low)

`lib/l10n/app_localizations_*.dart` are build artifacts but are committed and
not gitignored. Running `flutter pub get` regenerated them, producing 8 changed
lines: the AR and ES password-requirement strings (`pwdReqLength`,
`pwdReqUppercase`, `pwdReqNumber`, `pwdReqSpecial`) were English placeholders in
the committed files while the ARB sources already had proper translations.

Runtime was never affected — the files regenerate on every build — but the
committed copies are noise and mislead anyone reading them to judge translation
coverage. **Fix direction:** gitignore `lib/l10n/app_localizations*.dart`.

### F13 — Money tests are written around the defects (Low)

[expense_calculator_test.dart](../../test/shared/utils/expense_calculator_test.dart)
uses only whole-currency amounts (`50/30/20`, `100`, `150`), which is precisely
the input class F1–F3 handle correctly. The single fractional case asserts
`expect(total, closeTo(100.01, 0.02))` — a two-cent tolerance on a money total,
which accepts a broken result as passing.

**Fix direction:** assert exact conservation (`sum == total` in minor units) and
add a property test sweeping totals `0.01…1000.00` against participant counts
`1…12` for all four split methods.

## Suggested order of work

1. F1, F2, F3 — rewrite `ExpenseCalculator` in integer minor units, and F13
   alongside it so the fix is pinned by tests.
2. F5 — unblock fresh clones.
3. F4 — get the service-role key out of anything bundled.
4. F6 — fix `recalculateSplit` once the calculator is sound.
5. F7, F8, F9, F10, F11, F12 — cleanup.
