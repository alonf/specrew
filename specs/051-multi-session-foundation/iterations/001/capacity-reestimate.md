# Capacity Re-Estimate: F-051 (drift D-001 resolution input)

**Date**: 2026-05-31
**Trigger**: before-implement re-verification found tasks.md decomposing to 139 SP vs the approved 45–65 envelope (drift [D-001](drift-log.md)). Architect chose "re-estimate first" — audit the 97-task per-SP markup for inflation before any re-slice/de-scope.

## Rubric (calibrated to F-054 ~0.5 SP/task + justified code-vs-docs premium)

| Task shape | SP | Rationale |
| --- | --- | --- |
| New `.ps1` module file w/ several small functions | 1.0 | Scaffold + 3–4 small functions; modest premium over F-054 docs |
| Complex logic (atomic-write race, migration+commit, upgrade extract+preserve, multi-signal heuristics, mechanism selector) | 1.0–1.5 | Genuine algorithmic/edge-case weight |
| Simple logic / single function / wire into existing flow / CLI entry point | 0.5 | One small unit of code |
| Acceptance test (single scenario) | 0.5 | F-054 test-scaffold analogue |
| Validation task (run suite / run validator) | 0.5 | Mechanical |
| Doc / schema / data-model create-or-update | 0.5 | Most already produced at plan boundary |

The original markup averaged 1.43 SP/task (2.9× F-054's 0.49). This re-estimate averages ~0.62 SP/task — a ~25% premium over F-054 for code-vs-docs, which is defensible; the gap to 1.43 was inflation introduced in the 48→97 expansion (`3da2b23b`) without calibration.

## Per-iteration re-estimate

| Iteration | Tasks | Old SP | New SP | Cap | Old vs cap | New vs cap |
| --- | --- | --- | --- | --- | --- | --- |
| 1 (config + file classification) | 19 | 28 | **11.0** | ≤20 | ✗ +8 | ✓ |
| 2 (collision + claims + conflict-reduction + auto-detect) | 36 | 54 | **23.0** | 12–18 | ✗ +36 | ✗ +5 |
| 3 (spec-kit upgrade + version fix) | 21 | 29 | **13.5** | 10–15 | ✗ +14 | ✓ |
| 4 (identity split + brand-new worktree) | 21 | 28 | **13.0** | 8–12 | ✗ +16 | ✗ +1 |
| **Total** | **97** | **139** | **60.5** | 45–65 | ✗ +74 | ✓ |

### Tasks given the 1.0–1.5 SP premium (complex logic)

- Iter 1: T004 (Set-SessionMode + validation), T009 (file-classification.ps1), T010 (gitignore merge-without-dup)
- Iter 2: T020 (session-management.ps1), T021 (atomic session create), T023 (collision check), T024 (stale-lock clear), T027 (feature-claims.ps1), T030 (concurrent-claim detect), T034 (decisions-split.ps1), T036 (JSON-Lines logs), T042 (auto-detection.ps1), T045 (concurrent-write detect)
- Iter 3: T056 (detection fn), T059 (mechanism selector), T061 (extension upgrade extract+preserve = 1.5), T065 (live upgrade acceptance test), T066 (version-management.ps1)
- Iter 4: T077 (identity-split.ps1), T078 (identity split), T080 (migration+commit), T084 (worktree-detection.ps1), T085 (brand-new heuristics)

Everything else re-estimated to 0.5 SP.

## Conclusion

**The honest total is ~60.5 SP — within the approved 45–65 envelope.** No wholesale re-slice (7–8 iterations) and no FR de-scoping are warranted; the 139 figure was inflation, not real scope.

**One structural fix is still needed:** Iteration 2 packs four user stories (US3 collision + US4 claims + US5 conflict-reduction + US6 auto-detection = FR-007–024) and remains ~23 SP even honestly estimated — over its 12–18 cap and near the 20 SP ceiling. The minimal "split, don't raise" fix is to split Iteration 2 into two:

- **Iteration 2a** — US3 collision detection + US4 feature claims (T020–T033) ≈ **10 SP**
- **Iteration 2b** — US5 conflict-reduction + US6 auto-detection (T034–T052) + Iter-2 validation (T053–T055) ≈ **13 SP**

This yields **5 iterations**, each within a ≤20 SP cap, total ~60.5 SP. Iteration 4's marginal +1 (13 vs 12 cap) is within estimation rounding; trim one redundant validation task at plan-detailing if strict adherence is wanted.

## Required reconciliation if approved

1. Rewrite the per-task `[effort: N SP]` markup in tasks.md to the re-estimated values.
2. Replace the false "Effort Verification & SP Allocation" summary (18/18/14/12 → 62) with the corrected per-iteration sums.
3. Renumber Iteration 2 → 2a/2b (or 2/3 with 3/4/5 shift) and update the spec's TG-003 iteration windows + the 4→5 iteration count in Governance Alignment + the iteration headers/traceability matrix.
4. Re-run the capacity check to green; close drift D-001 as `spec-updated`.
