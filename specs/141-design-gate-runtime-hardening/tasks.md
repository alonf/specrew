# Tasks: Design Gate Runtime Hardening — Iteration 1

**Input**: Design documents from `specs/141-design-gate-runtime-hardening/`
**Prerequisites**: `plan.md`, `spec.md`, `data-model.md`, `quickstart.md`, `contracts/design-gate-runtime-hardening.md`, `review-diagrams.md`, `iterations/001/design-analysis.md` (Option B)
**Branch**: `141-design-gate-runtime-hardening` (stacked on Feature 140 tip)
**Iteration**: 001 — design-gate runtime path + validator robustness
**Capacity**: 18/20 story_points
**Protected Core**: Scaffold/template, pre-plan validator + enforcement, typed packet + durable 155-lite, validator robustness (FR-022/FR-023), and focused tests must stay intact and firm. The Applicable Lenses section (T008, FR-009/FR-010) is **deferred to a later iteration within Feature 141** per the 2026-06-02 directive — deferred-within-feature, not dropped — so Iteration 1 starts at 18 SP with implementation headroom under the 20 SP cap.

## Phase 1: Foundation and Scope Guardrails

**Goal**: Lock scope and exclusions before touching runtime code.

**Independent Test Criteria**: Scope review proves no task implements full Proposal 155, Proposal 156 automation, Proposal 105 hooks, broad validator rollout, Unix/wrapper/bootstrap edits, or release publishing.

- [ ] T001 [US0] [Owner: Spec Steward] [Capacity: 1 story_points] Confirm Iteration 1 scope against `specs/141-design-gate-runtime-hardening/plan.md`, preserve Option B and the scope limits, and record any found overrun in `specs/141-design-gate-runtime-hardening/iterations/001/drift-log.md`. (Trace: FR-016, FR-017, FR-018, FR-019, SC-011, SC-013)

**Checkpoint**: Scope and exclusions explicit before implementation.

---

## Phase 2: Protected Core — Scaffold and Template

**Goal**: Emit a conformant `design-analysis.md` from a versioned template reconciled with the Feature 140 validator contract.

**Independent Test Criteria**: A freshly scaffolded artifact passes the Feature 140 validator once filled; the scaffold never overwrites an existing decision record.

- [ ] T002 [US1] [Owner: Implementer] [Capacity: 3 story_points] Add `extensions/specrew-speckit/templates/design-analysis.template.md` and a scaffold path (extend `scripts/internal/design-analysis-gate.ps1`) that emits `specs/<feature>/iterations/<NNN>/design-analysis.md` from the template, reconciled with the validator contract (single-token recommendation, hyphenated By-the-book), without overwriting an existing artifact. (Trace: FR-001, FR-008, TG-007, SC-001)

**Checkpoint**: Scaffold output is validator-passing and non-destructive.

---

## Phase 3: Protected Core — Validator Robustness (FR-022/FR-023, firm)

**Goal**: Make the Feature 140 validator tolerant of well-authored prose while still enforcing option shape and a single recommendation.

**Independent Test Criteria**: A prose By-the-book heading and a recommendation that mentions rejected options contextually both pass; a missing/undistinct By-the-book and a genuinely multi-recommendation section both still fail.

- [ ] T003 [US1] [Owner: Implementer] [Capacity: 1 story_points] Make By-the-book detection in `scripts/internal/design-analysis-gate.ps1` tolerant of normal prose ("By the book" with or without hyphen) while still enforcing the conditional option shape. (Trace: FR-022, SC-014)
- [ ] T004 [US1] [Owner: Implementer] [Capacity: 2 story_points] Make Crew Recommendation parsing resolve exactly one selected option without failing on contextual mentions of rejected/alternative options, and add unit tests for the tolerant-pass and genuine-multi-recommendation-fail cases. (Trace: FR-023, SC-014)

**Checkpoint**: Validator accepts good prose, rejects genuine violations.

---

## Phase 4: Protected Core — Pre-Plan Validation and Enforcement

**Goal**: Block substantive `plan.md` authoring until the artifact and human decision are valid, before plan content exists.

**Independent Test Criteria**: A missing/invalid artifact or an unrecorded human decision blocks plan authoring with an actionable message; a valid artifact + decision passes.

- [ ] T005 [US1] [Owner: Implementer] [Capacity: 3 story_points] Add a callable pre-plan validator (reusing the Feature 140 validation core) and update `scripts/specrew-start.ps1` generated guidance so the coordinator must not author substantive `plan.md` before the artifact and human decision are valid; no host-native hooks. (Trace: FR-002, FR-003, FR-021, SC-002)

**Checkpoint**: Pre-plan enforcement is checkable, not only narrated.

---

## Phase 5: Protected Core — Typed Packet, Durable Storage, Continuity

**Goal**: Render and validate the design-analysis gate packet from typed fields and persist a narrow durable packet scoped to this gate.

**Independent Test Criteria**: A packet rendered from typed fields validates (six sections, `file:///` refs, verdict shape); a malformed packet fails; the selected option propagates to plan input.

- [ ] T006 [US2] [Owner: Implementer] [Capacity: 2 story_points] Implement the typed design-analysis gate packet renderer + validator (required human re-entry sections, `file:///` references, `approved for plan with Option <X>` verdict shape). (Trace: FR-004, FR-005, SC-004)
- [ ] T007 [US2] [Owner: Implementer] [Capacity: 2 story_points] Persist a narrow 155-lite packet under `specs/<feature>/gates/` for the design-analysis gate only (no generalization), and preserve the human-selected option/modifications as authoritative plan input. (Trace: FR-006, FR-007, FR-020, SC-003, SC-005)

**Checkpoint**: Packet is auditable and scoped; selected option flows to plan.

---

## Phase 6: Applicable Lenses — DEFERRED to a later iteration within Feature 141

**Goal**: Surface relevant existing lens files read-only in `design-analysis.md`.

**Status**: **Deferred-within-feature** per the 2026-06-02 directive. Not part of Iteration 1's 18 SP; not dropped. Carried as a named obligation for a later Feature 141 iteration (sequenced after the smoke-bundle iterations or as a dedicated lens slice).

- [~] T008 [US3] [Owner: Implementer] [Capacity: 2 story_points — DEFERRED to later Feature 141 iteration; NOT counted in Iteration 1's 18 SP] Render a lightweight read-only "Applicable Lenses" section referencing existing files under `extensions/specrew-speckit/templates/quality/lenses/`, degrading gracefully when absent. (Trace: FR-009, FR-010, SC-006)

**Checkpoint**: Lens deferral is recorded; Iteration 1 proceeds without it.

---

## Phase 7: Tests, Docs, and Review Readiness

**Goal**: Prove runtime behavior and close documentation/evidence gaps.

**Independent Test Criteria**: Tests exercise real block/pass and render/validate behavior (not file-presence); docs match final command/file names.

- [ ] T009 [US1] [Owner: Implementer, Reviewer] [Capacity: 2 story_points] Add unit tests for scaffold conformance, packet render/validate, and validator-robustness positive/negative cases under `tests/unit/`. (Trace: SC-001, SC-004, SC-012, SC-014)
- [ ] T010 [US1] [Owner: Implementer, Reviewer] [Capacity: 1 story_points] Add integration tests for pre-plan block/pass and compatibility skip under `tests/integration/`. (Trace: FR-002, FR-003, SC-002, SC-012)
- [ ] T011 [US0] [Owner: Planner, Reviewer] [Capacity: 1 story_points] Refresh `contracts/design-gate-runtime-hardening.md`, `quickstart.md`, `data-model.md`, `review-diagrams.md` to final names and record the review gap ledger (implemented/enforced/observable/documented). (Trace: TG-006, SC-011)

**Checkpoint**: Iteration 1 is review-ready within the 20 SP cap.

---

## Dependencies and Execution Order

- T001 precedes implementation.
- T002 (scaffold/template) and T003/T004 (validator robustness) build the artifact + validator; they precede T005 (pre-plan enforcement consumes the validation core).
- T006/T007 (packet) can proceed after the validation core is stable.
- T008 (lenses) is deferred to a later Feature 141 iteration; not executed in Iteration 1.
- T009/T010 (tests) follow the behavior they cover; T011 (docs) follows surface stabilization.
- Sequence edits to `scripts/internal/design-analysis-gate.ps1` (T002, T003, T004, T005, T006, T007) to avoid conflicts.

## Parallel Opportunities

- T003 and T004 (validator robustness) can be prepared in parallel with T006 packet work after the validation core API is fixed.
- T011 docs can proceed in parallel with T009/T010 once surfaces stabilize.

## Verification Commands

```powershell
pwsh -File tests/unit/design-analysis-gate.tests.ps1
pwsh -File tests/integration/design-analysis-boundary.tests.ps1
pwsh -File .specify/extensions/specrew-speckit/scripts/validate-governance.ps1 -ProjectPath .
```

## Traceability Summary (Iteration 1)

| Requirement / Success Criterion | Covering Tasks |
| --- | --- |
| FR-001 | T002 |
| FR-002 | T005, T010 |
| FR-003 | T005, T010 |
| FR-004 | T006 |
| FR-005 | T006 |
| FR-006 | T007 |
| FR-007 | T007 |
| FR-008 | T002 |
| FR-009 | T008 (deferred — later Feature 141 iteration) |
| FR-010 | T008 (deferred — later Feature 141 iteration) |
| FR-016 | T001 |
| FR-017 | T001 |
| FR-018 | T001 |
| FR-019 | T001 |
| FR-020 | T007 |
| FR-021 | T005 |
| FR-022 | T003 |
| FR-023 | T004 |
| TG-005 | T001 |
| TG-006 | T011 |
| TG-007 | T002 |
| SC-001 | T002, T009 |
| SC-002 | T005, T010 |
| SC-003 | T007 |
| SC-004 | T006, T009 |
| SC-005 | T007 |
| SC-006 | T008 (deferred — later Feature 141 iteration) |
| SC-011 | T001, T011 |
| SC-012 | T009, T010 |
| SC-013 | T001 |
| SC-014 | T003, T004, T009 |

### Deferred to later iterations (tracked in plan.md, not Iteration 1 tasks)

| Requirement / Success Criterion | Iteration | Notes |
| --- | --- | --- |
| FR-009, FR-010, SC-006 (Applicable Lenses) | later Feature 141 iteration | Pre-deferred 2026-06-02 to keep Iteration 1 at 18 SP with headroom; deferred-within-feature, not dropped (T008). |
| FR-011 (empty start-packet paths) | Iteration 2 | Start-packet correctness; reproduction confirmed at iter-2 planning. |
| FR-014 (host wording leak) | Iteration 2 | Bundled with FR-011 (same generator surface). |
| FR-012 (noisy downstream warnings) | Iteration 3 | Greenfield/downstream hygiene. |
| FR-013 (greenfield baseline commit) | Iteration 3 | Bundled with FR-012. |
| FR-015 (smoke bugs stay in feature) | all | Governance guard; enforced across iterations. |
| SC-007, SC-010 | Iteration 2 | Start-packet path + per-host wording tests. |
| SC-008, SC-009 | Iteration 3 | Warning-scope + baseline-commit tests. |
