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
**Reviewed At**: 2026-06-09T12:30:00Z

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | `security` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | The agent-authored body is still LOCAL + gitignored + write-only (FR-021 unchanged); `Write-SpecrewHandoverContext` writes ONLY the body section of the local file (no `git add`, no eval of body content). Trust surface unchanged from iter-4. | `true` | Adds richer body CONTENT, not a new transport or git op; the local-only + write-only controls carry over. | `—` |
| `error-handling-expectations` | `error-handling` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Fail-open: a malformed/absent agent body degrades to the hook PLACEHOLDER (never a block); the placeholder detector WARN is NON-BLOCKING; a write failure exits 0 + stderr warn. | `true` | The body split must never make a Stop or a SessionStart fail; degrade to placeholder + warn. | `—` |
| `retry-idempotency-requirements` | `retry-idempotency` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | `Write-SpecrewHandoverContext` overwrites the body section in place (idempotent); the hook preserve-body path is idempotent (re-running a Stop with the body present yields the same body); the floor refresh is the existing iter-4 idempotent overwrite. | `true` | No duplication of body or floor; re-entrant Stops + resumes converge. | `—` |
| `test-integrity-targets` | `test-integrity` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | **Failure-mode A (plumbing) is the CI-BLOCKING floor:** an agent-authored body survives a material Stop (hook preserves, never clobbers); the bootstrap surfaces the rich body on resume; the rendered boundary packet equals the persisted body (human-sees == successor-inherits); on-disk read pattern. **Failure-mode B (the agent never authors) is detected, NOT prevented** — the placeholder detector is NON-BLOCKING by design; the gate explicitly does NOT claim authoring is mechanically forced (transcript-blindness ceiling). | `true` | The mechanism-not-pledge lesson: A is mechanical + blocking; B is best-effort protocol + late non-blocking detection + human backstop. SC-010 encodes the split. | `—` |
| `operational-resilience-concerns` | `operational` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Crash-safety is preserved: the hook floor still refreshes every material Stop, so a hard-kill leaves the last-turn floor + whatever body the agent last persisted. The body split adds richness WITHOUT weakening the iter-4 crash-safe floor; the Stop-time placeholder warn improves (not degrades) operational visibility. | `true` | The iter-4 crash-safe floor is the invariant; iter-5 layers body authorship on top without changing it. | `—` |

## Notes

- Planning-time gate (before-implement): `planning-time-analysis` / `pending-post-implementation`;
  runtime proof recorded at the iteration-005 review (incl. the CI-blocking failure-mode-A plumbing
  floor + the non-blocking placeholder detector).
- Honors carry `f174-i005-mechanical-detector-in-scope`: the detector (T031 + Stop-time warn T030) is in
  scope; it is a real detector but a WEAK enforcer (after-the-fact, non-blocking) — not parity with a
  boundary-blocking validator FAIL, and the gate says so.
- Detector lives in the BOOTSTRAP (rebase-safe); a validator-side handover-body gate is a follow-up
  candidate, gated with the other validator work on the rebase (`f174-action4-reconcile-with-2216`).
- Sub-agents OUT OF SCOPE (single-agent only); per-worktree handover merge deferred.
