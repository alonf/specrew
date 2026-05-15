# Implementation Plan: Velocity Dashboard

**Branch**: `017-velocity-dashboard` | **Date**: 2026-05-15 | **Spec**: [spec.md](./spec.md)  
**Input**: Feature specification from `C:\Dev\Specrew-017\specs\017-velocity-dashboard\spec.md`

## Summary

Feature 017 adds a console-first "Where Am I?" dashboard that answers what has shipped, what is in
flight, and what is next through a single renderer shared by `specrew where`, the `specrew status`
alias, a dedicated script entry point, and repository/project-status Squad routing.

Iteration 1 delivers the dashboard core and the fidelity repair cycle: command wiring, canonical-record
aggregation, recent pace, recently shipped work, plan-vs-reality table, full-history summary, structured
`.specrew/roadmap.yml` input, semantic color/monochrome rendering, compact 24-line mode, future-team
placeholder behavior, bounded-warning resilience, plus the new summary line, consistent iteration naming,
derived feature status, current-phase highlight, multi-scope ETA projection, confidence mapping, and
drifted-over handling for roadmap overages. Iteration 2 integrates automatic generation into
iteration-closeout and feature-closeout, preserves immutable historical `dashboard.md` snapshots, adds
roadmap/dashboard drift validation, updates help and documentation, and extends integration coverage
across healthy, sparse, malformed, and no-roadmap states.

The feature remains additive to Specrew's existing PowerShell + Markdown/YAML governance surfaces:
no new boundary type, no browser UI, no living mutable top-level dashboard file, and no
multi-developer implementation beyond a friendly reserved `--Team` fallback.

## Iteration Scope & Effort Updates

**Iteration 1 (~14 SP)**: Deliver FR-001 through FR-018 and FR-034 through FR-046, including the repair
cycle for summary-line rendering, derived status/phase highlighting, consistent iteration naming,
confidence mapping, drifted-over roadmap status, and multi-scope ETA projection.

**Iteration 2 (~8 SP)**: Deliver FR-019 through FR-033 with closeout integration, validator updates,
documentation, and full fixture coverage.

## Technical Context

**Language/Version**: PowerShell 7.x scripts plus Markdown/YAML/JSON governance artifacts  
**Primary Dependencies**: `scripts/specrew.ps1`, planned `scripts/specrew-where.ps1`, mirrored `extensions/specrew-speckit` + `.specify/extensions/specrew-speckit` governance scripts, `.specify/feature.json`, `.specrew/iteration-config.yml`, `.specrew/role-assignments.yml`, `specs/**` iteration artifacts, and `.specrew/roadmap.yml`  
**Storage**: Git-tracked file artifacts in `specs/`, `.specrew/`, `.specify/`, `extensions/`, `docs/`, and `tests/`  
**Testing**: PowerShell integration scripts in `tests/integration/`, unit-style PowerShell checks in `tests/unit/`, repo validator runs, and optional `Invoke-ScriptAnalyzer` linting per `tests/README.md`  
**Target Platform**: PowerShell-capable Specrew repositories on Windows-first console workflows, including TTY, non-TTY, and monochrome capture contexts  
**Project Type**: Specrew governance CLI / extension monorepo  
**Performance Goals**: Dashboard rendering should feel immediate inside ad hoc status checks and
closeout flows, stay bounded to repository-local scans, and keep compact output within the fixed
24-line budget  
**Constraints**: Console-first only; monochrome-safe visuals; no burndowns/pie charts/scatterplots;
derive roadmap shipped progress from canonical history instead of manual totals; preserve immutable
closeout snapshots; honor `NO_COLOR`, dumb-terminal detection, non-TTY output, and explicit
no-color intent; no new boundary type; grandfather pre-feature iterations that lack dashboard
artifacts  
**Scale/Scope**: One feature spanning CLI dispatch, dashboard aggregation/rendering, roadmap schema,
closeout artifact generation, validator drift checks, documentation/help, and fixture-backed test
coverage across two bounded iterations (~14 SP then ~8 SP, ~22 SP total)

## Phase 1 Quality Planning

**Phase Scope**: `feature-017-dashboard-core-and-closeout-planning`  
**Inferred Quality Profile**: `quality-profile.custom-composition.v1`  
**Selected preset ref or explicit custom composition**: Custom composition of PowerShell CLI
correctness, console-rendering readability, artifact/governance integrity, roadmap-drift detection,
and fixture-driven closeout validation  
**Bounded custom composition**: No recognized preset cleanly matches a Specrew-internal PowerShell
governance dashboard. Planning stays bounded to the dashboard's CLI, roadmap, artifact, validator,
documentation, and test surfaces; browser UI, analytics expansion, and multi-developer execution
remain explicit deferrals.

### Stack Surfaces in Scope

| Stack Surface | Path Globs / Evidence | Recognized Stack | Why It Matters |
| --- | --- | --- | --- |
| `cli-dispatch-and-rendering` | `scripts/specrew.ps1`, `scripts/specrew-*.ps1` | `powershell-cli-governance` | Command parity for `where`, `status`, and the dedicated dashboard entry point lives here |
| `dashboard-data-and-roadmap` | `.specify/feature.json`, `specs/*/spec.md`, `specs/*/iterations/**`, `.specrew/roadmap.yml` | `markdown-yaml-file-aggregation` | FR-002, FR-003, FR-010, and FR-011 depend on truthful aggregation from canonical records |
| `closeout-and-validator-integration` | `extensions/specrew-speckit/scripts/*.ps1`, `.specify/extensions/specrew-speckit/scripts/*.ps1`, `.specrew/quality/known-traps.md` | `powershell-governance-validator` | Iteration-closeout snapshots, feature-closeout artifacts, dashboard artifact checks, and roadmap drift warnings land here |
| `docs-and-discovery` | `README.md`, `docs/**/*.md`, help output, `.github/copilot-instructions.md`, routing/prompt surfaces | `markdown-cli-docs` | FR-024 through FR-030 require consistent discovery, explanation, and project-status routing |
| `test-fixtures-and-replay` | `tests/integration/**/*.ps1`, `tests/unit/**/*.ps1`, fixture directories under `tests/integration/fixtures/` | `powershell-fixture-harness` | FR-032 and SC-002/SC-006 depend on deterministic replay across healthy and degraded repository states |

### Risk Dimensions

| Risk Dimension | Status (`required` / `not-applicable`) | Rationale |
| --- | --- | --- |
| governance-integrity | required | The dashboard becomes a new trust surface; misleading status or silent artifact drift would violate the constitution |
| console-rendering-readability | required | The feature's value depends on one-screen clarity in color and monochrome environments |
| data-integrity-and-drift | required | Roadmap status, shipped totals, and partial histories can disagree unless validation and warning paths stay explicit |
| test-integrity | required | The feature must prove non-crashing behavior across healthy, sparse, malformed, and no-roadmap states |
| backward-compatibility | required | New command and closeout behavior must remain additive to current lifecycle and validator expectations |
| concurrency-correctness | not-applicable | The slice is repository-local artifact aggregation, not concurrent runtime state management |

### Quality Tool Bundle

| Area | Selection | Evidence / Notes |
| --- | --- | --- |
| Bundle ID | `feature-017-console-dashboard-governance` | Custom bundle for PowerShell CLI + roadmap aggregation + closeout artifact discipline |
| Mechanical Checks | `command-surface-parity`, `compact-line-budget`, `partial-data-resilience`, `roadmap-drift-warning-contract`, `snapshot-artifact-contract`, `mirror-sync-check` | Evidence recorded in contracts, integration fixtures, and mirrored extension script paths |
| Ecosystem Tools | `pwsh` integration replay scripts, repo `validate-governance.ps1` runs, optional `Invoke-ScriptAnalyzer`, deterministic fixture assertions | Reuse the existing PowerShell governance harness rather than introduce a new toolchain |

### Required Quality Gates

| Required Quality Gate | Category | Evidence Source | Phase 1 Status |
| --- | --- | --- | --- |
| `command-surface-parity` | tooling | `specrew where`, `specrew status`, dedicated script entry point, and project-status routing contract | planned |
| `compact-line-budget` | mechanical | `contracts/dashboard-command-contract.md`, compact rendering fixture expectations | planned |
| `partial-data-resilience` | tooling | integration fixtures for malformed history, sparse history, and missing roadmap | planned |
| `roadmap-drift-warning-contract` | manual-evidence | `contracts/roadmap-schema-contract.md`, validator design, `.specrew/quality/known-traps.md` updates | planned |
| `snapshot-artifact-contract` | manual-evidence | `contracts/dashboard-artifact-contract.md` | planned |
| `repo-validator-clean` | tooling | repo validator run after dashboard drift/artifact rules are added | planned |

### Not-Applicable Dimensions and Rationale

| Dimension / Gate | Why Not Applicable in This Feature | Follow-up |
| --- | --- | --- |
| `frontend-rendering-review` | The dashboard is console-only; no browser, web app, or GUI surface is introduced | none |
| `distributed-systems-failure-review` | All data comes from local repository artifacts; no service-to-service or networked runtime is added | none |
| `predictive-model-review` | The feature is descriptive only and explicitly defers "next likely feature" prediction | none |

### Explicit Phase 2+ Deferrals

- Dedicated pre-implementation hardening-gate execution remains deferred until implementation is
  explicitly authorized.
- Full multi-developer aggregation remains deferred; v1 only reserves the `--Team` invocation path
  with a friendly fallback.
- Browser/HTML visualization, dense analytics, and predictive prioritization remain out of scope.
- Quality-drift automation beyond dashboard-specific roadmap/artifact checks remains deferred unless
  a later authorized slice expands the scope.

## Phase 2 Hardening and Specialist Review Planning

**Phase 2 Slice Scope**: `Feature 017 implementation hardening for dashboard truthfulness, artifact immutability, and closeout integration`  
**Hardening Gate Artifact**: `specs/017-velocity-dashboard/iterations/001/quality/hardening-gate.md`  
**Known-Traps Corpus Location**: `.specrew/quality/known-traps.md`  
**Trap Reapplication Artifact**: `specs/017-velocity-dashboard/quality/trap-reapplication.md`

### Hardening Focus Areas

| Focus Area | Why It Matters in This Slice | Planned Artifact / Evidence | Status (`required` / `deferred` / `not-applicable`) |
| --- | --- | --- | --- |
| Dashboard truthfulness and drift handling | The dashboard becomes a decision surface; roadmap status and shipped totals must never silently diverge from canonical records | roadmap contract, hardening gate, validator evidence, known-traps corpus | required |
| Error handling and bounded-warning semantics | Missing or malformed artifacts must produce partial render plus calm remediation guidance instead of a crash | command contract, integration fixtures, hardening gate | required |
| Snapshot immutability and closeout safety | `dashboard.md` and `closeout-dashboard.md` must capture closeout-time truth without being silently rewritten later | artifact contract, closeout integration tests, hardening gate | required |
| Test-integrity targets | Healthy, sparse, malformed, no-roadmap, compact-mode, and team-fallback scenarios all require deterministic fixture coverage | integration tests, quickstart verification commands, hardening gate | required |

### Lens Activation Plan

| Lens / Checklist Ref | Activation (`required` / `optional` / `not-applicable`) | Why Activated or Omitted | Planned Evidence / Artifact Path |
| --- | --- | --- | --- |
| `manual-governance-review` | required | Dashboard messaging, drift warnings, and closeout artifact semantics need human truthfulness review | `specs/017-velocity-dashboard/iterations/001/quality/quality-evidence.md` |
| `robustness-baseline-v1` | required | Partial-data handling and non-crashing rendering are core success criteria | `specs/017-velocity-dashboard/iterations/001/quality/hardening-gate.md` |
| `security-issues-v1` | optional | The surface is local-file-only, but path handling and artifact writes still merit a bounded pass | `specs/017-velocity-dashboard/iterations/001/quality/hardening-gate.md` |
| `concurrency-correctness-review` | not-applicable | No concurrent runtime or shared mutable service state is introduced | none |

### Routing Policy

| Lens Scope | Requested Reasoning / Review Class | Effective Class (when run) | Override / Approval Record | Notes |
| --- | --- | --- | --- | --- |
| Required hardening and bug-hunter lenses | strongest available planning/review class | not run yet | none | Planning only; execution remains a later explicit boundary |

### Explicit Later Deferrals

- Full line-by-line lens execution evidence remains deferred until implementation is authorized.
- Strongest-class routing execution evidence remains deferred until routed review actually runs.
- Dashboard freshness heuristics beyond immutable snapshot timestamps remain deferred unless later work
  proves they are needed.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Spec Authority Gate**: PASS — plan scope maps directly to `specs/017-velocity-dashboard/spec.md`,
  and the explicit user request in this planning boundary provides the required authorization to
  proceed from clarified spec to implementation planning.
- **Layering Gate**: PASS — changes are classified primarily as Spec Kit / repository-governance
  layer work (`scripts/`, `extensions/`, `.specify/`, `.specrew/`, `specs/`, `docs/`, `tests/`).
  Any Squad or Copilot routing updates are limited to supported prompt/discovery surfaces that point
  at the same renderer, not to unsupported platform hacks.
- **Traceability Gate**: PASS — planned deliverables map to user stories and FR/TG/SC ranges:
  command + rendering contracts cover User Story 1 / FR-001..FR-009 / FR-015..FR-017 / FR-030;
  roadmap and validator contracts cover User Story 2 / FR-002 / FR-008 / FR-010..FR-014 /
  FR-018 / FR-031 / FR-032; artifact and quickstart deliverables cover User Story 3 /
  FR-019..FR-030.
- **Ownership Gate**: PASS — Spec Steward remains accountable for spec/plan truth; CLI steward owns
  command surfaces; Product + UX stewards own layout/compact/no-color behavior; Roadmap steward owns
  `.specrew/roadmap.yml`; Governance + Validator stewards own closeout and drift checks; Test
  steward owns fixture coverage; Documentation + Interaction stewards own help and project-status
  routing coherence.
- **Capacity Gate**: PASS — effort unit is story points per `.specrew/iteration-config.yml`; the
feature defines two bounded iterations (~14 SP and ~8 SP) under the repository
  `capacity_per_iteration: 20` limit with no overcommit required.
- **Drift/Reconciliation Gate**: PASS — the plan requires roadmap-drift warnings, dashboard-artifact
  validation, immutable snapshot metadata, and explicit reconciliation when roadmap declarations,
  shipped totals, or closeout artifacts disagree with canonical records.
- **Verification Gate**: PASS — verification is explicit: command-surface parity, compact budget,
  missing-data resilience, validator warnings, closeout artifact generation, and documentation/help
  clarity all have named contracts or planned test fixtures.

*Post-design re-check*: Constitution check remains PASS. Phase 1 design kept all interfaces on
supported extension surfaces, preserved one-boundary discipline, resolved planning-time unknowns in
research, and introduced no new constitutional violations or unjustified complexity.

## Project Structure

### Documentation (this feature)

```text
specs/017-velocity-dashboard/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── dashboard-command-contract.md
│   ├── roadmap-schema-contract.md
│   └── dashboard-artifact-contract.md
└── tasks.md
```

### Source Code (repository root)

```text
scripts/
├── specrew.ps1
└── specrew-where.ps1               # planned dedicated dashboard entry point

.specrew/
├── roadmap.yml                     # new structured roadmap source
├── iteration-config.yml
└── quality/
    └── known-traps.md

extensions/specrew-speckit/
├── scripts/                        # closeout integration + validator additions
├── prompts/                        # project-status routing/discovery alignment if needed
└── validators/

.specify/extensions/specrew-speckit/
├── scripts/                        # mirrored extension surfaces
└── prompts/

docs/
├── getting-started.md
└── user-guide.md

tests/
├── integration/
│   └── fixtures/
└── unit/

README.md
.github/copilot-instructions.md
specs/<feature>/iterations/<NNN>/   # future `dashboard.md` snapshot artifacts
```

**Structure Decision**: This is a single-repository governance/tooling feature. The implementation
extends the existing PowerShell CLI and mirrored Spec Kit extension scripts, adds a file-based
roadmap source under `.specrew/`, stores dashboard snapshots beside iteration/feature closeout
artifacts, and proves behavior through the existing PowerShell replay/fixture test layout rather
than by introducing a new runtime application module.

## Complexity Tracking

No constitutional violations require justification in this plan. Complexity is controlled by keeping
the feature additive, console-first, file-based, and bounded to the five approved pillars with
explicit deferrals for team dashboards, browser views, predictive analytics, and broader automation.
