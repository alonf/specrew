# Specrew

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-0.17.0-blue.svg)](.specrew/config.yml)
[![Status: Alpha](https://img.shields.io/badge/status-alpha-orange.svg)](#current-state)

Specrew combines Spec Kit and Squad into a spec-governed operating model for
AI-assisted software delivery.

## Current State

- Public shipped baseline: **0.17.0**, backed by 17 implementing features
- Alpha software, validated through dogfooding in this repository
- Built today for a single developer running on a single host
- Not yet ready for multi-developer coordination or multi-host operation
- Release truth now has public-facing surfaces in `CHANGELOG.md`,
  `docs\versioning.md`, and the `v0.15.0` / `v0.16.0` / `v0.17.0` tags

## What's working

- `specrew init` bootstraps Spec Kit, Squad, and Specrew governance into a repo
- `specrew start` is the canonical entrypoint and refreshes runtime handoff
  artifacts before launch
- `specrew where` / `specrew status` render the repository's velocity dashboard
  from canonical feature, iteration, and roadmap artifacts
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

## What's NOT working yet

- Multi-developer reconciliation is not yet a polished default workflow
- Multi-host runtime support is not yet ready for public promises
- Just-in-time brownfield cartography for arbitrary inherited repos is still a
  roadmap item
- Installable packaging and a polished public CLI distribution are still
  deferred
- External pull requests are not yet part of the alpha operating model

## Recommended Lifecycle

1. Bootstrap a repository with `scripts\specrew-init.ps1`.
2. Start every work session with `scripts\specrew.ps1 start`.
3. Use `scripts\specrew.ps1 where` whenever you want the current project-status
   dashboard.
4. Let Squad drive `specify -> clarify -> plan -> tasks -> implement` from the
   generated feature artifacts.
5. Keep iteration evidence current under `specs\<feature>\iterations\<NNN>\`.
6. Move through planning, implementing, review, and retro in order without
   skipping governance gates or bundling boundary advances.

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
  declares **0.17.0**.
- Feature releases use `0.NN.0`, where `NN` tracks the shipped feature ordinal
  (`0.17.0` = Feature 017).
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
- `docs\dashboard-guide.md` - dashboard sections, flags, and closeout snapshots
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
