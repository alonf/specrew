updated_at: 2026-05-16T18:29:12Z
focus_area: Feature 019 review repair
active_issues: Review boundary for Feature 019 Iteration 001 found blocking explicit `FileList` allowlist drift. `Specrew.psd1` still omits required distributable files including `scripts/internal/invoke-module-release.ps1` and `templates/github/agents/squad.agent.md`, so package-shaped US1/US2 and publish-surface evidence must be repaired before signoff. Human-owned release follow-up (T042, T053) and Iteration 002 deferrals (T041, T054) remain non-blocking.
---

What We're Focused On
====================

**Phase**: Feature 019 Iteration 001 review boundary is complete; bounded repair is required.
**Urgency**: Tier 1 — repair the explicit allowlist gap without widening scope, then return to independent review.

---

Current Status
--------------

Feature Lifecycle: REVIEW-REPAIR-NEEDED

- Feature 019 is `Specrew Distribution Module via PowerShell Gallery`
- Clarified spec: `file:///C:/Dev/Specrew/specs/019-specrew-distribution-module/spec.md`
- Implementation plan: `file:///C:/Dev/Specrew/specs/019-specrew-distribution-module/plan.md`
- Task breakdown: `file:///C:/Dev/Specrew/specs/019-specrew-distribution-module/tasks.md`
- Public proposal: `file:///C:/Dev/Specrew/proposals/031-specrew-distribution-module.md` (`draft`)
- Hardening gate artifact: `file:///C:/Dev/Specrew/specs/019-specrew-distribution-module/iterations/001/quality/hardening-gate.md` (canonical format, READY verdict)
- Iteration plan: `file:///C:/Dev/Specrew/specs/019-specrew-distribution-module/iterations/001/plan.md` (canonical format with Schema, Started, Capacity, Effort Model)
- Hardening-gate-and-implementation-auth boundary completed on 2026-05-16T17:42:05Z
- Governance repair completed on 2026-05-16T19:00:00Z
- Validation status: Phase 0 through Phase 6 Windows-first validations passed, but review found explicit allowlist drift that the current package-surface tests did not catch.
- Implementation execution has completed the authorized Iteration 001 slice: Phase 0, Pillars 1-5, and the Windows-first final-validation tasks.
- T001 resolved by human verdict: **Option 1 — Explicit FileList allowlist for Specrew.psd1**.
- T001 rationale captured in `specs/019-specrew-distribution-module/contracts/Specrew.psd1.contract.md` and `.squad/decisions.md`.
- T002 resolved by human verdict: **Option A — Git-style conflict markers in `.specrew/template-conflicts/<filename>.conflict` artifacts**.
- T002 rationale and compose-with flow captured in `specs/019-specrew-distribution-module/spec.md`, `research.md`, `data-model.md`, and `.squad/decisions.md`.
- T003 resolved by human verdict: **Option A — manual checklist/evidence for Iteration 001**.
- T003 rationale, checklist scaffold, and Iteration 002 deferrals are captured in `plan.md`, `research.md`, `tasks.md`, `iterations/001/state.md`, `iterations/001/quality/cross-platform-manual-checklist.md`, and `.specrew/cross-platform-backlog.md`.
- T004 resolved by human verdict: **Option A — explicit dot-sourcing for `Specrew.psm1`**.
- T004 rationale and approved loader order are captured in `contracts/Specrew.psd1.contract.md`, `plan.md`, `research.md`, `tasks.md`, `iterations/001/plan.md`, `iterations/001/state.md`, and `.squad/decisions.md`.
- T005 resolved by human verdict: **Option A — document lightweight PSGallery API-key rotation cadence now**.
- T005 cadence/procedure are captured in `docs/operations/psgallery-release-credentials.md`, `plan.md`, `research.md`, `data-model.md`, `tasks.md`, `iterations/001/plan.md`, `iterations/001/state.md`, and `.squad/decisions.md`.
- T005 remains documentation-only and non-blocking.
- T006 resolved by human verdict: **Option A — 1-year validity for the self-signed module-signing certificate**.
- T006 rationale and renewal procedure are captured in `docs/operations/psgallery-release-credentials.md`, `plan.md`, `research.md`, `data-model.md`, `tasks.md`, `iterations/001/plan.md`, `iterations/001/state.md`, and `.squad/decisions.md`.
- Pillar 1 is complete: `Specrew.psd1` and `Specrew.psm1` exist at repo root and expose the FR-002 command surface.
- Pillar 2 implementation is present, but review found the manifest allowlist still incomplete for the approved shipped package contract.
- **39 total tasks** across 6 phases
  - **Phase 0 (Design Questions)**: 6 tasks explicitly resolving plan-time design questions
    - T001: Module Manifest File-List Strategy (blocks Pillar 1/2)
    - T002: Conflict-Marker Format (blocks Pillar 4)
    - T003: Cross-Platform Test Automation Depth (blocks Pillar 5)
    - T004: Module Loader Structure (blocks Pillar 1)
    - T005: API-Key Rotation Guidance (documentation-only)
    - T006: Self-Signed Certificate Validity Period (blocks Pillar 5)
  - **Pillar 1 (Module Packaging)**: 3 tasks (US1, US2, US4)
  - **Pillar 2 (Resource Bundling)**: 5 tasks (US1, US2)
  - **Pillar 3 (Init Refactor)**: 5 tasks (US2, US5)
  - **Pillar 4 (Update Story)**: 6 tasks (US3, US5)
  - **Pillar 5 (Publishing Workflow)**: 7 tasks (US4, US5)
  - **Phase 6 (Final Validation)**: 7 tasks (US1-US5)
  - Task-count-per-pillar: Phase0=6, P1=3, P2=5, P3=5, P4=6, P5=7, Validation=7
  - Explicit dependencies captured with "Blocks" annotations
  - Parallel execution opportunities identified (16+ parallel-capable tasks)
  - Critical path defined: Phase 0 → P1/P2 (parallel) → P3 → P4/P5 (parallel) → Validation
- Branch: `019-specrew-distribution-module`
- Estimated effort: 14 SP (within 10-15 SP spec estimate)
- **Authorization scope**: Iteration 001 implementation is complete, but review signoff is blocked pending a bounded repair to the manifest allowlist and package-shaped evidence.
- **Hardening Gate Status**: READY verdict with canonical concerns; sign-off complete (2026-05-16T17:42:05Z)
- **Critical Constraint**: Iteration 001 remains Windows-first; do not pull Ubuntu/macOS/WSL hardening, broader embedded backslash cleanup, or new validator work into this slice.

Next Valid Action

Authorize bounded repair items `R-019-R1` and `R-019-R2` for the manifest allowlist and package-shaped evidence, then return Feature 019 Iteration 001 to independent `/review`.
