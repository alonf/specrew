# Iteration 005 Drift Log

**Feature**: F-044 | **Iteration**: 005 — Antigravity Launch Fix + v0.27.0 Release Prep (LIVE-TRACKED)

## Drift #1 — Antigravity-followup spec FR-005 flag set wrong

- **Spec text** (antigravity-followup FR-005 referenced in `hosts/antigravity/handlers.ps1` comment): `agy -p '<prompt>' --output-format json [--cwd <path>]`
- **Shipped reality** (iter-005 T001): `agy -i '<prompt>' --add-dir '<path>' [--dangerously-skip-permissions]`
- **Discovery**: User's iter-004 dogfood produced `flags provided but not defined: -output-format` from agy CLI, with full `agy --help` output pasted inline confirming the actual flag set.
- **Pivot**: iter-005 T001 rewrote `New-AntigravityLaunchInvocation` to match the verified `agy --help` output. Handler-file comment updated to reference iter-005 as the canonical source.
- **Schema impact**: None at the contract level — the host package contract doesn't dictate which flags a host accepts; that's the host's API.
- **User impact**: Positive — `specrew start --host antigravity` now actually launches `agy` instead of failing with rejected flags.
- **Reviewer disposition**: Accepted. Antigravity-followup spec text remains stale and is queued as a follow-up small-fix slice (see [retro.md](./retro.md) Improvement Action 1).

## Surfaced-but-deferred (recorded for traceability)

- **T007 — `proposals/INDEX.md` entries for F-043 + F-044 + Proposal 108**: verified missing from INDEX. Deferred to on-main post-PR-merge chore per "proposals always commit to main, not feature branches" policy. Captured in iter-005 scope.md + closeout-dashboard.
- **CHANGELOG entry length**: The v0.27.0 entry includes a multi-paragraph versioning-drift explanation that may be too long for a CHANGELOG. Future improvement (retro Action 3): split methodology meta-notes into `docs/versioning.md`.
