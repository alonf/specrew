# Drift Log: Iteration 008

**Schema**: v1

<!--
  Markdown authoring note (Specrew lifecycle convention):

  When you add new drift events to this file, watch for MD032 (blanks-around-lists).
  A sentence ending with a colon, immediately followed by a bullet list, is the most
  common violation. Always put a BLANK LINE between the colon line and the list:

      BAD:                              GOOD:
      Resolution steps:                 Resolution steps:
      - Step one                        <— blank line here
      - Step two                        - Step one
                                        - Step two

  The F-033 pre-boundary markdownlint gate runs markdownlint-cli --fix on .md
  changes before every boundary-sync write, so most violations auto-fix — but the
  blank line you write in the first place avoids the cleanup churn.
-->

## Summary

**Total drift events**: 20
**Resolution rate**: 100% (20/20 resolved; correction drifts 004–019 independently closed by T066 run 11)
**Specification drift**: None detected

The review-signoff reconciliation compared the delivered T066 output with its FR-024–FR-032, FR-035,
FR-036, FR-040–FR-042, FR-044–FR-049, FR-055, FR-056, SC-008–SC-015, NFR-002, and NFR-007 scope. Clean
run 11 approved reviewed commit `9a6b88540088be2ff82fec145079b3f8765e863e` / digest
`eb9643d51780361d1009ba3267e7e14cb011b385` with zero findings. The direct-child six-file evidence commit
`3fb3a1fc4640b1e2a468a56d8dbad91a8cc67466` is bound exactly once outside that digest, and its exact CI run
`29785802064` passed all eight jobs. No omitted, unauthorized, or contradictory implementation remains in T066
scope; DRIFT-198-I008-020 normalizes only the post-signoff lifecycle projection. T029 release and T067
published-beta validation remain deliberately pending behind their named boundaries.

## Events

### DRIFT-198-I008-001 — Pending crossing cites stale pre-closeout identity

- **Status**: resolved by T068; deterministic current/stale fixtures green
- **Severity**: major governance identity defect
- **Type**: authority-binding drift, not specification drift
- **Requirements**: FR-041, FR-042, FR-044, FR-045, NFR-007
- **Observed evidence**: the generated pending `iteration-closeout -> plan` narrative cited commit `744e77d8`
  and tree `542c54f0`, while the actual Iteration 007 closeout commit is
  `ec2287c0b950ceb78522f3b5aae8dd94d4710a88`.
- **Tasks-boundary reproduction**: after task commit `29cf84084fd65da9f4199466a9aa4dccc5105958`
  (tree `0457cdd8da4ba24aa5e258224fda8f6ec1dd4ca3`), the canonical `tasks` boundary sync reported
  `success: true` but `pending_verdict_has_pending: false`; its boundary, approval phrase, crossing ID, commit,
  and artifact identity fields were all null even though no `before-implement` verdict exists. No pending packet
  was published. This exact missing-pending result is evidence of the same stale/global binding class, not an
  authorization or a successful gate advance.
- **Human disposition**: the planning verdict explicitly binds only to `ec2287c0`; the stale citation carries
  no authority.
- **Immediate containment**: Iteration 008 planning state and plan record the exact human binding. No later
  boundary may rely on the stale pending record or the false no-pending sync result. The next crossing must use
  a manually rendered packet bound to its exact committed task artifact and Git tree.
- **Selected correction**: T068, 0.75 SP, narrowly rebinds a pending crossing to the actual closeout commit/tree
  with paired current/stale tests. It executes first and must not expand into a matcher redesign.
- **Resolution evidence**: boundary sync now rejects a supplied commit that is not current `HEAD`; a sync of an
  already-authorized completed boundary opens the next exact crossing at that current commit and Git tree. The
  production-path fixture reproduces the tasks null-pending case and the stale pre-closeout-parent case, verifies
  no context mutation on rejection, verifies stable rerendering, and keeps bare-number replies non-authoritative.

### DRIFT-198-I008-002 — injected-context and shared-baseline capture defects carried into T069

- **Status**: resolved by T069 at commit `9ef3b137a4bf6525d823eee3e6c6d8bc6faf8517`
- **Severity**: major authorization and interaction-integrity defect
- **Type**: inherited implementation/integration drift
- **Requirements**: FR-041, FR-042, FR-055, FR-056, NFR-002, NFR-007
- **Source evidence**: DRIFT-198-I007-025 recorded that review-signoff capture selected an injected
  `<environment_context>` user-role turn and rejected the real leading approval followed by binding instructions.
  The Iteration 007 retro separately recorded concurrent sessions sharing one material baseline, allowing one
  session's file changes to trigger another session's material-work packet.
- **Tasks-verdict disposition**: T069 is selected at a hard 2.25 SP ceiling and executes immediately after T068.
  Its acceptance fixtures must reproduce injected context, instruction-bearing approval, shared-baseline
  cross-session attribution, concurrent sessions, the stale-binding class, machinery/teaching text, exact
  boundary identity, and bare-number rejection.
- **Scope guard**: if the full production correction and fixture matrix cannot fit 2.25 SP, stop and replan. Do
  not hide additional work under distribution, supplier, or release tasks.
- **Dogfood rule**: subsequent Iteration 008 lifecycle boundaries exercise the corrected T068/T069 path.
- **Resolution evidence**: the real hook/writer fixture skips an injected `<environment_context>` turn, accepts the
  later exact instruction-bearing approval, persists its complete instruction once, and preserves contiguous
  crossing and bare-number controls. The dispatcher passes only a sanitized genuine host session identity. A
  barrier-synchronized two-session fixture writes distinct baseline files, attributes session B's PostToolUse
  surface to B, keeps session A's routine status conversational, and makes B's own material Stop request exactly
  one packet. The exact stale/current T068 suite, machinery/quoted/teaching fixtures, focused neighbors, and all 60
  registered Feature 198 suites pass; full-registry wall time was 788.5 seconds. Cross-platform CI run
  `29662556573` passed the committed repair on Windows, Ubuntu, and macOS.

### DRIFT-198-I008-003 — material packet counts absolute dirty state as turn-owned work

- **Status**: resolved by full-scope T070
- **Severity**: major interaction-integrity defect
- **Type**: implementation/contract drift
- **Requirements**: FR-055, FR-056, NFR-002, NFR-007
- **Observed evidence**: a read-only reviewer session was told `MATERIAL WORK IN PROGRESS this turn (8 changed
  user files)` for files it never touched. The conformance signal reads the rolling handover's absolute Git dirty
  count, and SessionStart may inherit a stale handover surface rather than snapshot live Git state.
- **Required correction**: owner-scoped `turn-baseline.json` captures live HEAD plus dirty-path status/content
  fingerprints at genuine turn start; PostToolUse/Stop uses only the resulting delta for the trigger and count;
  SessionStart refreshes live state; T069 owner suppression remains.
- **Replan disposition**: the maintainer removed the SP ceiling and repriced the complete repair to 4.0 SP. The
  iteration becomes 22/26 SP with 4 SP headroom.
- **Implementation shape**: a host-independent core owns live Git snapshotting, content fingerprints, owner
  baseline, delta, and packet-demand classification. Thin manifests map Claude/Codex `UserPromptSubmit`, Copilot
  `userPromptSubmitted`, Cursor `beforeSubmitPrompt`, and Antigravity `PreInvocation`. No supported host is
  capability-absent; the generic degraded path says only `CURRENTLY DIRTY IN THE WORKTREE`.
- **Resolution evidence**: deterministic core, real deployment registration, normalized dispatcher delivery,
  provider prompt/degraded message, stale-handover, consecutive-turn, same-path re-edit, and concurrent-session
  fixtures pass. All 73 registered Feature 198 suites pass in 740.4 seconds. Three-OS CI remains T066 candidate
  preparation evidence and does not reopen the corrected contract.

### DRIFT-198-I008-004 — T066 self-plan omitted its production child-environment declaration

- **Status**: resolved by the corrected plan contract and clean T066 run 11
- **Severity**: blocking verification-integrity defect
- **Type**: implementation/evidence drift
- **Requirements**: FR-048, FR-049, SC-015, NFR-002, NFR-007
- **Observed evidence**: T066 attempt 01 executed the selected plan through the real production runner. Its empty
  child environment was correct by contract, but the project plan declared no `env_refs`; the registry failed
  before its first suite because temp paths were unavailable, and governance validated zero iterations because
  Git was not resolvable. The prior deterministic-green wording described only ambient local/CI execution.
- **Required correction**: version the self-plan, declare only the ambient variable names required by its tools,
  prove the declared environment succeeds and the undeclared form fails through the production runner, and run
  the exact full plan successfully before requesting another provider slot.
- **Attempt evidence**: `run-t066-claude-windows-8daac538-e03a4139-01`, commit
  `8daac53888f29c47cab0c23531e9fbf53ec38729`, digest
  `e03a413985002981933eccdbcd7b25c5b6c6df96`, one provider invocation/slot, valid incomplete result with two
  blocking findings and one major finding.
- **Correction shape**: tracked `f198.i008.signoff.v5` plan, identical runtime selected-plan bytes, paired
  production-runner allow/deny fixture, full production execution, fresh exact-commit CI, and a new digest-bound
  preparation artifact. No output salvage, environment-value persistence, or hidden provider retry is allowed.
- **Resolution evidence**: the environment fixture proves declared tool lookup, nested PowerShell launch, and
  Windows common-data resolution while the undeclared form fails. The ANSI-wrapped stale-binding fixture now
  normalizes presentation bytes without weakening commit identity. At code candidate `9dc0c10d`, the production
  runner passed all 73 suites plus scoped governance and preserved digest
  `ee374f3685cebfae153a63fd525d95f18e04dc01` before/after; hosted three-OS run `29693858260` passed every job.

### DRIFT-198-I008-005 — red controller verification spent a provider slot and suppressed actionable diagnostics

- **Status**: resolved by the zero-spend preflight correction and clean T066 run 11
- **Severity**: major cost/integrity defect
- **Type**: implementation/evidence drift
- **Requirements**: FR-048, FR-049, SC-015, NFR-002, NFR-007
- **Observed evidence**: T066 attempt 02 recorded both configured commands red before reviewer launch but continued
  into Claude, spending one provider slot. Its durable evidence retained exit/duration/hash facts while suppressing
  output text, so the paid reviewer could identify the failed command IDs but could not determine their causes.
  The controller result was valid incomplete with two blocking and three major findings. A later no-provider,
  human-authorized bounded diagnostic reproduction under the same constructed environment passed all 73 suites
  and scoped governance, proving the red result was intermittent rather than a deterministic candidate defect.
- **Correction**: a red configured command now makes frozen verification fail before harness preflight, claim, or
  spend. The reservation is released and the stable failure reason names all failed command IDs plus the required
  command-scoped diagnostic-disclosure path. Automatic output disclosure remains forbidden; troubleshooting uses
  the existing bounded, redacted, explicitly human-authorized one-command surface.
- **Paired evidence**: unit and supplier-to-campaign end-to-end fixtures prove a green plan still injects exact
  evidence and spends once, while pass/fail/pass records every attempt but performs zero harness preflight, zero
  invocation, zero spend, and exactly one reservation release. Focused result: 18/18 passed; expanded campaign,
  public-command, strict-ingress, and supplier-to-campaign result: 77/77 passed; scoped governance passed.

### DRIFT-198-I008-006 — machinery-stripped reviewer snapshot was not a complete verification repository

- **Status**: resolved by pinned-support/disposable verification and clean T066 run 11
- **Severity**: blocking verification-integrity defect
- **Type**: architecture/evidence drift
- **Requirements**: FR-048, FR-049, SC-015, NFR-002, NFR-007
- **Observed evidence**: zero-spend T066 attempts 03 and 04 both stopped before provider invocation after the
  campaign-generated snapshot recorded the full registry and governance red. Raising the outer bound from 900 to
  2100 seconds did not move the roughly 907-second failure, disproving the initial timeout diagnosis. A retained
  campaign snapshot with command-scoped bounded disclosure showed five registry failures because tracked
  `.specify/**` distribution mirrors were absent; governance also required pinned `.squad/**` and
  `.specrew/iteration-config.yml`. The external commit worktree was green because it contained those tracked
  support trees, while `New-GitReviewTargetSnapshot` checked out only the machinery-stripped canonical digest.
- **Correction**: controller verification derives the existing authoritative machinery path set from the origin,
  lists only files tracked by `origin_head_before`, stages those exact files in bounded chunks, runs the selected
  plan, and deletes exactly the manifest files in `finally`. It then recomputes the canonical digest before any
  reviewer harness preflight. Dirty origin machinery is never copied, path collisions fail closed, and the
  reviewer-visible tree remains machinery-stripped. A red configured command now returns before creating
  `.review/implementer-evidence.json` because no reviewer can consume it.
- **Paired evidence**: a production Git campaign fixture proves verification sees pinned `.specify`, `.squad`,
  and `.specrew` support while ignoring dirty origin support; the capturing harness proves none is visible at
  preflight. A red-command fixture proves cleanup and unchanged digest before return. The expanded production
  target/campaign/public-command/strict-ingress/supplier matrix passes 86/86 on the final purge/baseline code. The
  immediate pre-purge precursor passed all 73 registered entries in 845.1 seconds; the committed campaign's
  pre-spend execution owns the final full-registry proof.

### DRIFT-198-I008-007 — plan-level time was persisted as every serial command's observed time

- **Status**: resolved by per-command observed clocks and clean T066 run 11
- **Severity**: major evidence-honesty defect
- **Type**: implementation/evidence drift
- **Requirements**: FR-015, FR-048, NFR-002, NFR-007
- **Observed evidence**: T066 attempt 05 passed both controller commands, but its injected records gave the
  900.3-second registry and the later 10.9-second governance command the same `started_at` and `recorded_at`.
  Governance therefore appeared to start before the registry ended, contradicting declared serial order. Run
  `run-t066-claude-windows-fe17e387-5602cb72-05` spent one provider slot and returned valid current incomplete.
- **Correction**: the production recorded-run wrapper accepts no caller clock. It captures start immediately before
  spawn and captures record time only after process, structured-result, and artifact observation. Synthetic failed
  attempts also obtain their own live stamp; the pure assembler retains injected clocks only for deterministic core
  fixtures.
- **Paired evidence**: a two-command production-plan fixture sleeps across clock-second boundaries and proves the
  second start is at or after the first end/record time, while each `recorded_at` is at or after its command end.
  Recorder/plan/campaign/public/target/end-to-end coverage records 157 passed with one platform skip.

### DRIFT-198-I008-008 — empty support manifest produced false reviewer teaching

- **Status**: resolved by conditional support teaching and clean T066 run 11
- **Severity**: minor teaching/evidence defect
- **Type**: implementation/evidence drift
- **Requirements**: FR-048, NFR-002, NFR-007
- **Observed evidence**: attempt 05 found the reviewer scope unconditionally claimed tracked methodology support
  was staged and removed, even when the manifest contained zero files or lacked a commit identity.
- **Correction**: support lifecycle teaching is appended only when a non-empty manifest was actually staged and
  names the manifest's pinned commit, never an inferred or blank snapshot value.
- **Paired evidence**: the existing pinned-support campaign fixture retains the teaching; the ordinary empty-
  manifest campaign explicitly proves it is absent. Both reviewer-visible trees remain machinery-stripped.

### DRIFT-198-I008-009 — staging rollback could hide cleanup failures and skip its purge backstop

- **Status**: resolved by fail-loud two-layer cleanup and clean T066 run 11
- **Severity**: note-level rollback-observability defect
- **Type**: implementation/robustness drift
- **Requirements**: FR-048, NFR-002, NFR-007
- **Observed evidence**: attempt 05 found that a chunked restore failure called exact cleanup but swallowed its
  exception; because the caller never received a manifest, its outer machinery purge was then skipped.
- **Correction**: a staging failure always attempts exact manifest cleanup and then the complete authoritative
  machinery purge inside the staging boundary. The controller reason preserves the restore failure and every
  rollback failure; the run remains pre-provider and fail closed.
- **Paired evidence**: one fixture proves both cleanup layers run when restore fails; a second makes both layers
  fail and proves both diagnostics survive in the returned exception. The expanded suite remains green.

### DRIFT-198-I008-010 — pinned support staging collided with the captured current verification plan

- **Status**: resolved by current-plan precedence and clean T066 run 11
- **Severity**: major target-integrity defect
- **Type**: implementation/evidence drift
- **Requirements**: FR-048, FR-049, NFR-002, NFR-007
- **Observed evidence**: T066 attempt 06 found that a tracked `.specrew/verification-plan.json` could enter the
  pinned support manifest even though the target port had already captured and hash-bound the current plan bytes.
  Support staging would then reject the collision or overwrite the plan the campaign was required to execute.
- **Correction**: `.specrew/verification-plan.json` remains exclusively target-port owned and is excluded from
  support restore/removal. The controller executes the separately captured current plan while staging only other
  pinned support files.
- **Paired evidence**: a production campaign fixture dirties the tracked current plan against the pinned commit,
  proves that the current command executes, and proves exact cleanup plus an unchanged origin target.

### DRIFT-198-I008-011 — support staging recomputed a live machinery vocabulary after target freeze

- **Status**: resolved by frozen machinery-vocabulary binding and clean T066 run 11
- **Severity**: minor determinism/currentness defect
- **Type**: implementation/evidence drift
- **Requirements**: FR-048, NFR-002, NFR-007
- **Observed evidence**: attempt 06 found the support manifest performed a second recursive live-origin scan after
  the canonical digest had already chosen its machinery paths. Marker changes between those observations could
  change support scope, add latency, and contradict the pinned-only contract.
- **Correction**: the canonical digest returns the normalized exact machinery-path vocabulary it used. The target
  snapshot freezes and hash-binds that vocabulary, currentness recomputes and compares its hash, and support
  staging reuses the frozen list while reading eligible tracked file contents only from the pinned commit.
- **Paired evidence**: a direct target fixture changes a machinery marker after freeze, proves verification reuses
  the captured vocabulary without copying dirty origin contents, and proves currentness fails with
  `machinery-paths-changed`. A false-allow pair mutates the in-memory vocabulary and proves support staging refuses
  it when it no longer matches the frozen hash.

### DRIFT-198-I008-012 — failed verification re-baselined source hashes

- **Status**: resolved by success-only rebaseline and clean T066 run 11
- **Severity**: note-level failure-path defect
- **Type**: implementation/evidence drift
- **Requirements**: FR-048, NFR-002, NFR-007
- **Observed evidence**: attempt 06 found source hashes were refreshed in an unconditional exit path. A failed
  verification therefore could replace the original comparison baseline and weaken later mutation detection.
- **Correction**: source hashes are re-baselined only after complete successful verification and cleanup; every
  red or exceptional path retains the original frozen baseline.
- **Paired evidence**: the production red-verification fixture proves failure remains pre-provider and the original
  `source_hashes_before` value is unchanged.

### DRIFT-198-I008-013 — verification returned a vestigial degradation field with no reachable path

- **Status**: resolved by removal of the unreachable contract field and clean T066 run 11
- **Severity**: note-level contract/plumbing defect
- **Type**: implementation drift
- **Requirements**: FR-048, NFR-002
- **Observed evidence**: attempt 06 found `degrade_reason` was always null in verification results while the caller
  still conditionally consumed it, implying a verification-degradation state the implementation could not emit.
- **Correction**: the unused verification field and consumer branch are removed. Design-context degradation remains
  owned by its actual resolver and no verification failure is silently converted into degraded approval evidence.
- **Paired evidence**: focused target/campaign coverage, including a mismatched frozen-vocabulary binding refusal,
  passes 37/37. The preceding expanded eleven-file set records 175 passed with one platform skip without a
  verification degradation branch; the committed campaign owns final exact-candidate full-registry proof.

### DRIFT-198-I008-014 — crash-recovery facts omitted target currentness bindings

- **Status**: resolved by recovery binding round-trip and clean T066 run 11
- **Severity**: minor recovery-observability defect
- **Type**: implementation/evidence drift
- **Requirements**: FR-048, NFR-002, NFR-007
- **Observed evidence**: T066 attempt 07 found `Get-ReviewRecoverySnapshot` rebuilt only the original identity/path
  fields. Strict-mode production currentness now also requires the captured plan presence/hash and machinery
  path-list/hash, so an interrupted invoked run would always fall back to `recovery-currentness-check-failed`.
  Recovered runs remain abandoned and non-approving; approval authority was never granted incorrectly.
- **Correction**: new immutable recovery facts persist and contract-check all four bindings, code-target creation
  fails closed if any binding is missing, and recovery rehydrates them through the real target currentness path.
  Historical facts without the extension remain honestly `unknown` as `recovery-target-binding-unavailable`.
- **Paired evidence**: a real Git target freezes its bindings, round-trips them through
  `New-ReviewRunRecoveryFact`/`Get-ReviewRecoverySnapshot`, validates the fact contract, and classifies current.

### DRIFT-198-I008-015 — later currentness checks overwrote earlier divergence reasons

- **Status**: resolved by additive currentness reasons and clean T066 run 11
- **Severity**: note-level observability defect
- **Type**: implementation/evidence drift
- **Requirements**: FR-048, NFR-002, NFR-007
- **Observed evidence**: attempt 07 found plan drift overwrote head/digest drift and machinery-vocabulary drift then
  overwrote both. The final `snapshot-moved` classification was safe, but its single reason under-reported evidence.
- **Correction**: currentness accumulates ordered reasons while preserving the strongest classification; the legacy
  scalar `reason` becomes their comma-joined projection and an explicit `reasons` array carries the full evidence.
- **Paired evidence**: one production Git target simultaneously changes reviewable content, plan bytes, and the
  machinery vocabulary and proves all three ordered reasons survive.

### DRIFT-198-I008-016 — attempt 07 lost the changed-path cause behind snapshot-integrity failure

- **Status**: resolved by bounded changed-path evidence, T071 containment, and clean T066 run 11
- **Severity**: runtime-integrity/diagnostic defect
- **Type**: implementation/operability drift
- **Requirements**: FR-048, NFR-002, NFR-007
- **Observed evidence**: attempt 07's reviewer process terminated cleanly and produced valid current findings, but
  post-runtime integrity classified the snapshot changed and forced `containment-violated`. The old controller
  disposed the snapshot and published only that generic reason; no durable evidence identifies the changed path,
  so this record does not speculate that a particular file caused it.
- **Correction**: any integrity failure publishes its classification and at most 20 bounded relative changed paths
  in `failure_reason` before disposal. The initial non-persistent/user-only Claude vector was insufficient isolation
  and is superseded by DRIFT-198-I008-018.
- **Paired evidence**: a campaign integrity fixture mutates `.claude/settings.local.json` and proves the terminal
  non-approving result retains that exact relative path. Attempt 08 then proved the real path by retaining
  `.review/implementer-evidence.json` and generated `.scratch/distribution-module-update/**` entries.

### DRIFT-198-I008-017 — immutable canonicalization corrupted recovery string arrays

- **Status**: resolved by scalar-array canonicalization proof and clean T066 run 11
- **Severity**: major recovery-evidence defect
- **Type**: implementation/evidence drift
- **Requirements**: FR-048, NFR-002, NFR-007
- **Observed evidence**: attempt 08's immutable `recovery.json` persisted every `machinery_paths` string as an object
  containing only its `Length`. PowerShell's pipeline adapter made scalar array elements appear as PSCustomObject to
  the canonicalizer, so the new recovery binding was structurally destroyed after pre-write contract validation.
- **Correction**: canonicalization preserves strings and value types before dictionary/object recursion. Historical
  malformed evidence remains immutable; every new fact retains scalar arrays as scalar JSON.
- **Paired evidence**: a direct canonicalization pair covers string and integer arrays, rejects any `Length` wrapper,
  and a real Git-target RecoveryFact is written via CreateNew, contract-read, rehydrated, and classified current.

### DRIFT-198-I008-018 — Claude user settings leaked hooks/instructions into the frozen reviewer

- **Status**: resolved by the isolated Claude launch contract and clean T066 run 11
- **Severity**: major reviewer-isolation defect
- **Type**: integration/runtime-integrity drift
- **Requirements**: FR-048, NFR-002, NFR-007
- **Observed evidence**: attempt 08 passed deterministic preflight and invoked Claude once, but the retained `user`
  setting source admitted ambient behavior. The process exited 1 without a candidate after creating
  `.review/implementer-evidence.json` and `.scratch/distribution-module-update/**`; integrity refused approval.
- **Correction**: the production vector keeps OAuth/keychain authentication but supplies an empty setting-source
  list, disables skills and Chrome integration, uses a strict empty MCP config, and limits built-in tools to
  Read/Glob/Grep plus Write for the external candidate file. The prompt forbids commands and every other write.
- **Paired evidence**: the exact argument vector and prompt restrictions are asserted through the production harness
  builder; local Claude 2.1.215 accepts the vector without provider invocation. Snapshot-integrity failure has now
  recurred in attempts 07/08; one further recurrence triggers the three-round non-convergence stop.

### DRIFT-198-I008-019 — controller preparation mutated the frozen reviewer target before Claude startup

- **Status**: resolved by T071 containment/three-OS proof and clean T066 run 11
- **Severity**: blocking runtime-integrity defect
- **Type**: architecture/containment drift
- **Requirements**: FR-048, SC-015, NFR-002, NFR-007
- **Observed evidence**: attempt 09 invoked Claude once against commit
  `6667a3739ca487d41ef90df34d235783468d599a` and digest
  `2c29cb53005f7cc314d0734539dd6dde6aedbcb2`. The process exited 1 after roughly 1.8 seconds without a candidate;
  the already-completed controller phase had placed `.review/implementer-evidence.json` and regenerated
  `.scratch/distribution-module-update/**` content in the same target later attributed to reviewer tamper. This was
  the third consecutive snapshot-integrity recurrence, so T066 stopped under the non-convergence rule before any
  further slot.
- **Root-cause proof**: a zero-provider control/disposable experiment ran the exact frozen two-command plan for
  1013.039 seconds. The untouched frozen control retained zero changed paths; the disposable verification copy
  produced 2212 controller-owned changes: one implementer-evidence projection, 2210 distribution scratch paths,
  and controller cleanup of the captured plan. A provider-free Claude 2.1.215 launch then showed the shipped
  `--mcp-config {}` vector failed in 0.388 seconds because `mcpServers` was absent. The corrected
  `{"mcpServers":{}}` vector reached a closed-loopback API transport with zero registered hooks and no workspace-
  trust refusal. Neither probe invoked a provider.
- **Correction**: controller verification runs in a second disposable worktree built from the frozen commit/digest
  and captured plan bytes. Its joined implementer evidence is projected with CreateNew to the external controller
  staging path. The original reviewer target is verified byte-identical, then OS-protected read-only before any
  harness/runtime preflight; only the external candidate parent is write-probed. Windows applies/removes a recursive
  current-identity deny so explicit child allow ACEs cannot reopen writes. Privileged Linux uses a read-only self-bind
  because uid 0 bypasses chmod; ordinary POSIX/macOS uses portable chmod arguments and restores owner write mode.
  Claude receives the schema-valid strict empty-MCP document.
- **Paired evidence**: production-path fixtures prove disposable mutation/original invariance, target-local evidence
  absence, external CreateNew refusal on overwrite, Windows/POSIX existing-file and create denial, external write
  success, normal and lost-lease recovery, inside-target candidate refusal, and protection-before-host-preflight.
  The durable zero-spend proof is `quality/t071-controller-containment-proof.json`. The non-convergence guard may
  reset only after the full deterministic registry and exact-commit CI pass on the corrected candidate. The final
  local registry passed all 73 suites in 763.2 seconds and scoped governance passed in 11.6 seconds with historical
  warnings only. Hosted run `29771340851` at `11b10dd1592d81fa098fbc8782eb6a2cc59ed82f` then exposed the three
  platform subcases before spend; the corrected Windows deterministic sequence and privileged-Linux production path
  pass under Pester 5.7.1. The corrected full registry passes 73/73 in 783.5 seconds and scoped governance passes in
  11.2 seconds with historical warnings only. Hosted retry run `29775507402` passed all eight jobs at exact commit
  `b3fb1ab3037342ec7677cad694a0f7567789b7c2`; the original push run `29773556546` was cancelled after an unrelated
  macOS runner wedge and carries no authority. T071 completed with zero provider spend and reset the T066 guard.

### DRIFT-198-I008-020 — finalized T066 review grouping did not satisfy iteration-level review schema

- **Status**: resolved in the authorized post-signoff lifecycle projection
- **Severity**: minor governance-artifact defect
- **Type**: lifecycle/schema drift, not implementation drift
- **Requirements**: NFR-002
- **Observed evidence**: after the human approved review signoff and `plan.md` truthfully entered `reviewing`, the
  scoped governance validator reached `review.md` and failed under strict mode because the finalized T066-oriented
  table used header `Task group` and grouped completed tasks. The iteration validator requires header `Task` and one
  verdict row for every plan task. The earlier `executing` status had prevented that schema path from running.
- **Correction**: preserve approved commit `3fb3a1fc4640b1e2a468a56d8dbad91a8cc67466` and its one external
  finalization fact unchanged. In the later review-signoff boundary projection only, expand all 19 task rows,
  retain pass/done for completed T066 scope, mark T029/T067 blocked in plan/progress/review behind their real
  release/publication dependencies, and set the iteration-level overall verdict to blocked rather than falsely
  treating unexecuted work as passed.
- **Evidence**: the scoped Iteration 008 governance validator passes after the projection; no authority code,
  reviewed implementation identity, provider result, attempt ledger, or finalization fact changes.

### Resolution Strategies

The following resolution strategies remain available if drift is detected later in execution:

- **spec-updated**: Update the spec to reflect implementation choice
- **implementation-reverted**: Revert implementation to match spec
- **deferred**: Mark drift as deferred to next iteration
- **human-decision**: Escalate to Alon for resolution

### Notes

- The defect is visible even though execution has not started because it affected the authority offered to the
  planning boundary.
- The official scaffold's decorated-requirement parser limitation is recorded in plan.md as a planning-tool
  limitation; it did not create authority or implementation drift.
