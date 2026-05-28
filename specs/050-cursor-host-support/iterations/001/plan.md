# Iteration Plan: 001 (Stub)

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: reviewing
**Capacity**: 6/20 story_points
**Started**: 2026-05-28
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

Iteration 001 scope = core package + skill target. FR-005/006/007 (tests) → iteration 002; FR-008 (docs) → iteration 003.

| Requirement | Summary | Stories |
| ----------- | ------- | ------- |
| FR-001 | `hosts/cursor/host.psd1` manifest (F-044 schema): Kind, DisplayName, Status=supported, SchemaVersion, MenuPriority=1.5, Binary=cursor-agent, InstallUrl/InstallGuidance, SkillRoot=.cursor/rules, HasUserSlashCommandSurface=$false, AgentDir=.cursor/rules/, InstructionsFile=AGENTS.md, PreferredAgent, HandlersFile, CoordinatorRulesFile | US1, US4 |
| FR-002 | 5-function contract in `hosts/cursor/handlers.ps1` (canonical names: New-CursorLaunchInvocation, ConvertTo-CursorFlag, Test-CursorRuntimeInstalled, Get-CursorSignals, Install-CursorCrewRuntime) | US1, US3 |
| FR-003 | Add `cursor`→`.cursor/rules` entry to hardcoded `Get-ActiveSkillRoots` in `extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1` (3→4 entries) | US2 |
| FR-004 | Registry auto-discovery via `hosts/_registry.ps1` directory scan (no registry code change) | US1, US4 |
| FR-009 | Binary name `cursor-agent` (RESOLVED) in manifest + `New-CursorLaunchInvocation` | US1 |
| FR-010 | Deploy to `.cursor/rules/*.mdc` (RESOLVED); SkillRoot/HasUserSlashCommandSurface/InstructionsFile set; --plugin-dir OUT of scope | US2, US3 |
| FR-011 | Status=supported (CLI-drivable); INTERACTIVE launch `cursor-agent "<prompt>" --workspace` (RESOLVED; reconciled to interactive 2026-05-29 DRIFT-004); no preview downgrade | US1 |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T001 | Author `host.psd1` manifest | FR-001, FR-009, FR-010, FR-011 | US1 | 0.5 | Implementer | `hosts/cursor/host.psd1` | done | claude | — | pass |
| T002 | `New-CursorLaunchInvocation` + unit test | FR-002, FR-009, FR-011 | US1 | 1 | Implementer | `hosts/cursor/handlers.ps1`, `tests/hosts/cursor.tests.ps1` | done | claude | — | pass |
| T003 | `ConvertTo-CursorFlag` + unit test | FR-002 | US1 | 0.5 | Implementer | `hosts/cursor/handlers.ps1`, `tests/hosts/cursor.tests.ps1` | done | claude | — | pass |
| T004 | `Test-CursorRuntimeInstalled` + unit test | FR-002 | US1 | 0.5 | Implementer | `hosts/cursor/handlers.ps1`, `tests/hosts/cursor.tests.ps1` | done | claude | — | pass |
| T005 | `Get-CursorSignals` + unit test | FR-002 | US1 | 0.5 | Implementer | `hosts/cursor/handlers.ps1`, `tests/hosts/cursor.tests.ps1` | done | claude | — | pass |
| T006 | `Install-CursorCrewRuntime` (→.cursor/rules/*.mdc, dry-run, idempotent) + unit test | FR-002, FR-010 | US3 | 1 | Implementer | `hosts/cursor/handlers.ps1`, `tests/hosts/cursor.tests.ps1` | done | claude | — | pass |
| T007 | Author `coordinator-rules.psd1` | FR-001 | US1 | 0.25 | Implementer | `hosts/cursor/coordinator-rules.psd1` | done | claude | — | pass |
| T008 | Add cursor entry to `Get-ActiveSkillRoots` | FR-003 | US2 | 0.5 | Implementer | `extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1` | done | claude | — | pass |
| T009 | Add `hosts/cursor/*` to `Specrew.psd1` FileList | FR-001 | US1 | 0.25 | Implementer | `Specrew.psd1` | done | claude | — | pass |
| T010 | Verify registry discovery + manifest validity + firewall test green | FR-004 | US4 | 1 | Implementer | `tests/hosts/cursor.tests.ps1` | done | claude | — | pass |

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 20 | Maximum planned effort before overcommit guidance applies. |
| Iteration Bounding | scope | `scope` keeps requirements fixed; `time` enforces a time ceiling. |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time`. |
| Overcommit Threshold | 1.0 | Warn planners when total estimated effort exceeds 20 story_points (capacity 20 x threshold 1.0). |
| Defer Strategy | manual | How planning should choose deferrals when the iteration is over capacity. |
| Calibration Enabled | true | When true, retrospectives should suggest future capacity adjustments. |

## Concurrency Rationale

- Current roster snapshot: Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator
- Technology and scope signals: Backend/service-oriented signals dominate the scoped requirements.
- Task dependency graph: detailed dependencies are still pending task decomposition in this stub; revisit once the task table is populated.
- Workstream separability: The scoped requirements suggest multiple potentially separable workstreams, so same-specialty expansion may be justified after task decomposition.
- Shared-surface conflict risk: no elevated shared-surface warning inferred yet.
- Prior reviewer ownership/hotspot evidence: No prior reviewer hotspot signals were found for this feature.
- Recommendation: do not propose Junior/Senior same-specialty expansion until the task table and ownership boundaries make safe parallelism explicit. If a same-specialty pair is approved later, record `Owner File Globs` for the parallel tasks or keep the work serial.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | done | spec→clarify→plan→tasks complete; this iteration plan + hardening gate prepared |
| Discovery/Spikes | 0 | Empirical CLI verification done at clarify; no spikes needed |
| Implementation | 5.75 | Sum of T001–T010 |
| Review | ~1 | Cross-reviewer signoff (Charter Item 8) + reviewer artifacts |
| Rework | buffer | Within 6/20 capacity headroom |

## Traceability Summary

- Requirement scope for iteration 001: FR-001, FR-002, FR-003, FR-004, FR-009, FR-010, FR-011 (core package + skill target).
- Deferred to later iterations: FR-005, FR-006, FR-007 (tests → iter 002); FR-008 (docs → iter 003). Per-function unit tests still authored alongside functions in iter 001.
- User stories represented: US1 (launch), US2 (skills→rules), US3 (crew agents→rules), US4 (menu/discovery).
- Traceability check: PASS — every iteration-001 task (T001–T010) maps to ≥1 in-scope FR; every in-scope FR has ≥1 task. See feature-level [tasks.md](../../tasks.md) matrix.
- Overcommit guardrail: planned 5.75 SP vs capacity 20 (threshold 1.0) — well under; no deferrals required.

## Notes

- Iteration 001 = Cursor host package core (manifest, 5 contract functions, skill-root entry, FileList, registry verification).
- Hardening gate ([quality/hardening-gate.md](./quality/hardening-gate.md)) Overall Verdict: ready, with one `deferred-with-approval` item (`mirror-parity-integrity`) requiring explicit human acknowledgement: the FR-003 source edit's `.specify/` mirror sync is deferred to the controlled post-merge deploy per Parallel-Work Charter Items 2+3 (no `.specify/extensions/` edit, no `specrew update` in this worktree).
- Parallel-Work Charter active: ModuleVersion pinned `0.29.0`; F-049 PR merges before F-050; beta-before-stable publish; cross-reviewer at signoff.
- **FEATURE-CLOSEOUT ACTION (cross-reviewer contract, 2026-05-29)**: between PR merge and beta publish, sync the FR-003 source edit into the `.specify/` mirror — i.e. apply the `Get-ActiveSkillRoots` cursor entry to `.specify/extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1` via the controlled deploy/`specrew update` step. Without this, downstream installs after F-050's beta carry the source edit WITHOUT the mirror update. This closes the `mirror-parity-integrity` deferred-with-approval item.
- before-implement APPROVED by Alon Fliess 2026-05-29 (cross-reviewer verified, mirror-parity acknowledged); iteration status advances planning → executing.