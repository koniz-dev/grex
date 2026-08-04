# State Management & Dependency Injection

**Status:** Current as of 2026-08-04. Supersedes the "State Management: Riverpod"
section of [design-decisions.md](design-decisions.md), which describes an
earlier Riverpod-only design that the code no longer follows.

This app runs **three** systems side by side: BLoC, Riverpod, and GetIt. That is
unusual enough that it needs to be written down, because reading any one of them
in isolation gives a misleading picture of how state flows.

## Who owns what

| System | Owns | Entry point |
|---|---|---|
| **BLoC** (`flutter_bloc`) | All feature business logic and UI events — auth, groups, expenses, payments, balances | `lib/features/*/presentation/bloc/` |
| **Riverpod** | Infrastructure singletons (storage, logging, performance, localization, feature flags), the router, and the auth→router bridge | `lib/core/di/providers.dart` |
| **GetIt** | Repositories and BLoC construction | `lib/core/di/injection.dart`, `lib/core/di/main_app_injection.dart` |

Pages resolve their BLoC from GetIt (`getIt<GroupBloc>()`), read infrastructure
from Riverpod (`ref.watch(...)`), and never mix the two for the same concern.

## The one place they meet: auth → router

This is the only cross-system data flow, and it is deliberate.

```
Supabase auth stream
        │
        ▼
AuthRepository.authStateChanges
        │
        ├──────────────► AuthBloc          → drives auth UI (login, register,
        │                                     verification, profile setup)
        │
        └──────────────► AuthNotifier      → Riverpod state, bridge only
                              │
                              ▼
                    goRouterProvider.refreshListenable
                              │
                              ▼
                    GoRouter.redirect (guards)
```

`AuthNotifier` ([auth_provider.dart](../../lib/features/auth/presentation/providers/auth_provider.dart))
holds **no business logic**. Its whole job is to mirror the repository's auth
stream into Riverpod state so `GoRouter` has something to listen to, plus a
tri-state `hasProfile` flag the redirect uses to park orphaned social-login
sessions on `/profile-setup`.

**This is not two sources of truth.** `AuthBloc` and `AuthNotifier` are both
*derived* from the same Supabase auth stream; neither writes auth state the
other has to learn about. `go_router` needs a `Listenable` and BLoC does not
expose one, so a small Riverpod bridge is a reasonable adapter.

## Rules when adding code

1. **New feature state → BLoC.** Do not add a Riverpod notifier for feature
   logic. Register the BLoC in `configureMainAppDependencies()`.
2. **New infrastructure/service → Riverpod provider** in `core/di/providers.dart`.
3. **New repository → GetIt** (`registerLazySingleton`), constructor-injected
   into the BLoC. Do not also add a Riverpod provider for it — see the known
   issue below.
4. **Never call `getIt<T>()` from inside a Riverpod provider or notifier.** It
   defeats `ProviderContainer` overrides and makes the provider untestable.
5. **Never put business logic in `AuthNotifier`.** If the router needs to know
   something new, add a derived flag, not an operation.

## Known issues in the current wiring

These are real defects in the seam, not reasons to abandon the split. See the
[code audit](../audit/2026-08-04-code-audit.md) for severity and repro details.

- **`AuthRepository` is constructed twice.** GetIt registers
  `SupabaseAuthRepository(supabaseClient: getIt<SupabaseClient>())`, and
  `authRepositoryProvider` separately constructs `SupabaseAuthRepository()`.
  Each instance opens its own broadcast `StreamController` and its own
  `onAuthStateChange` subscription. Both observe the same Supabase events so
  behaviour is correct, but the duplication is wasted work and a trap: a future
  cache or in-memory field on the repository would diverge between the two
  copies. Fix: make `authRepositoryProvider` return `getIt<AuthRepository>()`.
- **`AuthNotifier._refreshProfileExistence` calls `GetIt.instance<UserRepository>()`**
  instead of reading a provider — violates rule 4 above.
- **`goRouterProvider` creates a `ValueNotifier` that is never disposed**
  (no `ref.onDispose`).
- **`main.dart` copies session tokens into secure storage "so AuthInterceptor
  can attach Bearer token"** — nothing uses `AuthInterceptor`; see the dead
  network layer finding in the audit.

## Verdict

The three-system split is **acceptable and coherent** as long as the ownership
table and the five rules above hold. Its real cost is onboarding: a newcomer
must learn three idioms, and the docs previously claimed only one. Consolidating
onto a single system would be a large refactor with no user-visible benefit;
fixing the four seam defects above is cheap and worth doing.

## Related

- [Design Decisions](design-decisions.md) — original rationale (state
  management and HTTP client sections are outdated; see notes there)
- [Architecture Overview](overview.md)
- [Code Audit 2026-08-04](../audit/2026-08-04-code-audit.md)
