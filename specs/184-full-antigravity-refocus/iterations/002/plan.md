# Iteration Plan: 002

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: planning
**Capacity**: 20/20 story_points
**Started**: 2026-06-17
**Completed**:

<!--
  Validator schema (canonical, enforced by validate-governance.ps1):
  - Iteration Status MUST be one of:
      planning | executing | reviewing | retro | complete | abandoned
    (Common mistakes the validator REJECTS: `approved`, `in-progress`, `done`, `ready`.)
  - Capacity format MUST be `<consumed>/<cap> <effort_unit>` with NO trailing prose on that line.
    Append explanatory notes in the Notes section at the bottom instead.
  - Task Status (in the Tasks table) MUST be one of:
      planned | in-progress | done | needs-rework | deferred | blocked
    (Note `in-progress` uses a hyphen, not an underscore. `done` not `completed`.)
-->

## Scope Summary

| Requirement | Summary | Stories |
| ----------- | ------- | ------- |
| FR-011 | `specrew init` deploys a persistent Specrew coordinator instruction section to every supported host's manifest-declared `InstructionsFile`. | US6 |
| FR-012 | Persistent instruction deployment preserves user-owned file content by replacing only a clearly delimited Specrew-owned section. | US6, US8 |
| FR-013 | Persistent instructions and bootstrap include the exact coordinator and anti-raw-`specify.exe workflow` guard. | US7 |
| FR-014 | Bootstrap orientation front-loads the immediate next Specrew lifecycle action before broader explanatory context. | US7 |
| FR-015 | Shared instruction delivery core remains host-neutral and reads file locations from host manifests. | US8 |
| FR-016 | `specrew update` refreshes managed instruction content and `specrew start` can heal missing or stale managed sections. | US6, US8 |
| FR-017 | Real-host Antigravity validation reruns Opus 4.6 and Gemini Flash dogfood with honest weak-model caveat handling. | US7 |
| FR-018 | Persistent instruction content comes from one packaged static Specrew coordinator template or fragment included in `Specrew.psd1` `FileList`. | US6, US7, US8 |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T001 | Confirm current instruction-file behavior and related proposal posture | FR-011, FR-016, FR-018, SC-011, SC-019, SC-020 | US6 | 2 | Planner, Reviewer | `hosts/**`; `scripts/specrew-init.ps1`; `scripts/specrew-update.ps1`; `scripts/specrew-start.ps1`; `scripts/init/**`; `scripts/internal/**`; `Specrew.psd1`; `proposals/**` | done | claude | 2 | premise confirmed; no split-guard (see discovery-host-landscape.md) |
| T002 | Add packaged coordinator instruction fragment and managed-section merge helper | FR-012, FR-013, FR-018, SC-012, SC-013, SC-020 | US6, US7, US8 | 4 | Implementer | `scripts/internal/**`; `templates/**`; `extensions/specrew-speckit/**`; `.specify/extensions/specrew-speckit/**`; `Specrew.psd1`; `tests/**` | done | claude | 4 | merge helper + lean fragment + 8/8 unit tests |
| T003 | Wire manifest-driven init deployment, update refresh, and start heal | FR-011, FR-015, FR-016, FR-018, SC-011, SC-014, SC-019, SC-020 | US6, US8 | 4 | Implementer | `hosts/**`; `scripts/specrew-init.ps1`; `scripts/specrew-update.ps1`; `scripts/specrew-start.ps1`; `scripts/init/**`; `scripts/internal/**`; `Specrew.psd1`; `tests/integration/**` | done | claude | 4 | deploy/refresh/heal wiring + 6/6 integration tests |
| T004 | Front-load bootstrap action and mirror the anti-raw-Spec-Kit guard | FR-013, FR-014, FR-018, SC-013, SC-015, SC-018 | US7 | 3 | Implementer, Spec Steward | `scripts/internal/specrew-bootstrap-provider.ps1`; `extensions/specrew-speckit/scripts/specrew-bootstrap-provider.ps1`; `.specify/extensions/specrew-speckit/scripts/specrew-bootstrap-provider.ps1`; `scripts/internal/bootstrap/**`; `tests/bootstrap/**` | done | claude | 3 | front-load + single-source guard; mirror parity green |
| T005 | Add automated coverage: instruction merge, FileList, bootstrap ordering, and host-coupling firewall | FR-012, FR-015, FR-016, FR-018, SC-011, SC-012, SC-013, SC-014, SC-015, SC-019, SC-020 | US6, US7, US8 | 4 | Reviewer | `tests/integration/**`; `tests/bootstrap/**`; `tests/unit/**`; `scripts/**`; `hosts/**`; `Specrew.psd1` | done | claude | 4 | firewall: new core guarded + negative test fail-then-pass |
| T006 | Run real-host Antigravity Opus 4.6 and Gemini Flash dogfood evidence | FR-017, SC-016, SC-017, SC-018, TG-005 | US7 | 3 | Reviewer, Human | `specs/184-full-antigravity-refocus/iterations/002/**` | in-progress | claude + human | — | evidence template ready; awaiting human real-host run |

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 20 | Restored global cap; no temporary raise is planned for iteration 002. |
| Iteration Bounding | scope | `scope` keeps requirements fixed; `time` enforces a time ceiling. |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time`. |
| Overcommit Threshold | 1.0 | Warn planners when total estimated effort exceeds 20 story_points (capacity 20 x threshold 1.0). |
| Defer Strategy | manual | If any task expands, stop for a split/defer decision instead of silently raising capacity. |
| Calibration Enabled | true | Retro should compare this 20 SP plan against the iteration 001 26 SP temporary-overcap history. |

## Concurrency Rationale

- Current roster snapshot: Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator.
- Technology and scope signals: PowerShell runtime/deployment code, host manifests, package manifest entries, Markdown instruction content, and Pester-style integration tests dominate.
- Task dependency graph: T001 gates implementation because it verifies whether instruction content exists anywhere today and whether a proposal needs amendment; T002 creates the reusable template/merge primitive; T003 consumes it from init/update/start; T004 can proceed after the guard wording is available; T005 and T006 validate the completed behavior.
- Workstream separability: T004 bootstrap text can run partly in parallel with T003 after T002, but T002/T003/T005 share the same deploy and package surfaces and should stay serial to avoid conflicting edits.
- Shared-surface conflict risk: elevated around `scripts/specrew-init.ps1`, `scripts/specrew-update.ps1`, `scripts/specrew-start.ps1`, `scripts/internal/specrew-bootstrap-provider.ps1`, the extension mirror, `Specrew.psd1`, and `tests/integration/host-coupling-firewall.tests.ps1`.
- Recommendation: keep one implementer workstream. Do not add a same-specialty parallel pair unless the task table is replanned with non-overlapping file globs.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | 1 | Plan artifact, capacity check, and gate packet. |
| Discovery/Spikes | 2 | T001 confirms current behavior, proposal posture, and exact deploy surfaces before implementation. |
| Implementation | 11 | T002-T004 deliver the template/merge helper, init/update/start wiring, and bootstrap front-load/guard. |
| Review | 4 | T005 automated validation plus the first pass of T006 real-host evidence packaging. |
| Rework | 2 | Expected repair buffer for merge/idempotence, package FileList, mirror parity, or weak-model evidence caveats. |

## Traceability Summary

- Requirement scope: FR-011, FR-012, FR-013, FR-014, FR-015, FR-016, FR-017, FR-018, TG-005.
- User stories represented in current scope: US6, US7, US8.
- Requirement coverage: every FR-011 through FR-018 has at least one task.
- Success criteria coverage: SC-011 through SC-020 are covered through T001-T006; SC-014 is explicitly tied to the host-coupling firewall in T003/T005.
- Task traceability: every task maps to at least one scoped FR, SC, or TG.
- Capacity check: 20/20 story_points, exactly at the restored cap. No capacity raise is requested.
- Split guard: if T001 or T003 shows this requires per-host handlers instead of a shared manifest-driven projection, or if T004 requires broader bootstrap/runtime contract rewrites beyond front-loading and guard wording, stop for a human split/defer decision.

## Planned Validation

| Validation | Tasks | Requirement / Criteria | Expected Evidence |
| ---------- | ----- | ---------------------- | ----------------- |
| Scratch init creates or merges every supported host `InstructionsFile` | T003, T005 | FR-011, FR-012, SC-011, SC-012 | Integration test with pre-existing user content in `AGENTS.md`, `CLAUDE.md`, and `.github/copilot-instructions.md`. |
| Exact guard text appears in both persistent instructions and bootstrap | T002, T004, T005 | FR-013, SC-013, SC-015 | Text/order tests pin the exact guard and the immediate-action ordering. |
| Host-neutral delivery reads manifest `InstructionsFile` | T003, T005 | FR-015, SC-014 | Host-coupling firewall negative test rejects Antigravity/`agy` branching or path literals in shared instruction-delivery core. |
| Update refresh and start heal preserve user content | T003, T005 | FR-016, SC-019 | Idempotence tests for init/update/start-heal replace only the managed section. |
| Package source exists | T002, T005 | FR-018, SC-020 | `Specrew.psd1` `FileList` contains the template/fragment and any helper, and validation proves each path exists. |
| Real-host weak-model dogfood | T006 | FR-017, SC-016, SC-017, SC-018 | Machine-local Antigravity Opus 4.6 and Gemini Flash transcript/evidence record; Flash failure keeps the weak-model caveat instead of claiming full parity. |

## Deferred / Out Of Scope

- No feature-closeout, beta, stable, release, or full Antigravity parity claim is authorized in this iteration.
- Release carry-forwards remain open: beta-before-stable, `MigrateLegacyTopLevelEventMap`, and reproducible or explicitly machine-local `agy` evidence.
- No general host-instruction overhaul beyond the shared manifest-declared `InstructionsFile` projection.
- No capacity raise. If the work grows beyond 20 SP, split the iteration.

## Plan Boundary Checks

| Check | Result | Notes |
| ----- | ------ | ----- |
| Capacity arithmetic | PASS | Six planned tasks sum to 20 story_points against the restored 20 SP cap. |
| Traceability | PASS | FR-011 through FR-018 all have task coverage; no orphan tasks found. |
| Host-coupling firewall | PASS | Existing firewall is green; T005 extends it with the required instruction-delivery negative test. |
| Scoped governance validation | PASS | `validate-governance.ps1 -IterationPath specs/184-full-antigravity-refocus/iterations/002 -NoParallel` passed for the target iteration. Existing repository-wide closed-iteration dashboard and handoff warnings remain unrelated to this plan. |
| Whitespace diff | PASS | `git diff --check` found no whitespace errors. |
| Placeholder scan | PASS | No draft placeholders or unchecked checklist markers remain in the iteration 002 plan/state artifacts. |

## Notes

- The planning scaffold helper was attempted before this manual plan was authored, but it failed before writing `plan.md` on an existing StrictMode `.Count` issue. Repairing that helper is not included in this iteration unless it blocks required validation.
- Current host manifests already declare `InstructionsFile`: `AGENTS.md` for Codex/Cursor/Antigravity, `CLAUDE.md` for Claude, and `.github/copilot-instructions.md` for Copilot. The plan relies on that manifest field instead of adding host-name branches.
- The exact guard to pin in both surfaces is: "You are the Specrew Crew coordinator. Drive the lifecycle via the design-workshop skill and the per-boundary speckit slash-commands. Do NOT run the raw specify.exe workflow / bundled SDD engine - it bypasses the governed boundary gates."
- Keep `Status: planning` until the maintainer approves this plan boundary. Approval advances to tasks only; it does not authorize implementation.
