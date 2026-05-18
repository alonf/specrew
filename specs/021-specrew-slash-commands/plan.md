# Implementation Plan: Specrew Slash-Command Surface

**Branch**: `021-specrew-slash-commands` | **Date**: 2026-05-18 | **Spec**: [file:///C:/Dev/Specrew/specs/021-specrew-slash-commands/spec.md](file:///C:/Dev/Specrew/specs/021-specrew-slash-commands/spec.md)  
**Input**: Feature specification from [file:///C:/Dev/Specrew/specs/021-specrew-slash-commands/spec.md](file:///C:/Dev/Specrew/specs/021-specrew-slash-commands/spec.md)

**Note**: This plan completes Phase 0 research and Phase 1 design only. Planning stops at the `/speckit.tasks` boundary for human review.

## Summary

**Primary Requirement**: Ship a first-class `/specrew.*` slash-command surface that exposes the full seven-command v1 catalog, preserves raw/native command output, provisions through standard Specrew setup and refresh flows, and coexists cleanly with `/speckit.*` without bypassing review boundaries.

**Technical Approach**: Model `/specrew.*` as a Squad-native, skill-backed command namespace whose source assets remain distribution-managed and whose deployed runtime lands in `.copilot/skills/specrew-*/SKILL.md`. Route each slash command through the existing PowerShell dispatcher and explicit script entry points in `scripts/`, keep `/specrew.help` as the canonical catalog fallback, enforce documented argument whitelists and visible diagnostics, and reuse existing compatibility/version-check and distribution-update patterns from Feature 019 and Feature 020.

## Technical Context

**Language/Version**: PowerShell 7+ for runtime scripts and module entry points; Markdown/YAML skill metadata for the slash-command contract  
**Primary Dependencies**: Existing `scripts/specrew.ps1` dispatcher, `Specrew.psm1` alias/module surface, Specrew distribution/update flows, Squad-native SKILL.md deployment surfaces, shared governance/version-check helpers  
**Storage**: File-based only: `.copilot/skills/`, `.squad/templates/skills/`, `.specrew/config.yml`, feature docs under `specs/021-specrew-slash-commands/`, and existing repository scripts/docs  
**Testing**: PowerShell-based integration and unit scripts under `file:///C:/Dev/Specrew/tests/integration/` and `file:///C:/Dev/Specrew/tests/unit/`, plus manual session validation for host-native discovery fallback, coexistence, and compatibility messaging  
**Target Platform**: Windows 11, WSL Ubuntu, Ubuntu Linux, and macOS in PowerShell 7+ with Squad/Copilot session support  
**Project Type**: PowerShell CLI/module with distributed skill templates and session-facing command contracts  
**Performance Goals**: Keep discovery/help usable inside 30 seconds for a first-time user, preserve current underlying command latency with only minimal wrapper overhead, and keep setup/refresh provisioning within the existing `specrew init` / `specrew update` expectations  
**Constraints**: Preserve `/speckit.*` coexistence and human-boundary discipline; forward only documented arguments; fail clearly with remediation guidance; keep Write-Output-visible warnings; avoid case-insensitive variable collisions; keep authored prose references in file:/// format; stay inside a locked 7 SP planning envelope with the usual repair reserve  
**Scale/Scope**: Seven canonical slash commands, one alias relationship, one compatibility pin policy, one distributed skill/template path, and a single-iteration slice capped at 7 SP

## Phase 1 Quality Planning

> This section is bounded to the approved Feature 021 slice only. It plans the quality bar for slash-command cataloging, routing, compatibility, and coexistence without claiming runtime proof already exists.

**Phase Scope**: `phase-1-first-slice` (catalog contract, skill assets, routing normalization, compatibility messaging, coexistence safeguards, validation docs)  
**Inferred Quality Profile**: `quality-profile.custom-composition.v1`  
**Selected preset ref or explicit custom composition**: Custom composition for a PowerShell command surface deployed through Squad-native skill assets  
**Bounded custom composition**: PowerShell routing parity checks, skill metadata completeness, compatibility/remediation validation, slash-command discovery fallback validation, coexistence checks, and reviewer-visible diagnostics. Future strongest-class execution evidence remains deferred to the implementation/review boundary.

### Stack Surfaces in Scope

| Stack Surface | Path Globs / Evidence | Recognized Stack | Why It Matters |
| --- | --- | --- | --- |
| `powershell-dispatcher` | `scripts/specrew.ps1`, `Specrew.psm1`, `scripts/specrew-where.ps1`, `scripts/specrew-update.ps1`, `scripts/specrew-team.ps1`, `scripts/specrew-review.ps1` | custom | Existing CLI/router semantics are the canonical backend for slash-command routing and alias parity |
| `skill-source-assets` | `extensions/specrew-speckit/squad-templates/skills/**`, `extensions/specrew-speckit/squad-templates/skills/README.md` | custom | Distribution-managed source of truth for Squad-native skill deployment |
| `skill-runtime-surface` | `.copilot/skills/**`, `file:///C:/Dev/Specrew/specs/001-specrew-product/contracts/squad-extension.md` | custom | Runtime discovery surface that Copilot/Squad already uses for skill-backed behavior |
| `compatibility-and-update` | `scripts/specrew-update.ps1`, `scripts/internal/version-check.ps1`, `file:///C:/Dev/Specrew/.specrew/config.yml` | custom | Slash commands must fail clearly when the installed/project baseline is too old |
| `verification-assets` | `tests/integration/**`, `tests/unit/**`, `specs/021-specrew-slash-commands/iterations/001/quality/hardening-gate.md` | custom | Discovery, routing, coexistence, compatibility, and diagnostics all need inspectable evidence |

### Risk Dimensions

| Risk Dimension | Status (`required` / `not-applicable`) | Rationale |
| --- | --- | --- |
| Command-contract integrity | required | Every shipped slash command needs a canonical name, help text, alias policy, and routing contract |
| Compatibility and remediation clarity | required | A too-old project or host must stop cleanly with upgrade guidance instead of appearing broken |
| Coexistence and boundary safety | required | `/specrew.*` must remain additive to `/speckit.*` and must not authorize lifecycle advancement |
| Discovery fallback reliability | required | Host-native prefix discovery may vary by environment, so `/specrew.help` must remain deterministic |
| Diagnostics and observability | required | Validator and runtime failures must stay reviewer-visible with Write-Output-friendly warning surfaces |
| Cross-platform PowerShell correctness | required | Windows/Linux/macOS all remain supported per the Feature 019 baseline |

### Quality Tool Bundle

| Area | Selection | Evidence / Notes |
| --- | --- | --- |
| Bundle ID | `custom-powershell-slash-command-surface-v1` | The repo uses custom PowerShell scripts and Squad-native skill assets rather than a standard preset |
| Mechanical Checks | Skill metadata completeness, command/alias parity, documented-argument whitelist parity, file:/// prose-link discipline, case-collision audit for new PowerShell variables, warning-surface visibility | Evidence will be recorded in `file:///C:/Dev/Specrew/specs/021-specrew-slash-commands/contracts/`, `file:///C:/Dev/Specrew/specs/021-specrew-slash-commands/quickstart.md`, and later execution artifacts |
| Ecosystem Tools | PowerShell integration/unit scripts, targeted script smoke runs, existing version-check/update helpers, hardening-gate review checklist | Reuse current repository patterns instead of introducing a new test runner |

### Required Quality Gates

| Required Quality Gate | Category | Evidence Source | Phase 1 Status |
| --- | --- | --- | --- |
| Slash catalog completeness | mechanical | [file:///C:/Dev/Specrew/specs/021-specrew-slash-commands/contracts/slash-command-catalog.md](file:///C:/Dev/Specrew/specs/021-specrew-slash-commands/contracts/slash-command-catalog.md) | planned |
| Routing and alias parity | tooling | [file:///C:/Dev/Specrew/specs/021-specrew-slash-commands/contracts/slash-command-routing.md](file:///C:/Dev/Specrew/specs/021-specrew-slash-commands/contracts/slash-command-routing.md) plus future PowerShell routing smoke tests | planned |
| Argument-whitelist clarity | mechanical | Per-command whitelist tables in the routing contract and aligned usage/help text | planned |
| Compatibility and remediation messaging | tooling/manual-evidence | [file:///C:/Dev/Specrew/specs/021-specrew-slash-commands/research.md](file:///C:/Dev/Specrew/specs/021-specrew-slash-commands/research.md), [file:///C:/Dev/Specrew/specs/021-specrew-slash-commands/quickstart.md](file:///C:/Dev/Specrew/specs/021-specrew-slash-commands/quickstart.md), and later update/version-check evidence | planned |
| Namespace coexistence and boundary discipline | manual-evidence | Quickstart coexistence scenarios and hardening-gate concern set | planned |
| Reviewer-visible diagnostics | mechanical | Existing error/usage patterns plus hardening-gate expectations for explicit warnings and non-silent failure | planned |

### Not-Applicable Dimensions and Rationale

| Dimension / Gate | Why Not Applicable in This Feature | Follow-up |
| --- | --- | --- |
| Database integrity | No database or persistent structured store is introduced; all state remains file-based | none |
| Concurrency correctness review | Slash-command routing is sequential CLI/session behavior, not concurrent processing | none |
| GUI accessibility | The surface is CLI/session text only; no graphical interface is added | none |

### Explicit Phase 2+ Deferrals

- Strongest-class execution evidence for specialist hardening review remains deferred until the approved implementation slice runs.
- Full host-by-host discovery-completion proof remains deferred until runtime validation can be recorded in session evidence.
- Future expansion beyond the seven-command v1 catalog (for example `/specrew.audit`) remains explicitly out of scope for this plan.

## Phase 2 Hardening and Specialist Review Planning

> This section captures the pre-implementation hardening scaffold that must exist before execution. It records planning-time focus areas and expected evidence only; no runtime hardening proof is claimed yet.

**Phase 2 Slice Scope**: `Iteration 001 pre-implementation hardening gate for discovery, routing, compatibility, and coexistence`  
**Hardening Gate Artifact**: [file:///C:/Dev/Specrew/specs/021-specrew-slash-commands/iterations/001/quality/hardening-gate.md](file:///C:/Dev/Specrew/specs/021-specrew-slash-commands/iterations/001/quality/hardening-gate.md)  
**Known-Traps Corpus Location**: [file:///C:/Dev/Specrew/.specrew/quality/known-traps.md](file:///C:/Dev/Specrew/.specrew/quality/known-traps.md)  
**Trap Reapplication Artifact**: none yet

### Hardening Focus Areas

| Focus Area | Why It Matters in This Slice | Planned Artifact / Evidence | Status (`required` / `deferred` / `not-applicable`) |
| --- | --- | --- | --- |
| Security surface analysis | Slash commands must not create hidden privileged behavior or unauthorized lifecycle advancement; only documented arguments may cross the command boundary | Hardening gate concern table plus routing contract boundary rules | required |
| Error handling and failure semantics | Unsupported args, missing setup, outdated baselines, and partial host discovery must fail clearly with explicit remediation guidance | Hardening gate concerns, routing contract failure table, quickstart negative-path checks | required |
| Retry and idempotency expectations | Re-running setup, refresh, help, and alias commands must stay stable and non-destructive | Hardening gate concerns plus quickstart refresh/retry checks | required |
| Test-integrity targets | The slice only succeeds if discovery, routing, compatibility, coexistence, and observability are exercised as an end-to-end contract | Quickstart validation matrix and later PowerShell integration evidence | required |

### Lens Activation Plan

| Lens / Checklist Ref | Activation (`required` / `optional` / `not-applicable`) | Why Activated or Omitted | Planned Evidence / Artifact Path |
| --- | --- | --- | --- |
| `security-issues-v1` | required | Namespace coexistence and lifecycle-boundary preservation are explicitly security/governance-sensitive | `iterations/001/quality/hardening-gate.md` |
| `error-handling-review-v1` | required | Unsupported args, compatibility mismatch, and missing setup are core failure modes in this slice | `iterations/001/quality/hardening-gate.md` |
| `test-integrity-review-v1` | required | The slash surface is only credible with end-to-end coverage across all seven commands | `quickstart.md` plus later execution evidence |
| `concurrency-correctness-v1` | not-applicable | The feature does not introduce concurrent execution or shared mutable runtime state | N/A |

### Routing Policy

| Lens Scope | Requested Reasoning / Review Class | Effective Class (when run) | Override / Approval Record | Notes |
| --- | --- | --- | --- | --- |
| Required hardening and bug-hunter lenses | strongest-available | pending-runtime-execution | none | Follow the project default routing policy unless a later human-approved override is recorded |

### Explicit Later Deferrals

- Full line-by-line lens execution evidence and runtime-only final proof remain deferred until the approved implementation/review slice authorizes them.
- Known-traps corpus additions and trap reapplication remain deferred until implementation reveals a concrete new trap.
- Requested-versus-effective review-class evidence remains deferred until lens execution actually occurs.
- Mixed-stack override workflows and reference-implementation comparisons remain deferred unless the later implementation slice expands scope.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Spec Authority Gate**: ✅ **PASS**. Scope is constrained to [file:///C:/Dev/Specrew/specs/021-specrew-slash-commands/spec.md](file:///C:/Dev/Specrew/specs/021-specrew-slash-commands/spec.md), [file:///C:/Dev/Specrew/proposals/032-specrew-slash-commands.md](file:///C:/Dev/Specrew/proposals/032-specrew-slash-commands.md), existing Feature 021 decision records in [file:///C:/Dev/Specrew/.squad/decisions.md](file:///C:/Dev/Specrew/.squad/decisions.md), and the Feature 019/020 carry-forward rules already approved. No new product scope is added.
- **Layering Gate**: ✅ **PASS**.  
  - **Spec Kit layer**: Source slash-command templates/contracts, distribution/update behavior, docs, and feature artifacts.  
  - **Squad layer**: Runtime skill deployment into `.copilot/skills/` and slash-command discoverability inside the session surface.  
  - **Team configuration**: No roster expansion is planned; baseline Squad roles remain sufficient.  
  - **Rationale**: The feature composes existing Specrew distribution and Squad-native surfaces instead of inventing a new plugin or runtime layer.
- **Traceability Gate**: ✅ **PASS**. Planned deliverables trace as follows: `research.md` resolves FR-004/FR-005/FR-009/FR-015/FR-019/FR-021 through FR-026 decisions; `data-model.md` formalizes the Key Entities section; `contracts/` defines the external slash-command contract for FR-001 through FR-024; `quickstart.md` covers SC-001 through SC-006 and the integration-test strategy; the pre-created hardening gate anchors FR-026.
- **Ownership Gate**: ✅ **PASS**. Ownership is explicit and baseline-role aligned. Spec owner labels in the specification are treated as descriptive labels, not as a mandatory roster expansion. The execution mapping is: Spec Steward owns catalog/governance/compatibility authority, Planner owns plan decomposition and acceptance traceability, Implementer owns PowerShell routing/distribution/test changes, Reviewer owns coexistence/diagnostics evidence, and Retro Facilitator owns later drift/repair learning capture.
- **Capacity Gate**: ✅ **PASS**. Effort unit is Story Points. The iteration planning envelope is locked at **7 SP total** with the usual **10% repair reserve** kept inside that ceiling. Planning therefore targets roughly 6 SP of primary implementation scope plus a bounded repair/quality allowance rather than expanding the roster or widening scope.
- **Drift/Reconciliation Gate**: ✅ **PASS**. Drift detection will stay live through structured decision updates in [file:///C:/Dev/Specrew/.squad/decisions.md](file:///C:/Dev/Specrew/.squad/decisions.md), hardening-gate updates, and per-lane drift labels for discovery, routing, compatibility, and coexistence. Conflicts escalate to the Spec Steward instead of silently shrinking the catalog or relaxing guardrails. Push-after-every-commit discipline remains in force.
- **Verification Gate**: ✅ **PASS**. Verification is planned through PowerShell-based test suites, manual session validation in `quickstart.md`, compatibility/remediation negative-path checks, and acceptance-criteria review against SC-001 through SC-006. Warnings must remain reviewer-visible, and file:/// prose-link discipline remains part of artifact review.

**Constitution Check Summary**: All pre-research gates pass. Phase 0 and Phase 1 planning may proceed.

## Authorization & Role Mapping

### Baseline-role disposition for spec owner labels

| Spec owner label / workstream | Baseline Squad role | Disposition |
| --- | --- | --- |
| Product steward + Governance steward | Spec Steward | Own canonical slash catalog, namespace rules, decisions, and human-boundary enforcement |
| Runtime steward + Distribution steward | Implementer | Own PowerShell router, module/skill deployment surfaces, version gating, and distribution/update changes |
| UX steward | Planner | Own catalog clarity, fallback help coverage, and traceability into quickstart/acceptance evidence |
| Reliability steward + Quality steward | Reviewer | Own failure-surface review, coexistence checks, diagnostics review, and gate evidence |
| Iteration learning / repair carry-forward | Retro Facilitator | Capture later drift and repair-budget learnings without expanding the active delivery roster |

**Disposition**: No roster expansion is justified for Feature 021. The descriptive owner labels from the specification map cleanly onto the baseline Squad roles already provisioned by Specrew.

### Iteration authorization defaults applied

- **Human authority**: Alon Fliess remains the approving authority for planning and the stop/go decision at the `/speckit.tasks` boundary.
- **Capacity**: locked at 7 SP total with the usual repair reserve inside the ceiling.
- **Repair policy**: 3-cycle repair budget and 30-minute wall-clock per failing test are carried forward as defaults.
- **Bookkeeping**: live updates to plan/gate/decision artifacts are required throughout implementation.
- **Drift handling**: per-lane drift labels must distinguish discovery, routing, compatibility, and coexistence failures.
- **Operational discipline**: push-after-every-commit, Write-Output-visible warnings, no case-insensitive variable collisions, and file:/// prose-path discipline remain mandatory.

## Project Structure

### Documentation (this feature)

```text
specs/021-specrew-slash-commands/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── slash-command-catalog.md
│   └── slash-command-routing.md
├── iterations/
│   └── 001/
│       └── quality/
│           └── hardening-gate.md
└── tasks.md             # Not created by this planning pass
```

### Source Code (repository root)

```text
Specrew.psm1
scripts/
├── specrew.ps1
├── specrew-init.ps1
├── specrew-update.ps1
├── specrew-where.ps1
├── specrew-review.ps1
├── specrew-team.ps1
└── internal/
    └── version-check.ps1

extensions/
└── specrew-speckit/
    └── squad-templates/
        └── skills/
            └── README.md

.copilot/
└── skills/
    └── specrew-*/SKILL.md

tests/
├── integration/
│   └── bootstrap-to-iteration.ps1
└── unit/
```

**Structure Decision**: Feature 021 stays inside the existing single-repository PowerShell/module structure. Slash-command source assets are distribution-managed, runtime skill deployment remains Squad-native under `.copilot/skills/`, and PowerShell scripts remain the single backend routing surface. No new service, database, or standalone plugin package is introduced.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

*No constitutional violations detected. This section remains empty.*

## Phase 0 Research Outputs

- `research.md` resolves all planning unknowns around skill deployment location, routing strategy, compatibility pinning, discovery fallback, and Feature 020 governance carry-forward.
- No `NEEDS CLARIFICATION` items remain in this plan after Phase 0.
- The authoritative research artifact is [file:///C:/Dev/Specrew/specs/021-specrew-slash-commands/research.md](file:///C:/Dev/Specrew/specs/021-specrew-slash-commands/research.md).

## Phase 1 Design Outputs

- `data-model.md` defines the catalog, definition, invocation, compatibility, and namespace-policy entities for the slash-command surface.
- `contracts/slash-command-catalog.md` defines the public command catalog and help/discovery contract.
- `contracts/slash-command-routing.md` defines routing, whitelisted arguments, compatibility gates, and failure semantics.
- `quickstart.md` defines the validation flow for discovery, routing, update/init provisioning, compatibility failures, and `/speckit.*` coexistence.
- `update-agent-context.ps1 -AgentType copilot` must be run after these artifacts are created so agent-facing context stays current without overwriting manual notes.

## Post-Design Constitution Re-Check

- **Spec Authority Gate**: ✅ **PASS**. `research.md`, `data-model.md`, `contracts/`, and `quickstart.md` all stay within the approved Feature 021 scope and preserve Proposal 032 / Feature 019 / Feature 020 alignment.
- **Layering Gate**: ✅ **PASS**. The design cleanly separates distribution-managed source assets from Squad-native runtime deployment and does not expand into unsupported plugin territory.
- **Traceability Gate**: ✅ **PASS**. Each Phase 1 artifact maps back to spec entities, FRs, TGs, and SCs; no orphan deliverable remains.
- **Ownership Gate**: ✅ **PASS**. The descriptive steward labels are fully mapped to baseline Squad roles with no roster expansion required.
- **Capacity Gate**: ✅ **PASS**. The design remains scoped to the locked 7 SP envelope and preserves the repair reserve rather than widening the feature.
- **Drift/Reconciliation Gate**: ✅ **PASS**. The design explicitly carries forward per-lane drift labels, live bookkeeping, push discipline, visible warnings, and case-collision avoidance.
- **Verification Gate**: ✅ **PASS**. The design now has concrete validation artifacts (`quickstart.md`, `contracts/`, hardening-gate scaffold) for discovery, routing, compatibility, and coexistence.

**Post-Design Verdict**: Constitution gates still pass after design. Planning stops here for human review at the plan-completion boundary; `tasks.md` is intentionally not created.
