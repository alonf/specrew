# Iteration Plan: 010

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: planning
**Capacity**: 17/20 story_points
**Started**: 2026-07-30
**Completed**:
**Planning Baseline**: `3c4f2496`

## Human Authorization

Approved for plan with instructions, 2026-07-30. The maintainer approved the split exactly
as proposed and confirmed the round cap. The standing Beta2 bug-bash grant (Iterations
009–013, approved 2026-07-26) covers autonomous fix, deterministic test, and
independent-review correction cycles. It does not authorize a merge, tag, publication, or
paid-provider action outside an existing grant.

Carried instructions, binding on this iteration:

1. Iteration 010 is **stream A only**. Stream B defers to Iteration 011 in full.
2. **Review round cap: 3.** Iteration 009 spent eight.
3. Beta2 follows **course 2** — narrow to the consumer-blocking subset, tag after Iteration
   011, updating `beta2-release-claim.md` at each closeout.
4. This plan MUST state which claim limitations it removes, so the claim is updated at
   closeout rather than reconstructed later. See `## Release-Claim Impact`.

## Objective

Close the path-identity/containment cluster deferred from Iteration 009 — and close it with
test evidence that could have caught it, which Iteration 009's did not. The differential
harness proved the primitive's answers on three real volumes and still missed
DRIFT-198-I009-042, because its fixtures contained no link states. Fixtures that span the
state space are therefore the first deliverable, not the last.

## Scope Summary

Stream A only: DRIFT-198-I009-041, -042, -043, plus limitation 3 of the narrowed release
claim (the harness's missing link-state fixtures), which is the reason -042 was invisible
to CI.

**Explicitly NOT in this iteration** — deferred to Iteration 011 in full, named:

| Deferred item | Description (maintainer's session ledger) |
| --- | --- |
| F11 | premature verdict demand + contradictory hook composition |
| F1 | first-boundary arrival sync |
| F4 / F4b | pre-iteration window + lost exception text |
| F5 / F9 (narrow) | as originally scoped |

### Why the split, on measured evidence

Both streams were independently sized at ~20 SP; together they are 40 against a cap of 20.
The stronger argument is Iteration 009's own calibration data: its base work landed exactly
on estimate (T072–T078, 19.5 planned / 19.5 delivered) while its correction cycles consumed
roughly 50 SP across eight review rounds. Stream A is the same kind of work — reviewer-driven
correction of a class that has already recurred four times. Pairing it with stream B would
repeat precisely the mistake Iteration 009 recorded as its transferable lesson.

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T080 | Link-state fixtures for the volume-differential harness, proven RED first | FR-008 | Containment coverage | 6.0 | Implementer | tests/continuous-co-review/unit/path-identity-volume-differential.Tests.ps1 | planned | — | — | — |
| T081 | Mutation gate for link containment; prove it fails against a link-blind primitive | FR-008 | Falsifiability | 2.0 | Implementer | tests/continuous-co-review/unit/review-authority-store-mutation-gate.Tests.ps1 | done | Implementer | 2.0 | **Re-targeted after T083's withdrawal** — see Notes. CONTROL 0 failed against the real store; mutant (lexical-only, pre-T082 shape) failed the reparse-point fixtures. Positive-verified: the mutant genuinely accepts a linked root (measured `ACCEPTED`) before the fixtures are run against it |
| T082 | DRIFT-198-I009-041 — authority-store containment against reparse points | FR-008 | Evidence-chain integrity | 5.0 | Implementer | scripts/internal/continuous-co-review/review-authority-store.ps1, tests/continuous-co-review/unit/review-authority-store.Tests.ps1 | done | Implementer | 5.0 | RED 3/15 pre-fix (root/campaign/run link fixtures) via git-checkout A/B; GREEN 15/15 post-fix incl. an ordinary-path sanity control |
| T083 | ~~DRIFT-198-I009-042 — link-aware directory-entry lookup in the case probe~~ | FR-008 | Path identity | 0.0 | Implementer | — | deferred | — | 0.0 | **WITHDRAWN 2026-07-31 — no reachable defect.** T080 measured the finding's premise on all three volumes and it does not hold; -042 is re-dispositioned NOT REPRODUCIBLE AS REPORTED (DRIFT-198-I010-002). Its 3.0 SP returns to SLACK and is deliberately NOT backfilled |
| T084 | DRIFT-198-I009-043 — case-distinct consumer-firewall fixture | FR-046 | Applicability firewall | 1.5 | Implementer | tests/unit/consumer-applicability-firewall.tests.ps1 | done | Implementer | 1.5 | logic-level A/B: old Sort-Object dedup drops 1 of 2 synthetic case-distinct entries, new Ordinal HashSet keeps both; real-fixture measurement deferred to ubuntu/ext4 leg, reported not skipped where the volume folds case |
| T085 | Integrated verification and capped certification | FR-008, FR-046 | Release confidence | 2.5 | Reviewer | tests/**, specs/198-beta2-hardening/iterations/010/** | in-progress | Reviewer | — | pre-certification evidence recorded (registry/bootstrap/lint green; three-volume matrix measurements read directly, macOS still catches the os-family mutant); certifying review requested |

**Total planned: 17.0 SP against a capacity of 20, with 3.0 SP of SLACK.**

Originally 20.0/20. T083 was withdrawn on 2026-07-31 when T080's measurement showed
DRIFT-198-I009-042 has no reachable defect, and the maintainer directed its 3.0 SP to **slack
rather than backfill**: *"That headroom is exactly what 009 never had."* Iteration 009 planned
24.5 against a cap of 20 and delivered ~70; entering an iteration at cap with zero absorption
is what made every subsequent finding an overrun. The headroom is the correction, and filling
it with new scope would undo it.

The correction allowance for rework remains inside T085 rather than pretending rework is free.

### T080 precedes T082 and T083 — this is the finding, not a preference

DRIFT-198-I009-042 survived a green three-volume matrix because the harness had zero
symlink, dangling-link, or reparse-point fixtures. A fixture authored after the fix, which
passes on first run, proves nothing about whether it would have caught the defect. Each
fixture in T080 MUST be demonstrated RED against current `HEAD` before the corresponding
correction lands, and the RED output recorded in the drift log.

Fixture set (minimum):

- symlink to an existing target, inside the tree
- **dangling** symlink — the DRIFT-198-I009-042 case exactly
- Windows junction / reparse point
- link AT the authority-store root
- link at a campaign ancestor and at a run ancestor
- case-distinct pair where one member is a link

## Method — carried forward from Iteration 009, binding

These are constraints on how the work is done, not advice.

1. **Test first, and prove the test can fail.** See T080 above. A fixture that passes before
   the fix is not evidence.
2. **The volume remains the oracle.** No authored expectations for link behaviour — measure
   what the OS actually does on each runner and assert the primitive against that
   measurement. Where a runner cannot materialize a fixture, that failure IS the measurement.
3. **Push per focused commit, and check the previous push's CI before starting the next
   cycle.** Check every workflow individually, not one of them. A red workflow is a stop.
   Iteration 009 reported a matrix "green on all three volumes" while `Specrew CI` for the
   same commit was failing.
4. **Evidence before hypothesis, and verify the evidence tool.** `gh run view --log`
   truncates; read untruncated logs via `gh api repos/<owner>/<repo>/actions/jobs/<id>/logs`.
   Two sessions were lost to that truncation. Equally: do not pipe a diagnostic run through
   `Select-String`/`Select-Object -First` and then trust the exit code — that produced a
   false `exit=0` and two wasted cycles in 009.
5. **Scoped validator during work, full validator before commit.**
   `validate-governance.ps1 -IterationPath specs/198-beta2-hardening/iterations/010` costs
   ~11s; the unscoped run costs ~440s.
6. **Never edit the tree while a registry or review run is in flight.** The caller-isolation
   guard will correctly fail the run, and the failure looks like a regression.

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 20 | Configured value, restored from the F197 override in `b3e2960e`. |
| Iteration Bounding | scope | Matches `iteration-config.yml`, which offers only `scope` or `time`. **This value is NOT the real bound for this iteration** — see the note below and DRIFT-198-I010-001. |
| Time Limit (hours) | n/a | Bounded by review rounds, not time. |
| Overcommit Threshold | 1.0 | No overcommit allowed. |
| Defer Strategy | manual | No approved finding is silently dropped. |
| Calibration Enabled | true | Retro records engineering and verification variance. |

## Certification and the Termination Rule

Agreed in advance, as in Iteration 009.

**Evidence that certifies Iteration 010:**

1. Every T080 link-state fixture demonstrated RED against pre-fix `HEAD`, then GREEN after.
2. The mutation gate extended to link states and proven able to fail against a link-blind
   primitive.
3. The three-volume matrix green, with `[volume-oracle]` measurements read directly out of
   each job log — not inferred from a green conclusion.
4. Registry, bootstrap suites, and markdownlint green, run as the workflows run them.
5. **One** certifying review.

**Round cap: 3.**

**Termination rule:** if a certifying round reports a new **blocking or major** finding of a
class already corrected in this iteration — containment or path-identity — stop. Bring the
maintainer the narrowed-claim update rather than starting another fix round. **Note-severity
findings are recorded residuals and do not block certification.**

## Release-Claim Impact

Which limitations in
file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/beta2-release-claim.md this
iteration removes. Recorded here so the claim is UPDATED at closeout rather than
reconstructed from memory.

| # | Limitation | Disposition after Iteration 010 |
| --- | --- | --- |
| 1 | Authority-store containment unproven against reparse points | **REMOVED** by T082 |
| 2 | ~~Case probe returns the wrong answer for a dangling link~~ | **WITHDRAWN — not reproducible.** Not removed by a fix; removed because measurement showed no such defect exists (DRIFT-198-I010-002). T083 withdrawn |
| 3 | The differential harness covers no link states | **REMOVED** by T080/T081 |
| 4 | Consumer applicability firewall's case-distinct behaviour unproven | **REMOVED** by T084 |
| 5 | Structural enforcement is textual, not syntactic (AST) | remains — scheduled replan task |
| 6 | A declared reviewer model is recorded, not enforced at invocation | remains — DRIFT-198-I009-007 |
| 7 | A freshly rediscovered human-deferred finding cannot be recorded as deferred | remains — Iteration 012 cluster |

Four of seven removed. The threat-model paragraph and the "who is affected" table both need
revision at closeout, because limitations 1–3 are what make checkout-borne links reachable.

## Beta2 Course — course 2, with the maintainer's classification

The maintainer supplied the consumer-reachability classification the Crew lacked. The
F-labels were the reviewer's **session-local ledger from the consumer manual test**; treat
this as their authoritative source until the register lands in the spec.

| Class | Items | Disposition |
| --- | --- | --- |
| Already delivered in 009 | F6, F12, F13, F15, F16 | done |
| **Consumer-severe, must precede the tag** | **F11** premature verdict demand (risks false human authorization), **F10** round-ceiling tax (hits every consumer whose lifecycle produces findings at 2+ checkpoints), **F17** non-convergent finality (this is what stopped the maintainer's manual test), **F1** first-boundary sync/marker (hits every new project at its very first boundary) | **Iteration 011** |
| Cheap and consumer-visible, include if capacity allows | F2 workshop schema drift, F9 verdict-phrase inconsistency, F7 draft-checkpoint placeholders flagged blocking | Iteration 011 stretch |
| Beta3 | F3, F4/F4b, F5, F8, F14 | after the tag |

**Tag beta2 after Iteration 011.** Two iterations to a tag — not six, and not one.

The decisive evidence is the maintainer's own consumer manual test: F10, F17 and F11 are
exactly what prevented it from converging — five hygiene escalations, ceiling halts on every
run, and a hook demanding a verdict for a stage with no evidence. Tagging without them means
every beta consumer relives that session, and the feedback that returns is feedback already
in hand.

Note the correction this forces to Iteration 011's shape: stream B as deferred here is F11,
F1, F4/F4b, F5/F9 — but F4/F4b and F5 are **beta3** under this classification, while **F10
and F17 are new to 011 and are consumer-severe**. Iteration 011's planning boundary must
re-cut stream B against this classification rather than inheriting it verbatim.

## Obligations Carried Into This Iteration

- **Iteration 009 closure.** Iteration 009 is held at `reviewing` with a recorded closure
  trigger in
  file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/iterations/009/state.md.
  When T082/T083/T084 actually land, close 009 per that trigger: T079 verdict `pass` with
  Notes citing Iteration 010 as the delivering vehicle, promote `retro-draft.md` to
  `retro.md`, advance status. **Do not close 009 before the corrections land** — the whole
  point of holding it open was refusing to assert a satisfied requirement that was not.
- **F-register, before Iteration 011 opens.** The F-labels resolve to nothing in the
  repository. Land the register into
  file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/spec.md or a findings
  artifact under the feature — and **check whether F-items already map to existing FRs
  before minting new ones** (the spec defines **FR-001..FR-065**; FR-046 already covers the
  consumer applicability firewall). Correction for the record: the plan packet presented at
  this boundary said FR-001..FR-040, which was wrong — that is where the Traceability Map
  ends, not the requirement register.

## Traceability Summary

- Requirement scope: FR-008 (reviewer containment), FR-046 (consumer applicability firewall).
- Deferred drift entries realized here: DRIFT-198-I009-041, -042, -043.
- Release-claim limitations removed: 1, 2, 3, 4 of seven.
- Traceability caveat: the F-label register is not in the repository; see the obligation above.

## Notes

- **Capacity, restated after T083's withdrawal and the priority DRIFT-198-I010-003 fix.**
  Originally 20/20 at cap by design. T083 (DRIFT-198-I009-042) was withdrawn when T080's own
  fixtures measured its premise not reproducible on any volume — freeing 3.0 SP to SLACK,
  deliberately not backfilled with new scope ("that headroom is exactly what 009 never had").
  The maintainer then explicitly overrode that guardrail to spend part of the slack on
  DRIFT-198-I010-003 (~1.5-2 SP, the material-work Stop-packet over-fire) — a days-old
  irritant fixed now rather than deferred, with the override recorded in the drift log. Net:
  roughly 20 - 3 (T083) + 1.5-2 (I010-003) ≈ 18.5-19 SP against 20, still under cap.
- **T081 was re-targeted, not silently reinterpreted.** Originally scoped to extend
  `path-identity-mutation-gate.Tests.ps1` — the file that mutates the CASE-SENSITIVITY
  primitive — for link states. That target no longer exists once T083 was withdrawn: there is
  no case-probe link defect to guard, and per the maintainer's instruction a link-aware lookup
  "as defence in depth" is explicitly NOT to be built or mutation-tested absent a real defect.
  The one link-state correction that DID survive is T082 (authority-store containment), which
  lives in a different file entirely. T081 was re-targeted there:
  `review-authority-store-mutation-gate.Tests.ps1`, mutating
  `Get-ReviewAuthorityStorePath` back to its pre-T082 lexical-only shape and requiring the T082
  fixtures to fail against it — the permanent form of the git-checkout A/B done once by hand
  during T082.
- **The effort model records `scope` bounding, and that is not what actually bounds this
  iteration.** Iteration 009's single most transferable lesson is that a scope-bounded
  review-correction iteration is not bounded at all — "the approved finding cluster is
  fixed" does not bound anything when each fix reveals the next defect. The real bound here
  is the **3-round cap** in `## Certification and the Termination Rule`. The schema cannot
  express it: `iteration-config.yml` offers only `scope` or `time`, and the validator
  requires the plan's value to match the config. Recorded as DRIFT-198-I010-001 rather than
  worked around by setting a value the config does not support. Until the vocabulary exists,
  the termination rule is the binding constraint and the Effort Model line is bookkeeping.
