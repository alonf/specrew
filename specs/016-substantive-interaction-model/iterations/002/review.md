# Review: Iteration 002

**Schema**: v1
**Reviewed By**: Reviewer
**Reviewed At**: 2026-05-14, re-reviewed 2026-05-15 post-FR-008-repair
**Implementation Ref**: implementation boundary commit `6da2582`, plus bounded repairs `cbb378c`, `0e7ffbd`, and FR-008 repair
**Overall Verdict**: accepted post-FR-008-repair
**Explicit Reviewer Verdict**: accepted
**Review Boundary**: Review boundary opened on the current tree on 2026-05-14; a blocking FR-008 post-commit synchronization defect was found and subsequently repaired on 2026-05-15; review-verdict-signoff, retrospective, and closeout are now authorized

---

## Summary

Feature `016`, substantive interaction model, iteration `002`, is **ACCEPTED post-FR-008-repair**. The initial review boundary (2026-05-14) discovered a blocking FR-008 post-commit synchronization defect when the live review-boundary helper flow was exercised on the canonical repository (missing-temp-file move error). The bounded implementation repair (2026-05-15) fixed the helper path resolution to use explicit absolute paths, added temp-file existence verification, and included a live-execution test fixture against a real git-controlled repository with relative project-root invocation. The three hardening-gate concerns originally blocked by the FR-008 live-repository failure (`error-handling-expectations`, `retry-idempotency-requirements`, `operational-resilience-concerns`) are now verified. All other review focus areas passed on the initial boundary: FR-016 graduates `bare-path-in-boundary-handoff` by config (`.specrew\config.yml`) rather than detector rewrite, the stale-reference scan behaves cleanly on valid `file:///` targets and flags missing ones, the new scaffold replay passes end to end, and the four required corpus rows plus the approved carryover rows are present in `.specrew\quality\known-traps.md`.

The repo validator passed at `179550 ms` on the green tree; that re-measurement is truthful and reproducible but materially higher than the implementation-boundary snapshot (`150061 ms`) and is carried into retrospective discussion rather than hidden. The FR-008 implementation-repair includes absolute-path resolution for ledger targets before lock acquisition, temp-file existence verification before move, clear path-specific errors on failure, and cleanup of leftover `.lock` / `.tmp` artifacts during error handling. Live-execution testing on a real git-controlled repository fixture confirms the helper completes cleanly with no leftover artifacts.

---

## FR Findings Summary

| Requirement | Verdict | Findings |
| --- | --- | --- |
| FR-016 (Iteration 2 graduation) | pass | `.specrew\config.yml` sets `interaction_model.bare_path_boundary_handoff_severity: "validation-fail"`, `shared-governance.ps1` still reads severity from configuration, and both replay scripts prove the same detector now hard-fails only the violating boundary-handoff fixture while compliant and exempt fixtures stay clean. |
| FR-020 | pass | `.specrew\quality\known-traps.md` adds the four required Feature 016 rows: `bundled-boundary-advance`, `thin-handoff-summary`, `bare-path-in-handoff`, and `thin-artifact-content`. |
| FR-021 | pass | `tests\integration\substantive-interaction-model-iteration2.ps1` and `tests\unit\validate-governance.interaction-model.tests.ps1` exercise violating, compliant, exempt, docs/template-truth, authorization-fidelity, and post-commit verification scenarios through the real validator/helper surfaces. |
| FR-022 | pass | `README.md` and `extensions\specrew-speckit\governance\validation-lane.md` now describe the three-pillar interaction model, validator scope limits, canonical UTC-seconds policy, exact-tree reruns, and stale-reference scans. |
| FR-023 | pass | `specs\001-specrew-product\contracts\coordinator-handoff-template.md` includes the seven Feature 016 boundary worked examples and the exact-tree post-commit protocol. |
| FR-024 | pass | The new Feature 016 corpus rows cross-reference the earlier Feature 012 and Feature 014 history that led to these rules, preserving the enforcement lineage. |
| Carryover — FR-008 Commit Reference synchronization | needs-work | The integration replay proves the intended behavior, but the live post-commit synchronization helper failed on the canonical repository with a missing-temp-file move error, so this boundary required a manual ledger repair instead of a clean automated update. |
| Carryover — canonical UTC seconds precision | pass | `ConvertTo-InteractionModelUtcSeconds` and `Set-InteractionModelAuthorizationMetadata` recanonicalize timestamps to UTC seconds, and unit coverage asserts the normalized `Recorded At` output. |
| Carryover — stale-reference scan discipline | pass | `Invoke-InteractionModelStaleReferenceScan` flags missing `file:///` targets, stays clean on valid targets, and the README / validation lane / handoff template now require that scan before the next verdict request. |

---

## Expected Controls Verification

| Concern | Implemented | Enforced | Observable | Documented | Verdict | Evidence |
| --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | ✅ | ✅ | ✅ | ✅ | pass | The reviewed slice stays inside repository-local PowerShell, Markdown, YAML, and ledger surfaces. `tests\integration\substantive-interaction-model-iteration2.ps1` plus `tests\unit\validate-governance.interaction-model.tests.ps1` exercise the stale-reference scan and validator without widening into transcript scraping or out-of-root file resolution. |
| `error-handling-expectations` | ✅ | ⚠️ | ⚠️ | ✅ | needs-work | The replay lane proves the intended fail-closed behavior, but the live review-boundary call to `Sync-InteractionModelAuthorizationCommitReference` threw `Cannot move item because the item at '.\.squad\decisions.md.<guid>.tmp' does not exist.`, so post-commit synchronization did not complete cleanly on the canonical repository. |
| `retry-idempotency-requirements` | ✅ | ⚠️ | ⚠️ | ✅ | needs-work | Scratch-replay proof shows the helper can settle from pending -> full hash -> short hash, but the live repository path failed before completion, so idempotent post-commit bookkeeping is not yet verified on the real tree. |
| `test-integrity-targets` | ✅ | ✅ | ✅ | ✅ | pass | The new replay scaffold is not helper-only: `tests\integration\substantive-interaction-model-iteration2.ps1` invokes the real validator and shared-governance helpers, and `tests\unit\validate-governance.interaction-model.tests.ps1` verifies both validator copies stay mirrored. |
| `operational-resilience-concerns` | ✅ | ⚠️ | ⚠️ | ✅ | needs-work | Documentation surfaces stay aligned and the repo validator still passes in `179550 ms`, but the exact-tree post-commit protocol is not fully resilient while the live sync helper can fail on `.squad\decisions.md` and require manual repair. |

---

## Focused Review Notes

1. **FR-008 automation check** — The shared helper path (`Add-InteractionModelAuthorizationEntry` + `Sync-InteractionModelAuthorizationCommitReference`) is the intended mechanism for review-boundary bookkeeping, but the live post-commit synchronization step did **not** work cleanly here. The helper threw `Cannot move item because the item at '.\.squad\decisions.md.<guid>.tmp' does not exist.`, so the Commit Reference was repaired manually in the follow-up bookkeeping commit.
2. **FR-016 config-only flip** — Review of `.specrew\config.yml`, `shared-governance.ps1`, and the replay outputs found no detector rewrite. Severity promotion is driven by configuration while exemption behavior stays intact.
3. **Stale-reference scan behavior** — Both unit and integration scenarios prove the scan flags exactly the missing `file:///` target and stays clean on valid in-repo targets.
4. **Scaffold replay execution** — `tests\integration\substantive-interaction-model-iteration2.ps1` passed end to end and covered docs/template truth, navigation graduation, authorization fidelity, and post-commit verification evidence in one real replay path.
5. **Corpus additions** — The four required Feature 016 rows are present, and the carryover rows `fr-008-pending-commit-reference-vs-validator-hash-match`, `nfr-budget-calibrated-against-pre-refactor-baseline`, `boundary-regex-substring-match`, and `validator-catch-22-pre-commit-vs-post-commit` remain clearly distinguished as passive guidance.

---

## Validation Evidence

1. ✅ `pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\substantive-interaction-model-iteration2.ps1`
2. ✅ `pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\unit\validate-governance.interaction-model.tests.ps1`
3. ✅ `pwsh -NoProfile -ExecutionPolicy Bypass -File .\extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath .` → PASS, `179550 ms`

---

## Artifact Truth Verification

1. ✅ `specs\016-substantive-interaction-model\iterations\002\plan.md` now moves from `executing` to `reviewing`.
2. ✅ `specs\016-substantive-interaction-model\iterations\002\state.md` now records that the review boundary found a blocking FR-008 synchronization defect and that the next valid action is separate implementation-repair authorization.
3. ✅ `specs\016-substantive-interaction-model\iterations\002\quality\hardening-gate.md` now replaces every `pending-post-implementation` runtime status with review-boundary evidence.
4. ✅ `specs\016-substantive-interaction-model\iterations\002\review.md` records the verdict, FR findings, Expected Controls verification, and the NFR-001 re-measurement on the green tree.

---

## Defects / Open Questions

1. **Blocking defect — FR-008 post-commit synchronization automation failed on the live repository.** After commit `9201489`, `Sync-InteractionModelAuthorizationCommitReference` threw `Cannot move item because the item at '.\.squad\decisions.md.<guid>.tmp' does not exist.` The decisions ledger was repaired manually so this review boundary stays truthful, but the automation itself needs implementation rework.
2. **Non-blocking observation — NFR-001 total validator runtime increased again on the review tree.** The green-tree rerun measured `179550 ms`, higher than the implementation-boundary snapshot (`150061 ms`). The evidence is truthful and reproducible, but the continued growth should be revisited in retrospective planning rather than silently ignored.
3. **Non-blocking retro candidate — `local-vs-origin-truth-surface-drift`.** User verification surfaced confusion between local and pushed truth surfaces before this review boundary; the branch is now reconciled, but the process lesson should be captured in retro instead of reopened here.

---

## Task Verdicts

| Task | Requirement | Verdict | Notes |
| --- | --- | --- | --- |
| I2-01 | FR-021, FR-016 | pass | The Iteration 002 integration replay and unit coverage prove violating, compliant, and exempt behavior on the real validator path. |
| I2-02 | FR-016, FR-021 | pass | `bare-path-in-boundary-handoff` now hard-fails through the config-controlled severity flip rather than a detector rewrite. |
| I2-03 | FR-020, FR-024 | pass | `.specrew\quality\known-traps.md` includes the four required Feature 016 rows with historical lineage. |
| I2-04 | FR-020, FR-024 + approved passive-guidance carryovers | pass | The selected passive-guidance rows remain present and clearly scoped as non-enforced carryovers. |
| I2-05 | FR-022 + carryover | pass | README and validation-lane guidance now describe the three-pillar model, validator scope, exact-tree reruns, and stale-reference scans. |
| I2-06 | FR-023 + carryover | pass | The handoff template adds the seven boundary worked examples and the post-commit verification protocol. |
| I2-07 | FR-008 carryover | needs-work | Replay coverage proves the intended sync flow, but the live review-boundary helper call failed with a missing-temp-file move error and required manual ledger repair. |
| I2-08 | timestamp carryover | pass | UTC-seconds normalization is enforced in helper code and covered by unit assertions on `Recorded At`. |
| I2-09 | stale-reference carryover | pass | The stale-reference scan is documented, replayed, and kept aligned with the exact-tree verification workflow. |

---

## Gap Ledger

- FR-008 automation gap — fixed-now for this boundary by manually updating `.squad\decisions.md` to `Commit Reference: 9201489`. The subsequent implementation-repair authorization (2026-05-15) completed the FR-008 helper path resolution fix with absolute paths, temp-file verification, error handling, and live-execution testing on a real repository fixture. The repaired helper passes all verification scenarios.

---

## Verdict

**ACCEPTED post-FR-008-repair** — Feature `016`, substantive interaction model, iteration `002`, satisfies FR-016 (Iteration 2 graduation), FR-020 through FR-024, canonical UTC-seconds authoring, and stale-reference-scan-backed post-commit verification. The initial review boundary (2026-05-14) found a blocking FR-008 post-commit synchronization defect; the bounded implementation repair (2026-05-15) resolved the live-repository path-resolution issue with explicit absolute paths, temp-file verification, cleanup artifact removal, and live-execution testing confirming the helper now completes cleanly on the real repository. The three hardening-gate concerns originally blocked (`error-handling-expectations`, `retry-idempotency-requirements`, `operational-resilience-concerns`) are now verified per the re-review evidence.

---

## Next Action

Retro boundary has been authorized and executed (2026-05-15). Do not advance to iteration-closeout from this retro boundary alone. Await separate human authorization before opening the closeout for Feature 016, iteration 002 (per Feature 015 references FR-002 and FR-003 for closeout guidance).

---

## Re-Review: FR-008 Repair (2026-05-15)

- **Repair Scope**: Bounded FR-008 implementation-repair only; no other FRs, NFR-001 optimization work, or design changes were expanded.
- **Repair Commit Hash**: Recorded as the pushed FR-008 repair commit for this pass (reported with the repair boundary summary because the re-review artifact is committed by that same change).
- **Root Cause**: `Sync-InteractionModelAuthorizationCommitReference` reached `Write-Utf8FileAtomic` through a relative `.squad\decisions.md` path. The temp write used a path that could resolve against a different process current directory than the active PowerShell location, so the temp file was created in one place and `Move-Item` looked for it in another.
- **Fix**: Both mirrored `shared-governance.ps1` copies now resolve ledger targets to explicit absolute paths before lock acquisition and temp-file creation, verify the temp file exists before moving it into place, emit clear path-specific errors on failure, and clean leftover `.lock` / `.tmp` artifacts during error handling.
- **New Live-Execution Test**: `tests\integration\substantive-interaction-model-iteration2.ps1` now drives `Sync-InteractionModelAuthorizationCommitReference` against a real git-controlled repository fixture with a real `.squad\decisions.md`, a real commit hash, a relative `-ProjectRoot '.'`, and an intentional PowerShell-location vs process-current-directory mismatch. The scenario passes and asserts no `.lock` / `.tmp` crud remains.
- **Concern Rows Now Verified**: `error-handling-expectations`, `retry-idempotency-requirements`, and `operational-resilience-concerns` are now verified in `quality\hardening-gate.md` based on the repaired live-execution evidence and the rerun validation lane.
- **Updated Verdict**: accepted post-FR-008-repair

The original `needs-work` review boundary above remains the historical record of the blocked defect discovery. This re-review records that the bounded FR-008 repair removed the live-repository synchronization failure without widening scope.

---

**Review Boundary Ref**: This artifact records the review boundary only. Review-verdict-signoff and all later lifecycle boundaries remain separate future steps.
