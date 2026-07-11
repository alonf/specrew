# Iteration State: 003

**Schema**: v1
**Last Completed Task**: T015
**Tasks Remaining**: T016, T017, T018, T019, T030, T031, T032, T033, T034b
**In Progress**: T016 (next)
**Baseline Ref**: 2d475962 (before-implement authorization commit)
**Updated**: 2026-07-11T22:40:00Z

<!--
  Current Phase / Iteration Status are set canonically by the sync
  machinery (Proposal 090) once execution begins — omitted at planning
  scaffold time to match the sanctioned shape (iteration 002 precedent),
  never hand-authored with a non-canonical value.
-->

## Execution Summary

- T034a done: the Devin shared-engine seam is recorded
  (research/devin-seam-inspection.md) — the strict design-context
  resolution (cca79708) in the orchestrator, exec-bit restoration
  (ec90e1b6) in the digest, and design-ref plumbing — mapped against
  T013/T014/T017 with the compose-not-collide rules and the semantic-vs-
  mechanical conflict doctrine. Devin authorization deferred to
  post-T034b-verification from a scratch dir; reviewer-hosts.json untouched.
- Co-review catch before T013 code (run 1446b84c, blocking): the shipped
  FR-020 tracker honesty check (T010, iteration 002) had a fail-OPEN —
  extract-and-ignore on state.md, non-canonical statuses accepted —
  contradicting its own TrackerClaims data model. Fixed in place
  (canonical enums, recognized shapes, injected-claim rejection); 5 paired
  tests added; recorded as DRIFT-198-I003-001. Suite green,
  signoff-gate wiring 9/9.
- T013 done (FR-008/SC-002): the reviewer worktree already materialized
  in system temp; T013 ENFORCES it with a containment guard that refuses
  an EphemeralRoot at or under the origin root (a nested worktree would let
  the confined reviewer walk up into the real project). Composes with the
  Devin seam (this is the materializer; their strict-resolution is in the
  orchestrator). Paired test worktree-containment.Tests.ps1 3/3: outside
  origin + no upward-walk resolves origin; inside-origin and origin-itself
  refused.
- T020 done (pulled forward, maintainer-directed execution-order
  adjustment, NOT scope drift): the review-loop spend allowance. A
  RESOLVED-AGAINST-DISK disposition clears the sticky blocking round-state
  - resets the round so a fixed finding can neither re-escalate nor keep
  consuming allowance (the four session incidents c894a74b/970a8d7c/
  efbbb98d/e4e88cb0 as the regression class) - and it REQUIRES committed
  fix evidence (an ancestor of HEAD; a bare claim is refused - no
  false-green). Two-budget accounting (provider spend vs round allowance:
  preflight-before-invocation consumes neither; invoked records spend +
  round). Consumer-legible halt text (N-of-M, reset command,
  resolved-vs-open, zero internal identifiers). CLI: --remediate
  resolved-against-disk --fix-evidence-ref. Proof suite 8/8;
  escalation-latch + degraded-gate regression 23/23; parse-clean.
- NFR-007 enforcement gap CLOSED (maintainer-directed, before resuming
  T014): the F-198 paired honesty tests were manual-only (no CI ran
  tests/unit or tests/continuous-co-review). Wired a bounded, EXPLICIT
  registry runner (tests/f198-regression-suite.ps1 - never a glob;
  per-test timeout + clear failure output) covering the ratchet, spend
  allowance, containment, tracker honesty, verdict-capture, budget, and
  signoff-gate regressions, and added it as a blocking CI step in the
  self-host lane (.github/workflows/specrew-ci.yml, timeout 15m). All 8
  suites green locally. This closes the iteration's own NFR-007
  enforcement - NOT T021 distribution work (T021 later generalizes/
  deploys the mechanism to consumers).
- T014 done (FR-009/SC-002): the reviewer-visible context leaked the
  origin location via file:/// origin URLs in the copied state/plan/spec/
  design snapshots. New ConvertTo-ContinuousCoReviewOriginRelativized
  relativizes origin-absolute paths (file:/// URLs + both separator forms,
  case-insensitive, multi-root) to <project> in the process-context copies,
  the generated process-context.md, and the design-context copies - the
  path STRUCTURE stays reviewable, only the origin PREFIX is neutralized.
  Composes with the Devin design-ref plumbing (relativize, never drop); the
  change-set diff itself (real content under review) is untouched. Paired
  test origin-path-hygiene.Tests.ps1 5/5; added to the F-198 CI registry.
- Co-review 8d3f5a6b (2 blocking): (1) T020 two-budget accounting was a
  standalone classifier with no caller - REAL; now WIRED into the
  orchestrator (preflight: a missing changes.diff fails before model
  invocation, consuming neither budget; post-invocation: an invoked
  invalid result records provider spend + consumes a round + a
  failed-invocation disposition), end-to-end fixtures proving both.
  (2) exec-bit strip on bin/specrew* - REFUTED: HEAD modes are 100755,
  byte-and-mode-identical to origin/main (git diff --summary empty,
  core.filemode=false); the reviewer worktree fabricates the phantom
  because the Devin exec-bit-restoration fix (ec90e1b6) isn''t integrated
  until T034b - the DRIFT-198-I001-001 class. Also fixed a pre-existing
  T012 regression the fix surfaced: the orchestrator crashed under
  StrictMode on a host object lacking independence_source (test mocks) -
  now defensive; four shared-engine F-197 suites added to the F-198 CI
  registry so this class is caught (the NFR-007 gap that let it slip).
- T015 done (FR-010/FR-013): the confinement contract (worktree-only
  rules + what-is-absent teaching) is written into the reviewer slim
  prompt and captured durably in reviewer-spawn-contract.md; the REQUIRED
  bounded in-worktree verification (Invoke-ContinuousCoReviewBoundedVerification)
  runs ONLY declared commands, each with a timeout + process-tree kill on
  expiry, a UTF-8 BYTE output cap, and pre/post mutation evidence where
  ADDED/DELETED/MODIFIED all count (a new file is exempt only via an
  explicit output-path allowlist). Two maintainer honesty corrections
  applied (add/delete as mutations + byte-not-char cap); the
  return @(List) -> ToArray() binding fix per the maintainer diagnosis.
  Paired suite 9/9 (timeout, process-tree kill, byte cap, add/delete/
  modify mutation, allowed-output, empty); added to the F-198 CI registry
  (now 15 suites, all green).
- Co-review bfc7b5c5 (2 blocking, on T015): (1) the bounded-verification
  wrapper had NO production caller and the prompt FALSELY claimed the
  reviewer's OWN shell runs were wrapped - REAL (the reviewer is an agentic
  host with direct tool access; nothing can route its runs through a
  PowerShell wrapper). Fixed by the honest synthesis of both offered
  options: (a) the ORCHESTRATOR now runs the DECLARED verification commands
  through the wrapper and injects the HOST-OBSERVED results into the
  worktree (.review/verification/results.json) BEFORE the reviewer spawns
  (a real caller on the real path, gated so an empty set injects nothing -
  never a pointer to an absent file; the runner-observed complement the
  T111 comment flagged as the 203-W8 fast-follow), and (b) the prompt now
  states the confinement contract honestly - the reviewer's own runs are
  governed by the isolated snapshot + origin-reference removal (T013/T014)
  with T016 monitoring/reporting, NOT a false wrapper claim. (Language
  corrected again at the maintainer's follow-up: no "cannot escape" /
  OS-sandbox implications anywhere - see the next entry.) (2) the output cap used
  ReadToEndAsync (unbounded memory before truncation) - REAL; now both
  pipes DRAIN TO DISK via CopyToAsync (~80KB buffer, reviewer memory
  bounded regardless of volume), then at most MaxOutputBytes are read back.
  New end-to-end suite orchestrator-verification-injection.Tests.ps1 (5:
  injection-on-real-path, mutating-command-recorded, empty=>no-injection,
  honest-prompt x2) + a SUSTAINED multibyte streaming test on the wrapper;
  F-198 CI registry now 16 suites, all green. SCOPE FLAG: the automatic
  SUPPLY of declared commands (deriving them from implementer-evidence =
  the 203-W8 runner-observed evidence) is left for a maintainer scope call,
  not folded in unilaterally.
- Maintainer verdict on the scope flag (2026-07-11, typed instruction):
  (1) the MINIMAL declared-command supply path folded into T015 - ONLY
  commands EXPLICITLY recorded in the digest-matched implementer evidence
  (suites[].command, verbatim; the digest gate inherited from the T111
  copy) reach -DeclaredVerificationCommands; caller-explicit wins; never
  inferred from suite names, never test-scanning, never repository sweeps;
  missing declarations run NOTHING and the status reports the account
  honestly (verification_source + declared/run counts); dedupe + cap 8
  (budget-death guard, cap visible in the counts); the run moved AFTER the
  ceiling/preflight guards so halted runs never spend verification time.
  Generalized discovery + provenance stay deferred to 203-W8 (T018).
  (2) Confinement language corrected EVERYWHERE (prompt, spawn contract,
  state, comments): T013/T014 provide an isolated snapshot + origin-
  reference removal, T016 monitors and reports violations - never an
  OS-enforced sandbox, never "cannot escape/reach". (3) Proof tests added:
  evidence-recorded commands reach the production orchestrator path;
  suite-name-only evidence supplies nothing (no inference); digest-
  mismatched evidence supplies nothing; caller declarations win over
  evidence; a mutating evidence-supplied command is recorded; timeout
  bounds + verbatim transport asserted at the wrapper call. Historical
  note: two closed F-197 iteration-006 artifacts carry the same
  "physically cannot reach" phrasing - left unedited (closed-record
  integrity), flagged to the maintainer.
- Serialized fresh review ran per the instruction (run 06cb3c64, codex,
  round 1 after the resolved-against-disk reset): 2 blocking findings,
  BOTH verified real against disk and fixed:
  (1) the CopyToAsync capture bounded memory but drained to UNBOUNDED temp
  files - a hostile flood could exhaust host temp storage. Fixed by
  eliminating disk entirely: both pipes are pumped into FIXED byte buffers
  capped at MaxOutputBytes each, overflow read-and-DISCARDED (the child
  stays drained, never blocks), memory ~2x cap, ZERO disk writes; the
  record now carries captured_stdout_bytes/captured_stderr_bytes as the
  observable retention proof (asserted at the cap under a ~3 MB flood).
  (2) the broad catch swallowed wrapper/results-write failures, so a
  DECLARED verification that failed to EXECUTE was indistinguishable from
  none-declared - a never-false-green hole. Fixed: declared>0 + engine
  failure now FAILS the run loudly BEFORE the model is invoked
  (failure_reason=verification-not-executed, diagnosable message, T020
  preflight spend class - neither budget consumed, no round latched);
  paired test forces the wrapper to throw and proves the reviewer is
  never invoked. Suites 21/21; registry 16/16.
- CONCURRENT-REVIEW observation (recorded for T019): the manual --live run
  (06cb3c64) and a navigator auto-run (97a93603) fired ~30s apart against
  the same lineage - the in-flight dedup that would serialize them is
  exactly T019's scope ("in-flight dedup per lineage"). 97a93603 added a
  REAL third finding the manual run missed: the orchestrator ran declared
  verification ON the reviewer's own worktree, so a mutating declared
  command - though RECORDED - could tamper with reviewer inputs (source,
  changes.diff, design context) before the review. Its other finding (the
  swallowed infra exception) was already fixed by d3edd098 at arrival
  (stale-against-disk; the demanded exception-path test exists).
- Round-2 re-review ffb729f2 (final round): confirmed the tamper hole
  still open in the d3edd098 tree (escalation, human-decision framing:
  disposable-child verification OR fail/rematerialize) + advisory f2
  (tasks.md checkboxes for T013/T014/T015/T020 lagged plan/state). Fixed:
  (1) declared commands now run in a DISPOSABLE SIBLING COPY of the
  worktree (system temp, T013 containment class, removed in finally) -
  a mutating declaration is still recorded for the reviewer to judge but
  is structurally unable to alter the certified reviewer inputs; the
  orchestrator-path test now asserts the reviewer-visible tree keeps the
  fire-time content (app.txt unmodified, changes.diff intact) while
  source_mutated=true is recorded. Of the escalation's two remedies the
  fix implements disposable-child verification (the stronger: the
  reviewer tree is never touched, no restore step to get wrong) -
  surfaced to the maintainer at the next stop for veto. (2) tasks.md
  T013/T014/T015/T020 ticked to match plan/state (the checklist had
  simply lagged; no divergent semantics).
- Confirming review 90173dc6 (round 1 after the d0cc9bf7 reset): 2
  blocking, BOTH real. (1) The mutation snapshot SKIPPED all of .review/,
  so a declared command could rewrite the verification copy's own
  authority (changes.diff, design/) and manufacture a pass with
  source_mutated=false. Fixed: the hash set now INCLUDES the
  reviewer-authority inputs; excluded are ONLY .git/ and the narrow
  engine-owned .review/verification/ output area. Paired tests: forging
  .review/changes.diff is reported; the engine-owned area stays exempt
  (wrapper suite 12/12). (2) The state's green counts were PROSE with no
  digest-linked runtime evidence (zero evidence standing under the review
  contract). Fixed the honest way: the T015 suites + the F-198 registry
  are re-RUN and recorded through the T111 recorder
  (Write-ContinuousCoReviewTestEvidence) with the runner-reported counts,
  exit codes, durations, and the exact reproducible commands, digest-bound
  to this tree at .specrew/review/test-evidence/<digest>.json - which
  ALSO arms the minimal supply path: the next review derives its declared
  commands from this record and re-observes the suites through the
  bounded wrapper in the disposable copy. Registry counts in this file
  are henceforth BACKED by that record, not prose.
- Next: fix re-review (round 2, same lineage) verifies both resolutions;
  then T016 if clean.

## Notes

- Update this file after each task completes.
- Keep task identifiers aligned to plan.md.
