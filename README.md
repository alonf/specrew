<p align="center">
  <img src="docs/assets/specrew-icon.png" alt="Specrew" height="130" align="middle" />
  &nbsp;&nbsp;
  <img src="docs/assets/specrew-wordmark-light.svg#gh-light-mode-only" alt="Specrew — Governed Agentic SDLC" height="110" align="middle" />
  <img src="docs/assets/specrew-wordmark-dark.svg#gh-dark-mode-only" alt="Specrew — Governed Agentic SDLC" height="110" align="middle" />
</p>

# Specrew

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-0.23.0-blue.svg)](.specrew/config.yml)
[![Status: Alpha](https://img.shields.io/badge/status-alpha-orange.svg)](#current-state)

Specrew combines Spec Kit and Squad into a spec-governed operating model for
AI-assisted software delivery.

## Current State

- Public shipped baseline: **0.23.0**, backed by 23 implementing features
- Alpha software, validated through dogfooding in this repository
- Built today for a single developer running on a single host
- Not yet ready for multi-developer coordination or multi-host operation
- Release truth now has public-facing surfaces in `CHANGELOG.md`,
  `docs\versioning.md`, and the `v0.15.0` / `v0.16.0` / `v0.17.0` / `v0.18.0` / `v0.19.0` / `v0.20.0` tags

## What's working

- `specrew init` bootstraps Spec Kit, Squad, and Specrew governance into a repo
- `specrew start` is the canonical entrypoint and refreshes runtime handoff
  artifacts before launch, with full session-state durability and recovery
- `specrew where` / `specrew status` render the repository's velocity dashboard
  from canonical feature, iteration, and roadmap artifacts, using richer default
  rendering when the terminal can truthfully support it
- **Feature 021 slash-command surface**: seven-command `/specrew.*` surface with discovery and help
  - `/specrew.where` — velocity dashboard ("Where am I?")
  - `/specrew.status` — alias for `/specrew.where`
  - `/specrew.update` — update Specrew assets
  - `/specrew.team` — show team context
  - `/specrew.review` — enter the review workflow
  - `/specrew.help` — show the command catalog (fallback when host-native discovery is unavailable)
  - `/specrew.version` — display version info
- Session-state durability and in-flight progress tracking across system reboots,
  worktree switches, and boundary events (Feature 020)
- Iteration closeout and feature closeout capture immutable dashboard snapshots
  under `specs/<feature>/iterations/<NNN>/dashboard.md` and
  `specs/<feature>/closeout-dashboard.md`
- Squad drives the lifecycle from `speckit.specify` through
  `speckit.implement`, with an explicit clarify gate
- Iteration planning, execution, review, and retrospective artifacts are
  treated as first-class governance surfaces
- Reviewer-regression routing and session-loaded file change detection are
  already built into the operating model
- Optional delegated-agent routing can extend the Copilot-hosted baseline when
  Claude or Codex lanes are configured

## Platform Support

Specrew is developed and validated on **Windows 11** with PowerShell 7.x and runs on
Linux/macOS via the same PowerShell module:

- **Windows**: ✅ Fully validated (primary development platform)
- **WSL (Ubuntu)**: ✅ Manually validated — `specrew init` + `specrew start` launch Copilot's interactive REPL with Squad selected
- **Linux (Ubuntu)**: ✅ Path handling cross-platform; CI matrix configured
- **macOS**: 🔧 Path handling cross-platform; CI matrix configured (no in-house validation runs yet)

See `specs/019-specrew-distribution-module/test-evidence/us5-cross-platform.md` for
detailed cross-platform validation status.

## What's NOT working yet

- Multi-developer reconciliation is not yet a polished default workflow
- Multi-host runtime support is not yet ready for public promises
- Just-in-time brownfield cartography for arbitrary inherited repos is still a
  roadmap item
- The module is currently signed with a self-signed certificate, so
  `Install-Module` must be invoked with `-SkipPublisherCheck` on first install
- External pull requests are not yet part of the alpha operating model

## Recommended Lifecycle

1. **Install Specrew** — pick one path:
   - **PowerShell Gallery** (recommended): `Install-Module Specrew -Scope CurrentUser -SkipPublisherCheck`
     (the `-SkipPublisherCheck` flag is required while the module is signed
     with a self-signed certificate; this will be removed once a CA-issued
     cert is in place)
   - **Prerelease channel** for early adopters who want to validate the next
     version: `Install-Module Specrew -AllowPrerelease -Scope CurrentUser -SkipPublisherCheck`
   - **Local clone** (development workflow):
     `git clone https://github.com/alonf/specrew && Import-Module specrew/Specrew.psd1`
2. **Bootstrap a project** with `specrew init` from inside the target directory.
3. **Start every work session** with `specrew start`; Specrew refreshes runtime
   handoff artifacts before launching Copilot + Squad.
4. **Check status** anytime with `specrew where` (alias: `specrew status`) —
   the velocity dashboard. Use `--ASCII`, `--RecentCount <N>`, and
   `--BarWidth <N>` to force fallback or tune the Recent Shipped density
   without changing lifecycle data.
5. Let Squad drive `specify -> clarify -> plan -> tasks -> implement` from the
   generated feature artifacts.
6. Keep iteration evidence current under `specs\<feature>\iterations\<NNN>\`.
7. Move through planning, implementing, review, and retro in order without
   skipping governance gates or bundling boundary advances.

> **Direct-script invocation** (no module load) still works against a cloned
> repo: `pwsh -File scripts/specrew.ps1 <command>`. The module aliases
> (`specrew`, `specrew-init`, `specrew-start`, `specrew-update`, `specrew-where`,
> `specrew-team`, `specrew-review`, `specrew-version`) are the recommended path because they
> survive PowerShell Gallery installation without any path-dependent
> gymnastics.

## Feature 016 Interaction Model

Feature 016 makes the delivery contract explicit across three linked pillars:

1. **Boundary discipline** — one human authorization advances at most one
   lifecycle boundary.
2. **Essence in console** — boundary handoffs stay substantive enough to review
   without opening files first.
3. **Click-through navigation** — authored review targets use `file:///` URIs
   instead of bare paths.

### Post-Commit Verification Protocol

After every boundary commit that ends with a human-blocked handoff:

1. synchronize any matching `.squad/decisions.md` authorization entries from
   `Commit Reference: pending` to the real boundary hash
2. keep `Recorded At` in canonical UTC seconds precision
   (`YYYY-MM-DDTHH:MM:SSZ`)
3. run a stale-reference scan over the cited `file:///` inspection targets
4. rerun the governed validation lane on the exact committed tree before
   claiming the boundary is ready
5. disclose any remaining defers or gaps instead of implying post-commit work
   already happened

Short and full commit hashes are both accepted once they point at the exact
committed boundary tree.

## PR-at-feature-close Workflow

Specrew currently uses a merge-at-close rhythm:

1. Do the work on a feature branch.
2. Keep the spec, plan, tasks, and iteration evidence current while the branch
   is open.
3. Open or refresh the pull request when the feature is ready for closeout
   review, not as the day-to-day control surface.
4. Merge only after the bounded slice has passing evidence or an explicit
   human-approved deferral.

## Roadmap

- Harden multi-developer and multi-host workflows
- Improve brownfield discovery and packaging for broader reuse
- Keep future feature closeout governance strict enough that release truth stays
  synchronized by default

## Versioning

- `.specrew\config.yml` is the canonical source for the active version and now
  declares **0.23.0**.
- Feature releases use `0.NN.0`, where `NN` tracks the shipped feature ordinal
  (`0.23.0` = Feature 023).
- `0.NN.M` is reserved for hotfixes against an existing shipped feature
  baseline.
- See `docs\versioning.md` for the policy details and `CHANGELOG.md` for the
  retroactive release history.

## License

Specrew is released under the MIT License. See `LICENSE` for the repository
license and `NOTICE.md` for upstream attribution covering derived Squad and Spec
Kit materials.

## Contributing

Specrew is still alpha. Reading, issues, and discussion are welcome now.
External pull requests are intentionally deferred until the operating model and
review boundaries stabilize.

## Key Documents

- `docs\getting-started.md` - bootstrap and quickstart guidance
- `docs\dashboard-guide.md` - dashboard sections, rich/fallback rules, flags, and closeout snapshots
- `docs\roadmap-maintenance.md` - `.specrew/roadmap.yml` maintenance guidance
- `docs\user-guide.md` - day-to-day lifecycle usage
- `docs\github-project.md` - Specrew self-development board guidance
- `docs\versioning.md` - release-numbering policy and tag/changelog rules
- `CHANGELOG.md` - retroactive feature-release history
- `tests\README.md` - integration and smoke-test entrypoints

## Reviewer-regression Governance Highlights

- A human-found defect in work the Squad reviewer already approved or marked
  ready creates a Reviewer Regression Event.
- The next review escalates to the lowest stronger reviewer class that is
  actually available, falls back to an independent reviewer at the same class
  when needed, and pauses for human direction only when neither path is safe.
- Implementer rotation remains capped at two extra owners beyond the original
  implementer unless a human explicitly records a justified exception.

## Session-loaded File Change Detection

When you restart Copilot or Squad, `specrew start` checks whether you committed
changes to session-loaded files such as agent charters, Copilot instructions,
or Spec Kit extension templates. If changes are detected, Specrew pauses the
auto-continue path and asks for confirmation or extra direction before the
lifecycle resumes.
