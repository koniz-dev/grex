# Issue #5 — A fresh clone cannot build: `.env` is gitignored but a required asset

Verification evidence for committing `.env` as an empty placeholder.
Commands run on macOS against branch `issue-5-env-placeholder-asset`.

## Criteria

| # | Criterion | Result | Evidence |
|---|---|---|---|
| 1 | Clean worktree, no `.env` of the developer's involved: `flutter pub get && flutter build web --debug` succeeds, no "No file or variants found for asset: .env" | PASS | [clean-worktree-build.log](clean-worktree-build.log) |
| 2 | In that clean worktree, `flutter test test/core/config` passes | PASS | [clean-worktree-config-tests.log](clean-worktree-config-tests.log) |
| 3 | With a real `.env` present, `flutter build web --debug` still succeeds and its values take effect; the fallback does not shadow a real file | PASS | [populated-env-build.log](populated-env-build.log) |
| 4 | The `pubspec.yaml` comment about `.env` being optional is true or corrected | PASS | Corrected — see below |
| 5 | `flutter analyze` 0 issues; `dart format --set-exit-if-changed .` passes | PASS | [analyze.log](analyze.log); format exit 0 |
| 6 | `SETUP.md` and `.env.example` agree with the new behaviour, no step left to guess | PASS | Both rewritten |

## The bug, reproduced and then fixed

Removing `.env` from the clean worktree reproduces the issue's exact error
([repro-without-env.log](repro-without-env.log)):

```
Error detected in pubspec.yaml:
No file or variants found for asset: .env.
Target web_release_bundle failed: Exception: Failed to bundle asset files.
```

With the committed placeholder restored, the same build succeeds
(`✓ Built build/web`). The failure is purely asset bundling, before Dart runs,
which is why `_ConfigErrorApp` could never appear for this case.

## Why option 1 and not option 2

The issue offered two directions and asked for a justification. Option 2 —
"drop `.env` from the asset list and make `--dart-define` the documented path" —
is **not available**, because `--dart-define` does not currently work at all.

`EnvConfig` resolves defines with `String.fromEnvironment(key)` where `key` is a
runtime variable. Environment declarations are compile-time only: a non-const
invocation always returns the default. Probed directly under
`--dart-define=PROBE_KEY=hello_from_define`:

```
const  String.fromEnvironment("PROBE_KEY") = "hello_from_define"
       String.fromEnvironment(runtimeKey)  = ""
       EnvConfig.get("PROBE_KEY")          = ""
       EnvConfig.has("PROBE_KEY")          = false
```

So every `--dart-define` passed to this app is silently ignored, and `.env` is
the only configuration path that works. Documenting `--dart-define` as *the*
path would have documented a no-op. Filed separately rather than fixed here.

## Why the placeholder is comments-only

It contains no `KEY=` lines at all. dotenv's typed getters treat a present-but-
empty value as a real value (`getBool` returns false, `getInt` parses `''`), so
`ENABLE_LOGGING=` in the placeholder would override the environment-aware
defaults in `AppConfig`. With no keys, the file is inert: the clean-worktree run
of criterion 2 exercises exactly that state.

## A defect criterion 3 caught in the new tests

The first version of `env_config_test.dart` asserted the *contents* of `.env`
(`getAll()` is empty, `has('SUPABASE_ANON_KEY')` is false). Those passed on a
fresh clone and **failed the moment a populated `.env` was present** — i.e. on
every configured developer machine:

```
EnvConfig with the committed .env placeholder carries no keys, so it cannot shadow anything [E]
EnvConfig with the committed .env placeholder every lookup still falls through to its default [E]
```

`.env` is developer-editable, so no assertion may depend on what is in it. The
group now asserts only what holds in both states — that the asset exists and
loads. The empty-value shadowing property is still pinned, but against
`.env.example`, which is committed and stable and does contain empty-valued
keys (`BASE_URL=`).

Both states were then re-run and both pass:

| State | `flutter test test/core/config` |
|---|---|
| Empty placeholder `.env` (fresh clone) | 13 passed |
| Populated `.env` (synthetic values) | 13 passed |

No real credentials were used: the populated run used
`https://fake-project-id.supabase.co` and a dummy anon key.

## Full suite

`flutter test`: **1335 passed, 572 skipped, 0 failed** ([full-suite.log](full-suite.log)).
`flutter analyze`: **No issues found!** `dart format --set-exit-if-changed .`: exit 0.

Note the full suite was run with the placeholder `.env` in place — i.e. with no
real configuration — which is the state CI now sees.

## CI

`cp .env.example .env` is removed from `ci.yml` (3 occurrences) and `test.yml`
(1). That step is what hid this bug: CI manufactured the missing file before
every build, so it never built what a contributor actually clones. The deploy
workflows still write a real `.env` from GitHub Secrets and are untouched.

## Residual risk, stated plainly

`.env` is now a **tracked** file. A developer who fills in real Supabase keys
has them in a tracked file in a public repository, one `git add -A` away from
publication. SETUP.md makes `git update-index --skip-worktree .env` a required
step immediately after filling values, which defuses it, but the step can be
skipped.

The durable fix is to move the env file under a committed asset *directory*
(e.g. `assets/env/`), where a missing individual file is not a build error and
the real file can stay gitignored. That was not taken here because it changes
the config path for every local run and all three deploy workflows, which is
well beyond this issue. Filed separately.

## Not covered here

- **F4 (service-role key bundling).** Out of scope per the issue; the existing
  warnings in `.env`, `.env.example` and SETUP.md are preserved.
- **`flutter run` on a real device.** Only the web build target was driven.
