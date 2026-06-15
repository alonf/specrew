# Hardening Gate: Iteration 006

**Schema**: v1
**Gate ID**: `pre-implementation-hardening`
**Feature Ref**: `specs/174-hook-driven-session-bootstrap/spec.md`
**Iteration Ref**: `specs/174-hook-driven-session-bootstrap/iterations/006`
**Requested Review Class**: `strongest-available`
**Effective Review Class**: `strongest-available`
**Overall Verdict**: `ready`
**Approval Ref**: —
**Reviewed By**: Reviewer
**Reviewed At**: 2026-06-09T16:55:00Z

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | `security` | `addressed` | `planning-time-analysis` | `not-needed` | The hook now WRITES `last-start-prompt.md` + a `boundary_enforcement` block, but the state write is a PRESERVE-MERGE via the existing `Initialize-SpecrewBoundaryEnforcementState` (it keeps the session anchor; never the launcher-only fields; never a wholesale rewrite). Both files stay LOCAL (last-start-prompt.md is gitignored-or-transient; start-context.json is the existing local anchor); no new transport, no `git add`, no eval. The reused `Get-StartPrompt` is the SAME generator specrew start already runs - no new trust surface. | `true` | Reusing the existing generator + the existing preserve-merge state functions adds no new transport or trust surface; the only new write is the contract file the launcher already writes. | `—` |
| `error-handling-expectations` | `error-handling` | `addressed` | `planning-time-analysis` | `not-needed` | Fail-open: if the shared generator throws or a required input is absent, the bootstrap DEGRADES to the iter-5 orientation directive (never a block); a contract-write failure exits 0 + stderr warn; SessionStart never fails the session. The boundary_enforcement init only fires when `Get-SpecrewBoundaryEnforcementState.NeedsMigration` is true (no redundant rewrite). | `true` | The drive-upgrade must never make a SessionStart fail; degrade to orientation, never block (P1 doctrine). | `—` |
| `retry-idempotency-requirements` | `retry-idempotency` | `addressed` | `planning-time-analysis` | `not-needed` | The contract write overwrites `last-start-prompt.md` in place (idempotent); `Initialize-SpecrewBoundaryEnforcementState` is migrate-once (idempotent - re-running yields the same block); the launcher dedupe (`Test-SpecrewLauncherBootstrapRecent`) prevents a launcher-then-hook double bootstrap. | `true` | Re-entrant SessionStarts converge; no duplicate contract, no anchor churn, no double bootstrap. | `—` |
| `test-integrity-targets` | `test-integrity` | `addressed` | `planning-time-analysis` | `not-needed` | **The LOAD-BEARING control (D-009 mechanized): the DEPLOYED live-wiring floor (T038).** It runs in a real installed-module scratch project (`evidence_locus: deployed`, NOT the dev tree) and asserts the 3-part round-trip: SessionStart writes boundary_enforcement + the contract ON DISK; a working turn + Stop captures intent into last-start-prompt.md + the handover on disk; a fresh resume reads them back. PLUS: the specrew-start integration suite is the behavior-preserving regression floor for the T035 extraction (T035 must FIRST confirm the suite characterizes the contract + boundary_enforcement init, else add the assertion); per-host injection-REACHES-model is a MANUAL observation (FR-024), NOT provable by this on-disk floor - the parity set requires plumbing-green AND injection-observed. Carry T040 adds an `evidence_locus` field (dev-tree or deployed) to the claim ledger + this gate schema, and the review REFUSES "delivered-live" on dev-tree-only evidence. | `true` | The iter-5 lesson: a floor that runs only in the dev tree is not a live-wiring guarantee. iter-6's floor MUST run deployed; the review mechanism (evidence_locus) makes build != live a gate, not a post-hoc dogfood. | `—` |
| `operational-resilience-concerns` | `operational` | `addressed` | `planning-time-analysis` | `not-needed` | LIR-001 stability: T035 is a BEHAVIOR-PRESERVING extraction (move `Get-StartPrompt` + helpers to a dot-sourced lib; specrew-start dot-sources it) guarded by the specrew-start integration suite as the regression floor - specrew start, the cross-host driver, must stay green. The hook path is additive (degrades to orientation on failure). Antigravity (no hook) is unaffected - it stays specrew-start-driven. | `true` | The cross-host driver must not regress while the hook gains drive; the extraction is move-not-rewrite, the integration suite is the net. | `—` |

## Notes

- Planning-time gate (before-implement): `planning-time-analysis` / `not-needed`; runtime
  proof is recorded at the iteration-006 review via the DEPLOYED live-wiring floor (T038) - NOT a dev-tree
  smoke (the explicit D-009 correction).
- **evidence_locus carry (T040):** every "surfaces / fires / drives" claim at the iter-6 review MUST record
  `evidence_locus: dev-tree | deployed`; the review refuses "delivered-live" on dev-tree-only evidence.
  This gate's concern schema is a second home for that field (forward note in `f174-i006-charter`).
- Per-host injection is EMPIRICAL (FR-024) in TWO parts: the deployed floor AUTO-proves plumbing;
  injection-reaches-model is a MANUAL per-host observation (the on-disk floor cannot assert it). iter-6
  proves Claude (plumbing via T038 + direct observation); codex/copilot/cursor injection re-tests are
  ENUMERATED as explicit follow-on (T039), not done this iteration (20 SP cap).
- Sub-agents OUT OF SCOPE (single-agent only); per-worktree handover merge deferred.
- **Closure (retroactive, 2026-06-11):** the runtime proof these planning-time concerns envisioned —
  the DEPLOYED live-wiring floor (T038) and per-host injection observation (FR-024) — was provided
  DOWNSTREAM: F-174 shipped through iterations 007-009 and the rolling-handover / bootstrap runtime was
  validated by the live multi-host (claude / codex / copilot) exit-resume dogfood. No further
  iter-006-specific runtime evidence is required for closure; Runtime Evidence Status updated
  `pending-post-implementation` → `not-needed` accordingly.
