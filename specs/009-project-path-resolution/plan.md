# Implementation Plan: Project Path Resolution in Specrew Entry-Point Scripts

**Branch**: `008-reviewer-escalation-symmetry` (active Git branch hosting feature 009 work) | **Date**: 2026-05-09 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `specs/009-project-path-resolution/spec.md`

## Summary

This plan formalizes the already-started path-resolution repair for feature `009-project-path-resolution`, which remains the active priority even though the current Git branch name still reflects feature 008. The implementation keeps the interim `Resolve-ProjectPath` helper as the canonical fix, adopts it across every user entry point and audited internal call site that accepts relative project/spec/iteration paths, adds deterministic regression coverage plus a static anti-pattern scan, seeds the known-traps corpus, and preserves the existing CLI surface and user-visible error messages.

## Technical Context

**Language/Version**: PowerShell 7.x plus Markdown/YAML/JSON governance artifacts  
**Primary Dependencies**: `scripts/*.ps1` entry points, `extensions/specrew-speckit/scripts/shared-governance.ps1`, mirrored `.specify/extensions/specrew-speckit/scripts/*`, Spec Kit planning scripts, and deterministic integration lanes under `tests/integration/`  
**Storage**: Git-tracked PowerShell, Markdown, YAML, and JSON files in `scripts/`, `extensions/`, `.specify/`, `specs/`, and future `.specrew/quality/known-traps.md`  
**Testing**: `tests/integration/quality-profile-foundation.ps1`, `tests/integration/hardening-gate-contract.ps1`, `tests/integration/quality-evidence-governance.ps1`, `tests/integration/validation-contract-lane.ps1`, `extensions/specrew-speckit/scripts/validate-governance.ps1 -ProjectPath .`, plus a new deterministic `tests/integration/project-path-resolution-regression.ps1` lane that includes the static anti-pattern scan  
**Target Platform**: PowerShell-capable Specrew repositories, with Windows path semantics as the bug trigger and cross-platform parity preserved  
**Project Type**: Specrew governance/CLI monorepo with Spec Kit extension assets and mirrored extension deployment surfaces  
**Performance Goals**: Zero false “Project is not Specrew-managed” / “Project is not fully bootstrapped” failures when the user invokes an entry-point script from the actual PowerShell working directory; deterministic zero-exit regression and validation lanes  
**Constraints**: Preserve or equivalently replace the interim `Resolve-ProjectPath` helper; keep argument names/defaults and existing error strings stable; audit and cover `specrew-init`, all five `specrew-team` call sites, `specrew-review`, and relevant internal scripts in both extension trees; keep the named validation lanes green; include deterministic regression coverage, static anti-pattern scanning, known-traps seeding, and trap reapplication before closure  
**Scale/Scope**: One bounded fix slice spanning 5 user entry points, mirrored internal governance scripts, one new regression lane, one static anti-pattern scan, and one known-traps corpus seed/reapplication path

## Phase 1 Quality Planning

**Phase Scope**: `phase-1-path-resolution-regression-repair`  
**Inferred Quality Profile**: `quality-profile.custom-composition.v1`  
**Selected preset ref or explicit custom composition**: Custom PowerShell CLI/governance composition anchored in shared helper adoption, deterministic regression checks, and governance-lane preservation  
**Bounded custom composition**: This slice stays within Specrew-owned path resolution, mirrored extension script parity, regression proof, and trap-corpus follow-through. It does not reopen broader quality-profile, specialist-lens, or unrelated lifecycle features.

### Stack Surfaces in Scope

| Stack Surface | Path Globs / Evidence | Recognized Stack | Why It Matters |
| --- | --- | --- | --- |
| User entry points | `scripts/specrew-start.ps1`, `scripts/specrew-update.ps1`, `scripts/specrew-init.ps1`, `scripts/specrew-team.ps1`, `scripts/specrew-review.ps1` | `powershell-cli` | The bug is user-visible here and must preserve the current CLI contract |
| Shared helper + internal governance scripts | `extensions/specrew-speckit/scripts/shared-governance.ps1`, `run-mechanical-checks.ps1`, `run-hardening-gate.ps1`, `resolve-quality-profile.ps1`, `validate-governance.ps1`, mirrored `.specify/extensions/**` copies | `powershell-governance` | Relative-path handling must stay consistent across deployed and source extension surfaces |
| Regression and validation lanes | `tests/integration/*.ps1`, `extensions/specrew-speckit/scripts/validate-governance.ps1` | `powershell-test-fixtures` | The fix must fail closed for regressions while preserving established quality/governance lanes |
| Known-traps corpus | `.specrew/quality/known-traps.md`, `specs/009-project-path-resolution/quality/**` | `quality-governance` | The defect must be captured and re-applied as a future recurrence trap |

### Risk Dimensions

| Risk Dimension | Status (`required` / `not-applicable`) | Rationale |
| --- | --- | --- |
| CLI compatibility | `required` | The fix must keep commands, defaults, and user-visible errors unchanged except for corrected absolute path reporting |
| Audit completeness | `required` | Partial adoption would reintroduce the same bug in less-common flows |
| Test integrity | `required` | Dynamic regression coverage and the static scan must both fail closed |
| Governance drift | `required` | The quality-profile lanes and trap-corpus commitments from feature 005 must remain truthful and green |
| New runtime/toolchain adoption | `not-applicable` | No new runtime, package manager, or external service is introduced |

### Quality Tool Bundle

| Area | Selection | Evidence / Notes |
| --- | --- | --- |
| Bundle ID | `quality-bundle.powershell-cli-path-resolution.v1` | Bounded to path-resolution helper adoption, mirrored script parity, and regression coverage |
| Mechanical Checks | `entrypoint-regression`, `static-anti-pattern-scan`, `trap-reapplication-check` | Evidence lives in the new integration lane, audit outputs, and known-traps artifacts |
| Ecosystem Tools | `pwsh`, existing integration lanes, `validate-governance.ps1` | Reuse the repo’s current PowerShell validation surface with no new dependency |

### Required Quality Gates

| Required Quality Gate | Category | Evidence Source | Phase 1 Status |
| --- | --- | --- | --- |
| `entrypoint-path-resolution-regression` | tooling | `tests/integration/project-path-resolution-regression.ps1` | `planned` |
| `static-relative-path-antipattern-scan` | tooling | static scan embedded in `tests/integration/project-path-resolution-regression.ps1` | `planned` |
| `governance-validation-lanes` | tooling | existing four integration lanes plus `extensions/specrew-speckit/scripts/validate-governance.ps1 -ProjectPath .` | `planned` |
| `error-message-fidelity-review` | manual-evidence | `contracts/cli-path-resolution.md` + implementation review evidence | `planned` |
| `known-traps-seed-and-reapply` | manual-evidence | `.specrew/quality/known-traps.md` + `specs/009-project-path-resolution/quality/trap-reapplication.md` | `planned` |

### Not-Applicable Dimensions and Rationale

| Dimension / Gate | Why Not Applicable in This Feature | Follow-up |
| --- | --- | --- |
| FR-009 mechanical-lens catalog mapping | Optional per spec and not required to close the initial repair slice | Revisit when broader Phase 2 mechanical-lens execution exists |
| New external API or UI contracts | The change is internal to PowerShell CLI path normalization and must keep the published interface stable | None |

### Explicit Phase 2+ Deferrals

- Optional mapping of the anti-pattern into the broader feature-005 mechanical lens catalog remains deferred.
- Any broader repository-wide cleanup of benign `GetFullPath` uses outside user-supplied relative-path resolution remains out of scope.
- Additional cross-platform ergonomics beyond the shared helper’s existing rooted-path handling remain deferred.

## Phase 2 Hardening and Specialist Review Planning

**Phase 2 Slice Scope**: `path-resolution-closure-hardening`  
**Hardening Gate Artifact**: `specs/009-project-path-resolution/quality/hardening-gate.md`  
**Known-Traps Corpus Location**: `.specrew/quality/known-traps.md`  
**Trap Reapplication Artifact**: `specs/009-project-path-resolution/quality/trap-reapplication.md`

### Hardening Focus Areas

| Focus Area | Why It Matters in This Slice | Planned Artifact / Evidence | Status (`required` / `deferred` / `not-applicable`) |
| --- | --- | --- | --- |
| CLI error handling and failure semantics | The fix must preserve exact user-facing errors while correcting the resolved absolute path in failure output | `contracts/cli-path-resolution.md`, review evidence, regression lane assertions | `required` |
| Audit completeness across mirrored script trees | Source extension and deployed `.specify` copies must not drift | audit matrix in `research.md`, implementation review notes, static scan results | `required` |
| Static anti-pattern detection | Future reintroduction of raw `GetFullPath($ProjectPath/$IterationPath/$SpecPath/...)` must be caught deterministically | `tests/integration/project-path-resolution-regression.ps1` | `required` |
| Known-traps seeding and reapplication | The discovered defect must become a reusable governance trap before closure | `.specrew/quality/known-traps.md`, `specs/009-project-path-resolution/quality/trap-reapplication.md` | `required` |

### Lens Activation Plan

| Lens / Checklist Ref | Activation (`required` / `optional` / `not-applicable`) | Why Activated or Omitted | Planned Evidence / Artifact Path |
| --- | --- | --- | --- |
| `static-relative-path-antipattern` | `required` | FR-007 requires deterministic detection of the historical broken idiom | `tests/integration/project-path-resolution-regression.ps1` |
| `cli-compatibility-review` | `required` | TG-005 and FR-005 require stable CLI surface and unchanged error messages | `contracts/cli-path-resolution.md` + review evidence |
| `known-traps-reapplication` | `required` | FR-008 requires corpus seeding and reapplication before closure | `.specrew/quality/known-traps.md`, `specs/009-project-path-resolution/quality/trap-reapplication.md` |
| `mechanical-lens-catalog-mapping` | `optional` | FR-009 is explicitly optional for the initial slice | future feature-005 mechanical-lens work |

### Routing Policy

| Lens Scope | Requested Reasoning / Review Class | Effective Class (when run) | Override / Approval Record | Notes |
| --- | --- | --- | --- | --- |
| Required hardening and bug-hunter-adjacent checks for this slice | `strongest-available` | record at execution time | `none` unless explicitly approved | Path-resolution regressions and trap reapplication should default to the strongest available review posture because they guard against silent recurrence |

### Explicit Later Deferrals

- Final hardening-gate completion evidence is deferred until implementation exists.
- Trap reapplication results are planned now but produced during implementation/closure.
- Optional feature-005 mechanical-lens catalog integration remains deferred unless separately approved.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Spec Authority Gate**: PASS — Scope maps directly to feature 009 user stories, FR-001 through FR-008, and TG-001 through TG-005.
- **Layering Gate**: PASS — The work stays inside Specrew-owned PowerShell entry points, extension scripts, tests, and quality artifacts.
- **Traceability Gate**: PASS — Each planned deliverable links to the helper, audited call sites, regression coverage, and trap-corpus follow-through.
- **Ownership Gate**: PASS — Spec Steward owns scope truth, Planner owns bounded design, Implementer owns helper adoption and regression wiring, Reviewer owns validation lanes and trap reapplication review.
- **Capacity Gate**: PASS — One bounded implementation slice covers helper adoption, script audit, regression/static scan, and trap seeding without reopening unrelated feature work.
- **Drift/Reconciliation Gate**: PASS — The plan explicitly calls out mirrored extension updates, validation-lane preservation, and the active-feature-vs-branch-name mismatch as visible drift to reconcile rather than ignore.
- **Verification Gate**: PASS — The validation path is explicit through the existing governance lanes plus one new deterministic regression lane.

## Project Structure

### Documentation (this feature)

```text
specs/009-project-path-resolution/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── cli-path-resolution.md
└── quality/
    ├── hardening-gate.md            # planned later, not created by /speckit.plan
    └── trap-reapplication.md        # planned later, not created by /speckit.plan
```

### Source Code (repository root)

```text
scripts/
├── specrew-start.ps1
├── specrew-update.ps1
├── specrew-init.ps1
├── specrew-team.ps1
└── specrew-review.ps1

extensions/specrew-speckit/
└── scripts/
    ├── shared-governance.ps1
    ├── resolve-quality-profile.ps1
    ├── run-hardening-gate.ps1
    ├── run-mechanical-checks.ps1
    └── validate-governance.ps1

.specify/extensions/specrew-speckit/
└── scripts/
    ├── shared-governance.ps1
    ├── resolve-quality-profile.ps1
    ├── run-hardening-gate.ps1
    ├── run-mechanical-checks.ps1
    └── validate-governance.ps1

tests/
└── integration/
    ├── quality-profile-foundation.ps1
    ├── hardening-gate-contract.ps1
    ├── quality-evidence-governance.ps1
    ├── validation-contract-lane.ps1
    └── project-path-resolution-regression.ps1

.specrew/
└── quality/
    └── known-traps.md
```

**Structure Decision**: Keep the feature anchored in one repo-level PowerShell CLI/governance surface. The documentation lives in the feature directory, while the implementation spans user entry points, shared governance helpers, mirrored extension scripts, deterministic tests, and the known-traps corpus.

## Phase 0: Research Decisions

Research outputs are captured in [research.md](research.md). The decisions that drive this plan are:

1. Preserve the interim `Resolve-ProjectPath` helper as the canonical relative-path resolver.
2. Treat both extension trees as in-scope because drift between `extensions/` and `.specify/extensions/` would reintroduce inconsistent behavior.
3. Pair the runtime regression with a static anti-pattern scan so the bug fails closed both behaviorally and mechanically.
4. Seed `.specrew/quality/known-traps.md` during implementation even if the file does not yet exist, then record trap reapplication before closure.
5. Keep the existing validation lanes green and preserve the CLI surface and error-message contract verbatim.

## Phase 1 Design

### Data and Contract Surfaces

- [data-model.md](data-model.md) defines the helper, audited call sites, regression cases, static scan rule, and trap-corpus entry.
- [contracts/cli-path-resolution.md](contracts/cli-path-resolution.md) defines the stable CLI/path-resolution contract, audit scope, and validation obligations.
- [quickstart.md](quickstart.md) captures the expected implementation and validation workflow for the bounded repair slice.

### Proposed Implementation Slices

| Slice | Scope | Affected Surfaces | Outcome |
| --- | --- | --- | --- |
| Slice A | Canonical helper adoption across user entry points | `scripts/specrew-init.ps1`, `scripts/specrew-team.ps1`, `scripts/specrew-review.ps1`, existing helper usage in `specrew-start.ps1` and `specrew-update.ps1` | Every user-invoked entry point resolves relative project paths against PowerShell’s current location |
| Slice B | Internal audit and mirrored extension parity | `extensions/specrew-speckit/scripts/*.ps1`, `.specify/extensions/specrew-speckit/scripts/*.ps1`, especially `resolve-quality-profile`, `run-hardening-gate`, `run-mechanical-checks`, and `validate-governance` | All in-scope user-supplied relative-path parameters use the shared helper or equivalent inline logic |
| Slice C | Deterministic proof, anti-pattern scanning, and trap-corpus follow-through | `tests/integration/project-path-resolution-regression.ps1`, existing validation lanes, `.specrew/quality/known-traps.md`, `specs/009-project-path-resolution/quality/trap-reapplication.md` | Regressions fail closed and the bug becomes a reusable known trap before closure |

### Validation Commands

```powershell
pwsh -NoProfile -File .\tests\integration\quality-profile-foundation.ps1
pwsh -NoProfile -File .\tests\integration\hardening-gate-contract.ps1
pwsh -NoProfile -File .\tests\integration\quality-evidence-governance.ps1
pwsh -NoProfile -File .\tests\integration\validation-contract-lane.ps1
pwsh -NoProfile -File .\tests\integration\project-path-resolution-regression.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File .\extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath .
```

## Post-Design Constitution Re-check

- **Spec Authority Gate**: PASS — The design remains bounded to the approved feature 009 scope and does not widen into unrelated PowerShell cleanup.
- **Layering Gate**: PASS — The proposed work stays in Specrew-owned CLI/governance layers and their test artifacts.
- **Traceability Gate**: PASS — Implementation slices map cleanly to FR-001/002, FR-003, FR-006/007, and FR-008.
- **Ownership Gate**: PASS — Human approval remains explicit for any exemptions and for the final trap-corpus text.
- **Capacity Gate**: PASS — The plan stays within one bounded repair slice and keeps feature 009 ahead of feature 008 work.
- **Drift/Reconciliation Gate**: PASS — Mirrored extension trees, missing trap-corpus file creation, and branch-name drift are all called out explicitly.
- **Verification Gate**: PASS — Existing governance lanes plus the planned regression lane provide both process and outcome verification.

## Complexity Tracking

No constitution exceptions are required for this repair slice.
