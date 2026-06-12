# Iteration Plan: 004

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: planning
**Capacity**: 17/20 story_points
**Started**: 2026-06-12
**Completed**:

<!--
  Validator schema (canonical, enforced by validate-governance.ps1):
  - Iteration Status MUST be one of: planning | executing | reviewing | retro | complete | abandoned
  - Capacity format MUST be `<consumed>/<cap> <effort_unit>` with NO trailing prose on that line.
  - Task Status MUST be one of: planned | in-progress | done | needs-rework | deferred | blocked
-->

## Scope Summary

Iteration 004 = the **dogfood-findings completion** (FR-022–FR-026), reopened **before merge** after the
real-GitLab dogfood (2026-06-12, see [../../dogfood-findings.md](../../dogfood-findings.md)) proved the
iter-3 implementation of FR-019 had a **markdown-only coverage gap** (runtime/deployed surfaces left
un-neutralized) and that lifecycle-right-sizing is documentation-only (templates inert).

**Binding scope guardrail (maintainer-set):** **work-kind / forge-neutral governance ONLY.** This
iteration does NOT absorb F-174's session-bootstrap rewrite, does NOT fold in DF-006 (session-state
clobber), does NOT treat session-state as F-182 scope, and changes Specrew's own GitHub release workflow
ONLY as a labeled Specrew-own example. The findings' confound-proof artifact facts drive the work; the
behavior-level "passing" signals are discounted (see dogfood-findings.md test-validity note).

**F-174 handoffs (NOT Iteration-4 tasks, recorded only):** DF-006 (resume-preserves-state regression
test) → F-174; the `scripts/internal/launch-contract.ps1` string → F-174 neutralizes after rebasing onto
F-182; DF-010 (merge reconciliation) → F-174 preserves F-182's neutralized coordinator sources and
resolves the `specrew-start.ps1` conflict in favor of its deletion. **F-182's binding obligation: the
widened sweep MUST land with F-182** so it catches F-174's `launch-contract.ps1` site at reconciliation.

| Requirement | Summary | Stories |
| ----------- | ------- | ------- |
| FR-022 | Neutralize downstream-governing runtime/deployed surfaces (launch-prompt text + deployed agent files), not only methodology markdown | US2 |
| FR-023 | Operationalize work-kind lifecycle templates via catalog/schema/deploy/intake (work_kind → `<kind>-lifecycle.md`) | US3 |
| FR-024 | Forge-aware CI-lane guidance (propose CI for the project's forge; honest no-lane; optional GitLab template) | US2 |
| FR-025 | Lifecycle-end routing distinguishes downstream project work / upstream tool defects / new work-kind items | US2 |
| FR-026 | Capability detection reads canonical `provider.name` (fallback for older/simpler schemas) | US5 |
| SC-015 | The widened sweep fails on unlabeled GitHub/PSGallery/Specrew-release mandates across `.ps1` + deployed-agent + lifecycle + methodology + coordinator surfaces | US2 |
| SC-016 | A deployed project resolves `work_kind` → correct `<kind>-lifecycle.md` and shows it at the intake/start surface | US3 |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T401 | Widen the SC-008/SC-015 sweep — pattern-based scan of `.ps1` launch-prompt/contract text + deployed-agent files + lifecycle templates + methodology + coordinator surfaces; token set (gh pr create/merge, Find/Install-Module Specrew, PSGallery/PowerShell Gallery); explicit allowlist + labeled-example semantics; pattern-based so it catches future `launch-contract.ps1`-style sites | FR-022, SC-015 | US2 | 3 | Reviewer | tests/integration/forge-neutralization-sweep.tests.ps1 | planned | claude | | |
| T402 | Neutralize ONLY F-182-owned/current-tree surfaces the widened sweep flags: `.github/agents/squad.agent.md` (regen/neutralize) + `scripts/specrew-start.ps1` (neutralize the launch-prompt closeout block ONLY if needed for F-182 sweep-clean; document F-174 supersedes it); confirm coordinator/methodology already clean | FR-022 | US2 | 2 | Implementer | scripts/specrew-start.ps1 | planned | claude | | |
| T403 | Operationalize lifecycle templates: add a `lifecycle_template` field per kind in `work-kinds.yml` + schema; ensure package/FileList/deploy coverage; wire intake/start/refocus surfaces to resolve `work_kind` → `<kind>-lifecycle.md` | FR-023, SC-016 | US3 | 3 | Spec Steward | extensions/specrew-speckit/knowledge/work-kinds.yml | planned | claude | | |
| T404 | Tests for FR-023: catalog `lifecycle_template` schema-validates; resolution work_kind→template; deploy/FileList coverage asserted; intake/start surface shows the contract (artifact-level, confound-proof) | FR-023, SC-016 | US3 | 1.5 | Implementer | tests/unit/work-kind-catalog.tests.ps1 | planned | claude | | |
| T405 | FR-024 forge-aware CI lane: DevOps lens proposes "CI for the project's forge" + honest "no lane ships for `<forge>`"; a non-GitHub project is never defaulted to GitHub Actions (optional: ship a GitLab CI template if planned at before-implement) | FR-024 | US2 | 2 | Spec Steward | extensions/specrew-speckit/knowledge/design-lenses/devops-operations.md | planned | claude | | |
| T406 | FR-025 lifecycle-end routing: the closeout/lifecycle-end surface distinguishes downstream project work, upstream Specrew/tool defects (→ tool backlog), and new work-kind items (→ separate work item, not "iteration N") | FR-025 | US2 | 2 | Spec Steward | extensions/specrew-speckit/prompts/coordinator-decision-guidance.md | planned | claude | | |
| T407 | FR-026 capability detection reads `provider.name` with a fallback for older/simpler schema shapes (reports `gitlab`, not `gitlab-ci`) + test | FR-026 | US5 | 1.5 | Implementer | extensions/specrew-speckit/scripts/capability-detector.ps1 | planned | claude | | |
| T408 | Verification wave: SC-015 widened-sweep green on F-182's tree; SC-016 work_kind→template resolution; FR-024/025/026 behaviour-proven; own-GitHub-flow preserved as labeled example; confound-proof (artifact + deterministic-validator, not agent behavior) | SC-015, SC-016 | US2 | 2 | Reviewer | tests/integration/forge-neutralization-sweep.tests.ps1 | planned | claude | | |

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 20 | Maximum planned effort before overcommit guidance applies. |
| Iteration Bounding | scope | `scope` keeps requirements fixed; `time` enforces a time ceiling. |
| Overcommit Threshold | 1.0 | Warn planners when total estimated effort exceeds 20 story_points. |
| Defer Strategy | manual | How planning should choose deferrals when over capacity. |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time`. |
| Calibration Enabled | true | When true, retrospectives should suggest future capacity adjustments. |

## Concurrency Rationale

- Roster snapshot: Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator (all `claude`).
- Dependency graph: T401 (widen sweep) precedes T402 (neutralize what it flags) and T408 (verify);
  T403 (catalog field) precedes T404 (its tests); T405/T406/T407 are independent surfaces; T408 is the
  verification wave. Serial single-developer execution.
- Workstream separability: the sweep+neutralization (T401–T402), the lifecycle-template operationalization
  (T403–T404), and the smaller forge-aware/routing/detector items (T405–T407) touch disjoint files, but
  run serial under single-developer execution to keep the sweep (T408) authoritative over a settled tree.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Implementation | ~13 SP | T401–T407 (sweep widening + neutralization + lifecycle-template operationalization + forge-aware CI + routing + detector). |
| Review | ~4 SP | T408 (SC-015 + SC-016 + own-flow) + the Prop-145 review. |
| Rework | small | needs-work buffer. |

## Traceability Summary

- Requirement scope for **iteration 004 (dogfood-findings completion)**: FR-022 → SC-015; FR-023 → SC-016;
  FR-024/025/026 (process/runtime correctness). Completes FR-019's "ALL surfaces" claim for the
  runtime/deployed layer.
- User stories: US2 (governance real on any forge — the runtime-surface neutralization + forge-aware CI +
  routing), US3 (lifecycle-right-sizing operationalized), US5 (the adapter/detector seam — provider.name).
- Out of scope (Must-Not-Do): F-174's session-bootstrap rewrite + `launch-contract.ps1`; DF-006 session
  -state clobber; session-state as F-182 scope; Specrew's own GitHub release workflow (except as a labeled
  example).
- Overcommit: 17 SP planned vs cap 20 — within capacity.

## Notes

- **Sync origin/main before implementation** (F-182 is behind) — done at the before-implement boundary.
- The widened sweep (T401) is the **load-bearing deliverable**: it must land with F-182 to catch F-174's
  `launch-contract.ps1` site at reconciliation (the F-174 handoff obligation).
- The iter-1–3 `closeout.md` stays historical with a reopened/superseded note; a fresh feature-closeout
  supersedes it at the end of Iteration 4.
