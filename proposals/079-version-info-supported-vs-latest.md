---
proposal: 079
title: Version Information — Supported vs Latest Distinction
status: candidate
phase: phase-2
estimated-sp: 5
discussion: tbd
---

# Version Information — Supported vs Latest Distinction

## Why

`specrew update --info` today fetches and displays the **latest upstream versions** of Specrew's dependencies (Squad via npm, Spec Kit via GitHub tags), then shows status as `current` or `update-available` based on that comparison.

This is methodologically wrong. Specrew has a TESTED compatibility surface — it validates against specific versions of Squad and Spec Kit at each release. When upstream ships a new version, Specrew has NOT yet validated against it. Showing "0.8.12 available" in `--info` when Specrew was only tested with 0.8.11 implicitly pushes the user toward an untested version, which can break their project.

### User direction (2026-05-21)

> "Currently specrew update --info shows the latest Squad and Spec-kit version — even if we never adopt and test Specrew with these versions. I think we need to provide the latest supported versions and not the latest actual versions. Of course we want to update Specrew ASAP after a version of the dependency is out, but we may be in a situation were we can't."

The fix is to declare a SUPPORTED versions matrix per Specrew release, and have `update --info` show that as the authoritative target, with upstream-latest available as advisory.

## What (4 Pillars)

### Pillar 1: Supported-versions declaration

Create a new MODULE-side file `scripts/internal/supported-versions.yml` that ships with the Specrew module (added to `Specrew.psd1` FileList). This is maintainer-managed data, not downstream-project state.

```yaml
# scripts/internal/supported-versions.yml
schema: v1
speckit:
  min: "0.8.4"            # absolute floor — Specrew refuses to operate below
  max_tested: "0.8.4"     # latest version Specrew validated against this release
  notes: ""               # surfaces in --info when set (e.g. "0.8.12 released; adoption pending")
squad:
  min: "0.9.1"
  max_tested: "0.9.4"
  notes: ""
```

**Why module-side, not `.specrew/config.yml`** (deviation from original proposal draft, decided 2026-05-21):

- The data is MAINTAINER-managed (updated when each Specrew release validates against new dependency versions). It is NOT project-state.
- If it lived in downstream `.specrew/config.yml`, every project would carry a duplicate of the same values, and Specrew updates would need a migration step to propagate corrections. That muddies the project-state/module-state boundary.
- Module-side: the maintainer edits one file at each Specrew release; downstream projects automatically get the updated supported-version data via `Update-Module Specrew`.

**Relationship to existing `extensions/specrew-speckit/extension.yml` `versions:` block** (which currently carries `min_speckit: "0.8.4"` and `min_squad: "0.9.1"`):

- `extension.yml` retains its existing `versions.min_*` keys for Spec Kit extension-loader contract compatibility.
- `scripts/internal/supported-versions.yml` becomes the SINGLE source of truth for Specrew code paths (`version-check.ps1`, `specrew-update.ps1`).
- The hardcoded `$minimumSpecKitVersion = '0.8.4'` and `$minimumSquadVersion = '0.9.1'` in `scripts/specrew-update.ps1` are removed and replaced with reads from the new file.
- Drift between `extension.yml` and `supported-versions.yml` is a Rule-15 candidate validator (out of scope for this slice; future Quality Hardening Bundle work).

The `max_tested` value is updated by the Specrew maintainer when each Specrew release validates against a new dependency version. It's part of the Rule-15 version-management discipline at each Specrew release.

Notes field is optional and surfaces in `--info` output when set, explaining adoption-pending state to the user.

### Pillar 2: Four-state status model

Replace today's two states (`current` / `update-available`) with four states:

| Status | Meaning |
|---|---|
| `current` | Installed version equals `max_tested` |
| `update-available-supported` | Installed version is between `min` and `max_tested`; user should upgrade within the supported range |
| `ahead-of-supported` | Installed version is at upstream-latest beyond `max_tested`; Specrew has NOT validated against it. Advisory only |
| `behind-supported` | Installed version is below `min`; Specrew refuses to operate (or warns sharply); user must upgrade |

The status is computed by `scripts/internal/version-check.ps1` after reading the supported-versions declaration.

### Pillar 3: Updated `--info` output

The table format gains a "LatestSupported" column and an explicit "UpstreamLatest" column (advisory):

```text
Version info for C:\Dev\MyProject

Platform Current LatestSupported UpstreamLatest Status                     Source
-------- ------- -------------- -------------- ------                     ------
Specrew  0.24.1  0.24.1         0.24.1         current                    module-manifest
Spec Kit 0.8.11  0.8.11         0.8.12         current                    config + github-tags
                                                ^^ (Specrew adoption pending; see notes)
Squad    0.9.4   0.9.4          0.9.4          current                    config + npm
```

If `UpstreamLatest > LatestSupported`, an advisory line surfaces:

> Note: Spec Kit 0.8.12 is available upstream but Specrew has not yet validated against it. Specrew is current within its supported range. Upgrading Spec Kit beyond the supported maximum is at your own risk; consider waiting for a Specrew release that validates against 0.8.12.

### Pillar 4: Behavior changes — `--info` is advisory, not prescriptive

The default behavior of `specrew update --info` shifts:

- Currently: "you can upgrade Spec Kit to 0.8.12" — implies action
- Proposed: "Specrew supports up to Spec Kit 0.8.11; you're current. Upstream has 0.8.12 (advisory)."

The advisory framing prevents downstream users from upgrading Spec Kit (or Squad) to versions Specrew hasn't tested, breaking their projects.

An explicit `--upstream-latest` flag opts into the old behavior for users who want to see upstream-latest prominently.

## How (implementation plan)

This is a small feature (~5 SP). Could ship as a chore-shaped small-fix slice per Proposal 067 since it touches few files and doesn't introduce new architectural concepts.

| Step | File | Effort |
|---|---|---|
| Create module-side declaration with initial min + max_tested values | `scripts/internal/supported-versions.yml` (new) | 0.5 SP |
| Add new file to module manifest FileList for PSGallery shipment | `Specrew.psd1` | 0.25 SP |
| Add `Get-SpecrewSupportedVersions` + four-state status helper | `scripts/internal/version-check.ps1` | 1.5 SP |
| Update `--info` table format with `LatestSupported` column + advisory notes; remove hardcoded `$minimumSpecKitVersion`/`$minimumSquadVersion` constants; add `--upstream-latest` flag | `scripts/specrew-update.ps1` | 1.5 SP |
| Tests: four-state status logic; missing-file fallback; advisory rendering | `tests/integration/version-info-states.tests.ps1` (new) | 1 SP |
| Update user-guide with the new status semantics | `docs/user-guide.md` | 0.25 SP |

Total: ~5 SP. Module-side location eliminates per-project migration; downstream projects auto-receive the supported-version data via `Update-Module Specrew`.

## Composition with other proposals

| Proposal | Relationship |
|---|---|
| **Proposal 049 (Version-Check Source Unification, candidate)** | 049 fixes the stale-warning bug in `update --info` (uses origin-tags instead of module manifest + PSGallery). 079 adds the supported-vs-upstream distinction. Both touch version-check.ps1 — could be bundled into one slice when 079 is implemented, OR shipped sequentially. Strong composition; one of them probably ships first and the other extends |
| **Proposal 050 (Version Surface Discoverability, candidate)** | 050 adds `specrew version` industry-standard command. 079 extends to show supported context. Could share a small implementation slice |
| **Rule 15 (version-consistency validator, project_psd1_version_consistency_validator_chore memory)** | This proposal extends Rule 15's discipline to a NEW manifest (supported_versions). Rule 15's check would ensure `max_tested` is updated at each Specrew release |
| **Proposal 060 (Prerelease Channel Staging, candidate)** | Prerelease channels validate against upstream-latest; the `max_tested` field gets updated when prerelease validation succeeds and a Specrew release ships against the new dependency |
| **Proposal 028 (Public Proposals Surface) / metadata schema** | The supported_versions declaration is itself a small metadata schema; composes with 028's broader proposal-metadata work |

## Acceptance signals

- **AC1**: Module ships `scripts/internal/supported-versions.yml` with `min`, `max_tested`, `notes` fields for both `speckit` and `squad`; file present in `Specrew.psd1` FileList
- **AC2**: `specrew update --info` shows a "LatestSupported" column in addition to (or replacing prominence of) "LatestKnown"
- **AC3**: When upstream has a version beyond `max_tested`, an advisory line surfaces explaining "Specrew adoption pending" and the user is NOT pushed toward upgrade
- **AC4**: Four-state status (`current`, `update-available-supported`, `ahead-of-supported`, `behind-supported`) is computed correctly for all combinations
- **AC5**: `specrew update --info --upstream-latest` opts into the old behavior (upstream-latest displayed prominently)
- **AC6**: Hardcoded `$minimumSpecKitVersion` and `$minimumSquadVersion` constants in `scripts/specrew-update.ps1` are removed; min/max are sourced from `scripts/internal/supported-versions.yml`
- **AC7**: Defensive fallback when `supported-versions.yml` is missing or malformed (degrades to today's two-state behavior with a warning, not a crash)
- **AC8**: Tests cover all four states + missing-file fallback + `--upstream-latest` opt-in

## Out of scope

- Automatic Specrew adoption of new upstream versions (manual maintainer task per Specrew release)
- Pinning downstream user's local installation to a specific dependency version (Specrew doesn't manage the user's local Spec Kit / Squad installation today)
- Multi-version support matrix (current model: one `max_tested` per dependency per Specrew release)

## Implementation note

**This proposal can be implemented directly by the Specrew developer (not Squad) as a small-fix slice while Squad works on Proposal 078 (Handoff Conversation Quality) in parallel.** The two proposals touch entirely different surfaces and have no implementation dependencies. Per 2026-05-21 user direction: "version info is not related and you can implement it while squad the others."

## Cross-references

- **User direction**: 2026-05-21 conversation, "specrew update --info shows the latest Squad and Spec-kit version — even if we never adopt and test Specrew with these versions"
- Proposal 049 (Version-Check Source Unification): file:///C:/Dev/Specrew/proposals/049-version-check-source-unification.md
- Proposal 050 (Version Surface Discoverability): file:///C:/Dev/Specrew/proposals/050-version-surface-discoverability.md
- Proposal 060 (Prerelease Channel Staging): file:///C:/Dev/Specrew/proposals/060-prerelease-channel-staging.md
- Memory: `[[project-psd1-version-consistency-validator-chore]]` — Rule 15 discipline
- INDEX: file:///C:/Dev/Specrew/proposals/INDEX.md
