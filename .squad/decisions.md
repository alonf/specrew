# Squad Decisions

## Active Decisions

### 2026-04-18: Iteration 0 Execution-Phase Closure Complete

**By**: Data (Planner)  
**Date**: 2026-04-18  
**What**: Iteration 0 execution phase is now contract-complete and ready for retrospective.

#### Artifacts Created/Updated

| Artifact | Action | Status |
|----------|--------|--------|
| `plan.md` | Updated metadata (Status → `complete`, Capacity → `20.5/20.5`, Completed → `2026-04-18`) | ✅ Complete |
| `state.md` | Verified present (La Forge) | ✅ Complete |
| `drift-log.md` | Created (0 events) | ✅ Complete |
| `review.md` | Verified present (Worf) | ✅ Complete |
| `retro.md` | Pending Troi (Retro Facilitator) | ⏳ Pending |

#### Contract Compliance

Per `contracts/iteration-artifacts.md`:
- ✅ **Iteration Plan**: Metadata complete; Status, Capacity, Started, Completed all present
- ✅ **Task State**: Last completed task, tasks remaining, in-progress status recorded
- ✅ **Drift Log**: Event ledger present (0 events); schema compliant
- ✅ **Review**: Verdict recorded; acceptance gates passed
- ⏳ **Retrospective**: Pending Troi — owned by retrospective ceremony

**Decision**: Iteration 0 execution-phase closure is **contract-complete and approved for retrospective handoff**.

---

### 2026-04-18: Governance Hardening Implementation

**By**: Picard (Spec Steward)  
**Date**: 2026-04-18  
**Status**: Implemented  

Four governance artifacts created/updated to make Specrew's iteration lifecycle normative and binding:

1. **Spec.md**: Added Iteration Lifecycle Contract Section with Phase State Machine
2. **contracts/iteration-artifacts.md**: Made State Machine explicit with Phase Rules and Validation Gates
3. **.squad/protocol.md**: Single Coordinator Protocol with all roles, rules, and decision workflows
4. **Dogfooding Obligation**: Clarified Specrew uses its own iteration lifecycle

**Decision**: Governance hardening complete. Iteration 1 execution proceeds under protocol.md rules.

---

### 2026-04-19: Iteration 1 Live Plan Traceability Fix

**Date**: 2026-04-19  
**Owner**: Data (Planner)  
**Type**: Planning alignment  
**Status**: Complete

Iteration 1 plan.md corrected for contract compliance:

1. **Test Task Requirement Mapping**: T-020, T-021, T-022 mapped to FRs
   - T-020 → FR-005, FR-006 (iteration lifecycle + planning)
   - T-021 → FR-008, FR-009 (drift detection + review)
   - T-022 → FR-013 (CI validation)

2. **Phase Baseline Structure**: Added per-phase effort allocation (Planning 2, Impl 16, Review 1, Rework 1.5)

3. **Target FRs Updated**: Added FR-013 to scope list

4. **Governance Wording**: Tightened verdicts to reference test task mappings

#### Validation

✅ All tasks T-001–T-022 now have requirement references  
✅ Phase Baseline section added per contract  
✅ Traceability 100%: every task maps to at least one FR  

**Decision**: Plan ready for validation with full traceability audit compliance.

---

### 2026-04-19: Normalize Validator Collections Under Strict Mode

**Date**: 2026-04-19  
**Owner**: La Forge (Implementer)  

Fixed `validate-governance.ps1` collection-handling under strict mode:

- Wrapped array-producing operations consistently
- Made `Get-MarkdownContent` return concrete arrays
- Normalized `Get-MarkdownSectionTable` row outputs
- Wrapped optional artifact reads before counting

#### Outcomes

✅ Iteration `000` passes cleanly  
✅ Iteration `001` now fails for real contract issues (not runtime exceptions):
  - Missing `Started` metadata in plan.md
  - Task `T-022` missing `Story` reference

**Decision**: Validator repair accepted. Correctly enforces actual artifact defects.

---

### 2026-04-19: Iteration 1 Governance Re-Review

**Date**: 2026-04-19  
**Reviewer**: Worf (Review Steward)  
**Verdict**: NEEDS-WORK  
**Execution Ready**: No

#### Contract Violations Found

1. **plan.md line 7**: `**Started**:` is blank (contract requires `YYYY-MM-DD`)
2. **Task T-022**: `Story` cell is blank (contract requires reference)

#### Review Judgment

| Artifact | Status | Owner | Rationale |
|----------|--------|-------|-----------|
| plan.md | Rejected | Picard (next) | Fails validator; not execution-ready |
| validate-governance.ps1 | Accepted | None | Correctly exposes defects |

**Lockout Applied**: Data locked out from next plan revision cycle

**Decision**: Iteration 1 NOT execution-ready. Picard owns next revision; must populate `Started` and fix T-022 `Story`.

---

### 2026-04-19: Iteration 1 Pre-Execution Risk Assessment

**Date**: 2026-04-19  
**Prepared by**: Picard (Spec Steward)  
**Status**: Ready for Alon approval

Three HIGH-priority architecture spikes must clear before planning ceremony:

#### Risk #1: Directive-to-Charter Mapping Ambiguity

**Problem**: Iteration 1 introduces directives (T-012–T-014) with no precedent. Mapping and enforcement unspecified.

**Mitigation**: Create reference directive in `.squad/directives/spec-authority.md`, embed in charter, verify Squad loads. Document in `.squad/directives/README.md`.

**Blocker**: T-012–T-014 cannot sign off without proof directive loads.

#### Risk #2: Ceremony Artifact Sequencing Contract

**Problem**: Planning ceremony must produce 100% traceable plan.md; review ceremony validates against it. LLM drift risk.

**Mitigation**: Validate schema matches contract. Run sample plan→review cycle. Verify verdicts map cleanly.

**Blocker**: If schema ambiguous, review gate fails and iteration cannot close.

#### Risk #3: Extension Integration Surfacing Gap

**Problem**: T-005–T-007 deployment lacks collision handling. Partial failure leaves inconsistent state.

**Mitigation**: Simulate fresh bootstrap. Run deployment steps. Verify no errors. Document checklist in `.squad/scripts/deploy-extensions-checklist.md`.

**Blocker**: If deployment fails, bootstrap broken and US-1 fails.

#### Spike Roadmap

| Risk | Owner | Status |
|------|-------|--------|
| #1: Directive | La Forge | ⏳ Planned |
| #2: Ceremony | Data | ⏳ Planned |
| #3: Deployment | La Forge | ⏳ Planned |

**Decision**: All three spikes approved. Execute in parallel before planning ceremony.

---

### 2026-04-19: Iteration 1 Operating Policy Consensus Check

**Facilitator**: Troi (Retro Facilitator)  
**Date**: 2026-04-19  
**Verdict**: NEEDS-DECISION (implementation readiness gates pending)

Six core operating rules assessed:

| Rule | Status | Barrier |
|------|--------|---------|
| Spec-Authority Gate (planning) | ✅ Embedded | None |
| Architecture-Risk Spikes (pre-planning) | ⏳ Identified | Need schedule |
| Traceability Check (planning) | ✅ Embedded | None |
| Retro Autonomous (fixed schedule) | ✅ Adopted | None |
| Drift-Reporting Directive (bootstrap) | ⏳ Planned | Need charter embed |
| Phase-Level Estimation (templates) | ⏳ Planned | Need updates |

#### Implementation Readiness

Before planning ceremony:

- [ ] **Picard + La Forge**: Schedule 2–3 spikes (Rule 2) — Target: 2026-04-19
- [ ] **Alon**: Confirm retro schedule policy — Target: 2026-04-19
- [ ] **Data**: Update templates with per-phase tracking (Rule 6) — Target: 2026-04-20

#### Team Consensus

No objections to rules' intent. Consensus on *what*; remaining work is *how* and *when*.

**Recommendation**: Execute spikes pre-planning (Option A) to surface dependencies before task assignment.

**Decision**: Policy is consensus-sound. Implementation tasks + spike schedule confirmation complete readiness gate.

---

### 2026-04-19: Iteration 1 Plan Revision for Governance Gate

**By**: Picard (Spec Steward)  
**Reviewed by**: Worf (Iteration 1 Governance Re-Review)  
**Date**: 2026-04-19  
**Scope**: Narrow defect correction only  
**Outcome**: PASS

**Problem**: Two contract violations blocked execution:
1. Missing `Started` metadata (blank, should be `YYYY-MM-DD`)
2. Task T-022 missing `Story` reference

**Resolution**:
- Set `Started: 2026-04-19` (governance review date, marks planning completion)
- Map T-022 to `US-2` ("Run planned iteration end-to-end") — CI pipeline validates full lifecycle

**Validation**: Re-ran validator → PASS on iterations 000 and 001

**Decision**: Both defects resolved, plan contract-compliant. Execution ready.

---

### 2026-04-19: Iteration 1 Final Governance Gate

**By**: Worf (Review Steward)  
**Requested by**: Alon Fliess  
**Date**: 2026-04-19  
**Verdict**: PASS  
**Execution Ready**: Yes

**Scope**: Final verification of plan.md against iteration-artifacts.md contract

**Prior Rejection Reasons Re-Checked**:
- ✅ `Started` metadata: Now present in `YYYY-MM-DD` format (2026-04-19)
- ✅ T-022 Story reference: Now maps to US-2

**Validator Evidence**:
```
PASS C:\Dev\Specrew\specs\001-specrew-product\iterations\000
PASS C:\Dev\Specrew\specs\001-specrew-product\iterations\001
```

**Final Determination**: PASS. Iteration 1 passes governance gate and is execution-ready in reviewer terms.

---

### 2026-04-19: Iteration 1 Git Tracking (Finalized)

**By**: La Forge (Implementer)  
**Date**: 2026-04-19  
**Scope**: Plan artifact git tracking  
**Outcome**: Complete

Staged `specs/001-specrew-product/iterations/001/plan.md` to git index for audit traceability. Plan was present in worktree but untracked. No `.gitignore` rule adjustment required. Minimum git-state correction applied.

**Decision**: Plan now tracked and execution-ready state is git-auditable.

---

### 2026-04-19: Bootstrap Guardrails — Iteration 1, Slice 1: `specrew init`

**By**: Picard (Spec Steward)  
**Date**: 2026-04-19  
**Scope**: Guard La Forge's bootstrap CLI implementation against spec drift  
**Status**: Alignment gates READY

Bootstrap guardrail document establishes approved scope for `specrew init`, explicit deferred boundaries, and drift markers that would violate FR-001, FR-002, FR-011, FR-013.

**Key Constraints**:
- ✅ Greenfield initialization only (Iteration 1); brownfield deferred to Iteration 2
- ✅ NO `extensions/specrew-squad/` package; use native Squad layout
- ✅ Extension registration through documented surfaces only
- ✅ Protected paths never overwritten; additive merges only
- ✅ Five baseline roles: Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator
- ✅ Downstream governance as template, not Specrew's own

**Acceptance Gates**: 8 gates defined (greenfield path, version validation, collision detection, brownfield graceful defer, no undocumented APIs, FR-011 compliance, no scope creep, acceptance testing).

**Decision**: ✅ READY FOR BOOTSTRAP IMPLEMENTATION.

---

### 2026-04-19: Bootstrap Spine Slice — `specrew init` Implementation Complete

**By**: La Forge (Implementer)  
**Date**: 2026-04-19  
**Scope**: Iteration 1 bootstrap execution slice

Implemented the first working `specrew init` spine as a standalone root script plus supporting scripts:

**Deliverables**:
1. ✅ **Dependency and version gate**: `validate-versions.ps1` detects Spec Kit and Squad from CLIs; installs missing; blocks incompatible versions
2. ✅ **Greenfield platform init**: `specrew-init.ps1` orchestrates dependency validation, `specify init`, `squad init`, governance scaffolding
3. ✅ **Governance separation**: Writes `.specrew/config.yml`, `.specrew/constitution.md`, `.specrew/iteration-config.yml`, `.specrew/role-assignments.yml`

**Explicit Scope Boundary / Pending Gap**:

This slice intentionally stops **before**:
- Spec Kit extension deployment into `.specify/extensions/specrew-speckit/`
- Squad runtime surface deployment into `.copilot/skills/` and `.squad/`
- Baseline role merge into `.squad/team.md`

These remain the next bootstrap slice to align with Iteration 1 task sequencing.

**Evidence**: 
- Dry-run succeeds for the new root bootstrap script
- Smoke bootstrap against fresh local workspace succeeded end-to-end for dependency validation, `specify init`, `squad init`, `.specrew/*` governance artifact creation

**Decision**: Bootstrap spine implementation slice COMPLETE and READY for next slice (extension deployment).

---

### 2026-04-19: Complete `specrew init` Deployment Slice

**By**: La Forge (Implementer)  
**Date**: 2026-04-19  
**Scope**: Iteration 1 bootstrap deployment phase

Implemented the remaining greenfield deployment path needed for `specrew init` to become materially useful:

1. **Spec Kit Extension Deployment**
   - Added `deploy-speckit-extension.ps1`
   - Copies bundled `specrew-speckit` assets into `.specify/extensions/specrew-speckit/`
   - Registers `specrew-speckit` additively in `.specify/extensions.yml`

2. **Squad Runtime-Surface Deployment**
   - Added `deploy-squad-runtime.ps1`
   - Deploys Specrew skills into `.copilot/skills/specrew-*/SKILL.md`
   - Appends Specrew ceremony blocks to `.squad/ceremonies.md`
   - Seeds baseline role charters under `.squad/agents/`
   - Merges directive blocks into relevant role charters

3. **Baseline Role Merge**
   - Merges five baseline roles into `.squad/team.md`
   - Uses additive-only writes; preserves existing team entries

4. **Bootstrap Hardening**
   - Fixed native-command exit-code handling under strict mode
   - Missing or wrapped CLIs do not crash version detection or bootstrap orchestration

**Execution Boundary**: Stays on approved greenfield path. Brownfield conflict negotiation remains deferred (FR-020).

**Validation**: 
- `specrew-init.ps1` dry-run against fresh workspace ✅
- Live smoke bootstrap against fresh workspace ✅
- PSScriptAnalyzer on bootstrap scripts ✅

**Decision**: ✅ **DEPLOYMENT SLICE 2 COMPLETE**. `specrew init` now carries full bootstrap from dependency validation through governance scaffolding without replacing approved spine.

---

### 2026-04-19: Deployment Guardrails — Iteration 1, Slice 2: Runtime Surface Deployment

**By**: Picard (Spec Steward)  
**Date**: 2026-04-19  
**Scope**: Guard La Forge's deployment slice (extension deployment + role merge) against spec drift  
**Status**: Alignment gates READY

#### What IS In Scope (Slice 2)

1. **Spec Kit Extension Installation** (T-005): Per contract, copy extension files + manual register in `.specify/extensions.yml`; never overwrite existing file
2. **Squad Skills Deployment** (T-006): Copy Specrew skills to `.copilot/skills/specrew-*/` per Squad native layout
3. **Squad Ceremonies Merge** (T-007): Merge Specrew ceremonies into `.squad/ceremonies.md`; preserve existing entries
4. **Directive Embedding**: Merge Specrew directives into `.squad/agents/*/charter.md`; additive-only
5. **Baseline Role Merge** (T-008): Merge 5 baseline roles (Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator) into `.squad/team.md`

#### What is DEFERRED

- **FR-020** (Brownfield bootstrap) → Iteration 2
- **FR-007** (Configurable effort model) → Iteration 2
- **FR-012** (Five-class collision detector) → Iteration 3
- **Directive logic** (T-012–T-014) — Text merge only in this slice
- **Ceremony logic** (T-015–T-017) — Definitions only in this slice

#### Acceptance Gates (8 gates)

1. ✅ Greenfield path only — Additive merges, never delete/overwrite
2. ✅ Extension registration surfaces documented
3. ✅ Squad native layout — No packaged plugin
4. ✅ Five baseline roles present and correctly named
5. ✅ Collision handling — Prompt on role-name conflicts
6. ✅ Protected paths honored — Never touch user constitution or templates
7. ✅ FR-011 governance artifact compliance
8. ✅ Acceptance testing — Fresh greenfield smoke test passes

**Blockers**: None identified. Source requirements coherent.

**Decision**: ✅ **READY FOR DEPLOYMENT SLICE 2 IMPLEMENTATION**. Scope narrow, boundaries clear, requirements coherent. Proceed with T-005–T-008.

---

### 2026-04-19: Worf Review: Bootstrap Slice 2

**By**: Worf (Reviewer)  
**Date**: 2026-04-19  
**Requested by**: La Forge / Picard  
**Verdict**: PASS  
**Iteration 1 Increment Valid**: Yes

#### Scope Reviewed

Deployment slice 2 as scoped by Picard:

1. Spec Kit extension deployment to `.specify/extensions/specrew-speckit/`
2. Squad skills deployment to `.copilot/skills/specrew-*/`
3. Squad ceremonies merge into `.squad/ceremonies.md`
4. Directive embedding into `.squad/agents/*/charter.md`
5. Baseline role merge into `.squad/team.md`

#### Evidence

✅ All 5 baseline roles present in deployment scripts  
✅ Extension registration logic uses documented Spec Kit surfaces  
✅ Squad native layout respected (no packaged plugin)  
✅ Protected paths honored (additive-only merges)  
✅ Collision handling implemented (prompts on conflicts)  
✅ Smoke test on fresh bootstrap passes  

#### Review Judgment

Deployment scope is narrow, gates explicit, and implementation aligned. Slice materials qualify for execution under eight-gate acceptance framework.

**Determination**: **PASS.** Slice 2 is deployment-ready. Proceed with T-005–T-008 execution.

---

## Inbox Decisions Merged

**Merge Date**: 2026-04-19T20:24:18Z  
**Inbox Files Deleted**: 3 decision files merged

1. `laforge-deploy-runtime-surfaces.md` → Complete `specrew init` Deployment Slice
2. `picard-deploy-guardrails.md` → Deployment Guardrails — Iteration 1, Slice 2
3. `worf-bootstrap-slice-review.md` → Worf Review: Bootstrap Slice 2

**Prior Merges**: 2026-04-19T02:08:48Z (2 files); 2026-04-19T07:43:21Z (1 file); 2026-04-19T195521Z (2 files)

**Total Inbox Merges (Current)**: 3 files merged this session → Inbox now empty

**Deduplication**: No duplicates. All decisions indexed chronologically in main ledger.
