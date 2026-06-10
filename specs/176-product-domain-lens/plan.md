# Implementation Plan: Product & Problem Domain Lens (first workshop lens)

**Branch**: `176-product-domain-lens` | **Date**: 2026-06-09 | **Spec**: file:///C:/Dev/Specrew-product-domain-lens/specs/176-product-domain-lens/spec.md
**Input**: Feature specification at file:///C:/Dev/Specrew-product-domain-lens/specs/176-product-domain-lens/spec.md; design analysis (Option B) at file:///C:/Dev/Specrew-product-domain-lens/specs/176-product-domain-lens/iterations/001/design-analysis.md

## Summary

Add a required first design-workshop lens `product-domain` that runs as a **new first-stage
phase ahead of the existing applicability selector** (design-analysis Option B). It captures
product/problem context at adaptive depth (Light/Standard/Deep by risk and novelty), tags
every material statement with an evidence quality, persists a human-readable
(`product-domain.md`) and a structured (`product-domain.yml`) record, summarizes decisions into
`spec.md`, and is enforced at the specify boundary by extending the existing lens gate with the
SC-026 confirmation provenance (rejecting batch approval). The lens runs before EVERY feature
(adaptive depth, `context_scope: feature_standalone` in V1); Proposal 162 later owns the
persistent product-level baseline + `feature_delta` inheritance. FR-007 (Proposal 156) and
FR-008 (Proposal 162) are forward-compatible shape only — both dependencies are unshipped.

## Technical Context

**Language/Version**: PowerShell 7+ (pwsh); Markdown; JSON + YAML data files.
**Primary Dependencies**: Pester (tests); PSScriptAnalyzer (lint); the existing Specrew design-lens
catalog and governance helpers (`scripts/internal/lens-applicability.ps1`,
`scripts/internal/design-analysis-gate.ps1`, the governance validator). No new runtime packages.
**Storage**: on-disk artifacts only — `product-domain.yml` + `product-domain.md` under
`specs/<feature>/workshop/`; catalog files under the design-lens catalog. No database.
**Testing**: Pester (`tests/unit`, `tests/integration`); Specrew mechanical-checks
(dead-field / anti-pattern / test-integrity); the governance validator; markdownlint.
**Target Platform**: cross-host — the five supported hosts (Claude, Copilot/GitHub, Codex/Agents,
Cursor, Antigravity); PowerShell helpers + the host-managed skill surfaces.
**Project Type**: governance/methodology tooling (PowerShell library + lens catalog + skill conduct).
**Performance Goals**: N/A — the lens is an interactive workshop phase; no runtime throughput target.
**Constraints**: reuse the existing catalog + skill + gate machinery (no parallel subsystem); keep
the deterministic selector pure; multi-host conduct parity; Proposals 156/162 forward-compatible
shape only; ~6-10 SP, single iteration; 20 SP iteration cap.
**Scale/Scope**: one new lens file + a structured-record schema + a record writer/validator + a
first-stage phase in the workshop conduct (4 surfaces) + a specify-gate floor extension + tests.

## Phase 1 Quality Planning

**Phase Scope**: `phase-1-first-slice`
**Inferred Quality Profile**: `quality-profile.powershell-governance-tooling.v1` *(CORRECTED — the
auto-resolver mis-inferred `quality-profile.react-spa-public.v1` from the repo root `package.json`;
drift D-003, maintainer-approved at the design-analysis verdict)*
**Selected preset ref or explicit custom composition**: bounded custom composition —
PowerShell/Pester + PSScriptAnalyzer + the Specrew mechanical-checks/validator (no react-spa bundle).
**Bounded custom composition**: there is no shipped PowerShell-governance preset; the bar is the
existing Specrew self-host tooling (Pester, PSScriptAnalyzer, mechanical-checks, the governance
validator, markdownlint) — the same bar prior governance features (141, 171) used.

### Stack Surfaces in Scope

| Stack Surface | Path Globs / Evidence | Recognized Stack | Why It Matters |
| --- | --- | --- | --- |
| `governance-scripts` | `scripts/internal/*.ps1`, `extensions/specrew-speckit/scripts/*.ps1` | `powershell-governance` | the record writer/validator + gate floor are PowerShell |
| `lens-catalog` | `extensions/specrew-speckit/knowledge/design-lenses/*` | `markdown+json` | the lens md + catalog registration |
| `workshop-conduct` | `.claude/skills`, `.cursor/rules`, `.github/skills`, `.agents/skills` | `skill-markdown` | the first-stage phase conduct (multi-host) |
| `feature-artifacts` | `specs/<feature>/workshop/product-domain.{yml,md}` | `yaml+markdown` | the per-feature records + schema |

### Risk Dimensions

| Risk Dimension | Status (`required` / `not-applicable`) | Rationale |
| --- | --- | --- |
| `code-quality` | `required` | PowerShell helpers must be PSScriptAnalyzer-clean and reviewable. |
| `design-quality-and-separation-of-concerns` | `required` | the first-stage phase must stay isolated from the deterministic selector (Option B). |
| `verification-confidence` | `required` | depth selection, evidence tags, FR-009, and the gate floor need behavior-proving Pester tests. |
| `maintainability` | `required` | the lens md + schema + conduct must stay in sync across host surfaces. |
| `security` | `required` (light) | no auth/secrets/PII/network; the only surface is evidence-integrity at the gate (deterministic). |
| `robustness` | `required` | graceful fail-open when the catalog/record/skill copy is absent — surfaced, never a silent skip. |
| `concurrency-correctness` | `not-applicable` | *(CORRECTED)* no realtime/session/shared-state behavior; the react-spa trigger was a false positive (D-003). |

### Quality Tool Bundle

| Area | Selection | Evidence / Notes |
| --- | --- | --- |
| Bundle ID | `powershell-governance-phase1` | matches the Specrew self-host bar |
| Mechanical Checks | dead-field, anti-pattern, test-integrity | `specs/176-product-domain-lens/iterations/001/quality/mechanical-findings.json` |
| Ecosystem Tools | Pester unit + integration; PSScriptAnalyzer lint; markdownlint; governance validator | free/community baseline |

### Required Quality Gates

| Required Quality Gate | Category | Evidence Source | Phase 1 Status |
| --- | --- | --- | --- |
| `dead-field` | mechanical | `iterations/001/quality/mechanical-findings.json` | planned |
| `anti-pattern` | mechanical | `iterations/001/quality/mechanical-findings.json` | planned |
| `test-integrity` | mechanical | `iterations/001/quality/mechanical-findings.json` | planned |
| `pester-unit-integration` | tooling | `tests/unit/product-domain-lens.tests.ps1`, `tests/integration/product-domain-multihost.tests.ps1` | planned |
| `psscriptanalyzer-lint` | tooling | CI / local PSScriptAnalyzer run | planned |
| `specify-gate-floor` | manual-evidence | `iterations/001/quality/quality-evidence.md` | planned |

### Not-Applicable Dimensions and Rationale

| Dimension / Gate | Why Not Applicable in This Feature | Follow-up |
| --- | --- | --- |
| `concurrency-correctness-review` | no concurrency/shared-state; react-spa trigger was a false positive | recorded as drift D-003 |
| browser/UI gates | agent-facing conduct + artifact files; no GUI | none |

### Explicit Phase 2+ Deferrals

- FR-007 (Proposal 156 `workshop-decisions.yml` emission) and FR-008 (Proposal 162 inheritance
  behavior) ship as forward-compatible shape only this iteration.
- Strongest-class routing enforcement and runtime-only proof remain deferred to later closure.
- Quality-drift logic and reference-implementation comparison remain deferred.

## Phase 2 Hardening and Specialist Review Planning

**Phase 2 Slice Scope**: `US-2 hardening-gate planning only` — planning-time analysis for the
specify-gate floor, the schema, and the multi-host deploy; runtime proof at beta validation.
**Hardening Gate Artifact**: `specs/176-product-domain-lens/iterations/001/quality/hardening-gate.md`
**Known-Traps Corpus Location**: `.specrew/quality/known-traps.md`
**Trap Reapplication Artifact**: `specs/176-product-domain-lens/iterations/001/quality/trap-reapplication.md` (none yet)

### Hardening Focus Areas

| Focus Area | Why It Matters in This Slice | Planned Artifact / Evidence | Status |
| --- | --- | --- | --- |
| Security surface analysis | the only new surface is evidence-integrity at the gate (no secrets/network); confirm the gate cannot be satisfied by batch approval (FR-009) | hardening-gate.md security section | required |
| Error handling and failure semantics | absent catalog / record / skill copy must fail-open with a surfaced WARN, never a silent skip of the grounding | hardening-gate.md robustness section | required |
| Retry and idempotency expectations | record writes are idempotent (re-running rewrites the same record); no retry logic needed | hardening-gate.md (not-applicable reasoning) | not-applicable |
| Test-integrity targets | depth selection, dual-artifact persistence, evidence-tagging, FR-009 non-equivalence, the gate floor, host-parity, SC-008 schema are the named Pester targets | test plan + quality-evidence.md | required |

### Lens Activation Plan

| Lens / Checklist Ref | Activation | Why Activated or Omitted | Planned Evidence / Artifact Path |
| --- | --- | --- | --- |
| `security-baseline@v1.0.0` | required (light) | evidence-integrity gate surface | `iterations/001/quality/lenses/security-baseline.md` |
| `robustness-baseline@v1.0.0` | required | fail-open graceful degradation | `iterations/001/quality/lenses/robustness-baseline.md` |
| `test-integrity@v1.0.0` | required | named Pester suites prove behavior, not file presence | `iterations/001/quality/lenses/test-integrity.md` |

### Routing Policy

| Lens Scope | Requested Reasoning / Review Class | Effective Class (when run) | Override / Approval Record | Notes |
| --- | --- | --- | --- | --- |
| Required hardening lenses | strongest-available | record when execution happens | none | planning baseline only |

### Explicit Later Deferrals

- Full line-by-line lens execution evidence and runtime-only proof are deferred to the
  implementation/review slice + beta validation.
- Known-traps seeding and trap reapplication are deferred until a dedicated slice.
- FR-007/FR-008 runtime wiring is deferred to Proposals 156/162.

## Constitution Check

- **Spec Authority Gate**: plan scope maps to spec FR-001..FR-014 and SC-001..SC-009; the
  design-analysis Option B is the approved architecture. Pass.
- **Layering Gate**: changes are the **Spec Kit extension layer** (design-lens catalog +
  design-analysis/specify-gate machinery) + **skill conduct** (the multi-host workshop) + PowerShell
  governance helpers. NOT the Squad layer; no team-config change. Pass.
- **Traceability Gate**: each deliverable links to FR/SC and a planned task in
  file:///C:/Dev/Specrew-product-domain-lens/specs/176-product-domain-lens/tasks.md (next phase). Pass.
- **Ownership Gate**: Implementer owns the lens md / record writer / gate floor / conduct / tests;
  Spec Steward owns FR-006 spec summary + FR-012 reframing; Reviewer owns the FR-009/FR-010 gate
  evidence. Pass.
- **Capacity Gate**: effort unit = story points; iteration cap 20 SP; this slice ~6-10 SP, single
  iteration (capacity planning confirms in tasks). Pass.
- **Drift/Reconciliation Gate**: drift-log.md carries D-001/D-002/D-003; the validator + the new
  specify-gate floor detect missing/malformed records + host-conduct drift. Pass.
- **Verification Gate**: Pester unit/integration + mechanical-checks + governance validator +
  host-parity + the SC-008 schema test; acceptance via the spec's SC-001..SC-009. Pass.

## Project Structure

### Documentation (this feature)

```text
specs/176-product-domain-lens/
├── spec.md
├── plan.md                      # this file
├── data-model.md                # Wave-B
├── quickstart.md                # Wave-B
├── contracts/                   # Wave-B (product-domain.schema.json + the public-surface contract)
├── review-diagrams.md           # Wave-B
├── lens-applicability.json      # feature-level intake workshop records
├── workshop/                    # per-feature workshop diagrams/records
├── gates/design-analysis-001.md # persisted design-gate packet
└── iterations/001/              # design-analysis.md, drift-log.md, state.md, quality/
```

### Source Code (repository root)

```text
extensions/specrew-speckit/knowledge/design-lenses/
├── product-domain.md            # NEW — the lens knowledge (decision areas, depth model, evidence vocab, conduct)
├── index.yml                    # EDIT — register product-domain as the first-stage lens
└── diagram-vocabulary.json      # EDIT — add the product-domain context diagram entry

scripts/internal/
├── product-domain-lens.ps1      # NEW — record writer/validator: scaffold + format + validate product-domain.{yml,md}
└── design-analysis-gate.ps1     # EDIT — extend the specify-boundary lens gate to require the product-domain record (FR-010)

.claude/skills/specrew-design-workshop/SKILL.md   # EDIT — run product-domain first (the first-stage phase)
.cursor/rules/specrew-design-workshop/SKILL.md    # EDIT — same conduct (managed-skill deploy)
.github/skills/specrew-design-workshop/SKILL.md   # EDIT — same conduct
.agents/skills/specrew-design-workshop/SKILL.md   # EDIT — same conduct (Codex + Antigravity)

specs/176-product-domain-lens/contracts/
└── product-domain.schema.json   # NEW — the product-domain.yml structured-record schema (156-forward-compatible)

tests/unit/product-domain-lens.tests.ps1          # NEW — depth, schema, evidence-tags, FR-009, gate floor
tests/integration/product-domain-multihost.tests.ps1  # NEW — host-skill parity
```

**Structure Decision**: Option B (a new first-stage workshop phase). The lens knowledge lives in
the catalog; the phase conduct lives in the `specrew-design-workshop` skill (deployed to the four
host surfaces); the record writer/validator is a new PowerShell helper; the enforcement extends the
existing specify-boundary lens gate. No new top-level directories; the deterministic selector is
untouched.

## Complexity Tracking

No Constitution violations to justify. Option B was chosen over the Option C generalized
pre-technical framework specifically to avoid premature complexity — the single new "first-stage
phase" concept is the minimum needed to honor FR-001, and it generalizes incrementally when a
second pre-technical lens (Proposal 164/175) is approved.
