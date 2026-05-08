# Planner History

Project-specific learnings and patterns discovered during work.

## Patterns

<!-- Append entries below. Format: **Pattern:** description. **Context:** when it applies. -->

## Learnings

- 2026-05-07: Feature `specs\005-stack-aware-quality-bar\` had no active iteration artifacts; execution readiness was repaired by first scaffolding `iterations\001\plan.md` and then `state.md`/`drift-log.md` with the Specrew helpers before replacing the stub with a capacity-bounded execution slice.
- 2026-05-07: For this feature, the executable Iteration 001 slice is `T001`-`T011` (20 story points, Slices A-B / US-1). `T012`-`T018` stay in the approved Phase 1 boundary but are deferred to Iteration 002 to respect `.specrew\iteration-config.yml` capacity.
- 2026-05-07: The execution-readiness gate for this repair was satisfied by recording Alon's explicit session approval text ("OK, continue implementation") in `specs\005-stack-aware-quality-bar\iterations\001\plan.md` and setting the iteration status to `executing`.
- 2026-05-07: The relevant validation path is `extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath . -IterationPath .\specs\005-stack-aware-quality-bar\iterations\001`; repo-wide validation still reports an unrelated blocker in `specs\001-specrew-product\iterations\011`.
- 2026-05-08: For `specs\005-stack-aware-quality-bar\iterations\002`, the mechanical-check foundation tasks `T012` and `T014` trace to `US-3` only because their governing requirements are `FR-027` through `FR-030a`; do not blend them into `US-2` unless the task also carries lifecycle-evidence requirements like `FR-011` or `FR-012`.
- 2026-05-08: When planning a follow-on iteration while the prior iteration still shows `Status: executing`, describe the prior work as a handoff recorded in `state.md` rather than saying the iteration is complete, and keep approval blocked until the iteration boundary is made lifecycle-clean.
- 2026-05-08: When extending `.specify\templates\plan-template.md` for a later quality phase, keep the new section planning-scoped: publish artifact locations, planning placeholders, and explicit later deferrals, but do not imply execution evidence or enforcement that belongs to later tasks.
- 2026-05-08: For bounded Phase 2 hardening work, keep the resolved planning data flat and parallel to the existing Phase 1 profile fields (`phase2_*` metadata plus focus-area/lens/routing arrays) so the template can mirror it without inventing a second planning structure.
