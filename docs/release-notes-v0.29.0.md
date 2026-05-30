# Specrew v0.29.0 — Cursor Host Package

**Released**: 2026-05-30

## TL;DR — The headline

**v0.29.0 is the first post-F-044 host addition**: Cursor is now a first-class Specrew host. Launch with `specrew start --host cursor "<task>"` and the standalone `cursor-agent` CLI opens an interactive Cursor Agent panel with the Specrew coordinator prompt, Crew identity translated to `.cursor/rules/*.mdc` Project Rules, and AGENTS.md serving as the coordinator instructions file. Same boundary discipline, same audit-trail durability, same cross-host artifact portability — fifth host on the matrix.

## Why this matters

The F-044 per-host architecture (shipped in v0.27.0) made adding a new host a mechanical exercise: implement the 5-function contract (`New-CursorLaunchInvocation`, `ConvertTo-CursorFlag`, `Test-CursorRuntimeInstalled`, `Get-CursorSignals`, `Install-CursorCrewRuntime`) + a manifest + coordinator-rules and the rest of Specrew's machinery picks it up. v0.29.0 proves that promise: Cursor went from candidate proposal to shipped host in three short iterations with no edits to Specrew's core dispatch logic. Five hosts now run the same governance layer.

For Cursor users specifically: you don't need to switch IDEs to get spec-driven discipline on your AI work. Specrew runs inside Cursor's Agent panel via `cursor-agent` (the standalone CLI distinct from the VS Code-style `cursor` editor launcher), reads your `.cursor/rules/*.mdc` deployments as auto-attached context, and follows AGENTS.md for coordinator instructions — all while preserving the same `.specrew/`, `.squad/`, `specs/` artifact layout that other hosts use.

## What's new

### F-050: Cursor Host Package (three iterations)

#### Iteration 001 — Cursor handlers + 5-function contract

`hosts/cursor/` package with manifest + handlers + coordinator-rules:

- **`New-CursorLaunchInvocation`**: builds interactive `cursor-agent "<prompt>" --workspace <path>` invocation. `--allow-all` maps to `--force` (run-everything) via `ConvertTo-CursorFlag`. `--print` (headless one-shot) and `--trust` (headless-only) are reserved and NOT used in the interactive Specrew launch — the launch contract is INTERACTIVE so the developer drives the lifecycle in a live session.
- **`ConvertTo-CursorFlag`**: per-host flag translation per Proposal 069 contract (`--allow-all` -> `--force`; `--autopilot` folds into `--force` with no extra args; `--remote` has no Cursor equivalent and surfaces a warn-and-drop notice).
- **`Test-CursorRuntimeInstalled`**: detects `.cursor/rules/*.mdc` presence.
- **`Get-CursorSignals`**: returns set Cursor env-var names (e.g., `CURSOR_TRACE_ID`) for detection.
- **`Install-CursorCrewRuntime`**: translates `.specrew/team/agents/<role>.md` canonical Crew identity to `.cursor/rules/<role>.mdc` Project Rules with proper MDC front-matter (`description:`, `alwaysApply:`, Specrew-managed marker); idempotent re-runs do not duplicate; `-DryRun` flag for read-only preview.

Deployment shape:

- **CLI binary**: `cursor-agent` (the standalone Agent CLI; NOT the `cursor` editor launcher)
- **Skill catalog**: `.cursor/rules/*.mdc` (Cursor's auto-attached context mechanism; NOT invocable slash commands — Cursor has no user-typeable slash-command surface comparable to Claude/Copilot)
- **Coordinator instructions**: `AGENTS.md` at the project root (Cursor honors the AGENTS.md convention)
- **HasUserSlashCommandSurface**: `$false` (matches the established Codex pattern from F-044)
- **MenuPriority**: 1.5 (places Cursor second in the interactive selection menu, after Claude)

#### Iteration 002 — Test coverage (FR-005..FR-007)

- **`tests/integration/host-cursor.tests.ps1`**: real-`cursor-agent` version-probe fixture (skip-guarded when binary absent on CI); verifies all 5 contract functions including idempotent install, MDC front-matter content, and detection helpers
- **`tests/integration/host-cursor-launch.tests.ps1`** (NEW): dedicated launch-path integration smoke; extracts `Get-SpecrewHostLaunchInvocation` from `specrew-start.ps1` and exercises the FULL dispatch (`--host cursor` -> handler -> launch invocation). Verifies interactive argv shape, `--allow-all` -> `--force` mapping, real-binary skip-guard.
- **`tests/integration/host-detection-ux.tests.ps1`**: cursor added to the supported-hosts detection matrix; cursor launch-shape verified via `Invoke-HostHandler -Kind cursor` (second code path independent from `Get-SpecrewHostLaunchInvocation` — belt-and-suspenders coverage).

#### Iteration 003 — Documentation + human-verified live smoke (FR-008)

- **`docs/getting-started.md`**: Cursor host-table row, Cursor Quickstart callout, install notes (`cursor-agent` + `.cursor/rules`-not-slash-palette caveat), `--allow-all` -> `--force` flag-mapping documentation
- **`docs/user-guide.md`**: dedicated Cursor interaction-model section, five-host counts, Cursor column in flag/capability/charter tables, FR-014 rewrite note
- **Human-verified end-to-end live smoke** (Alon Fliess, 2026-05-30): `specrew start --host cursor` launches `cursor-agent` interactively, reads AGENTS.md, begins specify boundary. SC-001 (launch) + SC-005 (UX guarantee) satisfied with real-binary evidence — strongest evidence form in the feature.

### Pre-publish Docker harness Phase 2 bidirectional check (PR #1225)

A directional-blind-spot lesson from v0.28.0-beta.1: the F-049 Phase 2 FileList integrity check verified "declared files exist on disk" (catches deletions) but did NOT verify "every referenced source file is declared in FileList" (missed omissions). v0.28.0-beta.1 shipped without `scripts/internal/user-profile.ps1` declared in FileList, breaking `specrew start` on fresh installs. PR #1225 adds the inverse check: walk source-tree, diff against FileList declarations, fail on any deployable source file not declared. The exact omission class is now structurally prevented in both directions.

## For external users — what you can now do

1. **Try Specrew on Cursor**: install [Cursor](https://cursor.com/) (which includes both the editor and the standalone `cursor-agent` CLI), then `specrew start --host cursor "<your task>"` launches the Cursor Agent panel with the Specrew coordinator prompt + your Crew identity deployed as `.cursor/rules/*.mdc` Project Rules.
2. **Switch hosts mid-feature including Cursor**: the F-040 multi-host launch path + F-044 per-host architecture mean Cursor participates fully in the cross-host switching workflow. Start a feature on Copilot Monday, continue on Cursor Tuesday, finish on Claude Wednesday — boundary state + decisions ledger + audit trail follow you across hosts via on-disk artifacts.
3. **Auto-attached context, not slash commands**: Cursor's Specrew skill deployment lives in `.cursor/rules/*.mdc` and is auto-attached by Cursor at session time — unlike Claude/Copilot where `/specrew-*` slash commands are user-invoked. No new mental model needed; the same Crew identity reaches your AI through whichever surface the host provides.

## Known limitations

### `cursor` vs `cursor-agent` binary disambiguation

Cursor ships TWO CLIs: `cursor` (the VS Code-style editor launcher, `cursor.cmd` v2.4.28) and `cursor-agent` (the standalone Agent CLI, `cursor-agent.ps1` v2026.05.28). Specrew uses `cursor-agent` exclusively for headless governance launches. If you only have the VS Code launcher on PATH, `specrew start --host cursor` will report `cursor-agent` not installed and surface the install URL. Both binaries should be on PATH after a normal Cursor install.

### Cursor has no user-defined slash-command surface

Specrew's Crew on Cursor cannot use `/speckit.*` or `/specrew-*` invocations the way Claude/Copilot users do. The skill catalog deploys as `.cursor/rules/*.mdc` (auto-attached) instead. Functionally equivalent for the Crew (rules content is read at every Cursor session); the user-visible difference is that Cursor users don't type slash-prefix commands. This matches the Codex pattern (Codex also has no slash-command surface).

### `--plugin-dir` packaging out of scope for v0.29.0

Cursor supports a `--plugin-dir` option for advanced packaging (Proposal 114 Option 3). v0.29.0 ships the Project Rules approach (Option 2). Plugin-dir packaging is tracked as a v2 follow-up if real Cursor user patterns indicate demand.

### Boundary enforcement is cooperative on Cursor (same as other non-Antigravity hosts)

Like Claude/Codex/Copilot, Cursor boundary enforcement is prose-based in v0.29.0. [Proposal 105](../proposals/105-host-native-hook-deployment.md) (host-native PreToolUse hooks) will move this to runtime enforcement in a future release as host hook surfaces mature.

## Migration from v0.28.x

`specrew update --module` (or `Install-Module Specrew -Force` followed by re-launch) brings you to v0.29.0. Existing `.specrew/`, `.specify/`, `.squad/` directories are preserved. To start using Cursor as your host, install [Cursor](https://cursor.com/) (which adds both `cursor` and `cursor-agent` to PATH) then `specrew start --host cursor "<task>"` from any existing or new Specrew project.

If you're starting fresh: `specrew init` followed by `specrew start --host cursor "<feature>"` works in a clean project directory. The first launch deploys Specrew skills to `.cursor/rules/*.mdc` (and to all other detected hosts' skill catalogs in parallel, per the F-044 multi-host architecture).

## Verification

PR #1226 shipped with all 6 CI gates green + the F-049 Docker pre-publish harness running cleanly including the new Phase 2 bidirectional FileList completeness guard (PR #1225). Three iterations closed (T011-T013 test coverage; T014-T016 docs + human-verified smoke). 0 drift events at feature-closeout. Manual install validation passed: v0.29.0-beta.1 installed + Cursor launch smoke-tested before v0.29.0 stable promotion (Universal Beta-Before-Stable mandate Step 11).

## What's next

- **F-051 — Multi-Session Foundation** (Proposals 010 + 134 minimal slice + Spec-Kit upgrade 0.8.13 -> 0.8.18 + `specrew update` baseline bug-fix + `.squad/identity/now.md` split + fresh-worktree detection): single-human-multiple-Crew-shells coordination + multi-developer foundation
- **F-052 — Structured Multi-Phase Reviewer Skill** (Proposal 145): per-phase per-FR coverage matrix enforcement
- **F-053 — Multi-Agent Subagent Orchestration V1** (Proposal 139): cost-aware per-task model routing
- **Parallel small-fix bundle alongside F-051**: Proposal 138 (Spec Kit Underutilized Surfaces — activate `/speckit.checklist`, `/speckit.analyze`), Proposal 146 (`/specrew.refocus` slash command for methodology re-load), Proposal 147 (`--host-options` host-native flag passthrough), Proposal 011 (Architecture Intent Checkpoint)
