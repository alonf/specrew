# Code & Implementation Workshop Record: Work Kind and Branch Governance Model

**Feature**: 182-work-kind-branch-governance
**Auto-on**: code feature (writes PowerShell + data + tests)
**Confirmation**: human-confirmed (lens-question)
**Manifest**: [implementation-rules.yml](../implementation-rules.yml)

```text
DESIGN-TIME (this lens)            →  implementation-rules.yml (reference-by-ID)  →  IMPLEMENT-TIME (specrew-code-rules)
  source-of-truth · stack ·            selections + decisions + dependency_policy     surfaces chosen rules to the agent
  baseline (exceptions only) ·
  consequential forks · deps
```

## Decisions

- **Source of code-rules truth**: emulate Specrew's existing PowerShell conventions (the
  module-function patterns in `extensions/specrew-speckit/scripts/*` + the existing
  `code-rules.yml` catalog); no external guideline.
- **Resolved stack**: PowerShell 7+ module functions + YAML/JSON data + JSON-schema + Pester
  tests + markdown surfaces.
- **Baseline craft**: Specrew defaults accepted (intent-revealing names, short functions,
  low nesting, SOLID/single-responsibility, object invariants, no magic values, no leaky
  internals). No baseline exceptions beyond the two recorded below.
- **Consequential forks**:
  - **Error handling → fail-open + WARN** (`idiomatic-error-handling`, `robustness-state-boundaries`):
    validator/detector never throw or block spuriously; structured verdicts; malformed/unknown
    → WARN + neutral; advisory by default. Binds DP-A5/DP-I4.
  - **Strategy over conditionals** (`strategy-state-over-repeated-conditionals`,
    `polymorphism-mechanism`, `anti-corruption-layers`, `extension-points`): `ProviderAdapter`
    is a Strategy / anti-corruption layer (github | generic | synthesized) dispatched by the
    contract; no central provider `switch`; the core imports no forge tool.
  - **Testing** (`simple-trustworthy-tests`, `testing-posture`): Pester on pure logic +
    denial-path + fail-open + catalog-integrity + multi-host parity; behavior, not file-presence.
  - **Public contracts** (`api-service-design`, `public-api-reusable-design`): catalog schema +
    declaration + adapter contract carry `schema_version`, stable IDs, deprecate-not-delete.
  - **Security** (`secure-coding-defaults`, `authz-security-context`): no secrets in scripts;
    `gh` confined to the GitHub adapter; least-privilege token scopes; `apply_protection`
    human-gated.
  - **Dependency injection** (`dependency-injection`): the validator takes the adapter as an
    injected dependency (enables git-diff fallback + tests).
  - **Packaging** (`shared-code-packaging`, `lts-version-check`): ship via the module (FileList +
    `extension.yml` bump + `.specify` mirror parity); PowerShell 7+ baseline.
- **Recorded baseline exceptions**: `concurrency-over-locks` (no concurrency surface),
  `evidence-driven-performance` (performance is an explicit non-driver).
- **Dependency policy (FR-013)**: `use-existing-no-new-dependency` — PowerShell + Pester + git +
  Specrew's existing YAML handling; `gh`/GitHub API is an existing dependency confined to the
  GitHub adapter; the core + generic fallback use pure git. No new runtime dependency.

## Run cadence

`feature_standalone` (V1). Forward-compatible with Proposal 162 product-baseline inheritance.
