# Retrospective: Iteration 001

**Schema**: v1
**Date**: 2026-06-17

## Context

F-184 completed the full Antigravity refocus follow-up to F-183: real
`conversationId` state, per-session anchors, B3 on `PreInvocation`,
self-marker classification, F-183 regression preservation, docs parity, and
machine-local real-host `agy` evidence. Review-signoff was accepted at commit
`8abc3d39` after a Proposal 145 send-back repaired a shared-core abstraction
leak.

## Estimation Accuracy

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| T001 | 3 | 3 | 0 |
| T002 | 4 | 4 | 0 |
| T003 | 5 | 5 | 0 |
| T004 | 3 | 3 | 0 |
| T005 | 3 | 3 | 0 |
| T006 | 2 | 2 | 0 |
| T007 | 3 | 3 | 0 |
| T008 | 3 | 3 | 0 |

**Average variance**: +/- 0

The task table remains 26/26 story points because the human-approved F-184
override intentionally kept all known Antigravity completion work in one slice.
That is historical truth for this iteration, not a new default capacity. The
project-global capacity is restored to 20 at retro so the temporary override
does not leak into the next plan.

## Phase Variance

| Phase | Estimated | Actual | Delta | Notes |
| ----- | --------- | ------ | ----- | ----- |
| Planning | 3 | 3 | 0 | Option B made the 26 SP override explicit and kept the split guard falsifiable. |
| Discovery/Spikes | 3 | 3 | 0 | T001 confirmed B3-on-`PreInvocation` could stay inside the bounded host surface. |
| Implementation | 14 | 14 | 0 | Existing refocus state, dedupe, breaker, and deploy machinery were reused. |
| Review | 4 | 4 | 0 | Automated suites plus manual `agy` evidence carried the review-stage tasks. |
| Rework | 2 | 2 | 0 | The abstraction-leak send-back consumed the planned rework buffer. |

## Drift Summary

- Total drift events: 0
- Resolved via spec update: 0
- Resolved via revert: 0
- Deferred: 0
- Escalated to human decision: 0

## What Went Well

- The discovery spike did real work. It gave a falsifiable split guard for
  fresh boundary cursor, exactly-once B3, and bounded host-model change before
  runtime implementation started.
- Reusing the existing refocus machinery paid off: Antigravity now uses the same
  state, dedupe, breaker, fallback, and deploy paths rather than a private
  implementation.
- The manual `agy` run caught a real dev-tree module-path defect that the
  automated suite did not expose. That defect was fixed and regression-tested.
- The review send-back improved the design: runtime hook policy moved into
  `RefocusHookBindings.DispatcherRuntime`, and the firewall now blocks future
  shared-core `agy` or Antigravity routing literals.

## What Didn't Go Well

- The first review over-claimed host neutrality and missed the abstraction leak.
  Proposal 145 worked only after the reviewer tried to disprove the report with
  a targeted coupling scan and structural test.
- The boundary ledger lagged behind the artifacts: review-signoff had to be
  mechanically synced at retro start because implementation advanced faster
  than the session-state cursor.
- The retro scaffolder emitted ignored `.pending` duplicates and a premature
  iteration-closeout dashboard. Those were removed here; the closeout dashboard
  belongs at iteration-closeout.
- Antigravity B3 proof is still inferential because the host does not expose a
  direct "prompt received injected steps" transcript. The proof is strong enough
  for review-signoff, but release validation must keep the evidence label honest
  or add stronger confirmation if the host exposes it.

## Lessons Learned

- Host names and binary names are host-manifest data. Shared core may consume a
  host binding, but it must not encode a host's CLI name or event-routing
  exceptions.
- Capacity overrides can be correct, but only when treated as temporary
  historical truth. F-184 needed 26 SP to finish the known completion work; that
  does not change the normal 20 SP planning cap.
- Review claims about "no coupling" need a negative test, not just code reading.
  The host-coupling firewall is the durable guard for this class.
- Real-host evidence should stay labeled by evidence strength. The `agy`
  machine-local run proves hooks fired, state persisted, and B3 journaled once;
  it does not by itself become a stable release claim.

## Improvement Actions

1. Owner: Planner | Phase: next planning | Type: capacity | Expected effect: keep host-model/refocus work at 20 SP unless a human explicitly approves a bounded override or split.
2. Owner: Reviewer | Phase: next review-signoff | Type: review-method | Expected effect: add an explicit abstraction-leak scan for shared-core host names, binary names, and event-output branches.
3. Owner: Release Steward | Phase: release gate | Type: validation | Expected effect: reproduce the `agy` evidence from repo-run steps or keep the machine-local label explicit.
4. Owner: Release Steward | Phase: release gate | Type: validation | Expected effect: validate `MigrateLegacyTopLevelEventMap` legacy-upgrade behavior before stable promotion.
5. Owner: Maintainer | Phase: methodology backlog | Type: tooling | Expected effect: adjust retro scaffolding so protected reviewer artifacts do not create ignored `.pending` clutter or premature closeout dashboards.

## Reviewer Instruction Candidates

| Candidate | Disposition | Rationale |
| --- | --- | --- |
| Add shared-core host-coupling scan to Proposal 145 review-signoff. | promote | It would have caught the abstraction leak before human send-back. |
| Treat manifest-driven host policy as a design/code trace item. | promote | Runtime behavior moved to manifests; review must verify producer and consumer. |
| Require direct host transcript proof for Antigravity `injectSteps`. | defer | The host is opaque today; release can add stronger proof if available, but review must not require impossible evidence. |
| Automatically keep raised capacity after a successful override. | drop | The override was explicitly temporary; keeping it would recreate capacity drift. |

## Signals for Next Iteration

- Stable release remains blocked until beta-before-stable is honored at the
  eventual release gate.
- Release validation still owes legacy config upgrade coverage for
  `MigrateLegacyTopLevelEventMap`.
- Release validation must either reproduce the F-184 `agy` evidence from repo
  instructions or keep the machine-local label visible.
- The next host-related slice should start with a coupling/firewall scan before
  code review, not as a late send-back repair.
- Antigravity "full parity" is not fully achieved until iteration 002 lands.
  The manual dogfood found three parity gaps that iteration 002 must carry:
  persistent `AGENTS.md` instructions are not deployed on the hook-only path;
  the bootstrap lacks a prominent "drive Specrew / do not run raw
  `specify.exe workflow`" guard; and time-to-workshop is slow on Opus and
  effectively undrivable on Flash.
- Iteration 002 should confirm whether persistent host instruction deployment is
  currently `specrew start`-only, then deploy the host-manifest
  `InstructionsFile` during `specrew init` without clobbering user-owned
  `AGENTS.md` content.
- Iteration 002 should validate the anti-raw-Spec-Kit guard in real
  Antigravity host tests: Opus 4.6 should reach the workshop faster, and Gemini
  Flash should follow the governed workshop path without shelling out to
  `specify.exe workflow`; if Flash still cannot drive it, keep the weak-model
  caveat explicit.

## Calibration Suggestion

- Suggested capacity adjustment: restore project baseline 26 -> 20 now.
- Rationale: F-184 consumed the approved 26 SP override, but the reason was
  feature-specific completeness of a known Antigravity follow-up. Future
  host-model/refocus slices should either split at 20 SP or record a fresh
  human-approved override with explicit retro restoration.

## Notes

- Review-signoff accepted the abstraction-leak repair at `8abc3d39`.
- Retro restored `.specrew/iteration-config.yml` to the baseline 20 SP cap while
  leaving the iteration plan's 26/26 capacity line as historical truth.
