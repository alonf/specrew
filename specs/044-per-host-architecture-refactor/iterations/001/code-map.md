# Iteration 001 Code Map

**Feature**: F-044 | **Iteration**: 001 — Architectural Phase A-D + Slices 1-9

## Surface inventory

### Host package registry (Phase A)

| File | Lines | Purpose |
|---|---|---|
| `hosts/_registry.ps1` | ~330 | Registry discovery, manifest validation, contract-function dispatch |
| `hosts/_contract.md` | ~120 | Declarative contract documentation |
| `hosts/copilot/host.psd1` | ~28 | Copilot manifest |
| `hosts/claude/host.psd1` | ~27 | Claude manifest |
| `hosts/codex/host.psd1` | ~28 | Codex manifest |
| `hosts/antigravity/host.psd1` | ~27 | Antigravity manifest (Phase C.2 — graduated from deferred) |

### Per-host handlers (Phase B)

| File | Lines | Functions |
|---|---|---|
| `hosts/copilot/handlers.ps1` | ~170 | New-CopilotLaunchInvocation, ConvertTo-CopilotFlag, Test-CopilotRuntimeInstalled, Get-CopilotSignals, Install-CopilotCrewRuntime |
| `hosts/claude/handlers.ps1` | ~165 | New-ClaudeLaunchInvocation, ConvertTo-ClaudeFlag, Test-ClaudeRuntimeInstalled, Get-ClaudeSignals, Install-ClaudeCrewRuntime, ConvertTo-ClaudeAgentDescription |
| `hosts/codex/handlers.ps1` | ~165 | New-CodexLaunchInvocation, ConvertTo-CodexFlag, Test-CodexRuntimeInstalled, Get-CodexSignals, Install-CodexCrewRuntime, ConvertTo-CodexAgentDescription, ConvertTo-CodexTomlString |
| `hosts/antigravity/handlers.ps1` | ~165 | New-AntigravityLaunchInvocation, ConvertTo-AntigravityFlag, Test-AntigravityRuntimeInstalled, Get-AntigravitySignals, Install-AntigravityCrewRuntime, ConvertTo-AntigravityAgentDescription |

### Coordinator-prompt surgery (Phase C.3)

| File | Lines | Purpose |
|---|---|---|
| `scripts/internal/coordinator-prompt-surgery.ps1` | ~130 | Rules-engine — applies universal header (FR-011) + per-host declared rules |
| `hosts/copilot/coordinator-rules.psd1` | ~10 | Copilot rules (empty Rules array) |
| `hosts/claude/coordinator-rules.psd1` | ~20 | Claude per-host strip/replace rules |
| `hosts/codex/coordinator-rules.psd1` | ~20 | Codex per-host strip/replace rules + Codex pwsh-form rewrite |
| `hosts/antigravity/coordinator-rules.psd1` | ~20 | Antigravity per-host rules |

### Canonical team source-of-truth (Slice 9)

| File | Lines | Purpose |
|---|---|---|
| `hosts/_team-canonical.ps1` | ~180 | Get-SpecrewTeamCanonicalPath, Get-SpecrewTeamAgentsPath, Get-SpecrewCanonicalAgentRoles, Get-SpecrewCanonicalCharterContent, Get-SpecrewBaselineCrewRoles, Get-SpecrewShippedCharterPath, Initialize-SpecrewTeamCanonical |
| `scripts/init/crew-bootstrap.ps1` | ~70 | Initialize-SpecrewTeam (init-time seed) + Invoke-CrewBootstrap (start-time per-host dispatch) |

### `scripts/init/` split (Slices 1-8)

| File | Lines | Functions |
|---|---|---|
| `scripts/init/_utilities.ps1` | ~242 | 11 helper functions (Invoke-NativeCommand*, Add-Action, Ensure-DirectoryExists, Get-SpecrewExecutionLayout, etc.) |
| `scripts/init/preflight.ps1` | ~207 | Test-PreFlightDependencies, Show-Usage |
| `scripts/init/template-deploy.ps1` | ~228 | Copy-TemplateTree, Invoke-BundledTemplateDeployment, Test-BootstrappedProjectState |
| `scripts/init/spec-kit-deploy.ps1` | ~250 | 9 spec-kit deployment functions |
| `scripts/init/dependency-install.ps1` | ~165 | Install-MissingDependency, Invoke-VersionValidation, etc. |
| `scripts/init/agent-detection.ps1` | ~280 | Agent detection (delegates Copilot signals to registry) |
| `scripts/init/squad-deploy.ps1` | ~214 | Squad-CLI probe + Initialize-SquadFallbackScaffold (Copilot-only) |
| `scripts/init/post-bootstrap-output.ps1` | ~181 | Write-PostBootstrapGuidance, Write-BootstrapSummary |

### Registry-driven shims (Phase C)

| File | Lines | Notes |
|---|---|---|
| `scripts/internal/host-flag-translation.ps1` | ~55 (was 121) | Thin shim — dispatches to per-host `ConvertTo-<Kind>Flag` |
| `scripts/internal/host-runtime-inventory.ps1` | ~62 | Iterates `Get-RegisteredHostKinds`, reads manifest AgentDir |
| `scripts/internal/detect-hosts.ps1` | ~120 (was ~290) | 4 lookup functions now 1-line manifest reads |

### `scripts/specrew-start.ps1` (Phase C.2 + Slice 9 integration)

- `Get-SpecrewHostLaunchInvocation` rewritten to registry dispatch
- Added `Invoke-CrewBootstrap` call after host resolution
- Host-history dot-source + `Resolve-SpecrewHostFromHistory` integration (F-043 surface — uses F-044's registry)

### Tests (architectural coverage)

| File | Assertions | Coverage |
|---|---|---|
| `tests/integration/host-registry.tests.ps1` | 13 | Registry discovery, manifest validation, kind/folder parity, legacy parity, per-host fields, dispatch correctness |
| `tests/integration/multi-host-launch-path.tests.ps1` | 21 | F-040 suite, regression-covers Phase C launch path |
| `tests/integration/host-coupling-firewall.tests.ps1` | structural | Scans all production .ps1 outside `hosts/` for hardcoded host-enum patterns |

(iter-002 adds 12 more assertions in `host-registry.tests.ps1` + new `crew-bootstrap-contract.tests.ps1`.)

### Documentation

- `docs/architecture/host-package-architecture.md` — overview + Mermaid `flowchart TB` diagram
- `docs/design/host-package-architecture.md` — original design proposal (companion to commit `0aa3ff51`)
- `docs/design/proposal-108-slice-9-review.md` — Slice 9 implementation review
- `docs/how-to/add-a-new-host.md` — how-to guide for adding a new host
- `hosts/_contract.md` — declarative contract (rewritten in iter-002)

## Lines-of-code summary

- Code added in iter-001: ~3,200 lines (mostly across `hosts/`, `scripts/init/`, `hosts/_team-canonical.ps1`, `scripts/init/crew-bootstrap.ps1`, registry-driven shims)
- Code removed in iter-001: `scripts/specrew-init.ps1` shrunk from 2,428 → ~800 lines (net -1,628 in that file alone; functions relocated to `scripts/init/`)
- Net delta: ~+1,600 lines but with dramatically improved Open-Closed posture
