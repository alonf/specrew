# Coverage Evidence: Iteration 001

**Schema**: v1
**Reviewed**: 2026-06-16
**Overall Verdict**: accepted
**Review Commit**: `b79b59d8`

## Test Strategy

The review used focused post-commit regression coverage, not ambient working-tree
claims. The commands below were run after the durable F-183 scope commit
`b79b59d8`, with in-scope implementation/spec paths clean against `HEAD`.

## Tests Run

| Command | Result | Notes |
| ------- | ------ | ----- |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File .specify/extensions/specrew-speckit/scripts/validate-governance.ps1 -ProjectPath . -IterationPath .\specs\183-stability-quality-bundle\iterations\001 -NoCacheRead` | pass | Target iteration passes; warnings are historical closed-iteration dashboard/trust-hardening warnings. |
| `git diff --check -- .gitignore .agents .specify/extensions/specrew-speckit README.md docs extensions/specrew-speckit hosts scripts specs/183-stability-quality-bundle tests/bootstrap tests/integration tests/unit/feature-051-file-classification.tests.ps1` | pass | Line-ending notices only. |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File tests/unit/feature-051-file-classification.tests.ps1` | pass | `.agents/hooks.json` is classified and ignored as per-session. |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File tests/integration/refocus-deploy.tests.ps1` | pass | Hook install/remove/opt-out/status behavior across Claude, Codex, Copilot, Cursor, and Antigravity. |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File tests/integration/specrew-hooks-command.tests.ps1` | pass | CLI install/status/remove, Antigravity install/status, stale detection, and failure reporting. |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File tests/bootstrap/ProviderMirrorParity.Tests.ps1` | pass | Module, extension source, and `.specify` provider copies are byte-identical. |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File tests/integration/quality-profile-foundation.ps1` | pass | Configured reviewer command failure is repaired. |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File tests/bootstrap/DirectiveDeliveryCap.Tests.ps1` | pass | Synthetic shipped SessionStart composite is under cap after dispatcher policy. |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File tests/bootstrap/DispatcherSessionStartPolicy.Tests.ps1` | pass | Bootstrap survives cap handling; provider failure emits governed fallback; Antigravity degraded fallback points to `specrew start --host antigravity`. |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File tests/bootstrap/DispatcherSessionIdFallback.Tests.ps1` | pass | Missing, blank, and malformed IDs get distinct per-launch tokens; no global `unknown` state files. |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File tests/bootstrap/HookRenderDedupe.Tests.ps1` | pass | Concurrent duplicate fires dedupe; missing-ID fires remain per-launch. |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File tests/bootstrap/HostEventAdapter.Tests.ps1` | pass | Host events normalize session/project data, including Antigravity `conversationId` and `workspacePaths`. |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File tests/bootstrap/SessionBootstrapManager.Tests.ps1` | pass | Bootstrap state and dedupe keys avoid global fallback buckets. |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File tests/bootstrap/BootstrapProvider.Tests.ps1` | pass | Bootstrap provider emits launch grounding and stays silent for compact events. |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File tests/bootstrap/LauncherIntegration.Tests.ps1` | pass | Launcher/hook dedupe markers behave as expected. |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File tests/bootstrap/HostDeliveryPolicy.Tests.ps1` | pass | Claude/Codex/Antigravity use bounded pointer directives; Copilot/Cursor stay inline where cap behavior is unverified. |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File tests/bootstrap/PerHost.Tests.ps1` | pass | Per-host event adapter behavior covers all five supported hosts. |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File tests/bootstrap/Regression.Tests.ps1` | pass | Refocus/bootstrap/handover event registrations remain consistent, including bounded Antigravity routing. |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File tests/integration/refocus-dispatcher.tests.ps1` | pass | Dispatcher fail-open behavior covers malformed events, broken catalog, provider crash/timeout, unresolvable command, gates, corrupt state, breaker, and host output shaping. |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File tests/integration/baseline-hygiene.tests.ps1` | pass | Baseline helper and boundary sync remain stable. |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File tests/integration/closeout-lifecycle-sync-commands.tests.ps1` | pass | Sync command parity, aliases, and module-internal boundary validation pass. |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File tests/integration/feature-closeout-working-tree-gate.tests.ps1` | pass | Dirty-surface classification, no-upstream wording, and dashboard refresh behavior pass. |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File tests/integration/bootstrap-resolver-guard.tests.ps1` | pass | Bootstrap resolver avoids stale module fallback and uses project-local deployed source. |
| `pwsh -NoProfile -ExecutionPolicy Bypass -File tests/integration/handoff-governance-descriptive-stop-message-test.ps1` | pass | Downstream five-part stop-context guidance and validator warnings are aligned. |

## Coverage-to-Requirements

| Requirement | Evidence |
| ----------- | -------- |
| FR-001 / SC-001 | `DirectiveDeliveryCap`, `DispatcherSessionStartPolicy`, `HostDeliveryPolicy`, `BootstrapProvider`. |
| FR-002 / SC-002 | `DispatcherSessionStartPolicy`, `refocus-dispatcher`; fallback wording includes `specrew where`, `/specrew-refocus`, and host-specific `specrew start --host <host>`. |
| FR-003 / SC-003 | `HostEventAdapter`, `SessionBootstrapManager`, `DispatcherSessionIdFallback`, `HookRenderDedupe`, `refocus-dispatcher`. |
| FR-004 / SC-004 | `DirectiveDeliveryCap` synthetic shipped SessionStart composite. |
| FR-005 / SC-005 | `feature-closeout-working-tree-gate`, `closeout-lifecycle-sync-commands`, `baseline-hygiene`. |
| FR-006 / SC-006 | `closeout-lifecycle-sync-commands`, `baseline-hygiene`, `feature-closeout-working-tree-gate`. |
| FR-007 / SC-009 / TG-004 | `refocus-deploy`, `specrew-hooks-command`, `HostEventAdapter`, `HostDeliveryPolicy`, `PerHost`, `Regression`, plus file:///C:/Dev/183-stability-quality-bundle/specs/183-stability-quality-bundle/iterations/001/quality/real-host-validation.md. |
| FR-008 / SC-010 / TG-006 | `refocus-deploy`, `specrew-hooks-command`, `ProviderMirrorParity`, host manifests, deploy/status scripts, and file:///C:/Dev/183-stability-quality-bundle/specs/183-stability-quality-bundle/iterations/001/quality/mirror-parity.md. |
| SC-007 / TG-003 | `ProviderMirrorParity` and mirror parity quality evidence. |
| SC-008 | Real-host Antigravity validation and non-Claude envelope measurement in file:///C:/Dev/183-stability-quality-bundle/specs/183-stability-quality-bundle/iterations/001/quality/real-host-validation.md. |
| TG-001 / TG-002 / TG-005 | file:///C:/Dev/183-stability-quality-bundle/specs/183-stability-quality-bundle/tasks.md and file:///C:/Dev/183-stability-quality-bundle/specs/183-stability-quality-bundle/iterations/001/quality/closeout-issue-linkage.md. |
