# Iteration 003 Scope

**Feature**: F-044 | **Iteration**: 003 — Manual-Test Repair Slice

## Bug-by-bug closure

| Bug | Description | Fix | File(s) |
|---|---|---|---|
| 2 | `specrew-iteration-resume` SKILL.md missing YAML frontmatter — Claude + Antigravity rejected the skill on load | Added YAML frontmatter (`name`, `description`, `domain`, `confidence`, `source`) matching the 3 other generic skills' shape | `extensions/specrew-speckit/squad-templates/skills/iteration-resume.md` |
| 5 | Bootstrap "Usage Flow" + Next-Steps message hardcoded Squad terminology ("Squad drives", "Squad agent", "Keep block intact in .squad/team.md") on every host | Rewrote message to host-agnostic Crew language; canonical team customization location surfaced as `.specrew/team/agents/`; added explanation of per-host translation flow | `scripts/init/post-bootstrap-output.ps1` |
| 7c | `run-hardening-gate.ps1` first-run failure: `Cannot bind argument to parameter 'ExistingLines' because it is null` when gate file doesn't exist yet | Replaced if-as-expression assignment with explicit branches + `[string[]]@()` cast + defensive null-coerce. PowerShell strict mode can drop empty-array values returned from `if/else` expressions. | `extensions/specrew-speckit/scripts/run-hardening-gate.ps1` |
| 7b | `scaffold-retro-artifact.ps1` throws hard if iteration plan lacks a Phase Baseline table (which happens when an agent writes the plan by hand instead of using `scaffold-iteration-plan.ps1`) | Replaced the throw with a `Write-Warning` + TBD-row fallback. Retro can still scaffold; variance shows TBD instead of failing the whole iteration close. | `extensions/specrew-speckit/scripts/scaffold-retro-artifact.ps1` |
| 7d | `scaffold-feature-closeout-dashboard.ps1`: caller passed `-PassThru` to `sync-boundary-state.ps1` which doesn't accept that flag → error: "A parameter cannot be found that matches parameter name 'PassThru'." | Removed the stray `-PassThru` from the inner call (output already piped to `Out-Null`). Also tolerate `-FeatureId 001` numeric-only IDs by prefix-matching `specs/001-*` when the exact path is absent. | `extensions/specrew-speckit/scripts/scaffold-feature-closeout-dashboard.ps1` |

## Already-fixed on branch (no-op, noted in retro)

| Bug | Why | Where |
|---|---|---|
| 7a | Codex `--allow-all` → `--full-auto` flag rejected. User's test loaded stale 0.24.1 PSGallery install (dual-module-load visible in test output). Current branch returns `--dangerously-bypass-approvals-and-sandbox`. | `hosts/codex/handlers.ps1:101` |

## Out of iter-003 scope (queued)

| Bug/Concern | Vehicle | Why deferred |
|---|---|---|
| 1: `specrew start` no-`--host` should show interactive menu (1/2/3) | Separate small-fix slice OR Proposal 063 | UX improvement, not a regression; needs design (how to fall back when stdin is not a TTY) |
| 3: Codex stops in fewer places, no clarify questions | Proposal 063 Substantive Intake Questioning + Proposal 065 Launch-Mode Boundary Enforcement | Methodology-deep — host autopilot bypasses prose handoffs; requires tool-protocol layer |
| 4: Claude finishes without presenting closeout/iteration-approval menu | Same — Proposal 063 / 065 | Same root cause |
| 6: Only Squad shows concurrent per-mission agent dispatch | Proposal 024 Category D (per-host coordinator overlay translation) | Already documented as out-of-scope in F-044 [spec.md](../../spec.md) |
| 7e: Copilot "Failed to load 3 skills" beyond `iteration-resume` | Investigation needed | Copilot may validate more strictly than Claude/Antigravity; only `iteration-resume` was named in the warning — needs reproduction with newest Copilot CLI to identify the other 2 |
| 8: Copilot very slow | External — user hit weekly quota | Aligns with Proposal 068 cost-aware routing (URGENT) |
| Dual-module-load (0.24.1 + 0.26.0 in `Get-Module` simultaneously) | Investigation; possibly `specrew update` UX fix | Not a Specrew bug per se; PSGallery + Dev-tree coexistence quirk |

## Implementation commit

iter-003 ships as a single focused commit. Mirror of iter-002's pattern: a fix slice that closes the immediately-actionable bugs from the prior boundary's review.
