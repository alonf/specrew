# Lens: requirements-nfr (medium)

**Feature**: 203-beta5-stabilization
**Confirmation**: human-confirmed / lens-question, closed with a typed `move on` on Claude, 2026-10-30.
**Question**: turn success measures (a) to (f) into thresholds a test or the walk can fail.

## Priority order and thresholds

```text
 prio  measure                                driver?  threshold            proven by
 ----  -------------------------------------  -------  -------------------  ------------------------------
  1    (b) no approval the human did not GIVE  design   0 records            record->typed-turn audit +
                                                                             fault tests on every mint path
                                                                             + non-approval phrase tests
  2    (a) recorded the first time typed      design   0 re-types           per-act turn identity check;
                                                                             compaction case on each host
  3    (c) no false "not recorded"            design   0 reports            every such report checks the
                                                                             store at the moment it speaks
  4    (d) review stops only (a)-(d)          design   0 other stops        stop-reason census on the walk
  5    (f) review cost; workshop confirm cost verify   review <= 1 + top-   ledger count per boundary;
                                                       ups (baseline 6);    replies per workshop
                                                       1 reply per          confirmation
                                                       workshop confirm
  6    (e) census tests also in a PR lane     verify   0 missing            census-vs-lane parity check in CI
```

## Decisions

1. **Order.** Authority correctness ((b), then (a)) outranks friction ((d), (f)). Where a fix trades
   one for the other, (b) wins: refusing to record beats recording an approval nobody gave.
2. **(a) "recorded the first time".** The act is in the store with the typed turn's own identity
   (message id and response hash), written by the end of that same turn, including when a compaction
   falls between the packet and the reply (B4F-112). A re-type is a failure even when the second one
   lands.
3. **(b) wording and proof.** The measure reads "no approval is recorded that the human did not
   GIVE", not "did not type". Proven in three layers:
   - an audit joining every authority record to a human typed turn; any record without one fails
     (covers the backstop double-record class);
   - fault tests driving every mint path (hook, turn-end, transcript backstop) with no human turn,
     asserting nothing is written;
   - fault tests where the human's own typed turn contains an approval phrase that is not an approval:
     quoted mid-message, inside backticks, or inside pasted content. Nothing is minted. (The
     maintainer's direction messages in this workshop carried `approved for allowance reset` that way
     and nothing was minted; a test keeps it so.)
4. **(e) proof.** A parity check in PR CI lists the tests the publish census runs and fails when any is
   in no PR lane.
5. **The three-host walk.** On each host: a verdict typed after a compaction; a review with at least
   one fix-needed round; a spent budget and a top-up; one disputed finding; one plan without a budget.
   It records the stop reasons and the authorization count per boundary. Manual with records; the
   B4F-145 automated walk stays out of scope.
6. **(f) extended to workshop confirmations.** A workshop confirmation costs one reply. A reply of the
   form "confirmed, with these changes" either saves against the amended text, or the crew applies the
   changes and saves without asking again. The second "confirm" this workshop's agenda needed (the
   three additions) is the same class as B4F-061. This adds the workshop agenda/lens confirmation path
   to 203's scope.

## Bindings

- `measure-priority`: `b-a-c-d-f-e`
- `measure-b-wording`: `not-given`
- `measure-b-proof`: `audit-plus-mint-path-faults-plus-non-approval-phrases`
- `measure-a-definition`: `same-turn-identity-incl-compaction`
- `measure-e-proof`: `census-lane-parity-check-in-pr-ci`
- `walk-mode`: `manual-with-records`
- `workshop-confirm-cost`: `one-reply`
