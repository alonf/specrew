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

**Second sighting, a different case** (DRIFT-007): 2026-11-15 17:24:35Z, Specrew CI run 43739142768, attempt 1,
Deterministic gate job 132889634266, the same step, on `b6ba0341` (Markdown records only). Case "I4b: all concurrent
journal rows remain present" (truncated in the log after "present and pa"): expected '16', got '15'. The suite had
passed on `d03a1f08` an hour earlier. Attempt 2 (job 132894671162) was green after one rerun the reviewer ruled for
that run only.

**Pattern**: two different concurrency cases in the same suite (I3a, then I4b) failed on two records-only pushes
within a day. That is a pattern for whoever owns the bootstrap hook chain, not a one-off. The standing rerun exception
does not cover this suite; the reviewer is asking the maintainer whether it should.

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

## H-026 — sighting: co-review-service.Tests.ps1:129 failed on a records push (standing rerun exception used)

**Severity**: low. A records-only push went red on the lease-handoff case, and the Contract lane was skipped.

**Observed**: 2026-11-16 00:57:31Z, Specrew CI run 43782743984, attempt 1, Deterministic gate job 133024616043 (Linux
runner), step "F-198 honesty regression suite (NFR-007)", on `1b8f22d6` (iteration 003 records only).
`tests/continuous-co-review/unit/co-review-service.Tests.ps1:129`, "a FAILED lease owner-handoff STOPS the spawned
supervisor ...": "Expected $null or empty ... but got System.Diagnostics.Process (pwsh)". 1 of 131 suites failed.
Rerun once under the standing exception; attempt 2 green (Deterministic gate job 133028487355, Contract lane job
133032838976). Recorded in 205's iteration 003 drift log as DRIFT-009.

**Status**: open; owner feature 203.
