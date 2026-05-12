# Feature Specification: Reviewer Escalation Symmetry and Lockout-Chain Cap

**Feature Branch**: `008-reviewer-escalation-symmetry`  
**Created**: 2026-05-09  
**Status**: Approved  
**Approved By**: Alon Fliess (human developer) on 2026-05-09 to authorize before-plan readiness.  
**Input**: User description: "Add a reviewer-side escalation rule symmetric to Specrew's existing implementer-side escalation policy. When a human reviewer finds a concrete defect in work the Squad reviewer already approved, treat it as a Reviewer Regression Event, escalate the reviewer's reasoning class for the remaining review work on the affected feature, cap implementer lockout chains so the roster does not grow unbounded, and seed regression findings into the known-traps corpus when present."

## Problem Statement

Specrew already defines implementer-side escalation when repeated governance failures show that the current repair path is not producing reliable outcomes. That policy protects implementation quality, but it does not yet apply symmetric pressure to the review side when a human later finds a concrete defect in work that Squad review already approved or marked ready.

Without a reviewer-side symmetry rule, the system can keep trusting the same review posture after a clear miss, fail to distinguish reviewer regressions from ordinary downstream defects, and continue rotating implementers without a bounded stopping point. That creates three governance problems:

1. **Reviewer misses do not trigger stronger review behavior** even when the defect proves that the prior review posture was insufficient.
2. **Implementer lockout chains can grow unbounded** as revisions keep moving to new owners without a clear cap or human checkpoint.
3. **Regression learning is inconsistently retained** when reviewer-missed defects are not logged, surfaced, or proposed for the known-traps corpus.

This feature adds a reviewer-side escalation rule that mirrors Specrew's existing implementer-side escalation policy, bounds lockout-chain growth, preserves explicit human decision points, and captures confirmed reviewer regressions as durable governance memory.

## Relationship to Existing Features

This feature is additive to Specrew's existing lifecycle and review-governance model.

- It extends spec 001 FR-027 (implementer-side escalation, including reasoning-tier escalation, reassignment to an independent owner, ledger recording, and de-escalation after a clean gate pass).
- It uses spec 005 FR-038 through FR-040 (strongest-class routing for required bug-hunter lens execution) as the source of truth for "strongest available reasoning class."
- It integrates with spec 005 FR-034 through FR-037 (project-wide known-traps corpus and trap reapplication) so reviewer regressions become durable defect knowledge rather than ephemeral recoveries.
- It references spec 007 FR-016 so reviewer-escalation and lockout-cap states remain consistent with the user-facing progress-status and next-step handoff contract when that feature is present.
- It does not replace the existing reviewer charter, the existing approval workflow, or any implementer-side escalation behavior. It is additive.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Escalate review after a reviewer regression (Priority: P1)

A human reviewer finds a concrete defect in a slice that a Squad reviewer previously approved or marked ready, and wants the remaining review work on that feature to move to a stronger review posture instead of repeating the same reasoning level.

**Why this priority**: The core value of the feature is to make reviewer misses visible and to improve the next review pass immediately, rather than only penalizing implementers.

**Independent Test**: Start with a feature whose Squad reviewer has already approved a slice. Record a human-found concrete defect in that slice. Verify that Specrew creates a Reviewer Regression Event, escalates the reviewer reasoning class for the remaining review work on the affected feature, or routes to an independent reviewer at the same class when no stronger class exists.

**Acceptance Scenarios**:

1. **Given** a Squad reviewer previously approved or marked a slice ready, **When** a human reviewer later identifies a concrete defect in that slice, **Then** Specrew records a Reviewer Regression Event for the affected feature.
2. **Given** a Reviewer Regression Event and a stronger reviewer reasoning class is available, **When** remaining review work continues on that feature, **Then** Specrew looks up eligible reviewer-capable routes in configured strength order, selects the lowest class that is strictly stronger than the prior reviewer class, and assigns the remaining review work there.
3. **Given** a Reviewer Regression Event and no stronger reviewer reasoning class is available, **When** an independent reviewer owner at the same class exists, **Then** Specrew routes the remaining review work to an eligible independent reviewer owner at that same class.
4. **Given** the strongest reviewer reasoning class is already active and no independent reviewer owner is available, **When** a Reviewer Regression Event occurs, **Then** Specrew holds the review and requires human direction before review continues.

---

### User Story 2 - Bound implementer lockout growth after repeated reviewer-missed defects (Priority: P1)

A human maintainer wants reviewer regressions to stop creating an unlimited chain of new implementer assignments, so the roster remains stable and the system asks for human direction when the default rotation budget has been exhausted.

**Why this priority**: Reviewer-side escalation is incomplete if the implementation side can still churn through owners indefinitely after reviewer misses.

**Independent Test**: Simulate repeated revision handoffs after reviewer regressions on the same feature. Verify that implementer reassignment stops after two rotations beyond the original implementer by default, and that the next revision is routed to a human or to an explicitly justified alternate owner recorded in `.squad/decisions.md`.

**Acceptance Scenarios**:

1. **Given** a feature has already rotated through the original implementer plus two additional implementer owners, **When** another revision would normally rotate to a new implementer owner, **Then** Specrew activates the implementer lockout-chain cap.
2. **Given** the lockout-chain cap is active, **When** the next revision is assigned, **Then** the revision goes to a human by default unless an explicitly justified alternate owner is recorded in `.squad/decisions.md`.
3. **Given** the lockout-chain cap becomes active, **When** Specrew records the handoff and state transition, **Then** the cap activation is surfaced in the user-facing handoff, decisions ledger, and iteration state.

---

### User Story 3 - Preserve governance memory and recover from misreports (Priority: P2)

A human maintainer wants reviewer regressions to remain auditable, feed confirmed findings into project learning, and still support withdrawals or misreports without treating every report as a permanent hard failure.

**Why this priority**: Governance quality depends on accurate records and durable learning, but it also requires reversible handling when a reported reviewer regression is later withdrawn or shown to be incorrect.

**Independent Test**: Record a Reviewer Regression Event, mark one event as confirmed and another as withdrawn, and verify that the confirmed event is logged and can generate a candidate known-traps entry for human approval when the corpus is enabled, while the withdrawn event stays auditable without continuing escalation state.

**Acceptance Scenarios**:

1. **Given** a Reviewer Regression Event occurs, **When** Specrew records the event, **Then** it writes the event to the Reviewer Regression Ledger at the default location `.specrew/reviewer-regression-log.md` including the affected feature, iteration, slice, prior reviewer verdict, prior reasoning class, defect description, defect source location, escalation taken, and de-escalation outcome when applicable.
2. **Given** the known-traps corpus is enabled and a reviewer regression finding is confirmed, **When** Specrew processes the event, **Then** it offers one or more candidate trap entries for human approval and, after approval, adds them to the corpus so trap reapplication can scan for similar instances.
3. **Given** a reported reviewer regression is later withdrawn or classified as a misreport after it already triggered escalation or a lockout-cap path, **When** Specrew updates the event state, **Then** the ledger preserves the audit trail, reverses only still-pending escalation or routing state derived from that event, keeps already-completed ownership changes as historical record, and leaves already merged corpus entries governed by the normal corpus-change workflow rather than auto-removing them.
4. **Given** a Reviewer Regression Event is active, **When** Specrew applies governance handling, **Then** the event is treated as a soft-warning governance signal rather than as an automatic hard failure of the entire feature.
5. **Given** a human reports a Reviewer Regression Event after the iteration is already closed, **When** Specrew processes the event, **Then** it records the event immediately and carries any resulting escalation or lockout-cap handling into the next active iteration of the same feature unless the human explicitly reopens the closed iteration.

---

### Edge Cases

- A human reports a defect, but the defect is later shown to be unrelated to the slice that the Squad reviewer approved or marked ready.
- The reviewer is already operating at the strongest available reasoning class when the event is raised.
- No independent reviewer owner exists at the strongest active class, so the system cannot safely continue review without human direction.
- A regression is reported on work that was approved by a delegated reviewer where the configured strongest available class is already active. Specrew must distinguish between "stronger class still exists in another delegated family" and "no stronger class exists at all" before deciding whether to escalate or hold.
- The human reports the regression after the iteration has been closed. Specrew must still record the event in the ledger and apply the escalation rule to the next active iteration of the same feature, not retroactively reopen the closed iteration unless the human explicitly requests reopening.
- The implementer lockout-chain cap is reached while an alternate owner exists, but the alternate path has not yet been justified and recorded in `.squad/decisions.md`.
- The implementer lockout-chain cap is reached but the human is unavailable to own the next revision. Specrew must hold the iteration with explicit "awaiting human-owned revision" state rather than silently synthesizing another specialist.
- The known-traps corpus is disabled for the repository or current feature.
- Multiple reviewer regression findings are reported for the same feature before the next clean review pass occurs. Specrew must dedupe duplicate reports for the same approved slice and defect, append distinct findings to the ledger, and preserve only the strongest unresolved escalation outcome on the active feature until a clean review pass de-escalates it.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001: Reviewer Regression Trigger**: Specrew MUST treat any concrete defect a human reports in a slice that the Squad reviewer already marked approved or ready for implementation as a Reviewer Regression Event for the affected feature.
- **FR-002: Reviewer-Side Escalation**: A Reviewer Regression Event MUST escalate the reviewer's effective reasoning class to the next stronger available class for the affected feature's remaining review work, by analogy to spec 001 FR-027 on the implementer side. The definition of "strongest available reasoning class" MUST follow spec 005 FR-038 through FR-040, including runtime evaluation of configured reviewer-capable agents and consent settings.
- **FR-003: Stronger-Reviewer Lookup and Same-Class Independent Routing Fallback**: To choose the stronger reviewer path, Specrew MUST evaluate eligible reviewer-capable routes in strength order above the prior reviewer class and select the lowest class that is strictly stronger than the prior class. If multiple eligible reviewer owners exist at that selected class, Specrew MUST prefer one not already used in the active reviewer-regression chain for the feature. When no stronger reasoning class is available, Specrew MUST route the next review for the affected feature through an independent reviewer owner (a different agent identity at the same class), again preferring an eligible owner not already used in the active chain.
- **FR-004: Human-Direction Hold at Maximum Review Strength**: When the strongest available reasoning class is already in use and an independent reviewer owner at the same class is also unavailable, Specrew MUST record the regression in the ledger, hold further review for the affected feature, and require explicit human direction on the next path before continuing.
- **FR-005: Configurable Reviewer De-Escalation**: After a Reviewer Regression Event, Specrew MUST de-escalate the reviewer's effective reasoning class for the affected feature only after the configured number of clean review passes on that feature, mirroring implementer-side de-escalation in spec 001 FR-027. Projects MAY configure a different number of clean passes required before de-escalation; the default MUST be one clean pass.
- **FR-006: Reviewer Regression Ledger**: Specrew MUST record every Reviewer Regression Event in a Reviewer Regression Ledger whose default location is `.specrew/reviewer-regression-log.md`, including the affected feature, iteration, slice, prior reviewer verdict, prior reasoning class used, defect description, defect source location, escalation taken, and de-escalation outcome when applicable.
- **FR-007: Soft-Warning Governance Treatment**: Reviewer Regression Events MUST be recorded as a soft-warning class governance signal, consistent with spec 007 FR-016 when that feature is present, and MUST NOT automatically invalidate the affected feature on their own.
- **FR-008: Withdrawal and Misreport Handling**: Specrew MUST support recording a withdrawal of a Reviewer Regression Event when the report turns out to be a misreport. A withdrawal MUST reverse only still-pending routing state caused solely by that event, including any in-flight reviewer-class escalation, awaiting-human-owned-revision hold, or alternate-owner routing that has not yet completed. Ownership changes or revisions already completed before the withdrawal MUST remain recorded as historical fact and MUST NOT be retroactively undone. Specrew MUST also remove any unapproved candidate trap entry derived from the event. Approved trap entries already merged into the corpus MUST NOT be auto-removed; their removal goes through the existing corpus-change workflow.
- **FR-009: Implementer Lockout-Chain Cap**: Specrew MUST cap the implementer lockout chain at a configurable maximum. The default cap MUST be two rotations beyond the original Implementer.
- **FR-010: Post-Cap Ownership Rule**: When the lockout chain reaches its cap, Specrew MUST NOT synthesize an additional implementer specialist. Instead it MUST route the next revision to either a human developer or an explicitly justified alternate owner whose rationale is recorded in `.squad/decisions.md`.
- **FR-011: Cap and Escalation Visibility**: When the implementer lockout chain reaches its cap or reviewer escalation materially affects the next action, Specrew MUST surface that state in the user-facing handoff, `.squad/decisions.md`, and the iteration state artifact, including the locked-out agents, the current reviewer reasoning class, and the planned next-owner path.
- **FR-012: Known-Traps Seeding and Reapplication**: When the project has the known-traps corpus enabled per spec 005 FR-034, Specrew MUST offer a candidate trap entry derived from each Reviewer Regression Event for human approval, and after approval MUST add the entry to the corpus so trap reapplication per spec 005 FR-037 can scan for similar instances.
- **FR-013: Additive Symmetry with Existing Policy**: This feature MUST NOT change implementer-side escalation behavior described in spec 001 FR-027 beyond enforcing the lockout-chain cap. Implementer-side reasoning-tier escalation, reassignment to an independent owner, ledger recording, and de-escalation after a clean gate pass remain authoritative as defined in spec 001.
- **FR-014: Closed-Iteration Carry-Forward**: When a Reviewer Regression Event is reported after an iteration has already been closed, Specrew MUST record the event immediately in the Reviewer Regression Ledger and carry any resulting reviewer-escalation or lockout-cap state forward to the next active iteration of the same feature by default. Specrew MUST NOT silently reopen the closed iteration; reopening requires explicit human direction.
- **FR-015: Repeated Reviewer Regression Consolidation**: Before the next clean review pass de-escalates the feature, Specrew MUST maintain a single active reviewer-regression chain per feature. Duplicate reports for the same approved slice and defect MUST be deduplicated into that chain, while distinct additional findings MUST append to the ledger and extend the same chain rather than creating parallel escalation ladders. Repeated events MUST preserve only the strongest unresolved escalation or routing outcome currently reached for that feature unless explicit human direction selects a different path.

### Requirement Ownership & Delivery *(mandatory)*

- **FR-001 to FR-005** — **Owner roles**: Reviewer-governance policy maintainers and lifecycle-routing maintainers. **Delivery window**: Initial rollout of reviewer-regression symmetry.
- **FR-006 to FR-008** — **Owner roles**: Governance artifact maintainers and review-operations maintainers. **Delivery window**: Same rollout, so reviewer regression events are auditable and reversible from day one.
- **FR-009 to FR-011** — **Owner roles**: Runtime routing maintainers, coordinator handoff maintainers, and decisions-ledger maintainers. **Delivery window**: Same rollout, because bounded lockout chains and visible handoffs are required parts of the policy.
- **FR-012 to FR-015** — **Owner roles**: Quality-governance maintainers, lifecycle-routing maintainers, and spec-governance maintainers. **Delivery window**: Same rollout, so confirmed reviewer regressions feed project learning, repeated events stay deterministic, and closed-iteration findings carry forward without changing the underlying lifecycle contract.

### Traceability & Governance Requirements *(mandatory)*

- **TG-001**: User Story 1 MUST be covered by FR-001 through FR-005 and FR-015.
- **TG-002**: User Story 2 MUST be covered by FR-009 through FR-011.
- **TG-003**: User Story 3 MUST be covered by FR-006 through FR-008, FR-012, and FR-014.
- **TG-004**: Every Reviewer Regression Event recorded in the ledger MUST be traceable to the prior Squad-reviewer approval record, the human-found defect report, the escalation or independent-owner action taken, and any subsequent de-escalation event.
- **TG-005**: Every lockout-chain cap activation MUST be visible in `.squad/decisions.md`, in the iteration state artifact, and in the user-facing handoff for the request that triggered it.
- **TG-006**: This feature MUST remain visibly additive to spec 001 FR-027, spec 005 FR-034 through FR-040, and spec 007 when those features are present.
- **TG-007**: Any conflict between this feature and the existing implementer-side escalation policy MUST be reconciled in favor of keeping the original implementer-side policy intact while adding symmetric reviewer-side handling.
- **TG-008**: Any conflict between this feature and known-traps governance MUST be reconciled in favor of preserving human approval before new trap entries are added to the corpus.

### Key Entities *(include if feature involves data)*

- **Reviewer Regression Event**: A recorded instance of a human-found concrete defect in a slice that the Squad reviewer previously marked approved or ready for implementation. Includes feature, iteration, slice, prior verdict, prior reasoning class, defect description, source location, escalation action, and de-escalation outcome.
- **Reviewer Regression Ledger**: The append-only, human-readable log of Reviewer Regression Events. Default location `.specrew/reviewer-regression-log.md` with optional iteration-local mirrors.
- **Lockout-Chain Cap**: The configured maximum number of implementer rotations Specrew will perform before holding the iteration for human-owned or explicitly justified alternate ownership. Default value 2.
- **Reviewer Class Escalation Record**: The structured record of a reviewer-class change for a feature, including from-class, to-class, triggering event id, and de-escalation status.
- **Reviewer Regression Withdrawal**: A recorded reversal of a Reviewer Regression Event when the report turns out to be a misreport.

### Non-Goals

- This feature does not replace the existing implementer-side escalation policy.
- This feature does not automatically insert new entries into the known-traps corpus without human approval.
- This feature does not redefine the entire review lifecycle or require every reviewer finding to become a Reviewer Regression Event.
- This feature does not remove the need for human direction when no safe independent reviewer path exists.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: After rollout, in sampled iterations across at least five representative features, 100% of human-found defects on previously approved Squad-review work are recorded as Reviewer Regression Events in the ledger.
- **SC-002**: After rollout, in 100% of recorded Reviewer Regression Events where a strictly stronger reasoning class is available for the reviewer, the next review for the affected feature runs on that strictly stronger class within the same iteration.
- **SC-003**: After rollout, the implementer lockout chain MUST NOT exceed the configured cap without an explicit human-approved override on file in 100% of sampled iterations.
- **SC-004**: After rollout, in 100% of sampled requests where a Reviewer Regression Event or a lockout-chain cap activation occurred, the user-facing handoff names the event or activation, the locked-out agents, and the planned next-owner path.
- **SC-005**: After three iterations using this capability in a project that has the known-traps corpus enabled, at least 50% of recorded Reviewer Regression Events have seeded an approved trap entry in the corpus.
- **SC-006**: After rollout, in 100% of sampled cases where the strongest available reasoning class is already in use at the time of a Reviewer Regression Event, Specrew records the situation, holds review for the affected feature, and requires explicit human direction before continuing.

## Clarifications

### Session 2026-05-09

- Q: What specifically triggers a Reviewer Regression Event? → A: A human-found concrete defect in a slice previously approved or marked ready by the Squad reviewer.
- Q: What is the default reviewer-side response after such an event? → A: Escalate the reviewer reasoning class to the next stronger available class for the remaining review work on the affected feature, then de-escalate after the next clean review pass by default. Projects MAY require more clean passes before de-escalation.
- Q: What happens if no stronger reviewer reasoning class exists? → A: Route to an independent reviewer owner at the same class; if the strongest class is already active and no independent reviewer is available, hold review and require human direction. Specrew must distinguish between "no stronger class in this delegated family" and "no stronger class exists at all."
- Q: How far may implementer lockout chains grow by default? → A: At most two rotations beyond the original Implementer; once that cap is reached, the next revision goes to a human or to an explicitly justified alternate owner recorded in `.squad/decisions.md`.
- Q: Are Reviewer Regression Events hard failures, and how are false alarms handled? → A: They are soft-warning governance signals, and Specrew must support withdrawals or misreports with an auditable corrected disposition.
- Q: What happens when a reviewer regression is reported after an iteration is already closed? → A: Record the event in the ledger and apply the escalation rule to the next active iteration of the same feature unless the human explicitly requests reopening the closed iteration.
- Q: If a Reviewer Regression Event is withdrawn after it already triggered escalation or a lockout-cap path, what gets reversed? → A: Reverse only still-pending escalation and routing state; keep already-completed ownership changes as historical record.

## Assumptions

- Spec 001 FR-027 remains the authoritative implementer-side escalation rule. This feature adds a symmetric reviewer-side rule and a chain cap; it does not redefine implementer-side behavior.
- Reasoning-class strength ordering used for escalation is the same definition referenced in spec 005 FR-038, applied symmetrically to reviewer routing.
- Reviewer Regression Events are detected when a human reports a concrete defect against a slice that has a recorded Squad-reviewer approval. Detecting silent regressions where the human never reports is out of scope.
- The default lockout-chain cap of two rotations beyond the original Implementer is a starting policy, not a hard product invariant. Projects may calibrate it after experience.
- The known-traps corpus is the canonical durable surface for converting one observed defect into mechanical or lens-level prevention; this feature integrates with that surface rather than introducing a parallel corpus.
- Reviewer Regression Events are soft-warning class governance signals, consistent with spec 007 FR-016 when that feature is present.

## Governance Alignment *(mandatory)*

- **Spec Steward**: Alon Fliess, as requesting maintainer and reviewer of reviewer-regression governance behavior.
- **Iteration Facilitator**: Specrew lifecycle and routing maintainers responsible for keeping reviewer escalation, lockout-cap behavior, and handoff visibility aligned through one delivery slice.
- **Capacity Model**: One cross-cutting governance slice spanning review routing, iteration state, handoff visibility, and quality-memory updates within a single delivery iteration.
- **Drift Signals**: Human-found reviewer misses do not change reviewer routing; implementer chains keep growing past the cap; cap activation is absent from handoffs or state artifacts; confirmed reviewer regressions do not produce candidate known-traps proposals; withdrawn events continue to influence active routing.
- **Human Oversight Points**: Human confirmation of reviewer regression reports when needed, approval of any alternate owner used after cap activation, approval of candidate known-traps entries, and direction when review is held at maximum strength without an independent reviewer path.
