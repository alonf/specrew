# Implementation Plan: Velocity Dashboard Visual Richness + PoC-Parity Restoration

**Branch**: `018-velocity-dashboard-visual-richness` | **Date**: 2026-05-15 | **Spec**: [spec.md](./spec.md)  
**Input**: Feature specification from `C:\Dev\Specrew\specs\018-velocity-dashboard-visual-richness\spec.md`

## Summary

Feature 018 is a single-iteration presentation-layer follow-up to Feature 017 that restores PoC-level
information density while adding richer visual primitives and one bounded new visualization: a
velocity-only sparkline. The implementation stays on the existing PowerShell dashboard surfaces,
preserves lifecycle and closeout semantics, keeps monochrome-safe rendering available at all times,
and extends documentation and fixture-backed validation rather than introducing new workflow scope.

The approved slice covers five pillars only: rich-mode Unicode and ANSI primitives, PoC-parity
dashboard density, a velocity sparkline confined to the Velocity section, backward-compatible test
coverage with rich-mode and monochrome-mode fixtures, and documentation updates across the dashboard
guide, README, and manual quickstart. Explicitly deferred items remain out of scope: working-days
projection, MVP-versus-1.0 two-horizon logic, minimum-days sample stretching, bootstrapped-date schema
changes, and configurable velocity sample windows.

## Iteration Scope & Effort Updates

**Iteration 1 target**: ~10-12 SP nominal, planned with a realistic actual envelope of ~12-15 SP to
absorb small rendering, compatibility, fixture, and documentation repair items without reopening scope.

**Capacity fit**: The repository iteration budget remains `20` story points
(`.specrew/iteration-config.yml`), so this single-iteration slice fits within constitutional capacity
without overcommit.

## Technical Context

**Language/Version**: PowerShell 7.x scripts plus Markdown/YAML/JSON governance artifacts  
**Primary Dependencies**: `scripts/internal/dashboard-renderer.ps1`, `scripts/specrew.ps1`, `scripts/specrew-where.ps1`, mirrored `extensions/specrew-speckit` + `.specify/extensions/specrew-speckit` closeout/validator scripts, `.specify/feature.json`, `.specrew/roadmap.yml`, `specs/**` dashboard artifacts, `docs/dashboard-guide.md`, `README.md`, and dashboard fixture/test harnesses under `tests/`  
**Storage**: Git-tracked file artifacts only under `specs/`, `.specrew/`, `.specify/`, `docs/`, `scripts/`, `extensions/`, and `tests/`  
**Testing**: PowerShell integration scripts in `tests/integration/`, unit-style PowerShell checks in
`tests/unit/`, validator replay through `extensions/specrew-speckit/scripts/validate-governance.ps1`,
manual dashboard quickstart verification, and optional `Invoke-ScriptAnalyzer` per `tests/README.md`  
**Target Platform**: PowerShell-capable Specrew repositories on Windows and Linux/macOS terminals,
including rich TTY consoles, monochrome/dumb terminals, redirected non-TTY output, and stored Markdown
snapshot readers  
**Project Type**: Specrew governance CLI / extension monorepo  
**Performance Goals**: Preserve NFR-001 by keeping dashboard rendering at or below 1.5 seconds on a
representative 16-feature repository while adding Unicode, ANSI, and sparkline formatting  
**Constraints**: Preserve Feature 017 behavior and tests; keep lifecycle semantics unchanged; rich mode
must default only when terminal eligibility is satisfied; fallback must be clean under `--ASCII`,
`NO_COLOR`, `NO_UNICODE`, dumb terminal, redirected output, and missing Windows virtual-terminal
support; velocity sparkline appears only in Velocity; stored snapshots strip ANSI but preserve Unicode;
fixture and artifact text must remain UTF-8 without BOM and use LF line endings  
**Scale/Scope**: One bounded iteration covering renderer formatting, CLI flags, closeout artifact
rendering, validator/fixture expectations, and documentation for the five approved pillars only

## Phase 1 Quality Planning

**Phase Scope**: `feature-018-visual-richness-single-iteration-slice`  
**Inferred Quality Profile**: `quality-profile.custom-composition.v1`  
**Selected preset ref or explicit custom composition**: Custom composition of PowerShell CLI rendering
correctness, terminal compatibility, artifact encoding integrity, backward-compatibility replay, and
dashboard performance validation  
**Bounded custom composition**: No stock preset cleanly matches a PowerShell console renderer that must
balance Unicode, ANSI, ASCII fallback, immutable closeout artifacts, and fixture encoding controls.
Planning stays bounded to the existing dashboard renderer/CLI/doc/test surfaces and leaves broader
analytics or lifecycle expansion explicitly deferred.

### Stack Surfaces in Scope

| Stack Surface | Path Globs / Evidence | Recognized Stack | Why It Matters |
| --- | --- | --- | --- |
| `dashboard-renderer-core` | `scripts/internal/dashboard-renderer.ps1` | `powershell-console-renderer` | Rich-mode primitives, fallback substitutions, sparkline output, and snapshot text all originate here |
| `dashboard-cli-surface` | `scripts/specrew.ps1`, `scripts/specrew-where.ps1` | `powershell-cli-governance` | `where`/`status` parity and new `--ASCII`, `--RecentCount`, `--BarWidth` options must remain coherent |
| `closeout-and-validator-paths` | `extensions/specrew-speckit/scripts/*.ps1`, `.specify/extensions/specrew-speckit/scripts/*.ps1` | `powershell-governance-validator` | Iteration/feature snapshot persistence and bounded governance checks must preserve artifact semantics |
| `docs-and-discovery` | `docs/dashboard-guide.md`, `README.md`, `tests/manual/feature-017-dashboard-quickstart.md` | `markdown-user-guidance` | Users need clear explanation of rich mode, fallback behavior, flags, and stored-snapshot rules |
| `fixture-replay-harness` | `tests/integration/**/*.ps1`, `tests/unit/**/*.ps1`, `tests/integration/fixtures/feature-017-dashboard/**` | `powershell-fixture-harness` | Feature 017 regression coverage plus new rich/monochrome fixtures prove compatibility and encoding stability |

### Risk Dimensions

| Risk Dimension | Status (`required` / `not-applicable`) | Rationale |
| --- | --- | --- |
| terminal-compatibility | required | The value of this feature depends on correct behavior across Windows, Linux/macOS, TTY, and non-TTY contexts |
| fallback-truthfulness | required | ASCII/monochrome output must preserve meaning with no Unicode or ANSI dependence |
| artifact-integrity | required | Stored closeout snapshots must remain historical, ANSI-free, Unicode-preserving, and encoding-stable |
| performance-budget | required | Rich formatting must not violate the 1.5 second rendering budget |
| backward-compatibility | required | All Feature 017 tests and lifecycle behaviors must remain valid |
| documentation-clarity | required | New rendering rules and flags must be understandable without source inspection |
| concurrency-correctness | not-applicable | The slice remains local file aggregation and rendering, not concurrent shared-state orchestration |

### Quality Tool Bundle

| Area | Selection | Evidence / Notes |
| --- | --- | --- |
| Bundle ID | `feature-018-rich-dashboard-compatibility` | Custom bundle for console rendering, fallback safety, artifact persistence, and replay validation |
| Mechanical Checks | `feature-017-regression-pass`, `rich-vs-mono-fixture-parity`, `ansi-strip-unicode-preserve`, `recent-count-bar-width-contract`, `velocity-only-sparkline`, `fixture-encoding-consistency`, `nfr-001-render-budget` | Evidence recorded in contracts, test fixtures, and quickstart verification targets |
| Ecosystem Tools | `pwsh` integration scripts, unit PowerShell checks, validator runs, manual quickstart checks, optional `Invoke-ScriptAnalyzer` | Reuse the existing PowerShell governance/tooling lane instead of adding a new test stack |

### Required Quality Gates

| Required Quality Gate | Category | Evidence Source | Phase 1 Status |
| --- | --- | --- | --- |
| `existing-dashboard-suite-pass` | tooling | `tests/integration/feature-017-dashboard-core.ps1` and `tests/unit/feature-017-dashboard.tests.ps1` continue to pass | planned |
| `rich-mode-fixture-contract` | tooling | Dedicated rich-mode fixture expectations for Unicode blocks, ANSI emphasis, status markers, sparkline, and information density | planned |
| `monochrome-fallback-contract` | tooling | Dedicated fallback fixtures proving ASCII-only, ANSI-free, Unicode-free readability under `--ASCII`/restricted environments | planned |
| `artifact-persistence-contract` | manual-evidence | Artifact contract plus validator expectations for ANSI stripping and Unicode preservation in stored snapshots | planned |
| `flag-surface-contract` | manual-evidence | Dashboard rendering contract for `--ASCII`, `--RecentCount`, and `--BarWidth` defaults and override behavior | planned |
| `render-budget-check` | tooling | Performance verification against the 16-feature, <=1.5s NFR-001 budget | planned |
| `fixture-encoding-consistency` | mechanical | UTF-8 no BOM + LF line ending expectations for fixtures and stored snapshots | planned |

### Not-Applicable Dimensions and Rationale

| Dimension / Gate | Why Not Applicable in This Feature | Follow-up |
| --- | --- | --- |
| `web-ui-accessibility-audit` | The dashboard remains console-first with no browser or GUI surface | none |
| `network-service-resilience-review` | The feature reads only repository-local artifacts and does not introduce networked dependencies | none |
| `schema-migration-review` | Approved scope explicitly defers any `.specrew/config.yml` or velocity-window schema changes | none |

### Explicit Phase 2+ Deferrals

- Hardening execution evidence and bug-hunter review remain deferred until implementation is explicitly authorized.
- Working-days projections, MVP-versus-1.0 dual horizons, minimum-days window stretching, bootstrapped-date anchoring, and configurable velocity sample windows remain out of scope.
- Any broader dashboard analytics expansion beyond the single velocity sparkline remains deferred unless a later approved feature authorizes it.

## Phase 2 Hardening and Specialist Review Planning

**Phase 2 Slice Scope**: `Feature 018 pre-implementation hardening for terminal detection, fallback truthfulness, snapshot safety, and render-budget preservation`  
**Hardening Gate Artifact**: `specs/018-velocity-dashboard-visual-richness/quality/hardening-gate.md`  
**Known-Traps Corpus Location**: `.specrew/quality/known-traps.md`  
**Trap Reapplication Artifact**: `specs/018-velocity-dashboard-visual-richness/quality/trap-reapplication.md`

### Hardening Focus Areas

| Focus Area | Why It Matters in This Slice | Planned Artifact / Evidence | Status (`required` / `deferred` / `not-applicable`) |
| --- | --- | --- | --- |
| Terminal capability and fallback analysis | Rich mode must enable only when UTF-8, ANSI, and host capabilities are truly available; fallback must remain trustworthy otherwise | hardening gate + rendering contract + fixture evidence | required |
| Error handling and degraded rendering semantics | Missing roadmap/history or unsupported terminals must yield calm guidance, not broken glyph soup or crashes | hardening gate + existing/new integration fixtures | required |
| Snapshot persistence and encoding safety | Stored dashboards must strip ANSI, preserve Unicode, remain immutable, and avoid encoding drift across editors and CI | artifact contract + validator evidence + fixture samples | required |
| Test-integrity and regression targets | The new rich layer must prove additive behavior without regressing Feature 017 or breaching NFR-001 | unit/integration commands, quickstart verification, hardening gate | required |

### Lens Activation Plan

| Lens / Checklist Ref | Activation (`required` / `optional` / `not-applicable`) | Why Activated or Omitted | Planned Evidence / Artifact Path |
| --- | --- | --- | --- |
| `robustness-baseline-v1` | required | Terminal capability branching and graceful fallback are central failure surfaces | `specs/018-velocity-dashboard-visual-richness/quality/hardening-gate.md` |
| `manual-governance-review` | required | Users will read the dashboard as a trust surface; semantics and snapshot rules need human review | `specs/018-velocity-dashboard-visual-richness/quality/quality-evidence.md` |
| `performance-budget-review` | required | Unicode/ANSI overhead must stay inside NFR-001 | `specs/018-velocity-dashboard-visual-richness/quality/hardening-gate.md` |
| `security-issues-v1` | optional | The slice is local-file-only, but artifact writing and CLI arguments still merit a bounded review | `specs/018-velocity-dashboard-visual-richness/quality/hardening-gate.md` |
| `concurrency-correctness-review` | not-applicable | No concurrent mutable runtime or shared service state is added | none |

### Routing Policy

| Lens Scope | Requested Reasoning / Review Class | Effective Class (when run) | Override / Approval Record | Notes |
| --- | --- | --- | --- | --- |
| Required hardening and bug-hunter lenses | strongest available planning/review class | not run yet | none | Planning only; execution remains a later approved boundary |

### Explicit Later Deferrals

- Full runtime hardening execution evidence remains deferred until implementation/review boundaries authorize it.
- Known-traps corpus updates and reapplication proof remain deferred until a hardening slice is in scope.
- Requested-versus-effective strongest-class execution evidence remains deferred until routed lens runs occur.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Spec Authority Gate**: PASS — plan scope maps directly to
  `specs/018-velocity-dashboard-visual-richness/spec.md` and the approved clarifications captured there.
- **Layering Gate**: PASS — changes remain in supported repository-governance surfaces (`scripts/`,
  `extensions/`, `.specify/`, `docs/`, `tests/`, and feature artifacts). No unsupported Copilot/VS Code
  hacks or new runtime layer are introduced.
- **Traceability Gate**: PASS — planned deliverables map cleanly to the approved stories and requirement
  ranges: rendering + CLI contracts cover Story 1 / FR-004..FR-013; artifact/fallback rules cover Story 2
  / FR-001, FR-005, FR-010, FR-014, FR-017; documentation and verification deliverables cover Story 3 /
  FR-015..FR-020 plus SC-002..SC-005.
- **Ownership Gate**: PASS — Spec Steward owns spec/plan integrity; CLI steward owns entry-point flags;
  UX steward owns rendering semantics and fallback readability; Product steward owns active-work/recent
  shipped/velocity information density; Reliability steward owns NFR-001 preservation; Test steward owns
  fixture coverage; Documentation steward owns README/dashboard-guide/manual quickstart updates.
- **Capacity Gate**: PASS — effort unit is story points and repository capacity remains `20` story points
  per iteration. The feature stays within one iteration at ~12-15 SP actual envelope, below the configured
  overcommit threshold.
- **Drift/Reconciliation Gate**: PASS — plan requires preservation of Feature 017 behavior, validator-aware
  snapshot semantics, explicit fallback verification, and reconciliation if implementation attempts to
  change lifecycle semantics or expand analytics beyond the approved five pillars.
- **Verification Gate**: PASS — process and outcome verification are explicit through regression tests,
  new rich/monochrome fixtures, artifact rendering contracts, performance checks, and user-facing docs.

*Post-design re-check*: Constitution check remains PASS. Phase 1 design preserved the approved single
iteration scope, resolved planning-time unknowns, stayed on supported extension surfaces, and introduced
no unjustified complexity or new governance violations.

## Project Structure

### Documentation (this feature)

```text
specs/018-velocity-dashboard-visual-richness/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── dashboard-rich-rendering-contract.md
│   └── dashboard-artifact-encoding-contract.md
└── tasks.md
```

### Source Code (repository root)

```text
scripts/
├── specrew.ps1
├── specrew-where.ps1
└── internal/
    └── dashboard-renderer.ps1

extensions/specrew-speckit/
└── scripts/                        # closeout snapshot + validator integrations

.specify/extensions/specrew-speckit/
└── scripts/                        # mirrored extension surfaces

.specrew/
├── iteration-config.yml
├── roadmap.yml
└── quality/
    └── known-traps.md

docs/
├── dashboard-guide.md
└── README.md

tests/
├── integration/
│   ├── feature-017-dashboard-core.ps1
│   └── fixtures/feature-017-dashboard/
├── unit/
│   └── feature-017-dashboard.tests.ps1
└── manual/
    └── feature-017-dashboard-quickstart.md

README.md
```

**Structure Decision**: This remains a single-repository PowerShell governance/tooling feature. The work
extends the existing dashboard renderer and CLI surfaces, keeps closeout artifact generation on the
existing extension scripts, and validates behavior through the existing replay-style PowerShell test
harness instead of introducing a new application runtime or persistence layer.

## Complexity Tracking

No constitutional violations require justification in this plan. Complexity is controlled by keeping the
feature additive, presentation-only, single-iteration, and bounded to the five approved pillars.
