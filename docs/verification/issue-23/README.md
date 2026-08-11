# Issue #23 — `--dart-define` is silently ignored

Verification evidence. Commands run on macOS against branch
`issue-23-dart-define`.

## Criteria

| # | Criterion | Result | Evidence |
|---|---|---|---|
| 1 | A test asserts a `--dart-define` value is returned by `EnvConfig.get`, and fails against the old implementation | PASS | [with-defines.log](with-defines.log) |
| 2 | Same for `getBool`, `getInt`, `getDouble` | PASS | `getInt reads the define`, `getBool reads the define` |
| 3 | Precedence pinned: `.env` beats a define, a define beats the default | PASS | `a file value wins over a define of the same key`; `get prefers the define over the supplied default` |
| 4 | `has` returns `true` for a key supplied only by a define | PASS | `has reports a key supplied only by --dart-define` |
| 5 | Every key documented in `.env.example` is reachable, asserted by enumeration | PASS | `cover every key documented in .env.example` |
| 6 | `flutter analyze` 0, `dart format` clean, `flutter test` green with no new `skip:` | PASS with a caveat | see below |
| 7 | `SETUP.md` and the `pubspec.yaml` comment updated — both said this did not work | PASS | both rewritten |

## The defect

`EnvConfig` resolved defines with `String.fromEnvironment(key)` where `key` was
a runtime parameter. Environment declarations are compile-time only: a non-const
invocation always returns the default, so the entire "Priority 2" chain in
`get`, `getBool`, `getInt`, `getDouble` and `has` was dead code. Every
`--dart-define` passed to this app was ignored without a word.

Probed under `--dart-define=PROBE_KEY=hello_from_define`:

```
const  String.fromEnvironment("PROBE_KEY") = "hello_from_define"
       String.fromEnvironment(runtimeKey)  = ""
       EnvConfig.get("PROBE_KEY")          = ""
       EnvConfig.has("PROBE_KEY")          = false
```

## The fix, and what it costs

A `const` table of the 21 keys documented in `.env.example`:

```dart
static const Map<String, String> _dartDefines = <String, String>{
  'ENVIRONMENT': String.fromEnvironment('ENVIRONMENT'),
  // ...
};
```

Both the call and the key are now constant, so the compiler folds them.

**This makes the supported set finite and explicit** — a real behaviour change
from the (non-functional) open-ended lookup. A define whose name is not in the
table cannot be read. Two tests keep the table and `.env.example` in step in
both directions: a documented key missing from the table fails, and a table key
missing from the docs fails.

The `!kIsWeb` guard is also gone. It was wrong: `--dart-define` reaches web
builds through a const read just as it does native ones.

## Criterion 6's caveat: the tests skip themselves without defines

A define only exists if the run was compiled with it, so these tests **cannot**
assert anything about defines in a plain `flutter test`. They skip themselves
instead, which adds 6 conditional skips to the default run:

```
flutter test test/core/config/          -> 17 passed, 6 skipped
flutter test --dart-define=... ...      -> 23 passed, 0 skipped
```

Skipping is deliberate, and the alternative is worse: a test asserting "no
define is present" would have passed against the original bug, which is exactly
how this went unnoticed. To stop the skips meaning "never runs", `test.yml`
gains a step that runs this file **with** the defines set, so CI exercises every
one of them on every push.

Being blunt: judged against criterion 6's literal "no new `skip:`", this does
add six. They are conditional, documented in the file header, and covered by a
dedicated CI step — but they are skips, and a reader scanning skip counts should
know why.

## A trap this change exposed in the #5 tests

Adding real define support broke four tests from #5, because they asserted
fallback behaviour using real keys:

```
EnvConfig with no env file present get falls back to the supplied default
  Expected: 'https://fallback.test'
    Actual: 'https://define.test'
```

They were correct before only because defines never resolved. Those assertions
now use synthetic keys that no define can supply, so they test `EnvConfig`
rather than the runner's flags.

One assertion I added initially made the same mistake in the other direction —
`getAll().keys` must not contain `SUPABASE_URL` — which failed against a
developer's populated `.env`. It moved to the define test file, where no env
file is loaded and the assertion is about defines alone. Same lesson as #5:
never assert on a developer-editable file.

## Docs

`SETUP.md` and the `pubspec.yaml` comment both stated that `--dart-define` does
not work. That was accurate when written and is now stale, so both are rewritten
— criterion 7 exists precisely to stop that being left behind. `.env.example`
gains a note that its keys are also the define keys, and that the two lists must
change together.

## Coverage

Gate passes ([coverage-gate.log](coverage-gate.log), exit 0). Baselines
untouched.

## Not covered

- **`--dart-define-from-file`.** Not wired up; only individual defines resolve.
- **A real web build reading a define.** The `!kIsWeb` guard is removed and the
  const read is platform-independent, but this was verified under
  `flutter test`, not in a browser.
- **The deploy workflows still write `.env` from secrets.** They could now pass
  defines instead, which would stop secrets touching the filesystem. That is a
  change to untestable release plumbing and was left alone; it belongs with #24.
