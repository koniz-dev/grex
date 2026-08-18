# Issue #41 — CI is red on unchanged code

Verification evidence. Commands run on macOS against branch
`issue-41-pin-flutter-version`.

## Criteria

| # | Criterion | Result | Evidence |
|---|---|---|---|
| 1 | Every workflow pins an explicit version instead of `stable` | PASS | 9 sites across 5 workflows |
| 2 | `flutter analyze` reports 0 issues in CI; re-running an older green commit stays green | PASS | [analyze.log](analyze.log); CI run on this PR |
| 3 | Per-site analysis of `unawaited_return_in_try_block` fixes | N/A — route B taken | see below |
| 4 | If too large, pin first to unblock and file the cleanup separately; say which route | PASS — **route B** | filed as #42 |
| 5 | Document how the toolchain gets upgraded deliberately | PASS | `CLAUDE.md` "Toolchain" |
| 6 | format clean, `flutter test` green, coverage gate passes | PASS | 1376 passed / 0 failed; [coverage-gate.log](coverage-gate.log) |

## The defect, proven

CI was red on code nobody had touched. Demonstrated by re-running `main`'s own
last green workflow (`919b8b6`) with **no change of any kind**:

```
run of 2026-08-12       -> success
same run, re-run today  -> failure ("Analyze code", 36 issues)
```

Every workflow set `flutter-version: 'stable'`, which floats. The Dart SDK
advanced and enabled lints this codebase trips. None of the 36 sites were in the
PR that first hit it (#40 / #34) — they are in auth, balances, expenses, groups
and payments, untouched for weeks.

It also made the failure unreproducible: `flutter analyze` on the local Flutter
3.41.9 still reports 0 issues, so the gate said one thing locally and another in
CI. That is how a gate becomes something people learn to ignore.

## Route taken: pin now, clean up separately

Criterion 4 allowed either fixing all 36 lints here or pinning first. **Route B**,
deliberately.

The bulk of the 36 are `unawaited_return_in_try_block`, where the obvious fix is
not cosmetic. Returning a Future from inside a `try` without `await` lets it
escape before it can reject, so the surrounding `catch` never sees the failure;
adding `await` makes it catch. In these repositories that `catch` converts
exceptions into `Left(...)` failures — so a blanket `await` sweep would silently
change error handling across five features.

That deserves per-site analysis and tests, which is #42. Bundling it into a
one-line CI fix, while the whole queue sat red, would have produced an
unreviewable diff under time pressure.

## What was pinned

`3.41.9` — the version the maintainer actually runs locally. Pinning to a
version nobody has would recreate the "fails only on a machine nobody owns"
problem in the other direction.

| Workflow | Sites |
|---|---|
| `ci.yml` | 3 |
| `deploy-web.yml` | 3 |
| `test.yml` | 1 |
| `deploy-android.yml` | 1 |
| `deploy-ios.yml` | 1 |

`test.yml` was the subtle one: it set only `channel: 'stable'` with **no**
`flutter-version` at all, which floats just as badly while looking pinned.

## The test that stops it drifting back

`test/infrastructure/ci_toolchain_pin_test.dart` asserts five things: no
workflow floats on a channel name, every declared version is an explicit
`x.y.z`, all workflows pin the *same* version, every `subosito/flutter-action`
step declares a version (catching the `test.yml` case), and `CLAUDE.md` names
the pinned version so the upgrade path cannot rot silently.

Verified to bite: reintroducing `flutter-version: 'stable'` in one workflow
turns three of the six tests red, and restoring it returns them to green.

## Not covered

- **The 36 lints are still there**, waiting on a newer SDK. #42.
- **The deploy workflows were edited but not executed** — they are
  `workflow_dispatch`-only and need real signing credentials. The change is a
  literal version string in the same `with:` block the other workflows use, so
  the risk is low, but it is unverified, as noted in #24 for the same reason.
- **Whether 3.41.9 is the right version to sit on.** It is what is installed
  locally today, not a considered choice about SDK support windows.
