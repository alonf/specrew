# Review Diagrams: Cursor Host Package

**Feature**: `050-cursor-host-support`
**Phase**: pre-implementation (planning artifact for reviewer)

## Component diagram

```mermaid
flowchart LR
  CLI[specrew start --host cursor] --> Launch[Get-SpecrewHostLaunchInvocation]
  Launch --> Reg[hosts/_registry.ps1\nauto-discovery]
  Reg --> Manifest[hosts/cursor/host.psd1]
  Reg --> Handlers[hosts/cursor/handlers.ps1\n5 functions]
  Handlers --> NewInv[New-CursorLaunchInvocation]
  NewInv --> Agent[cursor-agent prompt --workspace]
  Canon[.specrew/team/agents/*.md\ncanonical source] --> Install[Install-CursorCrewRuntime]
  Install --> Rules[.cursor/rules/*.mdc]
  Deploy[deploy-squad-runtime.ps1\nGet-ActiveSkillRoots +cursor] --> Rules
  Coord[AGENTS.md\ncoordinator prompt] --> Agent
  Rules --> Agent
```

## Sequence: launch a feature in Cursor (US1 canonical flow)

```mermaid
sequenceDiagram
  participant User
  participant Specrew as specrew start
  participant Registry as hosts/_registry.ps1
  participant Handlers as cursor/handlers.ps1
  participant Cursor as cursor-agent

  User->>Specrew: specrew start --host cursor "Add OAuth login"
  Specrew->>Registry: Get-HostManifest -Kind cursor
  Registry-->>Specrew: manifest (Binary=cursor-agent, Status=supported)
  Specrew->>Specrew: Test-SpecrewHostAvailable (host-neutral PATH probe for cursor-agent)
  Specrew-->>Specrew: $true (binary on PATH)
  Specrew->>Handlers: Install-CursorCrewRuntime (sync .cursor/rules/*.mdc)
  Handlers-->>Specrew: Actions[], CrewRuntimePath=.cursor/rules
  Specrew->>Handlers: New-CursorLaunchInvocation -Prompt "..." [-AllowAll]
  Handlers-->>Specrew: {Binary=cursor-agent; Args=["...",--workspace,<proj>]}
  Specrew->>Cursor: spawn cursor-agent "..." --workspace <proj> (interactive)
  Cursor-->>User: Agent reads AGENTS.md + .cursor/rules, begins specify phase
```

## Sequence: binary missing (US1 scenario 2/3 — graceful guidance)

> Note: binary-on-PATH availability is the host-neutral `Test-SpecrewHostAvailable` probe (+ `Get-SpecrewHostInstallGuidance` from the manifest). `Test-CursorRuntimeInstalled` is a *separate* check that detects the deployed `.cursor/rules/*.mdc` crew runtime, NOT PATH presence.

```mermaid
sequenceDiagram
  participant User
  participant Specrew as specrew start

  User->>Specrew: specrew start --host cursor "x"
  Specrew->>Specrew: Test-SpecrewHostAvailable (cursor-agent on PATH?)
  Specrew-->>Specrew: $false (cursor-agent not on PATH)
  Specrew-->>User: Get-SpecrewHostInstallGuidance: install cursor-agent from https://cursor.com/cli (no stack trace)
```
