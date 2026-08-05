# Issue-Driven Workflow

GitHub issues are the single source of truth for all work in this repository.
Nothing gets implemented that is not an issue. Nothing is closed that is not
verified. This document defines the taxonomy, the lifecycle, the invariants
that keep the loop honest, and the exact `gh` commands for every transition.

The audience is both humans and autonomous Claude Code sessions. A session that
has read `CLAUDE.md` has the summary; this file is the full contract.

Repository: `koniz-dev/grex` (single repo — the Flutter app in `lib/` and the
database in `supabase/` are covered by one tracker, separated by `epic:*`).
Default branch: `main`.

---

## 1. Taxonomy

Every issue carries exactly one label from each of the first three families, and
— while open — exactly one `status:*` label.

| Family | Values | Rule |
|---|---|---|
| `type:*` | `type:bug`, `type:feature`, `type:task` | Exactly one. Stand-in for native issue types (see below). |
| `epic:*` | 11 values, see below | Exactly one. Functional area. |
| `priority:*` | `priority:P0` … `priority:P3` | Exactly one. Queue order. |
| `status:*` | `status:todo`, `status:in-progress`, `status:needs-uat`, `status:blocked` | Exactly one while open. None when closed. |

### Issue types are a repo setting, not labels

GitHub's native issue types (`Bug` / `Feature` / `Task`) are configured at the
**organisation** level and are **not available on user-owned repositories**.
Verified against this repo:

```console
$ gh api graphql -f query='{ repository(owner:"koniz-dev", name:"grex") { issueTypes(first:10) { nodes { name } } } }'
{"data":{"repository":{"issueTypes":null}}}
```

So `type:bug` / `type:feature` / `type:task` labels stand in for them. If this
repo moves to an organisation, create the native types there, migrate open
issues with `gh issue edit <N> --type <Type>`, and delete the `type:*` labels.
Until then, treat the `type:*` label as the issue type.

The stock GitHub labels `bug` and `enhancement` are **deprecated** here —
superseded by `type:bug` and `type:feature`. Do not apply them. To remove them
once you are confident nothing references them:
`gh label delete bug --yes && gh label delete enhancement --yes`.

### `type:*`

| Label | Meaning |
|---|---|
| `type:bug` | Broken relative to documented or intended behaviour. |
| `type:feature` | New user-visible capability. |
| `type:task` | Engineering work with no direct user-visible change: refactor, tooling, docs, CI, tests. |

### `epic:*`

`scripts/bootstrap-issue-labels.sh` is the **canonical source** for this list.
If an epic is not defined in that script, it does not exist. Do not invent
epics in an issue body, a doc, or an integration; add them to the script and
re-run it.

| Label | Covers |
|---|---|
| `epic:auth` | `lib/features/auth` — email/password, OAuth, sessions, profile setup |
| `epic:groups` | `lib/features/groups` — group CRUD, membership, roles, invitations |
| `epic:expenses` | `lib/features/expenses` — expense CRUD and the split calculator |
| `epic:payments` | `lib/features/payments` — payment recording between members |
| `epic:balances` | `lib/features/balances` — balance calculation and settlement plans |
| `epic:export` | `lib/features/export` — CSV and PDF export |
| `epic:core-infra` | `lib/core` — DI, config, routing, storage, logging, network, feature flags |
| `epic:database` | `supabase/` — migrations, RLS policies, database functions, seed data |
| `epic:i18n` | `lib/l10n` — ARB sources, generated localizations, RTL |
| `epic:testing` | `test/`, `integration_test/` — suites, harnesses, coverage tooling |
| `epic:release` | CI workflows, fastlane, signing material, store readiness |

### `priority:*`

| Label | Meaning |
|---|---|
| `priority:P0` | Drop everything: data loss, money computed incorrectly, build broken, security exposure. |
| `priority:P1` | Next in line: blocks a shipped user flow or another issue. |
| `priority:P2` | Normal planned work, nothing blocked. |
| `priority:P3` | Cleanup, polish, deferred. |

### `status:*`

| Label | Meaning | Assignee |
|---|---|---|
| `status:todo` | Triaged and startable: has acceptance criteria, ready to claim. | none |
| `status:in-progress` | Claimed and actively being worked. | exactly one |
| `status:needs-uat` | Implemented; acceptance criteria need a human to verify. | none (unassigned on hand-off) |
| `status:blocked` | Cannot proceed: needs a decision, credentials, or an upstream fix. | none (unassigned on block) |

---

## 2. Lifecycle

```
                      Backlog (open, no status label)
                                  │
                                  │  triage: add type/epic/priority,
                                  │  write "## Acceptance criteria"
                                  ▼
                            status:todo
                                  │
                                  │  claim: assign @me + swap label,
                                  │  then RE-READ to confirm you won the race
                                  ▼
                          status:in-progress
                                  │
                                  │  implement, lint/analyze/test,
                                  │  branch + PR with "Refs koniz-dev/grex#N",
                                  │  merge after CI green
                                  ▼
                     run the acceptance criteria against
                            the running artifact
                          ┌───────┴────────┐
                   PASS + evidence      cannot verify
                          │              (human-only step,
                          ▼               env-blocked flow)
                       closed                  │
                                               ▼
                                       status:needs-uat  ──── human verifies
                                                                │
                                                   ┌────────────┴───────────┐
                                                 PASS                     FAIL
                                                   │                        │
                                                   ▼                        ▼
                                                closed              status:todo
                                                                 (+ feedback comment)

any state ── stuck / needs a decision ──▶ status:blocked (+ comment saying
                                          exactly what is needed, unassign)
```

---

## 3. The six invariants

These are rules, not suggestions. They are what lets the loop run unattended.

### Invariant 1 — Exactly one state per open issue

Every open issue carries exactly one `status:*` label. A `status:*` label is
removed **only** as part of the same operation that closes the issue or moves it
to another state. Never strip a status label on its own.

An open issue with no `status:*` label is invisible limbo: it is not in the
queue, nobody owns it, and no human is waiting on it. This rule is the only
thing preventing that. Use `--remove-label old --add-label new` in a single
`gh issue edit` call so there is no window where both or neither is set.

Audit for violations at any time:

```bash
gh issue list --repo koniz-dev/grex --state open --json number,title,labels \
  --jq '[.[] | select([.labels[].name | select(startswith("status:"))] | length != 1)
        | {number, title, statuses: [.labels[].name | select(startswith("status:"))]}]'
```

An empty array means the invariant holds. Anything else is limbo (zero statuses)
or a contradiction (two statuses) and must be fixed before starting new work.
Newly filed, untriaged Backlog issues are the one legitimate zero-status case —
triage them rather than leaving them.

### Invariant 2 — Acceptance criteria live in the issue body

Every startable issue has a section under the exact heading
`## Acceptance criteria`. Its contents are concrete, observable steps that
someone — a person or an agent — can run against the built artifact, and a
statement of what the correct outcome looks like.

- Write observations, not intentions. "Splitting 100.00 among 7 participants
  returns shares that sum to exactly 100.00" is a criterion. "Fix the rounding
  logic" is a dev note.
- Number the steps.
- Mark any step only a human can perform with `(human)`. That mark is what
  routes the issue to `status:needs-uat` later.
- Name the command or screen. `flutter test test/foo_test.dart` beats "run the
  tests".

**No acceptance criteria means the issue is not startable.** Do not claim it;
triage it first, or move it to `status:blocked` if the criteria cannot be
written without a decision.

### Invariant 3 — Commits link, never close

Every commit and PR body that relates to an issue carries a trailer:

```
Refs koniz-dev/grex#12
```

`Fixes`, `Closes`, and `Resolves` are **banned** in commit messages, PR titles,
and PR bodies. GitHub auto-closes issues on those keywords when the commit
reaches the default branch, which destroys the verification gate — the issue
would close on push, before anyone ran the acceptance criteria. The gate is the
entire point of this workflow.

Note that the full `owner/repo#N` form is required, not bare `#N`. Bare `#N`
still links, but the explicit form survives being read outside the repo (in a
commit email, a mirror, or a log) and makes the ban easy to grep for.

### Invariant 4 — Definition of Done = closed AND evidence-backed

A session may close an issue only after it has:

1. Run every non-`(human)` acceptance criterion against the built artifact.
2. Attached retrievable evidence: files committed under
   `docs/verification/issue-<N>/` — screenshots, golden PNGs, command logs —
   plus a PASS summary comment on the issue that links to them.
3. Confirmed with its own eyes that the evidence shows the asserted behaviour.

"Tests are green", "CI passed", "the code looks right", and "deployed" are
**not** done. Evidence must be retrievable after the session ends, which means
committed files in the repo, not scrollback and not a temp directory.

### Invariant 5 — `status:needs-uat` means a human must verify this

`status:needs-uat` is reserved for acceptance criteria an agent genuinely
cannot drive. In this repo that means:

- Real-device gestures: hover, right-click, long-press, pinch, swipe.
- Anything requiring a physical Android or iOS device or a signed build.
- Flows gated on credentials a session does not hold: live Google/Apple OAuth
  consent screens, production Supabase data, App Store / Play Console.
- Judgements of visual taste, animation smoothness, or haptic feel.
- Anything requiring an email inbox (verification links, password resets).

It is **not** a "someone should test this later" dumping ground. If you skipped
verification because it was tedious, that is not `needs-uat` — finish the work.
When handing off, the comment must say exactly which criteria remain and how to
run them.

A human rejection sends the issue back to `status:todo` with a comment
explaining the failure. It does not go back to `in-progress` — it re-enters the
queue and is re-claimed, so the assignment race is always resolved the same way.

### Invariant 6 — Labels are the source of truth

Label state is authoritative. Any Project board, saved view, dashboard, or
report is a **read-only mirror** of label state, never the reverse. If a board
and the labels disagree, the labels are right and the board is stale. Never
implement automation that writes issue state from a board back into labels.

Corollary: the epic list lives in `scripts/bootstrap-issue-labels.sh` and the
labels it creates. Docs that enumerate epics — including this one — are mirrors
of that script.

---

## 4. Ship path for this repo

Feature branch plus PR, merged by the session that opened it:

1. Branch from up-to-date `main`: `issue-<N>-<slug>`.
2. Commit with a `Refs koniz-dev/grex#N` trailer.
3. Push and open a PR whose body also carries `Refs koniz-dev/grex#N` and never
   a closing keyword.
4. Wait for the `Tests` workflow (`.github/workflows/test.yml`, runs on PRs to
   `main`: `dart format --set-exit-if-changed`, `flutter analyze`,
   `flutter test --coverage`, coverage comment).
5. Squash-merge once CI is green.
6. Verify against the merged state, attach evidence, then close.

Why PRs rather than direct pushes: `test.yml` posts a per-layer coverage table
only on pull requests (the "Comment PR with coverage" step is gated on
`github.event_name == 'pull_request'`), `main` is unprotected so a session can
merge its own PR without human intervention, and a squashed PR is a single
revertible commit. Evidence is committed on the same branch, so it lands with the
change.

The `Tests` workflow takes roughly seven minutes end to end. Budget for that:
`gh pr checks --watch` blocks until it finishes, and merging before it completes
defeats the gate.

---

## 5. The per-issue agent loop

One issue at a time. Each pass through this loop touches exactly one issue, so
every change stays small and revertible.

1. **Check the invariant.** Run the Invariant 1 audit query. Fix any limbo or
   contradictory issue before starting new work.

2. **Select.** Take the highest-priority `status:todo` issue with no assignee:
   `priority:P0` first, then P1, P2, P3; within a priority, the lowest issue
   number (oldest) wins.

3. **Refill if empty.** If no `status:todo` issue exists, triage exactly one
   Backlog issue (open, no `status:*`) into `status:todo`: add `type:*`,
   `epic:*`, `priority:*`, and write the `## Acceptance criteria` section. Then
   go back to step 2. If the Backlog is also empty, stop and report an empty
   queue — do not invent work.

4. **Claim.** In one `gh issue edit` call: self-assign and swap
   `status:todo` → `status:in-progress`.

5. **Re-read to confirm the claim.** Immediately re-fetch the issue and check
   that you are the only assignee and that `status:in-progress` is set. Another
   session may have claimed it in the same second. If you did not win: remove
   yourself from the assignees, leave the labels exactly as the winner set them,
   and go back to step 2 for the next issue. Never contest a claim.

6. **Scope.** Re-read the acceptance criteria. Identify the smallest change that
   satisfies them. Note which criteria are marked `(human)` — those are already
   destined for `needs-uat`. If the criteria turn out to be unwritable,
   ambiguous, or wrong, go to step 10 (block) rather than guessing.

7. **Implement.** Make the change. Then, always:

   ```bash
   dart format .
   flutter analyze              # must be 0 issues
   flutter test                 # or a targeted subset for speed, then the full suite
   ```

8. **Ship.** Branch, commit with `Refs koniz-dev/grex#N`, push, open the PR,
   wait for CI, squash-merge. See section 4.

9. **Verify and close, or hand off.** Run every non-`(human)` acceptance
   criterion against the merged artifact. Commit evidence under
   `docs/verification/issue-<N>/`. Then either:
   - All criteria pass and none were `(human)`: comment the PASS summary with
     links to the evidence, and close.
   - Some criteria are `(human)` or could not be driven: move to
     `status:needs-uat`, unassign, and comment exactly which criteria remain,
     how to run them, and what the expected outcome is.

10. **Block, at any point.** If you are stuck or need a decision that is not
    yours: move to `status:blocked`, unassign, and comment stating exactly what
    is needed and from whom. A blocked issue with no such comment is a bug in
    the process.

11. **Stop.** One issue per pass. Report what you did, where the evidence is,
    and what state the issue landed in.

---

## 6. `gh` recipes

Every command uses the explicit `--repo` flag so it works from any directory.
Set `R=koniz-dev/grex` first if you prefer.

### Create (triaged, startable)

```bash
gh issue create --repo koniz-dev/grex \
  --title "Equal split does not conserve the expense total" \
  --label type:bug --label epic:expenses --label priority:P0 --label status:todo \
  --body-file /tmp/issue-body.md
```

The body file must contain a `## Acceptance criteria` section. Body template:

```markdown
## Context

What is wrong or missing, and where. Link the source: `lib/path/file.dart:42`,
`docs/audit/2026-08-04-code-audit.md#f1`.

## Acceptance criteria

1. Run `flutter test test/path/to_test.dart`; it passes with N tests.
2. Splitting 100.00 among 7 participants returns shares summing to exactly 100.00.
3. (human) On a physical iOS device, long-press the expense row and confirm the
   context menu appears.

## Notes

Optional. Implementation hints, fix direction, related issues. Never put
acceptance criteria here.
```

### Create (untriaged Backlog item)

Deliberately omit `status:*` — an open issue with no status label is the
Backlog. Give it a type and epic if you know them.

```bash
gh issue create --repo koniz-dev/grex \
  --title "Dio network layer is unreferenced dead code" \
  --label type:task --label epic:core-infra \
  --body "See docs/audit/2026-08-04-code-audit.md#f7 . Needs a decision: delete or keep as labelled scaffolding."
```

### Triage (Backlog to startable)

```bash
gh issue edit 12 --repo koniz-dev/grex \
  --add-label type:bug --add-label epic:expenses --add-label priority:P0 \
  --add-label status:todo
```

If the body lacks acceptance criteria, add them in the same triage pass:

```bash
gh issue view 12 --repo koniz-dev/grex --json body --jq .body > /tmp/body.md
# append a "## Acceptance criteria" section to /tmp/body.md, then:
gh issue edit 12 --repo koniz-dev/grex --body-file /tmp/body.md
```

### Find the next issue to work

```bash
# Highest-priority startable issue, unassigned, oldest first.
for p in P0 P1 P2 P3; do
  n=$(gh issue list --repo koniz-dev/grex --state open \
        --label status:todo --label "priority:$p" \
        --json number,title,assignees \
        --jq 'map(select(.assignees | length == 0)) | sort_by(.number) | .[0] // empty')
  [ -n "$n" ] && echo "$p -> $n" && break
done
```

### Claim (atomic label swap + assign)

```bash
gh issue edit 12 --repo koniz-dev/grex \
  --add-assignee @me \
  --remove-label status:todo --add-label status:in-progress
```

### Confirm the claim (race check — never skip)

```bash
gh issue view 12 --repo koniz-dev/grex --json assignees,labels \
  --jq '{assignees: [.assignees[].login], statuses: [.labels[].name | select(startswith("status:"))]}'
```

Expected: your login is the **only** assignee and `status:in-progress` is the
only status. If someone else is also assigned, you lost the race — release and
move on:

```bash
gh issue edit 12 --repo koniz-dev/grex --remove-assignee @me
```

Leave the labels alone when releasing: the winner owns them.

### Ship

```bash
git switch -c issue-12-conserve-equal-split main
# ... implement ...
dart format . && flutter analyze && flutter test

git commit -am "fix(expenses): compute equal splits in integer minor units

Refs koniz-dev/grex#12"

git push -u origin issue-12-conserve-equal-split
gh pr create --repo koniz-dev/grex --base main --fill \
  --body "$(printf 'Rewrites the equal-split path in cents.\n\nRefs koniz-dev/grex#12\n')"

gh pr checks --watch                    # wait for the Tests workflow
gh pr merge --squash --delete-branch
```

Never write `Fixes #12` / `Closes #12` / `Resolves #12` anywhere in a commit or
PR. To check yourself before pushing:

```bash
git log origin/main..HEAD --format=%B | grep -Ei '\b(fix(es|ed)?|close[sd]?|resolve[sd]?)\s+(#|[-a-z0-9]+/[-a-z0-9]+#)[0-9]+' \
  && echo "BANNED closing keyword found - amend before pushing"
```

### Close with evidence

`.gitignore` ignores `*.log` repository-wide and negates
`docs/verification/**/*.log`. Evidence logs must live under that path; anywhere
else `git add` silently drops them and the issue closes with nothing behind it.

```bash
mkdir -p docs/verification/issue-12
flutter test test/features/expenses/domain/utils/expense_calculator_test.dart \
  2>&1 | tee docs/verification/issue-12/flutter-test.log
git add -f docs/verification/issue-12   # -f is belt-and-braces; verify with:
git status --short docs/verification/issue-12
# copy any golden PNGs / screenshots into the same directory, then commit them
# on the issue branch so they land with the change.

gh issue comment 12 --repo koniz-dev/grex --body "$(cat <<'EOF'
PASS — verified against main at <sha>.

| # | Criterion | Result | Evidence |
|---|---|---|---|
| 1 | `flutter test .../expense_calculator_test.dart` passes | PASS | `docs/verification/issue-12/flutter-test.log` |
| 2 | 100.00 across 7 participants sums to exactly 100.00 | PASS | same log, case `n=7` |

Shipped in <pr-url>. Evidence committed under `docs/verification/issue-12/`.
EOF
)"

gh issue close 12 --repo koniz-dev/grex --reason completed
```

Closing removes the issue from the open set, which satisfies Invariant 1 without
a status label. Also drop the status label as part of closing so a reopened
issue does not resurrect a stale state:

```bash
gh issue edit 12 --repo koniz-dev/grex --remove-label status:in-progress
gh issue close 12 --repo koniz-dev/grex --reason completed
```

### Hand off to a human (needs-uat)

```bash
gh issue edit 12 --repo koniz-dev/grex \
  --remove-label status:in-progress --add-label status:needs-uat \
  --remove-assignee @me

gh issue comment 12 --repo koniz-dev/grex --body "$(cat <<'EOF'
Implemented in <pr-url>. Criteria 1-3 pass; evidence in `docs/verification/issue-12/`.

Needs a human for criterion 4 (marked `(human)`):

1. `flutter run -d ios` on a physical device.
2. Open any group with more than one member, long-press an expense row.
3. Expected: the context menu shows Edit / Delete / Split again.

Reason an agent cannot run it: long-press on a physical device is outside what
`flutter test` and the golden harness can drive.

If it fails, comment what you saw and move this back to `status:todo`.
EOF
)"
```

### Human verdict after UAT

```bash
# PASS
gh issue edit 12 --repo koniz-dev/grex --remove-label status:needs-uat
gh issue close 12 --repo koniz-dev/grex --reason completed

# FAIL - back into the queue with feedback
gh issue comment 12 --repo koniz-dev/grex --body "FAIL on criterion 4: the menu shows Edit only; Delete is missing on iOS 18.2."
gh issue edit 12 --repo koniz-dev/grex --remove-label status:needs-uat --add-label status:todo
```

### Block

```bash
gh issue edit 12 --repo koniz-dev/grex \
  --remove-label status:in-progress --add-label status:blocked \
  --remove-assignee @me

gh issue comment 12 --repo koniz-dev/grex --body "$(cat <<'EOF'
BLOCKED. Needed to proceed: a decision from the maintainer.

The fix direction requires choosing between (a) deleting the Dio layer and the
token-sync block in `main.dart`, or (b) keeping it as explicitly labelled
scaffolding for future non-Supabase APIs. Both are defensible; the choice
changes the docs and the public README claims, so it is not mine to make.

Unblock by commenting the choice and moving this to `status:todo`.
EOF
)"
```

### Unblock

```bash
gh issue edit 12 --repo koniz-dev/grex --remove-label status:blocked --add-label status:todo
```

### Board views (read-only mirrors, per Invariant 6)

```bash
gh issue list --repo koniz-dev/grex --state open --label status:todo
gh issue list --repo koniz-dev/grex --state open --label status:in-progress
gh issue list --repo koniz-dev/grex --state open --label status:needs-uat
gh issue list --repo koniz-dev/grex --state open --label status:blocked
gh issue list --repo koniz-dev/grex --state open --label epic:expenses --label priority:P0
```

---

## 7. Acceptance verification in this repo

The honest summary of what can and cannot be driven lives in `CLAUDE.md` under
`## Acceptance verification`, because that is the file every session reads.
Read it before writing acceptance criteria — criteria that name tooling this
repo does not have are worse than no criteria, because they look startable and
are not.

The short version: `flutter test`, `flutter analyze`, `dart format`, and golden
PNG screenshots from the widget harness are agent-drivable. There is no
scripted browser or device driver — `chromedriver` is absent, so `flutter drive`
is unavailable, and the files in `integration_test/` run in the headless
`flutter_test` harness against mock Supabase rather than on a device. Anything
that genuinely needs a real device, a real OAuth consent screen, an email inbox,
or a human gesture is `status:needs-uat` by construction.

---

## 8. Bootstrapping a fresh clone or a new repo

```bash
./scripts/bootstrap-issue-labels.sh                  # this repo
REPO=owner/other-repo ./scripts/bootstrap-issue-labels.sh
DRY_RUN=1 ./scripts/bootstrap-issue-labels.sh        # preview
```

The script is idempotent (`gh label create --force`): re-running it repairs
colours and descriptions that drifted, and adds labels introduced since the
last run. Run it after adding an epic.
