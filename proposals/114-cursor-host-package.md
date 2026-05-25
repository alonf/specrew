---
proposal: 114
title: Cursor Host Package — Tier-1 Multi-Host Expansion Following F-044 Per-Host Architecture
status: candidate
phase: phase-2
estimated-sp: 8-12
priority-tier: 1
type: tooling
discussion: tbd
depends-on:
  - F-044 # Per-Host Architecture Refactor (provides the 5-function contract + registry pattern Cursor will follow)
composes-with:
  - 069 # Multi-Host Launch Path (shipped F-040; --host flag dispatch)
  - 104 # Multi-Host Onboarding + Selection Flow (shipped F-043; host probe + menu)
  - 108 # specrew-init Refactor + Per-Host Crew-Runtime Abstraction (shipped F-044)
bundle-with:
  - tier-1-aider-host-package # candidate (memory pointer, no proposal yet)
  - tier-1-amp-host-package    # candidate
  - tier-1-opencode-host-package # candidate
audience: tooling
---

# Cursor Host Package — Tier-1 Multi-Host Expansion Following F-044 Per-Host Architecture

## Why

The 2026-05-24 multi-host expansion triage (recorded in memory) sorted candidate hosts into three tiers:

- **Tier 1 (ship)**: Aider, Amp, OpenCode, **Cursor**
- **Tier 2 (verify CLI first)**: Jules, Devin, Grok
- **Tier 3 (skip)**: Cline, Kiro, Junie, DeepSeek (IDE-embedded or model-layer)

Cursor is Tier 1 — it has a usable CLI (`cursor` binary), a recognized project-config surface (`.cursor/`), and an established user base actively asking for Specrew support. With F-044 (PR #844, shipped 2026-05-25) the per-host architecture is now mature: registry + 5-function contract + canonical `.specrew/team/agents/` source-of-truth. Adding a new host is a matter of writing one ~150-line package, not refactoring the codebase.

Empirical evidence the expansion has demand:

- 2026-05-25 launch chat: "people asked about Cursor support" (user statement during v0.27.0 ship)
- Cursor users routinely run a separate AI session inside Cursor's Agent panel while editing in the same window — natural Specrew composition (governance in Cursor, lifecycle ceremony in the panel)
- Memory: "per-host mechanical cost ~half-day once CLI cooperation verified" — Cursor is the lowest-friction Tier-1 candidate because its CLI semantics are already documented + stable

## What — Cursor Host Package Following F-044 Pattern

### Manifest (`hosts/cursor/host.psd1`)

Following the canonical schema established by F-044's existing 4 hosts (copilot/claude/codex/antigravity):

```powershell
@{
    Kind          = 'cursor'
    DisplayName   = 'Cursor (AI Code Editor)'
    Status        = 'supported'
    SchemaVersion = 1
    MenuPriority  = 1.5  # Between Claude (1) and Codex (2) — Tier-1 first wave

    Binary           = 'cursor'
    InstallUrl       = 'https://cursor.sh/install'
    InstallGuidance  = 'Cursor CLI not found on PATH. Install Cursor from https://cursor.sh, then ensure cursor command is in PATH (Cursor > Cmd-Shift-P > "Shell Command: Install cursor command in PATH").'

    SkillRoot                  = '.cursor/skills'
    HasUserSlashCommandSurface = $true   # Cursor's Agent mode supports custom rules; treat skills as rules-equivalent
    SettingsPath               = '.cursor/settings.json'
    AgentDir                   = '.cursor/agents/'
    InstructionsFile           = 'CURSOR.md'   # Cursor convention; falls back to AGENTS.md per spec

    SpeckitAiFlag  = 'cursor'
    PreferredAgent = 'cursor'

    HandlersFile         = 'handlers.ps1'
    CoordinatorRulesFile = 'coordinator-rules.psd1'
}
```

### Five-Function Contract (`hosts/cursor/host.ps1`)

1. **`New-CursorLaunchInvocation`** — builds the `cursor` CLI invocation for `specrew start --host cursor "..."`. Likely shape: `cursor agent --prompt "<feature-prompt>" --workdir <project>` (verified during implementation).
2. **`Convert-CursorFlag`** — translates universal Specrew flags (`--allow-all`, `--autonomous`, `--readonly`) to Cursor-CLI equivalents.
3. **`Test-CursorRuntimeInstalled`** — `Get-Command cursor` + version probe.
4. **`Get-CursorSignals`** — returns probe signals: `binary-present`, `binary-version`, `agent-mode-available`, `project-has-cursor-dir`.
5. **`Install-CursorCrewRuntime`** — translates `.specrew/team/agents/<role>.md` (canonical source) → `.cursor/agents/<role>.md` (Cursor's native agent-rules location). Mirrors the canonical-source pattern F-044 Slice 9 established.

### Skill-Catalog Deployment Target

Add `.cursor/skills/` to the three-host deployment targets already in `extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1`:

```powershell
# Before (4 targets after F-044):
return @(
    [pscustomobject]@{ Name = 'claude';    Path = Join-Path $ProjectPath '.claude\skills' }
    [pscustomobject]@{ Name = 'github';    Path = Join-Path $ProjectPath '.github\skills' }
    [pscustomobject]@{ Name = 'agents';    Path = Join-Path $ProjectPath '.agents\skills' }
)

# After (5 targets with Cursor):
return @(
    [pscustomobject]@{ Name = 'claude';    Path = Join-Path $ProjectPath '.claude\skills' }
    [pscustomobject]@{ Name = 'cursor';    Path = Join-Path $ProjectPath '.cursor\skills' }
    [pscustomobject]@{ Name = 'github';    Path = Join-Path $ProjectPath '.github\skills' }
    [pscustomobject]@{ Name = 'agents';    Path = Join-Path $ProjectPath '.agents\skills' }
)
```

### Registry Integration

Cursor's package is auto-discovered by `hosts/_registry.ps1`'s directory scan (no code change to registry needed — that's the point of the F-044 contract).

### Test Coverage

Following F-044's iter-004 + iter-005 patterns:

- `tests/hosts/cursor.tests.ps1` — unit tests for each of the 5 contract functions with mock + real Cursor binary fixtures
- `tests/integration/host-cursor-launch.tests.ps1` — smoke test for `specrew start --host cursor "..."` end-to-end (skipped on CI runners without Cursor installed)
- Update `tests/integration/multi-host-detection.tests.ps1` to include cursor in the host-probe matrix

## How — Implementation Surface + Effort

| Component | File | Effort |
|---|---|---|
| Manifest authoring | `hosts/cursor/host.psd1` | 0.5 SP |
| Five-function contract implementation | `hosts/cursor/host.ps1` | 3-4 SP |
| Handlers + coordinator rules | `hosts/cursor/handlers.ps1` + `coordinator-rules.psd1` | 1-2 SP |
| Skill-catalog deployment target addition | `extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1` | 0.5 SP |
| Unit tests | `tests/hosts/cursor.tests.ps1` | 1-2 SP |
| Integration tests | `tests/integration/host-cursor-launch.tests.ps1` | 1 SP |
| Documentation | `docs/getting-started.md` + `docs/user-guide.md` (add Cursor quickstart + caveats) | 1 SP |
| Empirical smoke test (manual) | Run a real feature on Cursor end-to-end | 1 SP |

**Total estimate**: ~8-12 SP for a single iteration. Skewed toward upper end if Cursor's CLI flag conventions require more translation work than expected.

### Verification Required Before Drafting → Spec

1. **Confirm `cursor` CLI command shape.** As of 2026-05 the CLI evolved through several iterations. Need to verify the actual invocation that triggers Agent mode with a non-interactive prompt + working-directory. If `cursor agent ...` isn't the right shape, the proposal needs adjustment.
2. **Confirm `.cursor/skills/` is a viable deployment path.** Cursor's "Rules" feature uses `.cursor/rules/` and `.cursorrules` file. May want `.cursor/rules/` instead of `.cursor/skills/` for closer convention alignment. Investigate during spec phase.
3. **Confirm `cursor` CLI is non-interactive.** Some Cursor versions only allow Agent mode through the GUI; CLI may just be a launcher. If non-interactive isn't supported, Cursor becomes Tier 2 (verify CLI first) instead of Tier 1.

## Composition Notes

### With Proposal 069 (Multi-Host Launch Path — shipped F-040)

069 established `--host <kind>` dispatch + host-aware routing fallback. 114 adds one more value to the `<kind>` enum + one more package implementing the contract. No 069 changes needed — that's the whole point of the host-package pattern.

### With Proposal 104 (Multi-Host Onboarding + Selection Flow — shipped F-043)

104 wrote the host-probe + interactive numbered menu. Adding Cursor means it appears in the menu automatically (registry-driven, with `MenuPriority: 1.5` placing it between Claude and Codex). No 104 changes needed.

### With Proposal 108 (specrew-init Refactor + Per-Host Crew-Runtime Abstraction — shipped F-044)

108 is the foundation. Adding Cursor is exactly the canonical use case 108 was designed to enable. Validates the architecture by being the first post-shipment host added.

### Bundle: Tier-1 Multi-Host Expansion

Recommend bundling Cursor + Aider + Amp + OpenCode as a single Phase-2c feature (separate iterations per host, single feature umbrella). Each is ~8-12 SP, total bundle ~32-48 SP across 4 iterations. Run sequentially (one iteration per host) so each can be smoke-tested on a real downstream project before the next starts.

Alternative: ship Cursor first as a single-host feature (validates the pattern post-F-044) and Aider/Amp/OpenCode follow as their own bundle once Cursor is proven.

## Open Questions

1. **Cursor's `.cursorrules` vs `.cursor/rules/` vs `.cursor/skills/`?** The Crew's translation layer for Cursor needs to land in whichever location Cursor's Agent mode actually reads. Multiple conventions co-exist in Cursor's ecosystem; investigate empirically during spec phase.
2. **Does Cursor have a per-conversation system prompt?** Specrew's coordinator prompt (currently delivered via `.github/agents/squad.agent.md` for Copilot, `CLAUDE.md` for Claude, etc.) needs a Cursor equivalent. Likely `CURSOR.md` or `AGENTS.md`.
3. **Cursor CLI working directory semantics?** Specrew runs in `--workdir <project>`. Verify Cursor CLI respects this OR document the workaround (`cd <project> && cursor agent ...`).
4. **Cursor account / authentication?** Some Cursor features require a Cursor Pro account. Should the host package check for auth status as a 6th signal? Currently `Get-Signals` returns 4 — adding `account-tier: free|pro|business|missing` would let Specrew warn users about quota limits.
5. **Slash-command surface?** Cursor's Agent mode may or may not invoke skills as user-typeable slash commands. If not, `HasUserSlashCommandSurface = $false` and the WARN message at `scripts/internal/detect-hosts.ps1:230-231` covers it (skills deployed but not invokable as slash). Verify empirically.
6. **MenuPriority 1.5 vs 2.5 vs other?** With Cursor + Aider + Amp + OpenCode all joining the menu, priority ordering matters. Recommendation: Cursor 1.5 (most-known Tier-1), Aider 2.5, Amp 3.5, OpenCode 4.5 — preserving current copilot=3, antigravity=4 placements. Final ordering up to user judgment.

## Not in Scope

- Tier 2 host packages (Jules, Devin, Grok) — those need CLI verification first
- Tier 3 host packages (Cline, Kiro, Junie, DeepSeek) — IDE-embedded or model-layer; not within multi-host scope
- Cursor-specific advanced features (multi-file context window, Composer agent, etc.) — first slice is parity with the existing host contract; advanced features per Cursor's evolving capabilities can land as follow-up enhancements
- Documentation deep-dive on Cursor's full feature set — only Cursor-meets-Specrew-contract surface is in scope

## Empirical Motivation Captured

- **2026-05-24** — multi-host expansion triage classified Cursor as Tier 1 ship-eligible
- **2026-05-25** — v0.27.0 launch chat: user statement "people asked about Cursur support" (typo preserved verbatim) immediately after release
- **F-044 mechanical-cost evidence** — adding antigravity host package as the 4th iteration of F-044 took ~half-iteration of work once the architecture was settled. Each subsequent host should be similar. ~8-12 SP for Cursor is consistent with this pattern.

## Status History

- **2026-05-25** — Drafted as next-after-v0.27.1-patch. Candidate status. Sequencing recommendation: ship after v0.27.1 patch closes; precedes Aider/Amp/OpenCode in the Tier-1 wave because Cursor has the highest demand signal.
