# Host Package Contract

> **Status**: Phase A schema (manifests only). Phase B will add handlers.

Each `hosts/<kind>/` directory defines a host package. To register a new host, create the directory and the manifest below. The host-neutral core auto-discovers all packages via `hosts/_registry.ps1`. No existing file edits.

## Files per host package

| File | Purpose | Required in Phase A? |
|---|---|---|
| `host.psd1` | Declarative manifest (this contract) | **Yes** |
| `handlers.ps1` | Function implementations (next phase) | No (Phase B) |
| `coordinator-rules.md` | Declarative coordinator-prompt surgery directives | No (Phase C) |
| `docs/install.md` | Per-host install guidance prose | No (Phase E or later) |
| `docs/deferred.md` | Required when `Status = 'deferred'`; explains why + follow-up pointer | Only if deferred |

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
| `InstallUrl` | string (URL) | `'https://docs.github.com/en/copilot/how-tos/copilot-cli'` | Surface in install guidance |
| `SkillRoot` | string (relative path) | `'.github/skills'` | Where this host expects skill catalog |
| `HasUserSlashCommandSurface` | bool | `$true` | False for Codex (per F-040 FR-013) |

### Optional fields

| Field | Type | Default | Notes |
|---|---|---|---|
| `BinaryAliases` | string[] | `@()` | Alternate command names; e.g., Antigravity uses `agy` not `antigravity` |
| `LegacySkillRoots` | string[] | `@()` | Old paths to migrate from (e.g., `.copilot/skills`) |
| `SharedSkillRootWith` | string[] | `@()` | Other host kinds that share the same SkillRoot (e.g., Antigravity shares `.agents/skills` with Codex) |
| `SettingsPath` | string | `$null` | Per-host settings file path (e.g., `.claude/settings.json`); `$null` if N/A |
| `AgentDir` | string | `$null` | Per-host agent directory (e.g., `.claude/agents/`); `$null` if not applicable |
| `InstructionsFile` | string | `$null` | Per-host top-level instructions file (e.g., `.github/copilot-instructions.md` for Copilot, `CLAUDE.md` for Claude); `$null` if none |
| `SpeckitAiFlag` | string | `$null` | What `--ai <flag>` value to pass to `specify init`; `$null` if spec-kit doesn't support this host |
| `PreferredAgent` | string | `$null` | Default value for `preferred_agent` in `role-assignments.yml`; usually same as `Kind`. `$null` means "don't auto-prefer" |
| `DeferredReason` | string | `$null` | REQUIRED if `Status = 'deferred'`. Short explanation + follow-up pointer |
| `DeferredGuidance` | string | `$null` | REQUIRED if `Status = 'deferred'`. User-facing guidance when they try to use the host |
| `HandlersFile` | string | `'handlers.ps1'` | Phase B; file containing function implementations |
| `CoordinatorRulesFile` | string | `'coordinator-rules.md'` | Phase C; declarative surgery rules |

### Phase B contract functions

When `handlers.ps1` exists (Phase B and later), it MUST export these functions. Naming convention uses the `Kind` field in PascalCase:

| Function name (template) | Signature | Returns | Used by |
|---|---|---|---|
| `New-<PascalKind>LaunchInvocation` | `-ProjectPath <p> -Prompt <s> -Flags <hashtable>` | `[pscustomobject]@{Binary; Args[]; Notice}` | `Invoke-HostLaunch` in core |
| `ConvertTo-<PascalKind>Flag` | `-SpecrewFlag <flag>` | `[pscustomobject]@{Args[]; Notice; SuppressWarning}` | `Build-HostLaunchArgs` in core |
| `Test-<PascalKind>RuntimeInstalled` | `-ProjectPath <p>` | `[bool]` (+ optional details object) | `Get-HostRuntimeInventory` in core |
| `Get-<PascalKind>Signals` | (no params; reads env vars) | `[pscustomobject]@{IsActive; SessionId; Version}` | `Get-CurrentHostContext` in core |

The registry (`_registry.ps1`) exposes:

- `Get-RegisteredHostKinds` — enumerates `hosts/*/host.psd1`
- `Get-HostManifest -Kind <kind>` — loads + validates manifest
- `Resolve-HostHandler -Kind <kind> -ContractFunction <name>` — returns the per-host function name
- `Invoke-HostHandler -Kind <kind> -ContractFunction <name> -Args <hashtable>` — convenience dispatcher

## Validator rules (Phase A enforces)

- Every `hosts/<kind>/host.psd1` is loadable via `Import-PowerShellDataFile`
- All required fields are present + non-empty
- `Kind` matches the folder name (lowercase)
- `Status = 'deferred'` requires `DeferredReason` AND `DeferredGuidance` to be set
- `Specrew.psd1` `FileList` includes every `hosts/*/host.psd1`

## Adding a new host (Phase A only)

Today, in Phase A, "adding a host" creates the manifest + folder structure. No runtime behavior change — host-neutral core still calls the existing scripts. Phase B wires the manifests into runtime.

Example: to add Cursor today:

1. `mkdir hosts/cursor/`
2. Create `hosts/cursor/host.psd1` with `Status = 'deferred'`, `DeferredReason = 'Phase B not yet implemented for Cursor'`, `DeferredGuidance = 'Cursor support arrives when handlers.ps1 is added to hosts/cursor/'`
3. Add `hosts/cursor/host.psd1` to `Specrew.psd1` FileList
4. Done — registry discovers Cursor, validator passes, but `specrew start --host cursor` fails with the deferred guidance (until Phase B handlers ship)
