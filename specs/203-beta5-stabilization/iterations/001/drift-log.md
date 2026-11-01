# Drift Log: Iteration 001

**Schema**: v2

## Summary

**Total drift events**: 9 (DRIFT-001 to DRIFT-009)
**Resolution rate**: 9 of 9 handled locally; DRIFT-001 to DRIFT-003, DRIFT-006, DRIFT-008 and DRIFT-009 carry an open product class
**Specification drift**: 0

## Events

### DRIFT-001 — the quality-profile resolver read the stack as Node plus a browser SPA (observation, recurring)

- **Observed**: 2026-10-31, plan stage, `resolve-quality-profile.ps1 -ProjectPath .`. The resolver matched the
  presets `node-rest-with-postgres` (score 90) and `react-spa-public` (score 80), declared stack surfaces "Node.js
  http-api" and "TypeScript browser-spa", and marked concurrency-correctness, resiliency and
  retry-idempotency-and-recovery not-applicable. The repository's product is a PowerShell module with host hooks.
  202's plan recorded the same misreading on 2026-10-13.
- **Requirement**: the plan's quality planning inputs (before-plan step 3); spec FR-042, FR-043 depend on the
  concurrency and retry dimensions being required.
- **Resolution**: corrected by hand in plan.md, "Quality plan (resolved profile, corrected)": stack surfaces
  replaced, and the three dimensions made required with rationale. Recorded at the maintainer's plan verdict.
- **Class closure**: OPEN — the resolver will misread the next feature in this repository too. Backlog candidate:
  the resolver should weigh the repository's own module manifest and language mix over preset keyword matches,
  and say when its reading is low-confidence.

### DRIFT-002 — the agent-context script removed an unrelated line from .github/copilot-instructions.md (observation)

- **Observed**: 2026-10-31, plan stage, `.specify/scripts/powershell/update-agent-context.ps1 -AgentType copilot`.
  The script changed the "Last updated" date and removed the `046-create-spec-branch` entry from the recent-changes
  list, leaving a stray blank line. It added no 203 technology, because the stack is unchanged.
- **Requirement**: none of 203's; a generated surface changed outside the feature's scope.
- **Resolution**: reverted with `git checkout -- .github/copilot-instructions.md` before the plan commit; the file
  is unchanged in 203's history. Recorded at the maintainer's plan verdict.
- **Class closure**: OPEN — the B4F-111 family (generated-surface churn and ordering). Backlog candidate: the
  agent-context update must not drop existing entries, and a no-new-technology run should leave the file
  untouched.

### DRIFT-003 — the before-implement packet opened with "Overall verdict: BLOCKED for implementation" (observation)

- **Observed**: 2026-11-01, the before-implement packet. The before-implement command requires the readiness
  script's first line verbatim as the report's first line. At a normal approval step, before the human's verdict,
  that line is always `Overall verdict: BLOCKED for implementation - 'before-implement' is not authorized ...`, so
  the packet opened with what reads as a failure at the exact moment nothing was wrong.
- **Requirement**: the refusal standard and the ui-ux binding `blocking-text-audience: human-plain-words`; B4F-071
  is the reason the line exists (a BLOCKED line was once summarized to PASS).
- **Resolution**: recorded at the maintainer's before-implement verdict; no change to the packet already sent.
- **Class closure**: OPEN — backlog candidate: at a pending crossing the readiness line should read as the state
  it is ("waiting for your approval to start implementing") rather than as a failure, while still never being
  summarized to PASS; or the line belongs in the crew's checks, not the human's packet.

### DRIFT-004 — the pin is selected by a record file, not by the launcher's SPECREW_MODULE_PATH (design detail)

- **Observed**: 2026-11-01, T002 implementation. The plan and DA-8 said the pin would be selected through the hook
  launcher's `-ModulePath` (`SPECREW_MODULE_PATH`).
- **Requirement**: DA-8; T002 "inert until configured" (before-implement verdict).
- **Resolution**: the pin is configured by `.specrew/runtime/live-engine.json` (machine-local, git-ignored), written
  only by `scripts/internal/live-engine-pin.ps1`. `SPECREW_MODULE_PATH` is a shared developer override that tests and
  the boundary-sync wrapper also read; giving it "configured but unusable refuses" semantics would reach beyond the
  hooks. The record file keeps T002 inert until configured and confines the refusal to the hooks.
- **Class closure**: NONE — a design detail within DA-8's intent; plan.md wording updated at the next plan touch.

### DRIFT-005 — mirror-parity tests fail on the branch between deployment points (superseded by DRIFT-007)

- **Observed**: 2026-11-01, the T002 regression sweep (103 files touching the changed providers, the dispatcher or
  shared-governance, run in a scratch checkout of `9f81fb52`). 10 failed; the same 10 at the base `fca9067e` gave 2
  pre-existing failures (`boundary-reader-conformance`, `CoordinatorFrontLoad`). Of the 8 new ones, 7 are mirror or
  deployed-copy parity checks (`ProviderMirrorParity`, `deployed-mirror-parity`, `conformance-material-turn-gate`
  parity case, `conformance-provider-seam`, `host-identity-runtime`, `session-orientation-rendered`,
  `workshop-material-packet-language`), all failing on "source and deployed `.specify` mirror differ", which the
  203 exception makes true until the deployment point. The 8th, `refocus-dispatcher` ("non-Specrew directory:
  silent no-op"), failed once under the 6-way parallel sweep and passed 3 of 3 in isolation: it is
  load-sensitive under parallel runs, not a T002 regression.
- **Pre-existing on main**: `boundary-reader-conformance` and `CoordinatorFrontLoad` also fail on main at
  `df1141a8` (checked 2026-11-01 in a scratch checkout), so they predate 203 entirely.
- **Requirement**: the 203 `provider-mirror-parity` exception (plan, "When 203's changes reach the live hooks");
  the B4F-158 class (red as the normal colour hides real failures).
- **Resolution**: resolved by the maintainer, 2026-11-01: **accept the red parity checks until each deployment
  point**, which is what the plan already says (parity is enforced at deployment points and at the pull request).
  No waiver is added to the tests: a list the tests read to excuse differences would outlive 203 and could hide a
  real mirror gap on main. Instead, **every regression sweep report in 203 lists the expected parity failures on
  one line and flags anything outside that list as new.** The expected list, until the next deployment point:
  `ProviderMirrorParity`, `deployed-mirror-parity`, `conformance-material-turn-gate` (parity case),
  `conformance-provider-seam`, `host-identity-runtime`, `session-orientation-rendered`,
  `workshop-material-packet-language`. Also reported on their own line: the two pre-existing main failures above,
  and `refocus-dispatcher` when it fails only under parallel load.
- **Superseded, 2026-11-01**: the resolution above could not stand. The pre-review verification lanes run parity
  suites, so with the mirror held back no review could start on a commit touching a deployed script (DRIFT-008).
  The maintainer ruled that the hooks run from the pin and the mirror syncs per commit again (DRIFT-007); the
  parity failures are gone and the expected-failure line in sweep reports is retired. The two pre-existing main
  failures and the load-sensitive `refocus-dispatcher` are still reported on their own line.
- **Class closure**: NONE — superseded by DRIFT-007, which removes the cause; the load-sensitive
  `refocus-dispatcher` case and the two pre-existing main failures remain backlog candidates.

### DRIFT-006 — a round approval typed while the previous turn was finishing was refused as a picker reply (observation, evidence for T003-T006)

- **Observed**: 2026-11-01, T002's review round on today's engine. The maintainer's first `approved for review
  round` was typed while the crew's previous turn was still finishing and arrived as a queued message. Nothing was
  recorded: the prompt hook reported it as a verdict for the `review` boundary with no crossing pending (the
  `approved for review...` prefix residue, B4F-116/150), and `specrew review --live --approve-round` then refused it
  as "arriving from a question UI or picker" (the B4F-117 class), although it was a typed chat message. The same
  phrase, typed once the crew was idle, was captured at prompt time (`hook-captured-user-prompt`, UserPromptSubmit,
  observed 00:05:18Z) within 2 seconds, and the round launched on it.
- **Correction of the crew's diagnosis**: the crew first suggested that capture on Claude is written only at turn end
  and that launching in the same turn caused the miss. That was wrong: capture does not wait for turn end on Claude;
  the second approval was recorded at prompt time. The difference between the two attempts is the queued delivery of
  the first message.
- **Requirement**: spec FR-014 (one mint origin: the typed turn), FR-015 (human-authored, standalone), FR-026 (a
  not-recorded report with its own reason, never a false one), measure (a) recorded the first time typed, measure (c)
  no false "not recorded".
- **Resolution**: recorded at the maintainer's instruction; the round ran on the second, captured approval.
- **Class closure**: OPEN, evidence for T003 to T006: a queued typed message must still count as typed. The
  classifier's origin decision must not treat a queued delivery as a question-UI or picker reply, and the replay
  fixtures should include a queued-message payload on Claude.

### DRIFT-007 — T002 extended: the live hooks run entirely from the pin; the mirror syncs per commit again (scope change, maintainer ruling)

- **Observed**: 2026-11-01, after DRIFT-008. With the `.specify` mirror held back until each deployment point
  (DRIFT-005), the pre-review verification lanes, which run parity suites, could not pass on any commit that touches
  a deployed script, so the exception and the review gate could not both stand.
- **Requirement**: FR-014; the clarify instruction (the live hooks run only reviewed code); the before-implement
  verdict (T002 inert until configured, refuses visibly when configured but unusable).
- **Resolution**: the maintainer chose to extend the pin to the deployed hook scripts, with two conditions.
  - With a pin configured, the hook launcher (Claude's per-project command and the per-machine launcher Codex and
    Copilot use) runs the pin's deployed dispatcher. The dispatcher reads its catalog and providers from its own
    tree, and every hook-path code load resolves to the pin (`Resolve-SpecrewLiveEngineExtensionScript`). The
    `.specify` mirror syncs per commit; the 203 `provider-mirror-parity` exception is withdrawn.
  - Condition (a): the project root comes from the host (`CLAUDE_PROJECT_DIR`, or the payload's cwd for the
    per-machine launcher) and is passed explicitly as `-ProjectRoot`. Today's dispatcher walks up from its own
    folder, which from the pin would reach the pin's tracked `.specrew` or `%USERPROFILE%\.specrew`.
    `tests/unit/live-engine-hook-root.tests.ps1` runs Claude and launcher events through a configured pin and
    asserts nothing is written into the pin or the profile's `.specrew`. A mutation that drops the explicit root
    turns it red: the approvals, handover and journal state land in the pin's `.specrew`.
  - The same test found a leak the provider-level tests had missed: the handover provider, the conformance
    provider (three places) and `ProjectMetadataAccessor` loaded `workshop-authority-store.ps1` from the project's
    `.specify` by path, so a pinned hook still ran a worktree engine file. All now resolve through the pin.
  - Condition (b), accepted: scripts the crew runs itself (`declare-turn-end`, `sync-boundary-state`,
    `validate-governance`) keep running from this worktree's `.specify`. If one breaks mid-iteration, the crew runs
    that script from the pin.
  - Data stays project-side: the refocus digests, knowledge catalogs and the project's own runtime records are
    read from the project, not the pin.
- **T002's own exposure**: until T002's sign-off no pin exists, so syncing T002's commits puts T002's code in the
  live hooks before its review. That code is inert without a pin record; the regression sweep of the committed tree
  covers the no-pin path. The pin is created, and this worktree's hooks redeployed with the launcher hand-off, only
  after T002's sign-off.
- **Class closure**: NONE — a scope change inside DA-8's intent, recorded in plan.md ("When 203's changes reach the
  live hooks"), tasks.md T002 and the implementation rules.

### DRIFT-008 — T002's first review round failed before the reviewer was invoked (observation)

- **Observed**: 2026-11-01, run `run-20261101-000541508-7a76e4a5`: `verification-command-failed` on three lanes, so
  no round was used. (1) `iteration-003-governance-202` validated feature 202's closed iteration 003, which now
  fails on closed-iteration records: the fourth recurrence of a governance lane naming an iteration by number
  (199 to 202 each re-pointed it). (2) `every-suite-is-named-by-a-lane` failed: the new
  `live-engine-resolution.tests.ps1` was in no lane. (3) `f199-slice-suites-a` runs two parity suites that DRIFT-005
  made red.
- **Requirement**: the pre-review verification plan (`.specrew/verification-plan.json`); measure (c), no false
  "not recorded"; the refusal standard.
- **Resolution**: the governance lane now names 203 iteration 001 (`iteration-001-governance-203`); a 203 lane,
  `f203-i001-suites`, names both live-engine suites; cause (3) is removed by DRIFT-007. The capacity rule does not
  apply to an executing iteration, so the accepted 28.5/20 overcommit needed no threshold change (the maintainer
  allowed recording it as threshold 1.5; it was not needed, and `overcommit_threshold` is project-wide). The round
  approval given before T002 changed is not used; a fresh one is asked for.
- **Class closure**: OPEN — backlog candidate: the governance lane should name the active iteration rather than a
  number, so it does not go stale at every feature boundary.

### DRIFT-009 — iteration 001 had no state.md (observation)

- **Observed**: 2026-11-01, `validate-governance.ps1` on 203 iteration 001: "Missing required artifact: state.md".
  The before-implement scaffold did not write it, and the before-implement crossing did not refuse its absence.
- **Requirement**: before-implement discipline ("state.md, drift-log.md, quality artifacts exist before the first
  implement commit").
- **Resolution**: written with T002's fix commit.
- **Class closure**: OPEN — backlog candidate: the before-implement readiness check should name a missing state.md
  before the crossing, not after the first implement commit.
