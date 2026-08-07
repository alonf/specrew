# Field evidence: the stop-ordering defect (verdict packets rendered during a pending/blocked co-review)

**Status**: field-evidence record (FR-045 / GOV-002). Recorded at the maintainer's instruction,
2026-07-12. Enforcement is bound to T019 (in-flight/digest) and T030–T032 (capture integrity); this
file is the durable evidence of WHY.

## The defect

During iteration-003 continuous co-review, the assistant repeatedly rendered **user-facing
decision/verdict-shaped packets** — the six-section re-entry packet ending in a numbered
"What I Need From You: pick 1 / 2" — **while a required co-review was still pending, in-flight, or
actively BLOCKING**, and before the review's reviewed-tree digest was accepted against the exact
current tree. The most concrete instance: the T034b strict-design-context-resolution decision was
presented as an approval-style choice (numbered options) across several stops while the co-review of
that same increment was returning blocking findings and while concurrent navigator runs were still
firing.

## Why it is a defect (the load-bearing rules)

A blocked or superseded review must never be able to become authorization evidence. Concretely:

1. A user-facing lifecycle **verdict/boundary packet** (six sections, approval options, and a
   `SPECREW-VERDICT-BOUNDARY` marker) MUST NOT be rendered while a required co-review of the increment
   is pending/in-flight, or before that review's reviewed-tree digest matches the EXACT current digest
   and is clean or human-dispositioned.
2. A **blocked** review attempt MUST produce **no approval options and no verdict-boundary marker**.
3. A human question genuinely needed **during** review MUST be a **narrow, non-boundary decision** (no
   approval options, no marker) — never a lifecycle verdict packet.
4. The boundary packet is rendered **only after** the exact-current-digest review evidence is clean or
   human-dispositioned.

The failure mode this closes: a packet rendered during a blocked/superseded review (or against a stale
digest) could be captured — by a hook, a tokenizer, or a fallback path — as a human authorization for a
boundary whose increment was never cleanly reviewed. That is the same never-false-green / fabricated-
authorization class as DEC-198-GOV-001 and FR-041–FR-044, one layer up: not "was the turn human?" but
"was a verdict even ALLOWED to be solicited at this moment?".

## Contributing conditions observed this iteration

- **Concurrent reviews.** Manual `--live` runs and Stop-hook navigator auto-runs fired against the same
  lineage seconds apart, so a superseded review's findings and a fresh review's findings interleaved.
  This is exactly the in-flight-dedup + reviewed-tree-digest binding that T019 owns.
- **Digest churn.** Each fix + re-record changed the reviewed-tree digest, so a packet or a review
  result tied to an earlier digest was already superseded when surfaced. A verdict must bind to the
  EXACT current digest.

## Binding

- **T019 (in-flight/digest, FR-016/FR-017)**: the reviewed-tree-digest acceptance gate is the mechanism
  that decides "is there clean or human-dispositioned review evidence for the EXACT current digest?".
  A verdict/boundary packet is gated on that answer; an in-flight or digest-mismatched review blocks the
  packet. In-flight dedup ensures a superseded review cannot stand in for the current one.
- **T030–T032 (capture integrity, FR-041–FR-043)**: verdict capture MUST reject any approval/verdict
  rendered while a required co-review was pending/blocked, or against a superseded digest — such a
  packet is never authorization evidence. Add fixtures reproducing this stop-ordering sequence
  (blocked review present → verdict-shaped packet rendered → assert capture records nothing), alongside
  the FR-043 fabrication-sequence fixtures.

## Required behavior (maintainer spec, 2026-07-12)

### While a required co-review for the CURRENT digest is still RUNNING, a Stop event MUST NOT

render the six-section lifecycle packet, approval options, or a `SPECREW-VERDICT-BOUNDARY` marker.
Instead it MUST:

1. **Detect the single tracked in-flight review** for the current digest.
2. **Block lifecycle advancement internally** (no boundary crossing while the review runs).
3. **Tell the implementer to wait or poll that existing run — never launch a duplicate** review.
4. **Optionally** show the user ONE short progress sentence: review is running, no decision required.
5. **Never** ask the user to "nudge" or return later; the implementer owns waiting for completion.

### After the review reaches a TERMINAL state, route by outcome

- **Clean / current-digest result** → render the normal six-section boundary packet AND the exact
  marker (this is the only path that carries a lifecycle marker).
- **Actionable findings** → SUPPRESS the boundary packet and marker; fix and re-review.
- **Human judgment required** → ask ONLY the narrow non-boundary question, with no approval options and
  no marker.
- **Timeout / infrastructure failure** → report the SPECIFIC failure and apply the retry/spend policy;
  do NOT represent it as a clean review.

### Invariant

Blocked, pending, stale, and superseded review attempts MUST NEVER become verdict-capture evidence.
ONLY the final packet backed by ACCEPTED review evidence for the EXACT current digest may carry a
lifecycle marker. The final packet is bound to the accepted reviewed-tree digest.

### Regression coverage (required)

Paired tests for each state: **pending review** (no packet/marker; wait, no duplicate), **duplicate
Stop events** (a second Stop while one review is in flight does not launch a second review), **stale
completion** (a completed review whose digest ≠ current is superseded, not authoritative), **actionable
findings** (packet+marker suppressed; fix+re-review), **human-decision escalation** (narrow question
only, no options/marker, not captured as a verdict), **timeout/infra failure** (specific failure, not
clean), and **clean completion** (packet+marker rendered, bound to the accepted digest).

## Acceptance intent

When FR-045 is realized (via T019 + T030–T032), the assistant/host cannot render a boundary verdict
packet, and the capture layer cannot record an authorization, until the exact current digest carries
clean or human-dispositioned review evidence — a Stop during an in-flight review waits (no duplicate,
no packet), and a mid-review human question is structurally a narrow non-boundary decision, not a
solicitable verdict.

## Field evidence — autonomous/manual review collision (2026-07-12)

A concrete instance observed during the T015 / file-primary remediation, recorded per maintainer
instruction (rather than changing review scheduling now). Two review drivers ran against the same
working tree:

- the AUTONOMOUS continuous-co-review, fired by the Stop-hook navigator on nearly every assistant Stop; and
- MANUAL serialized reviews the maintainer requested, each preceded by a per-digest evidence re-record.

Because the manual cycle re-records implementer-evidence for the EXACT digest it then reviews, its runs
carried injected evidence (`implementer_evidence=true`) and cleanly certified the current digest. The
autonomous navigator, by contrast, materialized whatever transient working-tree digest each Stop landed
on — digests for which no matching evidence had been recorded — so it produced STALE blocking packets:

- runs `20260712T094204795` (ceiling escalation) and `20260712T115340210` / `20260712T140622099`
  (evidence-absent / stale-count findings) each blocked on a digest already fixed or superseded by a
  later commit + re-record;
- their findings were real for THEIR digest but not for the current one, so treating them as blocking
  authorization would have been the FR-045 failure class (a superseded/blocked packet standing in for a
  clean-current-digest review).

**Why this is FR-045 / T019 evidence, not a scheduling change**: the fix is not to silence the
autonomous loop but to make the acceptance gate DIGEST-EXACT and in-flight-aware — T019's
reviewed-tree-digest acceptance + in-flight dedup, and T030–T032's capture layer rejecting
blocked/superseded packets, are precisely what render a stale-digest navigator block non-authoritative.
This real collision is retained as the motivating field case for those tasks.
