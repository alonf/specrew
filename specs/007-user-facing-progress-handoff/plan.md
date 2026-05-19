# Feature Plan: User-Facing Progress Handoff

**Spec**: [./spec.md](./spec.md)  
**Feature Branch**: `007-user-facing-progress-handoff`  
**Status**: planned  
**Planning Date**: 2026-05-11

---

## Overview

This plan delivers durable Squad coordinator handoff semantics across all final user-facing responses. Every completion, pause, or factual answer will explicitly state:

1. **Current progress status** — What is complete, where work stands, what was verified, what remains blocked or open
2. **Recommended next step** — The single best immediate action for the human user or Squad

When the next step is human review of a local repository file in this Windows environment, the handoff must provide a navigation-ready `file:///` URI using the absolute Windows path.

The implementation prioritizes **documentation, prompt updates, and soft-validator design only** — no new runtime stack changes. We absorb the lived precedent from the `human-handoff` trap row in `.specrew/quality/known-traps.md` (2026-05-10 discovery) as a formal acceptance test: final coordinator responses with three or more governance acronyms in the lead without plain-language paraphrase must be flagged as a quality concern.

---

## Two-Iteration Split (Confirmed)

### Iteration 001: Foundation & Governance

**Scope**: Phase 1 + Phase 2 coordinator guidance and agent documentation  
**Effort**: 10 story_points  
**Deliverables**: Prompt updates, handoff template, coordinator decision guidance, Squad.agent.md codification, soft-validator concept design, governance checklist surface

### Iteration 002: Validation & Integration

**Scope**: Phase 3 soft-validator implementation + integration tests + polish  
**Effort**: ~10 story_points (estimated)  
**Deliverables**: Soft-validator runtime, integration tests (governance-jargon response ▌ flag, plain-language response ▌ pass), validation lane integration, quality polish

This split allows **Iteration 001 completion → before-implement review checkpoint** (human validates handoff semantics and coordinator guidance) **→ Iteration 002 implementation** (soft validator adds automation without changing handoff behavior).

---

## Technical Context

### Handoff Semantics

The **Three-Section Handoff Format** (already drafted in iterations/001/plan.md) follows this structure:

```
What I just did / Why I stopped
  [Current progress status] — what changed, where work stands, what state.
  Reference: [relevant feature, artifact group, or work area if applicable]
  
Why I stopped / What I need from you
  [Reason for pause or blocker, if any]
  
What I need from you / What happens next
  [Recommended next step] — single, concrete, actionable.
  Owner: [human user | Squad | reviewer | manual tester]
```

For lightweight responses, all three may collapse into one concise paragraph while preserving both semantic fields.

### Governance-Acronym Detection Rule

**Source**: `human-handoff` row in `.specrew/quality/known-traps.md` (2026-05-10)

**Rule**: Scan every final user-facing coordinator response's lead sentence in any of the three handoff sections. If three or more governance acronyms or schema-field names appear in the lead **without plain-language paraphrase**, flag the response.

**Example Violation**:
> `before-implement gate, hardening-gate sign-off, Implementation Approval evidence reuse, and governance trap`

**Compliant Rewrite**:
> We need three decisions before moving forward: (1) approval to proceed to implementation, (2) sign-off on our governance controls, and (3) confirmation that we can reuse existing approval evidence. [_formal references: before-implement gate, hardening-gate sign-off, …_]

This rule becomes a soft-validator detection pattern in Iteration 002; coordinator guidance in Iteration 001 must absorb the constraint so agents understand it early.

---

## Requirements Mapping

### Iteration 001 Coverage (Phase 1 + Phase 2)

| Spec Ref | Requirement | Task | Notes |
|----------|-------------|------|-------|
| FR-001, FR-002, FR-003, FR-004, FR-005 | Final Handoff Coverage, Progress Status Content, Open Issues Disclosure | T001, T002, T005 | Coordinator prompt, handoff template, governance checklist |
| FR-006, FR-007, FR-012 | Actionable Next Step, Flexible Wording | T001, T002, T005 | Prompt reinforcement, compact patterns, inline examples |
| FR-008, FR-009, FR-010, FR-011 | Review, Manual Test, Verification Gap, Blocked vs. Continue | T001, T003 | Coordinator decision-guidance codification |
| FR-013, FR-014, FR-015 | Final Response Ownership, Durable Rollout, Specialized Format | T004, T006 | Squad.agent.md codification, governance surfaces |
| FR-016 | Soft Quality Warning | T006 | Soft-validator concept design (implementation deferred to Iteration 002) |
| Human-Handoff Trap Detection | Three-or-more governance acronyms in lead | T005, T006 | Governance checklist, soft-validator concept |
| User Story 1 | Clear completion handoff | T001, T002, T005 | Prompt, template, checklist |
| User Story 2 | Understand blockers and review needs | T001, T003 | Decision guidance, prompt |
| User Story 3 | Keep lightweight responses fluent | T001, T002, T005 | Compact patterns, inline guidance |

### Iteration 002 Coverage (Phase 3)

| Requirement | Task | Notes |
|-------------|------|-------|
| FR-016 implementation | T007 (soft-validator) | Post-response detection, governance integration |
| Integration testing | T008 (integration test fixtures) | Governance-jargon response (flag), plain-language response (pass) |
| Validation lane | T009 (validation lane updates) | Soft-validator registration, authorized command list |
| FR-017 review-file navigation | T010 (quality polish) | Add `file:///` absolute Windows path guidance for local review requests across final-response surfaces |
| Polish & Governance Integration | T010 (quality polish) | Final checklist tuning, review-link guidance, hardening gate sign-off |

---

## Iteration 001 Execution Plan

### Phase 1: Foundation

**T001** — Update coordinator prompt  

- **Owner**: Coordinator-response maintainer  
- **File**: `extensions/specrew-speckit/prompts/coordinator-response.md` + optional new `coordinator-final-response-guidance.md`  
- **Scope**: Reinforce two-field handoff contract with explicit guidance for completion, blocker, and lightweight scenarios  
- **Acceptance**: Prompt includes examples of:
  - Complete work handoff (progress + next step)
  - Blocked work handoff (blocker + unblock action)
  - Lightweight handoff (one concise paragraph)
  - Plain-language-first guidance (acronyms deferred to footnotes)
- **Effort**: 3 story_points

**T002** — Create handoff template artifact  

- **Owner**: Prompt maintainer  
- **File**: `specs/001-specrew-product/contracts/coordinator-handoff-template.md`  
- **Scope**: Three-section format examples with current-progress and next-step identification rules  
- **Content**: Completion patterns, blocked patterns, partial patterns, lightweight patterns  
- **Acceptance**: Template is usable by agents as a copy-paste starting point  
- **Effort**: 2 story_points

### Phase 2: Decision & Agent Guidance

**T003** — Codify coordinator decision guidance  

- **Owner**: Coordinator-response maintainer  
- **File**: `extensions/specrew-speckit/prompts/coordinator-decision-guidance.md`  
- **Scope**: Decision trees for blockers, review needs, manual testing, verification gaps, blocked-vs-continue logic  
- **Acceptance**: Decision trees reference the handoff semantics and show how to apply them to each scenario  
- **Effort**: 2 story_points

**T004** — Update Squad.agent.md  

- **Owner**: Agent guidance maintainer  
- **File**: `.github/agents/squad.agent.md`  
- **Scope**: Formally codify three-section handoff format as standard Squad coordinator final-response structure  
- **Critical Note**: **Touching this file requires session restart between iteration close and feature closeout.** Add this warning to the Squad.agent.md editing section.  
- **Acceptance**: Squad.agent.md Team Mode section includes explicit handoff format rules  
- **Effort**: 1 story_point

**T005** — Create coordinator-handoff governance checklist  

- **Owner**: Governance checklist maintainer  
- **File**: `extensions/specrew-speckit/checklists/coordinator-handoff-governance.md`  
- **Scope**: Soft-warning logic (not hard-blocking) for handoff validation  
- **Content**: Plain-language-first check, three-or-more-acronyms detection rule, progress-status presence check, next-step presence check  
- **Acceptance**: Checklist is human-reviewable and can be executed by a soft validator  
- **Effort**: 1 story_point

**T006** — Design soft-validator concept  

- **Owner**: Governance-validator maintainer  
- **File**: `extensions/specrew-speckit/design/soft-validator-handoff-governance.md`  
- **Scope**: Detection rule (three-or-more governance acronyms in lead without plain-language paraphrase), integration points, implementation sketch for Iteration 002  
- **Content**: Rule statement, rationale, detection algorithm pseudo-code, integration hooks (post-response, governance surface registration)  
- **Acceptance**: Iteration 002 implementer has a clear target and no ambiguity about detection logic  
- **Effort**: 1 story_point

**Total Iteration 001 Effort**: 10 story_points

---

## Iteration 002 Execution Plan (Outline)

### Phase 3: Validation & Soft Validator

**T007** — Implement soft-validator handoff-governance check  

- **Owner**: Governance-validator maintainer  
- **Scope**: Runtime detection of missing progress status, missing next step, three-or-more-acronyms rule  
- **Integration**: Register with governance checklist surface, hook into post-response coordinator output  

**T008** — Create integration tests for handoff validator  

- **Owner**: Test maintainer  
- **Scope**: Two test fixtures under `tests/integration/`:
  - `handoff-governance-jargon-response-test.ps1` — a response with 3+ governance acronyms in lead → expect flag  
  - `handoff-governance-plain-language-response-test.ps1` — a response with plain-language lead → expect pass  
- **Acceptance**: Both tests pass against the soft validator

**T009** — Update validation lane  

- **Owner**: Governance-validator maintainer  
- **Scope**: Register soft-validator command in authorized-commands list, add task to validation-lane execution  

**T010** — Quality polish  

- **Owner**: Feature owner (Alon Fliess)  
- **Scope**: Final checklist tuning, navigation-ready review-link guidance, hardening-gate sign-off prep, documentation review  

---

## Future Iteration Hardening Gates

When planning Iteration 003 and beyond, apply the **Iteration 005 pre-sign-off schema** from `.specrew/quality/known-traps.md`:

1. **Overall Verdict** field with values like `ready`, `deferred-with-approval`, or `review-pending`
2. **Rich pending metadata** for planning-time readiness (e.g., `Reviewed By: *(pending human sign-off)*, Reviewed At: *(pending)*`)
3. **Five canonical concerns first** (security-surface, error-handling-expectations, retry-idempotency-requirements, test-integrity-targets, operational-resilience-concerns), followed by feature-specific concerns
4. **Explicit approval traceability** from `.squad/decisions.md` — no inferred approvals from prior intake messages

---

## Governance Consistency

### Spec Authority ✅

Scope strictly limited to Phase 1 + Phase 2 coordination guidance and agent documentation from approved spec.md. Soft validator and integration tests explicitly deferred to Iteration 002.

### Traceability ✅

Every task maps to foundational FRs (FR-001 through FR-016) and user stories (US1, US2, US3). Soft-validator concept design (T006) explicitly bridges Iteration 001 planning to Iteration 002 implementation.

### Ownership ✅

Task owners align to Specrew roles in spec.md Requirement Ownership & Delivery section. Agent guidance maintainer (T004) has explicit session-restart warning.

### Capacity ✅

Iteration 001: 10/20 story_points (truthful slice with explicit deferrals).  
Iteration 002: ~10 story_points (estimated, subject to pre-implementation refinement).

---

## Quality Profile

**Profile**: `quality-profile.custom-composition.v1`

**Composition**:

- Markdown documentation guidance
- Coordinator-response prompt structure and examples
- Agent guidance codification (Squad.agent.md)
- Soft-validator concept design (pre-implementation)

**Risk Dimensions**:

- **Handoff semantics clarity** — Coordinator prompt and template must be clear enough for agents to consistently produce two-field handoffs (FR-001, FR-002, US1, US3)
- **Agent guidance durability** — Squad.agent.md codification must survive future agent updates and session restarts (FR-013, FR-014)
- **Soft-validator concept readiness** — Concept design must be complete and unambiguous so Iteration 002 implementation has a clear target (FR-016)
- **Governance-acronym rule absorption** — Handoff templates and coordinator guidance must absorb the human-handoff trap detection rule so agents understand the constraint before soft validator lands (derived from known-traps.md human-handoff row)
- **Specialized-format compatibility** — Coordinator guidance must explain how existing response formats preserve handoff semantics (FR-015)
- **Review-link navigation compatibility** — Review-oriented handoffs must use a `file:///` URI with the absolute Windows path so local file review works in the supported client workflow (FR-017)

---

## Success Criteria for Iteration 001

1. ✅ Coordinator prompt updated with explicit two-field handoff guidance and plain-language-first rule
2. ✅ Handoff template artifact created and ready for agent copy-paste
3. ✅ Decision guidance document codified for blocker and review scenarios
4. ✅ Squad.agent.md updated with three-section handoff format and session-restart note
5. ✅ Governance checklist surface defined and human-reviewable
6. ✅ Soft-validator concept design document complete with clear implementation target for Iteration 002

---

## Known Precedents & Traps

### human-handoff Trap (Row 12, `.specrew/quality/known-traps.md`)

**Incident**: Feature 008 iteration 002, 2026-05-10. Squad's stop message used `before-implement gate`, `hardening-gate sign-off`, `Implementation Approval evidence reuse`, and `governance trap` as primary lead phrasing without plain-language paraphrase. Human developer had to ask for a rewrite.

**Detection Method**: Scan every final user-facing coordinator response for governance acronyms or schema-field names appearing in the lead sentence. If three or more such terms lead without plain-language paraphrase, flag the response.

**This Plan's Absorption**: Iteration 001 T005 (governance checklist) and T006 (soft-validator concept) both explicitly codify and detect this pattern. Coordinator guidance in T001 and template in T002 enforce plain-language-first principle. Iteration 002 T007 implements the soft-validator check.

### validation-lane-completeness Concern Drift (Row 10, `.specrew/quality/known-traps.md`)

**Prevention**: Every hardening gate concern for `validation-lane-completeness` must document the exact authorized list of validation commands. Before sign-off, cross-check concern evidence against plan.md task definitions. If they differ, reconcile before proceeding.

**Application to Iteration 002**: T009 (validation lane update) must explicitly list the authorized soft-validator commands in both the hardening gate and the plan task definition, with documented human approval if the list changes.

---

## Unintended Artifact Cleanup

**Artifact to clean up**: `specs/007-user-facing-progress-handoff/iterations/001/plan.md`

**Status**: This file contains useful planning content that has been consolidated and expanded into this feature-level `plan.md`. The iterations/001/plan.md can be removed after this feature-level plan is reviewed and approved.

**Recommendation**: Delete `specs/007-user-facing-progress-handoff/iterations/001/plan.md` as part of the feature sign-off process (or during Iteration 001 task cleanup after implementation). Do not need to delete immediately; mark for cleanup after before-implement gate passes.

---

## Next Steps

1. **This plan is ready for Specrew `/speckit.plan` review**.
2. **Before-implement gate** will review Iteration 001 scope, traceability, and governance consistency.
3. **Upon approval**, Iteration 001 tasks (`T001`–`T006`) proceed in parallel and series as outlined above.
4. **Iteration 001 completion** → before-implement review checkpoint for handoff semantics and coordinator guidance.
5. **Upon checkpoint approval**, Iteration 002 planning begins for soft-validator implementation and integration tests.
