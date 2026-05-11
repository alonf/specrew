# Tasks: User-Facing Progress Handoff

**Feature**: `007-user-facing-progress-handoff`  
**Spec**: [spec.md](./spec.md)  
**Plan**: [plan.md](./plan.md)  
**Generated**: 2026-05-11  
**Status**: Ready for Iteration 001 execution

---

## Overview

This tasks file delivers Specrew user-facing progress handoff semantics across two iterations:

- **Iteration 001**: Foundation & Governance (Phases 1–2) — coordinator prompt, template, decision guidance, agent documentation, governance checklist, soft-validator concept design
- **Iteration 002**: Validation & Integration (Phase 3) — soft-validator implementation, integration tests, validation lane updates, polish & governance integration

Every final Squad user-facing response will explicitly include:
1. **Current progress status** — What is complete, where work stands, what was verified, what remains blocked or open
2. **Recommended next step** — The single best immediate action for the human user or Squad

The human-handoff trap from `.specrew/quality/known-traps.md` (row 12, 2026-05-10) is formalized as the governance-acronym detection rule and embedded in Iteration 001 coordinator guidance and governance checklist.

---

## Iteration 001: Foundation & Governance

**Scope**: Phase 1 + Phase 2 coordinator guidance and agent documentation  
**Effort**: 10 story_points  
**Delivery Dependency**: Before-implement review checkpoint after all Phase 2 tasks complete

### Phase 1: Foundation

- [X] T001 Update coordinator prompt in `extensions/specrew-speckit/prompts/coordinator-response.md` to reinforce two-field handoff contract (progress status + recommended next step) with explicit guidance for completion, blocker, and lightweight scenarios; include plain-language-first principle and examples showing governance acronyms deferred to footnotes; traceability: [FR-001][FR-003][FR-005][US1][US3]
- [X] T002 [P] Create handoff template artifact at `specs/001-specrew-product/contracts/coordinator-handoff-template.md` with three-section format (What I just did / Why I stopped / What I need from you) and patterns for completion, blocked, partial, and lightweight responses; acceptance: template is usable by agents as copy-paste starting point; traceability: [FR-001][FR-003][FR-004][FR-005][US1][US3]

### Phase 2: Decision & Agent Guidance

- [X] T003 [P] [US2] Codify coordinator decision guidance in `extensions/specrew-speckit/prompts/coordinator-decision-guidance.md` with decision trees for blockers, review needs (FR-008), manual testing (FR-009), verification gaps (FR-010), and blocked-vs-continue logic (FR-011); decision trees must reference handoff semantics; traceability: [FR-008][FR-009][FR-010][FR-011][US2]
- [X] T004 [US1] Update Squad.agent.md in `.github/agents/squad.agent.md` to formally codify three-section handoff format as standard Squad coordinator final-response structure; Add a new section titled `## Coordinator-Response: Final-Response Handoff Contract` under Team Mode containing the three-section format rules, plain-language-first principle, examples, and references to coordinator prompt/template/decision-guidance artifact locations. **CRITICAL REMINDER**: Touching this file requires session restart between Iteration 001 closeout and feature deployment. Add explicit session-restart warning to the new Coordinator-Response section with a note that after squad.agent.md changes take effect, a new session must start for Squad to load updated guidance. Traceability: [FR-013][FR-014]
- [X] T005 [P] [US1][US2][US3] Create coordinator-handoff governance checklist at `extensions/specrew-speckit/checklists/coordinator-handoff-governance.md` with soft-warning logic (not hard-blocking) for: (1) plain-language-first check (no three-or-more governance acronyms in lead without paraphrase), (2) current-progress-status presence check, (3) recommended-next-step presence check, (4) blocker/risk disclosure validation; reference the human-handoff trap detection pattern (`.specrew/quality/known-traps.md` row 12); checklist must be human-reviewable and executable by soft validator; traceability: [FR-005][FR-006][FR-016][TG-002][TG-003]
- [X] T006 [P] Design soft-validator concept for handoff-governance validation in `extensions/specrew-speckit/design/soft-validator-handoff-governance.md` with clear detection rule statement: scan final user-facing coordinator response lead for three-or-more governance acronyms or schema-field names without plain-language paraphrase and flag as quality concern (not hard-block); include detection algorithm pseudo-code, integration points (post-response coordinator output, governance surface registration), and implementation sketch for Iteration 002; reference human-handoff trap as formal acceptance test; Iteration 002 implementer must have zero ambiguity about detection logic; traceability: [FR-016][human-handoff-trap]

---

## Iteration 002: Validation & Integration

**Scope**: Phase 3 soft-validator implementation, integration tests, validation lane updates, polish  
**Effort**: ~10 story_points (estimated, subject to pre-implementation refinement)  
**Delivery Dependency**: Iteration 001 completion + before-implement review approval

### Phase 3: Soft-Validator, Tests & Integration

- [ ] T007 Implement soft-validator handoff-governance check as new governance validator under `extensions/specrew-speckit/validators/handoff-governance-validator.ps1` with runtime detection of: (1) missing current progress status, (2) missing recommended next step, (3) three-or-more-governance-acronyms rule violation; register with governance checklist surface (`extensions/specrew-speckit/checklists/coordinator-handoff-governance.md`); hook into post-response coordinator output path; soft-validator MUST flag missing fields without blocking response delivery; traceability: [FR-016]
- [ ] T008 [P] Create integration tests for handoff validator under `tests/integration/` with two test fixtures and validation logic: (1) `handoff-governance-jargon-response-test.ps1` — synthetic coordinator response containing 3+ governance acronyms in lead without plain-language paraphrase (e.g., `before-implement gate, hardening-gate sign-off, Implementation Approval evidence reuse`) → expect handoff-governance-validator to flag as quality concern; (2) `handoff-governance-plain-language-response-test.ps1` — synthetic coordinator response with plain-language lead followed by formal references in subsection (e.g., "We need three decisions before moving forward: (1) approval to proceed to implementation, (2) sign-off on our governance controls, (3) confirmation that we can reuse existing approval evidence. [formal references: before-implement gate, hardening-gate sign-off, ...]") → expect handoff-governance-validator to pass without flag; both fixtures must validate against FR-006 (plain-language-first, actionable next step) and FR-016 (soft quality warning); traceability: [FR-016][human-handoff-trap][test-integrity-trap]
- [ ] T009 Update validation lane integration in `extensions/specrew-speckit/governance/validation-lane.md` to register soft-validator command in authorized-commands list and add handoff-governance-validator task to validation-lane execution; document exact authorized soft-validator commands in both validation-lane task definition AND hardening-gate concern evidence; cross-check authorization against plan.md T007 definition before sign-off to prevent validation-lane-completeness drift (`.specrew/quality/known-traps.md` row 10); traceability: [FR-016]
- [ ] T010 Polish & hardening-gate sign-off prep including: (1) final tuning of all governance-checklist wording for clarity and consistency, (2) final review of handoff template examples for completeness across all three user stories (US1, US2, US3), (3) add review-file navigation guidance so local file review requests use a `file:///` URI with the absolute Windows path in this Windows environment, (4) draft hardening-gate.md for feature 007 closure using Iteration 005 pre-sign-off schema (Overall Verdict field, pending metadata, five canonical concerns first: security-surface, error-handling-expectations, retry-idempotency-requirements, test-integrity-targets, operational-resilience-concerns); (5) human sign-off documentation prep; traceability: [FR-017][iteration-005-schema][TG-001][TG-002][TG-003]

---

## Task Traceability & Cross-References

### User Stories

| User Story | Description | Priority | Phase | Tasks |
|---|---|---|---|---|
| US1 | Receive a clear completion handoff (progress status + next step explicit) | P1 | Iteration 001: T001, T002, T005; Iteration 002: T008, T010 | [FR-001][FR-003][FR-004][FR-006][FR-012][FR-013] |
| US2 | Understand blockers and review needs (blocker → unblock action, review → what-to-review) | P1 | Iteration 001: T003, T005; Iteration 002: T007, T008 | [FR-005][FR-007][FR-008][FR-009][FR-010][FR-011][FR-016] |
| US3 | Keep lightweight responses fluent (compact handoff without ceremony or duplication) | P2 | Iteration 001: T001, T002, T005; Iteration 002: T008, T010 | [FR-002][FR-006][FR-012][FR-015][FR-016] |

### Functional Requirements

| Requirement | Concern | Tasks | Notes |
|---|---|---|---|
| FR-001 Final Handoff Coverage | Every final user-facing response MUST include explicit current progress status | T001, T002, T005 | Coordinator prompt + template + checklist |
| FR-002 Universal Scope | Handoff applies across Direct, Lightweight, Standard, Full, Spec Kit, implementation, review, lifecycle flows | T001, T002, T005 | Template covers all patterns |
| FR-003 Progress Status Content | State present work/lifecycle state and summarize completed work | T001, T002, T005 | Prompt guidance + template examples |
| FR-004 Artifact Visibility | Identify relevant feature/artifact group when work changed; explicitly state "no files changed" if relevant | T002, T005 | Template pattern for each scenario |
| FR-005 Open Issues Disclosure | State blockers, known risks, deferred decisions, skipped/failed checks explicitly | T003, T005 | Decision guidance + checklist |
| FR-006 Actionable Next Step | Identify single best immediate action; concise enough to act on | T001, T002, T005 | Prompt guidance + template |
| FR-007 Ownership Clarity | Identify owner when ownership matters (user, Squad, reviewer, tester) | T003 | Decision guidance |
| FR-008 Review Guidance | If human review recommended, state what should be reviewed | T003, T008 | Decision guidance + test fixture |
| FR-009 Manual Test Guidance | If manual testing recommended, state what scenario/behavior/risk to test | T003, T008 | Decision guidance + test fixture |
| FR-010 Verification Gap Guidance | If automated verification failed/skipped, state gap and next action | T003 | Decision guidance |
| FR-011 Blocked vs. Continue Logic | If blocked, recommend unblock action before continued implementation | T003 | Decision guidance |
| FR-012 Flexible Wording | Exact headings not required; compact inline acceptable for small requests | T001, T002 | Prompt guidance + template |
| FR-013 Final Response Ownership | Apply to coordinator's final user-facing response | T004, T005 | Squad.agent.md + checklist |
| FR-014 Durable Rollout | Update coordinator guidance, agent instructions, quality surfaces for persistence | T004, T005 | Squad.agent.md + checklist |
| FR-015 Specialized Format Compatibility | Specialized formats MAY satisfy requirement only if both handoff concepts explicit | T001, T002 | Prompt + template |
| FR-016 Soft Quality Warning | Missing fields = soft quality warning, not hard failure | T005, T006, T007, T008, T009 | Governance checklist + soft validator |
| FR-017 Review File Navigation | Local file review requests include a `file:///` URI using the absolute Windows path | T010 | Final-response polish across review-facing guidance surfaces |

### Governance & Traceability Requirements

| Requirement | Traceability | Tasks | Owned By |
|---|---|---|---|
| TG-001: US1 → FR-001, FR-003, FR-004, FR-006, FR-012, FR-013 | Direct mapping | T001, T002, T005, T008, T010 | Coordinator-response maintainer |
| TG-002: US2 → FR-005, FR-007, FR-008, FR-009, FR-010, FR-011, FR-016 | Direct mapping | T003, T005, T007, T008 | Coordinator-response maintainer |
| TG-002A: Review-file navigation in US2 → FR-008, FR-017 | Direct mapping | T010 | Coordinator-response maintainer |
| TG-003: US3 → FR-002, FR-006, FR-012, FR-015, FR-016 | Direct mapping | T001, T002, T005, T008, T010 | Prompt maintainer |
| TG-004: Specialized format conflicts resolved in favor of explicit semantic fields | Design principle | T001, T002, T004 | Coordinator-response maintainer |

### Known Traps & Real-World Precedents

| Trap | Citation | Integration | Tasks |
|---|---|---|---|
| **human-handoff** (2026-05-10, feature 008 iteration 002) | `.specrew/quality/known-traps.md` row 12 | Governance-acronym detection rule becomes formal acceptance test for handoff validator. Coordinator guidance and checklist must enforce plain-language-first principle. Test fixtures validate against this trap. | T001, T005, T006, T008 |
| **validation-lane-completeness** drift (2026-05-11, feature 008 iteration 005) | `.specrew/quality/known-traps.md` row 10 | T009 (validation lane update) must document exact authorized soft-validator commands in both plan.md task definition AND hardening-gate concern evidence. Cross-check before sign-off to prevent list mismatch. | T009 |
| **test-integrity** — scaffold path exercise (2026-05-10, feature 008 iteration 003) | `.specrew/quality/known-traps.md` row 14 | T008 integration tests must invoke the actual soft-validator runtime path and assert user-visible output, not just internal state. Cannot satisfy coverage by only validating governance-checklist artifact content. | T008 |
| **Iteration 005 pre-sign-off schema** (formalized 2026-05-10, feature 008 iteration 005) | `.specrew/quality/known-traps.md` row 9 | T010 (hardening-gate draft) must use Overall Verdict field paired with pending metadata (Reviewed By, Reviewed At marked pending for pre-sign-off state). Five canonical concerns (security-surface, error-handling-expectations, retry-idempotency-requirements, test-integrity-targets, operational-resilience-concerns) MUST appear first in Concern Review table. | T010 |

---

## Task Execution Model

### Iteration 001 Execution

**Phases 1–2 may execute with limited parallelization:**

1. **Serial path**: T001 (coordinator prompt) → T002 (template) → T005 (checklist) — dependent on prompt/template clarity
2. **Parallel path**: T003 (decision guidance), T004 (Squad.agent.md), T006 (soft-validator concept) — independent of Phases 1–2 content

**Example parallel execution**:
- **Worker A**: Execute T001 → T002 → T005 in series
- **Worker B**: Execute T003, T004, T006 in parallel with Worker A, with T004 blocked on T001 completion only (to ensure prompt is updated first)

**Delivery checkpoint**: All Phases 1–2 tasks complete → Before-implement review approval required before Iteration 002 start.

### Iteration 002 Execution

**Serial dependency**: T006 (Iteration 001 soft-validator concept) → T007 (soft-validator implementation)  
**Parallel execution**: T008 (integration tests) and T009 (validation lane) can run in parallel with T007, provided test fixtures use design from T006.  
**Final task**: T010 (polish) runs after T007–T009 complete and integration tests pass.

---

## Independent Test Criteria Per User Story

### User Story 1: Clear Completion Handoff

**Independent Test Setup**: Run Squad on a completed implementation request (analysis, implementation, review, or lifecycle work).

**Acceptance Criteria** *(all must pass)*:
1. Final user-facing coordinator response includes explicit current progress status (identifies what changed, what state work is in)
2. Final user-facing coordinator response includes explicit recommended next step (single, concrete, actionable)
3. If files were changed, status identifies relevant feature/artifact group
4. If no files were changed, status explicitly states "no files changed" if that affects user's next decision

**Verification Method**: Manual sampling + T008 integration tests validate syntax and semantic coverage.

### User Story 2: Understand Blockers and Review Needs

**Independent Test Setup**: Simulate a blocked gate, failed validation, review finding, or deferred decision.

**Acceptance Criteria** *(all must pass)*:
1. Progress status identifies the blocking condition (blocker name, gate name, decision required)
2. When human approval required, recommended next step names the approval/review decision
3. When manual testing required, recommended next step describes test focus (scenario, behavior, risk)
4. When automated verification failed/skipped, status states the gap AND recommends next verification action
5. When the next step is local file review, the response includes a `file:///` URI using the absolute Windows path

**Verification Method**: Manual code review + T008 integration tests (plain-language vs. jargon fixtures).

### User Story 3: Keep Lightweight Responses Fluent

**Independent Test Setup**: Run Squad on direct factual request, read-only review, and small implementation task.

**Acceptance Criteria** *(all must pass)*:
1. For small requests: progress status and next step expressed in one concise paragraph (no bulky section headings)
2. For substantial requests: progress status and next step are visually scannable
3. For obvious next steps: action still stated explicitly (no inference)
4. For fully complete factual/read-only answers: may explicitly state "no further action needed" as valid recommended next step

**Verification Method**: Manual sampling + T008 integration tests validate compact formatting.

---

## MVP Scope Recommendation

**Suggested MVP = Iteration 001 complete + human sign-off before Iteration 002 starts**

This split allows:
1. Coordinator guidance, template, and decision trees to be reviewed by humans (Alon Fliess, spec steward)
2. Before-implement gate to validate handoff semantics match spec intent
3. Iteration 002 soft-validator implementation to proceed with confidence that semantic guidance is solid and durable

**Rationale**: The majority of handoff behavior will be driven by Iteration 001 artifacts (prompt, template, decision guidance, agent documentation). Iteration 002 soft-validator is an automation layer that validates and flags—it does not change the handoff semantics themselves.

---

## Implementation Strategy

### Coordinator Guidance Coherence

The coordinator prompt (T001), template (T002), and decision guidance (T003) must form a single coherent narrative:
- **Prompt** sets the expectation and principle (two-field handoff, plain-language-first)
- **Template** shows concrete patterns for each scenario type
- **Decision guidance** shows how to apply the pattern to specific decision points (blockers, reviews, tests)

**Coherence check**: Every pattern in the template must have a corresponding decision tree entry in guidance.

### Agent Documentation Durability

Squad.agent.md (T004) is a persistent artifact that must survive future agent updates and session restarts. The session-restart warning is **critical**:
- If Squad.agent.md is edited during task execution and not reloaded, Squad will not see the updated guidance until the next session
- Add explicit warning: *"After editing `.github/agents/squad.agent.md`, a new session is required for Squad to load updated guidance."*

### Governance Checklist as Soft Safety Net

The coordinator-handoff governance checklist (T005) is a **soft quality warning**, not a hard-blocking gate:
- Missing progress status → flag, suggest clarification, do not block delivery
- Missing next step → flag, suggest clarification, do not block delivery
- Three-or-more governance acronyms in lead → flag, suggest plain-language rewrite, do not block delivery
- This aligns with FR-016 (soft quality warning) and differentiates from hard governance failures

### Soft-Validator as Pattern Detector

The soft-validator concept (T006) and implementation (T007) must focus on **detection clarity** for the human-handoff trap:
- **Pattern to detect**: Three or more governance acronyms or schema-field names appearing in the lead sentence of any handoff section without plain-language paraphrase
- **Example violation**: *"We need before-implement gate approval, hardening-gate sign-off, and Implementation Approval evidence reuse"*
- **Example compliant**: *"We need three decisions before moving forward: (1) approval to proceed to implementation, (2) sign-off on our governance controls, and (3) confirmation that we can reuse existing approval evidence. [formal references: before-implement gate, hardening-gate sign-off, Implementation Approval evidence reuse]"*

### Integration Test Coverage Integrity

T008 integration tests (and by extension, T007 soft-validator implementation) must **exercise the actual validation path**:
- Cannot satisfy coverage by only validating governance-checklist artifact content
- Must invoke the soft-validator runtime itself (not just mocking internal state)
- Must assert user-visible output and governance surface response
- Aligns with test-integrity trap (`.specrew/quality/known-traps.md` row 14)

### Hardening Gate Alignment with Iteration 005 Schema

T010 (polish & hardening-gate prep) must draft a hardening gate using the formal pre-sign-off schema:

**Required structure**:
1. **Overall Verdict** field (e.g., `ready`, `deferred-with-approval`, `review-pending`)
2. **Pending metadata** for pre-sign-off state (e.g., `Reviewed By: *(pending human sign-off)*, Reviewed At: *(pending)*, Approval Ref: *(pending)*)`)
3. **Concern Review table** with five canonical concerns FIRST:
   - `security-surface`
   - `error-handling-expectations`
   - `retry-idempotency-requirements`
   - `test-integrity-targets`
   - `operational-resilience-concerns`
4. Feature-specific concerns follow after the canonical five
5. Nine-column schema recommended (Concern, Category, Status, Evidence Basis, Runtime Evidence Status, Expected Controls, Blocking, Rationale, Approval)

---

## Iteration 001 Completion Checklist

After all Phase 1 and Phase 2 tasks complete, before-implement review should verify:

- [ ] T001 Coordinator prompt includes plain-language-first principle, explicit two-field handoff guidance, and examples
- [ ] T002 Template provides usable copy-paste patterns for all response types (completion, blocked, partial, lightweight)
- [ ] T003 Decision guidance codifies blockers, reviews, testing, verification gaps, and blocked-vs-continue logic
- [ ] T004 Squad.agent.md includes three-section handoff format AND explicit session-restart warning
- [ ] T005 Governance checklist is human-reviewable and includes plain-language-first check, governance-acronym detection rule, and soft-warning logic
- [ ] T006 Soft-validator concept design is unambiguous and ready for Iteration 002 implementation
- [ ] **Coherence check**: Prompt + template + decision guidance form a single narrative (no contradictions)
- [ ] **Known-trap alignment**: Governance-acronym rule absorbed in T001 + T005 + T006 (human-handoff trap from `.specrew/quality/known-traps.md` row 12)
- [ ] **Traceability verified**: Every FR and TG requirement traced to at least one task
- [ ] **User story coverage verified**: All acceptance scenarios in spec.md can be satisfied by Iteration 001 artifacts

---

## Iteration 002 Readiness Checkpoints

Before Iteration 002 implementation begins:

1. **T006 output review**: Soft-validator concept design is clear and actionable
2. **Before-implement gate approval**: Human signs off that Iteration 001 artifacts match spec intent and are durable
3. **T007 implementation scope confirmed**: Soft-validator will be a new governance validator registered with existing checklist surface (no new framework changes)
4. **T008 test fixtures approved**: Integration test scenarios (governance-jargon vs. plain-language) are representative of real handoff scenarios
5. **T009 validation-lane integration scoped**: Authorized command list is documented and approved before T007 implementation

---

## Files Modified or Created

### Iteration 001

| File | Status | Owner | FR Traceability |
|---|---|---|---|
| `extensions/specrew-speckit/prompts/coordinator-response.md` | Create/Update | Coordinator-response maintainer | FR-001, FR-002, FR-003, FR-006, FR-012, FR-015 |
| `extensions/specrew-speckit/prompts/coordinator-final-response-guidance.md` (optional new) | Create | Coordinator-response maintainer | FR-001, FR-006, FR-012 |
| `specs/001-specrew-product/contracts/coordinator-handoff-template.md` | Create | Prompt maintainer | FR-001, FR-002, FR-003, FR-004, FR-006, FR-012 |
| `extensions/specrew-speckit/prompts/coordinator-decision-guidance.md` | Create | Coordinator-response maintainer | FR-007, FR-008, FR-009, FR-010, FR-011 |
| `.github/agents/squad.agent.md` | Update (Team Mode section) | Agent guidance maintainer | FR-013, FR-014 |
| `extensions/specrew-speckit/checklists/coordinator-handoff-governance.md` | Create | Governance checklist maintainer | FR-001, FR-005, FR-006, FR-016 |
| `extensions/specrew-speckit/design/soft-validator-handoff-governance.md` | Create | Governance-validator maintainer | FR-016 |

### Iteration 002

| File | Status | Owner | FR Traceability |
|---|---|---|---|
| `extensions/specrew-speckit/validators/handoff-governance-validator.ps1` | Create | Governance-validator maintainer | FR-016 |
| `tests/integration/handoff-governance-jargon-response-test.ps1` | Create | Test maintainer | FR-016 |
| `tests/integration/handoff-governance-plain-language-response-test.ps1` | Create | Test maintainer | FR-016 |
| `extensions/specrew-speckit/governance/validation-lane.md` | Update | Governance-validator maintainer | FR-016 |
| `specs/007-user-facing-progress-handoff/hardening-gate.md` | Create (post-Iteration 001) | Feature owner | All FR/TG |

---

## Related Documentation

- **Spec**: [spec.md](./spec.md) — User stories, functional requirements, acceptance scenarios
- **Plan**: [plan.md](./plan.md) — Technical context, two-iteration split, requirements mapping, known precedents
- **Known Traps**: `.specrew/quality/known-traps.md` — human-handoff trap (row 12), validation-lane-completeness drift (row 10), test-integrity (row 14), Iteration 005 pre-sign-off schema (row 9)
- **Squad Agent Guidance**: `.github/agents/squad.agent.md` — Coordinator role, final-response ownership
- **Iteration 001 Sandbox Plan** (cleanup candidate): `specs/007-user-facing-progress-handoff/iterations/001/plan.md` (to be removed after feature sign-off)

---

## Summary

**Iteration 001 (10 story_points)**:
- Coordinator prompt, template, decision guidance (Phases 1–2)
- Agent documentation (Squad.agent.md codification)
- Governance checklist & soft-validator concept design
- Ready for before-implement review & human validation

**Iteration 002 (~10 story_points)**:
- Soft-validator runtime implementation
- Integration tests (governance-jargon flag ✓, plain-language pass ✓)
- Validation lane integration
- Polish & hardening-gate sign-off prep

**Total Feature Tasks**: 10 (Iteration 001) + 4 (Iteration 002) = 14 tasks  
**User Story Coverage**: US1 (P1, 8 tasks), US2 (P1, 4 tasks), US3 (P2, 6 tasks)  
**Known Traps Integrated**: human-handoff (T001, T005, T006, T008), validation-lane-completeness (T009), test-integrity (T008), Iteration 005 schema (T010)  
**Traceability**: All 16 FRs, all 4 TGs, all 3 user stories covered in task assignments
