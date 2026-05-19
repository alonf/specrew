---
proposal: 060
title: PSGallery Prerelease Channel + Staging Discipline
status: candidate
phase: phase-2
estimated-sp: 10
discussion: tbd
---

# PSGallery Prerelease Channel + Staging Discipline

## Why

The 2026-05-19 WSL trial surfaced a five-bug cluster (`MakeRelativeUri` crash, `Get-SpecrewInstalledVersion` null, `Get-Item -Force` hidden-file crash, `session_state` StrictMode crash, plus the maintainer's stale-branch confusion) AFTER changes landed on `main`. Every one of these reached `main` without any pre-release surface that would have caught them.

The current Specrew release pipeline (F-019 / Proposal 031):
1. Work happens on `main` or feature branches
2. Feature-closeout PR merges to `main`
3. Maintainer occasionally tags `v0.NN.0` on `main`
4. `.github/workflows/publish-module.yml` fires on tag push → publishes to PSGallery as stable
5. Downstream consumers run `Update-Module Specrew` → get the new stable version

There's NO staging step. Stable and main are effectively the same channel (with tag-cadence as the only gate). For a methodology product where bugs in the lifecycle commands block users from doing their work, this is too risky as we approach public flip.

**Empirical pattern**: of the 5 bugs from the WSL trial, ALL would have surfaced in a `specrew init → start → update → where` smoke test on Linux. We don't have such a smoke test today, and there's no pre-release surface to run one against before stable.

PowerShell Gallery natively supports prerelease versions via SemVer 2.0 prerelease syntax (`0.23.0-beta.1`, `0.23.0-rc.1`, etc.) and the `-AllowPrerelease` install flag. We can use this as a zero-infrastructure staging channel.

## What

Three coupled changes: **(A)** prerelease publishing pipeline, **(B)** install/discovery documentation, **(C)** staging discipline policy.

### A. Prerelease publishing pipeline

Extend `.github/workflows/publish-module.yml`:

```yaml
# Existing trigger (stable release):
#   on: push: tags: ['v[0-9]+.[0-9]+.[0-9]+']
# Add prerelease trigger:
#   on: push: tags: ['v[0-9]+.[0-9]+.[0-9]+-(alpha|beta|rc).[0-9]+']
```

Workflow logic:

| Tag pattern | PSGallery action |
|---|---|
| `v0.23.0` | `Publish-Module` (stable) |
| `v0.23.0-beta.1` | `Publish-Module` (prerelease, `Specrew` module name preserved) |
| `v0.23.0-rc.1` | `Publish-Module` (prerelease) |

Important: PSGallery treats `Specrew` and `Specrew-beta.1` as the **same module** with different version strings (per SemVer 2.0). Users running `Install-Module Specrew` without `-AllowPrerelease` get the latest stable; `Install-Module Specrew -AllowPrerelease` gets the latest including prereleases.

`Specrew.psd1` `ModuleVersion` stays `0.23.0`; the prerelease suffix lives in the `PrivateData.PSData.Prerelease` manifest field:

```powershell
PrivateData = @{
    PSData = @{
        Prerelease = 'beta.1'  # absent for stable releases
        ...
    }
}
```

The release workflow auto-edits this field based on the tag pattern, then publishes.

### B. Install/discovery documentation

Add a "Staging channel" section to `docs/installation.md`:

```text
# Stable (default)
Install-Module Specrew

# Prerelease (beta/rc — for testing new features ahead of stable)
Install-Module Specrew -AllowPrerelease

# Pin a specific prerelease
Install-Module Specrew -RequiredVersion 0.23.0-beta.1 -AllowPrerelease

# Upgrade to latest prerelease
Update-Module Specrew -AllowPrerelease
```

Add `--allow-prerelease` flag to `specrew update`'s self-update path so the maintainer can run `specrew update --self --allow-prerelease` to fetch the latest beta.

### C. Staging discipline policy

Recommended cadence (codify in `docs/release-discipline.md`):

1. Feature-closeout PR merges to `main`
2. Maintainer tags `v0.NN.0-beta.1` → publishes prerelease automatically
3. Maintainer (and any opted-in early adopters) install via `-AllowPrerelease`, validate against their downstream projects
4. **Validation window**: ≥48h for normal features, ≥7d for schema-changing or cross-platform-sensitive features
5. If bugs surface → fix on main → tag `v0.NN.0-beta.2` → repeat
6. When clean: tag `v0.NN.0` (no prerelease suffix) → publishes stable
7. Downstream consumers see the stable upgrade

For Phase 2+ features that touch cross-platform paths, schema, or session-state: prerelease is **mandatory**. For documentation-only or test-only changes: prerelease is optional.

This discipline composes with Proposal 042 (Integration Test Suite). Once 042 ships a Linux E2E test, it should run automatically on every prerelease tag, with results posted to the PR or a dedicated dashboard before stable is allowed.

### Per-host plugin parallel (forward-looking)

Once Proposal 058 (Plugin-Based Multi-Host Distribution) ships, each host plugin's distribution channel needs its own prerelease/stable distinction. Claude Code marketplace, Copilot CLI plugin registry, etc. each have different mechanisms. This proposal establishes the *discipline*; per-host application of it lives in 058.

## Effort

- **Iteration 1 (~6 SP)**: workflow extension; `Prerelease` field handling in manifest; smoke-test that prerelease publishes work end-to-end (publish to test PSGallery account or use `-WhatIf`); documentation pages.
- **Iteration 2 (~4 SP)**: `--allow-prerelease` flag on `specrew update --self`; release-discipline doc; per-feature decision integrated into feature-closeout template ("Did this ship via prerelease first?").

**Total: ~10 SP, two iterations.** Smaller of the bug-prevention proposals; high leverage relative to size.

## Phase placement

**Phase 2, immediately post-F-022 / pre-public-flip.** Reasoning:

- Pre-public-flip is when prerelease has the most leverage — the maintainer + a small opt-in group can validate features before they reach a broader audience.
- Sequenced **before** Proposal 042 (Integration Test Suite) full scope: 042 needs a target to test against, and prerelease publishing gives 042 a natural hook ("run on every prerelease tag").
- Sequenced **before** Proposal 058 (Plugin-Based Distribution): per-host plugin staging discipline depends on the conceptual discipline established here.
- Sequenced **after** Proposal 049 (Version-Check Source Unification) — prerelease versions have a `-beta.N` suffix that the version comparator needs to understand correctly. Proposal 049's Compare-VersionState already added an `ahead-of-known` case; prerelease comparison is similar.

## Open questions

1. **Validation window**: who decides when a prerelease is "clean enough" to promote? Recommend: maintainer-only for v1 (Alon decides); add opt-in early-adopter sign-off in a later iteration.
2. **Automatic promotion vs explicit tag**: when `v0.23.0-beta.3` has been clean for 7d, should the workflow auto-tag `v0.23.0` and publish stable, or always require explicit maintainer tag? Explicit tag for v1; automation is a later refinement.
3. **Prerelease lifecycle for failed validations**: if `0.23.0-beta.3` is a "failed" release (bugs found), do we yank it from PSGallery, or leave it with documentation that explains the bug and points to `-beta.4`? PSGallery doesn't easily yank; leave with documentation is the pragmatic answer.
4. **Backward compatibility with existing tags**: existing `v0.NN.0` tags continue to work as stable releases. No retroactive renaming.
5. **Communication channel**: how do prerelease testers find out a new beta is available? GitHub Releases (automatic via workflow), Discussions thread, RSS feed of releases, or a Specrew-specific mailing-list-equivalent? Start with GitHub Releases; Discussions thread for major prereleases.
6. **NPM-style "channels"**: PSGallery prerelease is binary (stable vs prerelease). Some ecosystems have multiple channels (alpha, beta, rc, canary). Worth distinguishing? Recommend: use SemVer 2.0 conventional suffixes (`-alpha.N`, `-beta.N`, `-rc.N`); document semantics; don't add a UI to switch channels (users specify the version they want).
7. **Cost**: PSGallery publishing is free for open-source modules. Prerelease publishing is also free. No infrastructure cost; only minimal workflow time added.

## Risks

- **Prerelease confusion**: users running `Install-Module Specrew -AllowPrerelease` may not realize they're on a less-stable track. Mitigation: at every `specrew start` / `specrew where`, if the installed version has a `Prerelease` field, surface a one-line banner: `You are running Specrew 0.23.0-beta.1 (prerelease)`. Composes with Proposal 050 (Version Surface Discoverability).
- **Workflow complexity**: adding prerelease handling to the publish workflow adds branching logic. Mitigation: keep the logic narrow; one variable controls the `Prerelease` field; the rest is the same code path.
- **PSGallery upload failures**: prerelease publishes might fail (rate limit, network). Mitigation: workflow retries; if persistent, manual intervention via maintainer-only `Publish-Module` from a local pwsh session.
- **Tag-sprawl in the git history**: every prerelease creates a tag. With multi-beta features, this can produce 5-10 tags per shipped feature. Mitigation: namespace the tags (`v0.23.0-beta.1`, `v0.23.0-rc.1`) and accept the volume; tags are cheap.

## Cross-references

- Composes with [031](031-specrew-distribution-module.md) / F-019 (Specrew Distribution Module) — extends the PSGallery publish workflow that F-019 established.
- Composes with [042](042-specrew-integration-test-suite.md) (Specrew Integration Test Suite) — Integration Test Suite triggered automatically on every prerelease tag; prerelease is the natural test target.
- Composes with [049](049-version-check-source-unification.md) (Version-Check Source Unification) — `Compare-VersionState` needs to understand prerelease suffix comparison.
- Composes with [050](050-version-surface-discoverability.md) (Version Surface Discoverability) — `specrew version` should surface the prerelease label prominently when applicable.
- Composes with [054](054-pre-merge-lifecycle-verification-gate.md) (Pre-Merge Lifecycle Verification Gate) — pre-merge gate runs against `main`; prerelease channel runs after merge. Both layers of defense.
- Composes with [055](055-always-in-flow-bug-fix-lifecycle.md) (Always-In-Flow + Bug-Fix Lifecycle) — bug-fix-repair slices may ship as prerelease patches (`v0.23.1-beta.1`).
- Composes with [058](058-plugin-based-multi-host-distribution.md) (Plugin-Based Multi-Host Distribution) — establishes the conceptual discipline that 058 applies per-host.
- Sibling of [059](059-legacy-state-read-tolerance.md) (Legacy-State Read-Tolerance) — both are bug-class-prevention work; this proposal is the run-it-by-someone-first layer, 059 is the don't-break-when-old-state-is-encountered layer.

## Status history

- 2026-05-19: candidate captured after the 5-bug WSL trial cluster. Pattern: bugs reached `main` and would have reached PSGallery stable without a pre-release surface to shake them out. PSGallery's native prerelease support is a zero-infrastructure staging channel; this proposal codifies its use.
