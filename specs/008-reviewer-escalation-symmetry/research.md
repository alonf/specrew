# Research: Reviewer Escalation Symmetry and Lockout-Chain Cap

**Date**: 2026-05-09  
**Spec**: [spec.md](spec.md)  
**Plan**: [plan.md](plan.md)

## Decisions

### R1: What is the authoritative state surface for reviewer regressions across iterations?

**Decision**: Use `.specrew/reviewer-regression-log.md` as the append-only source of truth, and project the currently unresolved feature state into a new `reviewer-regression-state` managed block in the active iteration's `state.md`.

**Rationale**: The spec already mandates a dedicated reviewer regression ledger at `.specrew/reviewer-regression-log.md`, and FR-014 requires state to survive closed iterations without rewriting their artifacts. Using the ledger as the durable source of truth plus an iteration-local mirror keeps closed history immutable while still fitting the existing runtime pattern used by `sync-squad-model-overrides.ps1`.

**Alternatives considered**:

- A separate feature-level `reviewer-regression-state.md`: rejected because it duplicates the ledger and adds another source of truth.
- Decisions-ledger-only derivation: rejected because routing/config sync would have to re-derive active state from mixed event history on every read.

---

### R2: How should reviewer-class escalation and fallback routing be resolved?

**Decision**: Resolve reviewer-class escalation from runtime `strength_rank` ordering in `.specrew/iteration-config.yml`, pick the lowest enabled class strictly stronger than the prior reviewer class, and define same-class fallback as a different reviewer identity at the same class. If no stronger class or independent same-class reviewer exists, hold for explicit human direction.

**Rationale**: Spec 008 explicitly inherits strongest-class semantics from spec 005 FR-038 through FR-040, and the runtime source of truth for class ordering already exists in `.specrew/iteration-config.yml`. The repository currently has no built-in notion of multiple reviewer identities at the same class, so the plan must make independence explicit and fail closed when the roster does not provide it.

**Alternatives considered**:

- Treat any agent family as reviewer-capable without identity checks: rejected because FR-003 requires independent same-class routing, not just same-model reuse.
- Always synthesize another reviewer when no independent owner exists: rejected because FR-004 requires a human-direction hold in that case.

---

### R3: What are the repaired blocker semantics for reviewer regressions?

**Decision**: Treat Reviewer Regression Events as soft-warning governance signals by default. Only explicit FR-004 review holds (maximum strength with no independent reviewer path) or FR-010 post-cap ownership holds block forward progress.

**Rationale**: FR-007 says reviewer regressions must not automatically hard-fail the feature, and the spec separately defines the conditions that should hold review or revision routing. This keeps reviewer misses visible and actionable without collapsing the whole lifecycle into a permanent blocked state.

**Alternatives considered**:

- Make every reviewer regression a hard iteration failure: rejected because it contradicts FR-007 and the approved blocker repair.
- Never hold on maximum-strength/no-independent-reviewer cases: rejected because it would violate FR-004 and allow unsafe continuation.

---

### R4: Should reviewer symmetry reuse the existing implementer escalation script?

**Decision**: Create a new dedicated `manage-reviewer-regression.ps1` workflow that reuses shared-governance helpers but leaves `manage-escalation-state.ps1` behavior unchanged.

**Rationale**: The reviewer-regression lifecycle differs materially from FR-027 repair escalation: it is feature-scoped, append-only in its own ledger, supports withdrawal, de-escalates after clean review passes rather than gate pass, and distinguishes soft-warning events from blocker holds. A dedicated script preserves FR-013's requirement that implementer-side escalation remain authoritative and unchanged.

**Alternatives considered**:

- Extend `manage-escalation-state.ps1` with reviewer-specific flags: rejected because it would entangle two different state machines and risk FR-027 regressions.
- Encode the whole workflow in ad hoc markdown edits: rejected because runtime routing/config sync needs a deterministic script boundary.

---

### R5: How should the implementer lockout-chain cap be tracked?

**Decision**: Track the lockout chain as part of the active unresolved reviewer-regression chain, record cap activation in `.squad/decisions.md`, and surface the current cap state in the iteration `reviewer-regression-state` mirror and user-facing handoff.

**Rationale**: The cap is triggered by reviewer-regression-driven revision churn and must stay visible wherever the next-owner decision is made. Keeping it inside the active chain avoids a second parallel state machine while still satisfying FR-010 and FR-011 visibility requirements.

**Alternatives considered**:

- A completely separate `implementer-lockout-chain.md`: rejected because the cap is not independent from the triggering reviewer-regression chain.
- Re-derive the cap only from decisions ledger history: rejected because the next routing step needs a simple current-state read.

---

### R6: How should withdrawal and misreport handling work?

**Decision**: Record withdrawals as first-class reviewer-regression updates that mark the originating event withdrawn, reverse only still-pending reviewer routing, human-hold, or alternate-owner state, preserve completed ownership changes as historical fact, and remove only unapproved trap proposals derived solely from that event.

**Rationale**: FR-008 explicitly distinguishes pending state from completed history and approved corpus changes. The design therefore needs an explicit withdrawal record and a deterministic rule for what is reverted versus preserved.

**Alternatives considered**:

- Fully undo all state and history from the original event: rejected because it would rewrite factual history.
- Never reverse routing state after a misreport: rejected because it would leave incorrect escalation active.

---

### R7: How should known-traps integration behave when the corpus is absent?

**Decision**: Make known-traps seeding conditional. When `.specrew/quality/known-traps.md` exists and the project enables the corpus, offer a candidate trap entry for human approval; otherwise record that the candidate-trap offer was skipped because the corpus is disabled or absent.

**Rationale**: Spec 008 explicitly scopes FR-012 to projects that have the known-traps corpus enabled, and the self-dogfooding repository currently does not have the corpus file on disk. The feature therefore needs a truthful, non-failing degraded path.

**Alternatives considered**:

- Auto-create the known-traps corpus as part of 008: rejected because corpus initialization belongs to spec 005, not this additive feature.
- Fail whenever the corpus is missing: rejected because the feature must remain usable when the corpus is disabled.

---

### R8: What counts as a clean review pass for de-escalation?

**Decision**: A clean review pass means the feature's review cycle completes with an accepted outcome and no new Reviewer Regression Event is raised for that review cycle. Default de-escalation requires one such clean pass unless project configuration overrides it.

**Rationale**: FR-005 requires configurable de-escalation after clean review passes but does not bind the term to a concrete artifact. Tying it to an accepted review cycle with no new regression event makes the trigger auditable and consistent with the feature's governance intent.

**Alternatives considered**:

- De-escalate immediately after any accepted task verdict: rejected because reviewer regressions are feature-level, not task-local.
- De-escalate after a gate pass regardless of new regressions: rejected because that reintroduces silent drift.
