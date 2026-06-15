# Review: Iteration 004

**Schema**: v1
**Reviewed**: 2026-06-09
**Overall Verdict**: accepted

Structured per Proposal 145. Matrix + claim ledger + design-code trace in
[review-report.yml](./review-report.yml). The implementation report is treated as a claim to
disprove. This iteration pivots the handover from SessionEnd-only (Claude, crash-fragile) to a
per-host Stop-event rolling handover (portable + crash-safe), per the human-co-designed pass.

## Task Verdicts

| Task | Requirement | Verdict | Notes |
| ---- | ----------- | ------- | ----- |
| T023 | FR-009 | pass | Rolling write/read (overwrite-in-place always-latest session-handover.md) + `.specrew/handover/` gitignored. |
| T024 | FR-009 | pass | Pure material-change engine (boundary moved OR tracked-file change). |
| T025 | FR-009 | pass | Stop provider: host-agnostic, material-change gate, writes the rolling handover, fail-open. |
| T026 | FR-005, FR-009 | pass | Per-host Stop registered (Claude Stop, Codex Stop, Copilot agentStop, Cursor stop); Claude SessionEnd REMOVED (verified absent on disk). |
| T027 | FR-009, SC-009 | pass | RollingHandover round-trip + material-change + crash-safety + on-disk floor (Stop present / SessionEnd absent) + live cross-host Stop smoke (4 hosts). |
| T028 | FR-008, FR-009 | pass | Spec reconciled - every SessionEnd trigger ref -> Stop (zero stale); SC-009 added; docs updated. |

## Seven-Phase Structured Review (Proposal 145)

- **Phase 0 - Context load**: pass. Loaded spec.md (reconciled), iterations/004 plan + hardening-gate,
  the design decisions (`f174-i004-stop-event-rolling-handover` + `-design-settled`), and the F-171
  research-matrix (per-host end-of-turn events).
- **Phase 1 - Branch hygiene**: pass. All evidence committed (`b5f2c6df` readiness; `f4080821`
  implementation). Branch unpushed (push held until feature-closeout, per the human - ship 1-4 together).
- **Phase 2 - Functional correctness**: pass. The Stop pivot is genuinely live: per-host Stop
  registered + the dispatcher dispatches each host's stop variant to the handover provider (live
  cross-host Stop smoke, 4 hosts), which refreshes the rolling handover only on a material change. The
  SessionStart manager reads the rolling handover (welcome-back). Crash-safety: the rolling file is
  always-latest, so a hard-kill still leaves the last-turn handover.
- **Phase 3 - Non-functional**: pass. Local + gitignored (never pushed); write-only; fail-open; the
  material-change gate keeps the per-turn Stop cheap on quiet turns.
- **Phase 4 - Code quality**: pass. PSScriptAnalyzer clean on all F-174 bootstrap components + both
  providers; the two touched F-171 files (deployer, overlay) carry only pre-existing style findings.
- **Phase 5 - Test coverage + integrity**: pass. **The iteration-003 retro live-wiring FLOOR is applied
  from the start**: `DeployedHostConfig.Tests` reads the ACTUAL committed config on disk and asserts
  the Stop hook PRESENT and the SessionEnd hook ABSENT (the build != live trap, in reverse). Plus the
  rolling round-trip, the material-change skip (real git fixture), crash-safety (always-latest), and a
  live cross-host Stop dispatcher smoke. 18 bootstrap suites (`tests/bootstrap/*.Tests.ps1`) + the
  F-171 deploy integration green.
- **Phase 6 - System safety + ops**: pass. B1/B3 unchanged (Regression test); the Stop registration
  rides the F-171 deployment loop + C6 invariants; the SessionEnd removal is a clean swap verified on
  disk.
- **Phase 7 - Synthesis + falsification**: APPROVE for review-signoff. All phases pass; the live-wiring
  is proven to the dispatcher boundary AND on disk; claims map to committed files + reproduced smokes;
  no claim exceeds its evidence; no new dependencies.

## Gap Ledger

- No PSScriptAnalyzer findings introduced by this iteration: fixed-now.
- No outstanding requirement (FR/SC) gaps: every iteration-004 requirement is satisfied with runtime evidence: fixed-now.
- Dormant SessionEnd code retained (the timestamped `Write-SpecrewHandover`/`Get-SpecrewHandover` + `SessionEndHandoverManager.ps1` + their unit tests) - superseded by the rolling model, no longer wired: deferred (cleanup follow-up `f174-followup-remove-dormant-sessionend-code` in `.squad\decisions.md`).

## Scoped Limitations (carried)

- **SC-009 crash-safety** is auto-proven only as "the rolling file is current after each material
  Stop"; a true hard-kill mid-turn is the SC-008 manual-beta confirmation (stated honestly in the spec).
- **Per-host Stop INPUT schemas** are handled by defensive parsing (host-agnostic source extraction);
  the live render was proven with a representative Stop payload, not each host's authoritative schema.

## Notes

- Applied the iteration-003 retro actions: the on-disk deployed-config floor (action 1) AND validator
  EXIT 0 before presenting (action 4).
- This is the final planned F-174 iteration; feature-closeout ships iterations 1-4 together.
