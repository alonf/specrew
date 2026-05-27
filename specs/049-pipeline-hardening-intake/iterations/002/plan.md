# Iteration Plan: 002 (Stub)

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: planning
**Capacity**: 0/20 story_points
**Started**: 2026-05-27
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
| FR-001 | System MUST supply a Docker-based test runner using a Linux-based PowerShell container (`mcr.microsoft.com/powershell:lts-ubuntu-22.04`). | — |
| FR-002 | The harness MUST download and install the previous stable version (`0.27.6`) in a clean environment as the baseline. | — |
| FR-003 | The harness MUST verify that **every** item listed in the packaged candidate's `Specrew.psd1` `FileList` successfully unpacked on disk. | — |
| FR-004 | The harness MUST run `specrew update` and verify that the local project structure is updated cleanly, and mirror parity checks return `PASS`. | — |
| FR-005 | `.github/workflows/publish-module.yml` MUST execute this Docker harness as a blocker before any release is pushed to PSGallery. | — |
| FR-012 | The pre-publish verification suite MUST detect manifest version-pin drift before publication proceeds, so module and runtime version declarations cannot silently diverge. | — |
| FR-013 | The system MUST prevent `specrew update` from duplicating Squad team/routing entries. The template merge logic inside `scripts/specrew-update.ps1` / `deploy-squad-runtime.ps1` MUST perform a clean merge instead of appending duplicate role rows. | — |
| FR-014 | `specrew update --info` MUST default to checking and showing the actual latest version published on **PSGallery**, rather than using a hardcoded or misleading `UpstreamLatest` from local manifests (promotes Proposal 049). | — |
| FR-006 | System MUST contain `docs/troubleshooting.md` addressing: PSGallery side-by-side caches, FileList drops, deploy-script exceptions, stale-state recovery, and clean-reinstall flows. | — |
| FR-007 | `docs/troubleshooting.md` MUST be registered in `Specrew.psd1` `FileList` immediately upon creation. | — |
| FR-015 | `docs/troubleshooting.md` MUST explicitly document the naming distinction and functional boundary between `specrew update` (project environment deployment) and `Update-Module Specrew` (module software upgrade). | — |
| FR-016 | `README.md`, `docs/getting-started.md`, and `docs/user-guide.md` MUST cross-reference `docs/troubleshooting.md` so recovery guidance is discoverable from the primary onboarding and usage paths. | — |
| FR-017 | `docs/troubleshooting.md` MUST capture the Shape-5 lesson that accepted review evidence must match committed tree state, so maintainers understand why working-tree-only files are not durable delivery. | — |
| FR-008 | `/speckit.specify` MUST support **4 target personas**: | — |
| FR-009 | The system MUST supply a **12-category intake catalog** representing comprehensive software parameters. | — |
| FR-010 | Intake MUST dynamically branch into **Mode A (Direct Confirmation)**, **Mode B (Targeted Clarify)**, or **Mode C (Full Interview)** based on the completeness of initial input. | — |
| FR-011 | Intake forms MUST support `"Other"` and `"I don't know, you decide"` options, triggering proactive agent domain research when selected. | — |
| FR-018 | Governance validation MUST detect missing `=== SPECREW HANDOFF ===` evidence at boundary or lifecycle stops and surface the gap as an explicit handoff warning. | — |
| FR-019 | Governance validation MUST distinguish trigger-bypass artifact gaps from generic missing-artifact failures when an iteration otherwise appears fully closed. | — |
| FR-020 | Governance validation MUST detect canonical Specrew artifacts written into ephemeral host session-scratch locations and warn that they are outside the canonical feature path. | — |
| FR-021 | Governance validation and boundary enforcement MUST detect state advances across human-judgment boundaries that lack matching human verdict history, preventing silent state progression from being treated as valid. | — |
| FR-022 | Governance validation MUST compare accepted review evidence against the cited Tree Under Review and block iteration closeout if production files cited as delivered evidence are absent from that tree; test-only evidence mismatches may remain warning-level findings. | — |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |

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
- Technology and scope signals: No single specialty dominates yet; treat the slice as general product work until task decomposition adds sharper evidence.
- Task dependency graph: detailed dependencies are still pending task decomposition in this stub; revisit once the task table is populated.
- Workstream separability: Current scope does not yet prove enough safe parallelism for same-specialty expansion; default to a smaller serial team until tasks are clearer.
- Shared-surface conflict risk: no elevated shared-surface warning inferred yet.
- Prior reviewer ownership/hotspot evidence: No prior reviewer hotspot signals were found for this feature.
- Recommendation: do not propose Junior/Senior same-specialty expansion until the task table and ownership boundaries make safe parallelism explicit. If a same-specialty pair is approved later, record `Owner File Globs` for the parallel tasks or keep the work serial.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | TBD | Populate after task decomposition and approval gating |
| Discovery/Spikes | TBD | Capture any required risk-reduction work revealed during planning |
| Implementation | TBD | Sum planned delivery tasks once the task table is complete |
| Review | TBD | Estimate review/demo effort after verdict flow is defined |
| Rework | TBD | Expected needs-work buffer if review finds gaps |

## Traceability Summary

- Requirement scope for this stub: FR-001, FR-002, FR-003, FR-004, FR-005, FR-012, FR-013, FR-014, FR-006, FR-007, FR-015, FR-016, FR-017, FR-008, FR-009, FR-010, FR-011, FR-018, FR-019, FR-020, FR-021, FR-022
- User stories represented in current scope: 
- Pending detailed planning: populate the task table, then run specrew-capacity-planning and specrew-traceability-check before approval.
- Overcommit guardrail: compare planned task effort against the configured threshold and record any required deferrals from the lowest-priority requirement slices before leaving planning.

## Notes

- This stub captures the planned scope pending detailed planning in the Specrew Planning ceremony.
- Add task rows only for work that is traceable to the scoped requirements above.
- Keep Status: planning until the plan is fully decomposed and approved.
- If task effort exceeds the configured threshold, make the deferral decision explicit in this plan before execution starts and name the lowest-priority requirement slices proposed for deferral.