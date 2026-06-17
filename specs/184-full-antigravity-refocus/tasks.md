# Tasks: Full Antigravity Refocus

**Schema**: v1
**Feature**: file:///C:/Dev/183-stability-quality-bundle/specs/184-full-antigravity-refocus/spec.md
**Iteration**: file:///C:/Dev/183-stability-quality-bundle/specs/184-full-antigravity-refocus/iterations/001/plan.md
**Status**: ready-for-implementation
**Capacity**: 26/26 story_points

## Task Table

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Verification |
| --- | --- | --- | --- | ---: | --- | --- | --- | --- |
| T001 | Discovery spike: B3-on-PreInvocation split-guard proof | FR-003, FR-010, SC-009, TG-004, TG-005 | US2 | 3 | Planner, Reviewer | `scripts/internal/bootstrap/**`; `scripts/internal/specrew-hook-dispatcher.ps1`; `extensions/specrew-speckit/scripts/**`; `hosts/antigravity/**`; `specs/184-full-antigravity-refocus/**` | done | Evidence rows for `fresh-boundary-cursor`, `exactly-once-b3`, and `bounded-host-model` all PASS in file:///C:/Dev/183-stability-quality-bundle/specs/184-full-antigravity-refocus/iterations/001/discovery-antigravity-b3-preinvocation.md. |
| T002 | Antigravity session identity and per-session refocus state/anchor | FR-001, FR-002, FR-005, SC-001, SC-002 | US1, US4 | 4 | Implementer | `scripts/internal/bootstrap/**`; `scripts/internal/specrew-hook-dispatcher.ps1`; `extensions/specrew-speckit/scripts/**`; `tests/bootstrap/**`; `tests/integration/refocus-dispatcher.tests.ps1` | done | Automated tests prove real `conversationId` keys and no global `unknown`; manual `agy --conversation` proves exit/re-entry anchor persistence. |
| T003 | B3 `PreInvocation` injection with dedupe/breaker and fail-open diagnostics | FR-003, FR-006, FR-010, SC-003, SC-007, SC-009 | US2 | 5 | Implementer | `scripts/internal/bootstrap/**`; `scripts/internal/specrew-hook-dispatcher.ps1`; `extensions/specrew-speckit/scripts/**`; `tests/bootstrap/**`; `tests/integration/refocus-dispatcher.tests.ps1` | planned | Automated and manual evidence prove B3 injects once on real boundary crossing, not ordinary turns, with bounded fail-open diagnostics. |
| T004 | Antigravity self-marker concurrency classifier | FR-004, FR-006, SC-004 | US3 | 3 | Implementer | `scripts/internal/bootstrap/**`; `tests/bootstrap/ClassificationEngine.Tests.ps1`; `tests/bootstrap/SessionBootstrapManager.Tests.ps1` | planned | Current Antigravity marker emits no advisory; competing marker still warns. |
| T005 | Hook config preservation and F-183 Antigravity regression guards | FR-005, FR-007, SC-005, SC-006 | US4, US5 | 3 | Implementer, Reviewer | `hosts/antigravity/**`; `scripts/internal/deploy-refocus-hooks.ps1`; `extensions/specrew-speckit/scripts/deploy-refocus-hooks.ps1`; `tests/integration/refocus-deploy.tests.ps1`; `tests/integration/specrew-hooks-command.tests.ps1` | planned | Deploy/remove tests preserve user hooks and F-183 bootstrap/Stop/handover behavior. |
| T006 | Antigravity documentation, permission, recovery, and evidence-gated status wording | FR-008, FR-009, TG-006, SC-008, SC-010 | US5 | 2 | Spec Steward, Reviewer | `README.md`; `docs/**`; `specs/184-full-antigravity-refocus/**` | planned | Docs reach host-level depth for `agy`, hook install/remove, permissions, sandboxing, recovery, and evidence-gated labels. |
| T007 | Automated validation, mirror parity, and FileList/release readiness | TG-001, TG-002, TG-003, SC-001, SC-004, SC-006, SC-007, SC-008, SC-010 | US1-US5 | 3 | Reviewer | `tests/**`; `extensions/specrew-speckit/**`; `.specify/extensions/specrew-speckit/**`; `Specrew.psd1`; `specs/184-full-antigravity-refocus/**` | planned | Pester suite, mirror parity, FileList/release readiness, and governance validation pass or findings are fixed/classified. |
| T008 | Real-host `agy` validation and Proposal 145 review evidence | FR-009, TG-004, TG-005, TG-006, SC-002, SC-003, SC-005, SC-009, SC-010 | US1-US5 | 3 | Reviewer | `specs/184-full-antigravity-refocus/iterations/001/**` | planned | Real-host `agy` evidence proves B3, marker, state, handover, exit/re-entry, and support-label honesty. |

## Sequencing

- T001 gates T002-T005. Any FAIL row in the split-guard evidence stops runtime
  implementation for a human split/defer decision.
- T002 precedes T003 because B3 dedupe/state keys depend on real session
  identity and per-session anchor persistence.
- T004 starts after T002 stabilizes marker identity.
- T006 may proceed after T001, but status labels remain evidence-gated until
  T008.
- T007 and T008 are review-stage tasks after implementation slices merge.

## Traceability Check

**Verdict**: PASS

| Check | Result |
| --- | --- |
| Every task maps to at least one FR, SC, or TG | PASS |
| Every FR-001 through FR-010 has at least one task | PASS |
| Every SC-001 through SC-010 has at least one task | PASS |
| Every TG-001 through TG-006 has at least one task | PASS |
| Tasks include owner, effort, story, and verification metadata | PASS |
| Invalid or stale requirement references | None |
| Orphan tasks | None |
| Uncovered requirements | None |

## Traceability Matrix

| Requirement | Covering Tasks |
| --- | --- |
| FR-001 | T002 |
| FR-002 | T002 |
| FR-003 | T001, T003 |
| FR-004 | T004 |
| FR-005 | T002, T005 |
| FR-006 | T003, T004 |
| FR-007 | T005 |
| FR-008 | T006 |
| FR-009 | T006, T008 |
| FR-010 | T001, T003 |
| SC-001 | T002, T007 |
| SC-002 | T002, T008 |
| SC-003 | T003, T008 |
| SC-004 | T004, T007 |
| SC-005 | T005, T008 |
| SC-006 | T005, T007 |
| SC-007 | T003, T007 |
| SC-008 | T006, T007 |
| SC-009 | T001, T003, T008 |
| SC-010 | T006, T007, T008 |
| TG-001 | T007 |
| TG-002 | T007 |
| TG-003 | T007 |
| TG-004 | T001, T008 |
| TG-005 | T001, T008 |
| TG-006 | T006, T008 |
