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

### The beta-tester argument (primary motivation)

Specrew's growth path crosses a threshold at the moment external users start adopting it. Before that threshold, the maintainer is the only validator and git-clone-based testing covers everything. After that threshold, **early adopters need a low-friction install path that doesn't require cloning the repo** — they want `Install-Module Specrew -AllowPrerelease`. The PSGallery prerelease channel is that path.

PowerShell Gallery natively supports prerelease versions via SemVer 2.0 prerelease syntax (`0.23.0-beta.1`, `0.23.0-rc.1`, etc.) and the `-AllowPrerelease` install flag. Prereleases are invisible to default `Install-Module Specrew` consumers — only opt-in users see them. This makes prereleases a safe distribution channel for beta testers without committing to a public stable release.

Without this proposal: external adopters who want to test ahead of stable have to `git clone` the repo, which is friction for non-developers and not how PowerShell ecosystem users typically consume modules. With this proposal: `Install-Module Specrew -AllowPrerelease` is the canonical entry point for the beta-tester audience.

### The workflow-validation argument (secondary motivation)

The 2026-05-19 WSL trial surfaced a five-bug cluster (`MakeRelativeUri` crash, `Get-SpecrewInstalledVersion` null, `Get-Item -Force` hidden-file crash, `session_state` StrictMode crash, plus the maintainer's stale-branch confusion) AFTER changes landed on `main`. Every one of these reached `main` without any pre-release surface that would have caught them.

A prerelease tag also functions as a **dress rehearsal for the stable publish**: it exercises the full workflow path (manifest stamping, signing, PSGallery upload, GitHub Release flag handling) without committing to a stable release. If the workflow breaks, only opt-in beta testers (and the maintainer) see the failure.

The current Specrew release pipeline (F-019 / Proposal 031) has no staging step: stable and main are effectively the same channel with tag-cadence as the only gate. For a methodology product where bugs in the lifecycle commands block users from doing their work, this is too risky once external adoption begins.

### Per-feature opt-in, not universal mandate

For the **current solo-maintainer stage** (zero external users), prereleases are NOT mandatory per feature. Maintainer can validate via git-clone import and publish stable directly. The infrastructure (workflow + manifest primitives) lands once; the *discipline* of using it scales with the audience.

For the **post-announcement stage** (external beta testers exist), prereleases become the standard channel. Every Phase 2+ feature ships as `-beta.N` first, validation window held open for beta-tester feedback, then promote to stable.

For **any stage**, prereleases SHOULD be used when: the feature is high-risk (schema migration, manifest changes, signing changes, dependency bumps), OR the workflow itself was recently changed and needs a dress rehearsal, OR an external beta-tester explicitly requests early access.

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

### C. Staging discipline policy (stage-dependent)

The discipline is NOT a universal "prerelease every feature" mandate. It's adaptive to the project's adoption stage and per-feature risk profile.

#### Solo-maintainer stage (no external users)

Default workflow: git-clone testing → tag stable directly. Prereleases are opt-in per feature.

Use a prerelease when:

- Feature touches the publish workflow itself, signing path, or manifest structure (workflow dress-rehearsal)
- Schema migration (paired with Proposal 059 reader-tolerance + Proposal 061 init/update convergence)
- Cross-platform paths or session-state (high regression risk)
- First publish in N months (refresh workflow confidence)
- F-023 specifically: first PSGallery publish in Specrew's history (mandatory dress rehearsal)

For routine features (documentation, internal-tooling, small validator changes): tag stable directly.

#### Post-announcement stage (external beta testers exist)

Default workflow: every Phase 2+ feature ships as `-beta.N` first. Codified in `docs/release-discipline.md`:

1. Feature-closeout PR merges to `main`
2. Maintainer tags `v0.NN.0-beta.1` → publishes prerelease automatically
3. Maintainer + opted-in beta testers install via `Install-Module Specrew -AllowPrerelease`, validate against their downstream projects
4. **Validation window**: ≥48h for normal features, ≥7d for schema-changing or cross-platform-sensitive features
5. If bugs surface → fix on main → tag `v0.NN.0-beta.2` → repeat
6. When clean: workflow_dispatch `mode=promote-prerelease`, `release_tag=v0.NN.0` → publishes stable
7. Downstream consumers see the stable upgrade

For documentation-only or test-only changes: prerelease still optional.

#### Trigger for the stage transition

The "solo-maintainer → post-announcement" stage transition happens when:

- A public announcement on Medium / LinkedIn / HN / Twitter / etc. brings ≥1 known external adopter, OR
- An external contributor opens a PR or substantive Discussion thread, OR
- The maintainer explicitly decides to invite beta testers via a Discussion post

Until then, prereleases are an available tool, not a required step. The 2026-05-19 silent public-flip kept the project in the solo-maintainer stage despite repo visibility being public.

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
- 2026-05-19 (later): reframed from "mandatory pre-release every feature" to "stage-dependent + per-feature opt-in." Maintainer flagged that for the current solo-maintainer stage (zero external users), git-clone testing covers validation; the prerelease channel's *primary* value is beta-tester distribution (low-friction install for external adopters), with workflow dress-rehearsal as a secondary use. The proposal now treats the discipline as adaptive to project stage rather than universal mandate.
- 2026-05-19 (workflow primitives landed): F-023's bundled chore landed `publish-module.yml` mode handling + `invoke-module-release.ps1` prerelease/promote logic + `Specrew.psd1` PSData.Prerelease placeholder, in commit `f119e4a`. With those primitives in place, the remaining scope of this proposal shrinks to polish: `--allow-prerelease` flag on `specrew update --self`, prerelease banner at session start (composes with F-020 warning path), `docs/release-discipline.md` (capturing the stage-dependent guidance above), and the stage-transition trigger documented. Revised effort estimate: ~5-7 SP (down from original ~10 SP).
