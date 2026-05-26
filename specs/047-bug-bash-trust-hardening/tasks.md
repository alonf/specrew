# Tasks: F-047 Trust-Hardening Bug-Bash Bundle

**Input**: Design documents from `specs/047-bug-bash-trust-hardening/`  
**Prerequisites**: `plan.md`, `spec.md`, `data-model.md`, `contracts/trust-hardening.md`, `quickstart.md`, `findings.md`  
**Scope Guardrail**: Strictly limited to the 7-item F-047 bundle. Tests-first; mirror parity for all `extensions/specrew-speckit/scripts/*` edits. All new detection is WARN, never FAIL.

## Phase 1: Item 1 — Handoff-Block Validator Enforcement (foundation)

- [x] T001 [P] [assigned_to: Implementer] [effort: S] Create handoff-block detection fixtures in `tests/integration/non-specrew-session-bypass.tests.ps1` covering: (1) boundary commit with no preceding handoff block ⇒ WARN, (2) missing `dashboard.md` classified as non-Specrew-managed vs auto-render regression, (3) canonical artifact under an ephemeral host-scratch path ⇒ WARN. Assert WARN (not FAIL). (Trace: FR-001, FR-002, FR-003, FR-016, SC-001, SC-002, SC-003)
- [x] T002 [assigned_to: Implementer] [effort: M] Implement `Test-SpecrewHandoffBlockPresent` in `extensions/specrew-speckit/scripts/shared-governance.ps1` and the 3 WARN checks (Pillars 1-3) in `extensions/specrew-speckit/scripts/validate-governance.ps1`. (Trace: FR-001, FR-002, FR-003, FR-016)
- [x] T003 [assigned_to: Implementer] [effort: S] Mirror Item 1 changes byte-identical to `.specify/extensions/specrew-speckit/scripts/{shared-governance,validate-governance}.ps1`. (Trace: FR-014)

---

## Phase 2: Item 2 — Post-Compaction Handoff-Drop Acceptance Test

- [x] T004 [assigned_to: Implementer] [effort: S] Add the sub-trigger 3c scenario to `tests/integration/non-specrew-session-bypass.tests.ps1`: missing handoff block AND a compaction marker in session metadata ⇒ WARN; locks the Item 1 detector as a regression test. (Trace: FR-004, SC-004)

---

## Phase 3: Item 3 — Review-Diagrams Mermaid Template Hardening

- [x] T005 [P] [assigned_to: Reviewer] [effort: S] Create fixtures: validator soft-WARN when `review-diagrams.md` exists with no ` ```mermaid ` block (and no-WARN when both ` ```mermaid ` and ` ```text ` present); reviewer-artifacts scaffolder emits a non-empty Mermaid skeleton. (Trace: FR-005, FR-006, SC-005)
- [x] T006 [assigned_to: Reviewer] [effort: S] Implement the validator soft-WARN and the `scaffold-reviewer-artifacts.ps1` Mermaid skeleton (component `graph TD` + `sequenceDiagram`). (Trace: FR-005, FR-006, FR-016)
- [x] T007 [assigned_to: Reviewer] [effort: S] Add the "use Mermaid, not ` ```text ` ASCII trees" directive to per-host Reviewer charter templates and mirror scaffolder/validator changes to `.specify/extensions/specrew-speckit/scripts/`. (Trace: FR-007, FR-014)

---

## Phase 4: Item 4 — Downstream-Language Audit + Internal-Reference Regex

- [x] T008 [P] [assigned_to: Implementer] [effort: S] Create internal-reference regex fixtures: positive (`Feature 016` in handoff prose ⇒ WARN) and negative (version `v0.27.3`, years, ≤2-digit tokens do NOT WARN). (Trace: FR-009, SC-006)
- [x] T009 [assigned_to: Spec Steward] [effort: S] Audit all `installed-instructions/` files + coordinator-prompt templates for `\bF-\d{3,}\b` / `\bProposal \d{3,}\b` / `\bFeature \d{3,}\b`; rewrite each to name the methodology concept. (Trace: FR-008, SC-006)
- [x] T010 [assigned_to: Implementer] [effort: S] Implement the validator internal-reference regex WARN (handoff prose) and mirror. (Trace: FR-009, FR-014, FR-016)

---

## Phase 5: Item 5 — Skill-Catalog Empty-Directory UX

- [x] T011 [P] [assigned_to: Implementer] [effort: S] Create a fixture where a skill root dir exists with zero `SKILL.md` files; assert `Get-SpecrewSkillCatalogState` returns `HasMissingRoots = true`. (Trace: FR-010, SC-007)
- [x] T012 [assigned_to: Implementer] [effort: S] Implement the content-based missing-root check in `scripts/internal/skill-catalog-state.ps1` (zero `SKILL.md` ⇒ missing) so auto-repair fires and no contradictory per-host WARN survives. (Trace: FR-010)

---

## Phase 6: Item 6 — Feature-Closeout SDLC Actions in HANDOFF

- [x] T013 [P] [assigned_to: Spec Steward] [effort: S] Create a template-presence assertion test verifying every per-host coordinator feature-closeout HANDOFF template contains the PR-at-feature-close SDLC action items. (Trace: FR-011, SC-008)
- [x] T014 [assigned_to: Spec Steward] [effort: S] Embed the PR-at-feature-close SDLC sequence (push → open PR → address automated PR review → merge) in per-host coordinator-prompt feature-closeout HANDOFF templates; optionally echo from `sync-boundary-state.ps1` post-closeout output (+ mirror if touched). (Trace: FR-011)

---

## Phase 7: Item 7 — tasks-progress.yml Resume Reconciliation

- [x] T015 [P] [assigned_to: Implementer] [effort: S] Create a fixture where `tasks.md` shows all `[x]` and `state.md` confirms completion; assert the regenerated `tasks-progress.yml` marks tasks `done` (not `planned`). (Trace: FR-012, SC-009)
- [x] T016 [assigned_to: Implementer] [effort: S] Implement derive-from-`tasks.md` regeneration in `scripts/specrew-start.ps1` (tasks.md authoritative; surface `tasks.md`↔`state.md` divergence). (Trace: FR-012)

---

## Phase 8: Release & Closeout

- [x] T017 [assigned_to: Implementer] [effort: S] Bump version to `v0.27.3` across `.specrew/config.yml`, `extension.yml`, `Specrew.psd1` (ModuleVersion), and add a `CHANGELOG.md` entry. (Trace: FR-015)
- [x] T018 [assigned_to: Reviewer] [effort: S] Verify mirror parity byte-identical (`diff -q`) for every modified `extensions/specrew-speckit/scripts/*` file vs `.specify/extensions/...`. (Trace: FR-014, SC-010)
- [x] T019 [assigned_to: Reviewer] [effort: S] Run mechanical checks + all integration suites as a no-regression sweep; complete the `findings.md` ledger (per-item evidence pointers + status). (Trace: FR-013, SC-010)
