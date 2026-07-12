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

## Acceptance intent

When FR-045 is realized (via T019 + T030–T032), the assistant/host cannot render a boundary verdict
packet, and the capture layer cannot record an authorization, until the exact current digest carries
clean or human-dispositioned review evidence — and a mid-review human question is structurally a narrow
non-boundary decision, not a solicitable verdict.
