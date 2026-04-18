# Project Context

- **Owner:** Alon
- **Project:** Specrew
- **Stack:** Markdown, YAML, PowerShell, Spec Kit extension assets, Squad extension structure
- **Description:** A spec-governed AI crew operating model built as a monorepo with companion Spec Kit and Squad extensions.
- **Created:** 2026-04-17

## Core Context

I execute planned work for Specrew and produce outputs that remain traceable to the requirement and task that triggered them.

## Recent Updates

📌 Final plan polish completed on 2026-04-18: Removed FR-050 reference, mapped scaffolding tasks to FR-001, synchronized traceability matrix. All 23 tasks now FR-bound; 100% contract-compliant. Pending Alon approval.

📌 Contract-safe Iteration 0 plan revision completed on 2026-04-18: All 7 contract findings addressed (schema, task layout, ownership, capacity math, stale references, scope, citations). Plan now automation-safe and pending Alon approval.

📌 Team confirmed by Alon on 2026-04-17

## Learnings

- Implementation is the execution phase between planning and review/demo.
- Deliverables must stay requirement-traceable; undocumented deviation counts as drift.
- Specrew v1 uses Markdown, YAML, and PowerShell assets in a monorepo.
- The downstream product method and Specrew's own development method are intentionally the same.
- **Artifact contracts must be respected**: Iteration plans must conform to machine-readable schemas (metadata fields, unified task tables, role names instead of cast names).
- **Capacity math must be internally consistent**: All overcommit narratives and effort totals must agree. If a plan exceeds capacity, every statement (summary, effort table, capacity line) must align.
- **Stale references corrupt traceability**: Old task IDs and fabricated citations must be replaced with real spec citations to maintain audit trail.
- **Scope clarity prevents drift**: Iteration 0 scope is *enabling work only* (platform validation, extension scaffolds). All MVP delivery and bootstrap implementation deferred to Iteration 1.
- **Governance becomes real when templates and validators agree**: The operating method must live in runtime-facing ceremony/directive/skill templates, and lifecycle checks must fail automatically when artifacts are incomplete or phases are skipped.
- **Validator tightening needs context-aware matching**: stale "awaiting sign-off" language belongs in lifecycle checks, while role-name validation should only inspect actual approval/closure lines instead of owner or action annotations.
- **Cross-artifact evidence is the reliable stale-state detector**: once review/retro artifacts exist, validator checks should treat lingering "pending" lifecycle claims and non-terminal governance gate verdicts as semantic failures, not documentation drift.
- **Required artifacts need actual git tracking**: if governance or iteration assets are declared complete, make sure the files are added to version control and remove backup/handoff leftovers that only create untracked noise.

---

## Cross-Agent Team Update (2026-04-18T16:50:48Z)

**La Forge governance enforcement milestone**:

- **Worf (Final Gate Review)**: Iteration 0 closure audit passed. All four phases complete; governance validator script confirms artifact compliance. No blocking issues identified. Iteration 0 closure official and binding.

- **Coordinator (Governance Todos)**: All tier-0 governance enforcement tasks marked complete. Operating policy (6 rules + 3 tier-1 improvements) documented. Team consensus required before Iteration 1 execution. Iteration 1 planning prerequisites finalized.

- **User Directive**: Governance hardening authority now normative and binding. Specrew uses Specrew's own lifecycle. Iteration 1 work will run under binding phase state machine with automated validator gates.

**La Forge role in Iteration 1**: 
- Governance-validator skill (FR-008) deferred to Iteration 1 execution
- Identify architecture-risk spikes pre-planning (operating rule 2)
- Validator integration with agent charters and ceremony templates

**Terminal state**: Governance enforcement package complete; validator script live; Squad-native surfaces deployed. Ready for operator (Picard) ceremony integration.

---

## Cross-Agent Team Update (2026-04-18T17:31:28Z)

**Artifact Cleanup & Validation Hardening Complete**

**La Forge (Validator Tightening)**: `validate-governance.ps1` hardened post-review to distinguish real lifecycle drift from incidental prose patterns. 

- Status-line stale-language patterns now caught as semantic mismatch (e.g., "awaiting sign-off" marked COMPLETE)
- Role-name validation scoped to approval/closure statements only; no longer triggers on owner/action annotations
- Iteration 0 review copy normalized to terminal-state language; validator reran successfully (PASS)

**Context**: External review flagged overly broad validator patterns creating false positives. Refined scope to catch real governance issues without tripping on incidental prose.

**Impact**: Validator now ready for Iteration 1 phase gate enforcement. Governance enforcement package (protocol + validator + Squad-native surfaces) fully hardened and integrated.

- **Data (Planning Artifact Cleanup)**: state.md and plan.md updated to reflect Iteration 0 final closed state post-retrospective
- **Troi (Retrospective Consistency)**: retro.md role naming aligned with team.md
- **Worf (Review Artifact Freshness)**: review.md updated to post-retro state with corrected role names

**Status**: All four agents' artifact cleanup complete. Decisions merged to .squad/decisions.md. Iteration 0 closure official and binding. Validation hardening complete.
