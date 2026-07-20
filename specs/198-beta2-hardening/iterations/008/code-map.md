# Code Map: Iteration 008

**Schema**: v1
**Reviewed**: 2026-07-20
**Baseline Ref**: `364fbe88ef29cce5ac74d8086c1d78d8b8363197`
**Reviewed HEAD**: `659bec289646a2fa6f062973a94d2cbd3249632f`
**Reviewed-State Digest**: `45255b42eb97820858c9cd858956e7c78ad0a591`

## Production Surface

| Surface | Responsibility | Task(s) |
| --- | --- | --- |
| file:///C:/Dev/specrew-beta2-hardening/extensions/specrew-speckit/scripts/shared-governance.ps1 | Exact boundary rebind, live state resolution, and conformance host integration | T068–T070 |
| file:///C:/Dev/specrew-beta2-hardening/extensions/specrew-speckit/scripts/conformance-turn-delta.ps1 | Host-independent turn baseline, content fingerprint, delta, and packet-demand decision | T070 |
| file:///C:/Dev/specrew-beta2-hardening/scripts/internal/bootstrap/ConversationCaptureAccessor.ps1 | Owner/session-scoped capture attribution and stale-handover suppression | T069 |
| file:///C:/Dev/specrew-beta2-hardening/hosts/ | Genuine per-prompt event registrations for Claude, Codex, Copilot, Cursor, and Antigravity | T070 |
| file:///C:/Dev/specrew-beta2-hardening/scripts/internal/continuous-co-review/verification-plan-supplier.ps1 | Deterministic repository-governed verification-plan selection | T062 |
| file:///C:/Dev/specrew-beta2-hardening/scripts/internal/continuous-co-review/verification-plan-materializer.ps1 | Hash-guarded init/update/setup materialization and preservation | T063 |
| file:///C:/Dev/specrew-beta2-hardening/scripts/internal/continuous-co-review/verification-plan-runner.ps1 | Frozen declared-environment command execution and bounded evidence | T064, T071 |
| file:///C:/Dev/specrew-beta2-hardening/scripts/internal/continuous-co-review/review-target-port.ps1 | Exact target/disposable verification split, external evidence, OS read-only protection, and integrity proof | T064, T066, T071 |
| file:///C:/Dev/specrew-beta2-hardening/scripts/internal/continuous-co-review/review-campaign-orchestrator.ps1 | Pre-spend verification, immutable campaign facts, containment sequencing, recovery, and terminal publication | T064, T066, T071 |
| file:///C:/Dev/specrew-beta2-hardening/scripts/internal/continuous-co-review/reviewer-host-catalog.ps1 | Isolated Claude launch vector with strict empty MCP/settings and file-primary tools | T066, T071 |
| file:///C:/Dev/specrew-beta2-hardening/scripts/internal/continuous-co-review/test-evidence-recorder.ps1 | External, plan-bound, path-scrubbed evidence projection | T064, T071 |
| file:///C:/Dev/specrew-beta2-hardening/scripts/init/ and file:///C:/Dev/specrew-beta2-hardening/scripts/specrew-init.ps1 | Consumer workflow allowlist, bootstrap behavior, local configuration, and verification-plan setup | T021–T026, T063 |
| file:///C:/Dev/specrew-beta2-hardening/scripts/specrew-update.ps1 | Hash-guarded update healing and verification-plan refresh | T025, T063 |
| file:///C:/Dev/specrew-beta2-hardening/templates/github/workflows/ | Consumer-safe methodology/work-kind workflows; self-host lanes denied | T021–T023 |
| file:///C:/Dev/specrew-beta2-hardening/extensions/specrew-speckit/data/self-leak-deny-list.json | Applicability and self-leak firewall data | T028 |

The `.specify/extensions/specrew-speckit/` tree mirrors the shipped extension files and is covered by parity checks. `Specrew.psd1` contains the matching distribution inventory.

## Test Surface

| Surface | Behavior proved |
| --- | --- |
| file:///C:/Dev/specrew-beta2-hardening/tests/f198-regression-suite.ps1 | Process-isolated 73-suite Feature 198 release registry |
| file:///C:/Dev/specrew-beta2-hardening/tests/continuous-co-review/verification-plan-end-to-end.Tests.ps1 | Supplier/materializer/runner/evidence production path |
| file:///C:/Dev/specrew-beta2-hardening/tests/continuous-co-review/review-campaign-verification.Tests.ps1 | Pre-spend red-plan refusal, staged rollback, disposable verification, and terminal behavior |
| file:///C:/Dev/specrew-beta2-hardening/tests/continuous-co-review/review-target-port.Tests.ps1 | Exact target, external evidence, read-only false-allow/false-deny probes, restore, and cleanup |
| file:///C:/Dev/specrew-beta2-hardening/tests/unit/verification-plan-supplier.Tests.ps1 | Deterministic catalog selection and refusal cases |
| file:///C:/Dev/specrew-beta2-hardening/tests/unit/verification-plan-materializer.Tests.ps1 | Generated/current/modified/explicit plan lifecycle |
| file:///C:/Dev/specrew-beta2-hardening/tests/unit/conformance-material-turn-gate.Tests.ps1 | Host-independent baseline/delta decisions, same-path re-edit, and degraded-message honesty |
| file:///C:/Dev/specrew-beta2-hardening/tests/bootstrap/HookVerdictCapture.Tests.ps1 | Multi-session attribution, injected context, and live turn-start behavior |
| file:///C:/Dev/specrew-beta2-hardening/tests/unit/distribution-module-init.tests.ps1 | Consumer workflow allowlist and provider-specific deployment |
| file:///C:/Dev/specrew-beta2-hardening/tests/unit/test-consumer-assumptions.ps1 | Fresh consumer paths, non-GitHub/non-Pester/local-only cases, and applicability claims |

## Change Shape and Hotspots

- Reviewed range: 141 files, 7860 insertions, 908 deletions.
- Primary campaign/containment hotspot: file:///C:/Dev/specrew-beta2-hardening/scripts/internal/continuous-co-review/review-campaign-orchestrator.ps1.
- Primary target-integrity hotspot: file:///C:/Dev/specrew-beta2-hardening/scripts/internal/continuous-co-review/review-target-port.ps1.
- Primary verification hotspot: file:///C:/Dev/specrew-beta2-hardening/scripts/internal/continuous-co-review/verification-plan-runner.ps1.
- Primary turn-attribution hotspot: file:///C:/Dev/specrew-beta2-hardening/extensions/specrew-speckit/scripts/conformance-turn-delta.ps1.
- Primary distribution hotspot: file:///C:/Dev/specrew-beta2-hardening/scripts/init/template-deploy.ps1.

The repository remains the sole product-code mutation authority. Verification runs in a disposable exact-digest copy, the reviewer target is independently OS-protected, the reviewer can write only its external candidate path, and the controller alone publishes authoritative terminal evidence. The finalization child cannot carry implementation changes.
