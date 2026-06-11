# Drift Log: Iteration 002

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

**Total drift events**: 2
**Resolution rate**: 100% (2/2 recorded with a resolution: 1 accepted variance, 1 deferred-with-gate)
**Specification drift**: None (both events are implementation/process variances, not spec drift)

## Events

### D-002 -- Manifest capture changed from a PowerShell writer-call to hand-authored (T012/T013)

- **Date**: 2026-06-10
- **What changed**: the design-workshop code-implementation conduct (T012/T013) originally told the
  facilitating agent to CALL the PowerShell writer `New-SpecrewImplementationRulesManifest` to persist
  `implementation-rules.yml`. It now tells the agent to HAND-AUTHOR the manifest against
  `implementation-rules.schema.json` -- the shipped `product-domain` pattern.
- **Why**: on the deployed module the facilitating agent cannot reach `scripts/internal` from a downstream
  project (it is not mirrored into the project) and non-PowerShell hosts cannot run it mid-workshop, so the
  writer-call path would hard-fail or produce a false PASS at the dogfood. Surfaced by advisor review before
  the dogfood ran.
- **Same intent**: the manifest is still captured and schema-valid; only the authoring mechanism changed.
  `New-SpecrewImplementationRulesManifest` and the YAML writer are now TEST-ONLY by design (exactly like
  `product-domain`'s unused writer).
- **Resolution**: human-decision -- ACCEPTED VARIANCE (the maintainer directed recording it as an accepted
  variance at the 2026-06-10 review-signoff rejection).
- **Status**: resolved (accepted).

### D-003 -- T017 behavioral success criteria deferred-with-gate to the published beta

- **Date**: 2026-06-10
- **What**: the T017 deployed-module dogfood PASSED for deployment wiring + manifest-authoring (objectively
  checked: staged FileList-only 0.35.0 module, downstream catalog/skill/lens deployment, hand-authored
  manifest schema+catalog valid). The BEHAVIORAL success criteria -- SC-004 (the agent is actually guided),
  SC-007 (the human is not walled), SC-008 (the dependency stance is actually honored) -- were NOT
  established, because autonomous artifact inspection (and the author grading their own artifacts) cannot
  establish behavior, and this project has under-surfacing precedent (testLenses8/11; the workshop
  Approve+Delegate collapse).
- **Resolution**: deferred + human-decision (GATE). The definitive SC-004 / SC-007 / SC-008 confirmation is
  DEFERRED to the published `v0.35.0-beta.1` install-dogfood -- the human-on-host run mandated by the
  beta-before-stable policy. **Gate**: that beta validation MUST confirm SC-004 / SC-007 / SC-008 before the
  0.35.0 line is promoted to stable.
- **Approved by**: maintainer (Alon), 2026-06-10 -- the review-signoff rejection explicitly offered and
  approved this variance / defer-with-gate.
- **Status**: deferred-with-gate (open until the published-beta validation at feature-closeout).

### Notes

- D-001 (feature-level) is the conduct-driven lens registration decision (code-implementation is NOT a row
  in the deterministic `applicability-map.json`, like `product-domain`), recorded with the feature scope.
- Resolution strategies in use: `human-decision` (D-002, D-003) and `deferred` (D-003 gate). Still
  available if later drift is detected: `spec-updated`, `implementation-reverted`.
