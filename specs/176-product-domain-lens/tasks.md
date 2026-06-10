---
description: "Task list for feature 176 — Product & Problem Domain Lens"
---

# Tasks: Product & Problem Domain Lens (first workshop lens)

**Input**: Design documents under file:///C:/Dev/Specrew-product-domain-lens/specs/176-product-domain-lens/
**Prerequisites**: plan.md, spec.md, data-model.md, contracts/ (all present)

**Tests**: REQUESTED — the spec's SC-001..SC-009 require behavior-proving tests, and the
plan→tasks verdict explicitly requires traced tests for seven behaviors. Test tasks are included.

**Architecture**: Option B — `product-domain` is a new first-stage workshop phase ahead of the
deterministic applicability selector (the selector stays untouched). Proposals 156/162 are
forward-compatible shape only (no `workshop-decisions.yml` emission, no inheritance behavior).
Quality bar: Pester + PSScriptAnalyzer + Specrew mechanical-checks + governance validator.

**No product code is written until the before-implement gate is approved.**

## Format

`- [ ] T### [P?] [US#] [Owner: role] [Capacity: N SP] Description with exact path (Trace: FR/SC)`

`[P]` = parallelizable (different files, no dependency).

---

## Phase 1: Catalog + schema (foundational)

**Purpose**: the lens knowledge + the structured-record contract every later task builds on.

- [x] T001 [US1] [Owner: Implementer] [Capacity: 2 SP] Author the lens file `extensions/specrew-speckit/knowledge/design-lenses/product-domain.md` — the 8 decision areas, the Light/Standard/Deep depth model with the risk/novelty selection rules, the evidence-tag vocabulary, a `## Run Cadence` section (the per-feature adaptive rule), and the no-batch-confirmation + solution-first-reframing conduct (Trace: FR-002, FR-003, FR-004, FR-012, FR-014).
- [x] T002 [US1] [Owner: Implementer] [Capacity: 0.5 SP] Register the lens as the first-stage lens: add a `product-domain` entry to `extensions/specrew-speckit/knowledge/design-lenses/index.yml` with a first-stage `default_phase`, and a `product-domain` context-diagram entry to `diagram-vocabulary.json`. Do NOT add it to `applicability-map.json` (the selector stays pure) (Trace: FR-001).
- [x] T003 [P] [US3] [Owner: Implementer] [Capacity: 1 SP] Finalize the structured-record schema `specs/176-product-domain-lens/contracts/product-domain.schema.json` — the `product_id` / `product_context_ref` / `context_scope` forward-compat hooks and the conditional `load_bearing` requirement when `evidence = research-needed` (Trace: FR-004, FR-007, FR-008, FR-014, SC-008, SC-009).

**Checkpoint**: the lens knowledge + schema exist; the writer and conduct can build on them.

---

## Phase 2: US1 — product-first grounding (Priority: P1)

**Goal**: the lens runs first, captures product context at adaptive depth with evidence tags, and persists both records.

**Independent Test**: run a feature intake; the product-domain record is produced before the applicability questionnaire, at a recorded depth, with evidence tags, in both files.

- [x] T004 [US1] [Owner: Implementer] [Capacity: 2 SP] Implement the record writer/validator `scripts/internal/product-domain-lens.ps1`: `New-SpecrewProductDomainRecord`, `Get-SpecrewProductDomainDepth` (risk/novelty → light/standard/deep), `Test-SpecrewProductDomainRecord` (schema + evidence tags + provenance), `Format-SpecrewProductDomainSummary` (the `spec.md` summary), `Test-SpecrewProductDomainResearchBlock` (load-bearing `research-needed`). Idempotent, fail-open, UTF-8 no-BOM (Trace: FR-002, FR-005, FR-006, FR-011, SC-002, SC-004, SC-006).
- [x] T005 [US1] [Owner: Implementer] [Capacity: 1.5 SP] Add the first-stage phase to the `specrew-design-workshop` skill SOURCE: run `product-domain` FIRST (before the applicability agenda), select depth, reframe a solution-first request into the problem, capture evidence-tagged answers, write the records, and write the `spec.md` product-domain summary (Trace: FR-001, FR-006, FR-012, SC-001).
- [x] T006 [P] [US1] [Owner: Implementer] [Capacity: 0.5 SP] **Test — runs first**: assert the product-domain record is produced BEFORE the technical-lens applicability questionnaire is answered (`tests/unit/product-domain-lens.tests.ps1`) (Trace: FR-001, SC-001).
- [x] T007 [P] [US1] [Owner: Implementer] [Capacity: 0.5 SP] **Test — adaptive depth**: assert `Get-SpecrewProductDomainDepth` maps the risk/novelty inputs to Light / Standard / Deep across all three (Trace: FR-002, SC-002).
- [x] T008 [P] [US1] [Owner: Implementer] [Capacity: 0.75 SP] **Test — evidence tags + conditional blocking**: assert every material statement carries an evidence tag, an untagged statement fails validation, a load-bearing `research-needed` blocks the plan boundary, and a non-load-bearing one advances with the gap recorded (Trace: FR-004, FR-011, SC-003, SC-006).
- [x] T009 [P] [US1] [Owner: Implementer] [Capacity: 0.5 SP] **Test — dual-artifact persistence**: assert both `specs/<feature>/workshop/product-domain.yml` and `product-domain.md` are written, and absence of either fails the gate (Trace: FR-005, SC-004).

**Checkpoint**: US1 is an independently testable MVP — the grounding runs, captures, tags, and persists.

---

## Phase 3: US2 — the grounding cannot be skipped or faked (Priority: P2)

**Goal**: the specify gate refuses to advance without a genuine, non-batch product-domain record.

**Independent Test**: a batch-approved record fails the gate; a genuine human-confirmed record passes.

- [x] T010 [US2] [Owner: Reviewer] [Capacity: 1.5 SP] Extend the specify-boundary lens gate in `scripts/internal/design-analysis-gate.ps1` with `Test-SpecrewProductDomainGate`, wired into `Invoke-SpecrewSpecifyBoundaryLensGate`: require the record present + schema-valid + a `confirmation` / `confirmation_scope` provenance (reusing the SC-026 enum); marker-gated + grandfather-safe; fail-closed with the missing/invalid reason (Trace: FR-009, FR-010, SC-004, SC-005).
- [x] T011 [P] [US2] [Owner: Reviewer] [Capacity: 0.5 SP] **Test — batch approval rejected**: assert a record whose `confirmation_scope` is a batch/agenda approval FAILS the gate, and a `human-confirmed` / `lens-question` record passes (`tests/unit/product-domain-lens.tests.ps1`) (Trace: FR-009, SC-005).

**Checkpoint**: US2 enforces the grounding deterministically.

---

## Phase 4: US3 — multi-host + forward-compatibility (Priority: P3)

**Goal**: identical conduct across the supported hosts; the record is forward-compatible with 156/162.

**Independent Test**: the conduct is identical across the managed skill surfaces; `product-domain.yml` validates against the schema with the hooks present.

- [x] T012 [US3] [Owner: Implementer] [Capacity: 1 SP] Deploy the first-stage-phase conduct to the host-managed skill surfaces of all five supported hosts (Claude, Copilot/GitHub, Codex/Agents, Cursor, Antigravity) via the managed-skill deploy path — the four on-disk surfaces `.claude/skills`, `.cursor/rules`, `.github/skills`, `.agents/skills`; carry the "5 supported hosts vs 4 on-disk surfaces" wording so no host reads as unsupported (Trace: FR-013, SC-007).
- [x] T013 [P] [US3] [Owner: Implementer] [Capacity: 0.5 SP] **Test — schema hooks**: assert `product-domain.yml` validates against `contracts/product-domain.schema.json` with `product_id` / `product_context_ref` / `context_scope` present, `context_scope = feature_standalone` in V1, and the enum constrained (Trace: FR-007, FR-008, FR-014, SC-008, SC-009).
- [x] T014 [P] [US3] [Owner: Implementer] [Capacity: 0.75 SP] **Test — host-skill parity**: assert the product-domain conduct is identical across the four managed skill surfaces; injected drift fails (`tests/integration/product-domain-multihost.tests.ps1`) (Trace: FR-013, SC-007).
- [x] T015 [P] [US3] [Owner: Reviewer] [Capacity: 0.5 SP] **Test — graceful degradation (no silent skip)**: assert that when a required surface is absent — the lens catalog, a host skill copy, or a deploy surface — Specrew surfaces a WARN and does NOT silently skip product-domain enforcement; the gate fails-CLOSED on a substantive feature rather than passing silently (`tests/unit/product-domain-lens.tests.ps1`) (Trace: FR-010, FR-013). *(Promoted from T004's implicit fail-open scope to an explicit traced test at the tasks verdict.)*

**Checkpoint**: US3 protects portability, forward-compatibility, and degraded-mode safety.

---

## Deferred (forward-compatible shape only)

- **FR-007 emission into Proposal 156 `workshop-decisions.yml`** — deferred (156 unshipped); the
  schema (T003) is built 156-consumer-compatible. Drift D-001.
- **FR-008 Proposal 162 inheritance behavior** — deferred (162 unshipped); the `product_id` /
  `product_context_ref` / `context_scope` hooks (T003) are built so 162 connects later. Drift D-002.

## Verification commands

```pwsh
pwsh -NoProfile -File tests/unit/product-domain-lens.tests.ps1
pwsh -NoProfile -File tests/integration/product-domain-multihost.tests.ps1
Invoke-ScriptAnalyzer scripts/internal/product-domain-lens.ps1
pwsh -File .specify/extensions/specrew-speckit/scripts/run-mechanical-checks.ps1
pwsh -File .specify/extensions/specrew-speckit/scripts/validate-governance.ps1 -ProjectPath .
```

## Capacity

Total planned effort: **14.0 SP** (9.5 build + 4.5 tests) against a 20 SP iteration cap — within
capacity, single iteration. The +0.5 SP over the original 13.5 is the graceful-degradation test
(T015) promoted to an explicit traced test at the tasks verdict (behavior already in T004's fail-open
scope; maintainer-accepted, not scope creep). Traceability: every task carries a `Trace:` to one or
more FR/SC; every FR (FR-001..FR-014) and SC (SC-001..SC-009) is covered by at least one task
(FR-007/FR-008 by their forward-compatible-shape tasks T003/T013 with runtime wiring deferred).
