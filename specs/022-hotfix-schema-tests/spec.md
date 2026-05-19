# Feature Specification: F-020 Implementation Hotfix + Schema Parity Tests

**Feature Branch**: `022-hotfix-schema-tests`  
**Created**: 2026-05-18  
**Status**: Shipped  
**Shipping PR**: #268  
**Input**: User description: "Start Feature 022 as a reactive hotfix feature addressing three production bugs discovered when attempting to restart Squad after F-021 shipped: closeout-helper schema mismatch, incomplete boundary-sync wiring across the seven lifecycle boundaries, and broken stale-state recovery UX in `specrew start`. Include schema-parity, lifecycle boundary, and restart regression coverage while preserving the current single-iteration operating model and Feature 021 carry-forward defaults."

## Problem Statement

Feature 021 shipped, but the first real attempt to restart Squad exposed a production-facing gap between the intended Feature 020 session-state durability design and the actual brownfield behavior. Operators can encounter stale or inconsistent state after closeout, later lifecycle boundaries may never be recorded, and the advertised recovery path at `specrew start` can block the user instead of helping them recover.

This hotfix feature restores trust in Specrew restart behavior by reconciling state-schema expectations, ensuring every lifecycle boundary is durably recorded, and making stale-state recovery usable during real restart flows. The work is intentionally bounded to a single iteration hotfix of about 10 story points and must preserve the existing seven-boundary lifecycle and Feature 021 operating defaults.

## Clarifications

### Session 2026-05-18

- Q: Should this feature audit other state artifacts for the same schema gap, including `.specrew/last-start-prompt.md`, `.specrew/start-context.json`, or `.squad/drift-log.md`, or stay limited to the closeout identity surface? → A: Keep Feature 022 limited to the closeout identity surface at `.squad/identity/now.md`; broader schema parity auditing belongs to Proposal 054 / a future durable pre-merge gate rather than this reactive 10 story point hotfix.
- Q: Should `--recover` also disable best-guess confirmation behavior during launch, or should recovery mode stay orthogonal to that approval behavior? → A: Keep them orthogonal; `--recover` bypasses the stale-state pre-launch gate and launches recovery mode, but it does not implicitly disable best-guess or autopilot-style confirmation behavior.
- Q: Is the possible missing-ledger symptom part of Feature 022 acceptance scope, or should it be tracked as a follow-up once the three confirmed bugs are fixed? → A: Defer the inbox-to-ledger / Scribe auto-consolidation symptom to follow-up work; Feature 022 remains bounded to the three confirmed bugs plus their regression coverage.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Restart Safely After Ship or Closeout (Priority: P1)

A returning operator needs `specrew start` to recover cleanly after a ship, closeout, or stale-state incident so they can continue work instead of getting blocked by inconsistent state or a dead-end recovery prompt.

**Why this priority**: This is the production blocker. If restart recovery fails, users cannot reliably resume or re-anchor work after a shipped feature.

**Independent Test**: Simulate an F-021 ship or closeout state, run `specrew start`, and verify the operator can either complete an interactive A/B/C recovery flow or use `--recover` to enter recovery mode without stale-state startup failure.

**Acceptance Scenarios**:

1. **Given** session-state files describe a feature that has already shipped, **When** the operator runs `specrew start`, **Then** the product clearly reports the stale-state issue and allows a recovery path instead of exiting unusably
2. **Given** stale state is detected, **When** the operator chooses one of the presented recovery options, **Then** the product accepts the choice and continues into the corresponding recovery workflow
3. **Given** stale state is known before launch, **When** the operator runs `specrew start --recover`, **Then** the product bypasses the blocking stale-state gate and launches directly into recovery mode

---

### User Story 2 - Keep Lifecycle State in Sync Across All Boundaries (Priority: P1)

A Specrew maintainer needs every lifecycle boundary to record the same authoritative session state so restart logic, closeout flows, and ledger history all agree about where the feature actually is.

**Why this priority**: Boundary drift is the root cause behind stale restart behavior. If even one later boundary fails to synchronize, the restart experience becomes unreliable again.

**Independent Test**: Run a simulated feature through specify, clarify, plan, tasks, review-signoff, iteration closeout, and feature closeout, then verify that the lifecycle ledger shows all seven boundary-sync entries in order and that the state surfaces agree about the final boundary.

**Acceptance Scenarios**:

1. **Given** a feature completes any one of the seven lifecycle boundaries, **When** the boundary completes, **Then** the recorded session state reflects that boundary consistently across the tracked state surfaces
2. **Given** a simulated full lifecycle run, **When** the run reaches feature closeout, **Then** the lifecycle ledger contains seven ordered boundary-sync entries with no missing late-stage boundaries
3. **Given** a boundary-sync update fails or is skipped, **When** restart validation inspects the recorded state, **Then** the inconsistency is detectable instead of silently hidden

---

### User Story 3 - Preserve Schema Parity Between Human and Machine State (Priority: P2)

A maintainer needs closeout-generated identity state to remain readable to humans while also carrying the machine-readable session-state fields required by stale-state validation and restart recovery.

**Why this priority**: The current two-schema split is a correctness defect, but it is narrower than the restart blocker itself because it primarily affects one state surface.

**Independent Test**: Generate the closeout identity state, parse its frontmatter through the stale-state session-state parser, and verify the parser returns the same boundary, feature, and activity metadata expected from the closeout event.

**Acceptance Scenarios**:

1. **Given** feature closeout writes the current identity state, **When** a validator or restart flow parses that state, **Then** it can read the required machine-readable session-state fields successfully
2. **Given** the same closeout identity file, **When** a human opens it, **Then** the human-readable closeout summary fields remain present and understandable
3. **Given** schema parity coverage runs in CI or local verification, **When** the closeout identity output changes incompatibly, **Then** the parity test fails clearly

---

### Edge Cases

- What happens when a late lifecycle boundary writes to some state surfaces but not all of them before restart validation runs?
- How does the product behave when stale state is detected and the operator supplies invalid or empty interactive recovery input?
- What happens when closeout state contains readable summary metadata but one or more machine-readable session-state fields are missing or empty?
- How does the restart flow behave when a feature has shipped, the old branch no longer exists, and recovery must redirect the operator to a new intake path?
- What happens when lifecycle synchronization records all seven boundaries in the main state surfaces but the supporting ledger history appears incomplete? Record the condition as follow-up evidence outside Feature 022 acceptance scope unless it reproduces one of the three confirmed hotfix bugs.

### Integration Test Strategy

- **Schema parity suite**: verify closeout-generated identity state remains readable by both humans and the machine session-state parser
- **Boundary lifecycle suite**: verify a simulated full seven-boundary run produces ordered boundary-sync history through feature closeout
- **Restart recovery suite**: verify post-ship restart no longer fails on stale-state detection and that recovery mode remains reachable through interaction and `--recover`

## Requirements *(mandatory)*

### Functional Requirements

#### Pillar 1: Closeout Schema Parity

- **FR-001**: The feature MUST ensure the closeout-generated identity state contains the machine-readable session-state fields required by restart validation while preserving the existing human-readable summary fields. **Owner role**: Reliability steward. **Delivery window**: Iteration 001.
- **FR-002**: Machine-readable closeout state written at feature closeout MUST describe the active status, feature reference, boundary type, recorded timestamp, and any relevant iteration or authorization context needed for stale-state recovery. **Owner role**: Reliability steward. **Delivery window**: Iteration 001.
- **FR-003**: The closeout identity state MUST remain understandable to a human operator without requiring the operator to infer meaning from machine-only fields. **Owner role**: UX steward. **Delivery window**: Iteration 001.
- **FR-004**: The product MUST provide regression coverage proving that closeout-generated identity frontmatter can be consumed by the same parser used by stale-state validation. **Owner role**: Quality steward. **Delivery window**: Iteration 001.
- **FR-005**: Feature 022 MUST keep schema-parity auditing limited to the closeout identity surface at `.squad/identity/now.md`. Auditing `.specrew/last-start-prompt.md`, `.specrew/start-context.json`, `.squad/drift-log.md`, or other state artifacts for the same gap is explicitly out of scope for this hotfix and deferred to Proposal 054 / a future durable pre-merge gate. **Owner role**: Governance steward. **Delivery window**: Iteration 001.

#### Pillar 2: Seven-Boundary Lifecycle Synchronization

- **FR-006**: The feature MUST restore boundary-state synchronization at all seven lifecycle boundaries: specify, clarify, plan, tasks, review-signoff, iteration closeout, and feature closeout. **Owner role**: Runtime steward. **Delivery window**: Iteration 001.
- **FR-007**: Each lifecycle boundary MUST record synchronization at the correct moment in the lifecycle so restart logic and lifecycle history agree on the current feature state. **Owner role**: Runtime steward. **Delivery window**: Iteration 001.
- **FR-008**: The brownfield boundary scripts that implement the seven lifecycle transitions MUST be audited so missing or misplaced synchronization calls are identified and corrected. **Owner role**: Runtime steward. **Delivery window**: Iteration 001.
- **FR-009**: The product MUST provide lifecycle coverage that verifies a simulated full lifecycle produces all seven boundary-sync entries in the decision ledger in order. **Owner role**: Quality steward. **Delivery window**: Iteration 001.
- **FR-010**: If a lifecycle boundary fails to synchronize correctly, the resulting mismatch MUST remain observable through restart validation or lifecycle evidence rather than silently passing. **Owner role**: Reliability steward. **Delivery window**: Iteration 001.

#### Pillar 3: Restart Recovery UX

- **FR-011**: When stale session state is detected at `specrew start`, the product MUST present a usable recovery experience that accepts an operator's A/B/C recovery choice rather than exiting without progressing. **Owner role**: UX steward. **Delivery window**: Iteration 001.
- **FR-012**: The product MUST provide a `--recover` start option that bypasses the blocking stale-state gate and launches directly into recovery mode. **Owner role**: UX steward. **Delivery window**: Iteration 001.
- **FR-013**: Recovery mode MUST still explain why restart entered recovery and what next action the operator is expected to take. **Owner role**: UX steward. **Delivery window**: Iteration 001.
- **FR-014**: The `--recover` flag MUST bypass the stale-state pre-launch gate and launch recovery mode without implicitly changing any best-guess or autopilot-style confirmation behavior. If confirmation behavior ever needs separate control, it MUST be introduced through a distinct flag rather than folded into `--recover`. **Owner role**: Governance steward. **Delivery window**: Iteration 001.
- **FR-015**: The product MUST provide end-to-end restart coverage proving that a recently shipped feature does not leave `specrew start` blocked by stale-state errors. **Owner role**: Quality steward. **Delivery window**: Iteration 001.

#### Pillar 4: Hotfix Scope and Governance Preservation

- **FR-016**: This hotfix MUST remain scoped to a single iteration of approximately 10 story points and preserve the standard seven-boundary lifecycle model. **Owner role**: Product steward. **Delivery window**: Iteration 001.
- **FR-017**: The feature MUST carry forward the Feature 021 operating defaults for a 3-cycle repair budget, push-after-every-commit discipline, live bookkeeping during execution, and pre-handoff verification. **Owner role**: Governance steward. **Delivery window**: Iteration 001.
- **FR-018**: The specification MUST identify any known mismatch between the intended Feature 020 design and the observed brownfield behavior, along with the reconciliation path for this hotfix. **Owner role**: Governance steward. **Delivery window**: Iteration 001.
- **FR-019**: The possible fourth bug involving lifecycle inbox-to-ledger delivery / Scribe auto-consolidation MUST be recorded as follow-up work and remain out of Feature 022 acceptance scope. Feature 022 is limited to the three confirmed bugs plus the regression coverage needed to prevent their return. **Owner role**: Product steward. **Delivery window**: Iteration 001.

### Traceability & Governance Requirements *(mandatory)*

- **TG-001**: User story mapping: US1 → FR-011 through FR-015; US2 → FR-006 through FR-010; US3 → FR-001 through FR-005; governance carry-forward and scope discipline → FR-016 through FR-019.
- **TG-002**: Owner roles are Reliability steward (schema parity and observability), Runtime steward (boundary synchronization wiring), UX steward (restart recovery behavior), Quality steward (integration coverage), Governance steward (scope and policy decisions), and Product steward (iteration scope control).
- **TG-003**: All accepted requirements for this feature are intended for Iteration 001 only.
- **TG-004**: Known brownfield conflict: Feature 020 expected machine-readable closeout state and seven-boundary synchronization, but production evidence from the Feature 021 restart attempt showed schema divergence and missing later-boundary synchronization. This hotfix reconciles the implementation to the intended contract and defers any newly discovered out-of-scope defects to follow-up governance.

### Key Entities *(include if feature involves data)*

- **Session State Record**: The authoritative feature-state snapshot used by restart validation and lifecycle recovery, including feature reference, lifecycle boundary, timestamps, activity flags, and related context
- **Identity State Surface**: The human-facing state artifact that also needs enough structured metadata to support machine validation and recovery
- **Boundary Sync Event**: The recorded lifecycle transition for one of the seven required boundaries, including feature context, boundary type, and event order
- **Recovery Session**: A restart flow entered after stale-state detection or via explicit recovery intent, guiding the operator toward re-anchoring, new intake, or manual intervention

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In a simulated shipped-feature restart, 100% of tested stale-state scenarios provide a usable recovery path instead of terminating at the startup gate
- **SC-002**: In a simulated full lifecycle run, all 7 required lifecycle boundaries appear in ordered synchronization history with no missing late-stage entries
- **SC-003**: In schema parity verification, 100% of closeout identity samples required by the hotfix are successfully parsed by restart validation while remaining readable to human operators
- **SC-004**: Operators can enter recovery mode with `specrew start --recover` in a single command and reach a recovery-ready launch path without needing a second startup attempt
- **SC-005**: The Feature 022 hotfix completes within one iteration and preserves the existing seven-boundary operating model and carried-forward governance defaults

## Assumptions

- This feature remains a reactive hotfix for three confirmed production bugs and does not broaden into unrelated lifecycle redesign work unless clarify explicitly expands scope.
- The repository's existing integration-test structure under `tests/integration` remains the default home for the new regression coverage, even if the final test-script grouping is refined during planning.
- Recovery mode should continue to explain stale-state causes and operator choices even when entered directly via `--recover`.
- Existing Feature 021 governance defaults remain authoritative for Feature 022: 3-cycle repair budget, push-after-every-commit, live bookkeeping, and pre-handoff verification.
- The hotfix targets a single iteration rather than introducing a new multi-iteration delivery plan.

## Governance Alignment *(mandatory)*

- **Spec Steward**: Feature owner / Specrew maintainer responsible for restart reliability and brownfield reconciliation
- **Iteration Facilitator**: Squad operator coordinating the single hotfix iteration and confirming production evidence matches the implemented fixes
- **Capacity Model**: Single iteration, approximately 10 story points
- **Drift Signals**: Schema-parity regression failures, missing lifecycle boundary entries, stale-state restart failures, and any mismatch between intended boundary state and recorded lifecycle evidence
- **Human Oversight Points**: Human review of clarify resolutions before planning, human verification of restart recovery behavior, and pre-handoff verification before implementation is considered complete

## Cross-References

- Related baseline: `specs/020-session-state-durability/spec.md`
- Recently shipped context: `specs/021-specrew-slash-commands/spec.md`
- Expected state parser and lifecycle sync helpers currently live in the restart and boundary-state scripts
- In-scope brownfield boundary surfaces include the seven lifecycle artifact scaffolds named in the intake request
