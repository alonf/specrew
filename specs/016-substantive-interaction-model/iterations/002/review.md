# Review: Iteration 002

**Schema**: v1
**Reviewed By**: Reviewer
**Reviewed At**: 2026-05-14
**Implementation Ref**: implementation boundary commit `6da2582`, plus bounded repairs `cbb378c` and `0e7ffbd`
**Overall Verdict**: needs-rework
**Explicit Reviewer Verdict**: needs-work
**Review Boundary**: Review boundary opened on the current tree; a blocking FR-008 post-commit synchronization defect was found, and review-verdict-signoff, retrospective, and closeout remain intentionally unopened

---

## Summary

Feature `016`, substantive interaction model, iteration `002`, is **NOT ACCEPTED YET**. Most review focus areas cleared with runtime evidence: FR-016 graduates `bare-path-in-boundary-handoff` by config (`.specrew\config.yml`) rather than detector rewrite, the stale-reference scan behaves cleanly on valid `file:///` targets and flags missing ones, the new scaffold replay passes end to end, and the four required corpus rows plus the approved carryover rows are present in `.specrew\quality\known-traps.md`.

I re-ran the live Iteration 002 scaffold replay, the mirrored unit-coverage script, and the repo-wide validator on the green tree. The repo validator passed in `179550 ms`; that re-measurement is truthful and reproducible, but it is materially higher than the implementation-boundary snapshot (`150061 ms`) and should be carried into retrospective discussion rather than hidden. The blocking defect is FR-008 automation on the real repository: after the review-boundary commit, `Sync-InteractionModelAuthorizationCommitReference` threw `Cannot move item because the item at '.\.squad\decisions.md.<guid>.tmp' does not exist.`, so the boundary needed a manual ledger repair instead of a clean post-commit synchronization pass.

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

- FR-008 automation gap — fixed-now for this boundary by manually updating `.squad\decisions.md` to `Commit Reference: 9201489`, but still needs implementation repair because `Sync-InteractionModelAuthorizationCommitReference` failed on the canonical repository with `Cannot move item because the item at '.\.squad\decisions.md.<guid>.tmp' does not exist.`

---

## Verdict

**NEEDS-WORK** — Feature `016`, substantive interaction model, iteration `002`, satisfies FR-016 (Iteration 2 graduation), FR-020 through FR-024, canonical UTC-seconds authoring, and stale-reference-scan-backed post-commit verification, but FR-008 post-commit synchronization is not ready for acceptance on the live repository. The replay lane proves the intended helper behavior, yet the actual review-boundary sync failed and required manual ledger repair, so implementation rework is required before review-verdict-signoff can open.

---

## Next Action

Await Alon Fliess's separate implementation-repair authorization focused on the FR-008 post-commit synchronization defect before reopening review for feature `016`, iteration `002`. Do not open review-verdict-signoff, retrospective, or closeout from this review boundary.

---

**Review Boundary Ref**: This artifact records the review boundary only. Review-verdict-signoff and all later lifecycle boundaries remain separate future steps.
