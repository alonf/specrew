# Iteration Plan: 010

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: planning
**Capacity**: 17/20 story_points
**Started**: 2026-06-05

<!--
  Validator schema: Iteration Status one of planning|executing|reviewing|retro|complete|abandoned.
  Task Status one of planned|in-progress|done|needs-rework|deferred|blocked.
-->

## Iteration Theme

The **lens-conduct delivery relocation** (the i9-dogfood redo; Option B): move the A4/A5/A6 lens conduct out of
the one-shot ~50-rule launch prompt — which the agent skims, so it under-surfaces in-conversation — into a
**re-invokable `specrew-design-workshop` skill** (whose name+description stays in the system prompt and loads
on-demand at each lens) + the **per-lens conduct co-located in each `design-lenses/<id>.md`** (read at point of
use) + a **trimmed launch prompt** (a pointer to the skill). Same A4/A5/A6 INTENT, changed implementation; no
FR change. Web-confirmed: all five hosts share the agentskills.io open standard ("just folders"); skills
re-invoke on-demand (documented on Claude; the skill is self-contained + self-reinvoking for the other four).

## Scope Summary

| Requirement | Summary | Stories |
| ----------- | ------- | ------- |
| FR-025 / FR-030–033 / FR-034–037 | The existing workshop/visuals/co-design capability, RELOCATED from the launch prompt to a re-invokable skill + on-demand per-lens md | US-DR |
| SC-024 | Behavioral acceptance — the re-confirm dogfood (co-design surfaces in-band reliably via the relocated delivery) | US-DR |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T001 | Author the specrew-design-workshop skill (frontmatter description engineered to auto-load + body: big-picture lens map + the general method [ASCII-inline-default, co-design-not-unilateral, capture-agreements] + per-lens "load design-lenses/<id>.md" loop + self-reinvocation; self-contained per load) | FR-025, FR-030, FR-034, FR-036, FR-037 | US-DR | 5 | Spec Steward | extensions/specrew-speckit/squad-templates/skills/** | planned | claude | — | — |
| T002 | Co-locate a focused ## Workshop Conduct section into each of the 9 design-lenses/<id>.md (its diagram type + facilitation nuance + the re-invoke instruction) so the lens md is the point-of-use unit the skill loads | FR-009, FR-030 | US-DR | 3 | Spec Steward | extensions/specrew-speckit/knowledge/design-lenses/** | planned | claude | — | — |
| T003 | Trim the launch prompt: Rules 9a/9b/9c (the verbose conduct) -> a compact 9a pointer to the skill (keeps the SC-021/SC-025 gate refs) + 9b/9c folded-into-skill stubs | FR-025 | US-DR | 3 | Implementer | scripts/specrew-start.ps1 | planned | claude | — | — |
| T004 | Deploy: the skill auto-deploys (flat design-workshop.md -> specrew-design-workshop/SKILL.md to .claude/skills + .agents/skills + the other host roots) via the existing Get-LegacySpecrewSkillDefinitions path; no deploy-script change; .specrew-managed marker | FR-010 | US-DR | 1 | Implementer | extensions/specrew-speckit/scripts/** | planned | claude | — | — |
| T005 | Tests (lens-conduct-delivery.tests.ps1): skill exists + frontmatter trigger description + relocated conduct; all 9 lens md carry Workshop Conduct; the prompt points to the skill + is trimmed. skill-templates + design-gate-runtime-hardening + design-analysis-gate suites still green | FR-025 | US-DR | 3 | Reviewer | tests/unit/** | planned | claude | — | — |
| T006 | SC-024 re-confirm runtime dogfood: a downstream run where the relocated delivery drives the workshop — the skill auto-loads, the agent surfaces ASCII diagrams in-band, co-designs WITH the human, captures agreements. The behavioral acceptance gate (needs maintainer) | SC-024 | US-DR | 2 | Planner | specs/141-design-gate-runtime-hardening/** | planned | claude | — | — |

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | |
| Capacity per Iteration | 20 | |
| Iteration Bounding | scope | |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time`. |
| Overcommit Threshold | 1.0 | 17/20. |
| Defer Strategy | manual | |
| Calibration Enabled | true | |

## Concurrency Rationale

- T001 (the skill) is the root deliverable; T002 (lens md) and T003 (prompt trim) are independent of it and of
  each other (different files); T004 (deploy) is automatic; T005 (tests) follows the code; T006 (the dogfood) is
  the human-run acceptance gate. Serial baseline team.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | 1 | Design via the gate; Option B recorded (decision 65a5a534). |
| Implementation | 12 | T001 skill (5) + T002 lens md (3) + T003 prompt trim (3) + T004 deploy (1). |
| Review | 5 | T005 tests (3) + T006 the dogfood (2). |
| Rework | 0 | Buffer via the 17/20 headroom. |

## Traceability Summary

- Iteration 10 scope: relocate the A4/A5/A6 conduct delivery (no FR change — implementation of FR-025/030–037);
  SC-024 re-confirm is the acceptance.
- Design-analysis: completed via the gate; Option B; decision `65a5a534`, draft `deaa1b25`.
- Mapping: skill->T001; lens md->T002; prompt trim->T003; deploy->T004; tests->T005; dogfood->T006/SC-024.

## Notes

- **The value is the focused point-of-use delivery**, and whether the agent now reliably surfaces in-conversation
  is behavioral — T006's dogfood, not T005's unit tests, is the acceptance (the i6/i7/i8/i9 lesson; the retro
  PoC-up-front rule from i9 applies). The unit tests lock the relocation *structure* in place.
- `index.yml` stays pure; the deploy + skill-templates test enumerate skills dynamically (no hardcoded list);
  no release/push while 141 is in progress; the deferred Proposal 156 scope stays out.
- Stops at the dogfood for the maintainer's go-ahead (the build is done; the behavioral acceptance is the run).
