---
proposal: 206
title: Governance-Schema Vocabulary Completeness
status: candidate
phase: phase-2
estimated-sp: 5-8
discussion: tbd
---

# Governance-Schema Vocabulary Completeness

## Why

> **Updated 2026-08-01: now SIX instances, and scheduled.** A sixth appeared during F-198
> iteration 010's certification (DRIFT-198-I010-006, added to the table below). The maintainer
> has moved this proposal into **beta3, alongside the containment-consolidation feature** —
> at six instances it is overdue rather than optional. The count in the original text below
> reads "five"; it is left as written and corrected here rather than rewritten, per the
> supersede-not-rewrite record discipline.
>
> **Updated 2026-08-02: SEVEN, and the scope widens from dispositions to MACHINERY.**
> DRIFT-198-I010-008 was observed live while opening iteration 011 — a legitimate, human-
> instructed RE-ENTRY to an earlier boundary cannot open a pending verdict, because the cursor
> is global and monotonic and reads the return as backward movement. The maintainer clustered
> it here at the specify verdict. It is the first instance whose field is not a *disposition*
> but the *boundary cursor* itself, so this proposal's remit is now **governance-schema
> vocabulary completeness across both** — what a state can be recorded AS, and what a position
> can be recorded as MOVING TO. It is also the second occurrence of its own shape: iteration
> 006's `state.md` recorded the identical failure seven weeks earlier.

**Five times in one feature, the governance schema could not express the honest disposition,
and each time a human had to choose between an inaccurate record and a blocked lifecycle.**

That is the pattern. Individually each looked like a small schema wart and was recorded as a
minor drift entry. Together they say something structural: the vocabulary is specified for the
happy path, and the honest answer to a messy situation frequently has no representation.

The five instances, all from F-198:

| Drift | The honest thing that could not be said |
| --- | --- |
| DRIFT-198-I009-020 | "A human authorized a boundary decision ABOUT a historical iteration" — the boundary model assumes one moving cursor, so a retroactive closeout must either mis-record the crossing or record no authorization at all. |
| DRIFT-198-I009-021 | "Runtime evidence for this concern was recorded by a NAMED SUCCESSOR iteration." The hardening gate offers `recorded` (a lie), `not-needed` (an understatement), or stay pending (blocks a closure the maintainer authorized). |
| DRIFT-198-I009-034 | "This finding is known, human-deferred, and unfixed." The review gate's deferral vocabulary covers findings CARRIED across rounds; a fresh reviewer rediscovering a deferred defect re-raises it forever, and `can_approve_current` can never become true. |
| DRIFT-198-I009-044 | "This task is terminal-as-deferred and its work is satisfied NOWHERE yet." Closing requires `accepted`, which requires every task `pass`. Iteration 009 was held open rather than record a `pass` against an unsatisfied requirement. |
| DRIFT-198-I010-001 | "This iteration is bounded by ROUNDS, not scope." `iteration_bounding` offers only `scope` or `time`, and the validator requires the plan to match config — so the plan's structured field says `scope` while the real bound is a 3-round cap stated in prose. |
| DRIFT-198-I010-006 *(added 2026-08-01)* | "This campaign was TERMINATED by a human rule; no further round is authorized." The campaign gate models a moved digest as either authorized or needing a review, so after a termination rule fired it kept emitting `request-current-digest-review` — an action that would spend a paid round the governing decision forbids. Its only honest output is a request the human has prohibited. |
| DRIFT-198-I010-008 *(added 2026-08-02 — CURSOR, not disposition)* | "This feature has legitimately RETURNED to an earlier boundary for scoped work." The cursor is global and monotonic, so a human-instructed re-entry to `specify` reads as backward movement from `review-signoff` and no pending crossing opens — the machinery cannot produce the verdict stop the human explicitly asked for. Second occurrence: iteration 006 recorded the same shape. |

The cost is not theoretical. DRIFT-198-I009-044 **held Iteration 009 open** — it is still at
`reviewing` with a recorded closure trigger, because the alternative was asserting a satisfied
requirement that was not satisfied. DRIFT-198-I009-034 forced a choice between fixing a
consumer-reachable defect immediately or having an authorized deferral be unrepresentable.
DRIFT-198-I010-001 leaves a structured field that actively misleads a reader who trusts it.

The through-line: **a schema that cannot express a true state pressures its users toward
recording a false one.** Every one of these gaps has a locally convenient workaround that is
slightly dishonest — mark it `recorded`, mark it `pass`, mark it `not-needed`. The workaround
is always available and always cheaper than stopping. That is the risk this proposal exists to
remove, and it is squarely against Specrew's own evidence-honesty premise.

## What

Complete the disposition vocabulary at the four levels where these gaps occur — boundary,
concern, finding, task/iteration — so the honest state is always representable, and so the
validator can check it rather than a human having to argue for it in prose.

### Functional requirements

High-level capabilities for a candidate; FR-NNN entries come at draft.

1. **Boundary subject.** Give a verdict record an explicit SUBJECT — the (feature, iteration)
   the decision is ABOUT — distinct from the cursor position it advances, so a retroactive or
   out-of-band governance decision is real authorization without moving the active cursor.
   (-020)
2. **Successor-evidence disposition.** A concern-level status meaning "runtime evidence
   recorded by a named successor iteration", carrying that reference so the pointer is
   machine-checkable instead of prose. (-021)
3. **Durable deferral identity.** A deferral record with an identity that survives across
   campaigns and is surfaced to FRESH review rounds, not only to rounds carrying prior
   findings — so an authorized deferral stops being re-raised as a new finding. (-034)
4. **Unsatisfied-deferred task disposition.** A task verdict meaning "deferred; not satisfied
   here or elsewhere yet", and an overall verdict meaning "accepted with recorded deferrals",
   so an iteration can close honestly without a `pass` against unsatisfied work. (-044)
5. **Bounding vocabulary.** `rounds` and `budget` as first-class `iteration_bounding` values,
   with the cap as a configured value the validator checks against the plan's certification
   section. (-010-001)
6. **A general rule, not five patches.** Where a disposition field exists, the schema must
   offer a value for "true but inconvenient" — and the validator must accept it. New
   disposition fields should be reviewed against this rule.

### Out of scope

- Changing what any gate ENFORCES. This is vocabulary, not policy: nothing here should make a
  blocking finding non-blocking, or let an uncertified iteration claim certification.
- Retroactive rewriting of closed iterations. Existing records stay as they are; F-198's
  workarounds are documented in place.
- The review-round economy itself (Proposal 203's W11/W12 ceiling UX). Related but separate.

## Effort

- **Iteration 1 (~5 SP)**: items 1, 4 and 5 — the boundary subject, the unsatisfied-deferred
  task/overall dispositions, and the bounding vocabulary. These three unblock concrete,
  currently-blocked situations, including closing F-198 iteration 009 cleanly.
- **Iteration 2 (~3 SP)**: items 2 and 3 — successor-evidence disposition and durable deferral
  identity, both of which touch the review gate and want their own review.
- **Total**: ~8 SP.

## Phase placement

**Scheduled 2026-08-01: beta3, alongside the containment-consolidation feature.** Six instances
across one feature is the threshold at which patching each individually stops being defensible —
the same argument that moved DRIFT-198-I009-041 from a third per-site fix to a consolidation.
Both are the same lesson in different domains: when a class recurs, build the primitive and the
structural rule, not another instance-level patch.

Originally filed as Phase 2, on the reasoning below. That reasoning still holds and is why this
must land BEFORE the affected cluster is implemented — it has simply moved to beta3 with the
iterations that carry it:

Phase 2. It is a prerequisite for F-198 iteration 012's finality scope, which currently carries
the -021/-034/-044 cluster as implementation work. **This proposal should be approved before
that cluster is implemented, so 012 implements against a designed vocabulary rather than
inventing three point fixes** — which is precisely the "point corrections that never converge"
failure F-198 iteration 009 spent eight review rounds demonstrating.

## Open questions

1. Should the "accepted with recorded deferrals" overall verdict be a distinct value, or should
   `accepted` gain a required companion field enumerating the deferrals? A distinct value is
   more visible in a table; a companion field is harder to skim past.
2. Does the boundary SUBJECT belong on the verdict record, or is it a separate correction-ledger
   entry type? The correction ledger already exists and already carries an authorizing human.
3. How should a durable deferral identity be surfaced to a fresh reviewer without also handing
   it a way to dismiss findings it should raise? The current design deliberately requires a
   worktree-visible record; that property should survive.
4. Should the validator warn when a plan's prose asserts a bound (e.g. a round cap) that the
   structured field contradicts? That would have caught DRIFT-198-I010-001 at authoring time.
5. Is there a sixth instance already in the tree that has not been recognized as this class?

## Risks

- **Vocabulary expansion becomes an escape hatch.** New "honest" values could be used to avoid
  hard verdicts. Mitigation: every new disposition requires a named human and a machine-checkable
  pointer to where the work actually lives — the same shape the existing defer entry uses.
- **Schema churn across in-flight features.** F-198 has iterations at multiple statuses.
  Mitigation: additive values only, no re-interpretation of existing ones, and no retroactive
  rewriting.
- **It reads as process work while product defects wait.** Real tension. The counter is that
  three of the five instances actively cost lifecycle progress in F-198, one of them still
  holding an iteration open — this is not hypothetical tidiness.

## Provenance

Raised at the F-198 iteration-010 before-implement boundary (2026-07-31) on the maintainer's
instruction to elevate the pattern rather than treat a fifth instance as an isolated defect.
Source entries live in
file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/iterations/009/drift-log.md
and
file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/iterations/010/drift-log.md.
