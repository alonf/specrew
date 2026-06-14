# Drift Log: Iteration 011

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)

Divergences between spec / plan / tasks and the implementation, each with the requirement citation and the
reconciliation path (lifecycle-discipline rule 4: drift is logged, not absorbed).

## D-006 — T012 Layer-3 agent-guidance surface consolidated (plan named 3 surfaces; spec/build ship 1)

- **Status**: resolved (consolidation matches the spec's FR-028 Layer-3 Honest-residual; recorded for plan-vs-build traceability — review-signoff P4-2)
- **Requirement**: FR-028 Layer 3 (always-loaded degradation diagnostic). Plan T012's task text named THREE
  surfaces — "copilot-instructions + refocus core + `specrew-hooks` skill" — and its owner-file-glob included
  `extensions/specrew-speckit/refocus/general.md`.
- **Divergence**: as built, the Layer-3 agent guidance lives ONLY on the managed Squad `copilot-instructions.md`
  template, plus the `specrew hooks status` command surface. `general.md` was NOT modified (and the L3 attempt was
  reverted — see D-003), and there is NO `specrew-hooks` SKILL.md anywhere (only `scripts/specrew-hooks.ps1` + its
  test). The refocus core was left untouched because it is ≤600-token budget-locked (the refocus-digests cap).
- **Why this is correct (not under-delivery)**: it matches the SPEC's FR-028 Layer-3 "Honest residual" exactly —
  the copilot template is the one Specrew-deployed always-loaded surface; claude/codex/cursor have no Specrew
  always-loaded file, so the honest mitigation there is `specrew hooks status` (Layer 1 prevents the gap in the
  first place). SC-018's deterministic helper (`Get-SpecrewHookDegradationWarning` + `Test-SpecrewBootstrapDirectiveArrived`)
  is fully met and tested; the residual is documented, not asserted. state.md's as-built T012 line is honest.
- **Reconciliation path**: none required — the build matches the spec; this entry records the plan-text-vs-build
  consolidation so a plan-vs-implementation audit does not read T012 as under-delivered. Recorded 2026-06-14.

## D-005 — T001 shipped as a COMMAND, not a module-function export (deliberate design divergence)

- **Status**: resolved (accepted design choice; recorded for traceability)
- **Requirement**: FR-022 (capture ≠ author; the agent must have a reachable way to persist the handover body —
  DF-7: `Write-SpecrewHandoverContext` is named by the bootstrap directive but is NOT a module export, so it is
  unreachable except by dot-sourcing an internal file).
- **Divergence**: plan T001's parenthetical said "exporting + testing it is part of this task," which reads as
  "add `Write-SpecrewHandoverContext` to `Specrew.psd1` FunctionsToExport." The implementation instead ships a
  thin `specrew handover author` DISPATCHER COMMAND (`scripts/specrew-handover.ps1`, registered in
  `scripts/specrew.ps1`) that dot-sources `HandoverStore.ps1` and wraps the writer. The function is NOT exported.
- **Why the command, not the export** (advisor-confirmed): agents and hosts invoke Specrew as `specrew <cmd>`,
  never `Import-Module Specrew; Write-SpecrewHandoverContext ...` — so the genuinely *agent-callable* surface the
  task demands is a command, and the FR-022 directive can now name a token the agent can actually run. A module
  export would still be unreachable from the agent's real invocation path. The task title itself says
  "command/skill," anticipating this. The command reuses `ConvertFrom-SpecrewHandoverFile` (the same reader a
  resume uses) to parse `## ` sections — no bespoke multi-line CLI parser — and writes through the SAME atomic
  writer + centralized clobber guard as the Stop hook, so the authored body and a hook-captured packet coexist
  (proven by HandoverAuthorCommand.Tests case 5 / SC-015).
- **Residual**: `Write-SpecrewHandoverContext` stays internal (reached by dot-source from the command + by the
  existing tests that dot-source `HandoverStore.ps1`). No export was added; none is needed. The FR-022 directive
  text (all 3 mirror copies of `specrew-bootstrap-provider.ps1`) was updated to name `specrew handover author`
  instead of the bare function, keeping the "interpretive sections are agent-authored / Claude-only marker
  capture" nuance (the latter ties to D-001). Recorded 2026-06-14.

## D-004 — governance-validator capacity mismatch on the DELIBERATELY-OPEN iter-007 (accepted cap-raise drift)

- **Status**: open (pre-existing accepted drift; resolved by the `f174-i011-cap-revert-obligation` at closeout)
- **Requirement**: the capacity-consistency validator (`validate-governance.ps1`: plan "Capacity per Iteration" +
  "Capacity total" must match `.specrew/iteration-config.yml capacity_per_iteration`); adjacent to FR-028 only
  because T010-T012 raised the cap.
- **Divergence**: the validator FAILs `specs/174.../iterations/007` — "plan capacity '20' does not match
  iteration-config '32'". F-174 iter-007 is DELIBERATELY left OPEN ("Iteration Status: executing ... review-signoff
  DEMONSTRATED-not-ratified ... Left OPEN as a recorded historical gap", superseded by iter-008), so it is NOT in
  the grandfather `closed-iterations.yml` (iter-010 IS, which is why it passes) and is therefore validated against
  the CURRENT global cap. Since iter-007 records cap 20 and the only OTHER open F-174 iteration (011) needs a
  different cap, NO single global value satisfies both — the mismatch has existed since iter-011's APPROVED 20→22
  bump (`f174-i011-plan-tasks-approved`); the FR-028 32-bump only changes the number, not the failing set (still
  exactly iter-007). The iter-011 validator FAIL was a SEPARATE, now-FIXED defect (the T011 plan-table title
  contained literal `|` pipes that the validator's table parser split on — escaping with `\|` does not help —
  shifting the Owner into the Status column; rewritten without pipes).
- **Why parked**: iter-007 is intentionally open (a recorded historical gap — must NOT be force-closed or have its
  historical cap rewritten); reverting the cap now would break the active iter-011 (which needs 32). The planned
  reconciliation is the `f174-i011-cap-revert-obligation` (restore global 20 at closeout, once iter-011 is itself
  grandfathered), which restores iter-007's match. Out of FR-028 scope to resolve mid-iteration.
- **Reconciliation path**: at iter-011 closeout, revert `capacity_per_iteration` 32→20 + rerun the validator
  (the obligation already on file); iter-007 then matches again. Recorded 2026-06-14.

## D-003 — PRE-EXISTING refocus-digests red (specify.md host-scoped gate-stop line) — branch/main drift

- **Status**: open (pre-existing; parked — clears on a rebase of branch 174 onto main)
- **Requirement**: refocus digest content parity (`tests/integration/refocus-digests.tests.ps1:75`); unrelated to
  FR-028 (surfaced only because Layer 3 touched `general.md`, then reverted).
- **Divergence**: the test (updated by main-side commit `3d7180de` "fix: scope specify gate stop guidance by
  host") asserts `specify.md` body contains "On Claude, invoke `specrew-gate-stop`; on non-Claude hosts, render
  directly". Branch 174's `extensions/specrew-speckit/refocus/specify.md` predates that main-side digest fix and
  lacks the line, so the assertion fails. None of this iteration's commits touch `specify.md` or this test — it
  was red on branch 174 before the FR-028 work began. (The general.md ≤600-token check PASSES — Layer 3 added no
  digest content; the general.md hook-health rule was reverted precisely because the core is budget-maxed.)
- **Why parked**: it is a main-side digest alignment, not FR-028 scope. The memory note already anticipates F-174
  rebasing onto a newer main (0.36.0); the rebase brings main's `specify.md` fix. Fixing it directly on 174 risks
  a later rebase conflict for no in-scope benefit.
- **Reconciliation path**: rebase branch 174 onto main (planned), OR add the one host-scoped gate-stop line to
  `specify.md` to match `general.md`'s F-165 pattern. Recorded 2026-06-14.

## D-002 — PRE-EXISTING host-coupling-firewall red (SessionBootstrapManager ValidateSet) — NOT from hook-deploy work

- **Status**: open (pre-existing; parked for the maintainer — a Phase-D-vs-allow-list judgment call)
- **Requirement**: the Open-Closed host firewall (`tests/integration/host-coupling-firewall.tests.ps1`); adjacent
  to FR-028 only because T010 touched the hook-deploy host wiring.
- **Divergence**: `scripts/internal/bootstrap/SessionBootstrapManager.ps1:173` declares
  `[ValidateSet('copilot','claude','codex','antigravity','cursor')] $HostKind`, which the firewall test flags as a
  hardcoded host enum outside `hosts/`. It was introduced in iter-10 (commit `61f17bd0`), an ANCESTOR of this
  iteration's work — so the firewall test was ALREADY red before the FR-028 hook-deploy work began. The FR-028
  changes are firewall-CLEAN (verified: `hosts/_registry.ps1`, `refocus-deploy-integration.ps1`,
  `specrew-hook-health.ps1`, `specrew-hooks.ps1`, `specrew.ps1` match none of the firewall patterns); T010 in fact
  REMOVED a hardcoded host list from `refocus-deploy-integration.ps1` in favor of `Get-SpecrewHookCapableHosts`,
  REDUCING firewall debt. (The test additionally crashes on a `.Count` formatting bug when reporting any
  violation — a separate test defect that masks whether further violations exist.)
- **Why parked, not fixed here**: the resolution is a maintainer policy choice — either (a) add
  `SessionBootstrapManager.ps1` to the firewall allow-list alongside the 3 existing "ValidateSet pending Phase D"
  entries (`specrew-start.ps1`, `host-flag-translation.ps1`, `coordinator-prompt-surgery.ps1`), or (b) do the
  Phase-D registry-driven `[ValidateScript]` refactor. Both are out of FR-028's scope; per the overnight-run
  discipline, judgment/redesign calls on pre-existing debt are surfaced, not silently absorbed at run time.
- **Reconciliation path**: maintainer picks (a) or (b); also fix the firewall test's `.Count` crash so it reports
  the full violation set. Recorded 2026-06-14.

## D-001 — verdict-capture marker emission is Claude-only (descoped per-host rollout)

- **Status**: open (tracked residual)
- **Requirement**: FR-026 (verdict-integrity) + the T004 "require a packet boundary marker" decision
  (`f174-i011-verdict-authority-stop-hook`, maintainer-chosen tying strictness).
- **Divergence**: T004's hook verdict-capture ties the human's approval to a boundary ONLY via the packet's
  stable machine marker `<!-- SPECREW-VERDICT-BOUNDARY: <from> -> <to> -->`. The marker EMISSION is implemented
  in the Claude `specrew-gate-stop` skill (the Claude packet renderer). codex / copilot / cursor render the
  boundary packet via their own approved interaction path (refocus rule 9), which does NOT yet emit the marker.
  So on those three hooked hosts the reader returns `no-marker` and the hook does NOT auto-capture.
- **Why this is SAFE (not a regression)**: the capture machinery (recognizer + reader + wiring) is host-neutral
  and the failure mode is the designed one — no marker -> the gate stays un-authorized and the resume / `specrew
  where` surface "AWAITING YOUR VERDICT" (T006), so the human re-confirms. No fabrication, no false approval. The
  cost is liveness (the human re-confirms each boundary on those hosts), not integrity.
- **Reconciliation path**: carry the marker instruction into the HOST-NEUTRAL boundary-packet guidance (the
  launch contract / coordinator framing / the Rule 46 packet spec) so every host emits it, not just the Claude
  skill. Small doc rollout; best informed by the real-host re-dogfood (which validates the Claude path first).
- **Disposition**: deferred within F-174 iteration 011 as a fast-follow; does not block the verdict-integrity
  core (T004/T005/T006 are complete + proven on the Claude packet format). Recorded 2026-06-14.
