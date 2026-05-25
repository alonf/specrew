# Iteration State: 005

**Schema**: v1
**Last Completed Task**: T008 (Verification sweep)
**Tasks Remaining**: (none)
**In Progress**: (none)
**Baseline Ref**: 6eb1e022
**Updated**: 2026-05-25T00:30:00Z
**Current Phase**: iteration-closeout
**Iteration Status**: complete

**Feature**: F-044 Per-Host Architecture Refactor
**Branch**: `multi-host-integration-refactor`
**Iteration**: 005 — Antigravity Launch Fix + v0.27.0 Release Prep (LIVE-TRACKED)
**Started**: 2026-05-24
**Closed**: 2026-05-24

## Execution Summary

- T001 done: `New-AntigravityLaunchInvocation` rewritten with verified `agy --help` flag set — `-i <prompt> --add-dir <path>` (interactive). `ConvertTo-AntigravityFlag --allow-all` returns `--dangerously-skip-permissions`. Old `-p` / `--output-format` / `--cwd` flags removed (agy CLI rejected them).
- T002 done: `Specrew.psd1` ModuleVersion bumped 0.26.0 → 0.27.0. CHANGELOG entry for v0.27.0 documents F-043 + F-044 5-iteration arc + versioning-drift note.
- T003 done: New `tests/integration/host-detection-ux.tests.ps1` with 7 assertions covering iter-004 helper + parity + BinaryAliases canary + first-run probe + iter-005 antigravity launch shape. All pass.
- T004 done: New `tests/integration/post-bootstrap-output.tests.ps1` with 5 assertions covering iter-003 Bug 5 regression (no "Squad drives"/"Squad agent"; canonical team path mentioned; antigravity in --host list; translation flow explained). All pass.
- T005 done: New `tests/integration/skill-templates.tests.ps1` with assertion covering iter-003 Bug 2 regression — all 11 skill templates (7 directory-style + 4 generic-style) have YAML frontmatter. All pass.
- T006 done: README.md, docs/getting-started.md, docs/user-guide.md updated — host count v0.26.0 → v0.27.0; Antigravity added to host table; deferred-host language removed; F-043 + F-044 added to "What's coming" roadmap; baseline version bumped.
- T007 done (partial): `proposals/INDEX.md` verified to lack F-043/F-044/Proposal-108 entries — deferred to post-PR-merge on-main chore per "proposals always commit to main, not feature branches" rule.
- T008 done: All 7 host-related integration test suites green (host-registry / crew-bootstrap-contract / host-coupling-firewall / multi-host-launch-path / host-detection-ux / post-bootstrap-output / skill-templates).

Parse-check: pass on all touched files (3 production scripts + 3 new test files + Specrew.psd1).
Markdownlint: not re-run (touched docs are README + getting-started + user-guide + CHANGELOG; previously clean — could verify in T009 if needed).
Validator: deferred (will run after commit to scope iter-005 in the diff).
