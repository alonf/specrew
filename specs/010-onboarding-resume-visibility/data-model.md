# Data Model: Make Resume-Mode Visible in Specrew Onboarding

**Feature**: `010-onboarding-resume-visibility`  
**Phase**: Phase 1 – Design  
**Branch**: `010-onboarding-resume-visibility`  
**Date**: 2026-05-10  
**Status**: Complete

---

## Scope Note

This feature is documentation-and-banner-only. There are no application data structures, database schemas, or runtime models. The "data model" for this feature describes the **documentation surface entities**, their required content fields, consistency obligations, and review obligations. Each entity maps to a file in the repository.

---

## Entity 1 — README Surface

| Field | Value |
|-------|-------|
| **Entity name** | `README.md` |
| **File path** | `README.md` (repo root) |
| **Role** | Primary entry point for new users; first document most readers encounter |
| **Delivery type** | Primary delivery target (FR-001) |
| **Current state** | Contains a Recommended flow (4 steps) and a Notes section. Mentions `specrew start` as the canonical entry point but does not explicitly address resume sessions or warn against `copilot` directly. |

### Required Content Fields (FR-001, FR-004)

| Field ID | Required Text / Behavior | Source Requirement |
|----------|--------------------------|-------------------|
| `R-README-001` | The Recommended flow or an equivalent prominent section MUST state that later (resumed) sessions also begin with `specrew start` | FR-001 |
| `R-README-002` | MUST explicitly warn that running `copilot` directly is not the supported path for Specrew-managed projects | FR-004 |
| `R-README-003` | Warning MUST include a one-sentence rationale (e.g., bypassing `specrew start` skips runtime handoff regeneration) | FR-004 |

### Placement Guidance

The resume note belongs in the Recommended flow section (step 2 or as a follow-on step) or the Notes section, whichever makes the guidance most visible without reordering the existing steps. The anti-pattern warning MUST be co-located with or immediately adjacent to the resume note so a reader sees both together.

### Validation Rules

- Content must be visible without requiring readers to search through unrelated content (TG-004).
- Must not contradict the resume contract in any other sentence.
- Must remain platform-neutral (no Windows-only wording).

### State Transitions

N/A — Markdown file, no state machine.

---

## Entity 2 — Getting-Started Surface

| Field | Value |
|-------|-------|
| **Entity name** | `docs/getting-started.md` |
| **File path** | `docs/getting-started.md` |
| **Role** | Primary onboarding guide; detailed bootstrap and quickstart guidance for new users |
| **Delivery type** | Primary delivery target (FR-002) |
| **Current state** | Contains Greenfield Quickstart, Brownfield Quickstart, Common Flags, Troubleshooting. The Greenfield Quickstart covers the first session through `specrew start` but has no "Resuming work later" subsection. |

### Required Content Fields (FR-002, FR-004)

| Field ID | Required Text / Behavior | Source Requirement |
|----------|--------------------------|-------------------|
| `R-GS-001` | MUST include a dedicated "Resuming work later" subsection (or equally prominent equivalent) | FR-002 |
| `R-GS-002` | Subsection MUST name `specrew start` as the command for every subsequent (resumed) session | FR-002 |
| `R-GS-003` | Subsection MUST explain that `specrew start` regenerates `.specrew/last-start-prompt.md`, `.specrew/start-context.json`, and `.specrew/start-summary.md` | FR-002 |
| `R-GS-004` | Subsection MUST explicitly warn against running `copilot` directly | FR-002, FR-004 |
| `R-GS-005` | Subsection MUST cover the cross-machine case: transient runtime files do not travel with git; `specrew start` rebuilds them from tracked state on each machine | FR-002 |
| `R-GS-006` | Anti-pattern warning MUST include a one-sentence rationale | FR-004 |

### Placement Guidance

The "Resuming work later" subsection MUST appear at the end of the Greenfield Quickstart (after the first-session `specrew start` step) or as a clearly delineated section directly after it. It must be findable without reading the entire document.

### Validation Rules

- The subsection heading "Resuming work later" (or equivalent) must appear in the rendered output.
- The three transient file names must be listed explicitly.
- The cross-machine explanation must distinguish transient per-machine files from tracked project state.
- Anti-pattern (`copilot` directly) must be named explicitly per the spec clarification.
- Platform-neutral wording required.
- Must pass visibility check: findable without searching through unrelated content (TG-004).

### State Transitions

N/A — Markdown file, no state machine.

---

## Entity 3 — Bootstrap Complete Banner

| Field | Value |
|-------|-------|
| **Entity name** | Bootstrap Complete Banner |
| **File path** | `scripts/specrew-init.ps1` — function `Write-PostBootstrapGuidance` |
| **Role** | Terminal output shown after successful bootstrap; the last thing a new user reads before their first session |
| **Delivery type** | Primary delivery target (FR-003); only allowed code-shaped change in this feature |
| **Current state** | The banner emits "Next Steps" with step 1: run `specrew start`. The Usage Flow line mentions `specrew start` but refers only to spec/clarify/plan/tasks/implement/review/retro lifecycle, not to session resumption. No resume-mode guidance present. |

### Required Content Fields (FR-003, FR-004)

| Field ID | Required Text / Behavior | Source Requirement |
|----------|--------------------------|-------------------|
| `R-BANNER-001` | MUST include a "Resuming work later" line in the Next Steps guidance | FR-003 |
| `R-BANNER-002` | The line MUST state that every subsequent session runs through `specrew start` | FR-003 |
| `R-BANNER-003` | The line MUST explain that `specrew start` regenerates the runtime handoff before launch | FR-003 |
| `R-BANNER-004` | MUST explicitly state that running `copilot` directly is not the supported path | FR-004 |
| `R-BANNER-005` | Anti-pattern warning MUST include a one-sentence rationale | FR-004 |
| `R-BANNER-006` | The resume guidance MUST be visible without scrolling on a standard terminal width of at least 100 columns (SC-005) | SC-005 |

### Implementation Constraint

Only the `Write-PostBootstrapGuidance` function body may be edited. No logic, parameters, control flow, or other functions in `scripts/specrew-init.ps1` may be changed. The edit is limited to adding `Write-Host` lines within the existing "Next Steps" block.

### Validation Rules

- Banner text must render within 100 columns (SC-005).
- Resume guidance must be visible without scrolling past unrelated content.
- Anti-pattern (`copilot` directly) must be named explicitly.
- The three regenerated files need not be listed in the banner (brevity for terminal output), but the phrase "regenerates the runtime handoff" or equivalent must appear.
- Platform-neutral wording required.

### State Transitions

N/A — display-only function.

---

## Entity 4 — User Guide Consistency Surface

| Field | Value |
|-------|-------|
| **Entity name** | `docs/user-guide.md` |
| **File path** | `docs/user-guide.md` |
| **Role** | Day-to-day lifecycle reference; secondary onboarding surface |
| **Delivery type** | Review-only; update only if contradictory language found (FR-005) |
| **Current state** | "Recommended Downstream Entry Point" section describes `specrew start` as "the canonical downstream entrypoint" without first-launch restriction. No explicit resume guidance; no anti-pattern warning. Language is neutral but weak relative to the resume contract. |

### Review Obligation (FR-005)

| Check | Pass Condition | Fail Condition (requires edit) |
|-------|---------------|-------------------------------|
| First-launch-only language | Not present | Any sentence implying `specrew start` is only for first launch |
| Plain `copilot` as valid path | Not present | Any sentence implying running `copilot` directly is acceptable |
| Contradicts resume contract | Not present | Any sentence that would cause a user to believe resuming works differently from first launch |

### Optional Alignment Note

If the review finds neutral (non-contradictory but non-explicit) language — the current state — a one-sentence alignment note MAY be added to the "Recommended Downstream Entry Point" section to confirm `specrew start` applies to both first launch and resumed sessions. This is optional and at implementer discretion.

### FR-005 Recording Obligation

Regardless of outcome, the review finding MUST be recorded in the iteration state notes before closure:

- **If no edit needed**: "FR-005 review of docs/user-guide.md: no contradictory first-launch-only language found. No edit required."
- **If edit made**: "FR-005 review of docs/user-guide.md: [describe contradictory language found]. Edit applied: [describe change]."

### Validation Rules

- Review must happen before closure.
- Finding must be recorded.
- If an edit is made, it must not expand scope beyond resolving the contradiction.

---

## Cross-Surface Consistency Obligations

| Obligation | Description | Surfaces |
|------------|-------------|---------|
| `C-001` | All three primary surfaces must name `specrew start` as the resume command | README, getting-started, banner |
| `C-002` | All three primary surfaces must name `copilot` directly as the anti-pattern | README, getting-started, banner |
| `C-003` | All three primary surfaces must provide a one-sentence rationale for the anti-pattern | README, getting-started, banner |
| `C-004` | The handoff regeneration explanation must appear in at least two primary surfaces (getting-started is mandatory; README or banner provides the second) | README and/or banner |
| `C-005` | The cross-machine case (transient files don't travel with git) must appear in at least getting-started | getting-started |
| `C-006` | No surface may contradict another on the resume contract | All four surfaces |
| `C-007` | All wording must remain platform-neutral | All four surfaces |

---

## Summary

| Entity | Delivery Type | File | Key Gap Today |
|--------|--------------|------|---------------|
| README surface | Primary | `README.md` | No resume guidance; no anti-pattern warning |
| Getting-started surface | Primary | `docs/getting-started.md` | No "Resuming work later" subsection |
| Bootstrap banner | Primary | `scripts/specrew-init.ps1` | No resume-mode next step in banner |
| User-guide surface | Review-only | `docs/user-guide.md` | Neutral language; no contradiction; review and record |
