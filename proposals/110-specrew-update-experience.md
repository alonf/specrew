---
proposal: 110
title: Specrew Update Experience — Multi-Host Awareness + What's-New Surface + Pre-Update Safety + Agent-Driven Explanation
status: candidate
phase: phase-2
estimated-sp: 12-18
discussion: ad-hoc 2026-05-25 user request after F-044 multi-host work — `specrew update` was designed when Squad was the only Crew runtime; it must now mirror the multi-host architecture (hosts in version matrix + compatibility floor + supported-vs-latest semantics) and improve the update UX itself (what's new since installed, pre-update commit for rollback, agent-driven first-run explanation)
depends-on:
  - 049  # Version-Check Source Unification (provides LatestKnown source chain — extended here to host kinds)
  - 050  # Version Surface Discoverability (banner at init/start — extended here with update-available signal)
  - 079  # Supported-vs-Latest distinction (shipped for Spec-Kit/Squad — extended here to hosts)
  - 104  # Multi-Host Onboarding (shipped; provides `.specrew/host-history.yml` + per-host probe used here)
  - 108  # specrew-init Refactor + Per-Host Crew-Runtime (shipped; provides host registry + contract pattern — extended here with `GetHostVersion`)
composes-with:
  - 058  # Plugin-Based Multi-Host Distribution (each host plugin becomes the natural site for its own compatibility declaration)
  - 060  # Pre-Release Channel Staging (rollback messaging folds in stable-vs-beta channel awareness)
  - 075  # Update Artifact Backfill Discipline (adjacent: 075 backfills iteration artifacts post-update; 110 governs the update itself)
blocks: []
---

# Specrew Update Experience — Multi-Host Awareness + What's-New Surface + Pre-Update Safety + Agent-Driven Explanation

## Why

`specrew update` and `specrew update --info` were designed when Squad was the only Crew runtime and Spec-Kit was the only adjacent toolchain. The command's version-check matrix today is exactly two columns wide:

```
Platform Current LatestKnown Status  Source
-------- ------- ----------- ------  ------
Specrew  0.27.0  0.27.0      current module-manifest
Spec Kit 0.8.11  0.8.11      current github-tags
Squad    0.9.4   0.9.4       current npm
```

After F-040 + F-043 + F-044 (Proposals 069 + 104 + 108), Specrew supports multiple hosts — Copilot CLI, Claude Code CLI, Codex CLI, Antigravity. Each host has its own version surface, its own release cadence, and its own compatibility surface with Specrew. None of this is visible in `update --info`. The update command's mental model still assumes a single host.

Five concrete gaps surface as a result:

### Gap 1 — Host versions are invisible

A user can have Claude CLI 1.0.65 installed and Codex CLI 0.42.0 installed, AND be running Specrew configured for both, AND have no UI in `update --info` that tells them either version, OR whether Specrew has been tested against those host versions. The first signal a user gets that the host changed underneath them is "my Specrew session started behaving weirdly." That's the same UX failure F-020 + Proposal 079 closed for Spec-Kit/Squad.

### Gap 2 — Host compatibility floor is undeclared

Specrew has tested compatibility surfaces for Spec-Kit (`min: 0.8.4`, `max_tested: 0.8.4` in `scripts/internal/supported-versions.yml` per Proposal 079) and for Squad (`min: 0.9.1`, `max_tested: 0.9.4`). It has NONE for Copilot/Claude/Codex/Antigravity. When Anthropic ships Claude CLI 1.1.x and changes a flag, Specrew has no declared "we tested up to 1.0.78" signal — users hit the breakage as a runtime error, not as a `update --info` warning.

### Gap 3 — "What's new" is silently hidden

`Update-Module Specrew` upgrades the user from v0.24.2 → v0.27.0 in one PSGallery call. CHANGELOG.md has rich entries for v0.25.0 (Launch-Mode Boundary Enforcement), v0.26.0 (Multi-Host Launch Path), v0.27.0 (Multi-Host Onboarding + Per-Host Crew-Runtime Abstraction) — all directly relevant to a user who skipped three releases. None of that text surfaces during the upgrade. Users have to know to read CHANGELOG.md manually. Most won't.

### Gap 4 — Rollback path is invisible until needed

Specrew updates touch two surfaces: the PSGallery-installed module (`Update-Module Specrew`) AND the user's project files (template refresh via `specrew update --spec-kit` / `--squad`). The module can be rolled back via `Uninstall-Module / Install-Module -RequiredVersion`. The project-side template-refresh is hard to roll back unless the user committed first. Today there's no prompt to commit before updating, no surfaced rollback command after updating, and no advice that the update is reversible at all. Users who hit a regression don't know they have an exit.

### Gap 5 — Agent context for the update is missing

After an update, the user runs `specrew start`. The agent has no idea Specrew just changed. If a release added a new boundary (F-039), or a new validator (F-028), or a new artifact (F-040 review-diagrams.md), the agent may behave inconsistently with what the user expected from the previous version — and the user has no signal of what's new without reading CHANGELOG themselves. This is exactly the kind of "LLM has the context to explain it but isn't asked to" gap that Specrew's broader interaction model (Proposal 007) is built to close.

### User direction (2026-05-25)

> "We need to enhance the specrew update: First we do not only use Squad, we use multiple host and we may suggest to update the hosts if there is a new version, we also need to know that there is no breaking compatability of the host (copilot, claude, codex...) with Specrew the same as we do with Spec-Kit and Squad. We need to see the current installed version of Specrew and we should provide the information of what is new in Specrew with this update (all the changes since the current installed Specrew and the latest version). We should also offer to do a git commit before updating Specrew to have the ability to role back. If we want to have the ability of LLM to explain the new features, we can, on the first Specrew start after an update to ask the host agent to provide information about the update, like what is new, or maybe specific new feature that relevant to the current project (we can prompt the agent to do that)."

## What

Five pillars, each independently shippable. Pillars 1+2 deliver the multi-host visibility floor; 3+4 close the update-UX safety gaps; 5 wires the agent into the update narrative.

### Pillar 1 — Multi-host coverage in `specrew update --info`

Extend the version-check matrix to include every host the project has used (read from `.specrew/host-history.yml` — Proposal 104) AND every host currently detectable on PATH (probed via the host registry's `TestRuntimeInstalled` from Proposal 108).

```text
Platform   Current  LatestKnown  Status    Source
--------   -------  -----------  ------    ------
Specrew    0.27.0   0.27.0       current   module-manifest
Spec Kit   0.8.11   0.8.11       current   github-tags
Squad      0.9.4    0.9.4        current   npm
Copilot    0.0.346  0.0.346      current   gh extension
Claude     1.0.65   1.0.78       outdated  npm registry
Codex      0.42.0   0.42.0       current   npm registry
Antigravity 0.5.2-preview --      unknown   preview-only
```

Add a new contract function to the host registry (extends Proposal 108's pattern):

| Function (template) | Signature | Returns | Used by |
|---|---|---|---|
| `Get-<Kind>HostVersion` | `[-ProbeMethod auto\|cli\|registry]` | `[pscustomobject]@{Installed; LatestKnown; ProbeMethod; RawOutput}` | `scripts/internal/version-check.ps1` |

Each host package implements via the host CLI's `--version` flag (or equivalent) for Installed, and the host's release registry (npm / gh extensions / etc.) for LatestKnown. Antigravity package returns `unknown` until the host stabilizes (per 108 caveat).

### Pillar 2 — Host compatibility floor

Extend `scripts/internal/supported-versions.yml` (introduced in Proposal 079) with a `hosts:` section:

```yaml
schema: v2
speckit:
  min: "0.8.4"
  max_tested: "0.8.4"
  notes: ""
squad:
  min: "0.9.1"
  max_tested: "0.9.4"
  notes: ""
hosts:
  copilot:
    min: "0.0.345"
    max_tested: "0.0.346"
    notes: ""
  claude:
    min: "1.0.65"
    max_tested: "1.0.78"
    notes: ""
  codex:
    min: "0.42.0"
    max_tested: "0.42.0"
    notes: "0.43.x untested; watch for flag changes"
  antigravity:
    min: ""
    max_tested: ""
    notes: "Preview-grade host (2026-06-18 Gemini deadline pending)"
```

Status logic mirrors Proposal 079:

| Installed vs Supported | Status |
|---|---|
| `min` ≤ installed ≤ `max_tested` | `current` |
| installed < `min` | `below-floor` (red — Specrew refuses to run until host updated) |
| installed > `max_tested` | `ahead-of-tested` (yellow — advisory; may work but untested) |
| `max_tested` unset | `unknown` (Antigravity preview state) |

When a `below-floor` host is selected, `specrew start --host <kind>` refuses to launch and prints the supported range + the host's `--version` raw output as evidence. Same enforcement pattern Spec-Kit/Squad use today.

**Where the matrix lives**: same module-side YAML as Proposal 079, NOT downstream `.specrew/config.yml` (per 079's decision rationale — supported-versions is maintainer-managed data shipped with the module).

**Plugin-distribution composition (composes-with 058)**: when host packages become discoverable plugins, each plugin declares its own `compatibility` block; the aggregate matrix is assembled from active plugins. Until 058 ships, the matrix is centralized in `supported-versions.yml`.

### Pillar 3 — "What's New" since installed Specrew version

When `update --info` detects an available Specrew upgrade (or runs interactively before `Update-Module Specrew`), emit a CHANGELOG excerpt:

```text
Specrew  0.24.2  →  0.27.0  (3 minor versions behind)

What's new since your version:

  v0.25.0  Launch-Mode Boundary Enforcement (F-039)
           Tool-call-layer intercept; nine-boundary normalization

  v0.26.0  Multi-Host Launch Path (F-040)
           --host claude|codex|copilot with per-host flag translation

  v0.27.0  Multi-Host Onboarding + Selection Flow (F-043)
           Per-Host Crew-Runtime Abstraction (F-044)

See full notes: https://github.com/alonf/specrew/blob/main/CHANGELOG.md#0270---2026-05-25
```

New helper `scripts/internal/changelog-parser.ps1` exposes:

- `Get-ChangelogEntries -FromVersion <v> -ToVersion <v>` — returns parsed entries between two versions
- `Format-ChangelogExcerpt -Entries <obj> [-Style summary|full]` — renders to the console

CHANGELOG.md's existing schema (`## [X.Y.Z] - YYYY-MM-DD` anchors; `### Added` / `### Fixed` sections) is already well-structured; the parser is mechanical. When the format breaks (manual edits, missing anchor), the parser falls back to a "see CHANGELOG.md" link rather than failing.

Default behavior: summary style (feature name + 1-line subtitle per version). Full style available via `--changelog-style full`. Suppress entirely with `--no-changelog`.

### Pillar 4 — Pre-update git commit / rollback safety

Before running `Update-Module Specrew` OR `specrew update --spec-kit` / `--squad` (commands that write to disk), `specrew update` checks the working-tree state:

**Case A — clean working tree (no uncommitted changes)**:

```text
Working tree is clean. Updating Specrew 0.24.2 → 0.27.0...
[update runs]
Rollback if needed:
  Uninstall-Module Specrew -RequiredVersion 0.27.0 -Force
  Install-Module Specrew -RequiredVersion 0.24.2 -Scope CurrentUser
```

**Case B — dirty working tree**:

```text
You have 14 uncommitted changes in this project.
Specrew updates can touch project templates (.specify/, .squad/, .github/).
Committing first makes the update reversible via `git revert`.

Options:
  [c] Commit current changes  (recommended — labelled "chore(specrew-update): snapshot before 0.24.2 → 0.27.0")
  [s] Stash and continue
  [i] Continue without snapshot (rollback will be harder)
  [a] Abort

Choose [c/s/i/a]:
```

Choice `c` runs `git add -A && git commit -m "chore(specrew-update): snapshot before <from> → <to>"` then proceeds. Choice `s` runs `git stash push -u -m "specrew-update-stash 0.24.2 → 0.27.0"` then proceeds (post-update message reminds the user to `git stash pop`). Choice `i` proceeds with no snapshot. Choice `a` aborts.

Post-update, regardless of choice, the rollback hint emits with the exact commands needed.

For non-interactive runs (`--autonomous`, scripts), default is `i` with a warning printed; `--pre-commit` flag forces `c`; `--no-pre-commit` forces `i` silently.

**Why this is opt-in-by-prompt rather than default-on**: not all users want auto-commits in their history. The prompt makes the choice explicit at the moment it matters.

### Pillar 5 — Agent-driven first-run explanation post-update

On the first `specrew start` after a Specrew module version change, the coordinator prompt receives an additive intro block. Detection: compare `.specrew/config.yml`'s `specrew_version` field against the loaded module's `Specrew.psd1` `ModuleVersion`. If they differ, emit:

```text
=== SPECREW VERSION CHANGE DETECTED ===

You are running Specrew 0.27.0 for the first time in this project (previously 0.24.2).

Before proceeding with the user's first request, do these in order:

  1. Read C:/Dev/SomeProject/CHANGELOG.md (or the module's CHANGELOG)
     between entries [0.25.0] and [0.27.0].
  2. Read .specrew/config.yml to understand this project's context:
     - active feature(s)
     - recent iterations
     - governance profile
     - selected host
  3. Identify 3-5 changes from the CHANGELOG that are most relevant to
     THIS project given its context. Examples of relevance:
       - If project uses --host claude, F-040 / F-043 / F-044 are directly relevant
       - If project has a heavy review burden, F-028 (Review Evidence Integrity)
         is directly relevant
       - If project has been hitting boundary-skip issues, F-039
         (Launch-Mode Boundary Enforcement) is directly relevant
  4. Surface those 3-5 to the user in a concise list and ask if they want
     (a) a fuller walkthrough, (b) to proceed with their request, or
     (c) to skip the explanation in future.

After the user acknowledges (or chooses to skip), update .specrew/config.yml's
`last_update_explained_at_version` field to 0.27.0 so this intro doesn't fire
again until the next version change.

=== END SPECREW VERSION CHANGE DETECTED ===
```

**Config flag**:

```yaml
# .specrew/config.yml
update_explanation: on  # on | off | once-per-major
last_update_explained_at_version: "0.24.2"
```

Default `on`. Power users can set `off`. Setting `once-per-major` fires only on major bumps (X.Y.Z → X+1.0.0) which today are rare.

**Why agent-driven rather than static**: the relevance filter ("which CHANGELOG entries matter to THIS project") needs project context — active feature, host selection, governance profile, iteration history. The agent has all that. A static `--info` view does not. Pillar 3 covers the unfiltered surface; Pillar 5 covers the filtered + contextualized surface.

**Cost composition with Proposal 070**: this intro consumes tokens. With 070's per-iteration cost tracking shipped (F-042), the cost of this explanation surfaces in `iterations/<NNN>/cost.yml` under a `boundary_kind: update-explanation` row. Users who find the cost not worth it can flip `update_explanation: off`.

## Architecture

### Contract surface additions

`hosts/_contract.md` grows one row:

| Function (template) | Signature | Returns | Used by |
|---|---|---|---|
| `Get-<Kind>HostVersion` | `[-ProbeMethod auto\|cli\|registry]` | `@{Installed; LatestKnown; ProbeMethod; RawOutput}` | `scripts/internal/version-check.ps1`, `specrew update --info` |

`hosts/_registry.ps1` `$script:HostContractFunctionMap` grows one entry:

```powershell
$script:HostContractFunctionMap = @{
    'NewLaunchInvocation'    = 'New-{0}LaunchInvocation'
    'ConvertFlag'            = 'ConvertTo-{0}Flag'
    'TestRuntimeInstalled'   = 'Test-{0}RuntimeInstalled'
    'GetSignals'             = 'Get-{0}Signals'
    'InstallCrewRuntime'     = 'Install-{0}CrewRuntime'   # added by 108
    'GetHostVersion'         = 'Get-{0}HostVersion'       # NEW (Proposal 110)
}
```

### Files touched

| File | Change | Pillar |
|---|---|---|
| `scripts/internal/supported-versions.yml` | Add `hosts:` block; bump schema to v2 | 2 |
| `scripts/internal/version-check.ps1` | Extend `Get-VersionMatrix` to include hosts | 1, 2 |
| `scripts/internal/changelog-parser.ps1` | NEW — CHANGELOG.md parser | 3 |
| `scripts/specrew-update.ps1` | Pre-update working-tree check + rollback hint emission | 4 |
| `scripts/specrew-start.ps1` | Detect version-change + emit intro block to coordinator prompt | 5 |
| `hosts/<kind>/handlers.ps1` (×4 host packages) | Implement `Get-<Kind>HostVersion` | 1 |
| `hosts/_contract.md` | Document new contract function | 1 |
| `hosts/_registry.ps1` | Add `GetHostVersion` to `$HostContractFunctionMap` | 1 |
| `.specrew/config.yml` schema | Add `update_explanation` + `last_update_explained_at_version` fields | 5 |
| `templates/.specrew/config.yml` (init template) | Default new fields on greenfield init | 5 |
| `tests/integration/specrew-update-multi-host.tests.ps1` | NEW — verify per-host version matrix + compatibility floor enforcement | 1, 2 |
| `tests/integration/changelog-parser.tests.ps1` | NEW — parser correctness | 3 |
| `tests/integration/specrew-update-pre-commit.tests.ps1` | NEW — working-tree-check flow | 4 |
| `tests/integration/post-update-explanation.tests.ps1` | NEW — version-change detection + intro emission | 5 |
| `docs/how-to/specrew-update.md` | New doc covering all 5 pillars | docs |
| `docs/how-to/add-a-new-host.md` | Add Step 7: "implement `Get-<Kind>HostVersion`" | docs |

## Implementation slices

Five ordered PRs, each independently shippable with tests green at every step:

| # | Slice | Pillars | SP | Risk |
|---|---|---|---|---|
| 1 | Multi-host version matrix + `Get-<Kind>HostVersion` contract function for all 4 hosts + tests | 1 | 4-5 | Med — adds contract surface; mechanical per-host implementation |
| 2 | Host compatibility floor: `hosts:` block in `supported-versions.yml`; `version-check.ps1` status logic extended; below-floor refuses launch in `specrew start --host <kind>` | 2 | 2-3 | Low — reuses Proposal 079's pattern verbatim |
| 3 | CHANGELOG parser + "what's new" excerpt in `update --info` (default summary style; `--changelog-style full` opt-in; `--no-changelog` to suppress) | 3 | 2-3 | Low — CHANGELOG.md is already well-structured |
| 4 | Pre-update working-tree check + commit/stash/continue/abort prompt + rollback hint emission post-update | 4 | 2-3 | Med — touches `specrew-update.ps1`; user-facing interactive surface |
| 5 | First-run-post-update detection + coordinator-prompt intro emission + `update_explanation` + `last_update_explained_at_version` config fields | 5 | 2-3 | Med — touches `specrew-start.ps1` coordinator-prompt assembly; needs careful test isolation |

Total: **12-17 SP** (estimate range carries to frontmatter `12-18 SP`).

### Test plan per slice

- **Slice 1**: greenfield `specrew update --info` produces the 7-row matrix (4 base + 3 detected hosts in a typical machine); per-host probe handles "host not installed" cleanly.
- **Slice 2**: simulate each status (current / below-floor / ahead-of-tested / unknown) via mocked host responses; `specrew start --host claude` refuses to launch when host version < `min`.
- **Slice 3**: parse a sample CHANGELOG.md → match expected entries; broken CHANGELOG falls back to "see CHANGELOG.md" link; `--no-changelog` suppresses.
- **Slice 4**: dirty-tree + each of `c|s|i|a` → expected end-state (commit / stash / unchanged / aborted); `--autonomous` defaults to `i` with warning; `--pre-commit` forces `c`.
- **Slice 5**: simulate version change in `.specrew/config.yml` → intro block emitted in coordinator prompt; user acknowledgement (or `config update_explanation: off`) clears the field; subsequent start has no intro.

## Composition

- **[049](049-version-check-source-unification.md)** — Provides the source-resolution chain for "LatestKnown" Specrew version. Proposal 110 extends the chain pattern to hosts: PSGallery → module manifest → tag fallback becomes (per host) host registry → host CLI `--version` → unknown.
- **[050](050-version-surface-discoverability.md)** — Provides the version banner at `init`/`start`. Proposal 110 doesn't change the banner but adds a complementary "update available" line when the version-check matrix shows `outdated` for Specrew itself.
- **[079](079-version-info-supported-vs-latest.md) (shipped)** — Source of the `supported-versions.yml` matrix + status logic. Proposal 110 extends to hosts using the same shape and same enforcement pattern. Zero new conceptual surface; pure horizontal extension.
- **[104](104-multi-host-onboarding-and-selection-flow.md) (shipped)** — Provides `.specrew/host-history.yml` and the per-host probe. Proposal 110 uses both as inputs to the multi-host matrix.
- **[108](108-specrew-init-refactor-and-crew-runtime-abstraction.md) (shipped)** — Provides the host registry + 5-function contract. Proposal 110 adds the 6th contract function (`GetHostVersion`).
- **[058](058-plugin-based-multi-host-distribution.md)** — When host packages become discoverable plugins, each plugin's manifest declares its own `compatibility: { min, max_tested, notes }`. Proposal 110's matrix is then assembled from active plugins. Composes cleanly; doesn't block.
- **[060](060-prerelease-channel-staging.md)** — Pre-release channel awareness: rollback messaging in Pillar 4 switches form based on whether the installed Specrew came from stable or beta channel. Compatible; 110 reads the channel info, 060 owns the channel mechanism.
- **[070](070-token-economy-mvp.md) (shipped as F-042)** — Pillar 5's coordinator-prompt intro consumes tokens. F-042's `iterations/<NNN>/cost.yml` records it under `boundary_kind: update-explanation` so the cost is visible. If too expensive, user flips `update_explanation: off`.
- **[075](075-update-artifact-backfill-discipline.md)** — Adjacent. 075 backfills iteration artifacts AFTER an update changes what artifacts exist. 110 manages the update process itself. They compose left-to-right: pre-commit (110 Pillar 4) → update → backfill iterations (075) → first-run explanation (110 Pillar 5).

## Open questions

1. **CHANGELOG anchor stability**: Pillar 3's parser depends on CHANGELOG.md keeping its `## [X.Y.Z] - YYYY-MM-DD` format. Should the parser also detect/warn on format drift, or just fall back to "see CHANGELOG.md"? Recommendation: fall back silently for now; add format-drift detection as a follow-up if the parser starts swallowing real content.
2. **Host version probe caching**: probing 4 host CLIs on every `specrew update --info` adds 0.5-2s wall time. Cache for 24h in `.specrew/cache/host-versions.json`? Recommendation: yes, with `--refresh` to force re-probe.
3. **Below-floor enforcement scope**: Pillar 2 says `specrew start --host claude` refuses if claude < min. Should `specrew update` ALSO refuse with the same hard-block, or only warn? Recommendation: hard-block for `start` (running on an unsupported host produces unsafe state); warn-only for `update --info` (informational; user might be running --info to discover they need to upgrade the host).
4. **`once-per-major` semantics for Pillar 5**: with current 0.X.Y versioning, what counts as "major"? Recommendation: treat minor bumps (0.X.0 → 0.X+1.0) as major until v1.0.0, then treat as proper semver. Alternative: `once-per-feature-shipped` (fires only when new features shipped, not bug-fix-only releases) — less rule, more behavior.
5. **Pre-commit prompt non-interactivity**: `--autonomous` defaulting to `i` (no snapshot) is pragmatic but unsafe — a long autonomous run could leave the user with no rollback path. Should `--autonomous` instead force `c` (auto-commit)? Recommendation: yes for `--autonomous`; the autonomous mode is already trading interactivity for unattended progress; auto-commit is consistent with that contract.
6. **Plugin-distribution timing (composes-with 058)**: should 110 wait for 058 to land so per-host compatibility lives in plugins? Recommendation: no — 110 ships against the centralized `supported-versions.yml`; when 058 ships, the data migrates to plugins as a follow-up small-fix. 110's contract surface (`GetHostVersion`) is the same either way.
7. **Detect-installed-via-Specrew vs detect-installed-globally**: Specrew may have installed the host CLI via a per-host package install path; the host may also be globally installed. Probe both? Recommendation: prefer the global PATH probe (matches what `specrew start` actually launches); fall back to per-host package install path.

## Out of scope

- **Host CLI auto-update** — Specrew detects host versions and surfaces upgrade hints; it does NOT run `claude update` / `npm install -g @openai/codex` / equivalent automatically. The user runs those manually. Auto-update is a follow-up consideration once each host's update protocol stabilizes.
- **Cross-host migration during update** — if a Specrew update changes which hosts are supported (e.g., drops Antigravity from supported list), Proposal 110 doesn't migrate the project's host selection. That belongs in Proposal 010 (Multi-Developer Reconciliation) / a future "host migration" feature.
- **CHANGELOG semantic enrichment** — Pillar 3's parser is mechanical (extract sections between version anchors). It doesn't classify entries by impact (breaking / feature / fix / docs) beyond what the CHANGELOG headers already declare. Richer semantics (e.g., "this release breaks API X") need maintainer discipline at CHANGELOG-write time; that's CHANGELOG hygiene, not update tooling.
- **Spec-Kit / Squad upgrade orchestration UX** — Proposal 110 doesn't change `specrew update --spec-kit` or `--squad` semantics beyond adding the pre-commit prompt. The two commands themselves remain as today.
- **Per-host pricing / cost-aware update suggestions** — "this Claude version increased per-token pricing, consider routing more to Copilot" is interesting but lives in Proposals 068 + 106's territory (cost routing + billing reconciliation), not here.

## Success criteria

- `specrew update --info` shows host versions alongside Specrew/Spec-Kit/Squad rows with same `Status` semantics.
- Host compatibility floor enforced: `specrew start --host claude` refuses when claude < `min`; ahead-of-tested produces an advisory warning.
- "What's new" excerpt visible inline when an update is available; CHANGELOG link shown when format unparseable.
- Pre-update working-tree check prompts for commit/stash/continue/abort; rollback hint emitted post-update regardless of choice.
- First `specrew start` after a module version change surfaces an agent-generated, project-contextualized explanation of what's new; config flag controls cadence (`on` / `off` / `once-per-major`).
- Per-host `Get-<Kind>HostVersion` contract function documented in `hosts/_contract.md` + implemented for all 4 hosts (copilot, claude, codex, antigravity).
- `scripts/internal/supported-versions.yml` schema bumped to v2 with `hosts:` block.
- New integration tests for all 5 pillars green.
