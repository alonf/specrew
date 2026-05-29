# Implementation Plan: Release Pipeline Hardening + Substantive Intake Slice

**Branch**: `049-pipeline-hardening-intake` | **Date**: 2026-05-28 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `specs/049-pipeline-hardening-intake/spec.md`

**Note**: This refreshed plan restores roadmap truth for Feature `049`: it is a **five-iteration** feature. Iterations `001`-`003` are closed, Iteration `004` remains the reserved Proposal `120` five-pillar bypass-detection slice unchanged, and Iteration `005` is the newly planned Proposal `141` **Crew Interaction Profile / Persona Lens Separation** slice. This refresh does **not** reopen Iteration `003` and does **not** reduce or reinterpret Iteration `004`.

## Summary

Feature `049` now carries a truthful five-iteration roadmap aligned to the updated spec at `HEAD 14de1147`. Iteration `005` is a bounded **6-8 SP** correction slice that reframes the saved values as a **Crew Interaction Profile** rather than user identity/persona claims, preserves stable persisted keys and internal persona IDs, keeps `/speckit.specify` as the only hard-applied behavior in this release, and adds explicit session-context, loader/path-rule, and multi-developer-safety planning truth. The slice covers soft collaboration guidance for all agents via current-user session context, durable shared instructions that point to the current-user profile loader/path rule instead of concrete dial values, and compatibility proof that existing `user-profile.yml` files load unchanged and preserve internal routing and question-depth behavior.

## Technical Context

**Language/Version**: PowerShell 7.x plus Markdown/YAML/JSON governance assets  
**Primary Dependencies**: Specrew module scripts, Spec Kit extension assets, slash-command skills, intake YAML catalogs, reviewer/operator guidance surfaces  
**Storage**: Current-user `user-profile.yml` resolved via `$env:USERPROFILE\.specrew\user-profile.yml` on Windows or `~/.specrew/user-profile.yml` on Unix-like systems, plus project-local `.specrew/start-summary.md`, `.specrew/start-context.json`, `.specrew/last-start-prompt.md`, and review/evidence artifacts  
**Testing**: PowerShell integration tests, scripted evidence artifacts, paired-developer validation, reviewer/operator audit evidence  
**Target Platform**: Cross-platform PowerShell (Windows/Linux/macOS) with GitHub Copilot / Claude / Agents skill surfaces  
**Project Type**: PowerShell module with documentation, prompt, skill, and governance overlays  
**Performance Goals**: Preserve existing profile-load, internal-lens routing, and `/speckit.specify` question-depth behavior while correcting user-facing wording and shared-guidance semantics only  
**Constraints**: No schema migration, no persisted-key rename, no internal persona ID rename, no Iteration `003` reopening, no Iteration `004` scope drift, no shared-repository persistence of resolved per-developer profile values  
**Scale/Scope**: Bounded planning slice touching first-run/profile/help/session-context/shared-guidance/reviewer surfaces across shipped and mirrored paths

## Constitution Check

| Gate | Verdict | Notes |
| ---- | ------- | ----- |
| Spec Authority | PASS | Scope is anchored to `FR-032..FR-041`, `SC-007..SC-008`, and `TG-016..TG-018` in `spec.md`. |
| Layering | PASS | Work remains a presentation/guidance/evidence correction over the existing intake/profile runtime; no new persona architecture, schema split, or fifth lens is introduced. |
| Traceability | PASS | Iteration `005` is explicitly mapped to User Story `3`, Proposal `141`, soft session-context guidance, durable loader/path rules, and preserved Iteration `004` Proposal `120` reservation. |
| Ownership | PASS | Planner owns package refresh now; later work splits between Implementer (runtime/docs/guidance) and Reviewer (audit/evidence/paired-developer proof). |
| Capacity | PASS | Iteration `005` is bounded to **6-8 story points**. Feature roadmap truth is **54-66 SP** across all five iterations. |
| Drift/Reconciliation | PASS | This refresh removes stale “3-5 SP” and incomplete `FR-032..FR-037` planning truth, while preserving the explicit `004`-reserved / `005`-planned caveat. |
| Verification | PASS | Compatibility proof, audited-surface coverage, current-user loader/path rule coverage, mirror parity, and multi-developer safety evidence are mandatory before Iteration `005` can close. |

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

.specrew/team/agents/reviewer.md
.agents/agents/reviewer.md

tests/integration/f049-i003-intake-engine-tests.ps1
```

**Structure Decision**: Feature `049` remains a PowerShell module enhancement spanning scripts, docs, skills, prompts, mirrored Spec Kit assets, and review/evidence artifacts. Iteration `005` is intentionally bounded: it corrects user-facing semantics, session-context usage, durable shared-instruction rules, and compatibility proof around the existing four-lens architecture rather than changing intake catalogs, persisted schema, or internal lens IDs.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

**No violations** — this refresh tightens roadmap truth, slice capacity truth, and current-user guidance discipline rather than adding architectural complexity.

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

**Protection Rule**: Proposal `120` stays fully anchored here. Nothing in Iteration `005` may reduce, reinterpret, defer, or partially absorb this slice.

---

### Iteration 005: Crew Interaction Profile / Persona Lens Separation (Planning)

**Status**: Planning  
**Capacity**: 6-8 SP  
**Scope**: `FR-032..FR-041`, `SC-007`, `SC-008`, `TG-003`, `TG-006`, `TG-007`, `TG-016..TG-018`

**Deliverables**:

- Crew Interaction Profile wording across first-run, profile, help, and summary surfaces
- Stable-key and internal-persona-ID preservation with unchanged internal lens execution
- Visible fourth decision-area label fixed to **AI Delivery Planning**
- Explicit copy separating the user's Crew Interaction Profile from Specrew's internal persona lenses
- Soft collaboration guidance for all agents via current-user runtime session context
- Durable shared instructions pointing to the current-user profile loader/path rule, not hard-coded dial values
- Explicit `/speckit.specify`-only hard-application boundary
- Multi-developer safety guidance and proof that different local profiles can coexist in the same repository
- Scripted legacy `user-profile.yml` compatibility proof with unchanged routing and question-depth behavior

**Outcome Targets**: `SC-007`, `SC-008`.

**Boundary Rule**: This is a follow-on correction slice only. It does **not** split the fourth internal lens, add a fifth lens, migrate persisted profile data, or hard-apply the profile outside `/speckit.specify`.

---

## Feature Capacity Summary

| Iteration | Status | Planned SP | Actual / Forecast SP | Notes |
| --------- | ------ | ---------- | -------------------- | ----- |
| 001 | Closed | 17 | 17.00 | Completed release hardening slice. |
| 002 | Closed | 4-6 | 4.00 | Closed documentation slice. |
| 003 | Closed | 21-25 | 23.45 | Architectural pivot completed. |
| 004 | Reserved | 6-10 | TBD | Proposal `120` full five-pillar bypass detection. |
| 005 | Planning | 6-8 | TBD | Proposal `141` Crew Interaction Profile / Persona Lens Separation slice. |
| **Total** | - | **54-66** | **44.45 consumed + 12-18 remaining = 56.45-62.45 projected** | **Roadmap truth is now aligned to the updated five-iteration spec.** |

## Iteration 005 Planning Decisions

1. **Reframed slice title**: `Crew Interaction Profile / Persona Lens Separation`.
2. **All four visible labels are decision-area labels**: `Product Strategy`, `UX/UI Design`, `Software Architecture`, `AI Delivery Planning`.
3. **Persisted schema and internal IDs stay unchanged**: including `expertise.ai_research_project_management` and `ai-researcher-project-manager`.
4. **Soft guidance for all agents**: current-user session context may inform how much to ask, explain, recommend, and auto-decide across the session.
5. **Only one hard-applied behavior in this release**: `/speckit.specify`.
6. **Durable shared instructions must reference the loader rule**: point to the current-user profile path/loader, not concrete dial values or a specific developer's resolved settings.
7. **Multi-developer safety is explicit**: paired developers may resolve different local profiles in the same repository without shared repo changes.
8. **No Iteration 003 reopen**: this slice corrects semantics, session-context framing, durable guidance, and proof surfaces only.
9. **No Iteration 004 drift**: Proposal `120` remains fully reserved in Iteration `004`.

## Iteration 005 Audit Inventory

| Surface Group | Correction Need | Candidate Paths |
| ------------- | --------------- | --------------- |
| First-run prompt | Replace persona/job-title framing with Crew Interaction Profile framing and clear decision-area language | `scripts/internal/user-profile.ps1`, `scripts/specrew-start.ps1` |
| Profile display / edit / reset | Show decision-area labels while preserving existing keys and internal persona IDs | `scripts/internal/user-profile.ps1`, `.github/skills/specrew-user-profile/SKILL.md`, `.claude/skills/specrew-user-profile/SKILL.md`, `.agents/skills/specrew-user-profile/SKILL.md` |
| Start summaries / runtime session context | Surface the resolved current user's Crew Interaction Profile as soft session guidance without treating it as shared project truth | `scripts/specrew-start.ps1` -> `.specrew/start-summary.md`, `.specrew/start-context.json`, `.specrew/last-start-prompt.md` |
| Specify guidance | Explain that the profile is soft session guidance generally, but `/speckit.specify` is the only hard-applied behavior in this release | `.github/prompts/speckit.specify.prompt.md`, `.github/agents/speckit.specify.agent.md`, `extensions/specrew-speckit/scripts/intake/Invoke-SpecifyIntake.ps1`, `.specify/extensions/specrew-speckit/scripts/intake/Invoke-SpecifyIntake.ps1` |
| Shared instructions / durable guidance | Replace hard-coded dial guidance with the current-user profile loader/path rule | `README.md`, `docs/user-guide.md`, reviewer/operator guidance surfaces, session bootstrap guidance |
| Reviewer / operator guidance | Require audit of capability labels, stable-key compatibility, current-user loader/path rule, soft-vs-hard boundary, and multi-developer safety | `.specrew/team/agents/reviewer.md`, `.agents/agents/reviewer.md`, `extensions/specrew-speckit/squad-templates/agents/reviewer/charter.md`, `.specify/extensions/specrew-speckit/squad-templates/agents/reviewer/charter.md`, Iteration `005` review/evidence artifacts |
| Tests / scripted evidence | Prove audited coverage, loader-rule correctness, legacy-profile compatibility, and paired-developer safety without migration | `tests/integration/f049-i003-intake-engine-tests.ps1`, start-flow/manual smoke surfaces if wording assertions are needed, `specs/049-pipeline-hardening-intake/iterations/005/quality/quality-evidence.md` |

## Next-Phase Guardrails

- **Do not reinterpret Iteration `004`**; Proposal `120` remains a reserved-but-unopened slice and must stay unchanged.
- Task generation for Iteration `005` MUST cover `FR-032..FR-041`, `SC-007`, and `SC-008`.
- Tasks for Iteration `005` MUST preserve `FR-033` by keeping persisted schema keys and internal persona IDs stable.
- If implementation touches mirrored intake guidance, both shipped and `.specify` copies MUST be updated in the same boundary.
- Durable shared instructions MUST point to the current-user profile loader/path rule rather than concrete dial values.
- Compatibility proof MUST include legacy `user-profile.yml` fixtures demonstrating unchanged key loading, unchanged internal routing, and unchanged `/speckit.specify` depth behavior.
- Multi-developer proof MUST show that different developers can resolve different local profile guidance in the same repository without committing per-developer values.
- No planning surface may continue to claim “3-5 SP” or omit the `FR-038..FR-041` / `SC-008` requirements from Iteration `005`.
