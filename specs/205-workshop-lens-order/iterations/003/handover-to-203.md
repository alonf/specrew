# Hand-over to feature 203: findings from 205 iteration 003

**From**: feature 205 (workshop lens order), iteration 003 | **Written**: 2026-11-15

Feature 205 does not edit files under `scripts/internal/continuous-co-review/`, the review engine, the bootstrap
capture stores or `specrew-conformance-provider.ps1`. Hand-overs H-001 to H-022 are in iterations 001 and 002
(sealed); numbering continues here.

## H-023 — sighting: HookRenderDedupe I3a rendered once where two concurrent fires must both render

**Severity**: low to medium. A records-only push went red on a timing-dependent hook-chain case, and the Contract lane
was skipped as a consequence.

**Observed**: 2026-11-15 03:22:57Z, Specrew CI run 43670851775, attempt 1, Deterministic gate job 132681450478, step
"Bootstrap suite (F-174 hook chain - incl. directive delivery cap, P2)", on `ce444ca8` (iteration 002 closeout records
only). `tests/bootstrap/HookRenderDedupe.Tests.ps1`, case "I3a: two concurrent missing-id fires BOTH render (per-launch
fallback keys, never shared suppression)": expected '2', got '1'. Attempt 2 passed after one rerun the reviewer
ruled. Recorded in 205's iteration 003 drift log as DRIFT-001.

**Why it is useful**: the third different CI failure outside 205's pushes in one night (with H-022's
`empty-result-retry` and iteration 002's Windows Pester install). The test was last changed by feature 202
(`7bb8028f`); earlier records naming it are listed in DRIFT-001.

**Status**: open; owner feature 203 (CI stability), or the hook chain's owner if 203 names another.

## H-024 — the iteration plan scaffold refuses a requirement scope and, without one, lists every requirement

**Severity**: low. Each iteration's scope is written by hand.

**Observed**: iteration 002 (its DRIFT-002): `scaffold-iteration-plan.ps1 -RequirementScope FR-022,FR-024` refused
with `Requirement(s) not found in spec: FR-022,FR-024`, though both are in the spec. Iteration 003 (its DRIFT-002): run
without a scope, the stub lists FR-001 to FR-032. Not handed over in iteration 002.

**Status**: open; owner feature 203.

## H-025 — the quality resolver reads a PowerShell, markdown and YAML change as frontend (third sighting)

**Severity**: low. The plan's quality profile and concurrency lines are corrected by hand each iteration.

**Observed**: iterations 001, 002 (its DRIFT-001) and 003 (its DRIFT-003). The scaffold reads "Frontend-oriented
signals dominate the scoped requirements"; the resolved profile names Node and a browser SPA. The real stack is
PowerShell 7 scripts, lens markdown, a YAML catalog and tests.

**Status**: open; owner feature 203.
