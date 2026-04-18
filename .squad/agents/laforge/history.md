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
