# Iteration State: 003

**Schema**: v1
**Last Completed Task**: T018 (universal language/framework-NEUTRAL recorded-run evidence runner `Invoke-ContinuousCoReviewRecordedRun` — direct command-execution facts + OPTIONAL run-produced schema-valid SpecrewTestResult; caller counts forbidden; fail-loud; evidence-only; 10/10 focused + full 19-suite registry green; T013/T014/T015/T016/T017/T020 also complete)
**Tasks Remaining**: T019, T030, T031, T032, T033, T034b
**In Progress**: T019 — the CHARACTERIZATION/CONTRACT slice (steps 1–5: the five identities; the five artifact-lifecycle classes; DRIFT-002 digest-A-vs-B, in-flight-dedup/out-of-order, and FR-045 Stop-ordering fixtures; PURE UNWIRED contract functions) is DONE and green; step 6 (implement against the contracts — runtime wiring) is NOT started, pending maintainer review (instruction 2026-07-13: return after the slice before broad runtime changes)
**Baseline Ref**: 2d475962 (before-implement authorization commit)
**Updated**: 2026-07-13T03:00:00Z

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
  F-198 CI registry was 16 suites, all green at that round's digest (it later
  grew to 18). SCOPE FLAG: the automatic
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
  never invoked. Suites 21/21; registry was 16/16 at that round's digest.
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
  (1) declared commands now run in a DISPOSABLE COPY of the worktree, so
  an output-writing verification does not perturb the reviewer inputs and
  a mutating declaration is recorded for the reviewer to judge. (NOTE: the
  first cut of this entry called the copy "structurally unable to alter"
  the reviewer inputs - that overclaim was itself the next finding
  (4b124d0e-1) and is corrected below; the copy is NOT an OS boundary.)
  (2) tasks.md
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
- Confirming review 4b124d0e + my --live run c9abe16d (round 1): 3 issues,
  all real. (1) SECURITY (4b124d0e-1): the disposable copy is NOT an OS
  boundary - a declared command has ambient filesystem authority and can
  reach the sibling reviewer worktree by absolute/.. path; my "structurally
  unable" claim was false. Fixed per the escalation's accepted remedy
  (detect + refuse, not sandbox theatre): the orchestrator hashes the
  CERTIFIED reviewer tree before/after verification and, if any source or
  .review-authority file changed, FAILS the run
  (verification-tampered-reviewer-tree) before the reviewer is invoked.
  Deterministic paired test proves an out-of-sandbox reviewer-tree change
  is caught and the reviewer is never invoked. All "structurally unable" /
  OS-sandbox language removed. (2) FRAGILITY (c9abe16d): my --live round-2
  review DID NOT RUN - Copy-Item -Recurse crashed when a transient
  reviewer-host file (.antigravitycli/*.json) vanished mid-copy under the
  concurrent-review races. Fixed: a robust Copy-...VerificationSandbox
  skips .git + volatile host-runtime dirs and tolerates a file that
  vanishes mid-copy. (3) EVIDENCE (4b124d0e-2): no worktree-visible
  runtime-evidence artifact existed (the .specrew record is stripped from
  the reviewer worktree). Fixed: hand-authored iterations/003/
  coverage-evidence.md (worktree-visible; commands/counts/exit/durations),
  and the digest-linked supply record NARROWED to the single fast
  self-contained bounded-verification suite (12/12, ~12s) so the live
  re-run is cheap - re-running the 91s full registry every review was the
  T111 budget-death class. Suites 24/24; registry was 16/16 at that round's digest (88s).
- DESIGN CONCERN surfaced to the maintainer (not auto-resolved): the
  orchestrator-runs-declared-verification mechanism has now taken 5 review
  rounds of hardening (tamper, fragility, authority-hash, evidence, escape)
  and re-runs suites inside a copy on every review - tension with the T111
  "do NOT re-run whole covered suites" anti-budget-death design. Options
  for the maintainer: keep hardening the re-run design, or simplify to the
  honest host-boundary contract (reviewer reads T111 evidence + self-
  spot-checks; orchestrator does NOT re-run; the bounded wrapper stays for
  EXPLICIT caller-supplied focused commands only). Recommendation carried
  in the stop packet; proceeding with the hardened fix meanwhile.
- DESIGN DECISION (maintainer, option 1 = SIMPLIFY, 2026-07-11): removed
  the orchestrator's automatic declared-command supply, verification-
  sandbox copying, and per-review reruns entirely. Runner-observed
  verification moves to T018 (commands run ONCE through the recorded-run
  wrapper; digest-bound evidence injected as .review/implementer-evidence
  .json for the reviewer to READ + spot-check). Invoke-...BoundedVerification
  survives ONLY as an explicit opt-in API (never automatic). NEW protection
  at the real risk: the REVIEWER invocation is integrity-checked - source +
  .review authority hashed before/after, only .review/findings.jsonl may
  change, any other mutation FAILS the review (reviewer-tampered-tree,
  invoked-failed spend, findings discarded); volatile host dirs
  (.antigravitycli/.codex/.claude/.cursor/.gemini/.copilot) + .git excluded
  so host churn is not false-flagged. Docs say MONITORED confinement, not
  OS isolation. Removed: Get-...EvidenceDeclaredCommands,
  Copy-...VerificationSandbox, the -DeclaredVerificationCommands params, the
  verification_* status fields, the prompt verification-results block +
  VerificationResultsPresent param; the prompt now teaches STRICT read-only
  (only findings.jsonl). Preserved as regression evidence (WHY reruns were
  removed): bounded-verification.Tests.ps1 (opt-in helper). New suite
  orchestrator-reviewer-integrity.Tests.ps1 (7): no-auto-run + helper never
  auto-invoked, source-mutation fail, authority-mutation fail, findings.jsonl
  allowed, host-dir not-flagged, honest prompt x2. OS-level isolation
  (dedicated process identity + worktree-only ACLs) recorded as a future
  proposal (research/reviewer-os-isolation-future.md), not T015 scope. Net a
  code REDUCTION. Suites 18/18 (helper 11 + integrity 7); registry was 16/16 at that round's digest.
- Serialized confirming review 9e3a44f1 (round 1, post-simplification): 2
  blocking, BOTH real - and neither about the simplification (the review of
  the whole change-set surfaced two pre-existing bugs). (1) FALSE ROUND
  ACCOUNTING (T020/FR-019): the ceiling halt passed the PROSPECTIVE round
  (prior.round+1) to the escalation + persisted it, so a never-invoked halt
  read as "3 review rounds of 2" and state recorded round 3 - but only 2
  rounds actually reviewed. Fixed: the halt now reports/persists
  min(round,maxRounds) (the rounds that ran); the renderer test dropped its
  fixture-owned 3-of-2 assertion and a real two-invocation e2e test proves
  the ceiling reports 2, persists 2, and never invokes a reviewer. (2)
  ORIGIN LEAK IN THE DIFF (FR-009/SC-002): the bundle builder wrote
  .review/changes.diff WITHOUT relativization, so origin-absolute paths in
  CHANGED CONTENT (committed review-evidence / docs referencing the origin)
  leaked file:///C:/Dev... and C:\Dev... into the reviewer bundle - my T014
  "leave the diff untouched" call was wrong. Fixed: the diff is now
  relativized to <project> against both the governance + git roots before
  writing (structure preserved, prefix scrubbed); a new END-TO-END
  origin-path-hygiene test materializes a worktree whose changed content
  embeds the origin path and asserts changes.diff carries zero
  origin-absolute paths. Suites green; registry was 16/16 at that round's digest.
- Co-review 40a06e84 (1 blocking, valid): the digest-bound implementer
  evidence injected for the reviewed tree covered ONLY bounded-verification
  .Tests.ps1 (the opt-in helper the orchestrator never calls); the
  PRODUCTION-PATH suite orchestrator-reviewer-integrity.Tests.ps1 (which
  proves no-auto-verification + reviewer-invocation integrity = the actual
  FR-010 behavior) was claimed 7/7 only in the hand-authored coverage-
  evidence table (zero evidence standing). Fixed: the recorder now records
  BOTH T015 suites (production-path FIRST) as digest-linked runner-observed
  evidence the reviewer reads (the simplified model reads, never re-runs, so
  no budget reason to withhold it); coverage-evidence note corrected (also
  scrubbed the stale "disposable copy / minimal supply" wording the
  simplification removed).
- Serialized review 3b5ae645 (my --live, concurrent with 40a06e84): 2
  DIFFERENT blocking findings, both real containment holes (not about the
  simplification). (1) T013 SYMLINK/JUNCTION ESCAPE (FR-008): the
  outside-origin guard compared LEXICAL paths only, so an EphemeralRoot
  junction whose target is inside origin passed, then materialized the
  worktree physically under origin (restoring the upward-walk). Fixed: the
  guard now resolves real paths via ResolveLinkTarget(final) for both the
  root and the origin roots, AND re-checks the created worktree's resolved
  path; junction-escape regression added (Windows-guarded). (2) HOST-DIR
  EXEMPTION TOO BROAD: Get-...SourceHashes excluded .codex/.claude/.cursor/
  etc. WHOLESALE, so a reviewer could rewrite tracked config there
  undetected. Fixed: those dirs are now HASHED; the exemption is NEW-files
  only (Test-...IsHostChurnPath in the integrity new-file branch) - a
  modified/deleted PRE-EXISTING file under a host dir is tampering. Paired
  test: a new .codex file is churn (done), a rewritten pre-existing
  .claude/settings.json fails (reviewer-tampered-tree). Contract doc
  updated for both. Reviewer suites 29/29.
- Serialized review 8ff8474e: 1 advisory + 1 blocking. ADVISORY (fixed):
  coverage-evidence table still said orchestrator-reviewer-integrity 7/7
  while the file + digest evidence are 8/8 (the host-dir config-modify test)
  - table corrected to 8. BLOCKING (ESCALATED, not auto-resolved): the
  strict design-context resolution for EXPLICITLY-supplied unresolved refs
  (fail-before-reviewer-selection with design-context-unresolved: + status
  unresolved_design_context; only omitted/empty degrades to
  DESIGN_CONTEXT_EMPTY) is ABSENT from the orchestrator (confirmed: line 568
  uses supplied DesignContextFiles as-is, no per-entry validation; no
  unresolved_design_context anywhere). This is the Devin cca79708 behavior
  that T034b carries and is EXPLICITLY at-landing/PENDING (this state's own
  T034a/T034b entries + tasks.md). It is a Devin-SEAM FAIL-CLOSED behavior -
  the maintainer's T034b doctrine says semantic/fail-closed seam conflicts
  ESCALATE, never auto-resolve - and a scheduling call (pull T034b forward
  vs at-landing deferral) the maintainer owns. Surfaced in the stop packet;
  NOT clearing the latch unilaterally. The T015 simplification + all
  containment work reviewed clean; this lone blocker is deferred T034b work.
- Co-review d5511d31 (navigator, concurrent): finding-1 (coverage 7-vs-8)
  was STALE (already fixed in 2bd6085b). finding-2 VALID: T020 is done but
  its suite review-spend-allowance.Tests.ps1 was NOT in the digest-matched
  evidence, so the done/tested claim was prose-only. DURABLE fix: the
  recorder records each iteration-003 done-task suite (T013 containment, T014
  origin-hygiene, T015 production + helper, T020 spend) to the DIGEST-KEYED
  machine record for the recorded tree — the record proves which suites ran for
  its recorded digest. A reviewer gives a suite runner-observed standing ONLY when
  that exact record is injected for the exact reviewed digest; a partial-injection
  review (e.g. the autonomous navigator on its own working-tree digest) is
  DRIFT-198-I003-002 behavior, NOT proof the recorded runs did not occur (no
  universal-injection claim). coverage-evidence.md is a per-task table with the
  runner-reported counts (DRIFT-198-I003-006 truth-alignment). The T034b
  strict-resolution blocker (below) is still the maintainer's open decision.
- STOP-ORDERING DEFECT recorded (maintainer instruction 2026-07-12,
  DRIFT-198-I003-002 → NEW FR-045/GOV-002): this session rendered
  decision/verdict-shaped packets (six-section + numbered options) WHILE
  co-reviews were pending/BLOCKING and before the exact-current-digest
  review was clean/dispositioned - a blocked/superseded packet could then
  be captured as authorization for a never-cleanly-reviewed increment (one
  layer up from the FR-041 fabricated-auth class). Recorded as field
  evidence (research/stop-ordering-defect.md) + FR-045 in spec.md + bound
  to T019 (reviewed-tree-digest acceptance gate + in-flight dedup gates the
  verdict packet) and T030-T032 (capture rejects blocked/superseded
  packets; stop-ordering fixture). Rule: no verdict/boundary packet
  (options + marker) while a required co-review is pending or before the
  exact-current-digest evidence is clean/human-dispositioned; blocked
  attempts yield no options + no marker; mid-review human questions are
  narrow non-boundary decisions. Behavioral correction applied now: the
  T034b item is NO LONGER surfaced as a decision packet while its review is
  unresolved - it stays a recorded open item, dispositioned once the
  current-digest review is clean.
- STOP-ORDERING requirement EXPANDED (maintainer detailed spec 2026-07-12):
  FR-045 + T019/T030-T032 now carry the full behavior - while a required
  co-review for the CURRENT digest is RUNNING, a Stop MUST (1) detect the
  SINGLE tracked in-flight review, (2) block advancement internally, (3)
  implementer WAITS/polls it, NEVER launches a duplicate, (4) optional one
  progress line, (5) never ask the user to nudge/return. Terminal routing:
  clean/current-digest -> six-section packet + marker (the ONLY marker path);
  actionable -> suppress packet+marker, fix+re-review; human judgment ->
  narrow non-boundary question only; timeout/infra -> report specific
  failure, never "clean". Final packet BOUND to the accepted reviewed-tree
  digest. Regression matrix (pending, duplicate-stop, stale completion,
  superseded, actionable, human-escalation, timeout, clean) split across
  T019 (stop-event) + T032 (capture). Full spec:
  research/stop-ordering-defect.md.
- Review counter RESET (maintainer approved 2026-07-12): the ceiling-halt
  (run 8ec02c73, honest "2 of 2" - the round-accounting fix working; 6 items
  cleared, T034b the sole open item) is cleared via the human-approved
  more-time remediation so review can continue.
- T034b strict-resolution INTEGRATED (maintainer direction 2026-07-12: pull
  forward now under the existing authorization). REUSED Devin cca79708
  (DEC-200-I004-006) verbatim - my simplified orchestrator was byte-identical
  to its pre-image at the design-context-resolution phase, so it applied
  mechanically: explicitly-supplied design-context refs are ALL validated at
  resolution time; ANY unresolved explicit ref FAILS the run BEFORE reviewer
  selection with failure_reason 'design-context-unresolved: ...' listing every
  unresolved ref (status carries unresolved_design_context[]); only
  omitted/empty keeps the DESIGN_CONTEXT_EMPTY degrade - never softened to a
  warn. Paired 7f/7g mirrored as Pester in review-context-and-harvest-
  hardening.Tests.ps1: MIXED valid+invalid FAILS (reviewer never invoked),
  ALL-invalid FAILS (reviewer never invoked), OMITTED degrades (not a
  strict-fail). Focused suite 14/14; F-198 registry was 16/16 at that round's digest. This closes the
  8ff8474e/9e3a44f1 strict-resolution blocker. T034b's remaining part (final
  live Devin compat review) stays at-landing.
- The one review (run 13a8f2bd, per the maintainer's launch-one-and-wait
  instruction) RAN and found 1 blocking - a REAL hole in the reused cca79708
  code: the strict check used Test-Path(Join-Path RepoRoot ref) WITHOUT
  canonicalizing + proving containment, so a ../ TRAVERSAL ref to an existing
  file OUTSIDE the project passed, then materialization would copy that
  ambient host content into .review/design. Fixed per the FR-045
  actionable-findings route (fix + re-review, no packet): the check now
  rejects ROOTED inputs, normalizes .. via GetFullPath, resolves links, and
  requires the real path UNDER the canonical repo root. Paired tests added:
  ../ traversal to an outside file REJECTED (reviewer never invoked), rooted
  absolute REJECTED, valid in-repo ref still PASSES (reviewer invoked). NOTE
  for the Devin crew: cca79708 upstream has this same traversal hole. Focused
  suite 17/17; registry was 16/16 at that round's digest.
- Re-review 44760c20 (final round, human-decision-framed): the traversal fix
  was INCOMPLETE - it resolved only the FINAL file component, so an
  INTERMEDIATE in-repo directory junction/symlink to an outside dir still
  passed (ResolveLinkTarget is null on the non-link final file; FullName kept
  the lexical in-repo alias). Real. Maintainer chose FIX (component-wise
  physical containment). Implemented ONE shared canonicalizer
  Get-ContinuousCoReviewPhysicalPath (worktree-reviewer.ps1): resolves EVERY
  existing component (intermediate links followed), fail-closed on an
  unresolvable existing component, lexical for not-yet-existing trailing
  components. BOTH T013 (outside-origin guard) and the strict design-context
  validation now use this ONE helper (semantics cannot drift). Policy: an
  in-scope link whose physical target stays under the boundary PASSES; only
  outside targets are rejected. Tests: intermediate-dir-junction-to-outside
  design ref REJECTED (reviewer never invoked); shared-helper direct tests
  (intermediate junction resolves to real outside target; in-scope junction
  stays under root; plain path normalizes); the existing T013 junction +
  traversal + rooted + valid tests still green. Suites 25/25; registry was 16/16 at that round's digest.
- Re-review round after the containment fix hit a transient reviewer-HOST
  infra failure first (run ecd4c7b8: codex empty-exit0 x2, T108 retry
  exhausted -> no-parseable-findings-json, invoked-failed per T020 - NOT a
  clean review, NOT a code finding; the FR-045 infra-failure route). The
  FR-045 retry (one sequential re-run, not a duplicate) then RAN (run
  ea521faf) and found 1 blocking: an EVIDENCE gap - the intermediate-junction
  INTEGRATION proof lives in review-context-and-harvest-hardening.Tests.ps1
  (18/18), which was NOT in the digest-matched evidence, so the 25/25 claim
  had no standing for that suite. Durable fix: the recorder now records that
  integration suite too (6 suites digest-bound); coverage-evidence.md gains a
  T034b row. Launching exactly one serialized re-review.
- Codex-host availability check (maintainer-requested): codex-cli 0.144.1 IS
  available - proven with a live `codex exec` probe (from a throwaway temp
  dir, never the governed cwd per probe hygiene) that answered "C# 15 / .NET
  11", exit 0. Catch: codex exec HANGS with an open stdin pipe (waits for EOF
  even with a prompt arg); the engine already closes codex stdin
  (worktree-reviewer.ps1:1064), so the empty-exit0 co-review failures are
  codex's intermittent ~50% empty-output flakiness (the T108 retry class),
  not a stdin bug or an outage. Maintainer chose: retry the co-review.
- Re-review 40365de9 (codex landed a real run on retry): 1 blocking, REAL and
  subtle - the containment comparison used OrdinalIgnoreCase UNCONDITIONALLY,
  so on a CASE-SENSITIVE POSIX filesystem a case-distinct sibling (repo
  /x/Repo, sibling /x/repo/secret.md) bypassed the check in BOTH the
  design-context gate and the T013 guard. Fixed: a SHARED containment
  predicate Test-ContinuousCoReviewPathUnderRoot (resolves both sides via the
  shared physical-path helper, compares with PLATFORM-APPROPRIATE case -
  OrdinalIgnoreCase on Windows, Ordinal on POSIX); both T013 and the strict
  design-context gate now call it (case + resolution semantics cannot drift).
  Tests: platform-aware predicate test (Windows: case-variant under root;
  POSIX: case-distinct sibling NOT under root) + a POSIX end-to-end
  design-context case-distinct-sibling REJECTION (reviewer never invoked;
  skipped on case-insensitive Windows). Suites 26/26 (1 POSIX-only skip on
  Windows); registry was 16/16 at that round's digest. Launching exactly one serialized re-review.
- CODEX empty-exit0 ROOT CAUSE (maintainer-directed deep-dive): the reviewer
  subprocess INHERITED the environment, so codex-the-reviewer's OWN global
  Specrew hooks (~/.codex/hooks.json -> specrew-hook-launch.ps1, HostKind
  codex) fired while it reviewed - and the codex STOP hook is a DECISION-BLOCK
  that runs the Specrew dispatcher against the extracted specs/ in the reviewer
  worktree, derailing codex into empty output. The launcher has a documented
  kill switch (SPECREW_REFOCUS_DISABLE) but the engine NEVER set it for the
  reviewer spawn (grep: 0 matches). Diagnosis proven: a bare-temp-dir codex
  exec probe worked (no governance context); the worktree runs (governance
  context) intermittently failed. FIX: the reviewer spawn
  (Invoke-ContinuousCoReviewAgentInWorktree) now sets
  $psi.Environment['SPECREW_REFOCUS_DISABLE']='1', inherited by codex + its
  hook children, so a reviewer can never trigger governance on itself.
- CODEX empty-exit0 SECOND CAUSE + FIX (maintainer 2-step verification,
  2026-07-12). Step 1 (commit 983ae3e7): deterministic regression proving the
  reviewer launch path passes SPECREW_REFOCUS_DISABLE=1 and the dispatcher exits
  before governance when it inherits it. Step 2 (three sequential + one preserved
  codex probe via the exact launch path): empty-exit0-by-stdout PERSISTS, but
  .review/findings.jsonl is PRESENT + VALID every time (finalization-or-capture-
  gap, NOT the hook vector's no-output-produced). PROVEN second cause: codex
  DELIVERS its review to .review/findings.jsonl (per the slim prompt) and exits 0
  with EMPTY stdout; the engine's stdout-primary assumption then misfired - a
  wasteful T108 retry, a 'partial' completeness mislabel, and a failure-looking
  WARN - even though the orchestrator harvest still recovered the findings (the
  co-review was FUNCTIONAL, just wasteful + mislabeled). CODEX_HOME NOT changed.
- FIX (file-primary result, maintainer option-1 w/ strict qualification): a CLEAN
  reviewer exit (0, not timed out) + EMPTY stdout + a current-run, every-line-
  parses, fully contract-validated .review/findings.jsonl = a COMPLETE result
  (completeness='full', result_source=file-primary) - NO retry, NO WARN. STRICT +
  fail-closed (malformed/truncated/stale/mismatched-run/absent/empty falls back to
  the retry/harvest/partial path); a zero-finding verdict must arrive via stdout
  (file-only delivery cannot prove no_findings); stdout-primary hosts (claude)
  unchanged. New suites reviewer-file-primary-result (10) + reviewer-hook-
  suppression (4); F-198 registry was 18/18 at commit 08d97fa0 (the registry
  META-run became digest-recorded evidence only from 36cbb73a - see the closing
  AUTHORITATIVE note).
- END-TO-END VALIDATION (serialized codex co-review of digest 1173e1ab, run
  20260712T112120158): the fix WORKS - result_source=file-primary,
  completeness=full, T108_retried=false, reviewer-execution=103.9s (codex really
  ran), implementer_evidence=true, independent, current-run identity confirmed.
  A pre-fix ceiling latch (round 2, blocking, from the empty-exit0 failed-
  invocation saga) first ceiling-halted a run; cleared via the AUDITABLE
  `resolved-against-disk` remediation (--fix-evidence-ref 08d97fa0, ancestor
  verified, 12 dispositions preserved), NOT a delete.
- codex f1 (blocking, verification-environment-contamination): SPECREW_REFOCUS_
  DISABLE=1 on the reviewer process is inherited by children, so a reviewer-
  launched governance test could false-green. FIX (maintainer option-1 strict
  bounded contract): the engine-owned bounded-verification helper now EXPLICITLY
  REMOVES SPECREW_REFOCUS_DISABLE from each verification child (the ONLY supported
  governance-sensitive path); paired test proves the reviewer host inherits
  suppression while a bounded-verification child does NOT + reaches governance;
  the prompt tells the reviewer to report a governance check not in evidence as
  UNVERIFIABLE (never self-run / self-mutate env); reviewer-spawn-contract.md
  records this as a BOUNDED contract (supported=bounded helper; unsupported=
  arbitrary reviewer child inherits suppression BY DESIGN to prevent recursive
  governance; general scoping = future OS-isolation), NOT complete isolation.
- codex f1 ROUND-2 ESCALATION (autonomous co-review of the fix): the first paired
  test used a fixture-owned Boolean env-PROXY, never launching the REAL dispatcher
  - so it proved the var was cleared but not that governance is actually reached.
  Maintainer required the real-dispatcher proof. RESOLVED: EXTRACTED the existing
  governed fixture from tests/integration/refocus-dispatcher.tests.ps1 into a
  shared refocus-dispatcher-fixture.ps1 (no second substitute fixture), and
  rewrote hook-suppression test 3 as a governed-fixture PAIR under
  SPECREW_REFOCUS_DISABLE=1: (A) the reviewer host's OWN hook inherits suppression
  -> the governed dispatcher emits NO '[specrew-refocus] trigger=b1' marker; (B) a
  bounded-verification child clears the var, reaches the REAL dispatcher in the
  SAME fixture, and governance PRODUCES the marker (asserts exit, marker
  presence/absence, child env). Empirically: governance fails-open SILENTLY in a
  bare dir (byte-identical to the kill-switch no-op), which is why the governed
  fixture is required for a positive marker. Dispatcher + hook-suppression suites
  green.
- SERIALIZED review of digest e02d3243 (run 20260712T124441759) VALIDATED the fix
  again (file-primary, full, no retry, current-run) and codex raised 2 new blocking
  findings on INCREMENT HYGIENE (not the feature code): f1 test-evidence-honesty -
  coverage/state claimed 'F-198 registry 18/18 green' but the digest record held no
  execution of the registry META-run nor refocus-dispatcher.tests.ps1; f2
  unplanned-generated-artifacts - 6 gitignored *.pending scaffolder byproducts from
  completed iteration 001 appeared in the reviewed increment. FIX (maintainer
  option-1 + T017 disposition): (f1) the evidence recorder now ALSO records the
  f198-regression-suite + refocus-dispatcher script-suites digest-bound (exit +
  PASS-count), and coverage-evidence.md states their runner-observed standing; (f2)
  deleted the 6 stale iteration-001 .pending files; (T017 interim) excluded the SIX
  named review-closeout scaffolder artifacts under specs/*/iterations/*/ (code-map,
  coverage-evidence, dashboard, dependency-report, review-diagrams, reviewer-index
  .md.pending) from the digest inclusion denylist
  (Get-ContinuousCoReviewSecretAmbientDenylist) - excluded from the digest identity
  AND the reviewer worktree (materialized from the digest tree).
- CORRECTION (co-review f1 digest-false-allow, run 20260712T154540412): my FIRST
  T017 cut used a GLOBAL `*.pending` rule and I wrongly described it as narrow. It
  was NOT narrow - it would have dropped a genuine ignored SOURCE file (e.g.
  src/schema.pending) from the digest, the exact false-allow the force-add-ignored-
  source design prevents. FIXED to the six PATH-AND-NAME-specific patterns above;
  paired tests now prove the six scaffold artifacts are excluded, src/schema.pending
  still flips the digest, an unlisted specs/.../iterations/.../custom.md.pending
  stays IN, and other ignored source stays reviewable. Consolidation into ONE
  digest/worktree machinery data file remains the planned T017 task (not pulled
  ahead of T016).
- CURRENT AUTHORITATIVE registry evidence (evidence-honesty cleanup, maintainer-
  directed 2026-07-12): the F-198 registry whole-run (18/18, exit 0) AND the
  refocus-dispatcher suite are recorded as DIGEST-LINKED runner-observed evidence
  (runner exit + PASS-line count) at the current cleanup digest - NOT a prose
  claim. The per-round "registry was N/N at that round's digest" figures ABOVE are
  explicitly TIME-BOUND historical snapshots (the registry grew 16 -> 18 over
  iteration 003); they are not current-tree closure claims. NEXT: commit, re-record
  evidence, remediate against the commit, one serialized review of the cleanup
  digest (Copilot fallback if codex returns another true empty result).
- T018 DONE (FR-014/FR-015 amended 2026-07-13, language/framework-NEUTRAL): the
  universal recorded-run runner Invoke-ContinuousCoReviewRecordedRun records ONLY
  directly-observed process facts (exe/args/cwd, exact reviewed-tree digest,
  start/end/duration, exit + timeout, bounded/redacted stdout/stderr metadata,
  output-artifact digests, command_succeeded); RICH counts come ONLY from a
  run-produced, schema-valid SpecrewTestResult bound to the same digest (caller
  counts FORBIDDEN; requested-but-missing/malformed/stale/invalid FAILS LOUD; exit
  0 = command_succeeded, never "all passed"). No framework parsers; Pester is a
  DEMONSTRATION producer only. 10/10 focused (recorded-run.Tests.ps1) + full
  19-suite F-198 registry green; dogfooded on a real Pester command
  (framework-neutral facts + SpecrewTestResult passed=2/failed=0/skipped=1).
  Refocus FR-014 runner-observed-evidence floor added to review-signoff.md.
  EVIDENCE-ONLY for the exact digest — scheduling, injection, cross-digest
  collisions, stale results, and lineage stay T019.
- PROPOSAL 205 AMENDMENT carried into F-198 (maintainer 2026-07-13, strict scope
  separation; merged main 1210d4e7): W10 (generic contract before adapters)
  realized HERE by FR-015/T018; W7–W9 (applicability provenance —
  project-detected/profile-selected/provider-gated/example-only; the
  stack-assumption/delivery-assumption deny-list classes; heterogeneous
  Python/non-Pester, non-GitHub, no-release fixtures) recorded as FR-046/FR-047,
  owned by Iteration 004 T028 (SP 0.5->2.0 provisional, pending 004 design
  calibration), composing with T021-T023 + T027. T004-T006 NOT reopened.
  DRIFT-198-I003-007 records the provenance; retention/cleanup + exact-digest
  artifact ownership carried to T019 alongside DRIFT-002.
- T019 CHARACTERIZATION/CONTRACT slice (maintainer-directed 2026-07-13: characterization + contract
  work BEFORE runtime behavior; return before step 6). Grounded in a full file:line recon of the live
  fire path (worktree-navigator -> co-review-service -> detached-entry -> orchestrator; digest,
  evidence, run-index, blackboard, gate). Deliverables: (1) the FIVE identities defined — baseline
  (FR-016 last-reviewed vs the shipped merge-base diff baseline), reviewed digest (unify three key
  spellings + stamp into EVERY surface incl. findings, FR-017), evidence digest (exact-match-only
  injection, DRIFT-002), run lineage (<=1 in-flight per lineage + out-of-order supersession),
  per-finding identity (bind to reviewed tree AND baseline); (2) the FIVE artifact-lifecycle classes
  (transient/durable/superseded/archived/prunable) mapped to every on-disk family; (3-5) fixtures for
  DRIFT-002 digest-A-vs-B, in-flight dedup + out-of-order completion, and the FR-045 8-state
  Stop-ordering matrix. Realized as PURE UNWIRED contract functions (review-identity-contracts.ps1 —
  deliberately NOT in _load.ps1) + t019-identity-contracts.Tests.ps1 (14/14) + data-model entities +
  iterations/003/research/t019-review-identity-and-artifact-lifecycle.md. Pinned load-bearing GAPS for
  step 6: registry key drift (live path writes tree_id + reviewed_digest_tree_id but the T019a stale
  downgrade reads the never-written reviewed_tree_id, so stale blocks recur); NO in-flight gate on the
  verdict-packet path (FR-045 hole); evidence lookup is suites-only (ignores T018 runs records);
  findings-result carries no in-schema tree/baseline. Step 6 (wire the contracts + retention runtime)
  NOT started.

## Notes

- Update this file after each task completes.
- Keep task identifiers aligned to plan.md.
