# Release Validation Record (template)

A **post-merge** validation record — beta/stable/CI/docs learning captured **after** a feature merged,
**separate** from that feature's `feature-closeout`. It references the merged feature; it does **not**
reopen it. Any finding that needs a change becomes a **new** PR-backed work item.

**Merged feature**: `<feature-ref>` (e.g. 182-work-kind-branch-governance)
**Merge commit**: `<hash>`
**Validated artifact**: `<beta version / stable tag / CI run / published package>`
**Validated by**: `<role/person>`
**Date**: `<YYYY-MM-DD>`

## Findings

| # | Finding | Severity | Disposition (NEW work item) |
| --- | --- | --- | --- |
| 1 | `<what was observed during release/post-merge validation>` | `<info/minor/major>` | `<docs-only / devops / bug-bash + PR ref, OR "none">` |

## New work items created

- `<kind>`: `<title>` → `<PR ref>` *(never a reopen of the merged feature)*

## Notes

- The merged feature's closeout artifacts are **not** edited. Corrections are small new PRs.
- If validation produced no findings, record that explicitly (the record still documents the
  validation happened).
