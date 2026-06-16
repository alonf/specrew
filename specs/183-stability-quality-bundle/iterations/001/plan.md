# Iteration Plan: 001

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: retro
**Capacity**: 28/20 story_points
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
| FR-008 | Specrew hook deploy/status logic for hook-capable hosts MUST be | US5 |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T001 | SessionStart cap policy and provider fallback | FR-001, FR-002, SC-001, SC-002 | US1 | 4 | Implementer | extensions/specrew-speckit/scripts/**; tests/bootstrap/** | done | codex | 4 | pass |
| T002 | Delivery-cap hermetic fixture | FR-004, SC-004 | US1 | 2 | Implementer, Reviewer | tests/bootstrap/DirectiveDeliveryCap.Tests.ps1 | done | codex | 2 | pass |
| T003 | Session ID resolver and journal state | FR-003, SC-003 | US2 | 3 | Implementer | scripts/internal/bootstrap/**; scripts/internal/specrew-hook-dispatcher.ps1; scripts/internal/specrew-bootstrap-provider.ps1; extensions/specrew-speckit/scripts/**; .specify/extensions/specrew-speckit/scripts/**; tests/bootstrap/**; tests/integration/refocus-dispatcher.tests.ps1 | done | codex | 3 | pass |
| T004 | Closeout classification, upstream wording, dashboard refresh | FR-005, SC-005 | US3 | 4 | Implementer | scripts/internal/sync-boundary-state.ps1; tests/integration/** | done | codex | 4 | pass |
| T005 | #1761 mechanical local-test hygiene | FR-006, SC-006 | US3 | 2 | Implementer, Reviewer | tests/integration/closeout-lifecycle-sync-commands.tests.ps1; tests/integration/** | done | codex | 2 | pass |
| T006 | Antigravity hook binding and docs cleanup | FR-007, SC-009, TG-004 | US4 | 4 | Implementer, Reviewer | hosts/**; scripts/internal/deploy-refocus-hooks.ps1; scripts/specrew-hooks.ps1; docs/**; README.md; tests/integration/refocus-deploy.tests.ps1; tests/integration/specrew-hooks-command.tests.ps1 | done | codex | 4 | pass |
| T011 | Manifest-driven hook-capable host model | FR-008, SC-010, TG-006 | US5 | 4 | Implementer, Reviewer | hosts/**; scripts/internal/deploy-refocus-hooks.ps1; scripts/internal/specrew-hook-health.ps1; extensions/specrew-speckit/scripts/**; .specify/extensions/specrew-speckit/scripts/**; tests/bootstrap/**; tests/integration/refocus-deploy.tests.ps1; tests/integration/specrew-hooks-command.tests.ps1 | done | codex | 8 | pass |
| T007 | Mirror parity evidence | SC-007, TG-003 | US1-US5 | 0.25 | Reviewer | extensions/specrew-speckit/**; .specify/extensions/specrew-speckit/** | done | codex | 0.25 | pass |
| T008 | Dynamic beta release readiness | SC-007 | US1-US5 | 0.25 | Spec Steward | specs/183-stability-quality-bundle/** | done | codex | 0.25 | pass |
| T009 | Real-host validation evidence | SC-008, SC-009, TG-004 | US1, US4 | 0.25 | Reviewer | specs/183-stability-quality-bundle/** | done | codex | 0.25 | pass |
| T010 | Closeout issue linkage and traceability evidence | TG-001, TG-002, TG-005 | US3 | 0.25 | Spec Steward, Reviewer | specs/183-stability-quality-bundle/** | done | codex | 0.25 | pass, linkage pending at closeout |

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
- Workstream separability: Closeout/test-hygiene and Antigravity workstreams are conceptually separable, but the 24/20 human-approved over-cap scope and shared Specrew governance surfaces favor a smaller serial team for this iteration.
- Shared-surface conflict risk: elevated around `extensions/specrew-speckit/scripts/**`, `tests/bootstrap/**`, and mirror parity when runtime slices overlap.
- Prior reviewer ownership/hotspot evidence: No prior reviewer hotspot signals were found for this feature.
- Recommendation: keep the iteration serial by default. If a same-specialty pair is approved later, first narrow `Owner File Globs` for the parallel tasks and record the parallelism proof; otherwise keep overlapping slices serial.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | 2 | Plan, design gate, and Wave B artifacts |
| Discovery/Spikes | 1 | Antigravity official schema/event/output verification |
| Implementation | 17 | Runtime, hook, host-model, closeout, docs, and test changes |
| Review | 3 | Deterministic validation, mirror parity, and real-host evidence |
| Rework | 1 | Expected repair buffer |

## Traceability Summary

- Requirement scope: FR-001, FR-002, FR-003, FR-004, FR-005, FR-006, FR-007,
  FR-008.
- User stories represented in current scope: US1, US2, US3, US4, US5.
- Capacity check: 28/20 story_points actual task effort. DR-004 Option A
  approved a 24/20 expanded scope baseline; retro calibration records T011 as
  roughly 8 SP because the 511-line cross-host host-model refactor was the
  iteration's largest task.
- Overcommit guardrail: DR-004 resolved the first FR-007 split guard by
  accepting the manifest-driven host-model refactor into F-183. Any further
  FR-007 or FR-008 growth still requires a fresh human split/defer decision.

## Notes

- Design-analysis verdict: `approved for plan with Option B`.
- Feature plan: file:///C:/Dev/183-stability-quality-bundle/specs/183-stability-quality-bundle/plan.md
- Wave B review artifacts: file:///C:/Dev/183-stability-quality-bundle/specs/183-stability-quality-bundle/data-model.md, file:///C:/Dev/183-stability-quality-bundle/specs/183-stability-quality-bundle/quickstart.md, file:///C:/Dev/183-stability-quality-bundle/specs/183-stability-quality-bundle/contracts/stability-quality-bundle.md, file:///C:/Dev/183-stability-quality-bundle/specs/183-stability-quality-bundle/review-diagrams.md
- Tasks authoring decomposed the former combined T007 evidence slice into T007-T010 for mirror parity, dynamic beta readiness, real-host validation, and closeout issue linkage.
- T001/T003 preserve the shared-glob constraint: execute serially, or narrow owner globs before claiming safe parallelism.
- Before-implement hardening gate is approved with instructions by `f183-i001-before-implement-approved`; runtime evidence remains pending until implementation and review.
- T001 implemented dispatcher SessionStart fragment priority/cap handling and governed provider-failure fallback. Validation passed for file:///C:/Dev/183-stability-quality-bundle/tests/bootstrap/DispatcherSessionStartPolicy.Tests.ps1, dispatcher launch guards, host delivery/bootstrap provider checks, and file:///C:/Dev/183-stability-quality-bundle/tests/bootstrap/ProviderMirrorParity.Tests.ps1.
- Protocol correction: T001 ran before the explicit before-implement verdict; DR-001 is now fully resolved by `f183-i001-before-implement-approved`, which ratifies T001 and authorizes T003 onward. DR-002 remains a separate non-blocking governance-only follow-up outside F-183's 20 SP scope, not a T004 carry.
- Carry-forward controls: fallback negative-path tests must cover non-zero provider exit, command-unresolved provider launch, dispatcher outer-catch, and bootstrap-over-cap; T006/T011 must stay within the accepted Antigravity plus manifest-driven hook deploy/status scope; T009 must include a hook-firing Antigravity host and non-Claude host validation for the final hook-output envelope.
- T003 implemented per-launch fallback session tokens for missing, blank, and malformed host session IDs across the bootstrap adapter/manager and dispatcher state path. Validation passed for file:///C:/Dev/183-stability-quality-bundle/tests/bootstrap/HostEventAdapter.Tests.ps1, file:///C:/Dev/183-stability-quality-bundle/tests/bootstrap/SessionBootstrapManager.Tests.ps1, file:///C:/Dev/183-stability-quality-bundle/tests/bootstrap/DispatcherSessionIdFallback.Tests.ps1, file:///C:/Dev/183-stability-quality-bundle/tests/bootstrap/HookRenderDedupe.Tests.ps1, file:///C:/Dev/183-stability-quality-bundle/tests/bootstrap/DispatcherSessionStartPolicy.Tests.ps1, file:///C:/Dev/183-stability-quality-bundle/tests/bootstrap/BootstrapProvider.Tests.ps1, file:///C:/Dev/183-stability-quality-bundle/tests/bootstrap/LauncherIntegration.Tests.ps1, file:///C:/Dev/183-stability-quality-bundle/tests/bootstrap/ProviderMirrorParity.Tests.ps1, and file:///C:/Dev/183-stability-quality-bundle/tests/integration/refocus-dispatcher.tests.ps1.
- T002 rewrote file:///C:/Dev/183-stability-quality-bundle/tests/bootstrap/DirectiveDeliveryCap.Tests.ps1 to measure a synthetic shipped SessionStart composite with a synthetic `source=startup` event and scratch dispatcher project instead of ambient developer-machine refocus state. Validation passed for file:///C:/Dev/183-stability-quality-bundle/tests/bootstrap/DirectiveDeliveryCap.Tests.ps1.
- T004 expanded feature-closeout dirty-surface classification to non-session `.specify` companions, made push wording conditional on a configured upstream, and refreshed feature closeout dashboards on auto-render paths. Validation passed for file:///C:/Dev/183-stability-quality-bundle/tests/integration/feature-closeout-working-tree-gate.tests.ps1, file:///C:/Dev/183-stability-quality-bundle/tests/integration/closeout-lifecycle-sync-commands.tests.ps1, file:///C:/Dev/183-stability-quality-bundle/tests/integration/lifecycle-boundary-sync.tests.ps1, and `git diff --check`.
- T005 repaired the #1761 local-test hygiene fixtures by committing scratch boundary artifacts before repeat sync checks and proving lifecycle sync assertions target the module-internal sync script. Validation passed for file:///C:/Dev/183-stability-quality-bundle/tests/integration/baseline-hygiene.tests.ps1, file:///C:/Dev/183-stability-quality-bundle/tests/integration/closeout-lifecycle-sync-commands.tests.ps1, and file:///C:/Dev/183-stability-quality-bundle/tests/integration/feature-closeout-working-tree-gate.tests.ps1.
- T006 implemented Antigravity hook support through project `.agents/hooks.json`: verified `PreInvocation` bootstrap injection shape, `Stop` handover decision dispatch, hook install/remove/opt-out preservation, stale hookless docs cleanup, and fallback guidance to `specrew start --host antigravity`. Validation passed for file:///C:/Dev/183-stability-quality-bundle/tests/bootstrap/PerHost.Tests.ps1, file:///C:/Dev/183-stability-quality-bundle/tests/bootstrap/HostEventAdapter.Tests.ps1, file:///C:/Dev/183-stability-quality-bundle/tests/bootstrap/SessionBootstrapManager.Tests.ps1, file:///C:/Dev/183-stability-quality-bundle/tests/bootstrap/HostDeliveryPolicy.Tests.ps1, file:///C:/Dev/183-stability-quality-bundle/tests/bootstrap/DispatcherSessionStartPolicy.Tests.ps1, file:///C:/Dev/183-stability-quality-bundle/tests/bootstrap/Regression.Tests.ps1, file:///C:/Dev/183-stability-quality-bundle/tests/bootstrap/ProviderMirrorParity.Tests.ps1, file:///C:/Dev/183-stability-quality-bundle/tests/integration/refocus-deploy.tests.ps1, file:///C:/Dev/183-stability-quality-bundle/tests/integration/specrew-hooks-command.tests.ps1, focused handoff-governance stop-packet tests, `git diff --check`, and governance validation for this iteration with historical warnings only. This is not an Antigravity parity claim; the hook-firing real-host check remains T009 review-stage evidence.
- T011 was added by DR-004 Option A to make the accepted host-model refactor explicit. It covers the `RefocusHookBindings` manifest schema, migration of Claude/Codex/Copilot/Cursor/Antigravity hook registrations into host manifests, manifest-driven deploy/status command rendering, hook-health resolution from manifest data, and mirrored deploy script alignment.
- T007 recorded mirror parity evidence in file:///C:/Dev/183-stability-quality-bundle/specs/183-stability-quality-bundle/iterations/001/quality/mirror-parity.md. Provider mirror parity passed, and direct SHA-256 comparison confirmed every touched `extensions/specrew-speckit/**` file is byte-identical to its `.specify/extensions/specrew-speckit/**` mirror.
- T008 recorded dynamic release readiness in file:///C:/Dev/183-stability-quality-bundle/specs/183-stability-quality-bundle/iterations/001/quality/release-readiness.md. Local tags, origin tags, PSGallery packages, and GitHub releases show `0.37.0-beta1` and `0.37.0` already published, so the superseded `0.37.0-beta<N>` line is closed for this feature. DR-003 records the release-line drift and selects `0.38.0-beta1` as the next valid beta target, with stable `0.38.0` gated behind T009 real-host validation and manual beta PASS.
- T009 recorded real-host validation evidence in file:///C:/Dev/183-stability-quality-bundle/specs/183-stability-quality-bundle/iterations/001/quality/real-host-validation.md. The passing Antigravity run loaded project `.agents/hooks.json`, executed `PreInvocation`, executed `Stop`, produced no hook stderr/failure lines, updated the durable handover, and measured the final Antigravity JSON envelope at 6,637 characters under the 10,000 character cap. This remains bounded support, not a full parity claim.
- T010 recorded closeout issue linkage and traceability evidence in file:///C:/Dev/183-stability-quality-bundle/specs/183-stability-quality-bundle/iterations/001/quality/closeout-issue-linkage.md. After DR-004 Option A, traceability covers 11/11 tasks and 24/24 in-scope FR/SC/TG requirements. #2446, #1627, and #1761 must be bound at feature closeout to bundle commit `b79b59d8` or to the final merge/squash commit if the branch is rewritten.
- Retrospective recorded in file:///C:/Dev/183-stability-quality-bundle/specs/183-stability-quality-bundle/iterations/001/retro.md. Effective actual effort is recorded as roughly 30 SP: 28 SP actual task effort plus an estimated 2 SP review/governance tail.
