# Quickstart: Code & Implementation Lens

**Feature**: 177-software-development-rules-lens
**Last verified**: 2026-06-10 (planning artifact — verified at implement/dogfood)

## Run it

```text
# 1. Run the design workshop on a feature; the code-implementation lens turn runs automatically
#    for any code-writing feature (always-applicable-for-code, with explicit skip for doc-only).
# 2. Inspect the catalog + the per-feature manifest:
pwsh -File scripts/internal/code-implementation-lens.ps1 -Validate -ProjectPath . -Feature <feature>
# 3. Run the lens tests:
Invoke-Pester tests/unit/code-implementation-lens.tests.ps1
Invoke-Pester tests/integration/code-rules-skill-multihost.tests.ps1
```

## Try the canonical scenario

1. Start a feature whose implementation writes code (e.g., a C#/.NET utility). The workshop reaches the
   **code-implementation** lens turn.
2. **Guideline-first**: the lens asks "do you have an existing coding guideline (yours/company)? paste,
   point, or no." Say "no" for this run.
   - *Expected*: the lens proceeds to Specrew defaults pre-checked.
3. **Resolve stack**: pick `C#/.NET`.
   - *Expected*: only the C#/.NET slice + cross-language baseline are loaded (no C++/React noise).
4. **Grouped checklist**: review the pre-checked cross-language baseline (one summary, exceptions only),
   the C#/.NET group, and answer the handful of decision-prompts (concurrency, copy semantics, etc.).
   Uncheck one baseline rule and add one custom rule.
   - *Expected*: a schema-valid `specs/<feature>/implementation-rules.yml` is written with the selected
     ids, the unchecked exception, the custom rule, and `context_scope: feature_standalone`; plus
     `specs/<feature>/workshop/code-implementation.md`.
5. **Dependency selection (FR-013)**: if the feature might add a package, the lens presents "use existing
   project tools / no new dependency" first; choose to add one and capture its fields.
   - *Expected*: a `dependency_policy` block is persisted in the manifest.
6. **Implement time**: the `specrew-code-rules` skill resolves the active feature, reads the manifest, and
   surfaces the baseline + this feature's overlay + the dependency policy to the coding agent.
   - *Expected (SC-004/SC-008)*: generated code reflects the chosen rules + honors the dependency stance,
     without the maintainer re-pasting rules.

## Verify the edge cases

- **No manifest** (a quick change with no workshop): the skill still surfaces the catalog
  `baseline-default` rules (SC-006, baseline mode).
- **Unknown rule id** (catalog changed): the skill warns and skips the unknown id (fail-open), never crashes.
- **Company guideline pasted**: the lens maps it onto the catalog (auto-checks matches, flags conflicts),
  extracts non-catalog rules as custom items with provenance, and (org-level) offers to save them to
  `code-rules.local.yml` for reuse across features.
- **Multi-host**: after `specrew init` / `update`, `specrew-code-rules` is present and identical in every
  host skill dir (SC-003, parity test).
