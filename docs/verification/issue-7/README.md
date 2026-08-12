# Issue #7 — Fate of the unreferenced Dio network layer

Decision (maintainer, 2026-08-12): **keep as scaffolding**, not delete.
Evidence for making the code and docs say so.

## Criteria

| # | Criterion | Result | Evidence |
|---|---|---|---|
| 1 | Every file under `lib/core/network/` and the `apiClientProvider` definition carries an unused-scaffolding notice, enforced by an enumerating test | PASS | [scaffolding-tests.log](scaffolding-tests.log) |
| 2 | A test asserts `apiClientProvider` still has no consumer | PASS | `the layer really has no consumer …` |
| 3 | The `main.dart` token-sync block says nothing reads what it writes; the keep/remove decision recorded | PASS | see below |
| 4 | `README.md` and `design-decisions.md` describe it as present-but-not-wired-up | PASS | see below |
| 5 | format clean, analyze 0, `flutter test` green, no new `skip:` | PASS | [analyze.log](analyze.log); 1370 passed / 0 failed |
| 6 | Coverage gate passes | PASS | [coverage-gate.log](coverage-gate.log), exit 0 |

## What changed

Eight files gained a leading `// UNUSED SCAFFOLDING:` notice — the seven under
`lib/core/network/` plus `lib/core/constants/api_endpoints.dart`, which is
reachable only from the dead layer. `apiClientProvider` gained the doc-comment
form.

Its old doc comment was the worst of the false claims and is gone:

> "This is the main API client used throughout the application for non-auth API
> calls (groups, expenses, payments, etc.)."

It is not. That definition is the only reference to `apiClientProvider` in
`lib/`.

## Criterion 2 is what keeps this from rotting

A comment saying "unused" is wrong the moment someone uses it. So
`test/core/network/network_scaffolding_test.dart` walks `lib/` and asserts
`apiClientProvider` has exactly one non-comment reference — its own definition.

Wiring the layer up is allowed; it just fails this test, which tells the
implementer to delete the notices and the test. The notices can no longer go
stale while still claiming nothing uses the layer.

The notice test enumerates the directory rather than listing files, so a new
interceptor cannot be added without one.

## Criterion 3 — the token writes stay, and here is why

Tracing the keys turned up something the issue understated. `AuthInterceptor` is
the **only reader** of `AppConstants.tokenKey` / `refreshTokenKey` anywhere in
`lib/`. Three places write them:

| Location | Operation |
|---|---|
| `main.dart` session restore | write |
| `secure_session_service.dart` | write, and delete on sign-out |
| `optimized_session_service.dart` | write, and delete on sign-out |

So it is not just `main.dart`: **three sites persist access and refresh tokens
that nothing consumes**, and two of them carried the same misattributing comment
("Sync tokens to keys used by AuthInterceptor").

Decision: **keep the writes, correct all three comments.** Removing them is a
behaviour change, and #7 was explicit that nothing here should change behaviour
— the point is to make the code tell the truth. It would also have to be undone
the moment the layer is wired up, which is the option the maintainer chose to
preserve.

But an unread second copy of live credentials is a real cost, and deciding it is
not this issue's job, so it is filed as #35.

## Criterion 4 — docs

Both had already been partly corrected. What still read as live:

| Where | Before | After |
|---|---|---|
| `README.md` project tree | `network/  # Network layer (Dio setup)` | `network/  # Dio setup — scaffolding, nothing uses it` |
| `README.md` "Network Configuration" | a `Dio(BaseOptions(...))` snippet with no caveat | preceded by a warning that nothing builds a `Dio` client and the snippet is illustrative |
| `design-decisions.md` | "should either be adopted for non-Supabase APIs or deleted" | records the #7 decision to keep, and that the notices plus the test force this section to be updated if the layer is ever wired up |

## Coverage

Gate passes, unchanged from the previous run — the aggregator already imported
these files, so nothing entered or left the denominator. Baselines untouched.

## Not covered

- **Nothing was deleted and nothing was wired up**, by design.
- **The header redaction in `api_logging_interceptor.dart`** is correct code and
  stays. Its notice makes clear it is not on any request path, so nobody reads
  it as evidence that logs are already safe.
- **Whether the duplicate credential copy should exist at all** — filed as #35,
  not decided here.
