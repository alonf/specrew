# Retrospective: Iteration 011 — Authorization Integrity

**Schema**: v1
**Date**: 2026-08-06
**Facilitator**: Retro Facilitator
**Iteration Duration**: 2026-08-02 → 2026-08-06 (specify → retro)
**Scope**: FR-066, FR-068 (evidence half), FR-018

---

## Executive Summary

Iteration 011 set out to close two authorization-integrity defects where a human could be led to
authorize an increment that does not exist. **It delivered one and a half of them, at 45% over
capacity, and its most durable output is not code.**

| | Result |
| --- | --- |
| FR-068 evidence half | **delivered** — tree-bound stage evidence, fail-closed unverifiable reasons, strict clarify matcher |
| FR-066 arrival state | **delivered** — an unrecordable crossing is branchable; the surface speaks and names what is missing |
| FR-066 mint guard | **NOT delivered** — two attempts, both faulted by independent review, both reverted |
| Capacity | **~29.0 SP against 20** — over by ~9, recorded uncompressed |
| Certification | 3 of 3 rounds spent; **the shipping tree carries no certification**, and the tag basis says so |

**The central finding is not about any of those defects.** Four times this iteration, a rule that was
written down, recent, and authored by the person who then violated it, failed to prevent the violation
— once from **eleven lines away in the same code block**, and once at the closeout itself, where three
independent parties each held the relevant knowledge and none of them was structurally checked. The conclusion the ledger reached is
the one this retro promotes: *a rule that can be violated in the file that states it is not a rule, it
is a wish.* Everything that actually held this iteration held because it was structural.

---

## Estimation Accuracy

| Phase | Planned | Actual | Delta |
| --- | ---: | ---: | ---: |
| T086–T090 as approved | 20.0 | 20.0 | 0 |
| Option 3 rework (certification round 1's four findings) | — | +5.5 | +5.5 |
| Fixture collateral (priced as 1 suite; measured as 3) | 1.5 | +3.5 | +2.0 |
| **Total** | **20.0** | **~29.0** | **+9.0 (45% over)** |

**The overrun was recorded at its real number every time it moved, and never compressed.** That is a
deliberate contrast with Iteration 009, whose ledger prices at ~70 SP against a cap of 20 and whose
trigger needed amending twice because the number was massaged rather than reported.

**Estimation lesson**: the fixture-collateral line was priced from *one observed failing suite* rather
than from *the class of fixtures the change invalidated*. The fail-closed conversion broke every fixture
that committed evidence without recording a crossing — three suites and 26 fixtures, not one. **When a
change alters what makes a fixture valid, the estimate must be sized on the invariant, not on the first
red.**

---

## Finding 1 — Prose rules do not bind; only structure does

Four instances, same shape, escalating in how damning each is — the fourth arrived *after this retro was
first drafted*, during the closeout it was written to conclude:

| # | The rule | Where it lived | How it failed |
| --- | --- | --- | --- |
| 1 | "A passing assertion is not evidence until you check what it measured" (DRIFT-198-I009-042) | Iteration 010's record | Did not transfer. Reproduced twice in T086's first two fixture revisions. |
| 2 | "Walk every consumer of every flag before building" | Practised, unwritten | Killed two wrong designs; **not applied** to the one design that shipped a blocking defect. |
| 3 | "A warning is NOT a state a caller can branch on (NFR-002)" | **A comment eleven lines above the code that violated it**, same block, same author, same day | The finding-2 fix made the failure *loud* — a warning — which is precisely what that line says is insufficient. |
| 4 | "A status must not claim more than its artifacts support" (FR-018, and the boundary-evidence contract authored *in this iteration*) | The contract file, and the iteration's own scope | **The closeout marked 011 `closed` with no `review.md` and no `quality/hardening-gate.md`.** See DRIFT-198-I011-010. |

Instance 3 is the proof. Proximity, authorship, recency and relevance were all maximal, and the rule
still did not bind. **The conclusion is not "read your own comments."**

**Instance 4 is worse, and it is the one that should change practice**, because it was **three-party**:
the executor set the status without checking the boundary's artifact preconditions — having personally
authored the contract that names `review.md`; the human approved the closeout; and the reviewer's
drafted verdict omitted the artifact checklist despite having audited iteration 003's closure
requirements first-hand. **Three competent parties, each holding the relevant knowledge, and no
structural check existed between any of them and the over-claim** — only a release gate whose *natural
command silently skips closed iterations*, and which therefore returned exit 0 on the first run.

**Knowledge does not bind. Structure binds.** Instance 4 is the sentence this retro is for.

### What DID bind — and it is worth as much as the failures

| Mechanism | What it caught |
| --- | --- |
| **RED→GREEN fixtures** | Every fix this iteration; a fix without a proven RED was never trusted |
| **The INCONCLUSIVE third outcome** | Five would-be false passes (see Finding 6) |
| **A single choke point** | One guarded initializer covered all three bootstrap mint sites; patching callers would have left whichever was missed live |
| **Read-backs** | The latch write that "succeeded" into a directory — caught only because the code read back what it wrote |
| **Independent review** | Every defect in the corrections themselves; the implementer found none of them unaided |

**Action**: rules that matter must ship as a test, a choke point, or a read-back. A rule expressible
only in prose should be treated as unenforced until it has one of those three forms.

---

## Finding 2 — The consequence-graph walk, promoted to a named design-gate step

The practice: before building, walk *every consumer of every flag you touch, in writing*.

| Application | Outcome |
| --- | --- |
| T088 — "supply the missing marker" | **Killed pre-construction.** Measurement showed silence, not a marker-less block. |
| T090 — `HasPendingVerdict = false` | **Killed pre-construction.** Would have broken verdict capture — an over-demanding gate converted into a *lost authorization*, worse than the defect. |
| T089's evidence gate | **Not applied.** Shipped a live tree checked against an immutable bound tree — a false-authorization path inside the fix for false authorization. |
| Finding 2 (T092 rework) | **Applied, and immediately re-scoped the work**: the reviewer had verified the one mint site the maintainer never runs; the live path was the SessionStart hook, and the mint needed *no human action at all*. |

**Two applications, two saves. Two omissions, two blocking defects.** That is a control group, and it
is why the practice is now a *step* with a written artifact rather than a virtue someone may recall.

**A practice applied intermittently is indistinguishable from luck** — and this iteration has the data
to say so rather than assert it.

---

## Finding 3 — The disposition record: the iteration's actual output

Flagged by the maintainer as what this feature exists to produce. Three moments where the agent's
conduct, not the code, was the deliverable:

1. **Refusing to self-reset the review allowance.** The replenish path was available to run
   unilaterally. Running it would have been an agent minting its own authorization in order to certify
   its own work — structurally identical to DRIFT-198-I011-004, where a failed crossing was converted
   into an authorized cursor by the recovery path itself. **FR-066/FR-068's principle generalized from
   the code paths to the conduct of the agent operating them.**
2. **Not fixing forward while fully able to.** Round 2's blocking defect had an obvious, small fix. It
   was withheld because the standing termination rule said escalate. The rule existed to prevent a
   fix-forward spiral, and it worked *because it was obeyed when obeying it was the expensive option*.
3. **Refusing to guess a destructive scope.** When the termination rule's letter ("revert T088–T090")
   and the defect's actual location (a later commit) diverged, the agent brought the discrepancy rather
   than picking the cheapest reading. That refusal is what let the maintainer amend the rule openly
   instead of having it satisfied by reinterpretation.

**These generalize past this feature.** The code closes specific holes; the disposition is what makes
the next hole survivable.

---

## Finding 4 — Cap and slot are different things, and only one gates a launch

| Concept | What it is | Set by |
| --- | --- | --- |
| **Round cap** | the budget POLICY ceiling — how many rounds the maintainer will fund in total | standing policy |
| **Grant slot** | ONE round, funded by ONE human spend decision | one authorization reference, per round |

The drift log itself conflated them once ("the grant is intact and the 3-round cap is untouched") and
the conflation cost a launch attempt. **One authorization reference funds exactly one slot,
permanently** — `grant_id` is derived from `campaign_id/authorization_ref`, and a grant whose
`slots != 1` is treated as store corruption.

**The 1-slot grant is correct as built.** A pre-funded multi-slot grant would let rounds launch without
per-round human consent — the exact property this iteration existed to close. **This is the model
FR-019's beta3 grant-scoping should follow.**

Corollary recorded as a beta3 carry: `allowance-reset` is *named* as the replenish mechanism while
being unreachable in campaign mode. It must become reachable or stop being named — the per-reference
grant already is the mechanism.

---

## Finding 5 — The measurement-hazard family: one class, one cure

Four distinct times, the instrument lied and nearly produced a false conclusion:

| Hazard | The lie |
| --- | --- |
| **Git-Bash `tar`** | Full gate reported 3 of 90 red. One was `tar` resolving `C:\…` as a remote host. From PowerShell: green. **The shell changed the answer.** |
| **A harness truncating its own error at 220 chars** | Hid the real exception (`property 'unreadable' cannot be found`) behind a stack frame, turning a five-minute diagnosis into a hunt. |
| **`Write-Utf8FileAtomic` succeeding into a directory** | `Move-Item -Force` onto a container moves the file *inside* it and returns success. The write "succeeded" where no reader looks, **raising no exception anywhere**. A fix keyed on the write throwing would have been defeated silently. |
| **`git stash create` during an in-progress revert** | Post-revert gate reported a failure caused entirely by the uncommitted mid-revert state. |

**One cure, and it is the same sentence in every case: read what the measurement measured before
trusting its colour.** Not one of these four was caught by something failing loudly. Each was caught by
looking at the output against the claim being made about it.

The third is the sharpest, because it generalizes into product code: **a write that does not throw is
not evidence that a later process can find what you wrote.** That is why the surviving guard in the
reverted design was the *read-back*, not the write — and why the atomic writer's defect is carried to
beta3 at MAJOR, since `start-context`, `boundary-state` and ledger writers all trust its return.

---

## Finding 6 — INCONCLUSIVE is a required third outcome (candidate for SHIPPED method guidance)

A harness MUST distinguish *the defect is absent* from *the probe never reached the code path*, and
report the latter as a fixture defect rather than folding it into pass/fail.

**Counted record: five false passes prevented.**

| # | Task | Defect | Two-outcome reading |
| --- | --- | --- | --- |
| 1 | T086 | transcript omitted; provider emitted nothing | "half 1 satisfied" ✅ **false pass** |
| 2 | T086 | asserted the scoped branch's phrase; unscoped demand missed | "no demand" ✅ **false pass** |
| 3 | T087 | schema `v2` used for the un-bootstrapped shape | "sync correctly refused" ✅ **false pass** |
| 4 | T087 | `.squad/active-features.yml` absent | INCONCLUSIVE — caught |
| 5 | T092 | CASE 3c reused a project whose state a prior case had already changed | "the instruction does not name the mint path" ✅ **false pass on a live defect** |

**Four of five would have read as passes.** This is past the threshold where a practice becomes a rule.

**Recommendation**: promote to
file:///C:/Dev/specrew-beta2-hardening/docs/methodology/lifecycle-discipline.md as shipped guidance,
not merely this repo's habit — every downstream consumer writing a RED-first fixture hits the same trap.
Its companion rule ("read the measured output against the claim") cannot be automated; INCONCLUSIVE is
its mechanical proxy and should ship as a checkable convention.

---

## Certification economics — what three rounds actually bought

| Round | Result | Value |
| --- | --- | --- |
| Attempt 1 | did not run (`--host` omitted); **no round spent** | surfaced DRIFT-198-I011-002: preflight burned 614.5s to report a knowable-at-reservation condition |
| Round 1 | 4 validated findings — 2 blocking, 2 major, **all in the corrections themselves** | caught two false-authorization paths the implementer had shipped |
| Round 2 | 1 blocking; **validated findings 1, 3, 4** | localized the remaining defect and cleared three-quarters of the work |
| Round 3 | 1 blocking + 1 major | caught a concurrency defect in an accepted note-level deviation |

**Independent review found every defect in the corrections. The implementer found none of them
unaided.** The single most valuable structural fact of this iteration.

**And a note-level acceptance is a claim about consequence.** "Any-success clearing" was accepted as
note-level by both implementer and maintainer; round 3 showed it is blocking under concurrency. The
acceptance inherited every gap in the consequence walk that produced it — the same lesson as Finding 2,
arriving through a governance decision rather than a code change.

---

## Actions

| # | Action | Owner | Where |
| --- | --- | --- | --- |
| 1 | Promote INCONCLUSIVE + "read what the measurement measured" to shipped method guidance | Spec Steward | `docs/methodology/lifecycle-discipline.md` |
| 2 | Consequence-graph walk becomes a required, written design-gate artifact before construction | Planner | ceremonies |
| 3 | Rules that matter ship as a test, a choke point, or a read-back — prose alone is unenforced | All roles | constitution candidate |
| 4 | Estimate fixture collateral on the invalidated invariant, not the first red suite | Planner | capacity practice |
| 5 | Run the F-198 gate from PowerShell; record Git-Bash `tar` as a known hazard | Implementer | recorded in drift log |
| 7 | Closeout probe: validate-as-if-closed BEFORE committing the status flip (the 003 pattern, promoted to standing practice) | Implementer | ceremonies |
| 8 | `-IncludeClosed` on every release-gate run — the default command skips closed iterations and nearly converted a false green into a tag | Implementer, Reviewer | confirmed beta3 finding |
| 6 | Carry the six beta3 items as recorded, FR-066's mint guard first | Planner | drift log carry table |

### Maintainer rulings on the three discussion prompts, 2026-08-06

1. **Action 3 goes to CONSTITUTION level — through the governed path, not as a retro rider.** *"Rules
   that matter ship as a test, a choke point, or a read-back"* changes how every future requirement is
   written, which is exactly what a constitution amendment process exists to decide deliberately.
   **Proposed at beta3's planning boundary with its evidence attached** — the three prose failures AND
   the control group. Until then it binds this repo as iteration guidance only. *(Note the shape: the
   ruling applies the finding to itself — a rule about structural enforcement is not allowed to enter by
   the unstructured path.)*
2. **Finding 6 ships.** INCONCLUSIVE becomes shipped method guidance with its counted evidence (five
   false passes prevented; four of five would have read as passes). Routed as **one named beta3 task on
   the shipped surface**, bundled with the other downstream-bound discipline rules already queued
   (CI-consumption, evidence-before-hypothesis) — **one "shipped method guidance" work item, not three
   riders.**
3. **The FR-066 mint guard enters beta3 as a DESIGN SPIKE, not a task.** Two designs have failed at
   design level, so the spike's deliverable is **the concurrency/failure matrix and a design that
   survives it** — serialize the sequence vs attempt-scoped records with same-attempt clearance —
   **priced before any implementation is scheduled.** Same price-before-build pattern that worked for the
   `artifact_state_id` re-cut, which came in sane at 5.5 SP because it was priced against machinery that
   already existed.

---

## Carried to beta3

Consolidated in
file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/iterations/011/drift-log.md — the
FR-066 mint guard (blocking, open, needs a design that survives concurrency), the atomic-writer defect
(major), the preflight timeout burn, the `allowance-reset` naming/reachability gap, the unregistered
suite, and SC-025's composition clause — **observed live in this session's own Stop blocks.**
