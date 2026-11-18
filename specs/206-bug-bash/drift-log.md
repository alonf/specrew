# Drift Log: 206-bug-bash

**Feature**: 206-bug-bash
**Scope**: feature-level findings recorded before the first iteration exists

## DRIFT-206-001 — the workshop hook stored a receipt for a message that answered no workshop question

- **Recorded**: 2026-11-10, at the maintainer's instruction. Evidence for feature 203's capture work; not
  fixed in 206.
- **What happened**: `.specrew/runtime/workshop-authority.jsonl` holds two `product-domain` receipts for this
  feature, both `human-confirmed` / `lens-question`:
  - `4c7eca3aec78a8a729bb723114182a366c9075e9e132f95eb858ae12da963c43`, recorded 03:28:23 local
    (01:28:23Z), for the maintainer's message beginning "Recovery: not an override yet…". That message
    ruled on the specify-gate recovery and the triage; no product-domain question had been asked yet.
  - `fa0b6d95b75e59ce61cf183afa0f0b64ee0d0b0459307e901910c1c2ddf38982`, recorded 03:30:24 local
    (01:30:24Z), for the maintainer's "confirm - Light depth and this picture are right…", the real answer
    to the product-domain question.
- **Consequence avoided**: only the second receipt is cited in `lens-applicability.json` and the
  product-domain record. A writer that took "any receipt for this lens" would have bound the lens to a
  message that never answered it.
- **Same class, next message**: on the maintainer's push approval ("Approved: push 206-bug-bash to
  origin…"), the prompt hook reported "your agenda confirmation was received but NOT bound". No agenda had
  been presented and none was confirmed; the hook read an approval of a push as an agenda confirmation.
  Nothing was recorded, so nothing needs undoing.
- **Owner**: feature 203's follow-up (capture work).

## DRIFT-206-002 — iteration 002's scope, decided by the maintainer (Amendment A1)

- **Recorded**: 2026-11-15, after iteration 001's closeout and before iteration 002's folder exists.
- **Decision** (maintainer, 11:31 local, to the reviewer session, relayed under the wider delegation; a decision, not
  an approval): "OK, agree, do it", answering the reviewer's recommendation:
  - in scope: the carried work (SC-002 first, SC-001, T016, T017, DRIFT-206-I001-010, items 12 and 15 to 35) plus
    items 37, 39, 41 and 44;
  - the four need requirements, so the spec is amended through clarify first (Amendment A1, FR-015 to FR-018);
  - everything is sized; if it exceeds capacity, the plan shows what moves out and why; the cut is the maintainer's
    at the plan approval;
  - item 37 links feature 203's T014 case and proposal 206, and says how far the fix goes;
  - not in scope: items 40, 42 and 43 (feature 203's code) and items 36 and 38 (later).
- **Where it is applied**: `spec.md` (scope tables, FR-015 to FR-018, SC-008 to SC-011, Clarifications session
  2026-11-15) and the bug list's Iteration 002 Intake.

## DRIFT-206-003 — the rerun exception also covers `empty-result-retry.Tests.ps1` (standing rule)

- **Recorded**: 2026-11-15.
- **Decision** (maintainer, 11:31 local, the same "OK, agree, do it", relayed by the reviewer session under the wider
  delegation): the standing rerun exception for `tests/continuous-co-review/unit/co-review-service.Tests.ps1:129`
  also covers `tests/continuous-co-review/unit/empty-result-retry.Tests.ps1` (bug list item 3), on the same terms,
  until feature 203 merges.
- **Terms**: when Specrew CI fails only in that test, on a push that could not have caused it, the failed job may be
  rerun once without asking. Each use is recorded as a sighting with the run and the job, and added to the hand-over
  to 203. A second failure stops the work. It covers nothing else.

## DRIFT-206-004 — after a closed iteration, the clarify sync for Amendment A1 opened no approval point (second sighting, for feature 203)

- **Observed**: 2026-11-15, 12:54 local (10:54Z). With iteration 001 closed, `sync-boundary-state.ps1 -BoundaryType
  clarify -FeatureRef 206-bug-bash -IterationNumber 002 -AuthCommitHash e827a9af` (run after CI was green on
  `e827a9af` in all three workflows, every job run) exited 0 and wrote its bookkeeping (`.squad/decisions.md`, a
  lifecycle event, `.squad/identity/now.md`), but opened no crossing: there is no
  `.specrew/runtime/pending-verdict-stop.md`, and `start-context.json` still names `iteration-closeout` as the last
  authorized boundary with nothing pending.
- **Also written**: a decisions entry "Boundary sync warning: clarify — Expected next boundary 'feature-closeout' but
  received 'clarify'". After an iteration closeout the sync knows only the feature closeout as next; a later
  iteration's amendment has no route of its own.
- **Same as**: feature 205's DRIFT-205-INTAKE-005 (2026-11-13), where the maintainer ruled that Amendment A1 is
  approved at the plan boundary and the clarify records are committed as bookkeeping.
- **Impact**: a spec amendment for a later iteration reaches planning with no approval of its own.
- **Owner**: feature 203's follow-up; it goes into iteration 002's hand-over to 203.
- **Here (reviewer, 2026-11-15, routine ruling under the maintainer's delegation, on feature 205's precedent)**: the
  clarify bookkeeping (`.squad/decisions.md`, `.squad/events/lifecycle-events.jsonl`, `.squad/identity/now.md`) is
  committed as a `boundary(clarify)` bookkeeping commit with this entry; `.squad/active-features.yml` stays out.
  Amendment A1 is approved by the maintainer at iteration 002's plan boundary, and the plan packet says so.

## DRIFT-206-005 — the records-only push rule widened to records in general (maintainer, relayed)

- **Decision**: the maintainer's words to the reviewer, at 19:02 local on 2026-11-15, "Yes for all", answering feature
  203's question whether the records-only push rule covers records in general and not only Markdown. Relayed by the
  reviewer (specrewreviewer-98) for all three crews; a decision, not a boundary approval.
- **The rule**: when the only difference from the last commit on which the full pre-push checks were green is records,
  run markdownlint and the governance check, push, and follow CI to its end. Records are Markdown under `specs/` or
  `docs/`; the files a boundary sync writes (the `.squad` records, the sign-off gate's record and listing, `state.md`,
  the closed-iterations index and the seal); and the iteration's own record files such as `tasks-progress.yml`.
  Anything else (any script, test, workflow, configuration file, deployed copy or hash record) still gets the five
  lanes in the preflight layout. Before using it, the changed files are printed and each confirmed a record of those
  kinds; one that is not clearly so is not.
- **Unchanged**: `.squad/active-features.yml` is in no commit; the rule does not relax a review round's head or widen
  the item 13 rerun exception.

## DRIFT-206-006 — iteration 002's closeout: two arrival syncs (bug list item 69, a sighting) and one rerun of empty-result-retry

- **Recorded**: 2026-11-18, after the iteration-closeout verdict, here rather than in iteration 002's drift log,
  which the closeout seal covers (iteration 001's post-seal drift entry forced a reseal, DRIFT-206-I001-031 to -033).
- **Two arrival syncs**: the first iteration-closeout sync (23:46:14Z, at `c26f9990`) named two open items in
  `quality/hardening-gate.md`: Post-Implementation Verification pending, and Verified At not recorded. This is the
  arrival listing T036 built. The crew filled both before the verdict (`44d7c71b`) so the seal taken at capture covers
  them. One sync attempt before the push refused on `pushed-head` with no write. After the push, the sync ran again
  (23:49:28Z, at `44d7c71b`).
  - The second sync wrote a second "Boundary sync: iteration-closeout" entry in `.squad/decisions.md`, a "Boundary
    sync warning" ("Expected next boundary 'feature-closeout' but received 'iteration-closeout'") and a second
    lifecycle event. Bug list item 69, a sighting.
  - The maintainer's verdict (captured 01:07:19Z) authorized the second crossing; the boundary commit is `0f6313ed`.
- **CI**: Specrew CI run `44202679172` on `44d7c71b`, job Deterministic gate `134463069183`, failed 1 of 131. The only
  failure was `tests/continuous-co-review/unit/empty-result-retry.Tests.ps1`. It was rerun once under the standing
  exception (DRIFT-206-003), and attempt 2 succeeded. This is the second sighting that night, after `1b40bb44`
  (DRIFT-206-I002-025); bug list item 3, feature 203's to fix.
- **Class closure**: NONE — sightings of bug list items 69 and 3.
