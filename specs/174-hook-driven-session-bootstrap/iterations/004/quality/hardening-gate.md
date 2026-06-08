# Hardening Gate: Iteration 004

**Schema**: v1
**Gate ID**: `pre-implementation-hardening`
**Feature Ref**: `specs/174-hook-driven-session-bootstrap/spec.md`
**Iteration Ref**: `specs/174-hook-driven-session-bootstrap/iterations/004`
**Requested Review Class**: `strongest-available`
**Effective Review Class**: `strongest-available`
**Overall Verdict**: `ready`
**Approval Ref**: —
**Reviewed By**: Reviewer
**Reviewed At**: 2026-06-09T02:15:00Z

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | `security` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | The Stop event JSON is parsed defensively (multi-key adapter), never evaluated; the rolling handover is LOCAL + gitignored (never pushed); the write is write-only (no `git add -A`). Local-tree trust unchanged. | `true` | The per-turn Stop fire widens the write cadence; controls = local-only file + write-only + the material-change gate. | `—` |
| `error-handling-expectations` | `error-handling` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Fail-open: a Stop on a host whose event shape is unknown degrades to no-write (not a block); a write failure never breaks the turn (exit 0 + stderr warn); the material-change gate skips cheaply on quiet turns. | `true` | integration-api d3; T025 provider fail-open + T024 material-change skip are the proof vehicles. | `—` |
| `retry-idempotency-requirements` | `retry-idempotency` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | The rolling file is OVERWRITTEN in place (idempotent - re-running a Stop with no change yields the same file); the material-change gate prevents redundant rewrites; per-turn firing is the intended cadence, not a retry. | `true` | T024 material-change + T027 round-trip assert single-current-file, no duplication. | `—` |
| `test-integrity-targets` | `test-integrity` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | The iteration-003 retro FLOOR applies from the start: T027 includes an ON-DISK deployed-config assertion (DeployedHostConfig pattern) for the per-host Stop hooks - because deployer-integration + dispatcher-round-trip can both pass while the host->dispatcher link is dead. Plus rolling round-trip, material-change (refresh vs skip), crash-safety (file current after last Stop), and a live cross-host Stop smoke. | `true` | The build!=live floor (retro action 1); SC-009 crash-safety + FR-009/FR-005 are the proof vehicles. | `—` |
| `operational-resilience-concerns` | `operational` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Crash-safety is the POINT: every material Stop refreshes the rolling file, so a hard-kill with no clean exit still leaves the last-turn handover. The per-host Stop registration rides the F-171 deployment loop + C6 invariants; removing the Claude SessionEnd hook is a clean swap (B1/B3 untouched). | `true` | devops d1; T026 deploy + T027 crash-safety assert it. | `—` |

## Notes

- Planning-time gate (before-implement): `planning-time-analysis` / `pending-post-implementation`;
  runtime proof recorded at iteration-004 review (incl. the on-disk Stop-hook floor + crash-safety).
- Supersedes the iteration-003 SessionEnd-only handover; the Claude SessionEnd hook is REMOVED.
- Sub-agents OUT OF SCOPE (single-agent only); per-worktree handover merge deferred.
