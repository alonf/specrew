# Iteration Plan: 001

**Schema**: v1  
**Spec**: [../../spec.md](../../spec.md)  
**Status**: planning  
**Capacity**: 10/20 story_points  
**Started**: 2026-05-11

## Summary

Iteration 001 is the foundation slice for feature `007-user-facing-progress-handoff`. It carries **Phase 1 (Governance & Prompt Foundation) + Phase 2 (Agent Guidance & Handoff Contract)** only—the durable coordinator prompt updates, agent guidance codification, and handoff validation concept that all verification steps depend on—so before-implement can review the user-facing handoff contract before soft-validator runtime integration lands.

This is a truthful 10-point slice deliberately stopped before integration-test infrastructure and soft-validator implementation. Soft validation work (including the governance-acronym detection rule, test fixtures, and post-response checking) is explicitly deferred to Iteration 002, giving reviewers a clean checkpoint to validate the handoff semantics and coordinator guidance before validation automation adds complexity.

**Primary Focus**: Squad coordinator prompt updates, agent guidance codification for three-section handoff, handoff contract in spec documentation, soft-validator concept design, and reusable handoff template artifacts  
**Target Slice**: Phase 1 + Phase 2 (`T001`-`T006`)  
**Execution Status**: awaiting implementation approval  
**Deferred Follow-On**: Soft-validator implementation, integration tests, and polish (`T007`-`T010`)

---

## Requirements Traceability

| Spec Ref | Requirement | This Iteration | Owner | Notes |
|----------|-------------|----------------|-------|-------|
| FR-001, FR-002, FR-003, FR-004 | Final Handoff Coverage and Progress Status Content | ✅ `T001`, `T002`, `T005` | Coordinator-response maintainer, Prompt maintainer | Coordinator prompt updates, handoff template, and spec guidance |
| FR-006, FR-007, FR-012 | Actionable Next Step and Flexible Wording | ✅ `T001`, `T002`, `T005` | Coordinator-response maintainer | Prompt reinforcement of next-step clarity and compact wording patterns |
| FR-008, FR-009, FR-010, FR-011 | Review, Manual Test, Verification Gap, and Blocked vs. Continue Guidance | ✅ `T001`, `T003` | Coordinator-response maintainer | Coordinator guidance codification for decision trees |
| FR-013, FR-014, FR-015 | Final Response Ownership, Durable Rollout, and Specialized Format Compatibility | ✅ `T004`, `T006` | Agent guidance maintainer, Governance checklist maintainer | Squad.agent.md codification and governance surfaces |
| FR-016 | Soft Quality Warning | ⏳ `T007` (deferred) | Governance-validator maintainer | Soft validator implementation and governance integration deferred to Iteration 002 |
| Human-Handoff Trap Detection | Three-or-more governance acronyms in lead without plain-language paraphrase | ⏳ `T007` (deferred) | Governance-validator maintainer | Detection rule codification and soft-validator integration deferred to Iteration 002 |
| User Story 1 | Receive a clear completion handoff | ✅ `T001`, `T002`, `T005` | Coordinator-response maintainer | Coordinator prompt, template, guidance |
| User Story 2 | Understand blockers and review needs | ✅ `T001`, `T003` | Coordinator-response maintainer | Coordinator prompt decision-tree guidance, blocker/approval/test/verification gap guidance |
| User Story 3 | Keep lightweight responses fluent | ✅ `T001`, `T002`, `T005` | Coordinator-response maintainer, Prompt maintainer | Compact wording pattern reinforcement, inline guidance examples |

---

## Governance Consistency Check

| Gate | Verdict | Notes |
|------|---------|-------|
| **Spec Authority** | ✅ PASS | Scope limited to Phase 1 + Phase 2 coordinator guidance and agent documentation from approved spec.md; soft validator and integration tests explicitly deferred |
| **Traceability** | ✅ PASS | Every task maps to foundational FRs (FR-001 through FR-015) and user stories (US1, US2, US3) |
| **Ownership** | ✅ PASS | Task owners align to Specrew roles in spec.md Requirement Ownership & Delivery |
| **Capacity** | ✅ PASS | 10/20 story_points; truthful slice with explicit deferrals of soft-validator and test work |
| **Execution Support** | ✅ PASS | Planning artifacts, handoff template, and coordinator guidance ready for before-implement review |

---

## Phase 1 Quality Planning

**Phase Scope**: `phase-1-foundation` — coordinator prompt, handoff contract semantics, agent guidance  
**Inferred Quality Profile**: `quality-profile.custom-composition.v1`  
**Selected preset ref or explicit custom composition**: Custom composition for Markdown documentation guidance, coordinator-response prompt structure, agent guidance codification (Squad.agent.md), and plan-time handoff contract validation.

### Risk Dimensions

| Risk Dimension | Status | Rationale |
| --- | --- | --- |
| Handoff semantics clarity | `required` | Coordinator prompt and template must be clear enough for agents to consistently produce two-field handoffs |
| Agent guidance durability | `required` | Squad.agent.md codification must survive future agent updates and session restarts |
| Soft-validator concept readiness | `required` | Concept design and constraint documentation must be complete so Iteration 002 implementation has a clear target |
| Governance-acronym rule absorption | `required` | Handoff templates and coordinator guidance must absorb the human-handoff trap detection rule so agents understand the constraint even before soft validator lands |
| Specialized-format compatibility | `required` | Coordinator guidance must explain how existing response formats (specialized lifecycle, review) preserve handoff semantics |

---

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T001 | Update coordinator prompt to reinforce the two-field handoff contract (current progress status + recommended next step) with explicit guidance for completion, blocker, and lightweight scenarios | FR-001, FR-002, FR-003, FR-004, FR-006, FR-007, FR-012, US1, US2, US3 | Foundation | 3 | Coordinator-response maintainer | `extensions/specrew-speckit/prompts/coordinator-response.md`, `extensions/specrew-speckit/prompts/coordinator-final-response-guidance.md` | planned | Implementer | — | — |
| T002 | Create handoff template artifact with three-section format examples ("What I just did" / "Why I stopped" / "What I need from you") for completion, blocked, partial, and lightweight patterns, with current-progress and next-step identification rules | FR-001, FR-005, FR-006, FR-012, US1, US3 | Foundation | 2 | Prompt maintainer | `specs/001-specrew-product/contracts/coordinator-handoff-template.md` | planned | Implementer | — | — |
| T003 | Codify coordinator decision guidance for blockers, review needs, manual testing, verification gaps, and blocked-vs-continue logic in coordinator guidance document | FR-008, FR-009, FR-010, FR-011, US2 | Foundation | 2 | Coordinator-response maintainer | `extensions/specrew-speckit/prompts/coordinator-decision-guidance.md` | planned | Implementer | — | — |
| T004 | Update .github/agents/squad.agent.md to formally codify the three-section handoff format as the standard Squad coordinator final-response structure, with note that touching this file requires session restart between iteration close and feature closeout | FR-013, FR-014, FR-015 | Foundation | 1 | Agent guidance maintainer | `.github/agents/squad.agent.md` | planned | Implementer | — | — |
| T005 | Create comprehensive handoff governance checklist surface for coordinator-response validation (soft-warning logic, not hard-blocking) with reference to governance-acronym rule and plain-language-first principle | FR-016, Human-Handoff Trap Detection | Foundation | 1 | Governance checklist maintainer | `extensions/specrew-speckit/checklists/coordinator-handoff-governance.md` | planned | Implementer | — | — |
| T006 | Document soft-validator concept, detection rule (three-or-more governance acronyms in lead of handoff section without plain-language paraphrase), and integration points for Iteration 002 implementation in soft-validator design document | FR-016, Human-Handoff Trap Detection | Foundation | 1 | Governance-validator maintainer | `extensions/specrew-speckit/design/soft-validator-handoff-governance.md` | planned | Implementer | — | — |

**Total Effort**: 10 story_points

---

## Planned Execution Order

1. **Phase 1 (Foundation Start)**: `T001` and `T002` in parallel—coordinator prompt updates and handoff template seeds
2. **Phase 2 (Decision & Agent Guidance)**: `T003` (decision guidance), then `T004` (Squad.agent.md), in series
3. **Phase 2 (Governance & Validation Design)**: `T005` and `T006` in parallel—checklist surface and soft-validator concept
4. Stop at `T006`; do not start any soft-validator implementation or integration-test work in this iteration

---

## Deferred Follow-On

| Deferred Task(s) | Target Iteration | Reason |
| ---------------- | ---------------- | ------ |
| `T007`-`T008` | 002 | Soft-validator implementation and integration test fixtures depend on coordinator guidance and handoff template from Iteration 001 |
| `T009`-`T010` | 002 | Polish, validation lane, and governance integration depend on both soft validator and tests landing |

This is a capacity and dependency split, not a descoping decision. The deferred tasks remain part of the approved feature plan and must be carried forward explicitly.

---

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 20 | Maximum planned effort before overcommit guidance applies. |
| Iteration Bounding | scope | `scope` keeps requirements fixed; `time` enforces a time ceiling. |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time`. |
| Overcommit Threshold | 1.0 | Warn planners when total estimated effort exceeds 20.0 story_points (capacity 20 x threshold 1.0). |
| Defer Strategy | manual | The Planner must make any future deferral decision explicit. |
| Calibration Enabled | true | Retrospectives should suggest future capacity adjustments when actual variance accumulates. |

---

## Concurrency Rationale

- Current roster snapshot: Coordinator-response maintainer, Prompt maintainer, Agent guidance maintainer, Governance checklist maintainer, Governance-validator maintainer
- Technology and scope signals: Coordinator prompt updates, Markdown handoff contracts and guidance documents, Squad.agent.md codification, governance checklist and validator design
- Task dependency graph: Phase 1 (`T001`, `T002` parallel) → Phase 2 Guidance start (`T003`, `T004` serial) → Phase 2 Parallel (`T005`, `T006`)
- Workstream separability: Bounded. `T001` and `T002` are independent (prompt vs. template). `T003` and `T004` build on `T001`-`T002` outputs. `T005` and `T006` can proceed in parallel (checklist vs. validator design).
- Shared-surface conflict risk: Low. `T001` (coordinator prompt) and `T003` (decision guidance) both inform coordinator behavior but don't directly conflict. `T004` (Squad.agent.md) is read by all agents but only modified once in this iteration. `T005` and `T006` work on distinct governance documents.
- Prior reviewer ownership/hotspot evidence: None; this is the first iteration for feature 007.
- Recommendation: Use the explicit parallel windows (`T001`/`T002`, then `T005`/`T006` after `T003`/`T004`). No Junior/Senior expansion needed in Iteration 001.

---

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | 2 | Iteration slicing, traceability packaging, this plan document, spec absorption of known-traps corpus |
| Discovery/Spikes | 0 | No separate spike authorized; spec and known-traps corpus provide sufficient clarity |
| Implementation | 10 | All six tasks (`T001`-`T006`) covering coordinator prompt, templates, guidance, agent codification, and soft-validator design |
| Review | 1 | Review handoff contract semantics, coordinator guidance clarity, and soft-validator concept completeness |
| Rework | 0 | Small buffer reserved if review finds guidance gaps or clarity issues |

---

## Implementation Approval

- **Approval Verdict**: pending
- **Approved By**: —
- **Recorded Evidence**: —
- **Recorded At**: —
- **Scope Approved for Execution**: —
- **Gate Effect**: —

---

## Pre-Implementation Hardening Gate

### Hardening Gate: Iteration 001

**Schema**: v1  
**Gate ID**: `pre-implementation-hardening`  
**Feature Ref**: `specs/007-user-facing-progress-handoff/spec.md`  
**Iteration Ref**: `specs/007-user-facing-progress-handoff/iterations/001`  
**Requested Review Class**: `strongest-available`  
**Effective Review Class**: strongest-available  
**Overall Verdict**: ready  
**Approval Ref**: —  
**Reviewed By**: Alon Fliess  
**Reviewed At**: 2026-05-11  
**Post-Implementation Verification**: ⏳ PENDING  
**Verified At**: *(pending)*  

#### Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | `security` | `not-applicable` | `not-applicable` | `not-needed` | — | `false` | Iteration 001 Foundation contains no authentication boundaries, privilege checks, trust domain crossings, or user-controlled paths. It updates coordinator prompt, agent guidance documents, and handoff templates only, with no new runtime code or state transitions. Security surface analysis is not applicable. | — |
| `error-handling-expectations` | `error-handling` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Coordinator prompt and handoff templates must document graceful handling of edge cases: read-only responses with no artifact work, fully complete factual answers with no follow-up, and verification gaps. T001-T003 planning documents fail-safe guidance; no runtime changes. | `false` | Planning evidence: coordinator prompt (T001) explicitly guides agents to state progress even for read-only answers; handoff template (T002) includes all edge-case patterns; decision guidance (T003) covers verification-gap disclosure. No runtime error paths exist pre-implementation. | — |
| `retry-idempotency-requirements` | `retry-idempotency` | `not-applicable` | `not-applicable` | `not-needed` | — | `false` | Iteration 001 Foundation is purely documentation and prompt guidance. No idempotency concerns apply to coordinator prompt updates, handoff templates, or agent guidance documents. | — |
| `test-integrity-targets` | `test-integrity` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Planning documents test coverage scope: Iteration 002 (T007-T008) must deliver integration tests under `tests/integration/` that exercise the handoff validator against synthetic governance-jargon responses (must flag) and plain-language responses (must pass). T002 (handoff template) and T006 (soft-validator design) must provide test fixture definitions. | `false` | Planning evidence: T002 handoff template includes edge-case examples for testing; T006 soft-validator design document specifies test scenarios (governance-acronym flag and plain-language pass). Runtime evidence deferred to Iteration 002 when tests land. | — |
| `operational-resilience-concerns` | `operational-resilience` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Squad.agent.md (T004) must formally codify the three-section handoff format with an explicit session-restart note, and the coordinator prompt, handoff template, and checklist artifacts must remain durable across future updates. | `false` | Planning evidence: T004 explicitly requires the session-restart warning for `.github/agents/squad.agent.md`; T001, T002, and T005 keep the guidance in git-tracked artifacts that can be reviewed and maintained without runtime dependencies. | — |
| `validation-lane-completeness` | `validation` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Planning documents validation-lane scope: Iteration 002 (T007-T009) must deliver an authorized validation command set for handoff soft-validator coverage. Before Iteration 002 sign-off, validation must confirm the governance-acronym detection rule, plain-language scoring, and edge-case handling (lightweight patterns, fully complete answers, verification gaps, blockers). | `false` | Planning evidence: T006 soft-validator design document specifies the detection rule (three-or-more governance acronyms in lead without plain-language paraphrase) and five core validation scenarios. Runtime evidence deferred to Iteration 002 validation lane. | — |
| `handoff-semantics-correctness` | `specification-compliance` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Planning documents coordinator prompt, handoff template, and decision guidance must satisfy all three user stories (US1 clear completion, US2 blockers/review needs, US3 lightweight fluency) and map to FR-001 through FR-015. Each artifact must be reviewed by strongest-available class before implementation. | `false` | Planning evidence: T001 coordinator prompt explicitly maps to FR-001–FR-007, FR-012–FR-013; T002 handoff template covers US1, US2, US3 patterns; T003 decision guidance covers FR-008–FR-011. All six tasks traced to spec requirements in Requirements Traceability table. | — |
| `governance-acronym-rule-absorption` | `governance-compliance` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Planning documents coordinator prompt (T001) and handoff templates (T002) must explicitly absorb the human-handoff trap detection rule (three-or-more governance acronyms in lead without plain-language paraphrase). Agents must understand this constraint during response generation, not discover it only in post-validation. T006 soft-validator design must codify the detection method. | `false` | Planning evidence: T001 coordinator prompt explicitly instructs agents to use plain-language lead and defer governance vocabulary to subsections; T002 handoff template examples demonstrate plain-language-first pattern; T006 soft-validator design formalizes the detection rule (acronym count, lead-sentence scope, plain-language paraphrase requirement). | — |
| `agent-guidance-durability` | `operational-resilience` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Planning documents agent guidance (T004 Squad.agent.md update) must formally codify the three-section handoff format and include a session-restart note (touching Squad.agent.md requires session restart between iteration close and feature closeout). Guidance must survive future agent updates and be reviewable by strongest-available class. | `false` | Planning evidence: T004 explicitly updates `.github/agents/squad.agent.md` with formal three-section format (`What I just did` / `Why I stopped` / `What I need from you`) and includes session-restart note. This codification survives across sessions and can be reviewed before implementation. | — |
| `governance-integration-readiness` | `governance-compliance` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Planning documents governance integration (T005 checklist surface, T006 soft-validator design) must define soft-warning logic, integration points for iteration 002, and traceability to known-traps corpus. Soft validator must not hard-block responses but must flag governance-acronym violations and missing handoff fields. | `false` | Planning evidence: T005 governance checklist (coordinator-handoff-governance.md) specifies soft-warning logic and reference to governance-acronym rule; T006 soft-validator design document specifies soft-validator integration and no hard-blocking behavior. Runtime integration deferred to Iteration 002. | — |

#### Post-Implementation Evidence Notes

- This gate is in the planning-evidence state. All concerns carry planning-level evidence and are marked ready pending human review.
- Runtime evidence (post-implementation validation) is explicitly deferred to Iteration 002 when soft-validator and integration tests land.
- Test integrity and validation-lane concerns note the Iteration 002 dependence but are marked `addressed` based on Iteration 001 planning artifacts providing sufficient design for Iteration 002 execution.

#### Hardening-Gate Status

**Overall Verdict**: ✅ **READY FOR REVIEW** — All planning artifacts are complete and ready for strongest-available class review before implementation.

**Scope**: Iteration 001 Foundation (T001–T006, 10 story_points); soft-validator and integration tests deferred to Iteration 002

**Reviewed By**: Alon Fliess  
**Reviewed At**: 2026-05-11

---

## Notes

- Iteration 001 is deliberately bounded to coordinator guidance and documentation work—no soft-validator implementation or integration-test infrastructure.
- This slice gives reviewers a clean checkpoint to validate handoff semantics and coordinator guidance clarity before validation automation and test fixtures add complexity in Iteration 002.
- All tasks are documentation and prompt updates with no new runtime code or state changes. This keeps the scope lean and reviewable.
- `T001` updates the coordinator response prompt to reinforce both required handoff fields (current progress status and recommended next step) with explicit patterns for completion, blockers, and lightweight requests.
- `T002` creates a reusable handoff template with three-section format examples, demonstrating how to structure progress and next-step information for different task sizes and outcomes.
- `T003` codifies decision guidance for tricky scenarios: blockers vs. continue logic, review approval identification, manual test focus, and verification-gap disclosure.
- `T004` updates Squad.agent.md to formally document the three-section handoff format as the standard coordinator final-response structure, with session-restart warning for future agent updates.
- `T005` creates a governance checklist surface for soft-warning validation of handoff fields and governance-acronym rule compliance (not hard-blocking).
- `T006` designs the soft-validator concept, formalizing the governance-acronym detection rule and identifying all integration points for Iteration 002 implementation.
- The known-traps corpus row `human-handoff` seeded this entire feature. Iteration 001 absorbs the trap detection rule into coordinator guidance and soft-validator design so agents understand the constraint before validation runs.
- Implementation approval is required before work begins. This plan is ready for strongest-available review.
