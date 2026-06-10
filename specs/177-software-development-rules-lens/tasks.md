---
description: "Task list for feature 177 — Code & Implementation Lens (software-development-rules)"
---

# Tasks: Code & Implementation Lens (software-development-rules workshop lens)

**Input**: Design documents under file:///C:/Dev/Specrew-software-development-rules-lens/specs/177-software-development-rules-lens/
**Prerequisites**: spec.md, plan.md, data-model.md, contracts/ (all present)

**Tests**: REQUESTED — the spec's SC-001..SC-008 require behavior-proving tests; SC-004 / SC-007 / SC-008
are validated by the dogfood (runtime), not file-presence.

**Architecture**: Option B — data-driven `code-rules.yml` catalog → per-feature `implementation-rules.yml`
manifest (reference-by-ID) → one static, multi-host `specrew-code-rules` guidance skill (baseline +
per-feature overlay). No 145 gate / no parallel code-quality engine. Proposals 156/162/145/097/122/178 are
forward-compatible / out of scope.

**No product code is written until the before-implement gate is approved.**

## Format

`- [ ] T### [P?] [iN] [US#] [Owner: role] [Capacity: N SP] Description with exact path (Trace: FR/SC)`

`[P]` = parallelizable (different files, no dependency). `[iN]` = iteration 1 or 2.

---

## Iteration 1 (i1) — capture substrate (~12 SP, ≤ 20 cap)

### Phase 1: Catalog + schema + lens md (foundational)

- [ ] T001 [i1] [US3] [Owner: Implementer] [Capacity: 3 SP] Author the catalog `extensions/specrew-speckit/knowledge/design-lenses/code-rules.yml` — the Proposal-163 baseline rules + the F-177 additions (Strategy/State over repeated conditionals; polymorphism mechanism functional-vs-inheritance; SOLID baseline composing with the OCP/DI rules) + per-stack defaults (C#/.NET, C/C++, TS/JS, Python, Go, Java), each rule with `id` / `group` / `scope` / `applies` / `default` / `enforcement_mode` (Trace: FR-002, SC-005).
- [ ] T002 [P] [i1] [US3] [Owner: Implementer] [Capacity: 1.5 SP] Finalize the manifest schema `specs/177-software-development-rules-lens/contracts/implementation-rules.schema.json` — reference-by-ID `selections`, `custom_rules` with provenance (incl. `from-example-project`), `dependency_policy`, `context_scope` (162 hook), and confirmation provenance (Trace: FR-004, FR-007, FR-012, FR-013, SC-002).
- [ ] T003 [i1] [US2] [Owner: Implementer] [Capacity: 2.5 SP] Author the lens md `extensions/specrew-speckit/knowledge/design-lenses/code-implementation.md` — the decision spine, per-stack dilemmas, `## Run Cadence` (product-baseline-then-feature-delta), and the conduct (guideline-first incl. example projects, grouped set/unset checklist, dependency-selection) referencing the catalog (Trace: FR-001, FR-003, FR-010, FR-013).
- [ ] T004 [P] [i1] [US1] [Owner: Implementer] [Capacity: 0.5 SP] Register the lens: add the `code-implementation` row to `index.yml` + the always-applicable-for-code entry to `applicability-map.json` + the design-workshop lens map + the `$lensIds` test list (Trace: FR-001, SC-001).

**Checkpoint**: the catalog + schema + lens md + registration exist; the writer + conduct can build on them.

### Phase 2: Manifest writer/validator + dependency-selection

- [ ] T005 [i1] [US2] [Owner: Implementer] [Capacity: 2.5 SP] Implement `scripts/internal/code-implementation-lens.ps1` — the manifest writer/validator (schema-valid reference-by-ID), overlay merge (`code-rules.local.yml` additive + per-rule override, never drops a shipped rule), `dependency_policy` capture, idempotent + fail-open + UTF-8 no-BOM (Trace: FR-004, FR-009, FR-012, FR-013, SC-002).
- [ ] T006 [i1] [US2] [Owner: Implementer] [Capacity: 1 SP] Encode the FR-013 dependency-selection decision area in the catalog + writer: default-first "use existing / no new dependency" + the capture fields (version, license, source org, canonical URL, maintenance, security/advisory, compatibility, cost/quota, coupling weight, replaceability, test implications) persisted to `dependency_policy` (Trace: FR-013, SC-008).

### Phase 3: i1 tests

- [ ] T007 [P] [i1] [US3] [Owner: Implementer] [Capacity: 1 SP] Test — catalog integrity (`tests/unit/code-implementation-lens.tests.ps1`): the Proposal-163 baseline + the 3 F-177 additions + per-stack present, unique/stable IDs, schema-valid, grouped + scope-tagged (Trace: FR-002, SC-005).
- [ ] T008 [P] [i1] [US2] [Owner: Implementer] [Capacity: 1 SP] Test — manifest schema + overlay: reference-by-ID, `dependency_policy`, `context_scope`, `custom_rules` provenance (incl. `from-example-project`), overlay merge never drops a shipped rule (Trace: FR-004, FR-012, FR-013, SC-002).
- [ ] T009 [P] [i1] [US1] [Owner: Implementer] [Capacity: 0.5 SP] Test — registration: lens id present in `index.yml`, `applicability-map.json`, the design-workshop lens map, and `$lensIds` (Trace: FR-001, SC-001).

**Checkpoint (i1)**: the capture substrate is complete + tested; ~12 SP.

---

## Iteration 2 (i2) — delivery + guidance (~13.5 SP, ≤ 20 cap)

### Phase 4: Guidance skill (consumer)

- [ ] T010 [i2] [US1] [Owner: Implementer] [Capacity: 3 SP] Author the NEW `specrew-code-rules` skill (`extensions/specrew-speckit/squad-templates/skills/specrew-code-rules/SKILL.md` + resolver) — resolve the active feature, read the manifest at the known location, compose baseline (catalog `baseline-default`) + per-feature overlay + `dependency_policy`, task-scoped surfacing (service/client/concurrency/API), baseline-only mode with no manifest, fail-open on unknown id / malformed (Trace: FR-005, FR-008, SC-004, SC-006).
- [ ] T011 [P] [i2] [US4] [Owner: Implementer] [Capacity: 0.5 SP] Add `specrew-code-rules` to the canonical `skills/` template with host-scope frontmatter so the existing deploy engine fans it to every host skill dir (no per-feature deployment code) (Trace: FR-005, SC-003).

### Phase 5: Workshop conduct (producer) + ingestion

- [ ] T012 [i2] [US2] [Owner: Implementer] [Capacity: 2.5 SP] Add the `code-implementation` lens turn to the `specrew-design-workshop` skill SOURCE — guideline-first source-of-truth (guideline doc OR example project(s) OR none), stack resolution, grouped pre-checked set/unset checklist (no flat wall), decision-prompts paced, applicability-filtered context-gated, custom rules; write the manifest + `workshop/code-implementation.md` + the lens record (Trace: FR-003, FR-009, FR-010, SC-002, SC-007).
- [ ] T013 [i2] [US2] [Owner: Implementer] [Capacity: 1.5 SP] Assisted ingestion: map a provided guideline OR example project onto the catalog (auto-check matches, flag conflicts), extract non-catalog conventions as custom rules with provenance (`from-guideline` / `from-example-project` + source ref); persist company/org-level rules to the `code-rules.local.yml` overlay (Trace: FR-011, FR-012).

### Phase 6: Plan/implement wiring

- [ ] T014 [P] [i2] [US1] [Owner: Implementer] [Capacity: 1 SP] Wiring: Planner directive (`plan.md` converts selected rules → implement constraints) + the Implementer charter/coordinator thin pointer ("consult `specrew-code-rules`, follow `implementation-rules.yml`") (Trace: FR-006).

### Phase 7: i2 tests + dogfood + release

- [ ] T015 [P] [i2] [US1] [Owner: Implementer] [Capacity: 1 SP] Test — guidance skill: baseline+overlay composition; baseline-only with no manifest; unknown-id fail-open; `dependency_policy` surfaced (Trace: FR-005, FR-008, FR-013, SC-004, SC-006, SC-008).
- [ ] T016 [P] [i2] [US4] [Owner: Implementer] [Capacity: 1 SP] Test — multi-host parity (`tests/integration/code-rules-skill-multihost.tests.ps1`): `specrew-code-rules` present + identical in every active host skill dir after init/update (Trace: FR-005, SC-003).
- [ ] T017 [i2] [US2] [Owner: Reviewer] [Capacity: 1.5 SP] Dogfood (Claude first, runtime evidence — NOT file-presence): run the lens on a real feature; verify no rule wall (SC-007), the agent is guided + generated code reflects the chosen rules (SC-004), and the dependency stance is honored (SC-008) (Trace: SC-004, SC-007, SC-008).
- [ ] T018 [i2] [US4] [Owner: Implementer] [Capacity: 1.5 SP] Release: add every new deployable file (lens md, `code-rules.yml`, schema, the skill) to the `Specrew.psd1` FileList; bump `extension.yml` 0.34.0 → 0.35.0; `.specify/` mirror parity; CHANGELOG; publish `v0.35.0-beta.1` (Trace: SC-003, devops-operations).

**Checkpoint (i2)**: the guidance skill + workshop conduct + wiring are delivered, dogfooded, and released; ~13.5 SP.

---

## Traceability summary

- Every task above carries a `Trace:` to ≥1 FR/SC.
- FR coverage: FR-001 (T003,T004,T009) · FR-002 (T001,T007) · FR-003 (T003,T012) · FR-004 (T002,T005,T008) · FR-005 (T010,T011,T015,T016) · FR-006 (T014) · FR-007 (T002) · FR-008 (T010,T015) · FR-009 (T005,T012) · FR-010 (T003,T012) · FR-011 (T013) · FR-012 (T002,T005,T008,T013) · FR-013 (T002,T005,T006,T008,T015).
- SC coverage: SC-001 (T004,T009) · SC-002 (T002,T005,T008,T012) · SC-003 (T011,T016,T018) · SC-004 (T010,T015,T017) · SC-005 (T001,T007) · SC-006 (T010,T015) · SC-007 (T012,T017) · SC-008 (T006,T015,T017).
- Capacity: i1 ≈ 12 SP, i2 ≈ 13.5 SP — each within the 20 SP per-iteration cap. Per-iteration task tables are populated into `iterations/<NNN>/plan.md` at each before-implement gate.
