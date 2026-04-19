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

### 2026-04-19: Runtime-Surface Drift Reconciliation

**By**: Picard (Spec Steward)  
**Date**: 2026-04-19  
**Scope**: Reconcile Squad runtime deployment behavior against authoritative sources  
**Outcome**: ACCEPTED  

Corrected contract/template documentation and ceremonies README to align Specrew source-of-truth with Squad runtime behavior:

#### Finding 1: `iteration-resume` mismatch
- **Disposition**: Correct source-of-truth docs, not runtime
- **Reasoning**: `spec.md` places FR-019 in Iteration 2; `deploy-squad-runtime.ps1` correctly excludes it
- **Accepted**: Mark `specrew-iteration-resume` as deferred source stub until FR-019 enters scope

#### Finding 2: Retrospective deployment drift
- **Disposition**: Source-of-truth clarification; implementation follow-up for La Forge
- **Reasoning**: `spec.md` FR-005 already authoritative; retrospective uses Squad built-in
- **Accepted**: Recast `squad-templates\ceremonies\retro.md` as built-in retrospective guidance only
- **Follow-up**: `deploy-squad-runtime.ps1` must stop appending `retro.md` into `.squad/ceremonies.md`

#### Finding 3: Hardcoded `Chief Architect`
- **Disposition**: Correct source templates now
- **Reasoning**: Downstream baseline roles are five neutral roles (FR-002); `Chief Architect` is project-specific
- **Accepted**: Replace with `Project Owner (optional)` in planning/review/retro source templates

**Decision**: All source-of-truth corrections accepted. No FR-019 scope creep. No unrelated expansions.

---

### 2026-04-19: Ceremonies README Runtime Alignment

**By**: La Forge (Implementer)  
**Date**: 2026-04-19  
**Scope**: Narrow correction of ceremonies README mismatch  
**Outcome**: ACCEPTED + RE-REVIEW PASS  

**Problem**: Worf's rejection identified ceremonies README as the only remaining documentation/runtime mismatch. README documents retrospective as appended ceremony, but contract + runtime state it is Squad built-in guidance only.

**Resolution**:
- Fixed `extensions\specrew-speckit\squad-templates\ceremonies\README.md` (line 5)
- Stated only `planning.md` and `review-demo.md` are appended ceremonies
- Moved retrospective documentation to guidance section (lines 26-32)
- Removed erroneous `Specrew: Retrospective` ceremony claim

**Re-Review Verdict (Worf)**: PASS — Prior rejection reason closed; README now aligns with contract + runtime.

**Decision**: Ceremonies README now matches live deployment behavior without reintroducing duplicate retrospective surface.

---

### 2026-04-19: Runtime-Surface Drift Review Verdict

**By**: Worf (Reviewer)  
**Date**: 2026-04-19  
**Scope**: Initial review of Squad runtime drift corrections  
**Verdict**: NEEDS-WORK → Re-Review PASS  

#### Initial Review Findings

| Acceptance Point | Status | Evidence |
|---|---|---|
| `iteration-resume` deferred | ✅ PASS | Deploy script excludes; source docs mark as Iteration 2 stub |
| Retrospective remains Squad built-in | ❌ FAIL | README still documents `Specrew: Retrospective` appended ceremony |
| Baseline role language compatible | ✅ PASS | `Project Owner (optional)` replaces `Chief Architect` |
| No scope creep | ✅ PASS | No FR-019 implementation; no unrelated expansions |

**Required Correction**: Fix `extensions\specrew-speckit\squad-templates\ceremonies\README.md` to match runtime model.

#### Re-Review Findings

After La Forge's narrow revision:
- ✅ `README.md` line 5 states only planning.md and review-demo.md appended
- ✅ Lines 26-32 describe retrospective as built-in guidance, not appended ceremony
- ✅ Prior rejection reason closed

**Final Verdict**: PASS — Ceremonies README now aligns with contract and runtime without duplicate retrospective surface.

**Decision**: Runtime-surface drift correction complete. All source docs and ceremonies README traceable to authoritative spec.md + deploy script behavior.

---

## Inbox Decisions Merged

**Merge Date**: 2026-04-19T20:40:24Z  
**Inbox Files Deleted**: 4 decision files merged

1. `picard-drift-reconcile.md` → Runtime-Surface Drift Reconciliation
2. `laforge-ceremonies-readme-fix.md` → Ceremonies README Runtime Alignment
3. `worf-runtime-drift-review.md` → Runtime-Surface Drift Review Verdict
4. `worf-ceremonies-readme-rereview.md` → Re-review verdict (consolidated into review decision)

**Prior Merges**: 2026-04-19T02:08:48Z (2 files); 2026-04-19T07:43:21Z (1 file); 2026-04-19T195521Z (2 files); 2026-04-19T20:24:18Z (3 files)

**Total Inbox Merges (Current)**: 4 files merged this session → Inbox now empty

**Deduplication**: No duplicates. All decisions indexed chronologically in main ledger.

---

### 2026-04-19: Deployment Slice Review — `specrew init` Runtime Surfaces

**By**: Worf (Reviewer)  
**Date**: 2026-04-19  
**Requested by**: Alon Fliess  
**Scope reviewed**: Approved deployment slice only (Spec Kit extension deployment, Squad runtime surfaces, baseline role merge)  
**Verdict**: NEEDS-WORK

#### Judgment

This increment is **not yet acceptable as the approved bootstrap deployment slice**.

The mechanics are real: I verified a fresh dry-run and a live smoke bootstrap, and the bootstrap does deploy the Spec Kit extension, baseline role charters, directives, and `.squad/team.md` entries. That effort does not clear the review gate because the deployed slice misses part of the approved runtime-surface payload and also ships a deferred surface not authorized by this slice.

#### Evidence — Rejection

1. **Retro ceremony runtime surface is not deployed**
   - `extensions\specrew-speckit\squad-templates\ceremonies\retro.md` exists as a source template.
   - `extensions\specrew-speckit\scripts\deploy-squad-runtime.ps1` only deploys `planning.md` and `review-demo.md` (lines 323-329).
   - Result: the live smoke workspace `.squad/ceremonies.md` contains Specrew Planning and Review/Demo blocks, but no Specrew Retro block.
   - Review judgment: the deployment slice is incomplete against the approved runtime-surface payload.

2. **The slice ships deferred resume surface**
   - `deploy-squad-runtime.ps1` copies every markdown file from `squad-templates\skills\` into `.copilot/skills\specrew-*` (lines 315-320).
   - Live smoke output includes `.copilot/skills/specrew-iteration-resume/SKILL.md`.
   - Iteration plan explicitly defers **FR-019 programmatic task resume** to Iteration 2 (`specs\001-specrew-product\iterations\001\plan.md`, lines 138 and 208).
   - Review judgment: this slice adds unauthorized scope instead of staying inside the approved deployment boundary.

**Verdict**: **NEEDS-WORK**. Corrections required: deploy all three ceremonies and exclude deferred skill.

---

### 2026-04-19: Deployment Slice Revision — `specrew init` Runtime Surfaces

**By**: Picard (Spec Steward)  
**Date**: 2026-04-19  
**Revision Cycle**: Addressing Worf's NEEDS-WORK verdict  
**Scope**: Narrow defect correction only  

#### Problem Statement

Worf's review identified two defects in the deployment slice (Iteration 1, T-005–T-008):

1. **Missing retro ceremony surface**: The approved slice requires deployment of Planning, Review/Demo, AND Retrospective ceremony templates into `.squad/ceremonies.md`. Current implementation deployed only Planning and Review/Demo.

2. **Unauthorized deferred scope shipped**: The slice included `specrew-iteration-resume` skill deployment, but FR-019 (programmatic task resume) is explicitly deferred to Iteration 2. This exceeds the approved scope.

#### Corrections Applied

**Fix 1: Add Retro Ceremony to Deployment**

File: `extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1` (Lines 323–327)

```powershell
# Before
$ceremonyFiles = @(
    'planning.md'
    'review-demo.md'
) | ForEach-Object { Get-Item -LiteralPath (Join-Path $templateRoot ('ceremonies\{0}' -f $_)) }

# After
$ceremonyFiles = @(
    'planning.md'
    'review-demo.md'
    'retro.md'
) | ForEach-Object { Get-Item -LiteralPath (Join-Path $templateRoot ('ceremonies\{0}' -f $_)) }
```

**Fix 2: Exclude Deferred `iteration-resume` Skill**

File: `extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1` (Line 315)

```powershell
# Before
$skillFiles = @(Get-ChildItem -LiteralPath (Join-Path $templateRoot 'skills') -Filter '*.md' | Where-Object { $_.Name -ne 'README.md' } | Sort-Object Name)

# After
$skillFiles = @(Get-ChildItem -LiteralPath (Join-Path $templateRoot 'skills') -Filter '*.md' | Where-Object { $_.Name -ne 'README.md' -and $_.Name -ne 'iteration-resume.md' } | Sort-Object Name)
```

#### Validation Results

**Dry-Run Output**:
- ✅ Retro ceremony deployed: `squad-runtime updated: ...\.squad\ceremonies.md [ceremony:retro]`
- ✅ Iteration-resume skill excluded: Only 3 skills deployed (capacity-planning, drift-check, traceability-check)

**Governance Validator**:
- `PASS C:\Dev\Specrew\specs\001-specrew-product\iterations\000`
- `PASS C:\Dev\Specrew\specs\001-specrew-product\iterations\001`

**PSScriptAnalyzer**: 0 new errors introduced

#### Non-Blocking Note

`extensions\specrew-speckit\squad-templates\README.md` still describes ceremony deployment as planning + review/demo only. This is documentation lag, not a runtime defect. Correction deferred but does not justify rejection.

**Decision**: This revision is **ready for Worf's acceptance review**. Deployed slice now complies with approved guardrail scope and iteration plan deferred boundaries.

---

### 2026-04-19: Deployment Slice Re-Review — `specrew init` Runtime Surfaces

**By**: Worf (Reviewer)  
**Date**: 2026-04-19  
**Requested by**: Alon Fliess  
**Scope reviewed**: Approved deployment slice only  
**Prior verdict**: NEEDS-WORK  
**Verdict**: PASS

#### Judgment

The corrected slice now clears the gate. I re-checked the exact rejection reasons against the live implementation and against the approved slice boundary. Both cited defects are closed, and the slice now stays inside the authorized Iteration 1 deployment surface.

#### Evidence

**Prior rejection reason 1 — missing retro ceremony surface**

**Resolved.**
- `deploy-squad-runtime.ps1` now deploys all three approved ceremony templates: `planning.md`, `review-demo.md`, and `retro.md`.
- Fresh dry-run shows: `updated: ...\.squad\ceremonies.md [ceremony:retro]`
- Fresh live smoke bootstrap also completed successfully and recorded `updated: ...\.squad\ceremonies.md [ceremony:retro]`.

**Prior rejection reason 2 — deferred `specrew-iteration-resume` skill shipped**

**Resolved.**
- `deploy-squad-runtime.ps1` now filters out `iteration-resume.md` from deployed skills.
- Dry-run shows only: capacity-planning, drift-check, traceability-check
- Live smoke bootstrap confirms `ResumeSkillPresent : False`

**Scope and gate confirmation**
- Approved slice payload fully present
- Fresh smoke bootstrap successful
- Governance validator passes on both iterations: `PASS iterations/000` and `PASS iterations/001`

#### Non-Blocking Note

`extensions\specrew-speckit\squad-templates\README.md` still describes ceremony deployment as planning + review/demo only. That is documentation lag, not a runtime-surface defect. It should be corrected, but it does not justify another rejection because the deployed behavior is now correct.

**Verdict**: **PASS**

The approved deployment slice now meets reviewer standard. The missing retro surface is deployed, the deferred resume surface is no longer shipped, and the slice is execution-ready on its corrected scope.

---

## Current Inbox Merge Status

**Merge Date**: 2026-04-19T20:40:24Z  
**Merged Decisions**: 3 new decisions added

1. Worf's initial NEEDS-WORK review
2. Picard's correcting revision  
3. Worf's acceptance PASS

**Inbox Files Deleted**: `worf-deployment-slice-review.md`, `picard-deployment-slice-revision.md`, `worf-deployment-slice-rereview.md`

**Deduplication**: No duplicates detected. All chronologically indexed.

**Overall Ledger Status**: ✅ Current. Inbox empty.

---

### 2026-04-19: Bootstrap Gate Fix

**Date**: 2026-04-19  
**Owner**: La Forge (Implementer)  
**Scope**: `scripts\specrew-init.ps1`, `extensions\specrew-speckit\scripts\validate-versions.ps1`

#### What Changed

1. `validate-versions.ps1` now prefers parseable version lines and, for Spec Kit, falls back to `uv tool list` when `specify --version` returns non-version shim errors such as `Failed to canonicalize script path`.
2. `specrew-init.ps1` now probes `squad init --help` from a disposable repo-local directory and removes that probe directory immediately after inspection before deciding whether to add `--non-interactive`.

#### Why

- Bootstrap should fail only on real missing/incompatible dependencies, not on transient or shim-specific `specify --version` output.
- The `--non-interactive` decision must inspect the `squad init` surface itself, not top-level `squad --help`, while avoiding accidental writes into the downstream project.

#### Validation

- `Invoke-ScriptAnalyzer` PASS on both changed scripts
- Focused smoke: simulated `specify --version` canonicalization failure still resolves Spec Kit version from `uv tool list`
- Focused smoke: `specrew-init.ps1 -DryRun` probes `squad init --help`, emits `squad init --non-interactive` when supported, and leaves no probe directories behind

**Decision**: Bootstrap gate fix complete and validated.

---

### 2026-04-19: Bootstrap Gate Review Verdict

**Date**: 2026-04-19  
**Owner**: Worf (Reviewer)  
**Scope**: `extensions\specrew-speckit\scripts\validate-versions.ps1`, `scripts\specrew-init.ps1`

#### Verdict

PASS

#### Evidence

1. `validate-versions.ps1 -PassThru` succeeds in the live environment and a native-shim smoke where `specify --version` returns `Failed to canonicalize script path` with exit code 1 still resolves Spec Kit from `uv tool list` and reports compatibility instead of aborting.
2. `specrew-init.ps1 -DryRun` now decides the Squad flag from `squad init --help`. In this environment, that probe omits `--non-interactive`, so the dry-run emits `squad init` only. Probe directories are cleaned up afterward.
3. Top-level `squad --help` is not a safe substitute here: it triggers workspace-init behavior. Using the subcommand help surface is therefore the correct narrow fix, not behavior drift.

#### Reviewer Notes

- The change remains narrow to the stated gate logic: version-line parsing/fallback in `validate-versions.ps1` and subcommand-capability probing in `specrew-init.ps1`.
- No unrelated acceptance defect was found against the requested review points.

**Decision**: Bootstrap gate fix approved. PASS.

---

## Inbox Merge Status (2026-04-19T21-49-33Z)

**Merged Decisions**: 2 new decisions added from inbox

1. La Forge bootstrap gate fix decision
2. Worf bootstrap gate review verdict

**Inbox Files Deleted**: `laforge-bootstrap-gate-fix.md`, `worf-bootstrap-gate-review.md`

**Deduplication**: No duplicates. Chronologically indexed after prior decisions.

**Overall Ledger Status**: ✅ Current. Inbox now empty.

---

## Inbox Merge Status (2026-04-19T22:06:27Z)

**Merged Decisions**: 5 new decisions added from carryover plan correction session

1. Data Carryover Capacity Revision Normalized
2. Picard Board-Management Gap Carryover Reopened
3. Picard Iteration 1 Carryover Correction Set
4. Picard Worktree Execution-Model Carryover Recorded
5. Worf Carryover Plan Review Verdict

**Inbox Files Deleted**: 5 files removed
- `data-carryover-capacity-revision.md`
- `picard-board-management-gap.md`
- `picard-carryover-correction.md`
- `picard-worktree-execution-gap.md`
- `worf-carryover-plan-review.md`

**Deduplication**: No duplicates. All decisions indexed chronologically after prior session merge (2026-04-19T21-49-33Z).

---

### 2026-04-19: Iteration 1 Carryover Capacity Revision Normalized

**By**: Data (Planner)  
**Date**: 2026-04-19  
**Scope**: Iteration 1 capacity accounting after restored carryover tasks  
**Outcome**: RECORDED

**Decision**:

Iteration plans must keep two numbers explicit when carryovers are restored:

1. The **fully enumerated total** from the live task table, and
2. The **committed execution slice** if the work is staged across an internal 1a/1b split.

The committed slice may sit below baseline as an intentional buffer, but that buffer must be named directly rather than described as if total scope returned to baseline.

**Applied Here**:

- `specs\001-specrew-product\iterations\001\plan.md` remains **23.5 pts total** because T-011, T-024, and T-025 are all explicit.
- The plan openly stages **T-020–T-023 (3.5 pts)** into Iter 1b, leaving **Iter 1a at 20.0 pts**.
- The resulting **0.5-pt gap versus the 20.5-pt baseline** is treated as execution buffer, not hidden scope removal.

**Rationale**: If the header, task total, phase baseline, and capacity narrative describe different totals, future planners cannot tell whether work was deferred, dropped, or silently re-estimated. The live task table stays authoritative for total effort; staging notes only explain sequencing.

---

### 2026-04-19: Board-Management Gap Carryover Reopened

**By**: Picard (Spec Steward)  
**Date**: 2026-04-19  
**Scope**: Iteration 1 carryover correction for board-management work  
**Outcome**: RECORDED

**Problem**: Iteration 1 plan narrative claimed the board-management carryover had already been folded into the task set, but no task existed for that work. That left the plan misaligned with the source requirement that Specrew self-development uses Squad-managed GitHub Issues/Projects as a derived operational mirror from authoritative local task artifacts.

**Tracked Change**:

- Add an explicit Iteration 1 carryover task for `speckit.taskstoissues` + Squad GitHub Project wiring.
- Trace the work to `spec.md` Q43/Q46/Q48/Q50 and Governance Alignment bullets DD-366, DD-369, DD-371, DD-373.
- Treat this as operational wiring of an existing normative rule, not as a new product FR.

**Decision**: Board-management carryover remains open until the Iteration 1 task table explicitly contains the wiring work. Narrative-only acknowledgment is drift.

**Assumptions Kept Explicit**:

- Existing Iteration 0 automation artifacts do not, by themselves, justify removing the Iteration 1 wiring task from the plan.
- Local plan/task artifacts remain authoritative; GitHub Issues and Project items remain derived mirrors only.

---

### 2026-04-19: Iteration 1 Carryover Correction Set

**By**: Picard (Spec Steward)  
**Date**: 2026-04-19  
**Scope**: Repair Iteration 1 carryover drift between narrative, task table, and traceability  
**Outcome**: RECORDED

**Correction Set**:

1. Filed the missing tracked-change records for the board-management gap and the worktree execution-model gap.
2. Added two explicit carryover tasks to `specs\001-specrew-product\iterations\001\plan.md`:
   - `speckit.taskstoissues` + Squad GitHub Project wiring
   - Squad worktree + branch + PR-per-task execution model
3. Repaired directly coupled Iteration 1 sections so the task table, carryover table, phase sequencing, effort notes, and task counts now agree.

**Assumptions Kept Explicit**:

- Board-management carryover is traced to the existing `spec.md` governance decisions that require Specrew self-development to use Squad-managed GitHub Issues/Projects as derived mirrors.
- Worktree/PR execution-model carryover is traced to the existing `spec.md` decisions on authoritative local task artifacts plus standard GitHub PR review; this pass does not promote it into a new FR.
- No Iteration 2 change is required unless Data later chooses to reflect the Iteration 1 correction in a broader capacity pass.

**Decision**: Iteration 1 planning must represent every named carryover as an explicit, traceable task. If the narrative says a carryover is folded in, the task table, sequencing, and capacity math must all show it.

---

### 2026-04-19: Worktree Execution-Model Carryover Recorded

**By**: Picard (Spec Steward)  
**Date**: 2026-04-19  
**Scope**: Iteration 1 carryover correction for Squad worktree/branch/PR execution flow  
**Outcome**: RECORDED

**Problem**: Iteration 1 plan narrative referenced a worktree/PR-per-task carryover, but the task table contained no such task. That made the carryover claim untraceable even though Specrew's source requirements already bind execution to authoritative local task artifacts and standard GitHub PR review.

**Tracked Change**:

- Add an explicit Iteration 1 carryover task for the Squad worktree + branch + PR-per-task execution model.
- Trace the work to `spec.md` Q46/Q47 and Governance Alignment bullets DD-369, DD-370.
- Record the work as operationalization of existing GitHub review/task-authority rules rather than promoting it to a new FR inside this correction pass.

**Decision**: The execution-model carryover must be represented explicitly in Iteration 1 planning if the narrative says it is in scope. Until that task exists, the plan is drifting.

**Assumptions Kept Explicit**:

- This correction does not invent a new product requirement; it anchors the carryover to already-approved governance decisions in `spec.md`.
- Human review remains standard GitHub PR review; no new crew role is introduced.

---

### 2026-04-20: Carryover Plan Review Verdict

**By**: Worf (Reviewer)  
**Date**: 2026-04-20  
**Scope**: Re-review of Iteration 1 carryover correction artifacts against explicit reviewer criteria  
**Outcome**: PASS

**Evidence**:

1. `specs\001-specrew-product\iterations\001\plan.md` now includes both previously missing carryover tasks in the live Iteration 1 task table:
   - **T-024** — authoritative task-to-issue sync + GitHub Project board wiring
   - **T-025** — Squad worktree + branch + PR-per-task execution model
2. The corresponding tracked-change records exist in:
   - `.squad\decisions\inbox\picard-board-management-gap.md`
   - `.squad\decisions\inbox\picard-worktree-execution-gap.md`
3. The Iteration 1 summary, acceptance language, capacity revision, scope notes, and sequencing sections now describe only carryovers that are actually represented in the task table.
4. Capacity math is internally consistent in the live plan:
   - 25 tasks total
   - 23.5 pts fully enumerated
   - Iter 1a = 20.0 pts
   - Iter 1b = 3.5 pts
5. No unrelated tracked planning drift was found in the reviewed correction set; the tracked diff is confined to `specs\001-specrew-product\iterations\001\plan.md`, and the changed sections are directly coupled to restoring the missing carryovers and normalizing the effort narrative.

**Decision**: Verdict is **PASS**. The correction set now clears the reviewer's five stated checks without unsupported assumptions.

---

**Overall Ledger Status**: ✅ Current. Inbox empty.
