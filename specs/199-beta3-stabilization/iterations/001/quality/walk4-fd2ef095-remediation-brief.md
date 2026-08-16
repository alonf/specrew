# Walk 4 (`fd2ef095`) — Remediation Brief

**Source**: manual Copilot walk with `claude-sonnet-4.6 (medium)` pinned.
**Status**: diagnostic evidence only. This is not `review.md` and authorizes nothing.

## What Worked

- Producer-level ordering enforcement caught the product-domain question before feature setup and
  gave the correct recovery action immediately.
- The calm refusal contract preserved the user's answers, prohibited hand-written workshop state,
  avoided assigning blame, and stopped rather than bypassing the gate.
- The four-walk failure trajectory improved monotonically: bypass, forensics, wasted confirmations,
  then a clean refusal with a proposed action.

These controls are acceptance evidence and must not be undone by the remediation.

## W14 — Pre-Agenda Product Projection Wedge

The product-domain phase was persisted before the technical agenda, as required. A weaker host also
projected that phase into the `workshop.product-domain` property. The agenda writer treated every
`workshop` property as a technical decision and refused to render the agenda.

The durable product-domain authority is the Markdown record, structured YAML record, and typed-turn
receipt. A redundant pre-agenda `product-domain` projection must be tolerated but never consumed as
technical-lens authority. A technical-lens projection before agenda confirmation must still refuse.
The confirmed agenda writer must remove the redundant projection when it writes canonical state.

## W15 — No Sanctioned Recovery

The refusal correctly prohibited editing `lens-applicability.json` by hand, but no governed repair
operation existed. The only action the agent could invent was the forbidden manual replacement,
offered after asking permission. This made any future inconsistent state a wedge by construction.

The required recovery is proposal-based and human-authorized: bind the proposed repair to the exact
feature and current state hash, preserve saved product-domain records byte-for-byte, require an exact
typed human authorization captured by the hook, refuse if state changes after authorization, and
write an audit record when applied.

## Class Closure — Finite Transition Population

The workshop has a small, bounded state population. The remediation must test every cell of an
explicit transition table rather than finding illegal transitions one manual walk at a time. The
minimum table covers eight representative states and six production operations (48 cells):

- missing state;
- canonical pending state;
- pending plus redundant product-domain projection;
- pending plus a technical record;
- pending plus selected lenses;
- pending plus agenda coverage;
- incomplete confirmed state;
- complete confirmed state;
- initialize, read, render agenda, confirm agenda, request repair, and apply repair.

The transition resolver must be consumed by the initializer, lifecycle reader, agenda writer, and
repair operation. The typed repair authorization must be consumed by the prompt-submit hook path.

## Acceptance

1. The real W14 state renders and confirms an agenda; a technical pre-agenda key still refuses.
2. Confirmation discards, rather than promotes, the product-domain projection.
3. All 48 transition cells pass deterministically without a model or provider.
4. Repair without exact typed authorization refuses and changes no state.
5. Authorization is state-hash-bound; post-authorization mutation refuses.
6. An authorized repair preserves product-domain files byte-for-byte and writes an audit record.
7. The next comparable walk uses a fresh fixture and the same pinned model.

## Automated Verification

- The transition table passed all 48 cells in 1.3 seconds.
- The focused workshop, authority, hook, refusal, agenda, controller, signoff, and multihost suites
  passed, including the real W14 state and the nonce-bound W15 repair lifecycle.
- The final curated release registry passed 124/124 suites in 2,123.351 seconds, including the
  deployed Copilot nested-skill detector added after the first walk-5 canary exposed a false
  empty-catalog warning.
- The final disk-wide census passed all 352 named PowerShell test files (121 Pester containers and
  231 direct scripts) in 4,203.6 seconds, with zero failures and no caller-tree contamination.

## Standing Release Blocks

- `specs/199-beta3-stabilization/iterations/001/review.md` is still absent.
- No review campaign evidence covers the current tree.

Neither block is changed by this remediation.
