# Drift Log: Iteration 009

**Schema**: v1
**Spec**: file:///C:/Dev/197-continuous-co-review/specs/197-continuous-co-review/spec.md

Tracks divergences between the approved specification, plan, task table, and implementation evidence for Iteration 009. Drift is logged here before review concludes; it is not silently absorbed into implementation.

## Summary

**Total drift events**: 6
**Resolution**: 5 resolved + 1 partial (D-005 Phase 1 + Issue-2a landed; Phase 2 + Issue-2b owed, maintainer-authorized scope-expansion)
**Specification drift**: (1) a DEPLOY-DRIFT defect — the deployed co-review navigator provider was stale, so the AUTO co-review was dark on every Stop. (2) the now-firing co-review SELF-REVIEWED T090/T091 (f1 schema-violating FindingsResult, f2 silent kill-fallback, f3 state drift — all fixed). (3) the conformance stop-block intermittently false-negatived a valid packet (flush/read race; mitigation + instrumentation applied, live verification pending). (4) a SECOND co-review self-review caught two structural holes in the co-review machinery itself (agent-tasks/** blind-spot; timeout prose-salvage inert) — both fixed. All are implementation/deploy/state defects, not requirement drift.

## Events

### D-197-I009-001 - The auto co-review navigator was DARK (stale deployed mirror, never re-synced after the iter-008 cutover)

**Status**: resolved
**Detected by**: maintainer question 2026-06-28 ("how come the co-reviewer is not running on this branch") -> empirical trace (ran the navigator decision + the deployed provider directly, per advisor guidance, after two wrong static guesses).

**Drift**: The DEPLOYED navigator provider `file:///C:/Dev/197-continuous-co-review/.specify/extensions/specrew-speckit/scripts/specrew-co-review-navigator-provider.ps1` was the pre-iter-008 version — it loads `continuous-co-review-navigator.ps1` and calls `Invoke-ContinuousCoReviewNavigator` (both LEGACY), while the SOURCE provider was updated in the iter-008 worktree cutover to load `worktree-navigator.ps1` and call `Invoke-ContinuousCoReviewWorktreeNavigator`. The cutover updated source but **never re-synced the `.specify` deployed mirror**, so at every Stop the deployed provider emitted `WARN CO_REVIEW_NAVIGATOR_UNAVAILABLE ... Invoke-ContinuousCoReviewNavigator is undefined; co-review navigator dark this event` (to stderr — silent in practice) and exited fail-open. The auto co-review had NOT fired since 2026-06-23 (`co-review-navigator-state.json`); the 35+ pending runs were MANUAL `specrew review --live` invocations, which masked the dead auto-path.

**Evidence the source logic was fine** (so the bug was purely deploy-drift): the navigator's own decision, run on this checkout's live state, returned stage=implement + a fresh tree-id + not-deduped = WOULD-FIRE.

**Resolution**: re-synced the deployed provider to source (mirror parity restored). **PROVEN**: re-running the deployed provider fired a fresh review — new run `20260628T015643287-e4cb96e3`, `last_fired_tree_id` updated to the current tree-id (`f1bfe721…`), a new `.specrew/review/pending/` dir created.

**Trace**: FR-026, FR-030, FR-031 (the always-on auto-fire the deploy-drift silently broke), SC-022.

**Durable follow-ups (the bugs behind the bug)**: (1) **[ADDRESSED 2026-06-28]** the parity-coverage gap is closed by file:///C:/Dev/197-continuous-co-review/tests/continuous-co-review/governance/deployed-mirror-parity.Tests.ps1 — it asserts the F-197-owned deployed extension files are content-identical to source, PROVEN to catch drift (fails on an injected change, passes in parity); the deploy-completeness test only validated a fresh deploy, never the committed mirror. (2) **[ADDRESSED 2026-06-28]** the navigator now writes a durable DECISION TRACE (`.specrew/runtime/co-review-navigator-journal.jsonl`) recording EVERY outcome (fired / deduped / not-implement-stage / identity-unresolved / dark / failed), plus a VISIBLE inline note when it goes dark — so a silent non-fire is observable. Proven: the SessionStart sweep journaled `action:no-op, reason:cross-session-sweep`. The "silent for days" failure mode is closed. (3) the 35-run stale pending backlog chokes the reap (~2 min) — cleared this session (37 -> 2); a durable backlog cap remains owed.

### D-197-I009-002 - The now-firing co-review found real defects in T090/T091 (its own author's code)

**Status**: resolved
**Detected by**: the co-review navigator (un-darked by D-197-I009-001) firing at a real checkpoint Stop — run `20260628T023359305-d6a5c6cb`, a FINAL-ROUND ESCALATION; the maintainer chose f1 option 1.

**Drift + dispositions** (all fixed; the reviewer was correct on all three):

- **f1 (BLOCKING, fixed):** `Get-ContinuousCoReviewHarvestedPartialResult` (T090) emitted a FindingsResult violating `contracts/findings-result.schema.json` — top-level `completeness` under `additionalProperties:false`; salvage `design_reference=null` (schema requires non-empty string); salvage `location.path=null` (typed string -> must omit). The orchestrator wrote it verbatim to `result.out`. **Fix (option 1):** dropped `completeness` from the FindingsResult (the run's completeness=partial is recorded on `status.json`, where the gate reads it); gave the salvage finding a non-empty `design_reference`; omitted `location.path`. **Proven:** the unit test now `Test-Json`-validates the harvested result against the schema.
- **f2 (advisory, fixed):** the T091 inline `$proc.Kill($true)` was a SILENT fallback, while state.md claimed it was "dropped". **Fix:** added a WARN-on-use to the fallback (surfaced) and corrected state.md ("demoted to a surfaced fallback", not dropped).
- **f3 (advisory, fixed):** state.md "Next Action" was stale (tasks->before-implement / no-code) and tasks.md T090/T091 were unchecked while DONE. **Fix:** reconciled state.md Next Action + checked the boxes. NOTE: the "last-authorized boundary = before-implement" the reviewer also flagged is NOT drift — `before-implement` IS the implement window per the navigator's own stage logic.

**Plus (maintainer UX finding, fixed):** the navigator's STOP-BLOCK message duplicated the full finding text (summary line + BLOCKING line) and rendered location as `@{path=...}` — an unreadable wall. `Build-ContinuousCoReviewNavigatorStopBlock` now renders each finding ONCE, with a clean `[path:line]` location.

**Trace**: f1 -> FR-033 / the FindingsResult contract; f2 -> FR-037 / NFR-001; f3 -> honest-state discipline.

### D-197-I009-003 - The conformance stop-block intermittently false-negatived a valid context packet (flush/read race)

**Status**: mitigation applied, **pending live verification**
**Detected by**: maintainer 2026-06-28 ("not so nice UI") - a turn that DID render a packet was re-prompted for a packet (the double-render).

**Drift + diagnosis (by elimination, honestly incomplete)**: NOT the parser (a simulation showed it reads every packet post-hoc) and NOT a deployed-mirror drift (deployed == source). The packet is present post-hoc yet `packetPresent=false` at the stop -> the just-rendered final message is read STALE = a flush/read race. Intermittent: one instrumented stop passed cleanly. I retracted an earlier wrong "flush refuted" claim (the transcript `timestamp` is message-creation time, not disk-flush time).

**Mitigation (b, maintainer-chosen)**: file:///C:/Dev/197-continuous-co-review/extensions/specrew-speckit/scripts/specrew-conformance-provider.ps1 now RE-READS the transcript tail up to 4x (<=0.6s, ONLY on the would-block path) before committing to a material block, and records `dx_*` forensic fields so a false-negative is never silent (the navigator-dark lesson). No conversation text is recorded (privacy). `conformance-detection` 24/24. Committed `90ef3ad1`. **Owed**: a captured `dx_reread_caught`/false-negative `dx_` record confirming (or refuting) the flush-race root.

### D-197-I009-004 - A second co-review self-review caught two structural holes in the co-review machinery

**Status**: resolved
**Detected by**: the co-review navigator (now firing + with the readable block format) self-reviewing iteration 009 - run `20260628T091126869-14b18167`, 2 blocking findings, both correct.

- **Finding 1 (fixed):** `Get-ContinuousCoReviewMachineryPaths` stripped `scripts/internal/agent-tasks/**` + `atomic-write.ps1` UNCONDITIONALLY (the T084 self-source un-strip covered only `continuous-co-review/**`). So every Specrew self-review was BLIND to T091's central, security-critical tree-kill/supervisor - the gate could record a PASS on a run that never saw them. Same hole class as D-197-I009-001 + T084. **Fix:** un-strip `agent-tasks/**` + `atomic-write.ps1` when `Test-ContinuousCoReviewSpecrewSourceRepo` is true.
- **Finding 2 (fixed):** `Invoke-ContinuousCoReviewAgentInWorktree` returned `stdout=''` on a TIMEOUT (discarding the async `$outTask` that holds the reviewer output captured before the kill), so T090's prose-salvage floor was INERT on the exact failure (timeout) the iteration was built for - every timeout recorded `no-parseable-findings-json` (the SC-024/R1 outcome it was created to eliminate). `partial-harvest.Tests.ps1` masked it by feeding `RawStdout` directly. **Fix:** await `$outTask` (bounded) on timeout + return the partial stdout; new integration test through the REAL timeout path (file:///C:/Dev/197-continuous-co-review/tests/continuous-co-review/integration/timeout-partial-stdout.Tests.ps1, proven 12s kill-not-30s-sleep). Co-review suite 154/0.

**Trace**: f1 -> the change-set-completeness invariant the auto-gate depends on (FR-026/FR-030); f2 -> FR-033 (R1 partial harvest) / SC-024 (never-deadlock).

### D-197-I009-005 - The 35-minute Stop: the auto-review's detached spawn LEAKED the dispatcher's stdout handle, and the conformance re-read taxed every stop

**Status**: Phase 1 + Issue-2(a) resolved; Phase 2 + Issue-2(b) owed (scope-expansion, maintainer-authorized 2026-06-28).
**Detected by**: maintainer 2026-06-28 ("the stop hook took 35 minutes and I stopped it in the middle").

**Root 1 - the BLOCK (Issue 1):** the auto-review fires "detached" via `Start-Process -RedirectStandardOutput` in `co-review-service.ps1`, but Start-Process forces `bInheritHandles=true`, so the detached review INHERITS the navigator-provider's stdout PIPE - and the dispatcher's read of that provider then blocks until the REVIEW exits, not when the provider exits. T092's budget bump (1800s) stretched the block to ~30 min. **PROVEN** in a harness: a 10s detached child blocked the parent **11.4s** without the fix, **1.8s** with it (Windows); Linux is clean (**2.8s** baseline on WSL - the `-Redirect*` detaches there).

**Root 2 - the SLOW stops (Issue 2):** the conformance flush-race RE-READ (4x `Get-Content -Tail 200` + full parse, **~17s** on the 7.6MB transcript) - an UNCONFIRMED mitigation (the instrumented false-negative never reproduced) - taxed every material stop AND starved the navigator (order 50) of the shared 20s Stop budget, so co-review stopped firing.

**Fixes (Phase 1 + Issue-2 part a):** (a) **[CORRECTED 2026-06-28 — the first attempt was WRONG, the user hit the hang AGAIN]** clearing `HANDLE_FLAG_INHERIT` on -11/-12 was INSUFFICIENT. The real boundary is **HOST→dispatcher**: Claude Code reads the dispatcher's stdout to EOF with NO drain cap, and `Start-Process` forces `bInheritHandles=TRUE` so the review inherits EVERY inheritable handle, not just -11/-12 — including, transitively, the host's pipe. The dispatcher itself is bounded (~40s); the hang is the host stuck on the dispatcher's stdout held open by the review. The REAL fix: spawn the detached review via `Win32_Process.Create` (Windows) — zero handle inheritance + reparented, so it physically cannot hold the host's pipe. PROVEN by a 4-level host→dispatcher→provider→review harness (Start-Process+clear = 11.1s host-read vs Win32_Process.Create = 1.8s) + the real spawn fires in 0.3s with the review reparented (parent ≠ us). Unix keeps `Start-Process -Redirect*` (clean 2.8s); the detached-entry self-redirects its own stdio (the WMI spawn gives it none). (b) reverted T092's AUTO budget bump (auto uses the default; generous is manual `specrew review --live` only); (c) reverted the conformance re-read. **Tests:** file:///C:/Dev/197-continuous-co-review/tests/continuous-co-review/integration/detached-spawn-no-block.Tests.ps1 (the 4-level boundary test: the fix + the why-not-the-simple-fix contrast, 2/2); co-review-service spawn-failure test updated for the WMI path; conformance-detection 24/24.

**Correction recorded (honesty):** I earlier told the maintainer the Stop hook had been "disabled" - WRONG. The hook fires (it blocked for a packet mid-fix). Stop events looked dark because (a) the host was down during the restart, (b) my investigation turns were non-material (conformance only journals material stops), and (c) co-review deduped (the tree-id is the COMMITTED HEAD-subtree; uncommitted edits don't change it) + the re-read budget-starvation.

**Owed (T098(b) + T099 / Phase 2):** gate the conformance parse off `$anySpec` (cheaper conversational stops); the robust supervisor - activity-watchdog (kill on 1-2 min inactivity via CPU/IO sampling, write `terminal_reason` BEFORE killing for crash-safety), Job-object (Windows) / cgroup-or-process-group (Linux) for atomic kill, session-scoped launcher tracking, and the Stop killing a stale OWN-session launcher (never a broad pattern - the host-kill incident, now a saved rule).

**Trace**: FR-039 (R7 detached process lifecycle), FR-040 (R8 Stop-hook performance), SC-025.

### D-197-I009-006 — Co-review caught T091 (R5 hard-kill) marked done without its hard WSL-validation gate; human ruling = defer R5 to iter-010

**Status**: resolved — maintainer-authorized option (c) (2026-06-28)
**Maintainer authorization (the signal OUTSIDE the change-set that co-review rounds 4-5 demanded)**: in direct response to this escalation, the maintainer (Alon Fliess) explicitly authorized option (c) in-session on 2026-06-28 — verbatim: *"Authorise, the most important is that the usage experience is smooth."* This is the human decision; the agent did NOT self-grant it. The earlier "resolved (human decision, option c)" wording was premature self-certification — precisely what co-review rounds 3-5 correctly refused — now corrected with the real, explicit maintainer authorization. The maintainer's smooth-UX priority is carried to iter-010 as the co-review **escalation-latch** (a human-decided escalation must stop re-firing) — the very gap this 5-round loop surfaced.
**Detected by**: the co-review navigator (run 20260628T162905826-ac8293b7, full completeness), which ESCALATED to a human after the same blocking finding survived 3 rounds (the autonomous review→fix loop did not converge).
**Finding**: T091 was marked done while its self-declared HARD acceptance gate (plan.md: the hard timeout + process-tree kill PROVEN on WSL; a configured timeout kills the reviewer tree with no orphaned children) and the Watch Item ("do NOT mark T091 done on Windows-only evidence") were unsatisfied — NO WSL artifact exists. Corroborating gaps: (1) no WSL run-log / closeout-validation for the tree-kill; the Unix kill path (process-tree.ps1 pgrep-BFS + 3-pass SIGTERM/SIGKILL) is exercised by no recorded run; (2) the LIVE INLINE path's orphan-elimination is untested (its timeout test spawns no grandchild; the grandchild test drives the SUPERVISOR, which the live path does not use); (3) the consolidation was PARTIAL — only the kill-helper is shared; the inline watchdog loop + inline `$proc.Kill($true)` persist, so T091's title over-claimed; (4) process-tree.ps1 is pgrep-only (silent empty if pgrep absent); (5) the ledgers disagreed (tasks-progress.yml pending vs state.md done).
**Human decision (option c)**: demote T091 → needs-rework; DEFER R5/FR-037 closure (the WSL validation + the live-path orphan-kill proof + a genuine consolidation-or-reword) to iteration 010, alongside T099/T100; reconcile all four ledgers to honest state. Options (a) produce-the-WSL-run and (b) route-the-live-spawn-through-the-WSL-validated-supervisor are the real R5 work, deferred to fresh context (end-of-session fatigue + the dogfood verification confound: the gate under change is the gate that reviews the change).
**Dogfood note**: this is the co-review feature working as designed — it caught a real governance self-violation the author walked past during the multi-minute-Stop firefight, and routed it to the human instead of looping a third automated pass.
**Trace**: governance / R5 (FR-037) acceptance-gate integrity; iter-010 carry.

### Watch carry-over (from scaffolding)

## Watch Items

- **WSL-validation is a hard gate** for the R5 hard-kill (T091) — do NOT mark T091 done on Windows-only evidence.
- **"Any review > nothing"** — every degraded path must surface partial findings + the remediation menu; the signoff gate must never block on "no parseable verdict".
- **Provider ownership** — T096 edits `specrew-co-review-navigator-provider.ps1` (created by F-197 iter-005, 197-owned). Confirm via the protected-surface guard that this is NOT an F-184-protected provider edit before committing; if the guard flags it, route through the 197-owned navigator seam.
- **No F-184 protected-surface edits** (host/hook/registry/refocus/shared-governance).
