# Iteration Plan: 001

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: complete
**Capacity**: 7/20 story_points
**Started**: 2026-05-20
**Completed**: 2026-05-20

## Scope Summary

| Requirement | Summary | Stories |
| ----------- | ------- | ------- |
| FR-001 | Fresh project bootstrap MUST deploy each of the seven existing Specrew slash commands (`where`, `status`, `update`, `team`, `review`, `help`, `version`) to `.claude/skills/`, `.github/skills/`, and `.agents/skills/`. | — |
| FR-002 | The deployed command definitions across the three supported project skill locations MUST remain content-identical and managed as one logical deployment set. | — |
| FR-003 | Every deployed `SKILL.md` MUST include YAML frontmatter with a lowercase-hyphen `name`, a non-empty `description`, and optional `allowed-tools` where tool restrictions are part of the command contract; the existing body guidance MUST remain intact. | — |
| FR-004 | All active user-facing, operational, and governance references to the slash-command catalog MUST use the `/specrew-X` hyphenated form, while historical pre-v0.24.0 records remain unchanged. | — |
| FR-005 | `specrew update` MUST remove legacy `.copilot/skills/specrew-*` directories only when they are confirmed to be Specrew-managed; unmanaged or third-party content MUST be preserved and surfaced as leftover non-discoverable content. | — |
| FR-006 | Automated validation MUST add three new integration tests covering multi-path deployment, frontmatter validity, and legacy-path migration. | — |
| FR-007 | All pre-existing slash-command validation coverage MUST remain active and pass against the hyphenated, multi-host surface with no skipped assertions. | — |
| FR-008 | Release readiness for v0.24.0 MUST include a prerelease validation cycle through v0.24.0-beta.1 in a clean PowerShell session, verifying bootstrap deployment, frontmatter validity, migration behavior, and manual `/specrew-where` discoverability in Claude Code or GitHub Copilot CLI before stable promotion. | — |
| FR-009 | The v0.24.0 release line MUST truthfully describe this fix in release metadata, including restored slash-command discoverability in Claude Code and GitHub Copilot CLI, host-neutral `.agents/skills/` deployment, and cleanup of managed legacy `.copilot/skills/` directories on update. | — |
| FR-010 | Proposal 058 MUST be reframed to non-skill per-host instruction-file harmonization only, with explicit cross-reference that Feature 024 resolves the skill-surface portion. | — |
| FR-011 | The specification and downstream lifecycle artifacts MUST preserve the form-vs-meaning rationale for this feature: slash commands are not considered restored when files merely exist on disk; they are restored only when the published surface is discoverable and the messaging is truthful. | — |
| FR-012 | Public host-coverage wording for Feature 024 MUST claim slash-command discoverability only for Claude Code and GitHub Copilot CLI in v0.24.0, while still deploying `.agents/skills/` as a host-neutral future-proof path and explicitly deferring Codex CLI discoverability claims until its project-skill guidance stabilizes. | — |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T001-T002 | Setup evidence scaffolds | FR-008, FR-011, FR-012 | US-3 | 1.0 | Planner | `specs/024-slash-command-multi-host-correctness/checklists/**`, `specs/024-slash-command-multi-host-correctness/iterations/001/quality/**` | done | Planner | AI | pass |
| T003-T004 | Canonical deployment catalog + mirrored helper structure | FR-001, FR-002, FR-011 | US-1 | 1.5 | Implementer | `extensions/**/deploy-squad-runtime.ps1`, `.specify/extensions/**/deploy-squad-runtime.ps1` | done | Implementer | AI | pass |
| T005-T012 | Fresh-bootstrap multi-host deployment, frontmatter, and active-surface updates | FR-001, FR-002, FR-003, FR-004, FR-006, FR-007, FR-011, FR-012 | US-1 | 2.0 | Implementer | `extensions/**`, `.specify/extensions/**`, `scripts/**`, `tests/integration/slash-command-*` | done | Implementer | AI | pass |
| T013-T017 | Safe legacy migration and update messaging | FR-005, FR-006, FR-007, FR-011 | US-2 | 1.0 | Implementer | `extensions/**/deploy-squad-runtime.ps1`, `.specify/extensions/**/deploy-squad-runtime.ps1`, `scripts/specrew-update.ps1`, `tests/integration/slash-command-*` | done | Implementer | AI | pass |
| T018-T023 | Release/doc/proposal truth-surface updates | FR-004, FR-008, FR-009, FR-010, FR-011, FR-012 | US-3 | 1.0 | Spec Steward | `Specrew.psd1`, `.specrew/config.yml`, `extensions/**`, `.specify/extensions/**`, `README.md`, `docs/**`, `proposals/**`, `.github/**` | done | Spec Steward | AI | pass |
| T024-T025 | Validation lane + governance verdict capture | FR-006, FR-007, FR-008, FR-011 | US-1, US-2, US-3 | 0.5 | Reviewer | `tests/integration/**`, `specs/024-slash-command-multi-host-correctness/iterations/001/quality/**`, `extensions/**/validate-governance.ps1` | done | Reviewer | AI | pass |

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
| Planning | complete | Feature spec, clarify, plan, tasks, and after-tasks governance are complete |
| Discovery/Spikes | complete | Host-doc/frontmatter research and migration-safety analysis are already captured in planning artifacts |
| Implementation | complete | Runtime, template, migration, and truth-surface work completed on the current review tree |
| Review | complete | Validation lane, evidence capture, and governance verdict recording are complete |
| Retro | complete | Retrospective recorded before iteration-closeout |
| Iteration Closeout | complete | Dashboard snapshot and canonical iteration-closeout state are recorded; feature-closeout remains unopened |
| Rework | 0.0 SP reserved | No approved rework slice is open at implementation start |

## Traceability Summary

- Requirement scope for this iteration: FR-001, FR-002, FR-003, FR-004, FR-005, FR-006, FR-007, FR-008, FR-009, FR-010, FR-011, FR-012
- User stories represented in current scope: 
- Detailed execution remains source-controlled in `specs/024-slash-command-multi-host-correctness/tasks.md`; the task rows above summarize the approved work packets for Iteration 001.
- The iteration stays within capacity with the refined 7 SP estimate carried from the approved Feature 024 intake.
- No deferral is approved at implementation start; all FR-001 through FR-012 remain in Iteration 001 scope.

## Implementation Approval

- **Approval Verdict**: approved
- **Approved By**: Alon Fliess
- **Recorded Evidence**: current session explicit instruction to "Approved. Start implementation for Feature 024." with ratified Clarifications scope and stop-at-review-boundary constraint
- **Recorded At**: 2026-05-20T00:00:00Z
- **Scope Approved for Execution**: Iteration 001 active slice (`T003`-`T025`) only
- **Gate Effect**: implementation authority was consumed; review-verdict-signoff, retro-boundary, and iteration-closeout are complete, and feature-closeout is now the next human-authorization boundary

## Notes

- This iteration plan is the approved execution companion to `tasks.md` for Feature 024 Iteration 001.
- The implementation go-ahead is recorded in the current session; no additional planning gate remains open.
- Active discoverability claims remain limited to Claude Code + GitHub Copilot CLI.
- `.agents/skills/` remains a host-neutral deployment path, not a Codex CLI discoverability claim.
