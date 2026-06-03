# Implementation Plan: Unix Resolver Sidecar Hardening Investigations

**Branch**: `160-unix-resolver-sidecar-hardening` | **Date**:
2026-06-03 | **Spec**: `spec.md`
**Input**: Feature specification from
`specs/160-unix-resolver-sidecar-hardening/spec.md`

## Summary

Deliver one governed investigation iteration for two Feature-140 fast-follow
suspicions. The work is evidence-first: each suspected issue gets a repro
fixture and a disposition before any shipped resolver, sidecar, host-runtime, or
documentation behavior changes. If a failure is confirmed, the implementation is
limited to the proven failure with regression tests. If it is not confirmed, the
iteration closes with recorded evidence and no behavior change for that finding.

## Technical Context

**Language/Version**: PowerShell 7 for module scripts, deploy scripts, host
runtime handlers, and integration tests
**Primary Dependencies**: PowerShell Core (`pwsh`), existing standalone
PowerShell integration-test harnesses, existing Specrew module scripts
**Storage**: No product persistence; temporary scratch projects and evidence
records only
**Testing**: Focused PowerShell integration tests run directly with `pwsh`;
Windows path proof on the current host; Unix/macOS proof preferred via real
PowerShell and allowed through deterministic path fixtures when equivalent
**Target Platform**: Windows, macOS, Linux PowerShell
**Project Type**: PowerShell module + CLI/runtime deployment tooling
**Performance Goals**: Test fixtures should run in under 30 seconds locally and
must avoid network or package-manager access
**Constraints**: No blind fixes; do not push; do not touch unrelated untracked
or runtime files; product docs only change after confirmed behavior changes
**Scale/Scope**: Two independent investigation slices, each with conditional fix
work only after repro evidence

## Architecture

### Components

1. **Resolver path investigation harness** - a deterministic test/probe covering
   path construction used by module/script resolution. Source surfaces to inspect
   and test include `Specrew.psm1`, `scripts/specrew.ps1`, and any helper path
   that decides whether a development tree or installed module is authoritative.
   The harness must record the current behavior before any resolver change.
2. **Path construction candidate fix** - conditional only if the resolver
   harness proves failure. Expected shape is multi-segment `Join-Path`, explicit
   `[System.IO.Path]::Combine(...)`, or equivalent platform-safe construction,
   with no broad resolver rewrite.
3. **Managed-refresh sidecar fixture** - direct deploy-logic tests around
   `hosts/_team-canonical.ps1`, `hosts/*/handlers.ps1`, and
   `extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1`. The fixture
   models canonical charters, host-native deployed files, sidecar markers, inline
   managed markers, and user-edited unmanaged files.
4. **Marker behavior candidate fix** - conditional only if the sidecar fixture
   proves marker creation or recognition is broken. Expected shape is a focused
   change to marker creation/read semantics, not broad host-runtime or Squad
   deployment refactoring.
5. **Investigation evidence record** - final implementation/review evidence must
   name each suspected issue, attempted repro path, observed result, disposition
   (`confirmed`, `not-confirmed`, or `environment-blocked`), changed files if
   any, and matching tests.

### Canonical Flow

Planning creates test and evidence structure. Implementation first writes and
runs the repro fixture for a suspicion. If the fixture fails in the suspected
way, the implementer records the failure, applies the smallest behavior fix, and
reruns Windows plus Unix-equivalent regression coverage. If the fixture does not
fail, the implementer records not-confirmed evidence and does not change shipped
behavior for that suspicion.

### FR to Verification Mapping

| FR | Verification | Authoritative Surface |
| --- | --- | --- |
| FR-001 | Resolver repro output exists before resolver source diffs | review evidence + test log |
| FR-002 | Unix/macOS run or deterministic cross-platform path fixture proves embedded backslash semantics | resolver path integration test |
| FR-003 | Separator-safe path construction appears only after confirmed failure | source diff + evidence ordering |
| FR-004 | Windows and Unix path regression cases pass after confirmed fix | resolver path integration test |
| FR-005 | Fresh scratch fixture exercises deploy logic and related mirrors | managed sidecar integration test |
| FR-006 | Marker creation and marker recognition are asserted separately | managed sidecar integration test |
| FR-007 | Marker-controlled fix is limited to proven behavior | source diff review |
| FR-008 | Managed refresh and unmanaged preserve behavior both pass | managed sidecar integration test |
| FR-009 | Not-confirmed findings record attempted repro and no code change | review evidence |
| FR-010 | No push, unrelated files untouched, docs only if confirmed | git status + review checklist |

## Phase 1 Quality Planning

**Phase Scope**: `phase-1-first-slice`
**Resolved Quality Profile Output**:
`quality-profile.node-rest-with-postgres.v1` from
`resolve-quality-profile.ps1` on 2026-06-03.
**Feature-Specific Applicability**: The resolver selected a repo-wide
Node/Postgres preset from package signals, but this feature's active surfaces are
PowerShell resolver and runtime-deploy scripts. Node API and Postgres tooling are
not applicable unless implementation unexpectedly touches those stacks. The
required quality dimensions still apply: code quality, separation of concerns,
verification confidence, maintainability, security, robustness, resiliency, and
retry/idempotency review.

### Stack Surfaces in Scope

| Stack Surface | Path Globs / Evidence | Recognized Stack | Why It Matters |
| --- | --- | --- | --- |
| `ps-module-resolver` | `Specrew.psm1`, `scripts/specrew.ps1`, resolver-related helper tests | PowerShell module/CLI | Determines dev-tree vs installed-module resolution |
| `host-runtime-sidecars` | `hosts/_team-canonical.ps1`, `hosts/*/handlers.ps1` | PowerShell host runtime deployment | Controls managed marker creation/read and preserve notices |
| `squad-runtime-deploy` | `extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1` | PowerShell deploy helper | Related managed mirrors and slash-surface marker deployment |
| `test-fixtures` | `tests/integration/*` and temporary scratch projects | PowerShell integration harness | Proves behavior before any fix |

### Risk Dimensions

| Risk Dimension | Status | Rationale |
| --- | --- | --- |
| `code-quality` | required | Any fix must stay narrowly scoped and reviewable |
| `design-quality-and-separation-of-concerns` | required | Resolver behavior, host runtime translation, and deploy helper refresh must not be conflated |
| `verification-confidence` | required | Spec requires proof before changes; smoke-only success is insufficient |
| `maintainability` | required | Regression tests must capture platform semantics for future maintainers |
| `security` | required | Runtime deployment writes agent files and must preserve user-owned edits |
| `robustness` | required | Failure and fallback behavior around path resolution and markers must be explicit |
| `resiliency` | required | Update/start refresh paths must be idempotent and recoverable by rerun |
| `retry-idempotency-and-recovery` | required | Managed refresh must be safe on repeated init/update/start or deploy runs |

### Quality Tool Bundle

| Area | Selection |
| --- | --- |
| Bundle ID | `ps-runtime-investigation-phase1` |
| Mechanical Checks | dead-field, anti-pattern, test-integrity |
| Ecosystem Tools | direct `pwsh` integration tests; repo-standard validator; PSScriptAnalyzer only if available in the repo test flow |
| Manual Evidence | feature plan Phase 1 section; iteration quality evidence; review evidence disposition table |

### Required Quality Gates

| Required Quality Gate | Category | Evidence Source |
| --- | --- | --- |
| `dead-field` | mechanical | `specs/160-unix-resolver-sidecar-hardening/iterations/001/quality/mechanical-findings.json` |
| `anti-pattern` | mechanical | `specs/160-unix-resolver-sidecar-hardening/iterations/001/quality/mechanical-findings.json` |
| `test-integrity` | mechanical | `specs/160-unix-resolver-sidecar-hardening/iterations/001/quality/mechanical-findings.json` |
| `stack-tooling-evidence` | tooling | `specs/160-unix-resolver-sidecar-hardening/iterations/001/quality/quality-evidence.md` |
| `quality-lens-review` | manual-evidence | `specs/160-unix-resolver-sidecar-hardening/iterations/001/quality/quality-evidence.md` |
| `retry-idempotency-review` | manual-evidence | managed sidecar fixture and quality evidence |

### Not-Applicable Dimensions and Rationale

| Dimension / Gate | Why Not Applicable | Follow-up |
| --- | --- | --- |
| Node REST API tooling | No API source is in scope for this feature | Activate only if implementation touches Node API files |
| Postgres-backed integration coverage | No persistence source or schema is in scope | Activate only if implementation unexpectedly touches persistence |
| Network retry | Tests must avoid network/package-manager access | None |

## Phase 2 Hardening and Specialist Review Planning

**Phase 2 Slice Scope**: hardening-gate planning only; runtime proof stays
pending until the implementation/review slice.
**Hardening Gate Artifact**:
`specs/160-unix-resolver-sidecar-hardening/iterations/001/quality/hardening-gate.md`
**Known-Traps Corpus Location**: `.specrew/quality/known-traps.md`

### Hardening Focus Areas

| Focus Area | Why It Matters | Status |
| --- | --- | --- |
| Security surface | Agent/runtime files may be user-owned; preserve-vs-refresh must be intentional | required |
| Error handling / failure semantics | Resolver fallback to installed modules and preserve notices must not hide stale behavior | required |
| Idempotency | Deploy/refresh fixtures must prove safe repeated runs | required |
| Test integrity | Repro-first requirement forbids after-the-fact tests that only prove the final implementation | required |

### Lens Activation Plan

| Lens Ref | Activation | Rationale |
| --- | --- | --- |
| `security-baseline@v1.0.0` | required | Marker semantics protect user-edited files from overwrite |
| `robustness-baseline@v1.0.0` | required | Resolver and deploy fallback paths must be explicit |
| `test-integrity@v1.0.0` | required | The feature's core value is proof before fix |

### Explicit Later Deferrals

- Full lens-row execution is deferred until the approved implementation/review
  slice.
- Product documentation updates are deferred unless implementation confirms and
  changes user-visible behavior.
- Broader init/update/start lifecycle fixtures are deferred unless direct
  deploy-logic fixtures cannot prove the sidecar behavior.

## Constitution Check

- **Spec Authority Gate**: Every planned artifact maps to FR-001 through FR-010.
  PASS.
- **Layering Gate**: Planned probes target resolver and runtime-deploy surfaces;
  no UI, API, or persistence layer work is planned. PASS.
- **Traceability Gate**: FR-to-verification mapping is explicit and task
  decomposition will keep each task tied to at least one FR/SC. PASS.
- **Ownership Gate**: Spec Steward owns dispositions; Implementer owns fixtures
  and conditional fixes; Reviewer owns evidence ordering, no-blind-fix checks,
  and unrelated-file review. PASS.
- **Capacity Gate**: One investigation iteration is feasible if fixes remain
  conditional and focused. PASS.
- **Drift/Reconciliation Gate**: Drift exists if source changes precede repro
  evidence, if docs change without confirmation, or if a finding lacks a final
  disposition. PASS.
- **Verification Gate**: Windows plus Unix/macOS or deterministic Unix-equivalent
  path/marker tests are required for confirmed fixes. PASS.

## Project Structure

### Documentation and Review Artifacts

```text
specs/160-unix-resolver-sidecar-hardening/
├── spec.md
├── research.md
├── plan.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── unix-resolver-sidecar-hardening.md
├── review-diagrams.md
├── checklists/
│   └── requirements.md
└── tasks.md                    # produced during tasks phase
```

### Planned Source/Test Surfaces

```text
Specrew.psm1                                      # conditional resolver fix only
scripts/specrew.ps1                               # conditional resolver fix only
hosts/_team-canonical.ps1                         # conditional marker fix only
hosts/*/handlers.ps1                              # conditional marker fix only
extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1
tests/integration/unix-resolver-path-semantics.tests.ps1
tests/integration/managed-runtime-sidecar.tests.ps1
```

**Structure Decision**: Prefer standalone integration tests that create scratch
projects under temporary paths and remove them after execution. Do not write
test fixtures into active runtime directories such as `.squad`, `.codex`,
`.cursor`, `.claude`, `.agents`, or `.specrew`.

## Capacity and Iteration Structure

One iteration is planned.

- **Iteration 001 - Repro-first investigations and conditional fixes (~13-18
  SP)**: resolver path probe and disposition; sidecar marker fixture and
  disposition; conditional separator-safe resolver fix; conditional
  marker-controlled refresh fix; review evidence and retro. If both suspicions
  are confirmed, the upper estimate applies. If either is not confirmed, the
  iteration closes that slice with evidence instead of using the budget for a
  speculative fix.

## Complexity Tracking

No Constitution Check violations. The extra planning artifacts and fixtures are
justified by the no-blind-fix rule: they prevent broad resolver/deploy changes
from being made without proof.
