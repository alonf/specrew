# Code Map: Iteration 007

**Schema**: v1
**Reviewed**: 2026-07-18
**Baseline Ref**: `d9cdd16457e322628957ea74de959a5457358852`
**Reviewed HEAD**: `58869dfe343e1183c08e22ed1a1dd7419a75dc71`
**Reviewed-State Digest**: `7c225e535f34597501ba1b3f0a80facfa7639e3e`

## Production Surface

| Surface | Responsibility | Task(s) |
| --- | --- | --- |
| file:///C:/Dev/specrew-beta2-hardening/scripts/specrew-review.ps1 | Public campaign execution, reconciliation, model/root/context plumbing, truthful terminal rendering | T051, T058, T060, T061 |
| file:///C:/Dev/specrew-beta2-hardening/scripts/internal/continuous-co-review/ | Campaign authority, immutable store, strict ingress, target/root policy, five harness ports, three runtime ports, recovery, progress, retro, signoff gating, and bounded finalization | T034b, T051, T053–T058, T060, T061 |
| file:///C:/Dev/specrew-beta2-hardening/scripts/internal/bootstrap/ | Genuine-human capture filtering and rolling handover integration | T030–T032 |
| file:///C:/Dev/specrew-beta2-hardening/extensions/specrew-speckit/scripts/shared-governance.ps1 | Append-only boundary correction and effective-state readers | T033 |
| file:///C:/Dev/specrew-beta2-hardening/extensions/specrew-speckit/scripts/specrew-conformance-provider.ps1 | Workshop-aware versus ordinary Stop materiality | T052 |
| file:///C:/Dev/specrew-beta2-hardening/.github/workflows/cross-platform-validation.yml | Hosted deterministic Windows/Ubuntu/macOS review-runtime matrix | T059 |
| file:///C:/Dev/specrew-beta2-hardening/scripts/t060-local-platform-smoke.ps1 | Bounded Windows/Linux live-smoke operator package | T060 |
| file:///C:/Dev/specrew-beta2-hardening/scripts/t060-local-macos-smoke.ps1 | Bounded local-Mac live-smoke package | T060 |
| file:///C:/Dev/specrew-beta2-hardening/scripts/validate-t060-local-macos-evidence.ps1 | Independent Mac package/commit/digest validation | T060 |

## Test Surface

| Surface | Behavior proved |
| --- | --- |
| file:///C:/Dev/specrew-beta2-hardening/tests/f198-regression-suite.ps1 | Process-isolated 57-suite Feature 198 release registry |
| file:///C:/Dev/specrew-beta2-hardening/tests/continuous-co-review/ | Authority, target, ingress, adapter, runtime, recovery, progress, retro, public-command, package, platform-fault, and finalization-envelope contracts |
| file:///C:/Dev/specrew-beta2-hardening/tests/integration/verdict-capture-blocks.tests.ps1 | Exact fabricated packet sequences, genuine/machinery distinction, and fail-closed capture |
| file:///C:/Dev/specrew-beta2-hardening/tests/unit/boundary-correction-ledger.tests.ps1 | Append-only correction and effective boundary state |
| file:///C:/Dev/specrew-beta2-hardening/tests/integration/f198-iter005-hook-health-production-path.tests.ps1 | Production-path hook health under bounded reviewer execution |

## Change Shape and Hotspots

- Reviewed range: 121 files, 10541 insertions, 785 deletions.
- Primary authority/orchestration hotspot: file:///C:/Dev/specrew-beta2-hardening/scripts/internal/continuous-co-review/review-campaign-orchestrator.ps1.
- Primary signoff/finalization hotspot: file:///C:/Dev/specrew-beta2-hardening/scripts/internal/continuous-co-review/review-signoff-evidence-gate.ps1.
- Primary immutable-store hotspot: file:///C:/Dev/specrew-beta2-hardening/scripts/internal/continuous-co-review/review-authority-store.ps1.
- Primary target-integrity hotspot: file:///C:/Dev/specrew-beta2-hardening/scripts/internal/continuous-co-review/review-target-port.ps1.
- Primary public/recovery hotspot: file:///C:/Dev/specrew-beta2-hardening/scripts/specrew-review.ps1.
- Primary capture-integrity hotspot: file:///C:/Dev/specrew-beta2-hardening/scripts/internal/bootstrap/ConversationCaptureAccessor.ps1.

The repository remains the sole code-mutation authority. Reviewers receive external disposable targets and may write only run-owned candidate output; the controller alone publishes authoritative terminal results. The evidence finalization is a single deny-by-default direct child and cannot modify implementation, tests, specifications, or contracts.
