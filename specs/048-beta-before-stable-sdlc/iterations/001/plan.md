# Iteration Plan: 001

**Schema**: v1  
**Spec**: [../../spec.md](../../spec.md)  
**Status**: planning  
**Capacity**: 9/20 story_points  
**Started**: 2026-05-26  
**Completed**:

## Scope Summary

Iteration 001 ships the visible beta-before-stable policy surface before audit
automation begins. It updates the coordinator feature-closeout handoff so the
agent owns Steps 5-14, documents the release discipline, and adds tests that
prevent the ownership split and PASS gate from regressing.

| Requirement | Summary | Stories |
| --- | --- | --- |
| FR-001 | Add `AGENT NEXT ACTION:` row to feature-closeout handoff. | US1 |
| FR-002 | Add `HUMAN ACTION NEEDED:` row for approvals and PASS/FAIL. | US1 |
| FR-003 | Cover Steps 5-14 in order. | US1 |
| FR-004 | Document and test the Step 12 beta fail-loop. | US1 |
| FR-005 | Add `docs/release-discipline.md`. | US2 |
| FR-006 | Block stable publication until explicit human PASS. | US2 |
| FR-013 | Add focused tests for handoff/docs behavior. | US4 |
| FR-014 | Preserve mirror parity for mirrored extension files. | US4 |
| FR-015 | Update durable proposal/index metadata where applicable. | US4 |
| FR-016 | Do not treat missing credentials, workflow result, PR state, or PASS as success. | US1, US2 |

Out of iteration 001 scope: FR-007 through FR-012 release audit helper, CLI,
schema, and direct-main config behavior. Those are iteration 002.

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| T001 | Handoff ownership fixtures | FR-001,FR-002,FR-003,FR-004,FR-013 | US1 | 1 | Reviewer | tests/integration/*handoff*; tests/integration/*beta-before-stable* | done | codex | 1 | expected-fail |
| T002 | Coordinator handoff template wording | FR-001,FR-002,FR-003,FR-004,FR-014 | US1 | 2 | Spec Steward | scripts/specrew-start.ps1; extensions/specrew-speckit/prompts/*; extensions/specrew-speckit/squad-templates/coordinator/*; .specify/extensions/specrew-speckit/**/* | done | codex | 2 | pass |
| T003 | Release discipline docs fixtures | FR-005,FR-006,FR-013 | US2 | 1 | Reviewer | tests/integration/*release*; tests/integration/*beta-before-stable* | planned | codex | 0 | pending |
| T004 | Release discipline documentation | FR-005,FR-006,FR-016 | US2 | 2 | Spec Steward | docs/release-discipline.md | planned | codex | 0 | pending |
| T005 | Proposal/index metadata | FR-015 | US4 | 1 | Spec Steward | proposals/060-prerelease-channel-staging.md; proposals/131-coordinator-prompt-sdlc-ownership-clarification.md; proposals/INDEX.md | planned | codex | 0 | pending |
| T006 | Mirror parity verification | FR-014 | US4 | 1 | Reviewer | extensions/specrew-speckit/**/*; .specify/extensions/specrew-speckit/**/* | planned | codex | 0 | pending |
| T007 | Iteration 001 focused verification | FR-013,FR-014,FR-016 | US1,US2,US4 | 1 | Reviewer | tests/integration/*; .specify/extensions/specrew-speckit/scripts/validate-governance.ps1 | planned | codex | 0 | pending |

## Effort Model

| Setting | Value | Notes |
| --- | --- | --- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 20 | Maximum planned effort before overcommit guidance applies. |
| Iteration Bounding | scope | This iteration is scope-bounded to prompt/docs/tests only. |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time`. |
| Overcommit Threshold | 1.0 | Planned 9 SP is under the 20 SP threshold. |
| Defer Strategy | manual | Audit automation is intentionally deferred to iteration 002. |
| Calibration Enabled | true | Retro should compare planned 9 SP to actual effort. |

## Concurrency Rationale

- Current roster snapshot: Spec Steward, Planner, Implementer, Reviewer,
  Retro Facilitator.
- Iteration 001 has two safe lanes: tests/docs assertions and prompt/docs
  authoring. In this single-agent session they execute serially.
- Same-specialty Junior/Senior parallelism is not warranted for seven small
  tasks touching shared prompt and docs surfaces.
- Security-sensitive release/publish behavior is documented in iteration 001
  but not automated until iteration 002; Reviewer owns hardening scrutiny.

## Quality Focus

- **Security and release safety**: stable publish requires explicit human PASS;
  no missing credential/workflow/verdict may be treated as success.
- **Maintainability and testability**: prompt/docs policy is protected by
  focused assertions, not only by reviewer memory.
- **Mirror parity**: mirrored Specrew extension files remain byte-identical.
- **Drift control**: if implementation needs to change CLI/schema assumptions
  from the plan, update spec/plan/tasks before review sign-off.

## Notes

- `Overall Verdict: ready` in `quality/hardening-gate.md` applies only to
  iteration 001 prompt/docs/tests scope.
- Release audit automation remains planned for iteration 002 and must not be
  claimed as implemented during iteration 001 review.
