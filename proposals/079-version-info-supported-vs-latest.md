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

Add a new top-level key to `.specrew/config.yml` (or a sibling file if config.yml shouldn't grow):

```yaml
supported_versions:
  speckit:
    min: "0.8.4"            # absolute floor — Specrew refuses to operate below
    max_tested: "0.8.11"    # latest version Specrew validated against this release
    notes: "0.8.12 released 2026-05-21 — Specrew adoption pending"
  squad:
    min: "0.9.0"
    max_tested: "0.9.4"
    notes: ""
```

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
| Add `supported_versions` declaration to `.specrew/config.yml` template (or new file `.specrew/supported-versions.yml`) | `.specrew/config.yml` + `scripts/specrew-init.ps1` (write template at bootstrap) | 1 SP |
| Update `scripts/internal/version-check.ps1` to read the declaration + compute four-state status | `scripts/internal/version-check.ps1` | 1.5 SP |
| Update `scripts/specrew-update.ps1` to render the new table format with `LatestSupported` + advisory notes | `scripts/specrew-update.ps1` | 1 SP |
| Migration: existing `.specrew/config.yml` files without `supported_versions` get a sensible default (use existing `speckit_version` and infer `max_tested`) | `scripts/internal/version-check.ps1` defensive read | 0.5 SP |
| Tests: four-state status logic; missing-declaration migration | `tests/integration/version-info-states.tests.ps1` (new) | 1 SP |
| Update user-guide with the new status semantics | `docs/user-guide.md` | 0.5 SP |

Total: ~5 SP.

## Composition with other proposals

| Proposal | Relationship |
|---|---|
| **Proposal 049 (Version-Check Source Unification, candidate)** | 049 fixes the stale-warning bug in `update --info` (uses origin-tags instead of module manifest + PSGallery). 079 adds the supported-vs-upstream distinction. Both touch version-check.ps1 — could be bundled into one slice when 079 is implemented, OR shipped sequentially. Strong composition; one of them probably ships first and the other extends |
| **Proposal 050 (Version Surface Discoverability, candidate)** | 050 adds `specrew version` industry-standard command. 079 extends to show supported context. Could share a small implementation slice |
| **Rule 15 (version-consistency validator, project_psd1_version_consistency_validator_chore memory)** | This proposal extends Rule 15's discipline to a NEW manifest (supported_versions). Rule 15's check would ensure `max_tested` is updated at each Specrew release |
| **Proposal 060 (Prerelease Channel Staging, candidate)** | Prerelease channels validate against upstream-latest; the `max_tested` field gets updated when prerelease validation succeeds and a Specrew release ships against the new dependency |
| **Proposal 028 (Public Proposals Surface) / metadata schema** | The supported_versions declaration is itself a small metadata schema; composes with 028's broader proposal-metadata work |

## Acceptance signals

- **AC1**: `.specrew/config.yml` (or sibling file) carries a `supported_versions` declaration with `min`, `max_tested`, `notes` fields for both `speckit` and `squad`
- **AC2**: `specrew update --info` shows a "LatestSupported" column in addition to (or replacing prominence of) "LatestKnown"
- **AC3**: When upstream has a version beyond `max_tested`, an advisory line surfaces explaining "Specrew adoption pending" and the user is NOT pushed toward upgrade
- **AC4**: Four-state status (`current`, `update-available-supported`, `ahead-of-supported`, `behind-supported`) is computed correctly for all combinations
- **AC5**: `specrew update --info --upstream-latest` opts into the old behavior (upstream-latest displayed prominently)
- **AC6**: Existing `.specrew/config.yml` files without `supported_versions` declaration fall back to sensible defaults (use the existing `speckit_version` field as `max_tested`); no breaking change for downstream users
- **AC7**: Tests cover all four states + migration

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
