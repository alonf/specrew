# Host Package Contract

> **Status**: Phases A-D + Slice 9 shipped. Stable. To add a new host see [docs/how-to/add-a-new-host.md](../docs/how-to/add-a-new-host.md).

Each `hosts/<kind>/` directory defines a host package. To register a new host, create the directory and three files (manifest, handlers, coordinator-rules). The host-neutral core auto-discovers all packages via `hosts/_registry.ps1`. No existing core-script edits.

## Files per host package

| File | Purpose | Required? |
|---|---|---|
| `host.psd1` | Declarative manifest (this contract) | **Yes** |
| `handlers.ps1` | 5 contract-function implementations (Phase B + Slice 9) | **Yes** for `Status: supported` |
| `coordinator-rules.psd1` | Declarative coordinator-prompt surgery directives | **Yes** (may declare `Rules = @()` if no host-specific surgery) |
| `docs/install.md` | Per-host install guidance prose | Optional |
| `docs/deferred.md` | Required when `Status = 'deferred'`; explains why + follow-up pointer | Only if `Status = 'deferred'` |

Every file beneath a registered host package is generated into the module
`FileList` after the three required contract files validate. This lets
package-private adapters and host documentation ship with a folder-only
addition; hand-authored per-host `FileList` rows are not the source of truth.

## Manifest schema (`host.psd1`)

Top-level: a PowerShell hashtable consumed via `Import-PowerShellDataFile`.

### Required fields

| Field | Type | Example | Notes |
|---|---|---|---|
| `Kind` | string (lowercase) | `'copilot'` | Canonical enum value; matches the folder name |
| `DisplayName` | string | `'GitHub Copilot CLI'` | User-facing |
| `Status` | enum: `supported` \| `deferred` \| `experimental` | `'supported'` | Drives validator + UX |
| `SchemaVersion` | int | `1` | Manifest schema version (bump on breaking changes) |
| `Binary` | string | `'copilot'` | Command name on PATH used for detection |
| `InstallUrl` | string (URL) | `'https://docs.github.com/en/copilot/how-tos/copilot-cli'` | Surfaced in install guidance |
| `SkillRoot` | string (relative path) | `'.github/skills'` | Where this host expects skill catalog |
| `HasUserSlashCommandSurface` | bool | `$true` | False for Codex (per F-040 FR-013) |

### Optional fields

| Field | Type | Default | Notes |
|---|---|---|---|
| `BinaryAliases` | string[] | `@()` | Alternate command names; e.g., Antigravity uses `agy` |
| `LegacySkillRoots` | string[] | `@()` | Old paths to migrate from (e.g., `.copilot/skills`) |
| `SharedSkillRootWith` | string[] | `@()` | Other hosts sharing this SkillRoot (e.g., Antigravity shares `.agents/skills` with Codex) |
| `SettingsPath` | string | `$null` | Per-host settings file (e.g., `.claude/settings.json`) |
| `AgentDir` | string | `$null` | Per-host agent directory (`.claude/agents/`, `.squad/agents/`, `.codex/agents/`, `.agents/agents/`). **Required** for `Status: 'supported'` — consumed by `Install-<Kind>CrewRuntime` + `Get-SpecrewHostRuntimeInventory` |
| `InstructionsFile` | string | `$null` | Per-host top-level instructions file (e.g., `.github/copilot-instructions.md`, `CLAUDE.md`) |
| `SpeckitAiFlag` | string | `$null` | What `--ai <flag>` value to pass to `specify init`; `$null` if spec-kit doesn't support this host |
| `PreferredAgent` | string | `$null` | Default value for `preferred_agent` in `role-assignments.yml`; usually same as `Kind` |
| `InstallGuidance` | string | `$null` | One-line text shown when the host CLI is missing on PATH (e.g., `'Install: https://...'`). Surfaced by `Get-SpecrewHostInstallGuidance` |
| `DeferredReason` | string | `$null` | REQUIRED if `Status = 'deferred'`. Short explanation + follow-up pointer |
| `DeferredGuidance` | string | `$null` | REQUIRED if `Status = 'deferred'`. User-facing guidance when they try to use the host |
| `HandlersFile` | string | `'handlers.ps1'` | Path to file containing the 5 contract functions |
| `CoordinatorRulesFile` | string | `'coordinator-rules.psd1'` | Path to declarative surgery rules file |
| `RefocusHookBindings` | hashtable | `$null` | Required for hook-capable hosts. Owns hook config path, opt-out marker, config shape, command mode, registrations, and any owned-file/version metadata. Core hook deploy/status code must consume this instead of branching on concrete host names. |

### RefocusHookBindings fields

| Field | Type | Required | Notes |
|---|---|---|---|
| `SettingsFile` | string | yes | Hook config file. `~/` paths resolve under user home; other paths resolve under the project. |
| `OptOutMarkerFile` | string | yes | Project/runtime marker used by remove and status to record an explicit hook opt-out. |
| `DispatcherPath` | string | yes | Project-relative dispatcher path used by command renderers and launcher resolution. |
| `ConfigShape` | enum: `event-map` \| `named-definition` | yes | JSON layout written by deploy. |
| `CommandMode` | enum: `project-placeholder` \| `launcher-file` \| `launcher-encoded` | yes | How hook commands name the dispatcher or launcher. |
| `Registrations` | hashtable[] | yes | Ordered event rows. Each row declares `Event`, `DispatcherEvent`, `HandlerShape`, and optional timeout/matcher fields. |
| `SettingsVersion` | int | no | Version added to config files that require it. |
| `OwnsSettingsFile` | bool | no | True when Specrew owns the entire hook config file and may delete it on remove. |
| `MigrateLegacyTopLevelEventMap` | bool | no | True when deploy should strip legacy top-level Specrew event entries before writing `hooks.<Event>`. |
| `ProjectDirPlaceholder` | string | for `project-placeholder` | Host-provided project-root placeholder included in the command string. |
| `ProjectRootEnvironmentVariables` | string[] | no | Host-exposed environment variables that directly identify the live project root. The generated launcher bakes the union from manifests into its project-resolution candidate list. |
| `DefinitionName` | string | for `named-definition` | Managed top-level definition name. |
| `DefinitionNameWhenOccupied` | string | no | Alternate managed name when `DefinitionName` is already occupied by a non-Specrew definition. |

## Contract functions (handlers.ps1)

`handlers.ps1` MUST export these 5 functions. Naming convention uses the `Kind` field in PascalCase (e.g., `copilot` → `Copilot`, `antigravity` → `Antigravity`):

| Function name (template) | Signature | Returns | Used by |
|---|---|---|---|
| `New-<PascalKind>LaunchInvocation` | `-ProjectPath <p> -Prompt <s> -Agent <s> [-AllowAll <bool>] [-UseAutopilot <bool>] [-UseRemote <bool>]` | `[pscustomobject]@{Binary; Args[]; Notice}` | `Get-SpecrewHostLaunchInvocation` in `specrew-start.ps1` |
| `ConvertTo-<PascalKind>Flag` | `-SpecrewFlag <flag>` | `[pscustomobject]@{Args[]; Notice; SuppressWarning}` | `Get-HostFlagTranslation` in `scripts/internal/host-flag-translation.ps1` |
| `Test-<PascalKind>RuntimeInstalled` | `-ProjectPath <p>` | `[bool]` | `Get-SpecrewHostRuntimeInventory` in `scripts/internal/host-runtime-inventory.ps1` |
| `Get-<PascalKind>Signals` | (no params; reads env vars) | `string[]` (env-var names that are set when running INSIDE this host) | `Get-CurrentHostContext` / `agent-detection.ps1` |
| `Install-<PascalKind>CrewRuntime` | `-ProjectPath <p> [-DryRun]` | `[pscustomobject]@{Actions[]; CrewRuntimePath; Notices[]}` | `Invoke-CrewBootstrap` in `scripts/init/crew-bootstrap.ps1`; called by `specrew start` to translate `.specrew/team/agents/*.md` → host-native subagent format |

### Registry public API

The registry (`_registry.ps1`) exposes:

- `Get-RegisteredHostKinds` — enumerates `hosts/*/host.psd1`
- `Get-HostManifest -Kind <kind>` — loads + caches + validates manifest
- `Get-SpecrewHostsByStatus -Status supported|deferred|experimental` — filtered list
- `Resolve-HostHandler -Kind <kind> -ContractFunction <name>` — returns the per-host function name
- `Invoke-HostHandler -Kind <kind> -ContractFunction <name> -Arguments <hashtable>` — convenience dispatcher

The `$script:HostContractFunctionMap` maps contract slot → function template:

```powershell
$script:HostContractFunctionMap = @{
    'NewLaunchInvocation'  = 'New-{0}LaunchInvocation'
    'ConvertFlag'          = 'ConvertTo-{0}Flag'
    'TestRuntimeInstalled' = 'Test-{0}RuntimeInstalled'
    'GetSignals'           = 'Get-{0}Signals'
    'InstallCrewRuntime'   = 'Install-{0}CrewRuntime'
}
```

To add a new contract slot (e.g., `Get-<Kind>CostCatalogUrl` for F-041), add one entry here AND export the function from each handlers.ps1. The dispatcher itself stays unchanged.

### Canonical-team helpers (`_team-canonical.ps1`)

`_registry.ps1` dot-sources `_team-canonical.ps1`, which exposes the canonical source-of-truth for Crew identity. `Install-<Kind>CrewRuntime` reads from these helpers:

- `Get-SpecrewTeamAgentsPath -ProjectPath <p>` — returns `<p>/.specrew/team/agents`
- `Get-SpecrewCanonicalAgentRoles -ProjectPath <p>` — enumerates roles (baseline 5 + user-added)
- `Get-SpecrewCanonicalCharterContent -ProjectPath <p> -RoleName <r>` — reads the canonical charter, falls back to shipped baseline if missing
- `Get-SpecrewHostAgentRoot -HostKind <k> -ProjectPath <p>` — resolves the per-host agent directory from `$manifest.AgentDir`
- `Initialize-SpecrewTeamCanonical -ProjectPath <p>` — seeds `.specrew/team/agents/` from shipped baseline (idempotent)

## Validator rules (`Test-HostManifestValid`)

- Every `hosts/<kind>/host.psd1` is loadable via `Import-PowerShellDataFile`
- All 8 required fields are present + non-empty
- `Kind` matches the folder name (lowercase)
- `Status = 'deferred'` requires `DeferredReason` AND `DeferredGuidance` to be set
- `Status = 'supported'` requires `AgentDir` to be set (so the Crew runtime can deploy)
- Generated `Specrew.psd1` `FileList` membership includes every file beneath
  each valid host package. Generation fails when any required contract file is
  missing, the manifest `Kind` differs from the folder, or a package path
  escapes through a reparse point.
- The structural firewall test (`tests/integration/host-coupling-firewall.tests.ps1`) ensures no production `.ps1` outside `hosts/` hardcodes a host-enum tuple (allow-list documented in the test itself)
