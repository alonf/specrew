# Implementation Plan: Cursor Host Package

**Feature**: `050-cursor-host-support`
**Date**: 2026-05-28
**Spec**: [spec.md](./spec.md)
**Proposal**: `proposals/114-cursor-host-package.md`
**Quality profile**: `quality-profile.custom-composition.v1` (Phase-1 bounded custom; lenses: security-baseline, robustness-baseline, test-integrity; required dimensions: code-quality, design-quality/SoC, verification-confidence, maintainability)
**Pre-allocated ModuleVersion**: `0.29.0` (Parallel-Work Charter Item 1 — do NOT change)

## Summary

Add a Cursor host package to Specrew's per-host architecture (shipped F-044), making `specrew start --host cursor "<feature>"` launch the `cursor-agent` standalone Agent CLI in **interactive** Agent mode with the Specrew coordinator prompt (matching claude/codex/antigravity). This is the **first post-F-044 host addition** — its purpose is partly to validate that the registry + 5-function-contract + canonical-source architecture scales to a new host with **no host-neutral core edits** (the one exception is the deliberately-hardcoded skill-root list in `deploy-squad-runtime.ps1`, FR-003).

All three previously-deferred questions were resolved empirically at the clarify boundary (see spec `## Clarifications`):

- **Binary** = `cursor-agent` (standalone Agent CLI; v2026.05.28 on PATH).
- **Skill/agent target** = `.cursor/rules/*.mdc` Cursor Project Rules; `HasUserSlashCommandSurface = $false`; coordinator prompt via `AGENTS.md`.
- **Launch** = INTERACTIVE `cursor-agent "<prompt>" --workspace <path>` (the headless `--print` mode confirms CLI-drivability → `Status = supported`, but is not the launch shape); `--allow-all`/`--autopilot` → `--force` (`--trust` is headless-only, unused). Reconciled to interactive 2026-05-29 (drift-log DRIFT-004).

## Architecture

Cursor follows the **codex host package** as its closest analog (`HasUserSlashCommandSurface = $false`, `InstructionsFile = AGENTS.md`). No new architecture is introduced — Cursor implements the existing contract.

```
hosts/cursor/
  host.psd1               # declarative manifest (F-044 schema)
  handlers.ps1            # 5 contract functions
  coordinator-rules.psd1  # coordinator-prompt surgery directives (may be Rules = @())
```

Auto-discovered by `hosts/_registry.ps1` directory scan — **no registry edit**. The interactive `specrew onboard` menu picks Cursor up automatically via `MenuPriority = 1.5`.

### Component diagram

```
specrew start --host cursor "<prompt>"
        │
        ▼
Get-SpecrewHostLaunchInvocation ──► New-CursorLaunchInvocation
        │                                    │ builds: cursor-agent "<prompt>" --workspace <proj>
        │                                    │ (+ --force under --allow-all/--autopilot)
        ▼                                    ▼
   cursor-agent (interactive Agent mode, reads AGENTS.md + .cursor/rules/*.mdc)
        ▲
        │ deployed by
  Install-CursorCrewRuntime  ◄── .specrew/team/agents/*.md (canonical source)
        │ writes .cursor/rules/<role>.mdc
  deploy-squad-runtime.ps1 (Get-ActiveSkillRoots + cursor → .cursor/rules)
```

## The 5-function contract (`hosts/cursor/handlers.ps1`)

Canonical naming verified against `hosts/_contract.md`. PascalKind = `Cursor`.

| Slot | Function | Behavior | Returns |
|---|---|---|---|
| NewLaunchInvocation | `New-CursorLaunchInvocation` | Build the INTERACTIVE `cursor-agent` invocation. Base args: `"<Prompt>" --workspace <ProjectPath>`. Under `-AllowAll`/`-UseAutopilot`: append `--force` (`--trust` is headless-only, not used). | `[pscustomobject]@{Binary='cursor-agent'; Args=@(...); Notices[]; HostKind}` |
| ConvertFlag | `ConvertTo-CursorFlag` | `[ValidateSet('--remote','--allow-all','--autopilot')]` (codex/antigravity parity): `--allow-all`→`--force`; `--autopilot`→no-op (folds into --force); `--remote`→warn-and-drop. | `[pscustomobject]@{Args=@(); Notice; SuppressWarning}` |
| TestRuntimeInstalled | `Test-CursorRuntimeInstalled` | `Get-Command cursor-agent` probe (+ optional `BinaryAliases`). | `[bool]` |
| GetSignals | `Get-CursorSignals` | Return env-var names that indicate running INSIDE Cursor (e.g., `CURSOR_AGENT`, `CURSOR_TRACE_ID` — verify which Cursor sets; ship the confirmed set, document any uncertainty). | `string[]` |
| InstallCrewRuntime | `Install-CursorCrewRuntime` | For each canonical role in `.specrew/team/agents/*.md`, write `.cursor/rules/<role>.mdc` (MDC front-matter + charter body). Honor `-DryRun`. Use `_team-canonical.ps1` helpers + `$manifest.AgentDir`. | `[pscustomobject]@{Actions=@(); CrewRuntimePath; Notices=@()}` |

### Manifest (`hosts/cursor/host.psd1`)

```powershell
@{
    Kind          = 'cursor'
    DisplayName   = 'Cursor (AI Code Editor)'
    Status        = 'supported'
    SchemaVersion = 1
    MenuPriority  = 1.5

    Binary           = 'cursor-agent'
    InstallUrl       = 'https://cursor.com/cli'
    InstallGuidance  = 'Cursor Agent CLI (cursor-agent) not found on PATH. Install from https://cursor.com/cli ...'

    SkillRoot                  = '.cursor/rules'
    HasUserSlashCommandSurface = $false
    AgentDir                   = '.cursor/rules/'   # crew agents land alongside rules as .mdc
    InstructionsFile           = 'AGENTS.md'

    SpeckitAiFlag  = $null     # spec-kit `specify init` does not (yet) support a 'cursor' --ai flag; verify at implement, set $null if unsupported
    PreferredAgent = 'cursor'

    HandlersFile         = 'handlers.ps1'
    CoordinatorRulesFile = 'coordinator-rules.psd1'
}
```

> **Design note (AgentDir vs SkillRoot):** both crew-agent translations and skill rules target `.cursor/rules/`. The plan keeps them in the single `.cursor/rules/` directory (Cursor's only auto-attach surface). If the reviewer wants role rules namespaced (e.g., `.cursor/rules/crew-<role>.mdc`) to avoid collision with skill rules, that is an Install-CursorCrewRuntime naming choice, not a manifest change.

## FR → component → test mapping

| FR | Component | Verifying test |
|---|---|---|
| FR-001 | `host.psd1` manifest (all required + relevant optional fields) | `tests/hosts/cursor.tests.ps1` manifest-load + `Test-HostManifestValid` |
| FR-002 | `handlers.ps1` 5 functions | `tests/hosts/cursor.tests.ps1` per-function (mock + real-binary) |
| FR-003 | `Get-ActiveSkillRoots` cursor entry → `.cursor/rules` | `tests/hosts/cursor.tests.ps1` deploy-target assertion |
| FR-004 | registry auto-discovery (no code) | `tests/hosts/cursor.tests.ps1` `Get-RegisteredHostKinds` includes `cursor` |
| FR-005 | unit tests | the test file itself (SC-004: 5/5 functions covered) |
| FR-006 | `tests/integration/host-cursor-launch.tests.ps1` | skipped-without-binary integration smoke |
| FR-007 | `tests/integration/multi-host-detection.tests.ps1` cursor row | updated matrix passes |
| FR-008 | `docs/getting-started.md` + `docs/user-guide.md` Cursor quickstart | doc presence + SC-007 manual walkthrough |
| FR-009 | `Binary='cursor-agent'` in manifest + invocation | manifest + `New-CursorLaunchInvocation` test |
| FR-010 | `SkillRoot=.cursor/rules`, `HasUserSlashCommandSurface=$false`, `InstructionsFile=AGENTS.md` | manifest-field assertions |
| FR-011 | `Status=supported` (CLI-drivable via `--print` capability) + interactive `"<prompt>" --workspace` launch | `New-CursorLaunchInvocation` interactive-args test |

Also: `Specrew.psd1` `FileList` MUST gain the 3 new `hosts/cursor/*` paths (contract validator rule + the Mac-install FileList-omission lesson). The structural firewall test (`host-coupling-firewall.tests.ps1`) must still pass (no host-enum hardcoding outside `hosts/`).

## UX divergence: Cursor has no slash-command surface (carry-forward from clarify)

Unlike Claude/Copilot (which expose Speckit skills as user-typed `/speckit.*` slash commands), **Cursor users do NOT invoke lifecycle commands by typing slashes**. `HasUserSlashCommandSurface = $false` (same as Codex). In Cursor:

- The **coordinator prompt** (lifecycle driver) is delivered via `AGENTS.md`, which `cursor-agent` auto-reads. This carries the spec→plan→implement→review→retro ceremony.
- Speckit skills + crew charters deploy as **`.cursor/rules/*.mdc`** — auto-attached context the agent consults, NOT a command palette.
- US2's "type `/speckit.` and see autocomplete" acceptance scenario does NOT hold for Cursor; it is **reframed**: success = the skill content is present as rules-context and the coordinator drives the lifecycle through `AGENTS.md`. US2 acceptance scenarios are rewritten in tasks.md to assert rule-file deployment + content presence, not slash-command autocomplete.
- US3 (crew agents) similarly = `.cursor/rules/<role>.mdc` presence + content fidelity, not a Cursor "agent picker".

This is documented in `docs/user-guide.md` so Cursor users understand the interaction model is prompt-driven, not palette-driven.

## Spec→plan drift surfaced (reconciled into spec at clarify)

- Spec FR-002 originally named `Convert-CursorFlag` + a single `host.ps1`; corrected to `ConvertTo-CursorFlag` + `handlers.ps1`/3-file package per `hosts/_contract.md`. **(spec already updated)**
- Spec FR-003 originally said `.cursor/skills` / 5-target list; corrected to `.cursor/rules` added to the real 3-entry hardcoded `Get-ActiveSkillRoots`. **(spec already updated)**
- Proposal 114 guessed `AgentDir=.cursor/agents/` + `InstructionsFile=CURSOR.md`; clarify resolved to `.cursor/rules/` + `AGENTS.md`. Plan uses resolved values; `CURSOR.md`/`.cursor/agents/` are NOT used.

## Iteration decomposition

Spec governance specifies 3 iterations. Recommended (single feature umbrella):

- **Iteration 001 — core package + skill target (~4-6 SP)**: `host.psd1`, `handlers.ps1` (5 functions), `coordinator-rules.psd1`, `Get-ActiveSkillRoots` cursor entry, `Specrew.psd1` FileList, registry auto-discovery verification. Closes FR-001/002/003/004/009/010/011.
- **Iteration 002 — test coverage (~2-3 SP)**: `tests/hosts/cursor.tests.ps1`, `tests/integration/host-cursor-launch.tests.ps1`, update `tests/integration/multi-host-detection.tests.ps1`. Closes FR-005/006/007 + SC-004/005.
- **Iteration 003 — docs + manual smoke (~2-3 SP)**: Cursor quickstart + caveats in `docs/getting-started.md` + `docs/user-guide.md`; real end-to-end `specrew start --host cursor` smoke on this machine. Closes FR-008 + SC-001/007.

> Unit tests for the 5 functions are authored **with** the functions in Iteration 001 (TDD-leaning) even though FR-005 is iteration-2-tagged; Iteration 002 then hardens + adds the integration/multi-host matrix tests. This keeps verification-confidence (quality dimension) honest rather than deferring all tests.

## Quality planning (from resolved profile)

| Dimension | Plan response |
|---|---|
| code-quality | Match codex handlers idiom; no dead manifest fields; PowerShell `Set-StrictMode`-clean. |
| design-quality / SoC | Cursor logic stays inside `hosts/cursor/`; only the deliberate `Get-ActiveSkillRoots` edit touches a shared script (contract-sanctioned). No host-enum leakage (firewall test). |
| verification-confidence | Every contract function gets a unit test with both mock and real-`cursor-agent` fixtures; integration smoke is skip-guarded without binary; assertions check args/return shape, not just "ran". |
| maintainability | Follows the established 3-file package shape so future host additions stay mechanical. |
| security-baseline lens | `--force`/`--yolo` are auto-approve flags — gate them strictly behind explicit `--allow-all`/`--autopilot`; never default-on (`--trust` is headless-only, unused). `--api-key`/`CURSOR_API_KEY` are user-managed; Specrew MUST NOT read, log, or persist them. Document in `New-CursorLaunchInvocation`. |
| robustness-baseline lens | Graceful `binary-missing` guidance; version probe tolerant of `cursor-agent --version` output shape. |

## Parallel-Work Charter constraints (Proposal 114) — active

1. ModuleVersion pinned to `0.29.0`; do not change.
2. Do NOT edit `.specify/extensions/specrew-speckit/**` (deployed framework copy). The legitimate source edit (`extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1`, FR-003) IS in scope — it is product source, not the dogfood-deployed governance copy. (Plan flags this distinction explicitly so the boundary isn't crossed by accident.)
3. No `specrew update` in this worktree.
4. Append-only on `proposals/INDEX.md`, `CHANGELOG.md`, `dashboard.md`.
5. F-049 PR merges to main BEFORE F-050's PR.
6. Beta-before-stable: ship `v0.29.0-beta.N` first.
7. No `.specrew/`/`.squad/` state committed to this branch.
8. Cross-reviewer (different model session) at review-signoff.

## Open implement-time verifications (low-risk, not blockers)

- Exact env-var names Cursor sets inside its agent (for `Get-CursorSignals`) — ship the confirmed set; document uncertainty rather than guess.
- Whether spec-kit `specify init` accepts an `--ai cursor` flag (`SpeckitAiFlag`); default `$null` if unsupported (matches several hosts).
- MDC front-matter shape Cursor expects for rules (`description`, `globs`, `alwaysApply`); verify against `cursor-agent generate-rule` output at implement.
