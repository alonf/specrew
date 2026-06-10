# Drift Log: Iteration 001

**Schema**: v1

<!--
  Markdown authoring note (Specrew lifecycle convention):

  When you add new drift events to this file, watch for MD032 (blanks-around-lists).
  A sentence ending with a colon, immediately followed by a bullet list, is the most
  common violation. Always put a BLANK LINE between the colon line and the list:

      BAD:                              GOOD:
      Resolution steps:                 Resolution steps:
      - Step one                        <— blank line here
      - Step two                        - Step one
                                        - Step two

  The F-033 pre-boundary markdownlint gate runs markdownlint-cli --fix on .md
  changes before every boundary-sync write, so most violations auto-fix — but the
  blank line you write in the first place avoids the cleanup churn.
-->

## Summary

**Total drift events**: 1
**Resolution rate**: 100% (1/1 resolved)
**Specification drift**: 1 plan→implement variance (registration mechanism), resolved

## Events

### D-001: Registration mechanism — conduct-driven, not a deterministic applicability-map entry

**Detected**: 2026-06-10, during T004 (registration). **Class**: plan→implement variance (Proposal 174).

**What**: plan.md / tasks.md / design-analysis listed an `applicability-map.json` entry among the
registration surfaces. Implementation does NOT add code-implementation to the deterministic
applicability-map, because that map hard-codes a 6-question / 9-lens / 3-always-on contract asserted by
`tests/unit/lens-applicability-selector.tests.ps1` (always_on == 3, questions == 6, all-yes == 9 lenses).
Adding code-implementation as a 7th question would make code quality opt-in; adding it as a 4th always_on
would force it onto doc-only features and break the foundational-lens semantic + tests.

**Resolution** (implementation-choice): register code-implementation in `index.yml` + the `$lensIds`
conduct list (done in T004) and select it via the **workshop conduct** for code features (auto-on,
skip-for-doc-only) — exactly like the `product-domain` lens, which is in `index.yml` but NOT in the
applicability-map (`product-domain.tests.ps1` asserts that). The conduct selection ships in iteration 002
(T012). This preserves the deterministic-selector contract and matches precedent; the behavioral intent
(always-applicable-for-code, skip-for-doc-only) is unchanged.

**Impact**: none to intent; mechanism is conduct, not the deterministic map. Surface at review-signoff
(Proposal 174 variance disclosure). **Status**: resolved.

### Resolution Strategies (Unused)

The following resolution strategies remain available if drift is detected later in execution:

- **spec-updated**: Update the spec to reflect implementation choice
- **implementation-reverted**: Revert implementation to match spec
- **deferred**: Mark drift as deferred to next iteration
- **human-decision**: Escalate to Alon for resolution

### Notes

- This artifact was scaffolded before review starts so drift can be logged immediately when detected.
- Replace the zero-drift summary with real counts when the first drift event is recorded.
