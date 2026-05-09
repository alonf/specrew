# Research: Stack-Aware Quality Bar (Hardening Evidence Boundary Repair)

**Date**: 2026-05-09
**Spec**: [spec.md](spec.md)  
**Plan**: [plan.md](plan.md)

## Decisions

### R1: Should the repair split planning and runtime proof into separate hardening artifacts?

**Decision**: No. Keep a single `hardening-gate.md` artifact and make each concern row explicitly phase-aware.

**Rationale**: The approved 2026-05-09 clarifications, FR-032, and TG-013 all require one auditable artifact that shows whether the current basis is planning-time analysis or later runtime evidence. A split artifact model would make carry-forward state easier to lose and would weaken review traceability.

**Alternatives considered**:

- Separate pre-implementation and post-implementation hardening files: rejected because it fractures the audit chain.
- Closing rows at planning time and recreating them later: rejected because it hides the unresolved runtime follow-through.

---

### R2: What exactly may `deferred-with-approval` mean in the repaired gate?

**Decision**: `deferred-with-approval` is allowed only when planning-time analysis, expected controls, and rationale are already recorded, but the final proof depends on implemented runtime behavior.

**Rationale**: This is the direct outcome of the approved clarification and FR-033a. The repair must prevent deferral from becoming a loophole for missing pre-implementation analysis while still allowing runtime-only proof to remain pending honestly.

**Alternatives considered**:

- Allowing deferral whenever evidence is incomplete: rejected because it recreates the overreach/ambiguity bug.
- Forcing runtime proof before implementation: rejected because it is impossible for concerns that depend on executable behavior.

---

### R3: How should completed history be preserved while planning this repair?

**Decision**: Leave Iteration `003` untouched and create Iteration `004` as the bounded repair-planning artifact.

**Rationale**: Iteration `003` is already complete and accepted. Reopening it would corrupt execution history; a new iteration keeps the repair explicit, reviewable, and additive.

**Alternatives considered**:

- Editing Iteration `003` to absorb the repair: rejected because it rewrites completed history.
- Planning the repair only at feature level with no iteration artifact: rejected because the follow-on slice would not be cleanly traceable for later implementation approval.

---

### R4: What is the minimum validation lane for this bugfix?

**Decision**: Keep the validation lane focused on `quality-profile-foundation`, `hardening-gate-contract`, `quality-evidence-governance`, live `run-hardening-gate`, and `validate-governance`.

**Rationale**: Those lanes directly cover planning publication, the hardening-gate contract, fail-closed governance behavior, and the lifecycle transition between planning-time evidence and later runtime closure. Bug-hunter, known-traps, routing-expansion, drift, and reference-implementation suites are intentionally out of scope for this repair.

**Alternatives considered**:

- Re-running the full Phase 2 suite: rejected because it would reopen unrelated scope.
- Treating this as documentation-only with no regression lane: rejected because the bug is governance behavior, not wording alone.
