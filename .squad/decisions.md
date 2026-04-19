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

## Inbox Decisions Merged

**Merge Date**: 2026-04-19T02:08:48Z  
**Inbox Files Deleted**: 2 decision files merged

1. `picard-iteration1-plan-revision.md` → 2026-04-19 Plan Revision
2. `worf-iteration1-final-gate.md` → 2026-04-19 Final Gate

**Deduplication**: No duplicates. Both decisions now in main ledger.
