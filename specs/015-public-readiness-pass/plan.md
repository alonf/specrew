# Implementation Plan: Public-Readiness Pass

**Branch**: `015-public-readiness-pass` | **Date**: 2026-05-13 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `specs/015-public-readiness-pass/spec.md`

## Summary

Public-Readiness Pass establishes correct licensing, rewritten public documentation, a reconciled
version declaration in `.specrew/config.yml` (bumped from 0.1.0-dev to 0.14.0), a retroactive CHANGELOG, retroactive git tags (v0.13.0, v0.14.0),
updated product-spec status, and extended feature-closeout governance so future features include
release bookkeeping by default. `.specrew/config.yml` serves as the canonical source-of-truth for the active Specrew version;
downstream README and documentation surfaces mirror this version. The bounded Iteration 001 slice does not edit `.specrew/config.yml`; it locks the canonical-source decision so Iteration 002 can reconcile the remaining release-truth surfaces without ambiguity. All work is documentary and governance tooling; no runtime behaviour
changes occur. The technical approach relies on Markdown file authoring, a targeted additive
extension to `validate-governance.ps1`, and git tagging operations.

## Technical Context

**Language/Version**: PowerShell 7 (script extension), Markdown (all documentation artifacts), Git (tag operations)  
**Primary Dependencies**: `validate-governance.ps1` and `shared-governance.ps1` (existing); standard
`pwsh` 7+ runtime; Git ≥ 2.40 for retroactive tag creation  
**Storage**: Filesystem only — Markdown files at repo root and under `docs/`, `specs/`, and
`extensions/specrew-speckit/squad-templates/`  
**Testing**: Manual reviewer documentation check (primary); PowerShell Pester unit tests for the new
`Test-PublicReadinessSurfaces` function added to `validate-governance.ps1`  
**Target Platform**: Windows/Linux/macOS via `pwsh` 7; documentation is platform-agnostic  
**Project Type**: Governance tooling / documentation-pass feature (no user-facing runtime code)  
**Performance Goals**: Public-readiness drift check must add no perceptible latency to a standard
`validate-governance.ps1` run; the new check performs only file-existence and basic staleness probes  
**Constraints**: Additive only — no breaking changes to existing `validate-governance.ps1` hard exit
codes or structured-failure schema; soft warnings MUST NOT become hard blockers for iteration governance  
**Scale/Scope**: Fourteen shipped features reflected; single-developer alpha product; two planned
iterations totalling ≈19 story points

## Phase 1 Quality Planning

**Phase Scope**: `phase-1-first-slice` — Iteration 001 licensing, README rewrite, and product-spec status  
**Inferred Quality Profile**: `quality-profile.custom-composition.v1` — documentation/governance tooling, no recognised stack preset applies  
**Selected preset ref or explicit custom composition**: Custom composition: Markdown lint (`markdownlint-cli` via `.markdownlintrc`), PowerShell Script Analyzer for any script touched in Iteration 001, and manual reviewer documentation check  
**Bounded custom composition**: No recognised Phase 1 preset matches a docs-pass feature. Custom path: (1) markdownlint on all authored/modified `.md` files, (2) manual human-reviewer check that README sections satisfy FR-003–FR-007 for first-time-reader clarity, (3) no automated performance or security testing required for pure documentation.

### Stack Surfaces in Scope

| Stack Surface | Path Globs / Evidence | Recognized Stack | Why It Matters |
| --- | --- | --- | --- |
| `documentation` | `README.md`, `docs/versioning.md`, `NOTICE.md`, `CHANGELOG.md` | `custom` (docs) | First-time public observer landing surface; all FR-001–FR-009 targets |
| `governance-script` | `extensions/specrew-speckit/scripts/validate-governance.ps1` | `custom` (PowerShell tooling) | FR-016 public-readiness drift check extension |
| `product-spec` | `specs/001-specrew-product/spec.md` | `custom` (governance artifact) | FR-011 status reconciliation |

### Risk Dimensions

| Risk Dimension | Status | Rationale |
| --- | --- | --- |
| `security` | not-applicable | No authentication, no user data, no network endpoints introduced |
| `error-handling` | required | `validate-governance.ps1` extension must emit warnings without disrupting hard exit paths |
| `concurrency` | not-applicable | Single-developer dogfooding project; no concurrent runtime path |
| `data-integrity` | required | Git tag operations must not corrupt existing history; tags are lightweight and idempotent |
| `documentation-accuracy` | required | Core risk surface for this feature: inaccurate public docs block public-readiness goal |

### Quality Tool Bundle

| Area | Selection | Evidence / Notes |
| --- | --- | --- |
| Bundle ID | `docs-pass-governance-tooling-v1` | Custom composition for documentation + PowerShell tooling |
| Markdown Lint | `markdownlint-cli` via `.markdownlintrc` | Run on all authored/modified `.md` files before iteration close |
| Script Lint | `PSScriptAnalyzer` | Run on `validate-governance.ps1` after FR-016 extension |
| Manual Review | Human reviewer documentation check | Confirm README sections meet FR-003–FR-007 first-reader clarity bar |

### Required Quality Gates

| Required Quality Gate | Category | Evidence Source | Phase 1 Status |
| --- | --- | --- | --- |
| `markdownlint-clean` | tooling | `npx markdownlint-cli README.md NOTICE.md CHANGELOG.md docs/versioning.md` | planned |
| `psscriptanalyzer-clean` | tooling | `Invoke-ScriptAnalyzer -Path extensions/specrew-speckit/scripts/validate-governance.ps1` | planned |
| `manual-readme-reviewer-check` | manual-evidence | Human reviewer confirms all FR-003–FR-007 sections readable within 30s | planned |
| `validate-governance-clean-run` | tooling | `validate-governance.ps1` exits 0 after FR-016 extension added | planned |

### Not-Applicable Dimensions and Rationale

| Dimension / Gate | Why Not Applicable in This Feature | Follow-up |
| --- | --- | --- |
| `security-issues-v1` lens | No new auth surfaces, APIs, or user-data paths introduced | None — record as permanent N/A for this feature |
| `concurrency-correctness-review` | Single-developer dogfooding; no concurrent code paths added | None |
| `retry-idempotency` | No network calls or transactional operations in this feature | None |
| `performance-profiling` | Docs pass; new validator check is file-existence only | None |

### Explicit Phase 2+ Deferrals

- Pre-implementation hardening gate sign-off is now recorded for Iteration 001 on 2026-05-13.
- Iteration 002 is now explicitly authorized on 2026-05-13 for version bump, changelog, release tags, closeout governance extension, versioning schema documentation, public-readiness drift check, and stale shipped-feature spec status reconciliation.
- Dedicated bug-hunter lens execution and strongest-class routing remain deferred.
- Quality-drift logic, mixed-stack override workflows, and reference-implementation comparison remain deferred.

## Iteration 002 Planning Authorization

**Iteration 002 Scope** (Authorized 2026-05-13):
- Version reconciliation: `.specrew/config.yml` version bump to `0.14.0` (FR-008)
- Release documentation: root `CHANGELOG.md` with Features 001-014 entries (FR-009)
- Release tags: retroactive `v0.13.0` at `21d9e7f` and `v0.14.0` at `3ff32d4` (FR-010)
- Feature closeout governance: Version management steps in closeout template (FR-012, FR-013)
- Coordinator governance updates: Across `.github/agents/squad.agent.md`, `.squad/templates/squad.agent.md`, and `.specify/extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md` (FR-013)
- Versioning schema: `docs/versioning.md` and README reference (FR-014)
- Public-readiness drift check: `validate-governance.ps1` extension (FR-016)
- Shipped-feature spec status reconciliation: Update specs 007, 009, 011, 012 status from Draft to Complete (FR-017)

Iteration 002 testing and validation remain scoped: test fixtures, Pester coverage, markdown lint, validator verification, and evidence recording as defined in tasks T010-T025.

## Phase 2 Hardening and Specialist Review Planning

**Phase 2 Slice Scope**: `iteration-001-completed` and `iteration-002-authorized` — Iteration 001 hardening-gate sign-off is recorded; Iteration 002 scope is now authorized for planning and execution  
**Hardening Gate Artifact**: `specs/015-public-readiness-pass/iterations/001/quality/hardening-gate.md`  
**Known-Traps Corpus Location**: `.specrew/quality/known-traps.md`  
**Trap Reapplication Artifact**: `none` — not opened for this documentation-focused feature

### Hardening Focus Areas

| Focus Area | Why It Matters in This Slice | Planned Artifact / Evidence | Status |
| --- | --- | --- | --- |
| Security surface analysis | No new trust boundaries; existing `validate-governance.ps1` pattern preserved | `iterations/001/quality/hardening-gate.md` §security-surface | signed-off for Iteration 001 |
| Error handling and failure semantics | Soft-warning extension must not convert to hard exits | `iterations/001/quality/hardening-gate.md` §error-handling-expectations | signed-off for Iteration 001 |
| Retry and idempotency expectations | Git tag creation is idempotent (`--force` not used; duplicate tag emits advisory) | `iterations/001/quality/hardening-gate.md` §retry-idempotency-requirements | signed-off for Iteration 001 |
| Test-integrity targets | Pester unit tests for `Test-PublicReadinessSurfaces`; manual README reviewer check | `iterations/001/quality/hardening-gate.md` §test-integrity-targets | signed-off for Iteration 001 |

### Lens Activation Plan

| Lens / Checklist Ref | Activation | Why Activated or Omitted | Planned Evidence / Artifact Path |
| --- | --- | --- | --- |
| `robustness-baseline-v1` | not-applicable | Pure docs + soft-warning extension; no retry/failure-recovery logic | N/A |
| `security-baseline-v1` | not-applicable | No new security surface | N/A |
| `test-integrity-v1` | optional | Validator extension warrants a basic test-integrity check when authorized | `quality/lenses/test-integrity-v1.md` (when authorized) |

### Routing Policy

| Lens Scope | Requested Reasoning / Review Class | Effective Class (when run) | Override / Approval Record | Notes |
| --- | --- | --- | --- | --- |
| Iteration 001 hardening | default to strongest available | strongest-available | current-session human authorization recorded 2026-05-13 | Signed off for the bounded T001-T009 slice only |

### Explicit Later Deferrals

- Iteration 001 hardening sign-off is complete and implementation is authorized only for T001-T009.
- Iteration 002 is now explicitly authorized on 2026-05-13; hardening, release-truth work, validator-warning execution, and stale-status reconciliation are now in scope for T010-T025.
- Known-traps corpus seeding and trap reapplication remain deferred because they are not part of this documentation-focused feature.
- Public-repo visibility change and any new scope or lifecycle artifacts beyond the two-iteration slice still require later human authorization.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Spec Authority Gate**: ✅ PASS. Plan scope maps directly to approved `spec.md` (FR-001–FR-016,
  TG-001–TG-004). No work is proposed outside that boundary. Later explicit human approval recorded
  on 2026-05-13 completed `T001-T009`; `T010-T025` are now separately authorized for Iteration 002.

- **Layering Gate**: ✅ PASS. Changes are correctly classified:
  - Spec Kit layer: `plan.md`, `research.md`, `data-model.md`, `quickstart.md`, `contracts/` (this
    file set — governance/specification artifacts)
  - Specrew team-configuration layer: `validate-governance.ps1` extension (additive soft-warning
    check in the Specrew extension script), coordinator-governance update in
    `extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md`
  - Repository root: `LICENSE`, `NOTICE.md`, `CHANGELOG.md`, `README.md`, `docs/versioning.md`
    (documentation assets, not Squad or Spec Kit internals)
  - Out of scope for the currently authorized slice: Squad runtime layer changes, Iteration 002
    versioning/tag/governance-extension work, public visibility change, and any lifecycle expansion
    beyond `T001-T009`

- **Traceability Gate**: ✅ PASS. Every planned deliverable links to at least one FR in the spec:
  - LICENSE → FR-001 | NOTICE.md → FR-002 | README sections → FR-003–FR-007
  - Product spec status → FR-011 | Iteration 001 boundary → FR-015
  - Versioning reconciliation → FR-008, FR-014 | CHANGELOG → FR-009 | Tags → FR-010
  - Closeout guidance → FR-012, FR-013 | Drift check → FR-016
  - User stories: US-1 (FR-001–007, FR-011), US-2 (FR-008–011, FR-014, FR-016), US-3 (FR-012–016)

- **Ownership Gate**: ✅ PASS. Roles are explicit per spec Governance Alignment:
  - Spec Steward: Alon Fliess (requesting human)
  - Iteration Facilitator: Specrew planner/coordinator pairing
  - Repository steward: responsible for FR-001, FR-002
  - Documentation steward: FR-003–FR-007, FR-014
  - Release steward: FR-008–FR-010
  - Product spec steward: FR-011
  - Governance steward: FR-012, FR-013, FR-016

- **Capacity Gate**: ✅ PASS. Two iterations; effort unit is story points (complexity).
  - Iteration 001: ≈10 story points (licensing 2 + README rewrite 4 + product-spec status 1 +
    planning scaffold 3)
  - Iteration 002: ≈9 story points (versioning 2 + CHANGELOG 2 + tags 1 + closeout governance 2 +
    drift check 1 + shipped-spec status reconciliation 1)
  - Total: ≈19 story points (matches the current two-iteration planning baseline)

- **Drift/Reconciliation Gate**: ✅ PASS. Drift signals are explicit per spec §Governance Alignment:
  mismatch among README public state, licensing files, declared version, changelog, tags,
  product-spec status, or closeout guidance constitutes drift. `validate-governance.ps1` soft
  warning (FR-016) provides proactive detection at every governance gate.

- **Verification Gate**: ✅ PASS. Verification activities are defined:
  - markdownlint clean run on all authored `.md` files
  - PSScriptAnalyzer clean on modified `validate-governance.ps1`
  - `validate-governance.ps1` exits 0 after FR-016 extension
  - Manual human-reviewer documentation check (FR-003–FR-007, SC-001, SC-002)
  - Git tag existence verification (`git tag -l "v0.13.0" "v0.14.0"`)
  - Changelog + version + product-spec alignment check (SC-003, SC-004)

**Post-Phase-1-Design Re-check**: ✅ PASS — see research.md and data-model.md. All clarifications
resolved, no new constitution conflicts introduced by the chosen design.

## Project Structure

### Documentation (this feature)

```text
specs/015-public-readiness-pass/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output — validate-governance.ps1 soft-warning contract
│   └── public-readiness-warning-schema.md
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
# Root-level licensing and attribution (Iteration 001)
LICENSE                          # FR-001 — MIT license text
NOTICE.md                        # FR-002 — upstream attribution (Squad + Spec Kit)

# Public documentation (Iteration 001 + 002)
README.md                        # FR-003–FR-007 rewrite; versioning summary (FR-008)
CHANGELOG.md                     # FR-009 retroactive entries Features 001–014

# Versioning source-of-truth (Iteration 002)
.specrew/
└── config.yml                   # FR-008 specrew_version: "0.14.0" (authoritative version source)

# Versioning reference (Iteration 002)
docs/
└── versioning.md                # FR-014 detailed versioning policy

# Product-spec status (Iteration 001)
specs/001-specrew-product/
└── spec.md                      # FR-011 status → "Active 0.14.0"

# Governance extension (Iteration 002)
extensions/specrew-speckit/
├── scripts/
│   └── validate-governance.ps1  # FR-016 additive soft-warning block
└── squad-templates/coordinator/
    └── specrew-governance.md    # FR-012, FR-013 version-management closeout steps

# Git tags (Iteration 002)
# v0.13.0 → commit 21d9e7f (Merge PR #79, Feature 013 catch-up merge to main)
# v0.14.0 → commit 3ff32d4 (Merge PR #99, Feature 014 current mainline)
```

**Structure Decision**: Single-project documentation/governance pass. No `src/`, `backend/`,
or `frontend/` directories are involved. All changes are to root-level files, `docs/`, `specs/`,
and the existing `extensions/specrew-speckit/` extension directories.

## Complexity Tracking

> No constitution violations requiring justification. All changes are additive within existing
> layer boundaries.
