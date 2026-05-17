---
proposal: 037
title: PSScriptAnalyzer Lint Cleanup
status: candidate
phase: phase-2
estimated-sp: 7
discussion: tbd
---

# PSScriptAnalyzer Lint Cleanup

## Why

Surfaced 2026-05-18 during F-019 PR #189 CI investigation: the repo-wide CI "test" lane runs `Invoke-ScriptAnalyzer -Settings PSGallery` over all `*.ps1` files and reports ~30-50+ Warning-level findings across 7+ scripts. These are pre-existing — NOT introduced by F-019 — but contribute to the chronic CI-red baseline noted in [project_ci_watchdog_and_recurrence_prevention_2026_05_16] memory.

The verb-conformance pattern already shipped for `Specrew.psm1` module exports during F-019 closeout (commit `7b08dfd`). This proposal applies the same pattern to internal scripts so the repo shows green by default for first-time contributors.

## What

### Findings inventory (from PR #189 run `25996392712`)

Categorized by file:

- **`extensions/specrew-speckit/validators/handoff-governance-validator.ps1`**: ~6× `PSUseSingularNouns` (e.g. functions named `Get-Sections` should be `Get-Section`)
- **`extensions/specrew-speckit/scripts/deploy-speckit-extension.ps1`**: 2× `PSUseApprovedVerbs` (`Deploy-*` not on approved list — use `Publish-*` or `Install-*`)
- **`extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1`**: `PSUseApprovedVerbs`, multiple `PSUseShouldProcessForStateChangingFunctions`, `PSUseSingularNouns`
- **`extensions/specrew-speckit/scripts/drift-diff.ps1`**: `PSUseSingularNouns`
- **`extensions/specrew-speckit/scripts/manage-escalation-state.ps1`**: `PSUseShouldProcessForStateChangingFunctions`
- **`extensions/specrew-speckit/scripts/manage-reviewer-regression.ps1`**: multiple `PSUseApprovedVerbs` (`Manage-*` not approved — use `Set-*`/`Update-*`), multiple `PSUseShouldProcessForStateChangingFunctions`, multiple `PSUseSingularNouns`
- **`extensions/specrew-speckit/scripts/resolve-quality-profile.ps1`**: multiple `PSUseShouldProcessForStateChangingFunctions`

(Full inventory: run `Invoke-ScriptAnalyzer -Path . -Recurse -Settings PSGallery` locally before scoping iteration 1.)

### Cleanup approach

- Rename functions with non-approved verbs (e.g., `Deploy-*` → `Publish-*` / `Install-*`; `Manage-*` → `Set-*` / `Update-*`)
- Rename functions with plural nouns to singular form (`Get-Sections` → `Get-Section` etc.)
- Add `[CmdletBinding(SupportsShouldProcess)]` + `$PSCmdlet.ShouldProcess(...)` gates to state-changing functions
- Provide deprecation aliases for any externally-referenced functions so consumers don't break

### Out of scope

- Reformatting / style-only changes that don't address an analyzer finding
- New functionality
- Public-API surface changes beyond the renames (the module export surface was already fixed in F-019's verb-conformance commit)

## Effort

- **Iteration 1** (~3-4 SP): full inventory + low-risk renames + `[CmdletBinding(SupportsShouldProcess)]` on internal helpers
- **Iteration 2** (~3-4 SP): high-touch renames with deprecation aliases + integration test verification

Could combine into a single ~5-8 SP iteration if call-site graph is small enough.

## Phase placement

**Phase 2**, after [035](035-session-state-durability.md). Not load-bearing for public flip (lint warnings don't block users), but should ship before GA so the repo shows clean by default for first-time contributors.

## Open questions

1. Reasonable to combine into one iteration or keep split? Depends on call-site count for high-touch renames.
2. Should deprecation aliases stay forever or be removed on a major version bump?
3. Run analyzer in CI as a strict gate (any finding fails build) after cleanup, or keep as advisory?
4. Compose with [004](004-validator-hardening.md) into a single "static-quality lift" iteration, or keep separate?

## Risks

- **External-reference breakage**: renaming `Deploy-*` or `Manage-*` functions could break downstream scripts that call them. Mitigation: deprecation aliases for at least one release cycle.
- **Test brittleness**: tests asserting function-name regex patterns will need updates alongside renames.

## Cross-references

- Sibling of [004](004-validator-hardening.md) (could fold in if cleanup naturally requires validator gap fixes)
- Sibling of [034](034-markdown-lint-strict-defaults-restoration.md) (similar "restore clean lint baseline" goal, different toolchain)
- Composes with [008](008-nfr-governance.md) (lint conformance is an NFR baseline candidate)

## Status history

- 2026-05-18: captured during F-019 PR #189 CI investigation; promoted to candidate proposal
