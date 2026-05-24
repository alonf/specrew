# Iteration 002 Drift Log

**Feature**: F-044 | **Iteration**: 002

Drift = anything that diverged from the iter-001 review-driven plan during implementation. Documenting drift honestly is required by Specrew's review-gate discipline (Proposal 073 Review Evidence Integrity).

## Drift #1 — W-4 sentinel implementation pivot (advisor-caught)

- **Original plan**: Prepend inline `<!-- Specrew-managed: ... -->` HTML comment to all 4 hosts' charter/agent files as the marker.
- **Mid-iteration discovery**: Advisor flagged that Copilot's `.squad/agents/<role>/charter.md` is consumed by Squad CLI as the charter BODY verbatim — leading HTML comment could break Squad's parser.
- **Pivot**: Introduced `Write-SpecrewManagedSidecar` helper writing a sidecar marker file (`<path>.specrew-managed`) for Copilot only. Other 3 hosts (Claude/Codex/Antigravity) still use inline comments since their formats (YAML frontmatter, TOML headers) tolerate comments natively.
- **Schema impact**: Adds an optional sidecar marker file convention. `Test-SpecrewManagedFile` checks both inline comment AND sidecar marker.
- **User impact**: Positive — Squad CLI parse safety preserved; sentinel mechanism uniform across hosts via the helper.
- **Reviewer disposition**: Accepted. Documented as the canonical sentinel pattern for any future host whose subagent format cannot tolerate inline comments.

## Deferred-to-on-main (not drift but recorded for traceability)

- **W-7 + W-8**: Proposal 108 file + INDEX.md entry must land on `main` per "proposals always commit to main, not feature branches" policy. Tracked as follow-up chore in `closeout-dashboard.md`.

## Cross-feature note

- **A-1 host-gate `-NoLaunch` carve-out**: bug introduced by F-043 commit `755c87f1`, but fix lives in F-044 iter-002. Cross-referenced in F-043 iter-001 [`drift-log.md`](../../../043-multi-host-onboarding/iterations/001/drift-log.md) § Drift #4.
