---
proposal: 136
title: Per-Project Shell Visual Context (Title + Prompt + Color) for Multi-Shell Discipline
status: candidate
phase: phase-2
estimated-sp: 2-4
priority-tier: 1
discussion: empirically motivated 2026-05-28 by Shape 6 cross-project lifecycle bleed incident — user pasted iTeach-Avatar bug instruction into PlanningPoC's shell because identical-looking PowerShell prompts gave no visual cue which Specrew session was active. User confirmed *"It is going to happen a lot, since we are using multiple shell windows concurrently"* — expected weekly under normal multi-project workflow. This proposal is Layer 0 of the Shape 6 fix stack — visual prevention BEFORE the wrong-shell paste happens. Composes with the Layer 1 coordinator-charter prompt-relevance check (separate proposal candidate / small-fix slice) and Layer 2/3 validator + runtime-hook downstream defenses (Proposal 120 Pillar 6 + Proposal 105). HIGH PRIORITY because empirical workflow makes the bug class structural, not edge.
---

# Per-Project Shell Visual Context (Title + Prompt + Color) for Multi-Shell Discipline

## Why

Specrew's actual user workflow involves multiple concurrent shell windows, each bound to a different project (e.g., Specrew dev + downstream-project A + downstream-project B + tester-assist project C). PowerShell's default prompt is identical across all shells (`PS C:\...\path>` with cwd as the only differentiator). Human attention switches between shells throughout a day; the visual cue that distinguishes "which Specrew session is this?" is currently just the current-working-directory path — which is small, scannable only by close attention, and often truncated by terminal width.

User report 2026-05-28: pasted an iTeach-Avatar bug instruction into PlanningPoC's shell because the shells looked identical at the moment of attention-switching. The downstream consequence was the Shape 6 cross-project lifecycle bleed incident (memory `[[shape6-cross-project-lifecycle-bleed-2026-05-28]]`). User explicitly stated: *"It is going to happen a lot, since we are using multiple shell windows concurrently."*

That's structural, not edge. The bug class will recur weekly under normal usage. **The cheapest + highest-ROI prevention is at the visual layer**: make each shell announce its bound project at every prompt, so the user's eye catches the mismatch before paste.

### What's missing today

When `specrew start` launches a shell session:

- The terminal-window/tab title remains the host's default (often "PowerShell" or the underlying shell binary name)
- The prompt remains the default `PS C:\<cwd>>` shape
- No visual color cue distinguishes "this shell is bound to project X" from "this shell is bound to project Y"
- After several minutes of attention switching, the user has no fast visual disambiguator

This is exactly the cognitive-load layer where multi-window workflow mistakes happen.

## What — three small additions

### 1. Set terminal title via ANSI on session launch (~0.5 SP)

`specrew start` (or a `Set-SpecrewShellContext` helper) writes the terminal title via the universal ANSI escape sequence:

```text
ESC ] 0 ; <title> BEL
```

Concretely:

```powershell
$ESC = [char]27
$BEL = [char]7
Write-Host -NoNewline "${ESC}]0;Specrew: $projectLabel ($currentFeatureRef)${BEL}"
```

This works in Windows Terminal, VS Code terminal, ConEmu, and most modern terminal emulators. The classic Windows Console host honors `$Host.UI.RawUI.WindowTitle` as fallback.

Result: every terminal tab visibly says `Specrew: PlanningPoC (F-049 iter-3)` in its title bar.

### 2. Override PowerShell `prompt` function with colored project label (~1 SP)

Define a `global:prompt` function that includes the project label inline at every prompt:

```powershell
function global:prompt {
    Write-Host "[" -NoNewline
    Write-Host "Specrew:$projectLabel" -ForegroundColor $projectColor -NoNewline
    Write-Host " $currentFeatureRef" -NoNewline -ForegroundColor DarkGray
    Write-Host "]" -NoNewline
    "PS $(Get-Location)> "
}
```

Result: every prompt visibly starts with `[Specrew:PlanningPoC F-049 iter-3]PS C:\...>` with the project name colored (e.g., Cyan for PlanningPoC, Magenta for iTeach-Avatar, Yellow for Specrew dev itself).

### 3. Per-project color stored in `.specrew/config.yml` (~0.5 SP)

Extend `.specrew/config.yml` with a `shell:` block:

```yaml
shell:
  project_label: "PlanningPoC"
  project_color: "Cyan"
  show_feature_in_prompt: true
  set_terminal_title: true
```

- `project_label` defaults to the project directory name; user can override (e.g., short alias)
- `project_color` defaults to a deterministic color picked from the project name hash (so identical names always get the same color across machines); user can override
- `show_feature_in_prompt` / `set_terminal_title` are toggles for users who prefer minimal UI

Color picker at `specrew init` time offers the default + lets user pick from a small palette (Cyan / Magenta / Yellow / Green / Red / Blue / White / Gray) with preview.

## How

Single iteration, ~2-4 SP total. Suggested task breakdown:

| Task | What | SP |
|---|---|---|
| T01 | `Set-SpecrewShellContext` cmdlet exported by the Specrew module (reads `.specrew/config.yml shell:` block, writes title via ANSI, defines `global:prompt`) | 1 |
| T02 | `specrew init` writes default `shell:` block to `.specrew/config.yml` with deterministic-from-name color default + offers user-override prompt | 0.5 |
| T03 | `specrew start` auto-invokes `Set-SpecrewShellContext` at session launch (after bootstrap context written, before host CLI launches) | 0.5 |
| T04 | Docs section in `docs/troubleshooting.md` (or new `docs/multi-shell-discipline.md`) covering the recipe + manual override + how to disable | 0.5 |
| T05 | Integration test covering: `.specrew/config.yml shell:` block parsing + cmdlet output (title set, prompt function defined) | 0.5 |

Total: 3 SP. Could ship as standalone small-fix slice (per Proposal 067) OR bundle with the Layer 1 coordinator-charter prompt-relevance directive (separately captured) into a "Shape 6 multi-shell discipline bundle" small-fix slice (~5-7 SP combined).

## Caveats

- **Terminal compatibility**: ANSI title works in Windows Terminal + VS Code + ConEmu + most modern terminals; classic Windows Console host needs `$Host.UI.RawUI.WindowTitle` fallback (well-supported)
- **Foreground accent only, not background**: changing terminal background per project is brittle (Windows Terminal needs profile config; classic Console can do it but changes the whole window; IDE terminals often ignore). Foreground color in the prompt is the safe lowest-common-denominator
- **User customization**: respect users who want minimal UI — toggles in `.specrew/config.yml` (`show_feature_in_prompt: false`, `set_terminal_title: false`) honored
- **Color blindness / accessibility**: default palette picks colors that work for common color-vision-deficiency types; users can override with text-only labels if needed (palette includes a "None" option that skips color)
- **Existing user prompts**: this `Set-SpecrewShellContext` REPLACES the user's prompt function. Document this clearly + offer a `Restore-SpecrewShellContext` cmdlet that reverts to default
- **IDE terminals**: VS Code honors ANSI title sequence; JetBrains terminals partial support; users in those IDEs get prompt-based cue but maybe not title (graceful degradation)

## Acceptance criteria

- **AC1**: `Set-SpecrewShellContext` cmdlet exported by Specrew module; reads `.specrew/config.yml shell:` block; writes ANSI title; defines `global:prompt` with colored project label
- **AC2**: `specrew init` writes default `shell:` block with deterministic-from-name color
- **AC3**: `specrew start` auto-invokes the cmdlet at session launch
- **AC4**: User can disable via `set_terminal_title: false` and `show_feature_in_prompt: false` in `.specrew/config.yml`
- **AC5**: Empirical mistake-reduction signal: dogfooding session run with 3+ parallel Specrew shells, user reports the visual cue makes the active shell unambiguous at a glance (subjective acceptance)
- **AC6**: Docs cover: the visual recipe, the disable toggles, the manual override (user can customize their prompt function further), the per-project color picker
- **AC7**: Integration test verifies `.specrew/config.yml shell:` block parsing + cmdlet behavior across PowerShell 7.x on Windows / Linux / macOS

## Out of scope

- Background-color changes per project (brittle across terminals; foreground accent is the safe layer)
- Per-project terminal-tab grouping in Windows Terminal (separate proposal candidate if requested; depends on Windows Terminal profile API)
- Custom terminal themes per project (user-side; not Specrew's surface)
- Auto-detecting wrong-shell paste mistakes via topical analysis (that's the Layer 1 coordinator-charter prompt-relevance check — separate proposal candidate)
- Cross-shell session coordination (e.g., locks preventing parallel boundary-syncs against the same project) — multi-developer territory (Proposal 010)

## Composition

| Proposal | Relationship |
|---|---|
| **Shape 6 cross-project lifecycle bleed memory** | THIS proposal is Layer 0 (pre-mistake prevention) of the Shape 6 fix stack. Layer 1 (coordinator-charter prompt-relevance check) ships separately as adjacent small-fix slice. Layer 2 (Pillar 6 of Proposal 120) + Layer 3 (Proposal 105 runtime hook) ship downstream as belt+suspenders |
| **Proposal 050 (Version Surface Discoverability)** | Both make project state visible at shell interaction. Could bundle: `Set-SpecrewShellContext` includes version in the prompt — `[Specrew:PlanningPoC v0.27.6 F-049 iter-3]` — combining shell visual context + version surface in one prompt-customization slice |
| **Proposal 047 (Project Governance Profile)** | `.specrew/config.yml shell:` block extends the per-project preference catalog; fits naturally inside 047's 10-dial concept (`shell_color`, `shell_title_enabled`, etc.) as additional dials |
| **Proposal 067 (Small-Fix Slice Type)** | This proposal IS a natural small-fix slice (~2-4 SP, single iteration, focused scope, well-bounded files) |
| **Proposal 130 (`/specrew-switch-to` slash command)** | Both target multi-shell UX. Could bundle as "Multi-Shell Discipline Bundle" feature: F-050 = 130 + 136 + Layer 1 charter directive (~15-20 SP combined). Or ship 136 standalone first; 130 + Layer 1 follow |
| **Proposal 133 (Specrew primer in persistent host-instruction files)** | Both involve `specrew init` writing per-host/per-project surfaces. Composable but independent |

## Sequencing options

| Option | When | Tradeoff |
|---|---|---|
| **A. Ship NOW as standalone small-fix slice** | Within days; ~2-4 SP | Fastest user-visible mistake-prevention; doesn't wait for F-049 close. Risk: parallel to F-049 work |
| **B. Bundle with Layer 1 charter directive as small-fix slice** | After F-049 closes; ~5-7 SP combined | Coherent "Shape 6 multi-shell discipline" bundle. Slight delay |
| **C. Fold into F-050 (Proposal 130 + 136 + Layer 1) as "Multi-Shell Discipline Bundle"** | After F-049 + maybe deferred behind Proposal 133; ~15-20 SP | Most thematic; biggest single feature. Longest delay before user benefit |
| **D. F-049 iter-4 scope-extension** (alongside Proposal 120 Pillar 6 = Layer 2) | Within F-049's remaining iterations; ~10-15 SP added to iter-4 | Bundles all Shape 6 layers in one F-049 closeout; but iter-4 already at 6-10 SP — adding 5+ SP makes iter-4 heavy |

**Recommended: Option A** — ship NOW as standalone small-fix slice. Empirical workflow pressure (weekly recurrence expected) justifies fastest possible delivery. Layer 1 charter directive (separate proposal candidate) can follow immediately as another small-fix slice; both ship before F-050 starts. F-050 then becomes the larger "multi-shell discipline" feature combining `/specrew-switch-to` + Pillar 6 validator with the L0+L1 already in place.

## Status history

- 2026-05-28: candidate proposal drafted after Shape 6 cross-project lifecycle bleed incident (memory `[[shape6-cross-project-lifecycle-bleed-2026-05-28]]`). User-confirmed multi-shell workflow makes Shape 6 structural, not edge. Layer 0 (visual shell-binding cue) is the highest-ROI prevention because it operates at the cognitive layer where the routing mistake originates. ~2-4 SP standalone small-fix slice; or bundle with Layer 1 charter directive (~5-7 SP combined). HIGH PRIORITY Tier 1.

## Cross-references

- `[[shape6-cross-project-lifecycle-bleed-2026-05-28]]` — empirical motivation
- file:///C:/Dev/Specrew/proposals/067-small-fix-slice-type.md — natural slice type
- file:///C:/Dev/Specrew/proposals/050-version-surface-discoverability.md — adjacent visual-surface proposal
- file:///C:/Dev/Specrew/proposals/047-project-governance-profile.md — `.specrew/config.yml shell:` block extends per-project preference catalog
- file:///C:/Dev/Specrew/proposals/130-specrew-switch-to-host-handover.md — sibling multi-shell UX proposal
- file:///C:/Dev/Specrew/proposals/120-handoff-block-validator-enforcement.md — Pillar 6 (Layer 2 of Shape 6 fix stack)
- file:///C:/Dev/Specrew/proposals/105-host-native-hook-deployment.md — Layer 3 of Shape 6 fix stack
- INDEX: file:///C:/Dev/Specrew/proposals/INDEX.md
