# Hardening Gate: Iteration 002

**Schema**: v1
**Gate ID**: `pre-implementation-hardening`
**Feature Ref**: `specs/171-specrew-refocus/spec.md`
**Iteration Ref**: `specs/171-specrew-refocus/iterations/002`
**Requested Review Class**: `strongest-available`
**Effective Review Class**: `strongest-available`
**Overall Verdict**: `ready`
**Approval Ref**: —
**Reviewed By**: Reviewer
**Reviewed At**: 2026-06-07T03:20:00Z

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | `security` | `addressed` | `runtime-evidence` | `recorded` | T014 bindings inherit iteration-001's controls unchanged (per-user settings only; ours-by-command-path; event JSON never evaluated; out-of-tree provider refusal). NEW surface this iteration: T017 wires hook deployment into init/update — the wiring MUST respect the recorded opt-out and never escalate beyond what `deploy-refocus-hooks.ps1` already does; no new execution paths. Research (T013) is read-only. | `true` | Iteration 001 proved the controls with denial-path fixtures; iteration 002 adds call-sites, not capabilities — the wiring tests assert opt-out respect end-to-end through `specrew update`. | `—` |
| `error-handling-expectations` | `error-handling` | `addressed` | `runtime-evidence` | `recorded` | Fail-open doctrine unchanged (P1; 8 reason codes). NEW: the catalog overlay-merge (T017) must fail SAFE — an unreadable existing catalog aborts the merge and preserves the user file (the deploy-refocus-hooks unparsable-refusal pattern applied to the catalog); a failed overlay never leaves a half-merged catalog. | `true` | The overlay-merge is the one new mutation path this iteration; its failure mode is specified before implementation and fixture-tested like every other refusal. | `—` |
| `retry-idempotency-requirements` | `retry-idempotency` | `addressed` | `runtime-evidence` | `recorded` | `specrew update` re-runs MUST be idempotent across the new wiring: hook re-deploy byte-idempotent (already proven), catalog overlay-merge idempotent (canonical keys refresh, user keys byte-stable across repeat updates). SC-009 extends to the update path. | `true` | Iteration 001 proved idempotence for the writer in isolation; T017's tests prove it through the real update entry point. | `—` |
| `test-integrity-targets` | `test-integrity` | `addressed` | `runtime-evidence` | `recorded` | T013's research matrix MUST cite primary documentation sources per host (URL + access date) — no binding is implemented from memory or assumption (the 145 read-the-source lesson, now retro-recorded). T014 fixtures derive from documented event shapes. SC-008 beta evidence remains live-host runtime proof, never file presence. Latency measurements (retro lesson #1) precede every binding decision. | `true` | The iteration's core risk is building against assumed host surfaces; the matrix-gates-bindings sequencing is the structural control, and measurement-first is binding per the retro. | `—` |
| `operational-resilience-concerns` | `operational` | `addressed` | `runtime-evidence` | `recorded` | Kill-switch matrix unchanged and re-verified through the update path (T017): update never silently flips disables, prints the re-enable hint only on refocus-component changes. New host bindings inherit breaker/journal semantics automatically (dispatcher-level, host-blind). | `false` | Operator surfaces were the lens-6 centerpiece in iteration 001; this iteration only adds call-sites that must preserve them — asserted by the wiring tests. | `—` |

## Notes

- Gate updated at review time: runtime evidence RECORDED for all five concerns — 336 asserts re-run at review (six suites post-`64a908e7`); security-surface: T017 wiring adds call-sites only, opt-out respect proven through the deploy suite + real update lane; error-handling: overlay merge fail-SAFE proven in both directions (corrupt capture never merged; corrupt target never written); retry-idempotency: byte-idempotent re-deploys per host + pristine-catalog overlay no-op byte-untouched + REAL `update-command.ps1` and `bootstrap-to-iteration.ps1` lanes green; test-integrity: every T014 binding cites a live-fetched primary source (research-matrix.md URLs + 2026-06-07 fetch dates), Antigravity honestly unbindable; operational: kill-switch matrix re-proven through the update path (user b1 disable survives canonical refresh).
- Planning-time framing preserved below for the audit trail: T013 (matrix + measurements) gated every T014 binding per host; a host that fails verification ships channels 1+2 with documented variance (Option C's contracted degradation), never a slipped iteration — exactly what happened (Antigravity deferred-with-path, Cursor B1 documented variance).
- Defer-approved carries (review-signoff 2026-06-07, ledger entries 12:20/12:21Z) are in scope as T017.
- Release-blocking: SC-008 runtime beta validation (≥2 hook-bound hosts) gates stable promotion; with PostToolUse unregistered per TG-004 option (a), the B3 live evidence comes from channel 1 + the SessionStart B1 path.
