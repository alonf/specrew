# Implementation Plan: Legacy-State Read-Tolerance + Schema Migration Discipline

**Branch**: `023-legacy-state-read-tolerance` | **Date**: 2026-05-19 | **Spec**: file:///C:/Dev/Specrew-023/specs/023-legacy-state-read-tolerance/spec.md
**Input**: Feature specification from `/specs/023-legacy-state-read-tolerance/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

Implement schema versioning and reader tolerance for Specrew state files to prevent crashes during version upgrades. Add explicit `schema: v1` markers to all persisted state files, migrate readers to hashtable-based parsing to tolerate missing fields, create legacy fixture corpus (versions 0.18.0-0.22.0) for continuous regression testing, and provide validator rules to enforce the pattern. This establishes foundational discipline for safe schema evolution across the 059 → 060 → 042 bug-prevention triad.

## Technical Context

**Language/Version**: PowerShell 7.0+ (per Specrew.psd1 PowerShellVersion requirement)
**Primary Dependencies**: PowerShell-Yaml module (for YAML parsing), ConvertFrom-Json -AsHashtable (available in PS 6.0+)
**Storage**: Local filesystem state files (JSON, YAML); paths: `.specrew/`, `.specify/`, `.squad/`, `tasks-progress.yml`
**Testing**: Pester 5.x for PowerShell unit/integration tests; legacy fixture corpus at `tests/fixtures/legacy-versions/`
**Target Platform**: Windows, Linux, macOS (cross-platform PowerShell 7.0+)
**Project Type**: CLI tooling / development workflow automation (PowerShell module)
**Performance Goals**: CI fixture test suite must complete within +2 minutes per PR (acceptable within 10-minute CI budget)
**Constraints**: Must preserve backward compatibility with v0 state files (no breaking changes); StrictMode compatibility required; cross-platform line-ending normalization via Git
**Scale/Scope**: ~14 state file types across 5 Specrew versions (0.18.0-0.22.0); ~10-15 reader functions to audit and migrate

## Phase 1 Quality Planning

> Fill this section when the stack-aware quality-bar capability applies to the active feature. Keep it bounded to the implemented Phase 1 slice only.

**Phase Scope**: `phase-1-first-slice`
**Inferred Quality Profile**: `quality-profile.custom-composition.v1`
**Selected preset ref or explicit custom composition**: None - using bounded custom composition
**Bounded custom composition**: Repository and feature signals are weak or unsupported for a confident Phase 1 preset match, so this slice falls back to a bounded custom composition with explicit manual review expectations.

### Stack Surfaces in Scope

| Stack Surface | Path Globs / Evidence | Recognized Stack | Why It Matters |
| --- | --- | --- | --- |
| `custom-phase1-surface` | `**/*`, `package.json` | `custom` | PowerShell module + Node.js tooling; standard ecosystem tools not fully auto-detected |

### Risk Dimensions

| Risk Dimension | Status (`required` / `not-applicable`) | Rationale |
| --- | --- | --- |
| `code-quality` | required | Phase 1 always evaluates code-quality expectations because the quality tool bundle must remain explicit and reviewable. |
| `design-quality-and-separation-of-concerns` | required | Phase 1 always evaluates design quality and separation of concerns so the plan does not hide layering or coupling risks. |
| `verification-confidence` | required | Phase 1 always requires verification confidence so tests and evidence prove observable behavior instead of smoke-only success. |
| `maintainability` | required | Phase 1 always evaluates maintainability because the quality bar must remain stack-aware and reviewable for later iterations. **F-023 explicitly preserves maintainability/testability quality focus per planning requirements.** |
| `security` | required | Phase 1 always evaluates security because every active feature can expose boundary, configuration, or data-handling concerns. **F-023 explicitly preserves security/privacy quality focus per planning requirements.** |
| `robustness` | required | Phase 1 always evaluates robustness so degraded behavior and failure semantics are explicit before implementation continues. |

### Quality Tool Bundle

| Area | Selection | Evidence / Notes |
| --- | --- | --- |
| Bundle ID | `phase1-custom-quality-bundle` | Custom composition for PowerShell module |
| Mechanical Checks | dead-field, anti-pattern, test-integrity | `specs/023-legacy-state-read-tolerance/iterations/<NNN>/quality/mechanical-findings.json` |
| Ecosystem Tools | Pester 5.x (verification), PSScriptAnalyzer (static analysis), existing validator framework from F-013 | Repo-standard PowerShell tooling |

### Required Quality Gates

| Required Quality Gate | Category | Evidence Source | Phase 1 Status |
| --- | --- | --- | --- |
| `dead-field` | mechanical | `specs/023-legacy-state-read-tolerance/iterations/<NNN>/quality/mechanical-findings.json` | planned |
| `anti-pattern` | mechanical | `specs/023-legacy-state-read-tolerance/iterations/<NNN>/quality/mechanical-findings.json` | planned |
| `test-integrity` | mechanical | `specs/023-legacy-state-read-tolerance/iterations/<NNN>/quality/mechanical-findings.json` | planned |
| `stack-tooling-evidence` | tooling | `specs/023-legacy-state-read-tolerance/iterations/<NNN>/quality/quality-evidence.md` | planned |
| `quality-lens-review` | manual-evidence | `specs/023-legacy-state-read-tolerance/iterations/<NNN>/quality/quality-evidence.md` | planned |

### Not-Applicable Dimensions and Rationale

| Dimension / Gate | Why Not Applicable in This Feature | Follow-up |
| --- | --- | --- |
| `concurrency-correctness` | No repository or feature signal shows material shared-state, parallel, or realtime concurrency behavior for this Phase 1 slice. State files are read/written sequentially during CLI command execution. | none |
| `resiliency` | The current Phase 1 slice does not materially depend on retries, reconnect, or degraded recovery behavior beyond the baseline robustness expectation. | none |
| `retry-idempotency-and-recovery` | Retry, idempotency, and recovery-specific gates are not required because the active feature shape does not present a material retry or recovery workflow in this slice. | none |

### Explicit Phase 2+ Deferrals

- Pre-implementation hardening gate sign-off and blocking semantics remain deferred to Phase 2+.
- Dedicated bug-hunter lens execution and strongest-class routing remain deferred to Phase 2+.
- Quality-drift logic, mixed-stack override routing, and reference-implementation comparison remain deferred to Phase 2+.

## Phase 2 Hardening and Specialist Review Planning

> Fill this section when pre-implementation hardening and specialist bug-hunter review planning apply to the active feature. Mirror the bounded Phase 2 planning metadata from quality-profile resolution when available: slice scope, artifact refs, focus-area statuses, lens activation classifications, routing defaults, and explicit later deferrals, plus the planning-time-vs-runtime evidence boundary. Keep it bounded to the currently approved hardening slice; record planning-time analysis, expected controls, rationale, explicit non-applicable reasoning, and any narrow runtime-only deferments instead of implying later execution or runtime proof already happened.

**Phase 2 Slice Scope**: `US-2 hardening-gate planning only; pre-implementation readiness must accept planning-time analysis, expected controls, rationale, and explicit non-applicable reasoning, while runtime-only final proof stays pending until later closure or approved runtime-only deferment.`
**Hardening Gate Artifact**: `specs/023-legacy-state-read-tolerance/iterations/<NNN>/quality/hardening-gate.md`
**Known-Traps Corpus Location**: `.specrew/quality/known-traps.md`
**Trap Reapplication Artifact**: `specs/023-legacy-state-read-tolerance/iterations/<NNN>/quality/trap-reapplication.md`

### Hardening Focus Areas

| Focus Area | Why It Matters in This Slice | Planned Artifact / Evidence | Status (`required` / `deferred` / `not-applicable`) |
| --- | --- | --- | --- |
| Security surface analysis | The hardening gate must capture planning-time security analysis, expected controls, and any explicit non-applicable reasoning before coding begins; runtime proof can remain pending only until later closure. Local state file handling, no network boundaries or credential management in scope. | `specs/023-legacy-state-read-tolerance/iterations/<NNN>/quality/hardening-gate.md` | required |
| Error handling and failure semantics | Silent failure paths, expected controls, and fallback expectations must be made explicit in the hardening gate so implementation does not invent them later or bypass runtime follow-through. Parse errors, missing files, unsupported schema versions covered explicitly in spec edge cases. | `specs/023-legacy-state-read-tolerance/iterations/<NNN>/quality/hardening-gate.md` | required |
| Retry and idempotency expectations | The hardening gate still records why retry and idempotency do not materially apply in this slice so omissions stay reviewable before implementation begins. State file I/O is not retried; read operations are idempotent by nature. | `specs/023-legacy-state-read-tolerance/iterations/<NNN>/quality/hardening-gate.md` | not-applicable |
| Test-integrity targets | The hardening gate must name the planned validation evidence and expected controls for this slice so implementation readiness does not rely on smoke-only success while runtime/test proof remains visibly pending until later closure. Legacy fixture corpus (FR-008) provides explicit regression test evidence. | `feature plan Phase 2 quality planning section plus specs/023-legacy-state-read-tolerance/iterations/<NNN>/quality/quality-evidence.md` | required |

### Lens Activation Plan

| Lens / Checklist Ref | Activation (`required` / `optional` / `not-applicable`) | Why Activated or Omitted | Planned Evidence / Artifact Path |
| --- | --- | --- | --- |
| `security-baseline@v1.0.0` | required | Security is always a materially reviewed baseline dimension, so the security lens stays pre-activated in planning even though row-level execution remains deferred. Local file parsing, no credential exposure expected. | `specs/023-legacy-state-read-tolerance/iterations/<NNN>/quality/lenses/security-baseline.md` |
| `robustness-baseline@v1.0.0` | required | Robustness, failure semantics, and retry-related concerns feed the hardening gate directly, so the robustness lens must be visible as required planning metadata. Parse error handling, missing file tolerance, schema version mismatch behavior all explicit. | `specs/023-legacy-state-read-tolerance/iterations/<NNN>/quality/lenses/robustness-baseline.md` |
| `test-integrity@v1.0.0` | required | Test-integrity targets are part of the pre-implementation hardening review, so this lens stays explicitly required in the bounded plan. FR-008 legacy fixture corpus provides concrete regression test coverage across versions 0.18.0-0.22.0. | `specs/023-legacy-state-read-tolerance/iterations/<NNN>/quality/lenses/test-integrity.md` |

### Routing Policy

| Lens Scope | Requested Reasoning / Review Class | Effective Class (when run) | Override / Approval Record | Notes |
| --- | --- | --- | --- | --- |
| Required hardening and bug-hunter lenses | `strongest-available` | Record when execution happens | Explicit approved lower-tier override required before any downgrade takes effect. | Planning publishes the requested routing baseline only; effective-class evidence stays deferred until the execution path exists. |

### Explicit Later Deferrals

- Full line-by-line lens execution evidence and runtime-only final proof remain deferred until the approved implementation/review slice authorizes them.
- Known-traps corpus seeding, approved additions, and trap reapplication remain deferred until the dedicated known-traps slice is in scope.
- Strongest-class routing enforcement details and requested-versus-effective execution evidence remain deferred until the routed lens execution path exists.
- Quality-drift comparison, mixed-stack override workflows, and reference-implementation checks remain deferred unless the approved slice explicitly includes them.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Spec Authority Gate**: ✅ PASS — Plan scope maps to approved spec file:///C:/Dev/Specrew-023/specs/023-legacy-state-read-tolerance/spec.md. All functional requirements (FR-001 through FR-014), user stories (US-1 through US-3), success criteria (SC-001 through SC-006), and governance alignment explicitly grounded in spec artifacts.

- **Layering Gate**: ✅ PASS — All changes classified as **Spec Kit layer** behavior:
  - Schema versioning discipline (FR-001, FR-002, FR-003) → Spec Kit layer: state file format conventions
  - Reader tolerance patterns (FR-004, FR-005, FR-006) → Spec Kit layer: PowerShell script implementation
  - Legacy fixture corpus (FR-007, FR-008, FR-009) → Spec Kit layer: test infrastructure
  - Validator rule (FR-010, FR-011) → Spec Kit layer: extends existing validator framework from Proposal 004/F-013
  - Documentation (FR-012, FR-013) → Spec Kit layer: governance artifact templates
  - No Squad layer changes, no team configuration changes

- **Traceability Gate**: ✅ PASS — All deliverables traced:
  - User Story 1 → FR-001, FR-002, FR-004, FR-005, FR-006, FR-008, FR-014
  - User Story 2 → FR-002, FR-005, FR-006, FR-008
  - User Story 3 → FR-001, FR-002, FR-003, FR-009
  - Iteration 1 (~14.5 SP): FR-001 through FR-009, FR-014 → `research.md`, `data-model.md`, `contracts/`, fixture corpus, reader migrations
  - Iteration 2 (~5.5 SP): FR-010, FR-011, FR-012, FR-013, FR-014 → validator rule, docs, closeout template updates
  - Task links will be explicit in `tasks.md` (Phase 2 output from `/speckit.tasks`)

- **Ownership Gate**: ✅ PASS — Explicit role ownership defined:
  - **Spec Steward**: Specrew maintainer (human) — accountable for schema design decisions, fixture content validation, alignment with Proposals 059/060/042 triad
  - **Iteration Facilitator**: AI-driven session orchestrator — accountable for iteration cadence, 3-cycle repair budget enforcement at boundaries, blocker escalation
  - **Implementation Owner**: AI-driven developer agents (Specrew's normal development model) — accountable for reader migrations, fixture generation, validator rule implementation
  - **Human Oversight Points**: Before planning (schema strategy alignment), after Iteration 1 (fixture completeness), before Iteration 2 merge (validator false positives), final PR merge (docs clarity)

- **Capacity Gate**: ✅ PASS — Effort unit and capacity budget explicit:
  - **Unit**: Story Points (SP)
  - **Iteration 1 capacity**: ~14.5 SP (schema markers, reader audit + hashtable migration, fixture corpus 0.18.0-0.23.0, dispatch review)
  - **Iteration 2 capacity**: ~5.5 SP (validator rule, docs, closeout template updates)
  - **Total feature capacity**: ~20 SP across two iterations
  - **Cadence**: Standard Specrew development (1-2 weeks per iteration)

- **Drift/Reconciliation Gate**: ✅ PASS — Drift detection and conflict escalation explicit:
  - **Spec-to-plan drift**: Detected by `/speckit.specrew-speckit.before-plan` validator (existing hook, executed successfully above)
  - **Plan-to-tasks drift**: Detected by `/speckit.specrew-speckit.after-tasks` validator (existing hook, will execute after task generation)
  - **Tasks-to-implementation drift**: Detected by PR-time validator runs against legacy fixtures (FR-008); failures block merge
  - **Cross-artifact consistency**: Proposal 030 (Quality Hardening Bundle) patterns apply — form-vs-meaning checks at boundaries
  - **3-cycle repair budget**: Enforced at clarify/plan/tasks boundaries per feedback rule 2026-05-18; conflicts escalate to human Spec Steward for reconciliation

- **Verification Gate**: ✅ PASS — Process and outcome verification explicit:
  - **Process verification**:
    - Legacy fixture corpus completeness audit (FR-007, FR-009) — human review after Iteration 1
    - Validator rule false-positive check (FR-010, FR-011) — human review before Iteration 2 merge
    - Cross-platform CI evidence (FR-014) — automated Linux test lane required for all PRs touching readers
  - **Outcome verification**:
    - SC-001: Zero crashes from legacy state files (tracked via production incident reports)
    - SC-002: 100% pass rate for reader tests against legacy fixtures (automated CI gate)
    - SC-003: 100% schema marker presence in new state files (code review + automated validator check)
    - SC-004: 100% detection of PSCustomObject-based parsing (validator rule effectiveness audit)
    - SC-005: 80% reduction in compatibility issue resolution time (support ticket metrics)
    - SC-006: 100% cross-platform CI evidence (automated PR gate)
  - **Acceptance criteria validation**: Each user story acceptance scenario maps to fixture test cases and cross-platform CI runs

## Project Structure

### Documentation (this feature)

```text
specs/023-legacy-state-read-tolerance/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
│   └── state-file-schema-v1.md    # Schema contract for v1 state files
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
# PowerShell module + scripts structure (existing)
scripts/
├── internal/
│   ├── sync-boundary-state.ps1        # State reader/writer - requires hashtable migration
│   ├── task-progress.ps1               # State reader/writer - requires hashtable migration
│   ├── version-check.ps1               # State reader/writer - may require hashtable migration
│   ├── coordinator-resume.ps1          # State reader - requires hashtable migration
│   ├── dashboard-renderer.ps1          # State reader - audit required
│   └── worktree-awareness.ps1          # State reader - audit required
├── specrew-start.ps1                   # State reader - audit required
├── specrew-init.ps1                    # State writer - add schema: v1 markers
└── [other command scripts]             # Audit required for state file access

.specrew/
├── config.yml                          # Add schema: v1 marker
├── start-context.json                  # Add schema: v1 marker (motivating crash file)
├── last-validator-summary.json         # Add schema: v1 marker
└── version-check-cache.json            # Already has schema marker (F-020); reaffirm

.specify/
├── extensions/specrew-speckit/
│   └── extension.yml                   # Add separate schema: v1 field (FR-003)
└── feature.json                        # Add schema: v1 marker

.squad/
└── identity/
    └── now.md                          # Add schema: v1 to frontmatter

tasks-progress.yml                      # Already has schema marker (F-020); reaffirm

tests/
├── fixtures/
│   └── legacy-versions/                # NEW: Legacy fixture corpus (FR-007)
│       ├── 0.18.0/                     # Hand-curated from real 0.18.0 project
│       ├── 0.19.0/                     # Hand-curated from real 0.19.0 project (crash repro)
│       ├── 0.20.0/                     # Hand-curated from real 0.20.0 project
│       ├── 0.21.0/                     # Hand-curated from real 0.21.0 project
│       └── 0.22.0/                     # Hand-curated from real 0.22.0 project
└── integration/
    └── Test-LegacyStateReaders.Tests.ps1   # NEW: Pester tests for fixture corpus (FR-008)

docs/
└── data-contracts.md                   # NEW: Schema versioning discipline docs (FR-012)

.specify/templates/
└── closeout-template.md                # UPDATE: Add fixture reminder (FR-013)

# Validator rule implementation (Iteration 2)
.specify/extensions/specrew-speckit/
└── validators/
    └── gap-11-reader-hashtable-rule.ps1   # NEW: Validator rule (FR-010, FR-011)
```

**Structure Decision**: Specrew is a PowerShell module with CLI scripts under `scripts/` and internal utilities under `scripts/internal/`. State files are persisted in `.specrew/`, `.specify/`, and `.squad/` directories within user projects. This feature adds legacy fixture corpus under `tests/fixtures/legacy-versions/` and extends the existing validator framework (from Proposal 004/F-013) with a new rule for reader tolerance enforcement.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

**No violations** — all Constitution Check gates passed.

---

## Iteration Planning

### Iteration 1: Schema Markers + Reader Migration + Fixture Corpus (~14.5 SP)

**Scope**: FR-001 through FR-009, FR-014

**Deliverables**:
1. **Schema marker implementation** (FR-001, FR-002, FR-003):
   - Add `schema: v1` to all state file writers:
     - `scripts/specrew-init.ps1` → writes `.specrew/config.yml`
     - `scripts/specrew-start.ps1` → writes `.specrew/start-context.json`
     - `scripts/internal/sync-boundary-state.ps1` → writes `.squad/identity/now.md` frontmatter
     - Feature scaffold scripts → write `.specify/feature.json`
     - Validator framework → writes `.specrew/last-validator-summary.json`
     - Extension installer → writes `.specify/extensions/specrew-speckit/extension.yml` (separate `schema:` field per FR-003)
   - Reaffirm existing schema markers in `version-check-cache.json` and `tasks-progress.yml` (from F-020)

2. **Reader tolerance migration** (FR-004, FR-005, FR-006):
   - **HIGH priority** (3 scripts):
     - `scripts/specrew-start.ps1:375` — migrate `feature.json` parsing to `-AsHashtable`
     - `scripts/internal/worktree-awareness.ps1:57-75` — migrate `feature.json` parsing to `-AsHashtable`
     - `.specify/extensions/specrew-speckit/scripts/scaffold-feature-closeout-dashboard.ps1:106-121` — migrate to `-AsHashtable` + null-safe access
   - **MEDIUM priority** (2 scripts):
     - `scripts/internal/version-check.ps1:113-143` — migrate `version-check-cache.json` parsing to `-AsHashtable`
     - `scripts/internal/coordinator-resume.ps1:28-56` — migrate `last-validator-summary.json` parsing to `-AsHashtable`
   - Add schema version dispatch logic where reader behavior differs between v0 and v1 (FR-006)
   - Add "schema-implied-v0" debug logging for files without `schema` field

3. **Legacy fixture corpus** (FR-007, FR-008, FR-009):
   - Hand-curate fixtures from real projects for versions 0.18.0, 0.19.0, 0.20.0, 0.21.0, 0.22.0
   - Add a current-version 0.23.0 fixture directory capturing the first `schema: v1` state files produced by this feature
   - Create `tests/fixtures/legacy-versions/` directory structure
   - Include crash repro from 2026-05-19 WSL trial in 0.19.0 fixture (motivating evidence)
   - Write Pester test script: `tests/integration/Test-LegacyStateReaders.Tests.ps1`
   - Test all state readers against all fixtures:
     - `Get-SpecrewStartContextSessionState`
     - `Get-FeatureJson`
     - `Get-ConfigMap`
     - `Get-SpecrewIdentitySessionState`
     - All other functions reading from `.specrew/*`, `.specify/*`, `.squad/*`

4. **Cross-platform validation** (FR-014):
   - Extend `.github/workflows/specrew-ci.yml` with Linux test lane
   - Run legacy fixture tests on both Windows (`windows-latest`) and Linux (`ubuntu-latest`)
   - Validate Git `core.autocrlf` normalization for text fixtures

**Success Criteria**:
- SC-001: Zero crashes from legacy state files (0.18.0-0.22.0) after reader migrations
- SC-002: 100% pass rate for all reader tests against all fixtures
- SC-003: 100% schema marker presence in newly written state files
- SC-006: 100% cross-platform CI evidence (Windows + Linux) for reader changes

**Human Oversight Points**:
- After Iteration 1 closeout: Human review of fixture corpus completeness (verify 0.18.0-0.23.0 fixtures exercise all readers and include the new schema-v1 baseline)
- During implementation: Human approval of schema version dispatch logic where v0/v1 behavior differs

**Bootstrap Principle**: Iteration 1 implementation (writers adding `schema: v1`, readers using hashtables) serves as the reference implementation of the pattern being established.

---

### Iteration 2: Validator Rule + Documentation + Closeout Template (~5.5 SP)

**Scope**: FR-010, FR-011, FR-012, FR-013, FR-014 (continued)

**Deliverables**:
1. **Validator rule implementation** (FR-010, FR-011):
   - Add `Test-ReaderTolerance` function to `.specify/extensions/specrew-speckit/scripts/validate-governance.ps1`
   - Rule scope: PowerShell functions matching:
     - `Get-Specrew*SessionState` or `Get-Specrew*State` name pattern
     - OR any function reading from `.specrew/*`, `.specify/*`, `.squad/*` paths
   - Violation condition: Function includes `ConvertFrom-Json` **without** `-AsHashtable` parameter
   - Error format: Category `"reader-tolerance"`, clear message + remediation hint (FR-011)
   - Integrate with existing validator orchestration
   - Add validator invocation to PR checks

2. **Documentation** (FR-012):
   - Create `docs/data-contracts.md`:
     - Schema versioning discipline (v0 → v1 → v2 evolution)
     - Reader tolerance principles (hashtable-based parsing, StrictMode compatibility)
     - How to add new fixtures when schema evolves
     - Writer contract (always include `schema: v1`)
     - Reader contract (use `-AsHashtable`, handle missing fields gracefully)
     - Cross-platform considerations (line endings, path separators)

3. **Closeout template update** (FR-013):
   - Update `.specify/templates/closeout-template.md`:
     - Add reminder: "If this feature modified any state file schema, add a legacy fixture for the current Specrew version to `tests/fixtures/legacy-versions/`"
     - Include fixture generation instructions (hand-curate vs generated vs snapshot-based)

4. **Validator effectiveness audit**:
   - Manual audit of all PowerShell scripts using `ConvertFrom-Json`
   - Verify validator detects 100% of PSCustomObject-based state readers (SC-004)
   - Check for false positives (scripts reading non-state JSON files)
   - Human review before Iteration 2 merge

**Success Criteria**:
- SC-004: Validator rule detects 100% of PSCustomObject-based JSON parsing in state readers (0 false negatives)
- SC-005: 80% reduction in compatibility issue resolution time (measured via support ticket metrics post-release)
- Documentation completeness: `docs/data-contracts.md` covers all schema versioning + reader tolerance patterns

**Human Oversight Points**:
- Before Iteration 2 merge: Human review of validator rule to ensure no false positives
- Final PR merge: Human review of `docs/data-contracts.md` for clarity and completeness

---

## Iteration Capacity Summary

| Iteration | Scope | Story Points | Duration (est.) | Key Deliverables |
|-----------|-------|--------------|-----------------|------------------|
| Iteration 1 | FR-001 through FR-009, FR-014 | ~14.5 SP | 1-2 weeks | Schema markers, reader migrations, fixture corpus, cross-platform CI |
| Iteration 2 | FR-010, FR-011, FR-012, FR-013, FR-014 | ~5.5 SP | 1 week | Validator rule, docs, closeout template updates |
| **Total** | **FR-001 through FR-014** | **~20 SP** | **2-3 weeks** | **Full feature implementation** |

**Cadence**: Standard Specrew development (1-2 weeks per iteration)
**Capacity Model**: Story points (SP) as effort unit; ~14.5 SP for Iteration 1, ~5.5 SP for Iteration 2

---

## Planning Complete — Proceed to Task Generation

**Phase 0**: ✅ Research complete (`research.md` generated)
**Phase 1**: ✅ Design complete (`data-model.md`, `contracts/state-file-schema-v1.md`, `quickstart.md` generated)
**Agent Context**: ✅ Updated (`.github/copilot-instructions.md` reflects PowerShell + hashtable patterns)

**Next Command**: `/speckit.tasks` (generates `tasks.md` with dependency-ordered implementation tasks)

**Branch**: `023-legacy-state-read-tolerance`
**Implementation Plan**: `file:///C:/Dev/Specrew-023/specs/023-legacy-state-read-tolerance/plan.md`
