---
proposal: 049
title: Version-Check Source Unification (Replace origin-tags with Module-Manifest + PSGallery)
status: candidate
phase: phase-2
estimated-sp: 3
discussion: tbd
---

# Version-Check Source Unification

## Why

`specrew update --info` currently uses `origin-tags` as the source for "LatestKnown" Specrew version. Tags lag behind the actual module version because we ship version bumps to `Specrew.psd1` `ModuleVersion` without tagging until a public release. This produces three concrete bugs:

1. **Stale LatestKnown**: project says it's at 0.19.0, latest tag is v0.18.0, but the actually-loaded module is at 0.20.0. The user has no signal that 0.20.0 is available.

2. **Logically inverted status**: `Current 0.19.0 > LatestKnown 0.18.0` and Status reports "current" — but the project IS behind the actually-loaded module. The comparison is against the wrong source.

3. **Misleading "current" verdict**: downstream projects (like a freshly-bootstrapped consumer) get told they're "current" when they're actually missing an available upgrade. This is exactly the UX gap F-020 was supposed to close — but F-020 only fixed the warning path at `specrew start` / `specrew init`, not `specrew update --info`.

**Reproduction** (observed 2026-05-18 on Linux WSL):

```
PS /home/alon/projects/Moment20> Import-Module $HOME/projects/specrew/Specrew.psd1 -Force
PS /home/alon/projects/Moment20> specrew update --info
Platform Current LatestKnown Status  Source
-------- ------- ----------- ------  ------
Specrew  0.19.0  0.18.0      current origin-tags
Spec Kit 0.8.11  0.8.11      current github-tags
Squad    0.9.4   0.9.4       current npm
```

Expected: Specrew row should show `Current 0.19.0 | LatestKnown 0.20.0 | Status outdated | Source module-manifest` and surface the available upgrade.

## What

Unify the Specrew version-check source with the helper F-020 extracted to `scripts/internal/version-check.ps1`. `specrew update --info` should consult the same logic as `specrew start` / `specrew init` so that all three commands report consistent results.

### Source resolution chain (in precedence order)

For determining "LatestKnown" Specrew version:

1. **PSGallery published version** (when available) — authoritative for downstream consumers installed via `Install-Module Specrew`. Cached daily per FR-029.
2. **Loaded module's `Specrew.psd1` `ModuleVersion`** — authoritative for users running from a local clone or pre-PSGallery deployment. Always available because the module IS loaded.
3. **`origin-tags` fallback** — last-resort signal when neither PSGallery nor module manifest can be read (e.g., corrupted manifest, network failure on PSGallery, no module imported).

Drop the current default of `origin-tags`. It's only correct when the maintainer manually tags every version, which won't happen for in-development states.

### Status logic correction

Replace the current `Current >= LatestKnown → "current"` with proper three-way comparison:

| Current vs LatestKnown | Status |
|---|---|
| Current == LatestKnown | `current` |
| Current < LatestKnown | `outdated` (with recommended action: `specrew update --spec-kit` or `Update-Module Specrew` depending on install path) |
| Current > LatestKnown | `ahead-of-known` (development pre-release; suggest tagging or PSGallery publish) |
| Either unresolvable | `unknown` (with diagnostic in verbose mode) |

### `specrew update --info` output change

Before:
```
Specrew  0.19.0  0.18.0      current origin-tags
```

After (Moment20 example):
```
Specrew  0.19.0  0.20.0      outdated  module-manifest
                                       → run 'specrew update --spec-kit' to upgrade
```

After (Specrew dev repo example, post-bump but pre-tag):
```
Specrew  0.20.0  0.20.0      current   module-manifest
```

### Composition with proposal 047 (Project Governance Profile)

Add a `version_check_source_preference` dial to the governance profile:
- `auto` (default) — use the precedence chain above
- `psgallery-only` — fail if PSGallery unreachable (strict downstream consumer)
- `manifest-only` — only consult loaded module's manifest (dev / offline use)
- `tags-only` — preserve current behavior for users who want it

This integrates cleanly with proposal 047's other dials.

## Effort

~3 SP, single iteration. Roughly:

- Refactor `specrew-update.ps1` `--info` path to call `Get-SpecrewVersionMismatchWarning` (or equivalent) from `scripts/internal/version-check.ps1` (~1 SP)
- Replace the three-way comparison logic in the `--info` output formatter (~0.5 SP)
- Update integration tests `tests/integration/version-checks.tests.ps1` to assert the corrected behavior across the four scenarios (current/outdated/ahead-of-known/unknown) (~1 SP)
- Documentation: brief update to `docs/getting-started.md` and the version-check section of `docs/dashboard-guide.md` (~0.5 SP)

## Phase placement

**Phase 2, fast follow-up to F-020.** Slots into the post-F-020 queue alongside 032, 046+048, 047. Smallest of the queued items, could ship as a hotfix before public flip.

Sequencing options:
- **Option A (separate small feature)**: ship as F-024 or wherever the queue lands. ~3 SP, half-day work.
- **Option B (combine with 047)**: roll into Proposal 047's governance profile work since it includes the `version_check_source_preference` dial anyway. Adds ~2 SP to 047 (the fix itself counts toward 047's scope, only the dial is new).
- **Option C (hotfix now)**: ship as a tactical fix before public flip, outside the proposal queue. Reasonable if the public flip is in days, not weeks.

Recommended: **Option B** (combine with 047). The fix is mechanically tied to the dial; shipping them together minimizes context-switching for the dashboard-helper code.

## Open questions

1. **PSGallery network failure handling**: if PSGallery is unreachable, fall back silently to module-manifest, or surface the failure as `unknown` with a diagnostic? Per FR-034 (F-020), silent fallback with verbose-only logging is established pattern — apply that here.
2. **`origin-tags` deprecation timeline**: drop the `origin-tags` source entirely, or keep it as the last-resort fallback? Argument for keeping: developer working without PSGallery or with broken manifest. Argument for dropping: tags are unreliable; one less source to maintain.
3. **Per-platform source preferences**: Spec Kit uses `github-tags`, Squad uses `npm`. Is the source preference per-platform (Specrew always uses module-manifest, Spec Kit always uses github-tags) or is it project-wide? Composition with 047's dial favors per-platform.
4. **Caching**: should the version-check result be cached the same way F-020's PSGallery check is (24h)? Composition opportunity with the shared cache layer.
5. **Cross-platform** (Windows / Linux / Mac WSL): the loaded module's `Specrew.psd1` is a single file; same module-manifest read should work everywhere. PSGallery query needs `Find-Module` which depends on `PowerShellGet`. Worth a smoke test on each OS.
6. **`specrew where` integration**: should the dashboard also surface "upgrade available" prominently if the version-check returns `outdated`? Composes with proposal 046 (auto-render) — the dashboard could include an "Upgrade available" notice when relevant.

## Risks

- **Breaking change for existing scripted consumers**: if anyone scripts against the `specrew update --info` output format (parsing the "current" string), changing the format could break them. Mitigation: keep column structure stable; only the values change. The status now distinguishes more cases (outdated, ahead-of-known) which is strictly more information.
- **PSGallery vs module-manifest divergence**: if PSGallery has a newer version than the module the user has loaded (e.g., they installed older but PSGallery has newer), which is "LatestKnown"? Both should be reported. Maybe a two-line output: "LatestKnown (PSGallery): 0.21.0 | LatestKnown (loaded): 0.20.0". Defer to v2 if too complex for v1.
- **Test fixture complexity**: the version-check tests need to mock both PSGallery and module-manifest sources. Re-use the F-020 test fixtures where possible.

## Cross-references

- **Proposal 035 / F-020 (Session-State Durability)** — Iter 2 introduced the version-check helper `scripts/internal/version-check.ps1`. This proposal extends its usage to `specrew update --info`.
- **Proposal 047 (Project Governance Profile)** — recommended combination target; adds the `version_check_source_preference` dial alongside this proposal's fix.
- **Proposal 046 (Auto-Render Dashboard)** — composes; auto-render could surface "upgrade available" notices when the unified version-check returns `outdated`.
- **Proposal 048 (Dashboard Velocity Metric Refinement)** — composes; same dashboard renderer touched by 046+048 can surface version status alongside velocity.
- **Proposal 031 / F-019 (Specrew Distribution Module)** — established the PSGallery distribution surface that PSGallery-based version-check depends on.

## Status history

- 2026-05-18: candidate captured after maintainer observed `specrew update --info` reporting "current" status for a downstream project (Moment20) whose pinned version (0.19.0) was behind the actually-loaded module (0.20.0). The bug is that `--info` uses `origin-tags` as the source (latest tag v0.18.0), an older code path that F-020 didn't refactor. The fix is mechanical: use the unified version-check helper from `scripts/internal/version-check.ps1`.
