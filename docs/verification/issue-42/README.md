# Issue #42 — Clean up the lints a newer Dart SDK flags

Verification evidence. Branch `issue-42-sdk-lints`, target **Flutter 3.47.0 /
Dart 3.13.0** (current `stable`, released 2026-08-12 — which is exactly when
#41's floating pin broke CI).

## Criteria

| # | Criterion | Result | Evidence |
|---|---|---|---|
| 1 | All 36 sites resolved; `flutter analyze` 0 issues on the newer SDK; record the version | PASS | `Analyze code :: success` on 3.47.0 |
| 2 | Per-site category stated, with a test where behaviour changes | PASS | table below; `secure_session_service_test.dart` |
| 3 | No lint silenced in `analysis_options.yaml`; a file-scoped exemption argued instead | PASS | see "the one exemption" |
| 4 | `unnecessary_unawaited` and `unnecessary_ignore` removed, not suppressed | PASS | wrappers and ignore comments deleted |
| 5 | Pin bumped in workflows + pin test + CLAUDE.md | PASS | 3.41.9 → 3.47.0, 11 places |
| 6 | format clean, `flutter test` green, no new `skip:` | PASS | 1410 passed / 0 failed |
| 7 | Coverage gate passes | PASS | see final CI run |

## Verified on CI, not locally — and why

Local Flutter is 3.41.9, whose analyzer **does not have these lints at all**, so
`flutter analyze` here reports 0 either way and cannot verify anything. Every
round was therefore checked by dispatching the workflow on the branch with the
pin already bumped. Five rounds: **36 → 4 → 3 → 2 → 0**.

The first attempt did not run at all: `test.yml` triggers only on `push: main`,
`pull_request`, and `workflow_dispatch`, so pushing a branch produced no run.
Subsequent rounds used `gh workflow run --ref`.

## Criterion 2 — all 30 `unawaited_return_in_try_block` sites

Only **4 of 30** change behaviour. The rest are provably no-ops.

| Category | Count | Why |
|---|---|---|
| **(a) no-op — sibling repository call** | 8 | `return getExpenseById(...)` and friends. Each callee wraps its whole body in `try/catch` and returns `Left` on failure, so the future cannot reject. `Error`s (not `Exception`s) escape both the callee and the caller's `catch`, so awaiting changes nothing for those either. |
| **(a) no-op — synchronous `fold`** | 18 | `hasPermissionResult.fold(Left.new, (_) => const Left(...))`. Neither branch is `async`; the value is a plain `Either`, and `await` on a non-future only costs a microtask. |
| **(b) behaviour changes — `fold` with an `async` branch** | 4 | The async branch's future escaped the `try` before it could reject, so a throw inside it propagated as a raw exception, breaking the `Future<Either<Failure, T>>` contract the method advertises. Awaited, the enclosing `catch` converts it to a typed failure. |

The four category (b) sites:

- `secure_session_service.dart:118` — `validateSession`
- `optimized_session_service.dart:182`
- `optimized_session_service.dart:548`
- `supabase_social_auth_repository.dart:155`

### The test that backs category (b)

`secure_session_service_test.dart` gains a test that round-trips a real session
through `storeSession`, hands the stored JSON back on read, then makes
`_supabaseClient.auth` throw from inside the async fold branch, and asserts the
caller gets a `Left`.

**Verified to pin the change**: removing just that one `await` fails the test
with the raw exception escaping —

```
validateSession error handling a throw inside the async branch becomes a Left, not an exception [E]
  Exception: auth unavailable
```

— and restoring it returns to green. The other three category (b) sites are the
same shape in the same two files; they are not separately tested, which is
stated here rather than implied.

## The one exemption, and why it is file-scoped

`balance_page.dart` carries `// ignore_for_file: discarded_futures`.

`HapticFeedback.lightImpact` and `Navigator.pushNamed` are annotated
`@awaitNotRequired` and are called from synchronous callbacks, where there is
nothing to await into. No per-line form settles:

| Round | `HapticFeedback` | `Navigator.pushNamed` |
|---|---|---|
| 3 | ignore reported **unnecessary** | ignore **required** |
| 4 | ignore **required** | ignore reported **unnecessary** |

Wrapping in `unawaited()` trips `unnecessary_unawaited`; leaving bare trips
`discarded_futures`. Fixing one moved the diagnostic to the other and back
across consecutive runs of the same analyzer. Chasing it line by line was
thrash, so the exemption is scoped to the one file where the conflict occurs —
**not** to `analysis_options.yaml`, and not to any future carrying a result
worth handling. Criterion 3 permits this when argued; this is the argument.

I do not have a confident account of *why* the diagnostic moves. Two earlier
claims I made about the rule consulting `@awaitNotRequired` were each
contradicted by the next run, so this records the observation and stops there.

## Criterion 4

- 4 `unnecessary_unawaited`: the `unawaited(...)` wrappers are gone (two
  `Navigator.pushReplacementNamed`, one `Scrollable.ensureVisible`, one
  `HapticFeedback.lightImpact`).
- 2 `unnecessary_ignore`: the `// ignore: unreachable_from_main` comments are
  deleted from `test_helpers.dart` and
  `verification_status_property_test.dart`.

## Consequence for developers

**The repo cannot be clean on both SDKs.** 3.41.9 emits
`unreachable_from_main` where 3.47.0 calls the matching ignore unnecessary — a
direct disagreement about the same lines. After this lands, `flutter analyze` on
an older local SDK reports issues CI does not.

`CLAUDE.md`'s Toolchain section now says so, and says to upgrade rather than
"fix" them — because fixing them locally re-breaks CI, which is #41 in reverse.

## Not covered

- **The other three category (b) sites** are classified but not individually
  tested; they share the shape and the files of the one that is.
- **Deploy workflows** got the pin bump but were not executed —
  `workflow_dispatch`-only and needing real signing credentials, as in #24
  and #41.
- **Whether 3.47.0 is the right version to sit on** — it is simply current
  `stable`, not a considered choice about support windows.
