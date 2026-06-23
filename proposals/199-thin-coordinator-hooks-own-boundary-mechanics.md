---
proposal: 199
title: Thin Coordinator — Hooks Own the Boundary Mechanics (clean cooperative/deterministic split for weak-host portability)
status: candidate
phase: phase-2
priority-tier: 1
discussion: surfaced 2026-06-22 from the F-185 Antigravity dogfood. Gemini Flash (both Low and High) thrashed at every boundary — manually re-running `sync-boundary-state.ps1`, inventing a `-HandoffText` argument to "push" the verdict in, running `Test-SpecrewBoundaryAuthorization` by hand, reading the gate scripts, and listing installed module versions — i.e. trying to UNDERSTAND and OPERATE Specrew instead of rendering the packet and stopping. Root-caused to a leaky abstraction (the cooperative coordinator is instructed to operate the deterministic machinery) compounded by async, hook-driven verdict capture that is invisible to the agent. This is architectural — not fixable by a stronger model alone (F-184) or by porting the scripts to a compiled language.
---

# Thin Coordinator — Hooks Own the Boundary Mechanics

## Why

Specrew's design has a clean idea at its center: **cooperative agent drives, deterministic hooks enforce, human authorizes.** But the boundary mechanics violate that line. Today the coordinator agent is told to *operate the deterministic machinery itself*: after doing the phase work it must `git commit`, then **run `sync-boundary-state.ps1`**, sometimes scaffold scripts and `validate-governance.ps1`, then render the packet and stop. Verdict capture, meanwhile, is **asynchronous and hook-driven**: the human's "approved for X" arrives on the *next* turn, and *that* turn's Stop hook reads the transcript marker + reply and records the authorization. The agent that ran `sync` this turn can never see the gate advance this turn.

That combination — *"you operate the plumbing, but the part that actually advances the gate is invisible to you and happens later"* — is a trap. A strong host (Claude, Codex) holds the rule "render packet + marker, stop, the hook captures on my next turn" and doesn't poke at the internals. A weak host cannot, and the leaky contract hands it the rope.

**Empirical record (F-185 dogfood, 2026-06):**

- Antigravity / Gemini Flash, at `tasks` and `before-implement`: the human approved repeatedly; the gate did not advance; the agent fell into a debugging spiral — manual `sync-boundary-state.ps1` reruns with different commit hashes, an invented `-HandoffText "approved for …"` argument, manual `Test-SpecrewBoundaryAuthorization`, reading `sync-boundary-state.ps1` source, conflating the `handoff-block` validator check with verdict authorization, and inspecting installed `Specrew` module versions. None of this is the coordinator's job; all of it is the agent reverse-engineering machinery it was told to run.
- The same root explains why the verdict-capture work needed iteration after iteration (last-marker-wins, markerless packets, the multi-feature mis-scope, the over-advance): each is a symptom of the agent operating the gate plumbing under partial, async feedback.

The honest framing: every one of these failed **safe** (the gate refused to advance without a captured human verdict — never a false advance). The problem is **liveness and host-portability**, not safety. But "a coordinator must understand and operate Specrew's scripts" is exactly the property that makes weak-host support impossible, and it is the property this proposal removes.

## What — the Thin-Coordinator invariant

**The cooperative agent never touches the deterministic machinery.** At a boundary, the coordinator's *entire* responsibility is:

> do the phase work → commit it → render the six-section re-entry packet + the verdict marker → **STOP.**

Everything mechanical — `sync-boundary-state`, the pending-verdict artifact, verdict capture, cursor advance, iteration scaffold, gate preflight/validation — runs **inside the hooks, autonomously**, and is surfaced back to the agent only as *read-only state* via the SessionStart / PreInvocation refocus injection. The agent does not know `sync-boundary-state.ps1` exists, and is never instructed to run a lifecycle script.

Four design elements:

1. **Strip script-operation from the coordinator contract.** Remove every "run `sync-boundary-state.ps1` / `scaffold-*` / `validate-governance.ps1`" instruction from the bootstrap, refocus, and skills. Replace with: "commit your boundary artifacts; render the packet + marker; stop. Specrew advances the gate for you once the human approves."

2. **The Stop hook becomes the sole mechanic.** After the agent renders the packet and the human replies on the next turn, the Stop hook: (a) captures the verdict (marker + reply, with the F-185 markerless fallback for weak renders), (b) if it is a clear approval for the pending crossing, runs `sync` + cursor advance + any scaffold autonomously, (c) writes the boundary commit or stages it per project discipline. The agent's *next* turn already starts advanced.

3. **State reaches the agent only as computed read-only context.** The agent learns "where am I / what's pending" exclusively from the deterministic refocus injection (already computed from artifacts) — never by running a script and interpreting its output. There is no "stuck sync" for it to debug, because it never issued one.

4. **Preflight moves left, into the hook.** The two-tier gate preflight (validator, parity, dirty-state, stale-phrase, packet-consistency) runs inside the hook before it advances, and surfaces failures as an injected directive ("send-back: fix X"), not as an exit code the agent must read from a script it ran.

## The cooperative/deterministic line — before and after

```
  BEFORE (leaky — the line is crossed)
  ─────────────────────────────────────────────
  AGENT (cooperative):  do work ─▶ commit ─▶ RUN sync-boundary-state.ps1
                                              RUN scaffold/validate
                                              render packet (+ maybe marker)
                                              ... gate didn't advance? RUN it again,
                                                  read the script, run the gate fn,
                                                  invent -HandoffText, check versions
  HOOK (deterministic): captures verdict next turn (invisible to the agent)

  AFTER (clean — the agent never crosses the line)
  ─────────────────────────────────────────────
  AGENT (cooperative):  do work ─▶ commit ─▶ render packet + marker ─▶ STOP.   (that's all)
  HOOK (deterministic): on the human's reply → capture verdict, sync, advance,
                        scaffold, preflight — autonomously. Surfaces state back
                        as read-only refocus context the agent only READS.
```

The agent's surface area shrinks to *prose it must author*. The machinery it cannot author becomes something it cannot touch.

## Architecture (deliverable shape)

- **Contract edits:** remove agent-issued lifecycle-script instructions from `refocus/*.md`, the launch contract, the bootstrap, and the gate-stop / workshop skills. The only imperative the agent retains is "commit your artifacts; render; stop."
- **Hook-internal boundary engine:** the Stop-provider chain gains an *advance* responsibility alongside the existing F-185 *detect/block* and *capture* responsibilities — on a captured forward approval it performs sync + advance + scaffold + preflight in-process (or via a single internal command the hook invokes, never the agent).
- **Read-only state contract:** define exactly what the refocus injection must surface so the agent can render an accurate packet without running anything (current/pending boundary, the approval phrase + marker from the pending-verdict artifact, dirty-state summary, last preflight result).
- **Host capability matrix:** classify hosts by hook surface — (a) full (fires Stop with a readable transcript and can run the mechanic) → thin-coordinator works end-to-end; (b) partial → degrade to a sanctioned explicit path; (c) too weak to render a compliant packet/marker at all → **not coordinator-eligible** (the F-184 line, made explicit). The point of this proposal is to *widen* tier (a), not to pretend tier (c) away.

## Composition map

- **F-185 host-neutral gate enforcement (conformance provider)** — this proposal is its natural completion: F-185 made the hooks *detect and block* a missing/markerless packet; this makes the hooks *do the mechanics* too, so the agent has no reason to run them.
- `[[proposal-180-pretooluse-lifecycle-entry-gate]]` — composes directly: 180 makes a deterministic hook (PreToolUse) the gate authority; this proposal extends that posture from "the hook blocks unauthorized entry" to "the hook also *performs* the capture/sync/advance, so the agent never operates the gate plumbing at all." Capture/advance stays hook-only and never agent- or sync-self-authored.
- **F-174 hook-driven session bootstrap** — same philosophy already applied to SessionStart; this carries it to the boundary lifecycle.
- `[[proposal-024-multi-host-runtime-abstraction]]` / `[[proposal-069-multi-host-launch-path]]` — thin-coordinator is the precondition that makes weak/diverse hosts viable runtimes rather than aspirational ones.
- `[[proposal-130-specrew-switch-to-host-handover]]`, `[[proposal-105-host-native-hook-deployment]]` — share the "hooks own host-side mechanics" direction.
- `[[proposal-145-structured-multi-phase-reviewer]]` — the review-signoff preflight likewise moves into the hook-driven gate flow rather than being an agent-run script.
- **Performance complement (not a substitute):** porting the now hook-internal mechanics to a faster runtime (e.g. a compiled `specrew` core) addresses the D-019/D-021 Stop-hook timeout class and makes the deterministic layer harder to knock over on a weak host. It is orthogonal — do the architecture first; speed second. Language does not fix the leaky abstraction.

## Sizing + sequencing

Multi-iteration; prerequisite is the F-185 conformance + markerless-capture work landing.

- **Iter 1 (~8-13 SP):** remove agent-issued `sync-boundary-state` from the contract; move sync + cursor advance into the Stop hook's captured-approval path; define and surface the read-only state contract. Prove on Claude + Codex that a boundary advances with the agent issuing *zero* lifecycle commands.
- **Iter 2 (~8-13 SP):** move iteration scaffold + gate preflight into the hook; surface preflight failures as injected send-back directives.
- **Iter 3 (~8-13 SP):** the host capability matrix + the partial-host explicit fallback; real-host validation on Antigravity/weak hosts (the runtime test, per the "test the deliverable, not file-presence" rule).

## Risks + honest ceiling

- **Hook-poor hosts.** A host that cannot run a mechanic autonomously from a hook cannot get the full benefit; it needs the explicit fallback or is tier (c). This proposal *reveals* that boundary honestly rather than hiding it.
- **Hook runtime grows.** Folding scaffold/validate into the hook risks the 30s-class timeouts already seen (D-019/D-021). Mitigate with the performance complement above and by keeping the heavy preflight asynchronous where possible.
- **Render-compliance is NOT eliminated.** The agent still must author the packet + marker. Thin-coordinator removes the *machinery-operation* failure mode; it does not remove the *render* failure mode (weak hosts dropping the marker), which the F-185 markerless fallback handles separately. Be explicit that this narrows the problem, it does not close it.
- **Migration.** Existing flows and any muscle-memory that has the agent run `sync` must be migrated; a transition period where both paths work risks the agent doing both. Prefer a hard cutover per host once iter-1 proves out.
- **The F-184 line stays.** Some hosts/models are simply too weak to coordinate a governed lifecycle even as a thin driver. This proposal widens the set of viable hosts; it does not make every host viable.

## Open questions (for proposal-to-spec conversion)

- What is the exact read-only state contract the refocus injection must carry so the agent can render an accurate packet with zero script runs?
- For partial-hook hosts, what is the *sanctioned* explicit path that still never lets the agent self-author the verdict?
- Does moving preflight into the hook breach host hook-timeout budgets, and does that force the performance complement to be a hard dependency rather than an optional follow-on?
- How is the cutover staged per host without a window where the agent both runs `sync` and the hook also advances (double-advance / contention)?
- Should the "agent issues zero lifecycle commands" invariant be *validator-enforced* (flag any agent-run `sync-boundary-state` in the transcript as drift), so the leak cannot quietly return?
