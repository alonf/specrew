# Test Integrity Lens: Iteration 001

**Feature**: 168-post-ship-proposal-amendment-discipline
**Status**: recorded

## Focus

- Tests must use synthetic proposal fixtures.
- Tests must cover unsafe shipped/superseded edits, allowed corrections, candidate/draft edits, active proposal exclusion, malformed amendments, reviewer guidance, and status surfacing.
- Tests must not claim real shipped proposal bodies were validated by editing those bodies.

## Evidence

- Focused replay passed with `PASS: Feature 168 post-ship proposal amendment validator, docs, status, and mirror coverage`.
- Markdownlint passed across methodology docs, proposal index, fixtures, and Feature 168 lifecycle markdown.
- Scoped governance validation passed; remaining warnings are out-of-scope legacy validator drift.
