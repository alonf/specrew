# Implementation Plan: Make Resume-Mode Visible in Specrew Onboarding

**Branch**: `010-onboarding-resume-visibility` | **Date**: 2026-05-10 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `specs/010-onboarding-resume-visibility/spec.md`
**Approved By**: Alon Fliess (2026-05-09 — spec approval; planning authorized in this session)

**State Note — Human Approval**: _I am explicitly authorizing the work below; do all of it in this same session._

## Summary

Make the resume-mode contract explicit in three primary Specrew onboarding surfaces — `README.md`, `docs/getting-started.md`, and the bootstrap completion banner (`scripts/specrew-init.ps1`) — so new users understand that every session, including resumes, must begin with `specrew start`, and that running `copilot` directly is not the supported path. Review `docs/user-guide.md` for contradictions and record the finding either way. Scope is strictly documentation and banner text; no runtime behavior changes.

**Technical approach**: Add prose to two Markdown files and `Write-Host` lines to one pure-display PowerShell function (`Write-PostBootstrapGuidance`). No new files, commands, or infrastructure. One review-only surface.

## Technical Context

**Language/Version**: PowerShell 7+ (`pwsh`) for the bootstrap banner function; Markdown (CommonMark) for documentation files
**Primary Dependencies**: None — plain Markdown + existing PowerShell function; no new packages or tooling
**Storage**: File system only — four existing files in the Specrew repository
**Testing**: Six-command integration validation lane (regression guard); manual review for prose correctness (TG-004)
**Target Platform**: Cross-platform (Windows, macOS, Linux) — wording must be platform-neutral per spec edge cases

**Project Type**: Documentation-only feature (FR-006 explicitly limits scope to documentation and bootstrap banner wording)
**Performance Goals**: Banner guidance visible within 100 terminal columns (SC-005)
**Constraints**: No runtime behavior changes; only allowed code-shaped change is `Write-PostBootstrapGuidance` display text in `scripts/specrew-init.ps1`; specs 008 and 009 MUST NOT be modified
**Scale/Scope**: Three primary text surfaces (README, getting-started, banner) + one review-only surface (user-guide)

**Editing surfaces in scope**:

| File | Role | Change Type |
|------|------|-------------|
| `README.md` | Primary onboarding entry point | Add resume note + anti-pattern warning to Recommended flow / Notes |
| `docs/getting-started.md` | Primary onboarding guide | Add "Resuming work later" subsection after Greenfield first-session step |
| `scripts/specrew-init.ps1` | Bootstrap banner — `Write-PostBootstrapGuidance` function only | Add `Write-Host` lines for resume guidance in Next Steps block |
| `docs/user-guide.md` | Secondary lifecycle reference | Review-only; edit only if contradictory first-launch-only language found |

**Out of scope**: specs 008, 009; any runtime scripts beyond the banner display function; governance schema files; test files; new documentation files; new onboarding surfaces.

## Phase 1 Quality Planning

**Phase Scope**: `phase-1-first-slice` — all three primary surfaces + user-guide review, delivered in one bounded iteration

**Inferred Quality Profile**: `quality-profile.custom-composition.v1` — documentation-only feature; no recognized stack preset applies

**Selected preset ref or explicit custom composition**: Custom composition: manual review (prose correctness, visibility, consistency) + six-command integration lane (regression guard) + governance validation. No automated linter for Markdown content or banner text in this repo.

**Bounded custom composition**: No automated prose quality tool is in scope. The custom composition is explicit: (1) six-command lane for regression, (2) manual review for content correctness and visibility, (3) governance validation before closure. All unknowns are explicit: prose quality is human-reviewed only.

### Stack Surfaces in Scope

| Stack Surface | Path Globs / Evidence | Recognized Stack | Why It Matters |
|---|---|---|---|
| `banner-display` | `scripts/specrew-init.ps1` — `Write-PostBootstrapGuidance` function | PowerShell 7+, display-only | Only code-shaped change; must not introduce regressions |
| `docs-primary` | `README.md`, `docs/getting-started.md` | Markdown (CommonMark) | Primary delivery surfaces for FR-001 and FR-002 |
| `docs-review` | `docs/user-guide.md` | Markdown (CommonMark) | Review-only surface for FR-005 |

### Risk Dimensions

| Risk Dimension | Status | Rationale |
|---|---|---|
| `security` | not-applicable | Documentation and display-text change; no code paths, data handling, or trust boundaries involved |
| `behavioral-regression` | required | Banner function is exercised by `start-command.ps1`; any inadvertent logic change would break the lane |
| `scope-creep` | required | Documentation-only boundary must be actively enforced; only display text in `Write-PostBootstrapGuidance` may change |
| `cross-surface-consistency` | required | Three primary surfaces must not contradict each other on the resume contract |
| `platform-neutrality` | required | Wording must apply on Windows, macOS, and Linux without modification |
| `concurrency-correctness` | not-applicable | No concurrent code paths involved |
| `data-integrity` | not-applicable | No data models or storage involved |

### Quality Tool Bundle

| Area | Selection | Evidence / Notes |
|---|---|---|
| Bundle ID | `docs-banner-custom-v1` | Custom composition for documentation + display-text feature |
| Mechanical Checks | Scope boundary check (only `Write-PostBootstrapGuidance` lines changed), banner width check (≤100 col) | Manual review during implementation; no automated tool |
| Ecosystem Tools | `validate-governance.ps1 -ProjectPath .` | Free governance validation; confirms plan/spec traceability after edits |
| Integration Lane | All six commands in the validation lane | Regression guard for behavioral surface |

### Required Quality Gates

| Required Quality Gate | Category | Evidence Source | Phase 1 Status |
|---|---|---|---|
| Validation lane baseline green (pre-edit) | tooling | Six-command lane output recorded in state notes | planned |
| Banner function scope check | mechanical | Human inspection: only `Write-Host` lines added, no logic changes | planned |
| Banner width check (SC-005) | mechanical | Human inspection: lines ≤ 100 chars | planned |
| Cross-surface consistency review | manual-evidence | Human reads all three primary surfaces together | planned |
| FR-005 user-guide review finding recorded | manual-evidence | Iteration state notes entry | planned |
| Validation lane post-edit green (SC-006) | tooling | Six-command lane output recorded in state notes | planned |
| Governance validation (`validate-governance.ps1`) | tooling | Exit code 0 after plan.md and spec.md are final | planned |

### Not-Applicable Dimensions and Rationale

| Dimension / Gate | Why Not Applicable in This Feature | Follow-up |
|---|---|---|
| Security surface analysis | No code paths, trust boundaries, or data handling | None — recorded explicitly |
| Error handling and failure semantics | No runtime logic changed | None — recorded explicitly |
| Retry and idempotency | No network or state-mutating operations | None — recorded explicitly |
| Concurrency correctness | No concurrent code paths | None — recorded explicitly |
| Performance profiling | Banner text rendering is not a performance surface | None — recorded explicitly |
| Unit tests | No logic added; banner is display-only | None — regression covered by lane command 5 |
| Automated prose linting | No Markdown linter configured in this repo | Human review substitutes; explicit gap recorded |

### Explicit Phase 2+ Deferrals

- Pre-implementation hardening gate sign-off and blocking semantics: not applicable for this documentation-only feature; deferred indefinitely.
- Dedicated bug-hunter lens execution: not applicable; deferred.
- Quality-drift logic, mixed-stack override workflows: not applicable; deferred.
- Automated prose quality checking (Markdown linter, grammar checker): out of scope for this feature; may be addressed in a future tooling feature.

## Phase 2 Hardening and Specialist Review Planning

**Phase 2 Slice Scope**: Not applicable for this documentation-only feature. No hardening gate artifact is required.
**Hardening Gate Artifact**: none
**Known-Traps Corpus Location**: `.specrew/quality/known-traps.md` (not relevant to this feature)
**Trap Reapplication Artifact**: none

### Hardening Focus Areas

| Focus Area | Why It Matters in This Slice | Planned Artifact / Evidence | Status |
|---|---|---|---|
| Security surface analysis | Not applicable — no code, no trust boundary, no data handling | none | not-applicable |
| Error handling and failure semantics | Not applicable — no runtime logic changed | none | not-applicable |
| Retry and idempotency expectations | Not applicable — no state-mutating operations | none | not-applicable |
| Test-integrity targets | Banner regression covered by lane command 5 (`start-command.ps1`); prose correctness covered by manual review | Six-command lane results + manual review record | required (manual) |

### Lens Activation Plan

| Lens / Checklist Ref | Activation | Why Activated or Omitted | Planned Evidence / Artifact Path |
|---|---|---|---|
| `security-issues-v1` | not-applicable | No code paths, no trust boundaries | recorded explicitly |
| `docs-consistency-review` | required (manual) | Three primary surfaces must be mutually consistent on resume contract | Human review record in state notes |
| `scope-boundary-check` | required (manual) | Documentation-only boundary must be enforced | Human inspection of git diff before commit |

### Routing Policy

All lens work for this feature is manual (human review). No automated routing or model-class routing applies.

### Explicit Later Deferrals

- Automated prose verification tools: deferred (no tooling in scope for this feature).
- Hardening gate artifact: deferred indefinitely — not applicable for documentation-only scope.
- Known-traps corpus update: deferred — no code traps introduced by this feature.

## Constitution Check

_GATE: Pre-Phase-0 check (initial) and post-Phase-1 check (re-evaluation below)._

### Pre-Phase-0 Constitution Check (Initial)

| Gate | Status | Evidence |
|------|--------|----------|
| **Spec Authority Gate** | ✅ PASS | Plan scope maps directly to approved spec artifacts: FR-001 → README edit; FR-002 → getting-started edit; FR-003 → banner edit; FR-004 → anti-pattern in all three; FR-005 → user-guide review; FR-006 → documentation-only constraint honored. |
| **Layering Gate** | ✅ PASS | Changes classified: `Write-PostBootstrapGuidance` text edit = Specrew team configuration layer (bootstrap script); Markdown edits = documentation layer. No Spec Kit layer or Squad layer changes. No architectural layer violations. |
| **Traceability Gate** | ✅ PASS | Every planned deliverable links to at least one FR: README → FR-001, FR-004; getting-started → FR-002, FR-004; banner → FR-003, FR-004; user-guide review → FR-005. User stories covered: US-1 by FR-001 to FR-004 (TG-001); US-2 by FR-002 with cross-machine language (TG-002). |
| **Ownership Gate** | ✅ PASS | Spec Steward: Alon Fliess (named in spec). Iteration Facilitator: Specrew documentation maintainers (named in spec). Implementation owner: Copilot/Squad agent in the authorized session. |
| **Capacity Gate** | ✅ PASS | Effort unit: one small documentation-and-banner slice (named in spec Governance Alignment section). No point budget conflict — three text edits + one review is well within a single iteration. |
| **Drift/Reconciliation Gate** | ✅ PASS | Drift signals defined in spec Governance Alignment section. Any surface that implies `specrew start` is first-launch-only, or presents `copilot` as valid, is a drift signal. Reconciliation: update the surface and re-run the validation lane before closure. |
| **Verification Gate** | ✅ PASS | Process verification: six-command validation lane (SC-006); governance validation (`validate-governance.ps1`). Outcome verification: manual review of all three primary surfaces (TG-004); FR-005 user-guide finding recorded. Acceptance criteria: SC-001 through SC-006 checked in closure checklist. |

**Pre-Phase-0 verdict**: All constitution gates PASS. Research phase authorized.

### Post-Phase-1 Constitution Re-evaluation

| Gate | Status | Post-Design Evidence |
|------|--------|---------------------|
| **Spec Authority Gate** | ✅ PASS | Design artifacts (data-model.md, contracts/, quickstart.md) remain within the spec-defined scope. No new surfaces added. No runtime changes planned. |
| **Layering Gate** | ✅ PASS | All Phase 1 design artifacts are documentation-layer or team-configuration-layer. No architectural layer violations introduced during design. |
| **Traceability Gate** | ✅ PASS | data-model.md entities map to FR-001 through FR-005. Contracts clauses map to FR-001 through FR-005 and SC-001 through SC-005. Quickstart maps to SC-006 and TG-004. |
| **Ownership Gate** | ✅ PASS | No change from pre-Phase-0. |
| **Capacity Gate** | ✅ PASS | Design confirms scope is bounded. Implementation is four file touches (three edits + one review). No capacity overrun. |
| **Drift/Reconciliation Gate** | ✅ PASS | Contract clauses define drift signals per surface. Consistency matrix in contracts/ makes cross-surface drift detectable. |
| **Verification Gate** | ✅ PASS | Quickstart.md captures the full validation and closure workflow, including the six-command lane, manual review gate, and FR-005 recording obligation. |

**Post-Phase-1 verdict**: All constitution gates PASS. Implementation phase authorized.

## Project Structure

### Documentation (this feature)

```text
specs/010-onboarding-resume-visibility/
├── spec.md              # Approved feature specification
├── plan.md              # This file — planning artifact
├── research.md          # Phase 0 output — all NEEDS CLARIFICATION resolved
├── data-model.md        # Phase 1 output — documentation surface entities
├── quickstart.md        # Phase 1 output — bounded implementation/validation workflow
├── contracts/
│   └── onboarding-text-surface.md  # Phase 1 output — text surface content contract
├── checklists/
│   └── requirements.md  # Pre-existing requirements checklist (passed)
└── tasks.md             # Phase 2 output — NOT created by this plan (speckit.tasks command)
```

### Repository Files Modified by This Feature

```text
README.md                          # Add resume note + anti-pattern warning
docs/
├── getting-started.md             # Add "Resuming work later" subsection
└── user-guide.md                  # Review-only; edit only if contradiction found
scripts/
└── specrew-init.ps1               # Edit Write-PostBootstrapGuidance function body only
```

**Structure Decision**: Documentation-only layout. No source tree changes beyond the display function. All changes are additive to existing files.

### Validation Lane

```text
tests/integration/
├── quality-profile-foundation.ps1   # Lane command 1 — regression guard
├── hardening-gate-contract.ps1      # Lane command 2 — regression guard
├── quality-evidence-governance.ps1  # Lane command 3 — regression guard
├── validation-contract-lane.ps1     # Lane command 4 — regression guard
└── start-command.ps1                # Lane command 5 — direct coverage for banner path
extensions/specrew-speckit/scripts/
└── validate-governance.ps1          # Lane command 6 — governance schema coverage
```

**Six-Command Validation Lane** (run verbatim, from repo root, before and after all edits):

```powershell
pwsh -NoProfile -File .\tests\integration\quality-profile-foundation.ps1
pwsh -NoProfile -File .\tests\integration\hardening-gate-contract.ps1
pwsh -NoProfile -File .\tests\integration\quality-evidence-governance.ps1
pwsh -NoProfile -File .\tests\integration\validation-contract-lane.ps1
pwsh -NoProfile -File .\tests\integration\start-command.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File .\extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath .
```

## Complexity Tracking

> No constitution violations requiring justification. All gates pass. No complexity table required.

## Iteration State Notes

**Approval**: _I am explicitly authorizing the work below; do all of it in this same session._

**Before-plan hook**: `speckit.specrew-speckit.before-plan` — PASS (executed; spec approved; requirements actionable; governance check passed)

**Phase 0 Research**: Complete — research.md created. All three NEEDS CLARIFICATION items resolved:
1. Docs-only boundary confirmed (Markdown + pure-display function; no runtime impact possible)
2. User-guide review-only handling confirmed (review against contradiction checklist; FR-005 recording obligation defined)
3. Six-command validation lane role confirmed (regression guard + direct coverage for banner and governance; manual review covers prose)

**Phase 1 Design**: Complete — data-model.md, contracts/onboarding-text-surface.md, quickstart.md created.
- Four documentation surface entities defined with required content fields and validation rules
- Text surface content contract defines minimum required semantic elements per surface (not exact wording)
- Quickstart captures bounded implementation order and full closure checklist
- Post-Phase-1 constitution check: all gates PASS

**FR-005 user-guide review**: Pending implementation — to be recorded in this section before closure.
- Finding placeholder: _[Record here during implementation: "no contradictory language found / edit applied: …"]_

**SC-006 lane results**: Pending implementation — record baseline and post-edit lane results here.
- Baseline (pre-edit): _[Record here]_
- Post-implementation: _[Record here]_
