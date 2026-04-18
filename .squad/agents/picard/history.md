# Project Context

- **Owner:** Alon
- **Project:** Specrew
- **Stack:** Markdown, YAML, PowerShell, Spec Kit extension assets, Squad extension structure
- **Description:** A spec-governed AI crew operating model built as a monorepo with companion Spec Kit and Squad extensions.
- **Created:** 2026-04-17

## Core Context

I am the spec alignment gate for Specrew. My job is to keep every plan, task, decision, and implementation traceable to the authoritative source requirements.

## Recent Updates

📌 Team confirmed by Alon on 2026-04-17

## Learnings

- Specrew runs planning -> execution -> review/demo -> retrospective.
- The spec is authoritative and only tracked changes may override it.
- Drift detection runs after each task, not just at iteration end.
- Alon is the human Chief Architect and final reviewer.

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

### 2026-04-17: First Iteration Plan (Iteration 0 — Foundation) [MERGED TO DECISIONS.MD]

- **Spec scope from TG-003**: Iteration 0 = FR-001 (two-package architecture) + FR-013 (extension surfaces only). MVP (Iteration 1) = FR-002–FR-006, FR-008–FR-011, FR-018. Deferred iterations 2–3 per phased plan § 14.
- **Key insight**: Iteration 0 is precondition-critical. Must be completed and de-risked before MVP can begin. All feature implementation (bootstrap, ceremonies, skills) deferred to Iter 1.
- **Platform risks**: Two critical-path spikes that may require tracked changes if results are negative: (1) Squad post-task hook availability (Spike 4 — affects FR-008 implementation path); (2) Spec Kit `specify extension add` command (Spike 9 — affects `specrew init` script). Both are within Iter 0; results drive Iter 1 re-planning if needed.
- **Effort scoping**: Original plan 23 pts; capacity 20 pts. Deferred Spikes 6–7 (GitHub Projects API, local dev cycle) to reduce to 20 pts. Rationale: GitHub Projects is operational concern, not architectural blocker; local dev cycle is developer productivity, not customer-facing.
- **Traceability discipline**: Every task in Iteration 0 plan maps to at least one FR. No orphan tasks. Three categories: (1) FR-001 tasks (repo + extension skeletons), (2) FR-013 tasks (platform validation), (3) Support/infrastructure (CI, board).
- **Contingency planning**: Plan § Risk Mitigation explicitly flags overcommit decision and spike contingencies. Plan § Known Drift / Ambiguities documents what is pending vs. resolved.
- **Decision routing**: Decisions that affect downstream specs (Iter 1 plan, FR refinements) are routed to Alon via tracked change process rather than auto-resolved.
- **File paths**: Iteration 0 plan stored at `specs/001-specrew-product/iterations/000/plan.md` (zero-indexed, not `001/`). Decision merged to decisions.md on 2026-04-17T19:00:43Z.
- **Pattern**: This first iteration plan establishes the ceremony structure: Planning phase produces task list + effort estimates + traceability. Review/demo gate verifies completion. Retro captures learnings (esp. spike results driving Iter 1 changes).
