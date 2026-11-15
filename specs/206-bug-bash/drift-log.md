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
