# Product-domain scope: beta4.1

**Feature**: 202-beta4-1-ux-stabilization
**Depth**: Light. The product and users are established; this is a bounded defect sweep.
**Confirmation**: human-confirmed / lens-question. The maintainer typed `move on` to the scope presented on Claude, 2026-10-13. Workshop receipt `34cc2b6996b11d959255ad05b7fe44bfb1e0dcd783e0233bc9a77a03aff8bb37` (feature 202, product-domain, host claude, 08:51:13Z).
**History**: the earlier Codex-authored records, written before any receipt existed, are preserved in `preserved-product-answers/`. See intake-drift-log.md entries 001 to 006 and B4F-108.

## Users and problem

[known] Specrew developers and the maintainer lose time to unrelated stops, repeated corrective replies, stale work context and refusals without a forward action. Today's workarounds are manual context reconciliation, packet and draft corrections, and artifact re-reading.

## Tier 1 - iteration 1

[known] B4F-104 (unchanged pending crossing repainted every turn), B4F-106 (missing dials line costs a conformance cycle), B4F-100 (whole-draft visibility rejects a tightened packet), B4F-102 (design-analysis refusal omits the producing step), B4F-105 (dashboard and lifecycle state select different features), B4F-089 (resume narrates a stale handover), B4F-101 (turn drafts have no fixed ignored location), B4F-107 (dials are numbers on Codex, prose on Claude).

[known] B4F-096 (late orientation demand), reproduced by a controlled replay against installed beta4 `8d3f9906`. It is a replay, not a live session. Evidence: evidence/b4f096-installed-beta4.json and conditional-findings.md.

[known] B4F-108: a transient journal-lock failure silently blocks every workshop receipt. Three defects: the failure latches permanently; the latch is undisclosed, so turns are consumed silently; the refusal names a "selection channel" instead of the marker. Acceptance: the same workshop flow (product-domain, agenda, one lens) produces receipts and closes each checkpoint with the same number of replies on Claude, Codex and Copilot.

[research-needed, not load-bearing] Codex has not yet been tested on a healthy worktree.

## Tier 2 - iteration 2

[known] Starts only after the human accepts Tier 1; green tests do not start it. Contents: the narrow review-ordering slices of B4F-054/056/058/061 bounded by B4F-074, B4F-093 and B4F-103. B4F-103 is a package-comparison correction with no beta4 republish. No broader review redesign.

## Out of scope (beta5)

[known] Both B4F-039 sub-findings; B4F-090; B4F-091 band semantics (B4F-107 changes presentation only); broader review redesign; every other beta5 item in finding-inventory.md.

## Friction measures

[known] For each included scenario: before/after extra-stop and reply counts, separating real decisions from corrective exchanges; elapsed time where observable; a missing value is recorded as not captured, never zero; after-fix values only from real runs.

## Constraints

[known] Branch from `24e5701a`, not main; merging to main is a later, separate decision. No planning or implementation before the specify verdict. Historical validator failures (review-evidence, defer-provenance, the 198/011 needs-rework verdict) are known baseline and are listed in the spec; new findings in those categories are compared against that baseline.
