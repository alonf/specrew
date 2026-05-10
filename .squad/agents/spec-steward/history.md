# Spec Steward History

Project-specific learnings and patterns discovered during work.

## Learnings

### 2026-05-11: Feature 008 Iteration 005 Pre-Sign-Off Hardening-Gate Schema Convention

Accepted and recorded the pre-sign-off hardening-gate schema convention established by iteration 005 sign-off. This governance pattern formalizes how hardening gates transition from planning-phase drafts to signed-off completion.

**Schema Characteristics**:
1. **Overall Verdict**: Set to `ready` (not `deferred-with-approval`) to signal planning-level readiness before sign-off is recorded
2. **Pending Metadata**: Keep rich pending-field notation (`Reviewed By: *(pending Alon Fliess)*`, `Reviewed At: *(pending)*`) in planning-only state before transition to signed-off state
3. **Post-Sign-Off State**: Update Reviewed By and Reviewed At to actual values, add Sign-Off Evidence section, and change Overall Verdict notation to reflect signed status (e.g., `✅ SIGNED OFF`)
4. **Evidence Authority**: Sign-Off Evidence section records verbatim authorization statement from the approving authority, along with recorded date and context

**Recognized Pattern**: Pre-implementation hardening gates use this richer schema to separate planning-level readiness (Overall Verdict: ready with all blocking concerns addressed) from sign-off completion (Reviewed By and Reviewed At recorded, Sign-Off Evidence captured). This allows gates to be ready for review without obscuring which fields are still awaiting human approval.

**Scope Governance During Sign-Off**: When human approval changes the authorized scope (e.g., reducing validation commands from seven to six), update both the plan.md task definition AND the hardening-gate concern evidence to reflect the new scope. The validation-lane-completeness concern rationale must name the exact authorized command set, creating a two-artifact traceability point.

**Known-Traps Seeding**: Added two traps to `.specrew/quality/known-traps.md`:
1. **pre-sign-off-schema-convention-drift**: Detects when hardening gates regress pending metadata or Overall Verdict notation during lifecycle transitions
2. **validation-lane-concern-scope-drift**: Detects when a hardening gate documents one command set but plan.md lists a different set

**Pattern discovered**: Pre-sign-off hardening gates benefit from explicit pending-field notation in planning phase because it shows readiness FOR review while explicitly naming what's still pending human action. Regression to simpler blocked/unblocked states loses this valuable traceability bridge.

### 2026-05-10: Feature 008 Iteration 003 Approval Recording and Hardening Gate Status Vocabulary

Recorded two fresh approvals for feature 008 iteration 003 (User Story 2 — implementer lockout-chain cap) into the iteration artifacts: hardening-gate sign-off and implementation authorization.

The approval recording involved:
1. **plan.md Implementation Approval section**: Updated from pending to authorized with explicit approval evidence, approving human (Alon Fliess), and recorded date.
2. **state.md lifecycle state**: Updated Current Phase from 'planning' to 'approved' and Iteration Status to reflect implementation-approved but not yet executed state. Added hardening-gate and implementation authorization checkpoints to Decisions and Handoff section.
3. **hardening-gate.md approval fields**: Updated Overall Verdict, Reviewed By, Reviewed At, and added Hardening-Gate Sign-Off section with verbatim sign-off evidence.
4. **Hardening concern status vocabulary repair**: Five feature-specific concerns (`chain-counting-integrity`, `cap-activation-routing`, `decision-ledger-recording`, `handoff-visibility`, `us1-integration-correctness`) required Status correction from `requires-evidence` to `addressed` and Runtime Evidence Status correction from `requires-runtime-proof` to `pending-post-implementation` to pass validate-governance.

**Pattern discovered**: For pre-implementation hardening gates, concerns that will be validated after implementation must use Status `addressed` with Evidence Basis `planning-time-analysis` and Runtime Evidence Status `pending-post-implementation`. Status `requires-evidence` is not valid for pre-implementation gates—it triggers the validator's default case which adds "must resolve the concern before implementation can proceed" issue and causes `BlocksImplementation` to be true. The correct vocabulary signals planning-level readiness while explicitly deferring runtime proof to post-implementation review.

**Pattern discovered**: When a hardening gate's Overall Verdict is `ready` (all blocking concerns are addressed at planning level), the gate-level Approval Ref must be empty (—). Approval references are required only for `deferred-with-approval` verdicts where human approval explicitly permits proceeding despite unresolved concerns. A `ready` verdict means the gate is cleared based on planning-time evidence and does not require separate approval—the approval is at the implementation-authorization level in plan.md, not at the gate level.

**Pattern discovered**: Hardening-gate sign-off and implementation authorization are separate but complementary approvals. The hardening-gate sign-off validates that the quality planning meets the pre-implementation bar (canonical concerns present, feature-specific concerns documented, evidence basis and controls specified). The implementation authorization grants permission to execute the iteration tasks. Both must be recorded truthfully in the respective artifact sections before implementation begins.

### 2026-05-10: Feature 008 Iteration 003 Hardening Gate Canonical Concern Repair

Repaired the hardening-gate.md for feature 008 iteration 003 after intra-feature schema regression was detected during revision cycle. The original planner-authored artifact omitted the five canonical concerns required by spec 005 Phase 2 (security-surface, error-handling-expectations, retry-idempotency-requirements, test-integrity-targets, operational-resilience-concerns).

The repair involved:
1. **Canonical concern addition**: Added five canonical concerns in the required order as the first five rows of the Concern Review table, each with honest pre-implementation evaluation specific to the US2 lockout-chain-cap slice.
2. **Schema upgrade**: Upgraded from six-column schema to nine-column schema (Concern, Category, Status, Evidence Basis, Runtime Evidence Status, Expected Controls, Blocking, Rationale, Approval) to match spec 005 iteration 004 pattern.
3. **Feature-specific concerns preserved**: Kept the six existing feature-specific concerns after the canonical five.
4. **Governance validation fixes**: Adjusted Evidence Basis to `not-applicable` for not-applicable status, and Runtime Evidence Status to `pending-post-implementation` for planning-time-analysis addressed concerns.
5. **Known-traps corpus seeding**: Added `missing-canonical-concerns` governance-category trap entry with concrete example, detection method (scan Concern Review table for canonical five in order), remediation guidance, discovery date 2026-05-10, and reapplication note.

**Pattern discovered**: When a hardening gate is authored without the required canonical concerns, the remediation is not just adding them but ensuring they appear in the exact required order (security-surface, error-handling-expectations, retry-idempotency-requirements, test-integrity-targets, operational-resilience-concerns) as the first five rows, with feature-specific concerns following after. The nine-column schema provides better granularity for planning-vs-runtime evidence tracking than the original six-column schema.

**Pattern discovered**: The governance validator enforces strict Evidence Basis and Runtime Evidence Status combinations: `not-applicable` status requires `not-applicable` Evidence Basis, and `planning-time-analysis` Evidence Basis requires `pending-post-implementation` or `not-needed` Runtime Evidence Status (not `requires-runtime-proof`).

### 2026-05-08: Spec Quality Hardening Pass

Applied surgical spec-hardening to close contract gaps in specs 002 and 005 from roadmap review. Key improvements:

- **Canonicalizer versioning and derivation allow-lists** (Spec 002): Closed loophole where canonicalization could use open-ended derivation reasoning. Now requires explicit versioned allow-list artifacts and version recording in canonicalization reports.
- **Worked-example preset requirement** (Spec 005): Prevented preset content from being named but not specified. `node-public-ws-service` preset must include fully-specified worked example in the preset artifact itself.
- **Known-traps corpus seeding** (Spec 005): Corpus must be seeded from dogfooding findings and prior learnings rather than starting empty.
- **Mechanical check demotion workflow** (Spec 005): Provided safety valve for noisy checks that can be demoted to advisory through explicit reviewed workflow.
- **Strongest-class binding for hardening gate** (Spec 005): Aligned hardening gate routing with bug-hunter lens policy by default.
- **Quality-drift detection timing** (Spec 005): Bound detection to end of review phase before iteration close, preventing silent quality debt accumulation.
- **Phased implementation guidance** (Spec 005): Added 4-phase delivery structure to guide planning without mandating single undifferentiated block.

**Pattern discovered**: When closing contract gaps, prefer surgical edits that add explicit constraints or versioned artifacts over rewriting requirements. This preserves traceability and approval history while strengthening the contract.

### 2026-05-08: Phase 2 Multi-Iteration Repair

Repaired feature `005-stack-aware-quality-bar` Phase 2 planning after drift appeared between the feature-level capacity claim and the generated 32-task package. The governing fix was to keep the repo-standard 20-point capacity intact, rewrite the feature plan/tasks to name concrete execution slices (`003`-`005`), and make Iteration 003 the only MVP execution candidate until its hardening-gate contract is accepted.

**Pattern discovered**: when task generation reveals that one phase-level package no longer fits a single iteration, repair the parent plan and task language before repairing the active iteration. Otherwise the new iteration inherits a false capacity story and every downstream approval artifact starts from drift.

### 2026-05-08: Phase 2 Lifecycle Boundary Tightening

T007 closed a lifecycle gap in feature `005-stack-aware-quality-bar` by making the Phase 2 boundary explicit across `before-plan`, `before-implement`, and coordinator governance guidance. The hardening gate is now described as a required pre-implementation sign-off or human-approved deferral checkpoint, while bug-hunter execution, routing enforcement, known-traps workflows, and quality-drift automation remain explicitly deferred unless the active slice truly delivers them.

**Pattern discovered**: when a later-phase governance requirement becomes the current slice's entry gate, update every lifecycle checkpoint that can misstate readiness. Tightening only the implementation gate is insufficient if planning or coordinator guidance still lets the team narrate later-phase behavior as already active.

### 2026-05-08: Feature 006 Requirement Repair for Checkpoint Sequencing and Success Metrics

Repaired authoritative requirement surfaces for feature `006-human-architecture-checkpoint` to resolve four critical specification ambiguities:

1. **Checkpoint sequencing made explicit**: Tightened the flow to resolve "before plan.md exists" vs "recorded in plan.md" paradox. The checkpoint now explicitly runs INSIDE `/speckit.plan`, after spec loading and before plan body generation, with the approved direction recorded IN the finalized plan.md's Architecture Intent Review section. This eliminates downstream confusion about whether the checkpoint happens before or after planning.

2. **Alternatives made optional for routine features**: Repaired FR-001, FR-005, brief-schema.md, and validation rules to permit empty alternatives when no meaningful architectural choices exist. Routine convention-following features (small bug fixes, simple refactors) no longer require fabricated alternative analysis. Alternatives are required only "WHEN alternative approaches meaningfully differ in cost, risk, or reversibility."

3. **SC-002 repaired to accept clean approvals**: Changed from "presence of at least one human constraint or decision override per feature" to "checkpoint completion with recorded approval (clean approval or approval-with-constraints both count as success)." Clean approvals where the human reviews and approves without changes are now explicitly valid successful outcomes, not failures requiring artificial activity.

4. **Decision record validation aligned**: Updated data-model.md to explicitly bless clean approval (no constraints, no rejected alternatives, no overrides) as a valid and successful outcome. `rejected_alternatives` and `human_constraints` are now correctly marked as optional rather than required.

**Pattern discovered**: When a governance checkpoint creates a "happens-before vs recorded-in" paradox, resolve by making the sequencing explicit: the checkpoint is a blocking pre-step INSIDE the command that generates the artifact, and the result is recorded IN the finalized artifact. This preserves both blocking behavior and traceability without requiring the artifact to exist before the checkpoint runs.

**Pattern discovered**: When "minimal interruption" conflicts with "always require alternatives," the specification should permit stating routine nature without detailed alternative generation. Success metrics must not punish clean approvals by requiring artificial constraints or overrides. A good governance checkpoint surfaces decisions when they matter, not when they don't.

### 2026-05-09: Feature 006 Metadata Cleanup—Branch and Date Alignment

Performed narrow metadata-only cleanup on feature 006 to close two consistency issues discovered in spec-steward review:

1. **Branch label alignment**: spec.md declared `006-human-architecture-checkpoint` as the feature branch while plan.md, research.md, and data-model.md correctly used `008-quality-profile-foundation`. Verified against git branch list that `008-quality-profile-foundation` is the current authoritative branch containing this work. Updated spec.md line 3 to match truth.

2. **Stale date correction**: spec.md line 169 contained `Session 2025-01-09` (clearly a typo from 2025 vs 2026). Corrected to `2026-05-09` to match the `Created` date in spec.md metadata (line 4) and the date headers in plan.md, research.md, and data-model.md.

**Pattern discovered**: When downstream documents (plan.md, research.md, data-model.md) already contain corrected metadata and the source spec is stale, prefer the truth of the downstream artifacts over cosmetic matching. Verify against authoritative sources (git branch state, session timestamps) before deciding which document to repair.

## Patterns

<!-- Append entries below. Format: **Pattern:** description. **Context:** when it applies. -->
