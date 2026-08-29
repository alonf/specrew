# Retrospective: Iteration 001

**Schema**: v1
**Date**: 2026-08-29

Written from the drift log, the verdict ledger, the review record and the commit history - not from
memory. The iteration ran 2026-08-10 (specify approved 00:46Z) to 2026-08-27 (review-signoff
approved 11:00Z), with two post-signoff maintainer-instructed fixes (W76, W77) landing through
2026-08-28. 316 commits, 33 authorized review rounds, repair wedges W1 through W77, 153 drift
entries.

## Estimation Accuracy

Per-task effort was not time-tracked; the `tasks-progress.yml` timestamps are batch stamps written
at landing, not effort. The honest per-task measure available is when the task landed and how many
follow-on commits named it afterwards (rework proxy). The real variance lives at phase level below.

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| T001 | 3 | landed 2026-08-10; 10 follow-on commits | within estimate at landing |
| T002 | 1 | landed 2026-08-10; 1 follow-on commit | within estimate |
| T003 | 1 | landed 2026-08-10; 11 follow-on commits | within estimate at landing; reworked in round 5 |
| T004 | 1.5 | landed 2026-08-10; 13 follow-on commits | within estimate at landing; capture contract reworked through W45 |
| T005 | 0.5 | landed 2026-08-10; 4 follow-on commits | within estimate |
| T006 | 1.75 | landed 2026-08-10; 20 follow-on commits | within estimate at landing; refusal messages reworked repeatedly |
| T007 | 1 | landed 2026-08-10; 22 follow-on commits | under-estimated: named errors and init bootstrap kept surfacing |
| T008 | 0.5 | landed 2026-08-11; 30 follow-on commits | most under-estimated task: spend accounting touched every pause change |
| T009 | 0.5 | landed 2026-08-10; 3 follow-on commits | within estimate |
| T010 | 1.75 | landed 2026-08-11; 21 follow-on commits | within estimate at landing; the consumer-language pass kept finding surfaces |
| T011 | 0.25 | landed 2026-08-10; 2 follow-on commits | within estimate |
| T012 | 0.25 | landed 2026-08-11; 11 follow-on commits | records kept moving with every wedge |
| T013 | 0.1 | landed 2026-08-10; 4 follow-on commits | within estimate |

**Average variance**: at landing, roughly zero - all 13 tasks landed inside two days against a
13.1 SP envelope. After landing, the follow-on commit counts (152 across the 13 tasks) say the
estimate covered the first version of each task and none of the versions review produced.

## Phase Variance

| Phase | Estimated | Actual | Delta | Notes |
| ----- | --------- | ------ | ----- | ----- |
| Planning | 1 | ~7 hours on 2026-08-10 (four verdicts, specify through before-implement) | on estimate | Each verdict carried a recorded instruction; the ledger explains itself. |
| Discovery/Spikes | 0 | three ratified exception commits before before-implement | small, ratified | Activation-premise repair, run-id minter, verification plan - each ruled in scope individually. |
| Implementation | 13.1 | 2026-08-10 to 2026-08-11 | on estimate | The tasks were the easy part. |
| Review | 2 | 33 authorized rounds, 2026-08-10 to 2026-08-27, plus two live dogfood walks | roughly eight times the implementation phase by calendar | Review was not a verification step; it was the discovery engine for the engine's own defects. |
| Rework | 1.5 | W1 through W77, 152 drift entries, ~300 commits | the dominant cost of the iteration | Eleven-plus inert controls, three composition defects, three architectural models proven wrong before code was built on them. |

Systemic bias, recorded rather than explained away: the plan priced review and rework as 3.5 SP of
checking on 13.1 SP of building. For a stabilization iteration on a governance engine, review IS
the building - most of what shipped was found by review, not planned into it.

## Drift Summary

- Total drift events: 153 headed entries under 151 distinct identifiers (DRIFT-199-I001-001
  through -152; 005 and 024 each carry two entries, 036 was never used). The log's own summary
  line said 78 until this retro corrected it - a count claim that drifted from its artifact, in
  the file whose job is to record drift.
- Marked resolved in their heading: 132. Open under a recorded maintainer ruling: 6. Deferred: 2.
  The remainder carry other dispositions (records-only, delivered, overturned) in their headings.
- Resolved via spec update: none - the spec held; the events are defect and process records.
- Resolved via revert: none as a category; two fixes were withdrawn and replaced on evidence
  (W69/W70 turn identity, the W38 retraction overturned in DRIFT-139).
- Escalated to human decision: every boundary and every campaign pause; six verdicts, each with
  its rationale in the ledger.
- Beta4 notes carried in the log: five, including the instruction-layer finding recorded at this
  retro.

## What Went Well

- The gates caught real things: unauthorized product code, a machinery-forged approval, a review
  claiming coverage it lacked, a password-handling fail-open, a spec written before its workshop,
  and three architectural models proven wrong before code was built on them. Strictness earned its
  place.
- Mutation proving became the standard mid-iteration and stayed: after the `if ($false)` incident
  (a test asserting a call existed while a guard left it green), every fix carried a mutation that
  turned its own case red.
- Two live dogfood walks (KeyContextAI, HelloWinUIReactive) found what 33 review rounds could
  not: the crossing ladder, the published-remote demand, the JSON-shaped lens record, the
  placeholder spec. Field walks are a review modality, not a demo.
- The record held. The drift log carried the iteration's memory across sessions and hosts; the
  verdict ledger explained every crossing without cross-referencing; the crossing-ladder forgery
  was caught by a human reading that record and noticing the shape did not fit.
- Refusals improved measurably where the rules were applied: W36's owner clause, W44's phrase
  naming, W49's typed decisions all reduced the round trips they targeted.

## What Didn't Go Well

- Eight human stops in one KeyContextAI session, none about the code under review. The nine real
  defects in privacy-critical code were the easy part; the friction was the hard part, and almost
  none of it was strictness - it was messages withholding the one fact that made a refusal
  actionable.
- The inert-control family reached eleven-plus, and this retro's own preparation found two more:
  no writer owns `state.md`'s phase at a boundary crossing (every project's `state.md` is wrong at
  every crossing, in the file a human opens to learn where they are - DRIFT-199-I001-152), and no
  writer advances the workshop controller at lens confirmation (F-1). Same family, different
  ladders.
- Three composition defects: the packet's mandated re-render against receipt hashing (F-2); the
  sync's own preflight moving the tree its coverage gate then refused (W77); the gate-stop
  discipline requiring verdict options for a crossing whose stage had nothing to approve (TB-1).
  Two controls, each correct alone, hostile together - and nothing tests that.
- One check carrying two jobs under one name: `pushed-head` delivers (release-model, closeouts
  only per its own schema) and also keeps verdict commits durable (every boundary, because three
  readers resolve `auth_commit_hash` back against git). Aimed at delivery, it fired at specify and
  demanded a public repository to clear a specification.
- The scaffolding contradicted the method's own documented rule by writing a placeholder `spec.md`
  before the workshop that decides what it should say (B-7).
- The record's count claims drifted: the drift-log summary said 78 at 152; two identifiers were
  used twice; one was skipped. Authored counts do not track their artifacts.
- Redeploy drift cost real rounds: every fix needed re-stamping across byte-identical mirrors
  (`extensions/` and `.specify/extensions/`, three skill copies), and the deployed side silently
  kept old behavior whenever a copy was missed.

## Lessons Learned

1. **An authority write and its mirror write belong in one writer, with a truth check between
   them.** Two of the three inert controls found this fortnight were a mirror nobody wrote
   (`state.md` phase, workshop `moved_on`). Owner: crew, iteration 002 (F-1 writer; item eight
   phase mirror in `Add-SpecrewBoundaryAuthorization`, truth gate extended).
2. **One check, one job, one name.** A check with two jobs gets aimed at the boundaries of one of
   them. Owner: crew, iteration 002 (TB-3 split: release-model delivery at closeouts; verdict-commit
   durability at every boundary, each with its own message).
3. **Every refusal names what failed, the instance, and one reachable action.** Would have removed
   five of eight stops. Owner: maintainer, beta4 UX programme as the standard; crew applies it to
   every refusal touched in 002 so beta4 does not have to rewrite them.
4. **A structural assertion that cannot see a disabled call is not a test.** Standing rule, kept.
   Owner: crew, every fix in 002 carries the mutation that turns its own case red.
5. **Instruction-layer friction is invisible to every control that measures gate behavior.** F-3's
   refusals were agent-rendered: no recognizer refused, no journal line, receipts minted. The stop
   counts from both walks are a floor, not a total. Owner: maintainer, beta4 friction measurement
   must read the walk transcript, not the gate log.
6. **Composition is where the worst moments came from, and nothing tests it.** Owner: maintainer,
   beta4 (proposal 213's walk harness: "human does an ordinary thing, two gates disagree").
7. **Authored counts drift; derived counts do not.** Owner: crew, beta4 chore - derive the drift-log
   summary from its entries.
8. **The review process, as constituted, cannot see defects that live in how the machinery meets a
   person - only in the code it inspects.** Thirty-three review rounds on this feature produced none
   of the four findings now blocking the tag; all four came from two humans doing ordinary things
   in a walk. That is the argument for the walk harness and for friction measurement as a release
   criterion. Owner: maintainer (recorded at the retro verdict, 2026-08-29); next action: both
   land in the beta4 UX programme as release criteria, not as advice.

Reviewer-instruction candidates, triaged: PROMOTE "verify the mechanism at source before designing
the fix" to durable methodology (the F-3 correction and the TB-3 second job both came from it).
PROMOTE "mutation proving is mandatory" (already standing; now in the playbook). DEFER composition
tests to beta4 with reason: design work, not a tag-batch item. DROP per-fix covering rounds
explicitly, per the 2026-08-27 ruling: one covering round on the tree that ships.

## Signals for the Next Iteration

Iteration 002 is the beta3 tag batch, defined by the crew brief of 2026-08-29 and the maintainer's
answers to the crew report, and it is where these lessons become work:

- Eight items: TB-1 (both halves; half 2's gate-stop discipline alignment approved because the
  discipline was already inconsistent - the conformance provider ships the counter-discipline and
  `refocus/general.md` contradicts Rule 53), TB-3 split as above, TB-4 with its sibling converter,
  F-1 and B-6 as one governed lens-checkpoint writer (no new validators, no pipeline redesign),
  F-3 as message text on both surfaces with recognizers untouched, B-7, and item eight - the
  phase-mirror writer behind DRIFT-199-I001-152.
- Six items explicitly out and staying out: F-2, TB-5, B-5, B-1/B-1a, B-2, B-3, plus the UX
  programme B-4 as beta4's top priority.
- Iteration 001 closes on what it actually reviewed: sign-off against `66403e9b` resting on
  covering evidence for tree `1b50ae60`. The post-signoff movement (W76, W77) is not claimed as
  reviewed here; iteration 002's single covering round carries the whole delta since `1b50ae60`.
- Known test flips to own in 002, not discover: `fr068-verdict-demand-reproduction` HALF 2
  (documented as designed to invert), `gate-stop-skill.tests.ps1:65`,
  `multi-host-launch-path.tests.ps1:326`, and the workshop transition table growing from 48 to 56
  pinned cells.
- Mirror discipline: every fix lands in every byte-identical copy in the same commit.

## Improvement Actions

1. Owner: crew (iteration 002) | Phase: 002 implement | Type: implementation | Expected effect: the
   eight-item batch lands with a mutation per fix and B-4.1-shaped text for every refusal touched;
   the two walks' blocking findings (crossing forgery, greenfield specify block, wrong-cause
   refusal) cannot recur on the shipped tree.
2. Owner: crew (iteration 002) | Phase: 002 plan | Type: process | Expected effect: `pushed-head`
   split into a closeout-scoped delivery check and a boundary-wide `verdict-commit-durable` check,
   each named for its job, so this repository keeps its every-boundary push requirement while a
   greenfield project can clear specify without a remote.
3. Owner: crew (iteration 002) | Phase: 002 review | Type: process | Expected effect: one covering
   round on the shipping tree, covering the whole delta since tree `1b50ae60`, before the tag
   decision.
4. Owner: maintainer | Phase: beta4 workshop | Type: process | Expected effect: the UX programme -
   refusal standard with a standing check, composition tests in the walk harness, friction
   measurement that counts agent-rendered refusals, and the rule that a control ships only with a
   refusal meeting the standard.
5. Owner: crew | Phase: beta4 | Type: chore | Expected effect: the drift-log summary counts are
   derived from entries and the identifier sequence is enforced, so the record cannot understate
   itself again.

## Calibration Suggestion

- Suggested capacity adjustment: current baseline 20 SP -> keep 20 SP. The observed
  implementation:review:rework parity (roughly 1:1:1) is recorded as a FLOOR for stabilization
  iterations on the engine itself, not as iteration 002's capacity model, and it is not baked into
  the capacity gate: a ratio there produces overcommit signals that are artifacts of the ratio
  (maintainer ruling at the retro verdict, 2026-08-29).
- How 002 uses it: estimate 002's review work directly - it is enumerable (eight items, times the
  mirrored copies each touches, times the mutations each carries, plus one covering round over the
  13-file delta since tree `1b50ae60`) - then check that estimate against parity. If it lands
  materially under the floor, that is evidence the estimate is repeating 001's error, not permission
  to plan less.
- Rationale: at landing every task was on estimate; the iteration then spent roughly eight times
  the implementation calendar in review and rework, and that is where the shipped value came from.

## Rulings Recorded at the Retro Verdict

- Verdict-commit durability for projects with no remote (a `refs/specrew/verdicts/<id>` namespace):
  beta4. The TB-3 split unblocks the no-origin case and its message states the risk rather than
  hiding it, which is what makes deferring legitimate; a ref namespace brings its own lifecycle
  questions and the 002 batch already adds two writers.
- Drift-log identifier defects (005 and 024 doubled, 036 unused): recorded, not renumbered.
  Identifiers are cited across records including signed-off ones; the numbering defect is cosmetic
  and the citation graph is not.
- The TB-3 split and the item-eight phase-mirror design are accepted as iteration 002 plan input.

## Notes

- This artifact was scaffolded from plan.md, state.md, drift-log.md, and review.md for Squad's
  built-in Retrospective ceremony, then authored from the drift log, the verdict ledger and the
  commit history.
- Counts in this record were measured on 2026-08-29 against commit `7ca61b53` and the drift log
  as corrected at this retro.
