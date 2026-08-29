# Iteration Plan: 002

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: planning
**Capacity**: 18.5/20 story_points
**Started**: 2026-08-29
**Completed**:

<!--
  Validator schema (canonical, enforced by validate-governance.ps1):
  - Iteration Status MUST be one of:
      planning | executing | reviewing | retro | complete | abandoned
    (Common mistakes the validator REJECTS: `approved`, `in-progress`, `done`, `ready`.)
  - Capacity format MUST be `<consumed>/<cap> <effort_unit>` with NO trailing prose on that line.
    Append explanatory notes in the Notes section at the bottom instead.
  - Task Status (in the Tasks table) MUST be one of:
      planned | in-progress | done | needs-rework | deferred | blocked
    (Note `in-progress` uses a hyphen, not an underscore. `done` not `completed`.)
-->

## Scope Summary

| Requirement | Summary | Stories |
| ----------- | ------- | ------- |
| FR-024 | A crossing is not minted until the stage it leaves has its owed artifacts (live filesystem, every minting mechanism); no packet renders verdict options or the marker for an empty stage; one withhold discipline in every copy | US8 |
| FR-025 | `pushed-head` is the delivery check at closeouts (release model + enforcement mode); `verdict-commit-durable` is the durability check at every boundary; each named, each with its own message | US8 |
| FR-026 | Both constrained YAML readers report zero recognized constructs as unparseable; the message names the representation, keeps the answers, names the re-write | US8 |
| FR-027 | One governed lens-checkpoint writer (`confirm-workshop-lens`) closes a lens from its receipt, runs the existing validators, writes `moved_on`; `confirm-lens` in the transition table | US8 |
| FR-028 | The acknowledgment line at an open lens; the repair refusal through the refusal contract; no recognizer changes | US8 |
| FR-029 | Feature creation writes a not-yet-authored `spec.md` stub; the specify gate refuses while it stands | US8 |
| FR-030 | The crossing writer writes every enumerated mirror of `last_authorized_boundary`; the sync re-mirrors; the truth gate compares each; a mirror ahead of the store is refused | US8 |
| FR-031 | The closeout seal is the sync's last write; a test proves it hashes the rendered dashboard | US8 |
| FR-032 | A pending crossing is owed by the session that recorded it; the Stop-hook demand fires only there; other sessions get one informational line | US8 |
| FR-033 | Method: mutation per fix asserting observable state; refusal standard on every touched message; mirrors byte-identical per commit; review and rework tracked separately; one covering round over the delta since `1b50ae60` | US8 |
| FR-010 | (existing) A verdict-shaped turn the capture does not record produces one line naming what was received and what would capture; the leading-quote-bar fixture | US3 |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T001 | Mint gate: from-stage owed artifacts on disk at all three minting mechanisms; the verdict marker carries the crossing identity; ladder-replay and stale-marker fixtures | FR-024 | US8 | 3.0 | Implementer | extensions/specrew-speckit/scripts/shared-governance.ps1, .specify/extensions/specrew-speckit/scripts/shared-governance.ps1, scripts/internal/bootstrap/HandoverStore.ps1, tests/unit/**, tests/integration/** | planned | | | |
| T002 | Withhold discipline: packet re-mint guard; gate-stop skill (3 copies), Rule 53, refocus/general.md (2), lifecycle-discipline.md; owned test flips | FR-024 | US8 | 2.0 | Implementer | scripts/internal/bootstrap/HandoverStore.ps1, .claude/skills/specrew-gate-stop/SKILL.md, extensions/specrew-speckit/squad-templates/skills/gate-stop.md, .specify/extensions/specrew-speckit/squad-templates/skills/gate-stop.md, scripts/internal/launch-contract.ps1, extensions/specrew-speckit/refocus/general.md, .specify/extensions/specrew-speckit/refocus/general.md, docs/methodology/lifecycle-discipline.md, tests/integration/** | planned | | | |
| T003 | Split `pushed-head`: delivery at closeouts reading enforcement_mode; new `verdict-commit-durable`; messages; the field case and this repository as fixtures | FR-025 | US8 | 1.5 | Implementer | scripts/internal/gate-preflight.ps1, tests/unit/gate-preflight.Tests.ps1 | planned | | | |
| T004 | Zero-construct detection in both constrained readers; representation-naming parse message; JSON fixtures | FR-026 | US8 | 1.0 | Implementer | scripts/internal/product-domain-lens.ps1, scripts/internal/code-implementation-lens.ps1, tests/unit/product-domain-lens.tests.ps1, tests/unit/code-implementation-lens.tests.ps1 | planned | | | |
| T005 | `confirm-workshop-lens` writer; `confirm-lens` operation (56 pinned cells); validators wired at the checkpoint; skill step 7 invokes it | FR-027 | US8 | 3.0 | Implementer | extensions/specrew-speckit/scripts/confirm-workshop-lens.ps1, .specify/extensions/specrew-speckit/scripts/confirm-workshop-lens.ps1, extensions/specrew-speckit/scripts/workshop-authority-store.ps1, .specify/extensions/specrew-speckit/scripts/workshop-authority-store.ps1, .claude/skills/specrew-design-workshop/SKILL.md, tests/integration/workshop-*.tests.ps1 | planned | | | |
| T006 | Acknowledgment line in the skill and lens texts; repair refusal through the refusal contract; text-presence and AST tests | FR-028 | US8 | 0.75 | Implementer | .claude/skills/specrew-design-workshop/SKILL.md, extensions/specrew-speckit/knowledge/design-lenses/*.md, extensions/specrew-speckit/scripts/repair-workshop-controller-state.ps1, .specify/extensions/specrew-speckit/scripts/repair-workshop-controller-state.ps1, tests/unit/workshop-refusal-contract.tests.ps1 | planned | | | |
| T007 | Not-yet-authored `spec.md` stub at feature creation; specify-gate sentinel refusal | FR-029 | US8 | 1.0 | Implementer | extensions/specrew-speckit/scripts/create-governed-feature.ps1, .specify/extensions/specrew-speckit/scripts/create-governed-feature.ps1, scripts/internal/design-analysis-gate.ps1, tests/integration/governed-feature-*.tests.ps1 | planned | | | |
| T008 | Crossing-mirror writer for every enumerated mirror; sync re-mirror; truth gate over each; DRIFT-199-I001-152 reproduced then green | FR-030 | US8 | 2.0 | Implementer | extensions/specrew-speckit/scripts/shared-governance.ps1, .specify/extensions/specrew-speckit/scripts/shared-governance.ps1, scripts/internal/sync-boundary-state.ps1, scripts/internal/task-progress.ps1, tests/unit/**, tests/integration/** | planned | | | |
| T009 | Seal as the closeout sync's last write; test that it hashes the rendered dashboard | FR-031 | US8 | 0.5 | Implementer | scripts/internal/sync-boundary-state.ps1, tests/integration/** | planned | | | |
| T010 | Crossing owner recorded at mint; owner-scoped Stop-hook demand; informational line for other sessions; owner-unknown named out loud; capture verifies the marker's crossing identity | FR-032 | US8 | 2.5 | Implementer | extensions/specrew-speckit/scripts/shared-governance.ps1, .specify/extensions/specrew-speckit/scripts/shared-governance.ps1, extensions/specrew-speckit/scripts/specrew-conformance-provider.ps1, .specify/extensions/specrew-speckit/scripts/specrew-conformance-provider.ps1, scripts/internal/bootstrap/HandoverStore.ps1, tests/integration/conformance-*.tests.ps1 | planned | | | |
| T011 | Capture disclosure: one line naming what was received and what would capture; leading-quote-bar fixture | FR-010 | US3 | 0.75 | Implementer | scripts/internal/bootstrap/HandoverStore.ps1, scripts/internal/bootstrap/ConversationCaptureAccessor.ps1, tests/integration/verdict-capture-blocks.tests.ps1 | planned | | | |
| T012 | Method sweep: mirror byte-identity, mutation audit per fix, refusal-standard pass over every touched message, release-notes draft | FR-033 | US8 | 0.5 | Spec Steward | docs/release-notes-v0.40.0-beta3.md, specs/199-beta3-stabilization/** | planned | | | |

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 20 | Maximum planned effort before overcommit guidance applies. |
| Iteration Bounding | scope | `scope` keeps requirements fixed; `time` enforces a time ceiling. |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time`. |
| Overcommit Threshold | 1.0 | Warn planners when total estimated effort exceeds 20 story_points (capacity 20 x threshold 1.0). |
| Defer Strategy | manual | How planning should choose deferrals when the iteration is over capacity. |
| Calibration Enabled | true | When true, retrospectives should suggest future capacity adjustments. |

## Concurrency Rationale

- Current roster snapshot: Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator
- Technology and scope signals: PowerShell engine work across two mirrored script trees and three
  skill copies; every task touches at least one mirrored path.
- Task dependency graph: T001 and T002 share `HandoverStore.ps1` and `shared-governance.ps1` with
  T008 and T010 (the crossing family) - serial, in the order T001, T008, T010, T002. T005 and T006
  share the design-workshop skill - serial. T003, T004, T007, T009 and T011 are independent of the
  crossing family and of each other.
- Workstream separability: two workstreams are separable - the crossing family (T001, T008, T010,
  T002, T011) and the workshop family (T005, T006, T004, T007); T003 and T009 sit in either.
- Shared-surface conflict risk: elevated on `shared-governance.ps1` (four tasks) and
  `HandoverStore.ps1` (four tasks); keep those tasks serial and re-stamp mirrors per commit.
- Prior reviewer ownership/hotspot evidence: Latest reviewer hotspots: .specify/extensions/specrew-speckit/.specrew-extension-runtime.json (659 changed lines); .specify/extensions/specrew-speckit/scripts/confirm-workshop-agenda.ps1 (257 changed lines); .specify/extensions/specrew-speckit/scripts/repair-workshop-controller-state.ps1 (286 changed lines); .specify/extensions/specrew-speckit/scripts/shared-governance.ps1 (1510 changed lines); .specify/extensions/specrew-speckit/scripts/specrew-conformance-provider.ps1 (727 changed lines); .specify/extensions/specrew-speckit/scripts/validate-governance.ps1 (625 changed lines); .specify/extensions/specrew-speckit/scripts/workshop-authority-store.ps1 (533 changed lines); .specrew/release-gate-suites.txt (354 changed lines); extensions/specrew-speckit/scripts/confirm-workshop-agenda.ps1 (257 changed lines); extensions/specrew-speckit/scripts/repair-workshop-controller-state.ps1 (286 changed lines); extensions/specrew-speckit/scripts/shared-governance.ps1 (1510 changed lines); extensions/specrew-speckit/scripts/specrew-conformance-provider.ps1 (727 changed lines); extensions/specrew-speckit/scripts/validate-governance.ps1 (625 changed lines); extensions/specrew-speckit/scripts/workshop-authority-store.ps1 (533 changed lines); scripts/internal/bootstrap/ConversationCaptureAccessor.ps1 (278 changed lines); scripts/internal/bootstrap/HumanAuthorityStore.ps1 (1825 changed lines); scripts/internal/continuous-co-review/.specrew-runtime.json (252 changed lines); scripts/internal/continuous-co-review/continuous-co-review-navigator.ps1 (472 changed lines); scripts/internal/continuous-co-review/review-authority-core.ps1 (501 changed lines); scripts/internal/continuous-co-review/review-campaign-orchestrator.ps1 (971 changed lines); scripts/internal/continuous-co-review/review-signoff-evidence-gate.ps1 (685 changed lines); scripts/internal/module-packaging.ps1 (356 changed lines); scripts/internal/sync-boundary-state.ps1 (285 changed lines); scripts/specrew-review.ps1 (1089 changed lines); specs/199-beta3-stabilization/iterations/001/design-analysis.md (1113 changed lines); specs/199-beta3-stabilization/iterations/001/drift-log.md (8196 changed lines); tests/continuous-co-review/unit/advisory-names-the-humans-act.Tests.ps1 (359 changed lines); tests/continuous-co-review/unit/campaign-pause-core.Tests.ps1 (505 changed lines); tests/continuous-co-review/unit/campaign-pause-wiring.Tests.ps1 (838 changed lines); tests/continuous-co-review/unit/campaign-stop-authority.Tests.ps1 (440 changed lines); tests/continuous-co-review/unit/consumer-language.Tests.ps1 (385 changed lines); tests/continuous-co-review/unit/reparse-tag-policy.Tests.ps1 (394 changed lines); tests/continuous-co-review/unit/review-derived-independence.Tests.ps1 (417 changed lines); tests/continuous-co-review/unit/review-frame-and-evidence-honesty.Tests.ps1 (569 changed lines); tests/continuous-co-review/unit/review-spend-allowance.Tests.ps1 (313 changed lines); tests/integration/no-code-without-approval.tests.ps1 (257 changed lines); tests/integration/review-record-survives-its-own-commit.tests.ps1 (307 changed lines); tests/integration/workshop-agenda-confirmation.tests.ps1 (313 changed lines); tests/unit/round-approval-typed-authority.tests.ps1 (2578 changed lines)
- Recommendation: one Implementer, serial within each family; no same-specialty expansion.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | 1.5 | Spec amendment, design-analysis, this plan (spent 2026-08-29) |
| Discovery/Spikes | 0.5 | Rebind-versus-re-mint and owner-identity reads, done at source before the design |
| Implementation | 18.5 | Sum of T001-T012 |
| Review | 3.0 | Direct estimate (one covering round over ~40 paths); parity-floor CHECK 9.25 beside it; tripwire at 6.0 |
| Rework | 2.5 | Direct estimate (~2.3 wedges per round at 001's rate); parity-floor CHECK 9.25 beside it; tripwire at 5.0 |

## Traceability Summary

- Requirement scope: FR-024, FR-025, FR-026, FR-027, FR-028, FR-029, FR-030, FR-031, FR-032,
  FR-033, plus the existing FR-010 (its capture-disclosure defect, DRIFT-199-I002-004).
- User stories represented: US8 (the two field walks), US3 (the maintainer's verdicts always
  capture).
- Success criteria: SC-011 (T001, T002), SC-012 (T003), SC-013 (T004, T005), SC-014 (T005, T006),
  SC-015 (T007), SC-016 (T008), SC-017 (T009), SC-018 (T012 and the covering round), SC-019
  (T010), SC-020 (T011).
- Both-directions traceability is recorded in tasks.md at the tasks boundary.

## Notes

- Execution order: the crossing family first, since it is where authority is forged - T001
  (mint gate), T008 (mirrors), T010 (owner), T002 (withhold discipline and its test flips), T011
  (capture disclosure); then T003 and T009 (gate-preflight and the seal, both one-file changes);
  then the workshop family - T004, T005, T006, T007; T012 last, as the sweep over everything.
- Planned task effort: 18.5 SP of the 20 SP capacity (threshold 20 x 1.0 not exceeded); T001 and
  T010 grew by 0.5 SP each when the marker-identity binding was folded in by ruling.
- Review and rework, per the maintainer's ruling at the design decision (2026-08-29): the DIRECT
  estimate is what is planned - 3.0 SP review (one covering round over roughly 40 source paths: the
  14-file delta since `1b50ae60` plus this batch's two mirrored script trees, three skill copies
  and their tests) and 2.5 SP rework (one round at 001's measured rate of ~2.3 repair wedges per
  round). The parity floor - review plus rework equal to implementation, 18.5 SP, or 9.25 each - is
  named beside it as a CHECK, not planned as a number: planning the floor converts a check into a
  number and manufactures the overcommit. The direct estimate is 0.30 of implementation; 001's plan
  carried 0.27 and spent roughly eight times its implementation calendar, which is why the check
  stands. TRIPWIRE: if review or rework actuals exceed the direct estimate by 2x (review past 6.0
  SP, rework past 5.0 SP), execution stops and the plan is re-planned rather than ground through.
  Review and rework actuals are recorded separately, per round and per wedge as they happen
  (drift log and review record), never batch-stamped at landing, so the next retro can say which
  figure was right - the thing 001 could not do.
- One iteration, not a split (maintainer ruling 2026-08-29), conditional on the campaign
  allowance. Measured 2026-08-29 through `Get-SpecrewReviewCoverageState`: the allowance is per
  campaign; iteration 001's campaign (`cmp-199-beta3-stabilization-i001`) has used 3 of 4 rounds,
  which is the "1 of 4 remaining" the packets showed, and 001 is closed. Iteration 002's covering
  round runs under its own campaign with the per-campaign allowance (4 rounds), so one iteration
  with one covering round is supported with three rounds of headroom for tripwire-driven rework;
  a split would have needed two campaigns, also within allowance - the ruling stands on its own
  merits, not on scarcity.
- Owned test flips (planned, not discovered): `fr068-verdict-demand-reproduction` HALF 2 inverts
  by its own design; `gate-stop-skill.tests.ps1:65` and `multi-host-launch-path.tests.ps1:326`
  update to the conditional discipline; the workshop transition table grows from 48 to 56 pinned
  cells.
- Mirror discipline: every task's commit lands every byte-identical copy it touches
  (`extensions/` and `.specify/extensions/`; three skill copies); the deployed-extension-integrity
  suite is the check.
- Wave B (data-model.md, quickstart.md, contracts/, review-diagrams.md) is reconciled to the new
  writers and checks before the tasks boundary: the `confirm-workshop-lens` contract, the
  `verdict-commit-durable` check, `pending_crossing.owner`, the seal ordering.
- Authored into the `scaffold-iteration-plan.ps1` scaffold (its section shape, effort model and
  reviewer-hotspot evidence are the scaffold's). A first invocation from a POSIX shell passed the
  ten requirement ids as one comma-joined string and the scaffold failed on `.Count`; invoked with
  a PowerShell array it ran cleanly. Friction observation for the record, not a defect in scope.
