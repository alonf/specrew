# Contract: Product-Domain Lens Public Surface

**Feature**: 176-product-domain-lens
**Stability**: pre-1.0

## product-domain-lens.ps1 (PowerShell record writer/validator)

The new helper at `scripts/internal/product-domain-lens.ps1` owns scaffolding, formatting, and
validating the product-domain record. Pure + deterministic; no network/LLM. Mirrors the existing
`lens-applicability.ps1` style (graceful degradation, UTF-8 no-BOM writes).

### Exported API

| Symbol | Signature | Purpose | Errors |
| --- | --- | --- | --- |
| `New-SpecrewProductDomainRecord` | `(-FeatureDir <string> -Record <object> [-Force]) : string` | persist a built record object to `workshop/product-domain.yml` + `.md` (UTF-8 no-BOM) | returns the existing `.yml` path unless `-Force` (and regenerates a missing `.md`); throws when `-Record` is null |
| `Get-SpecrewProductDomainDepth` | `(-Risk <string> -Novelty <string>) : string` | map risk/novelty signals to `light\|standard\|deep` (FR-002) | never throws; defaults to `standard` when ambiguous |
| `Test-SpecrewProductDomainRecord` | `(-Path <string>) : string[]` | validate the record against the schema (required fields, evidence tags, confirmation provenance, context_scope enum) | returns error list (empty = OK); graceful `@()` when absent |
| `Format-SpecrewProductDomainSummary` | `(-Path <string>) : string` | render the `spec.md` product-domain summary (FR-006) | graceful "none recorded" |
| `Test-SpecrewProductDomainResearchBlock` | `(-Path <string>) : string[]` | return load-bearing `research-needed` statements that block the plan boundary (FR-011) | `@()` when none load-bearing |

### Invariants

- A batch/agenda approval can never produce `confirmation: human-confirmed` (FR-009) — the gate
  rejects it.
- `context_scope = feature_standalone` in V1; `product_baseline` / `feature_delta` validate in the
  schema but have no behavior until Proposal 162.
- Record writes are idempotent: re-running with the same inputs rewrites an equivalent record.
- Absent catalog / record → graceful fail-open with a surfaced WARN; never a silent skip.

## Specify-gate floor extension (design-analysis-gate.ps1)

`Invoke-SpecrewSpecifyBoundaryLensGate` is extended to additionally require, for a substantive
feature, a valid product-domain record before the specify boundary syncs (FR-010).

| Symbol | Signature | Purpose | Errors |
| --- | --- | --- | --- |
| `Test-SpecrewProductDomainGate` | `(-ProjectRoot <string> -FeatureRef <string>) : pscustomobject` | require `workshop/product-domain.{yml,md}` present + schema-valid + non-batch confirmation provenance | throws (fail-closed) with the missing/invalid reason; `$null` graceful skip when the lens catalog is absent or the feature is trivial |

### Invariants

- Marker-gated + grandfather-safe (the SC-021/SC-025 precedent): pre-176 features without a
  product-domain record are not retroactively failed.
- The gate checks PRESENCE + schema + provenance only — it cannot judge whether the grounding is
  genuine (that is the runtime dogfood + reviewer's discriminator).

## Catalog contract (index.yml + product-domain.md)

- `index.yml` gains a `product-domain` entry with a `default_phase` marking it the first-stage lens
  (NOT a row in `applicability-map.json`; the deterministic selector stays pure).
- `product-domain.md` follows the lens-template sections plus a `## Depth Model`, `## Evidence
  Vocabulary`, and `## Run Cadence` section (the maintainer rule).

## Workshop conduct contract (the first-stage phase)

The `specrew-design-workshop` skill runs the product-domain phase FIRST (before the applicability
agenda). It loads `product-domain.md`, selects depth by risk/novelty, reframes a solution-first
request into the problem, captures evidence-tagged answers, writes the record, and never accepts a
batch "confirm all" as the product-domain confirmation. Identical across the four host surfaces.
