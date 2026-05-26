---
proposal: 060
title: PSGallery Prerelease Channel + Universal Beta-Before-Stable Mandate
status: draft
phase: phase-2
estimated-sp: 5-7
priority-tier: 1
discussion: **HIGH PRIORITY** — user direction 2026-05-26 flipped this from stage-dependent + per-feature opt-in to universal mandate. Every feature ships -beta.N to PSGallery first; maintainer manually validates installed prerelease; only after PASS verdict does the Crew promote to stable. Infrastructure already landed in F-023 (`f119e4a` workflow primitives). F-048 iteration 001 implemented the policy/docs/coordinator-handoff/test slice on the active feature branch: Steps 5-14, the explicit Step 11 PASS gate, `docs/release-discipline.md`, and focused regression coverage. Remaining proposal scope: `specrew update --self --allow-prerelease`, prerelease banner/version-surface polish, and an optional validator rule. F-048 iteration 002's release-audit mechanism is separate F-048 scope and is not shipped by iteration 001. Composes with [[feedback-beta-publish-before-stable-2026-05-26]] standing rule and Proposal 131 (coordinator-prompt SDLC ownership clarification).
---

# PSGallery Prerelease Channel + Universal Beta-Before-Stable Mandate

## Why

### Policy update 2026-05-26 — universal mandate (was: stage-dependent opt-in)

This proposal originally articulated the prerelease discipline as **stage-dependent + per-feature opt-in**: solo-maintainer stage skips beta unless feature is risky; post-announcement stage uses beta as default. The 2026-05-19 trigger for the stage transition was "≥1 known external adopter."

**On 2026-05-26 the policy flipped to universal mandate.** Trigger: v0.27.3 (F-047) shipped directly to PSGallery stable on 2026-05-26 without going through the beta channel. No bugs surfaced — but the F-046 v0.27.0 stale-installed-module trap (verdicts silently dropped because installed `0.27.0` lacked F-046's atomic verdict writer; worked around with `$env:SPECREW_MODULE_PATH` override) made it concrete that **the installed PSGallery package is the only surface that exercises the full real-world install path**, and skipping beta means skipping that validation layer. The maintainer adopted: **every feature ships -beta.N first, manual test, then promote.** No exceptions for risk profile or audience size.

The standing rule is captured in [[feedback-beta-publish-before-stable-2026-05-26]] which extends the [[feedback-pr-at-feature-close-sdlc]] feature-closeout Steps 5-9 to Steps 5-14.

This Why section retains the original beta-tester argument and workflow-validation argument below as supporting context, but the per-feature opt-in language is superseded by the universal mandate.

### The beta-tester argument (primary motivation)

Specrew's growth path crosses a threshold at the moment external users start adopting it. Before that threshold, the maintainer is the only validator and git-clone-based testing covers everything. After that threshold, **early adopters need a low-friction install path that doesn't require cloning the repo** — they want `Install-Module Specrew -AllowPrerelease`. The PSGallery prerelease channel is that path.

PowerShell Gallery natively supports prerelease versions via SemVer 2.0 prerelease syntax (`0.23.0-beta.1`, `0.23.0-rc.1`, etc.) and the `-AllowPrerelease` install flag. Prereleases are invisible to default `Install-Module Specrew` consumers — only opt-in users see them. This makes prereleases a safe distribution channel for beta testers without committing to a public stable release.

Without this proposal: external adopters who want to test ahead of stable have to `git clone` the repo, which is friction for non-developers and not how PowerShell ecosystem users typically consume modules. With this proposal: `Install-Module Specrew -AllowPrerelease` is the canonical entry point for the beta-tester audience.

### The workflow-validation argument (secondary motivation)

The 2026-05-19 WSL trial surfaced a five-bug cluster (`MakeRelativeUri` crash, `Get-SpecrewInstalledVersion` null, `Get-Item -Force` hidden-file crash, `session_state` StrictMode crash, plus the maintainer's stale-branch confusion) AFTER changes landed on `main`. Every one of these reached `main` without any pre-release surface that would have caught them.

A prerelease tag also functions as a **dress rehearsal for the stable publish**: it exercises the full workflow path (manifest stamping, signing, PSGallery upload, GitHub Release flag handling) without committing to a stable release. If the workflow breaks, only opt-in beta testers (and the maintainer) see the failure.

The current Specrew release pipeline (F-019 / Proposal 031) has no staging step: stable and main are effectively the same channel with tag-cadence as the only gate. For a methodology product where bugs in the lifecycle commands block users from doing their work, this is too risky once external adoption begins.

### Per-feature universal mandate (effective 2026-05-26)

Every feature publishes `-beta.N` to PSGallery first; the maintainer manually validates the installed prerelease package against PSGallery (clean shell, `Install-Module Specrew -RequiredVersion <ver> -AllowPrerelease -Force`, exercise feature-specific surface + smoke `specrew start` + `specrew where`); only after explicit PASS verdict does the Crew tag stable and publish.

**No per-feature opt-out** — even for "doc-only" or "test-only" or "validator-only" features that change any runtime artifact (scripts, manifests, validator rules, agent templates, CHANGELOG version). The cost is one extra tag + one `Install-Module` + ~10 minutes wait; the benefit is the PSGallery install path is exercised every release.

**Exception**: proposal-only commits that do NOT change runtime artifacts (e.g., the proposal-doc updates on 2026-05-26) do not publish a beta — they don't change the package shape.

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

### C. Staging discipline policy (universal mandate, effective 2026-05-26)

Every feature publishes beta to PSGallery first, manual test, then promote. Codified in `docs/release-discipline.md` by F-048 iteration 001:

1. Feature-closeout PR merges to `main` (Step 8 of the PR-at-feature-close SDLC per [[feedback-pr-at-feature-close-sdlc]])
2. **Step 9 (NEW)**: Agent tags the merge commit (or the PASS-candidate fix commit if looping after a FAIL) as `v<next-version>-beta.1` (or `beta.N`) and pushes the tag
3. **Step 10 (NEW)**: `.github/workflows/publish-module.yml` publishes prerelease automatically; agent verifies package visible via `Find-Module Specrew -AllowPrerelease -RequiredVersion <ver>`
4. **Step 11 (NEW)**: Agent emits HANDOFF — "Beta v<ver>-beta.1 published to PSGallery. Please install via `Install-Module Specrew -RequiredVersion <ver> -AllowPrerelease -Force` in a clean shell, exercise feature-specific surface + smoke `specrew start` + `specrew where`, report PASS or FAIL with evidence." Agent PAUSES for human verdict.
5. **Step 12 (NEW)**: If human reports FAIL — agent commits fix on main → tags `v<ver>-beta.2` → repeats Step 9-11. Beta-loop continues until human reports PASS.
6. **Step 13 (NEW)**: If human reports PASS — agent tags the PASS-validated commit `v<ver>` stable; pushes tag; workflow publishes stable to PSGallery; agent verifies package visible via `Find-Module Specrew -RequiredVersion <ver>`.
7. **Step 14**: Stop before any new feature work.

**Validation window**: no fixed time gate — gated on the human's PASS verdict at Step 11. The maintainer chooses the depth of manual test based on the feature's surface area.

**Skipping not allowed**: even for "doc-only" / "test-only" / "validator-only" features that change runtime artifacts. Proposal-only commits exempt (no runtime artifact change).

**Composes with Proposal 042** (Integration Test Suite): once 042 ships a Linux E2E test, it runs automatically on every prerelease tag and reports to a dashboard the human consults at Step 11. The agent's HANDOFF at Step 11 surfaces both the dashboard link and the manual-test instructions.

### Per-host plugin parallel (forward-looking)

Once Proposal 058 (Plugin-Based Multi-Host Distribution) ships, each host plugin's distribution channel needs its own prerelease/stable distinction. Claude Code marketplace, Copilot CLI plugin registry, etc. each have different mechanisms. This proposal establishes the *discipline*; per-host application of it lives in 058.

## Effort

Infrastructure already landed in F-023 (commit `f119e4a`) — `publish-module.yml` handles `v*-(alpha|beta|rc).N` tag patterns, `invoke-module-release.ps1` injects `PSData.Prerelease`, `Specrew.psd1` has the placeholder. F-048 iteration 001 has implemented policy + template + docs + fixture coverage. Remaining proposal scope is the maintainer-facing CLI flag, prerelease banner/version-surface polish, and the optional validator rule; F-048 iteration 002 release-audit automation is related but separately scoped by F-048.

- **Iteration 1 (implemented by F-048 iteration 001, ~3-4 SP, small-fix-slice-sized)**:
  - Coordinator-prompt template extension: feature-closeout HANDOFF includes Steps 5-14 with `AGENT NEXT ACTION:` and `HUMAN ACTION NEEDED:` ownership rows (composes with Proposal 131 — same template surface)
  - `docs/release-discipline.md` (new) — codifies the universal mandate + Steps 5-14
  - Focused integration test in `tests/integration/beta-before-stable-sdlc.tests.ps1` for the coordinator handoff and release-discipline docs

- **Iteration 2 (~2-3 SP)**:
  - `--allow-prerelease` flag on `specrew update --self` (maintainer convenience)
  - Prerelease-banner integration at session start (composes with Proposal 050 Version Surface Discoverability) — `specrew start` / `specrew where` surface `[PRERELEASE]` label when installed version has `PSData.Prerelease` field
  - Validator rule (optional, soft WARN): closeout commit detected without subsequent `-beta.N` tag within N hours (composes with Proposal 120 handoff-block validator)

**Total: ~5-7 SP, two small iterations.** Down from original ~10 SP because workflow primitives shipped in F-023.

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
- **2026-05-26 (policy flip — universal mandate)**: status bumped candidate → **draft**, priority-tier 1 (HIGH PRIORITY). User direction after observing v0.27.3 ship directly to stable without exercising the PSGallery install path: "Every feature publishes -beta.N first; manual test on PSGallery package; only then release." Trigger reframed from "≥1 external adopter" to "PSGallery is the only surface that exercises the full install path — exercise it every release, no exceptions." Standing rule captured in [[feedback-beta-publish-before-stable-2026-05-26]]; extends [[feedback-pr-at-feature-close-sdlc]] Steps 5-9 to Steps 5-14. Bundle candidate with Proposal 131 (same coordinator-prompt template surface). Sequencing: ship immediately so the next runtime-touching feature (e.g., F-048 bug-bash) is the first to exercise the new SDLC.
- 2026-05-26 (F-048 iteration 001): active feature-branch implementation landed the policy/docs/template slice: coordinator surfaces enumerate Steps 5-14 with split `AGENT NEXT ACTION:` / `HUMAN ACTION NEEDED:` ownership rows, `docs/release-discipline.md` codifies the beta-before-stable rule, and `tests/integration/beta-before-stable-sdlc.tests.ps1` protects the handoff/docs shape. Remaining scope not shipped by this slice: `specrew update --self --allow-prerelease`, prerelease banner/version-surface polish, optional validator rule, and F-048 iteration 002 release-audit automation.
