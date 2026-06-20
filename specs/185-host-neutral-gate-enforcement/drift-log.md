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

## D-003: 145-review residuals + the better-solution direction (Stop-hook authority) (2026-06-20)

A Proposal-145 adversarial review of the session's FR-010/013/014 + workshop-gate work (through `996af4f9`) surfaced residuals worth recording so the "done" labels stay honest. Two review blockers were FIXED in `996af4f9` (B3: the `scripts/internal/` provider twin lacked the FR-014 thread-through — both copies ship; B1: two test comments overclaimed "verified end-to-end"). The residuals KEPT:

- **C5 - #2884's headline is NOT closed.** #2884 is the clarify->plan silent self-advance (#2). FR-009 (resume orientation) + FR-011 (per-turn gate-skip detector) remain UNIMPLEMENTED. The session fixed the cross-host command surface, workshop routing, the workshop gate, and host identity - all real, all dogfooded - but the deterministic catch for a gate-skip is still pending.
- **C3 - the workshop gate is COOPERATIVE.** `Test-SpecrewWorkshopRecordsPresent` fires only inside `sync-specify`, which the model must run; a model that hand-writes `spec.md` and never syncs bypasses it - the same "fires only inside the sync-wrappers after the artifact is written" weakness that is half of #2884's root.
- **C4 - fail-CLOSED blast radius.** A transient/missing `feature.json` -> `Present=$false` -> `sync-specify` throws -> all specify advances block. Recoverable; warrants a guarded carve-out (absent-feature vs workshop-incomplete).
- **C1 - FR-010 mechanism drift.** The spec names a "markdown-patch of the specify command"; a native `before_specify` HOOK shipped instead - a BETTER mechanism (survives Spec Kit re-deploy via the extension manifest, not a patched file). Intent met; FR-010 wording is stale and should be updated.

**The better solution (NOT done - the ceiling-raiser):** move the HARD enforcement from the cooperative layer (`sync-specify`) to the **Stop-hook / boundary-authorization authority** - the pivot D-001 already recommended. The Stop hook (`HandoverStore.ps1`) fires EVERY turn on every transcript host and records an advance ONLY on a captured verdict. Two moves close C3 + C5: (a) **FR-011 detection** - detect an unauthorized next-phase advance (phase-N artifact without the phase-N verdict) -> halt; the boundary STATE stays un-authorized (mechanically protected) regardless of model cooperation; (b) **workshop-records requirement in the authorization recording** - so even skipping `sync-specify` cannot advance the boundary without the lens records.

**Honest ceiling.** The Stop hook is transcript-gated (no-transcript hosts residual) and post-hoc (it protects the STATE, does not pre-block the action). Much more deterministic than the cooperative gate, not 100% universal; the universal pre-block (PreToolUse) was rejected in D-001 (Claude-only, expensive, wrong host). The Stop-hook authority is the best cross-host deterministic lever available.

**Next.** FR-011 (the Stop-hook conformance detection) is the deferred critical-path piece that raises the ceiling - it addresses the #2884 headline (C5) + the cooperative residual (C3); it touches the verdict authority, so it needs careful fresh-context work.
