# Iteration 001 Scope

**Feature**: F-044 | **Iteration**: 001 — Architectural Phase A-D + Slices 1-9

## FR allocation

| FR | Scope | Shipped in iter-001 | Vehicle |
|---|---|---|---|
| FR-001 | Canonical team source-of-truth at `.specrew/team/agents/<role>.md` | ✅ | `hosts/_team-canonical.ps1` (Slice 9) |
| FR-002 | `Status='supported'` hosts declare `AgentDir` | Partial — declared in 3/4 manifests during Phase A; Copilot `AgentDir` added in iter-002 | hosts/{claude,codex,antigravity}/host.psd1 |
| FR-003 | 5 contract functions per host (including `Install-<Kind>CrewRuntime`) | ✅ | Slice 9 — `Install-<Kind>CrewRuntime` in each `handlers.ps1` |
| FR-004 | Registry exposes `InstallCrewRuntime` slot | ✅ | Slice 9 — added to `$HostContractFunctionMap` |
| FR-005 | `Invoke-CrewBootstrap` dispatcher | ✅ | Slice 9 — `scripts/init/crew-bootstrap.ps1` |
| FR-006 | Auto-seed canonical on first `specrew start` | Deferred to iter-002 (W-3 finding) | iter-002 commit `dcc4beb7` |
| FR-007 | Specrew-managed marker (inline or sidecar) | Partial — inline marker on Claude/Codex/Antigravity; Copilot sidecar added in iter-002 | Slice 9 + iter-002 |
| FR-008 | User-edit preservation | Deferred to iter-002 (W-4 finding) | iter-002 commit `dcc4beb7` |
| FR-009 | `scripts/specrew-init.ps1` split into orchestrator + 9 init files | ✅ | Slices 1-8 |
| FR-010 | Marker-file walk for path resolution | Partial — applied in Slices 5/8; new Slice 9 files used fragile 2-level Split-Path (W-2 finding) | Cleanup in iter-002 |
| FR-011 | Adding a new host requires zero edits to existing files | ✅ | Phase A registry + Phase C registry-driven shims + Slice 9 contract |
| FR-012 | Documentation updated for 5-function contract + canonical team | Partial — Slice 9 finalization shipped architecture doc + slice-9 review + how-to update; contract doc rewrite + user-guide update deferred to iter-002 | iter-002 W-1 + W-11 |
| FR-013 | `tests/integration/crew-bootstrap-contract.tests.ps1` | Deferred to iter-002 (W-6 finding) | iter-002 commit `dcc4beb7` |

iter-001 ships the **architectural substrate**; iter-002 finishes the polish + closes the FR-006 / FR-007 (sentinel) / FR-008 / FR-010 / FR-012 / FR-013 gaps caught at the review boundary.

## Commits attributing to iter-001

| Commit | Title | Phase/Slice |
|---|---|---|
| `0aa3ff51` | design(host-package-architecture): per-host package proposal — Open-Closed host extension | (pre-implementation design doc) |
| `c61daf5b` | refactor(Phase A): per-host package registry + manifests for 4 hosts | Phase A |
| `b656da6c` | refactor(Phase B): per-host handler implementations + registry dispatch | Phase B |
| `0bf59876` | refactor(Phase C): replace host-flag-translation + host-runtime-inventory with registry-driven shims | Phase C |
| `d3581bab` | refactor(Phase C.2): Get-SpecrewHostLaunchInvocation → registry dispatch + antigravity added | Phase C.2 |
| `4170c305` | refactor(Phase C.3): coordinator-prompt surgery → declarative per-host rules engine | Phase C.3 |
| `af88192f` | docs(architecture): host-package architecture overview + add-a-new-host guide | (companion doc) |
| `e281aa17` | fix(Phase D + ship-blockers): detect-hosts manifest-driven + 3 deep-review ship-blockers | Phase D |
| `cdd8901e` | docs(architecture): truthful metrics post-Phase D | Phase D |
| `5f0939f2` | spec(antigravity-followup): small-fix slice spec for the deferred 4th host | (companion spec) |
| `f32a8c32` | draft(antigravity-slice): graduate antigravity from deferred to supported | Phase D companion |
| `6b3b010c` | refactor(Proposal 108 Slice 1): extract scripts/init/_utilities.ps1 | Slice 1 |
| `436f4923` | refactor(Proposal 108 Slice 2): extract scripts/init/preflight.ps1 | Slice 2 |
| `58f6a8ac` | refactor(Proposal 108 Slice 3): extract scripts/init/template-deploy.ps1 | Slice 3 |
| `a0094d1e` | refactor(Proposal 108 Slice 4): extract scripts/init/spec-kit-deploy.ps1 | Slice 4 |
| `7cdaa19a` | refactor(Proposal 108 Slice 5): extract scripts/init/dependency-install.ps1 + path-resolution fix | Slice 5 |
| `02f54860` | refactor(Proposal 108 Slice 6): extract scripts/init/agent-detection.ps1 + Get-CopilotSignals dedup | Slice 6 |
| `c7534feb` | refactor(Proposal 108 Slice 7): extract scripts/init/squad-deploy.ps1 | Slice 7 |
| `4294ca06` | refactor(Proposal 108 Slice 8): extract scripts/init/post-bootstrap-output.ps1 + path-resolution fix | Slice 8 |
| `15a472cf` | feat(Proposal 108 Slice 9): per-host Crew runtime install + canonical .specrew/team/ source-of-truth | Slice 9 |
| `70b1da06` | docs(Proposal 108 Slice 9): architecture diagram + implementation review + add-a-new-host updates | Slice 9 finalization |

## Cross-feature entanglement

This iteration is interleaved with F-043 on the `multi-host-integration-refactor` branch. F-044's commits sit BEFORE F-043's MVP (Phase A/B/C provide the registry F-043 uses) and AFTER F-043's wiring (Phase D + Slice 1-9 build on the post-wiring substrate). See [`../../../043-multi-host-onboarding/iterations/001/scope.md`](../../../043-multi-host-onboarding/iterations/001/scope.md) § "Cross-feature entanglement" for the full commit-order timeline.
