# Data Model: Cursor Host Package

**Feature**: `050-cursor-host-support`
**Date**: 2026-05-28
**Purpose**: Define the entities, attributes, and validation rules for the Cursor host package. This feature adds no persisted application state and no database; its "data" is a declarative manifest + the on-disk rule files it produces.

## No persisted runtime data

The host package is configuration + pure functions. The only state on disk is (a) the static manifest committed to the repo and (b) `.cursor/rules/*.mdc` files generated into the user's project during `specrew start`/`init`. There is no mutable shared state, no concurrency, no secrets persisted by Specrew.

## Entity: Cursor Host Manifest (`hosts/cursor/host.psd1`)

**Purpose**: Declarative description of the Cursor host consumed by `hosts/_registry.ps1` via `Import-PowerShellDataFile`.

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| `Kind` | string (lowercase) | Yes | MUST equal folder name `cursor` | Canonical enum value |
| `DisplayName` | string | Yes | non-empty | `Cursor (AI Code Editor)` |
| `Status` | enum | Yes | `supported` (resolved; not `preview`/`deferred`) | Drives validator + UX |
| `SchemaVersion` | int | Yes | `1` | Manifest schema version |
| `MenuPriority` | number | Yes (for menu) | `1.5` (between Claude=1, Codex=2) | Onboard menu ordering |
| `Binary` | string | Yes | `cursor-agent` | Command name probed on PATH |
| `InstallUrl` | string (URL) | Yes | valid URL | Cursor CLI install page |
| `SkillRoot` | string (rel path) | Yes | `.cursor/rules` | Where skill catalog + crew rules deploy |
| `HasUserSlashCommandSurface` | bool | Yes | `$false` | Cursor has no slash-command palette |
| `AgentDir` | string (rel path) | Yes (Status=supported) | `.cursor/rules/` | Crew-runtime deploy dir |
| `InstructionsFile` | string | Optional | `AGENTS.md` | Coordinator-prompt surface |
| `SpeckitAiFlag` | string\|null | Optional | `$null` unless `specify init --ai cursor` verified | spec-kit coupling |
| `PreferredAgent` | string | Optional | `cursor` | Default `preferred_agent` |
| `InstallGuidance` | string | Optional | non-empty when present | Shown when binary missing |
| `HandlersFile` | string | Optional | `handlers.ps1` | 5-function file |
| `CoordinatorRulesFile` | string | Optional | `coordinator-rules.psd1` | Surgery directives |

### Lifecycle / Relationships

Authored once, committed to the repo, never mutated at runtime. Loaded + cached + validated by `Get-HostManifest -Kind cursor`. Referenced by `Specrew.psd1` `FileList`. Validated by `Test-HostManifestValid` (all 8 required fields present; `Kind` matches folder; `Status=supported` ⇒ `AgentDir` set).

## Entity: Cursor Rule File (`.cursor/rules/<name>.mdc`) — generated output

**Purpose**: Auto-attached context Cursor's agent reads. Specrew emits two kinds: skill-catalog rules and crew-role rules.

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| front-matter `description` | string | Yes | non-empty | MDC rule summary Cursor indexes |
| front-matter `globs` / `alwaysApply` | string/bool | Optional | valid MDC | When the rule auto-attaches |
| body | markdown | Yes | non-empty | Skill content or crew charter |
| filename | string | Yes | unique within `.cursor/rules/` | Derived from skill/role name |

### Lifecycle / Relationships

Created/updated idempotently by `Install-CursorCrewRuntime` (crew roles) and `deploy-squad-runtime.ps1` `Get-ActiveSkillRoots` (skill catalog). Source of truth for crew rules is `.specrew/team/agents/<role>.md` (canonical). Re-sync overwrites without duplication. Destroyed only by the user deleting `.cursor/rules/`.

## Entity: Launch Invocation (transient, in-memory)

**Purpose**: The object `New-CursorLaunchInvocation` returns; consumed immediately to spawn `cursor-agent`.

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| `Binary` | string | Yes | `cursor-agent` | Executable |
| `Args` | string[] | Yes | includes `--print --workspace <path> "<prompt>"`; `--force --trust` only under allow-all/autonomous | CLI args |
| `Notice` | string\|null | Optional | — | User-facing note (e.g., flag fallback) |

### Lifecycle / Relationships

Built per `specrew start` call, returned to `Get-SpecrewHostLaunchInvocation`, never persisted. The `--force`/`--trust` auto-approve flags MUST be present ONLY when the user explicitly passed `--allow-all`/`--autonomous` (security-baseline lens).
