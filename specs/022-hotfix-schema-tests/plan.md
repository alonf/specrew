# Implementation Plan: Feature 022 Hotfix + Schema Tests

**Branch**: `022-hotfix-schema-tests` | **Date**: 2026-05-18 | **Spec**: [spec.md](spec.md)  
**Input**: Feature specification from `specs/022-hotfix-schema-tests/spec.md`

**Note**: This plan completes Phase 0 research and Phase 1 design only. It stops at the plan-completion boundary for human review and does **not** enter `/speckit.tasks`.

## Summary

**Primary Requirement**: Repair the three confirmed restart defects from the first post-Feature-021 restart attempt: closeout identity schema mismatch, incomplete seven-boundary synchronization, and unusable stale-state recovery at `specrew start`.

**Technical Approach**: Keep the hotfix bounded to one 10 SP iteration with 1 SP reserved for repair, preserve Feature 021 carry-forward governance defaults, and plan the implementation as three tightly scoped runtime lanes: (1) preserve both human-readable and machine-readable closeout identity state, (2) restore late-boundary sync wiring and ordered ledger evidence across all seven lifecycle boundaries, and (3) turn the stale-state A/B/C dead-end into a real recovery flow with an explicit `--recover` bypass. Regression coverage is planned as three standalone PowerShell integration scripts under `tests/integration/` so Proposal 054 can compose them later without collapsing this hotfix into a monolith.

## Technical Context

**Language/Version**: PowerShell 7.x for the active runtime/test lane, while preserving existing Specrew PowerShell module compatibility expectations  
**Primary Dependencies**: `scripts/specrew-start.ps1`, `scripts/internal/sync-boundary-state.ps1`, `extensions/specrew-speckit/scripts/scaffold-feature-closeout-dashboard.ps1`, lifecycle sync command wrappers under `extensions/specrew-speckit/commands/`, shared governance helpers, Git CLI  
**Storage**: File-based only (`.specrew/`, `.squad/`, `specs/`, `tests/`)  
**Testing**: Standalone PowerShell integration scripts run with `pwsh -NoProfile -File ...`, plus the existing governance validator  
**Target Platform**: Windows 11 primary; PowerShell 7+ flows remain compatible with Linux/macOS support expectations documented in the repo  
**Project Type**: PowerShell CLI/module with governance artifacts and integration-test scripts  
**Performance Goals**: No material startup regression beyond the current `specrew start` path; stale-state recovery must become actionable on the first detection path; boundary sync remains per-file atomic and ledger-visible  
**Constraints**: Single iteration only; 10 SP ceiling with 1 SP repair reserve inside the cap; preserve seven-boundary lifecycle model; keep FR-005 and FR-019 deferred; keep `--recover` orthogonal to approval/autopilot behavior; push after every commit; verify origin matches local HEAD before handoff; perform pre-handoff artifact checks before claiming plan completion  
**Scale/Scope**: Three confirmed bugs plus regression coverage only; three standalone integration scripts; seven lifecycle boundaries; no broader schema audit

## Phase 1 Quality Planning

> This section is bounded to the approved Feature 022 hotfix slice only. It plans the quality bar for schema parity, lifecycle synchronization, and restart recovery without claiming runtime proof already exists.

**Phase Scope**: `phase-1-first-slice` (schema parity + late-boundary sync + restart recovery hotfix)  
**Inferred Quality Profile**: `quality-profile.custom-composition.v1`  
**Selected preset ref or explicit custom composition**: Custom PowerShell governance-hotfix composition for state artifacts, lifecycle hooks, and interactive restart recovery  
**Bounded custom composition**: Frontmatter/schema parity checks, seven-boundary lifecycle evidence, restart-recovery failure semantics, and standalone PowerShell integration suites. Proposal 054 composition work, broader state-surface audits, and the deferred fourth bug remain explicitly out of scope.

### Stack Surfaces in Scope

| Stack Surface | Path Globs / Evidence | Recognized Stack | Why It Matters |
| --- | --- | --- | --- |
| `closeout-identity-surface` | `.squad/identity/now.md`, `scripts/internal/sync-boundary-state.ps1`, `extensions/specrew-speckit/scripts/scaffold-feature-closeout-dashboard.ps1` | custom | Schema parity must preserve human-readable identity content while keeping parser-readable `session_state_*` frontmatter |
| `lifecycle-boundary-sync` | `extensions/specrew-speckit/commands/speckit.specrew-speckit.sync-*.md`, `scripts/internal/sync-boundary-state.ps1`, `.squad/decisions.md` | custom | The hotfix must restore all seven ordered boundary sync entries, especially the late lifecycle boundaries |
| `start-recovery-flow` | `scripts/specrew-start.ps1`, `extensions/specrew-speckit/scripts/resume-iteration.ps1`, `.specrew/start-context.json` | custom | `specrew start` currently detects stale state but exits instead of letting the operator recover |
| `verification-surface` | `tests/integration/*.ps1`, `tests/README.md`, `specs/022-hotfix-schema-tests/iterations/001/quality/hardening-gate.md` | custom | FR-004, FR-009, and FR-015 must each land as a standalone PowerShell integration script with inspectable evidence |

### Risk Dimensions

| Risk Dimension | Status (`required` / `not-applicable`) | Rationale |
| --- | --- | --- |
| Schema parity correctness | required | Closeout identity state must satisfy both the human-readable summary contract and the machine-readable parser contract |
| Lifecycle integrity | required | Missing late-boundary sync entries recreate stale restart behavior and break restart evidence |
| Recovery failure semantics | required | The stale-state gate is a production blocker until the A/B/C flow and `--recover` path become usable |
| Test composition integrity | required | FR-004, FR-009, and FR-015 must stay independently runnable and later composable into Proposal 054 |
| Operator messaging clarity | required | Recovery mode and stale-state detection must explain why restart stopped and what the next action is |
| Database / service integrity | not-applicable | The hotfix touches file-based governance artifacts only; no database or external service schema is introduced |

### Quality Tool Bundle

| Area | Selection | Evidence / Notes |
| --- | --- | --- |
| Bundle ID | `custom-powershell-session-state-hotfix-v1` | Custom bundle for Specrew lifecycle-state and recovery hotfix work |
| Mechanical Checks | Frontmatter/session-state parity audit, late-boundary hook audit, standalone test-script naming discipline, artifact traceability review | Evidence recorded in `research.md`, `contracts/`, `quickstart.md`, and the iteration hardening gate |
| Ecosystem Tools | `pwsh -NoProfile -File tests/integration/closeout-identity-schema-parity.tests.ps1`, `pwsh -NoProfile -File tests/integration/lifecycle-boundary-sync.tests.ps1`, `pwsh -NoProfile -File tests/integration/start-recovery-flow.tests.ps1`, governance validator | Reuse existing repository PowerShell test conventions rather than introducing a new runner |

### Required Quality Gates

| Required Quality Gate | Category | Evidence Source | Phase 1 Status |
| --- | --- | --- | --- |
| Closeout identity schema parity | tooling | `tests/integration/closeout-identity-schema-parity.tests.ps1` + `contracts/closeout-identity-state-contract.md` | planned |
| Seven-boundary ordered sync evidence | tooling | `tests/integration/lifecycle-boundary-sync.tests.ps1` + `contracts/lifecycle-boundary-sync-contract.md` | planned |
| Restart recovery UX and `--recover` semantics | tooling/manual-evidence | `tests/integration/start-recovery-flow.tests.ps1` + `contracts/restart-recovery-contract.md` | planned |
| Observability on sync failure | mechanical/tooling | `research.md` decision on failure visibility + stale-state validation path | planned |
| Governance carry-forward compliance | manual-evidence | `iterations/001/plan.md`, `iterations/001/quality/hardening-gate.md`, and pre-handoff origin/artifact checks | planned |

### Not-Applicable Dimensions and Rationale

| Dimension / Gate | Why Not Applicable in This Feature | Follow-up |
| --- | --- | --- |
| GUI accessibility | The hotfix is CLI/session text only; no graphical UI is introduced | none |
| Distributed concurrency review | This slice restores single-operator restart behavior, not multi-host or concurrent coordination | none |
| Broad schema-audit gate | FR-005 explicitly limits schema parity auditing to `.squad/identity/now.md` | Proposal 054 / future durable gate |

### Explicit Phase 2+ Deferrals

- Proposal 054 composition of the standalone scripts remains deferred; this plan only names the independent scripts and their contracts.
- FR-005 broader schema parity auditing remains deferred beyond `.squad/identity/now.md`.
- FR-019 inbox-to-ledger / Scribe auto-consolidation remains deferred and must not be reopened by this plan.
- Runtime hardening evidence remains pending until implementation and review execute the planned suites.

## Phase 2 Hardening and Specialist Review Planning

> This section captures the pre-implementation hardening scaffold that must exist before execution. It records planning-time analysis and expected controls only; runtime proof remains pending.

**Phase 2 Slice Scope**: `Iteration 001 pre-implementation hardening gate for schema parity, late-boundary sync, and restart recovery`  
**Hardening Gate Artifact**: `specs/022-hotfix-schema-tests/iterations/001/quality/hardening-gate.md`  
**Known-Traps Corpus Location**: `.specrew/quality/known-traps.md`  
**Trap Reapplication Artifact**: none yet

### Hardening Focus Areas

| Focus Area | Why It Matters in This Slice | Planned Artifact / Evidence | Status (`required` / `deferred` / `not-applicable`) |
| --- | --- | --- | --- |
| Schema parity and closeout body preservation | Feature-closeout currently risks drifting between human-readable identity text and parser-readable frontmatter | `contracts/closeout-identity-state-contract.md` + hardening gate concern row | required |
| Error handling and failure visibility | A missing boundary sync or stale-state mismatch must remain visible instead of silently passing | `contracts/lifecycle-boundary-sync-contract.md` + hardening gate concern row | required |
| Recovery and idempotency expectations | Interactive recovery and `--recover` must remain operator-safe and orthogonal to approval behavior | `contracts/restart-recovery-contract.md` + hardening gate concern row | required |
| Test-integrity targets | The hotfix is only credible if each bug has a standalone regression script with later Proposal 054 composition value | `quickstart.md` + hardening gate concern rows | required |

### Lens Activation Plan

| Lens / Checklist Ref | Activation (`required` / `optional` / `not-applicable`) | Why Activated or Omitted | Planned Evidence / Artifact Path |
| --- | --- | --- | --- |
| `error-handling-review-v1` | required | Restart and sync failures are the primary production symptom | `iterations/001/quality/hardening-gate.md` |
| `test-integrity-review-v1` | required | FR-004, FR-009, and FR-015 must each have a standalone integration proof path | `quickstart.md` + `iterations/001/quality/hardening-gate.md` |
| `operational-resilience-review-v1` | required | Restart recovery must remain usable after ship/closeout and after stale-state corruption | `iterations/001/quality/hardening-gate.md` |
| `concurrency-correctness-v1` | not-applicable | The approved slice does not introduce concurrent execution semantics | N/A |

### Routing Policy

| Lens Scope | Requested Reasoning / Review Class | Effective Class (when run) | Override / Approval Record | Notes |
| --- | --- | --- | --- | --- |
| Required hardening and bug-hunter lenses | strongest-available | pending-runtime-execution | none | Follow the project default routing policy unless a later human-approved override is recorded |

### Explicit Later Deferrals

- Full runtime lens execution evidence remains deferred until the approved implementation/review slice runs.
- Known-traps additions and trap reapplication remain deferred unless implementation reveals a new recurring failure mode.
- Requested-versus-effective review-class evidence remains deferred until routed review actually runs.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Spec Authority Gate**: ✅ **PASS**. Scope remains anchored to `spec.md`, `checklists/requirements.md`, the iteration scaffold artifacts, `.squad/decisions.md`, and the explicit user directives for Feature 022. No new product scope is added.
- **Layering Gate**: ✅ **PASS**.  
  - **Spec Kit layer**: closeout dashboard scaffolding, sync command wrappers, planning artifacts, contracts, quickstart, and test design.  
  - **Squad layer**: session-state identity/decision surfaces consumed at restart.  
  - **Team configuration**: no roster expansion; stewardship labels map onto baseline Squad roles only.
- **Traceability Gate**: ✅ **PASS**. `research.md` resolves the planning-time bug analysis and scope bounds; `data-model.md` formalizes the state artifacts and recovery entities; `contracts/` defines the closeout, boundary-sync, and restart-recovery contracts; `quickstart.md` binds SC-001 through SC-005 to the three standalone integration scripts; `iterations/001/plan.md` carries grouped work-package ownership and capacity.
- **Ownership Gate**: ✅ **PASS**. Baseline-role mapping is explicit: Reliability + Runtime + Quality stewardship labels map to **Implementer** for build work, Quality stewardship maps to **Reviewer** for test work, Governance + Product stewardship map to **Spec Steward** for scope/policy work, and UX stewardship maps to **Implementer** for `--recover` and interactive recovery behavior. Spec Steward accountability remains explicit.
- **Capacity Gate**: ✅ **PASS**. Effort unit is story points. The feature is locked to **10 SP total** in **Iteration 001 only**, with **1 SP repair reserve** held inside the ceiling.
- **Drift/Reconciliation Gate**: ✅ **PASS**. Drift remains visible through the iteration drift log, `.squad/decisions.md`, the hardening gate, and stale-state validation. Conflicts must be reconciled explicitly instead of broadening into FR-005 or FR-019 deferrals. Push-after-every-commit, pre-handoff origin verification, and pre-handoff artifact checks remain mandatory.
- **Verification Gate**: ✅ **PASS**. Verification is planned through the three standalone PowerShell integration scripts, the governance validator, hardening-gate updates, and explicit origin/artifact checks before boundary handoff.

**Constitution Check Summary**: All pre-research gates pass. Phase 0 and Phase 1 planning may proceed.

### Post-Design Constitution Re-check

- **Spec authority remains intact**: ✅ The completed Phase 0/1 artifacts do not widen scope beyond the three confirmed bugs plus regression coverage.
- **Traceability remains intact**: ✅ Every planned deliverable still maps to approved stories/requirements and the single authorized iteration.
- **Ownership/capacity remain intact**: ✅ Baseline-role mapping and the 10 SP / 1 SP reserve lock are preserved in `iterations/001/plan.md`.
- **Verification remains intact**: ✅ The three standalone scripts remain the required proof surfaces and are still bounded for later Proposal 054 composition.

**Post-Design Verdict**: PASS.

## Authorization & Role Mapping

### Baseline-role disposition for stewardship labels

| Stewardship label / workstream | Baseline Squad role | Disposition |
| --- | --- | --- |
| Reliability steward + Runtime steward + Quality steward | Implementer | Own build-side repairs to closeout schema writing, boundary-sync wiring, stale-state observability, and related runtime helper changes |
| Quality steward | Reviewer | Own standalone regression scripts, test integrity review, and hardening evidence for FR-004, FR-009, and FR-015 |
| Governance steward + Product steward | Spec Steward | Own scope lock, policy guardrails, Proposal 054 / FR-005 / FR-019 deferrals, and pre-handoff governance checks |
| UX steward | Implementer | Own `--recover`, interactive A/B/C recovery flow, and operator-facing stale-state messaging |

**Disposition**: Feature 022 does not justify roster expansion. Stewardship labels remain descriptive responsibility tags mapped onto the baseline Squad roles above.

### Iteration authorization defaults applied

- **Human authority**: Alon Fliess remains the approving authority for plan completion and any later `/speckit.tasks` decision.
- **Capacity lock**: Iteration 001 only, 10 SP ceiling, 1 SP repair reserve inside the cap.
- **Repair policy**: 3-cycle repair budget remains carried forward.
- **Operational discipline**: push after every commit, pre-handoff origin verification, pre-handoff artifact checks, and live bookkeeping remain mandatory.
- **Scope guardrail**: keep Feature 022 bounded to the three confirmed bugs plus regression coverage only.
- **Deferred items preserved**: do not reopen FR-005 broader schema auditing or FR-019 fourth-bug follow-up.

### Single-iteration allocation

| Delivery lane | Scope anchor | Baseline owner | Planned effort (SP) |
| --- | --- | --- | --- |
| Governance, contracts, and scope reconciliation | FR-005, FR-014, FR-016, FR-017, FR-018, FR-019 | Spec Steward | 1.0 |
| Closeout schema parity repair design | FR-001, FR-002, FR-003, FR-004, FR-010 | Implementer | 2.0 |
| Seven-boundary sync restoration | FR-006, FR-007, FR-008, FR-009, FR-010 | Implementer | 2.5 |
| Restart recovery UX and `--recover` behavior | FR-011, FR-012, FR-013, FR-014, FR-015 | Implementer | 2.0 |
| Standalone regression suites and hardening evidence | FR-004, FR-009, FR-015, SC-001..SC-005 | Reviewer | 1.5 |
| Repair reserve | Bounded defect repair and artifact-quality assurance only | Reviewer + Spec Steward | 1.0 |

**Allocation verdict**: Primary planned scope is **9.0 SP** with **1.0 SP** reserved for repair, keeping the feature inside the authorized **10.0 SP** single-iteration ceiling.

## Project Structure

### Documentation (this feature)

```text
specs/022-hotfix-schema-tests/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── closeout-identity-state-contract.md
│   ├── lifecycle-boundary-sync-contract.md
│   └── restart-recovery-contract.md
└── tasks.md              # Not created by this plan
```

### Source Code (repository root)

```text
scripts/
├── specrew-start.ps1
└── internal/
    └── sync-boundary-state.ps1

extensions/
└── specrew-speckit/
    ├── commands/
    │   └── speckit.specrew-speckit.sync-*.md
    └── scripts/
        ├── scaffold-feature-closeout-dashboard.ps1
        └── resume-iteration.ps1

.squad/
├── identity/
│   └── now.md
└── decisions.md

tests/
└── integration/
    ├── closeout-identity-schema-parity.tests.ps1
    ├── lifecycle-boundary-sync.tests.ps1
    └── start-recovery-flow.tests.ps1
```

**Structure Decision**: This hotfix modifies existing PowerShell runtime/helper scripts and adds three standalone integration scripts under the existing `tests/integration/` convention. No new top-level directories or extra iterations are introduced.

## Complexity Tracking

> No constitutional violations require justification. These notes record bounded design choices only.

| Consideration | Design Choice | Simpler Alternative Rejected Because |
| --- | --- | --- |
| Schema parity surface | Limit parser/human-state parity work to `.squad/identity/now.md` | A broad audit would violate FR-005 and exceed the hotfix cap |
| Regression composition | Keep FR-004, FR-009, and FR-015 as standalone scripts | One monolithic end-to-end script would be harder to debug and would block later Proposal 054 composition |
| Recovery bypass semantics | Add a dedicated `--recover` path without changing approval flags | Folding approval/autopilot behavior into recovery would violate FR-014 and blur operator intent |
