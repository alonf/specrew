# Plan: F-047 Trust-Hardening Bug-Bash Bundle

**Feature**: `047-bug-bash-trust-hardening`  
**Date**: 2026-05-26  
**Status**: Draft  
**Input**: F-047 Bug-Bash + Improvement Brief (7 items)  

---

## 1. Summary & Goals

Deliver 7 bundled lifecycle-tooling reliability + downstream-user trust-hardening fixes as the v0.27.3 minor patch. Theme: make Specrew's user-facing prose decodable by downstream users (no opaque internal references), and make the lifecycle tooling detect/prevent the prose-discipline and persistence-layer gaps empirically observed across F-046 and the PlanningPoC sessions. All new detection is WARN-only (backward-compatible). This release also deploys F-046's already-landed fixes to the installed module.

---

## 2. Substantive Decisions

### Decision 1: All new detection is WARN, never FAIL (FR-016)

New validator rules (handoff-block presence, missing-dashboard diagnosis, wrong-location, mermaid-absence, internal-reference regex) emit WARN findings only. Rationale: backward compatibility — existing repos must not start FAILing governance on the day they update.

### Decision 2: Single iteration for all 7 items

Per the brief + operator preference. Execution order: Item 1 (foundation) → Item 2 (its regression lock) → Items 3–7 in any order → release/closeout. ~12-20 SP within the 20 SP cap.

### Decision 3: Tests-first rhythm

Every fix lands a failing fixture/test BEFORE the runtime change. Item 2 is itself purely a test (the regression lock for Item 1's sub-trigger 3c).

### Decision 4: Mirror parity (FR-014)

Every change to `extensions/specrew-speckit/scripts/*` is mirrored byte-identical in `.specify/extensions/specrew-speckit/scripts/*`. Verified by `diff -q` at review.

### Decision 5: Item 4 is a bounded subset

Item 4 implements only Proposal 078 Pillar 2b (the internal-reference regex check) + the `installed-instructions/` audit/rewrite. The full 5-pillar Proposal 078 and the full Proposal 099 installed-file audit remain out of scope.

### Decision 6 (out-of-scope finding): cross-feature authorization-cursor bleed

While starting F-047, the boundary-sync helper's `last_authorized_boundary` was found to be global (not feature-scoped); F-046's own T004 backward-guard then refuses to record a new feature's early-boundary verdicts. This is architecturally part of the out-of-scope verdict-history atomic refactor work, NOT one of the 7 items. It is recorded in findings.md as a follow-up and handled operationally for this feature (one-time cursor reset at the before-implement gate), not fixed here.

---

## 3. Existing Specify/Planning Artifacts

The following planning artifacts accompany this plan and must not be re-scaffolded or overwritten:

- **Data Model**: [data-model.md](file:///C:/Dev/Specrew/specs/047-bug-bash-trust-hardening/data-model.md)
- **Quickstart**: [quickstart.md](file:///C:/Dev/Specrew/specs/047-bug-bash-trust-hardening/quickstart.md)
- **Contract**: [contracts/trust-hardening.md](file:///C:/Dev/Specrew/specs/047-bug-bash-trust-hardening/contracts/trust-hardening.md)
- **Review Diagrams**: [review-diagrams.md](file:///C:/Dev/Specrew/specs/047-bug-bash-trust-hardening/review-diagrams.md)
- **Findings Ledger**: [findings.md](file:///C:/Dev/Specrew/specs/047-bug-bash-trust-hardening/findings.md)

---

## 4. Implementation Slices

### Slice 1: Item 1 — Handoff-block validator enforcement (FR-001/002/003)

- **Files**: `extensions/specrew-speckit/scripts/validate-governance.ps1` (+ `.specify/` mirror), `extensions/specrew-speckit/scripts/shared-governance.ps1` (+ mirror, helper `Test-SpecrewHandoffBlockPresent`)
- **Approach**: Add a shared presence helper + three WARN-emitting checks. Pillar 1 inspects the boundary commit window for a handoff block. Pillar 2 augments the existing missing-`dashboard.md` diagnosis to branch on whether the iteration is Specrew-managed (feature.json/iteration markers present) vs. an auto-render regression. Pillar 3 scans for canonical artifact filenames under ephemeral host-scratch path patterns.
- **Tests**: `tests/integration/non-specrew-session-bypass.tests.ps1` (new).

### Slice 2: Item 2 — Post-compaction acceptance test (FR-004)

- **Files**: `tests/integration/non-specrew-session-bypass.tests.ps1` (extend)
- **Approach**: Add the sub-trigger 3c scenario — missing handoff + compaction marker in session metadata ⇒ WARN. Pure test slice locking the Item 1 detector.

### Slice 3: Item 3 — Review-diagrams mermaid hardening (FR-005/006/007)

- **Files**: `validate-governance.ps1` (+ mirror), `scaffold-reviewer-artifacts.ps1` (+ mirror), per-host Reviewer charter templates
- **Approach**: Validator soft-WARN when `review-diagrams.md` exists with no ` ```mermaid ` block. Scaffolder emits a Mermaid skeleton (component `graph TD` + `sequenceDiagram`). Reviewer charters gain a "use Mermaid, not ` ```text ` ASCII trees" directive.
- **Tests**: extend reviewer-artifacts/validator fixtures.

### Slice 4: Item 4 — Downstream-language audit + regex (FR-008/009)

- **Files**: `installed-instructions/*` + coordinator-prompt templates (audit/rewrite), `validate-governance.ps1` (+ mirror, regex check)
- **Approach**: Audit for `\bF-\d{3,}\b` / `\bProposal \d{3,}\b` / `\bFeature \d{3,}\b`; rewrite each to the methodology concept. Add a validator WARN when those patterns appear in handoff-block prose. Anchor patterns to avoid version strings / years.
- **Tests**: regex unit fixtures + post-rewrite grep assertion.

### Slice 5: Item 5 — Skill-catalog empty-dir UX (FR-010)

- **Files**: `scripts/internal/skill-catalog-state.ps1`, `scripts/internal/detect-hosts.ps1`
- **Approach**: `Get-SpecrewSkillCatalogState` treats a skill root dir with zero `SKILL.md` files as a missing root (content check), so auto-repair fires and the contradictory per-host WARN no longer survives.
- **Tests**: `tests/integration/` skill-catalog fixture (empty dir ⇒ HasMissingRoots true).

### Slice 6: Item 6 — Feature-closeout SDLC handoff (FR-011)

- **Files**: per-host coordinator-prompt templates; optionally `extensions/specrew-speckit/scripts/sync-boundary-state.ps1` (+ mirror) post-closeout console output
- **Approach**: Embed the PR-at-feature-close SDLC action items (push → PR → address automated PR review → merge) in every host's feature-closeout HANDOFF template.
- **Tests**: template-presence assertion across hosts.

### Slice 7: Item 7 — tasks-progress.yml resume reconciliation (FR-012)

- **Files**: `scripts/specrew-start.ps1` (regeneration path)
- **Approach**: Parse `tasks.md` `[x]` checkboxes + `state.md` `Last Completed Task`; derive per-task status (tasks.md authoritative); surface divergence rather than silently overwriting all-pending.
- **Tests**: `tests/integration/` fixture (complete tasks.md ⇒ derived `done`).

### Slice 8: Release + closeout (FR-013/014/015)

- v0.27.3 bump across `.specrew/config.yml`, `extension.yml`, `Specrew.psd1`; CHANGELOG entry; mirror-parity verification; full integration-suite no-regression run; findings.md completion.

---

## 5. FR → Test Mapping

| FR | Verified by |
| --- | --- |
| FR-001 | `non-specrew-session-bypass.tests.ps1` (handoff-presence WARN + helper) |
| FR-002 | `non-specrew-session-bypass.tests.ps1` (missing-dashboard diagnosis branch) |
| FR-003 | `non-specrew-session-bypass.tests.ps1` (wrong-location WARN) |
| FR-004 | `non-specrew-session-bypass.tests.ps1` (sub-trigger 3c post-compaction) |
| FR-005 | validator mermaid-absence fixture |
| FR-006 | reviewer-artifacts scaffolder skeleton fixture |
| FR-007 | per-host charter content assertion |
| FR-008 | post-rewrite grep assertion over `installed-instructions/` |
| FR-009 | validator internal-reference regex fixture |
| FR-010 | skill-catalog empty-dir fixture (HasMissingRoots true) |
| FR-011 | per-host feature-closeout template presence assertion |
| FR-012 | tasks-progress reconciliation fixture |
| FR-013 | findings.md completeness review |
| FR-014 | `diff -q` mirror parity check |
| FR-015 | version-consistency across 3 manifests |
| FR-016 | all new-rule fixtures assert WARN (not FAIL) |

---

## 6. Quality Planning (Phase 1 profile: bounded custom composition)

Resolved profile `quality-profile.custom-composition.v1`. Required risk dimensions: **code-quality, design-quality & separation-of-concerns, verification-confidence, maintainability**. Not-applicable: concurrency-correctness, resiliency, retry-idempotency-and-recovery (no shared-state/realtime/retry workflow in this slice). Active lenses: security-baseline, robustness-baseline, test-integrity.

- **Code quality**: changes are small, localized PowerShell edits + new test fixtures; helpers (e.g. `Test-SpecrewHandoffBlockPresent`) are factored into `shared-governance.ps1` for reuse rather than duplicated across validator/sync.
- **Design quality**: new validator rules are additive WARN checks that do not alter existing FAIL pathways; mirror parity keeps `extensions/` and `.specify/` from diverging.
- **Verification confidence**: tests-first; each FR has an explicit fixture; the post-compaction case (Item 2) is locked as a regression test; full integration suite run as no-regression gate.
- **Maintainability**: regex patterns are anchored + documented to avoid false positives (version strings, years); skill-catalog content-check is deterministic.
- **Mechanical gates**: dead-field, anti-pattern, test-integrity → `quality/mechanical-findings.json`; stack-tooling-evidence (PowerShell Pester/`Invoke-Pester` + the integration suites) → `quality/quality-evidence.md`.

### Phase 2 hardening-gate slice scope

US-2 (handoff-block enforcement) carries the hardening-gate planning scope. Pre-implementation readiness accepts planning-time analysis + expected controls + rationale + explicit non-applicable markings (no runtime hardening implied beyond the WARN detection).

---

## 7. Risks & Mitigation

- **Regex false positives (Item 4)**: anchor to internal-reference prefixes (`F-`, `Proposal `, `Feature `) + ≥3 digits; exclude version/year tokens. Mitigation: explicit negative fixtures.
- **Mirror divergence**: enforced by FR-014 `diff -q` at review.
- **Cross-feature cursor bleed** (Decision 6): handled by a one-time cursor reset at the before-implement gate; root fix deferred to the verdict-history atomic refactor follow-up (recorded in findings.md).
- **Installed-module staleness**: every boundary sync uses the dev-tree `SPECREW_MODULE_PATH` override until v0.27.3 ships and is installed; the release itself resolves this.
- **Scope creep into full Proposal 078/099**: bounded by Decision 5.
