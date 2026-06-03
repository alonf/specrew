# Coverage Evidence: Iteration 003

**Schema**: v1
**Prepared**: 2026-06-03
**Overall Verdict**: pending-review-signoff (producer-side; the Reviewer accepts at review-signoff)

> **Scope**: greenfield/downstream hygiene — FR-012 (suppress spurious multi-developer warning
> from a single-dev bootstrap) and FR-013 (fresh-greenfield baseline-commit handling). FR-013 is
> verify-clean for the baseline logic (prove-first) + a conservative guidance nudge per the
> maintainer C+nudge decision (no auto-commit).

## Test Strategy

- Reproduce-first per defect: FR-012 (single-dev bootstrap → spurious "Multiple developers
  detected") FAILED on pre-fix code and passes after; FR-013 prove-first showed the baseline
  already resolves once a commit exists and the zero-commit omission is intentional tested
  fail-safe (Feature-029), so the FR-013 fix is the guidance nudge + SC-009 coverage only.
- Tests are interleaved with the fixes (SC-008 with T002, SC-009 with T003).

## Tests Run

| Command | Result | Pass | Fail | Exit | Notes |
| ------- | ------ | ---- | ---- | ---- | ----- |
| `pwsh -File tests/unit/feature-051-iteration2b.tests.ps1` | pass | 21 | 0 | 0 | FR-012 / SC-008: single-dev bootstrap → no multi-dev signal/recommendation; genuine 2-author signal still fires with write-signal corroboration (no over-suppression). Co-located with the detector it covers (auto-detection.ps1). |
| `pwsh -File tests/integration/design-gate-runtime-hardening-greenfield-baseline.tests.ps1` | pass | 6 | 0 | 0 | SC-009 **primary** (committed, runs green LOCALLY): zero-commit greenfield start emits guidance, does NOT stamp a baseline, creates NO commit; post-commit the repo baseline-refresh path (`Get-SpecrewCurrentHeadCommitHash` + `Update-BaselineCommitHashInFrontmatter`) resolves to HEAD + stays consistent. |
| `pwsh -File tests/integration/baseline-hygiene.tests.ps1` (SC-009 co-located) | not run here | — | — | — | A co-located SC-009 also lives in the Feature-029 baseline suite, but it is NOT independently verified in this packet: locally the suite halts earlier at its pre-existing repeated-tasks gate (see note), and its CI execution is not confirmed here. Do not rely on it as evidence — the verified SC-009 enforcement is the row above. |
| `pwsh -File tests/unit/design-gate-runtime-hardening.tests.ps1` | pass | 17 | 0 | 0 | Feature-141 unit suite — no regression from the FR-013 `specrew-start.ps1` guidance change. |
| `pwsh -File tests/integration/multi-host-launch-path.tests.ps1` | pass | 24 | 0 | 0 | Iteration-2 FR-011/FR-014 — no regression from the `specrew-start.ps1` change. |
| Governance validator (`extensions/specrew-speckit/scripts/validate-governance.ps1 -NoCacheRead`) | pass | — | — | 0 | All 4 scoped iterations PASS (incl. 141/003), re-run post-merge of origin/main (0.31.0 stable + Feature 140) and post state/plan reconciliation. |

**Pre-existing local-env note (honest):** the full `baseline-hygiene.tests.ps1` suite halts locally at its
EXISTING repeated-tasks idempotency sub-check — the installed-module F-033 markdownlint pre-boundary gate
auto-fixes the regenerated `last-start-prompt.md` and halts. Confirmed PRE-EXISTING by stashing the
iteration-003 changes and re-running at HEAD (identical halt); it is environmental (local `markdownlint-cli`
present). To avoid resting SC-009 enforcement on an unverified "green in CI" assumption, SC-009's PRIMARY
home is the committed, **locally-green** `tests/integration/design-gate-runtime-hardening-greenfield-baseline.tests.ps1`
(6 pass / 0 fail, watched pass against repo code). The co-located baseline-hygiene SC-009 is a bonus whose
execution is NOT verified in this packet (the local suite halts at the pre-existing gate and CI status is
unconfirmed here) — it is not relied on as evidence. SC-009 part-2 calls the same repo functions the boundary
sync uses (`Get-SpecrewCurrentHeadCommitHash` and `Update-BaselineCommitHashInFrontmatter`).

## TG-006 Gap Ledger (implemented / enforced / observable / documented)

| Behavior | Implemented | Enforced (test) | Observable (runtime) | Documented |
| -------- | ----------- | --------------- | -------------------- | ---------- |
| FR-012 — single-dev bootstrap writes do not trigger the multi-dev recommendation | `scripts/auto-detection.ps1` (`$writeSignals` corroborates a distinct-actor signal, never triggers alone) | SC-008 (`tests/unit/feature-051-iteration2b.tests.ps1`) | `Get-SpecrewMultiDeveloperSignals` → `has_multi_developer_signal=False` in a fresh single-dev repo; no recommendation surfaced at the first feature boundary | quickstart.md Iteration-3 + drift-log.md classification |
| FR-012 — genuine multi-developer activity still surfaces | same (≥2 authors / ≥2 machines / ≥3 numbered branches still trigger; write count shown as corroborating detail) | SC-008 over-suppression guard (2-author repo still recommends) | recommendation message includes "close-together shared-state writes" alongside a genuine signal | quickstart.md Iteration-3 |
| FR-013 — zero-commit greenfield: fail-safe + guidance | `scripts/specrew-start.ps1` `Save-StartArtifacts` else-branch (guidance line; no stamp; no commit created) | SC-009 part 1 (`tests/integration/design-gate-runtime-hardening-greenfield-baseline.tests.ps1`) | `specrew start` in a no-commit repo emits "No baseline commit yet … make an initial commit"; no `baseline_commit_hash` stamped; no commit created | quickstart.md Iteration-3 + drift-log.md |
| FR-013 — baseline resolves once a commit exists, consistently | existing Feature-029 boundary refresh (`sync-boundary-state.ps1:1209-1210`), preserved | SC-009 part 2 (`design-gate-runtime-hardening-greenfield-baseline.tests.ps1`) + Feature-029 lifecycle test | post-commit `baseline_commit_hash == HEAD`; the stamped value matches what the reader resolves | quickstart.md Iteration-3 |
| SC-008 (test) | n/a | `tests/unit/feature-051-iteration2b.tests.ps1` (21/0, locally green) | reproduce-first (failed pre-fix, passes after) | this ledger |
| SC-009 (test) | n/a | `tests/integration/design-gate-runtime-hardening-greenfield-baseline.tests.ps1` (6/0, locally green, primary) + `baseline-hygiene.tests.ps1` (co-located; not verified here) | verified against repo code | this ledger |

## Spec note (resolved-by-clarification, per maintainer)

US6-AC1's literal "baseline MUST resolve to a real commit hash … with no prior history" is satisfied the
moment a commit exists (which it does by the first meaningful boundary, when the agent commits the spec).
The degenerate zero-commit case has nothing to resolve to and is handled by the Feature-029 fail-safe + the
guidance nudge, NOT by auto-creating a commit (which would contradict the tested contract at
`tests/integration/baseline-hygiene.tests.ps1:372-375` and create commits on the user's behalf). Recorded
as resolved-by-clarification, not an auto-commit behavior change.

## Out of scope (not reproduced as greenfield/downstream leaks → follow-ups, not fixed)

- FR-012 version-mismatch-vs-placeholder (`0.0.0`) and author/branch-fanout signals fire only under
  Specrew SOURCE/dev-repo conditions (placeholder version, many authors/branches), not in a fresh
  greenfield/downstream. Self-host-only; no leak observed.
