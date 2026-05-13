# Specrew

Specrew combines Spec Kit and Squad into a spec-governed operating model for
AI-assisted software delivery.

## Current State

- Public shipped baseline: **0.14.0**, backed by 14 implementing features
- Alpha software, validated through dogfooding in this repository
- Built today for a single developer running on a single host
- Not yet ready for multi-developer coordination or multi-host operation
- Feature 015 Iteration 001 now fixes the public landing surfaces; Iteration 002
  will reconcile changelog, tags, versioning docs, and validator warnings

## What's working

- `specrew init` bootstraps Spec Kit, Squad, and Specrew governance into a repo
- `specrew start` is the canonical entrypoint and refreshes runtime handoff
  artifacts before launch
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
3. Let Squad drive `specify -> clarify -> plan -> tasks -> implement` from the
   generated feature artifacts.
4. Keep iteration evidence current under `specs\<feature>\iterations\<NNN>\`.
5. Move through planning, executing, reviewing, and retro in order without
   skipping governance gates.

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

- Finish Iteration 002 public-readiness work: version reconciliation,
  `docs/versioning.md`, `CHANGELOG.md`, release tags, and advisory validator
  warnings
- Harden multi-developer and multi-host workflows
- Improve brownfield discovery and packaging for broader reuse
- Keep future feature closeout governance strict enough that release truth stays
  synchronized by default

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
- `docs\user-guide.md` - day-to-day lifecycle usage
- `docs\github-project.md` - Specrew self-development board guidance
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
