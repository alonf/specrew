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

**Total drift events**: 43
**Resolution rate**: 86.0% (37/43 resolved; DRIFT-198-I008-038/039/041/042 await fresh independent review, DRIFT-198-I008-040 awaits fresh-review and completed-workshop retest proof, and DRIFT-198-I008-043 awaits exact-head and fresh-review proof)
**Specification drift**: None detected

The review-signoff reconciliation compared the delivered T066 output with its FR-024–FR-032, FR-035,
FR-036, FR-040–FR-042, FR-044–FR-049, FR-055, FR-056, SC-008–SC-015, NFR-002, and NFR-007 scope. Clean
run 11 approved reviewed commit `9a6b88540088be2ff82fec145079b3f8765e863e` / digest
`eb9643d51780361d1009ba3267e7e14cb011b385` with zero findings. The direct-child six-file evidence commit
`3fb3a1fc4640b1e2a468a56d8dbad91a8cc67466` is bound exactly once outside that digest, and its exact CI run
`29785802064` passed all eight jobs. No omitted, unauthorized, or contradictory implementation remains in T066
  scope; DRIFT-198-I008-020 normalizes only the post-signoff lifecycle projection. The T029 manual-test correction
  added DRIFT-198-I008-021–037: 021–031 are corrected and exact-head independently verified. The later Copilot
  workshop exposed 032; review run 08 verified its core correction and found the bounded 033–036 follow-ons. Their
  first exact-head PR exposed the macOS capability-probe race recorded as 037. Commit `bb780bf1` then passed every
  exact-head workflow, and current/valid run 10 independently verified 032–037 before finding the bounded 038/039
  residual directions. Commit `d5046896` and exact-head CI `29922949655` corrected 038/039, and the fresh Article
  Amplifier test proved feature-level intake reaches its first lens, closing 032. That same test exposed 040: the
  model-authored workshop marker is not a stable cross-host authority surface. The strict artifact-derived
  replacement is focused-green but still needs full/hosted/fresh-review proof and a from-scratch test through final
  lens completion. T029 release and T067 published-beta validation remain deliberately pending behind their named
  boundaries.

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

### DRIFT-198-I008-021 — Squad 0.11.0 hidden TTY prompts blocked real-console init

- **Status**: resolved by the immediate-EOF correction and exact-head proof; maintainer manual retest remains a T029 release gate
- **Severity**: release-blocking integration defect
- **Type**: implementation/toolchain-validation drift
- **Requirements**: FR-039, SC-012; T029 release acceptance
- **Observed evidence**: the maintainer ran `specrew init --Force` from a real PowerShell 7.6.3 console against
  candidate `b5f17296afa7336d6302dc76b02c67d7d12d41df`. Init reached **Running squad init** and waited indefinitely.
  Squad CLI 0.11.0 received `--non-interactive`, but its memory-strategy and Copilot-member prompts branch on
  `process.stdin.isTTY`. Specrew's output-capturing probe and its production call both inherited live console stdin,
  hiding the prompt text while leaving the child able to wait for user input. Non-TTY CI and Docker runs took
  Squad's default branch and therefore did not expose the defect.
- **Correction**: resolve the external command cross-platform (including Windows npm `.ps1` shims), launch it with
  redirected stdin, and close that stream immediately. Both the scratch capability probe and production Squad init
  use the same primitive. Other init subprocesses were audited: they are bounded query/version calls or have their
  own explicit force/preflight contracts; no second wizard-style invocation was found.
- **Paired evidence**: `tests/integration/squad-init-closed-stdin.tests.ps1` keeps the parent process's redirected
  input deliberately open. A fake Squad waits for EOF, so either old call path deterministically times out; the
  corrected probe and production invocation both finish, retain `init --non-interactive`, observe redirected
  zero-length stdin, and create `.squad`. The suite is registered in the bounded Feature 198 gate. Fresh full-gate,
  three-OS CI, independent-review, and human live-console evidence will be appended before merge.

### DRIFT-198-I008-022 — distribution integration test treated Squad-owned workflows as Specrew allowlist drift

- **Status**: resolved and verified by narrowing the assertion to Specrew-managed workflows
- **Severity**: minor test-contract defect
- **Type**: test drift
- **Requirements**: FR-026; T023 acceptance
- **Observed evidence**: the post-correction distribution bootstrap completed real Squad 0.11.0 init, then the
  legacy integration test rejected `squad-heartbeat.yml`, `squad-issue-assign.yml`, `squad-triage.yml`, and
  `sync-squad-labels.yml` merely because the final project contained more than the two Specrew-managed workflow
  templates. The dedicated T023 fixture already proves the source tree, module manifest, and real bundled-template
  deployment contain exactly `specrew-methodology-gate.yml` and `specrew-work-kind.yml`. Squad creates its own
  separately named workflows during the later dependency-owned init step.
- **Correction**: retain the exact allowlist assertion over `specrew-*` workflows in the combined distribution
  bootstrap while allowing Squad-owned names to remain Squad's responsibility. The dedicated source/manifest/
  deployment allowlist test remains unchanged and still fails on any extra Specrew-managed consumer workflow.
- **Evidence**: `tests/integration/distribution-module-init.ps1` now distinguishes the two ownership surfaces;
  the corrected real packaged-module bootstrap and the dedicated T023 allowlist fixture must both pass.

### DRIFT-198-I008-023 — version-check cache dirtied a fresh bootstrap after its baseline commit

- **Status**: resolved and verified by the canonical per-session ignore contract
- **Severity**: major fresh-consumer defect
- **Type**: implementation/file-classification drift
- **Requirements**: FR-029, SC-008; T026 acceptance
- **Observed evidence**: after the real packaged-module bootstrap created and announced
  `chore(specrew): bootstrap scaffold`, `git status --porcelain=v1 --untracked-files=all` reported the newly written
  `.specrew/version-check-cache.json`. The self-host repository ignored that cache, but the canonical downstream
  per-session patterns omitted it, so fresh projects received no equivalent rule and did not remain clean.
- **Correction**: classify `.specrew/version-check-cache.json` as per-session cache state. Fresh init writes the
  ignore rule before version checks can leave the file behind; a later init also removes any mistakenly tracked
  copy from the index without deleting the local cache.
- **Paired evidence**: the production file-classification fixture begins with both the Claude local config and
  version cache force-tracked, proves both are untracked but preserved, proves Git ignores each, and proves the
  second update is idempotent. The real packaged-module bootstrap must finish with a clean committed baseline.

### DRIFT-198-I008-024 — T025 template fixture leaked an unrelated PSGallery network check

- **Status**: resolved and verified by isolated plus hosted aggregate execution
- **Severity**: minor deterministic-gate defect
- **Type**: test-harness drift
- **Requirements**: FR-028, SC-009; T025 acceptance
- **Observed evidence**: the 74-suite Feature 198 registry passed 73 suites and timed out only
  `tests/integration/distribution-module-update.ps1` at its exact 300-second child ceiling. The fixture invokes the
  real `specrew update --specrew` template-healing path but omitted the existing `--skip-update-check` switch, so
  it also reached the unrelated PSGallery availability query. The gate produced no assertion failure before the
  timeout; all other 73 suites, including the new live-console init case, passed.
- **Correction**: keep the production update path and every template/hash/advisory assertion, but pass
  `--skip-update-check` in this deterministic template fixture. PSGallery/version-query behavior remains covered by
  its dedicated integration suite and production is unchanged.
- **Evidence**: one isolated corrected T025 run must finish under its 300-second registry budget; the committed
  candidate then requires the normal hosted aggregate gate rather than treating the earlier 73/74 run as green.

### DRIFT-198-I008-025 — closed-input launcher still allowed an unbounded child wait

- **Status**: resolved by commit `249992b7b6bf7b96da6ade1b4a9f4d648d9c1f9e` and exact-head required CI; follow-on DRIFT-198-I008-027 remains open
- **Severity**: note-level robustness defect
- **Type**: incomplete anti-hang implementation
- **Requirements**: FR-039, SC-012; T029 release acceptance
- **Observed evidence**: exact-digest Claude run `run-t029-claude-windows-acc39fea-da3428b3-01` verified the
  immediate-EOF correction and all configured tests but found that `Invoke-NativeCommandWithClosedInput` still
  called parameterless `WaitForExit()`. Squad 0.11.0 exits correctly on non-TTY EOF, but any future child that
  ignored EOF could recreate the indefinite-wait class. The result was complete, valid, contained, current, and
  non-approving with one note finding and no blocking or major defects.
- **Authoritative requirement**: FR-039 requires the Squad 0.11.0 scratch probe and layout suites; SC-012 requires
  `specrew init` to complete against the pinned toolchain. A timeout cannot satisfy either obligation and is failure,
  not compatibility evidence.
- **Correction**: require an explicit timeout at both call sites; on expiry request whole-tree termination, verify
  exit, bound diagnostic draining, and throw `System.TimeoutException`. The 30-second capability probe rethrows the
  timeout instead of selecting fallback; the production init call uses 120 seconds and aborts loudly.
- **Paired evidence**: the existing fake completes normally after immediate EOF. A second mode ignores EOF, spawns
  a descendant, and must hit a one-second bound, throw the stable typed failure, and leave the descendant dead.
  The registered fixture proves both directions; the local 74/74 registry and exact-head pull-request runs
  `29848194319`, `29848194342`, and `29848194521` passed. Fresh run 02 verified this correction but exposed the
  distinct success-drain gap recorded as DRIFT-198-I008-027.

### DRIFT-198-I008-026 — informational progress renderer output stranded an invoked run

- **Status**: resolved by commit `9b32d8e79ae511b2ac1cf5c97cffac2eb9ae8732`, exact-head CI, and run 03
- **Severity**: major authority-lifecycle defect
- **Type**: implementation/progress-isolation drift
- **Requirements**: FR-061, FR-063, SC-020, SC-021; T029 correction review
- **Observed evidence**: authorized Claude run `run-t029-claude-windows-249992b7-e897e2dd-02` spent exactly one
  slot, wrote a raw candidate, and exited under verified Windows Job Object containment. The external progress
  renderer returned display text to PowerShell's success pipeline. Both the collector and lower-level progress
  writer forwarded that return value, so the runtime adapter result became an array and terminalization failed on
  missing property `process_tree_live`. Restart reconciliation subsequently published one current, valid,
  partial/incomplete spent-abandoned result without invoking a provider again.
- **Authoritative requirement**: FR-061 requires every invoked run, including post-invocation controller failures,
  to publish exactly one terminal authority result. FR-063 makes progress informational; it cannot change authority
  or runtime result shape.
- **Correction**: discard sink return values at both the orchestration writer and external-renderer collector.
  Renderer exceptions and argument mutation remain contained exactly as before.
- **Paired evidence**: the projection unit fixture returns a sentinel and proves zero pipeline output. The real
  orchestration composition fixture uses an output-producing renderer, receives exactly one scalar terminal run
  result, and retains its approving fixture verdict. Exact-head runs `29856856265`, `29856856269`, and
  `29856856271` passed; current, valid, complete Claude run
  `run-t029-claude-windows-9b32d8e7-f270afb3-03` verified the correction and found no current leak.

### DRIFT-198-I008-027 — successful child exit could still hang during output drain

- **Status**: resolved by commit `9b32d8e79ae511b2ac1cf5c97cffac2eb9ae8732`, exact-head CI, and run 03
- **Severity**: note-level robustness defect
- **Type**: incomplete anti-hang implementation
- **Requirements**: FR-039, SC-012; T029 release acceptance
- **Observed evidence**: provider-free reconciliation of run 02 preserved Claude's valid finding that the normal
  path called `GetResult()` on stdout/stderr tasks without a bound after the root process exited. A descendant
  retaining an inherited pipe could therefore recreate a secondary indefinite wait even though the command met
  its invocation timeout.
- **Authoritative requirement**: SC-012 requires real pinned-toolchain init to complete. A process exit followed by
  an unbounded output wait is failure, not successful completion, and cannot satisfy that gate.
- **Correction**: the normal path now uses the same named 10-second output-drain bound as timeout diagnostics.
  Incomplete drain throws `System.TimeoutException` with stable file, drain-bound, verified-root-exit, and
  incomplete-diagnostics fields; it never returns a successful command result.
- **Paired evidence**: the existing fake Squad still completes normally and returns its output. A new mode exits
  zero after spawning a descendant that retains the redirected handles; the launcher must fail with the typed
  bounded drain contract rather than hang or return success, and the fixture cleans up and proves its descendant
  dead. Exact-head runs `29856856265`, `29856856269`, and `29856856271` passed; current, valid, complete Claude
  run `run-t029-claude-windows-9b32d8e7-f270afb3-03` verified the symmetric 10-second drain contract.

### DRIFT-198-I008-028 — runtime progress adapter relied on upstream output suppression

- **Status**: resolved by commit `ac919fae2a227edb2f4baabcc464c55c9369d88d`, exact-head CI, and run 04
- **Severity**: note-level latent authority robustness defect
- **Type**: incomplete defense-in-depth implementation
- **Requirements**: FR-061, FR-063, SC-020, SC-021; T029 release acceptance
- **Observed evidence**: current, valid, complete Claude run
  `run-t029-claude-windows-9b32d8e7-f270afb3-03` verified both prior corrections but found a third progress-sink
  invocation boundary in `Write-ReviewRuntimeProgressSample`. Its bare invocation could forward caller output into
  the runtime adapter pipeline. Production had no current leak because the orchestrator sink returned nothing,
  but correctness depended on an invariant two layers away.
- **Authoritative requirement**: FR-063 makes progress informational and non-authoritative; FR-061 requires one
  truthful terminal result. Each adapter boundary must therefore contain advisory sink output locally rather than
  relying on a particular caller implementation.
- **Correction**: discard the progress callback's pipeline output inside `Write-ReviewRuntimeProgressSample`,
  matching the orchestration and external-renderer boundaries.
- **Paired evidence**: a pure runtime-sampler fixture makes the callback return a sentinel and proves no pipeline
  output. The real Windows Job Object timeout fixture uses the same output-producing callback and still returns
  exactly one scalar runtime result while preserving its heartbeat and verified process-tree termination evidence.
  Exact-head runs `29862411243`, `29862411018`, and `29862411082` passed; current, valid, complete Claude run
  `run-t029-claude-windows-ac919fae-ade3639a-04` verified all three production boundaries.

### DRIFT-198-I008-029 — fixture runtime did not model production progress containment

- **Status**: resolved by commit `73f1487a8c24b607499075042e9e67b5ecabb22c`, exact-head CI, and clean run 05
- **Severity**: note-level test-fidelity defect
- **Type**: incomplete regression-model implementation
- **Requirements**: FR-061, FR-063, SC-020, SC-021; T029 release acceptance
- **Observed evidence**: current, valid, complete Claude run
  `run-t029-claude-windows-ac919fae-ade3639a-04` found that `New-ReviewFixtureRuntimePort` still called its
  progress callback without discarding output. Production was fully contained, but the test double depended on
  the upstream callback returning nothing and could not independently detect the old runtime-result array defect.
- **Authoritative requirement**: FR-063 makes progress advisory and FR-061 requires one scalar terminal authority
  result. A fixture used by orchestration tests must model that production boundary rather than encode a weaker
  contract.
- **Correction**: discard fixture progress-callback output locally, matching the production runtime sampler.
- **Paired evidence**: the direct fixture-port regression supplies an output-producing progress callback and
  asserts that the port returns exactly one scalar completed runtime result. The existing full orchestration
  renderer regression remains green and continues to prove the composed terminal result is scalar.

### DRIFT-198-I008-030 — greenfield Copilot intake rendered a false campaign-authority failure after every turn

- **Status**: resolved by commit `4e34209ea7b77706883238e46ed049242bf80da5`, exact-head CI, and clean run 07
- **Severity**: release-blocking workflow defect
- **Type**: applicability/authority-routing drift
- **Requirements**: FR-055, FR-056, NFR-002; T029 manual-test acceptance
- **Observed evidence**: the first Copilot CLI workshop in a newly initialized project had no active feature or
  iteration, which is the legitimate greenfield intake state. Every answer nevertheless rendered
  `review-campaign-active-feature-unresolved` as a campaign block. The campaign-authoritative worktree navigator
  called the signoff packet gate on every Stop without first distinguishing an inapplicable pre-feature or
  pre-iteration workspace from malformed active state. No provider review was launched or spent.
- **Correction**: the always-on navigator now returns explicit silent no-op reasons for valid pre-feature and
  pre-iteration intake. Once any active lifecycle signal exists, malformed or missing identity still routes
  through the authoritative packet gate and fails closed; the signoff gate itself is unchanged.
- **Paired evidence**: deterministic fixtures cover silent valid pre-feature and pre-iteration workspaces plus a
  malformed active feature marker and an advanced lifecycle cursor whose iteration disappeared; both invalid
  directions still emit the named campaign block. A read-only production-source replay against
  `C:/Dev/article-amplifier` returns `campaign-not-applicable:no-active-feature`, injects no text, and leaves its
  Git status unchanged. Exact-head Specrew CI `29875238272`, Test `29875238264`, Cross-Platform PR
  `29875238262`, and Cross-Platform push `29875236067` passed. Claude run
  `run-t029-claude-windows-4e34209e-739b76f6-07` published complete/pass/current/valid evidence with zero findings.

### DRIFT-198-I008-031 — fresh init omitted generated runtime and handover directories from downstream ignore rules

- **Status**: resolved by commit `4e34209ea7b77706883238e46ed049242bf80da5`, exact-head CI, and clean run 07
- **Severity**: release-blocking consumer-hygiene defect
- **Type**: distribution/file-classification drift
- **Requirements**: FR-027, SC-008, NFR-002; T029 manual-test acceptance
- **Observed evidence**: after one real Copilot session, the otherwise clean `C:/Dev/article-amplifier` consumer
  reported `.specrew/runtime/` and `.specrew/handover/` as untracked. Specrew's own repository ignored both, but
  the canonical per-session list used by `specrew init` omitted them, so downstream `.gitignore` generation could
  not preserve a clean application worktree.
- **Correction**: both directories are canonical per-session patterns written before runtime deployment. Existing
  tracked copies are removed only from the index; local evidence remains on disk.
- **Paired evidence**: the production helper and fresh-init ordering fixture prove both patterns are emitted,
  ignored by Git, untracked when previously indexed, retained locally, and idempotent. The broader F-051
  classification fixture proves the same index-versus-working-copy behavior for representative files in both
  directories. The from-scratch Article Amplifier retest completed init without a hang; `git check-ignore -v`
  bound both generated directories to the new canonical rules. The exact-head CI and clean run 07 evidence named
  in DRIFT-030 independently cover the same reviewed tree.

### DRIFT-198-I008-032 — feature-level intake workshop was forced into the generic material-work packet

- **Status**: resolved by commit `d5046896`, exact-head CI `29922949655`, and the fresh Article Amplifier retest reaching the first architecture lens
- **Severity**: release-blocking workshop UX defect
- **Type**: scope-model mismatch
- **Requirements**: FR-055, FR-056, SC-016, NFR-002; T029 manual-test acceptance
- **Observed evidence**: after DRIFT-030/031 were fixed and independently reviewed, a from-scratch Copilot workshop
  created `specs/001-medium-auto-promote/lens-applicability.json`, rendered the `architecture-core` lens and its
  pacing question, then received the generic five-heading material-work Stop directive. The conformance journal
  recorded `block_kind=material`, `stop_intent=real`, and null workshop identity. The product intake correctly had
  no iteration yet. The provider required a numeric active iteration and only read
  `specs/<feature>/iterations/<NNN>/lens-applicability.json`; the workshop skill likewise required an iteration
  marker the host could not truthfully emit. FR-056 existed, but its only executable scope was the later
  design-analysis workshop rather than the feature-level intake workshop that users encounter first.
- **Correction**: workshop markers now declare either `scope=feature` for specify/intake or `iteration=<NNN>` for
  design analysis. The provider validates the declared scope against the corresponding durable applicability
  artifact and current lens. A feature marker is rejected after iteration activation; an iteration marker is
  rejected when active iteration truth is absent. The skill explicitly forbids inventing an iteration during
  feature-level intake, and all host copies remain byte-identical.
- **Paired evidence**: the exact Article Amplifier shape—feature agenda, no iteration, current architecture lens,
  visible question, and feature marker—stops without a generic packet and writes bounded handover context with
  `scope=feature` and no iteration number. Reverse-direction fixtures prove both cross-scope markers fail closed;
  existing iteration, fabricated-prose, stale-iteration, ordinary-material, and lifecycle-boundary cases remain
  green. The complete focused conformance and multi-host skill suites pass. DRIFT-198-I008-040 supersedes the
  marker-as-authority mechanism after the real host omitted it, without reopening the feature-scope correction.

### DRIFT-198-I008-033 — drift summary did not reflect the current event set

- **Status**: resolved by exact-head commit `bb780bf1` and current/valid review run 10
- **Severity**: minor governance-artifact defect
- **Type**: stale summary projection
- **Requirements**: NFR-002; T029 release acceptance
- **Observed evidence**: current/valid review run 08 found that this summary still reported 31 events, described
  DRIFT-030/031 as open, and omitted DRIFT-032 even though the event body recorded 32 events and resolved 030/031.
- **Correction**: the summary now counts the complete event set and names only the genuinely open proof/retest
  obligations. This event and the other run-08 findings are included rather than hidden from the new total.

### DRIFT-198-I008-034 — all-host workshop skill parity was outside every automated aggregate

- **Status**: resolved by exact-head commit `bb780bf1` and current/valid review run 10
- **Severity**: minor regression-gate defect
- **Type**: verification-plan coverage drift
- **Requirements**: FR-056, SC-016, NFR-002; T029 release acceptance
- **Observed evidence**: run 08 confirmed the copies were byte-identical but found that
  `code-rules-skill-multihost.tests.ps1`, the only test enforcing that property, was absent from the Feature 198
  registry and every explicit hosted workflow list.
- **Correction**: the parity suite is now a named Feature 198 registry row. The controller verification plan and
  every hosted aggregate that runs the registry therefore exercise the canonical-template/four-host equality.
- **Paired evidence**: the direct parity suite passes and the registry contains the exact named path.

### DRIFT-198-I008-035 — unreadable start context could falsely prove feature-level intake

- **Status**: resolved by exact-head commit `bb780bf1` and current/valid review run 10
- **Severity**: minor workshop false-allow
- **Type**: fail-open lifecycle-state handling
- **Requirements**: FR-055, FR-056, SC-016, NFR-002; T029 release acceptance
- **Observed evidence**: run 08 found the existing `$startContextReadable` variable was written but never used.
  When `.specrew/start-context.json` existed but could not be parsed, iteration and boundary truth fell back to
  null/false and a valid feature marker could suppress the material packet even though pre-iteration state was
  unproven.
- **Correction**: the provider carries an explicit `absent|readable|unreadable` state. Missing context remains the
  valid greenfield intake shape; an existing unreadable context fails closed before feature-scope suppression.
- **Paired evidence**: case 16e retains the context-absent allow direction; new case 16i corrupts the existing
  context and requires the ordinary five-part packet. The complete conformance matrix passes.

### DRIFT-198-I008-036 — runtime start callbacks relied on distant output-suppression invariants

- **Status**: resolved by exact-head commit `bb780bf1` and current/valid review run 10
- **Severity**: note-level latent authority robustness defect
- **Type**: incomplete callback-boundary containment
- **Requirements**: FR-061, FR-063, SC-020, SC-021; T029 release acceptance
- **Observed evidence**: run 08 found bare `onStarted` callback invocations in the Windows port, shared POSIX port,
  and fixture port. Production currently returned no callback output, but a future output value could join the
  adapter pipeline and turn the scalar runtime result into an array, repeating the DRIFT-028/029 class.
- **Correction**: all three ports discard `onStarted` output locally while retaining exception handling and spend
  publication semantics.
- **Paired evidence**: Windows, current-OS POSIX, and fixture regressions make `onStarted` return a sentinel and
  assert exactly one scalar runtime result. Focused runtime/orchestrator suites pass 31 tests with four expected
  non-Windows skips.

### DRIFT-198-I008-037 — macOS membership capability probe made one transient observation

- **Status**: resolved by exact-head commit `bb780bf1` and current/valid review run 10
- **Severity**: release-gate flake
- **Type**: insufficiently stabilized native capability observation
- **Requirements**: FR-061, SC-020, SC-021, NFR-002; T029 release acceptance
- **Observed evidence**: exact-head commit `2b918ae69125ca4a537d19aa1604d5d167b0b874` passed Test
  `29912180092`, Specrew CI `29912180102`, and Cross-Platform push `29912176060`. Cross-Platform PR
  `29912180099` failed only its macOS deterministic runtime job: the process host wrote its post-`setsid` ready
  receipt, then the capability probe's single `ps` membership read returned false. The identical-head push macOS
  job passed the same suite minutes earlier, isolating a transient observation rather than a callback regression.
- **Correction**: membership verification now polls the same exact PID/PGID/ready-receipt invariant for at most
  one second at 25 ms intervals. It never changes the expected identity and still fails closed when the invariant
  does not stabilize. The production availability probe and real runtime verification use the same helper.
- **Paired evidence**: an injected sequence `false,false,true` succeeds on the third read; a permanently false
  probe performs multiple reads and returns false within a 25 ms bound. The complete Feature 198 registry passes
  all 75 suites in 998.1 seconds after the correction.

### DRIFT-198-I008-038 — absent start context did not consult durable on-disk iteration truth

- **Status**: corrected locally; focused and full 75-suite verification pass; hosted verification and fresh independent review pending
- **Severity**: note-level workshop false-allow
- **Type**: incomplete lifecycle-state corroboration
- **Requirements**: FR-055, FR-056, SC-016, NFR-002; T029 manual-test acceptance
- **Observed evidence**: current/valid review run 10 verified DRIFT-032–037, then found that an entirely absent
  `.specrew/start-context.json` remained eligible for feature-scope suppression even when
  `specs/<feature>/iterations/<NNN>/` proved the feature had already entered an iteration. This can occur when a
  host is launched outside `specrew start`; the feature-level agenda and first-remaining lens still had to match.
- **Correction**: feature-scope validation now rejects any durable numeric iteration directory before reading the
  feature agenda. Context-absent greenfield intake remains valid only when no such iteration exists.
- **Paired evidence**: case 16e retains genuine pre-iteration intake; new case 16j removes start context, creates
  numeric iteration truth, and requires the ordinary five-part material packet. The complete Feature 198
  registry passes all 75 suites in 1,088.1 seconds.

### DRIFT-198-I008-039 — static macOS identity mismatch consumed the transient observation budget

- **Status**: corrected locally; focused and full 75-suite verification pass; hosted verification and fresh independent review pending
- **Severity**: note-level bounded-runtime robustness defect
- **Type**: avoidable wait on immutable mismatch
- **Requirements**: FR-061, SC-020, SC-021, NFR-002; T029 release acceptance
- **Observed evidence**: run 10 found that the bounded helper repeated immutable descriptor-PGID and ready-receipt
  identity checks inside the live `ps` polling loop. A mismatch was safe and bounded but could never stabilize, so
  it unnecessarily consumed the full one-second observation allowance.
- **Correction**: immutable descriptor/receipt identity is checked once before the loop; only live process-group
  observation is polled. Valid identity retains the transient-success and permanent-live-failure behavior.
- **Paired evidence**: a mismatched descriptor fails without invoking an injected always-true live probe, while
  the existing `false,false,true` and permanently-false live observation fixtures remain green.

### DRIFT-198-I008-040 — model-authored workshop marker was absent in a real Copilot lens turn

- **Status**: corrected; all 76 registered suites and exact-head hosted CI pass; fresh independent review and
  from-scratch completion retest pending
- **Severity**: release-blocking workshop UX and lifecycle-completion defect
- **Type**: unstable cross-host control signal and incomplete durable completion proof
- **Requirements**: FR-055, FR-056, SC-016, NFR-002; T029 manual-test acceptance
- **Observed evidence**: the fresh Article Amplifier project initialized from commit `d5046896`, created a valid
  feature-level eight-lens agenda, persisted product-domain records, opened `architecture-core`, rendered its
  decision content and pacing question, then received the generic five-section packet. The last assistant text and
  conformance journal contained no `SPECREW-WORKSHOP-QUESTION` marker (`dx_lat_hits=0`, null workshop scope). Candidate
  and deployed provider/skill hashes matched, ruling out stale bits. Copilot used ordinary assistant prose in this
  turn, so there was no native question-tool payload to trust either.
- **Correction**: one pure strict accessor derives `absent|invalid|active|complete` from the exact current feature or
  iteration artifact. Actual root booleans, a nonempty unique selected agenda, no unselected records, an ordered
  completed prefix, full agenda/decision/depth/moved-on/confirmation fields, matching confirmation scope, and a
  nonempty bounded Markdown record are required. Active state suppresses only the generic non-boundary packet;
  lifecycle boundaries retain precedence. Complete or invalid state restores ordinary Stop behavior. The host skill
  writes each Markdown record before its full structured completion entry, so the final structured write is the
  deterministic active-to-complete transition. Model comments, environment variables, and question-tool transcript
  shapes are explicitly non-authoritative; the bounded handover file is projection only. A pre-review instruction
  audit found an older checkpoint paragraph that still listed the structured entry before the Markdown record; all
  host and template copies now state the same Markdown-first order and distinguish feature from iteration paths.
- **Paired evidence**: the exact unmarked Copilot-style feature and iteration turns remain conversational; marker/no-
  marker and question/no-question prose do not change classification; stale iteration and on-disk lifecycle truth
  retain scope denial; boundary state wins; loose moved-on, missing record, duplicate agenda, out-of-order completion,
  and malformed JSON all require ordinary Stop behavior; full valid completion restores both material and lifecycle
  packet enforcement. The strict metadata suite, complete real-provider matrix (including 16k–16o denial fixtures),
  and byte-identical all-host skill parity suite pass. The parity suite also rejects any reintroduction of the
  contradictory checkpoint order; the complete 76-suite Feature 198 registry passes in 1,083.1
  seconds. The primary-worktree governance command reached only the unrelated dirty `state.md` value `implement`;
  the clean detached candidate then passed scoped Iteration 008 governance in 18.4 seconds with only the repository's
  known dashboard/handoff warnings.

### DRIFT-198-I008-041 — the frozen full-registry command had no controller-overhead margin

- **Status**: corrected; command-scoped diagnostic and exact-head CI proof captured; fresh independent review
  pending
- **Severity**: release-review blocker
- **Type**: verification-budget configuration drift
- **Requirements**: FR-048, FR-049, SC-015, NFR-002; T029 release acceptance
- **Observed evidence**: run `run-t029-claude-windows-4400076f-70c86564-11` invoked no provider and released its
  reservation after `f198-full-registry` returned a suppressed failure. A human-authorized, command-scoped,
  8 KiB-capped diagnostic replay in a disposable exact-commit worktree proved that no suite had failed: the
  registry printed 75 passing suites and was killed at exactly 1,200.149 seconds before its final suite/summary.
  The same 76-suite registry had completed cleanly in 1,113.6 seconds locally and in exact-head Specrew CI, so
  the configured 1,200-second command ceiling left insufficient margin for the recorded-run process and isolated
  environment overhead.
- **Correction**: raise only the declared `f198-full-registry` verification-plan timeout from 1,200 to 1,500
  seconds. The campaign remains bounded at 2,400 seconds, the per-suite ceiling remains 300 seconds, and no
  reviewer/runtime/provider limit changes.
- **Paired evidence**: the 1,200-second attempt is durable as timed-out command-scoped evidence with provider
  invocation false. The replacement plan must complete the same 76-suite command within 1,500 seconds before a
  fresh run may claim or spend a provider slot; a failure still stops before provider invocation.

### DRIFT-198-I008-042 — POSIX containment proof used startup windows below observed host latency

- **Status**: corrected; three concurrent WSL and exact-head hosted CI proofs pass; fresh independent review pending
- **Severity**: release-check stability blocker
- **Type**: timing-sensitive containment fixture and startup-budget drift
- **Requirements**: FR-061, FR-063, SC-020, SC-021, NFR-002; T029 release acceptance
- **Observed evidence**: exact-head Specrew CI run `29949990624` failed only the portable native process-group
  fixture. Its isolated containment host did not publish the ready handshake within the fixed five-second window,
  so the runtime correctly failed closed as `abandoned` instead of reaching the expected timeout path. A WSL replay
  then reached the timeout path but showed the second race: the one-second reviewer window expired before the nested
  fixture had published `child.pid`. The three other exact-head workflows were green, including the full
  cross-platform PR and push matrices; no workshop-state assertion failed.
- **Correction**: use one named 15-second bound for containment-host readiness in both the production invocation
  and macOS capability probe, capturing the value into the runtime port before its generated closure is created.
  Keep reviewer execution independently bounded by its invocation timeout. Give the native descendant-reap fixture
  five seconds so it proves an actually-started child is killed rather than racing cold PowerShell startup. The
  first WSL proof correctly rejected a direct `$script:` reference inside the generated closure because that dynamic
  module resolved the value as zero; the captured closure value is the corrected implementation.
- **Paired evidence**: missing or invalid readiness still returns no authority after the named bound, while a valid
  handshake proceeds to the independently bounded execution timeout. The existing timeout case must observe a real
  child and prove it dead; capability absence, permanent membership failure, and cleanup failure remain fail-closed.
  Three concurrent WSL executions each passed all six applicable cases with two expected cgroup-delegation skips;
  the Windows contract path passed four cases with four expected POSIX skips. Clean detached commit `47298c66`
  passed all 76 registered suites in 1,343.7 seconds and scoped governance in 21.880 seconds. Its Test run
  `29951947552`, Specrew CI `29951948377`, Cross-Platform PR `29951947673`, and Cross-Platform push
  `29951942654` all succeeded, including both macOS runtime jobs.

### DRIFT-198-I008-043 — reviewer prompt omitted the numeric candidate budgets enforced by strict ingress

- **Status**: corrected locally; focused contract proof passes 27/27; exact-head CI and fresh independent review pending
- **Severity**: release-review blocker
- **Type**: incomplete file-primary prompt contract
- **Requirements**: FR-060, FR-063, NFR-002; T029 release acceptance
- **Observed evidence**: run `run-t029-claude-windows-b39e3fce-e231860c-12` completed its frozen verification
  plan and invoked Claude exactly once against commit `b39e3fce0d185941878ad27c019dc2dd66b82b3a` / digest
  `e231860c254278f7006486d26a5906c9eaa05c78`. Strict ingress rejected the raw file-primary candidate as
  `schema-invalid: too-long:summary:4000` because its summary contained 4,051 characters. The immutable result is
  therefore `invalid-output`, has no validated findings, and cannot approve the target. The raw rejected payload's
  single note is unvalidated evidence and is not promoted or repaired under this correction.
- **Correction**: the production prompt now states conservative budgets below every schema maximum: 2,000 summary
  characters, 50 findings, 48-character local IDs, 160-character titles, 3,000-character descriptions, and
  800-character locations. It tells the reviewer to shorten prose and never truncate the JSON object. The prompt
  validator requires both the summary and per-finding budget clauses, preventing an adapter from silently reverting
  to the ambiguous word `bounded`.
- **Paired evidence**: the deterministic contract suite rejects a prompt with the budget paragraph removed while
  retaining the existing overlong-candidate rejection and valid raw-file acceptance cases. One exact-head CI pass
  and one fresh invocation are the only remaining proof cycle; any new invalid output, finding, runtime failure, or
  drift stops instead of starting another correction loop.

#### T029 run-12 release-preparation evidence

- **Provider accounting**: one unique invocation and one spend; no hidden retry.
- **Controller proof**: the frozen verification plan completed before spend and the target remained current.
- **Authoritative outcome**: strict invalid-output rejection; no validated finding and no approval effect.
- **Next action**: one conservative prompt-contract correction, exact-head CI, and one new run identity. A clean
  result returns T029 to the maintainer's manual workshop test; any other outcome returns to the maintainer.

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
