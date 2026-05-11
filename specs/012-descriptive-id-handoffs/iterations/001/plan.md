# Iteration Plan: Iteration 001 — Readable-Reference Rule and Guidance Rollout

**Feature**: `012-descriptive-id-handoffs` | **Iteration**: `001` | **Date**: 2026-05-11  
**Spec Ref**: [../../spec.md](../../spec.md) | **Feature Plan Ref**: [../../plan.md](../../plan.md)

## Summary

Deliver the readable-reference rule and user-facing guidance surfaces for described numeric references in authored handoff prose. Iteration 001 rolls out the shared validator rule, updates prompts, checklists, contracts, and Squad startup guidance, and provides worked examples. Iteration 002 defers replay-path integration coverage, corpus seeding, and quality artifacts.

## Iteration Scope

| Category | Coverage | Boundary |
| --- | --- | --- |
| **User Stories** | US1 (Readable in-flight narration), US2 (Readable stop messages and handoffs) | US3 and integration evidence deferred to Iteration 002 |
| **Rollout Slice** | Descriptive-reference guidance and soft-warning rule for authored narration and stop messages | No blocking enforcement, no replay-path fixtures, no corpus seeding, no quality/ artifacts yet |
| **Tasks** | T001-T011 | T012-T020 deferred to Iteration 002 |
| **Primary Surfaces** | Validator rule, coordinator prompt guidance, decision guidance, checklist, contract/template, Squad startup guidance, worked examples | Integration tests, corpus, and hardening artifacts remain unscaffolded |

## Rollout Checklist

- [ ] **T001**: Pre-implementation baseline from existing handoff-governance tests
- [ ] **T002**: Feature boundary and two-iteration split confirmation
- [ ] **T003**: Extend validator rule for opaque numeric references (shared foundational task)
- [ ] **T004**: Update coordinator handoff contract (shared foundational task)
- [ ] **T005-T007**: Readable narration guidance (US1, runs in parallel)
- [ ] **T008**: Narration spot-check validation (US1)
- [ ] **T009-T010**: Readable stop-message guidance (US2, runs in parallel)
- [ ] **T011**: Stop-message and handoff validation (US2)

## Implementation Context

**Primary Files Modified**: `extensions/specrew-speckit/validators/handoff-governance-validator.ps1`, `extensions/specrew-speckit/prompts/coordinator-response.md`, `extensions/specrew-speckit/prompts/coordinator-decision-guidance.md`, `extensions/specrew-speckit/checklists/coordinator-handoff-governance.md`, `specs/001-specrew-product/contracts/coordinator-handoff-template.md`, `.github/agents/squad.agent.md`, `.squad/templates/squad.agent.md`

**Key Constraints**:
- Limit changes to authored narration and stop-message prose only
- Exclude verbatim/tool-rendered/code/quoted surfaces from the rule
- Keep the rule as a soft warning only
- Preserve all existing feature 007 guidance and checks
- Keep `.github/agents/squad.agent.md` and `.squad/templates/squad.agent.md` synchronized

**Regression Baseline**: Run the pre-implementation baseline once before starting implementation:
```powershell
tests/integration/handoff-governance-jargon-response-test.ps1
tests/integration/handoff-governance-plain-language-response-test.ps1
tests/integration/handoff-governance-review-file-reference-test.ps1
extensions/specrew-speckit/scripts/validate-governance.ps1 -ProjectPath .
```

**Regression Validation**: After all tasks complete, re-run the same four commands to confirm no existing guidance was lost.

## Quality Gates

| Gate | Status | Evidence |
| --- | --- | --- |
| Feature boundary locked | pending-pre-implementation | Iteration 001 tasks explicitly limited to T001-T011; Iteration 002 starts at T012 |
| Existing feature 007 compatibility | pending-pre-implementation | All four regression tests must pass before and after Iteration 001 changes |
| Prompt/checklist/contract alignment | pending-pre-implementation | All three author-facing guidance surfaces must describe the same descriptive-reference behavior |
| Squad startup guidance synchronization | pending-pre-implementation | `.github/agents/squad.agent.md` and `.squad/templates/squad.agent.md` must carry identical descriptive-reference guidance |
| Worked example coverage | pending-pre-implementation | Prompts and checklists must include acceptable and unacceptable narration/stop-message examples |

## Known Dependencies

- T003 and T004 are foundational and must complete before T005-T011 begin
- T005, T006, T007 can run in parallel (all narration guidance)
- T009, T010 can run in parallel (all stop-message guidance)
- `.github/agents/squad.agent.md` and `.squad/templates/squad.agent.md` must stay synchronized in the same commit

## Risk Tracking

| Risk | Mitigation | Status |
| --- | --- | --- |
| Validator rule detects the wrong numeric patterns | Validate rule scope against both US1 and US2 acceptance scenarios from spec.md | mitigation-planned |
| Existing feature 007 warnings are lost or changed | Regression commands serve as the primary baseline | mitigation-planned |
| Agent startup guidance drifts between `.github/` and `.squad/` versions | Synchronization enforced in the same task and verified in T008 | mitigation-planned |
| Worked examples don't match the actual rule behavior | Examples must be validated via spot-check against the real validator before closeout | mitigation-planned |

## Phase Dependencies

This iteration depends on:
- Planning artifacts from feature 012 being finalized (spec.md, plan.md, research.md, data-model.md, quickstart.md, contracts/descriptive-reference-handoff.md)
- Pre-implementation baseline from the existing three handoff-governance tests being recorded
- Fresh authorization from the Spec Steward for Iteration 001 hardening-gate sign-off and implementation start

## Success Criteria

Iteration 001 is considered complete when:

1. T001-T011 all pass independently
2. The four regression commands pass with no regressions from the baseline
3. Numeric references in narration and stop messages are understandable on first read
4. Grouped lists use shared scope only when the grouping is unmistakable
5. Excluded verbatim surfaces are not being flagged
6. Existing feature 007 handoff expectations still read naturally
7. The rule is still described as non-blocking everywhere it appears
8. `.github/agents/squad.agent.md` and `.squad/templates/squad.agent.md` carry the same descriptive-reference guidance

## Explicit Deferrals

- Replay-path integration tests remain deferred to Iteration 002
- Corpus seeding remains deferred to Iteration 002
- Quality/ artifacts (hardening-gate.md, trap-reapplication.md) remain deferred to Iteration 002
- Any blocking enforcement remains out of scope
- Any expansion to tool-rendered output remains out of scope
