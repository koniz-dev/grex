# Issue #46 — `dart format .` reports a false failure on any machine that has built

Verification evidence. Branch `issue-46-format-scope`, Flutter 3.47.0.

## Criteria

| # | Criterion | Result | Evidence |
|---|---|---|---|
| 1 | The documented command does not walk build output; say which approach and why | PASS — scoped | see below |
| 2 | With a populated `build/`, the command exits 0 when the repo is clean and 1 on a real misformat — demonstrate both | PASS | [before-after.log](before-after.log) |
| 3 | `CLAUDE.md` and the workflows use the same command, so local and CI cannot diverge again | PASS | plus a test that enforces it |
| 4 | analyze 0, suite green with no new `skip:`, coverage gate | PASS | 1415 passed / 0 failed; gate exit 0 |

## The problem was worse than the issue said

The issue described a confusing minute. It is more than that: the **pre-commit
hooks run the same command**.

```sh
# scripts/linux/development/setup-git-hooks.sh
dart format --set-exit-if-changed . || {
  echo "❌ Code formatting check failed!"
  exit 1
}
```

So anyone who installed the hooks and had built **could not commit at all**,
with an error blaming their formatting while their formatting was fine.

## Criterion 2 — measured both ways

With `build/` populated (23 Dart files) and the repository itself clean:

| Command | Exit | What it wanted to rewrite |
|---|---|---|
| `dart format --set-exit-if-changed .` | **1** | 11 files, all under `build/` |
| `dart format --set-exit-if-changed lib test integration_test tool` | **0** | 512 files checked, 0 changed |

And the scoped gate still bites on a genuine problem — writing
`class Probe{int  x  =1;}` into `lib/`:

```
exit: 1
Changed lib/tmp_misformatted_probe.dart
```

The probe file was removed afterwards; the gate returns to exit 0.

## Criterion 1 — scoping, not excluding

`dart format` has no exclude flag and does not read `analysis_options.yaml`'s
`exclude:`, so the only reliable fix is to name the directories. The scope is
the four that hold tracked Dart files:

```
lib test integration_test tool
```

Derived from `git ls-files '*.dart'`, not guessed — 295 in `lib`, 197 in `test`,
15 in `integration_test`, 4 in `tool`.

## Criterion 3 — enforced, not just documented

Every invocation now names the same scope: `test.yml`, `CLAUDE.md` (both the
command list and the tooling table), and both pre-commit hook installers, plus
the two script READMEs that describe them.

`test/infrastructure/format_scope_test.dart` keeps them that way. It asserts
that no invocation formats the whole tree, that every site names the identical
scope, and — the one that matters over time — that **the scope still covers
every directory holding tracked Dart files**, so a new top-level source
directory cannot quietly escape formatting.

## Not covered

- **The Windows hook was edited but not run.** `setup-git-hooks.ps1` gets the
  same change as its shell counterpart; no Windows machine is available here.
- **`scripts/windows/utilities/reorganize-scripts.ps1`** mentions the old
  command inside generated documentation text. Left alone: it is a one-off
  reorganisation script, not part of the gate.
