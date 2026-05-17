---
proposal: 031
title: Specrew Distribution Module (PowerShell Gallery)
status: shipped
phase: phase-2
estimated-sp: 27
discussion: tbd
shipped-as: feature-019
---

# Specrew Distribution Module (PowerShell Gallery)

## Why

Specrew today distributes as a Git repository. Users wanting to try Specrew must:

1. Clone the repo locally
2. Manually add `<repo>/scripts/` to `$PATH`
3. Run `specrew init` in their project
4. Repeat for every update (no clean version semantics)

Empirical evidence: an early contributor hit the clone-and-PATH friction first try. The install step was the highest-cost piece of his onboarding. Before Specrew goes public, this friction must disappear — otherwise every visitor who arrives at the public repo will bounce off the install step before encountering the methodology's value.

PowerShell Gallery is the idiomatic distribution path for PowerShell-native tools. A Specrew module published there gives users a one-line install:

```powershell
Install-Module Specrew -Scope CurrentUser
```

Cross-platform via PowerShell 7+. Clean versioning. Updates via `Update-Module Specrew`.

This proposal establishes Specrew as a real installable tool, removing the highest-friction onboarding step before the public flip.

## What

A PowerShell Gallery module that bundles everything Specrew distributes — scripts, validator extensions, coordinator prompts, templates for `.specify/` / `.squad/` / `.github/` surfaces, reference documentation. The existing `specrew init` command is updated to bootstrap user projects by copying templates from the installed module's path.

### Five pillars

1. **PowerShell module packaging** — manifest (`Specrew.psd1`), entry point (`Specrew.psm1`), exported functions, target pwsh 7+, no external runtime dependencies
2. **Template + resource bundling** — module folder contains scripts, extensions, all templates the `specrew init` command needs to bootstrap a user project
3. **`specrew init` bootstrap from module** — existing init script resolves template sources from the module install path; copies into user project on first run
4. **Update story** — `specrew update` template-refresh pass keeps user projects current with template improvements while preserving user-edited files
5. **Publishing + versioning** — `Publish-Module` integrated into Rule 15 feature-closeout sequence; signed releases via GitHub Actions on every v*.* tag push

### Post-feature user experience

```powershell
# Install once
Install-Module Specrew -Scope CurrentUser

# Bootstrap any project
cd C:\my-project
specrew init

# Use the methodology
specrew start
specrew where

# Update later
Update-Module Specrew
specrew update     # template-refresh into existing projects
```

That replaces the current clone-and-PATH friction with idiomatic PowerShell ergonomics.

## Effort

Two-iteration feature (~25-30 SP total).

- **Iteration 1** (~10-15 SP): Windows-correct module structure, PSGallery package built and validated locally, `specrew init` / `specrew start` / `specrew where` / `specrew update` work end-to-end on Windows post-install. PSGallery publish workflow EXISTS but is GATED — does not fire until Iteration 2 verifies cross-platform.
- **Iteration 2** (~10-15 SP) — Cross-Platform Hardening: sweep all PowerShell scripts for embedded `\` in path strings (104+ sites observed across 7 entry-point scripts), replace with multi-arg `Join-Path` or forward slashes. End-to-end verification on Linux (Ubuntu via WSL) using Copilot CLI as the test harness. Add `.github/workflows/cross-platform-validation.yml` running validator + integration tests on `ubuntu-latest` (macOS optional, cost-dependent). README + `docs/getting-started.md` updated to claim "Tested on Windows + Linux (Ubuntu via WSL)" replacing the implicit Windows-only baseline. First real PSGallery publish fires at Iteration 2 feature-closeout.

Rationale for the split: shipping a Windows-only PowerShell module to PSGallery as v1 would deliver a broken first impression to Linux/macOS users who run `Install-Module Specrew` and hit file-not-found errors from literal backslash paths. Iteration 1 builds confidence on Windows; Iteration 2 graduates the module to cross-platform-verified before its first public publish.

## Phase placement

**Phase 2, pre-public-flip priority** — slots between F-006 (Phase 1 trilogy closure) and Branch Reconciliation (state-foundation pillar) in the Quality Hardening Bundle sequencing.

Rationale:
- Small scope fits as a single-day Monday-Tuesday slot
- Load-bearing for public flip — visitor first-impression equity depends on one-line install working
- Composes with the Methodology Site (queued) which can link to PSGallery install instructions
- Doesn't depend on other queued features; can ship independently

## Open questions

1. Update story pattern (no auto-update / template-refresh / scripts-from-module-only)?
2. PSGallery only for v1, or also winget / Chocolatey / Scoop?
3. Module name claim: `Specrew` exact?
4. PSGallery API key management (GitHub Actions secret vs maintainer-local)?
5. Module signing (self-sign vs codesign cert)?
6. Backward compatibility with clone-and-PATH (support indefinitely or deprecate)?
7. Template-update conflict resolution (overwrite / skip / 3-way-merge / preserve-and-flag)?
8. Cross-platform path handling (Windows `\` vs Linux/Mac `/`)?
9. Module version policy (same as repo or separate)?
10. Migration path for existing alpha users (manual or tooling)?

## Risks

- **PSGallery name squatting**: if `Specrew` is already taken, fallback names needed. Mitigation: claim the name before public flip.
- **Template-update conflicts**: user-edited template files might conflict with updated versions. Mitigation: preserve-and-flag pattern with explicit diff for human resolution.
- **Maintainer overhead**: every Rule 15 release now includes a `Publish-Module` step. Mitigation: CI/CD automation; humans don't run the publish manually.
- **Signing complexity**: PSGallery code-signing requirements add setup overhead. Mitigation: self-sign for v1; revisit for v1.0+.

## Cross-references

- Proposal 009 (Velocity Dashboard) — composes; dashboard help text would update to mention module install
- Proposal 013 (Methodology Site) — composes; site documents `Install-Module Specrew` as the canonical install path
- Proposal 030 (Quality Hardening Bundle) — Distribution sequences alongside the bundle; benefits from the bundle's quality machinery

## Status history

- 2026-05-16: candidate captured after early-contributor onboarding-friction feedback identified clone-and-PATH as the highest-cost step before public flip
