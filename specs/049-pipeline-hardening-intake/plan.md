# Implementation Plan: Release Pipeline Hardening + Substantive Intake Slice

**Branch**: `049-pipeline-hardening-intake` | **Date**: 2026-05-28 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `specs/049-pipeline-hardening-intake/spec.md`

**Note**: This refreshed plan restores roadmap truth for Feature `049`: it is a **five-iteration** feature. Iterations `001`-`003` are closed, Iteration `004` remains the reserved Proposal `120` five-pillar bypass-detection slice, and Iteration `005` is the newly planned Proposal `141` capability-dial/persona-lens correction slice. This refresh does **not** reopen Iteration `003` and does **not** reduce Iteration `004`.

## Summary

Feature `049` now carries a truthful five-iteration roadmap. The new Iteration `005` is a bounded **3-5 SP** correction slice that updates user-facing capability/confidence wording around the existing Iteration `003` intake/profile architecture while preserving stable persisted keys, internal persona IDs, and Iteration `004`'s reserved Proposal `120` scope unchanged. The slice centers on capability-dial vs persona-lens separation, the visible fourth label **AI Delivery Planning**, docs/skills/reviewer-guidance consistency, and explicit compatibility proof that existing `user-profile.yml` files load unchanged and preserve behavior.

## Technical Context

**Language/Version**: PowerShell 7.x plus Markdown/YAML/JSON governance assets  
**Primary Dependencies**: Specrew module scripts, Spec Kit extension assets, slash-command skills, intake YAML catalogs  
**Storage**: User-level `~/.specrew/user-profile.yml` plus project-local `.specrew/start-summary.md`, `.specrew/start-context.json`, and related review/evidence artifacts  
**Testing**: PowerShell integration tests, scripted evidence artifacts, reviewer/operator audit evidence  
**Target Platform**: Cross-platform PowerShell (Windows/Linux/macOS) with GitHub Copilot / Claude / Agents skill surfaces  
**Project Type**: PowerShell module with documentation, prompt, skill, and governance overlays  
**Performance Goals**: Preserve existing profile-load and intake-depth behavior while correcting user-facing wording only  
**Constraints**: No schema migration, no persisted-key rename, no internal persona ID rename, no Iteration `003` reopening, no Iteration `004` scope drift  
**Scale/Scope**: Small corrective slice touching first-run/profile/help/reviewer surfaces across shipped and mirrored paths

## Constitution Check

| Gate | Verdict | Notes |
| ---- | ------- | ----- |
| Spec Authority | PASS | Scope is anchored to `FR-032..FR-037`, `SC-007`, and `TG-016..TG-018` in `spec.md`. |
| Layering | PASS | Work remains a presentation/guidance/evidence correction over the existing intake/profile runtime; no new architecture layer or persona-model split is introduced. |
| Traceability | PASS | Iteration `005` is explicitly mapped to User Story `3`, Proposal `141`, and the preserved Iteration `004` Proposal `120` reservation. |
| Ownership | PASS | Planner owns package refresh now; later work splits between Implementer (wording/runtime/docs) and Reviewer (audit/evidence/compatibility proof). |
| Capacity | PASS | Iteration `005` is bounded to **3-5 story points**. Feature roadmap increases by **+3 to +5 SP** versus the stale four-iteration plan. |
| Drift/Reconciliation | PASS | This refresh removes stale “four-iteration” and “Iteration `003` planning” truth from planning surfaces and records the `004`-absent / `005`-present caveat explicitly. |
| Verification | PASS | Compatibility proof, audited-surface coverage, mirror-parity discipline, and reviewer evidence are mandatory before Iteration `005` can close. |

## Project Structure

### Feature Planning Surfaces

```text
specs/049-pipeline-hardening-intake/
├── spec.md
├── plan.md
└── iterations/
    ├── 001/plan.md
    ├── 002/plan.md
    ├── 003/plan.md
    └── 005/plan.md
```

### Principal Runtime / Guidance Surfaces for Iteration 005

```text
scripts/
├── specrew-start.ps1
└── internal/user-profile.ps1

.github/
├── prompts/speckit.specify.prompt.md
├── agents/speckit.specify.agent.md
└── skills/specrew-user-profile/SKILL.md

.claude/skills/specrew-user-profile/SKILL.md
.agents/skills/specrew-user-profile/SKILL.md

extensions/specrew-speckit/scripts/intake/Invoke-SpecifyIntake.ps1
.specify/extensions/specrew-speckit/scripts/intake/Invoke-SpecifyIntake.ps1

tests/integration/f049-i003-intake-engine-tests.ps1
```

**Structure Decision**: Feature `049` remains a PowerShell module enhancement spanning scripts, docs, skills, prompts, mirrored Spec Kit assets, and review/evidence artifacts. Iteration `005` is intentionally narrow: it corrects user-facing capability wording and compatibility proof around the existing four-lens architecture rather than changing the underlying intake catalogs or schema.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

**No violations** — this refresh tightens roadmap truth and bounded-slice discipline rather than adding architectural complexity.

---

## Iteration Breakdown

### Iteration 001: Docker Pre-Publish Verification (Closed)

**Status**: Complete  
**Capacity**: 17 SP actual  
**Scope**: `FR-001..FR-005`, `FR-012..FR-014`, `SC-001`, `TG-001`, `TG-007`

**Deliverables**:

- Docker-based E2E publish blocker
- FileList verification + `specrew update` regression guardrails
- Publish workflow enforcement
- Manifest version-drift detection
- Duplicate-row merge protection
- PSGallery `--info` truthfulness

**Outcome**: `SC-001` met.

---

### Iteration 002: Troubleshooting Guide (Closed)

**Status**: Complete  
**Capacity**: 4.0 SP actual  
**Scope**: `FR-006`, `FR-007`, `FR-015`, `FR-016`, `FR-017`, `SC-002`, `TG-002`, `TG-007`

**Deliverables**:

- `docs/troubleshooting.md`
- `Specrew.psd1` FileList registration
- Cross-references from onboarding docs
- Durable Shape-5 lesson

**Outcome**: `SC-002` met.

---

### Iteration 003: Persona Intake + Engine/Data Architecture (Closed)

**Status**: Complete  
**Capacity**: 23.45 SP actual  
**Scope**: `FR-008..FR-011`, `FR-023..FR-031`, `SC-003`, `SC-005`, `SC-006`, `TG-003`, `TG-009..TG-015`

**Deliverables**:

- Discrete intake engine + mirrored helper surface
- YAML persona/category/question/default catalogs
- `user-profile.yml` persistence and `specrew start` integration
- `/specrew-user-profile` skill deployment
- Per-lens mode routing + transparency annotations
- Extensibility proof for a fifth persona as data-only change

**Outcome**: Iteration `003` is historical/closed and MUST NOT be reopened by Iteration `005`.

---

### Iteration 004: Five-Pillar Bypass Detection (Reserved, Unchanged)

**Status**: Reserved (not opened)  
**Capacity**: 6-10 SP  
**Scope**: `FR-018..FR-022`, `SC-004`, `TG-004`, `TG-007`, `TG-008`, `TG-016`

**Deliverables**:

- Pillar 1 handoff detection
- Pillar 2 trigger-bypass artifact classification
- Pillar 3 canonical-artifact-location warnings
- Pillar 4 verdict-history enforcement
- Pillar 5 tree-under-review vs accepted-evidence validation

**Outcome Target**: `SC-004`.

**Protection Rule**: Proposal `120` stays fully anchored here. Nothing in Iteration `005` may reduce, reinterpret, or defer this slice.

---

### Iteration 005: Capability Dial / Persona Lens Separation Correction (Planning)

**Status**: Planning  
**Capacity**: 3-5 SP  
**Scope**: `FR-032..FR-037`, `SC-007`, `TG-003`, `TG-006`, `TG-007`, `TG-016..TG-018`

**Deliverables**:

- Capability-area wording across first-run, profile, and help surfaces
- Stable-key and internal-persona-ID preservation
- Visible fourth capability label fixed to **AI Delivery Planning**
- Explicit copy distinguishing user dials from internal persona lenses
- Docs / skills / reviewer guidance consistency audit
- Scripted legacy `user-profile.yml` compatibility proof

**Outcome Target**: `SC-007`.

**Boundary Rule**: This is a follow-on correction slice only. It does **not** split the fourth internal lens, add a fifth lens, or migrate persisted profile data.

---

## Feature Capacity Summary

| Iteration | Status | Planned SP | Actual / Forecast SP | Notes |
| --------- | ------ | ---------- | -------------------- | ----- |
| 001 | Closed | 12-15 | 17.00 | Completed above original band because regression hardening was absorbed. |
| 002 | Closed | 4-6 | 4.00 | Closed documentation slice. |
| 003 | Closed | 21-25 | 23.45 | Architectural pivot completed. |
| 004 | Reserved | 6-10 | TBD | Proposal `120` full five-pillar bypass detection. |
| 005 | Planning | 3-5 | TBD | Proposal `141` correction slice. |
| **Total** | - | **51-63** | **44.45 consumed + 9-15 remaining = 53.45-59.45 projected** | **Roadmap increased by +3 to +5 SP vs the stale four-iteration model.** |

## Iteration 005 Planning Decisions

1. **Final fourth capability label**: `AI Delivery Planning`.
2. **All four visible labels are capability areas**: `Product Strategy`, `UX/UI Design`, `Software Architecture`, `AI Delivery Planning`.
3. **Persisted schema and internal IDs stay unchanged**: including `expertise.ai_research_project_management` and `ai-researcher-project-manager`.
4. **No Iteration 003 reopen**: this slice corrects display language and proof surfaces only.
5. **No Iteration 004 drift**: Proposal `120` remains fully reserved in Iteration `004`.
6. **Display-label implementation strategy**: use a shared presentation-layer mapping over unchanged persisted keys and internal persona IDs; do not require a schema rewrite to land the correction.
7. **Reviewer guidance is in scope**: review instructions and evidence must explicitly check capability-vs-identity wording and legacy-profile compatibility.

## Iteration 005 Audit Inventory

| Surface Group | Correction Need | Candidate Paths |
| ------------- | --------------- | --------------- |
| First-run prompt | Replace persona/job-title framing with capability/confidence framing | `scripts/internal/user-profile.ps1`, `scripts/specrew-start.ps1` |
| Profile display / edit / reset | Show capability labels while preserving existing keys | `scripts/internal/user-profile.ps1`, `.github/skills/specrew-user-profile/SKILL.md`, `.claude/skills/specrew-user-profile/SKILL.md`, `.agents/skills/specrew-user-profile/SKILL.md` |
| Start summaries / persisted context | Keep user-facing summaries truthful after first run and reuse | `scripts/specrew-start.ps1` -> `.specrew/start-summary.md`, `.specrew/start-context.json`, `.specrew/last-start-prompt.md` |
| Specify guidance | Explain that dials control question depth while personas remain internal lenses | `.github/prompts/speckit.specify.prompt.md`, `.github/agents/speckit.specify.agent.md`, `extensions/specrew-speckit/scripts/intake/Invoke-SpecifyIntake.ps1`, `.specify/extensions/specrew-speckit/scripts/intake/Invoke-SpecifyIntake.ps1` |
| Docs / help | Keep substantive-intake help text and downstream docs aligned to the corrected semantics | `docs/user-guide.md`, `README.md`, release/help notes if touched during implementation |
| Reviewer / operator guidance | Require audit of capability labels, stable-key compatibility, and `004` vs `005` roadmap truth | `.specrew/team/agents/reviewer.md`, `.agents/agents/reviewer.md`, `extensions/specrew-speckit/squad-templates/agents/reviewer/charter.md`, `.specify/extensions/specrew-speckit/squad-templates/agents/reviewer/charter.md`, Iteration `005` review/evidence artifacts |
| Tests / scripted evidence | Prove audited coverage and legacy-profile compatibility without migration | `tests/integration/f049-i003-intake-engine-tests.ps1`, start-flow/manual smoke surfaces if wording assertions are needed, `specs/049-pipeline-hardening-intake/iterations/005/quality/quality-evidence.md` |

## Next-Phase Guardrails

- **Do not generate implementation tasks in this refresh**; task packaging is the next phase.
- Task generation MUST treat Iteration `004` as a reserved-but-unopened slice, not as missing scope that should be reordered or reopened.
- Tasks for Iteration `005` MUST preserve `FR-033` by keeping persisted schema keys and internal persona IDs stable.
- If implementation touches mirrored intake guidance, both shipped and `.specify` copies MUST be updated in the same boundary.
- Compatibility proof MUST include legacy `user-profile.yml` fixtures demonstrating unchanged key loading and unchanged routing/depth behavior.
- No planning surface may continue to claim “four iterations” or “Iteration `003` planning”.
