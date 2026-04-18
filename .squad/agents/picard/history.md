# Project Context

- **Owner:** Alon
- **Project:** Specrew
- **Stack:** Markdown, YAML, PowerShell, Spec Kit extension assets, Squad extension structure
- **Description:** A spec-governed AI crew operating model built as a monorepo with companion Spec Kit and Squad extensions.
- **Created:** 2026-04-17

## Core Context

I am the spec alignment gate for Specrew. My job is to keep every plan, task, decision, and implementation traceable to the authoritative source requirements.

**Authority Foundation** (Iteration 0):
- Iteration lifecycle is **normative and binding** (spec.md, contracts/iteration-artifacts.md)
- Four-phase state machine: Planning → Execution → Review/Demo → Retrospective (enforced by validator)
- Dogfooding obligation: Specrew must follow its own iteration lifecycle (binding per spec.md)
- Single Coordinator Protocol (`.squad/protocol.md` v1.0): 6 roles, decision workflows, escalation paths
- Governance validator deployed (`.squad/agents/scribe/scripts/validate-governance.ps1`) and operational at CI gates
- Iteration 0 closure: Complete (2026-04-18), Alon sign-off recorded, all closure artifacts aligned, validator PASS

**Recent Work** (2026-04-18–04-19):
- ✅ Closure artifact drift remediation: Updated review.md, state.md, retro.md to clear stale "pending sign-off" language after Alon recorded final sign-off
- ✅ Governance validation: All phase gates pass; state machine enforcement ready for Iteration 1
- ✅ Operating policy: 6 core rules + 3 tier-1 improvements identified for team consensus before Iteration 1

## Learnings

- Phase state machine is **normative** — not optional governance. Skipping phases is a contract violation.
- Dogfooding is binding: Specrew must follow its own iteration lifecycle for its own development.
- Phase gates prevent drift: spec-authority gate (pre-execute), traceability gate (pre-execute), drift-check (per-task), review gate (end-execute).
- Completion semantics must stay single-purpose: `retro.md` closes retrospective, but iteration status remains `retro` until Alon records final sign-off.
- Closure evidence tables must be regenerated at sign-off time, not copied from draft versions (prevents stale claims).

### 2026-04-18T18-30-00Z: Closure Artifact Signoff Drift Remediation

**Task**: La Forge readiness pass found blocker — review.md and state.md contained stale "pending sign-off" language even though Iteration 000 status was already `complete` in plan.md with Alon's final sign-off recorded.

**Root Cause**: Artifacts were finalized before Alon's sign-off was formally recorded in all closure documents. Language like "pending Alon sign-off" contradicted the actual iteration state when validator checked consistency.

**Fix Applied** (7 edits across 3 artifacts):
1. **review.md line 16**: Changed "Final iteration completion pending Alon sign-off" → "Alon final sign-off recorded (2026-04-18)"
2. **review.md line 233**: Updated closure evidence table to reflect actual plan.md status = `complete` (not `retro`)
3. **review.md line 237**: Changed "final completion still awaits Alon sign-off" → "Alon final sign-off recorded (2026-04-18)"
4. **review.md line 256**: Changed "Final iteration completion remains pending Alon sign-off" → "Alon final sign-off recorded (2026-04-18)"
5. **state.md line 18**: Changed "Iteration closure remains pending Alon sign-off" → "Iteration closure complete with Alon final sign-off recorded (2026-04-18)"
6. **retro.md line 149**: Removed blocking sense; restated as fact: "Retrospective completed same-day; Alon's final sign-off was recorded (2026-04-18)"
7. **retro.md line 330**: Changed section header from "Remaining External Dependency" (future tense) to "Closure Gate" with ✅ verdict

**Validator Result**: ✅ **PASS** — `validate-governance.ps1` confirms no stale post-signoff language remains; all closure evidence aligns with plan.md state=`complete`.

**Pattern Insight**: Closure artifacts containing *evidence tables* (validation gates claiming to verify metadata) become stale if written before final sign-off is recorded everywhere. Must regenerate closure evidence at sign-off time, not copy from draft versions. Recommend template guidance for future iterations: "Closure evidence MUST be regenerated from current artifacts when final sign-off is recorded, not carried forward from drafts."

**Traceability**: Fix ensures iteration-artifacts.md § Complete phase gate is satisfied: "Alon MUST record final sign-off" ✅ Done and reflected across all closure documents.

### 2026-04-18T18-50-28Z: Iteration 000 Closeout Session Update

**Session**: Scribe Handoff Log — Iteration 000 Complete, Iteration 001 Planning-Ready  
**Update**: Final sign-off recorded, governance hardening authority BINDING, Iteration 1 prerequisites clear

**Key Facts**:
- ✅ Alon final sign-off officially recorded (2026-04-18T18:15:45Z) — plan.md Status transitioned from `retro` → `complete`
- ✅ Post-signoff drift cleared (2026-04-18T18:30:00Z) — all closure language updated to past-tense confirmation
- ✅ Validator passes cleanly — no blocking issues remain
- ✅ Governance hardening authority now BINDING and enforced at CI gates
- ✅ Four authority artifacts live: spec.md, contracts/iteration-artifacts.md, .squad/protocol.md, validate-governance.ps1
- ✅ Iteration 001 planning-ready state confirmed — execution-ready plan present (Data created specs/001-specrew-product/iterations/001/plan.md)
- ⏳ Next gate: Alon approval of Iteration 001 plan + team consensus on operating policy (6 rules + 3 tier-1 improvements) before planning ceremony

**Role Note**: Spec Steward remains the authority for phase-contract enforcement and traceability validation. All Iteration 1+ work will follow binding four-phase state machine with automatic phase gate validation.

---

### 2026-04-18: Iteration 0 Completion & Governance Hardening Analysis

**Iteration 0 Verdict**: ✅ COMPLETE (100%, 0 drift events, all spikes passed)
- 23/23 tasks delivered (20.5/20.5 story points, zero variance)
- All 9 platform validation spikes PASS — Spec Kit 0.7.3 and Squad 0.9.1 compatible
- Critical discovery: Squad-native surfaces architecture (skills, ceremonies, directives) refined mid-execution (T-017); architecture documented and decision properly routed
- Iteration 0 acceptance gate cleared by Worf (Reviewer); awaiting Alon sign-off before Iteration 1 begins

**Governance Readiness Assessment**: Foundation iteration proved governance works at precondition-only scope. MVP (Iteration 1) will expose governance gaps at higher complexity.

**Six Normative Hardening Findings**:
1. **Artifact Contracts** — Currently prose documentation; recommend schema validators at ceremony gates (Deferred to Iter 2)
2. **Iteration State Machine** — Currently semantic; recommend runtime validator blocking phase skips (BLOCKING for Iter 1)
3. **Dogfooding Governance** — Currently implicit; recommend normative directive formalizing internal compliance (BLOCKING for Iter 1)
4. **Governance Validator Skill** — No batch traceability check at Review gate; recommend governance-validator skill for Iter 1 (BLOCKING for MVP)
5. **Methodology Runtime Config** — Currently text documentation; recommend `.specrew/methodology.yml` encoding phases/rules (NON-BLOCKING but enables validator)
6. **Coordinator Protocol** — Role responsibilities scattered; recommend `.squad/coordinator.md` centralizing handoffs (BLOCKING for Iter 1)

**Recommended Actions Before Iteration 1 Planning**:
- Accept 6 hardening recommendations (defer artifact schemas to Iter 2)
- Create pre-implementation artifacts: methodology.yml, coordinator.md, schema definitions
- Make state machine, dogfooding directive, governance-validator skill, coordinator integration TIER 0 (blocking) tasks in Iter 1 plan
- Estimate ~6 pts for hardening tasks; feature delivery capacity ~14 pts (with reasonable overcommit approval)

**Documentation**: Detailed recommendation written to `.squad/decisions/inbox/picard-governance-hardening.md`

**Key Insight**: Drift becomes mechanically harder to hide when: (1) artifact contracts are schema-validated at gates, (2) ceremony phase transitions are enforced, (3) governance validator runs before Review concludes, (4) role handoff gates are explicit, (5) dogfooding obligation is binding. Iteration 0 manual discipline scales to Iteration 1+ automation.

---

## Cross-Agent Team Update (2026-04-18T15:54:58Z)

**Picard receives inputs from team**:

- **Worf (Reviewer)**: Iteration 0 closure audit found 3 critical blockers (missing state.md, drift-log.md, retro.md). Artifact completeness gates must enforce phase sequencing. Picard is embedded in planning ceremony for spec-authority gate (Rule 1 of operating hardening).

- **Troi (Retro Facilitator)**: Operating hardening policy prescribes Picard as spec-authority gatekeeper at planning ceremony (pre-execution gate before task assignment). Picard also partners with La Forge for pre-planning architecture-risk spikes (planning prerequisite). Implementation checklist has immediate adoption steps.

- **User Directive**: Governance hardening is TIER 0 before Iteration 1 planning. Normative rules (operating policy) + artifact validators (governance-validator skill) + explicit protocols (coordinator.md) are blocking.

**Picard action items from team**:
1. Embed spec-authority gate logic into planning ceremony (yes/no gate: all tasks trace? all FRs covered?)
2. Identify Iteration 1 architecture-risk spikes before planning ceremony
3. Partner with La Forge on pre-planning spike session (2–4 hours, before planning ceremony)
4. Integrate traceability-check skill into planning ceremony gate sequence
5. Confirm Rules 1, 2, 3 (spec-authority, architecture spikes, traceability) are team consensus before Iteration 1 planning starts

### 2026-04-18: Governance Hardening Implementation - Phase 1 (Authoritative Artifacts)

**Status**: ✅ COMPLETE

**Four Governance Artifacts Updated/Created**:
1. **spec.md** — Added normative "Iteration Lifecycle Contract" section (phase state machine binding) + "Dogfooding Obligation" (Specrew must use Specrew)
2. **contracts/iteration-artifacts.md** — Made phase state machine explicit with validation gates per phase; artifact production table; abandoned iteration rule
3. **Created `.squad/protocol.md`** — Single coordinator protocol: role responsibilities (6 roles), decision-making workflow (routine/tracked/escalation), iteration coordination (4-phase sequence), 6 operating rules, conflict resolution, escalation summary
4. **`.squad/decisions/inbox/picard-governance-hardening-implementation.md`** — Decision record documenting all changes and alignment with architecture

**Scope Addressed**:
- ✅ Lifecycle contract is now normative (binding, not guidance)
- ✅ Phase state machine restated as operating rule (in spec + protocol)
- ✅ Dogfooding obligations clarified (Specrew follows Specrew)
- ✅ Single coordinator protocol document created

**Deferred to Iteration 1**:
- Governance-validator skill (enforces state machine at gates)
- `.specrew/methodology.yml` (runtime config)

**Key Insight**: Authority now precedes validation. The binding rules (spec.md) and coordination protocol (.squad/protocol.md) are in place. The validator skill will enforce these rules automatically in Iteration 1. Iteration 0 closure artifacts can now be created using the normative contracts.

---

- **Spec scope from TG-003**: Iteration 0 = FR-001 (two-package architecture) + FR-013 (extension surfaces only). MVP (Iteration 1) = FR-002–FR-006, FR-008–FR-011, FR-018. Deferred iterations 2–3 per phased plan § 14.
- **Key insight**: Iteration 0 is precondition-critical. Must be completed and de-risked before MVP can begin. All feature implementation (bootstrap, ceremonies, skills) deferred to Iter 1.
- **Platform risks**: Two critical-path spikes that may require tracked changes if results are negative: (1) Squad post-task hook availability (Spike 4 — affects FR-008 implementation path); (2) Spec Kit `specify extension add` command (Spike 9 — affects `specrew init` script). Both are within Iter 0; results drive Iter 1 re-planning if needed.
- **Effort scoping**: Original plan 23 pts; capacity 20 pts. Deferred Spikes 6–7 (GitHub Projects API, local dev cycle) to reduce to 20 pts. Rationale: GitHub Projects is operational concern, not architectural blocker; local dev cycle is developer productivity, not customer-facing.
- **Traceability discipline**: Every task in Iteration 0 plan maps to at least one FR. No orphan tasks. Three categories: (1) FR-001 tasks (repo + extension skeletons), (2) FR-013 tasks (platform validation), (3) Support/infrastructure (CI, board).
- **Contingency planning**: Plan § Risk Mitigation explicitly flags overcommit decision and spike contingencies. Plan § Known Drift / Ambiguities documents what is pending vs. resolved.
- **Decision routing**: Decisions that affect downstream specs (Iter 1 plan, FR refinements) are routed to Alon via tracked change process rather than auto-resolved.
- **File paths**: Iteration 0 plan stored at `specs/001-specrew-product/iterations/000/plan.md` (zero-indexed, not `001/`). Decision merged to decisions.md on 2026-04-17T19:00:43Z.
- **Pattern**: This first iteration plan establishes the ceremony structure: Planning phase produces task list + effort estimates + traceability. Review/demo gate verifies completion. Retro captures learnings (esp. spike results driving Iter 1 changes).

### 2026-04-18T13-30-34Z: Governance Hardening Implementation Merged to Decisions

**Status**: ✅ DECIDED & MERGED

**Scribe Summary**: Picard's governance hardening implementation decision merged into `.squad/decisions.md` under "2026-04-18: Governance Hardening Implementation". Three-part implementation completed:

1. **spec.md**: Normative lifecycle contract + dogfooding obligation (binding rules for all iterations)
2. **contracts/iteration-artifacts.md**: Explicit state machine, phase rules, artifact gates
3. **.squad/protocol.md**: Single source of truth for roles (6 roles), decision workflows, iteration coordination (4-phase sequence), 6 operating rules, escalation paths

**Governance Scope vs. Implementation Roadmap**:
- ✅ **Iter 0 (Completed)**: Artifact contracts, state machine normative, dogfooding binding, coordinator protocol
- ⏳ **Iter 1 (Deferred)**: Governance-validator skill (FR-008), methodology.yml runtime config

**Implications for Iteration 1**:
- Phase state machine now has binding authority (not optional guidance); Iteration 1 plan cannot skip phases
- Dogfooding obligation means Iteration 1 tasks must be traceable to FRs (same discipline as downstream customers)
- .squad/protocol.md defines Picard's embedding in planning ceremony for spec-authority pre-gate (Rule 1)
- Architecture-risk spikes must be identified and run pre-planning (Rule 2); Picard + La Forge partnership required before each planning ceremony

**Cross-Agent Update**: Team consensus on 6 core operating rules must be confirmed by Troi + Alon before Iteration 1 planning. Picard participates in confirm-or-escalate pattern (spec authority is non-delegable).

---

## Learnings

### 2026-04-18: Review Evidence Correctness & Closure Semantics

**Task**: Fix stale closure evidence in review.md (Iteration 0 review incorrectly claimed plan.md status=complete and Completed=2026-04-18 when actual state was status=retro, Completed=blank).

**Discovery**: Review artifact had snapshot-stale closure evidence. Contract gate (iteration-artifacts.md § Artifact Validation Gates) specifies that "before completing" requires Alon sign-off to transition from `retro` to `complete`. Review.md contained False evidence contradicting the actual plan.md semantics.

**Fix Applied**:
- Updated line 230: Changed false claim "Line 4 currently reads Status: complete" to accurate "Line 5 currently reads Status: retro"
- Updated line 231: Changed false claim "Completed: 2026-04-18" to accurate "Completed: (blank, recorded after Alon sign-off)"

**Key Insight**: Review artifacts that contain *evidence tables* (verification gates that claim to validate metadata) can become stale if they were written before execution completed. Must regenerate closure readiness verification after all phase artifacts are finalized, not copy from earlier review drafts. 

**Pattern**: Closure evidence (artifact validation table) must be regenerated at **Final Gate Validation** phase, not carried forward. Recommend template guidance for review.md authors: "Closure readiness table MUST be regenerated from current artifacts at review-complete time, not copied from draft versions."

**Implication for Iteration 1**: Review ceremony must include step to validate that all closure evidence references match actual artifact state. Picard to flag during review ceremony if evidence contradicts actual metadata.

### 2026-04-18T18-00-00Z: Orchestration Complete — Closure Evidence Fix

**Session**: Reviewer-Drift Cleanup Batch  
**Status**: ✅ COMPLETE  

Stale closure evidence discovered and corrected in review.md. False claims about plan.md metadata prevented through evidence-table regeneration at final gate time. Pattern documented for Iteration 1 review ceremony template improvement.

**Decision**: picard-closure-evidence-fix (merged to .squad/decisions.md)  
**Impact**: Critical — prevents false sign-off signals  
**Next**: Closure-evidence regeneration checkpoint added to Iteration 1 review ceremony template

### 2026-04-18T18-15-45Z: Alon Final Sign-Off Recorded — Iteration 0 Closure Complete

**Action**: Record Alon's final governance authority sign-off in all iteration closure artifacts.

**Artifacts Updated**:
1. ✅ **plan.md**: Status transitioned from `retro` → `complete`; Completed date recorded (2026-04-18)
2. ✅ **state.md**: Current Phase transitioned to `complete`; Final Sign-Off recorded with explicit attribution (Alon, 2026-04-18)
3. ✅ **review.md**: Verdict Summary updated to reflect `complete` status; Sign-Off Checklist appended with Alon final sign-off; removed pending language
4. ✅ **retro.md**: Sign-Off section updated to record Alon's final governance authority approval
5. ✅ **.squad/identity/now.md**: Focus area updated to reflect Iteration 0 complete; active issues shifted to Iteration 1 prerequisites

**Closure Semantics Verified**:
- Spec contract (iteration-artifacts.md) gate logic: "Before completing: `retro.md` MUST exist with all mandatory fields, and Alon MUST record final sign-off"
- ✅ retro.md exists and is complete
- ✅ Alon final sign-off recorded across all artifacts
- ✅ Iteration 0 moved to terminal `complete` state
- ✅ All four phase artifacts (plan, state, review, retro) are consistent and terminal

**Wording Precision**:
- Used "final governance authority sign-off" (not "pending" or "provisional")
- Recorded explicit date stamp (2026-04-18) for accountability
- Noted Chief Architect & Reviewer role for clarity on authority

**Traceability**:
- Iteration 0 closure ties to spec requirement: "Completion gate = Alon must record final sign-off" (contracts/iteration-artifacts.md § Complete phase)
- Dogfooding obligation satisfied: Specrew used its own governance lifecycle for Iteration 0 (binding proof for Iteration 1+)

**Key Insight**: Closure semantics require precision about *what* is being signed off: governance authority approval (Alon records this), not just task completion verdicts (Worf records these). Sign-off is a separate, deliberate act that gates the state-machine transition to `complete`. Capturing the distinction in artifacts prevents ambiguity in future iterations.

**Implication for Iteration 1**:
- Sign-off is now a normative part of iteration closure (not optional)
- Review and retro are separate phases that close independently; sign-off is a third gate
- Iteration 1 planning ceremony charter must embed the understanding that *any iteration* cannot move to `complete` without Alon's final recorded sign-off

### 2026-04-18: GitHub Projects V2 Source-of-Truth Governance — Specrew Self-Development

**Task**: Encode Alon's authoritative source-of-truth correction for GitHub Projects V2 board management into spec.md, protocol.md, and decision records.

**Problem Addressed**: Previous design decisions left board synchronization ambiguous — manual management accepted as sufficient, automation left deferred, downstream projects left unclassified.

**Correction Implemented**:

1. **Normative Rule for Specrew**: GitHub Projects V2 board MUST be used for self-development
   - Local task artifacts (plan.md, iteration state) are authoritative source of truth
   - GitHub Issues and Project board items are derived operational mirrors
   - Squad is responsible for board sync and maintenance (automation primary, manual fallback-only)
   - If automation fails, capability gap MUST be recorded (not silently downgraded)

2. **Downstream Projects**: MAY choose whether to use GitHub Projects V2 (no mandate)
   - Choice of authoritative source is up to downstream project
   - If board is used, follow Squad automation model as reference

3. **Artifacts Updated**:
   - **spec.md** Clarifications (Q&A 38): Changed from "optional choice" to "normative requirement"
   - **spec.md** Clarifications (Q&A 43): Squad automation is primary, manual mgmt fallback-only
   - **spec.md** Design Decisions: Updated GitHub Projects board paragraphs with explicit rules
   - **spec.md** Design Decisions: Updated source-of-truth paragraph (local artifacts authoritative, GitHub Issues derived)
   - **.squad/protocol.md** New Section: "GitHub Projects V2 Board Synchronization & Maintenance" with:
     - Source-of-truth rule (authoritative vs. derived)
     - Squad automation responsibilities (phase-by-phase action table)
     - Acceptance criteria (6 criteria for board sync)
     - Fallback procedure (automation failure recording)
   - **.squad/protocol.md** Implementation Notes: Added AC-001 through AC-004 for Specrew acceptance criteria
   - **.squad/decisions/inbox/picard-board-sot.md**: Decision record documenting all changes

**Implications for Iteration 1**:
- Before Iteration 1 planning can approve plan: Squad automation for issue creation must be designed/validated (Spike 10 or equivalent)
- Board column mapping must be confirmed (planning ↔ Backlog, executing ↔ In Progress, reviewing ↔ In Review, retro ↔ Retrospective, complete ↔ Closed)
- Fallback procedure must be accessible and documented
- Iteration 1 cannot move to `complete` without all AC-001–AC-004 verified
- If automation fails, capability gap recorded in decisions inbox with resolution path

**Pattern Insight**: Ambiguous downstream rules leak into self-development discipline. By encoding the corrected source-of-truth as normative (not optional) for Specrew self-development, while explicitly MAY-ing it for downstream, we model clarity. The board is a derived operational mirror, not a primary source — this distinction protects against task drift hidden in board-only updates.

**Traceability**: Decision recorded in `.squad/decisions/inbox/picard-board-sot.md` for Alon review before Iteration 1 planning.

### 2026-04-18: Plan.md Board-Usage Drift Remediation (Worf Review Fix)

**Task**: Worf issued NEEDS-WORK on `specs\001-specrew-product\plan.md` because Section 9 and Iteration 0 deliverables table still stated board/issue usage as "optional" for Specrew, contradicting the corrected spec and protocol.

**Root Cause**: Plan.md was authored before the normative source-of-truth correction (board MUST be used, not MAY be used, for Specrew self-development). The phrase "Issue tracking (optional)" and "Project board (optional)" remained in the plan even after spec.md and protocol.md were corrected.

**Drift Evidence** (from Worf review):
- Section 9 line: "Issue tracking (optional): GitHub Issues are *optionally* created..."
- Section 9 line: "Project board (optional): GitHub Projects V2 may be used for visibility if the team chooses"
- Iteration 0 deliverables table: "GitHub Project board (optional)"

All three contradicted the corrected rule: **Specrew self-development MUST use GitHub Projects V2 as a derived operational mirror maintained by Squad.**

**Fix Applied** (2 edits to plan.md):

1. **Section 9 (GitHub Workflow for Specrew Development)** — Lines 360–376:
   - Removed "(optional)" labels and discretionary framing
   - Restated board usage as REQUIRED for Specrew: "GitHub Issues are created from plan tasks and synchronized to GitHub Projects V2 board"
   - Clarified Squad responsibility: "Squad is responsible for creating, populating, and maintaining the board as a derived operational mirror from local artifacts"
   - Clarified distinction: "Manual board management is fallback-only if automation fails; capability gaps or blockers must be recorded, not silently downgraded to manual management"
   - Added explicit downstream carve-out: "Downstream projects MAY opt in or out of GitHub Projects board usage. Downstream projects retain choice of authority model..."

2. **Iteration 0 Deliverables Table** — Line 521:
   - Changed "GitHub Project board (optional)" to "GitHub Project board"
   - Changed description from "If used for visibility..." to normative: "GitHub Projects V2 board created and synced from iteration artifacts via automation"

**Validator Result**: ✅ **PASS** — Plan.md no longer contradicts spec.md or protocol.md. Board usage is now clearly marked as REQUIRED for Specrew self-development, with explicit MAY carve-out for downstream projects.

**Key Insight**: Governance drift at the planning artifact level surfaces when upstream (spec) corrects a rule but downstream (plan, tasks) is not automatically refreshed. Plan.md was correct in intent (local artifacts are authoritative) but incorrect in scope (saying board was optional when it was actually required). Remediation required explicit re-alignment with the source spec, not just cascade-down automation. Future reviews should verify that all three layers (spec, plan, tasks) use the same language for governance rules (MUST vs. MAY).

**Traceability**: Fix aligns `plan.md` with:
- `spec.md` § Clarifications (GitHub Projects V2): "Specrew's own development MUST use GitHub Projects V2"
- `.squad/protocol.md` § Iteration Coordination: "board is a derived operational mirror, manual board management is never normal"
- `docs/github-project.md` § Overview: "GitHub Issues and Project items are synchronized from local artifacts for visibility, but they are not the authoritative source"

**Decision**: No team-relevant decision required. This is a straightforward drift remediation (one agent fixing drift from another agent's prior work). Documented in this history entry for audit trail.
