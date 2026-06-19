# Drift Log - Feature 185

## D-001: PreToolUse gate empirically rejected - split-guard fired (2026-06-19)

**Decision point (plan boundary).** `plan.md` proposed activating the dormant gate seat via a Claude `PreToolUse` provider (FR-007), flagged as needing (1) empirical verification of the load-bearing product-domain assumption and (2) a maintainer nod, because it reverses F-184's deliberate decision to leave `PreToolUse` unregistered (~920 ms). The maintainer authorized activation ("solve it once and for all"); the empirical check ran first.

**Empirical measurement (per Write/Edit).** Cold pwsh spawn ~445 ms; lean gate (spawn + read state + parse) ~660 ms; loading `shared-governance.ps1` (179 KB) ~590 ms. The real per-Write cost is the **dispatcher spawn+load (fires on EVERY `PreToolUse`) + the gate-provider spawn = ~600 ms-1.2 s per Write/Edit.** This confirms the F-184 concern.

**The deeper finding.** `PreToolUse` hooks are **Claude-only**. But #2884's bug is **Antigravity** (a weak model) self-advancing. Antigravity has no `PreToolUse` surface, so the expensive Claude gate **does not touch the host that actually broke** - it would tax Claude (which respects the gates anyway; the F-184 finding is that strong models follow the gates and weak ones do not) to enforce where enforcement was not the problem.

**Conclusion.** The split-guard FIRES: the `PreToolUse` pre-block is both expensive and aimed at the wrong host. Do NOT silently proceed with FR-007 as planned. Surfaced to the maintainer for a design verdict (FR-007 approach change).

**Recommended pivot.** A cheap, cross-host **Stop-hook detection**: the Stop hook already runs every turn and captures verdicts (`HandoverStore.ps1`). Extend it to detect an unauthorized next-phase advance (a phase-N governance artifact written/committed without the phase-N verdict) and halt (the boundary stays un-authorized; the resume tells the next turn to revert and get the verdict). It works on Antigravity (which has a Stop hook), fires once per turn (no per-Write tax), and catches the actual bug. The Iteration-1 cleaning floor is committed regardless, so #2884 is already substantially better.

**Awaiting maintainer verdict:** (a) Stop-hook detection pivot [recommended] / (b) Claude `PreToolUse` anyway / (c) both (full capability matrix: PreToolUse on Claude + Stop-hook detection on hookless hosts).
