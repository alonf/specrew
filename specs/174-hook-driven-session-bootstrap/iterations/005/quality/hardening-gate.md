# Hardening Gate: Iteration 005

**Schema**: v1
**Gate ID**: `pre-implementation-hardening`
**Feature Ref**: `specs/174-hook-driven-session-bootstrap/spec.md`
**Iteration Ref**: `specs/174-hook-driven-session-bootstrap/iterations/005`
**Requested Review Class**: `strongest-available`
**Effective Review Class**: `strongest-available`
**Overall Verdict**: `ready`
**Approval Ref**: —
**Reviewed By**: Reviewer
**Reviewed At**: 2026-06-09T16:31:00Z

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | `security` | `addressed` | `runtime-evidence` | `recorded` | The agent-authored body stays LOCAL + gitignored + write-only (FR-021 unchanged); `Write-SpecrewHandoverContext` writes ONLY the body section of the local file (no `git add`, no eval of body content). Verified by the AgentAuthoredHandover unit floor (local temp-dir writes, no git ops). Trust surface unchanged from iter-4. | `true` | Adds richer body CONTENT, not a new transport or git op; the local-only + write-only controls carry over and are unaffected by the deployed-resolution gap. | `—` |
| `error-handling-expectations` | `error-handling` | `addressed` | `runtime-evidence` | `recorded` | Fail-open: a malformed/absent agent body degrades to the hook PLACEHOLDER (never a block); the placeholder detector WARN is NON-BLOCKING; a write failure exits 0 + stderr warn. Verified by the detector + provider exit-0 tests. NOTE: the DEPLOYED failure found in the greenfield dogfood (provider cannot resolve components -> PROVIDER_FAILED, no file) is ITSELF fail-open (exits 0, no crash) - consistent with this control; the missing live FILE is the FR-022 deferral (D-009), not an error-handling regression. | `true` | The body split must never make a Stop or a SessionStart fail; degrade to placeholder + warn. | `—` |
| `retry-idempotency-requirements` | `retry-idempotency` | `addressed` | `runtime-evidence` | `recorded` | `Write-SpecrewHandoverContext` overwrites the body section in place (idempotent); the hook preserve-body path is idempotent (re-running a Stop with the body present yields the same body); the floor refresh is the existing iter-4 idempotent overwrite. Verified by A3 (same-boundary preserve yields the same body). | `true` | No duplication of body or floor; re-entrant Stops + resumes converge - independent of deployment. | `—` |
| `test-integrity-targets` | `test-integrity` | `addressed` | `runtime-evidence` | `recorded` | **Failure-mode A (plumbing)** floor is CI-blocking and GREEN - but DEV-TREE-ONLY: it asserts persisted-bytes == surfaced-bytes with components co-located via `$PSScriptRoot/bootstrap`. It does NOT assert deployed-tree component resolution, so the "bootstrap surfaces the body on resume" behavior is dev-tree-verified, NOT deployed-verified (build != live; D-009). **Failure-mode B (the agent never authors)** is detected, NOT prevented (non-blocking; transcript-blindness ceiling; SC-010). DEPLOYED surfacing proof is DEFERRED to iteration 6's load-bearing live-wiring floor (`f174-i005-defer-live-wiring`). | `true` | The mechanism-not-pledge lesson applied to the floor ITSELF: A is mechanical + CI-blocking but dev-tree-scoped (deployed proof is iter-6); B is best-effort + non-blocking. SC-010 + D-009 encode the honesty. | `—` |
| `operational-resilience-concerns` | `operational` | `addressed` | `runtime-evidence` | `recorded` | Crash-safety preserved at the DEV-TREE level: the hook floor refreshes every material Stop, so a hard-kill leaves the last floor + the last-persisted body; the Stop-time placeholder warn improves operational visibility. NOTE: per D-009 the Stop hook does not resolve its bootstrap components in a DEPLOYED tree, so deployed-tree Stop-refresh firing is NOT yet proven and is deferred to iteration 6's live-wiring floor; the iter-4 crash-safe floor invariant is unchanged in design. | `true` | The iter-4 crash-safe floor is the invariant; iter-5 layers body authorship on top without changing it - but deployed firing is iter-6's proof. | `—` |

## Notes

- Runtime proof recorded at the iteration-005 review (19/19 unit suites incl. the CI-blocking
  failure-mode-A plumbing floor + the provider child-process render A7/A8 + the non-blocking placeholder
  detector). **Honesty scope (D-009):** that runtime evidence is DEV-TREE-only. The DEPLOYED-tree behavior
  (the provider resolving its components; the handover firing live; the Stop hook refreshing in a deployed
  project) is NOT proven in iteration 5 and is DEFERRED to iteration 6's load-bearing live-wiring floor
  (defer `f174-i005-defer-live-wiring`; verdict `f174-i005-review-signoff-qualified`).
- Honors carry `f174-i005-mechanical-detector-in-scope`: the detector (T031 + Stop-time warn T030) is in
  scope; it is a real detector but a WEAK enforcer (after-the-fact, non-blocking) — not parity with a
  boundary-blocking validator FAIL, and the gate says so.
- Detector lives in the BOOTSTRAP (rebase-safe); a validator-side handover-body gate is a follow-up
  candidate, gated with the other validator work on the rebase (`f174-action4-reconcile-with-2216`).
- Sub-agents OUT OF SCOPE (single-agent only); per-worktree handover merge deferred.
