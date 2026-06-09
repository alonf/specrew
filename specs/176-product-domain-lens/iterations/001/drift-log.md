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

**Total drift events**: 3
**Resolution rate**: 100% (3/3 reconciled with explicit paths)
**Specification drift**: 2 dependency-deferrals + 1 quality-profile stack mis-inference, all reconciled below

## Events

### D-001 — FR-007 deferred (Proposal 156 `workshop-decisions.yml` absent)

- **Requirement citation**: FR-007 (structured product-domain record feeds Proposal 156 `workshop-decisions.yml`).
- **Drift**: the consumer artifact `workshop-decisions.yml` does not exist on disk; the emission path cannot be implemented this iteration.
- **Resolution strategy**: `deferred`. Build the structured `product-domain.yml` *forward-compatible* with 156's consumer shape (schema-tested per SC-008); wire the actual emission when 156 ships. Reconciliation owner: Planner.

### D-002 — FR-008 deferred (Proposal 162 product-level context absent)

- **Requirement citation**: FR-008 (feature-level lens inherits Proposal 162 product-level context and records deltas).
- **Drift**: the two-tier product-level context does not exist on disk; inheritance behavior cannot be implemented this iteration.
- **Resolution strategy**: `deferred`. Record feature-only context now; include a stable optional `product_id` / `product_context_ref` field in `product-domain.yml` (maintainer instruction at the clarify→plan verdict) so 162 inheritance connects later without redesign. No inheritance behavior built now. Reconciliation owner: Planner.

### D-003 — Quality-profile stack mis-inference (react-spa-public false positive)

- **Requirement citation**: Governance Alignment quality bar; Rule 25 (derive the quality bar from the feature); stack-aware-tool-selection (per-project stack needs human approval).
- **Drift**: `resolve-quality-profile.ps1` inferred `quality-profile.react-spa-public.v1` (browser-UI + concurrency-correctness) by matching the repo root `package.json`/react dependency. The actual feature stack is PowerShell governance tooling (lens markdown, PowerShell functions, JSON/YAML artifacts, skill conduct) — no browser UI, no concurrency.
- **Resolution strategy**: `human-decision`. Surface the stack correction at the design-analysis stop for maintainer sign-off; embed the corrected PowerShell quality bar (Pester + PSScriptAnalyzer + Specrew mechanical-checks/validator) in `plan.md`, not the react-spa profile. Reconciliation owner: Alon (stack approval) → Planner (plan embed).

### Resolution Strategies (Unused)

The following resolution strategies remain available if drift is detected later in execution:

- **spec-updated**: Update the spec to reflect implementation choice
- **implementation-reverted**: Revert implementation to match spec
- **deferred**: Mark drift as deferred to next iteration
- **human-decision**: Escalate to Alon for resolution

### Notes

- This artifact was scaffolded before review starts so drift can be logged immediately when detected.
- Replace the zero-drift summary with real counts when the first drift event is recorded.
