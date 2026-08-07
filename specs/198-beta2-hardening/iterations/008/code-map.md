# Code Map: Iteration 008

**Schema**: v1
**Reviewed**: 2026-07-21
**Baseline Ref**: `364fbe88ef29cce5ac74d8086c1d78d8b8363197`
**Reviewed HEAD**: `9a6b88540088be2ff82fec145079b3f8765e863e`
**Reviewed-State Digest**: `eb9643d51780361d1009ba3267e7e14cb011b385`

## Production Surface

| Surface | Responsibility | Task(s) |
| --- | --- | --- |
| file:///C:/Dev/specrew-beta2-hardening/extensions/specrew-speckit/scripts/shared-governance.ps1 | Exact boundary rebind, live-state resolution, and conformance integration | T068–T070 |
| file:///C:/Dev/specrew-beta2-hardening/extensions/specrew-speckit/scripts/conformance-turn-delta.ps1 | Host-independent baseline, fingerprint, delta, and packet decision | T070 |
| file:///C:/Dev/specrew-beta2-hardening/scripts/internal/bootstrap/ConversationCaptureAccessor.ps1 | Owner/session-scoped capture attribution and stale-handover suppression | T069 |
| file:///C:/Dev/specrew-beta2-hardening/hosts/ | Genuine per-prompt events for Claude, Codex, Copilot, Cursor, and Antigravity | T070 |
| file:///C:/Dev/specrew-beta2-hardening/scripts/internal/continuous-co-review/verification-plan-supplier.ps1 | Deterministic repository-governed verification-plan selection | T062 |
| file:///C:/Dev/specrew-beta2-hardening/scripts/internal/continuous-co-review/verification-plan-materializer.ps1 | Hash-guarded plan materialization and preservation | T063 |
| file:///C:/Dev/specrew-beta2-hardening/scripts/internal/continuous-co-review/verification-plan-runner.ps1 | Frozen declared-environment command execution and bounded evidence | T064, T071 |
| file:///C:/Dev/specrew-beta2-hardening/scripts/internal/continuous-co-review/review-target-port.ps1 | Exact target/disposable-copy split, external evidence, read-only protection, integrity proof | T064, T066, T071 |
| file:///C:/Dev/specrew-beta2-hardening/scripts/internal/continuous-co-review/review-campaign-orchestrator.ps1 | Pre-spend verification, immutable facts, containment sequencing, recovery, publication | T064, T066, T071 |
| file:///C:/Dev/specrew-beta2-hardening/scripts/internal/continuous-co-review/reviewer-host-catalog.ps1 | Isolated Claude launch with empty MCP/settings sources and file-primary tools | T066, T071 |
| file:///C:/Dev/specrew-beta2-hardening/scripts/internal/continuous-co-review/test-evidence-recorder.ps1 | External, plan-bound, path-scrubbed evidence projection | T064, T071 |
| file:///C:/Dev/specrew-beta2-hardening/scripts/internal/continuous-co-review/worktree-reviewer.ps1 | One machinery classifier shared by target stripping, digest, and finalization; canonical local Claude settings excluded, ordinary settings retained | T066 |
| file:///C:/Dev/specrew-beta2-hardening/scripts/init/ and file:///C:/Dev/specrew-beta2-hardening/scripts/specrew-init.ps1 | Consumer workflow allowlist, bootstrap behavior, local config, plan setup | T021–T026, T063 |
| file:///C:/Dev/specrew-beta2-hardening/scripts/specrew-update.ps1 | Hash-guarded update healing and plan refresh | T025, T063 |
| file:///C:/Dev/specrew-beta2-hardening/templates/github/workflows/ | Consumer-safe methodology/work-kind workflows; self-host lanes denied | T021–T023 |

The `.specify/extensions/specrew-speckit/` tree mirrors shipped extension files and is covered by parity checks. `Specrew.psd1` contains the matching distribution inventory.

## Test Surface

| Surface | Behavior proved |
| --- | --- |
| file:///C:/Dev/specrew-beta2-hardening/tests/f198-regression-suite.ps1 | Process-isolated 73-suite Feature 198 registry |
| file:///C:/Dev/specrew-beta2-hardening/tests/continuous-co-review/unit/review-public-campaign-command.Tests.ps1 | Public campaign, finalization, local-overlay valid path, ordinary-settings false-allow refusal |
| file:///C:/Dev/specrew-beta2-hardening/tests/continuous-co-review/unit/worktree-reviewer-machinery-paths.Tests.ps1 | Source/downstream machinery policy and precise local-settings exception |
| file:///C:/Dev/specrew-beta2-hardening/tests/continuous-co-review/unit/review-campaign-verification.Tests.ps1 | Pre-spend refusal, rollback, disposable verification, terminal behavior |
| file:///C:/Dev/specrew-beta2-hardening/tests/continuous-co-review/unit/review-target-port.Tests.ps1 | Exact target, external evidence, read-only probes, restore, cleanup |
| file:///C:/Dev/specrew-beta2-hardening/tests/unit/conformance-turn-delta.tests.ps1 | Baseline/delta decisions, same-path re-edit, degraded-message honesty |
| file:///C:/Dev/specrew-beta2-hardening/tests/bootstrap/HookVerdictCapture.Tests.ps1 | Multi-session attribution, injected context, live turn-start behavior |
| file:///C:/Dev/specrew-beta2-hardening/tests/unit/test-consumer-assumptions.ps1 | Fresh consumer, non-GitHub/non-Pester/local-only, applicability claims |

## Change Shape and Hotspots

- Reviewed range: 143 files, 7896 insertions, 912 deletions.
- Primary campaign/containment hotspot: file:///C:/Dev/specrew-beta2-hardening/scripts/internal/continuous-co-review/review-campaign-orchestrator.ps1.
- Primary target-integrity hotspot: file:///C:/Dev/specrew-beta2-hardening/scripts/internal/continuous-co-review/review-target-port.ps1.
- Primary finalization-classification hotspot: file:///C:/Dev/specrew-beta2-hardening/scripts/internal/continuous-co-review/worktree-reviewer.ps1.
- Primary turn-attribution hotspot: file:///C:/Dev/specrew-beta2-hardening/extensions/specrew-speckit/scripts/conformance-turn-delta.ps1.

The repository remains the sole product-code mutation authority. Verification runs in a disposable exact-digest copy, the reviewer target is independently OS-protected, the reviewer can write only its external candidate path, and the controller alone publishes terminal authority. The finalization child cannot carry implementation changes.
