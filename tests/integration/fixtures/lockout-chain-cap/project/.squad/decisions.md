# Decisions

**Schema**: v1  
**Feature**: 008-sample-lockout  
**Last Updated**: 2026-05-10

## Decision Log

### D001 - Lockout Cap Testing Configuration

- **Date**: 2026-05-09
- **Type**: configuration
- **Decision**: Set lockout-chain cap to 2 rotations beyond original implementer
- **Rationale**: Test lockout-cap activation and post-cap ownership rules
- **Participants**: Test maintainer

---

## Reviewer-Regression Decisions

### 2026-05-10-lockout-cap-activated
### 2026-05-10T10:00:00Z: Implementer lockout-chain cap activated
**By:** System (reviewer-regression chain)
**Type:** lockout-cap
**What:** Implementer lockout-chain reached the configured cap (2 rotations beyond original implementer). Feature `008-sample` has cycled through Implementer-Alpha (original), Implementer-Beta (rotation 1), and Implementer-Gamma (rotation 2). Cap is now active.
**Why:** Enforcement of FR-009 lockout-chain cap policy after repeated reviewer-regression defects.
**Evidence:**
- Feature: `008-sample`
- Prior implementers: Implementer-Alpha → Implementer-Beta → Implementer-Gamma
- Chain length: 3 (original + 2 rotations)
- Cap threshold: 3 (original + lockout_chain_cap=2)
- Cap state: **active**
- Next-owner path: awaiting human-owned revision or approved alternate owner

### 2026-05-10-alternate-owner-approved
### 2026-05-10T11:00:00Z: Approved alternate implementer owner after lockout cap
**By:** Alon Fliess (human developer)
**Type:** alternate-owner-approval
**What:** Approved Implementer-Delta as alternate owner for feature `008-sample` revision after lockout-chain cap activation.
**Why:** The standard implementer rotation has exhausted its budget (original + 2 rotations), but the defect is narrowly scoped to the auth module and Implementer-Delta has specific domain expertise. This is a targeted exception rather than synthesis of another rotation.
**Evidence:**
- Feature: `008-sample`
- Lockout cap: **active** (3 owners used: Alpha, Beta, Gamma)
- Approved alternate: Implementer-Delta
- Rationale: Domain expertise in auth module; narrowly scoped defect
- Authorization: Human developer (Alon Fliess)
