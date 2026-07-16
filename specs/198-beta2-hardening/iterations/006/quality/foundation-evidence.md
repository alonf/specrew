# Iteration 006 Foundation Quality Evidence

**Evidence boundary**: T049 authority-foundation verification
**Implementation commit**: `8f0c939b87d3ddb5bbdfa737d933369c83013b81`
**Reviewed-state digest**: `57b0c02b107e42c66759190b91e8d46705ae9816`
**Recorded at**: 2026-07-16
**Independent review**: complete T050; v6 is a valid current pass with zero findings for digest `bedc0172de77fda277f764cd07b90d5af291e2cc`

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

## T050 v4 timing-contract review and third correction

Separately authorized run `run-i006-t050-claude-v4` reviewed exact digest
`5ffcca9fb50d47abd922e5352baaeca16e0d83f5`. It completed in 638.140 seconds with verified
containment and termination, current applicability, valid strict JSON, and one note finding. The
finding showed that the 86,400,000 ms terminal-duration maximum equaled the former 86,400-second
invocation-timeout maximum, so a truthful max-timeout run plus termination/controller overhead could
not publish a terminal result.

The authorized correction lowers the invocation ceiling to 7,200 seconds and defines the terminal
duration maximum as `(7,200-second invocation timeout + 10-second maximum termination grace +
120-second bounded orchestration overhead) * 1000`, yielding 7,330,000 ms. The orchestrator parameter,
terminal-result validation, and project `co_review_timeout_seconds` reader consume the same pure
timing definition. Tests prove the parameter accepts 7,200 and rejects 7,201 before reservation, the
config reader accepts 7,200 and fails closed at 7,201, maximum timeout plus maximum grace publishes
the exact observed duration unchanged, and 7,330,001 ms fails closed. No duration evidence is clamped.

Post-correction verification on 2026-07-16:

- Focused authority/ingress/orchestrator suites: PASS, 50/50; config-boundary regression: PASS.
- `pwsh -NoProfile -File tests/f198-iteration006-foundation.ps1`: PASS, 91/91, 26.059 s observed suite duration.
- `pwsh -NoProfile -File tests/f198-regression-suite.ps1`: PASS, all 45 suites, 421.1 s wall time.
- PowerShell parser and `git diff --check`: PASS.

The v4 result remains immutable machine-local evidence at
file:///C:/Dev/specrew-beta2-hardening/.specrew/review/campaign-t050-i006/authority-store-v2/campaigns/cmp-i006-t050-claude-v2/runs/run-i006-t050-claude-v4/.
At that stop, the maintainer authorized exactly one Claude v5 invocation against the post-correction
committed digest, with a new run ID and no hidden retry. `DRIFT-198-I006-001` remained open and
closeout could not rely on the stale global ledger. The v2 prose-wrapped-JSON failure was still a
deterministic malformed-output fixture plus production prompt-contract hardening obligation for
Iteration 007; the next section records the later scoped pull-forward that superseded that placement.

## T050 v5 invalid output and scoped file-primary pull-forward

Separately authorized run `run-i006-t050-claude-v5` reviewed exact digest
`8a8702862cd0caed22103b9617057a66d04dd548`. It observed 475.187 seconds with verified containment,
termination, and currentness, but Claude prefixed prose to an embedded pass object. Strict ingress
correctly published `completion=none`, `verdict=incomplete`, `runtime_outcome=invalid-output`,
`validation=invalid`, zero authoritative findings, and `can_approve_current=false`. The embedded pass
is not accepted retroactively and stdout is not salvaged.

The maintainer authorized `DRIFT-198-I006-003` as one narrow pull-forward from Iteration 007. The
Claude adapter now puts the controller-owned candidate path in the invocation prompt, requires the
reviewer to write only a raw JSON object directly to that file, and never parses stdout for
authority. A deterministic pair proves both directions: a prose-wrapped candidate file is rejected
even when stdout is raw valid JSON, while a raw candidate file is accepted when stdout repeats the
real prose-wrapped failure shape. Strict ingress itself remains unchanged.

Post-pull-forward verification on 2026-07-16:

- Focused authority/ingress/orchestrator suites: PASS, 52/52.
- `pwsh -NoProfile -File tests/f198-iteration006-foundation.ps1`: PASS, 93/93, 25.054 s observed suite duration.
- `pwsh -NoProfile -File tests/f198-regression-suite.ps1 -PerTestTimeoutSeconds 300`: PASS, all 45 suites, 393.5 s wall time.
- Packaged-artifact deployment: PASS, 2/2.
- Bidirectional traceability: PASS, 10/10 tasks and 14/14 scoped requirements, with no gaps or invalid references.
- Changed PowerShell syntax, authority-mode JSON, module manifest, loader/FileList coverage, and `git diff --check`: PASS. PSScriptAnalyzer is not installed, so no analyzer result is inferred.

Iteration 007 must subtract this exact Claude delivery slice and pair; its full malformed-output
fixture matrix and remaining adapter hardening are unchanged.

The authoritative v5 result is machine-local at
file:///C:/Dev/specrew-beta2-hardening/.specrew/review/campaign-t050-i006/authority-store-v2/campaigns/cmp-i006-t050-claude-v2/runs/run-i006-t050-claude-v5/.
At that stop, the maintainer granted one Claude v6 provider slot against the post-hardening committed
digest, with a new run ID and no hidden retry. A clean v6 would close T050; findings or invalid output
would stop without a fix or further spend under that grant.

## T050 v6 clean independent review

The single authorized `run-i006-t050-claude-v6` reviewed committed HEAD
`2157017f77a225f9497c44ffb013e101bff6f2a7` at exact reviewed-state digest
`bedc0172de77fda277f764cd07b90d5af291e2cc`. The file-primary adapter supplied the controller-owned
candidate path and did not copy or parse stdout. After 507.609 seconds, the controller published a
complete, valid, current pass with verified containment and termination, zero findings, and
`can_approve_current=true`. Claude independently reran the foundation suite at 93/93 on that exact
tree. No hidden retry occurred.

The authoritative result and controller report are machine-local at
file:///C:/Dev/specrew-beta2-hardening/.specrew/review/campaign-t050-i006/authority-store-v2/campaigns/cmp-i006-t050-claude-v2/runs/run-i006-t050-claude-v6/.
T050 is complete. This clean foundation result does not satisfy SC-019 or the remaining Iteration 007
adapter/runtime/live-smoke/cross-platform obligations.

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
