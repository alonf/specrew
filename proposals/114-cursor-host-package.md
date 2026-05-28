---
proposal: 114
title: Cursor Host Package — Tier-1 Multi-Host Expansion Following F-044 Per-Host Architecture
status: draft
phase: phase-2
estimated-sp: 8-12
priority-tier: 1
type: tooling
discussion: parallel-with-f049 pilot; promoted to draft 2026-05-28 to seed parallel-development workflow validation
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

    Binary           = 'cursor-agent'   # VERIFY AT CLARIFY: Proposal 124 uses 'cursor-agent'; this proposal originally said 'cursor'. Cursor's CLI evolved through 2025; current canonical name must be empirically verified. Candidates: 'cursor-agent' (standalone CLI), 'cursor' (with 'agent' subcommand). Pick whichever exists on PATH at implementation time.
    InstallUrl       = 'https://cursor.sh/install'
    InstallGuidance  = 'Cursor CLI not found on PATH. Install Cursor from https://cursor.sh; ensure the agent CLI is on PATH (via Cursor > Cmd-Shift-P > "Shell Command: Install ..." or platform-specific installer). Verify exact binary name (cursor-agent vs cursor) during clarify-boundary empirical CLI check.'

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

1. **`New-CursorLaunchInvocation`** — builds the Cursor CLI invocation for `specrew start --host cursor "..."`. Exact shape verified at clarify boundary; likely candidates: `cursor-agent --prompt "<feature-prompt>" --workdir <project>` OR `cursor agent --prompt "..." --workdir ...`. The implementing Crew empirically discovers which form Cursor's current CLI accepts.
2. **`Convert-CursorFlag`** — translates universal Specrew flags (`--allow-all`, `--autonomous`, `--readonly`) to Cursor-CLI equivalents.
3. **`Test-CursorRuntimeInstalled`** — probes for the resolved binary (`cursor-agent` or `cursor` per clarify-boundary verification) + version check.
4. **`Get-CursorSignals`** — returns probe signals: `binary-present`, `binary-version`, `agent-mode-available`, `project-has-cursor-dir`.
5. **`Install-CursorCrewRuntime`** — translates `.specrew/team/agents/<role>.md` (canonical source) → Cursor's native agent/rules location. Target path (`.cursor/agents/` vs `.cursor/rules/` vs `.cursorrules` file) verified at clarify boundary; mirrors the canonical-source pattern F-044 Slice 9 established.

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

### Empirical Verification Required At Clarify Boundary

Promoted to draft 2026-05-28. These items are no longer pre-drafting blockers — the implementing Crew resolves them at the clarify boundary as part of substantive intake, and the spec captures the resolved answers as authoritative scope inputs.

1. **Canonical CLI binary name + invocation shape.** Cursor's CLI evolved through 2025. Verify on the implementing machine whether the binary is `cursor-agent` (standalone CLI) or `cursor` (with `agent` subcommand). Verify the invocation that triggers Agent mode with non-interactive prompt + working-directory. Resolves the discrepancy between this proposal's original `cursor` claim and Proposal 124's `cursor-agent` claim.
2. **Skill/agent deployment target.** Cursor's "Rules" feature uses `.cursor/rules/` and `.cursorrules`. Verify whether `.cursor/skills/` (this proposal's original target) is viable, or whether `.cursor/rules/` is the correct convention-aligned target. Cursor's agent-rules path semantics may have shifted; ground-truth at clarify.
3. **Non-interactive CLI support.** Confirm Cursor CLI supports non-interactive Agent mode (not just GUI launcher). If non-interactive isn't supported, downgrade host status from `supported` to `preview`. If GUI-only, escalate to "Tier 2 — verify CLI first" and re-scope this proposal accordingly.
4. **Per-conversation system prompt mechanism.** Verify whether Cursor uses `CURSOR.md`, `AGENTS.md`, or another convention for the coordinator prompt equivalent. Set `InstructionsFile` accordingly.

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

## Parallel-Work Coordination Charter

**Added 2026-05-28 as part of parallel-development workflow pilot** (this feature runs concurrently with Feature 049 on the main branch). The implementing Crew MUST observe these durable coordination guardrails to avoid merge catastrophe or audit-trail breakage:

1. **Pre-assigned ModuleVersion**: this feature ships at ModuleVersion `0.29.0` in `Specrew.psd1`. F-049 owns the previous slot. Do NOT bump to any other value during implementation — the assignment is pre-allocated to prevent collision at PR-merge time.
2. **Do NOT touch framework infrastructure**: `validate-governance.ps1`, `shared-governance.ps1`, or any file under `.specify/extensions/specrew-speckit/**`. These are framework files. Even a "small fix" creates catastrophic merge state with F-049 and risks downstream breakage for installed Specrew users. Surface bugs as proposals, not in-place edits.
3. **Do NOT run `specrew update` in this worktree**: initial `specrew init` only. Mid-iteration `specrew update` risks the duplicate-row deploy bug (memory `[[project-specrew-update-deploy-duplicate-rows-2026-05-27]]`) AND would conflict with F-049's parallel deploy work.
4. **Append-only on shared cross-feature files**: `proposals/INDEX.md`, `CHANGELOG.md`, `dashboard.md` — add new rows/entries at the END (not the middle). Reduces autoresolve risk at merge time.
5. **Sequential PR merge — F-049 first**: do NOT merge this feature's PR before F-049's PR merges to main. F-049 contains audit-trail commit-hash citations in `specs/049-pipeline-hardening-intake/iterations/*/state.md` that invalidate if F-049 rebases onto another feature's merge. After F-049 merges to main, this branch rebases onto post-F-049 main, then proceeds with its own PR + beta-publish cycle.
6. **Beta-before-stable publish sequence**: per universal mandate `[[feedback-beta-before-stable-universal-2026-05-26]]`, this feature ships to PSGallery as `v0.29.0-beta.N` first, awaits manual install validation, then promotes to stable. Same SDLC Steps 5-14 as F-049.
7. **No `.specrew/` or `.squad/` state edits committed to this branch**: those files are gitignored (per fix `437338f6`); ensure your work doesn't re-track them.
8. **Cross-reviewer at boundaries**: use a different model session for review-signoff (e.g., if implementing Crew is Copilot, review with Codex or Claude — pattern empirically validated 4× in F-049 lifecycle including bidirectional convergence; see `[[cross-reviewer-3rd-empirical-instance-2026-05-28]]`).
9. **Empirical multi-host validation moment**: this is the first post-F-044 host-package addition AND the first parallel-development pilot for Specrew. Both data points are valuable methodology evidence; capture surprises in retro for downstream proposal refinement (114, 124, future per-host packages).

The maintainer (Alon Fliess) is the integration point: this Crew runs to its own beat, hits boundaries, asks for verdicts; F-049 Crew does the same; maintainer decides when each PR merges based on which finishes first.

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
- **2026-05-28** — Promoted candidate → draft to seed the **parallel-development workflow pilot** (this feature runs concurrently with Feature 049 on the main branch). Resolved binary-name discrepancy with Proposal 124 (defer to clarify-boundary empirical verification). Added Parallel-Work Coordination Charter section with pre-assigned ModuleVersion (`0.29.0`), framework-file protection, sequential PR merge ordering (F-049 first), and cross-reviewer requirement. Empirical Verification items relabeled from "Required Before Drafting → Spec" to "Required At Clarify Boundary" (now part of the implementing Crew's substantive intake, not pre-drafting blocker). Proposal 124 (Tier-1 bundle) amended in parallel with deconflict note pointing here.
