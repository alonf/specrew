# Implementation Plan: Release Pipeline Hardening + Substantive Intake Slice

**Branch**: `049-pipeline-hardening-intake` | **Date**: 2026-05-28 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `specs/049-pipeline-hardening-intake/spec.md`

**Note**: This plan implements F-049 across 4 iterations: Docker pre-publish verification (Iteration 001, closed), troubleshooting guide (Iteration 002, closed), persona-driven intake with **engine + data architecture** (Iteration 003, planning), and five-pillar bypass detection (Iteration 004, future).

## Summary

F-049 addresses four critical production-hardening needs: (1) Docker-based pre-publish verification to block corrupt FileList layouts before PSGallery release; (2) durable troubleshooting documentation covering recovery flows, side-by-side cache issues, and Shape-5 durability lessons; (3) persona-driven `/speckit.specify` intake with expertise-aware depth adaptation, user-level profile persistence, and **engine + data architecture foundation** enabling future persona/domain/question expansion as YAML-only additions; (4) Proposal 120 five-pillar governance bypass detection before iteration closeout.

**Iteration 003 Architectural Pivot**: The spec has been updated to require a **discrete intake engine + data layer** architecture rather than inline prompt/workflow logic. This pivot enables future 5th+ personas, domain bundles, solution-type bundles, and stack-specific auto-decision defaults to land as **data-only YAML additions** without engine rewrites. Iteration 003 now carries the foundational engine (`Invoke-SpecifyIntake.ps1`), YAML catalogs (personas, categories, depth-rules, questions, auto-decision-defaults), mirror parity between `extensions/specrew-speckit/scripts/intake/*` and `.specify/extensions/specrew-speckit/scripts/intake/*`, and stack-detection mechanism. This architectural foundation is the primary work of Iteration 003, with prompts/agents/workflows as thin orchestrators consuming the engine.

## Technical Context

**Language/Version**: PowerShell 7.4+ (cross-platform), YAML 1.2 (data catalogs)  
**Primary Dependencies**: Docker (pre-publish verification), PowerShell Gallery API (version checks), F-021 slash-command machinery  
**Storage**: User-level `~/.specrew/user-profile.yml`, project-level `.specify/intake/*.yml` catalogs  
**Testing**: Pester integration tests, Docker E2E harness  
**Target Platform**: Windows, macOS, Linux (PowerShell Core cross-platform support)  
**Project Type**: PowerShell module (Spec Kit layer) + governance framework  
**Performance Goals**: <5s intake mode evaluation, <10s user-profile persistence  
**Constraints**: Cross-platform path handling, PSGallery network latency tolerance, backward-compatible YAML schema  
**Scale/Scope**: 4 personas, 12 categories, minimal question banks (3 questions/persona for v1), extensible to 5th+ personas and domain bundles as data-only additions

## Phase 1 Quality Planning

> Fill this section when the stack-aware quality-bar capability applies to the active feature. Keep it bounded to the implemented Phase 1 slice only.

**Phase Scope**: `phase-1-first-slice`  
**Inferred Quality Profile**: [e.g., `quality-profile.node-public-ws-service.v1` or `quality-profile.custom-composition.v1`]  
**Selected preset ref or explicit custom composition**: [List the selected preset ref or explicit custom composition for this feature.]  
**Bounded custom composition**: [If no recognized Phase 1 preset matches cleanly, describe the bounded custom composition path and the manual unknowns it leaves explicit.]

### Stack Surfaces in Scope

| Stack Surface | Path Globs / Evidence | Recognized Stack | Why It Matters |
| --- | --- | --- | --- |
| [e.g., `api-runtime`] | [e.g., `src/api/**`, `package.json`] | [preset ID or `custom`] | [material feature surface] |

### Risk Dimensions

| Risk Dimension | Status (`required` / `not-applicable`) | Rationale |
| --- | --- | --- |
| [e.g., `security`] | [required] | [why this dimension is active] |

### Quality Tool Bundle

| Area | Selection | Evidence / Notes |
| --- | --- | --- |
| Bundle ID | [tool bundle identifier] | [how it maps to the feature] |
| Mechanical Checks | [dead-field, anti-pattern, test-integrity] | [where evidence will be recorded] |
| Ecosystem Tools | [stack-aware lint/test/analyzer commands] | [free/community baseline when practical] |

### Required Quality Gates

| Required Quality Gate | Category | Evidence Source | Phase 1 Status |
| --- | --- | --- | --- |
| [gate ID] | [mechanical/tooling/manual-evidence] | [command or artifact path] | [planned] |

### Not-Applicable Dimensions and Rationale

| Dimension / Gate | Why Not Applicable in This Feature | Follow-up |
| --- | --- | --- |
| [e.g., `concurrency-correctness-review`] | [explicit rationale] | [recorded defer or none] |

### Explicit Phase 2+ Deferrals

- Pre-implementation hardening gate sign-off and blocking semantics remain deferred in this template.
- Dedicated bug-hunter lens execution and strongest-class routing remain deferred in this template.
- Quality-drift logic, mixed-stack override workflows, and reference-implementation comparison remain deferred in this template.

## Phase 2 Hardening and Specialist Review Planning

> Fill this section when pre-implementation hardening and specialist bug-hunter review planning apply to the active feature. Mirror the bounded Phase 2 planning metadata from quality-profile resolution when available: slice scope, artifact refs, focus-area statuses, lens activation classifications, routing defaults, and explicit later deferrals, plus the planning-time-vs-runtime evidence boundary. Keep it bounded to the currently approved hardening slice; record planning-time analysis, expected controls, rationale, explicit non-applicable reasoning, and any narrow runtime-only deferments instead of implying later execution or runtime proof already happened.

**Phase 2 Slice Scope**: [e.g., `US-2 hardening gate only` or `NEEDS CLARIFICATION`]  
**Hardening Gate Artifact**: [e.g., `specs/[###-feature-name]/quality/hardening-gate.md`]  
**Known-Traps Corpus Location**: [e.g., `.specrew/quality/known-traps.md`]  
**Trap Reapplication Artifact**: [e.g., `specs/[###-feature-name]/quality/trap-reapplication.md` or `none yet`]

### Hardening Focus Areas

| Focus Area | Why It Matters in This Slice | Planned Artifact / Evidence | Status (`required` / `deferred` / `not-applicable`) |
| --- | --- | --- | --- |
| Security surface analysis | [record planning-time analysis, exposed trust boundaries, expected controls, and whether runtime proof is still pending for closure] | [hardening artifact section or linked evidence] | [required] |
| Error handling and failure semantics | [record user-visible failures, expected controls, retry boundaries, and fallback expectations] | [hardening artifact section or linked evidence] | [required] |
| Retry and idempotency expectations | [record whether retry logic exists, is forbidden, or needs explicit justification, including non-applicable reasoning when valid] | [hardening artifact section or linked evidence] | [required] |
| Test-integrity targets | [record what proves the slice is actually exercised now, what runtime-only proof remains pending, and what gaps remain explicit] | [test plan, command, or review artifact] | [required] |

### Lens Activation Plan

| Lens / Checklist Ref | Activation (`required` / `optional` / `not-applicable`) | Why Activated or Omitted | Planned Evidence / Artifact Path |
| --- | --- | --- | --- |
| [e.g., `security-issues-v1`] | [required] | [scope, stack, architecture, or risk-dimension signal] | [quality/lenses/... or later evidence artifact] |

### Routing Policy

| Lens Scope | Requested Reasoning / Review Class | Effective Class (when run) | Override / Approval Record | Notes |
| --- | --- | --- | --- | --- |
| Required hardening and bug-hunter lenses | [default to strongest available reasoning/review class] | [record actual class when execution happens] | [path to explicit lower-tier override approval or `none`] | [fallback or routing rationale] |

### Explicit Later Deferrals

- Full line-by-line lens execution evidence and runtime-only final proof remain deferred until the approved implementation/review slice authorizes them.
- Known-traps corpus seeding, approved additions, and trap reapplication remain deferred until the dedicated known-traps slice is in scope.
- Strongest-class routing enforcement details and requested-versus-effective execution evidence remain deferred until the routed lens execution path exists.
- Quality-drift comparison, mixed-stack override workflows, and reference-implementation checks remain deferred unless the approved slice explicitly includes them.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Spec Authority Gate**: **PASS** — Plan scope maps to approved F-049 spec.md artifacts across all 4 iterations. Iteration 003 architectural pivot (engine + data) is authoritative from spec TG-013, TG-014, FR-028..FR-031.
- **Layering Gate**: **PASS** — All F-049 changes are Spec Kit layer: Docker harness (Iteration 001), troubleshooting docs (Iteration 002), intake engine + YAML catalogs (Iteration 003), bypass detection (Iteration 004). No Squad layer or team configuration changes.
- **Traceability Gate**: **PASS** — Every iteration maps to explicit FR/SC/TG: Iteration 001 (FR-001..FR-005, FR-012..FR-014, SC-001, TG-001, TG-007), Iteration 002 (FR-006..FR-007, FR-015..FR-017, SC-002, TG-002, TG-007), Iteration 003 (FR-008..FR-011, FR-023..FR-031, SC-003, SC-005, SC-006, TG-003, TG-006, TG-007, TG-009..TG-015), Iteration 004 (FR-018..FR-022, SC-004, TG-004, TG-007, TG-008).
- **Ownership Gate**: **PASS** — Roles defined: Spec Steward (F-049 specs/clarification), Planner (iteration planning), Implementer (code/docs), Reviewer (E2E PR audit, SC validation).
- **Capacity Gate**: **PASS** — Effort unit: story_points. Feature total: 48-58 SP. Iteration 001: 17 SP actual (closed). Iteration 002: 4-6 SP (closed). Iteration 003: 21-25 SP (architectural foundation work, justified by engine + data pivot). Iteration 004: 6-10 SP (bypass detection). Remaining: 31-41 SP after F-049.
- **Drift/Reconciliation Gate**: **PASS** — Drift detected via `validate-governance.ps1`, Docker E2E pre-publish harness (Iteration 001), and Iteration 004 bypass-detection rules cross-checking closeout evidence against canonical repository state.
- **Verification Gate**: **PASS** — Process quality verified via governance validator. Artifact consistency verified via manual committed-tree checks (Iterations 001-003, manual Pillar 5 discipline) and mechanized Pillar 5 validation (Iteration 004). Acceptance-criteria validated per SC-001 (100% pre-publish blocking), SC-002 (troubleshooting completeness), SC-003 (substantive intake quality), SC-005 (expertise-dial effectiveness), SC-006 (5th-persona extensibility proof), SC-004 (bypass-detection coverage).

## Project Structure

### Documentation (this feature)

```text
specs/049-pipeline-hardening-intake/
├── spec.md                              # Authoritative feature specification
├── plan.md                              # This file (feature-level implementation plan)
├── iterations/
│   ├── 001/
│   │   ├── plan.md                      # Iteration 001 plan (Docker pre-publish verification)
│   │   └── quality/                     # Iteration 001 verification evidence
│   ├── 002/
│   │   ├── plan.md                      # Iteration 002 plan (Troubleshooting guide)
│   │   └── quality/                     # Iteration 002 verification evidence
│   ├── 003/
│   │   ├── plan.md                      # Iteration 003 plan (Persona intake + engine/data architecture)
│   │   └── quality/                     # Iteration 003 verification evidence
│   └── 004/
│       ├── plan.md                      # Iteration 004 plan (Five-pillar bypass detection)
│       └── quality/                     # Iteration 004 verification evidence
└── research.md                          # Research findings (if needed for Iteration 003 architectural foundation)
```

### Source Code (repository root)

**Iteration 001 (Docker Pre-Publish Verification)**:
```text
.github/workflows/
└── publish-module.yml                   # Pre-publish Docker harness integration

tests/
└── docker/
    ├── Dockerfile                       # Linux PowerShell container base
    ├── test-harness.ps1                 # FileList verification + specrew update tests
    └── fixtures/                        # Test data for harness validation
```

**Iteration 002 (Troubleshooting Guide)**:
```text
docs/
├── troubleshooting.md                   # Recovery flows, cache issues, Shape-5 lesson
├── getting-started.md                   # Updated with troubleshooting cross-references
├── user-guide.md                        # Updated with troubleshooting cross-references
└── README.md                            # Updated with troubleshooting cross-references

Specrew.psd1                             # FileList updated to include docs/troubleshooting.md
```

**Iteration 003 (Persona Intake + Engine/Data Architecture)**:
```text
# Engine Foundation (FR-028: Mirror Parity Required)
extensions/specrew-speckit/scripts/intake/
├── Invoke-SpecifyIntake.ps1             # Discrete intake engine (shipped in module)
├── helpers/
│   ├── Load-PersonaCatalog.ps1
│   ├── Load-CategoryCatalog.ps1
│   ├── Resolve-PerLensMode.ps1          # Per-lens Mode A/B/C evaluation + most-conservative-wins
│   ├── Traverse-QuestionBank.ps1
│   ├── Resolve-AutoDecision.ps1
│   └── Render-Annotation.ps1

.specify/extensions/specrew-speckit/scripts/intake/
├── Invoke-SpecifyIntake.ps1             # Mirror copy (project-local override path)
├── helpers/                             # Mirror copy
│   ├── Load-PersonaCatalog.ps1
│   ├── Load-CategoryCatalog.ps1
│   ├── Resolve-PerLensMode.ps1
│   ├── Traverse-QuestionBank.ps1
│   ├── Resolve-AutoDecision.ps1
│   └── Render-Annotation.ps1

# Data Catalogs (FR-029)
.specify/intake/
├── personas.yml                         # 4 personas (PM, UX/UI, Architect, AI Researcher/PM)
├── categories.yml                       # 12 categories
├── depth-rules.yml                      # Per-lens mode thresholds (dial/completeness → Mode A/B/C)
├── questions/
│   ├── product-manager.yml              # 3 questions minimum (v1 capacity constraint)
│   ├── ux-ui-specialist.yml             # 3 questions minimum
│   ├── architect.yml                    # 3 questions minimum
│   └── ai-researcher-project-manager.yml # 3 questions minimum
├── auto-decision-defaults/
│   └── generic.yml                      # Stack-agnostic defaults (v1 only; stack-specific later)
├── domain-bundles/                      # Reserved empty (FR-030)
└── solution-type-bundles/               # Reserved empty (FR-030)

# User Profile Persistence (FR-024)
~/.specrew/
└── user-profile.yml                     # User-level expertise profile (cross-project)

# Slash Command Deployment (FR-025)
.claude/skills/
└── specrew-user-profile.md              # /specrew-user-profile show/edit/reset

.github/skills/
└── specrew-user-profile.md              # /specrew-user-profile show/edit/reset

.agents/skills/
└── specrew-user-profile.md              # /specrew-user-profile show/edit/reset

# Thin Orchestrators (consume engine, do not contain inline logic)
.github/prompts/
└── speckit.specify.prompt.md            # Updated to invoke Invoke-SpecifyIntake.ps1

.github/agents/
└── speckit.specify.agent.md             # Updated to invoke Invoke-SpecifyIntake.ps1

.specify/workflows/speckit/
└── workflow.yml                         # Updated to invoke Invoke-SpecifyIntake.ps1

# Bootstrap Integration (FR-026)
scripts/
└── specrew-start.ps1                    # First-run expertise self-rating + profile summary

# Tests (SC-006 extensibility proof)
tests/integration/
├── substantive-interaction-model-iteration2.ps1  # Persona intake + expertise-dial tests
└── skill-templates.tests.ps1            # Slash-command functionality tests
```

**Iteration 004 (Five-Pillar Bypass Detection)**:
```text
scripts/
└── validate-governance.ps1              # Five-pillar bypass detection (handoff, trigger-bypass, artifact-location, verdict-history, tree-under-review)

tests/integration/
└── governance-bypass-detection.tests.ps1 # Pillar 1-5 validation tests
```

**Structure Decision**: F-049 is a PowerShell module enhancement spanning scripts, documentation, test infrastructure, and governance validation. The core architectural pivot in Iteration 003 is the separation of engine (PowerShell scripts in `extensions/specrew-speckit/scripts/intake/` with mirror parity in `.specify/extensions/specrew-speckit/scripts/intake/`) and data (YAML catalogs in `.specify/intake/`). This enables future persona/category/question/domain-bundle additions as data-only changes without touching engine code or versioned module manifests.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

**No violations** — F-049 passes all constitutional gates. The architectural pivot to engine + data in Iteration 003 is justified by SC-006 (5th-persona extensibility proof) and TG-013 (modular design enabling future growth as data-only additions), not complexity accumulation.

---

## Iteration Breakdown

### Iteration 001: Docker Pre-Publish Verification (Closed)

**Status**: Complete  
**Capacity**: 17 SP actual (12 SP Docker harness + 5 SP regression fixes)  
**Scope**: FR-001..FR-005, FR-012..FR-014, SC-001, TG-001, TG-007  
**Deliverables**:
- Docker-based E2E test harness (Linux PowerShell container)
- FileList verification + specrew update tests
- `.github/workflows/publish-module.yml` integration (blocker before PSGallery publish)
- Manifest version-pin drift detection (Proposal 134 Pillar 1+3 incremental)
- Squad duplicate-row fix (`specrew update` template merge)
- PSGallery --info version check (Proposal 049 promotion)

**Outcome**: 100% of missing FileList or corrupt layouts blocked before PSGallery upload (SC-001 met).

---

### Iteration 002: Troubleshooting Guide (Closed)

**Status**: Complete  
**Capacity**: 4-6 SP actual  
**Scope**: FR-006..FR-007, FR-015..FR-017, SC-002, TG-002, TG-007  
**Deliverables**:
- `docs/troubleshooting.md` (recovery flows, cache issues, Shape-5 lesson)
- FileList registration for troubleshooting.md in Specrew.psd1
- Cross-references from README.md, docs/getting-started.md, docs/user-guide.md
- `specrew update` vs `Update-Module Specrew` distinction
- Shape-5 durability lesson (accepted evidence must match committed tree)

**Outcome**: Troubleshooting guide exists, is discoverable, and explains recovery flows + Shape-5 lesson (SC-002 met).

---

### Iteration 003: Persona Intake + Engine/Data Architecture (Planning)

**Status**: Planning  
**Capacity**: 21-25 SP (soft cap justified by architectural foundation work)  
**Scope**: FR-008..FR-011, FR-023..FR-031, SC-003, SC-005, SC-006, TG-003, TG-006..TG-007, TG-009..TG-015  
**Architectural Pivot**: Engine + data separation is **primary work**. Iteration 003 builds the discrete intake engine (`Invoke-SpecifyIntake.ps1`), YAML catalog structure (`personas.yml`, `categories.yml`, `depth-rules.yml`, `questions/<persona>.yml`, `auto-decision-defaults/generic.yml`), mirror parity between `extensions/specrew-speckit/scripts/intake/*` and `.specify/extensions/specrew-speckit/scripts/intake/*`, stack-detection mechanism, and extensibility proof (SC-006: adding 5th persona requires only YAML additions, zero engine changes). Prompts, agents, and workflows are thin orchestrators consuming the engine.

**Deliverables**:
- **Engine Foundation (FR-028)**:
  - `Invoke-SpecifyIntake.ps1` (discrete intake engine)
  - Helper sub-scripts: persona-catalog loading, category-catalog loading, per-lens depth-rule application (Mode A/B/C evaluation + most-conservative-wins), question-bank traversal, auto-decision resolution, annotation rendering
  - Mirror parity: `extensions/specrew-speckit/scripts/intake/*` (shipped) and `.specify/extensions/specrew-speckit/scripts/intake/*` (project-local)
  
- **Data Catalogs (FR-029)**:
  - `.specify/intake/personas.yml` (4 personas: Product Manager, UX/UI Specialist, Architect, AI Researcher/Project Manager)
  - `.specify/intake/categories.yml` (12 categories)
  - `.specify/intake/depth-rules.yml` (per-lens mode thresholds: dial ≥7 + ≥75% completeness → Mode A; dial 4-6 or 40-74% completeness → Mode B; dial ≤3 or <40% completeness → Mode C; most-conservative-wins conflict resolution)
  - `.specify/intake/questions/<persona>.yml` (3 questions/persona minimum for v1 capacity constraint)
  - `.specify/intake/auto-decision-defaults/generic.yml` (stack-agnostic defaults)
  
- **Extension Hooks (FR-030)**:
  - `.specify/intake/domain-bundles/` (reserved empty)
  - `.specify/intake/solution-type-bundles/` (reserved empty)
  
- **Stack-Aware Defaults (FR-031)**:
  - Stack-detection mechanism (detect `.csproj`, `pyproject.toml`, `package.json`)
  - Fallback to `generic.yml` (v1 only; stack-specific files land later as data additions)
  
- **User Profile Persistence (FR-024, FR-026)**:
  - `~/.specrew/user-profile.yml` schema and cross-platform path handling
  - `specrew start` first-run expertise self-rating prompt (4 personas, 1-10 scale or "I'm new, you decide")
  - Profile summary in `start-context.json` and `start-summary.md`
  
- **Slash Command (FR-025)**:
  - `/specrew-user-profile` in `.claude/skills/`, `.github/skills/`, `.agents/skills/`
  - Subcommands: `show`, `edit`, `reset`
  
- **Intake Consumption (FR-027)**:
  - Updated `.github/prompts/speckit.specify.prompt.md` (invoke engine)
  - Updated `.github/agents/speckit.specify.agent.md` (invoke engine)
  - Updated `.specify/workflows/speckit/workflow.yml` (invoke engine)
  - Expertise-driven question depth: 7-10 (Senior, nuanced questions), 4-6 (Standard, confirmation prompts), 1-3 (Learning, auto-decide + transparency annotations)
  - Proposal 053 transparency: `[AUTO-DECIDED: <decision>]` annotations for low-expertise auto-decisions
  
- **Per-Lens Mode Branching (FR-010)**:
  - Each persona lens independently evaluated against its own expertise dial and lens-completeness percentage
  - Most-conservative-wins conflict resolution (C > B > A) ensures low-expertise or incomplete lenses drive overall intake depth
  
- **Extensibility Proof (SC-006)**:
  - Test fixture: temporary 5th persona added to `personas.yml` + `questions/<new-persona>.yml`
  - Verification: persona recognized, questions loaded, expertise-dial behavior adapts—all without touching engine code

**Outcome**:
- SC-003: `/speckit.specify` generates highly contextual specs tailored to 4 persona lenses, <2 subsequent clarify questions in 90% of runs when expertise dial is 4+
- SC-005: ≥30% question reduction for dial 7-10, ≥40% decision reduction for dial 1-3, no clarify-question regression
- SC-006: Adding 5th persona demonstrably achievable as YAML-only data addition (zero engine changes)

**Capacity Justification**: 21-25 SP reflects the architectural foundation work (FR-028 engine + FR-029 data catalogs + FR-030 extension hooks + FR-031 stack detection) that enables future extensibility. This is 4-5 SP higher than the old 17-20 SP estimate because the pivot from inline logic to modular engine + data requires upfront investment in sub-helper architecture, mirror parity, and YAML catalog design. The payoff is that future 5th+ personas, domain bundles, solution-type bundles, and stack-specific defaults will land as data-only additions without touching engine code or module manifests.

---

### Iteration 004: Five-Pillar Bypass Detection (Future)

**Status**: Planned (not started)  
**Capacity**: 6-10 SP  
**Scope**: FR-018..FR-022, SC-004, TG-004, TG-007, TG-008  
**Deliverables**:
- Pillar 1: Missing `=== SPECREW HANDOFF ===` detection
- Pillar 2: Trigger-bypass artifact gap classification
- Pillar 3: Ephemeral session-scratch location warnings
- Pillar 4: State-advance-without-verdict-history detection
- Pillar 5: Tree-under-review vs accepted-evidence file-presence validation (blocks closeout when production evidence is absent from cited tree)

**Outcome**: SC-004 met (all five bypass pillars surface, 0 closeouts allowed when production evidence is absent from committed tree).

---

## Feature Capacity Summary

| Iteration | Status | Planned SP | Actual SP | Scope |
| --------- | ------ | ---------- | --------- | ----- |
| 001 | Closed | 12-15 | 17 | Docker pre-publish verification + regression fixes |
| 002 | Closed | 4-6 | 4-6 | Troubleshooting guide + cross-references |
| 003 | Planning | 21-25 | TBD | Persona intake + **engine/data architecture foundation** |
| 004 | Planned | 6-10 | TBD | Five-pillar bypass detection |
| **Total** | - | **48-58** | **21-23 (so far)** | **Remaining: 31-41 SP** |

**Architectural Pivot Impact**: Iteration 003 capacity increased from 17-20 SP to 21-25 SP due to the engine + data separation required by TG-013. The pivot is justified by SC-006 (5th-persona extensibility proof) and TG-013 (modular design enabling future growth as data-only additions). This upfront investment ensures that future personas, domain bundles, and stack-specific defaults will not require engine rewrites or module manifest versioning.
