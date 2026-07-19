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

**Total drift events**: 5
**Resolution rate**: 50% (3/6 resolved; DRIFT-198-I008-004/005/006 remain open through exact-digest signoff)
**Specification drift**: None detected

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

- **Status**: correction implemented; exact-digest signoff pending after attempt 02 intermittent verification failure
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

- **Status**: correction implemented; full exact-candidate verification pending
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

- **Status**: correction implemented; exact-candidate full verification and signoff pending
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

- **Status**: correction implemented; exact-digest signoff pending
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

- **Status**: correction implemented; exact-digest signoff pending
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

- **Status**: correction implemented; exact-digest signoff pending
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
