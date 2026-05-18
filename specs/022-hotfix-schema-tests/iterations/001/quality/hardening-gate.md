# Hardening Gate: Iteration 001

**Schema**: v1
**Gate ID**: `pre-implementation-hardening`
**Feature Ref**: `specs/022-hotfix-schema-tests/spec.md`
**Iteration Ref**: `specs/022-hotfix-schema-tests/iterations/001`
**Requested Review Class**: `strongest-available`
**Effective Review Class**: `(pending hardening review)`
**Overall Verdict**: `ready`
**Approval Ref**: `a135e11dd3ab7983d2f2fa8438303cbd279443ee`
**Reviewed By**: `Alon Fliess (Planning-time analysis complete; runtime evidence pending post-implementation)`
**Reviewed At**: `2026-05-18T18:47:44Z`

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | `security` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Keep recovery and boundary-sync behavior inside existing trusted local-governance surfaces; do not widen the hotfix into a new privilege or external-service boundary. | `true` | The hotfix touches restart gating and lifecycle write paths, so planning must explicitly preserve the existing local-only trust boundary while staying inside FR-005/FR-019 scope. | `—` |
| `error-handling-expectations` | `error-handling` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Missing sync state, parser failures, invalid recovery input, and stale-state mismatches must remain explicit and operator-visible. | `true` | Feature 022 is driven by broken stale-state failure semantics; the plan must keep restart and sync errors actionable instead of silent or dead-ending. | `—` |
| `retry-idempotency-requirements` | `retry-idempotency` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Re-running boundary sync or re-entering recovery must remain bounded, observable, and safe without changing approval behavior. | `true` | The operator may retry stale-state recovery or rerun lifecycle commands while repairing drift, so the hotfix must make those repeated paths explicit. | `—` |
| `test-integrity-targets` | `test-integrity` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Keep FR-004, FR-009, and FR-015 as three standalone integration scripts with later Proposal 054 composition value. | `true` | The user explicitly required standalone regression scripts, so the hardening gate must anchor that proof shape before implementation starts. | `—` |
| `operational-resilience-concerns` | `operational` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Restart recovery, lifecycle observability, and closeout state must remain usable after ship/closeout and after stale-state corruption. | `true` | The production symptom is a failed restart after ship/closeout, so resilience and operator recovery remain a blocking operational concern. | `—` |
| `schema-parity-closeout-identity` | `schema-parity` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Preserve human-readable closeout summary fields while writing parser-readable `session_state_*` frontmatter to `.squad/identity/now.md`; keep the scope limited to the closeout identity surface only. | `true` | Feature 022 exists because closeout identity state drifted away from the machine-readable session-state contract. Planned evidence: `contracts/closeout-identity-state-contract.md`, `research.md`, and `tests/integration/closeout-identity-schema-parity.tests.ps1`. | `—` |
| `seven-boundary-sync-restoration` | `boundary-sync` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Audit and restore late-boundary sync wiring so specify, clarify, plan, tasks, review-signoff, iteration-closeout, and feature-closeout all emit ordered boundary-sync ledger entries and keep state surfaces aligned. | `true` | The hotfix must repair incomplete boundary sync across the seven lifecycle boundaries, especially the late boundaries. Planned evidence: `contracts/lifecycle-boundary-sync-contract.md` and `tests/integration/lifecycle-boundary-sync.tests.ps1`. | `—` |
| `restart-recovery-ux` | `recovery-ux` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Convert the stale-state A/B/C prompt from a dead-end into an actionable recovery flow, add a `--recover` bypass that stays orthogonal to approval behavior, and keep failure reasons visible to the operator. | `true` | `specrew start` currently reports stale state and exits instead of letting the operator recover. Planned evidence: `contracts/restart-recovery-contract.md`, `quickstart.md`, and `tests/integration/start-recovery-flow.tests.ps1`. | `—` |

## Pre-Implementation Planning Evidence

Planning-time analysis is complete. The plan-complete artifact set includes `specs/022-hotfix-schema-tests/plan.md`, `research.md`, `data-model.md`, `contracts/`, `quickstart.md`, `iterations/001/plan.md`, and `specs/022-hotfix-schema-tests/tasks.md` (tasks-boundary commit a135e11dd3ab7983d2f2fa8438303cbd279443ee). Runtime proof remains pending until implementation and review execute the planned standalone regression suites (I1-T009, I1-T013, I1-T015) and capture post-implementation evidence.

## Pre-Implementation Sign-Off

**Authority**: Alon Fliess  
**Recorded At**: 2026-05-18T18:47:44Z  
**Authorization Text**: Bounded governance-only repair: reconcile pre-implementation truth surfaces after tasks completion (I1-T001 through I1-T016 generated at tasks-boundary commit a135e11dd3ab7983d2f2fa8438303cbd279443ee). Planning-time analysis is complete and documented in all three concern-review rows. Runtime evidence from the three standalone regression lanes (closeout-identity-schema-parity.tests.ps1, lifecycle-boundary-sync.tests.ps1, start-recovery-flow.tests.ps1) is deferred until post-implementation hardening-gate evidence review.  
**Implementation Start Condition**: Implementation may proceed only after the before-implement validator passes and a later human decision authorizes `/speckit.implement`.  
**Deferred Items**:
- Proposal 054 composition of the standalone scripts remains deferred.
- FR-005 broader schema parity auditing remains deferred beyond `.squad/identity/now.md`.
- FR-019 fourth-bug follow-up remains deferred.
- Runtime evidence collection for all eight hardening concerns is pending post-implementation.

## Hardening-Gate Status

**Overall Verdict**: `ready`

**Scope**: Iteration 001 tasks-complete readiness before implementation starts.

**Rationale**: Planning-time analysis is complete for all eight hardening concerns; all concern rows recorded as addressed with planning-time-analysis evidence basis. Tasks I1-T001 through I1-T016 have been generated at tasks-boundary commit a135e11dd3ab7983d2f2fa8438303cbd279443ee. Runtime evidence is pending post-implementation execution of the three standalone regression lanes.

## Current Progress Status

Iteration 001 planning and task decomposition are complete. All eight hardening gate concerns have been analyzed and addressed with planning-time evidence. Task generation has produced 16 executable tasks (I1-T001 through I1-T016) covering four phase groups: governance setup, foundation work, boundary-sync restoration, and restart recovery UX. Feature 022 is ready to proceed to implementation phase after validator approval.

## Recommended Next Step

Execute `/speckit.implement` to begin implementation of I1-T001 through I1-T016, then run the post-implementation hardening-gate evidence review to collect runtime proof from the three standalone regression lanes before feature closeout.

## Notes

- Created and retained per the carry-forward rule that requires upfront hardening-gate scaffolding.
- Keep the concern set bounded to the three confirmed bugs and their regression evidence.
- Update runtime evidence only after the next boundary is authorized.
