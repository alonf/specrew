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
| Picard | Spec Steward | `.squad/agents/picard/charter.md` | ✅ Active |
| Data | Planner | `.squad/agents/data/charter.md` | ✅ Active |
| La Forge | Implementer | `.squad/agents/laforge/charter.md` | ✅ Active |
| Worf | Reviewer | `.squad/agents/worf/charter.md` | ✅ Active |
| Troi | Retro Facilitator | `.squad/agents/troi/charter.md` | ✅ Active |
| Scribe | Session Logger | `.squad/agents/scribe/charter.md` | 📋 Silent |
| Ralph | Work Monitor | `.squad/agents/ralph/charter.md` | 🔄 Monitor |

## Project Context

- **Owner:** Alon
- **Project:** Specrew
- **Stack:** Markdown, YAML, PowerShell, Spec Kit extension assets, Squad extension structure
- **Description:** Specrew runs a spec-governed iteration lifecycle across planning, execution, review/demo, and retrospective phases.
- **Source of truth:** The spec is authoritative; behavior changes require a tracked change to the source requirements.
- **Created:** 2026-04-17
