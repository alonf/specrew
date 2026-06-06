# Drift Log: Iteration 006

**Schema**: v1

<!--
  Markdown authoring note: keep a BLANK LINE between a colon-terminated sentence and a
  following bullet list (MD032), and never start a wrapped prose line with `+`/`*` (the
  F-033 markdownlint --fix gate rewrites a leading `+` into a `-` bullet and corrupts prose).
-->

## Summary

**Total drift events**: 0 (no mid-flight specification drift)
**Resolution rate**: 100% (2/2 re-scopes resolved via recorded deferral)
**Specification drift**: None detected mid-implementation; two post-dogfood re-scopes recorded up front.

## Events

No silent specification drift during Iteration 006. The implementation followed the design-analysis
Option B decision (`3e610c4a`). Two re-scopes were surfaced by the maintainer's downstream
human-experience dogfood at review-signoff and recorded **up front** (spec Amendment A4 + the canonical
defer entry in `.squad/decisions.md`), not resolved silently in code:

1. **FR-025 workshop re-scope** — the intake is an interactive questionnaire, not the intended per-lens
   workshop. Resolution: **deferred** to Amendment A4 / Iteration 7 (engine retained). Human decision.
2. **T003 / FR-009 per-phase decision-point flow** — only the high-level Rule 9a sentence shipped.
   Resolution: **deferred** to Iteration 7 (subsumed by the workshop).

### Resolution Strategies (applied / available)

- **deferred** (applied to both above): marked deferred to Iteration 7 with maintainer approval (see
  `.squad/decisions.md` → "Feature 141 Iteration 006 Gap Ledger Deferrals").
- **human-decision** (applied): the maintainer directed the A4 re-scope and the "Continue 141" container.
- **spec-updated**: Amendment A4 records the workshop redefinition.
- **implementation-reverted**: unused (no code reverted; the deterministic engine stands).

### Notes

- Scaffolded at closeout (Iteration 6 ran without a separate drift event during implementation).
- The two re-scopes are deferrals to Iteration 7, not defects in Iteration 6's delivered code.
