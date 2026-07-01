# Iteration 009 Retro

**Feature**: 197-continuous-co-review
**Iteration**: 009 (reviewer robustness — graceful degradation)
**Date**: 2026-07-01 (work window closed at the 0.39.0-beta1 release)
**Provenance**: RECONSTRUCTED 2026-07-02, from evidence only — `state.md`,
`drift-log.md` (findings D-197-I009-001..017), `plan.md`, and `tasks-progress.yml`.
Iteration 009 pivoted toward the 0.39.0-beta1 release before a formal retro was held
(`state.md` was reconciled to disk-truth 2026-07-01), so this record distills the
recorded evidence and invents no reflection beyond it.

## What went well

- **The now-firing co-review found real defects in its OWN author's code that green tests missed.**
  Un-darking the navigator (D-197-I009-001) let it self-review T090/T091 and catch three real defects
  (D-197-I009-002: a schema-violating `FindingsResult`, a silent kill-fallback, and stale state), then
  catch two more structural holes in the co-review machinery itself (D-197-I009-004: the
  `agent-tasks/**` self-review blind-spot and an inert timeout prose-salvage). A `--live` run even caught
  a real reachability bug in the D-197-I009-014 fix that parse/unit checks passed clean. The shift-left
  thesis proved out: adversarial co-review out-performed the green suite on soundness, exactly as in
  iteration 005.
- **Halt-is-not-a-pass was made honest.** The round-ceiling halt was emitting `done / 0 findings` — a
  silent FALSE-GREEN that nearly signed off an unreviewed increment (D-197-I009-010). The ceiling branch
  now emits a visible `kind=escalation, severity=blocking` finding and `status.reviewed=false`, so an
  unreviewed halt can never read as clean, while Option-A parking keeps the gate from deadlocking.
- **Never-deadlock robustness landed at named seams.** T090 partial-harvest + prose-salvage floor, T092
  time-extension, T097 detach-leak fix (WMI `Win32_Process.Create` spawn, proven in a 4-level
  host→dispatcher→provider→review harness), T098 conformance re-read revert, plus the Option-A
  `escalated_to_human` parking and the round-ceiling bound — all shipped, extending the worktree pipeline
  with no new architecture.
- **Dogfood + beta rehearsal surfaced and fixed a run of setup-UX defects** (D-197-I009-007 version-probe
  override, -011 `specrew init --force`, -012 empty SessionStart banner-3, -014 actionable
  no-authorized-host message, -009 codex sandbox-bypass), and the full loop validated end-to-end: a
  126-second codex review with 2 real findings once a host was authorized.

## What hurt (friction -> learning)

1. **Reviewer reliability is a first-class robustness concern, not a given (the headline learning).** Across
   ~a dozen `specrew review --live --host codex` runs, roughly HALF returned exit 0 with a 0-byte
   `result.out` -> `no-parseable-findings-json` (D-197-I009-015). For a co-review that fires per checkpoint,
   a ~50% "reviewed nothing" rate makes a real verdict a coin-flip per fire, and the T090 prose-salvage
   floor is INERT when the reviewer emits literally nothing to harvest. It fails LOUDLY (`status=failed`,
   never a false pass), so correctness holds — but **the graceful-degradation charter has a blind spot:
   "any review beats nothing" has nothing to floor when the reviewer produces nothing.** -> OPEN, recorded
   for the beta; diagnose + retry-once + a more reliable default carried to iter-010.
2. **A halt that reports clean is the worst failure class for a review gate.** The round-ceiling "stop
   nagging" fix conflated *stop re-reviewing* (correct) with *report clean* (a lie), producing the silent
   false-green above. **Learning: a false-green is silent where a crash is visible; a halt must ALWAYS be
   distinguishable from a genuine pass.** -> FIXED (visible escalation + `reviewed=false`).
3. **State-truth cursor drift recurred and bit hard across a machine switch.** The gitignored per-machine
   session cursor did not travel desktop->laptop (D-197-I009-008), so a fresh empty cursor drove the
   navigator to no-op `not-implement-stage` at every Stop while the committed `state.md` said `implement`,
   AND drove the pending-verdict detector to demand a spurious early-boundary verdict. Same recurring
   class the iter-005 retro already flagged (#2784 stale session anchor). **Learning: never gate dark on
   missing LOCAL state — fall back to committed `state.md`; the lifecycle pointer must be git-carried /
   reconstructable, not a per-machine single point of failure.** -> diagnosed + reverted; durable fix
   deferred (iter-010 navigator-stage fallback + Proposals 142/193).
4. **Scope grew mid-iteration from real, plannable-only-in-hindsight dogfood work.** The 35-minute Stop
   incident (D-197-I009-005) forced the R7/R8 scope-expansion (T097 detach-leak + T098 Stop-perf,
   maintainer-authorized 2026-06-28), and the escalation-latch, Option-A, and round-ceiling all landed on
   top of the planned R1-R6 slice. **Learning (confirming iter-005): integration-heavy dogfood reliably
   surfaces real work that did not exist at plan time — budget closeout headroom for it.**
5. **Orphaned-but-validated artifacts are a repeating gap class.** The escalation-latch is committed but
   wired into nothing (absent from `_load.ps1`, zero callers), and the canonical `code-review-agent.md`
   reviewer instruction is validated by its test yet injected into no live reviewer while the slim prompt
   carries the real instruction (D-197-I009-016) — the same "green-but-inert / file-presence != runtime"
   trap the iter-005 retro named as its headline. **Learning: a passing test on an unwired artifact proves
   nothing about runtime.** -> both staged/decided, wiring + fold carried to iter-010.

## Estimation Accuracy

Planned 17.50/20 story_points (`plan.md`). The original R1-R6 reviewer-robustness slice plus the T095
governance cleanup was ~14.5 SP (`state.md` Planning Summary); the R7/R8 dogfood scope-expansion (T097
+T098, +3.00 SP, maintainer-authorized 2026-06-28 from the 35-minute-Stop incident) brought the plan to
17.50/20 — still within cap.

Of that plan, 5 tasks were delivered done — T090 (2.5), T092 (1.5), T095 (0.5), T097 (2.0), T098 (1.0) =
**7.50 SP** — plus the un-tasked Option-A escalation parking, the round-ceiling fix, and the (committed
but unwired) escalation-latch. The remaining 4 robustness tasks — T091 R5 hard-timeout (3.0), T093 host
fallback (1.5), T094 degraded gate (2.5), T096 remediation menu (3.0) = **10.00 SP** — were DEFERRED to
iter-010 under the full-robustness decision (2026-07-01).

The deferral was the honest overcommit-management move, not a miss: the R7/R8 expansion + the beta
rehearsal consumed the closeout window, and R5's hard WSL-validation gate (D-197-I009-006, maintainer
option (c)) could not be met on Windows-only evidence, so it was demoted and carried rather than
self-certified. Calibration actuals (effort-spent variance) were NOT recorded because the iteration
pivoted to the 0.39.0-beta1 release before a formal retro; no precise actuals are fabricated here.

## Drift Summary

`drift-log.md` records **17 findings** (D-197-I009-001..017; the Summary header count of 15 predates the
-016/-017 additions made during the 2026-07-01 Phase-0 reconciliation). The majority were resolved or
fixed this iteration (deploy-mirror parity D-001, the two co-review self-reviews D-002/D-004, ceiling
false-green D-010, `init --force` D-011, SessionStart banner-3 D-012, version-probe D-007, codex
sandbox-bypass leg D-009, no-authorized-host message D-014, and the iter-002 cluster reconciliation
D-017).

A set was honestly carried forward rather than force-closed: to **iter-010** — R5 WSL validation +
consolidation (D-006), the empty-cursor navigator fallback (D-008), the per-run worktree-allow framework
T102 (D-009), the `code-review-agent.md` fold (D-016), and the codex empty-exit-0 reliability finding
(D-015, OPEN); to the cross-feature **Proposals 142/193** — the durable state-truth / lifecycle-pointer
fix. D-003 (conformance flush-race) is mitigated with a pending live `dx_` confirmation, and D-005 landed
Phase 1 + Issue-2(a) with Phase 2 owed. All findings were implementation/deploy/state/reliability
defects — no in-scope requirement drift (FR-033..FR-040 + SC-024/SC-025 stayed fixed).

## Improvement Actions

Fixed this iteration:

- [x] Deployed-mirror parity guard + a durable navigator decision journal so a silent non-fire is
  observable (D-197-I009-001).
- [x] `FindingsResult` schema conformance + a readable single-render stop-block (D-197-I009-002).
- [x] Un-strip `agent-tasks/**` + `atomic-write.ps1` on self-review, and await the timeout partial stdout
  so the prose-salvage floor is not inert (D-197-I009-004).
- [x] WMI `Win32_Process.Create` detach spawn (no host-pipe inheritance) + revert the AUTO generous-budget
  bump (T097 / D-197-I009-005 Phase 1).
- [x] Revert the unconfirmed conformance flush-race re-read that taxed every stop (T098 /
  D-197-I009-005 Issue-2a).
- [x] Ceiling-halt emits a visible escalation + `status.reviewed=false`, never a false-green
  (D-197-I009-010).
- [x] Codex sandbox-bypass so the reviewer operates in the ephemeral worktree (D-197-I009-009, codex leg).
- [x] Version-probe honors `SPECREW_MODULE_PATH` (D-197-I009-007); `specrew init` drops the unsupported
  `--force` (D-197-I009-011); SessionStart injects the resolved profile into banner-3 (D-197-I009-012).
- [x] Actionable "authorize a reviewer" navigator message on `no-authorized-reviewer-host`
  (D-197-I009-014).
- [x] iter-002 abandoned-cluster + 5 untraced-requirements reconciliation of record (D-197-I009-017).

Carried to iter-010:

- [ ] T091 R5 hard-timeout — WSL validation of the live-path tree-kill + a genuine consolidation-or-reword
  (D-197-I009-006).
- [ ] T093 host-independence fallback; T094 tiered degraded-evidence gate; T096 remediation menu.
- [ ] Navigator stage-gate fallback to committed `state.md` when the session cursor is empty/missing
  (candidate T101, D-197-I009-008).
- [ ] Per-run worktree-allow injection framework + sandbox-capability preflight (T102, D-197-I009-009).
- [ ] Wire the committed escalation-latch (parser + human-closure predicate) into `_load.ps1` + an
  integration test.
- [ ] Fold the load-bearing `code-review-agent.md` bindings into the slim prompt + retire the orphan file
  (D-197-I009-016).
- [ ] Diagnose the codex empty-exit-0; consider a retry-once on a 0-byte result and a more reliable default
  reviewer (D-197-I009-015).
- [ ] Capture a `dx_` record confirming (or refuting) the conformance flush-race root (D-197-I009-003).
- [ ] SC-012 / SC-022 cross-host validation.

Deferred beyond F-197:

- [ ] The durable lifecycle-pointer / state-truth fix (Proposals 142/193).
- [ ] Automated live cross-host CI (Proposals 181/194).

## Process Notes

- **Dogfood-on-self was the primary defect source.** Every co-review-caught finding (D-002, D-004, and the
  D-014 self-catch of a bug in its own fix) came from the feature reviewing its own change-set at real
  checkpoint Stops — the shift-left value the feature exists to prove.
- **The iteration shipped 0.39.0-beta1** (`35cb66c3`) with PR-hardening: a markdownlint sweep across the
  changed docs (`b6db4b42`) and the 7 Copilot+codex PR-review findings (`f91f8360`). The side-by-side
  0.39.0-beta1 install (D-197-I009-013) put the CLI in the exact state a published-beta user gets, which
  de-risked the release.
- **`state.md` was reconciled to disk-truth on 2026-07-01** after the 2026-06-28 snapshot was overrun by a
  full work-cycle + the beta: Option-A and the round-ceiling in fact landed in iter-009 though the frozen
  snapshot had "carried" them, while the escalation-latch is committed but NOT wired (staged for iter-010).
- **Human authorization was recorded, not self-granted.** The R5 defer (D-197-I009-006) and the codex
  bypass (D-197-I009-009) both cite explicit in-session maintainer authorizations; the premature
  "resolved (human decision)" wording that co-review rounds 3-5 had refused was corrected to the real
  authorization — reinforcing that a human-decided escalation must stop re-firing (the escalation-latch
  gap carried forward).
