# Iteration 007 Drift Log

**Feature**: F-044 | **Iteration**: 007 — Linux Portability + Docs Sweep + PR Readiness (LIVE-TRACKED)

## Drift #1 — T007 absorbed a bootstrap-to-iteration test repair that wasn't in plan

- **Planned (T007)**: Pre-PR final verification — merge `origin/main`, bump `.specrew/config.yml` to 0.27.0, run full integration test suite, parse-check, markdownlint, write PR description.
- **Surfaced**: Running the 12 CI integration tests revealed `bootstrap-to-iteration.ps1` had 2 stale assertions (Squad-branded text from before F-044's Crew-neutral bootstrap output landed in Slice 9).
- **Resolution**: Updated assertions in-place (`'Add extra Squad members'` → `'Add extra Crew members'`; `'Keep the Specrew-managed baseline block intact'` → `'Keep the Specrew-managed baseline charters intact'`). Test now passes.
- **Why this isn't scope creep**: This is mechanical alignment between a test and the production code's output — the production output is correct (Crew-neutral per F-044), the test assertion is the stale party. Letting the test fail through to PR would have CI red on a code change that's strictly an improvement.
- **Why this isn't iter-008**: The fix was 2 lines, found and resolved in <5 minutes, and falls cleanly under T007's "run full integration test suite" mandate (which implicitly requires they pass).

## Drift #2 — `evaluation/scorers/process-scorer.ps1` sibling bug found via T002 audit

- **Planned (T002)**: "Audit ALL extension scripts + scripts/* for hardcoded `C:\` / Windows-only path constants".
- **Surfaced**: T002 grep'd broader patterns (not just `C:\`) including `-ChildPath '<name>\...'` literals. Found ONE: `evaluation/scorers/process-scorer.ps1:92` had `'evaluation\report.md'` (backslash literal — Linux Join-Path treats `\` as part of filename).
- **Resolution**: Single-character fix: `\` → `/`.
- **Why this is in-scope**: T002 explicitly mandated the sibling-bug audit. The find was within the surface T002 was auditing.
- **Lesson**: This bug had never surfaced because Antigravity's WSL dogfood didn't exercise `evaluation/scorers/`. The proactive grep paid off — saved a future surprise on whichever dogfood does eventually exercise that code path.

## Surfaced-but-deferred (recorded for traceability)

- **`baseline-hygiene` + `lifecycle-boundary-sync` integration tests fail on origin/main** (not iter-007 introduced). Markdownlint gate inside `Invoke-SpecrewBoundaryStateSync` halts because the auto-fixed `last-start-prompt.md` violations need to be committed but the test harness doesn't commit them. Confirmed by stash-test on origin/main. Real test workflow bug, not iter-007 scope.
- **dashboard.md missing for 8 closed iterations** — pre-existing across F-031, F-043, F-044/001..006. Dashboard auto-render is open work (Proposal 046+048 bundle).
- **proposals/INDEX.md entries deferred** (iter-005 drift-log already records this).
- **Host-specific init deferral proposal** — separate proposal candidate per memory; draft post-PR-merge.
