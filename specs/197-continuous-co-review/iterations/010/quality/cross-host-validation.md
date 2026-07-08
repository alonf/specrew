# Cross-Host Manual Validation — SC-012 / SC-022 (T110, design N8)

**Date**: 2026-07-08
**Scope rule (maintainer-approved N8 default)**: validate the **installed + authorized** harnesses;
honestly record the rest as unavailable/unauthorized — no all-five claim without all-five evidence.

## Harness matrix (this machine, 2026-07-08)

| Harness | Installed | Authorized as reviewer | Exercised | How |
| --- | --- | --- | --- | --- |
| claude | yes (`claude.exe`) | no (`allowed=false`, no ref) | **YES — as the governed CODE-WRITER host** | This entire iter-010 session ran on Claude Code with the deployed Specrew Stop/SessionStart hooks live: the conformance provider material-turn machinery blocked a real packet-less material stop (journal 2026-07-08 07:45:02, `dx_lat_len=6948`), the packet then rendered and the next stop passed; SessionStart ran the cross-session sweep. |
| codex | yes (`codex.exe`) | **yes** (`maintainer-authorized-dogfood-self-review-2026-07-01`) | **YES — as the independent REVIEWER host** | `specrew review --live --code-writer-host claude` executed the full worktree pipeline: selection labelled codex `independent` of the claude code-writer (T093), the OS-contained spawn ran `codex exec` in the stripped worktree (T091/T100), and the run produced a verdict (outcome recorded below). |
| copilot | yes (`copilot.cmd`) | no (`allowed=false`, no ref) | **NO — recorded unavailable-for-review** | Installed but not human-authorized; authorization is a human cost/independence consent (SEC-004) and is NOT self-granted for a validation checkbox. |
| cursor-agent | yes (`cursor-agent.cmd`) | no (`allowed=false`, no ref) | **NO — recorded unavailable-for-review** | Same as copilot. |
| antigravity | **no** | no | **NO — not installed** | Honestly unavailable. |

## claude-side evidence (SC-022: the Stop-hook fire on the code-writer host)

- The deployed hook chain (dispatcher → handover → conformance → co-review navigator) fired on every
  Stop of this session; the conformance journal recorded the 2026-07-08 material stop-block and the
  subsequent compliant packet stop (see `iterations/010/quality/flush-race-forensic.md` for the full
  record table — the same corpus).
- The navigator's fire-side is Stop-gated by design: this implement arc ran as one long turn, so the
  turn-end Stop after this validation fires the detached checkpoint review of the committed increment
  (dedup state shows the last auto-fire at the previous session boundary, 2026-07-02T07:20:17Z —
  consistent, not a defect: no Stop events occurred mid-turn).

## codex-side evidence (SC-012: the independent reviewer executes end-to-end)

- Door: `specrew review --live --code-writer-host claude --timeout-seconds 540` (the inline service
  path — the same orchestrator the detached navigator fire drives).
- **Run outcome (run `20260708T094626098-104b9497`, 2026-07-08, elapsed 150.33s of a 540s budget)**:

  1. **The T108 retry fired on its FIRST production exercise**: codex returned the exact
     D-197-I009-015 failure (exit 0, EMPTY stdout); the new retry-once recovered the run and the
     diagnostic classified it `finalization-or-capture-gap` (codex had worked; its final blob was
     lost on the first attempt). The fix earned its keep ~30 minutes after shipping.
  2. **Status `done`, 2 findings, both `blocking`/`kind=escalation`**: codex ran the round-aware
     protocol (round 2 of 2, prior findings threaded from round-state per FR-009's fresh-context +
     injected-prior-findings model), verified the prior round's findings were NOT fixed, and
     **honored the ceiling by escalating to the human** instead of looping — the exact iter-009
     Option-A behavior. The findings are substantive (see below), name files+lines+design
     references, and demand a human repair decision before signoff.
  3. **The sticky round-state** now carries `round=2, blocking=true` + the verdict — the loop-state
     machinery (T106-latched at future stops) behaving as designed.

- **The navigator AUTO-FIRE also validated**: the turn-end Stop after the ten implement commits fired
  the detached path (run `20260708T094838294-b6a1683a` via the Stop-hook provider chain) — the
  SC-022 host-hook → detached-supervisor → codex pipeline exercised end-to-end without any manual
  door.

### The two blocking findings (real machinery defects, escalated to the maintainer)

- **f1 — blind-context review is silent**: this repo's `.specify/feature.json` is MISSING (verified),
  so `Resolve-ContinuousCoReviewWorktreeDesignContext` fail-softs to `@()` and the run proceeds with
  an EMPTY `.review/design` (no spec, no design-analysis, no contracts) and a blank Active feature in
  the process context — the reviewer reviews blind of design intent with no degradation recorded.
- **f2 — harvest schema laxity**: `Get-ContinuousCoReviewHarvestedPartialResult` embeds any JSONL
  object carrying only a `comment` property into the FindingsResult, though the formal schema
  requires finding_id/source_run_id/location/severity/kind/design_reference/disposition/resolution.

Both were carried from the prior round (2026-07-01/02 era) and re-verified unresolved — the
round-threading itself is further SC-012 evidence.

## Honest ceilings

- copilot / cursor-agent / antigravity were **not** exercised (unauthorized / not installed) — SC-022's
  five-harness breadth is validated to the degree this machine + the maintainer's authorizations allow,
  exactly as the N8 scope rule prescribes.
- The claude-side reviewer role (claude reviewing codex-written code) is not exercisable in this
  session (claude is the code-writer; using it as its own reviewer would be the same-host degraded
  path by construction).
