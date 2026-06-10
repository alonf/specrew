# Implementation Plan: Code & Implementation Lens (software-development-rules workshop lens)

**Branch**: `177-software-development-rules-lens` | **Date**: 2026-06-10 | **Spec**: file:///C:/Dev/Specrew-software-development-rules-lens/specs/177-software-development-rules-lens/spec.md
**Input**: Feature spec at file:///C:/Dev/Specrew-software-development-rules-lens/specs/177-software-development-rules-lens/spec.md; design analysis (Option B) at file:///C:/Dev/Specrew-software-development-rules-lens/specs/177-software-development-rules-lens/iterations/001/design-analysis.md

## Summary

Add a `code-implementation` design-workshop lens (design-analysis **Option B**: the full feature,
self-contained, **no 145 gate**). A data-driven `code-rules.yml` catalog (the 49 maintainer rules +
per-stack defaults, each with a stable `id` / `group` / `scope`) is presented in the workshop via a
guideline-first, grouped, pre-checked set/unset checklist; the human's selections (plus custom rules and
a `dependency_policy` from the FR-013 Tooling/Dependency Selection Research decision area) are written to
a per-feature reference-by-ID `implementation-rules.yml` manifest. A new static, multi-host
`specrew-code-rules` skill resolves the active feature, reads the manifest at the known location, and
composes a **baseline + per-feature overlay** to actively guide the coding agent at implement time.
`plan.md` converts selected rules into implement constraints and the Implementer charter carries a thin
pointer to the skill. Forward-compatible with Proposals 156 (`workshop-decisions.yml`) and 162
(`context_scope` inheritance); the full coupling-catalog + dependency-report automation (097/122/178)
stay out of scope.

## Technical Context

**Language/Version**: PowerShell 7+ (pwsh); Markdown; JSON + YAML data files; host skill markdown.
**Primary Dependencies**: Pester (tests); PSScriptAnalyzer (lint); the existing Specrew design-lens
catalog, the `specrew-design-workshop` skill, the managed-skill deploy engine
(`extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1`), and the governance validator. No new
runtime packages.
**Storage**: on-disk only — shipped catalog `code-rules.yml` + lens md + `implementation-rules.schema.json`
under the design-lens catalog; per-feature `implementation-rules.yml` + `workshop/code-implementation.md`
under `specs/<feature>/`; optional project overlay `code-rules.local.yml`. No database.
**Testing**: Pester (`tests/unit`, `tests/integration`); Specrew mechanical-checks (dead-field /
anti-pattern / test-integrity); the governance validator; markdownlint.
**Target Platform**: cross-host — the five supported hosts (Claude, Copilot/GitHub, Codex/Agents, Cursor,
Antigravity); PowerShell helpers + the host-managed skill surfaces.
**Project Type**: governance/methodology tooling (PowerShell library + lens catalog + skill conduct + a
new guidance skill).
**Performance Goals**: N/A — interactive workshop + an implement-time reader skill; no runtime throughput target.
**Constraints**: reuse the existing catalog + skill + deploy + gate machinery (no parallel subsystem);
**no 145 mechanical gate / no parallel code-quality engine**; data-driven catalog (one source of truth,
stable IDs); fail-open everywhere; multi-host conduct + skill parity; Proposals 156/162 forward-compatible
shape only; ~2 iterations; 20 SP iteration cap.
**Scale/Scope**: one lens md + one catalog + one manifest schema + registration edits + the
`specrew-design-workshop` conduct edit + one NEW guidance skill (multi-host) + plan/implement wiring +
tests.

## Phase 1 Quality Planning

**Phase Scope**: `phase-1-first-slice`
**Inferred Quality Profile**: `quality-profile.powershell-governance-tooling` — bounded custom composition
(the auto-resolver returned `bounded-custom-composition`; the bar is the existing Specrew self-host tooling,
same as features 141 / 171 / 176).
**Selected preset ref or explicit custom composition**: bounded custom composition — PowerShell/Pester +
PSScriptAnalyzer + the Specrew mechanical-checks/validator + markdownlint.

### Stack Surfaces in Scope

| Stack Surface | Path Globs / Evidence | Recognized Stack | Why It Matters |
| --- | --- | --- | --- |
| `governance-scripts` | `scripts/internal/*.ps1`, `extensions/specrew-speckit/scripts/*.ps1` | `powershell-governance` | the manifest writer/validator + plan/implement wiring are PowerShell |
| `lens-catalog` | `extensions/specrew-speckit/knowledge/design-lenses/*` | `markdown+yaml+json` | the lens md + `code-rules.yml` catalog + the manifest schema + registration |
| `workshop-conduct` | `.claude/skills`, `.cursor/rules`, `.github/skills`, `.agents/skills` | `skill-markdown` | the code lens turn in `specrew-design-workshop` + the NEW `specrew-code-rules` skill (multi-host) |
| `feature-artifacts` | `specs/<feature>/implementation-rules.yml`, `specs/<feature>/workshop/code-implementation.md` | `yaml+markdown` | the per-feature manifest + record |

### Risk Dimensions

| Risk Dimension | Status (`required` / `not-applicable`) | Rationale |
| --- | --- | --- |
| `code-quality` | `required` | PowerShell helpers + the skill resolver must be PSScriptAnalyzer-clean and reviewable. |
| `design-quality-and-separation-of-concerns` | `required` | catalog (data) / manifest (selection) / skill (delivery) must stay separate; content out of the system prompt. |
| `verification-confidence` | `required` | registration, catalog integrity, manifest schema, parity, baseline+overlay, and dependency-capture need behavior-proving Pester tests. |
| `maintainability` | `required` | one source of truth (catalog, stable IDs); add/change a rule = edit the catalog only; multi-host parity. |
| `security` | `required` (light) | no auth/secrets/PII/network in the feature; the catalog's secure-coding rules are content, not the feature's surface. |
| `robustness` | `required` | fail-open when manifest/catalog/overlay/skill copy is absent or malformed — surfaced WARN, never a crash or silent skip. |
| `concurrency-correctness` | `not-applicable` | no realtime/shared-state behavior; the lens is interactive + the skill is a read-only reader. |

### Quality Tool Bundle

| Area | Selection | Evidence / Notes |
| --- | --- | --- |
| Bundle ID | `powershell-governance-phase1` | matches the Specrew self-host bar |
| Mechanical Checks | dead-field, anti-pattern, test-integrity | `iterations/<NNN>/quality/mechanical-findings.json` |
| Ecosystem Tools | Pester unit + integration; PSScriptAnalyzer lint; markdownlint; governance validator | free/community baseline |

### Required Quality Gates

| Required Quality Gate | Category | Evidence Source | Status |
| --- | --- | --- | --- |
| `dead-field` | mechanical | `iterations/<NNN>/quality/mechanical-findings.json` | planned |
| `anti-pattern` | mechanical | `iterations/<NNN>/quality/mechanical-findings.json` | planned |
| `test-integrity` | mechanical | `iterations/<NNN>/quality/mechanical-findings.json` | planned |
| `pester-unit-integration` | tooling | `tests/unit/code-implementation-lens.tests.ps1`, `tests/integration/code-rules-skill-multihost.tests.ps1` | planned |
| `psscriptanalyzer-lint` | tooling | CI / local PSScriptAnalyzer run | planned |
| `catalog-integrity` | tooling | catalog schema + unique/stable-ID test | planned |

### FR / SC to Test Mapping

| Requirement | Evidence / Test Target |
| --- | --- |
| FR-001 lens registered | registration test: lens id in `index.yml`, `applicability-map.json`, design-workshop lens map, `$lensIds` |
| FR-002 data-driven catalog | catalog-integrity test: 49 rules + per-stack present, unique/stable IDs, group + scope tags, schema-valid |
| FR-003 grouping-model presentation | conduct test + dogfood (SC-007): grouped, pre-checked, no flat wall |
| FR-004 manifest write | manifest-write test: schema-valid reference-by-ID `implementation-rules.yml` + record + lens-applicability entry |
| FR-005 guidance skill (baseline+overlay) | skill test + multi-host parity test; baseline+overlay composition test |
| FR-006 plan/implement wiring | wiring test: Planner directive present; Implementer charter pointer present |
| FR-007 context_scope hooks | manifest test: `context_scope=feature_standalone`; no 162 behavior |
| FR-008 baseline-only mode | skill test: no manifest → baseline-default rules surface |
| FR-009 set/unset + custom rules | conduct + manifest test: unchecked recorded; custom rule captured |
| FR-010 guideline-first | conduct test: source-of-truth question first |
| FR-011 assisted ingestion | conduct test: guideline maps onto catalog + extracts customs + provenance (agent-reasoning, no parser) |
| FR-012 custom via text/doc + overlay | manifest + overlay test: overlay additive + per-rule override, never drops shipped |
| FR-013 dependency-selection | manifest test: `dependency_policy` block with the capture fields; default-first "use existing"; skill surfaces it (dogfood SC-008) |
| SC-001..SC-008 | the tests above + the dogfood for SC-004 (agent guided) and SC-007 (no wall) and SC-008 (dependency policy honored) |

### Not-Applicable Dimensions and Rationale

| Dimension / Gate | Why Not Applicable | Follow-up |
| --- | --- | --- |
| `concurrency-correctness-review` | no concurrency/shared-state; interactive lens + read-only skill | none |
| browser/UI gates | agent-facing conduct + console interaction; no GUI | none |
| 145 mechanical conformance gate | ruled out (no parallel code-quality engine) | future (Option C) |

### Explicit Phase 2+ Deferrals

- Proposal 156 `workshop-decisions.yml` emission + Proposal 162 inheritance behavior ship as
  forward-compatible shape only (hooks + stable IDs).
- The full coupling-surface catalog (097) + dependency-report registry/CVE automation (122) + the
  dependency-selection automation umbrella (planned 178) are out of scope (FR-013 is design-time capture).
- An analyzer-config "enforced mode" (configure + require stack tooling) is deferred (Option C).

## Phase 2 Hardening and Specialist Review Planning

**Phase 2 Slice Scope**: planning-time analysis for the manifest schema, the skill resolver fail-open
behavior, and the multi-host deploy/parity; runtime proof at the dogfood + beta validation.
**Hardening Gate Artifact**: `specs/177-software-development-rules-lens/iterations/<NNN>/quality/hardening-gate.md`
**Known-Traps Corpus Location**: `.specrew/quality/known-traps.md`

### Hardening Focus Areas

| Focus Area | Why It Matters | Planned Artifact / Evidence | Status |
| --- | --- | --- | --- |
| Robustness / fail-open | absent or malformed manifest / catalog / overlay / skill copy must surface a WARN and fall back (baseline, shipped catalog), never crash or silently skip | hardening-gate.md robustness section | required |
| Maintainability / one source of truth | rule content lives only in the catalog; the skill + system prompt carry only a pointer; stable IDs survive workshop→plan→implement→(future 156) | hardening-gate.md design section | required |
| Test-integrity | registration, catalog integrity, manifest schema, parity, baseline+overlay, dependency-capture are named Pester targets proving behavior, not file presence | test plan + quality-evidence.md | required |
| Security (light) | no auth/secrets/PII; confirm the secure-coding rules are content the lens captures, not a feature surface | hardening-gate.md security section | required (light) |
| Rule-volume usability | the human is not shown a wall (grouping + pre-checked + guideline pre-marking); validated by dogfood | hardening-gate.md + dogfood evidence | required |

### Lens Activation Plan

| Lens / Checklist Ref | Activation | Why | Planned Evidence |
| --- | --- | --- | --- |
| `security-baseline@v1.0.0` | required (light) | no real security surface; confirm content-vs-surface | `iterations/<NNN>/quality/lenses/security-baseline.md` |
| `robustness-baseline@v1.0.0` | required | fail-open graceful degradation | `iterations/<NNN>/quality/lenses/robustness-baseline.md` |
| `test-integrity@v1.0.0` | required | named suites prove behavior, not file presence | `iterations/<NNN>/quality/lenses/test-integrity.md` |

### Explicit Later Deferrals

- Full line-by-line lens execution evidence + runtime-only proof deferred to implement/review + dogfood.
- FR-007 (156) / 162 inheritance runtime wiring deferred to those proposals.
- Dependency-selection automation (097/122/178) deferred.

## Constitution Check

- **Spec Authority Gate**: plan scope maps to spec FR-001..FR-013 + SC-001..SC-008; design-analysis
  Option B is the approved architecture. Pass.
- **Layering Gate**: changes are the **Spec Kit extension layer** (design-lens catalog, workshop conduct,
  the manifest schema, governance helpers), a **new guidance skill**, and Planner/Implementer charter
  pointers. NOT the Squad layer; no team-config change. Pass.
- **Traceability Gate**: each deliverable links to FR/SC and a planned task in
  file:///C:/Dev/Specrew-software-development-rules-lens/specs/177-software-development-rules-lens/tasks.md (next phase). Pass.
- **Ownership Gate**: Implementer owns the catalog / lens md / manifest schema + writer / guidance skill /
  registration / wiring / tests; Spec Steward owns the lens content fidelity (the 49 rules); Reviewer owns
  the dogfood evidence (SC-004/007/008) + parity. Security Specialist (light) confirms content-vs-surface. Pass.
- **Capacity Gate**: effort unit = story points; iteration cap 20 SP; ~2 iterations (capacity confirmed in tasks). Pass.
- **Drift/Reconciliation Gate**: drift-log.md per iteration; the validator + parity test detect drift; the
  manifest schema fail-open WARN is surfaced. Pass.
- **Verification Gate**: Pester unit/integration + mechanical-checks + governance validator + parity + the
  catalog/manifest schema tests; acceptance via SC-001..SC-008 including the dogfood. Pass.

## Project Structure

### Documentation (this feature)

```text
specs/177-software-development-rules-lens/
├── spec.md
├── plan.md                      # this file
├── data-model.md                # Wave-B
├── quickstart.md                # Wave-B
├── contracts/                   # Wave-B: implementation-rules.schema.json + code-implementation-lens.md
├── review-diagrams.md           # Wave-B
├── lens-applicability.json      # feature-level intake workshop records
├── workshop/                    # per-lens workshop records + diagrams
├── gates/design-analysis-001.md # persisted design-gate packet
└── iterations/                  # 001 (i1) and 002 (i2): design-analysis.md, plan.md, state.md, drift-log.md, quality/
```

### Source Code (repository root)

```text
extensions/specrew-speckit/knowledge/design-lenses/
├── code-implementation.md          # NEW — lens md (decision spine + per-stack dilemmas + run-cadence + conduct)
├── code-rules.yml                  # NEW — canonical catalog: 49 rules + per-stack, id/group/scope/applicability/default
├── implementation-rules.schema.json# NEW — per-feature manifest schema (156-forward-compatible)
├── index.yml                       # EDIT — register code-implementation (default_phase, categories)
└── applicability-map.json          # EDIT — always-applicable-for-code-features entry

extensions/specrew-speckit/squad-templates/skills/
├── specrew-code-rules/SKILL.md     # NEW — static guidance skill (resolver + baseline+overlay)
└── design-workshop.md              # EDIT — add the code lens turn (guideline-first, grouped checklist)

scripts/internal/
└── code-implementation-lens.ps1    # NEW — manifest writer/validator + overlay merge + (optional) Deploy hook reuse

.specrew/review or charter templates
└── implementer charter / coordinator  # EDIT — thin pointer: consult specrew-code-rules, follow implementation-rules.yml

tests/unit/code-implementation-lens.tests.ps1            # NEW — catalog integrity, manifest schema, overlay, dependency_policy
tests/integration/code-rules-skill-multihost.tests.ps1   # NEW — guidance-skill parity + baseline+overlay + registration
```

**Structure Decision**: Option B. Catalog data + lens md + manifest schema live in the design-lens
catalog; the workshop conduct extends `specrew-design-workshop`; the NEW `specrew-code-rules` guidance
skill ships as a managed skill **definition** (the existing deploy engine fans it to all hosts — no new
deployment code); the manifest writer/validator is a new PowerShell helper. No new top-level directories.

## Iteration Breakdown (~2 iterations; capacity finalized at tasks)

- **Iteration 001 (i1) — capture substrate (~10-13 SP)**: `code-rules.yml` catalog (the 49 rules +
  per-stack, grouped + scope-tagged, stable IDs) + `implementation-rules.schema.json` (incl.
  `dependency_policy`) + `code-implementation.md` lens md + registration (index.yml, applicability-map,
  `$lensIds`) + the manifest writer/validator + the FR-013 dependency-selection decision area + catalog +
  manifest tests.
- **Iteration 002 (i2) — delivery + guidance (~10-14 SP)**: the `specrew-code-rules` guidance skill
  (resolver + baseline+overlay) + the design-workshop code-lens turn (guideline-first, grouped checklist,
  ingestion, custom rules, overlay) + plan/implement wiring (Planner directive + Implementer pointer) +
  multi-host parity + the dogfood (SC-004/007/008) + release (FileList + extension.yml 0.34.0→0.35.0 +
  beta).

## Complexity Tracking

No Constitution violations to justify. Option B was chosen over Option C (the full enforcement spine)
specifically to avoid premature complexity and the rejected parallel code-quality engine: the catalog +
manifest + one skill are the minimum needed for design-time capture + active implement-time guidance, and
the stable IDs + `context_scope` hooks let the 156/145/097/122/178 spine compose later from real dogfood
data at lower total cost.
