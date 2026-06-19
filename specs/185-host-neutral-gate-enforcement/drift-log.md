# Drift Log - Feature 185

## D-001: PreToolUse gate empirically rejected - split-guard fired (2026-06-19)

**Decision point (plan boundary).** `plan.md` proposed activating the dormant gate seat via a Claude `PreToolUse` provider (FR-007), flagged as needing (1) empirical verification of the load-bearing product-domain assumption and (2) a maintainer nod, because it reverses F-184's deliberate decision to leave `PreToolUse` unregistered (~920 ms). The maintainer authorized activation ("solve it once and for all"); the empirical check ran first.

**Empirical measurement (per Write/Edit).** Cold pwsh spawn ~445 ms; lean gate (spawn + read state + parse) ~660 ms; loading `shared-governance.ps1` (179 KB) ~590 ms. The real per-Write cost is the **dispatcher spawn+load (fires on EVERY `PreToolUse`) + the gate-provider spawn = ~600 ms-1.2 s per Write/Edit.** This confirms the F-184 concern.

**The deeper finding.** `PreToolUse` hooks are **Claude-only**. But #2884's bug is **Antigravity** (a weak model) self-advancing. Antigravity has no `PreToolUse` surface, so the expensive Claude gate **does not touch the host that actually broke** - it would tax Claude (which respects the gates anyway; the F-184 finding is that strong models follow the gates and weak ones do not) to enforce where enforcement was not the problem.

**Conclusion.** The split-guard FIRES: the `PreToolUse` pre-block is both expensive and aimed at the wrong host. Do NOT silently proceed with FR-007 as planned. Surfaced to the maintainer for a design verdict (FR-007 approach change).

**Recommended pivot.** A cheap, cross-host **Stop-hook detection**: the Stop hook already runs every turn and captures verdicts (`HandoverStore.ps1`). Extend it to detect an unauthorized next-phase advance (a phase-N governance artifact written/committed without the phase-N verdict) and halt (the boundary stays un-authorized; the resume tells the next turn to revert and get the verdict). It works on Antigravity (which has a Stop hook), fires once per turn (no per-Write tax), and catches the actual bug. The Iteration-1 cleaning floor is committed regardless, so #2884 is already substantially better.

**RESOLVED (2026-06-19):** the maintainer chose the detection pivot (a), which then generalized into the unified design — see D-002. The Claude `PreToolUse` pre-block is dropped (it taxes the host that already behaves).

## D-002: Re-scoped to unified "reliably follow Specrew"; CLI wrapper considered + dropped (2026-06-19)

**Decision (maintainer, in design conversation).** Dogfooding surfaced THREE failure modes, not just gate-skip: (1) on an existing project the host asks "what to build" instead of continuing (resume-orientation); (2) gate-skip (#2884); (3) the host runs raw Spec Kit instead of the Specrew workshop. Re-scoped 185 from "host-neutral gate enforcement" to **"make the host reliably follow Specrew"** (all three), via **prevention** (SessionStart orientation + a markdown patch of the deployed Spec Kit `specify` slash-command) + **detection** (a generalized Stop-hook conformance check catching all three). This generalizes D-001's detection pivot. See the spec Scope Amendment + FR-009..FR-012.

**CLI wrapper considered + dropped.** A `specify.exe` shim intercepting `specify workflow` was validated (`specify.exe` IS Spec Kit's uv-tool Python binary, with a `workflow` engine — the bundled SDD runner). But the maintainer confirmed `specrew start` is rarely used — harnesses launch directly — so the wrapper cannot ride launch-env PATH control; it would need invasive install-time PATH placement (global PATH mod / shadowing `~/.local/bin/specify.exe`) for marginal value over the detection (which catches the same `specify workflow` invocation post-hoc). DROPPED (FR-012). The other three levers ride the init-deployed hooks/files → work at direct launch with zero invasiveness and no new dependency.

**Empirical plan.** Implement the levers, then direct-launch dogfood to see if the three problems recur (maintainer: "test and see if we still have problems").
