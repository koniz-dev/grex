# Issue #24 — Move the env file under an asset directory so it can be gitignored

Verification evidence. Commands run on macOS against branch
`issue-24-env-asset-directory`.

**Verdict: NEEDS-HUMAN.** Criteria 1–5 and 7–9 PASS. Criterion 6 (deploy
workflows) is marked `(human)` in the issue and cannot be driven here.

## Criteria

| # | Criterion | Result | Evidence |
|---|---|---|---|
| 1 | `.env` removed from `pubspec.yaml` assets and from the repo; `.gitignore` ignores the developer's env file again | PASS | `git rm .env`; `.gitignore` now ignores `assets/env/env` |
| 2 | Clean worktree with no developer env file: `flutter pub get && flutter build web --debug` succeeds | PASS | [clean-worktree.log](clean-worktree.log) — `✓ Built build/web` |
| 3 | `flutter test test/core/config` passes in that worktree | PASS | [clean-worktree.log](clean-worktree.log) — 18 passed |
| 4 | With a **populated** env file, `flutter test test/core/config` also passes | PASS | 18 passed, identical to the empty case |
| 5 | With a populated env file, the build succeeds and values take effect | PASS | see below |
| 6 | **(human)** Deploy workflows write to the new path | CHANGED, **NOT VERIFIED** | see below |
| 7 | `rotate-api-keys.ps1` writes to the new path, or is documented | PASS | see below |
| 8 | Docs describe the new layout; `skip-worktree` instruction removed | PASS | SETUP.md, `.env.example`, pubspec comment |
| 9 | `flutter analyze` 0, `dart format` clean, `flutter test` green, no new `skip:` | PASS | "No issues found!"; format exit 0; 1363 passed / 0 failed |

## The approach was verified before it was built

The issue said to check criterion 2 *before writing any code*, because the whole
design rests on Flutter tolerating a missing file inside a declared asset
directory. It does:

```
pubspec.yaml:  - assets/env/     # the DIRECTORY, not a file inside it
assets/env/    contains only README.md — no `env` file
flutter build web --debug  ->  ✓ Built build/web
```

A declared asset *file* that does not exist fails bundling before any Dart runs
(that was #5). A declared *directory* only has to exist; files inside are
enumerated. `assets/env/README.md` is committed to keep the directory present in
a fresh clone.

## Criterion 5 — values take effect

With `assets/env/env` populated with synthetic values:

```
LOADED FROM assets/env/env: ENVIRONMENT=staging
                            SUPABASE_URL=https://fake-project-id.supabase.co
                            API_TIMEOUT=77
flutter build web --debug -> ✓ Built build/web
git status                -> assets/env/env does not appear (ignored)
```

No real credentials were used.

## Criterion 4 is the one that mattered

This is the trap #5 fell into and #23 hit again: a test that asserts something
about a developer-editable file passes in one state and fails in the other.
`test/core/config/` was run in **both** states and gives the same result:

| State | Result |
|---|---|
| No `assets/env/env` (fresh clone) | 18 passed, 6 skipped |
| Populated `assets/env/env` | 18 passed, 6 skipped |

The group that previously asserted "the committed `.env` loads successfully" no
longer asserts existence at all — that property is now false on a fresh clone by
design. It asserts only that loading the default path never throws and that
lookups still resolve.

(The 6 skips are the `--dart-define` tests from #23, which skip without defines
and are covered by a dedicated CI step. Not introduced here.)

## The residual risk from #5 is gone

`.env` is no longer a tracked file. The developer's real settings live in
`assets/env/env`, which is gitignored, so there is no longer a tracked
secret-bearing path one `git add -A` away from publication, and no
`skip-worktree` step to forget. `git status` stays clean with a fully populated
config.

## Criterion 7 — the rotate script

`rotate-api-keys.ps1` does **not** write the app's env file: it writes
`.env.<environment>` (e.g. `.env.production`), a separate credentials dump
containing a rotated **service-role** key. So it needs no path change.

It did expose a real gap: `.env.production` matched nothing in `.gitignore` —
not `.env`, not `.env.local`, not `.env.*.local`. A rotated service-role key
sitting in an untracked-but-not-ignored file in a public repo is exactly the F4
hazard. `.gitignore` now uses `.env.*` with a `!.env.example` negation, verified
both ways:

```
.env.production  -> ignored
.env.example     -> still committable
```

## Criterion 6 — changed but NOT verified

All three deploy workflows (`deploy-web.yml`, `deploy-android.yml`,
`deploy-ios.yml`) now `mkdir -p assets/env` and write `assets/env/env` from
GitHub Secrets instead of `.env`. **None of this was executed.** These workflows
are `workflow_dispatch`-only, need real signing credentials and store
provisioning, and are not run by the `Tests` workflow, so an agent session
cannot confirm a real deploy still picks up its secrets.

If these are wrong, a deploy produces a build with no configuration — it will
compile and boot, then show the "Configuration error" screen, because a missing
env file is no longer a build failure. That is a quieter failure mode than
before and worth a human's eyes.

This is why the issue goes to `status:needs-uat`.

## A note on this session

Partway through verification the machine became unresponsive — load average
above 800 with no Dart processes running — and `flutter analyze` and the
coverage run stalled past 10 minutes each. Both were re-run to completion after
it recovered, and the numbers above are from those completed runs. Two evidence
logs were briefly empty during that window and are not committed in that state.

## Coverage

Gate passes ([coverage-gate.log](coverage-gate.log), exit 0). Baselines
untouched.

## Not covered

- **A real deploy.** Criterion 6, above.
- **F4 is still not fixed.** Everything in `assets/env/` is bundled and served
  publicly on web, exactly as `.env` was. This change moves the file; it does
  not stop the file shipping.
- **Windows developers.** The path is now `assets/env/env`; nothing was tested
  on Windows, and `rotate-api-keys.ps1` was read but not run.
