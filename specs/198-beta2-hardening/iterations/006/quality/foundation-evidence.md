# Iteration 006 Foundation Quality Evidence

**Evidence boundary**: T049 authority-foundation verification
**Implementation commit**: `8f0c939b87d3ddb5bbdfa737d933369c83013b81`
**Reviewed-state digest**: `57b0c02b107e42c66759190b91e8d46705ae9816`
**Recorded at**: 2026-07-16
**Independent review**: incomplete T050; the second authorized Claude invocation produced a valid current findings result, all findings are corrected, and the corrected tree requires a new human allowance

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

## Pre-review operational correction

The first T050 operational rehearsal did not start Claude: the legacy launcher halted at its historical
round ceiling with `reviewed:false`. A later new-contract preflight then exposed a real recovery defect
before provider invocation. Windows rejected the initially long external worktree path, and the raw
adapter exception exceeded the immutable release fact's 512-character bound; publication of that
release failed and masked the target error. Commit `8cadb7aa` now bounds release reasons to 512 and
terminal failure reasons to 2000 with an explicit `...[truncated]` marker. The regression uses a
4,000-character target exception and proves the controller still releases the reservation, publishes
a visible preflight failure, and records no spend.

Post-correction verification on 2026-07-16:

- `pwsh -NoProfile -File tests/f198-iteration006-foundation.ps1`: PASS, 87/87.
- `pwsh -NoProfile -File tests/f198-regression-suite.ps1 -PerTestTimeoutSeconds 300`: PASS, all 45 suites, 421.9 s wall time.
- PowerShell parser and `git diff --check`: PASS.

The original `57b0c...` record above remains immutable historical T049 evidence. Digest
`2540aad2e6c0b3205eecece4a457a2cf38545078` became the target of the first provider invocation and is
also historical after the advisory corrections below. A new exact-tree record is written after the
correction commit and is the only digest eligible for a complete T050 rerun.

## T050 invalid attempt and advisory correction

Campaign `cmp-i006-t050-claude-v2`, run `run-i006-t050-claude-v2`, invoked Claude 2.1.210 once after
all preflights passed. The run observed 639.140 seconds, verified containment and process-tree
termination, and classified the target as current. Claude returned prose followed by JSON instead of a
single JSON object, so the strict ingestor correctly published `completion=none`, `verdict=incomplete`,
`runtime_outcome=invalid-output`, `validation=invalid`, and `can_approve_current=false`, with failure
reason `prose-wrapped-json: prose-wrapped-json`. No candidate finding became authoritative.

The five embedded comments were nevertheless preserved as fallible advisory input and addressed
within T050's approved correction scope:

1. Duplicate-combination detection now reads the persisted ReviewRun `schema_version` and its fixture
   uses the closed stored shape.
2. Runtime preflight has its own required spend-policy key and publishes
   `preflight-failed:runtime`, rather than blaming the harness.
3. Reused reservation IDs are rejected before allowance state can become ambiguous.
4. The unused `$claimHeld` variable was removed.
5. The foundation map now warns that changing to campaign mode before Iteration 007 public-command
   wiring suppresses legacy authority without a command-reachable replacement.

Post-advisory-correction verification on 2026-07-16:

- Focused authority/store/orchestrator suites: PASS, 48/48.
- `pwsh -NoProfile -File tests/f198-iteration006-foundation.ps1`: PASS, 87/87, 30.950 s observed suite duration.
- `pwsh -NoProfile -File tests/f198-regression-suite.ps1 -PerTestTimeoutSeconds 300`: PASS, all 45 suites, 426.4 s wall time.
- `git diff --check`: PASS.

The authoritative result and derived report are machine-local at
file:///C:/Dev/specrew-beta2-hardening/.specrew/review/campaign-t050-i006/authority-store-v2/campaigns/cmp-i006-t050-claude-v2/runs/run-i006-t050-claude-v2/.
The durable review summary is file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/iterations/006/review.md.
The provider allowance is spent; no complete rerun may start without a separate human grant.

## T050 valid review and second correction

Separately authorized run `run-i006-t050-claude-v3` reviewed exact digest
`6942d56832910922d4967aaf539a1744f2ebd122`. It completed in 721.328 seconds with verified
containment and termination, `current` applicability, valid strict JSON, and a complete findings
verdict. It independently reran the foundation suite at 87/87 and confirmed all five earlier advisory
corrections. The controller published four current findings and `can_approve_current=false`.

The four findings are corrected within T050 scope: immutable replay compares validated persisted
canonical text without timestamp coercion; active claim contention has a distinct closed
`claim-contended` outcome; possibly live snapshots remain for recovery until termination is verified;
and T042/T046 owner globs identify their delivered components, with the drift recorded as
`DRIFT-198-I006-002`.

Post-correction verification on 2026-07-16:

- Focused authority/store/orchestrator suites: PASS, 49/49.
- `pwsh -NoProfile -File tests/f198-iteration006-foundation.ps1`: PASS, 88/88, 31.475 s observed suite duration.
- Bidirectional traceability: PASS, 10/10 tasks and 14/14 scoped requirements, no gaps.
- The legacy lineage-lease race fixture passes five consecutive runs, 75/75 tests, after synchronizing
  the winner lifetime with every contender's first decision.
- `pwsh -NoProfile -File tests/f198-regression-suite.ps1 -PerTestTimeoutSeconds 300`: PASS, all 45 suites, 432.2 s wall time.

The v3 result remains immutable machine-local evidence at
file:///C:/Dev/specrew-beta2-hardening/.specrew/review/campaign-t050-i006/authority-store-v2/campaigns/cmp-i006-t050-claude-v2/runs/run-i006-t050-claude-v3/.
Because its findings are now corrected, it cannot approve the changed tree. Another complete run is
required and consumes a new provider slot only after a separate human grant.

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
