# Spec Steward History

Project-specific learnings and patterns discovered during work.

## Learnings

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
