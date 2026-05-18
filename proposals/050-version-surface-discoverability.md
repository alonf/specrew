---
proposal: 050
title: Version Surface Discoverability (init/start banner + `specrew version` command)
status: candidate
phase: phase-2
estimated-sp: 3
discussion: tbd
---

# Version Surface Discoverability

## Why

Users running `specrew init` or `specrew start` have no immediate signal of which versions they're using. F-020 introduced a "module version mismatch detected" warning when versions *differ* (FR-026), but emits nothing in the happy path. Result: a downstream user has to run a separate `specrew update --info` command to discover their installed versions — extra friction at exactly the moments (init / start) when context is most relevant.

Standard CLI tools follow a different convention:

- `git --version` → just `git version 2.42.0`
- `node --version` → just `v20.10.0`
- `dotnet --version` → just `8.0.100`
- `python --version` → just `Python 3.12.0`

A simple banner at init/start plus a dedicated `specrew version` command closes that gap. Together they answer "what versions am I running?" with minimal friction at the most-likely query moments.

## What

### Pillar 1: Version banner at `specrew init` and `specrew start`

Emit a single informational line near the top of init/start output:

```
Specrew 0.20.0 | Spec Kit 0.8.11 | Squad 0.9.4
```

- Always displayed (no flag needed)
- Stream: `Write-Output` (capturable, per the F-020 retro Lesson #2 about stream-capture observability)
- Single line, no extra formatting; users who want more detail run `specrew update --info`
- Suppressible via `--quiet` flag (composes with proposal 047's `ci_suppress_prompts` dial)

### Pillar 2: New `specrew version` shell command

A dedicated command that returns just the version info, machine-parseable:

```
PS> specrew version
Specrew 0.20.0 | Spec Kit 0.8.11 | Squad 0.9.4

PS> specrew version --json
{"specrew": "0.20.0", "speckit": "0.8.11", "squad": "0.9.4"}

PS> specrew version --short
0.20.0
```

Three output modes:

| Flag | Output | Use |
|---|---|---|
| (default) | `Specrew X | Spec Kit Y | Squad Z` | Interactive query |
| `--json` | Structured JSON | Scripted consumption |
| `--short` | Just the Specrew version | `$version = specrew version --short` in scripts |

### Pillar 3: `/specrew.version` slash command

Already in Proposal 032's catalog. This proposal does not change 032's scope; once 032 ships, `/specrew.version` invokes the new `specrew version` shell command. Listed here for cross-reference only.

### Why a separate command instead of aliasing `specrew update --info`

Alias proposal considered and rejected. Reasons:

- `specrew update --info` shows the rich table (current vs latest, source, status) — useful for upgrade decisions
- `specrew version` shows just the versions — useful for "what am I running?"
- Different use cases, different audiences, different output expectations
- Standard CLI convention is a dedicated `version` command separate from update/upgrade commands

Both commands stay available, sharing the underlying version-resolution helper from `scripts/internal/version-check.ps1` (the helper F-020 extracted).

## Effort

~3 SP, single iteration. Roughly:

- Add a `Get-SpecrewVersionBanner` helper in `scripts/internal/version-check.ps1` that returns the three-platform formatted string (~0.5 SP)
- Wire the banner into `specrew-init.ps1` and `specrew-start.ps1` near the top of their output (~0.5 SP)
- Implement the new `specrew version` command in the main entrypoint (`Specrew.psm1` or wherever Invoke-Specrew dispatches) with `--json` and `--short` flags (~1 SP)
- Integration tests: confirm banner appears at init + start, confirm `specrew version` with each flag produces expected output (~0.5 SP)
- Documentation: brief update to README, getting-started, and docs/dashboard-guide (~0.5 SP)

## Phase placement

**Phase 2, fast follow-up to F-020.** Slots tightly into the post-F-020 queue alongside 049 (version-check source unification — same helper).

Sequencing options:

- **Option A**: ship as standalone small feature (~3 SP) immediately after F-020 — quick win, low risk.
- **Option B (recommended)**: combine with proposal 049 into a single "Version surface refresh" feature (~6 SP). Both touch the same version-check helper; combining minimizes code-touching churn.
- **Option C**: combine with proposal 032 (slash commands) — the `/specrew.version` slash command is already in 032's catalog; if this ships first, 032 wires it up; if 032 ships first, this proposal becomes purely shell-side.

Recommended: **Option B** (combine with 049). Together ~6 SP, all version-display work in one feature.

## Open questions

1. **Banner placement**: at the very top of init/start output, or after the welcome message? Top maximizes discoverability; after-welcome reduces visual clutter at the most-prominent position.
2. **Banner format**: single line `Specrew X | Spec Kit Y | Squad Z` (recommended) vs three lines vs table format?
3. **CI suppression**: composes with proposal 047's `ci_suppress_prompts` dial — should the banner be suppressed in CI by default, or always shown?
4. **Color**: render with the platform-name dimmed and version-number bright for visual hierarchy? Or plain text? Composes with F-018 visual-richness work.
5. **`--short` semantics**: returns just the Specrew version (`0.20.0`) or all three space-separated (`0.20.0 0.8.11 0.9.4`)? Recommend Specrew-only since `--short` implies a single value for scripting.
6. **Pre-1.0 prefix**: should the banner indicate pre-1.0 status (e.g., `Specrew 0.20.0-pre1.0`)? Probably not — semver pre-release tags would be ugly; the simple version number is enough.
7. **Squad version resolution**: how does `specrew version` resolve the Squad version on a downstream project where Squad is installed as an extension? Same path as `specrew update --info` uses today.
8. **Banner caching**: should the banner cache the resolved versions for the session to avoid re-computing on every command? Probably yes — once-per-session is enough.
9. **`specrew --version` (with double-dash flag)**: should this also work as an alias for `specrew version`? GNU convention says yes. Implementing it costs nothing extra.

## Risks

- **Output clutter at init/start**: adding another line to already-verbose output. Mitigation: single concise line; can be suppressed via `--quiet`. The banner is small; the benefit (always-visible version) outweighs the cost.
- **Format drift between `version` and `update --info`**: two commands showing version info could drift if not sharing the helper. Mitigation: both use `Get-SpecrewVersionBanner` from `scripts/internal/version-check.ps1`.
- **Scripted-parser breakage**: anyone scripting against init/start output might break if a new line appears. Mitigation: the banner is added in a stable position; if it's at the top, scripts grepping for specific strings further down still work.
- **Banner emission timing on slow networks**: if version resolution touches PSGallery (per proposal 049), and PSGallery is slow, the banner could delay init/start startup. Mitigation: resolve versions ASYNCHRONOUSLY or use cached/offline-first sources; PSGallery is the SLOWEST path so version-check should not depend on it for the banner.

## Cross-references

- **Proposal 035 / F-020 (Session-State Durability)** — extracted the version-check helper this proposal builds on
- **Proposal 049 (Version-Check Source Unification)** — recommended combination target; shares the same helper
- **Proposal 047 (Project Governance Profile)** — `ci_suppress_prompts` dial composes with banner suppression
- **Proposal 032 (Specrew Slash-Command Surface)** — `/specrew.version` slash command is already in 032's catalog; this proposal makes the shell-side command it wraps
- **Proposal 046 (Auto-Render Dashboard)** — dashboard rendering at closeout could include the version banner; complementary not competing
- **Proposal 048 (Dashboard Velocity Metric Refinement)** — composes; the dashboard renderer already touched by 046+048 can include the version banner

## Status history

- 2026-05-18: candidate captured after maintainer observed that `specrew init` and `specrew start` don't display version information by default; running `specrew update --info` is required to discover installed versions. Standard CLI convention (`git --version`, `node --version`, etc.) is a dedicated `version` command — Specrew lacks one. Both gaps close with the same small feature.
