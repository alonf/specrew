# Iteration Plan: 002 (Stub)

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: planning
**Capacity**: 0/20 story_points
**Started**: 2026-10-17
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
| FR-001 | The hook-output journal MUST accept concurrent appends from separate hook processes without failure or torn lines. A share mode that permits concurrent appends is preferred. A per-write cross-process lock on that journal only is permitted when fault-injection case (e) shows the share mode alone is insufficient. | — |
| FR-002 | A failed journal append MUST be retried within a bounded window as a backup. Only a failure that persists past it enters a degraded state. | — |
| FR-003 | The degraded state MUST clear on the next successful append and record its recovery time. An unhealthy state left by an older version MUST be treated the same way. | — |
| FR-004 | While degraded, hook output that cannot be journaled MUST be recorded as hashes in per-process outage-buffer files. The integrity check MUST read them before the next prompt decision, and they MUST be flushed into the journal and removed on recovery. | — |
| FR-005 | A typed reply MUST be refused as authority only when it matches journaled or buffered hook output. If the buffer write itself fails, only that turn fails closed. | — |
| FR-006 | Each host adapter MUST normalize its host's payload into a standard turn record (event, typed user text, host, origin) under a declared, tested contract. Origin MUST be one of typed-user, host-injected or unknown. Only typed-user can produce a receipt, and the journal and buffer match MUST apply to every reply. | — |
| FR-007 | A degraded state MUST be disclosed in the affected turn, stating whether the reply was consumed. It MUST also appear in `specrew status` / `where` while degraded, and in session-start orientation. | — |
| FR-008 | A health journal MUST record each transition (class, error text, first-seen, count, recovered-at) with hashes only and no user text. | — |
| FR-009 | When self-recovery fails, the system MUST ask the maintainer one decision, in project terms that pass the banned-noun check and never imply loss when nothing is lost. The recovery action MUST record the receipt of the approving reply. | — |
| FR-010 | A refusal MUST name the actual cause and never attribute a reply to a channel the maintainer did not use. | — |
| FR-011 | An unchanged pending crossing MUST be presented in full once per session and again only after a context gap. In between, the pending decision MAY appear at most as a brief mention inside a reply that answers the maintainer: one line naming the decision and its approval phrase, with no verdict options, no marker and no packet sections. It MUST NOT produce a `Stop hook error`. The duration of a "long gap" is a named tuning value set in the plan. | — |
| FR-012 | The Stop hook MUST NOT block a reply over formatting. It checks substance only: that a needed decision is clear, and that authority is intact. | — |
| FR-013 | Deterministic text the system can supply, such as the dials line and orientation facts, MUST be filled in by the system, marked as system output, and recorded in the hook-output journal, with 0 human-visible cycles. | — |
| FR-014 | The orientation MUST reach the maintainer before the first question of a session. The mechanism is chosen at design-analysis. | — |
| FR-015 | The "presented" check MUST compare a meaning-bearing line set declared once in the shared path: headings, review-target links, question line, approval line, verdict options and marker. It MUST NOT compare the whole draft. | — |
| FR-016 | The adaptation text MUST be one shared sentence, identical on every host and with no numbers or keys. Only the correction-command reference comes from the adapter. | — |
| FR-017 | `.specrew/start-context.json` MUST be the single current-feature pointer, MUST record the branch it was written for, and MUST be updated by every writer that creates or advances a feature. | — |
| FR-018 | The branch is not the feature. Readers MUST resolve the current feature in this order: (1) the in-flight controller or pending crossing; (2) the pointer, if it was written for the current branch; (3) the branch name, as a hint only. A pointer written for another branch is stale. Readers MUST always disclose which source decided (reconciled at design-analysis, iteration 001 DRIFT-001). They MUST ask only when two in-flight features genuinely compete. A Shipped or closed feature MUST never be shown as active while one is in flight. | — |
| FR-019 | The resume "where we are / starting now" lines MUST come from disk only: the pending crossing, `from_commit..HEAD`, and progress. The handover narrative MUST be shown only as context with its age, and flagged when it is stale or names another feature. | — |
| FR-020 | A gate refusal for a missing artifact MUST name the step that produces it. | — |
| FR-021 | Turn drafts MUST be saved to an ignored per-session location that the saving script resolves itself. The three skills MUST name it. | — |
| FR-026 | `feature-closeout -> specify` for a new feature MUST be treated as a cycle reset, like `iteration-closeout -> plan`, in both the crossing calculation and the authorization writer. A feature is new when it differs from the feature whose feature-closeout was last authorized; a re-sync of the same feature is never a reset. The new feature's specify sync MUST open a scoped specify crossing, and a closed feature's history MUST NOT authorize or block another feature's boundaries. On a new-feature reset, all per-feature runtime state MUST be keyed to the new feature: the crossing, the current-feature pointer, and the review-campaign coverage line shown at boundary stops. The out-of-band specify authorization recorded for 202 (`auth-83b0f0c2...`) MUST stay in the append-only ledger as B4F-109's audit trail; it is never rewritten or removed (B4F-109). | — |
| FR-022 | Specrew-owned records written after review, such as the iteration seal and the reviewer scaffold output, MUST NOT count as uncovered source drift. The exact review-ordering slices of B4F-054/056/058/061 are set at iteration-2 design analysis, within the bounds of B4F-074 and B4F-093, and approved there. No broader review redesign. | — |
| FR-023 | The exact-byte package check MUST compare only the declared content scope (B4F-018's rule). No beta4 republish. | — |
| FR-024 | Real hook payloads from Claude, Codex and Copilot MUST be captured as test fixtures, in scratch directories only and never in a governed worktree. The cross-host tests MUST run through each host's real adapter with those payloads, never by calling the shared path directly. | — |
| FR-025 | The B4F-108 fault-injection suite MUST cover cases a-e (a: lock released within the retry window; b: lock held beyond it; c: recovery; d: hook output never counts; e: two real processes appending at once), with case (e) on Windows, macOS and Linux. | — |

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
- Technology and scope signals: Mixed frontend and backend/service signals are present in the scoped requirements.
- Task dependency graph: detailed dependencies are still pending task decomposition in this stub; revisit once the task table is populated.
- Workstream separability: Conflict-heavy signals are present, so keep same-specialty work serial unless ownership boundaries become explicit.
- Shared-surface conflict risk: elevated due to shared-state / cross-cutting cues in scope text.
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

- Requirement scope for this stub: FR-001, FR-002, FR-003, FR-004, FR-005, FR-006, FR-007, FR-008, FR-009, FR-010, FR-011, FR-012, FR-013, FR-014, FR-015, FR-016, FR-017, FR-018, FR-019, FR-020, FR-021, FR-026, FR-022, FR-023, FR-024, FR-025
- User stories represented in current scope: 
- Pending detailed planning: populate the task table, then run specrew-capacity-planning and specrew-traceability-check before approval.
- Overcommit guardrail: compare planned task effort against the configured threshold and record any required deferrals from the lowest-priority requirement slices before leaving planning.

## Notes

- This stub captures the planned scope pending detailed planning in the Specrew Planning ceremony.
- Add task rows only for work that is traceable to the scoped requirements above.
- Keep Status: planning until the plan is fully decomposed and approved.
- If task effort exceeds the configured threshold, make the deferral decision explicit in this plan before execution starts and name the lowest-priority requirement slices proposed for deferral.