# Iteration Plan: 008

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: executing
**Capacity**: 14/20 story_points
**Started**: 2026-06-10
**Completed**:

<!--
  Validator schema: Iteration Status one of planning|executing|reviewing|retro|complete|abandoned.
  Capacity `<consumed>/<cap> <unit>`. Task Status one of
  planned|in-progress|done|needs-rework|deferred|blocked.
-->

## Scope Summary

Iteration 008 finishes the hook-driven era now that all four hooked hosts are GREEN. iter-7 achieved claude
content-parity (FR-023); its FR-024 multi-host completion LANDED this session during the cross-host dogfood —
codex entered the PARITY SET after two codex-format fixes were found and shipped (the SessionStart `hooks.json`
needed codex's `{ hooks: { <Event> } }` wrapper, and the dispatcher output needed
`hookSpecificOutput.additionalContext` instead of the flat form), alongside the mandatory orientation banner
(hoisted + expanded in `Format-BootstrapDirective`) and real `-SpecrewVersion` threading. claude, codex, and
copilot are now observed governed; antigravity stays launcher-only by design (no hook).

This iteration delivers the three maintainer asks on that green baseline:

1. **Docs (FR-008):** reposition `specrew start` as an OPTIONAL host-selector / launcher, not the entry —
   after `specrew init` the user just opens their host and the SessionStart hook drives.
2. **Intake at init (FR-025, new):** capture the user-profile dials at `specrew init` (guarded interactive),
   so hook-only users still get the expertise adaptation; retain the `specrew start` fallback + a hook nudge.
3. **Handover validation (FR-022 / SC-003 / SC-008 / SC-009):** validate the rolling handover across exit
   modes (`/exit`, double Ctrl+C, window close, process kill), document the test procedure, and fix any
   agent-authoring gap the validation surfaces.

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Status |
| ---- | ----- | ----------- | ----- | ------ | ----- | ------ |
| T048 | Docs: reposition `specrew start` as an optional host-selector (README Quick Start + getting-started "Start the first feature" + host-pick note + CHANGELOG); the SessionStart hook drives after `specrew init` | FR-008, FR-001 | US-2 | 3 | Implementer | done |
| T049 | Move user-profile intake to `specrew init` (ask ONLY when profile ABSENT and session INTERACTIVE; skip silently on `-Force`/CI; retain `specrew start` fallback; bootstrap directive nudges `/specrew-user-profile` when absent) | FR-025 | US-1 | 5 | Implementer | planned |
| T050 | Handover validation across exit modes + test-procedure doc (`/exit`, double Ctrl+C, window close, kill); confirm the crash-safe agent-authored body persists + resume restores; fix any authoring gap | FR-022, FR-009 | US-1 | 6 | Implementer | planned |

**Capacity: 14/20** (T048 3 + T049 5 + T050 6 = 14). The FR-024 codex / FR-004 banner / version fixes were
delivered as iter-7's multi-host completion (already shipped + validated) and are NOT re-counted here.

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 20 | Maximum planned effort before overcommit guidance applies. |
| Iteration Bounding | scope | `scope` keeps requirements fixed; `time` enforces a time ceiling. |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time`. |
| Overcommit Threshold | 1.0 | Warn planners when total estimated effort exceeds 20 story_points. |
| Defer Strategy | manual | How planning chooses deferrals when over capacity. |
| Calibration Enabled | true | Retrospectives should suggest future capacity adjustments. |

## Traceability Summary

- T048 -> FR-008 (specrew start prompts + docs updated), FR-001 (the hook is the primary trigger).
- T049 -> FR-025 (NEW this iteration: user-profile intake capturable at init, guarded interactive).
- T050 -> FR-022 (rolling-handover body agent-authored), FR-009 (handover wired through hook deployment),
  SC-003 / SC-008 / SC-009 (Stop round-trip + hard-kill crash-safety).
- Reconciled this session (iter-7 FR-024 completion, not re-counted here): codex hooks.json wrapper +
  dispatcher hookSpecificOutput output + lean-pointer delivery; mandatory banner hoist+expand (FR-004);
  real version threading.

## Notes

- All hooked hosts (claude / codex / copilot) observed governed; antigravity launcher-only (FR-024).
- Sequence: T048 docs (lowest risk) -> T049 intake -> T050 handover validation.
- T050 may surface a real agent-authoring gap (the copilot dogfood showed the body was not authored); if so,
  the fix (the directive's handover-protocol instruction / its prominence) is in scope.
- **Cleanup candidate — `.gitignore` gap:** `.specrew/runtime/` is NOT ignored (`bootstrap-journal.jsonl`,
  `handover-journal.jsonl`, `refocus-state-*.json`, `session-marker.json` show as untracked runtime noise),
  and `.specrew/last-validator-summary.json` is gitignored yet still TRACKED (committed before the ignore).
  Fix: add `.specrew/runtime/` to `.gitignore` and `git rm --cached` the stale-tracked validator summary.
- **Finding — iter-4 state corruption (reverted this session):** tooling rewrote `iterations/004/state.md`
  from `complete / iteration-closeout` to `not-started / before-implement` and created a bogus
  `iterations/004/tasks-progress.yml` (2026-06-10T09:10). A progress-tracker/dashboard mis-resolved the
  ACTIVE iteration as the already-closed iter-4 — same wrong-context-resolution class as the refocus
  session-id bug (GitHub #2446). Reverted; file as a candidate.
