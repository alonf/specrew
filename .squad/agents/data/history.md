# Project Context

- **Owner:** Alon
- **Project:** Specrew
- **Stack:** Markdown, YAML, PowerShell, Spec Kit extension assets, Squad extension structure
- **Description:** A spec-governed AI crew operating model built as a monorepo with companion Spec Kit and Squad extensions.
- **Created:** 2026-04-17

## Core Context

I turn Specrew's requirements into iteration plans, task maps, and explicit dependencies while preserving traceability back to the source spec.

## Recent Updates

📌 Team confirmed by Alon on 2026-04-17

## Learnings

- Planning is the first ceremony in the Specrew lifecycle.
- Plans must map tasks back to requirements, with owners and effort estimates.
- v1 is Markdown-first and centered on extension assets rather than runtime code.
- Alon provides final architectural direction when requirements need interpretation.

### 2026-04-17: Plan Revision (Iteration 0)

- **Overcommit math**: Effort totals must be verified bi-directionally (sum of tasks = total). When overcommit occurs, defer lowest-priority work (not base requirements). Foundation iterations may exceed capacity for precondition-critical de-risking, but must be justified and tracked.
- **Acceptance criteria consistency**: AC gates must align with deferred work. If spikes are deferred, call them out explicitly in the AC. No ambiguity about what "complete" means.
- **Self-approval antipattern**: Roles should not pre-approve work outside their ownership. Spec Steward validates spec authority; Chief Architect gates approval. Sequence matters.
- **Traceability with enabling tasks**: Direct tasks (those that deliver a FR) differ from supporting tasks (those that enable a direct task). Both must be traceable, but the distinction clarifies dependencies. Use "Enabling Support" column to document which support tasks unblock which FRs.
- **Constitution checks are plan gates**: Specrew's own governance model (spec authority, traceability, ownership, capacity, drift, verification) must be applied to Specrew's own plans. This is not post-hoc validation — it's part of plan design.
- **Avoid calendrical assumptions**: AI crew estimates use story points, not wall-clock hours/days. Parallelization is noted; actual elapsed time depends on crew latency and verification feedback. Do not promise "3 days" for effort-estimated work.
- **Iteration naming is a convention, not a code change**: Clarify it in metadata rather than inventing new directory structures. Zero-indexing is the pattern; document it once in the design spec, then reference in plans.
- **Deferred work is not removed scope**: When spikes are moved to Iter 1 async, track them as deferred (not cancelled). They're still project work — just sequenced differently.

### 2026-04-17: Iteration 0 Plan Revision Complete

- All seven review findings resolved and integrated.
- Plan returned to "pending approval" state; Alon (Chief Architect) gate next.
- Decision merged to decisions.md; inbox file deleted.
- Orchestration log and session log written.

## Learnings

### 2026-04-18T18-50-28Z: Iteration 001 Plan & Iteration 000 Closeout Session Update

**Session**: Scribe Handoff Log — Iteration 000 Complete, Iteration 001 Planning-Ready  
**Update**: Iteration 001 execution-ready plan created; team handoff complete; governance hardening authority BINDING

**Key Facts**:
- ✅ Iteration 001 plan created (specs/001-specrew-product/iterations/001/plan.md) — execution-ready and awaiting Alon approval
- ✅ Iteration 000 final sign-off officially recorded (2026-04-18T18:15:45Z) — Alon's final approval now canonical
- ✅ All closure artifacts verified terminal and consistent (plan.md, state.md, review.md, retro.md)
- ✅ Governance hardening BINDING — four-phase state machine now enforced at CI gates for all future iterations
- ✅ Operating policy (6 rules + 3 tier-1 improvements) proposed awaiting team consensus
- ✅ Planning ceremony charter ready to finalize (pending Picard pre-ceremony spike identification)

**Role Note**: Planner role remains authorization point for capacity math, effort estimation, and task traceability. Iteration 001 planning ceremony will enforce pre-execution gates (spec-authority, traceability check) before task assignment.

---

### 2026-04-18: Iteration 0 Closeout — Planning Side

**Context**: Iteration 0 execution completed with 100% task delivery (20.5/20.5 pts, zero drift). Review accepted. Retrospective phase blocked on missing state artifacts. Alon directed me to close iteration correctly.

**Actions**:
- ✅ Verified state.md exists (was already created by La Forge during execution)
- ✅ Created drift-log.md (0 events; per contract requirement)
- ✅ Updated plan.md metadata: Status → `complete`, Capacity → `20.5/20.5`, Completed → `2026-04-18`
- ✅ All iteration artifact requirements now met per contracts/iteration-artifacts.md

**Artifacts Created**:
- `specs/001-specrew-product/iterations/000/drift-log.md` (contract compliance)

**Artifacts Updated**:
- `specs/001-specrew-product/iterations/000/plan.md` (terminal metadata)

**Key Insight**: The iteration artifact contract (FR-005, FR-008, FR-009, FR-010) requires all four artifacts (plan.md, state.md, drift-log.md, review.md) in execution phase + planning metadata for the iteration to be contract-complete. Retrospective phase (retro.md) is separate and owned by Troi. The distinction between execution phase completeness and retrospective phase completeness is now explicit.

**Status**: Iteration 0 planning-side closure complete. Contract-safe and ready for retrospective.

### 2026-04-18: Iteration 0 Capacity Baseline Established

**Observation**: Iteration 0 delivered at exactly planned capacity (20.5/20.5 pts, zero variance), with zero specification drift. This is the foundation data point for calibration:
- Estimation accuracy: 100% (no over/undercommit)
- Drift detection: 100% (zero drift events means planning fidelity was high)
- Feasibility: All platform validation spikes passed with no blockers

**For Iteration 1 Planning**: Suggest capacity remains at 20 pts default (with approved 0.5–1 pt overcommit buffer for precondition-critical work if needed). Current estimation and team velocity are well-calibrated.

### 2026-04-18: Iteration Lifecycle Clarity

**Realization**: The four-phase iteration lifecycle creates two distinct "complete" states:
1. **Execution Complete** (state.md + plan.md metadata): Tasks done, spikes passed, review verdict recorded
2. **Retrospective Complete** (retro.md written): Estimation calibration, drift summary, improvement actions documented

Iteration 0 is execution-complete but retrospective-pending. The distinction matters for sequencing: Retrospective cannot start until execution artifacts are contract-safe (now ✓). Iteration 1 planning cannot start until retrospective is written (pending Troi).

This is a planning sequencing gate, not a blocker — but it must remain explicit in the ceremony schedule.

### 2026-04-18T13-30-34Z: Iteration 0 Execution-Phase Closure Decision Merged

**Status**: ✅ DECIDED & MERGED

**Scribe Summary**: Data's iteration 0 execution-phase closure decision merged into `.squad/decisions.md` under "2026-04-18: Iteration 0 Execution-Phase Closure Complete". Execution-phase artifacts complete and contract-safe:

**Artifacts Created/Verified**:
- ✅ **plan.md**: Metadata updated (Status: complete, Capacity: 20.5/20.5, Completed: 2026-04-18)
- ✅ **state.md**: Present and verified (La Forge)
- ✅ **drift-log.md**: Created (0 events; schema compliant)
- ✅ **review.md**: Present and verified (Worf)
- ⏳ **retro.md**: Pending Troi (retrospective phase)

**Execution Verdict**:
- Task Completion: 23/23 (100%)
- Effort Delivery: 20.5/20.5 (100% exact commitment, 0% variance)
- Spec Drift: 0 events
- Platform Validation: 9/9 spikes passed
- Architecture Resolution: Squad-native surfaces (decision tracked)
- Artifact Completeness: ✅ Contract-safe for retrospective

**Four-Phase Lifecycle Status**:
1. ✅ Planning Phase (complete 2026-04-17)
2. ✅ Execution Phase (complete 2026-04-18)
3. ✅ Review/Demo Phase (complete 2026-04-18, Worf sign-off)
4. ⏳ Retrospective Phase (pending 2026-04-18, Troi to write retro.md)

**Implication for Iteration 1 Planning**: Iteration 1 planning gates on Iteration 0 retrospective completion. Data (Planner) will use retrospective findings (estimation accuracy, drift summary, process improvements) as calibration data for Iteration 1 capacity, templates, and ceremony structure.

**Next Action (Data's Role)**: Await Troi retro.md completion. Then review retrospective findings with Troi and route improvement actions to affected roles (Picard: spec-authority gate; La Forge: spikes pre-planning; Alon: policy confirmation).

### 2026-04-18T14-22-00Z: Iteration 0 Artifact Cleanup — Stale Wording Removed

**Context**: External review identified stale wording in Iteration 0 state and plan artifacts that didn't reflect actual closure state. state.md still said "Awaiting retrospective analysis" even though retro.md was complete. plan.md marked Extension Surfaces as IN PROGRESS despite all spikes passing.

**Actions**:
- ✅ state.md line 15: Updated "Awaiting retrospective analysis" → "Retrospective complete (retro.md, 2026-04-18)"
- ✅ plan.md line 55 (Governance Consistency Check): Updated Extension Surfaces gate from "✅ IN PROGRESS | Spikes 1–5, 8–11 validate documented surfaces..." → "✅ COMPLETE | Spikes 1–5, 8–11 all PASS; documented surfaces validated. Platform readiness confirmed."

**Key Insight**: Iteration artifact updates must flow in sequence: execution completes → review closes → retrospective writes findings → planning artifacts reflect final terminal state. When retrospective completes post-execution, planning artifacts must be backfilled with final closure signals to maintain state consistency across all four lifecycle phases.

**Status**: Artifact cleanup complete. All iteration 0 artifacts now consistent with actual closed state.

### 2026-04-18: Completion Metadata Must Reserve `complete` for Alon Sign-Off

- Iteration artifacts can show review and retrospective as done without promoting the iteration to `complete`.
- When Alon sign-off is still pending, planning metadata should stay in a pre-complete state and name the outstanding gate explicitly.

---

## Cross-Agent Team Update (2026-04-18T17:31:28Z)

**Artifact Cleanup & Validation Hardening Complete**

- **La Forge (Validator Tightening)**: `validate-governance.ps1` hardened to distinguish real lifecycle drift from incidental prose. Status-line stale-language patterns now caught; role-name validation scoped to approval/closure statements only (no false positives on owner/action annotations). Iteration 0 review copy normalized; validator PASS confirmed.

- **Troi (Retrospective Artifact Consistency)**: retro.md role naming aligned with team.md. Changed "Spec Steward" → "Chief Architect & Reviewer" (line 251). Source of truth: team.md lines 15–16. Consistency verified; no downstream impact.

- **Worf (Review Artifact Freshness)**: review.md updated to reflect post-retro state. Forward-looking language removed ("proceeding to retrospective" → retrospective complete); role names corrected to match team.md. Team guidance: all review-phase closures require final freshness check (temporal accuracy, role names, gate dependencies).

**Status**: All four agents' artifact cleanup complete. Decisions merged to .squad/decisions.md. Inbox decisions deleted (deduplication complete). Governance authority artifacts now hardened and consistent. Iteration 0 closure official and binding. Ready for Iteration 1 planning prerequisites validation.

### 2026-04-18T18-02-00Z: Orchestration Complete — Spike Numbering & Plan Summary Alignment

**Session**: Reviewer-Drift Cleanup Batch  
**Status**: ✅ COMPLETE  

Iteration 0 closure artifacts documentation normalized to match authoritative Squad-native surfaces model and canonical spike sequencing.

**Changes**:
1. **plan.md summary** (line 12): Updated scaffolding description from "both Spec Kit and Squad extension" to "Spec Kit with Squad-native template sources"
2. **spikes.md**: Normalized non-canonical spike numbers to canonical sequence (1–5, skip 6–7, 8–11) with task IDs preserved

**Key Insight**: Spike numbers must align with task decomposition order. Non-sequential numbering (1–5, skip 6–7, 8–11) is intentional — it documents deferred Spikes 6–7 to Iteration 1 async. This pattern must be preserved consistently.

**Traceability**: All spike sections retain task ID cross-references (e.g., "Spike 5: Squad extension discovery test (T-017)") for linking to plan.md.

**Decision**: data-spike-numbering-fix (merged to .squad/decisions.md)  
**Impact**: Low (documentation clarity; all execution facts complete)  
**Use Case**: Iteration 1 planning will use canonical spike sequence as baseline for new spike identification

---

## 2026-04-18T20-30-00Z: Iteration 1 MVP Planning — Capacity Calibration & Scope Slicing

**Session**: Iteration 1 Planning Ceremony
**Status**: ✅ COMPLETE

Created execution-ready iteration plan for Iteration 001 at `specs/001-specrew-product/iterations/001/plan.md`. Plan is MVP-focused: greenfield bootstrap + four-phase iteration lifecycle + drift detection active.

**Scope Decision**: 20.5 story points committed — same as Iteration 0 capacity. Rationale:
- Iteration 0 was scaffolding-heavy (predictable, hit exactly at 20.5 pts). Iteration 1 is execution-engine-heavy but scope-disciplined to match proven capacity.
- Highest-complexity tasks (planning ceremony 2 pts, drift-check 2 pts) are frontloaded; supporting work pruned to keep total near proven capacity.
- This conservative approach reflects the move from scaffolding to runtime behavior and allows for variance learning.

**Deferred to Iter 2+**:
- Brownfield bootstrap (FR-020) — deferred to allow MVP stability post-Iter 1
- Configurable effort model (FR-007) — requires calibration data from multiple iterations
- Five-class collision detector (FR-012) — scope-reduced to hook + role collision check only (in T-010)
- Task resume (FR-019) — post-MVP priority
- Outcome scorer + full eval harness (FR-015) — staged delivery per plan

**Task Sequencing**:
- Phase 1: Bootstrap CLI (T-001–T-010) — orchestration engine + dependency management
- Phase 2: Governance directives (T-011–T-014) — drift-check skill + three directives
- Phase 3: Ceremonies (T-015–T-017) — planning, review/demo, retro integration
- Phase 4: Support (T-018–T-019) — artifact storage templates + documentation
- Phase 5: Testing (T-020–T-022) — integration + scenario tests + CI validation

**Key Planning Insights**:
1. Planning ceremony (T-015) and drift-check skill (T-011) are the two highest-complexity tasks (3 pts and 2.5 pts). Both require LLM reasoning.
2. Bootstrap orchestration (T-001–T-010) is dependency-heavy but each task is clear and testable in isolation.
3. Deferred work is explicitly tracked and prioritized for Iter 2 (brownfield, resume, effort model).
4. MVP scope prioritizes delivering end-to-end iteration capability over feature completeness.

**Spec Authority Validation**: All 22 tasks trace to FR-002 through FR-011, FR-018, or user story references. Deferred work (FR-007, FR-012, FR-016, FR-020) is explicitly marked and justified. No scope exists outside the spec.

**Traceability & Governance**: 100% task-to-requirement mapping. All effort estimates justified per task complexity. Capacity math verified: sum of tasks = 20.5 pts (matching Iter 0 proven capacity). No hidden dependencies or scope ambiguity.

**Next Gate**: Plan awaits Alon (Chief Architect) approval before execution phase begins. Iteration 0 retrospective insights (late spec-authority gates, estimation accuracy, drift detection patterns) should inform Iter 1 execution planning and ceremony sequencing.

**Decision**: No team-relevant decisions recorded (tech stack finalized in Iter 0; operating policy awaiting team consensus per .squad/identity/now.md).

---

## 2026-04-19: Board Documentation Correction — Source-of-Truth Hierarchy

**Session**: Alon directive on GitHub Projects V2 role clarity  
**Status**: ✅ COMPLETE

**Context**: Documentation (plan.md, github-project.md) implied that manual GitHub Projects board management was the *intended* operating mode for Specrew development. This was misleading because local iteration artifacts are always the source of truth, and GitHub board usage should be optional.

**Action**: 
- Rewrote `docs/github-project.md` with three-tier source-of-truth hierarchy (authoritative artifacts → derived GitHub Issues → optional visibility board)
- Updated Section 9 of `specs/001-specrew-product/plan.md` to explicitly state local artifacts are authoritative
- Removed GitHub Projects V2 API validation from Iteration 0 compatibility spike (board is optional, not a platform requirement)
- Updated Iteration 0 deliverable for optional GitHub board with reference to operational procedures
- Created decision inbox note (data-board-docs.md) for team record

**Key Insight**: Documentation clarity matters as much as code. Wording like "uses GitHub Projects" can imply requirement when it should be "may optionally use." The difference between operational convenience and normative requirement must be explicit, especially in governance documentation.

**Outcome**: Specrew documentation now clearly establishes local artifacts as authoritative, making it safe for teams to choose whether to use GitHub boards at all. Source-of-truth hierarchy is now explicit and binding for future iterations.

