#!/usr/bin/env bash
#
# Bootstrap the issue-tracker label taxonomy for the Grex repository.
#
# This script is the CANONICAL SOURCE for the epic list. Humans, agents, and
# any issue-filing integration must read the epic names from here. If an epic
# is not in this file, it does not exist. See docs/issue-workflow.md.
#
# Usage:
#   ./scripts/bootstrap-issue-labels.sh                    # default repo
#   REPO=owner/name ./scripts/bootstrap-issue-labels.sh     # another repo
#   DRY_RUN=1 ./scripts/bootstrap-issue-labels.sh           # print, do nothing
#
# Idempotent: uses `gh label create --force`, which creates a label or updates
# the colour/description of an existing one. Safe to re-run at any time.
#
# NOTE ON ISSUE TYPES: GitHub's native issue types (Bug / Feature / Task) are
# an ORGANISATION-level setting, not labels, and they are unavailable on
# user-owned repositories. `koniz-dev/grex` is user-owned, so this script
# creates a `type:*` label family as the stand-in. If the repo ever moves to
# an organisation, create native issue types there, migrate open issues with
# `gh issue edit <N> --type <Type>`, and delete the `type:*` labels.
#
set -euo pipefail

REPO="${REPO:-koniz-dev/grex}"
DRY_RUN="${DRY_RUN:-}"

if ! command -v gh >/dev/null 2>&1; then
  echo "error: the GitHub CLI (gh) is required but was not found on PATH" >&2
  exit 1
fi

created=0

label() {
  local name="$1" color="$2" description="$3"
  if [[ -n "$DRY_RUN" ]]; then
    printf '  would set %-24s %s  %s\n' "$name" "$color" "$description"
    return
  fi
  gh label create "$name" \
    --repo "$REPO" \
    --color "$color" \
    --description "$description" \
    --force >/dev/null
  printf '  %-24s %s\n' "$name" "$color"
  created=$((created + 1))
}

echo "Bootstrapping issue labels on ${REPO}${DRY_RUN:+ (dry run)}"

# ---------------------------------------------------------------------------
# type:* - what kind of work this is.
# Stand-in for GitHub native issue types (unavailable on user-owned repos).
# Exactly one per issue.
# ---------------------------------------------------------------------------
echo
echo "type:* (stand-in for native issue types)"
label "type:bug"     "D73A4A" "Something is broken relative to documented or intended behaviour"
label "type:feature" "A2EEEF" "New user-visible capability"
label "type:task"    "CFD3D7" "Engineering work with no direct user-visible change (refactor, tooling, docs, CI)"

# ---------------------------------------------------------------------------
# epic:* - functional area. Exactly one per issue. Mirrors lib/ plus the
# non-Dart work surfaces. One colour for the whole family: colour encodes the
# dimension, the text carries the value.
# Parallelism rule: never two implementers in the same epic at the same time.
# ---------------------------------------------------------------------------
echo
echo "epic:* (functional area - THIS LIST IS CANONICAL)"
label "epic:auth"       "1D76DB" "lib/features/auth: email/password, OAuth, sessions, profile setup"
label "epic:groups"     "1D76DB" "lib/features/groups: group CRUD, membership, roles, invitations"
label "epic:expenses"   "1D76DB" "lib/features/expenses: expense CRUD and the split calculator"
label "epic:payments"   "1D76DB" "lib/features/payments: payment recording between members"
label "epic:balances"   "1D76DB" "lib/features/balances: balance calculation and settlement plans"
label "epic:export"     "1D76DB" "lib/features/export: CSV and PDF data export"
label "epic:core-infra" "1D76DB" "lib/core: DI, config, routing, storage, logging, network, feature flags"
label "epic:database"   "1D76DB" "supabase/: migrations, RLS policies, database functions, seed data"
label "epic:i18n"       "1D76DB" "lib/l10n: ARB sources, generated localizations, RTL support"
label "epic:testing"    "1D76DB" "test/, integration_test/: test suites, harnesses, coverage tooling"
label "epic:release"    "1D76DB" "CI workflows, fastlane, signing material, store submission readiness"

# ---------------------------------------------------------------------------
# priority:* - queue order. Exactly one per issue. Heat scale.
# ---------------------------------------------------------------------------
echo
echo "priority:*"
label "priority:P0" "B60205" "Drop everything: data loss, money incorrect, build broken, security exposure"
label "priority:P1" "D93F0B" "Next in line: blocks a shipped user flow or another issue"
label "priority:P2" "FBCA04" "Normal: planned work, no active blockage"
label "priority:P3" "C2E0C6" "Nice to have: cleanup, polish, deferred"

# ---------------------------------------------------------------------------
# status:* - lifecycle state. EXACTLY ONE per OPEN issue (invariant 1).
# A status label comes off only by moving to another state or closing.
# ---------------------------------------------------------------------------
echo
echo "status:*"
label "status:todo"        "C5DEF5" "Triaged and startable: has acceptance criteria, unassigned, ready to claim"
label "status:in-progress" "0E8A16" "Claimed by an assignee and actively being worked. One per assignee"
label "status:needs-uat"   "D4C5F9" "Implemented, but acceptance criteria require a human to verify"
label "status:blocked"     "444444" "Cannot proceed: needs a decision, credentials, or an upstream fix"

echo
if [[ -n "$DRY_RUN" ]]; then
  echo "Dry run complete. No labels were changed."
else
  echo "Done: ${created} labels created or updated on ${REPO}."
  echo "Reminder: issue types are a repo/org setting, not labels - see the note at the top of this file."
fi
