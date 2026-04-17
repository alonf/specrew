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
