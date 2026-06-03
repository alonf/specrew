---
proposal: 159
title: Make `specrew update` Module-Staleness-Aware (Downgrade Guard + Optional Self-Update)
status: candidate
phase: phase-2
estimated-sp: 3-13
discussion: surfaced 2026-06-03 during Feature 141 self-host when `specrew update`, run against a stale 0.30.0 installed module in a project whose config expected 0.31.0, silently DOWNGRADED the project (`.specrew/config.yml` `specrew_version` 0.31.0 -> 0.30.0 + `.specify/extensions/**`) instead of updating the module. The fix to actually upgrade the module is the separate cmdlet `Update-Module Specrew`.
---

# Make `specrew update` Module-Staleness-Aware (Downgrade Guard + Optional Self-Update)

## Why

`specrew update` is a **project asset re-sync**: it re-deploys `.specify`/`.squad`
surfaces and refreshes templates **from the Specrew module that is currently running the
script**, then writes `.specrew/config.yml`'s `specrew_version` to **that running module's
version**. It does **not** update the Specrew PowerShell module itself — when a newer module
is published it only prints an advisory (`WARN: Newer version available … To update:
Update-Module Specrew`).

Two problems follow:

1. **Silent downgrade on a stale install (the acute bug).** If the installed/resolved module
   is *older* than the version the project's `config.yml` records (e.g. after merging a release
   that bumped the project to 0.31.0 while the machine still has 0.30.0 installed), `specrew
   update` rewrites the project *backward* to the old module — config version and the deployed
   `.specify` extension — with no guard and no warning that it is downgrading. Observed
   2026-06-03: a 0.31.0 project was rewritten to 0.30.0 by a single `specrew update`.

2. **Asymmetry that surprises users.** For **Spec Kit** and **Squad**, `specrew update`
   *does* auto-install the newer version (via `uv tool install` / `npm install -g`). For
   **Specrew itself** it does not — so `specrew update --all` upgrades the dependencies but
   leaves the core module behind, and the user must separately discover and run
   `Update-Module Specrew`. The name "update" implies currency it does not deliver for the
   one component it is named after.

This also puts `specrew update` in direct conflict with the **boundary-sync stale-install
guard**: boundary-sync *hard-refuses* when the project's recorded version exceeds the resolved
module ("Stale Specrew install — boundary-sync dispatch refused"), protecting the project;
`specrew update` quietly walks the same project *backward* into that stale state. The two
commands should agree.

## Evidence (current behavior, `scripts/specrew-update.ps1`)

- Deploys from the running module: `$repoRoot = Split-Path -Parent $PSScriptRoot`; re-runs
  `deploy-speckit-extension.ps1` + `deploy-squad-runtime.ps1` + `Invoke-TemplateRefresh`
  (the Specrew scope block).
- Writes config to the running module's version: `Update-SpecrewConfig … -SpecrewVersion
  $sourceSpecrewVersion`, where `$sourceSpecrewVersion = Get-ExtensionVersion` of the running
  module's `extension.yml` — written **unconditionally**, with no comparison to the project's
  prior recorded version (no downgrade guard).
- Dependency auto-upgrade is Spec-Kit/Squad-only: `Install-PlatformVersion` declares
  `[ValidateSet('Spec Kit','Squad')]` — Specrew is deliberately excluded.
- Newer-module detection exists but is advisory only: `Get-PSGalleryUpdateWarning` /
  `Get-PSGalleryLatestVersion` (`scripts/internal/version-check.ps1`, `Find-Module -Repository
  PSGallery`) print `Newer version available … To update: Update-Module Specrew`.

The exclusion is not arbitrary: a loaded PowerShell module cannot cleanly replace *itself*
in-process (it would overwrite the files the running process has loaded), whereas Spec Kit and
Squad are external CLIs (uv/npm) and safe to upgrade mid-run. Any self-update therefore needs
an out-of-process step.

## What

Make `specrew update` aware of module staleness, in two tiers (ship Tier 1 regardless; Tier 2
is optional and larger).

### Tier 1 — Downgrade guard (the bug fix; small, defensive)

- Before re-deploying the Specrew scope, compare the running module's version to the project's
  recorded `specrew_version`. If the running module is **older**, **refuse** to rewrite the
  project: do not deploy older assets, do not downgrade `config.yml`. Emit an actionable
  message: "Installed module X is older than this project's recorded Y; run `Update-Module
  Specrew` (or set `$env:SPECREW_MODULE_PATH` to a matching dev tree) first." This mirrors the
  boundary-sync stale-install guard so the two commands agree.
- Equal/newer running module: behave as today.

### Tier 2 — Optional in-place self-update (the user's suggestion)

- Add a `--self-update` (and `--all` participation) path: when a newer Specrew module is
  detected on PSGallery, run `Update-Module Specrew` in a **child process**, then **re-dispatch**
  the deploy from the now-current module — the same child-process re-dispatch pattern Feature
  140 used for interactive-start. This makes `specrew update --self-update` a true one-command
  "get current + redeploy."
- Keep it opt-in (not the bare-`specrew update` default) so a plain re-sync never reaches out to
  install software unprompted.

## Scope / Non-goals

- No change to the boundary-sync guard (it already behaves correctly).
- No change to the Spec Kit / Squad auto-upgrade behavior.
- Tier 1 must never *upgrade* silently either — it only refuses to *downgrade*; upgrading the
  module stays an explicit user action (Tier 2 opt-in or `Update-Module Specrew`).

## Acceptance criteria

- AC1: `specrew update` against a stale (older) installed module in a project recording a newer
  version **refuses** and does not modify `config.yml` or `.specify`; exit non-zero with the
  remediation message.
- AC2: `specrew update` with an equal/newer module behaves exactly as today (no regression).
- AC3 (Tier 2, if shipped): `specrew update --self-update` with a newer published module updates
  the installed module out-of-process and then redeploys from it; `specrew version` afterward
  shows Installed == Project baseline.
- AC4: tests cover the downgrade-refusal, the no-regression equal/newer path, and (Tier 2) the
  self-update re-dispatch.

## Effort + phasing

- Tier 1 (downgrade guard + tests): ~3-5 SP. Recommended near-term — it is a real
  data-integrity bug (silent project downgrade).
- Tier 2 (self-update re-dispatch + tests): ~8 SP. Optional; schedule with other CLI-ergonomics
  work.

## Relationships

- Composes with the boundary-sync stale-install guard (this makes `specrew update` consistent
  with it).
- Reuses the Feature 140 child-process re-dispatch pattern (interactive-start) for Tier 2.
- Related operational notes captured in the self-host lifecycle mechanics (the
  `specrew update` ≠ `Update-Module Specrew` distinction).
