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
**Specification drift**: 1 reconciled (artifact-format detail)

## Events

### D-001 — Catalog format: refocus-scopes.yml → refocus-scopes.json (resolved: spec-updated)

- **Requirement**: FR-003 (data-driven scope catalog with required `schema_version`)
- **Detected**: 2026-06-07, T001 implementation (engine catalog reader)
- **What drifted**: the spec/plan/contract named the catalog `refocus-scopes.yml`; the implementation ships `refocus-scopes.json`.
- **Why**: the repository deliberately avoids a powershell-yaml / `ConvertFrom-Yaml` dependency (documented in `scripts/internal/yaml-list.ps1`; precedent in `scripts/internal/host-history.ps1` which chose JSON for exactly this reason). A hand-rolled nested-YAML parser would be new risk surface for zero requirement value — FR-003's substance (data-driven, schema-versioned, additive evolution, fail-open on mismatch) is format-agnostic and fully preserved.
- **Resolution**: spec-updated — living artifacts (spec.md FR-003, plan.md, tasks.md T003, contracts, data-model.md) say `refocus-scopes.json` as of the T002/T003 commits; workshop records stay as historical agreements. Engine comment + this entry carry the rationale.

### Resolution Strategies (Unused)

The following resolution strategies remain available if drift is detected later in execution:

- **spec-updated**: Update the spec to reflect implementation choice
- **implementation-reverted**: Revert implementation to match spec
- **deferred**: Mark drift as deferred to next iteration
- **human-decision**: Escalate to Alon for resolution

### Notes

- This artifact was scaffolded before review starts so drift can be logged immediately when detected.
- Replace the zero-drift summary with real counts when the first drift event is recorded.
