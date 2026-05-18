# Hardening Gate: Iteration 001

**Schema**: v1
**Gate ID**: `pre-implementation-hardening`
**Feature Ref**: `specs/022-hotfix-schema-tests/spec.md`
**Iteration Ref**: `specs/022-hotfix-schema-tests/iterations/001`
**Requested Review Class**: `strongest-available`
**Effective Review Class**: `(pending hardening review)`
**Overall Verdict**: `blocked`
**Approval Ref**: `—`
**Reviewed By**: `Reviewer (pending runtime evidence)`
**Reviewed At**: `2026-05-18T21:15:00Z`

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | `security` | `planned` | `planning-analysis` | `pending` | Keep recovery and boundary-sync behavior inside existing trusted local-governance surfaces; do not widen the hotfix into a new privilege or external-service boundary. | `true` | The hotfix touches restart gating and lifecycle write paths, so planning must explicitly preserve the existing local-only trust boundary while staying inside FR-005/FR-019 scope. | `—` |
| `error-handling-expectations` | `error-handling` | `planned` | `planning-analysis` | `pending` | Missing sync state, parser failures, invalid recovery input, and stale-state mismatches must remain explicit and operator-visible. | `true` | Feature 022 is driven by broken stale-state failure semantics; the plan must keep restart and sync errors actionable instead of silent or dead-ending. | `—` |
| `retry-idempotency-requirements` | `retry-idempotency` | `planned` | `planning-analysis` | `pending` | Re-running boundary sync or re-entering recovery must remain bounded, observable, and safe without changing approval behavior. | `true` | The operator may retry stale-state recovery or rerun lifecycle commands while repairing drift, so the hotfix must make those repeated paths explicit. | `—` |
| `test-integrity-targets` | `test-integrity` | `planned` | `planning-analysis` | `pending` | Keep FR-004, FR-009, and FR-015 as three standalone integration scripts with later Proposal 054 composition value. | `true` | The user explicitly required standalone regression scripts, so the hardening gate must anchor that proof shape before implementation starts. | `—` |
| `operational-resilience-concerns` | `operational` | `planned` | `planning-analysis` | `pending` | Restart recovery, lifecycle observability, and closeout state must remain usable after ship/closeout and after stale-state corruption. | `true` | The production symptom is a failed restart after ship/closeout, so resilience and operator recovery remain a blocking operational concern. | `—` |
| `schema-parity-closeout-identity` | `schema-parity` | `planned` | `planning-analysis` | `pending` | Preserve human-readable closeout summary fields while writing parser-readable `session_state_*` frontmatter to `.squad/identity/now.md`; keep the scope limited to the closeout identity surface only. | `true` | Feature 022 exists because closeout identity state drifted away from the machine-readable session-state contract. Planned evidence: `contracts/closeout-identity-state-contract.md`, `research.md`, and `tests/integration/closeout-identity-schema-parity.tests.ps1`. | `—` |
| `seven-boundary-sync-restoration` | `boundary-sync` | `planned` | `planning-analysis` | `pending` | Audit and restore late-boundary sync wiring so specify, clarify, plan, tasks, review-signoff, iteration-closeout, and feature-closeout all emit ordered boundary-sync ledger entries and keep state surfaces aligned. | `true` | The hotfix must repair incomplete boundary sync across the seven lifecycle boundaries, especially the late boundaries. Planned evidence: `contracts/lifecycle-boundary-sync-contract.md` and `tests/integration/lifecycle-boundary-sync.tests.ps1`. | `—` |
| `restart-recovery-ux` | `recovery-ux` | `planned` | `planning-analysis` | `pending` | Convert the stale-state A/B/C prompt from a dead-end into an actionable recovery flow, add a `--recover` bypass that stays orthogonal to approval behavior, and keep failure reasons visible to the operator. | `true` | `specrew start` currently reports stale state and exits instead of letting the operator recover. Planned evidence: `contracts/restart-recovery-contract.md`, `quickstart.md`, and `tests/integration/start-recovery-flow.tests.ps1`. | `—` |

## Pre-Implementation Planning Evidence

This hardening gate is intentionally a planning-time scaffold. The plan-complete artifact set now includes `specs/022-hotfix-schema-tests/plan.md`, `research.md`, `data-model.md`, `contracts/`, `quickstart.md`, and `iterations/001/plan.md`. Runtime proof remains pending until implementation and review execute the planned standalone regression suites and validator replay.

## Pre-Implementation Sign-Off

**Authority**: Alon Fliess  
**Recorded At**: 2026-05-18T17:35:05Z  
**Authorization Text**: Authorized: Run the Feature 022 planning workflow, keep the hardening gate and iteration-start triad in place, stop at the plan-completion boundary for human review, and do not enter `/speckit.tasks`.  
**Implementation Start Condition**: Implementation may proceed only after a later human decision authorizes the next boundary.  
**Deferred Items**:
- Proposal 054 composition of the standalone scripts remains deferred.
- FR-005 broader schema parity auditing remains deferred beyond `.squad/identity/now.md`.
- FR-019 fourth-bug follow-up remains deferred.

## Hardening-Gate Status

**Overall Verdict**: `blocked`

**Scope**: Iteration 001 readiness scaffold for Feature 022 restart hotfix planning only.

**Rationale**: Planning-time analysis is complete, but runtime evidence is still pending for schema parity, seven-boundary sync, and restart recovery.

## Notes

- Created and retained per the carry-forward rule that requires upfront hardening-gate scaffolding.
- Keep the concern set bounded to the three confirmed bugs and their regression evidence.
- Update runtime evidence only after the next boundary is authorized.
