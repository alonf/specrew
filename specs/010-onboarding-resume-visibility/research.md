# Research: Make Resume-Mode Visible in Specrew Onboarding

**Feature**: `010-onboarding-resume-visibility`  
**Phase**: Phase 0 – Research  
**Branch**: `010-onboarding-resume-visibility`  
**Date**: 2026-05-10  
**Status**: Complete — all NEEDS CLARIFICATION resolved

---

## Research Question 1 — Keeping the Feature Strictly Docs-Only

### Question

How do we keep this feature within a documentation-and-banner-only scope without accidentally touching runtime behavior, governance hooks, or lifecycle contracts?

### Findings

**Current code surfaces touched by the banner are limited to one function in one file.**
`Write-PostBootstrapGuidance` in `scripts/specrew-init.ps1` (lines 95–168) is the only PowerShell function that emits the bootstrap completion banner. It is a pure display function with no side effects: it calls `Write-Host` only and reads two local variables (`$baselineRoles`, `$specrewScriptsPath`) from its enclosing function. Changing the displayed text inside this function cannot affect runtime behavior.

**The three named documentation files are static Markdown.**
`README.md`, `docs/getting-started.md`, and `docs/user-guide.md` are plain Markdown files. They are not parsed by any Specrew script at runtime, not imported as configuration, and not validated by governance scripts for content. Changing their prose cannot break any runtime contract.

**Validation lane scripts do not parse documentation prose.**
Inspection of the six-lane validation commands confirms they test integration behavior, governance schema, and command contracts — not the wording of Markdown files or banner text. The approved command 5 is `project-path-resolution-regression.ps1`, which preserves existing path-resolution coverage rather than validating banner copy.

### Decision

**Restrict all changes to:**

1. `Write-PostBootstrapGuidance` function body in `scripts/specrew-init.ps1` — display text only, no logic changes.
2. `README.md` — prose additions in the Recommended flow / Notes section.
3. `docs/getting-started.md` — add a "Resuming work later" subsection.
4. `docs/user-guide.md` — review only; update only if contradictory first-launch-only language is found.

**No other files are in scope.** Specs 008 and 009 are explicitly excluded.

### Rationale

The documentation-only boundary is enforced by the file types involved (Markdown = static) and by the pure-display nature of the banner function. The validation lane scripts provide an independent proof that no behavioral regression can originate from text edits.

### Alternatives Considered

- Extracting banner text to a data file (e.g., `banner.json`): rejected — adds code-shaped complexity beyond the approved scope.
- Adding a new onboarding command: rejected — the spec explicitly lists this as a Non-Goal.

---

## Research Question 2 — Handling the Review-Only `docs/user-guide.md` Surface

### Question

`FR-005` requires reviewing `docs/user-guide.md` for contradictions to the resume contract, updating only if needed, and recording the finding either way. How should this be handled as a planning artifact?

### Findings

**Existing `user-guide.md` language for `specrew start`:**
The "Recommended Downstream Entry Point" section (lines 1–16 approx.) says:
> "`specrew start` is the canonical downstream entrypoint. It prepares the Squad handoff, launches Copilot CLI when available, and tells Squad to drive the full Spec Kit lifecycle…"

The section does not restrict `specrew start` to first launch only. The phrase "canonical downstream entrypoint" is neutral with respect to first versus resumed sessions.

**Iteration execution resume** (lines 72–83 approx.) discusses `resume-iteration.ps1` for recovering interrupted task execution — a different concept from session resumption.

**No first-launch-only language found.** The file does not tell users to run `copilot` directly, and does not imply `specrew start` is a one-time step. However, it also does not proactively clarify that resumed sessions require `specrew start`.

**FR-005 obligation:** The spec requires recording the finding even if no edit is needed.

### Decision

**Implementation task:** Inspect `docs/user-guide.md` against the resume contract. If no contradictory language is found, record the review outcome explicitly in the iteration state notes. A minor clarifying sentence in the "Recommended Downstream Entry Point" section (confirming `specrew start` applies to both first launch and resumed sessions) SHOULD be added for positive alignment with the resume contract, unless the reviewer determines it is unnecessary given the neutral existing language.

**Review criteria:** Contradictory language = any sentence that implies `specrew start` is only needed on first launch, or that running `copilot` directly is acceptable. Neutral language = neither confirms nor denies resume — acceptable but weak. Explicit resume language = preferred outcome.

### Rationale

The review-only designation means the user-guide is not a primary delivery target, but the FR-005 traceability obligation requires a recorded outcome either way. Recording "no contradictory language found; minor alignment note added" satisfies the requirement.

### Alternatives Considered

- Skipping user-guide review: rejected — FR-005 is a mandatory functional requirement.
- Treating user-guide as a full delivery target: rejected — spec designates it as review-only.

---

## Research Question 3 — Preserving the Six-Command Validation Lane for a Documentation-Only Feature

### Question

The six-command validation lane is inherited from prior features and tests runtime integration behavior, governance schema, and command contracts. How does it apply to a documentation-and-banner-only feature? Which commands will produce meaningful signal, and how should the plan record the lane without implying tests that are not meaningful?

### Findings

**Lane composition (from user specification, recorded verbatim):**

1. `pwsh -NoProfile -File .\tests\integration\quality-profile-foundation.ps1`
2. `pwsh -NoProfile -File .\tests\integration\hardening-gate-contract.ps1`
3. `pwsh -NoProfile -File .\tests\integration\quality-evidence-governance.ps1`
4. `pwsh -NoProfile -File .\tests\integration\validation-contract-lane.ps1`
5. `pwsh -NoProfile -File .\tests\integration\project-path-resolution-regression.ps1`
6. `pwsh -NoProfile -ExecutionPolicy Bypass -File .\extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath .`

**What each command tests relative to this feature:**

| Command | Tests | Relevance for Feature 010 |
|---------|-------|--------------------------|
| `quality-profile-foundation.ps1` | Quality profile schema and governance file structure | Regression guard — confirms governance files unchanged |
| `hardening-gate-contract.ps1` | Hardening gate artifact schema | Regression guard — no hardening artifact added by this feature |
| `quality-evidence-governance.ps1` | Evidence schema and governance quality contracts | Regression guard — no quality artifacts changed |
| `validation-contract-lane.ps1` | Validation contract schema and lane structure | Regression guard — ensures no lane schema drift |
| `project-path-resolution-regression.ps1` | Entry-point path resolution regression coverage | Meaningful — preserves the existing path-resolution guard required by TG-005 while this feature updates onboarding copy only |
| `validate-governance.ps1` | Governance artifacts, plan/spec traceability | Meaningful — confirms plan.md and spec.md satisfy governance schema after updates |

**Determination:** All six commands serve as regression guards. Command 5 preserves the pre-existing path-resolution coverage required by TG-005, and command 6 validates governance artifacts after planning updates. No lane command validates Markdown prose or banner copy directly; that remains bounded to manual review plus scope inspection of the display-only banner edits (TG-004, SC-003).

**SC-006 obligation:** The spec requires the validation lane to remain green at commit boundaries. This means all six must pass before and after the documentation edits, confirming no behavioral regression.

### Decision

**Preserve the six-command lane verbatim as the validation gate.** Run the full lane before editing (baseline green), after each surface edit (regression check), and as the final gate before closure (SC-006 compliance). Record lane results in iteration state notes.

Manual review covers what the lane cannot: reading the rendered surfaces and confirming the resume guidance is visible and correct (TG-004).

### Rationale

The lane was specified by the human owner and must be preserved exactly as given. Its regression-guard role is valid even for documentation-only features because it confirms no change broke the governance schema, quality contract, or existing entry-point path-resolution behavior. Running it costs little and provides documented evidence for SC-006.

### Alternatives Considered

- Running only commands 5 and 6: rejected — SC-006 requires the full lane green.
- Adding a documentation-specific lane command: rejected — scope is documentation-only; no new test infrastructure in scope.

---

## Summary of Resolutions

| NEEDS CLARIFICATION | Resolution |
|---------------------|-----------|
| How to stay docs-only | Change `Write-PostBootstrapGuidance` text only; edit three Markdown files; no logic, config, or schema changes. |
| How to handle user-guide review-only surface | Review against contradiction checklist; add alignment note if neutral; record finding in iteration state notes per FR-005. |
| How to preserve the six-command validation lane | Run the full lane verbatim as regression guard + direct coverage; manual review covers prose quality; document in quickstart.md. |

All NEEDS CLARIFICATION items resolved. Phase 1 Design may proceed.
