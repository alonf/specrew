# Decision: Feature 019 Before-Implement Quality Gate

**Date**: 2026-05-16  
**Boundary**: /speckit.specrew-speckit.before-implement  
**Feature**: 019-specrew-distribution-module (Specrew Distribution Module via PowerShell Gallery)  
**Authority**: Alon Fliess (user authorization)  
**Decision Type**: Quality-gate boundary with hardening-gate readiness verdict

## Runtime Evidence

Executed before-implement quality gate for Feature 019 Specrew Distribution Module. Applied 6 required quality lenses to spec.md, plan.md, and tasks.md artifacts.

**Artifacts Evaluated**:
- Spec: C:\Dev\Specrew\specs\019-specrew-distribution-module\spec.md (5 User Stories, 32 Functional Requirements)
- Plan: C:\Dev\Specrew\specs\019-specrew-distribution-module\plan.md (5-pillar architecture, 14 SP estimate)
- Tasks: C:\Dev\Specrew\specs\019-specrew-distribution-module\tasks.md (39 tasks across 6 phases)
- Supporting artifacts: research.md, data-model.md, quickstart.md, contracts/Specrew.psd1.contract.md

## Quality Lens Verdicts

### Lens 1: Constitution Alignment — ✅ PASS
- Principle I (Spec Is Authoritative): Plan tracks back to approved spec FRs; no ad-hoc scope detected
- Principle II (Layered System): All changes are Spec Kit layer (module packaging, scripts); no Squad layer violations
- Principle IX (Mandatory Traceability): All 39 tasks have explicit FR/US traceability; tasks.md Traceability Map complete
- Principle XIII (Spec Stewardship): Alon Fliess explicitly named as Spec Steward
- Principle XIV (Iteration Facilitation): Alon Fliess explicitly named as Iteration Facilitator
- Principle XVII (Planning Starts From Approved Specs): All tasks derived from spec FRs; no ad-hoc prompts
- Principle XXI (Verification Is Mandatory): Phase 1 quality gates defined; user story acceptance scenarios planned

### Lens 2: Traceability Completeness — ✅ PASS
- All 5 User Stories map to specific FRs with bidirectional traceability
- All 32 Functional Requirements have task coverage across 6 phases (Phase 0-5, Final Validation)
- All 39 tasks include explicit FR/US trace annotations in parenthetical (Trace: ...) format
- Explicit dependency tracking: T001-T006 block Pillars 1-5; Pillar 3 blocks Pillar 4; all blocks documented
- No orphaned tasks: All tasks trace to US1-US5 via FR-001 through FR-032
- Success criteria SC-001 through SC-006 map to specific user stories and validation tasks T050-T056

### Lens 3: Cross-Platform Coverage — ✅ PASS
- FR-030 mandates Join-Path for all path construction; WSL verification task explicitly planned
- FR-031 requires testing on Windows, Linux (Ubuntu), and macOS before every release
- FR-032 mandates PSEdition = Core to enforce PowerShell 7+ cross-platform requirement
- T003 design-question task explicitly addresses cross-platform test automation depth (manual vs automated)
- T040 implements cross-platform verification per T003 decision; T041 provides Join-Path audit script
- T054 validates US5 Cross-Platform Consistency scenarios on Linux, macOS, and PS 5.1 rejection
- US5 includes specific acceptance scenarios for forward-slash paths on Linux, macOS path display, and PS 5.1 install failure

### Lens 4: Test Strategy Coverage — ✅ PASS
- Pillar 1 (Module Packaging): T009 validates manifest with Test-ModuleManifest; manual test checklist planned
- Pillar 2 (Resource Bundling): T014 validates exclusions and size estimate; directory structure verification planned
- Pillar 3 (Init Refactor): T019 implements bootstrap validation; integration test for module-path init planned
- Pillar 4 (Update Story): Conflict-resolution test scenario with two module versions; conflict marker verification planned
- Pillar 5 (Publishing Workflow): GitHub Actions workflow validation, test tag dry-run, PSGallery verification planned
- Phase 6 (Final Validation): Explicit test tasks for all 5 user stories (T050-T054) with evidence collection
- T055 validates all 6 success criteria with measurements; T056 finalizes quickstart guide based on test evidence
- Plan Phase 1 Quality Planning documents 6 required quality gates with evidence sources and status

### Lens 5: Validator Integration Sketch — ✅ PASS
- Plan defines drift detection via Specrew-Speckit validators during /speckit.implement boundary
- Drift-detection mechanism includes: (1) Specrew-Speckit validators, (2) integration test failures, (3) manual PSGallery publish log review
- Validators will check spec-to-task traceability on every task completion during implementation
- Spec defines Human Oversight Points for clarify-time decisions, planning approval, pre-release manual test, and post-release verification
- Plan Phase 2 Quality Planning explicitly defers hardening gate and specialist review; rationale documented (distribution infrastructure focus)

### Lens 6: Security Baseline — ✅ PASS
- FR-028 mandates PSGallery API key stored as GitHub Actions secret (name: PSGALLERY_API_KEY)
- FR-025 mandates self-signed certificate stored as GitHub Actions secret; T038 implements signing step
- T042 explicitly plans GitHub Actions secrets configuration (PSGALLERY_API_KEY, SIGNING_CERT_BASE64, SIGNING_CERT_PASSWORD)
- T005 documents PSGallery API key rotation procedure for maintainer reference (non-blocking for v1)
- T006 resolves self-signed certificate validity period with security vs maintenance trade-off analysis
- Data model includes PSGallery API Key entity with expiration tracking and Signing Certificate entity with validity period
- Plan Phase 1 Quality Planning identifies credential management as required risk dimension; GitHub Actions secrets best practices cover Phase 1

## Artifact Polishing Applied

**T002 (Conflict-Marker Format)**:
- Added explicit options: (A) Git-style, (B) Custom, (C) Structured comments
- Added implications: Squad coordinator parser dependency, T031 implementation impact
- Rationale: Ensures design-question task has clear options and implications for human decision-making

**T005 (API-Key Rotation Guidance)**:
- Added explicit non-blocking statement: "This is a documentation-only task that does not block any implementation work"
- Clarified parallel execution capability with Pillars 1-5 or post-v1 deferral option
- Rationale: Removes ambiguity about blocking behavior for design-question task

## T001-T006 Design-Question Task Validation

All 6 design-question tasks (Phase 0) properly framed:

| Task | Blocking Behavior | Options Listed | Implications Documented | Status |
|------|-------------------|----------------|------------------------|--------|
| T001 | ✅ Blocks T007, T010-T014 | ✅ Explicit FileList vs automatic | ✅ Maintenance vs safety trade-off | READY |
| T002 | ✅ Blocks T030-T033 | ✅ Git-style vs Custom vs Structured | ✅ Parser dependency, impl impact | READY |
| T003 | ✅ Blocks T040, T041 | ✅ Manual checklist vs GitHub Actions matrix | ✅ Setup speed vs robustness, CI/CD complexity | READY |
| T004 | ✅ Blocks T008 | ✅ Explicit dot-sourcing vs dynamic discovery | ✅ Transparency vs automation, debuggability | READY |
| T005 | ✅ Non-blocking (doc-only) | ✅ Frequency recommendations (rotation strategy) | ✅ Maintainer reference, not blocking v1 | READY |
| T006 | ✅ Blocks T038 | ✅ 1-year vs 5-year vs 10-year validity | ✅ Maintenance burden vs security risk window | READY |

**Validation Result**: All design-question tasks are properly scoped with clear options, implications, and blocking behavior. Ready for human decision-making during Phase 0 execution.

## Hardening-Gate Readiness Verdict

**Overall Verdict**: ✅ **READY** (with deferral)

**Rationale**: 
- Feature 019 focuses on distribution infrastructure (module packaging, install/update mechanics, CI/CD automation) rather than runtime business logic or security-sensitive data processing
- Plan Phase 2 Hardening and Specialist Review Planning explicitly documents deferral rationale: "This feature focuses on distribution infrastructure... rather than runtime business logic or security-sensitive data processing. Hardening focus will return in future features that introduce complex state machines, external integrations, or user-data handling."
- Phase 1 quality gates are sufficient for v1: manual cross-platform verification, integration test scenarios, PSGallery test-gallery dry-run, GitHub Actions workflow validation
- Security surface analysis covered by Phase 1 credential-management gate (GitHub Actions secrets best practices)
- Error handling and idempotency covered by Phase 1 acceptance scenarios (US2 idempotency, US3 conflict resolution)
- No complex retry logic, concurrency, or state machines requiring dedicated hardening

**Hardening Gate Artifact**: Not created (deferred per plan)  
**Next Valid Human Action**: Await explicit authorization for hardening-gate-and-implementation-auth boundary before starting implementation

## Blockers Surfaced

**None**. All quality lenses returned PASS verdict. No blockers detected.

## Confirmation of Scope Boundaries

**In Scope** (completed at this boundary):
- ✅ Applied 6 pre-implementation quality lenses to spec.md, plan.md, tasks.md
- ✅ Evaluated hardening-gate readiness and produced explicit READY recommendation
- ✅ Performed necessary artifact polishing (T002 options/implications, T005 non-blocking clarification)
- ✅ Validated T001-T006 design-question tasks have proper framing (blocking behavior, options, implications)
- ✅ Updated .squad/identity/now.md with before-implement completion and recommendation
- ✅ Appended dated decisions.md entry with runtime evidence and lens verdicts

**Out of Scope** (explicitly not started):
- ❌ Hardening-gate-and-implementation-auth boundary (not authorized)
- ❌ Implementation work (no code changes to scripts/ or extensions/)
- ❌ Validator additions (no changes to specrew-speckit extension)
- ❌ Resolution of T001-T006 design questions (human decision tasks; preserved as-is)

## Impact

Feature 019 before-implement quality gate passed with READY verdict. All 6 quality lenses confirmed artifacts are execution-ready. Minor polishing improved clarity of T002 and T005 design-question tasks. Feature is ready for hardening-gate-and-implementation-auth boundary when human authorization is provided.

## Next Action

**Do not advance to hardening-gate-and-implementation-auth or implementation**. Boundary commit will be created and pushed to origin/019-specrew-distribution-module. Await explicit human authorization before advancing to the next boundary.


# Decision: Feature 019 Hardening-Gate and Implementation Authorization

**Date**: 2026-05-16T17:42:05Z  
**Boundary**: hardening-gate-and-implementation-auth  
**Feature**: 019-specrew-distribution-module (Specrew Distribution Module via PowerShell Gallery)  
**Iteration**: 001  
**Authority**: Alon Fliess (human authorization)  
**Decision Type**: Hardening-gate sign-off and implementation authorization

## Authorization Scope

Human approver **Alon Fliess** explicitly authorized the hardening-gate-and-implementation-auth boundary for Feature 019 Iteration 001 on 2026-05-16T17:42:05Z.

**Authorized scope**: Feature 019 Iteration 001 — the 39 tasks in tasks.md across Phase 0 T001-T006 + Pillars 1-5 + final validation

**Authorized actions**:
1. Hardening-gate sign-off for Feature 019 Iteration 001 pre-implementation readiness
2. Implementation authorization to proceed with task execution via `/speckit.implement`

**Critical constraints**:
- T001-T006 (Phase 0 design-question tasks) remain **unresolved by design** and MUST surface during implementation via pause-for-decision handling
- Implementer agent must NOT auto-decide T001-T006; each requires explicit human decision with options and implications review
- Implementation must stop after this boundary completion; do NOT advance to `/speckit.implement` without separate explicit authorization

## Hardening-Gate Sign-Off Record

**Hardening Gate Artifact**: `specs/019-specrew-distribution-module/iterations/001/quality/hardening-gate.md`  
**Overall Verdict**: ✅ **READY**  
**Reviewed By**: Alon Fliess  
**Reviewed At**: 2026-05-16T17:42:05Z  

### Quality Lens Verdicts Summary

All 6 pre-implementation quality lenses carried forward from before-implement boundary with PASS verdicts:

1. **Constitution Alignment** — ✅ PASS (Principles I, II, IX, XIII, XIV, XVII, XXI satisfied)
2. **Traceability Completeness** — ✅ PASS (All 5 US, 32 FR, 39 tasks with explicit traceability)
3. **Cross-Platform Coverage** — ✅ PASS (FR-030 Join-Path mandate, FR-031 Windows/Linux/macOS testing, FR-032 PS 7+ requirement)
4. **Test Strategy Coverage** — ✅ PASS (All 5 pillars with explicit test tasks, Phase 6 Final Validation for US1-US5)
5. **Validator Integration Sketch** — ✅ PASS (Drift detection via Specrew-Speckit validators, Human Oversight Points defined)
6. **Security Baseline** — ✅ PASS (FR-028 API key secrets, FR-025 cert secrets, T042 GitHub Actions secrets config)

### Phase 2 Hardening Deferral

**Rationale**: Feature 019 focuses on distribution infrastructure (module packaging, install/update mechanics, CI/CD automation) rather than runtime business logic or security-sensitive data processing. Phase 1 quality gates are sufficient for v1: manual cross-platform verification, integration test scenarios, PSGallery test-gallery dry-run, GitHub Actions workflow validation. Hardening focus will return in future features that introduce complex state machines, external integrations, or user-data handling.

**Deferred-with-Evidence Items**: None. Phase 2 hardening is deferred entirely for this feature, not deferred-with-approval.

### Phase 0 Design-Question Tasks: Preserved for Implementation-Time Resolution

**⚠️ CRITICAL IMPLEMENTATION CONSTRAINT**: All 6 design-question tasks (T001-T006) remain unresolved and MUST surface during implementation:

| Task | Blocking Behavior | Human Decision Required | Resolution Status |
|------|-------------------|------------------------|-------------------|
| T001 | Blocks T007, T010-T014 | YES — FileList strategy decision | UNRESOLVED |
| T002 | Blocks T030-T033 | YES — Conflict marker format | UNRESOLVED |
| T003 | Blocks T040, T041 | YES — Cross-platform test automation depth | UNRESOLVED |
| T004 | Blocks T008 | YES — Module loader structure | UNRESOLVED |
| T005 | Non-blocking (doc-only) | OPTIONAL — Documentation-only | UNRESOLVED |
| T006 | Blocks T038 | YES — Self-signed cert validity period | UNRESOLVED |

## Implementation Authorization Record

**Authorized By**: Alon Fliess  
**Authorized At**: 2026-05-16T17:42:05Z  
**Branch**: 019-specrew-distribution-module  
**Starting Commit**: 3e4da27 (before boundary)  
**Boundary Commit**: 6c1b3dd (hardening-gate-and-implementation-auth)

**Stop After**: This boundary (hardening-gate-and-implementation-auth). Do NOT advance to `/speckit.implement` without separate explicit human authorization.

## Runtime Evidence

**Hardening-gate artifacts created**:
- `specs/019-specrew-distribution-module/iterations/001/quality/hardening-gate.md` — pre-implementation hardening gate with READY verdict, 6 quality lens verdicts carried forward, Phase 0 design-question constraints, risk-tier verification focus, stack-ready analysis, and explicit Phase 2 hardening deferral
- Iteration directory structure scaffolded: `specs/019-specrew-distribution-module/iterations/001/quality/`

**State updates**:
- `.squad/identity/now.md` — updated to reflect hardening-gate-and-implementation-auth boundary complete, next action requires explicit human authorization for `/speckit.implement`
- `.squad/decisions.md` — this authorization record appended

## Verification

- ✅ Iteration 001 artifact structure exists: `specs/019-specrew-distribution-module/iterations/001/quality/`
- ✅ Hardening gate artifact created at canonical path: `specs/019-specrew-distribution-module/iterations/001/quality/hardening-gate.md`
- ✅ All 6 quality lens verdicts carried forward from before-implement boundary with PASS status
- ✅ Phase 0 design-question tasks (T001-T006) explicitly preserved as unresolved with blocking behavior documented
- ✅ Implementation authorization recorded with human approver, timestamp, scope, and constraints
- ✅ State artifact updated with boundary completion and next-action requirement

## Impact

Feature 019 hardening-gate-and-implementation-auth boundary complete. Pre-implementation readiness confirmed with READY verdict. Implementation authorization granted for Feature 019 Iteration 001 (39 tasks across Phase 0 + Pillars 1-5 + final validation). T001-T006 design-question tasks remain unresolved by design and will surface during implementation execution. Boundary artifacts will be committed and pushed to origin/019-specrew-distribution-module. Implementer must not advance to task execution without separate explicit human authorization.

## Next Action

**Boundary artifacts commit and push required**. After boundary commit is created, update the "Boundary Commit" field in this record with the actual commit hash. Then await explicit human authorization for `/speckit.implement` to begin task execution.


# Decision: Feature 015 Review-Boundary Commit

**Date**: 2026-05-13  
**Agent**: Implementer  
**Authority**: Alon Fliess (user input)  
**Decision Type**: Boundary-claim-without-commit repair  

## Problem

Squad's Iteration 002 review workflow declared the review boundary complete and clean, updating plan.md, state.md, and review.md plus creating the public-readiness-release-review skill. However, no dedicated review-boundary commit was created to persist these artifacts to git. The Scribe's orchestration commits (2e95c74, 170be02) remained local-only and unsigned for the review verdict itself.

## Resolution

Created a single dedicated review-boundary commit with:

- **Commit hash**: daf2b03e5a860fb680fcb26ea9313cd38ffb90a7
- **Subject**: "Feature 015 public-readiness-pass iteration 002 review boundary"
- **Body sections**: Artifacts, Verification, Outstanding-findings, Next-action (in order)
- **Staged files**:
  - specs/015-public-readiness-pass/iterations/002/review.md (95 lines, accepted verdict)
  - specs/015-public-readiness-pass/iterations/002/plan.md (updated to reviewing status)
  - specs/015-public-readiness-pass/iterations/002/state.md (updated with review acceptance timestamp)
  - .squad/skills/public-readiness-release-review/SKILL.md (new skill pattern for release-truth review)
- **Excluded**: .claude/settings.local.json (as requested)
- **Co-authored-by**: Copilot <223556219+Copilot@users.noreply.github.com>

## Verification

- ✅ Working tree clean except for .claude/settings.local.json (intentionally excluded)
- ✅ Local HEAD: daf2b03 (review-boundary commit)
- ✅ Origin HEAD: daf2b03 (synced after push)
- ✅ Branch tracking: "Your branch is up to date with 'origin/015-public-readiness-pass'"
- ✅ Push included all three local-only commits: 2e95c74 → 170be02 → daf2b03

## Impact

The review boundary is now durably persisted to git with explicit verify-and-handoff intent. The Scribe's context-summarization work and the Reviewer's decision are now part of the same historical record, not split across local-only noise and unsigned verdict artifacts.

## Next Action

Do not open retrospective or claim iteration closeout from this accepted review boundary alone. Await separate human authorization before opening the retrospective for Feature 015, iteration 002 (per review.md Next Action section).


# Implementer Decision: Feature 015 release-boundary handling

**Date**: 2026-05-13  
**By**: Implementer  
**Type**: release-boundary

## Decision

For Feature 015 Iteration 002 release-truth work, retroactive tags are created
only when the target tag name is absent. If `v0.13.0` or `v0.14.0` already
exists locally or remotely, implementation reports the duplicate as
advisory-only and preserves the existing tag target without any rewrite.

## Why It Matters

- This keeps FR-010 aligned with the no-force / no-history-rewrite constraint.
- It preserves historical documentary value for retroactive tags.
- It gives future release work a concrete rule for duplicate-tag scenarios.


# Planning Artifact Repair: Feature 015 Consistency

**Date**: 2026-05-13  
**Facilitator**: Planner  
**Context**: Feature 015 public-readiness-pass branch naming and versioning source-of-truth repair  

## What Was Repaired

1. **Branch Reference Consistency**: All references to `016-public-readiness-pass` corrected to `015-public-readiness-pass` in:
   - `specs/015-public-readiness-pass/spec.md` (Feature Branch header)
   - `specs/015-public-readiness-pass/plan.md` (Branch field in header)
   - `.github/copilot-instructions.md` (Recent Changes section)

2. **Versioning Source-of-Truth Explicitness**: Made `.specrew/config.yml` the authoritative version reference:
   - Updated plan.md Summary to state: "`.specrew/config.yml` serves as the canonical source-of-truth for the active Specrew version; downstream README and documentation surfaces mirror this version."
   - Updated FR-008 in spec.md to explicitly name `.specrew/config.yml` and the stale bootstrap value: "`specrew_version: "0.1.0-dev"` to `0.14.0`"
   - Added `.specrew/config.yml` to Project Structure section in plan.md with FR-008 reference

3. **Recent Changes Entry**: Updated `.github/copilot-instructions.md` to replace generic "standard" language with explicit versioning governance: "PowerShell 7 (script extension), Markdown (all documentation artifacts), Git (tag operations) + `validate-governance.ps1` and `shared-governance.ps1` (existing); `.specrew/config.yml` specrew_version bump from 0.1.0-dev to 0.14.0 (version source-of-truth)"

## Why This Matters

- **Consistency**: Feature uses correct branch number (`015`, not `016`) across all planning artifacts
- **Explicitness**: Version governance is now traceable to a specific source file (`.specrew/config.yml`) rather than treated as generic documentation policy
- **Durability**: Future feature-closeout work will understand that version bumps target `.specrew/config.yml` as the authoritative registry, not README or CHANGELOG
- **Scope Clarity**: Confirmed authorization boundary (Iteration 001 planning scaffold + upstream push) is preserved and explicitly stated in all artifacts

## Unchanged Elements

- Scope boundaries remain: specification → Iteration 001 planning scaffold → upstream push; hardening-gate sign-off and implementation authorization remain outside current scope (FR-015)
- All FR-001 through FR-016 and TG-001 through TG-004 requirements preserved
- Quality planning and Phase 1 design gates remain as authored

## Next Actions

Feature 015 planning artifacts are now repair-complete and ready for implementation authorization (when approved by human reviewer).


# Planning Decision: Feature 015 Iteration 002 Scaffold

**Decision ID**: planner-feature015-iteration002-plan  
**Feature**: 015 — Public-Readiness Pass  
**Date**: 2026-05-13  
**Decision Maker**: Planner (autonomous planning boundary)  
**Authority**: Feature 015 `plan.md` §Iteration 002 Planning Authorization (explicit human authorization on 2026-05-13)

---

## Decision Summary

Iteration 002 planning artifacts have been scaffolded for Feature 015 using the canonical iteration plan schema (v1). The scope covers seven explicitly authorized feature requirements (FR-008 through FR-010, FR-012 through FR-014, FR-016 through FR-017) decomposed into 15 tasks (T010-T024) totaling 9.0 story points of estimated effort.

---

## Authorized Scope Items

The Iteration 002 scope is drawn directly from `plan.md` §Iteration 002 Planning Authorization:

1. **FR-008**: Version bump (`.specrew/config.yml` 0.1.0-dev → 0.14.0)
2. **FR-009**: Retroactive CHANGELOG.md with Features 001-014 entries
3. **FR-010**: Annotated git tags v0.13.0 (21d9e7f) and v0.14.0 (3ff32d4)
4. **FR-012, FR-013**: Feature closeout governance updates across coordinator templates
5. **FR-014**: Versioning schema documentation (docs/versioning.md)
6. **FR-016**: Public-readiness drift detection validator extension
7. **FR-017**: Shipped-feature spec status reconciliation (specs/007, 009, 011, 012)

All seven scope items are represented in the task decomposition with explicit FR traceability.

---

## Artifacts Created

Planning boundary artifacts:
- `specs/015-public-readiness-pass/iterations/002/plan.md` — canonical iteration plan with 15 tasks, concurrency rationale, effort model
- `specs/015-public-readiness-pass/iterations/002/state.md` — iteration state artifact with planning-phase posture
- `specs/015-public-readiness-pass/iterations/002/drift-log.md` — zero-drift planning assessment with seven execution-monitoring areas
- `specs/015-public-readiness-pass/iterations/002/quality/hardening-gate.md` — pre-implementation quality concerns with canonical + iteration-specific schema

Governance updates:
- `.squad/identity/now.md` — updated to reflect Iteration 002 planning boundary complete, execution authorization pending

---

## Key Planning Decisions

### 1. Effort Scoping: 11.5 Story Points
- Total estimated effort for Iteration 002 is 11.5 story_points
- Approximately 58% of the 20 story_point capacity ceiling
- Leaves 8.5 story_points of post-execution buffer for rework if needed
- Respects the planning principle of leaving headroom for execution discovery
- Aligns with the original plan.md estimate of "≈8 story points" with additional reserve for test scaffolding and human verification phases

### 2. Task Decomposition: 15 Tasks Across Three Workstreams
- **Validator Coverage (T010-T011, T016, T023)**: Test fixtures, Pester coverage, implementation, fixture validation
- **Release-Truth (T012-T015, T017-T019)**: Version bump, docs, changelog, tags, spec status
- **Governance Carry-Forward (T020-T021)**: Feature closeout templates and proof deferral
- **Polish (T022-T024)**: Markdown validation, full validator run, plan reconciliation

Decomposition respects the planning principle of clear ownership and separable workstreams.

### 3. Hardening-Gate Status: `blocked` Pending Implementation Authorization
- Pre-implementation concerns are mapped to execution-evidence targets
- All canonical concerns (security, error-handling, idempotency, test-integrity, resilience) are addressed
- Iteration-specific concerns (changelog-completeness, version-tag-integrity, coordinator-prompt-correctness, status-field-consistency, version-surface-alignment, validator-non-invasiveness) are explicitly monitored
- Sign-off is reserved for post-implementation; planning-time verdict is `blocked` (procedurally correct; no implementation evidence yet)

### 4. No Specification Drift
- Planning boundary assessment confirms zero drift between authorized scope (plan.md) and task decomposition
- All seven FR items appear in task requirements
- No orphan tasks; all 15 tasks trace to explicit FR or planning-boundary work

### 5. Iteration 001 Closure is Preserved
- Iteration 001 is marked `complete` in state.md and plan.md; no changes are made to closed iteration artifacts
- Iteration 002 stands alone as a new planning boundary
- Feature 015 remains open for future separately authorized work (e.g., public visibility changes)

---

## Traceability Verification

| FR | Task(s) | User Story | Effort |
| --- | --- | --- | --- |
| FR-008 | T012, T013 | US2 | 1.0 |
| FR-009 | T015 | US2 | 1.0 |
| FR-010 | T017 | US2 | 0.5 |
| FR-012, FR-013 | T020, T021 | US3 | 1.5 |
| FR-014 | T014 | US2 | 1.0 |
| FR-016 | T010, T011, T016, T018, T023 | US2, Polish | 4.5 |
| FR-017 | T019 | US2 | 0.5 |

**Total Effort**: 11.5 story_points
**Missing FR Items**: None  
**Orphan Tasks**: None

---

## Risk Mitigation

### Test-Driven Validator Development (T010-T011 → T016)
Validator test fixtures and Pester coverage are planned before implementation to reduce risk of validator behavior deviations. Rationale: Public-readiness detection is a new surface; early test scaffolding ensures fitness before code.

### Version-Truth Baseline Lock (T012-T013 First)
Version bump and README sync are scheduled before changelog/docs/tags to establish a shared baseline. Rationale: Downstream artifacts (CHANGELOG, tags, docs) reference the canonical version; locking early reduces coordination risk.

### Human Reviewer Gates (T018, T023)
Two explicit human verification points are scheduled: post-US2 implementation (T018: Pester/analyzer/tags) and pre-polish-close (T023: validator fixture run). Rationale: Complex version/tag/validator work benefits from independent verification.

### Governance Carry-Forward Proof Deferral (T021)
The Feature Closeout Version Management guidance (T020) is documented as proof-deferred to the next real feature closeout (T021 notes). Rationale: Synthetic proof is less valuable than real feature-close evidence; deferral is explicit in quickstart.md.

---

## Coordination Handoff

**For the Coordinator**:

Before granting implementation authorization, verify:
1. ✅ Iteration 002 scope is explicitly authorized in `.squad/identity/now.md`
2. ✅ All 15 tasks (T010-T024) are present in `plan.md` task table with FR traceability
3. ✅ Effort total (9.0 story_points) is within capacity
4. ✅ Hardening-gate.md is acceptable for pre-implementation quality review
5. ✅ No cross-cutting issues block execution of the seven authorized FR items

**Next Step**: Release explicit implementation authorization via human approval recorded in state.md. Iteration 002 execution can then begin with T010-T011 (validator fixtures) and T012-T013 (version baseline) in parallel.

---

## Notes

- This decision is autonomous planning-boundary work; no design choices or implementation preferences are encoded here.
- Iteration 002 remains in `planning` status until explicit implementation authorization is granted.
- No `review.md` or `retro.md` placeholders are created; those artifacts are reserved for post-execution phases.
- All traceability is recorded in the canonical iteration plan (plan.md); this document is a summary for coordination visibility.


# Spec Steward Decision: Feature 015 Iteration 002 Planning Authorization and Shipped-Feature Status Reconciliation

**Date**: 2026-05-13  
**Requestor**: Alon Fliess (Spec Steward)  
**Scope**: Feature 015 public-readiness-pass, Iteration 002 planning authorization and stale shipped-feature spec status alignment  
**Authority**: Spec Steward role — requirement traceability, drift detection, and alignment verification  

---

## What

Align the authoritative Feature 015 planning surfaces (spec.md, plan.md, tasks.md) to the newly authorized Iteration 002 planning scope delivered on 2026-05-13 by user directive, and establish the canonical shipped-feature spec status label for reconciliation.

### Scope Items Authorized (2026-05-13)

1. `.specrew/config.yml` version bump to `0.14.0` (FR-008)
2. Root `CHANGELOG.md` with Features 001-014 one-line entries (FR-009)
3. Retroactive tags `v0.13.0` at `21d9e7f` and `v0.14.0` at `3ff32d4` (FR-010)
4. Feature-closeout authorization template Step 10 for version bump / changelog / tag creation (FR-012, FR-013)
5. Coordinator prompt and template updates across `.github/agents/squad.agent.md`, `.squad/templates/squad.agent.md`, and `.specify/extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md` (FR-013)
6. Versioning schema documentation in `docs/versioning.md` and README (FR-014)
7. Stale shipped-feature spec status reconciliation for specs 007, 009, 011, 012 (FR-017 — new requirement)

### Canonical Shipped-Feature Status Label

**Decision**: Use status label `Complete` as the canonical shipped-feature spec status, aligning with spec 013 (validator hardening) as the standard label for shipped and fully delivered features.

**Rationale**:
- Spec 013 (validator hardening) uses `Status: Complete` to indicate a shipped and fully delivered feature
- Four previously shipped features (007, 009, 011, 012) currently carry the stale `Draft` status that does not reflect their delivered and implemented state
- Status `Complete` signals that the feature is shipped, implemented, and ready for production use
- This aligns with the inventory of 14 shipped features that Feature 015 is reconciling
- `Draft` is inappropriate for shipped features; `Approved` is insufficient (indicates approved to ship, not shipped); `Complete` is the correct terminal state for delivered work

### Planning Surface Updates Made

1. **spec.md**:
   - Updated scope boundaries to clarify that Iteration 002 is now authorized (2026-05-13)
   - Added new FR-017 requirement for stale shipped-feature spec status reconciliation
   - Updated traceability requirements (TG-002, TG-005) to include FR-017 and Iteration 002 authorization
   - Updated Governance Alignment section to reflect Iteration 002 authorization and completed Iteration 001

2. **plan.md**:
   - Added "Iteration 002 Planning Authorization" section documenting the seven authorized scope items
   - Updated "Explicit Phase 2+ Deferrals" section to reflect that Iteration 002 is now authorized
   - Updated "Phase 2 Hardening and Specialist Review Planning" scope from "iteration-001-authorized" to "iteration-001-completed" and "iteration-002-authorized"
   - Updated "Explicit Later Deferrals" section to reflect Iteration 002 authorization and executor permissions

3. **tasks.md**:
   - Added task T019 (under Phase 4 User Story 2): Update status field in four shipped-feature specifications (007, 009, 011, 012) from `Draft` to `Complete`
   - Renumbered subsequent tasks (former T019-T024 → T020-T025) to accommodate the new task
   - Updated "Phase 6: Polish & Cross-Cutting Validation" section header to include shipped-feature spec status reconciliation
   - Updated Dependencies, Execution Order, Parallel Opportunities, Traceability Map, and Implementation Strategy sections to reflect:
     - Iteration 001 completion (2026-05-13) for T001-T009
     - Iteration 002 authorization (2026-05-13) for T010-T025
     - New T019 task for shipped-feature spec status reconciliation
     - FR-017 traceability

4. **.squad/identity/now.md**:
   - Updated status from "ITERATION 001 COMPLETE" to "ITERATION 001 COMPLETE; ITERATION 002 AUTHORIZED"
   - Updated focus_area and active_issues to reflect Iteration 002 authorization
   - Listed the seven authorized scope items in the status record
   - Updated Next Valid Action from "Await separate human authorization" to "Scaffold Iteration 002 planning artifacts"

---

## Why

### Requirement Authority

Feature 015 spec.md FR-015 and FR-017 establish planning and execution boundaries. FR-015 requires that planning artifacts preserve the authorization boundary, and FR-017 (new) requires reconciliation of stale shipped-feature spec status labels.

The user directive delivered on 2026-05-13 explicitly authorizes these seven scope items for Iteration 002 planning and execution. Without updating the planning surfaces, a Planner or Coordinator reviewing the artifacts would encounter:
1. Apparent ambiguity about whether Iteration 002 is deferred or authorized
2. Missing traceability from the new stale-status-reconciliation work back to a specification requirement
3. Stale governance records (spec.md scope, plan.md phase planning, .squad/identity/now.md next-valid-action) that would mislead decision-making

### Canonical Status Label Alignment

The four shipped specs (007, 009, 011, 012) currently carry `Draft` status despite being:
- Completed and shipped features
- Delivered to production in Specrew's alpha release
- Referenced in Feature 015 FR-011 as part of "14 shipped features"
- Intended as part of the "Active 0.14.0" product state

Using `Draft` for shipped features creates a governance signal misalignment: outside readers would see "Draft" status and infer these features are incomplete or intentionally unfinished, when in fact they are delivered. This contradicts the public-readiness goal of Feature 015 to accurately represent project state.

Status `Complete` is the correct terminal state because:
1. It aligns with spec 013 (validator-hardening) which uses `Complete` for a delivered feature
2. It signals that the feature is shipped and ready for use
3. It allows future status evolution (e.g., if a shipped feature later enters a "Deprecated" state)
4. It matches the validator's grandfathering rules for shipped features (no schema enforcement regression)

---

## Traceability

- **Spec Authority**: specs/015-public-readiness-pass/spec.md FR-015, FR-017, TG-005
- **Plan Authority**: specs/015-public-readiness-pass/plan.md Iteration 002 Planning Authorization section
- **Task Authority**: specs/015-public-readiness-pass/tasks.md T010-T025 (updated task decomposition)
- **User Directive**: Alon Fliess authorized the seven scope items on 2026-05-13 (captured in this decision and .squad/identity/now.md)
- **Pattern Reference**: Spec Steward History 2026-05-12 "Iteration Closeout Truth Requires Synchronized Lifecycle Surfaces" — when iteration boundaries change, all live artifacts must be synchronized

---

## Recommendation for Planners and Coordinators

1. **Before scaffolding Iteration 002 planning artifacts**: Verify that specs/015-public-readiness-pass/spec.md, plan.md, and tasks.md align with this decision. The planning surfaces are now authoritative for Iteration 002 scope.

2. **For Task T019 (shipped-feature spec status reconciliation)**: The canonical status label is `Complete`. Update the four specs' **Status** field from `Draft` to `Complete` in a single commit, with a message indicating the alignment to Feature 015 public-readiness and the canonical shipped-feature spec status pattern established in spec 013.

3. **For Iteration 002 scaffolding**: Use `specs/015-public-readiness-pass/iterations/002/plan.md` as the iteration-local planning surface. Do not scaffold review.md or retro.md placeholders during planning phase.

4. **Traceability verification**: Spot-check that the new FR-017 requirement is correctly traced in all downstream artifacts (plan.md, tasks.md, state.md, hardening-gate.md) once Iteration 002 artifacts are created.

---

## Sign-Off

**Spec Steward**: Alon Fliess  
**Decision Date**: 2026-05-13  
**Status**: Active — Planner may begin scaffolding Iteration 002 planning artifacts per this decision.


# Decision: Shipped Feature Spec Status Reconciliation (Feature 015 FR-017)

**Date**: 2026-05-13  
**Agent**: Spec Steward  
**Authoritative Requirement**: Feature 015 spec.md, FR-017 + tasks.md T019

## Decision Summary

Reconciled the Status field across four shipped feature specifications from the stale `Draft` label to the canonical shipped-spec status `Complete`:

- `specs/007-user-facing-progress-handoff/spec.md`
- `specs/009-project-path-resolution/spec.md`
- `specs/011-specrew-start-conditional-pause/spec.md`
- `specs/012-descriptive-id-handoffs/spec.md`

## Authority

**FR-017 source text** (Feature 015 spec.md):
> Four previously shipped and delivered feature specifications (…) MUST have their status field updated from the stale `Draft` label to the canonical shipped-spec status label `Complete` to accurately reflect their delivered and implemented state. **Canon choice**: Status label `Complete` aligns with spec 013 (validator hardening) as the standard label for shipped and fully delivered features.

**Task T019** (Feature 015 tasks.md):
> T019 [US2] [Owner: Governance steward] [Effort: M] Update the **Status** field in four shipped-feature specifications from the stale `Draft` label to the canonical shipped-spec status `Complete`… (Trace: FR-017, TG-002, SC-003)

## Rationale

1. **Canonical label alignment**: All four specs are previously delivered features with completed implementations and closed iterations. The status field must reflect that delivered state.
2. **Authoritative source**: Feature 015 FR-017 explicitly names these four specs and mandates the `Complete` label per spec 013 pattern.
3. **No scope expansion**: Only the Status field was changed; no other text edits were required because the header statements in all four specs remain truthful (they describe what was delivered and why).

## Verification

All four files verified after edit:
- `specs/007-user-facing-progress-handoff/spec.md` line 5: ✅ `Status: Complete`
- `specs/009-project-path-resolution/spec.md` line 5: ✅ `Status: Complete`
- `specs/011-specrew-start-conditional-pause/spec.md` line 5: ✅ `Status: Complete`
- `specs/012-descriptive-id-handoffs/spec.md` line 5: ✅ `Status: Complete`

## Scope Boundaries

- **In scope**: Status field reconciliation only; four specific specs as listed in FR-017.
- **Out of scope**: Any content edits beyond minimum adjacent repairs; broader feature-status audit across all specs.

---

This decision closes FR-017 (T019) for Feature 015 Iteration 002.


# Retrospective Decision: Feature 014 Iteration 001

**Date**: 2026-05-12  
**Facilitator**: Retro Facilitator  
**Scope**: Feature 014 handoff-format-scoping, Iteration 001 retrospective boundary

---

## Context

Feature 014 iteration 001 delivered the bounded stop-vs-progress selector and additive soft-warning rollout (FR-001 through FR-007) on 2026-05-12. Review verdict was **accepted** at commit 8e99013 with zero rework required. Retrospective analysis reveals zero estimation variance (8.0 sp actual = 8.0 sp planned) and three critical process patterns to protect in future iterations.

---

## Key Findings

### 1. Zero-Variance Delivery Pattern

- **What Happened**: All 15 tasks delivered at estimated effort (0% variance total, -12.5% unused rework buffer). No discovery surprises, no late-found gaps, zero review rework cycles.
- **Root Cause**: Tight scope locking before execution. Feature 014 plan.md clearly separated Iteration 001 (selector + additive warnings) from deferred Iteration 002 (proof + calibration) before work started. No new unknowns emerged during implementation.
- **Signal**: This is not luck. Feature 007 iteration 001 also achieved 0% variance with similar upstream planning rigor. The pattern is durable.
- **Decision**: Future well-scoped feature refinements should model their capacity planning on this pattern. Reduce the rework buffer from 1.0 sp to 0.5 sp for tight-scoped features where Iteration 001 is clearly bounded and Iteration 002 is deferred. Keep exploration/spike capacity at 0.5 sp baseline.

### 2. Boundary-Claim-Without-Commit Trap (Critical)

- **What Happened**: Review.md was committed at 8e99013 claiming the review boundary is durably complete. However, retro.md did not exist until after separate human authorization in this session. The iteration state appeared complete in git history but was logically incomplete until the retrospective phase could actually start.
- **Risk**: Future automation or planners treating the review claim as complete truth when the next phase's prerequisites are not yet met.
- **Candidate Rule** (for implementation in FR-008 or a future governance feature): Before accepting a `-boundary` commit, verify that either (a) all required artifacts for the next phase exist and are committed, or (b) the next phase is explicitly deferred in state.md with a human approval note. Reject the boundary claim if both conditions fail.
- **Decision**: Add this pattern to `.specrew/quality/known-traps.md` under a new row `boundary-claim-without-commit` with the evidence from Feature 014 iteration 001. Include the detection rule candidate so future governance work can implement it as a validator gate.

### 3. Startup-Coupling Task Invisibility Trap

- **What Happened**: Tasks T010 and T011 modified startup-loaded config files (`.github/agents/squad.agent.md`, `.squad/templates/squad.agent.md`). The mandatory session-restart requirement was documented in state.md, not in the task definition itself. This requirement was only surfaced during retrospective, not at task time.
- **Risk**: Implementation team completes the work, commits it, and later planners run in old sessions without knowing a restart is required. Silent activation gaps.
- **Candidate Rule**: Scan task.md for any task that edits files under `.github/agents/`, `.squad/templates/`, or `.specrew/config/`. Flag tasks without an explicit "Session restart required" note in the acceptance criteria.
- **Decision**: Add this pattern to `.specrew/quality/known-traps.md` under a new row `startup-coupling-task-invisibility`. Include task-definition template guidance: any startup-config task must state "[Task name] | Acceptance: [description]. **Session restart required for next session.**"

### 4. Acceptance-Evidence Scattering

- **What Happened**: Task T008 (manual validator exercise) had its acceptance criteria defined in tasks.md, but the expected test outputs and scenarios were scattered across spec.md (User Story 2 scenarios), contract.md (approved scenarios), and plan.md (task description). The team had to infer evidence from multiple sources rather than reading one unified definition.
- **Risk**: Underspecified test acceptance criteria make it harder to verify task completion and increase review friction.
- **Candidate Rule**: For any task with acceptance criteria "verify X" or "manually exercise Y," the task definition must include explicit expected outcomes in a single artifact, not scattered across multiple sources.
- **Decision**: Add this pattern to `.specrew/quality/known-traps.md` under a new row `acceptance-evidence-scattering`. Include guidance: "Task definitions must include acceptance evidence signatures. Instead of 'Manually exercise the new warning paths,' write 'Manually exercise: (1) correct-final-stop → pass; (2) placeholder-only → soft-warning.empty-user-action-section; [etc]. Update contract.md with observed results.' Unify acceptance in the task boundary."

---

## Improvement Actions (Binding for Next Planning)

1. **Action**: Before any future `-boundary` commit (review, retro, closeout), run a "boundary-claim durability checklist" validation. Check: (a) Preceding phase artifacts complete and committed, (b) Next phase artifacts exist or are explicitly deferred, (c) Validator passes with both phases' minimum artifacts.
   - **Owner**: Spec Steward + Iteration Facilitator
   - **Target**: Next planning ceremony or future governance feature (FR-008+)
   - **Expected Effect**: Prevent boundary-claim-without-commit patterns from recurring.

2. **Action**: Embed acceptance evidence signatures into task definitions in plan.md and tasks.md. For any "verify X" or "test Y" task, include explicit expected outcomes (e.g., "scenario A → pass; scenario B → soft-warning X") in the task entry itself.
   - **Owner**: Iteration Facilitator + Governance prompt stewards
   - **Target**: Next planning ceremony
   - **Expected Effect**: Unify acceptance criteria in task boundary, reduce review friction.

3. **Action**: For any task modifying startup-loaded config files, add a mandatory note in acceptance criteria: "Session restart required for next session." Make this visible at task time, not discovered later.
   - **Owner**: Governance prompt stewards
   - **Target**: Next iteration planning (feature 015+)
   - **Expected Effect**: Prevent silent session-coupling gaps.

---

## Known-Traps Additions (Candidate for Feature 014 Iteration 002 FR-008)

The following candidate rows should be added to `.specrew/quality/known-traps.md` during Iteration 002:

1. **`boundary-claim-without-commit`**: Lifecycle boundary claims (review, retro, closeout) recorded in committed artifacts must not be made unless all prerequisites for that boundary are durably met or explicitly deferred. A review-boundary claim without a retro-ready state creates a durability gap.

2. **`startup-coupling-task-invisibility`**: Tasks modifying startup-loaded config files must explicitly document the session-restart requirement in task acceptance criteria. This prevents silent activation gaps where changes are committed but not loaded until a manual session restart.

3. **`acceptance-evidence-scattering`**: Task acceptance criteria for verification or testing tasks must include expected evidence signatures in the task definition itself, not scattered across spec, contract, and plan artifacts.

---

## Sign-Off

- **Retro Boundary**: Open, pending final human authorization before iteration closeout.
- **Team-Relevant Decisions**: Recorded above; shared with .squad/decisions/inbox/ for integration into next planning ceremony.
- **Deferred to Iteration 002**: Addition of the three candidate known-traps rows to `.specrew/quality/known-traps.md` as part of FR-008 work.

---

**Status**: Awaiting Alon Fliess's separate authorization before closing the retrospective boundary and opening the closeout phase.


### 2026-05-14T00:00:00Z: Delegated lifecycle runtime evidence
**By:** Squad (Coordinator)  
**Role / Work Item:** Planner — Feature 016 Iteration 002 task generation  
**Requested agent:** claude  
**Actual agent:** copilot  
**Model ID:** unknown (same-window Copilot session)  
**Status:** fell back  
**Fallback reason:** preferred agent `claude` is not enabled in the active Specrew routing plan


# Retro Facilitator Inbox: Feature 015 Iteration 001 Retro Boundary

**Date**: 2026-05-13  
**Feature**: `015-public-readiness-pass`  
**Iteration**: `001`

## Candidate Rule 1

**Name**: `boundary-claim-without-commit`  
**Category**: `boundary-discipline`

### Proposed Rule: Boundary Claim

Do not narrate a lifecycle boundary as complete until the matching durable commit already contains the
boundary artifact plus truthful `plan.md` and `state.md` lifecycle updates. Until Feature 016
Substantive Interaction Model Pillar 1 graduates hard rule
`validation-fail.bundled-boundary-advance`, treat this as a manual stop condition.

### Evidence: Boundary Claim

- Feature 014 iteration 001 review boundary commit `8e99013`
- Feature 014 iteration 001 retro boundary commit `a5fcb90`
- Feature 015 iteration 001 review boundary commit `6ca218f`

## Candidate Rule 2

**Name**: `branch-name-mismatch-with-feature-directory`  
**Category**: `planning-discipline`

### Proposed Rule: Branch Name

Before scaffolding planning artifacts or recording a planning boundary, verify that the active branch
name matches the feature directory. If they differ, stop, repair the branch, and fix any generated
references before the next durable commit.

### Evidence: Branch Name

The mistaken orphan branch `016-public-readiness-pass` required cleanup plus repaired references in:

- `specs/015-public-readiness-pass/research.md`
- `specs/015-public-readiness-pass/data-model.md`
- `specs/015-public-readiness-pass/quickstart.md`
- `specs/015-public-readiness-pass/checklists/requirements.md`
- `specs/015-public-readiness-pass/iterations/001/plan.md`

### Current Gap

No validator rule currently checks branch name against feature directory before the planning boundary
is committed.


### 2026-05-12T23:17:38+03:00: User directive
**By:** Alon Fliess (via Copilot)
**What:** Before retrospective, commit the Feature 014 Iteration 001 review-boundary artifacts (`review.md`, `state.md`, and `plan.md`) as a single dedicated commit with message `Feature 014 handoff-format-scoping iteration 001 review boundary`, push it to `origin/014-handoff-format-scoping`, then report the new commit hash and clean tree state without opening retrospective.
**Why:** User request — captured for team memory


### 2026-05-12T23:21:39+03:00: User directive
**By:** Alon Fliess (via Copilot)
**What:** Sign off on the accepted review verdict for Feature 014, handoff-format scoping, Iteration 001, as recorded in `specs/014-handoff-format-scoping/iterations/001/review.md` and commit `8e99013`; authorize the retrospective boundary against implementation commit `f02688f`; produce `retro.md` with actual-vs-planned calibration across T001-T015, surfaced lessons including the review-boundary-without-commit pattern and any planning-output drift, and corpus-row candidates including a future `boundary-claim-without-commit` detection rule; stop before the iteration-closeout boundary for separate authorization.
**Why:** User request — captured for team memory


### 2026-05-12T23:48:37+03:00: User directive
**By:** Alon Fliess (via Copilot)
**What:** Sign off on the accepted retrospective for Feature 014 handoff-format-scoping Iteration 001, treat commit `a5fcb90` as the retro-boundary model for future boundary-commit messages, authorize the iteration-closeout boundary, and as part of the same closeout commit add a canonical defer entry for the pre-existing iteration-011 gap in `.squad/decisions.md` so repo-wide governance returns green without folding unrelated cleanup into Feature 014 scope.
**Why:** User request — captured for team memory


### 2026-05-13T00:23:50+03:00: User directive
**By:** Alon Fliess (via Copilot)
**What:** Sign off on the Feature 014 Iteration 001 closeout boundary, authorize the Feature 014 feature-closeout boundary including PR creation, self-review, merge to main, and use the high-rigor boundary-commit pattern established by `a5fcb90` for the feature-closeout commit.
**Why:** User request — captured for team memory


### 2026-05-13T23:40:30+03:00: Delegated lifecycle runtime evidence
**By:** Squad (Coordinator)
**Role / Work Item:** Implementer — Feature 015 Public-Readiness Pass feature-closeout boundary
**Requested Agent:** copilot
**Actual Agent:** copilot
**Model ID:** claude-haiku-4.5
**Status:** honored
**Fallback Reason:** none

---

### 2026-05-13T23:31:40+03:00: Delegated lifecycle runtime evidence
**By:** Squad (Coordinator)
**Role / Work Item:** Implementer — Feature 015 Public-Readiness Pass Iteration 002 closeout truth-state repair
**Requested Agent:** copilot
**Actual Agent:** copilot
**Model ID:** claude-haiku-4.5
**Status:** honored
**Fallback Reason:** none

---

### 2026-05-13T23:24:40+03:00: Delegated lifecycle runtime evidence
**By:** Squad (Coordinator)
**Role / Work Item:** Implementer — Feature 015 Public-Readiness Pass Iteration 002 iteration-closeout boundary
**Requested Agent:** copilot
**Actual Agent:** copilot
**Model ID:** claude-haiku-4.5
**Status:** honored
**Fallback Reason:** none

---

### 2026-05-13T22:52:17+03:00: Delegated lifecycle runtime evidence
**By:** Squad (Coordinator)
**Role / Work Item:** Retro Facilitator — Feature 015 Public-Readiness Pass Iteration 002 retrospective boundary
**Requested Agent:** copilot
**Actual Agent:** copilot
**Model ID:** claude-haiku-4.5
**Status:** honored
**Fallback Reason:** none

---

### 2026-05-13T20:39:39+03:00: Delegated lifecycle runtime evidence
**By:** Squad (Coordinator)
**Role / Work Item:** Reviewer — Feature 015 Public-Readiness Pass Iteration 002 independent review boundary
**Requested Agent:** claude
**Actual Agent:** copilot
**Model ID:** claude-opus-4.7
**Status:** fell back to enabled agent family
**Fallback Reason:** preferred agent `claude` is not enabled

---

---

### 2026-05-12T23:59:59+03:00: Deferred gap - Feature 001 iteration 011
**By:** Alon Fliess (via Copilot)
**Type:** deferred-gap
**Iteration Reference**: specs/001-specrew-product/iterations/011
**What:** Defer cleanup and historical-state verification of pre-existing gap in Feature 001, iteration 011 to a separate scoped feature. This gap is unrelated to Feature 014 handoff-format-scoping and is preserved without folding into Feature 014 closeout scope to maintain clean feature boundaries.
**Approving Human**: Alon Fliess
**Deferred On**: 2026-05-12
**Why:** Feature 014 Iteration 001 successfully delivered its bounded stop-vs-progress selector and additive soft-warning rollout (FR-001 through FR-007) without addressing unrelated historical cleanup. Recording this gap as an explicit tracked defer preserves the "no-gap" governance policy while protecting Feature 014's integrity.
**Follow-up Commitment:** Open a separate scoped feature to address Feature 001 iteration 011 state cleanup and verification.

---

## 2026-05-12T20:59:59Z — Canonical defer entry (Feature 014 iteration 001 closeout correction)

- **Decision ID**: defer-fr054-immutability-guardrail
- **Type**: defer
- **Affected Requirement**: FR-054
- **Affected Iteration**: specs\001-specrew-product\iterations\011
- **Approving Human**: Alon Fliess
- **Recorded At**: 2026-05-08T13:10:19Z
- **Next Action**: Address automated immutable-snapshot enforcement in a separate scoped feature after Feature 001 iteration 011 cleanup verification is complete
- **Rationale**: Historical cleanup during Feature 014 iteration 001 closeout. Iteration 011 focused on fixing legacy explicit-target validation regression without retroactively modifying closed iteration artifacts. FR-054 immutability enforcement (automated rejection of rewrites to closed iteration artifacts) remains unimplemented but this deferral preserves iteration boundaries and forward-only semantics.

---

### 2026-05-12T22:49:40+03:00: User directive
**By:** Alon Fliess (via Copilot)
**What:** Authorize the independent review boundary for Feature 014, handoff-format scoping, Iteration 001, the bounded stop-vs-progress selector and additive soft-warning rollout, against implementation commit `f02688f`; the reviewer must evaluate the canonical and iteration-specific concerns, run the five preserved handoff-governance regressions plus the two new soft-warning rules on compliant and violating fixtures, confirm the Feature 012 `human-handoff-id-context` scope-of-applicability update does not regress its existing detection, confirm repo-wide `validate-governance.ps1` stays green, emit `review.md` with an explicit verdict, dogfood the new format-scoping rules in the review output itself, repair any blocking gap in the current iteration instead of deferring it, and stop before retrospective for separate human sign-off on the review verdict.
**Why:** User request — captured for team memory


---

# Reviewer Decision: Feature 014 Iteration 001 Review

**Date**: 2026-05-12  
**By**: Reviewer  
**Type**: review-boundary

## Decision

Accept the review boundary for feature `014`, handoff format scoping, iteration `001`.

## Why It Matters

- The canonical concerns and all five iteration-specific concerns pass across implemented, enforced, observable, and documented lenses.
- The preserved five handoff-governance regressions, the two Feature `012`, descriptive references in handoffs, replay-path regressions, the bounded direct-validator stop-vs-progress matrix, and repo-wide `validate-governance.ps1 -ProjectPath .` all passed.
- The iteration artifacts are now truthful for the review boundary: `review.md` exists, `plan.md` is `reviewing`, and `state.md` no longer claims review is deferred.

## Evidence

- `specs\014-handoff-format-scoping\iterations\001\review.md`
- `specs\014-handoff-format-scoping\iterations\001\plan.md`
- `specs\014-handoff-format-scoping\iterations\001\state.md`
- `tests\integration\handoff-governance-jargon-response-test.ps1`
- `tests\integration\handoff-governance-plain-language-response-test.ps1`
- `tests\integration\handoff-governance-review-file-reference-test.ps1`
- `tests\integration\handoff-governance-descriptive-narration-test.ps1`
- `tests\integration\handoff-governance-descriptive-stop-message-test.ps1`
- `tests\integration\descriptive-reference-authored-prose.ps1`
- `tests\integration\descriptive-reference-excluded-surfaces.ps1`

## Next Action

Await Alon Fliess's separate authorization before opening retrospective or closeout work for feature `014`, iteration `001`.


---

# Spec Steward Inbox: Feature 013 Iteration 002 closeout boundary

**Date**: 2026-05-12  
**Feature**: `013-validator-hardening`  
**Iteration**: `002`

## Decision

Treat iteration `002` as truthfully closed once all six canonical iteration artifacts exist, accepted review `d7b2e42` is reflected in the hardening-gate verification fields, retrospective commit `947edff` is preserved, and the full closeout validation lane is green on the closeout tree.

## Alignment Guardrail

- Record iteration closure only at the iteration layer.
- Keep feature `013` open until a separate feature-closeout authorization is granted and recorded.
- Do not rewrite review or retrospective artifacts to narrate later lifecycle boundaries; update only the live closeout-facing artifacts.

## Authoritative References

- `specs/013-validator-hardening/spec.md`
- `specs/013-validator-hardening/iterations/002/state.md`
- `specs/013-validator-hardening/iterations/002/quality/hardening-gate.md`
- `specs/013-validator-hardening/iterations/002/retro.md`


### 2026-05-11T22:18:50+03:00: User directive
**By:** Alon Fliess (via Copilot)
**What:** Keep using the plain-language three-section handoff format, apply descriptive scope alongside numeric IDs in Squad-authored narration and stop messages during feature 012 iteration 001, require the reviewer to verify the two blocking concerns explicitly, run the full six-script validation lane before closeout, do not claim iteration closeout unless validation is green and git status is clean except for `.claude/settings.local.json`, and treat edits to `.github/agents/squad.agent.md` or `.squad/templates/squad.agent.md` as a session-restart trigger that requires an iteration-boundary commit and restart before closeout sign-off.
**Why:** User request — captured for team memory

# Decision: Feature 012 Iteration 001 Pre-Implementation Hardening Gate Sign-Off

**Decided**: 2026-05-11  
**Decision Owner**: Alon Fliess  
**Decision Type**: Feature Authorization  
**Status**: Effective Immediately  

## Decision Summary

**The pre-implementation hardening gate for Feature 012 (Descriptive-ID-Handoffs) Iteration 001 is SIGNED OFF and implementation is AUTHORIZED to proceed.**

Alon Fliess explicitly authorizes:
- Iteration 001 implementation (T001–T011, 8 story points)
- Iteration 001 review phase
- Iteration 001 retrospective and closeout

## Authorization Details

**Authorizer**: Alon Fliess  
**Review Class**: strongest-available  
**Review Date**: 2026-05-11  

**Authorization Statement (verbatim)**:  
"I sign off on the iteration 001 pre-implementation hardening gate for feature 012 descriptive-id-handoffs and I authorize iteration 001 implementation, review, retrospective, and closeout."

## Scope Locked

This decision locks the scope of Iteration 001 to the planned 11 tasks (T001–T011):

| Phase | Task Count | Tasks |
| --- | --- | --- |
| **Phase 1: Setup** | 2 | T001, T002 |
| **Phase 2: Foundational** | 2 | T003, T004 |
| **Phase 3: US1 (Narration)** | 4 | T005–T008 |
| **Phase 4: US2 (Stop Messages)** | 3 | T009–T011 |

Iteration 002 explicitly defers:
- Replay-path integration tests (T012–T014)
- Corpus seeding in `known-traps.md` (T015)
- Quality artifacts and hardening-gate updates (T016)
- Any blocking enforcement changes
- Any expansion to tool-rendered output

## Hardening Gate Assessment

The hardening gate assessment (see `specs/012-descriptive-id-handoffs/iterations/001/quality/hardening-gate.md`) confirms:

✓ All planning artifacts are complete  
✓ All pre-implementation concerns have been addressed or explicitly deferred  
✓ Feature 007 compatibility is preserved through regression testing  
✓ All user-facing guidance surfaces (prompts, checklists, contracts, startup guidance) are aligned  
✓ Worked examples are in scope for Iteration 001  
✓ The rule remains non-blocking per FR-008 and FR-009  

## Next Actions

1. **T001** (Pre-implementation baseline): Run existing handoff-governance regression tests and record baseline
2. **T002** (Boundary confirmation): Review feature boundary and two-iteration split  
3. **T003–T004** (Foundational): Extend validator rule and update coordinator contract
4. **T005–T011** (Parallel US1 and US2 work): Update guidance surfaces and validate

## Records Updated

- `specs/012-descriptive-id-handoffs/iterations/001/quality/hardening-gate.md`: Signed off by Alon Fliess
- `specs/012-descriptive-id-handoffs/iterations/001/plan.md`: Status changed to `implementation-authorized`
- `specs/012-descriptive-id-handoffs/iterations/001/state.md`: Current phase changed to `implementation-authorized`

---

**This decision is effective immediately. Implementation may begin with T001.**

## 2026-05-11-reviewer-feature012-iter001-review
### 2026-05-11T00:00:00Z: Reviewer decision - Iteration 001 review acceptance
**By:** Reviewer (Copilot)
**Type:** review-approval
**What:** Accept Iteration 001 review boundary for feature `012-descriptive-id-handoffs`.
**Why:** Both blocking concerns pass with runtime evidence (validator-detection-correctness via five integration tests, coordinator-prompt-rollout-fidelity via feature 007 regression suite preservation), all non-blocking concerns pass (guidance synchronization, bulk-list handling, tool-call scope exclusion), and iteration artifacts are truthful. T008 narration validation completed with new integration test script `tests\integration\handoff-governance-descriptive-narration-test.ps1`. All five handoff-governance tests passing. Readable-reference rule rolled out across validator, prompts, checklist, contract, and Squad startup surfaces with feature 007 compatibility preserved.
**Evidence:** `specs\012-descriptive-id-handoffs\iterations\001\review.md`, `specs\012-descriptive-id-handoffs\iterations\001\plan.md`, `specs\012-descriptive-id-handoffs\iterations\001\state.md`, `tests\integration\handoff-governance-descriptive-narration-test.ps1`
**Next Action:** Proceed to retrospective and closeout.

### 2026-05-12T00:17:00+03:00: User directive
**By:** Alon Fliess (via Copilot)
**What:** For feature 012 iteration 002, scaffold and commit planning artifacts only; use the canonical state.md schema, draft the nine-column hardening gate with the specified blocking concerns, do not start implementation, do not scaffold iteration 003, and stop for fresh hardening-gate sign-off plus implementation authorization after planning.
**Why:** User request — captured for team memory

# Planner Decision Inbox: Feature 012 Iteration 002 Planning

**Date**: 2026-05-12  
**By**: Planner  
**Type**: planning-governance

## Decision

Feature `012-descriptive-id-handoffs` iteration `002` planning keeps the canonical Iteration 001 `state.md` metadata schema and applies the richer pre-sign-off hardening-gate convention with pending review metadata.

## Why It Matters

- The older scaffolded `state.md` shape omits canonical metadata fields and previously caused validator failures.
- The richer hardening-gate convention lets planning show `Overall Verdict: ready` while truthfully keeping review and runtime-evidence fields pending.
- Iteration 002 therefore treats the iteration-local hardening gate as a planning artifact now, leaving task `T016` focused on post-implementation feature-level quality follow-through evidence instead of recreating the pre-implementation gate.

## Expected Follow-Through

- Reuse the canonical state metadata headings exactly in future feature 012 iteration artifacts.
- Keep the five canonical hardening concerns first, then add feature-specific concerns in explicit, reviewed order.
- Preserve the distinction between planning-time gate creation and post-implementation evidence recording when task tables mention quality artifacts.

### 2026-05-12T01:24:17+03:00: User directive
**By:** Alon Fliess (via Copilot)
**What:** For feature 012 iteration 002, record hardening-gate sign-off with the requested metadata repair (`error-handling-expectations` Blocking=false), then proceed with implementation, review, retrospective, and closeout for tasks T012-T020 while preserving replay-path evidence, corpus seeding, regression checks, the six-script closeout lane, readable-reference narration, and startup-guidance restart handling.
**Why:** User request — captured for team memory

# Implementer Decision Inbox: Feature 012 iteration 002 execution

## Decision

For feature 012, descriptive references in handoffs, iteration 002, the replay proof uses fixture-backed invocations of `extensions\specrew-speckit\validators\handoff-governance-validator.ps1` as the real governance review path, and the new tests assert on the validator's user-visible `status`, `findings`, and `summary` output instead of checking runtime state alone.

## Why

The signed iteration hardening gate called out replay-path integrity as a blocking concern, and the active known-traps corpus already requires user-facing handoff coverage to exercise the actual replay surface. Encoding the replay path in fixture manifests also makes the proof auditable in feature-level quality artifacts and keeps the lane aligned with the seeded corpus row.

# Reviewer Decision: Feature 012 Iteration 002 Review

**Date**: 2026-05-12  
**Reviewer**: Reviewer agent  
**Scope**: Feature `012`, descriptive references in handoffs, iteration `002`, the replay-path proof slice

## Decision

Accept the iteration `002` review boundary.

## Why

1. The replay tests use the real handoff-governance validator path and assert on user-visible output (`status`, `findings`, and `summary`) instead of internal state alone.
2. The `human-handoff-id-context` known-trap row is seeded in `.specrew\quality\known-traps.md` and aligned with the replay lane plus preserved regressions.
3. The preserved feature `007`, user-facing progress handoff, regression trio and the iteration `001`, readable-reference, regression pair all passed on the current tree, so the descriptive-reference proof slice remains additive and non-blocking.

## Evidence

- `specs\012-descriptive-id-handoffs\iterations\002\review.md`
- `specs\012-descriptive-id-handoffs\iterations\002\plan.md`
- `specs\012-descriptive-id-handoffs\iterations\002\state.md`
- `specs\012-descriptive-id-handoffs\iterations\002\quality\hardening-gate.md`
- `specs\012-descriptive-id-handoffs\quality\hardening-gate.md`

## Next Action

Proceed to the iteration `002` retrospective, then run closeout without reopening implementation unless contradictory runtime evidence appears.

# Retro Decision: Feature 012 Iteration 002

**Date**: 2026-05-12  
**By**: Retro Facilitator  
**Type**: process-governance

## Decision

Feature `012`, descriptive references in handoffs, iteration `002`, the replay-path and corpus follow-through slice, confirms four process baselines for future handoff-governance work.

## Why It Matters

1. User-facing governance rules need replay-path proof against the real validator output, not runtime-state-only checks.
2. A known-traps corpus row is durable only when the validation lane and follow-through artifacts are updated in the same slice.
3. Descriptive-reference proof must always preserve the feature `007` regression trio and the feature `012` iteration `001` readable-reference pair in the same lane.
4. Authored lifecycle prose is a legitimate dogfood surface for readable references and should keep pairing numeric IDs with descriptive scope.

## Expected Follow-Through

- Add a `Phase Baseline` table to iteration plans before review closes so retro scaffolding remains reusable.
- Keep replay-path assertions, corpus entries, validation-lane commands, and follow-through artifacts synchronized for future handoff-governance changes.
- Preserve the combined regression lane explicitly whenever descriptive-reference or related handoff-governance behavior changes.

# Reviewer Prep Rubric: Feature 013 Iteration 002

**Date**: 2026-05-12  
**Reviewer**: Reviewer  
**Feature**: `013-validator-hardening`  
**Iteration**: `002`  
**Scope**: Independent review preparation for the five blocking concerns in `specs/013-validator-hardening/iterations/002/quality/hardening-gate.md`

---

## Purpose

This note prepares the independent review boundary while implementation runs. It does **not** review code and does **not** issue a verdict. It translates the five blocking hardening-gate concerns into requirement-level evidence checks so the eventual review can fail fast on missing proof instead of retelling the implementation story.

---

## Acceptance Lenses the Eventual Review Must Apply

Each blocking concern must pass all applicable lenses below:

1. **Implemented** — the intended code or artifact change exists in the named path.
2. **Enforced** — the real validator or restart flow rejects/permits the right cases mechanically.
3. **Observable** — user-visible output proves the rule, including structured FAIL content where required.
4. **Documented / Traceable** — plan, quickstart, corpus, and iteration artifacts cite the requirement and test evidence truthfully.
5. **Regression-safe** — iteration 001 behavior and the additive CLI surface remain intact.

If any lens fails for a blocking concern, the review verdict is `needs-work`.

---

## Blocking Concern 1: Over-Claim Detection Correctness

**Hardening-Gate Concern**: `over-claim-detection-correctness`  
**Requirement Lens**: FR-004, FR-005, FR-008, FR-010; TG-004, TG-008; SC-004, SC-005  
**Primary Tasks**: T018, T019, T020, T029

### What Must Be True

- Closed-status iterations without complete closeout evidence fail mechanically.
- Required evidence includes accepted `review.md`, `retro.md`, and post-implementation verification in `quality/hardening-gate.md` for required concerns.
- Dirty-tree enforcement is limited to the iteration directory's canonical artifacts.
- `.squad/decisions.md` and `.squad/identity/now.md` may inform evidence but must not fail the dirty-tree check by themselves.
- FAIL output stays structured and names the missing evidence or changed files without surfacing raw PowerShell exceptions.

### Required Evidence

1. **Fixture Coverage**
   - `tests\integration\fixtures\013-validator-hardening\overclaim\`
   - Must include: missing retro, missing review, non-accepted review, pending post-implementation hardening evidence, clean pass case, dirty iteration-directory case, repo-level-only change case.

2. **Replay Assertions**
   - `tests\integration\validator-hardening-iteration2.ps1`
   - Must prove: closed-status detection, each required evidence failure mode, iteration-directory-only `git status --porcelain` filtering, zero raw exceptions.

3. **Implementation Inspection**
   - `extensions\specrew-speckit\scripts\shared-governance.ps1`
   - `extensions\specrew-speckit\scripts\validate-governance.ps1`
   - Must show: closeout-evidence checks, scoped dirty-tree filtering, explicit evidence-only treatment of `.squad/decisions.md` and `.squad/identity/now.md`, structured FAIL generation.

4. **Closeout Lane Proof**
   - `tests\integration\validator-hardening-iteration2.ps1`
   - `extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath .`
   - Must confirm the rule works in both seeded fixtures and the live repo lane.

### Failure Criteria

- Any over-claim fixture passes when it should fail.
- Repo-level evidence files alone trigger dirty-tree failure.
- A closed-status iteration missing review, retro, or hardening verification is accepted.
- Any failure mode produces raw exception text instead of structured FAIL output.

---

## Blocking Concern 2: Approval-Reuse Detection Correctness

**Hardening-Gate Concern**: `approval-reuse-detection-correctness`  
**Requirement Lens**: FR-003, FR-005, FR-008; TG-003, TG-008; SC-003, SC-005  
**Primary Tasks**: T014, T015, T016, T029

### What Must Be True

- Sibling iterations with duplicated approval evidence quotes in `plan.md` or `state.md` fail mechanically.
- Matching is based on whitespace normalization plus markdown-emphasis stripping only.
- Distinct quotes do not false-match after normalization.
- Reuse is allowed only when an explicit blanket multi-iteration authorization scope is recorded.
- FAIL output names both iterations and the duplicated quote in structured form.

### Required Evidence

1. **Fixture Coverage**
   - `tests\integration\fixtures\013-validator-hardening\approval-reuse\`
   - Must include: byte-identical duplicates, whitespace-drift duplicates, emphasis-variant duplicates, distinct quotes that must pass, explicit blanket-scope pass cases, unlabeled reuse fail cases.

2. **Replay Assertions**
   - `tests\integration\validator-hardening-iteration2.ps1`
   - Must prove: duplicate detection, normalization behavior, blanket-scope exemption, structured FAIL output, no raw exceptions.

3. **Implementation Inspection**
   - `extensions\specrew-speckit\scripts\shared-governance.ps1`
   - `extensions\specrew-speckit\scripts\validate-governance.ps1`
   - Must show: sibling-iteration collection, normalization logic, explicit-scope exemption handling, structured FAIL naming both iterations.

### Failure Criteria

- Duplicate approval evidence passes without explicit blanket scope.
- Distinct quotes are rejected because normalization over-matches.
- Blanket-scope cases still fail.
- FAIL output omits one of the two iterations or the duplicated quote.

---

## Blocking Concern 3: Bookkeeping Classifier Accuracy

**Hardening-Gate Concern**: `bookkeeping-classifier-accuracy`  
**Requirement Lens**: FR-006, FR-010, FR-005; TG-005, TG-007; SC-006, SC-005  
**Primary Tasks**: T022, T023, T024, T025, T026

### What Must Be True

- `.github/copilot-instructions.md` changes limited to timestamp, `## Active Technologies`, or `## Recent Changes` classify as `bookkeeping`.
- Any change outside those areas classifies as `behavior`.
- The classifier is implemented as reusable helper logic consumed by `scripts\specrew-start.ps1`, not validator-only logic.
- Bookkeeping-only changes do not trigger restart guidance; behavior changes do.
- Any validator-side reuse remains additive and does not change existing command surface or exit-code expectations.

### Required Evidence

1. **Fixture Coverage**
   - `tests\integration\fixtures\013-validator-hardening\copilot-instructions\`
   - Must include: timestamp-only, Active Technologies only, Recent Changes only, mixed bookkeeping-only, mixed bookkeeping+behavior, behavior-only edits, manual edits inside bookkeeping sections that must still classify correctly.

2. **Classifier-Only Replay**
   - `tests\integration\validator-hardening-iteration2.ps1 -ClassifierOnly`
   - Must prove the expected bookkeeping vs. behavior outcomes deterministically.

3. **Full Replay + Compatibility**
   - `tests\integration\validator-hardening-iteration2.ps1`
   - Must prove classifier participation does not alter validator CLI shape, PASS/FAIL format, or exit-code expectations.

4. **Implementation Inspection**
   - `extensions\specrew-speckit\scripts\Test-CopilotInstructionsChangeType.ps1`
   - `scripts\specrew-start.ps1`
   - `extensions\specrew-speckit\scripts\validate-governance.ps1`
   - Must show: helper ownership in the reusable script, consumption by `specrew-start.ps1`, additive-only validator-side reuse.

5. **Recorded Evidence**
   - `specs\013-validator-hardening\quickstart.md`
   - Must capture the classifier proof named in T026 after the commands pass.

### Failure Criteria

- Any bookkeeping-only diff is classified as behavior.
- Any behavior-affecting diff is classified as bookkeeping.
- Restart guidance still fires for bookkeeping-only changes.
- The helper exists only inside the validator and is not consumed by `specrew-start.ps1`.
- Classifier integration changes validator CLI or exit-code compatibility.

---

## Blocking Concern 4: Corpus Graduation Completeness

**Hardening-Gate Concern**: `corpus-graduation-completeness`  
**Requirement Lens**: FR-007; TG-003, TG-004, TG-006; SC-007  
**Primary Tasks**: T017, T021, T027, T028, T029

### What Must Be True

- `.specrew/quality/known-traps.md` marks the four relevant rows as validator-enforced:
  - per-iteration approval evidence reuse
  - over-claim
  - canonical iteration schema
  - canonical concern enumeration
- Each graduated row cites the implementing requirement(s), proving test(s), and implementation file(s).
- Stale guidance text does not remain after graduation.
- Feature documentation truthfully references the graduated enforcement state.

### Required Evidence

1. **Corpus Inspection**
   - `.specrew\quality\known-traps.md`
   - Must show all four rows marked validator-enforced with non-placeholder citations.

2. **Traceability Inspection**
   - Approval-reuse row must cite FR-003 and `tests\integration\validator-hardening-iteration2.ps1`.
   - Over-claim row must cite FR-004 and `tests\integration\validator-hardening-iteration2.ps1`.
   - Canonical-schema / canonical-concern rows must cite FR-001 / FR-002 and `tests\integration\validator-hardening-iteration1.ps1`.

3. **Documentation Truth**
   - `specs\013-validator-hardening\plan.md`
   - `specs\013-validator-hardening\quickstart.md`
   - `specs\013-validator-hardening\quality\trap-reapplication.md`
   - Must reflect the final enforcement/citation state without claiming closure before proof exists.

### Failure Criteria

- Any required row remains ungraduated at review time.
- Citations point to wrong or nonexistent requirement/test paths.
- Placeholder or stale pre-enforcement guidance remains.
- Feature docs claim graduation without the corpus proving it.

---

## Blocking Concern 5: Regression Preservation

**Hardening-Gate Concern**: `regression-preservation`  
**Requirement Lens**: FR-010 plus retained FR-001, FR-002, FR-005 behavior; TG-007; SC-001, SC-002, SC-003, SC-004, SC-005, SC-006, SC-007  
**Primary Tasks**: T023, T026, T029

### What Must Be True

- Iteration 002 changes do not break iteration 001 canonical-schema enforcement, canonical-concern enforcement, or structured FAIL behavior.
- `validate-governance.ps1` remains additive: same command surface, argument expectations, exit-code behavior, and PASS/FAIL compatibility.
- The full closeout lane passes on the final tree.

### Required Evidence

1. **Iteration 001 Regression Lane**
   - `tests\integration\validator-hardening-iteration1.ps1`
   - Must stay green after iteration 002 lands.

2. **Feature Closeout Lane**
   - `tests\integration\quality-profile-foundation.ps1`
   - `tests\integration\hardening-gate-contract.ps1`
   - `tests\integration\quality-evidence-governance.ps1`
   - `tests\integration\validation-contract-lane.ps1`
   - `tests\integration\project-path-resolution-regression.ps1`
   - `tests\integration\validator-hardening-iteration1.ps1`
   - `tests\integration\validator-hardening-iteration2.ps1`
   - `extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath .`

3. **Diff Audit**
   - Final review must inspect the touched validator, classifier, fixture, corpus, and documentation paths named by T029.
   - Must confirm the changes remain within the authorized iteration-002 scope.

### Failure Criteria

- Any iteration 001 rule regresses.
- The validator surface changes incompatibly.
- Repo-wide validator pass breaks on the final tree.
- Final diff contains out-of-scope behavior beyond iteration 002 authorization.

---

## Review Execution Checklist

Before issuing a verdict, the eventual reviewer must confirm all of the following:

- [ ] T014-T029 are marked complete only where corresponding evidence exists.
- [ ] `specs\013-validator-hardening\iterations\002\state.md` and `plan.md` tell the same lifecycle truth as the review boundary.
- [ ] `specs\013-validator-hardening\iterations\002\quality\hardening-gate.md` has post-implementation verification populated truthfully.
- [ ] All five blocking concerns above have passed their required evidence checks.
- [ ] Structured FAIL output remains the user-visible failure mode for new rejection paths.
- [ ] The full closeout lane from T029 passes on the review tree.

---

## Verdict Translation

| Outcome | Verdict | Next Move |
| --- | --- | --- |
| All five blocking concerns pass and artifact truth is coherent | `pass` | Proceed to retrospective and closeout |
| Any blocking concern fails or required evidence is missing | `needs-work` | Return to implementation with a named gap ledger |
| Scope/authority truth is contradictory or spec authority is insufficient | `blocked` | Escalate to Alon Fliess before closure |

---

## Notes

- This is review preparation only; it is not an implementation review and not a release verdict.
- The hardening gate remains the authority for which concerns are blocking; this note supplies the evidence bar the eventual review must enforce.
- No soft acceptance: a known gap must be fixed now or explicitly deferred with approval and recorded evidence.

# Retro Facilitator Inbox: Feature 013 iteration 002 retrospective

**Date**: 2026-05-12  
**Feature**: `013-validator-hardening`  
**Iteration**: `002`

## Decision

Treat three lessons from the accepted iteration-002 review as standing process guidance for future planning and retro work:

1. `/speckit.plan`-generated changes inside `.github/copilot-instructions.md` timestamp, `## Active Technologies`, and `## Recent Changes` sections are bookkeeping-only unless the diff escapes those bounded sections.
2. Any dirty-tree blocker change must prove both sides of the rule: one fixture where canonical iteration artifacts fail and one fixture where repo-level evidence-only traces pass.
3. `.claude/settings.local.json` and similar workstation-local files are lifecycle-boundary noise unless the iteration explicitly changes their behavior and says so.

## Why

Feature 013 iteration 002 hit all three patterns in a bounded way: planner-output drift had to be repaired before restart guidance stayed low-noise, the lockout-chain false-positive dirt precedent had to be encoded into the over-claim replay path, and commit `c3ac63a` carried local config noise that did not change governance truth. Recording the rule now keeps future retros from rediscovering the same distinctions as if they were new.

## Next Planning Application

- When a slice touches restart guidance, state the bookkeeping-only sections up front and require replay coverage before approval.
- When a slice touches closure truth or dirt filtering, require the evidence-only pass fixture in the plan, not just the dirty fail fixture.
- When a lifecycle commit includes local noise, either isolate it or label it explicitly so review/retro/closeout boundaries stay readable.


## 2026-05-11-implementer-iter005-implementation
### 2026-05-10T22:12:33Z: Iteration 005 implementation boundary
**By:** Implementer (Copilot)
**Type:** implementation-scope
**What:** Keep Polish execution aligned to the authorized six-command validation lane and verify any user-facing replay example against real reviewer replay output before documenting it.
**Why:** The iteration plan and hardening-gate authorization both narrowed T027 to a six-command lane, so implementation should not silently reintroduce extra validation commands. Reviewer-facing visibility text is easy to drift if copied by hand; replay examples in docs should come from `scaffold-reviewer-artifacts.ps1` / `specrew-review.ps1` output instead.
**Evidence:** Validation lane passed with: `tests\integration\reviewer-regression-event.ps1`, `tests\integration\lockout-chain-cap.ps1`, `tests\integration\reviewer-regression-ledger.ps1`, `tests\integration\reviewer-regression-withdrawal.ps1`, `tests\integration\carry-forward-closed-iteration.ps1`, and `extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath .`. Documentation examples in `docs\user-guide.md` were checked against live output from `extensions\specrew-speckit\scripts\scaffold-reviewer-artifacts.ps1` and `scripts\specrew.ps1 review` on the lockout-cap fixture.

## 2026-05-11-reviewer-iter005-review
### 2026-05-11T00:00:00Z: Reviewer decision - Iteration 005 review acceptance
**By:** Reviewer (Copilot)
**Type:** review-approval
**What:** Accept Iteration 005 review boundary for `008-reviewer-escalation-symmetry`.
**Why:** T027 passed on the authorized six-command lane only (no `gap-governance.ps1`), and T028 documentation plus the lockout-cap visibility example were verified against actual `scaffold-reviewer-artifacts.ps1` and `specrew review` replay output.
**Evidence:** `specs\008-reviewer-escalation-symmetry\iterations\005\review.md`, `specs\008-reviewer-escalation-symmetry\iterations\005\plan.md`, `specs\008-reviewer-escalation-symmetry\iterations\005\state.md`
**Next Action:** Run the Iteration 005 retrospective, then perform closeout without reopening implementation unless new contradictory runtime evidence appears.

## 2026-05-11-retro-facilitator-iter005-retro
### 2026-05-11T00:00:00Z: Team decision - Iteration 005 retrospective findings
**By:** Retro Facilitator (Copilot)
**Type:** process-governance
**What:** Iteration 005 retrospective extracted three core governance lessons and formalized them as enforced baselines for future hardening gates.

### Core Findings

**1. Richer Hardening-Gate Schema is Preferred Baseline**
- Iteration 005 hardening-gate was authored with Overall Verdict `ready` and explicit pending fields (`Reviewed By`, `Reviewed At` marked pending). At sign-off, governance fields updated atomically without blocking.
- This schema prevents approval-inheritance drift by signaling planning readiness while explicitly showing which governance fields remain pending.
- **Action:** Spec Steward (Alon Fliess) will update Spec 005 Phase 2 hardening-gate enforcement to require this schema for all new iterations.

**2. Approval Scope Must Tether to Active Iteration Slice**
- Iteration 004 review identified approval-recording gaps where scope was inherited from prior cycles without explicit revalidation.
- Iteration 005 corrected this by having Alon Fliess sign off on 2026-05-11 with explicit scope refresh: Polish slice (T027–T028, 3 story_points).
- **Action:** Encode this as a validation rule in Spec 008 governance-trap corpus and propagate to feature portfolio approval-gate checklists.

**3. Staged Validation Discipline Prevents Late-Found Gaps**
- Iteration 005 applied this discipline explicitly: T027 ran the authorized six-command validation lane; T028 verified documentation against live `scaffold-reviewer-artifacts.ps1` and `specrew review` output.
- Result: zero rework, zero review findings, zero reviewer-regression events.
- **Action:** Continue enforcing replay-path coverage mandate in all Polish and handoff-facing iterations.

## 2026-05-11-spec-steward-iter005-governance
### 2026-05-11T00:00:00Z: Spec steward decision - Feature 008 Iteration 005 pre-sign-off governance schema
**By:** Spec Steward (Copilot)
**Type:** governance-pattern
**What:** Accepted the pre-sign-off hardening-gate schema convention established by iteration 005 sign-off protocol. This convention formalizes the lifecycle transition from planning-phase readiness to signed-off authorization.

**Governance Pattern Formalized:**
- **Pre-Sign-Off State:** Overall Verdict: `ready`, Pending metadata fields explicitly marked, Evidence Basis: `planning-time-analysis`, Runtime Evidence Status: `pending-post-implementation`
- **Post-Sign-Off State:** Overall Verdict updated to reflect signed status, Reviewed By/Reviewed At updated with actual values, Sign-Off Evidence section added

**Two-Artifact Traceability:** When human approval changes authorized scope (e.g., reducing validation commands):
1. Update plan.md task definition with new scope
2. Update hardening-gate concern evidence to name exact authorized command set
3. Re-run validation to confirm both artifacts align
4. Record scope change in Sign-Off Evidence section

**Known-Traps Seeded:**
1. `pre-sign-off-schema-convention-drift` — Detects hardening gates losing pending-metadata notation
2. `validation-lane-concern-scope-drift` — Detects when concern documentation and plan.md task definitions diverge

**Applicability:** This pattern is baseline for pre-implementation hardening-gate sign-off workflows across all features. Future iteration 005+ slices follow this schema unless explicitly overridden.

## 2026-05-11-planner-iter005-approval-boundary-repair
### 2026-05-11T00:00:00Z: Planner decision - Iteration 005 approval-recording boundary repair
**By:** Planner (Copilot)
**Type:** governance-repair
**What:** Reviewer flagged four concrete governance gaps in Iteration 005's approval-recording boundary. All four gaps have been repaired.

**Repairs Applied:**
1. **state.md Sign-Off Status Alignment:** Updated `Hardening-Gate Sign-Off` to ✅ **SIGNED** (2026-05-11) and `Implementation Authorization` to ✅ **AUTHORIZED** (2026-05-11)
2. **plan.md Distinct Implementation Authorization Record:** Added new `Implementation Authorization` section (hardening-gate-triggered authorization to implement, 2026-05-11), distinct from planning-level approval (2026-05-10)
3. **hardening-gate.md Sign-Off Readiness Concern Count:** Updated concern count from four to six polish-specific concerns to match Concern Review table
4. **hardening-gate.md Approval Ref:** Preserved `Approval Ref: —` per explicit human direction, documented as exception to governance trap

**Verification:** Ran governance validation script — ✅ **PASS** — All governance checks passed.

**Learnings for Future Iterations:**
1. Distinguish planning-level approval (to prepare hardening gate) from hardening-gate-triggered implementation authorization (to execute after gate sign-off)
2. Validate concern counts match Concern Review table row counts
3. Governance traps document best practices but do not supersede explicit direction from approval authorities

## 2026-05-11-planner-iter005-retro-repair
### 2026-05-11T00:00:00Z: Planner decision - Iteration 005 retrospective truthfulness boundary repair
**By:** Planner (Copilot)
**Type:** governance-repair
**What:** Iteration 005 retrospective failed independent audit gate because it mischaracterized governance friction by framing the approval-recording boundary rejection and repair cycle as a "success story" while claiming zero friction occurred.

**Changes Made:**
1. **Retrospective (retro.md):** Separated friction from resolution with explicit "Friction Encountered and Resolved" section; corrected Approval Ref claim; reframed "What Didn't Go Well"
2. **State (state.md):** Updated Current Phase to `retrospective-in-progress`; updated Iteration Status to clarify retrospective repair in progress

**Governance Principle Codified:** Honest retrospectives must name friction explicitly before explaining how it was resolved. Narratives that omit friction events—even to praise remediation—fail the truthfulness boundary.

**Approval Status:** Retrospective truthfulness repair recorded. Closeout may proceed after human re-review confirms repaired retrospective satisfies truthfulness boundary. Retro facilitator locked out of further revisions.

## 2026-05-11-retro-facilitator-iter002-amendment
### 2026-05-10T00:00:00Z: Retro facilitator decision - Iteration 002 retrospective amendment
**By:** Retro Facilitator (Copilot)
**Type:** process-governance
**What:** Iteration 002 retrospective amended to capture three real governance lessons.

**Decisions Captured:**
1. **Approval Scope Must Be Tethered to Active Iteration Slice:** When a plan is resliced or deferred, approval scope must be refreshed. Do not reuse approval evidence from prior iteration boundaries.
2. **Human-Direction Hold Messages Must Follow Three-Section Rule:** All hold messages must include: (1) Why we stopped, (2) What you can do, (3) Who to escalate to.
3. **Startup-Loaded Configuration Requires Iteration-Boundary Commits:** Files loaded at session startup (`.github/agents/squad.agent.md`, `.specify/extensions/specrew-speckit/squad-templates/*`) require explicit iteration-boundary commits and session restart via `specrew-start.ps1` to take effect.

**Team Action Items:**
- Planner: Update Iteration 003 plan approval section to include explicit scope certification
- Coordinator handoff maintainer: Ensure all future human-direction holds follow the three-section rule
- Review-operations maintainer: Document startup-loaded file boundaries in the next planning ceremony

## 2026-05-11-reviewer-iter005-retro-reaudit
### 2026-05-11T00:00:00Z: Reviewer decision - Iteration 005 retrospective truthfulness re-audit
**By:** Reviewer (Copilot)
**Type:** review-audit
**What:** Re-audit of Iteration 005 retrospective repair confirmed it satisfies all three truthfulness boundaries.

**Audit Result:** ✅ **APPROVED**

**Findings:**

## 2026-05-11-runtime-evidence-feature011-iter002-signoff
### 2026-05-11T17:13:13+03:00: Runtime evidence - Feature 011 Iteration 002 hardening-gate sign-off routing
**By:** Squad (Coordinator)
**Type:** runtime-evidence
**Work Item:** Hardening-gate sign-off recording and planning -> execution boundary update for feature `011-specrew-start-conditional-pause` iteration 002
**Requested Agent:** Spec Steward
**Actual Agent:** Spec Steward
**Model:** claude-sonnet-4.5
**Assignment:** honored
**Fallback Reason:** none

## 2026-05-11-runtime-evidence-feature011-iter002-boundary-repair
### 2026-05-11T17:13:13+03:00: Runtime evidence - Feature 011 Iteration 002 execution-boundary truthfulness repair routing
**By:** Squad (Coordinator)
**Type:** runtime-evidence
**Work Item:** Repair stale pre-sign-off wording in feature `011-specrew-start-conditional-pause` iteration 002 execution-boundary artifacts after sign-off was recorded
**Requested Agent:** Spec Steward
**Actual Agent:** Spec Steward
**Model:** claude-sonnet-4.5
**Assignment:** honored
**Fallback Reason:** none

## 2026-05-11-runtime-evidence-feature011-iter002-state-tail-repair
### 2026-05-11T17:13:13+03:00: Runtime evidence - Feature 011 Iteration 002 state tail repair routing
**By:** Squad (Coordinator)
**Type:** runtime-evidence
**Work Item:** Repair the final stale pre-sign-off line remaining in `state.md` after execution-boundary updates
**Requested Agent:** Spec Steward
**Actual Agent:** Spec Steward
**Model:** claude-sonnet-4.5
**Assignment:** honored
**Fallback Reason:** none

## 2026-05-11-runtime-evidence-feature011-iter002-implementation
### 2026-05-11T17:13:13+03:00: Runtime evidence - Feature 011 Iteration 002 implementation routing
**By:** Squad (Coordinator)
**Type:** runtime-evidence
**Work Item:** Execute feature `011-specrew-start-conditional-pause` iteration 002 tasks T043-T056
**Requested Agent:** Implementer
**Actual Agent:** Implementer
**Model:** claude-sonnet-4.5
**Assignment:** honored
**Fallback Reason:** none

## 2026-05-11-runtime-evidence-feature011-iter002-review-prep
### 2026-05-11T17:13:13+03:00: Runtime evidence - Feature 011 Iteration 002 review-prep routing
**By:** Squad (Coordinator)
**Type:** runtime-evidence
**Work Item:** Prepare the independent review checklist for the three blocking concerns before implementation lands
**Requested Agent:** Reviewer
**Actual Agent:** Reviewer
**Model:** claude-sonnet-4.5
**Assignment:** honored
**Fallback Reason:** none

## 2026-05-11-runtime-evidence-feature011-iter002-review
### 2026-05-11T17:13:13+03:00: Runtime evidence - Feature 011 Iteration 002 review routing
**By:** Squad (Coordinator)
**Type:** runtime-evidence
**Work Item:** Independently review feature `011-specrew-start-conditional-pause` iteration 002 implementation against the approved blocking concerns and issue the review verdict
**Requested Agent:** Reviewer
**Actual Agent:** Reviewer
**Model:** claude-sonnet-4.5
**Assignment:** honored
**Fallback Reason:** none

## 2026-05-11-runtime-evidence-feature011-iter002-retro
### 2026-05-11T17:13:13+03:00: Runtime evidence - Feature 011 Iteration 002 retrospective routing
**By:** Squad (Coordinator)
**Type:** runtime-evidence
**Work Item:** Facilitate the retrospective for feature `011-specrew-start-conditional-pause` iteration 002 after accepted review
**Requested Agent:** Retro Facilitator
**Actual Agent:** Retro Facilitator
**Model:** claude-sonnet-4.5
**Assignment:** honored
**Fallback Reason:** none

## 2026-05-11-runtime-evidence-feature011-iter002-closeout
### 2026-05-11T17:13:13+03:00: Runtime evidence - Feature 011 Iteration 002 closeout routing
**By:** Squad (Coordinator)
**Type:** runtime-evidence
**Work Item:** Complete feature `011-specrew-start-conditional-pause` iteration 002 closeout, including T057 documentation updates, staged validation lane, and closure boundary
**Requested Agent:** Implementer
**Actual Agent:** Implementer
**Model:** claude-sonnet-4.5
**Assignment:** honored
**Fallback Reason:** none

## 2026-05-11-runtime-evidence-feature011-feature-closeout
### 2026-05-11T18:36:08+03:00: Runtime evidence - Feature 011 feature-level closeout routing
**By:** Squad (Coordinator)
**Type:** runtime-evidence
**Work Item:** Record the feature-level closure for `011-specrew-start-conditional-pause`, refresh stale focus pointers, rerun the six-script lane, and commit the feature closure boundary
**Requested Agent:** Spec Steward
**Actual Agent:** Spec Steward
**Model:** claude-sonnet-4.5
**Assignment:** honored
**Fallback Reason:** none

## 2026-05-11-runtime-evidence-feature012-tasks
### 2026-05-11T19:26:29+03:00: Runtime evidence - Feature 012 task generation routing
**By:** Squad (Coordinator)
**Type:** runtime-evidence
**Work Item:** Generate `tasks.md` for feature `012-descriptive-id-handoffs` from the approved spec and plan, then continue to the post-task governance readiness check
**Requested Agent:** Planner
**Actual Agent:** Planner
**Model:** gpt-5.4
**Assignment:** honored
**Fallback Reason:** none

## 2026-05-11-runtime-evidence-feature012-after-tasks
### 2026-05-11T19:26:29+03:00: Runtime evidence - Feature 012 after-tasks governance routing
**By:** Squad (Coordinator)
**Type:** runtime-evidence
**Work Item:** Run the post-task governance validation for `012-descriptive-id-handoffs` immediately after task generation
**Requested Agent:** Planner
**Actual Agent:** Planner
**Model:** gpt-5.4
**Assignment:** honored
**Fallback Reason:** none

## 2026-05-11-runtime-evidence-feature012-authorization-boundary-repair
### 2026-05-11T19:50:26+03:00: Runtime evidence - Feature 012 iteration 001 authorization-boundary repair routing
**By:** Squad (Coordinator)
**Type:** runtime-evidence
**Work Item:** Commit the generated task backlog boundary, scaffold iteration 001 planning artifacts with a canonical pre-implementation hardening gate, refine the feature plan's iteration-scaffolding constraint, and stop for fresh sign-off plus implementation authorization
**Requested Agent:** Planner
**Actual Agent:** Planner
**Model:** claude-haiku-4.5
**Assignment:** honored
**Fallback Reason:** none

## 2026-05-11-runtime-evidence-feature012-state-schema-repair
### 2026-05-11T20:06:05+03:00: Runtime evidence - Feature 012 iteration 001 state-schema repair routing
**By:** Squad (Coordinator)
**Type:** runtime-evidence
**Work Item:** Align iteration `001` state metadata to the canonical schema, rerun governance validation until the crash is gone and zero FAIL lines remain, then seed the canonical state-schema trap row
**Requested Agent:** Planner
**Actual Agent:** Planner
**Model:** claude-haiku-4.5
**Assignment:** honored
**Fallback Reason:** none

## 2026-05-11-runtime-evidence-feature012-before-implement
### 2026-05-11T22:18:50+03:00: Runtime evidence - Feature 012 iteration 001 before-implement routing
**By:** Squad (Coordinator)
**Type:** runtime-evidence
**Work Item:** Record the human hardening-gate sign-off and implementation authorization for feature `012-descriptive-id-handoffs` iteration `001`, then run the pre-implementation governance gate
**Requested Agent:** Spec Steward
**Actual Agent:** Spec Steward
**Model:** claude-haiku-4.5
**Assignment:** honored
**Fallback Reason:** none

## 2026-05-11-runtime-evidence-feature012-review
### 2026-05-11T23:20:48+03:00: Runtime evidence - Feature 012 iteration 001 review routing
**By:** Squad (Coordinator)
**Type:** runtime-evidence
**Work Item:** Run T008 narration validation for feature `012-descriptive-id-handoffs` iteration `001`, scaffold the missing review artifact, verify the blocking concerns, and record the review verdict for the readable-reference rollout
**Requested Agent:** Reviewer
**Actual Agent:** Reviewer
**Model:** claude-sonnet-4.5
**Assignment:** honored
**Fallback Reason:** none

## 2026-05-11-runtime-evidence-feature012-review-followthrough
### 2026-05-11T23:20:48+03:00: Runtime evidence - Feature 012 iteration 001 review follow-through routing
**By:** Squad (Coordinator)
**Type:** runtime-evidence
**Work Item:** Convert the iteration `001` hardening gate to post-implementation recorded state and normalize the review-phase artifact fields so retrospective can start cleanly
**Requested Agent:** Reviewer
**Actual Agent:** Reviewer
**Model:** claude-sonnet-4.5
**Assignment:** honored
**Fallback Reason:** none

## 2026-05-11-runtime-evidence-feature012-retro
### 2026-05-11T23:55:00+03:00: Runtime evidence - Feature 012 iteration 001 retrospective routing
**By:** Squad (Coordinator)
**Type:** runtime-evidence
**Work Item:** Author the iteration `001` retrospective for the readable-reference rollout, update lifecycle artifacts for the retro boundary, and keep closeout as the next step
**Requested Agent:** Retro Facilitator
**Actual Agent:** Retro Facilitator
**Model:** claude-sonnet-4.5
**Assignment:** honored
**Fallback Reason:** none

## 2026-05-12-runtime-evidence-feature012-iter002-planning
### 2026-05-12T00:22:00+03:00: Runtime evidence - Feature 012 iteration 002 planning routing
**By:** Squad (Coordinator)
**Type:** runtime-evidence
**Work Item:** Scaffold iteration `002`, the replay-path integration and corpus follow-through planning slice, validate governance, and commit the planning boundary without starting implementation
**Requested Agent:** Planner
**Actual Agent:** Planner
**Model:** claude-sonnet-4.5
**Assignment:** honored
**Fallback Reason:** none

## 2026-05-11-runtime-evidence-feature012-specify
### 2026-05-11T18:39:12+03:00: Runtime evidence - Feature 012 opening routing
**By:** Squad (Coordinator)
**Type:** runtime-evidence
**Work Item:** Open the next approved feature from `C:\Temp\squad-descriptive-references.md` and establish the repository feature pointer for descriptive-reference validation work
**Requested Agent:** Spec Steward
**Actual Agent:** Spec Steward
**Model:** claude-sonnet-4.5
**Assignment:** honored
**Fallback Reason:** none

## 2026-05-11-runtime-evidence-feature012-clarify
### 2026-05-11T18:41:37+03:00: Runtime evidence - Feature 012 clarification routing
**By:** Squad (Coordinator)
**Type:** runtime-evidence
**Work Item:** Tighten the descriptive-reference spec around the numeric-ID threshold, grouped-list handling, and exclusion of tool-rendered output from the detector
**Requested Agent:** Spec Steward
**Actual Agent:** Spec Steward
**Model:** claude-sonnet-4.5
**Assignment:** honored
**Fallback Reason:** none

## 2026-05-11-runtime-evidence-feature012-plan
### 2026-05-11T18:44:02+03:00: Runtime evidence - Feature 012 planning routing
**By:** Squad (Coordinator)
**Type:** runtime-evidence
**Work Item:** Build the feature plan for descriptive-reference handoffs, including iteration scoping across coordinator guidance and later governance/test enforcement
**Requested Agent:** Planner
**Actual Agent:** Planner
**Model:** claude-sonnet-4.5
**Assignment:** honored
**Fallback Reason:** none
1. **Rejection/Repair Cycle — No Smoothing Detected:** Retrospective now contains explicit "Friction Encountered and Resolved" section. New friction section isolates rejection event and names it explicitly before explaining resolution.
2. **Approval Ref Traceability — Accurate Language Confirmed:** Language now correctly states "Approval Ref remains `—`" and grounds traceability in timestamp records per governance discipline.
3. **State.md Retrospective Status — Consistent Fields:** All three status fields (Current Phase, Iteration Status, Retrospective Verdict) tell the same story: review complete, retrospective repaired, closure awaits re-approval.

**Governance Principles Confirmed:**
1. Honest friction naming — retro explicitly names rejection and repair cycle as governance correction
2. Approval Ref exception is auditable — decision inbox entry documents rationale
3. Staged validation discipline preserved — distinct positive item separate from friction event

**Approval Status:** Repaired retrospective passes truthfulness boundary. Iteration 005 closeout may proceed.

## 2026-05-10T12-05-33Z-copilot-directive
### 2026-05-10T12:05:33+03:00: User directive - Final user-facing response format
**By:** Alon Fliess (via Copilot)
**Type:** process-directive
**What:** Final user-facing responses must lead with plain English in three named sections: What I just did / Why I stopped / What I need from you. Governance vocabulary should appear only as cross-references.
**Why:** User request — captured for team memory

## 2026-05-11-runtime-evidence-feature007-iter002-implementation
### 2026-05-11T04:10:06+03:00: Runtime evidence - Feature 007 Iteration 002 implementation
**By:** Squad (Coordinator)
**Type:** implementation-evidence
**What:** Iteration 002 implementation completed T007-T010 for feature `007-user-facing-progress-handoff`: the soft validator landed, two validator integration tests landed, the validation lane was registered, and the review-file navigation rule was rolled into all durable guidance surfaces.
**Why:** Preserve the implementation boundary, the approval evidence (`Approved, continue implementation.`), the validation results, and the new session-restart requirement triggered by updating `.github/agents/squad.agent.md`.
**Evidence:** `extensions\specrew-speckit\validators\handoff-governance-validator.ps1`; `tests\integration\handoff-governance-jargon-response-test.ps1`; `tests\integration\handoff-governance-plain-language-response-test.ps1`; `extensions\specrew-speckit\governance\validation-lane.md`; `tests\integration\validation-contract-lane.ps1`; `specs\007-user-facing-progress-handoff\iterations\002\quality\hardening-gate.md`
**Validation:** `tests\integration\validation-contract-lane.ps1` ✅ PASS; `extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath . -IterationPath .\specs\007-user-facing-progress-handoff\iterations\002` ✅ PASS; empty-input validator invocation exited cleanly with soft warnings; repeated identical validator runs produced identical output.
**Next Action:** Start a fresh session before Iteration 002 review so the updated `.github/agents/squad.agent.md` coordinator-response guidance is active.

# Decision Ledger

## 2026-05-09-runtime-evidence-009
### 2026-05-09T22:09:00+03:00: Feature 009 lifecycle and repair evidence
**By:** Alon Fliess (via Copilot)
**What:** Feature `specs/009-project-path-resolution` was run through specify, clarify, planning, tasks, hardening-gate approval, implementation, reviewer repair, and final validation. The final outcome included audited path-resolution fixes across entry-point and internal scripts, a deterministic regression lane, static anti-pattern coverage, known-traps seeding, trap reapplication evidence, and a return of `.specify\feature.json` to `specs/008-reviewer-escalation-symmetry` after closure.
**Why:** Preserve a compact lifecycle record that feature 009 completed ahead of feature 008, including the reviewer-enforced repair cycle that expanded runtime coverage and closed the remaining audit gaps.

## copilot-decision-2026-05-07T22-12-30+03-00
### 2026-05-07T22:12:30+03:00: Clarify skip rationale for 005 Phase 1
**By:** Alon Fliess (via Copilot)
**What:** Resume `specs/005-stack-aware-quality-bar` at Phase 1 planning without re-running clarify because the hardened spec is unchanged, reviewer-approved, and materially complete for phase-scoped planning.
**Why:** Existing feature resume — proceed through the formal lifecycle with plan/tasks/before-implement for the first slice.


## 2026-05-08-spec-005-clarifications-applied
# Decision: Spec 005 Clarifications Applied - Planning Ready

**Date**: 2026-05-08  
**Type**: spec-clarification  
**Affected Feature**: specs/005-stack-aware-quality-bar  
**Requestor**: Alon Fliess  
**Status**: Applied

## Context

Six critical clarifications were resolved through interactive clarification workflow for spec 005 (Stack-Aware Quality Bar). These decisions remove ambiguity around implementation mechanisms, approval flows, baseline comparisons, and trap management workflows.

## Decisions Applied

1. **Lens Checklist Format**: Versioned lens checklists use Markdown tables (FR-022 updated)
2. **Reasoning Class Binding**: Required bug-hunter lenses hard-bind to the strongest available reviewer/reasoning class by default; lower-tier execution requires an explicit recorded override (FR-038, FR-039 updated)
3. **Hardening-Gate Approval Authority**: Deferrals for unresolved security, resilience, or operational concerns require human developer approval; agents may recommend only (FR-033 updated)
4. **Quality-Drift Baseline Order**: Compares against the active feature's planned quality baseline first, then prior iteration baselines when they exist (FR-042 updated)
5. **Technology-Specific Best Practices**: The quality bar enforces technology-specific software quality best practices even when the human developer lacks deep quality expertise (new FR-003a added)
6. **Trap Promotion Workflow**: After human approval, a newly found trap is added to the known-traps corpus immediately and may then be promoted into a checklist item or mechanical check in the same or next slice (FR-036 updated)

## Rationale

These clarifications resolve critical implementation ambiguities that would otherwise block planning:

- **Format standardization** (Markdown tables) enables consistent tooling and human review
- **Hard binding to strongest reasoning class** prevents quality regressions from model-tier downgrades
- **Human approval gates** for critical deferrals prevent agents from bypassing security/resilience concerns
- **Baseline comparison order** provides clear precedence for quality-drift detection
- **Technology-specific enforcement** ensures quality doesn't degrade when developers work outside their expertise zones
- **Immediate trap addition** with optional promotion creates a clear learning workflow without blocking current work

## Implications

- **Planning Readiness**: Spec 005 is now planning-ready with all critical ambiguities resolved
- **Implementation Clarity**: Format, approval, and workflow decisions provide concrete implementation targets
- **Quality Consistency**: Hard-binding and technology-specific enforcement raise the quality floor
- **Governance Traceability**: Human approval requirements and immediate trap addition support auditable quality governance

## Affected Artifacts

- `specs/005-stack-aware-quality-bar/spec.md`: Added Clarifications section, updated FR-022, FR-033, FR-038, FR-039, FR-042, added FR-003a, updated FR-036, updated TG-001, updated Requirement Ownership table, updated Key Entities, updated Assumptions

## Next Steps

1. Proceed to `/speckit.plan` to generate implementation plan artifacts

## 2026-05-11-runtime-evidence-feature007-iter001-review
### 2026-05-11T03:01:19+03:00: Runtime evidence - Feature 007 Iteration 001 review routing
**By:** Squad (Coordinator)
**Role / Work Item:** Reviewer - review iteration `specs/007-user-facing-progress-handoff/iterations/001`
**Requested Agent:** claude
**Actual Agent:** copilot
**Model ID:** claude-sonnet-4.5
**Status:** fallback
**Fallback Reason:** preferred agent `claude` is not enabled in the delegated routing plan; routed through Copilot task execution

## 2026-05-11-runtime-evidence-feature007-iter001-retro
### 2026-05-11T03:01:19+03:00: Runtime evidence - Feature 007 Iteration 001 retrospective routing
**By:** Squad (Coordinator)
**Role / Work Item:** Retro Facilitator - retrospective for `specs/007-user-facing-progress-handoff/iterations/001`
**Requested Agent:** copilot
**Actual Agent:** copilot
**Model ID:** claude-haiku-4.5
**Status:** honored
**Fallback Reason:** none

## 2026-05-11-runtime-evidence-feature007-iter002-planning
### 2026-05-11T03:01:19+03:00: Runtime evidence - Feature 007 Iteration 002 planning routing
**By:** Squad (Coordinator)
**Role / Work Item:** Planner - plan `specs/007-user-facing-progress-handoff/iterations/002`
**Requested Agent:** claude
**Actual Agent:** copilot
**Model ID:** claude-sonnet-4.5
**Status:** fallback
**Fallback Reason:** preferred agent `claude` is not enabled in the delegated routing plan; routed through Copilot task execution

## 2026-05-11-runtime-evidence-feature007-iter002-plan-repair
### 2026-05-11T03:28:32+03:00: Runtime evidence - Feature 007 Iteration 002 planning structure repair
**By:** Squad (Coordinator)
**Role / Work Item:** Planner - repair iteration 002 planning artifacts and draft planning-time hardening gate
**Requested Agent:** claude
**Actual Agent:** copilot
**Model ID:** claude-sonnet-4.5
**Status:** fallback
**Fallback Reason:** preferred agent `claude` is not enabled in the delegated routing plan; routed through Copilot task execution

## 2026-05-11-runtime-evidence-feature007-scaffolding-corpus-repair
### 2026-05-11T03:28:32+03:00: Runtime evidence - Feature 007 scaffolding-authorization corpus repair
**By:** Squad (Coordinator)
**Role / Work Item:** Spec Steward - clarify trap coverage for unauthorized iteration scaffolding
**Requested Agent:** codex
**Actual Agent:** copilot
**Model ID:** claude-haiku-4.5
**Status:** fallback
**Fallback Reason:** preferred agent `codex` is not enabled in the delegated routing plan; routed through Copilot task execution

## 2026-05-11-runtime-evidence-feature007-iter001-retro-repair
### 2026-05-11T03:01:19+03:00: Runtime evidence - Feature 007 Iteration 001 retro boundary repair
**By:** Squad (Coordinator)
**Role / Work Item:** Retro Facilitator - repair stale restart-boundary messaging in iteration 001 retrospective/state
**Requested Agent:** copilot
**Actual Agent:** copilot
**Model ID:** claude-haiku-4.5
**Status:** honored
**Fallback Reason:** none
2. Design versioned lens checklist Markdown table schema during planning
3. Implement strongest-class routing policy with explicit override tracking
4. Design hardening-gate approval workflow with human sign-off capture


## 2026-05-08-spec-005-concrete-mechanisms
# Decision: Spec 005 Updated with Concrete Quality Mechanisms

**Date**: 2026-05-08  
**Type**: spec-update  
**Affected Feature**: specs/005-stack-aware-quality-bar  
**Requestor**: Alon Fliess  
**Status**: Recorded

## Context

User diagnosis identified that spec 005's quality-governance approach was too category-level, naming quality concerns without providing concrete, enforceable mechanisms. Failures cluster around ceremonial sophistication without enforcement, security baseline drift, operational/resilience holes, and anti-patterns plus test theater. Fast-model implementations especially struggle because they lack concrete guidance.

## Decision

Updated spec 005 to convert tacit senior-quality knowledge into concrete, versioned, reviewable artifacts:

1. **Versioned Lens Checklists** (FR-022 through FR-026): Line-item checks with semantic versioning, upgrade guidance, and change logs
2. **Stack Profile Presets** (FR-024): Named bundles for common stacks (e.g., `node-public-ws-service v1.3.0`, `react-spa-public v2.1.0`)
3. **Mechanical Checks** (FR-027 through FR-030): Non-judgment checks for dead fields/symbols, anti-pattern heuristics, test-integrity validation
4. **Pre-Implementation Hardening Gate** (FR-031 through FR-033): Explicit security/resilience/operational review with recorded sign-off before implementation starts
5. **Known-Traps Corpus** (FR-034 through FR-037): Project-wide defect memory with trap reapplication capability
6. **Strongest-Class Review Binding** (FR-038 through FR-040): Required routing of lens execution to strongest available reasoning class with explicit override policy
7. **Quality-Drift Detection** (FR-041 through FR-043): Separate from spec-drift, detects non-functional quality degradation via quality gap ledger
8. **Reference-Implementation Mode** (FR-044 through FR-046): Optional companion capability for high-risk features

## Rationale

The user's diagnosis showed that category-level quality language helps but does not prevent recurring defect patterns. Concrete mechanisms—versioned checklists, presets, mechanical checks, hardening gates, defect memory, routing policy, and drift detection—convert quality expectations from reviewer intuition into explicit, auditable, improvable artifacts.

## Implications

- **Implementation Complexity**: Increases—now requires versioned artifact management, mechanical check integration, hardening gate workflow, and quality-drift baseline tracking
- **Review Quality**: Improves—explicit line-item checks, mechanical findings, and strongest-class routing reduce reliance on model judgment
- **Learning Curve**: Steeper for fast models—but that is the point; fast models need concrete guidance to deliver senior-quality output
- **Scope Discipline**: Maintained—all mechanisms remain additive to existing lifecycle, no separate platform introduced

## Affected Artifacts

- `specs/005-stack-aware-quality-bar/spec.md`: Problem statement, FR-022 through FR-046, updated TG requirements, updated Key Entities, updated Success Criteria, updated Assumptions, updated Governance Alignment

## Open Questions

- **Mechanical check implementation**: Static analysis extensions, custom lint rules, or integrated tooling?
- **Lens checklist format**: Pure Markdown with tables, or structured YAML with Markdown rendering?
- **Known-traps corpus maintenance**: Manual-only in v1, or semi-automated trap detection from review findings?
- **Quality-drift baseline storage**: Per-iteration JSON snapshots, or cumulative baseline files?

## Next Steps

1. Planning phase: design versioned lens checklist format and stack preset structure
2. Implementation phase: build mechanical checks for dead-field detection and anti-pattern heuristics
3. Validation phase: test hardening gate workflow and quality-drift detection against representative features


## copilot-directive-2026-05-04T11-28-23
### 2026-05-04T11:28:23+03:00: User directive
**By:** Alon Fliess (via Copilot)
**What:** Team member management must be command-driven; users should not have to edit multiple `.squad/` files manually. If Squad has no CRUD command surface for team members, Specrew must provide one.
**Why:** User request — captured for team memory


## copilot-directive-2026-05-04T12-28-01
### 2026-05-04T12:28:01+03:00: User directive
**By:** Alon Fliess (via Copilot)
**What:** Validation should require the mandatory baseline Specrew team members to exist, but must not reject or validate any other additional custom team members.
**Why:** User request — captured for team memory


## copilot-directive-2026-05-07T21-05-27+03-00
### 2026-05-07T21:05:27+03:00: User directive
**By:** Alon Fliess (via Copilot)
**What:** Quality drift should compare against the active feature's planned quality baseline first, then prior iteration baselines when present, and the quality bar should enforce technology-specific software quality best practices even when the human developer lacks deep quality expertise.
**Why:** User request — captured for team memory


## copilot-directive-2026-05-07T21-27-52+03-00
### 2026-05-07T21:27:52.819+03:00: User directive
**By:** Alon Fliess (via Copilot)
**What:** Agents must not "fix" warnings by adding them to a warning-disable or suppression list instead of addressing the underlying problem. The default policy is to fix the root cause. Only when disabling or suppressing the warning is genuinely reasonable or necessary may that path be taken, and it requires explicit human user approval first.
**Why:** User request — captured for team memory


## copilot-directive-2026-05-07T22-03-31+03-00
### 2026-05-07T22:03:31+03:00: User directive
**By:** Alon Fliess (via Copilot)
**What:** Keep GitHub lifecycle issues aligned with the authoritative local iteration artifacts; update source artifacts first and rely on sync rather than manual issue drift.
**Why:** User request — captured for team memory


## data-baseline-validation-fix
# Decision: Baseline Team Validation Fix

**Date**: 2026-05-04  
**Author**: Data (Planner)  
**Status**: Implemented

## Context

The governance validator (`validate-governance.ps1`) was missing team composition validation. Per FR-002 and the product spec, Specrew requires five baseline roles to be present:

- Spec Steward
- Planner
- Implementer
- Reviewer
- Retro Facilitator

However, downstream projects should be free to add custom domain-specific members (e.g., Security Analyst, UX Designer, DBA) without validation rejecting them.

## Problem

The validator had **no team validation logic at all**. It only extracted team roles for sign-off validation but never verified that the mandatory baseline roles were present.

## Solution

Added `Test-BaselineTeamMembers` function that:

1. Checks for presence of all five required baseline roles
2. Reports missing roles as validation errors
3. **Ignores any additional custom members** (does not validate or reject them)

Also updated `Get-TeamRoleMap` to read from **both** team formats:
- Standard Squad "Members" section (Name → Role mapping)
- Specrew-managed "Specrew Baseline Roles" section (Role-only entries in managed block)

This dual-format support is necessary because:
- The Specrew repo itself uses the Members section with named members
- Bootstrapped projects use the managed baseline-roles block

## Verification

Created comprehensive test suite (`tests/integration/validate-baseline-team.ps1`) covering:

1. ✅ Baseline-only team (should pass)
2. ✅ Baseline + single custom member (should pass)
3. ✅ Team missing baseline role (should fail with clear error)
4. ✅ Baseline + multiple custom members (should pass)

All existing integration tests still pass:
- ✅ `tests/integration/team-management.ps1`
- ✅ `tests/integration/bootstrap-to-iteration.ps1` (implied via scaffold paths)
- ✅ Main project validation (`validate-governance.ps1 -ProjectPath .`)

## Impact

- **Validation now enforces baseline team requirement** (previously missing)
- **Custom members are explicitly ignored** (requirement met)
- **No breaking changes** to existing workflows
- **Test coverage added** for this validation surface

## Related Requirements

- FR-002: Bootstrap MUST configure baseline roles (Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator)
- FR-002: Users can add domain-specific members; baseline roles are protected
- Dogfooding obligation: Specrew validates its own governance model

## Follow-Up

None required. Validation is complete and tested.


## data-bootstrap-handoff-revision
# Decision: Bootstrap Handoff Terminal Output and Squad Readiness Signal

**Date**: 2026-05-04  
**Author**: Data (Planner)  
**Status**: Implemented  
**Context**: Rejected artifact revision from La Forge; reviewer lockout applied

## Problem

Picard updated the bootstrap contract to require explicit next-step guidance. La Forge's implementation was rejected for three specific issues:

1. **Missing explicit flow orientation**: Terminal output must include the concise flow wording from contract: "baseline crew → specify features → plan iteration → execute (and review/retro if needed)"
2. **Inconsistent phrase**: Test expected "Baseline Specrew crew installed:" but code output "Baseline crew installed:" — contract/runtime/test were out of sync
3. **No explicit Squad readiness signal**: Downstream repo must be left in a state recognizable by Squad coordinator as "configured, operation-ready team" — not just inferred from populated files

## Decision

Fixed all three issues with minimal, complete changes:

### 1. Terminal Output Flow (Issue 1 & 2)
- Added "=== Usage Flow ===" section with explicit: "Baseline crew → specify features → plan iteration → execute (review and retro as needed)"
- Changed output phrase from "Baseline crew installed:" to "Baseline Specrew crew installed:" with trailing period to match contract and test expectations
- Restructured "Next Steps" to clearly separate: (1) Start spec authoring, (2) Run iteration lifecycle, (3) Optional team extension
- Added explicit references: "Add extra Squad members after bootstrap" and "Keep the Specrew-managed baseline block intact"

### 2. Squad Readiness Metadata (Issue 3)
- Added explicit team status block to `.squad/team.md` via `deploy-squad-runtime.ps1`
- Metadata includes:
  - `**Team Status**: configured` — explicit recognizable state
  - `**Baseline Roles**: Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator`
  - `**Configuration**: Specrew-managed baseline`
- Managed block approach ensures idempotency and allows merging with existing team config

## Rationale

- **Smallest complete fix**: No architectural changes; only output and metadata additions
- **Contract alignment**: Brings implementation, contract, and tests into sync
- **Squad recognizability**: Team status metadata provides explicit signal that Squad can read rather than inferring from file presence
- **Self-sufficient handoff**: Developer gets complete orientation in terminal without leaving for docs

## Validation

- Bootstrap integration test passes cleanly (all pattern matches succeed)
- Team status metadata appears in downstream `.squad/team.md` after bootstrap
- Terminal output includes all three required elements: baseline crew list, usage flow, extension instructions

## Files Changed

- `scripts/specrew-init.ps1`: Terminal output revised (lines 102-125)
- `extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1`: Team status block added (lines 408-414)

## Follow-up

None required. All three rejection issues resolved.


## data-greenfield-bootstrap-truthfulness
# Decision: Greenfield Bootstrap Documentation Truthfulness

**Date**: 2026-05-04  
**Status**: IMPLEMENTED  
**Owner**: Data (Planner)  
**Audience**: Team (Worf, Picard, La Forge, implementers)

## Problem

The greenfield bootstrap documentation (`docs/getting-started.md`) overclaimed what the non-interactive bootstrap path can deliver end-to-end. Specifically:

1. **Dependency validation success was conflated with bootstrap completion**: The script validates Spec Kit/Squad versions successfully, but this doesn't guarantee `.specify/` and `.squad/` will be created (CLIs might fail).
2. **Environment-specific Spec Kit CLI blocker was underemphasized**: The Unicode encoding issue in some Windows PowerShell environments was documented as a "workaround scenario" but actually **blocks the entire greenfield-to-iteration flow** because it prevents `.specify/` creation.
3. **No gate between bootstrap success and iteration scaffolding**: Docs implied you could immediately run downstream scripts (plan/artifacts/review/retro) after bootstrap, but these all require `.specify/` to exist.

## Evidence

- Test `bootstrap-to-iteration.ps1` (lines 76-79): **Skips entirely** if `specify` or `squad` CLIs unavailable
- CI workflow (lines 78-84): Full greenfield-to-iteration path only runs when both CLIs are installed and operational
- Script exit codes: `specrew-init.ps1` returns 0 when `.specrew/` is created + dependency validation passes, even if `.specify/` initialization failed
- Encoding issue: Not optional workaround; blocks all downstream iteration artifact scaffolding helpers

## Decision

**Distinguish three distinct success states in documentation**:

1. **Dependency Validation Success** (version detection): ✅ Always succeeds if CLIs installed
2. **Bootstrap Completion** (artifact creation): ✅ Creates `.specrew/` + governance; ⚠️ May fail to create `.specify/` or `.squad/` if CLIs error
3. **Greenfield-to-Iteration Flow Success** (full path): ⚠️ Requires dependency validation + CLI initialization + manual Spec Kit init if CLI failed

**Document this truthfully by**:
- Adding prerequisites section: Explicitly state Spec Kit CLI and Squad CLI must be operational
- Making `.specify/` existence a gate: Users must check for it before proceeding to iteration scaffolding
- Reframing Spec Kit encoding issue as a blocker (not optional workaround)
- Providing 5-step resolution path with terminal fallback
- Clearly separating what bootstrap always provides vs. what depends on CLI success

## Rationale

1. **Precision over comfort**: Users hitting the encoding issue deserve to know it's not a workaround scenario—it completely blocks iteration scaffolding.
2. **Traceability to test reality**: The docs now match what the CI integration tests actually validate (full flow requires both CLIs).
3. **No runtime changes needed**: Fix is pure documentation accuracy; all validator and flag fixes remain intact.
4. **Prevents silent failures**: Users won't waste time trying to run downstream scripts on incomplete bootstraps.

## Scope

**In Scope**: `docs/getting-started.md` greenfield and troubleshooting sections  
**Out of Scope**: Runtime code (no changes to `scripts/specrew-init.ps1` or validators)  
**Brownfield Notes**: Brownfield flow unchanged; this addresses only greenfield overclaiming

## Implementation

- ✅ Updated "Greenfield Quickstart" section (lines 40-114): Added prerequisites, conditional gate, step 4 guard
- ✅ Rewrote "Known Limitations" section (lines 178-228): Separated dependency validation from completion; reframed blocker; added resolution path
- ✅ Preserved validator and flag fixes: `validate-versions.ps1` behavior unchanged; `--ai` flag still corrected

## Verification

- ✅ Docs now explicitly state Spec Kit CLI must succeed for `.specify/` creation
- ✅ Docs now gate iteration scaffolding on `.specify/` existence
- ✅ Encoding issue now documented as flow blocker with 5-step resolution
- ✅ Integration tests (`bootstrap-to-iteration.ps1`, `validate-versions-cli-behavior.ps1`) remain unmodified
- ✅ CI workflow validates full greenfield-to-iteration path with both CLIs present

## Next Steps

1. Worf review: Verify docs now match test reality
2. Team review: Confirm truthfulness acceptable for published docs
3. No implementation work: This is doc-only; no runtime changes


## data-iter002-execution-update
# Data: Iteration 002 Execution Lifecycle Correction

**Date**: 2026-05-03
**By**: Data (Planner)
**Status**: Artifact-Safe Corrective Update (Verification Mode)

## Finding

Iteration 002 planning artifacts (plan.md) were still in `planning` status with Started=TBD, but substantial execution work had already commenced:
- FR-019 resume command implementation (resume-iteration.ps1 complete; integration tests present)
- FR-020 brownfield merge implementation (brownfield-merge.ps1 heavily modified; integration tests created)
- T-204, T-205, T-206 actively in development

## 2026-05-13T17:38:24Z — Delegated routing plan

- **Enabled Agents**: copilot
- **Independent Oversight Active**: False
- **Roles**:
  - Implementer | requested=copilot | actual=copilot | model=(platform default) | status=honored | fallback=(none)
  - Spec Steward | requested=codex | actual=copilot | model=(platform default) | status=fell-back | fallback=preferred agent 'codex' is not enabled
  - Planner | requested=claude | actual=copilot | model=(platform default) | status=fell-back | fallback=preferred agent 'claude' is not enabled
  - Reviewer | requested=claude | actual=copilot | model=(platform default) | status=fell-back | fallback=preferred agent 'claude' is not enabled
  - Retro Facilitator | requested=copilot | actual=copilot | model=(platform default) | status=honored | fallback=(none)

## 2026-05-13T17:38:24Z — Routing evidence: Spec Steward

- **Decision ID**: routing-evidence-a60fc7ccbc6e
- **Type**: routing-evidence
- **Affected Requirement**: FR-043
- **Affected Iteration**: (none)
- **Approving Human**: (none)
- **Recorded At**: 2026-05-13T17:38:24Z
- **Next Action**: none
- **Rationale**: Delegated lifecycle routing was applied for role 'Spec Steward'.

- **Routing Evidence**: Spec Steward | requested=codex | actual=copilot | model=(platform default) | status=fell-back | fallback=preferred agent 'codex' is not enabled

## 2026-05-13T17:38:24Z — Routing evidence: Planner

- **Decision ID**: routing-evidence-e8044a0b3c45
- **Type**: routing-evidence
- **Affected Requirement**: FR-043
- **Affected Iteration**: (none)
- **Approving Human**: (none)
- **Recorded At**: 2026-05-13T17:38:24Z
- **Next Action**: none
- **Rationale**: Delegated lifecycle routing was applied for role 'Planner'.

- **Routing Evidence**: Planner | requested=claude | actual=copilot | model=(platform default) | status=fell-back | fallback=preferred agent 'claude' is not enabled

## 2026-05-13T17:38:24Z — Routing evidence: Reviewer

- **Decision ID**: routing-evidence-5b5d7a455d86
- **Type**: routing-evidence
- **Affected Requirement**: FR-043
- **Affected Iteration**: (none)
- **Approving Human**: (none)
- **Recorded At**: 2026-05-13T17:38:24Z
- **Next Action**: none
- **Rationale**: Delegated lifecycle routing was applied for role 'Reviewer'.

- **Routing Evidence**: Reviewer | requested=claude | actual=copilot | model=(platform default) | status=fell-back | fallback=preferred agent 'claude' is not enabled

## 2026-05-16T12:03:53Z — Feature 019 start authorization

- **Decision ID**: feature-019-start-authorization
- **Type**: authorization
- **Boundary**: feature-start
- **Approving Human**: Alon Fliess
- **Recorded At**: 2026-05-16T12:03:53Z
- **Feature**: 019 — Specrew Distribution Module via PowerShell Gallery
- **Source Spec**: `file:///C:/Dev/SpecrewDraft/specrew-distribution-module.md`
- **Public Proposal**: `file:///C:/Dev/Specrew/proposals/031-specrew-distribution-module.md`

### Authorized boundary work

- Branch from `main` at `aac726b` to `019-specrew-distribution-module`
- Update `.specify/feature.json` to point at `specs/019-specrew-distribution-module`
- Push the feature-start boundary commit to `origin/019-specrew-distribution-module`
- Stop after feature-start and wait for explicit authorization before `/speckit.specify`

### Scope lock

- **In scope**: PSGallery module packaging, bundled scripts/templates/extensions/agent assets, `specrew init` bootstrap-from-module refactor, `specrew update` template-refresh story, and Rule 15 publish/version workflow integration
- **Out of scope**: Slash Commands / Proposal 032, winget / Chocolatey / Scoop, signing beyond self-sign for v1, and migration tooling for existing alpha users

### Clarify-time direction to preserve

- Reach human alignment during `/speckit.clarify` on the 10 source-spec questions before planning
- Default recommendations to carry into clarify: PSGallery-only for v1, preserve-and-flag template conflicts, module version mirrors `.specrew/config.yml` `specrew_version`, self-sign for v1, and indefinite clone-and-PATH fallback support

## 2026-05-16T12:28:07Z — Feature 019 specify authorization

- **Decision ID**: feature-019-specify-authorization
- **Type**: authorization
- **Boundary**: /speckit.specify
- **Approving Human**: Alon Fliess
- **Recorded At**: 2026-05-16T12:28:07Z
- **Feature**: 019 — Specrew Distribution Module via PowerShell Gallery
- **Generated Artifact**: `file:///C:/Dev/Specrew/specs/019-specrew-distribution-module/spec.md`

### Authorized boundary work

- Ingest `file:///C:/Dev/SpecrewDraft/specrew-distribution-module.md`
- Generate Draft spec artifact `specs/019-specrew-distribution-module/spec.md`
- Preserve the five pillars, explicit non-goals, and the 10 clarify-time questions
- Stop after `/speckit.specify` and wait for explicit authorization before `/speckit.clarify`

## 2026-05-16T12:28:07Z — Routing evidence: /speckit.specify

- **Decision ID**: routing-evidence-feature-019-specify
- **Type**: routing-evidence
- **Role or Work Item**: /speckit.specify
- **Requested Agent**: speckit.specify
- **Actual Agent**: speckit.specify
- **Model ID**: claude-sonnet-4.5
- **Status**: honored
- **Fallback Reason**: (none)

## 2026-05-15T18:12:42Z — Hardening-gate sign-off: Feature 018

- **Decision ID**: feature-018-hardening-gate-signoff-20260515
- **Type**: sign-off
- **Affected Requirement**: Feature 018 hardening-gate-and-implementation-auth boundary
- **Affected Iteration**: 001
- **Approving Human**: Alon Fliess
- **Recorded At**: 2026-05-15T18:12:42Z
- **Next Action**: Enter `/speckit.specrew-speckit.before-implement` for feature 018 after the pre-implementation review and hardening-gate artifacts are updated.
- **Rationale**: Bundled human authorization granted the hardening-gate sign-off and implementation authorization together for feature 018.
- **Authorization Text**: AUTHORIZE hardening-gate-and-implementation-auth + implementation for Feature 018 (Velocity Dashboard Visual Richness + PoC-Parity Restoration).

## 2026-05-15T18:12:42Z — Implementation authorization: Feature 018

- **Decision ID**: feature-018-implementation-authorization-20260515
- **Type**: authorization
- **Affected Requirement**: Feature 018 implementation boundary
- **Affected Iteration**: 001
- **Approving Human**: Alon Fliess
- **Recorded At**: 2026-05-15T18:12:42Z
- **Next Action**: If `/speckit.specrew-speckit.before-implement` passes, enter `/speckit.implement` for feature 018 and stop at the review-boundary.
- **Rationale**: Bundled human authorization granted the hardening-gate sign-off and implementation authorization together for feature 018.
- **Authorization Text**: AUTHORIZE hardening-gate-and-implementation-auth + implementation for Feature 018 (Velocity Dashboard Visual Richness + PoC-Parity Restoration).

## 2026-05-14T00:00:00Z — Authorization: planning

- **Decision ID**: authorization-feature-016-iter-001-planning
- **Type**: authorization
- **Boundary**: planning
- **Approving Human**: Alon Fliess
- **Recorded At**: 2026-05-14T00:00:00Z
- **Commit Reference**: 0070a74
- **Authorization Text**:
  > Continue to the planning boundary for Feature 016 Substantive Interaction Model Iteration 001.

## 2026-05-14T01:13:53Z — Authorization: hardening-gate-signoff

- **Decision ID**: authorization-feature-016-iter-001-hardening-gate-signoff
- **Type**: sign-off
- **Boundary**: hardening-gate-signoff
- **Approving Human**: Alon Fliess
- **Recorded At**: 2026-05-14T01:13:53Z
- **Commit Reference**: e47da21
- **Authorization Text**:
  > I sign off on the accepted Iteration 001 pre-implementation hardening gate for Feature 016 Substantive Interaction Model. The five concerns drafted at file:///C:/Dev/Specrew/specs/016-substantive-interaction-model/iterations/001/quality/hardening-gate.md
  > (security-surface, error-handling-expectations, retry-idempotency-requirements, test-integrity-targets, operational-resilience-concerns) are appropriate for this coordinator-prompt + validator-extension feature, with specific FR/NFR/Risk traceability and measurable
  > Expected Controls.
  >
  > I authorize implementation of Iteration 001 for Feature 016 against the planned scope: FR-001 through FR-019 (Pillar 1 Boundary Discipline + Pillar 2 Essence in Console + Pillar 3 Click-Through Navigation) per the iteration plan at
  > file:///C:/Dev/Specrew/specs/016-substantive-interaction-model/iterations/001/plan.md and the task breakdown at file:///C:/Dev/Specrew/specs/016-substantive-interaction-model/tasks.md, targeting the ~13 SP capacity.
  >
  > Per FR-008 and FR-009, the auto-generation machinery these introduce is itself the work being built. For THIS authorization specifically, Squad MUST create two distinct entries in file:///C:/Dev/Specrew/.squad/decisions.md by hand, one for hardening-gate sign-off and
  > one for implementation authorization, modeling the shape that FR-008's implementation will produce automatically going forward. Both entries cite this verbatim authorization text and capture the canonical 7 required fields.
  >
  > Step 1: Auto-generate (hand-create) the two distinct decisions.md entries per FR-008 / FR-009. Update the hardening-gate.md verdict from `blocked` to `accepted` (concerns remain `pending-gate-review` until implementation verifies expected controls — that happens at
  > review boundary, not now). Stage these as part of the hardening-gate-and-implementation-auth boundary commit.
  >
  > Step 2: Cut the hardening-gate-and-implementation-auth boundary commit on 016-substantive-interaction-model branch. Push.
  >
  > Step 3: Proceed with implementation work against the task table. Per the source spec NFR-006 (backward compat), grandfathering for pre-Feature-016 iterations applies. Per NFR-002, coordinator-prompt additions stay under 150 new lines. Per NFR-001, validator
  > performance budgets apply.
  >
  > Step 4: Implementation MUST progress through tasks.md in dependency order. When implementation is complete for the authorized FR scope, cut the implementation boundary commit (canonical subject pattern: `Feature 016 substantive-interaction-model iteration 001:
  > implement` or `Feature 016 substantive-interaction-model iteration 001: bounded T001-TNNN scope`). Push.
  >
  > Step 5: STOP at the implementation boundary commit. Do NOT advance to review work — that requires separate authorization. Present a substantive three-section boundary handoff per Pillar 2 modeling the discipline being shipped:
  >   - What I just did: enumerate the FR coverage delivered, commit hashes for hardening-gate-and-implementation-auth + implementation, specific file:/// paths for new validator rules + coordinator-prompt updates, test coverage status, baseline-vs-actual measurements
  > against NFR-001/NFR-002 budgets
  >   - Why I stopped: name the review boundary as next; explain that the review boundary requires separate authorization per per-boundary discipline (FR-002/FR-003)
  >   - What I need from you: specific review of the implementation against the hardening-gate concerns' Expected Controls, plus authorization to advance to review boundary
  >
  > Step 6: Do NOT touch the working-tree out-of-scope files (.claude/settings.local.json, scripts/specrew-where.ps1, subagent history). They remain unstaged. Do NOT modify SpecrewDraft or SpecrewManualTestProjects folders.
  >
  > Step 7: If implementation reveals that any FR cannot be delivered within the authorized scope, do NOT silently defer — surface the deferral, name the FR, name the reason, and ask for explicit deferral approval per Specrew's deferral discipline. Implementation scope
  > locks are real; scope expansion requires authorization.

## 2026-05-14T01:13:53Z — Authorization: implementation

- **Decision ID**: authorization-feature-016-iter-001-implementation
- **Type**: authorization
- **Boundary**: implementation
- **Approving Human**: Alon Fliess
- **Recorded At**: 2026-05-14T01:13:53Z
- **Commit Reference**: ed8dea9
- **Authorization Text**:
  > I sign off on the accepted Iteration 001 pre-implementation hardening gate for Feature 016 Substantive Interaction Model. The five concerns drafted at file:///C:/Dev/Specrew/specs/016-substantive-interaction-model/iterations/001/quality/hardening-gate.md
  > (security-surface, error-handling-expectations, retry-idempotency-requirements, test-integrity-targets, operational-resilience-concerns) are appropriate for this coordinator-prompt + validator-extension feature, with specific FR/NFR/Risk traceability and measurable
  > Expected Controls.
  >
  > I authorize implementation of Iteration 001 for Feature 016 against the planned scope: FR-001 through FR-019 (Pillar 1 Boundary Discipline + Pillar 2 Essence in Console + Pillar 3 Click-Through Navigation) per the iteration plan at
  > file:///C:/Dev/Specrew/specs/016-substantive-interaction-model/iterations/001/plan.md and the task breakdown at file:///C:/Dev/Specrew/specs/016-substantive-interaction-model/tasks.md, targeting the ~13 SP capacity.
  >
  > Per FR-008 and FR-009, the auto-generation machinery these introduce is itself the work being built. For THIS authorization specifically, Squad MUST create two distinct entries in file:///C:/Dev/Specrew/.squad/decisions.md by hand, one for hardening-gate sign-off and
  > one for implementation authorization, modeling the shape that FR-008's implementation will produce automatically going forward. Both entries cite this verbatim authorization text and capture the canonical 7 required fields.
  >
  > Step 1: Auto-generate (hand-create) the two distinct decisions.md entries per FR-008 / FR-009. Update the hardening-gate.md verdict from `blocked` to `accepted` (concerns remain `pending-gate-review` until implementation verifies expected controls — that happens at
  > review boundary, not now). Stage these as part of the hardening-gate-and-implementation-auth boundary commit.
  >
  > Step 2: Cut the hardening-gate-and-implementation-auth boundary commit on 016-substantive-interaction-model branch. Push.
  >
  > Step 3: Proceed with implementation work against the task table. Per the source spec NFR-006 (backward compat), grandfathering for pre-Feature-016 iterations applies. Per NFR-002, coordinator-prompt additions stay under 150 new lines. Per NFR-001, validator
  > performance budgets apply.
  >
  > Step 4: Implementation MUST progress through tasks.md in dependency order. When implementation is complete for the authorized FR scope, cut the implementation boundary commit (canonical subject pattern: `Feature 016 substantive-interaction-model iteration 001:
  > implement` or `Feature 016 substantive-interaction-model iteration 001: bounded T001-TNNN scope`). Push.
  >
  > Step 5: STOP at the implementation boundary commit. Do NOT advance to review work — that requires separate authorization. Present a substantive three-section boundary handoff per Pillar 2 modeling the discipline being shipped:
  >   - What I just did: enumerate the FR coverage delivered, commit hashes for hardening-gate-and-implementation-auth + implementation, specific file:/// paths for new validator rules + coordinator-prompt updates, test coverage status, baseline-vs-actual measurements
  > against NFR-001/NFR-002 budgets
  >   - Why I stopped: name the review boundary as next; explain that the review boundary requires separate authorization per per-boundary discipline (FR-002/FR-003)
  >   - What I need from you: specific review of the implementation against the hardening-gate concerns' Expected Controls, plus authorization to advance to review boundary
  >
  > Step 6: Do NOT touch the working-tree out-of-scope files (.claude/settings.local.json, scripts/specrew-where.ps1, subagent history). They remain unstaged. Do NOT modify SpecrewDraft or SpecrewManualTestProjects folders.
  >
  > Step 7: If implementation reveals that any FR cannot be delivered within the authorized scope, do NOT silently defer — surface the deferral, name the FR, name the reason, and ask for explicit deferral approval per Specrew's deferral discipline. Implementation scope
  > locks are real; scope expansion requires authorization.

## 2026-05-14T01:54:55Z — Routing evidence: Implementer

- **Decision ID**: routing-evidence-feature-016-iter-001-implementation
- **Type**: routing-evidence
- **Scope**: feature-016-iteration-001-implementation
- **Requested Agent**: Implementer
- **Actual Agent**: general-purpose
- **Model**: gpt-5.4
- **Status**: completed
- **Routing Evidence**: Implementer | requested=general-purpose | actual=general-purpose | model=gpt-5.4 | status=completed

## 2026-05-14T02:48:00Z — Authorization: review-boundary

- **Decision ID**: authorization-feature-016-iter-001-review-boundary
- **Type**: authorization
- **Boundary**: review-boundary
- **Approving Human**: Alon Fliess
- **Recorded At**: 2026-05-14T02:48:00Z
- **Commit Reference**: 7ddb7db
- **Authorization Text**:
  > Review the completed Feature 016 Substantive Interaction Model Iteration 001 implementation against the hardening-gate concerns and the authorized FR-001 through FR-019 scope. Verify that the bundled-boundary detection works as expected, that the validator rules are correct, and that the coordinator guidance is clear and actionable. If the implementation meets the acceptance criteria, record an accepted verdict in `file:///C:/Dev/Specrew/specs/016-substantive-interaction-model/iterations/001/review.md`. If issues are found, document them with specific remediation guidance and mark the verdict as needs-work.

---

## 2026-05-14T08:10:00Z — Authorization: implementation (validator-logic repair pass)

- **Decision ID**: authorization-feature-016-iter-001-implementation-repair
- **Type**: authorization
- **Boundary**: implementation
- **Approving Human**: Alon Fliess
- **Recorded At**: 2026-05-14T08:10:00Z
- **Commit Reference**: 37822b6
- **Authorization Text**:
  > Repair package validator output reveals two validator-logic design defects (not bookkeeping defects). Authorizing a deeper validator-logic repair as continuation of Iteration 1 implementation work, in scope per FR-006/FR-008/FR-009.
  >
  > Keep the bookkeeping fixes Implementer already applied to .squad\decisions.md (Commit Reference update + new review-boundary entry). The new work refines the validator logic so the bookkeeping pattern actually validates clean.
  >
  > The two validator-logic defects are:
  > 1. The paired-authorization lookup mistakenly compares recorded commit hashes as STRINGS rather than querying git ancestry/merge-base. Result: legitimate paired authorization entries are rejected because `37822b6` (short) ≠ `37822b6b7e1e1513e5fcc33438515d5edc5d1843` (full) even though they refer to the same commit object.
  > 2. The canonical boundary-subject regex overmatches hyphenated/underscored continuations of canonical tokens. Example: `Feature 016 ... iteration 001: implementation-repair refactor ...` incorrectly matches `^Feature \d+.* iteration \d+: implement` because the pattern lacks token termination, causing `implementation-repair` to appear as a bundled advance even though it's just descriptive narration.
  >
  > Repair scope:
  > - Harden all canonical boundary-subject patterns with consistent token terminators (word boundaries or explicit space/end-of-string anchors) to prevent the same bug class across all seven per-iteration boundaries plus feature-closeout.
  > - Fix paired-auth detection so commit-reference lookup uses git-native object identity (full hash normalization or merge-base ancestry) rather than naive string equality.
  > - Update `tests\integration\substantive-interaction-model-boundary-discipline-test.ps1` to add positive/negative regex classification coverage for the four tightening cases: `implement T001-T015` (✅), `implementation T001-T020` (✅), `implementation-repair refactor` (❌), `implementation_continuation` (❌).
  > - Preserve all existing test coverage and keep repo-wide validation green across the full 8-item validation lane.
  >
  > This authorization covers the validator-logic refinements only; it does NOT authorize any new Feature 016 scope expansion, any retrospective or closeout work, or any change outside the validator/test surfaces needed to harden boundary detection and paired-auth matching.

---
## 2026-05-14T09:26:39Z — Authorization: review-verdict-signoff

- **Decision ID**: authorization-feature-016-iter-001-review-verdict-signoff
- **Type**: sign-off
- **Boundary**: review-verdict-signoff
- **Approving Human**: Alon Fliess
- **Recorded At**: 2026-05-14T09:26:39Z
- **Commit Reference**: 58e3ed0
- **Authorization Text**:
  > I provide explicit review-verdict-signoff for Feature 016 Iteration 001 following independent post-commit validator verification I performed on HEAD 59f1b21.
  >
  > Verification performed:
  > - Ran `pwsh -NoProfile -ExecutionPolicy Bypass -File .\extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath .` on HEAD 59f1b21 → PASS (no bundled-boundary-advance failures, no paired-authorization false positives)
  > - Verified the regex tightening in shared-governance.ps1 lines 343-350 correctly adds word-boundary anchors to all eight canonical boundary patterns (planning, hardening-gate-signoff, implementation, review-boundary, review-verdict-signoff, retro, iteration-closeout, feature-closeout) and the mirror in .specify is correct
  > - Confirmed the authorization entry for 37822b6 exists in .squad\decisions.md with all seven canonical fields and populated Commit Reference
  > - Reviewed the re-recorded NFR-001 evidence in quickstart.md showing baseline 109134 ms → actual 122646 ms (+12.4%, within the +15% tolerance)
  >
  > NFR-001 acceptance: The +37.5% final-tree runtime (baseline 109134 ms → actual 150007 ms per Reviewer's independent measurement) is approved with the following documented rationale:
  > - The +37.5% delta reflects overhead from the new boundary-discipline and handoff-governance validators (FR-006 through FR-019) plus short-hash normalization and Commit-Reference authorization matching
  > - The pre-refactor baseline was measured on a tree without any boundary-discipline checking; the new measurement is against the full governed surface including seven per-iteration boundaries plus feature-closeout
  > - The performance budget tightening is deferred to Feature N optimization work (slot TBD); the current runtime remains acceptable for the governance-only use case where validator execution happens once per boundary rather than in a hot loop
  > - The +37.5% increase does not block feature acceptance because the validator still completes in reasonable time for manual governance workflows
  >
  > Reviewer Regression Event acknowledgement: I acknowledge the initial review boundary was opened prematurely on 2026-05-14 against commit ed8dea9 with a needs-work verdict due to bundled-boundary false positives and non-reproducible NFR-001 evidence. The implementation-repair authorization I provided on 2026-05-14T08:10:00Z (commit 37822b6) addressed the validator-logic defects, and the subsequent regex-hardening commit 59f1b21 resolved the remaining boundary-pattern overmatch issue. This review-verdict-signoff is based on independent human verifier validation against the repaired tree (59f1b21), not on automated Reviewer output alone.
  >
  > Retro corpus-row candidates identified during Feature 016 execution:
  > 1. `fr-008-pending-commit-reference-vs-validator-hash-match` — Authorization entries with Commit Reference: pending must be updated to the actual boundary commit hash before bundled-boundary-advance validation will accept them; the validator does not treat "pending" as a wildcard match (governance-discipline, passive guidance).
  > 2. `nfr-budget-calibrated-against-pre-refactor-baseline` — When measuring runtime performance budgets for new validation rules, capture the pre-refactor baseline measurement on a tree without the new rules; otherwise the "actual vs baseline" comparison may conflate governance overhead with other unrelated changes (measurement-discipline, passive guidance).
  >
  > This authorization covers review-verdict-signoff only and does NOT authorize retrospective, iteration closeout, or any other lifecycle boundary beyond this point.

## 2026-05-14T10:13:30Z — Authorization: retro-boundary

- **Decision ID**: authorization-feature-016-iter-001-retro-boundary
- **Type**: authorization
- **Boundary**: retro-boundary
- **Approving Human**: Alon Fliess
- **Recorded At**: 2026-05-14T10:13:30Z
- **Commit Reference**: 9f2778e
- **Authorization Text**:
  > I authorize the retro-boundary for Feature 016 Iteration 001. Retro Facilitator has performed independent post-commit validator verification on HEAD 1db47c3 and confirms:
  >
  > - `pwsh -NoProfile -ExecutionPolicy Bypass -File .\extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath .` → PASS on HEAD 1db47c3 (no validation errors, no bundled-boundary-advance failures)
  >
  > Retro Facilitator is authorized to draft retro.md capturing substantive lessons learned during Iteration 001 execution, including:
  > - Calibration data: planned vs. actual effort and velocity
  > - Substantive lessons: bundled-boundary commit matching discipline, regex anchoring requirements, authorization-entry timestamp/hash synchronization, validator scope bounding, and NFR measurement baseline discipline
  > - Six named corpus-row candidates from iteration execution (documented in retro.md): fr-008-pending-commit-reference-vs-validator-hash-match, nfr-budget-calibrated-against-pre-refactor-baseline, regex-boundary-patterns-require-anchoring, validator-idempotency-requires-immutable-data-sources, authorization-text-capture-preserves-human-intent-without-leakage, single-boundary-authorization-discipline-prevents-creeping-scope
  > - Process learnings: repair escalation pathways, pre-commit verification gates, authorization-entry synchronization requirements, spec authority discipline, hardening-repair-verdict sequence
  > - Estimation learnings and accuracy analysis
  > - Deferral items and positive learnings documentation
  >
  > Retro Facilitator is authorized to add additional corpus-row candidates to retro.md if clearly warranted by iteration-execution evidence, beyond the six required candidates.
  >
  > This authorization covers retro-boundary work only. Iteration closeout remains a separate authorization boundary.

## 2026-05-14T11:27:03Z — Authorization: iteration-closeout

- **Decision ID**: authorization-feature-016-iter-001-iteration-closeout
- **Type**: authorization
- **Boundary**: iteration-closeout
- **Approving Human**: Alon Fliess
- **Recorded At**: 2026-05-14T11:27:03Z
- **Commit Reference**: aa01752
- **Authorization Text**:
  > I authorize the iteration-closeout boundary for Feature 016 Iteration 001.
  >
  > **Deliverables Summary**: 
  > - FR-001 through FR-019 delivered and accepted via review-verdict-signoff on 2026-05-14
  > - Six named corpus-row candidates identified during iteration execution: fr-008-pending-commit-reference-vs-validator-hash-match, nfr-budget-calibrated-against-pre-refactor-baseline, regex-boundary-patterns-require-anchoring, validator-idempotency-requires-immutable-data-sources, authorization-text-capture-preserves-human-intent-without-leakage, single-boundary-authorization-discipline-prevents-creeping-scope
  > - Three estimation learnings recorded in retro.md: effort-calibration stable at 13.0 points, velocity sustainable at 13.0 points per iteration, quality shock-absorber recommendation of 5-10 point reserve for discovery-time defects
  >
  > **Iteration Completion State**: 
  > - All authorized implementation tasks T001-T008, T011-T013, T018-T020 complete with accepted review verdict (post-repair)
  > - Retrospective boundary completed on 2026-05-14T10:13:30Z with substantive lessons and corpus-row candidates recorded in retro.md
  > - NFR-001 +37.5% delta accepted with documented performance rationale; performance optimization deferred to future optimization work
  >
  > **Scope Clarity for Iteration 2**: 
  > - Iteration 2 FR-020 through FR-024 remains separately authorized
  > - No portion of Iteration 1 scope carries over pending
  > - Carryover items for post-commit automation planning: pending→post-commit automation, validator performance optimization, fractional-second timestamp support or format requirement, post-commit verification formalization, stale-reference scan mandate

---
# Reviewer Decision: Feature 015 Iteration 002 Review

**Date**: 2026-05-13
**By**: Reviewer
**Type**: review-boundary

## Decision

Accept the review boundary for feature `015`, public-readiness pass, iteration `002`.

## Why It Matters

- The release-truth surfaces now align on one public shipped baseline: `.specrew\config.yml`, `README.md`, `docs\versioning.md`, `CHANGELOG.md`, `specs\001-specrew-product\spec.md`, and the annotated `v0.14.0` tag all point to `0.14.0`.
- Rule `15`, feature closeout version management, is now explicit across the coordinator surfaces: config bump, changelog entry, README/versioning refresh, release-tag creation, validator rerun, and a keep-open defer path.
- The new public-readiness validator lane stayed additive under independent review: clean fixture pass without warnings, drift fixture pass with the expected warnings, pre-Feature `015` iteration pass unchanged, repo-wide validator green, and local plus `origin` tag anchors verified as `v0.13.0 -> 21d9e7f` and `v0.14.0 -> 3ff32d4`.

---

# Retro Facilitator Decision: Feature 017 Iteration 001 Retrospective

**Date**: 2026-05-16  
**By**: Retro Facilitator (delegated agent)  
**Type**: retro-boundary  
**Commit Reference**: TBD (to be recorded at commit time)

## Authorization

Explicit human authorization provided by Alon Fliess (user input): "The user has explicitly authorized exactly one boundary advance: from review-verdict-signoff to retro-boundary for Feature 017 Iteration 001."

## Decision

Facilitate and complete the retrospective for Feature 017 (Velocity Dashboard), Iteration 001, advancing from review-verdict-signoff to retro-boundary.

## What Was Completed

1. **Retro artifact created**: `specs/017-velocity-dashboard/iterations/001/retro.md`
   - Schema: v1, four-section format (Eight Substantive Lessons, Summary of New Corpus-Row Candidates, Updated Squad Decisions, Updated Identity/Now State)
   - Eight substantive lessons documented with sources, implications, and evidence links:
     1. Estimation variance: 11 SP planned → 17-19 SP actual (clarify gap + external review)
     2. Mid-implementation reboot resilience: uncommitted work survived, stale session state misdirected parallel session
     3. External pre-implementation review pattern: 16 findings across 3 severity tiers
     4. Architectural pillar features surfaced: Lifecycle Branch Reconciliation + Session-State Durability
     5. Corpus-row self-enforcement: essence-vs-exhaustive principle now implicit team expectation
     6. F-016 machinery validation: boundary discipline held across all 8 lifecycle boundaries
     7. Iteration 002 carryover: FR-042..FR-046 + FR-019..FR-033 remain scope; ~16-18 SP total
     8. Bundled multi-boundary authorization pattern: clarify→plan→tasks bundled under single authorization, but implementation/review/retro remain separate


2. **Corpus-row candidates identified**: Three candidates proposed for `.specrew/quality/known-traps.md`:
   - Bundled planning-phase boundary authorization (permissible variant of one-boundary-at-a-time rule)
   - Essence-vs-exhaustive corpus row self-enforcement (positive observation; no rule change needed)
   - Pre-implementation external review for specification integrity (coordination pattern)

3. **Squad decisions updated**: This decision record captures the retrospective authorization and runtime evidence.

---

## 2026-05-16T00:00:00Z — Authorization: iteration-closeout

- **Decision ID**: authorization-feature-017-iter-001-iteration-closeout
- **Type**: authorization
- **Boundary**: iteration-closeout
- **Approving Human**: Alon Fliess
- **Recorded At**: 2026-05-16T00:00:00Z
- **Commit Reference**: (recorded by closeout boundary commit)
- **Authorization Text**:
   > Feature 017 Iteration 001 retrospective complete with 8 substantive lessons captured. Iteration-closeout is explicitly authorized. Advance from retro-boundary to iteration-closeout: create `iterations/001/state.md` with delivered SP metrics (~18 SP actual vs. 11 SP planned, +7 SP variance from external-review repair cycle), update `.squad/decisions.md` with this authorization entry, update `.squad/identity/now.md` to reflect Iteration 001 closed and Iteration 002 pending authorization, verify `iterations/002/deferrals.md`, and create the iteration-closeout boundary commit.
   > Iteration 002 scope is fully specified in plan.md + tasks.md (FR-019..FR-033 plus FR-042..FR-046, ~16-18 SP). Next valid boundary: hardening-gate-and-implementation-auth for Iteration 002 (when explicitly authorized).

4. **Identity/now state prepared**: Update pending (separate batch commit).

## Why It Matters

Feature 017 Iteration 001 completed a full lifecycle (specify → clarify → plan → tasks → implementation → review-boundary → review-verdict-signoff → retro-boundary) while surfacing two new pillar features (Session-State Durability, Branch Reconciliation) required for Phase 2 adoption. The retrospective documents lessons from a complex real-world feature with external review, repair cycles, and multi-tier findings.

## Evidence

- `specs/017-velocity-dashboard/iterations/001/retro.md` (this boundary artifact)
- `specs/017-velocity-dashboard/iterations/001/review.md` (prior boundary)
- `specs/017-velocity-dashboard/clarify-residual-findings.md` (16 findings, 3 tiers)
- `C:\Dev\SpecrewDraft\session-state-durability.md` (pillar feature motivation)
- `C:\Dev\SpecrewDraft\branch-reconciliation.md` (pillar feature motivation)
- Repo validator runs confirm no governance regressions

## Next Action

Request explicit iteration-closeout authorization before the iteration-closeout boundary may proceed. Do NOT open iteration-closeout, feature-closeout, or any later boundary from this retro state alone.

## Evidence

- `specs\015-public-readiness-pass\iterations\002\review.md`
- `specs\015-public-readiness-pass\iterations\002\plan.md`
- `specs\015-public-readiness-pass\iterations\002\state.md`
- `extensions\specrew-speckit\scripts\validate-governance.ps1`
- `tests\unit\validate-governance.public-readiness.tests.ps1`
- `docs\versioning.md`
- `CHANGELOG.md`

## Next Action

Await Alon Fliess's separate authorization before opening retrospective or closeout work for feature `015`, iteration `002`.


# Runtime Evidence: Feature 015 post-closeout corpus-row addition

**Date**: 2026-05-14  
**Role / Work Item**: Implementer — Feature 015 post-closeout corpus-row addition  
**Requested Agent**: copilot  
**Actual Agent**: copilot  
**Model ID**: claude-haiku-4.5  
**Status**: honored  
**Fallback Reason**: none

Repair spawn authorized to add three passive-guidance rows from Rule 15's first real-world test to `.specrew\quality\known-traps.md`, then validate, commit, and push on `main`.

## 2026-05-14T06:14:15Z — Delegated routing plan

- **Enabled Agents**: copilot
- **Independent Oversight Active**: False
- **Roles**:
  - Implementer | requested=copilot | actual=copilot | model=(platform default) | status=honored | fallback=(none)
  - Spec Steward | requested=codex | actual=copilot | model=(platform default) | status=fell-back | fallback=preferred agent 'codex' is not enabled
  - Planner | requested=claude | actual=copilot | model=(platform default) | status=fell-back | fallback=preferred agent 'claude' is not enabled
  - Reviewer | requested=claude | actual=copilot | model=(platform default) | status=fell-back | fallback=preferred agent 'claude' is not enabled
  - Retro Facilitator | requested=copilot | actual=copilot | model=(platform default) | status=honored | fallback=(none)

## 2026-05-14T06:14:15Z — Routing evidence: Spec Steward

- **Decision ID**: routing-evidence-b351b5ff3003
- **Type**: routing-evidence
- **Affected Requirement**: FR-043
- **Affected Iteration**: (none)
- **Approving Human**: (none)
- **Recorded At**: 2026-05-14T06:14:15Z
- **Next Action**: none
- **Rationale**: Delegated lifecycle routing was applied for role 'Spec Steward'.

- **Routing Evidence**: Spec Steward | requested=codex | actual=copilot | model=(platform default) | status=fell-back | fallback=preferred agent 'codex' is not enabled

## 2026-05-14T06:14:15Z — Routing evidence: Planner

- **Decision ID**: routing-evidence-736f371fbe63
- **Type**: routing-evidence
- **Affected Requirement**: FR-043
- **Affected Iteration**: (none)
- **Approving Human**: (none)
- **Recorded At**: 2026-05-14T06:14:15Z
- **Next Action**: none
- **Rationale**: Delegated lifecycle routing was applied for role 'Planner'.

- **Routing Evidence**: Planner | requested=claude | actual=copilot | model=(platform default) | status=fell-back | fallback=preferred agent 'claude' is not enabled

## 2026-05-14T06:14:15Z — Routing evidence: Reviewer

- **Decision ID**: routing-evidence-a97dfff5eea0
- **Type**: routing-evidence
- **Affected Requirement**: FR-043
- **Affected Iteration**: (none)
- **Approving Human**: (none)
- **Recorded At**: 2026-05-14T06:14:15Z
- **Next Action**: none
- **Rationale**: Delegated lifecycle routing was applied for role 'Reviewer'.

- **Routing Evidence**: Reviewer | requested=claude | actual=copilot | model=(platform default) | status=fell-back | fallback=preferred agent 'claude' is not enabled

---

# Feature 015 Closeout Execution: Rule 15 Version Management

**Date**: 2026-05-13  
**By**: Implementer  
**Authority**: User directive to close Feature 015 per Rule 15 (Formal Spec-Kit + Specrew Lifecycle)  
**Decision Type**: feature-closeout-version-management

## Decision

Feature 015 (public-readiness-pass) is now completely closed and shipped to main with all Rule 15 version-management requirements executed:

### Actions Completed

1. **Feature Status Updates**
   - `specs/015-public-readiness-pass/spec.md`: Status updated from Draft to Complete
   - `specs/015-public-readiness-pass/plan.md`: Feature completion status documented (lines 263+)
   - `.specify/feature.json`: Active feature directory cleared to empty string

2. **Version Management (Rule 15 Core)**
   - `.specrew/config.yml`: Version bumped from 0.14.0 to 0.15.0
   - `CHANGELOG.md`: Feature 015 entry added for v0.15.0 release
   - `README.md`: All versioning references refreshed to 0.15.0 (4 locations)
   - Release tag: Annotated `v0.15.0` created at merge commit 08ed5ca and pushed to origin/

3. **Governance Closure**
   - `.squad/identity/now.md`: Updated to reflect no active feature and Feature 015 complete
   - `validate-governance.ps1`: Rerun after version/changelog/tag updates — all 32 specs PASS
   - Feature-closeout boundary commit: 13c4409 created with full Artifacts/Verification/Outstanding-findings/Next-action sections

4. **Release Integration**
   - PR #116 created with shipped-capability summary citing Iteration 001 and 002 review/retro artifacts
   - Self-review approval posted citing all Rule 15 execution verification
   - PR merged to main via `--merge` (not squash, not rebase) at commit 08ed5ca
   - Release tag v0.15.0 anchors the Feature 015 closeout at main merge commit

## Verification

✅ All Rule 15 requirements satisfied:
- Authoritative version updated in `.specrew/config.yml` (0.14.0 → 0.15.0)
- CHANGELOG.md entry created for Feature 015 release
- README version summary and reference tags refreshed
- Release tag v0.15.0 created and pushed (anchors shipped work)
- `validate-governance.ps1` rerun and passed after version/changelog/tag updates

✅ Feature closure state:
- Feature 015 spec status: Complete
- Feature 015 plan: completion documented
- Active feature: cleared from .specify/feature.json
- Squad identity: updated to no active feature
- Implementer history: learnings appended for future feature closeouts

## Impact

Feature 015 (public-readiness-pass) is now a closed and shipped feature on main. Version 0.15.0 is the canonical public-readiness baseline. All 15 shipped features (001–015) are now reflected in version tracking, changelog, and release tags.

The feature-closeout version-management pattern (Rule 15) is now proven in real-world execution and available as a reference for the next feature closeout.

## Next Action

No active feature. Future work requires a new feature specification request and Spec Kit intake via `speckit.specify`.

The v0.15.0 release tag is durable on origin and serves as a public bookmark for the public-readiness-pass completion milestone.


---

# Implementation Decision: Rule 15 Corpus-Row Addition

**Date:** 2026-05-14  
**Agent:** Implementer  
**Scope:** Feature 015 post-closeout corpus-row addition from Rule 15 first real-world test  

## Decision

Add three new passive-guidance rows to `.specrew/quality/known-traps.md` capturing defect patterns discovered during Feature 015 closeout execution on 2026-05-14.

## Rationale

Rule 15 (Feature Closeout) specified a forward-only execution pattern with three verifiable milestones:
1. Version bump (config, CHANGELOG, README, tags)
2. Boundary commit on main (merged PR with cleanup)
3. Release tag creation and push

During Feature 015 closeout, three real-world execution observations emerged:
- **Cosmetic-fix authorization boundary**: Squad offered surface-truth corrections (typos, stale examples, placeholder substitution) without pausing for human re-authorization; clarification needed on which cosmetic fixes require pause-and-ask vs auto-correct.
- **Template-substitution failure**: Literal `{merge_commit_hash}` placeholder remained in `.squad/identity/now.md` after substitution failed silently; detection and remediation path needed.
- **Stale-example wording**: Documentation (docs/versioning.md, plan.md) retained old version numbers and Feature 014 references after v0.15.0 bump; documentation-example refresh pass needed.

These three patterns are now reusable corpus knowledge for future feature closeouts and for Feature N Learning Loop Closure planning (Phase 2 slot 2.4).

## Implementation Approach

1. **Classification**: All three rows tagged as `passive guidance` (not validator-enforced in Phase 1).
2. **Cross-references**: Each row cites:
   - Canonical strategy record: `C:/Users/alon.HOME/.claude/projects/C--Dev-Specrew/memory/project_rule_15_first_real_world_test_2026_05_14.md`
   - Planned graduation: Feature N Learning Loop Closure (Phase 2 slot 2.4) per consolidated development plan
   - Originating commits: 13c4409 (feature-closeout), 08ed5ca (merge), 6174217 (truth-surface repair), 77db7ce (bookkeeping)
3. **Commit discipline**: High-rigor commit message with Artifacts/Verification/Outstanding-findings/Next-action sections; Co-authored-by trailer included; no history rewrites.
4. **Validation**: `validate-governance.ps1` passed clean at commit 4b2db8f after corpus-row addition.

## Outcomes

- **Artifacts**: `.specrew/quality/known-traps.md` extended with rows 24, 25, 26 (auto-correct-cosmetic-vs-pause-and-ask, template-substitution-failure-on-closeout, stale-example-wording-on-version-bump)
- **History**: `.squad/agents/implementer/history.md` appended with learning note dated 2026-05-14
- **Forward-only preservation**: No commits rewritten; new commit 4b2db8f merged to main; push confirmed at origin
- **Governance status**: All validations passed; Feature 015 corpus work complete; no active feature

## Next Steps

Feature 016 (Substantive Interaction Model) requires separate authorization.


---

---
decision_date: 2026-05-13T22:00:00Z
decision_type: planning-metadata-pattern
affected_feature: Feature 016 — Substantive Interaction Model
status: recorded
---

# Planning Decision: Ownership Rationale Metadata for Feature 016

## Decision Summary

Added an "Ownership Rationale" section to `specs/016-substantive-interaction-model/tasks.md` to explicitly document which owner roles implement which functional requirements (FRs) from the authoritative specification.

## Rationale

The Traceability Governance directive requires that all tasks have complete metadata, including explicit mapping of `task_id → requirement_ref`. Feature 016's tasks.md had owner role assignments but lacked explicit documentation linking those roles back to their governing FRs in the spec.

This visibility gap made it difficult for reviewers and implementers to:
1. Verify that ownership assignments are justified by spec authority (not arbitrary)
2. Trace ownership decisions back to the original FR definitions when auditing task assignments
3. Understand the scope boundaries for each owner role without reading individual task traces

## What Changed

Added a new "Ownership Rationale" section (lines 18–26) that maps each owner role to the FRs it implements:

- **Governance steward**: FR-001–FR-005, FR-008, FR-009, FR-010, FR-014, FR-015
- **Validator steward**: FR-006, FR-007, FR-011–FR-013, FR-016–FR-019
- **Quality steward**: FR-020, FR-021, T001, T025
- **Documentation steward**: FR-022, FR-023
- **Iteration facilitator**: T002, T026

Each role includes a concise description of responsibilities tied to the implementing FRs.

## Impact

- **Traceability**: Task ownership is now explicitly auditable against spec.md FR owner assignments (spec.md lines 137–169)
- **Clarity**: New readers can immediately understand why a specific owner is assigned to a task without inferring from individual task traces
- **Precedent**: This pattern can be reused for future features to make ownership metadata structurally explicit from planning phase forward

## Boundary

This decision is **metadata-scoping only**; it does not change:
- Task IDs, effort estimates, or dependencies
- The approved two-iteration split or task count
- Implementation scope or success criteria
- Any artifact creation or iteration scaffolding

## Scope for Future Features

Teams implementing future features should consider including Ownership Rationale sections in tasks.md as standard planning metadata when owner role assignments are explicitly stated in the spec.

---

**Co-authored-by**: Copilot <223556219+Copilot@users.noreply.github.com>


---

---
decision_date: 2026-05-14T09:30:00Z
decision_type: review-boundary-finding
affected_feature: Feature 016 — Substantive Interaction Model
status: recorded
---

# Review Decision: Feature 016 Iteration 001 Needs-Work Boundary

## Decision Summary

The Feature 016 Iteration 001 review boundary is **needs-work**, not accepted.

## Why This Matters

The implementation commit `ed8dea9` passes the new Feature 016 replay tests, but the repo-wide validator lane still fails on the feature's own canonical history. Specifically, `validate-governance.ps1 -ProjectPath .` reports `bundled-boundary-advance` between the hardening-gate-and-implementation-auth commit `e47da21` and the implementation commit `ed8dea9` even though `.squad/decisions.md` contains the canonical paired implementation authorization entry.

That defect also invalidates the `quickstart.md` claim that the final repo-validator run passed at `113070 ms`. The timing block is committed in `ed8dea9`, but the same command no longer passes on that tree, so the evidence is not trustworthy final-tree proof.

## Team-Relevant Takeaway

For future boundary-discipline reviews, do not accept a claimed final-tree timing or green validator lane until the exact repo-wide command is rerun successfully on the committed implementation tree. Canonical paired authorization entries also need runtime validation against real commit chronology, not just schema-shape inspection.

## Scope Note

This decision does **not** change the verified clean areas from the same review:

- boundary-inference schema-drift fix
- FR-016 parameterized severity rollover shape
- canonical seven-field paired decisions entries
- the two new integration tests using the real validator surface

---

**Co-authored-by**: Copilot <223556219+Copilot@users.noreply.github.com>


---

# Retrospective Decisions: Feature 015 Iteration 002

**From**: Retro Facilitator  
**Date**: 2026-05-13  
**Feature**: 015 — Public-Readiness Pass  
**Iteration**: 002  
**Status**: pending team review  

---

## Decision 1: Boundary-Claim-Without-Commit Enforcement Rule

**Context**: Five recurrences of a pattern where lifecycle boundaries (review, retro, closeout) are narrated as complete in commit messages while the matching durable artifacts (retro.md, closeout.md) do not yet exist. This creates gaps in git history where a boundary appears closed but the iteration is logically incomplete.

**Instances Documented**:

- Feature 014 Iteration 001: commit `8e99013` (review) claims boundary before `a5fcb90` (retro) exists
- Feature 015 Iteration 001: commit `6ca218f` (review) claims boundary before retro created
- Feature 015 Iteration 002 Scribe Variants: commits `2e95c74`, `9c46b30`, `bbaba3d` narrate administrative state while retro.md pending separate authorization

**Recommended Action**:

Add a boundary-subject enforcement rule to `.specrew\quality\known-traps.md`:

> A lifecycle boundary commit must be validated by pre-push gates:
>
> 1. **Boundary-claim commits** (subjects containing "boundary", "review boundary", "implementation boundary", "retro boundary", "closeout boundary") must reference matching artifacts (plan.md / state.md / review.md / retro.md / closeout.md) updated with timestamps matching the commit date ± 5 minutes.
> 2. **No future-phase artifacts** at prior-phase boundaries (e.g., retro.md must not exist at review boundary).
> 3. **Scribe-orchestrated commits** between functional boundaries should be flagged as administrative, not phase-transition. Use subject suffix "[Scribe boundary-phase]" to clarify.

**Integration Point**: Implement as a lightweight reviewer gate or pre-push hook before Feature 016 iteration planning.

**Owner**: Governance steward (for implementation in validator)  
**Timeline**: Before Feature 016 Iteration 001 planning  

---

## Decision 2: Scribe Commit Batching Guidance

**Context**: Administrative commits from Scribe multiplied between functional delivery boundaries (4+ commits between implementation and review in Feature 015 iteration 002), creating narrative gaps where git log shows multiple boundary-completion references before the actual artifact exists.

**Positive Observation**: All Scribe commits were reversible and non-destructive; this is a cognitive-load issue, not a correctness issue.

**Recommended Action**:

Establish Scribe batching discipline:

1. **During execution phases**, defer all Scribe administrative commits until the phase boundary is reached.
2. **At each lifecycle boundary**, execute ONE batched administrative commit that:
   - Updates admin-only surfaces (timestamps, orchestration ledgers, decision tracking).
   - Uses clear subject suffix: "Scribe: Admin sync at [Feature N Iteration M boundary-name]"
   - Does NOT narrate intent or future-phase readiness; only records current-phase completion.
3. **After retro authorization**, may create one final batched post-retro administrative commit if needed.

**Expected Benefit**: Reduces commit noise from 4+ intermediate commits to 2 batched boundary-administrative commits. Improves `git log` readability and closes narrative gaps.

**Integration Point**: Document in `.specify/extensions/specrew-speckit/` guidance or Scribe agent instructions.

**Owner**: Spec Kit extension maintainer / Scribe agent developer  
**Timeline**: Before Feature 016 iteration planning or rollout  

---

## Decision 3: Encourage Reviewer-Authored Skills as Reusable Patterns

**Context**: Feature 015 iteration 002 reviewer created `.squad/skills/public-readiness-release-review/SKILL.md` as a reusable guide for release-truth verification (version-surface alignment, tag verification, validator additivity, closeout-guidance enumeration).

**Positive Outcome**: The skill is git-tracked, discoverable, and immediately reusable by Feature 016+ reviewers without rediscovering the patterns.

**Recommended Action**:

Formalize reviewer-authored skills as first-class governance artifacts:

1. Treat skills created during review work as positive outcomes, not incidental byproducts.
2. List them explicitly in retrospectives when they capture durable patterns.
3. Reference them in next-iteration planning when similar work is expected.
4. Review for consolidation/archival when feature families complete.

**Update Retro Template**: Add "reviewer-authored skill creation" as a positive outcome marker in future retro artifact scaffolds.

**Owner**: Retro Facilitator / Squad coordinator  
**Timeline**: Immediate (update retro template for Feature 016)  

---

## Decision 4: Cross-Cutting Governance Work Synchronization Guidance

**Context**: Feature 015 iteration 002 delivered 9 SP at perfect estimation accuracy but required more repair cycles than typical features because it touched 7+ governance surfaces (config, docs, templates, validators, spec status, iteration artifacts). Cross-cutting work carries higher friction despite accurate effort estimates.

**Recommended Action**:

Document guidance for cross-cutting governance features:

1. **Front-load surface inventory**: Before implementation, list all files that must be updated and explicitly call out multi-location requirements (e.g., validator changes in two locations, coordinator templates in four locations).
2. **Batch verification passes**: Plan review time to verify consistency across all touched surfaces together ("version alignment pass", "template sync pass", "validator behavior pass") rather than serially.
3. **Capacity adjustment hints**: When cross-cutting work exceeds 8 SP, consider reducing scope or adding a dedicated "surface-sync" task. Estimation accuracy doesn't change, but repair-cycle friction increases.

**Artifact**: Create a "cross-cutting governance surface inventory template" for future feature planning.

**Owner**: Feature planners / Retro Facilitator  
**Timeline**: Before Feature 016 planning  

---

## Decision 5: Canonical-Concerns-Embed-Iteration-Specifics Design Principle

**Context**: Feature 015 iteration 002 (9 SP) benefited from tight embedding of iteration-specific checks into the canonical concern review template. Comparison: Feature 013 split validator-hardening into two 5 SP iterations to separate canonical schema (Iteration 001) from proof/calibration (Iteration 002+).

**Recommended Action**:

Document design principle for canonical-concerns review:

> **Use tight embedding for concentrated ≤10 SP slices; use split-iteration approach for larger work.**
>
> - **Tight embedding**: Works best when all concerns fit within 9–10 story points and scope is well-defined. Yields stronger coherence between requirements and review evidence, fewer deferred concerns, clearer artifact truth.
> - **Split-iteration approach**: Use for 10+ SP work or multi-iteration features. Phase 1 = core + canonical concerns; Phase 2+ = iteration-specific proof and calibration.

**Artifact**: Record in `.squad/decisions/` so future planners can reference when deciding between tight embedding vs. phased decomposition.

**Owner**: Retro Facilitator / Feature planners  
**Timeline**: Before Feature 016 planning  

---

## Decision 6: Rule 15 Real-World Test at Feature 015 Closeout

**Context**: Feature 015 iteration 002 defined Rule 15 (feature-closeout version management): version bump, CHANGELOG update, README/versioning.md refresh, release-tag creation, validator rerun, keep-open defer path. The rule is embedded in four coordinator surfaces but currently requires human coordination. No automation yet exists.

**Recommended Action**:

Plan explicit testing of Rule 15 at Feature 015 closeout:

1. **Measure Manual Intervention**: Count how many version-management steps require manual prompting or correction.
2. **Identify Automation Opportunities**: Note which steps are deterministic and could be auto-executed (version bump, CHANGELOG skeleton, tag creation, validator rerun).
3. **Plan Improvement**: If manual intervention is high, plan a dedicated `Invoke-FeatureCloseout` script for Feature 017+ that automates deterministic steps while keeping all steps reversible and requiring human sign-off on final push.
4. **Record Findings**: Document observations in the Feature 015 closeout boundary and retrospective trail.

**Owner**: Feature 015 coordinator / Retro Facilitator  
**Timeline**: At Feature 015 closeout, immediately after Iteration 002 closes  

---

## Summary

Six substantive lessons from Feature 015 Iteration 002:

1. Boundary-claim-without-commit pattern (5 instances) requires enforcement rule.
2. Scribe administrative commits should be batched after lifecycle boundaries.
3. Reviewer-authored skills are positive outcomes and should be encouraged.
4. Cross-cutting governance work requires tighter synchronization; consider capacity adjustment.
5. Canonical-concerns-embed-iteration-specifics design choice works well for ≤10 SP concentrated slices.
6. Rule 15 will get first real-world test at Feature 015 closeout; automate deterministic steps.

All recommendations are documented with implementation owners and timelines.

**Next Review**: These decisions should be reviewed and prioritized during the next planning ceremony before Feature 016 Iteration 001 begins.


---

### 2026-05-13T23:52:36+03:00: User directive
**By:** Alon Fliess (via Copilot)
**What:** Forward-only repair only for Feature 015 closeout; do not rewrite `main` history, preserve `77db7ce` and all subsequent commits, and make truth-surface fixes as additional commits on `main`.
**Why:** User request — captured for team memory


---

# Decision: Feature 016 before-plan boundary repair

**Date**: 2026-05-13  
**Type**: spec-clarification  
**Feature**: `016-substantive-interaction-model`

## Decision

1. Feature 016's canonical per-iteration boundary set is exactly seven entries: `planning`, `hardening-gate-and-implementation-auth`, `implementation`, `review-boundary`, `review-verdict-signoff`, `retro-boundary`, and `iteration-closeout`.
2. `feature-closeout` remains canonical, but only as a separate feature-level boundary outside the seven-boundary per-iteration count.
3. The canonical subject-line regex for the missing review verdict boundary is `^Feature \d+.* iteration \d+ review-verdict-signoff boundary`.

## Why

- This resolves the FR-001 count/name mismatch without weakening the clarified rule that `continue` advances only one boundary stop.
- It gives the validator a single mechanical review-verdict-signoff signature aligned with the same kebab-case boundary token used elsewhere in the spec.

## Scope Guard

- This repair is limited to Feature 016 before-plan readiness.
- Feature 017 remains explicitly out of scope.

## 2026-05-14-runtime-evidence-feature016-iter002-planning-prep
### 2026-05-14T12:02:39Z: Runtime evidence - Feature 016 Iteration 002 planning preparation
**By:** Squad (Coordinator)
**Role / Work Item:** Planner - open `specs/016-substantive-interaction-model/iterations/002` and scaffold planning artifacts for the authorized Iteration 002 slice
**Requested Agent:** claude
**Actual Agent:** copilot
**Model ID:** (platform default)
**Status:** fallback
**Fallback Reason:** preferred agent `claude` is not enabled in the delegated routing plan; routed through Copilot task execution

## copilot-decision-2026-05-14T12-02-39Z-feature016-iter002-clarify-skip
### 2026-05-14T12:02:39Z: Clarify skip rationale for Feature 016 Iteration 002 planning
**By:** Alon Fliess (via Copilot)
**What:** Open `specs/016-substantive-interaction-model/iterations/002` planning without re-running clarify because Feature 016 already has an approved, materially complete spec with all ten clarify-time questions resolved in `spec.md`, and the authorized Iteration 002 scope is already grounded as FR-020 through FR-024 plus the Iteration 2 promotion half of FR-016.
**Why:** Iteration 001 is closed, its plan/state/retro artifacts explicitly defer the Iteration 002 proof, corpus, documentation, template, and severity-promotion work, and the carryover planning decisions are already concrete: preserve the validator scope boundary to Squad-authored artifacts/handoffs only, keep commit-reference synchronization explicit in authorization records, carry the repair-escalation pathway forward, and treat the README/template/public-doc work as the bounded follow-through slice rather than new clarify work.

## 2026-05-14-runtime-evidence-feature016-iter002-before-plan-hook
### 2026-05-14T12:14:00Z: Runtime evidence - Feature 016 Iteration 002 mandatory before-plan validation
**By:** Squad (Coordinator)
**Role / Work Item:** Planner - run `speckit.specrew-speckit.before-plan` for Feature 016 Iteration 002 before continuing planning
**Requested Agent:** claude
**Actual Agent:** copilot
**Model ID:** (platform default)
**Status:** fallback
**Fallback Reason:** preferred agent `claude` is not enabled in the delegated routing plan; routed through Copilot task execution

## copilot-decision-2026-05-14T12-35-00Z-feature016-iter002-carryover-triage
### 2026-05-14T12:35:00Z: Iteration 002 carryover triage for Feature 016
**By:** Alon Fliess (via Copilot)
**What:** Treat Iteration 002 as the original FR-020 through FR-024 + FR-016 graduation slice **plus** the accepted feature-local carryovers that materially affect Feature 016 truth surfaces: FR-008 pending -> post-commit Commit Reference synchronization, canonical UTC seconds-precision `Recorded At` formatting, post-commit verification protocol formalization, stale-reference scan mandate after boundary commits, and graduation of the feature-local passive-guidance rows grounded by Iteration 001 review/retro evidence.
**Why:** This keeps the resumed plan truthful to accepted Iteration 001 learnings while staying below the 20 SP constitutional cap and inside the requested 15-19 SP planning target. Explicitly deferred from this plan are standalone fractional-second parser support, standalone stale-reference soft-validator support, validator performance optimization, `self-referential-feature-sp-surcharge`, and `decisions-ledger-parser-fractional-second-timestamp-incompatibility`.

## 2026-05-14-runtime-evidence-feature016-iter002-delegated-plan
### 2026-05-14T12:36:00Z: Runtime evidence - Feature 016 Iteration 002 delegated planning run
**By:** Squad (Coordinator)
**Role / Work Item:** Planner - run delegated iteration-002 planning for `specs/016-substantive-interaction-model/iterations/002` and update the Speckit planning artifacts only
**Requested Agent:** claude
**Actual Agent:** copilot
**Model ID:** gpt-5.4
**Status:** fallback
**Fallback Reason:** preferred agent `claude` is not enabled in the delegated routing plan; the planning run was executed through the Copilot-backed `speckit.plan` agent instead


## 2026-05-14-runtime-evidence-feature016-iter002-after-tasks
### 2026-05-14T12:40:00Z: Runtime evidence - Feature 016 Iteration 002 after-tasks governance pass
**By:** Squad (Coordinator)
**Role / Work Item:** Reviewer - run `speckit.specrew-speckit.after-tasks` for Feature 016 Iteration 002 and stop at the planning boundary
**Requested Agent:** claude
**Actual Agent:** copilot
**Model ID:** gpt-5.4
**Status:** fallback
**Fallback Reason:** preferred agent `claude` is not enabled in the delegated routing plan; the governance pass was executed through the Copilot-backed `speckit.specrew-speckit.after-tasks` agent

## 2026-05-14T12:37:40Z — Authorization: planning

- **Decision ID**: authorization-feature-016-iter-002-planning
- **Type**: authorization
- **Boundary**: planning
- **Approving Human**: Alon Fliess
- **Recorded At**: 2026-05-14T12:37:40Z
- **Commit Reference**: 7e803f5
- **Authorization Text**:
  > I authorize opening Iteration 002 planning for Feature 016 Substantive Interaction Model.
  >
  > Authorized planning scope:
  > - FR-020 through FR-024
  > - the Iteration 2 graduation portion of FR-016
  > - accepted Iteration 001 carryovers that materially affect Feature 016 truth surfaces: FR-008 pending -> post-commit Commit Reference synchronization, canonical UTC seconds-precision `Recorded At` formatting, post-commit verification protocol formalization, stale-reference scan mandate after boundary commits, and graduation of the feature-local passive-guidance rows grounded by Iteration 001 review/retro evidence
  >
  > Planning constraints:
  > - keep Iteration 002 bounded to 17.0 / 20 story_points
  > - stop at the planning boundary only; do not start hardening-gate work or implementation
  > - Feature 017 visual artifacts remain a separate follow-up feature; explicit deferrals must be documented in the iteration plan with rationale.

## 2026-05-14T13:11:02Z — Sign-off: hardening-gate-signoff

- **Decision ID**: authorization-feature-016-iter-002-hardening-gate-signoff
- **Type**: sign-off
- **Boundary**: hardening-gate-signoff
- **Approving Human**: Alon Fliess
- **Recorded At**: 2026-05-14T13:11:02Z
- **Commit Reference**: 6da2582
- **Authorization Text**:
  > I sign off on the accepted Iteration 002 pre-implementation hardening gate for Feature 016 Substantive Interaction Model and authorize proceeding to implementation.
  >
  > The hardening gate records five Iteration 002-specific concerns across security, error handling, retry/idempotency, test integrity, and operational resilience. Each concern is marked as addressed with evidence collection deferred to post-implementation. The Overall Verdict is ready, indicating the gate is satisfied for implementation authorization.
  >
  > Implementation authorization applies to the full Iteration 002 scope: FR-020 through FR-024, the Iteration 2 graduation portion of FR-016, and the accepted Iteration 001 carryovers affecting Feature 016 truth surfaces.

## 2026-05-14T13:11:02Z — Authorization: implementation

- **Decision ID**: authorization-feature-016-iter-002-implementation
- **Type**: authorization
- **Boundary**: implementation
- **Approving Human**: Alon Fliess
- **Recorded At**: 2026-05-14T13:11:02Z
- **Commit Reference**: 6da2582
- **Authorization Text**:
  > I sign off on the accepted Iteration 002 pre-implementation hardening gate for Feature 016 Substantive Interaction Model and authorize proceeding to implementation.
  >
  > The hardening gate records five Iteration 002-specific concerns across security, error handling, retry/idempotency, test integrity, and operational resilience. Each concern is marked as addressed with evidence collection deferred to post-implementation. The Overall Verdict is ready, indicating the gate is satisfied for implementation authorization.
  >
  > Implementation authorization applies to the full Iteration 002 scope: FR-020 through FR-024, the Iteration 2 graduation portion of FR-016, and the accepted Iteration 001 carryovers affecting Feature 016 truth surfaces.

## 2026-05-14-runtime-evidence-feature016-iter002-planning-boundary
### 2026-05-14T12:37:40Z: Runtime evidence - Feature 016 Iteration 002 planning boundary
**By:** Squad (Coordinator)
**Role / Work Item:** Planner - finalize the Iteration 002 planning boundary and stop before hardening-gate or implementation
**Requested Agent:** claude
**Actual Agent:** copilot
**Model ID:** unknown (same-window Copilot CLI session)
**Status:** fallback
**Fallback Reason:** preferred agent `claude` is not enabled in the delegated routing plan; this planning-boundary run used the available Copilot agent
## 2026-05-14-runtime-evidence-feature016-iter002-planning-repair
### 2026-05-14T12:58:12Z: Runtime evidence - Feature 016 Iteration 002 planning boundary Commit Reference correction

**By:** Planner (delegated to Copilot)
**Role / Work Item:** Planner - planning boundary Commit Reference repair (89e1073 → 7e803f5)
**Requested Agent:** Planner role (no explicit agent delegation; Planner ran directly)
**Actual Agent:** copilot
**Model ID:** gpt-5.4
**Status:** honored
**Fallback Reason:** none
**Repair Scope:** Single-line correction to .squad/decisions.md authorization entry authorization-feature-016-iter-002-planning; staged ONLY .squad/decisions.md; created repair commit 1f2bfec; pushed to origin/016-substantive-interaction-model; post-commit validation: PASS (all iterations validated successfully)
**Root Cause:** Stale hash from Iteration 2 FR-008 carryover scope (post-commit Commit Reference synchronization requirement)

## 2026-05-14-runtime-evidence-feature016-iter002-hardening-gate-truth-repair
### 2026-05-14T13:55:03Z: Runtime evidence - Feature 016 Iteration 002 hardening-gate truth repair

**By:** Squad (Coordinator)
**Role / Work Item:** Reviewer + Planner - repair the paired hardening-gate and implementation authorization evidence after the committed gate artifact lagged behind the signed-off ready-state
**Requested Agent:** claude
**Actual Agent:** copilot
**Model ID:** gpt-5.4
**Status:** fallback
**Fallback Reason:** preferred agent `claude` is not enabled in the delegated routing plan; the repair ran through the active Copilot session after independent critique
**Repair Scope:** Created non-canonical evidence-correction commit 4e6286c for `specs/016-substantive-interaction-model/iterations/002/quality/hardening-gate.md`, repointed `authorization-feature-016-iter-002-hardening-gate-signoff` and `authorization-feature-016-iter-002-implementation` from 1c3d91d to 4e6286c, and preserved the original authorization text, Decision IDs, and Recorded At values
**Root Cause:** Commit 1c3d91d recorded paired authorization before the truthful ready-state hardening-gate artifact was committed, so before-implement correctly treated the authorization evidence as untruthful against the cited tree

## 2026-05-14-runtime-evidence-feature016-iter002-implementation-reference-repair
### 2026-05-14T15:15:58Z: Runtime evidence - Feature 016 Iteration 002 implementation authorization Commit Reference repair

**By:** Squad (Coordinator)
**Role / Work Item:** Implementer - repair the implementation authorization evidence after the implementation boundary commit landed at 6da2582
**Requested Agent:** copilot
**Actual Agent:** copilot
**Model ID:** gpt-5.4
**Status:** honored
**Fallback Reason:** none
**Repair Scope:** Repointed `authorization-feature-016-iter-002-implementation` from 4e6286c to 6da2582 so the implementation boundary commit has a matching human authorization entry while preserving the original authorization text, Decision ID, and Recorded At value
**Root Cause:** The implementation boundary commit `6da2582`, Feature 016 substantive-interaction-model iteration 002: implement T001-T013, landed after the earlier hardening-gate truth repair, so the implementation authorization ledger entry still referenced the pre-implementation evidence commit instead of the actual implementation boundary

## 2026-05-14T18:40:42Z — Authorization: review-boundary

- **Decision ID**: authorization-feature-016-iter-002-review-boundary
- **Type**: authorization
- **Boundary**: review-boundary
- **Approving Human**: Alon Fliess
- **Recorded At**: 2026-05-14T18:40:42Z
- **Commit Reference**: 9201489
- **Authorization Text**:
  > You are Reviewer, the review and governance specialist for this project.
  > 
  > TEAM_ROOT: C:\Dev\Specrew-review
  > All `.squad/` paths are relative to this root.
  > WORKTREE_PATH: C:\Dev\Specrew-review
  > WORKTREE_MODE: true
  > **Requested by:** Alon Fliess
  > 
  > WORKTREE: You are working in a dedicated worktree at `C:\Dev\Specrew-review`.
  > - All file operations should be relative to this path
  > - Do NOT switch branches — the worktree is your branch (`feature016-review-boundary`)
  > - Build and test in this worktree, not the main repo
  > - Push to the canonical branch with: `git push origin HEAD:refs/heads/016-substantive-interaction-model`
  > 
  > Read `.squad/decisions.md` before starting.
  > Read `specs/016-substantive-interaction-model/iterations/002/plan.md`, `state.md`, `quality/hardening-gate.md`, `tasks.md`, and `quickstart.md` before starting.
  > 
  > Context:
  > - Feature 016 Iteration 002 implementation is complete on commit `6da2582`, the implementation boundary commit.
  > - Two bounded follow-up repairs are already on the pushed branch:
  >   - `cbb378c`, the validation-fixture and runtime-evidence repair
  >   - `0e7ffbd`, the non-canonical implementation-authorization bookkeeping fix
  > - Current local worktree is clean and based on pushed origin-equivalent HEAD `0e7ffbd`.
  > - Repo validator previously passed on the implementation tree.
  > - The user has now explicitly authorized advancing to the review boundary.
  > - Out-of-scope main-checkout files must remain untouched: `.claude/settings.local.json`, `.github/copilot-instructions.md`, `scripts/specrew-where.ps1`.
  > 
  > User-authorized review-boundary workflow:
  > 1. Evaluate the Iteration 002 implementation against the five hardening-gate Expected Controls at `specs/016-substantive-interaction-model/iterations/002/quality/hardening-gate.md`.
  >    - For each concern (`security-surface`, `error-handling-expectations`, `retry-idempotency-requirements`, `test-integrity-targets`, `operational-resilience-concerns`), update `Runtime Evidence Status` from `pending-post-implementation` to `verified` with specific citations (test paths, validator output, NFR-001 measurement) or `not-verified` with rationale.
  > 2. Draft `specs/016-substantive-interaction-model/iterations/002/review.md` with:
  >    - Overall verdict (`accepted` | `needs-work` | `rejected`)
  >    - FR-by-FR findings for FR-020 through FR-024, FR-016 Iteration 2 graduation, and the three carryover deliverables
  >    - Explicit Expected Controls verification with runtime evidence
  >    - Any defects or open questions
  >    - A note that local-vs-origin truth-surface drift was observed during user verification (`local-vs-origin-truth-surface-drift` as a retro candidate)
  > 3. Focus the review on:
  >    - FR-008 Commit Reference synchronization automation
  >    - FR-016 hard-fail config flip via config, not code rewrite
  >    - stale-reference scan behavior
  >    - the new `tests/integration/substantive-interaction-model-iteration2.ps1` scaffold-replay execution
  >    - NFR-001 validator timing re-measurement on the green tree
  >    - the four corpus row additions in `.specrew/quality/known-traps.md`
  > 4. Stage `review.md`, updated `quality/hardening-gate.md`, and any needed `state.md` / `plan.md` lifecycle updates reflecting review-in-progress.
  > 5. Record the review-boundary authorization in `.squad/decisions.md` if it does not already exist. Use the user's current message as the authorization text. Use the two-commit pattern, not amend, for any post-commit Commit Reference updates. FR-008 automation is expected to help here; verify whether it works cleanly and note that in the review.
  > 6. Create the canonical review-boundary commit with subject exactly:
  >    `Feature 016 substantive-interaction-model iteration 002 review boundary`
  > 7. Push to `origin/016-substantive-interaction-model` with explicit refspec and verify local HEAD equals origin HEAD after push.
  > 8. Post-commit verification: run `pwsh -NoProfile -ExecutionPolicy Bypass -File .\extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath .` and confirm PASS on Feature 016 Iteration 002.
  > 9. STOP at the review boundary. Do NOT advance to review-verdict-signoff.
  > 10. If defects requiring rework are found, the verdict must be `needs-work`, not `accepted`, with explicit defect descriptions.
  > 
  > Important review requirements:
  > - Be critical and evidence-driven. Classify the hardening-gate concerns as implemented, enforced, observable, and documented through actual runtime evidence.
  > - Re-measure NFR-001 on the green tree and cite the measurement in `hardening-gate.md` and `review.md`.
  > - Ensure the review remains truthful: if review and retro artifacts must exist now, create/update only the review artifact. Do not open retro.
  > - If the review-boundary authorization auto-generation or post-commit synchronization fails, repair it explicitly and report the exact behavior.
  > - Verify that the pushed branch state matches origin after push; call out any drift if found.
  > 
  > At the end, provide a concise boundary handoff including:
  > - What changed and the review verdict
  > - Review-boundary commit hash and any follow-up bookkeeping commit hash
  > - Whether the validator passed post-push
  > - Whether FR-008 automation worked cleanly or needed manual repair
  > - Why you stopped and what exact next human authorization is required
  > 
  > ⚠️ OUTPUT: Report outcomes in human terms. Never expose tool internals or SQL.
  > ⚠️ RESPONSE ORDER: After ALL tool calls, write a 2-3 sentence plain text summary as FINAL output. No tool calls after this summary.

## 2026-05-15T00:00:00Z — Authorization: retro-boundary

- **Decision ID**: authorization-feature-016-iter-002-retro-boundary
- **Type**: authorization
- **Boundary**: retro-boundary
- **Approving Human**: Alon Fliess
- **Recorded At**: 2026-05-15T00:00:00Z
- **Commit Reference**: 5e2a0a7
- **Authorization Text**:
  > I sign off on the accepted review verdict for Feature 016 Iteration 002 (Re-Review: FR-008 Repair, 2026-05-15, post-repair). The FR-008 implementation-repair is verified: live-execution test passes, the `.squad/decisions.md.lock` crud-cleanup is verified, and the three hardening-gate concerns (error-handling-expectations, retry-idempotency-requirements, operational-resilience-concerns) are now verified per the re-review section in review.md. NFR-001 stays at ~179550 ms with retro-capture noted. Authorized to advance to the retro boundary for Feature 016 Iteration 002.

## 2026-05-14T22:14:15Z — Authorization: iteration-closeout

- **Decision ID**: authorization-feature-016-iter-002-iteration-closeout
- **Type**: authorization
- **Boundary**: iteration-closeout
- **Approving Human**: Alon Fliess
- **Recorded At**: 2026-05-14T22:14:15Z
- **Commit Reference**: 8acd997
- **Authorization Text**:
  > I authorize iteration-closeout for Feature 016 substantive-interaction-model Iteration 002. The retro boundary is complete with corpus capture, estimation variance analysis, deferral documentation, and positive learnings recorded. Iteration 002 delivered all authorized scope (FR-020 through FR-024, the Iteration 2 graduation portion of FR-016, and accepted FR-008/timestamp/stale-reference carryovers) and passed all review verdicts post-FR-008-repair. Iteration Status transitions to closed on boundary commit. Feature-closeout remains separately authorized.

## 2026-05-14T23:14:40Z — Authorization: feature-closeout

- **Decision ID**: authorization-feature-016-feature-closeout
- **Type**: authorization
- **Boundary**: feature-closeout
- **Approving Human**: Alon Fliess
- **Recorded At**: 2026-05-14T23:14:40Z
- **Commit Reference**: fd0aff3
- **Authorization Text**:
  > I authorize feature-closeout for Feature 016 Substantive Interaction Model. Iteration 002 is closed and merged to feature branch. All hardening-gate concerns verified post-FR-008-repair, review verdict accepted, and retro complete with corpus capture and durability learnings. Authorized to proceed with Rule 15 version-management boundary commit (0.15.0 → 0.16.0), feature-closeout PR creation and merge to main, tag push, and final validator confirmation. Two chore commits (Feature 017, Feature 020) remain separately authorized.


## 2026-05-15T09:35:00Z — Authorization: implementation-repair

- **Decision ID**: authorization-feature-017-iter-001-implementation-repair
- **Type**: authorization
- **Boundary**: implementation-repair
- **Approving Human**: Alon Fliess
- **Recorded At**: 2026-05-15T09:35:00Z
- **Commit Reference**: 9093f98
- **Authorization Text**:
  > Repair + spec expansion — Feature 017 Velocity Dashboard. Begin with Part 1 spec extensions so the FRs are recorded before implementation repairs run against them. Then update plan/tasks, repair implementation (R1-R10), verify with live dashboard + validator + existing tests, commit, update decisions and identity, push, and stop at review-boundary.
  > Do not advance past review-boundary.

---

### 2026-05-15T12:58:32+03:00: Delegated lifecycle runtime evidence
**By:** Squad (Coordinator)
**Role / Work Item:** Reviewer — Feature 017 Velocity Dashboard Iteration 001 review-verdict-signoff boundary
**Requested Agent:** copilot (Reviewer family)
**Actual Agent:** copilot
**Model ID:** unknown (Copilot CLI host does not expose the active model identifier)
**Status:** honored
**Fallback Reason:** none

---

## 2026-05-15T09:58:32Z — Authorization: review-verdict-signoff

- **Decision ID**: authorization-feature-017-iter-001-review-verdict-signoff
- **Type**: authorization
- **Boundary**: review-verdict-signoff
- **Approving Human**: Alon Fliess
- **Recorded At**: 2026-05-15T09:58:32Z
- **Commit Reference**: pending (single-boundary-commit constraint; recorded by canonical boundary subject)
- **Authorization Text**:
  > The human reviewer has already ACCEPTED Feature 017 Iteration 1 and authorized exactly one boundary advance: from review-boundary to review-verdict-signoff.
  > Record the accepted review-verdict-signoff boundary, stop at retro-boundary, and request explicit retro authorization next.

---

### 2026-05-16T18:30:00Z: Delegated lifecycle runtime evidence
**By:** Squad (Coordinator)
**Role / Work Item:** Reviewer — Feature 017 Velocity Dashboard Iteration 002 pre-implementation self-review and hardening-gate signoff surface
**Requested Agent:** copilot (Reviewer family)
**Actual Agent:** copilot
**Model ID:** unknown (Copilot CLI host does not expose the active model identifier)
**Status:** honored
**Fallback Reason:** none

---

# Reviewer Decision: Feature 017 Iteration 002 Pre-Implementation Hardening Gate Sign-Off

**Decision ID**: reviewer-feature-017-iter-002-hardening-gate-signoff
**Feature**: 017 — Velocity Dashboard
**Date**: 2026-05-16
**Decision Maker**: Reviewer
**Authority**: bounded reviewer self-review under the explicitly authorized implementation boundary for Iteration 002

## Decision Summary

Iteration 002's pre-implementation review is complete. No material blocker prevents implementation of FR-019..FR-033 plus FR-042..FR-046, and the hardening gate is signed off as `ready` with explicit monitoring obligations for lifecycle safety, classifier safety, grandfathering, NFR-001 budget preservation, documentation/runtime alignment, Iteration 001 compatibility, FR-032 replay coverage, proof-of-concept uplift, and essence-first handoff discipline.

## Evidence Reviewed

- `specs/017-velocity-dashboard/spec.md`
- `specs/017-velocity-dashboard/plan.md`
- `specs/017-velocity-dashboard/tasks.md`
- `specs/017-velocity-dashboard/iterations/002/deferrals.md`
- `specs/017-velocity-dashboard/iterations/001/retro.md`
- `specs/017-velocity-dashboard/iterations/001/state.md`
- `specs/017-velocity-dashboard/iterations/001/review.md`
- `.specrew/quality/known-traps.md`
- `specs/017-velocity-dashboard/iterations/002/pre-implementation-review.md`
- `specs/017-velocity-dashboard/iterations/002/quality/hardening-gate.md`

## Review Outcome

- **Verdict**: ready
- **Blocking issues**: none
- **Required implementation posture**:
  1. Automatic dashboard generation is required, but artifact absence must warn rather than block lifecycle progression.
  2. FR-030 routing stays conservative; ambiguous “status” requests remain outside dashboard auto-routing.
  3. FR-022 grandfathering is explicit: all pre-rollout iterations, including Feature 017 Iteration 001, remain valid without dashboard artifacts.
  4. Iteration 002 must preserve the Iteration 001 renderer contract and re-measure NFR-001 on the green tree.
  5. Documentation/help/review artifacts must stay aligned with implemented behavior and preserve the essence-vs-exhaustive corpus lesson.

## Governance Validation Baseline

- `validate-governance.ps1 -ProjectPath .` completed with exit code `0`
- The committed pre-implementation rerun returned no WARN or FAIL lines
- Earlier ad hoc dashboard warning themes (roadmap drift, missing `dashboard.md`, missing `closeout-dashboard.md`) are still recorded in the hardening gate as implementation concerns rather than erased from the review record

---

## 2026-05-16T18:30:00Z — Authorization: implementation

- **Decision ID**: authorization-feature-017-iter-002-implementation
- **Type**: authorization
- **Boundary**: implementation
- **Approving Human**: Alon Fliess
- **Recorded At**: 2026-05-16T18:30:00Z
- **Commit Reference**: 9b51630
- **Authorization Text**:
  > The user has authorized a bundled hardening-gate-and-implementation-auth boundary for Feature 017 Iteration 002.
  > Advance from iteration-closeout to hardening-gate-and-implementation-auth. ONE boundary advance only. Stop at the next required human boundary (review-boundary) and request explicit authorization.
  > Implementation scope includes FR-019 through FR-033 and FR-042 through FR-046, with the required hardening-gate concerns, pre-implementation self-review, and implementation proceeding after that boundary commit lands.
  > If repair cycles emerge during Iteration 002 implementation, absorb them inside implementation work; stop at review-boundary and do not advance further without explicit human authorization.

## 2026-05-16T18:30:00Z — Authorization: hardening-gate-signoff

- **Decision ID**: authorization-feature-017-iter-002-hardening-gate-signoff
- **Type**: authorization
- **Boundary**: hardening-gate-signoff
- **Approving Human**: Alon Fliess
- **Recorded At**: 2026-05-16T18:30:00Z
- **Commit Reference**: 9b51630
- **Authorization Text**:
  > The user has authorized a bundled hardening-gate-and-implementation-auth boundary for Feature 017 Iteration 002.
  > Advance from iteration-closeout to hardening-gate-and-implementation-auth. ONE boundary advance only. Stop at the next required human boundary (review-boundary) and request explicit authorization.
  > Implementation scope includes FR-019 through FR-033 and FR-042 through FR-046, with the required hardening-gate concerns, pre-implementation self-review, and implementation proceeding after that boundary commit lands.
  > If repair cycles emerge during Iteration 002 implementation, absorb them inside implementation work; stop at review-boundary and do not advance further without explicit human authorization.

---

### 2026-05-15T11:36:20Z: Delegated lifecycle runtime evidence
**By:** Squad (Coordinator)  
**Role / Work Item:** Implementer — Feature 017 Velocity Dashboard Iteration 002 implementation boundary  
**Requested Agent:** copilot  
**Actual Agent:** copilot  
**Model ID:** unknown (Copilot CLI host does not expose the active model identifier)  
**Status:** honored  
**Fallback Reason:** none

---

# Implementer Boundary Note: Feature 017 Iteration 002 Implementation

**Date**: 2026-05-15  
**Scope**: FR-019..FR-033 plus FR-042..FR-046

## Summary

Completed the Iteration 002 implementation slice: closeout dashboard scaffolds now warn instead of blocking, validator grandfathering exempts pre-rollout iterations (including Feature 017 Iteration 001), onboarding messaging points to roadmap docs, routing guidance adds explicit positive/negative examples, and documentation + fixtures now cover closeout snapshots, immutability, and validator warning behavior.

## Evidence

- `scripts\internal\dashboard-renderer.ps1`
- `extensions\specrew-speckit\scripts\scaffold-reviewer-artifacts.ps1`
- `extensions\specrew-speckit\scripts\scaffold-feature-closeout-dashboard.ps1`
- `extensions\specrew-speckit\scripts\validate-governance.ps1`
- `tests\integration\feature-017-dashboard-core.ps1`

---

## 2026-05-16T20:10:00Z — Authorization: iteration-closeout

- **Decision ID**: authorization-feature-017-iter-002-iteration-closeout
- **Type**: authorization
- **Boundary**: iteration-closeout
- **Approving Human**: Alon Fliess
- **Recorded At**: 2026-05-16T20:10:00Z
- **Commit Reference**: 17
- **Authorization Text**:
  > The human has authorized exactly one boundary advance: retro-boundary -> iteration-closeout for Feature 017 Iteration 002.
  > Investigate planned-story-point parsing, ETA label duplication, and shipped-label drift; repair R-IC-1 through R-IC-3, rerun specrew where, validator, and tests, update closeout bookkeeping artifacts, and stop at feature-closeout pending explicit authorization.

## 2026-05-16T19:05:00Z — Authorization: review-verdict-signoff

- **Decision ID**: authorization-feature-017-iter-002-review-verdict-signoff
- **Type**: authorization
- **Boundary**: review-verdict-signoff
- **Approving Human**: Alon Fliess
- **Recorded At**: 2026-05-16T19:05:00Z
- **Commit Reference**: 6590e93
- **Authorization Text**:
  > The human has ACCEPTED review verdict for Feature 017 Iteration 002 WITH TWO REPAIR ITEMS and authorized exactly one boundary advance: review-boundary -> review-verdict-signoff.
  > Apply R-V1 and R-V2 in `scripts\internal\dashboard-renderer.ps1`, re-run specrew where, validator, and tests, update review/verdict artifacts, and stop at retro-boundary.

## 2026-05-15T13:30:59Z — Authorization: retro-boundary

- **Decision ID**: authorization-feature-017-iter-002-retro-boundary
- **Type**: authorization
- **Boundary**: retro-boundary
- **Approving Human**: Alon Fliess
- **Recorded At**: 2026-05-15T13:30:59Z
- **Commit Reference**: pending (single retro-boundary commit to be recorded by canonical subject)
- **Authorization Text**:
  > The human has authorized exactly one boundary advance: review-verdict-signoff -> retro-boundary for Feature 017 Iteration 002.
  > Absorb pre-retro repairs R-Retro-1 and R-Retro-2, create the missing Iteration 002 retrospective/state/plan artifacts, update known traps and runtime state, verify with `specrew where` and the governance validator, create exactly one retro-boundary commit, push it, and stop at iteration-closeout pending.

---

### 2026-05-15T13:30:59Z: Delegated lifecycle runtime evidence
**By:** Squad (Coordinator)
**Role / Work Item:** Retro Facilitator — Feature 017 Velocity Dashboard Iteration 002 retro-boundary
**Requested Agent:** copilot
**Actual Agent:** copilot
**Model ID:** unknown (Copilot CLI host does not expose the active model identifier)
**Status:** honored
**Fallback Reason:** none

---

# Retro Facilitator Decision: Feature 017 Iteration 002 Retrospective

**Date**: 2026-05-15
**Type**: retro-boundary
**Scope**: Feature 017 Iteration 002 review-verdict-signoff → retro-boundary

## Summary

Completed the Iteration 002 retro boundary and absorbed both pre-retro bookkeeping repairs.
Iteration 001 story points are now stored as a clean numeric `18 SP` with the observed `17-19 SP`
range preserved in notes, and Iteration 002 now has the missing `plan.md`, `state.md`, and
`retro.md` artifacts required for truthful dashboard rendering and canonical iteration tracking.

## Result

- `specrew where` can now render Feature 017 Iteration 001 as `18 SP` instead of `0 SP`
- Iteration 002 is now visible to dashboard aggregation because `iterations/002/state.md` exists
- The retro captures the eight required substantive topics, including the four bug categories and
  feature-closeout readiness posture
- `.specrew/quality/known-traps.md` now records the form-correctness-vs-meaning-correctness pattern

## Next Action

Do not advance further from this boundary. The next valid action is explicit iteration-closeout
authorization for Feature 017 Iteration 002.

## 2026-05-15T15:26:30Z — Authorization: feature-closeout

- **Decision ID**: authorization-feature-017-feature-closeout
- **Type**: authorization
- **Boundary**: feature-closeout
- **Approving Human**: Alon Fliess
- **Recorded At**: 2026-05-15T15:26:30Z
- **Commit Reference**: 17e2a4c
- **Authorization Text**:
  > The human has authorized exactly one boundary advance: iteration-closeout -> feature-closeout for Feature 017 Velocity Dashboard.
  > Apply R-FC-1 in `scripts\internal\dashboard-renderer.ps1`, rerun `specrew where`, generate the feature closeout dashboard snapshot, execute Rule 15 version-management updates, open and merge the feature-closeout PR, tag v0.17.0, verify on main, and stop.

# Feature 017 Closeout Execution: Rule 15 Version Management

**Date**: 2026-05-15  
**By**: Implementer  
**Authority**: Feature 017 feature-closeout authorization (Rule 15)  
**Decision Type**: feature-closeout-version-management

## Decision

Feature 017 (velocity-dashboard) is closed and shipped to main with Rule 15 version-management completed.

### Actions Completed

1. **Truthfulness repairs and artifacts**
   - R-FC-1 ETA classifier fix applied in `scripts\internal\dashboard-renderer.ps1`
   - `.specrew/quality/known-traps.md` reinforced for form-correctness vs meaning-correctness
   - `specrew where` rerun to confirm non-shipped ETA labels
   - `specs/017-velocity-dashboard/closeout-dashboard.md` captured as the feature-closeout snapshot

2. **Version management (Rule 15 core)**
   - `.specrew/config.yml`: version bumped to 0.17.0
   - `CHANGELOG.md`: Feature 017 entry added for v0.17.0
   - `README.md`: version badge, baseline, and recent tag window refreshed

3. **Release integration**
   - Feature-closeout boundary commit created and pushed
   - PR created and merged to main via merge commit (no squash/rebase)
   - Annotated tag v0.17.0 created at the merge commit and pushed

4. **Post-merge verification**
   - `validate-governance.ps1` rerun on main and passed
   - `specrew where` on main renders truthful ETA labels
   - Closeout dashboard artifact present on main

## Impact

Feature 017 (Velocity Dashboard) is now closed and shipped. Version 0.17.0 is the active baseline, and no feature is currently open without explicit authorization.

## 2026-05-15T16:10:40Z — Delegated routing plan

- **Enabled Agents**: copilot
- **Independent Oversight Active**: False
- **Roles**:
  - Implementer | requested=copilot | actual=copilot | model=(platform default) | status=honored | fallback=(none)
  - Spec Steward | requested=codex | actual=copilot | model=(platform default) | status=fell-back | fallback=preferred agent 'codex' is not enabled
  - Planner | requested=claude | actual=copilot | model=(platform default) | status=fell-back | fallback=preferred agent 'claude' is not enabled
  - Reviewer | requested=claude | actual=copilot | model=(platform default) | status=fell-back | fallback=preferred agent 'claude' is not enabled
  - Retro Facilitator | requested=copilot | actual=copilot | model=(platform default) | status=honored | fallback=(none)

## 2026-05-15T16:10:40Z — Routing evidence: Spec Steward

- **Decision ID**: routing-evidence-206ce5416f23
- **Type**: routing-evidence
- **Affected Requirement**: FR-043
- **Affected Iteration**: (none)
- **Approving Human**: (none)
- **Recorded At**: 2026-05-15T16:10:40Z
- **Next Action**: none
- **Rationale**: Delegated lifecycle routing was applied for role 'Spec Steward'.

- **Routing Evidence**: Spec Steward | requested=codex | actual=copilot | model=(platform default) | status=fell-back | fallback=preferred agent 'codex' is not enabled

## 2026-05-15T16:10:40Z — Routing evidence: Planner

- **Decision ID**: routing-evidence-cc6d58bdf628
- **Type**: routing-evidence
- **Affected Requirement**: FR-043
- **Affected Iteration**: (none)
- **Approving Human**: (none)
- **Recorded At**: 2026-05-15T16:10:40Z
- **Next Action**: none
- **Rationale**: Delegated lifecycle routing was applied for role 'Planner'.

- **Routing Evidence**: Planner | requested=claude | actual=copilot | model=(platform default) | status=fell-back | fallback=preferred agent 'claude' is not enabled

## 2026-05-15T16:10:40Z — Routing evidence: Reviewer

- **Decision ID**: routing-evidence-7692f5bf7c1e
- **Type**: routing-evidence
- **Affected Requirement**: FR-043
- **Affected Iteration**: (none)
- **Approving Human**: (none)
- **Recorded At**: 2026-05-15T16:10:40Z
- **Next Action**: none
- **Rationale**: Delegated lifecycle routing was applied for role 'Reviewer'.

- **Routing Evidence**: Reviewer | requested=claude | actual=copilot | model=(platform default) | status=fell-back | fallback=preferred agent 'claude' is not enabled


# Implementer Decision: Feature 018 bounded repair R-018-V2

**Date**: 2026-05-15  
**By**: Implementer  
**Type**: bounded-repair

## Decision

For Feature 018 review repair `R-018-V2`, the dashboard renderer must no longer use
`[Console]::IsOutputRedirected` as a live rich-mode eligibility gate. Instead, the
live `scripts\specrew-where.ps1` entrypoint temporarily primes UTF-8 when rich mode
has not already been disabled by explicit operator controls, then restores the
caller console state on exit.

## Why It Matters

- Fresh PowerShell review runs were receiving a misleading redirected-output fallback
  diagnosis even when the real issue was pre-render UTF-8 state.
- Moving the UTF-8 priming to the entry script keeps diagnostics truthful and leaves
  the shared renderer focused on directly verifiable eligibility checks.
- Restore-on-exit protects caller state so the repair stays bounded and safe for
  repeated local CLI use.

## Scope Guardrail

This decision is limited to Feature 018 review repair `R-018-V2a` / `R-018-V2b` /
`R-018-V2c`. It does not authorize review acceptance, retro opening, or any broader
terminal-capability redesign beyond the bounded repair.


# Implementer decision: Feature 018 review repair

- **Date**: 2026-05-15
- **Feature**: 018 — Velocity Dashboard Visual Richness + PoC-Parity Restoration
- **Boundary**: review-verdict-signoff
- **Decision**: Preserve Recent Shipped per-iteration granularity by rendering a combined feature-and-iteration label (`F-017 · iter-001`) on live dashboard rows.

## Rationale

1. Feature-only Recent Shipped labels regressed once Feature 017 and later features accumulated multiple closed
   iterations, causing `specrew where` to emit duplicate row labels.
2. A combined feature-and-iteration label keeps Feature 017 granularity visible without widening the repair into
   roadmap, projection, or retro surfaces.
3. The same label needs to flow through both rich and monochrome render paths so validator-backed snapshots and
   operator reruns stay consistent.


# Planner Decision Inbox: Feature 018 Hardening Scaffold

**Date**: 2026-05-15  
**Role**: Planner  
**Feature**: 018-velocity-dashboard-visual-richness  
**Iteration**: 001

## Decision

Use iteration-scoped execution artifacts under
`specs/018-velocity-dashboard-visual-richness/iterations/001/quality/` as the canonical pre-implementation
package for Feature 018, even though the backlog still contains feature-root quality paths.

## Why

1. `.squad/decisions/inbox/reviewer-feature018-preimpl.md` identified the missing hardening gate as the
   only blocker before implementation.
2. `/speckit.specrew-speckit.before-implement` needs a truthful iteration artifact set, not future
   review/retro placeholders.
3. Carrying the reviewer's five exact concern labels into the iteration-scoped hardening gate keeps the
   execution boundary auditable without reopening planning.

## Recorded Concern Labels

- `terminal-capability-decision-precedence`
- `windows-vt-fallback-truthfulness`
- `render-budget-stop-ship-evidence`
- `ansi-stripping-with-unicode-preservation`
- `closeout-dashboard-artifact-rendering`

## Consequence

Execution can stay paused at the correct boundary: plan/state/drift plus iteration-scoped quality artifacts
exist, review/retro remain unopened, and implementation can start later only if the before-implement gate
accepts this package.


# Reviewer decision: Feature 018 pre-implementation refresh

- **Date**: 2026-05-15
- **Feature**: 018 — Velocity Dashboard Visual Richness + PoC-Parity Restoration
- **Boundary**: pre-implementation / hardening-gate-and-implementation-auth
- **Decision**: Refresh the pre-implementation review to `ready-with-concerns`.

## Rationale

The earlier blocker was real when the hardening gate was absent. It is no longer real: the authorized
iteration-scoped artifact set now exists under `specs/018-velocity-dashboard-visual-richness/iterations/001/`,
the approval ledger records hardening-gate sign-off plus bundled implementation authorization, and the current
iteration package passes governance validation.

## Carry-forward watchpoints

1. Terminal-capability precedence must stay deterministic across `--ASCII`, Unicode opt-out,
   redirected/dumb output, UTF-8 checks, and Windows VT eligibility.
2. Missing Windows VT support must force a clean monochrome fallback with no partial ANSI leakage.
3. Render-budget proof (`<= 1.5s`) remains stop-ship evidence, not polish.
4. Stored dashboard artifacts must strip ANSI while preserving readable Unicode.
5. Iteration-closeout and feature-closeout dashboard rendering must stay parity-safe and immutable.


# Reviewer Decision Inbox: Feature 018 Pre-Implementation Review

**Date**: 2026-05-15  
**Role**: Reviewer  
**Feature**: 018-velocity-dashboard-visual-richness  
**Iteration**: 001  
**Verdict**: blocked

## Decision

Feature 018 is implementable on substance, but implementation should not start yet.

## Why

1. `spec.md`, `plan.md`, and `tasks.md` do cover the requested rendering, fallback, regression, artifact, and documentation surfaces.
2. The approved next-step ledger in `.squad/decisions.md` requires the pre-implementation review and hardening-gate artifacts to be updated before implementation proceeds.
3. `specs/018-velocity-dashboard-visual-richness/quality/hardening-gate.md` is still missing, so the implementation boundary is incomplete.

## Required Next Move

Create the hardening-gate artifact and carry these explicit concerns into it before implementation begins:

- terminal-capability decision precedence
- Windows VT fallback truthfulness
- NFR-001 render-budget stop-ship evidence
- ANSI stripping with Unicode preservation
- iteration-closeout and feature-closeout dashboard artifact rendering

## Scope Discipline

No planning-package rewrite is required once the hardening gate exists. Do not widen scope beyond the approved five pillars.


# Reviewer decision: Feature 018 visual terminal check

- **Date**: 2026-05-15
- **Feature**: 018 — Velocity Dashboard Visual Richness + PoC-Parity Restoration
- **Boundary**: review / direct-terminal rich-render verification
- **Decision**: needs-work

## Rationale

I ran `specrew where` directly in the PowerShell terminal against `tests\integration\fixtures\feature-018-dashboard\rich-capable-repository`.
The command rendered `Rendering: monochrome-safe fallback` and warned that output was redirected, so the approved rich-mode surface did not appear in the live review session.

## Additional repair item before signoff

Repair or explain the live capability-detection path so a direct terminal run shows the approved rich-mode elements instead of fallback substitutes. In the reviewed session these rich elements failed together:

1. Unicode block chars `█` / `░` did not render; ASCII `#` / `.` bars appeared instead.
2. ANSI semantic colors were not active because the renderer stayed in monochrome mode.
3. Status markers `✓` / `◐` / `○` did not render; `[x]` / `[~]` / `[ ]` appeared instead.
4. The active-feature arrow `→` did not render; `>` appeared instead.
5. The sparkline `▁▂▃▄▅▆▇█` did not render; a textual trend list appeared instead.

## Next move

Do not sign off the visual-richness claim until a direct PowerShell terminal run produces the rich glyph set and semantic emphasis on the rich-capable repository fixture, or the requirement is explicitly re-scoped with approval.

---

## 2026-05-15T23:30:00Z — Canonical defer entry (Feature 018 iteration 001 review signoff cosmetic defer)

- **Decision ID**: defer-roadmap-phase-status-marker-uniformity-feature-018-iter-001
- **Type**: defer
- **Affected Iteration**: specs\018-velocity-dashboard-visual-richness\iterations\001
- **Approving Human**: Alon Fliess
- **Recorded At**: 2026-05-15T23:30:00Z
- **Next Action**: Normalize roadmap rich-marker styling in a later scoped polish pass without changing lifecycle meaning or fallback semantics
- **Rationale**: Direct-terminal review acceptance for Feature 018 Iteration 001 confirmed that rich-mode rendering now works after `R-018-V2`. The remaining roadmap phase status marker uniformity observation is cosmetic only, so it is explicitly deferred instead of reopening review-verdict-signoff.

## 2026-05-16T00:26:17Z — Authorization: review-verdict-signoff

- **Decision ID**: authorization-feature-018-iter-001-review-verdict-signoff
- **Type**: authorization
- **Boundary**: review-verdict-signoff
- **Approving Human**: Alon Fliess
- **Recorded At**: 2026-05-16T00:26:17Z
- **Commit Reference**: 41d0767
- **Authorization Text**:
  > ACCEPT review-verdict-signoff for Feature 018 Iteration 001. Direct-terminal verification confirms rich-mode rendering works after R-018-V2.
  > This is a single boundary advance only: create and push the review-verdict-signoff boundary commit to origin/018-velocity-dashboard-visual-richness, and stop before retro-boundary.

## 2026-05-16T00:35:00Z — Authorization: retro-boundary

- **Decision ID**: authorization-feature-018-iter-001-retro-boundary
- **Type**: authorization
- **Boundary**: retro-boundary
- **Approving Human**: Alon Fliess
- **Recorded At**: 2026-05-16T00:35:00Z
- **Commit Reference**: 7ed5a21
- **Authorization Text**:
  > AUTHORIZE retro-boundary for Feature 018 Iteration 001. Advance from review-verdict-signoff to retro-boundary only, stop at iteration-closeout. Record the eight substantive lessons in retro.md, cross-reference the four relevant corpus rows in known-traps.md, and update identity/now.md to retro-complete state.
  > Eight lessons captured: (1) Five-attempt R-018-V2 detection-debugging saga, (2) Squad-discipline exemplar of refusing false signoff, (3) Recurring push-omission pattern, (4) Three new corpus rows + one deferred cosmetic, (5) PoC re-audit pattern, (6) F-018 estimation variance (zero variance: 14.5 SP), (7) Honest pre-implementation review assessment, (8) Article-visual-evidence milestone.
  > This is a single boundary advance only: create and push the retro-boundary commit to origin/018-velocity-dashboard-visual-richness, and stop before iteration-closeout.

---

### 2026-05-16T00:45:00Z: Delegated lifecycle runtime evidence
**By:** Squad (Coordinator)
**Role / Work Item:** Implementer — Feature 018 Velocity Dashboard Visual Richness Iteration 001 iteration-closeout boundary
**Requested Agent:** copilot
**Actual Agent:** copilot
**Model ID:** unknown (Copilot CLI host does not expose the active model identifier)
**Status:** honored
**Fallback Reason:** none

---

## 2026-05-16T00:45:00Z — Authorization: iteration-closeout

- **Decision ID**: authorization-feature-018-iter-001-iteration-closeout
- **Type**: authorization
- **Boundary**: iteration-closeout
- **Approving Human**: Alon Fliess
- **Recorded At**: 2026-05-16T00:45:00Z
- **Commit Reference**: b40965985e4f919d3733b8c43cc022aeafdb4fb3
- **Boundary Note**: This hash is the canonical Feature 018 Iteration 001 iteration-closeout boundary commit.
- **Authorization Text**:
  > Advance only the authorized boundary: Feature 018 Iteration 001 from retro-boundary to iteration-closeout.
  > Do NOT open or imply feature-closeout. Rule 15 release/version work is explicitly out of scope for this authorization.
  > Update the closeout bookkeeping, rerun the validator and existing relevant tests, create and push the iteration-closeout boundary commit, and stop there.

---

# Implementer Decision Inbox: Feature 018 Iteration 001 iteration-closeout boundary

**Date**: 2026-05-16  
**Role**: Implementer  
**Feature**: 018-velocity-dashboard-visual-richness  
**Iteration**: 001

## Decision

Treat Iteration 001 as truthfully closed at the iteration layer once the closeout state records the
requested PoC re-audit calibration baseline (~10-12 SP, with the original ~6-8 SP noted), grounds actual
delivery in the authoritative iteration task actuals (14.5 SP), cross-references the strategic-response
sequencing inputs, and leaves feature-closeout explicitly unopened.

## Why

1. The truthful delivery measure for this iteration is the task-actual table in
   `specs/018-velocity-dashboard-visual-richness/iterations/001/plan.md`, which sums to 14.5 SP and already
   includes the accepted execution slices that absorbed the review repairs.
2. The implementation and absorbed-repair evidence is corroborated by the authorized commit arc
   `228911a..7ed5a21`, including `d380212`, `cb052b9`, `aafc2e9`, and `41d0767`, so the closeout narrative
   can explain the basis without inventing extra hidden scope.
3. The strategic-response note is bookkeeping for forward readers only; retro remains the lesson authority,
   and this closeout must not imply feature-closeout or Rule 15 release work.

## Boundary Guardrail

- Close the iteration only.
- Keep feature-closeout pending explicit authorization.
- Accept only the pre-existing roadmap-drift validator warnings as carry-forward; no new warning class is acceptable.

## 2026-05-16T09:40:32Z — Authorization: feature-closeout

- **Decision ID**: authorization-feature-018-feature-closeout
- **Type**: authorization
- **Boundary**: feature-closeout
- **Approving Human**: Alon Fliess
- **Recorded At**: 2026-05-16T09:40:32Z
- **Commit Reference**: 35ff51577e7a54551e9133e4fef8cb4261fa444b
- **Boundary Note**: This hash is the canonical Feature 018 feature-closeout boundary commit.
- **Authorization Text**:
  > AUTHORIZE feature-closeout for Feature 018 Velocity Dashboard Visual Richness + PoC-Parity Restoration. Rule 15 fires.

## 2026-05-16T10:26:39Z — Delegated routing plan

- **Enabled Agents**: copilot
- **Independent Oversight Active**: False
- **Roles**:
  - Implementer | requested=copilot | actual=copilot | model=(platform default) | status=honored | fallback=(none)
  - Spec Steward | requested=codex | actual=copilot | model=(platform default) | status=fell-back | fallback=preferred agent 'codex' is not enabled
  - Planner | requested=claude | actual=copilot | model=(platform default) | status=fell-back | fallback=preferred agent 'claude' is not enabled
  - Reviewer | requested=claude | actual=copilot | model=(platform default) | status=fell-back | fallback=preferred agent 'claude' is not enabled
  - Retro Facilitator | requested=copilot | actual=copilot | model=(platform default) | status=honored | fallback=(none)

## 2026-05-16T10:26:39Z — Routing evidence: Spec Steward

- **Decision ID**: routing-evidence-3572bde54970
- **Type**: routing-evidence
- **Affected Requirement**: FR-043
- **Affected Iteration**: (none)
- **Approving Human**: (none)
- **Recorded At**: 2026-05-16T10:26:39Z
- **Next Action**: none
- **Rationale**: Delegated lifecycle routing was applied for role 'Spec Steward'.

- **Routing Evidence**: Spec Steward | requested=codex | actual=copilot | model=(platform default) | status=fell-back | fallback=preferred agent 'codex' is not enabled

## 2026-05-16T10:26:39Z — Routing evidence: Planner

- **Decision ID**: routing-evidence-a9458cb47f3b
- **Type**: routing-evidence
- **Affected Requirement**: FR-043
- **Affected Iteration**: (none)
- **Approving Human**: (none)
- **Recorded At**: 2026-05-16T10:26:39Z
- **Next Action**: none
- **Rationale**: Delegated lifecycle routing was applied for role 'Planner'.

- **Routing Evidence**: Planner | requested=claude | actual=copilot | model=(platform default) | status=fell-back | fallback=preferred agent 'claude' is not enabled

## 2026-05-16T10:26:39Z — Routing evidence: Reviewer

- **Decision ID**: routing-evidence-072e9e4d12b7
- **Type**: routing-evidence
- **Affected Requirement**: FR-043
- **Affected Iteration**: (none)
- **Approving Human**: (none)
- **Recorded At**: 2026-05-16T10:26:39Z
- **Next Action**: none
- **Rationale**: Delegated lifecycle routing was applied for role 'Reviewer'.

- **Routing Evidence**: Reviewer | requested=claude | actual=copilot | model=(platform default) | status=fell-back | fallback=preferred agent 'claude' is not enabled

## 2026-05-16T12:02:33Z — Delegated routing plan

- **Enabled Agents**: copilot
- **Independent Oversight Active**: False
- **Roles**:
  - Implementer | requested=copilot | actual=copilot | model=(platform default) | status=honored | fallback=(none)
  - Spec Steward | requested=codex | actual=copilot | model=(platform default) | status=fell-back | fallback=preferred agent 'codex' is not enabled
  - Planner | requested=claude | actual=copilot | model=(platform default) | status=fell-back | fallback=preferred agent 'claude' is not enabled
  - Reviewer | requested=claude | actual=copilot | model=(platform default) | status=fell-back | fallback=preferred agent 'claude' is not enabled
  - Retro Facilitator | requested=copilot | actual=copilot | model=(platform default) | status=honored | fallback=(none)

## 2026-05-16T12:02:33Z — Routing evidence: Spec Steward

- **Decision ID**: routing-evidence-51813d20b077
- **Type**: routing-evidence
- **Affected Requirement**: FR-043
- **Affected Iteration**: (none)
- **Approving Human**: (none)
- **Recorded At**: 2026-05-16T12:02:33Z
- **Next Action**: none
- **Rationale**: Delegated lifecycle routing was applied for role 'Spec Steward'.

- **Routing Evidence**: Spec Steward | requested=codex | actual=copilot | model=(platform default) | status=fell-back | fallback=preferred agent 'codex' is not enabled

## 2026-05-16T12:02:33Z — Routing evidence: Planner

- **Decision ID**: routing-evidence-4a2943e79954
- **Type**: routing-evidence
- **Affected Requirement**: FR-043
- **Affected Iteration**: (none)
- **Approving Human**: (none)
- **Recorded At**: 2026-05-16T12:02:33Z
- **Next Action**: none
- **Rationale**: Delegated lifecycle routing was applied for role 'Planner'.

- **Routing Evidence**: Planner | requested=claude | actual=copilot | model=(platform default) | status=fell-back | fallback=preferred agent 'claude' is not enabled

## 2026-05-16T12:02:34Z — Routing evidence: Reviewer

- **Decision ID**: routing-evidence-58e89b8ec8bf
- **Type**: routing-evidence
- **Affected Requirement**: FR-043
- **Affected Iteration**: (none)
- **Approving Human**: (none)
- **Recorded At**: 2026-05-16T12:02:33Z
- **Next Action**: none
- **Rationale**: Delegated lifecycle routing was applied for role 'Reviewer'.

- **Routing Evidence**: Reviewer | requested=claude | actual=copilot | model=(platform default) | status=fell-back | fallback=preferred agent 'claude' is not enabled


# Clarification Decision: Feature 019 Distribution Module

**Date**: 2026-05-16
**Agent**: Clarifier (explicit human authorization)
**Authority**: Alon Fliess (Feature Sponsor)
**Decision Type**: Clarify-boundary completion (all 10 questions resolved)

---

## Problem

Feature 019 Draft spec contained 10 open clarification questions (Q1-Q10) that required resolution before planning could begin. These questions covered critical design choices: template update pattern, distribution channels, module naming, API key management, signing strategy, backward compatibility, conflict resolution, cross-platform path handling, version policy, and migration path.

## Resolution

All 10 clarification questions have been resolved via explicit human authorization on 2026-05-16. Final verdicts integrated into spec.md:

### Q1: Update Story Pattern
**Decision**: Pattern B (Template-Refresh with preserve-and-flag conflict resolution)

**Rationale**: Specrew templates carry evolving methodology guidance. If templates can never be updated post-init, downstream projects cannot adopt Specrew evolution without manual re-bootstrap. Pattern B enables `specrew update` to refresh templates safely, with conflict resolution mediated by the protocol chosen in Q7.

**Extended by Q7**: The conflict-resolution protocol is designed to remain crew-framework-agnostic (not hard-coded only to Squad) to align with future Proposal 024 Multi-Host Runtime Abstraction, while naming Squad as the current provider in user-facing behavior.

### Q2: Distribution Channel Scope
**Decision**: PowerShell Gallery only for v1 (already resolved in prior session)

### Q3: Module Name on PSGallery
**Decision**: Specrew (canonical name; fallback SpeckitSpecrew if claimed) (already resolved in prior session)

### Q4: PSGallery API Key Management
**Decision**: GitHub Actions secret (name: `PSGALLERY_API_KEY`)

**Rationale**: Provides security (no local/codebase exposure), automation (tag-triggered publish), and Rule 15 integration without manual steps.

### Q5: Module Signing Strategy
**Decision**: Self-sign for v1, integrated into GitHub Action

**Rationale**: Quick setup, reduces trust warnings, avoids certificate acquisition lead time. Signing logic runs in publish workflow; cert material stored as GitHub Actions secret. Real codesign cert can be acquired post-v1 if user feedback indicates trust warnings are a blocker.

### Q6: Backward Compatibility with Clone-and-PATH
**Decision**: Support indefinitely (both distribution models coexist)

**Rationale**: Alpha users can continue clone-and-PATH workflow; new users can use `Install-Module`. README documents both paths; no forced migration.

### Q7: Template-Update Conflict Resolution
**Decision**: Preserve-and-flag with crew-mediated merge protocol (crew-framework-agnostic design)

**Rationale**: User-modified templates preserved with conflict markers (`<<<< USER / ==== / >>>> MODULE-v0.22`) and `.specrew/template-conflicts/<filename>.conflict` artifacts written for next-session review. Protocol designed to remain crew-framework-agnostic (not Squad-only) to align with future Proposal 024, but Squad is current provider for user-facing behavior.

### Q8: Cross-Platform Path Handling
**Decision**: Join-Path everywhere plus dedicated WSL verification task

**Rationale**: All path construction uses `Join-Path` for correct delimiters on all platforms. Implementation plan must include dedicated WSL verification task to validate real cross-platform behavior.

### Q9: Module Version Policy
**Decision**: Same version (manifest stamped from `.specrew/config.yml` at build time)

**Rationale**: Single source of truth reduces drift risk. Publishing workflow reads version from config and updates manifest before `Publish-Module`.

### Q10: Alpha-User Migration Path
**Decision**: README documentation only; `specrew update` is the migration path

**Rationale**: No automated migration command in v1. README docs sufficient; users run `Install-Module Specrew`, then `specrew update` in project to refresh templates. Tooling can be added later if friction reports indicate need.

---

## Spec Updates Made

### Requirements Updated
- **FR-020 through FR-023**: Made Template-Refresh pattern unconditional (removed "if Pattern B" conditional language)
- **FR-021**: Extended to specify crew-framework-agnostic conflict resolution protocol
- **FR-024 through FR-028**: Updated for GitHub Actions secret strategy and self-signing
- **FR-030**: Made Join-Path and WSL verification explicit

### User Stories Updated
- **US3**: Removed "pattern selection pending" note; specified preserve-and-flag conflict protocol
- **US4**: Updated to reflect GitHub Actions secret, self-signing, and manifest version stamping
- **US5**: Removed "cross-platform path handling strategy pending" note; specified WSL verification

### Other Sections Updated
- **Clarifications**: Added Q1 with full rationale; existing Q2-Q3 preserved; added Q4-Q10 with full rationale
- **Clarifications Pending**: Entire section removed (all questions resolved)
- **Assumptions**: Updated to reflect all resolved clarifications and crew-agnostic protocol design
- **Non-Goals**: Clarified that real certificate and migration tooling are deferred (not pending)
- **IN scope**: Updated to specify Pattern B explicitly

---

## Artifacts Updated

Files modified:
1. `specs/019-specrew-distribution-module/spec.md` — all 10 clarifications integrated, Clarifications Pending removed, Status remains Draft
2. `.squad/identity/now.md` — updated to reflect clarify-complete status, next action is await plan authorization
3. `.squad/decisions.md` — this decision entry appended

---

## Verification

- ✅ All 10 questions (Q1-Q10) resolved and recorded in spec.md Clarifications section
- ✅ Clarifications Pending section removed entirely from spec.md
- ✅ FR-020 through FR-023 updated to unconditional Template-Refresh language
- ✅ FR-021 specifies crew-framework-agnostic conflict resolution protocol
- ✅ FR-024 through FR-028 updated for GitHub Actions secrets and self-signing
- ✅ FR-030 updated for Join-Path and WSL verification
- ✅ User Stories 3, 4, 5 updated to remove conditional/pending language
- ✅ Assumptions section updated to reflect all resolved clarifications
- ✅ Non-Goals section clarified (deferred, not pending)
- ✅ Status remains Draft (correct for post-clarify, pre-plan state)
- ✅ .squad/identity/now.md updated to clarify-complete status
- ✅ No implementation code touched (artifact/state only boundary)

---

## Impact

The /speckit.clarify boundary for Feature 019 is now complete. All design choices are resolved and integrated into the Draft spec. The specification is ready for planning authorization (`/speckit.plan`) when explicitly authorized by the human sponsor.

Template-Refresh pattern (Pattern B) is confirmed with crew-framework-agnostic conflict resolution, enabling future evolution while respecting current Squad-mediated workflows and future Proposal 024 host abstractions.

---

## Next Action

Do not advance to `/speckit.plan` from this clarify-complete boundary alone. Await separate explicit human authorization before opening the planning boundary for Feature 019.

Authorization runtime: Feature 019 clarify completion authorized by Alon Fliess on 2026-05-16 at commit edd1ded (with local spec.md clarify edits present before boundary closeout).


# Planning Decision: Feature 019 /speckit.plan Boundary Complete

**Decision ID**: planner-feature019-plan-complete  
**Feature**: 019 — Specrew Distribution Module  
**Date**: 2026-05-16  
**Decision Maker**: Planner (autonomous planning boundary)  
**Authority**: User authorization for /speckit.plan boundary completion (2026-05-16)

---

## Decision Summary

Feature 019 implementation planning is complete with a 5-pillar distribution architecture (Module Packaging, Resource Bundling, Init Refactor, Update Story, Publishing Workflow). All design artifacts generated (plan.md, research.md, data-model.md, contracts/, quickstart.md). Constitution Check passed all gates. Estimated effort: 14 SP (within 10-15 SP spec estimate). Track dependencies mapped with critical path identified. Next boundary: `/speckit.tasks` (awaiting human authorization).

---

## Planning Scope

Feature 019 addresses the PowerShell Gallery module distribution requirement identified in user feedback (Venya's clone-and-PATH friction). The planning boundary encompasses:

1. **Phase 0 Research**: 6 research tasks resolving design unknowns (PSGallery best practices, module loader patterns, conflict resolution protocol, cross-platform path handling, publish workflow design, signing strategy)
2. **Phase 1 Design Artifacts**: 3 design artifacts defining implementation contracts (data-model.md, contracts/Specrew.psd1.contract.md, quickstart.md)
3. **Implementation Strategy**: 5-pillar architecture with dependency graph, critical path analysis, and parallelization opportunities
4. **Quality Planning**: Phase 1 quality gates (cross-platform correctness, template integrity, module packaging correctness, update conflict safety, publishing automation, credential management)
5. **Governance Alignment**: Constitution Check passed; all gates green; traceability verified

---

## Key Planning Decisions

### 1. Five-Pillar Implementation Architecture

**Decision**: Organize implementation into 5 major pillars aligned with spec requirements (FR-001 through FR-032):

| Pillar | Scope | Estimated SP |
| --- | --- | --- |
| Pillar 1: Module Packaging | Module manifest, exports, metadata | 2 SP |
| Pillar 2: Resource Bundling | Bundle scripts, extensions, templates, docs | 2 SP |
| Pillar 3: Init Refactor | Detect module-vs-clone, resolve templates from module path | 3 SP |
| Pillar 4: Update Story | Template-Refresh pattern, conflict resolution | 4 SP |
| Pillar 5: Publishing Workflow | GitHub Actions, version stamping, signing, publish | 3 SP |

**Total Estimated Effort**: 14 SP

**Rationale**: Pillars map 1:1 to spec sections (FR groups). Clear separation enables parallelization (Pillar 1 + 2 can run in parallel; Pillar 4 + 5 can run in parallel after Pillar 3). Total effort (14 SP) falls within spec estimate (10-15 SP) and fits single-iteration budget.

### 2. Template-Refresh Conflict Resolution Protocol (Git-Style Markers)

**Decision**: Use Git-style conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`) for user-vs-module template conflicts, backed by `.specrew/template-conflicts/*.conflict` artifacts with full diff.

**Rationale**: Git-style markers are universally recognized, supported by tooling (VSCode conflict resolution UI), and require zero learning curve. Conflict artifacts provide full context for manual resolution without data loss. Protocol is crew-framework-agnostic (no hard dependency on Squad internals).

**Research Evidence**: research.md R3 documents alternatives considered and decision rationale.

### 3. Cross-Platform Path Handling (Join-Path Everywhere + WSL Verification)

**Decision**: Enforce `Join-Path` for all path construction across scripts; add dedicated WSL verification task to validate real cross-platform behavior.

**Rationale**: PowerShell `Join-Path` automatically uses correct delimiters for current platform (Windows `\`, Linux/Mac `/`). Dedicated WSL task ensures real-world cross-platform correctness beyond unit tests (WSL is common Windows+Linux hybrid environment where path issues surface).

**Research Evidence**: research.md R4 documents audit strategy and verification checklist.

### 4. Module Version Stamping (Single Source of Truth: .specrew/config.yml)

**Decision**: Module manifest `ModuleVersion` is stamped from `.specrew/config.yml` `specrew_version` at build time via GitHub Actions workflow.

**Rationale**: Single source of truth reduces drift risk and eliminates version-sync governance burden. Aligns with spec clarification (Q9: "same version policy"). Publishing workflow reads config, updates manifest, validates, signs, and publishes.

**Research Evidence**: research.md R5 documents workflow structure and version stamping mechanism.

### 5. Self-Signed Certificate (5-Year Validity)

**Decision**: Use self-signed code signing certificate with 5-year validity period; store as GitHub Actions secrets (SIGNING_CERT_BASE64, SIGNING_CERT_PASSWORD).

**Rationale**: Balances security (moderate risk window) with maintenance burden (renewal every 5 years). Real codesign certificate deferred to post-v1 unless early feedback shows trust warnings are significant blocker.

**Research Evidence**: research.md R6 documents certificate generation procedure and validity period trade-offs.

### 6. Track Dependency Order (Critical Path Identified)

**Decision**: Implementation follows this dependency order:

```
Phase 0 (Research) → [Pillar 1 ∥ Pillar 2] → Pillar 3 → [Pillar 4 ∥ Pillar 5] → Integration Tests → Final Validation
```

**Critical Path**: Phase 0 → Pillar 1/2 → Pillar 3 → Pillar 4 → Final Validation

**Parallelization Opportunities**:
- Pillar 1 + Pillar 2 (independent; both feed into Pillar 3)
- Pillar 4 + Pillar 5 (independent after Pillar 3 completes)

**Rationale**: Pillar 3 (init refactor) depends on Pillar 1 (manifest structure) and Pillar 2 (template bundling layout). Pillar 4 (update) and Pillar 5 (publish) share init refactor's module-path detection logic but are otherwise independent. Critical path ensures incremental testability; parallelization opportunities reduce total cycle time.

---

## Plan-Time Design Questions Captured

Six design questions surfaced during planning but do not block the plan structure. Captured in plan.md for Phase 0 investigation:

1. **Module Manifest File List**: Explicit enumeration vs. automatic detection (trade-offs: safety vs. maintenance)
2. **Conflict Marker Format Details**: Exact marker syntax and language-aware alternatives (requires Squad integration validation)
3. **Cross-Platform Test Automation**: Manual checklist vs. GitHub Actions matrix (trade-offs: setup speed vs. robustness)
4. **Module Loader Implementation**: Explicit dot-sourcing vs. dynamic discovery (trade-offs: debuggability vs. DRY)
5. **PSGallery API Key Rotation**: Rotation cadence and procedure documentation (not a blocker; maintainer runbook item)
6. **Self-Signed Certificate Validity**: 1-year vs. 5-year vs. 10-year validity period (resolved in research as 5-year; question remains for renewal procedure)

All questions assigned to Phase 0 research tasks (R1-R6) or implementation-time decision points.

---

## Constitution Check: All Gates Passed

**Spec Authority Gate**: ✅ PASS (plan scope maps to spec FR-001 through FR-032, US-1 through US-5)  
**Layering Gate**: ✅ PASS (all changes in Spec Kit layer; Squad layer only provides runtime resolution behavior)  
**Traceability Gate**: ✅ PASS (all deliverables trace to user stories, FRs, and planned tasks)  
**Ownership Gate**: ✅ PASS (Spec Steward: Alon Fliess; Iteration Facilitator: Alon Fliess)  
**Capacity Gate**: ✅ PASS (14 SP estimated; single iteration; fits Phase 2 Quality Hardening Bundle sequencing)  
**Drift/Reconciliation Gate**: ✅ PASS (drift detection via Specrew-Speckit validators, integration tests, publish logs; reconciliation path defined)  
**Verification Gate**: ✅ PASS (process verification: validators + GitHub Actions validation; outcome verification: success criteria SC-001 through SC-006 + User Story acceptance scenarios)

**No violations detected.** Implementation may proceed to `/speckit.tasks` boundary.

---

## Artifacts Generated

**Phase 0 (Research)**:
- `specs/019-specrew-distribution-module/research.md` (6 research tasks; all design unknowns resolved)

**Phase 1 (Design)**:
- `specs/019-specrew-distribution-module/data-model.md` (11 entities, relationships, state machines)
- `specs/019-specrew-distribution-module/contracts/Specrew.psd1.contract.md` (module manifest schema, exported function signatures)
- `specs/019-specrew-distribution-module/quickstart.md` (user-facing installation and usage guide)

**Planning Artifact**:
- `specs/019-specrew-distribution-module/plan.md` (5-pillar strategy, track dependencies, Constitution Check, quality gates, implementation strategy)

**Squad State Updates**:
- `.squad/identity/now.md` (updated to reflect /speckit.plan complete; next valid action: /speckit.tasks authorization)
- `.squad/decisions.md` (this decision appended)

---

## Boundary Verification

**Pre-Commit Checklist**:
- ✅ plan.md complete with all template sections filled
- ✅ research.md complete with 6 research tasks documented
- ✅ data-model.md complete with 11 entities and relationships
- ✅ contracts/Specrew.psd1.contract.md complete with manifest schema and function signatures
- ✅ quickstart.md complete with user-facing installation guide
- ✅ Constitution Check passed (all gates green)
- ✅ Track dependency graph documented with critical path identified
- ✅ Plan-time design questions captured (6 questions for Phase 0 investigation)
- ✅ Quality gates defined (cross-platform, template integrity, publish automation, credential management)
- ✅ Effort estimated (14 SP; within spec estimate 10-15 SP)
- ✅ .squad/identity/now.md updated (next valid action: /speckit.tasks authorization)
- ✅ .squad/decisions.md updated (this decision appended)

**NOT Delivered** (scope boundaries respected):
- ❌ /speckit.tasks generation (not authorized at this boundary)
- ❌ Implementation execution (requires /speckit.tasks first)
- ❌ Code changes to scripts/ or extensions/ (implementation-time work)
- ❌ GitHub Actions workflow creation (implementation-time work)
- ❌ PSGallery module publishing (post-implementation work)

---

## Next Action

**For Spec Steward (Alon Fliess)**:
- Review planning artifacts (plan.md, research.md, data-model.md, contracts/, quickstart.md)
- Verify Constitution Check passes and track dependencies are sound
- Authorize `/speckit.tasks` boundary if planning is acceptable

**For Implementation Team** (after /speckit.tasks authorization):
- Read research.md (Phase 0 output) before starting implementation
- Review data-model.md, contracts/, quickstart.md as implementation blueprints
- Follow track dependency order (see plan.md Track Dependencies graph)
- Execute quality gates after each pillar completes
- Record evidence in `specs/019-specrew-distribution-module/test-evidence/`

---

## Traceability

- **Spec Authority**: `specs/019-specrew-distribution-module/spec.md` (FR-001 through FR-032, US-1 through US-5)
- **Plan Authority**: `specs/019-specrew-distribution-module/plan.md` (5-pillar strategy, track dependencies, Constitution Check)
- **User Authorization**: Alon Fliess authorized /speckit.plan boundary completion on 2026-05-16 (this session)
- **Constitutional Alignment**: Principles I (Spec Is Authoritative), IX (Mandatory Traceability), XVII (Planning Starts From Approved Specs), XXI (Verification Is Mandatory)

---

## Notes

- This decision is autonomous planning-boundary work; no implementation choices are encoded here.
- Feature 019 remains in `planning-complete` status until /speckit.tasks authorization is granted.
- All traceability is recorded in the canonical plan (plan.md); this document is a summary for coordination visibility.
- Phase 2 hardening gate is explicitly deferred (distribution infrastructure focus; no complex security surface or runtime business logic).


# Decision: Feature 019 /speckit.tasks Boundary Complete

**Date**: 2026-05-16
**Agent**: Copilot
**Authority**: Alon Fliess (user directive: "Complete the /speckit.tasks boundary for Feature 019")
**Decision Type**: Tasks-boundary completion

## What

Generated comprehensive task breakdown for Feature 019 (Specrew Distribution Module) with 39 tasks across 6 phases, completing the /speckit.tasks lifecycle boundary.

### Artifacts Created

- **tasks.md**: Complete task breakdown (39 tasks, 6 phases, 14 SP total)
  - Phase 0: Design-Question Resolution (6 tasks)
  - Pillar 1: Module Packaging (3 tasks)
  - Pillar 2: Resource Bundling (5 tasks)
  - Pillar 3: Init Refactor (5 tasks)
  - Pillar 4: Update Story (6 tasks)
  - Pillar 5: Publishing Workflow (7 tasks)
  - Phase 6: Final Validation (7 tasks)

### Six Design-Question Resolution Tasks

Per user requirement, six design-question resolution tasks are explicitly enumerated at Phase 0:

1. **T001**: Resolve Module Manifest File-List Strategy (blocks Pillar 1/2)
2. **T002**: Resolve Conflict-Marker Format (blocks Pillar 4)
3. **T003**: Resolve Cross-Platform Test Automation Depth (blocks Pillar 5)
4. **T004**: Resolve Module Loader Structure (blocks Pillar 1)
5. **T005**: Document API-Key Rotation Guidance (documentation-only)
6. **T006**: Resolve Self-Signed Certificate Validity Period (blocks Pillar 5)

Each task includes explicit "Blocks" annotations showing downstream dependencies and "Downstream Impact" rationale explaining why the decision matters.

### Task Organization

- **By Pillar**: Tasks organized following plan.md 5-pillar architecture
- **Explicit Dependencies**: Each task annotates blocking dependencies with task IDs
- **Parallel Opportunities**: 16+ tasks marked [P] for parallel execution
- **Traceability**: Every task traces to FR, US, and plan.md tracks
- **Critical Path**: Phase 0 → P1/P2 (parallel) → P3 → P4/P5 (parallel) → Validation

### State Updates

- **.squad/identity/now.md**: Updated to TASKS-COMPLETE lifecycle stage
- **focus_area**: Feature 019 /speckit.tasks completed
- **active_issues**: 39 tasks enumerated, six design questions explicitly listed
- **Next valid action**: Await authorization before advancing to hardening gate or implementation

## Why

The /speckit.tasks boundary completion enables implementation authorization by providing:

1. **Concrete Work Units**: 39 actionable tasks with explicit file paths and verification commands
2. **Dependency Clarity**: Task blocking relationships prevent premature work and rework
3. **Design-Question Resolution**: Six plan-time questions surfaced during planning now have dedicated resolution tasks before implementation begins
4. **Parallel Execution Planning**: 16+ parallel-capable tasks identified for efficient execution
5. **Traceability**: Every task maps to FRs, user stories, and plan tracks per Constitution Principle IX

## Traceability

- **Spec Authority**: specs/019-specrew-distribution-module/spec.md (FR-001 through FR-032, US1-US5)
- **Plan Authority**: specs/019-specrew-distribution-module/plan.md (5-pillar architecture, Phase 0 research, Phase 1 design artifacts)
- **User Directive**: "Complete the /speckit.tasks boundary for Feature 019" (2026-05-16)
- **Constitution Alignment**: Principle IX (Mandatory Traceability), Principle XVII (Planning Starts From Approved Specs), Principle XXI (Verification Is Mandatory)

## Runtime Evidence

**Files Changed**:
- Created: specs/019-specrew-distribution-module/tasks.md (26,676 characters, 39 tasks)
- Updated: .squad/identity/now.md (lifecycle stage: TASKS-COMPLETE)
- Updated: .squad/decisions.md (this entry)

**Task-Count-Per-Pillar Summary**:
- Phase 0 (Design Questions): 6 tasks
- Pillar 1 (Module Packaging): 3 tasks
- Pillar 2 (Resource Bundling): 5 tasks
- Pillar 3 (Init Refactor): 5 tasks
- Pillar 4 (Update Story): 6 tasks
- Pillar 5 (Publishing Workflow): 7 tasks
- Phase 6 (Final Validation): 7 tasks
- **Total**: 39 tasks

**Verification**:
`powershell
Test-Path C:\Dev\Specrew\specs\019-specrew-distribution-module\tasks.md
# Expected: True (file exists)
Get-Content C:\Dev\Specrew\specs\019-specrew-distribution-module\tasks.md | Select-String -Pattern "^- \[ \] T\d{3}"
# Expected: 39 matches (all 39 tasks present)
`

## Scope Confirmation

**Scope In**:
- ✅ Generated tasks.md from plan.md + spec.md
- ✅ Six design-question resolution tasks explicitly enumerated with blocking annotations
- ✅ Ordered, concrete, actionable tasks with per-task scope, owner, dependencies, acceptance criteria, and explicit FR references
- ✅ Preserved implementation ordering from plan: Phase 0 → Pillars 1 & 2 (parallel) → Pillar 3 → Pillars 4 & 5 (parallel) → final validation
- ✅ Updated .squad/identity/now.md to TASKS-COMPLETE stage
- ✅ Appended decisions.md entry for tasks-boundary runtime evidence

**Scope Out**:
- ❌ No code changes under scripts/ or extensions/
- ❌ No validator additions beyond task planning language
- ❌ No /speckit.specrew-speckit.before-implement work
- ❌ No hardening-gate or implementation work

## Next Action

Await explicit authorization before advancing to:
- /speckit.specrew-speckit.before-implement (hardening gate, if applicable)
- Implementation (if hardening gate skipped or passed)

Per user directive: "Do NOT advance to /speckit.specrew-speckit.before-implement. Do NOT advance to hardening-gate-and-implementation-auth."


# Repair: Feature 019 Before-Implement Lifecycle State Artifact

**Date**: 2026-05-16  
**Authority**: Reviewer (boundary-state tightly-coupled repair)  
**Scope**: `.squad/identity/now.md` lifecycle section state correction  

## What

The state artifact `.squad/identity/now.md` contained stale lifecycle information after the Feature 019 before-implement boundary was crossed:
- **Top lines (correct)**: Reported `/speckit.specrew-speckit.before-implement` completed with READY verdict
- **Lifecycle section (stale)**: Reported `/speckit.tasks` complete and listed authorization for before-implement as next action

This mismatch created boundary-state confusion: the top and bottom of the artifact contradicted each other about which lifecycle phase was active.

## Repair Applied

1. Updated "What We're Focused On" phase line from `/speckit.tasks` complete → `/speckit.specrew-speckit.before-implement` complete
2. Updated urgency line to reference `hardening-gate-and-implementation-auth` authorization (next valid action after before-implement)
3. Updated Feature Lifecycle status from `TASKS-COMPLETE` → `BEFORE-IMPLEMENT-COMPLETE`
4. Updated "Current Status" section references from `/speckit.tasks` → `/speckit.specrew-speckit.before-implement`
5. Updated "Authorization scope" line to clarify before-implement is complete and implementation is blocked pending authorization
6. Updated "Next Valid Action" section to await explicit human authorization for `hardening-gate-and-implementation-auth` only

## Why

Lifecycle artifacts must be consistent at all points to avoid automation, planner, or coordinator tools making incorrect routing decisions based on stale phase information. The boundary was crossed and verified; the state record must reflect that fact durably.

No lifecycle boundary advancement applied; only state artifact corrected to match the actual completed boundary.

