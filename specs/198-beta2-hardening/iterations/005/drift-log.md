# Drift Log: Iteration 005

**Schema**: v1

## Summary

**Total drift events**: 5
**Resolution state**: Architectural direction is human-decided and the specification/design are updated; implementation, plan, and task reconciliation remain open.
**Specification drift**: The final authorized review proved that the delivered mutable lease, result consumer, evidence claims, clock wiring, and T035–T040 plan do not satisfy the replacement FR-057–FR-065 authority model. No further point-fix round is authorized.

## Events

### DRIFT-198-I005-001 — mutable process-owned lease contradicts campaign/run authority and immutable coordination

- **Type**: violation
- **Severity**: critical
- **Detected at**: 2026-07-16
- **Task reference**: T039 / final authorized review run `20260714T235716273-eac6505c`
- **Requirement citation**: FR-057 requires campaign-owned allowance/lineage above one-invocation run state and repository-only authority; FR-058 requires immutable run-owned claim generations and forbids generic mutable lease/CAS authority.
- **Divergence**: Delivered code and the former lease model make a mutable one-file lease authoritative across parent/supervisor handoff, self-adoption, pending target mutation, owner release, orphan reclaim, and navigator promotion. Missing/throwing authority helpers fail open in supervisor/navigator paths, and atomic mutation is inconsistent across lease transitions.
- **Concrete evidence**: The final review findings summarized in file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/iterations/005/state.md identify fail-open gates and read/validate/write races; file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/iterations/005/lease-lifecycle-model.md documents the superseded handoff/adoption design.
- **Resolution**: human-decision
- **Resolution detail**: The maintainer selected the ReviewCampaign/ReviewRun immutable-JSON replacement. The old design is marked superseded; new plan/tasks must implement FR-057/FR-058 without promoting legacy authority.

### DRIFT-198-I005-002 — authority consumer accepts parseable but schema-invalid/substitute review results

- **Type**: incomplete
- **Severity**: critical
- **Detected at**: 2026-07-16
- **Task reference**: T019/T039 / final authorized review finding 8
- **Requirement citation**: FR-060 requires closed bounded candidate schema, run/target identity binding, controller-only validation/publication, and fail-closed consumer behavior; FR-061 requires one explicit terminal result envelope for every invoked run.
- **Divergence**: The producer validates FindingsResult, but the navigator consumer accepts arbitrary parseable JSON—including empty, illegal-status, or substituted content—as usable gate evidence and may promote it without required run identity validation.
- **Concrete evidence**: The final-round finding is recorded in file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/iterations/005/state.md under “Schema NOT enforced at the gate-evidence CONSUMER.”
- **Resolution**: human-decision
- **Resolution detail**: Replace direct legacy consumption with ResultIngestor plus RunRepository publication; all consumers read only validated terminal result/classification facts.

### DRIFT-198-I005-003 — verified host tiers overstate executable probe evidence

- **Type**: violation
- **Severity**: moderate
- **Detected at**: 2026-07-16
- **Task reference**: T036/T037/T039 / final authorized review findings 4 and 5
- **Requirement citation**: FR-051/FR-052 require the claimed Stop/agentStop behaviors to be executable-proven; FR-064 requires truthful five-harness live evidence and forbids a support claim beyond corresponding proof.
- **Divergence**: Codex and Copilot probes cover fewer scenarios than the `verified` tier prose claims, including missing proof for block-reason continuation, loop bounds, malformed visibility, and event-distinct firing/gating.
- **Concrete evidence**: The mismatch and required extend-or-narrow choice are recorded in file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/iterations/005/state.md; characterization evidence remains under file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/iterations/005/evidence/.
- **Resolution**: human-decision
- **Resolution detail**: Replanning must bind each support claim to the exact fixture/live evidence. Extend probes or narrow claims; never inherit an overbroad verified label.

### DRIFT-198-I005-004 — plan-level injected timestamp obscures per-command production timing

- **Type**: violation
- **Severity**: moderate
- **Detected at**: 2026-07-16
- **Task reference**: T018 / final authorized review finding 3
- **Requirement citation**: FR-063 requires controller-observed UTC start/end and monotonic duration per command attempt with injected clocks restricted to test provenance.
- **Divergence**: The plan runner captures `Now` once and supplies it to every command, so multiple production attempts report the plan-start timestamp instead of their directly observed ordering and latency.
- **Concrete evidence**: The injected-clock finding is recorded in file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/iterations/005/state.md.
- **Resolution**: human-decision
- **Resolution detail**: Route production through SystemClock read per attempt; retain injected deterministic time only behind the test clock port and record provenance explicitly.

### DRIFT-198-I005-005 — current plan/tasks cannot deliver the replacement Beta2 architecture

- **Type**: incomplete
- **Severity**: critical
- **Detected at**: 2026-07-16
- **Task reference**: Iteration 005 T035–T040 task block
- **Requirement citation**: FR-057–FR-065 and SC-017–SC-021 require the campaign/run core, immutable store, five real harness adapters, three OS runtimes, recovery/partial/retro behavior, and complete proof matrix.
- **Divergence**: The current task block covers host support tiers, Codex/Copilot hook contracts, hook-health, integration/docs, and a deferred plugin regression. It has no tasks or traceability for the replacement authority, store, target, runtime, all-harness, recovery, performance, workshop-Stop, or proof obligations. The old ~4 SP estimate is incompatible with the 30–34 SP reassessment.
- **Concrete evidence**: file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/tasks.md contains only T035–T040 for Iteration 005; the replacement scope and 16+17 SP recommended split are in file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/iterations/005/design-analysis.md.
- **Resolution**: human-decision
- **Resolution detail**: Supersede rather than extend T035–T040. Create new capacity-compliant iteration plan/task artifacts with complete FR/SC traceability and obtain a fresh human plan/tasks verdict before implementation.
