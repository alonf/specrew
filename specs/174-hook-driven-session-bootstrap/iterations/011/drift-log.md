# Drift Log: Iteration 011

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)

Divergences between spec / plan / tasks and the implementation, each with the requirement citation and the
reconciliation path (lifecycle-discipline rule 4: drift is logged, not absorbed).

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
