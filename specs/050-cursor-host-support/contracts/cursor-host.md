# Contract: Cursor Host Package Public Surface

**Feature**: `050-cursor-host-support`
**Stability**: pre-1.0 (follows the stable F-044 host-package contract; `hosts/_contract.md` is the umbrella contract)

## hosts/cursor/handlers.ps1

Implements the 5-function host contract. The host-neutral core dispatches to these via `Invoke-HostHandler -Kind cursor`. PascalKind = `Cursor`.

### Exported API

| Symbol | Signature | Purpose | Errors |
| --- | --- | --- | --- |
| `New-CursorLaunchInvocation` | `-ProjectPath <p> -Prompt <s> -Agent <s> [-AllowAll <bool>] [-UseAutopilot <bool>] [-UseRemote <bool>]` → `[pscustomobject]@{Binary;Args[];Notice}` | Build the `cursor-agent` non-interactive invocation | Returns object even when binary absent (detection is `Test-*`'s job); never throws on flag combos |
| `ConvertTo-CursorFlag` | `-SpecrewFlag <flag>` → `[pscustomobject]@{Args[];Notice;SuppressWarning}` | Map a universal Specrew flag to Cursor-CLI args | Unknown flag → empty `Args` + `Notice` + `SuppressWarning=$true` (no throw) |
| `Test-CursorRuntimeInstalled` | `-ProjectPath <p>` → `[bool]` | True iff `cursor-agent` (or alias) resolvable on PATH | Never throws; `$false` on any probe failure |
| `Get-CursorSignals` | (no params) → `string[]` | Env-var names that are set when running INSIDE Cursor | Never throws; `@()` if none confirmed |
| `Install-CursorCrewRuntime` | `-ProjectPath <p> [-DryRun]` → `[pscustomobject]@{Actions[];CrewRuntimePath;Notices[]}` | Translate canonical `.specrew/team/agents/*.md` → `.cursor/rules/<role>.mdc` | `-DryRun` performs no writes; idempotent re-runs do not duplicate |

### Flag translation table (`ConvertTo-CursorFlag`)

| Specrew flag | Cursor-agent args | Notes |
| --- | --- | --- |
| `--allow-all` | `--force --trust` | auto-approve + headless workspace trust; ONLY when user opted in |
| `--autonomous` | `--force` | run-everything without per-step prompts |
| `--readonly` | `--mode plan` | Cursor's read-only/planning mode |
| (unknown) | `@()` | `Notice` + `SuppressWarning=$true` |

### Launch invocation shape (`New-CursorLaunchInvocation`)

```
Binary: cursor-agent
Args:   --print --workspace <ProjectPath> "<Prompt>"
        (+ --force --trust   IFF -AllowAll or -UseAutopilot)
```

## hosts/cursor/host.psd1

Declarative manifest (see [data-model.md](../data-model.md)). Consumed by `Get-HostManifest -Kind cursor`.

## hosts/cursor/coordinator-rules.psd1

Declarative coordinator-prompt surgery directives. May be `@{ Rules = @() }` if no Cursor-specific surgery is needed beyond the shared coordinator prompt delivered via `AGENTS.md`.

## On-disk format produced

`.cursor/rules/<name>.mdc` — Cursor MDC rule files (YAML front-matter + markdown body). One per deployed skill + one per crew role.

## Skill-deploy integration (`extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1`)

`Get-ActiveSkillRoots -ProjectPath <p>` gains one entry:
```
[pscustomobject]@{ Name = 'cursor'; Path = Join-Path $ProjectPath '.cursor\rules' }
```
(4-entry list: claude, cursor, github, agents.)

## Invariants

- Adding the Cursor host requires **no edit to `hosts/_registry.ps1`** or any host-neutral core script EXCEPT the one sanctioned `Get-ActiveSkillRoots` entry (FR-003).
- `Status='supported'` ⇒ `AgentDir` is set (validator rule).
- `Specrew.psd1` `FileList` lists all three `hosts/cursor/*` files (validator rule + Mac-install lesson).
- No production `.ps1` outside `hosts/` hardcodes a `cursor`-specific enum tuple (structural firewall test).
- `--force`/`--trust`/`--yolo` auto-approve flags appear ONLY under explicit `--allow-all`/`--autonomous`; never default-on (security-baseline).
- Specrew never reads, logs, or persists `CURSOR_API_KEY` / `--api-key`.
