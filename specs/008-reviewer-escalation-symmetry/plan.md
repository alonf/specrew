# Implementation Plan: Reviewer Escalation Symmetry and Lockout-Chain Cap

**Branch**: `008-reviewer-escalation-symmetry` | **Date**: 2026-05-09 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `specs/008-reviewer-escalation-symmetry/spec.md`

## Summary

Add a reviewer-side governance path that mirrors existing implementer-side escalation without changing FR-027 behavior. The design will introduce a dedicated reviewer-regression ledger, a new reviewer-regression state mirror in active iteration artifacts, runtime routing sync for the effective reviewer class, and a bounded implementer lockout-chain cap. Reviewer regressions remain **soft-warning governance events** by default; only explicit hold states from maximum-strength review with no independent reviewer path, or from the post-cap ownership rule, block the next action.

## Technical Context

**Language/Version**: PowerShell 7.x plus Markdown/YAML/JSON governance artifacts  
**Primary Dependencies**: `extensions/specrew-speckit` governance scripts (`manage-escalation-state.ps1`, `shared-governance.ps1`, `sync-squad-model-overrides.ps1`, `validate-governance.ps1`), `.specrew` runtime config, `.squad` routing/ledger artifacts, and feature-local spec artifacts  
**Storage**: Git-tracked Markdown/YAML/JSON in `specs/008-reviewer-escalation-symmetry/`, `.specrew/`, `.squad/`, `.github/agents/`, and `extensions/specrew-speckit/`  
**Testing**: PowerShell integration coverage anchored in `tests/integration/iteration-resume.ps1`, `review-command.ps1`, `reviewer-closeout-governance.ps1`, `gap-governance.ps1`, plus new 008-specific integration scenarios for reviewer regressions, withdrawals, carry-forward, and lockout-cap handling  
**Target Platform**: Local Specrew repositories driven from PowerShell and GitHub Copilot CLI with optional delegated agents  
**Project Type**: Workflow/governance extension update for Specrew + Spec Kit  
**Performance Goals**: Deterministic fail-closed routing updates, no silent reviewer-regression drift, bounded implementer rotation chains, and auditable carry-forward across closed iterations  
**Constraints**: Preserve spec 001 FR-027 behavior unchanged; treat reviewer regressions as soft-warning by default; block only on explicit FR-004/FR-010 hold paths; use runtime `strength_rank` ordering from `.specrew/iteration-config.yml`; make known-traps integration conditional on an enabled corpus; preserve closed iterations and reverse only still-pending state on withdrawal  
**Scale/Scope**: One cross-cutting governance slice spanning feature-scoped reviewer-regression records, active-iteration state projection, reviewer routing, decisions/handoff visibility, and deterministic integration coverage

## Phase 1 Quality Planning

**Phase Scope**: `phase-1-first-slice` — reviewer-regression governance surfaces, lockout-cap visibility, and validation lanes  
**Inferred Quality Profile**: `quality-profile.custom-composition.v1`  
**Selected preset ref or explicit custom composition**: Custom composition for PowerShell governance scripts, Markdown/YAML/JSON artifact contracts, runtime routing sync, and deterministic integration tests. No application-runtime preset fits this repository.  
**Bounded custom composition**: Validate state-machine truthfulness, ledger/schema consistency, soft-warning vs. blocker semantics, and routing-sync correctness. Leave downstream implementation execution and operator-run smoke validation explicit.

### Stack Surfaces in Scope

| Stack Surface | Path Globs / Evidence | Recognized Stack | Why It Matters |
| --- | --- | --- | --- |
| Reviewer-regression planning artifacts | `specs/008-reviewer-escalation-symmetry/{plan,research,data-model,quickstart}.md`, `contracts/**` | `custom` | These are the authoritative design artifacts for the feature. |
| Governance script layer | `extensions/specrew-speckit/scripts/*.ps1`, `.specify/extensions/specrew-speckit/scripts/*.ps1` | `powershell-governance` | The runtime behavior will live here, including new reviewer-regression management and validation logic. |
| Runtime routing + ledger surfaces | `.specrew/{config.yml,iteration-config.yml,role-assignments.yml}`, `.squad/{config.json,decisions.md,routing.md}` | `squad-routing` | Strongest-class lookup, lockout visibility, and human override records are driven from these artifacts. |
| Reviewer/coordinator prompt surfaces | `extensions/specrew-speckit/squad-templates/**`, `.github/agents/squad.agent.md` | `prompt-governance` | Reviewer-side escalation must be reflected in coordinator/reviewer operating guidance. |
| Validation lanes | `tests/integration/*.ps1` | `powershell-integration-tests` | The feature is only acceptable with deterministic scenario coverage. |

### Risk Dimensions

| Risk Dimension | Status (`required` / `not-applicable`) | Rationale |
| --- | --- | --- |
| State-transition correctness | `required` | The feature adds active, withdrawn, held, resolved, and carried-forward reviewer-regression states. |
| Routing integrity | `required` | Reviewer-class escalation and same-class independence must follow runtime strength ordering and explicit identity rules. |
| Governance artifact consistency | `required` | The ledger, state mirror, `.squad/config.json`, decisions ledger, and handoff must agree on current reviewer-regression state. |
| Soft-warning vs. blocker semantics | `required` | The repaired blocker semantics are central: regression events themselves are non-blocking unless they activate a defined hold path. |
| Test integrity | `required` | This slice introduces multiple state-machine branches that need scratch-project regression tests. |
| Application runtime load/perf | `not-applicable` | The feature changes governance/routing behavior, not a serving runtime or product UI. |

### Quality Tool Bundle

| Area | Selection | Evidence / Notes |
| --- | --- | --- |
| Bundle ID | `specrew-reviewer-regression-governance.v1` | Bounded to governance scripts, artifact contracts, and PowerShell integration scenarios |
| Mechanical Checks | managed-block schema review, decisions-ledger type validation, routing-config inspection, traceability review | Proof is captured in plan/data-model/contracts and in validator/test updates |
| Ecosystem Tools | `pwsh` integration tests, `validate-governance.ps1`, targeted script contract assertions | Matches the repository's real verification surfaces |

### Required Quality Gates

| Required Quality Gate | Category | Evidence Source | Phase 1 Status |
| --- | --- | --- | --- |
| Reviewer-regression ledger schema is explicit and append-only | `manual-evidence` | `data-model.md`, `contracts/reviewer-regression-governance.md` | `planned` |
| Active reviewer-regression state projects into runtime config without altering FR-027 escalation state | `manual-evidence` | `plan.md`, `contracts/reviewer-regression-governance.md` | `planned` |
| Lockout-cap activation is visible in decisions/state/handoff | `manual-evidence` | `plan.md`, `quickstart.md`, future integration tests | `planned` |
| Withdrawal reverses only still-pending state | `tooling` | future `tests/integration/reviewer-regression-withdrawal.ps1` | `planned` |
| Closed-iteration carry-forward preserves history and seeds the next active iteration | `tooling` | future `tests/integration/carry-forward-closed-iteration.ps1` | `planned` |

### Not-Applicable Dimensions and Rationale

| Dimension / Gate | Why Not Applicable in This Feature | Follow-up |
| --- | --- | --- |
| Browser/UI compatibility | There is no product UI surface in scope. | None |
| Database migration review | All new state is markdown/yaml/json governance state. | None |
| Throughput benchmarking | The slice changes routing policy and artifact state, not workload throughput. | Revisit only if runtime sync becomes slow in practice. |

### Explicit Phase 2+ Deferrals

- Dedicated bug-hunter lens execution remains governed by spec 005 and is not reopened here.
- Known-traps corpus initialization remains out of scope; 008 only integrates when the corpus already exists and is enabled.
- Human/operator smoke validation with live delegated agents remains deferred until implementation exists.
- Any wider routing-family redesign beyond reviewer-regression symmetry remains deferred.

## Phase 2 Hardening and Specialist Review Planning

**Phase 2 Slice Scope**: `reviewer-regression-hardening` — feature-scoped reviewer state, cap enforcement, and withdrawal/carry-forward correctness  
**Hardening Gate Artifact**: `specs/008-reviewer-escalation-symmetry/quality/hardening-gate.md` *(future implementation slice)*  
**Known-Traps Corpus Location**: `.specrew/quality/known-traps.md` *(conditional; only when enabled)*  
**Trap Reapplication Artifact**: `specs/008-reviewer-escalation-symmetry/quality/trap-reapplication.md` *(future, only when corpus is enabled)*

### Hardening Focus Areas

| Focus Area | Why It Matters in This Slice | Planned Artifact / Evidence | Status (`required` / `deferred` / `not-applicable`) |
| --- | --- | --- | --- |
| Error handling and failure semantics | The system must distinguish non-blocking regression events from the specific hold conditions that block the next review or revision. | `plan.md`, `contracts/reviewer-regression-governance.md`, future hardening gate | `required` |
| Reviewer routing independence | Same-class fallback must use a different reviewer identity when available, else hold for human direction. | `research.md`, `data-model.md`, future routing tests | `required` |
| Withdrawal and idempotency expectations | Misreports must reverse only still-pending state and never rewrite completed history. | `data-model.md`, future withdrawal tests, future hardening gate | `required` |
| Carry-forward correctness | Post-close events must seed the next active iteration without reopening the closed one. | `contracts/reviewer-regression-governance.md`, future carry-forward tests | `required` |
| Test-integrity targets | The slice is only credible if deterministic scratch-project tests cover the major branches. | `quickstart.md`, future integration tests | `required` |

### Lens Activation Plan

| Lens / Checklist Ref | Activation (`required` / `optional` / `not-applicable`) | Why Activated or Omitted | Planned Evidence / Artifact Path |
| --- | --- | --- | --- |
| `governance-state-correctness` | `required` | This feature is a state-machine and artifact-consistency repair at the governance layer. | `quality/hardening-gate.md` |
| `routing-consistency-review` | `required` | Strongest-class lookup and same-class independence are the core behavioral risks. | `quality/hardening-gate.md` |
| `known-traps-corpus-integration` | `optional` | Only meaningful when a project has an enabled corpus on disk. | `quality/trap-reapplication.md` when applicable |
| `runtime-service-security` | `not-applicable` | No new networked service or data plane is introduced. | none |

### Routing Policy

| Lens Scope | Requested Reasoning / Review Class | Effective Class (when run) | Override / Approval Record | Notes |
| --- | --- | --- | --- | --- |
| Reviewer-regression routing and hardening review | `strongest-available` | Record at execution time from runtime `strength_rank` resolution | Lower-tier use still requires explicit human approval in `.squad/decisions.md` | Mirrors spec 005 strongest-class policy |
| Soft-warning/blocker semantics review | `strongest-available` | Record at execution time | `none` unless human overrides | Must verify that only FR-004/FR-010 holds block progress |

### Explicit Later Deferrals

- Live delegated-agent evidence for strongest-class routing remains deferred until the routed execution path exists.
- Known-traps promotion into checklist/mechanical enforcement remains deferred to a future quality-governance slice.
- Any cross-feature analytics over reviewer-regression history remain deferred.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Pre-Research Evaluation

- **Spec Authority Gate**: PASS — Scope maps directly to approved User Stories 1–3, FR-001 through FR-015, and TG-001 through TG-008 in `spec.md`.
- **Layering Gate**: PASS — Changes stay in Specrew/Spec Kit governance surfaces: scripts, markdown/yaml/json artifacts, routing metadata, and integration tests.
- **Traceability Gate**: PASS — Planned deliverables cover reviewer-regression recording, routing, lockout-cap visibility, withdrawal handling, known-traps conditioning, and carry-forward behavior.
- **Ownership Gate**: PASS — Spec Steward owns policy truth; Planner owns artifact chain and iteration slicing; Implementer owns later script/runtime updates; Reviewer owns deterministic scenario validation.
- **Capacity Gate**: PASS — The slice is one bounded governance feature spanning artifact/schema design plus a later implementation/test pass.
- **Drift/Reconciliation Gate**: PASS — Drift signals are explicit: regression events missing from ledger, state/config mismatch, cap activation missing from handoff, withdrawn events still influencing routing, or carry-forward reopening closed iterations.
- **Verification Gate**: PASS — Validation lanes and future integration tests are explicitly named.

## Project Structure

### Documentation (this feature)

```text
specs/008-reviewer-escalation-symmetry/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── reviewer-regression-governance.md
└── tasks.md                           # created later by /speckit.tasks
```

### Repository Surfaces in Scope

```text
.specrew/
├── config.yml
├── iteration-config.yml
└── reviewer-regression-log.md         # planned new ledger

.squad/
├── config.json
├── decisions.md
├── routing.md
└── agents/
    └── reviewer/
        └── charter.md

.github/agents/
└── squad.agent.md

extensions/specrew-speckit/
├── scripts/
│   ├── manage-escalation-state.ps1    # anchor; behavior unchanged
│   ├── manage-reviewer-regression.ps1 # planned new script
│   ├── shared-governance.ps1
│   ├── sync-squad-model-overrides.ps1
│   └── validate-governance.ps1
└── squad-templates/
    ├── agents/
    │   └── reviewer/
    │       └── charter.md
    └── coordinator/
        └── specrew-governance.md

.specify/extensions/specrew-speckit/
└── squad-templates/
    └── coordinator/
        └── specrew-governance.md

specs/001-specrew-product/contracts/
└── iteration-artifacts.md

tests/integration/
├── iteration-resume.ps1
├── review-command.ps1
├── reviewer-closeout-governance.ps1
├── gap-governance.ps1
├── reviewer-regression-event.ps1      # planned new
├── lockout-chain-cap.ps1              # planned new
├── reviewer-regression-ledger.ps1     # planned new
├── reviewer-regression-withdrawal.ps1 # planned new
└── carry-forward-closed-iteration.ps1 # planned new
```

**Structure Decision**: Keep the feature entirely inside existing Specrew governance assets. The authoritative event history lives in `.specrew/reviewer-regression-log.md`; the active iteration gets a projected `reviewer-regression-state` managed block in `state.md`, and `.squad/config.json` mirrors only the currently effective unresolved state. Closed iterations remain immutable.

## Phase 0: Research Decisions

Research outputs are captured in [research.md](research.md). The decisions that drive this plan are:

1. Use `.specrew/reviewer-regression-log.md` as the append-only feature-scoped source of truth, with the active iteration `state.md` carrying a runtime mirror instead of inventing a separate parallel ledger.
2. Define reviewer-class escalation from runtime `strength_rank` ordering in `.specrew/iteration-config.yml`; same-class fallback requires a different reviewer identity, otherwise review holds for human direction.
3. Preserve repaired blocker semantics: reviewer regression events are soft-warning governance records; only explicit maximum-strength/no-independent-reviewer holds or post-cap ownership holds block forward progress.
4. Keep known-traps integration conditional: offer candidate trap entries only when the corpus exists and is enabled; otherwise record the skipped offer in the reviewer-regression ledger.
5. Implement reviewer symmetry through a new dedicated script and new state/ledger contract rather than mutating the existing implementer-side FR-027 machinery.

## Phase 1 Design

### Data and Contract Surfaces

- [data-model.md](data-model.md) defines reviewer regression events, active chains, lockout-chain tracking, withdrawal records, and candidate trap proposals.
- [contracts/reviewer-regression-governance.md](contracts/reviewer-regression-governance.md) defines the ledger, state mirror, config-sync, and decisions-ledger contracts for the new governance path.
- [quickstart.md](quickstart.md) captures the bounded validation path for the future implementation slice, including conditional known-traps behavior.

### Proposed Implementation Slices

| Slice | Scope | Affected Surfaces | Outcome |
| --- | --- | --- | --- |
| Slice A | Reviewer-regression artifact and state contract | `specs/008-reviewer-escalation-symmetry/*`, `.specrew/reviewer-regression-log.md`, `specs/001-specrew-product/contracts/iteration-artifacts.md` | Authoritative reviewer-regression record and active-state schema are explicit |
| Slice B | Runtime routing + lockout-cap enforcement | `extensions/specrew-speckit/scripts/manage-reviewer-regression.ps1`, `shared-governance.ps1`, `sync-squad-model-overrides.ps1`, `validate-governance.ps1`, `.squad/config.json` | Reviewer-class escalation, lockout-cap activation, and withdrawal/carry-forward behavior become executable |
| Slice C | Coordinator/reviewer guidance and handoff visibility | `extensions/specrew-speckit/squad-templates/**`, `.specify/extensions/specrew-speckit/squad-templates/**`, `.github/agents/squad.agent.md`, `.squad/routing.md`, `.squad/agents/reviewer/charter.md` | Runtime governance instructions surface the new reviewer-side policy consistently |
| Slice D | Deterministic proof | `tests/integration/reviewer-regression-event.ps1`, `lockout-chain-cap.ps1`, `reviewer-regression-ledger.ps1`, `reviewer-regression-withdrawal.ps1`, `carry-forward-closed-iteration.ps1` | Acceptance paths, edge cases, and repaired blocker semantics are regression-tested |

### Validation Commands

```powershell
pwsh -NoProfile -File .\tests\integration\iteration-resume.ps1
pwsh -NoProfile -File .\tests\integration\review-command.ps1
pwsh -NoProfile -File .\tests\integration\reviewer-closeout-governance.ps1
pwsh -NoProfile -File .\tests\integration\gap-governance.ps1
pwsh -NoProfile -File .\tests\integration\reviewer-regression-event.ps1
pwsh -NoProfile -File .\tests\integration\lockout-chain-cap.ps1
pwsh -NoProfile -File .\tests\integration\reviewer-regression-ledger.ps1
pwsh -NoProfile -File .\tests\integration\reviewer-regression-withdrawal.ps1
pwsh -NoProfile -File .\tests\integration\carry-forward-closed-iteration.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File .\extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath .
```

## Post-Design Constitution Re-check

- **Spec Authority Gate**: PASS — The design stays additive to spec 001 FR-027, spec 005 FR-034 through FR-040, and spec 008's approved clarifications.
- **Layering Gate**: PASS — No fictional application modules or unrelated runtime subsystems are introduced.
- **Traceability Gate**: PASS — Planned implementation slices map directly to FR-001 through FR-015 and TG-001 through TG-008.
- **Ownership Gate**: PASS — Policy, script, routing, and review responsibilities remain explicit.
- **Capacity Gate**: PASS — The feature remains one bounded governance slice with deterministic proof surfaces.
- **Drift/Reconciliation Gate**: PASS — The design defines explicit ledger/state reconciliation, carry-forward rules, and withdrawal handling.
- **Verification Gate**: PASS — Required commands and future tests are named and scoped.

## Complexity Tracking

No constitution exceptions are required for this planning slice.
