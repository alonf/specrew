# Drift Log: Iteration 001

**Schema**: v1

<!--
  Markdown authoring note (Specrew lifecycle convention):

  When you add new drift events to this file, watch for MD032 (blanks-around-lists).
  A sentence ending with a colon, immediately followed by a bullet list, is the most
  common violation. Always put a BLANK LINE between the colon line and the list:

      BAD:                              GOOD:
      Resolution steps:                 Resolution steps:
      - Step one                        <— blank line here
      - Step two                        - Step one
                                        - Step two

  The F-033 pre-boundary markdownlint gate runs markdownlint-cli --fix on .md
  changes before every boundary-sync write, so most violations auto-fix — but the
  blank line you write in the first place avoids the cleanup churn.
-->

## Summary

**Total drift events**: 2
**Resolution rate**: 100% (2/2 resolved)
**Specification drift**: 2 detected, 2 resolved (capacity model; plan-vs-codebase path convention)

## Events

### D-001 — Capacity-model drift: tasks decompose to 139 SP vs spec 45–65 envelope (RESOLVED 2026-05-31, spec-updated)

**Detected**: 2026-05-31 at before-implement re-verification (reviewer-standard capacity check).

**Drift**: The spec capacity model (Governance Alignment + TG-003 + TG-005) approves ~45–65 SP total across 4 iterations with per-iteration caps (Iter 1 ≤20, Iter 2 12–18, Iter 3 10–15, Iter 4 8–12). The tasks.md per-task `[effort: N SP]` markup sums to materially more, and every iteration breaches its cap:

- Iteration 1: 28 SP actual vs ≤20 cap (summary asserts 18)
- Iteration 2: 54 SP actual vs 12–18 cap (summary asserts 18)
- Iteration 3: 29 SP actual vs 10–15 cap (summary asserts 14)
- Iteration 4: 28 SP actual vs 8–12 cap (summary asserts 12)
- Feature total: 139 SP actual vs 62 stated vs 45–65 approved envelope

**Root cause**: the per-task SP markup added during the 48→97 task expansion (commit `3da2b23b`) was never reconciled with the "Effort Verification & SP Allocation" summary table, which retained the original 62 SP estimate. All four iteration "✓" marks are arithmetically false against the documented verification method (line 310: "Reviewers can compute iteration totals by summing effort values").

**Why it blocks**: TG-005 makes Iteration 1 ≤20 SP a hard requirement and the iteration acts as a dependency gate; the systemic 2.2× envelope breach means the approved spec scope and the executable plan disagree about the size of the work.

**Resolution** (spec-updated, 2026-05-31): Architect chose "re-estimate first." All 97 tasks were honestly re-estimated against an F-054-anchored rubric (~0.5 SP/task baseline + justified code premium); the honest total is **~60.5 SP — within the 45–65 envelope** (the 139 figure was inflation from the 48→97 expansion, not real scope). One residual breach remained: original Iteration 2 packed four user stories (~23 SP) over its cap, so per "split, don't raise" it was split into **Iteration 2a** (US3+US4, ~10 SP) and **Iteration 2b** (US5+US6, ~13 SP). Final structure: 5 iterations, each ≤20 SP (1 ~11, 2a ~10, 2b ~13, 3 ~13.5, 4 ~13).

**Reconciliation applied**:

- tasks.md: per-task `[effort]` markup rewritten to re-estimate; Iter 2 split into 2a/2b sections; false "Effort Verification" summary replaced; traceability matrix + quality gates + dependency graph updated.
- spec.md: TG-003 delivery windows, Governance Alignment capacity model, and Assumptions iteration-slicing updated to 5 iterations / ~60.5 SP / ≤20 cap.
- plan.md: Summary, Technical Context scale, Iteration Structure (Iter 2 → 2a/2b), Constitution Capacity Gate, and requirement-traceability matrix updated.
- iterations/001/plan.md: scoped to FR-001..006, task table T001-T019 populated at re-estimated efforts, capacity 11/20.
- Evidence: [capacity-reestimate.md](capacity-reestimate.md).

Drift closed; before-implement capacity precondition now satisfiable.

### D-002 — Plan-vs-codebase path convention (RESOLVED 2026-05-31, human-decision)

**Detected**: 2026-05-31 at the start of implementation (T001-T005).

**Drift**: plan.md / tasks.md / contracts referenced invented script paths — `scripts/config-management.ps1`, `scripts/file-classification.ps1`, and `scripts/specrew-cli.ps1`. Codebase audit: the real module has no such files; the CLI is `scripts/specrew.ps1` dispatching `switch ($Command)` to eight `scripts/specrew-<cmd>.ps1` commands, with 14 helpers under `scripts/internal/`. Following the plan literally would make F-051 the one feature with a non-conforming command-script pattern.

**Resolution** (human-decision, implementation-aligned-to-codebase-idiom): the codebase convention is authoritative; plan paths were invented. F-051 code lands as:

- `scripts/specrew-config.ps1` — new `config get|set session_mode` command (9th `specrew-*.ps1`)
- `config` case added to `scripts/specrew.ps1` dispatch switch
- `scripts/internal/session-config.ps1` + `scripts/internal/file-classification.ps1` — helper logic
- defaults + gitignore + git-rm-cached wired via `scripts/specrew-init.ps1`

**Reconciliation applied**: tasks.md T004/T005/T009/T010/T012 descriptions + iterations/001/plan.md Owner File Globs (T004/T005/T006/T009/T010/T011/T012/T013) updated to the real paths. Drift closed; TDD implementation proceeds on the idiomatic layout.

### Resolution Strategies (Unused)

The following resolution strategies remain available if drift is detected later in execution:

- **spec-updated**: Update the spec to reflect implementation choice
- **implementation-reverted**: Revert implementation to match spec
- **deferred**: Mark drift as deferred to next iteration
- **human-decision**: Escalate to Alon for resolution

### Notes

- This artifact was scaffolded before review starts so drift can be logged immediately when detected.
- Replace the zero-drift summary with real counts when the first drift event is recorded.
