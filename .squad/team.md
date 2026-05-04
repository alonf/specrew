# Squad Team

> Specrew — a spec-governed AI crew operating model for a monorepo containing a Spec Kit extension and a Squad extension.

## Coordinator

| Name | Role | Notes |
|------|------|-------|
| Squad | Coordinator | Routes work, enforces handoffs and reviewer gates. Does not generate domain artifacts directly. |

## Members

| Name | Role | Charter | Status |
|------|------|---------|--------|
| Alon | Chief Architect & Reviewer | — | 👤 Human |
| Scribe | Session Logger | `.squad/agents/scribe/charter.md` | 📋 Silent |
| Ralph | Work Monitor | `.squad/agents/ralph/charter.md` | 🔄 Monitor |

## Project Context

- **Owner:** Alon
- **Project:** Specrew
- **Stack:** Markdown, YAML, PowerShell, Spec Kit extension assets, Squad extension structure
- **Description:** Specrew runs a spec-governed iteration lifecycle across planning, execution, review/demo, and retrospective phases.
- **Source of truth:** The spec is authoritative; behavior changes require a tracked change to the source requirements.
- **Created:** 2026-04-17

<!-- >>> specrew-managed baseline-roles >>> -->
## Specrew Baseline Roles

| Role | Charter | Status |
| ---- | ------- | ------ |
| Spec Steward | `.squad/agents/spec-steward/charter.md` | baseline |
| Planner | `.squad/agents/planner/charter.md` | baseline |
| Implementer | `.squad/agents/implementer/charter.md` | baseline |
| Reviewer | `.squad/agents/reviewer/charter.md` | baseline |
| Retro Facilitator | `.squad/agents/retro-facilitator/charter.md` | baseline |
<!-- <<< specrew-managed baseline-roles <<< -->
