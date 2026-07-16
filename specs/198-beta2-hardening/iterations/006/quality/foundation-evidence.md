# Iteration 006 Foundation Quality Evidence

**Evidence boundary**: T049 authority-foundation verification
**Implementation commit**: `8f0c939b87d3ddb5bbdfa737d933369c83013b81`
**Reviewed-state digest**: `57b0c02b107e42c66759190b91e8d46705ae9816`
**Recorded at**: 2026-07-16
**Independent review**: pending T050

The reviewed-state digest certifies the exact reviewable worktree content used by the recorded
foundation run, including preserved tracked worktree changes and excluding only runtime/machinery
paths defined by the shared digest contract. The machine record is stored under
`.specrew/review/test-evidence/57b0c02b107e42c66759190b91e8d46705ae9816.json`; `.specrew`
is digest-excluded so recording evidence cannot change the identity it certifies.

## Executed quality lanes

| Lane | Command | Result | Binding |
| --- | --- | --- | --- |
| Iteration 006 foundation | `pwsh -NoProfile -File tests/f198-iteration006-foundation.ps1 -RecordEvidence` | PASS, 85 passed / 0 failed / 0 skipped, 29.009 s observed suite duration | Machine record for reviewed digest `57b0c02b107e42c66759190b91e8d46705ae9816` and HEAD `8f0c939b` |
| Complete F-198 registry | `pwsh -NoProfile -File tests/f198-regression-suite.ps1 -PerTestTimeoutSeconds 300` | PASS, all 45 explicitly registered suites green, 426.3 s wall time | Same implementation/worktree boundary before this evidence document was added |
| Packaged artifact | `Invoke-Pester -Path tests/integration/packaged-artifact-deploy.Tests.ps1` | PASS, 2/2 | Staged module imports and package FileList is complete |
| PowerShell syntax | PowerShell parser over every changed/untracked `*.ps1` implementation/test path | PASS, 18 files, zero parse errors | Changed implementation boundary |
| JSON and manifest | `ConvertFrom-Json` for `review-authority-mode.json`; `Test-ModuleManifest ./Specrew.psd1` | PASS | Checked-in authority configuration and package manifest |
| Whitespace integrity | `git diff --check` | PASS | Worktree diff |
| PSScriptAnalyzer | `Get-Command Invoke-ScriptAnalyzer` then error-severity scan when present | SKIP: tool not installed | No analyzer result is inferred |

## Requirement evidence

| Requirement | Result | Executable evidence |
| --- | --- | --- |
| SC-017 concurrency and authority invariants | satisfied for the Iteration 006 foundation | Barrier-synchronized processes prove one reservation winner and one claim winner; immutable conflicting facts fail closed; released pre-invocation slots append generations; deterministic reconciliation covers reserved, invoked, validating, terminal, and claim-retirement boundaries. |
| SC-018 exact isolated target/currentness | satisfied for the code-target foundation | A real external linked Git worktree freezes the exact dirty state, preserves origin HEAD/files, rejects placement inside the origin, cleans up, and classifies current versus `snapshot-moved`; moved findings remain useful but cannot approve current code. |
| SC-020 strict contracts and authoritative publication | satisfied for the foundation | Closed contracts reject unknown/version/identity/bounds substitutions; candidate Markdown is never parsed as authority; the controller alone publishes one immutable run-owned JSON result plus derived Markdown; timeout publishes only after verified tree death. |
| SC-021 timing, cost, and diagnostic foundation | partially satisfied as planned | Preflight precedes spend, post-invocation failures remain spent, every rerun is a visible new run, SystemClock is read per attempt, duration is directly observed, and progress is informational. Production heartbeat/usage/retro projection remains Iteration 007. |
| SC-019 five harnesses and three production OS runtimes | **not complete** | Iteration 006 intentionally uses fixture harness/runtime ports plus the production Git target. It provides no five-harness live-smoke or Windows/Linux/macOS runtime-adapter proof. Completion remains Iteration 007. |

## Claim boundary

This evidence supports only the Iteration 006 authority foundation. It does not claim production
campaign cutover, five real harness adapters, Windows Job Object plus Linux/macOS cgroup/process-group
runtime completeness, live reviewer smokes, or progress-to-retro projection. Those obligations remain
blocked on Iteration 007 authorization and implementation. T050 must independently review the exact
current committed reviewable tree; a stale, moved, partial, invalid, timed-out, or containment-uncertain
result cannot close the iteration.
