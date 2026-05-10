# Iteration 001 Hardening Gate

**Feature**: `specs/007-user-facing-progress-handoff`  
**Iteration**: 001  
**Schema**: v1 (Iteration 005 pre-sign-off enrichment)  
**Gate Type**: pre-implementation-hardening  
**Created**: 2026-05-14  
**Last Updated**: 2026-05-14

---

## Gate Summary

Iteration 001 Foundation & Governance carries Phase 1–2 coordinator guidance and agent documentation (T001–T006, 10 story_points) before soft-validator runtime implementation. This gate validates planning completeness and readiness for before-implement review.

---

## Overall Verdict

**Verdict**: 🟡 **READY FOR STRONGEST-AVAILABLE REVIEW**

All planning artifacts are complete and ready for human review. Implementation approval is pending review sign-off from strongest-available class.

| Field | Status |
|-------|--------|
| **Scope Authority** | ✅ PASS — Phase 1–2 only; soft-validator and integration tests explicitly deferred to Iteration 002 |
| **Traceability** | ✅ PASS — All six tasks traced to spec requirements and user stories |
| **Ownership** | ✅ PASS — Task owners aligned to Specrew roles |
| **Capacity** | ✅ PASS — 10/20 story_points (truthful slice with explicit deferrals) |
| **Execution Support** | ✅ PASS — Planning artifacts ready for review |

---

## Approval Record

| Field | Value |
|-------|--------|
| **Reviewed By** | *(pending human sign-off)* |
| **Reviewed At** | *(pending)* |
| **Approval Ref** | — *(no decision record required at planning stage; human review will determine approval reference)* |
| **Approval Status** | *(awaiting review)* |

---

## Five Canonical Concerns

### 1. Security Surface

**Status**: ✅ **NOT APPLICABLE**

**Rationale**: Iteration 001 Foundation contains no authentication boundaries, privilege checks, trust domain crossings, or user-controlled input paths. It updates coordinator prompt, agent guidance documents, and handoff templates only, with no new runtime code, state transitions, or external integrations.

**Evidence Basis**: Planning documentation; no security-scoped requirements in Iteration 001 scope

**Expected Controls**: None required pre-implementation

**Blocking**: No

---

### 2. Error-Handling Expectations

**Status**: ✅ **ADDRESSED**

**Planning Evidence**: 
- Coordinator prompt (T001) must explicitly guide agents to state progress even for read-only answers with no artifact work
- Handoff template (T002) must include patterns for fully complete factual answers where no follow-up is needed
- Decision guidance (T003) must cover verification-gap disclosure and graceful handling of edge cases

**Expected Controls**: 
- No runtime error paths exist in Iteration 001 (documentation only)
- Coordinator guidance must fail safely toward explicit handoff (progress + next-step) rather than silent omission

**Runtime Evidence Timing**: Not needed pre-implementation; documentation guidance is sufficient

**Blocking**: No

---

### 3. Retry & Idempotency Requirements

**Status**: ✅ **NOT APPLICABLE**

**Rationale**: Iteration 001 Foundation is purely documentation and prompt guidance. No idempotency concerns apply to coordinator prompt updates, handoff templates, or agent guidance documents.

**Evidence Basis**: Planning scope definition

**Expected Controls**: None required

**Blocking**: No

---

### 4. Test Integrity & Targets

**Status**: 🟡 **ADDRESSED** *(runtime evidence deferred to Iteration 002)*

**Planning Evidence**:
- Handoff template (T002) must include concrete examples for all three user stories (US1 completion, US2 blockers, US3 lightweight) and edge cases (read-only, fully complete, verification gaps)
- Soft-validator design (T006) must document test scenarios: (1) governance-jargon response (3+ acronyms in lead without paraphrase) → expect flag; (2) plain-language response → expect pass
- Coordinator decision guidance (T003) must provide decision trees for testing blocker disclosure and review-need clarity

**Expected Controls** *(Iteration 002)*:
- Integration tests must exercise handoff validator against synthetic governance-jargon responses (must flag) and plain-language responses (must pass)
- Test fixtures must validate all three user story patterns and edge cases
- Validation lane must register soft-validator in authorized-commands list with documented scope

**Runtime Evidence Timing**: Pending Iteration 002 when integration tests land

**Blocking**: No (but Iteration 002 implementation cannot proceed without clear test targets from this gate)

---

### 5. Operational Resilience & Durability

**Status**: ✅ **ADDRESSED**

**Planning Evidence**:
- Squad.agent.md (T004) must formally codify the three-section handoff format with explicit session-restart note
- Coordinator prompt (T001), handoff template (T002), and decision guidance (T003) must be maintainable and version-stable
- Governance checklist (T005) must reference known-traps.md and be human-reviewable without tool dependencies

**Expected Controls**:
- All documentation artifacts are stored in git and reviewable
- Session-restart requirement for Squad.agent.md changes is explicitly documented
- Coordinator guidance survives agent-instruction updates and session restarts

**Runtime Evidence Timing**: Not needed pre-implementation; documentation durability is sufficient

**Blocking**: No

---

## Feature-Specific Concerns

### Handoff-Semantics Correctness

**Status**: ✅ **ADDRESSED**

**Concern**: Coordinator prompt, handoff template, and decision guidance must correctly satisfy all three user stories (US1 clear completion, US2 blockers/review needs, US3 lightweight fluency) and map to FR-001 through FR-015.

**Planning Evidence**:
- Requirements Traceability table in iterations/001/plan.md maps all six tasks to spec requirements and user stories
- T001 (coordinator prompt) covers FR-001–FR-007, FR-012–FR-013
- T002 (handoff template) covers US1, US2, US3 patterns with three-section format
- T003 (decision guidance) covers FR-008–FR-011 (review, manual test, verification gap, blocked-vs-continue)
- T004 (Squad.agent.md) covers FR-013–FR-014 (final response ownership and durable rollout)
- T005 (governance checklist) covers FR-005–FR-006, FR-016 (open issues, actionable next step, soft quality warning)
- T006 (soft-validator design) covers FR-016 and formal concept completeness

**Expected Controls**: Each artifact must be reviewed by strongest-available class to verify semantics align with spec

**Runtime Evidence Timing**: Human review is the control; implementation proceeds only after approval

**Blocking**: No, pending review approval

---

### Governance-Acronym Rule Absorption

**Status**: ✅ **ADDRESSED**

**Concern**: Coordinator prompt and handoff templates must explicitly absorb the human-handoff trap detection rule (three-or-more governance acronyms in lead without plain-language paraphrase). Agents must understand this constraint during response generation, not discover it only in post-validation.

**Planning Evidence**:
- Known-traps.md reference (row 12, 2026-05-10) is formally integrated into Feature 007 plan and tasks
- T001 (coordinator prompt) explicitly instructs agents to use plain-language lead and defer governance vocabulary to subsections or footnotes
- T002 (handoff template) examples demonstrate plain-language-first pattern (e.g., "We need three decisions before moving forward: (1) ..., (2) ..., (3) .... [formal references: before-implement gate, hardening-gate sign-off, ...]")
- T005 (governance checklist) documents the detection rule: "Scan lead sentence for three-or-more governance acronyms or schema-field names without plain-language paraphrase and flag"
- T006 (soft-validator design) formalizes the detection method and provides pseudo-code for Iteration 002 implementer

**Expected Controls**: 
- Coordinator prompt examples must show plain-language lead
- Handoff template examples must use same pattern
- Soft-validator design must provide operationalizable detection rule

**Runtime Evidence Timing**: Coordinator guidance effectiveness validated in Iteration 002 through sampled Squad completions and soft-validator flagging

**Blocking**: No, but coordinator guidance examples must pass this pattern check before implementation approval

---

### Agent-Guidance Durability

**Status**: ✅ **ADDRESSED**

**Concern**: Squad.agent.md codification must formally codify the three-section handoff format and include a session-restart note. Guidance must survive future agent updates and be reviewable by strongest-available class.

**Planning Evidence**:
- T004 explicitly updates `.github/agents/squad.agent.md` with formal three-section format: "What I just did / Why I stopped / What I need from you"
- Session-restart note is explicitly required to be included with the update
- Guidance location is in Team Mode section, which typically survives agent-instruction version rolls

**Expected Controls**:
- Session-restart note must be clearly visible and accessible
- Guidance must be placed in a durable section of Squad.agent.md
- Change log or version note must document this critical update

**Runtime Evidence Timing**: Implementation approval must include explicit sign-off on session-restart requirement

**Blocking**: No, but missing session-restart note blocks approval until added

---

### Governance Integration Readiness

**Status**: ✅ **ADDRESSED**

**Concern**: Planning documents governance integration (T005 checklist surface, T006 soft-validator design) must define soft-warning logic, integration points for iteration 002, and traceability to known-traps corpus.

**Planning Evidence**:
- T005 (governance checklist) specifies soft-warning logic: "Not hard-blocking; flag missing fields without blocking response delivery"
- T005 references governance-acronym rule and known-traps.md
- T006 (soft-validator design) documents soft-validator integration points: post-response coordinator output, governance surface registration
- T006 specifies no hard-blocking behavior: "Soft validator MUST flag missing fields without blocking response delivery"
- Integration points are explicitly deferred to Iteration 002 but design is complete

**Expected Controls**:
- Governance checklist is human-reviewable and operationalizable
- Soft-validator design provides clear implementation target with no ambiguity
- Known-traps corpus alignment is explicit

**Runtime Evidence Timing**: Pending Iteration 002 implementation; design clarity is pre-implementation gate

**Blocking**: No, pending soft-validator design review

---

### Validation-Lane Completeness

**Status**: 🟡 **ADDRESSED** *(runtime evidence deferred to Iteration 002)*

**Concern**: Planning documents validation-lane scope for Iteration 002 (T007–T009) must deliver authorized validation command set for handoff soft-validator coverage. Before Iteration 002 sign-off, validation must confirm governance-acronym detection rule, plain-language scoring, and edge-case handling.

**Planning Evidence**:
- T006 (soft-validator design) specifies the detection rule: "three-or-more governance acronyms in lead without plain-language paraphrase"
- T006 documents five core validation scenarios: (1) jargon-response flag, (2) plain-language-response pass, (3) lightweight-response fluency, (4) fully-complete-answer no-further-action, (5) verification-gap disclosure
- T009 (validation lane update) is explicitly tasked with registering soft-validator in authorized-commands list with documented scope

**Expected Controls** *(Iteration 002)*:
- Exact authorized list of validation commands must be documented in both validation-lane task definition and hardening-gate concern evidence
- Before Iteration 002 sign-off, cross-check concern evidence against plan.md T009 definition to prevent validation-lane-completeness drift (known-traps.md row 10)

**Runtime Evidence Timing**: Pending Iteration 002 when soft-validator lands and validation lane is updated

**Blocking**: No (but Iteration 002 sign-off cannot proceed without tight validation-lane alignment)

---

## Sign-Off Readiness Checklist

### Pre-Review

- ✅ **Scope locked**: Iteration 001 = Phase 1 + Phase 2 (T001–T006); Iteration 002 = Phase 3 (T007–T010)
- ✅ **Traceability complete**: All six tasks mapped to spec requirements and user stories
- ✅ **Planning artifacts complete**: plan.md, state.md, drift-log.md, and this hardening-gate.md created
- ✅ **Known-traps integration**: human-handoff trap formally referenced in coordinator guidance and soft-validator design

### For Reviewers

- [ ] **Handoff-semantics correctness**: Review T001 coordinator prompt, T002 handoff template, T003 decision guidance for completeness across US1, US2, US3
- [ ] **Coordinator-guidance clarity**: Verify prompt examples show plain-language lead with governance vocabulary deferred
- [ ] **Soft-validator design clarity**: Verify T006 design document provides pseudo-code or clear algorithmic definition of three-or-more-governance-acronyms detection
- [ ] **Squad.agent.md durability**: Verify T004 includes explicit session-restart note and formal three-section handoff format
- [ ] **Governance integration**: Verify T005 governance checklist is operationalizable and references known-traps corpus
- [ ] **Traceability audit**: Spot-check 2–3 tasks to confirm requirements mapping is accurate

### For Implementation Approval

- [ ] All reviewer checks passed
- [ ] Coordinator prompt and template examples meet plain-language-first standard
- [ ] Soft-validator concept design is unambiguous for Iteration 002 implementer
- [ ] Squad.agent.md update includes session-restart note
- [ ] No governance-acronym violations in planning artifacts themselves
- [ ] Human approval reference recorded (from `.squad/decisions.md` if applicable)

---

## Post-Gate Handoff

### To Implementer (Upon Approval)

1. Execute Iteration 001 tasks in planned order: Phase 1 (`T001`/`T002` parallel) → Phase 2 serial (`T003`/`T004`) → Phase 2 parallel (`T005`/`T006`)
2. Follow reviewer comments on prompt clarity, template patterns, and soft-validator design
3. Flag any governance-acronym patterns discovered during implementation for immediate rewrite
4. Stop at T006; do not start T007 soft-validator implementation in this iteration
5. Before-implement review checkpoint occurs after all Phase 2 tasks complete

### To Next Iteration

1. Iteration 002 planning begins after Iteration 001 before-implement review approval
2. Soft-validator implementation (T007) depends on T006 design completeness
3. Integration test fixtures (T008) depend on T002 handoff template examples
4. Validation lane updates (T009) must cross-check authorized commands against T007 and this hardening gate
5. Iteration 002 hardening gate must confirm validation-lane-completeness and test-integrity-targets with runtime evidence

---

## Governance Notes

- **Known Precedent**: Feature 008 Iteration 001 scaffolding (2026-05-09) followed similar pattern with plan.md, state.md, drift-log.md, and hardening-gate.md structure
- **Quality Profile**: `quality-profile.custom-composition.v1` — Markdown documentation, coordinator prompt, agent guidance codification
- **Drift Signals Tracked**: See drift-log.md for full monitoring scope
- **Feature Steward**: Alon Fliess (requesting maintainer and reviewer of user-facing handoff contract)
