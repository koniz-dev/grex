# CLAUDE.md

Guidance for Claude Code sessions working in this repository.

Grex is a Flutter expense-sharing app (Clean Architecture: `domain` / `data` /
`presentation` per feature) backed by Supabase (PostgreSQL, Auth, Realtime).
State management is BLoC for feature logic, Riverpod for infrastructure and
routing, GetIt for repositories. All data access goes through the Supabase
client directly; the Dio layer in `lib/core/network` is unreferenced scaffolding.

## Commands

```bash
flutter pub get                  # run this first after any clone or pull; a stale
                                 # .dart_tool produces phantom resolution errors
dart format .                    # CI fails on unformatted code
flutter analyze                  # must report 0 issues
flutter test                     # full suite
flutter test path/to/file_test.dart
flutter test --coverage
flutter gen-l10n                 # regenerate lib/l10n/app_localizations*.dart from ARB
flutter build web --debug        # verified working build target
flutter run -d macos             # or -d chrome; both devices are available locally
```

Known baseline as of 2026-08-05: `flutter analyze` clean, suite passes with a
large number of `skip:` markers, and the money-math defects in
`docs/audit/2026-08-04-code-audit.md` (F1-F3) are still open. Do not treat
expense splitting as correct.

## Workflow

All work is issue-driven. GitHub issues in `koniz-dev/grex` are the single
source of truth. Full contract: [docs/issue-workflow.md](docs/issue-workflow.md).

1. Labels define state: one `type:*`, one `epic:*`, one `priority:*`, and — while
   open — exactly one `status:*` (`todo`, `in-progress`, `needs-uat`, `blocked`).
   An open issue with no `status:*` label is the untriaged Backlog.
2. Never strip a `status:*` label on its own. It changes only by moving to
   another state or by closing the issue, in the same `gh issue edit` call.
3. Pick the highest-priority unassigned `status:todo` issue. If the queue is
   empty, triage exactly one Backlog issue in. Never invent work.
4. Claim by self-assigning and swapping `status:todo` → `status:in-progress`,
   then **re-read the issue** to confirm you are the only assignee. If you lost
   the race, unassign yourself and take the next issue.
5. An issue with no `## Acceptance criteria` section is not startable.
6. Ship on a branch: `issue-<N>-<slug>` → PR → wait for the `Tests` workflow →
   squash-merge. Commits and PR bodies carry `Refs koniz-dev/grex#N`.
   `Fixes` / `Closes` / `Resolves` are banned — auto-closing on push destroys
   the verification gate.
7. Close only after running the acceptance criteria and committing evidence
   under `docs/verification/issue-<N>/`. Tests green is not done.
8. Criteria only a human can run (`(human)`) go to `status:needs-uat`,
   unassigned, with a comment saying exactly what remains.
9. Stuck or needing a decision: `status:blocked`, unassigned, with a comment
   saying exactly what is needed and from whom.
10. One issue at a time, so every change stays small and revertible.

The epic list is defined in **`scripts/bootstrap-issue-labels.sh`** — that
script is the single canonical source. Do not invent an `epic:*` value anywhere
else; add it there and re-run the script.

## Acceptance verification

How to actually drive acceptance criteria in this repo, and what that tooling
cannot do. Write criteria against this list, not against tooling you wish
existed.

### What is agent-drivable

| Tool | Command | Produces |
|---|---|---|
| Unit / widget / BLoC tests | `flutter test <path>` | Deterministic pass/fail, log output |
| Static analysis | `flutter analyze` | Lint and type errors, must be 0 |
| Formatting | `dart format --set-exit-if-changed .` | Same gate as CI |
| Golden screenshots | `flutter test <path> --update-goldens` then `flutter test <path>` | Real PNG files on disk — the only automated visual evidence here |
| Build verification | `flutter build web --debug`, `flutter build macos` | Proves the target compiles |
| Coverage | `flutter test --coverage` + `scripts/linux/testing/calculate_layer_coverage.sh` | Per-layer coverage numbers |
| Real app, eyeballed | `flutter run -d macos` / `-d chrome`, then macOS `screencapture` | A screenshot of the actually-running app |

Golden screenshots are the workhorse for visual criteria. Use
`test/helpers/golden_helpers.dart`:

```dart
import '../helpers/golden_helpers.dart';

testWidgets('expense split summary renders', (tester) async {
  await loadAppFonts();                     // MANDATORY, see below
  await tester.pumpWidget(/* ... */);
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('goldens/expense_split_summary.png'),
  );
});
```

Generate with `--update-goldens`, then re-run **without** the flag to prove the
committed PNG matches. Commit the PNG. Copy it into
`docs/verification/issue-<N>/` when it is the evidence for an issue.

### What this tooling cannot verify

Be blunt about these when writing criteria; anything in this list is
`status:needs-uat` territory.

- **Text in golden PNGs without `loadAppFonts()`.** Verified firsthand: the
  default `flutter_test` font renders every glyph as a filled grey rectangle, so
  a screenshot proves layout but not a single character of copy. Any criterion
  about wording, currency formatting, or numbers shown on screen requires
  `loadAppFonts()` first. Without it, do not claim a screenshot verifies text.
- **Nothing.** A widget that throws still produces a golden PNG — of Flutter's
  red error screen. Also verified firsthand. The existence of a PNG, and even a
  passing golden test, is not evidence that the UI works. You must open it.
- **Real end-to-end flows.** `chromedriver` is not installed, so `flutter drive`
  is unavailable. The files in `integration_test/` are misleadingly named: they
  run under the headless `flutter_test` harness against a mock Supabase client,
  so they are widget-level tests, not device or browser E2E.
- **Real backend behaviour.** Repository tests mock `SupabaseClient`. RLS
  policies, database functions, and migrations in `supabase/` are not exercised
  by `flutter test` at all. Criteria about server-side behaviour need the
  Supabase CLI against a local or staging project, or a human.
- **Physical-device interaction.** Hover, right-click, long-press, pinch, swipe,
  haptics, share sheets, push notifications, deep links arriving from a cold
  start.
- **Credential-gated flows.** Live Google or Apple OAuth consent screens, email
  verification and password-reset links (no inbox access), Play Console and App
  Store Connect.
- **Visual judgement.** Animation smoothness, whether a colour looks right,
  whether spacing feels balanced. A golden PNG proves pixels are stable, not
  that they are good.
- **iOS and Android at all, locally.** Only `macos` and `chrome` devices are
  available in this environment. Any criterion naming a phone is `(human)`.

### Evidence discipline

Non-negotiable, because unattended sessions have no reviewer:

1. **Evidence is a committed file.** Write artifacts to
   `docs/verification/issue-<N>/` and commit them on the issue branch. Terminal
   scrollback, `/tmp`, and the scratchpad all vanish when the session ends. If
   the evidence cannot be retrieved by someone reading the repo next month, it
   is not evidence.
2. **Open every screenshot and confirm it shows the asserted behaviour before
   writing PASS.** Read the PNG with the Read tool and look at it. State what
   you saw in the PASS comment, referencing what is visible ("the summary row
   reads 14.29 and the total row reads 100.00"), not what should be visible. A
   PNG that shows a red error screen or box glyphs is a FAIL, however green the
   test run was.
3. **Never relay a subagent's PASS you have not inspected yourself.** A
   subagent reporting "all criteria pass" is a claim, not evidence. Open the
   artifacts it produced, re-run the commands it ran if they are cheap, and only
   then write PASS on the issue. If you cannot inspect it, the issue goes to
   `status:needs-uat`, not to closed.
4. **A PASS summary names each criterion and its result** in a table, with a
   path to the artifact for each. Partial passes are not passes: if criterion 3
   of 4 could not be driven, the issue goes to `status:needs-uat` with criteria
   1-2 marked PASS, not to closed.
5. **Log commands verbatim.** `command 2>&1 | tee docs/verification/issue-<N>/<name>.log`
   so the log contains the invocation and the full output, not a summary.

## Loop Protocol

Multi-agent role definitions live in `.claude/agents/`. A single-agent session
can ignore this section and follow the numbered loop in
[docs/issue-workflow.md](docs/issue-workflow.md#5-the-per-issue-agent-loop);
the phases below map onto the same steps.

Roles: `plan`, `implement`, `qa`, `security`, `review`, `release`.
**Reviewer roles (`qa`, `security`, `review`) file issues. They never fix.**
That rule is what keeps the tracker honest: a reviewer that quietly fixes what
it finds leaves no record and no verification gate.

### Phase order

```
plan ──▶ implement ──▶ qa ──▶ review ──┬──▶ (close, by the orchestrator)
             ▲          │        │      │
             │          │        │      └──▶ security (when the change touches
             │          │        │            auth, secrets, RLS, or storage)
             └──────────┴────────┘
              failures return to implement, never to plan

release: runs on demand only, never inside a per-issue pass
```

### Gate table

What must be true before the next phase starts. A phase that cannot meet its
gate escalates rather than proceeding.

| Phase | Entry gate | Exit gate (must all hold) |
|---|---|---|
| `plan` | An untriaged Backlog issue exists, or the `status:todo` queue is empty | Issue has one `type:*`, one `epic:*`, one `priority:*`, `status:todo`, and a `## Acceptance criteria` section whose steps name real commands or screens, with human-only steps marked `(human)` |
| `implement` | Issue is `status:todo`, unassigned, has acceptance criteria | Claim confirmed by re-read; `dart format` clean; `flutter analyze` 0 issues; `flutter test` green; PR merged with `Refs koniz-dev/grex#N` and no closing keyword |
| `qa` | Change is merged to `main` | Every non-`(human)` criterion executed against the merged state; artifacts committed under `docs/verification/issue-<N>/`; every screenshot opened and described; verdict is PASS, FAIL, or NEEDS-HUMAN with reasons per criterion |
| `security` | Diff touches `lib/features/auth`, `lib/core/storage`, `lib/core/config`, `supabase/`, `.env*`, CI secrets, or any dependency change | No new secret reachable from a bundled asset; no RLS policy weakened; no credential logged; findings filed as issues with `priority:P0`/`P1` |
| `review` | `qa` returned PASS | Change is the smallest that satisfies the criteria; matches surrounding idiom; no dead code added; findings filed as issues |
| `release` | Human asked for it; `status:in-progress` count is zero | Version bumped, CHANGELOG updated, build artifacts produced, no open `priority:P0` |

### Escalation rules

- **`qa` returns FAIL** → the issue goes back to `status:todo` with the failing
  criterion and observed behaviour in a comment, and is re-claimed by an
  `implement` agent. It does **not** go back to `plan`: the criteria were fine,
  the code was not.
- **`qa` returns NEEDS-HUMAN** → `status:needs-uat`, unassigned, with the
  remaining criteria spelled out. No further agent phases run.
- **`qa` or `implement` finds the acceptance criteria themselves wrong,
  ambiguous, or unwritable** → this is the only path back to `plan`:
  `status:blocked` with a comment naming the ambiguity, and `plan` rewrites the
  criteria and returns the issue to `status:todo`.
- **`security` or `review` finds a defect** → file a **new** issue with the
  right `epic:*` and priority. Do not reopen or extend the issue under review,
  and do not fix it in place. The only exception is a `priority:P0` security
  finding, which additionally blocks `release` until closed.
- **Two agents disagree** → the stricter verdict wins. FAIL beats PASS.
- **Anything unsafe, destructive, or requiring a credential the session does not
  hold** → `status:blocked`, and stop.

### Tiebreaker priority order

When choosing what to work on next, in order:

1. Repair any Invariant 1 violation (an open issue with zero or two `status:*`
   labels) before starting new work.
2. Any `status:blocked` issue whose blocking question has been answered in a
   comment — unblock it to `status:todo`.
3. Any `status:needs-uat` issue a human has marked FAIL — it is already back in
   `status:todo` and carries the oldest debt.
4. Highest `priority:*` (`P0` → `P3`).
5. Within a priority: `type:bug` before `type:task` before `type:feature`.
6. Within a type: lowest issue number (oldest first).

### Parallelism rules

- **Never two `implement` agents in the same `epic:*`.** Claim-by-label is the
  interlock: an epic with an open `status:in-progress` issue is closed to new
  implementers.
- `epic:core-infra` implementers run **alone**, with no other implementer
  active. `lib/core` is shared by every feature, so a concurrent change there
  invalidates other agents' test runs.
- `qa`, `security`, and `review` are read-only on source and may run
  concurrently with each other and with implementers in other epics.
- Multiple `implement` agents may run concurrently only across distinct epics
  that do not share files. Check the diff scope, not just the label.
- `plan` may run at any time; it only writes issues.
- `release` runs alone: no `status:in-progress` issue anywhere, no other agent
  active.
- Golden files are a shared resource: two agents regenerating goldens at once
  will fight. Only the implementer that owns the issue touches
  `test/**/goldens/`.
