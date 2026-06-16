# Iteration Plan: 001

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: executing
**Capacity**: 20/20 story_points
**Started**: 2026-06-16
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
| FR-001 | When the SessionStart composite would exceed the host hook-output | US1 |
| FR-002 | When the bootstrap/refocus provider fails, the hook MUST emit a | US1 |
| FR-003 | SessionStart journal/status/dedupe/breaker state MUST NOT collapse | US2 |
| FR-004 | The delivery-cap test MUST measure a synthetic shipped | US1 |
| FR-005 | Closeout sync MUST handle `.specify` dirty surfaces coherently, | US3 |
| FR-006 | The two in-scope #1761 local tests MUST stop failing because of | US3 |
| FR-007 | Specrew MUST add Antigravity to the hook-capable host path using | US4 |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T001 | SessionStart cap policy and provider fallback | FR-001, FR-002, SC-001, SC-002 | US1 | 4 | Implementer | extensions/specrew-speckit/scripts/**; tests/bootstrap/** | done | codex | 4 | pass |
| T002 | Delivery-cap hermetic fixture | FR-004, SC-004 | US1 | 2 | Implementer, Reviewer | tests/bootstrap/DirectiveDeliveryCap.Tests.ps1 | planned | codex | — | pending |
| T003 | Session ID resolver and journal state | FR-003, SC-003 | US2 | 3 | Implementer | scripts/internal/bootstrap/**; scripts/internal/specrew-hook-dispatcher.ps1; scripts/internal/specrew-bootstrap-provider.ps1; extensions/specrew-speckit/scripts/**; .specify/extensions/specrew-speckit/scripts/**; tests/bootstrap/**; tests/integration/refocus-dispatcher.tests.ps1 | done | codex | 3 | pass |
| T004 | Closeout classification, upstream wording, dashboard refresh | FR-005, SC-005 | US3 | 4 | Implementer | scripts/internal/sync-boundary-state.ps1; tests/integration/** | planned | codex | — | pending |
| T005 | #1761 mechanical local-test hygiene | FR-006, SC-006 | US3 | 2 | Implementer, Reviewer | tests/integration/closeout-lifecycle-sync-commands.tests.ps1; tests/integration/** | planned | codex | — | pending |
| T006 | Antigravity hook binding and docs cleanup | FR-007, SC-009, TG-004 | US4 | 4 | Implementer, Reviewer | hosts/**; scripts/internal/deploy-refocus-hooks.ps1; scripts/specrew-hooks.ps1; docs/**; README.md; tests/integration/refocus-deploy.tests.ps1; tests/integration/specrew-hooks-command.tests.ps1 | planned | codex | — | pending |
| T007 | Mirror parity evidence | SC-007, TG-003 | US1-US4 | 0.25 | Reviewer | extensions/specrew-speckit/**; .specify/extensions/specrew-speckit/** | planned | codex | — | pending |
| T008 | Dynamic beta release readiness | SC-007 | US1-US4 | 0.25 | Spec Steward | specs/183-stability-quality-bundle/** | planned | codex | — | pending |
| T009 | Real-host validation evidence | SC-008, SC-009, TG-004 | US1, US4 | 0.25 | Reviewer | specs/183-stability-quality-bundle/** | planned | codex | — | pending |
| T010 | Closeout issue linkage and traceability evidence | TG-001, TG-002, TG-005 | US3 | 0.25 | Spec Steward, Reviewer | specs/183-stability-quality-bundle/** | planned | codex | — | pending |

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
- Technology and scope signals: The resolved quality profile is `powershell-json-yaml-pester`; scoped work is PowerShell governance/runtime code, host metadata, JSON/YAML config, markdown docs, and Pester tests.
- Task dependency graph: T001 and T003 both touch hook runtime/bootstrap surfaces and `tests/bootstrap/**`; keep them serial unless tasks.md narrows owner globs enough to prove parallel safety.
- Workstream separability: Closeout/test-hygiene and Antigravity workstreams are conceptually separable, but the 20/20 SP cap and shared Specrew governance surfaces favor a smaller serial team for this iteration.
- Shared-surface conflict risk: elevated around `extensions/specrew-speckit/scripts/**`, `tests/bootstrap/**`, and mirror parity when runtime slices overlap.
- Prior reviewer ownership/hotspot evidence: No prior reviewer hotspot signals were found for this feature.
- Recommendation: keep the iteration serial by default. If a same-specialty pair is approved later, first narrow `Owner File Globs` for the parallel tasks and record the parallelism proof; otherwise keep overlapping slices serial.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | 2 | Plan, design gate, and Wave B artifacts |
| Discovery/Spikes | 1 | Antigravity official schema/event/output verification |
| Implementation | 13 | Runtime, hook, closeout, docs, and test changes |
| Review | 3 | Deterministic validation, mirror parity, and real-host evidence |
| Rework | 1 | Expected repair buffer |

## Traceability Summary

- Requirement scope: FR-001, FR-002, FR-003, FR-004, FR-005, FR-006, FR-007.
- User stories represented in current scope: US1, US2, US3, US4.
- Capacity check: 20/20 story_points. No slack remains.
- Overcommit guardrail: if Antigravity verification expands beyond the bounded
  adapter/config/docs/test slice, pause for a human split/defer decision before
  implementation continues.

## Notes

- Design-analysis verdict: `approved for plan with Option B`.
- Feature plan: file:///C:/Dev/183-stability-quality-bundle/specs/183-stability-quality-bundle/plan.md
- Wave B review artifacts: file:///C:/Dev/183-stability-quality-bundle/specs/183-stability-quality-bundle/data-model.md, file:///C:/Dev/183-stability-quality-bundle/specs/183-stability-quality-bundle/quickstart.md, file:///C:/Dev/183-stability-quality-bundle/specs/183-stability-quality-bundle/contracts/stability-quality-bundle.md, file:///C:/Dev/183-stability-quality-bundle/specs/183-stability-quality-bundle/review-diagrams.md
- Tasks authoring decomposed the former combined T007 evidence slice into T007-T010 for mirror parity, dynamic beta readiness, real-host validation, and closeout issue linkage.
- T001/T003 preserve the shared-glob constraint: execute serially, or narrow owner globs before claiming safe parallelism.
- Before-implement hardening gate is approved with instructions by `f183-i001-before-implement-approved`; runtime evidence remains pending until implementation and review.
- T001 implemented dispatcher SessionStart fragment priority/cap handling and governed provider-failure fallback. Validation passed for file:///C:/Dev/183-stability-quality-bundle/tests/bootstrap/DispatcherSessionStartPolicy.Tests.ps1, dispatcher launch guards, host delivery/bootstrap provider checks, and file:///C:/Dev/183-stability-quality-bundle/tests/bootstrap/ProviderMirrorParity.Tests.ps1; file:///C:/Dev/183-stability-quality-bundle/tests/bootstrap/DirectiveDeliveryCap.Tests.ps1 remains the planned T002 fixture rewrite.
- Protocol correction: T001 ran before the explicit before-implement verdict; DR-001 is now fully resolved by `f183-i001-before-implement-approved`, which ratifies T001 and authorizes T003 onward. DR-002 remains a separate non-blocking governance-only follow-up outside F-183's 20 SP scope, not a T004 carry.
- Carry-forward controls: T002 must clear the known-red delivery-cap test before review-signoff; T003 must replace the `Get-SanitizedSessionId` global `unknown` fallback with the per-launch token path; fallback negative-path tests must cover non-zero provider exit, command-unresolved provider launch, dispatcher outer-catch, and bootstrap-over-cap; T006 must surface Antigravity schema/event/output verification early and stop if it exceeds the bounded adapter/config/docs/test slice; T009 must include a hook-firing Antigravity host and non-Claude host validation for the final hook-output envelope.
- T003 implemented per-launch fallback session tokens for missing, blank, and malformed host session IDs across the bootstrap adapter/manager and dispatcher state path. Validation passed for file:///C:/Dev/183-stability-quality-bundle/tests/bootstrap/HostEventAdapter.Tests.ps1, file:///C:/Dev/183-stability-quality-bundle/tests/bootstrap/SessionBootstrapManager.Tests.ps1, file:///C:/Dev/183-stability-quality-bundle/tests/bootstrap/DispatcherSessionIdFallback.Tests.ps1, file:///C:/Dev/183-stability-quality-bundle/tests/bootstrap/HookRenderDedupe.Tests.ps1, file:///C:/Dev/183-stability-quality-bundle/tests/bootstrap/DispatcherSessionStartPolicy.Tests.ps1, file:///C:/Dev/183-stability-quality-bundle/tests/bootstrap/BootstrapProvider.Tests.ps1, file:///C:/Dev/183-stability-quality-bundle/tests/bootstrap/LauncherIntegration.Tests.ps1, file:///C:/Dev/183-stability-quality-bundle/tests/bootstrap/ProviderMirrorParity.Tests.ps1, and file:///C:/Dev/183-stability-quality-bundle/tests/integration/refocus-dispatcher.tests.ps1.
