# Implementation Plan: Work Kind and Branch Governance Model

**Feature**: 182-work-kind-branch-governance
**Design-analysis verdict**: `approved for plan with Option B` (3-iteration plan)
**Branch**: `182-work-kind-branch-governance`

## Summary

Add first-class **work kinds** (`software-feature`, `bug-bash`, `docs-only`, `devops`), a
DevOps-lens **repository-governance** decision area with a configurable **`branch_model`** and
**`review_gate`**, the **feature-closeout-vs-release-validation** invariant, a **provider-neutral
core + pluggable `ProviderAdapter`** (GitHub reference + generic fallback + on-the-fly read-only
synthesis), a provider-neutral **CI work-kind validator** (advisory by default), honest
**capability detection**, **brownfield adapt-or-change**, and the **forge-neutralization** of all
downstream-governing surfaces — delivered across three iterations per design-analysis Option B.

## Technical Context

- **Stack**: PowerShell 7+ module functions + YAML/JSON data + JSON-schema + Pester tests +
  markdown methodology surfaces. Dependency policy: `use-existing-no-new-dependency` (`gh`/GitHub
  API confined to the GitHub adapter; core + generic fallback use pure git).
- **Layer**: the Spec Kit extension layer (design-lens content, work-kind catalog + schemas,
  governance helpers, validator/adapters), deployed CI templates, and downstream-governing surfaces
  (Iter 3). NOT the Squad layer.
- **Architecture**: data-driven catalog → declaration → enforcement spine; provider-neutral core
  with the `ProviderAdapter` as the only forge seam (architecture-core DP-A1..A6).
- **Self-delivery**: built as a normal `software-feature`, dogfooded on Specrew's protected `main`
  (FR-013/SC-007/SC-014). Specrew's own GitHub usage is unchanged.

## Phase 1 Quality Planning

**Phase Scope**: `phase-1-first-slice`
**Inferred Quality Profile**: `quality-profile.powershell-governance-tooling` — bounded custom
composition (same self-host bar as features 141 / 171 / 176 / 177).
**Selected explicit custom composition**: PowerShell/Pester + PSScriptAnalyzer + the Specrew
mechanical-checks/validator + markdownlint.

### Stack Surfaces in Scope

| Stack Surface | Path Globs / Evidence | Recognized Stack | Why It Matters |
| --- | --- | --- | --- |
| `work-kind-catalog` | `extensions/specrew-speckit/knowledge/work-kinds.yml`, `*.schema.json` | `yaml+json` | the data-driven taxonomy + declaration + governance schemas |
| `governance-scripts` | `extensions/specrew-speckit/scripts/work-kind-*.ps1`, `provider-*.ps1` | `powershell-governance` | validator + classifier + evidence-checker + adapters + detector |
| `lens-content` | `extensions/specrew-speckit/knowledge/design-lenses/devops-operations.md` | `markdown` | the governance questions + branch_model + review_gate + synthesis conduct |
| `lifecycle-surfaces` | `templates/**` (docs-only/devops lifecycle, declaration + governance + release-validation templates) | `markdown+yaml` | the right-sized lifecycles + capture templates |
| `ci-wiring` | `templates/github/workflows/specrew-work-kind.yml` | `yaml` | v1 GitHub Actions wrapper invoking the provider-neutral validator |
| `downstream-surfaces` | lifecycle prompt template, charters, closeout steps, PR-review-integration | `markdown+ps1` | Iter-3 forge-neutralization targets |

### Risk Dimensions

| Risk Dimension | Status | Rationale |
| --- | --- | --- |
| `code-quality` | `required` | PowerShell validators/adapters/detector must be PSScriptAnalyzer-clean and reviewable. |
| `design-quality-and-separation-of-concerns` | `required` | provider-neutral core vs adapter seam; catalog (data) vs validator (code) must stay separate; no forge import in core. |
| `verification-confidence` | `required` | validator/classifier/evidence-checker/fallback/detector need behavior-proving Pester + denial-path + fail-open + parity tests. |
| `maintainability` | `required` | data-driven catalog = one source of truth; stable work-kind IDs; docs↔enforcement sync. |
| `security` | `required` | branch protection = access control; `apply_protection` human-gated; no Specrew-held secret; durable bypass audit; least-privilege scopes; denial-path tests. |
| `robustness` | `required` | fail-open + WARN; provider-neutral git-diff fallback; advisory default — never spuriously block. |
| `brownfield-compatibility` | `required` | detect existing CI/CD + protection; adapt-or-change, never overwrite; SC-014 self-consistency. |
| `concurrency-correctness` | `not-applicable` | the validator runs once per PR, single-threaded; no shared state. |

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
| `pester-unit-integration` | tooling | `tests/unit/work-kind-*.tests.ps1`, `tests/integration/work-kind-ci.tests.ps1` | planned |
| `psscriptanalyzer-lint` | tooling | CI / local PSScriptAnalyzer run | planned |
| `catalog-integrity` | tooling | work-kinds.yml schema + unique/stable-ID test | planned |
| `provider-neutral-fallback` | tooling | test: validator runs with no adapter via git-diff + branch_model | planned |
| `denial-path-security` | tooling | test: too-broad bypass, missing-token, apply_protection-without-approval | planned |
| `multi-host-parity` | tooling | deployed lens/template/skill parity across hosts | planned |

### FR / SC to Test Mapping

| Requirement | Evidence / Test Target |
| --- | --- |
| FR-001 work-kind taxonomy catalog | catalog-integrity test: 4 kinds × lifecycle weight + required-evidence + allowed scope; unique/stable IDs; schema-valid |
| FR-002 DevOps lens default model | lens-content test: default model present + adopt/modify/skip prompt |
| FR-003 branch_model + protected-branch + caveat | governance-schema test: branch_model (style + named branches + protection + promotion_path); provider/plan/visibility caveat precedes enforcement promise |
| FR-004 closeout vs release-validation | methodology test + worked example (SC-004): post-merge finding → new work item; release-validation-record template |
| FR-005 docs-only lifecycle | lifecycle-surface test (SC-003): docs-only reaches PR-ready closeout, no release |
| FR-006 devops lifecycle | lifecycle-surface test: risk/rollback + dry-run/CI evidence required |
| FR-007 provider-neutral CI validator | validator test: one kind? scope match? closeout evidence? advisory default; gap-naming message (SC-005) |
| FR-008 single/multi-repo capture | governance-schema test: multi_repo block captured only when chosen |
| FR-009 declaration mechanism | declaration test: `.specrew/work-kind.yml` authoritative + branch-prefix hint; allow-list exempts global/generated |
| FR-010 honest/phased enforcement | review check (SC-008): every enforcement claim labeled; no over-claim |
| FR-011 emergency bypass audit | test (SC-009): bypass writes durable audit artifact, no silent skip |
| FR-012 capability detection | detector test (SC-006): mechanism per provider/plan/visibility; ci-only/manual fallback |
| FR-013 dogfood on Specrew | dogfood (SC-007): Specrew `.specrew/work-kind.yml` + main protection recorded |
| FR-014 provider-neutral core | static test: core imports no forge tool; runs on non-GitHub (SC-010) |
| FR-015 adapter contract + GitHub ref + fallback | adapter test: contract conformance; GitHub detect; generic fallback ci-only/manual |
| FR-016 on-the-fly synthesis | synthesis-conduct test (SC-012): produces read-only-until-verified adapter |
| FR-017 review_gate | governance-schema test: human approvals + comment-resolution; automated review opt-in |
| FR-018 project-level capture | test: `.specrew/repository-governance.yml` project-level; deltas re-asked |
| FR-019 forge-neutralization | audit inventory exists; migrated surfaces no GitHub-only mandate (SC-013); Specrew own infra unchanged |
| FR-020 apply_protection human-gated + no secrets | denial-path test: no auto-apply; no unverified-adapter apply; no Specrew secret |
| FR-021 brownfield adapt-or-change | detector test: detect existing posture; offer adapt-or-change; never overwrite |
| SC-001..SC-014 | the tests above + worked example (SC-004), dogfood (SC-007/SC-014), non-GitHub run (SC-010/SC-011) |

### Not-Applicable Dimensions and Rationale

| Dimension / Gate | Why Not Applicable | Follow-up |
| --- | --- | --- |
| `concurrency-correctness-review` | validator single-threaded, runs once per PR | none |
| browser/UI gates | text/CLI surface only; no GUI | none |
| performance gates | governance tooling, runs once per PR; perf is a non-driver | none |

### Explicit Phase 2+ Deferrals

- Pre-built GitLab/Azure/Bitbucket adapters → synthesized on the fly (read-only) instead.
- Full ruleset-enforcement automation + blocking-by-default → graduates from advisory as proven.
- Proposals 174 / 178 stay follow-ups.
- Out-of-governance-surface GitHub coupling found in the Iter-1 inventory → tight follow-up work items.

## Phase 2 Hardening and Specialist Review Planning

**Phase 2 Slice Scope**: planning-time analysis for the validator fail-open behavior, the adapter
seam + apply_protection safety, the brownfield detection, and multi-host deploy/parity; runtime
proof at the dogfood + beta validation.
**Hardening Gate Artifact**: `specs/182-work-kind-branch-governance/iterations/<NNN>/quality/hardening-gate.md`
**Known-Traps Corpus Location**: `.specrew/quality/known-traps.md`

### Hardening Focus Areas

| Focus Area | Why It Matters | Planned Artifact / Evidence | Status |
| --- | --- | --- | --- |
| Robustness / fail-open | absent/malformed declaration/catalog/governance, or a missing adapter, must WARN + fall back (git-diff, ci-only/manual, advisory), never crash or spuriously block | hardening-gate.md robustness section | required |
| Security / privileged-action safety | `apply_protection` human-gated; synthesized adapters read-only; no Specrew secret; durable bypass audit; least-privilege scopes; denial paths tested | hardening-gate.md security section | required |
| Maintainability / one source of truth | the 4 kinds + scopes live only in the catalog; validator + docs read it; stable IDs survive workshop→plan→implement | hardening-gate.md design section | required |
| Brownfield-compatibility | detect existing CI/CD + protection; adapt-or-change; never overwrite; Specrew self-consistency (SC-014) | hardening-gate.md + dogfood evidence | required |
| Honesty / no over-claim | every enforcement claim labeled with its true posture (enforced vs phased/deferred) | review against SC-008/FR-010 | required |

### Lens Activation Plan

| Lens / Checklist Ref | Activation | Why | Planned Evidence |
| --- | --- | --- | --- |
| `security-baseline@v1.0.0` | required | branch protection = access control; apply_protection + bypass audit + no secrets | `iterations/<NNN>/quality/lenses/security-baseline.md` |
| `robustness-baseline@v1.0.0` | required | fail-open graceful degradation + provider-neutral fallback | `iterations/<NNN>/quality/lenses/robustness-baseline.md` |
| `test-integrity@v1.0.0` | required | named suites prove behavior, not file presence | `iterations/<NNN>/quality/lenses/test-integrity.md` |

### Explicit Later Deferrals

- Full line-by-line lens execution evidence + runtime-only proof → implement/review + dogfood + beta.
- Blocking enforcement + full ruleset automation → graduates from advisory once proven.
- Iter-3 decouple may split into a sibling if too large (decided at iteration-closeout).

## Constitution Check

- **Spec Authority Gate**: plan scope maps to FR-001..FR-021 + SC-001..SC-014; design-analysis
  Option B is the approved architecture. Pass.
- **Layering Gate**: changes are the Spec Kit extension layer (work-kind catalog, devops lens
  content, lifecycle templates, governance helpers/validator/adapters), deployed CI templates, and
  downstream-governing surfaces (Iter 3). NOT the Squad layer. Pass.
- **Traceability Gate**: each deliverable links to FR/SC and a planned task in
  file:///C:/tmp/Specrew-work-kind-branch-governance/specs/182-work-kind-branch-governance/tasks.md (next phase). Pass.
- **Ownership Gate**: per the spec's FR Ownership & Delivery Window matrix — Spec Steward owns lens
  content, lifecycle surfaces, and governance questions; Implementer owns the catalog, schemas,
  validator, adapters, detector, CI wiring, tests, and the Iter-3 migration; Reviewer owns honesty
  (SC-008), security/denial-path, and dogfood evidence (SC-007/SC-014). Pass.
- **Capacity Gate**: effort unit = story points; iteration cap 20 SP; ~16–24 SP across 3 iterations
  (capacity confirmed in tasks). Pass.
- **Drift/Reconciliation Gate**: drift-log.md per iteration; the validator + parity test + the
  forge-coupling inventory detect drift; fail-open WARN surfaced. Pass.

## Project Structure

### Documentation (this feature)

```text
specs/182-work-kind-branch-governance/
  spec.md · plan.md · tasks.md · data-model.md · quickstart.md
  contracts/work-kind-governance.md
  review-diagrams.md
  checklists/requirements.md
  workshop/*  ·  lens-applicability.json  ·  implementation-rules.yml
  gates/design-analysis-001.md
  iterations/001/{plan.md,state.md,design-analysis.md,drift-log.md,quality/*}
```

### Source Code (repository root)

```text
extensions/specrew-speckit/knowledge/
  work-kinds.yml                          # WorkKindCatalog (Iter 1)
  work-kinds.schema.json                  # CatalogSchema + declaration schema (Iter 1)
  repository-governance.schema.json       # RepositoryGovernance schema (Iter 1)
  design-lenses/devops-operations.md      # extended lens content (Iter 1)
extensions/specrew-speckit/scripts/
  work-kind-validator.ps1                 # WorkKindValidator + ChangedFileClassifier + CloseoutEvidenceChecker (Iter 2)
  provider-adapter.ps1                    # ProviderAdapterContract + dispatch (Iter 1 contract; Iter 2 detect)
  provider-github.ps1                     # GitHubAdapter (Iter 1 stub → Iter 2 detect)
  provider-generic.ps1                    # GenericFallbackAdapter (Iter 1)
  capability-detector.ps1                 # CapabilityDetector (Iter 2)
templates/
  work-kind/{work-kind.yml,repository-governance.yml,release-validation-record.md}   # capture templates (Iter 1)
  lifecycle/{docs-only-lifecycle.md,devops-lifecycle.md}                              # lifecycle surfaces (Iter 1)
  github/workflows/specrew-work-kind.yml                                             # CI wrapper (Iter 2)
docs/methodology/work-kinds.md            # WorkKindTaxonomyDoc + closeout-vs-release invariant (Iter 1)
tests/unit/work-kind-validator.tests.ps1 · tests/unit/provider-adapter.tests.ps1
tests/integration/work-kind-ci.tests.ps1
# Iter 3 forge-neutralization edits: lifecycle prompt template, charters, closeout steps, validate-governance PR-review
.specrew/work-kind.yml                    # Specrew's OWN declaration (dogfood, Iter 2)
.specrew/repository-governance.yml        # Specrew's OWN governance capture (dogfood, Iter 2)
```

## Iteration Breakdown (~16–24 SP across 3 iterations; capacity finalized at tasks)

| Iter | Theme | Scope (FRs) | Key SCs | Rough SP |
| --- | --- | --- | --- | --- |
| 001 | Methodology + seam contract + audit | FR-001..006, 008, 009, 010, 014, 015(contract+fallback), 016(doc), 017, 018, 019(inventory), 021(content) | SC-001..004, 011 | 6–9 |
| 002 | Runtime validator + capability + synthesis + dogfood | FR-007, 011, 012, 015(GH detect), 016(exercised), 020, 021(detector) | SC-005, 006, 007, 009, 010, 012, 014 | 6–9 |
| 003 | Forge-neutralization decouple migration | FR-019(migration) | SC-008, 013 | 4–6 |

Iter-3 escape hatch: if the decouple migration exceeds capacity, split it into a sibling
`devops`/`docs-only` work item at iteration-closeout (recorded, not silently dropped).

## Complexity Tracking

- **Highest-risk-to-reverse**: the declaration contract (`.specrew/work-kind.yml` shape) + the
  catalog schema — isolated as versioned data + a documented contract (architecture-core DP-A6).
- **Forge-coupling magnitude**: precise inventory is the Iter-1 deliverable (~10–15 genuinely-coupled
  files estimated; raw grep ~216 inflated by the `copilot` host name + generic prose + example histories).
- **Phased enforcement**: validator ships advisory; blocking graduates as proven (honest labeling).
