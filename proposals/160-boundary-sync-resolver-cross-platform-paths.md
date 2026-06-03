---
proposal: 160
title: Cross-Platform Path Resolution in the Boundary-Sync Module Resolver (Unix `\`-Separator Fix)
status: candidate
phase: phase-2
estimated-sp: 2-5
discussion: surfaced 2026-06-03 during Feature 140 closeout — the deployed boundary-sync wrapper resolved the INSTALLED 0.30.0 module over the 0.31.0 dev tree and hard-refused (stale-install guard), even when invoked from the dev tree; the Path-1 dev-tree walk-up "should have matched but didn't" and required a manual `$env:SPECREW_MODULE_PATH` override. Root-cause candidate: the resolver builds candidate paths with hardcoded backslash separators, which break Path 1 (dev-tree walk-up) and Path 2 (installed module) on Unix — a latent portability bug in Feature 140's own (Unix-native) domain.
---

# Cross-Platform Path Resolution in the Boundary-Sync Module Resolver

## Why

The deployed boundary-sync wrapper (`extensions/specrew-speckit/scripts/sync-boundary-state.ps1`,
mirrored to `.specify/extensions/.../sync-boundary-state.ps1` in every downstream project)
resolves the actual internal helper through three ordered paths:

0. `$env:SPECREW_MODULE_PATH` override
1. Dev-tree walk-up from `$PSScriptRoot` (looking for a dir with both `.specrew/config.yml` and `scripts/internal/sync-boundary-state.ps1`)
2. Installed Specrew module (highest version wins)

Every one of those builds its candidate path with **hardcoded backslash separators**:
`Join-Path $x 'scripts\internal\sync-boundary-state.ps1'` and
`Test-Path (Join-Path $searchRoot '.specrew\config.yml')`. On Windows this is fine. On Unix,
PowerShell does **not** rewrite an embedded `\`, so `Test-Path -LiteralPath` of
`/repo/scripts\internal\sync-boundary-state.ps1` looks for a literal file whose name contains a
backslash → `$false`. The consequence on Linux/macOS:

- **Path 1** (dev-tree walk-up) can never match → dev-tree dogfooding silently falls through.
- **Path 2** (installed module) can never match either → the wrapper throws "Unable to locate
  the internal sync-boundary-state helper" for *real downstream Unix projects* that rely on the
  deployed wrapper (the path the coordinator prompt explicitly tells downstream agents to use
  when the sync-* agents aren't wired up).

This is a latent portability bug in the exact domain Feature 140 shipped (Unix-native install +
native `specrew` surface). It likely went unnoticed because the maintainer's normal flow goes
through the module function (`Invoke-Specrew` → `scripts/internal/sync-boundary-state.ps1`
directly), not the standalone deployed wrapper, and the Linux beta validated interactive
`specrew start`, not a full hand-driven boundary-sync.

## Evidence

`extensions/specrew-speckit/scripts/sync-boundary-state.ps1`:

- Path 0 (~L53): `Join-Path $env:SPECREW_MODULE_PATH 'scripts\internal\sync-boundary-state.ps1'`
- Path 1 (~L65–66): `Join-Path $searchRoot 'scripts\internal\sync-boundary-state.ps1'` and `Test-Path (Join-Path $searchRoot '.specrew\config.yml')`
- Path 2 (~L89): `Join-Path $specrewModule.ModuleBase 'scripts\internal\sync-boundary-state.ps1'`

The resolved *target* (`scripts/internal/...`) is fine; the bug is purely in the **resolver's
candidate-path construction**. The stale-install version refusal further down (~L112–146) is
correct behavior (it protects against silently running a stale module against a newer project —
the Feature 044 iter-006 incident) and is **out of scope** for this proposal.

Observed (Windows, F-140 closeout): boundary-sync resolved the installed 0.30.0 module over the
0.31.0 dev tree and refused even when run from the dev tree; required
`$env:SPECREW_MODULE_PATH='<dev-tree>'`. Backslashes resolve on Windows, so the Unix bug above
does **not** explain the Windows symptom — see Open questions.

## What

- Normalize all candidate-path construction in the resolver to be cross-platform: multi-segment
  `Join-Path` (`Join-Path $x 'scripts' 'internal' 'sync-boundary-state.ps1'`) or
  `[IO.Path]::Combine`, so the same code resolves on Windows **and** Unix. Apply to Path 0, 1,
  and 2 (and the `.specrew/config.yml` probe). Keep source + `.specify` mirror in parity.
- Add a resolver test that runs on the Ubuntu + macOS CI lanes and asserts the helper resolves
  via Path 2 (installed-module shape) and Path 1 (dev-tree shape) on POSIX paths.
- Root-cause the Windows walk-up miss (Open questions) and cover it.

## Scope / Non-goals

- No change to the stale-install version guard (it behaves correctly).
- No change to resolution precedence (0 → 1 → 2).

## Acceptance criteria

- AC1: On Unix, the deployed wrapper resolves the helper via Path 2 when a module is installed
  (no false "unable to locate").
- AC2: On Unix, the wrapper run from inside a Specrew dev tree resolves via Path 1 (dev-tree
  preferred over an older installed module) without needing `$env:SPECREW_MODULE_PATH`.
- AC3: Windows behavior unchanged (no regression); the F-140 walk-up miss is reproduced and
  fixed, or proven to be an invocation-path expectation (not a bug) and documented.
- AC4: The cross-platform resolver test runs in CI (Ubuntu + macOS).

## Open questions

The F-140 Windows symptom (Path-1 not matching from the dev tree) is unexplained because
backslashes resolve on Windows. Confirm during the slice which applies: (a) the wrapper was
invoked through the module function, which imports the **installed** module and runs *its* copy
— whose `$PSScriptRoot` is under the installed module, so the walk-up never reaches the dev tree
and Path 2 is selected *by design*, not a bug; or (b) a genuine walk-up edge case. The repro
must establish which before any Windows-side change.

## Effort + phasing

- ~2–5 SP. The separator normalization is small and low-risk (safe on Windows, fixes Unix); the
  Windows root-cause + the cross-platform CI test are the bulk.
- **Feature-140 fast-follow** (Unix-native domain). Sequence after the F-140 closeout settles.

## Relationships

- Sibling to Proposal [159](159-specrew-update-module-staleness-guard.md) — same staleness /
  resolution area; 159 fixes the `specrew update` silent downgrade, this fixes the boundary-sync
  **resolver's** path portability. Scope them together if convenient.
- Feature 140 fast-follow (Unix-native install + native `specrew` command surface).
- Composes with the boundary-sync stale-install guard (unchanged).
