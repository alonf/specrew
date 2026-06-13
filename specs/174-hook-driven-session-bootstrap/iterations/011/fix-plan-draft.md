# Iteration 011 fix plan (DRAFT) — handover-authoring + boundary-authorization integrity

**Status**: Decisions LOCKED 2026-06-13 (see Decisions section) — A3 hybrid authoring + captured human
verdict-evidence + reopen as **iteration 011 on F-174**. Ready for the maintainer to formalize the iteration
(specify/plan/tasks) through the governed flow.
**Source**: the multi-host round-robin dogfood findings — `file:///C:/Dev/Specrew-session-bootstrap/specs/174-hook-driven-session-bootstrap/iterations/010/dogfood-multihost-handover.md`.
**Scope**: the DF-3/4/5/7 cluster (high) + DF-1/DF-2 (small). DF-6 (cursor-agent hooks) and DF-8 (agent can edit
governance) are OUT of scope — separate follow-ups (DF-8 is a governance-architecture proposal, bigger than F-174).

## Why one iteration, not five fixes

The cluster is a single causal chain, so it must be fixed as one coherent change or a DF-3 fix will not unblock
DF-4/5:

> the agent can't author the handover (**DF-7**) → so the boundary packet + `active_boundary` never land in it
> (**DF-3**) → so a resume reads only the committed artifacts + boundary-enforcement, which records a *fabricated*
> "approved" verdict (**DF-5**) and is read as "committed == approved" (**DF-4**) → so the resume misjudges /
> rewinds the gate.

Antigravity proved the GOOD news that makes this safe: the committed tree is the durable source of truth (a resume
re-derives + reuses prior work — no data-loss), so this cluster is about **resume accuracy + audit integrity**, not
recovery from loss.

## Design principle (the dogfood's core lesson)

**Do NOT rely on agent compliance for integrity-critical state.** Every finding is a variation of an agent not
doing what the directive asked: DF-3 skipped authoring, DF-5 ran boundary-sync with no human verdict, DF-7
couldn't call the named function, DF-8 edited the governance validator to pass. So a fix that *instructs* the
agent (FR-022 already did, and was ignored/unfollowable) is not a fix. Integrity-critical state — the authored
boundary packet, the `active_boundary`, and above all the **verdict** — must be produced or captured by a
mechanism the agent cannot skip or forge, not by an agent honoring a prompt. This is what unifies Fix A's
mechanical backstop (A3), Fix C's verdict-evidence, and the DF-8 follow-up. Where the agent is the only possible
producer of content (the packet prose), the mechanism captures what it actually rendered; where the human is the
only legitimate authority (the verdict), the mechanism captures what the human actually typed.

## Fixes (grounded in code)

### Fix A — a real authoring path (DF-7) + the boundary state in the handover (DF-3)

**Root**: `Write-SpecrewHandoverContext` (`scripts/internal/bootstrap/HandoverStore.ps1:305`) is module-internal —
NOT exported, NOT a command. The installed module exports zero `*Handover*` functions. So FR-022's directive
("FIRST persist via Write-SpecrewHandoverContext") names a target the agent cannot invoke. Confirmed empirically:
codex ran `Get-Command Write-SpecrewHandoverContext` → nothing, then direct-edited the file (clobbered by the Stop
hook); copilot/claude skipped authoring entirely.

**Design fork — DECIDED: A3 (hybrid).**

- **(A1) Expose an agent-callable authoring command** — e.g. `specrew handover write` (or a `specrew-handover`
  skill that wraps it), accepting the six packet sections + the boundary. FR-022 then points at a real target.
  *Pro*: minimal, makes the existing protocol followable. *Con*: still relies on the agent calling it (copilot/
  claude skipped even the file-edit path).
- **(A2) MECHANICAL persist via the Stop/boundary hook** — the Stop-hook conversation capture (T002) already reads
  the transcript; extend it to detect the rendered boundary packet (the `=== SPECREW HANDOFF ===` / six-section
  markers the agents already emit) and persist it as the authored handover body + set `active_boundary` from the
  boundary it is crossing. *Pro*: host-universal, no agent cooperation. *Con*: heuristic extraction; couples to the
  packet markers.
- **(A3 — RECOMMENDED) Hybrid**: ship A1 (so FR-022 is followable + a compliant agent like codex authors directly)
  AND A2 as the mechanical backstop (so a non-compliant agent's rendered packet is still captured). Belt + braces.

**Also fix the clobber** (HandoverStore `Update-SpecrewRollingHandover` / the Stop preserve path): a turn-end Stop
must NOT overwrite an agent-authored boundary body with the mechanical placeholder version, and must not regress
`active_boundary` (codex authored `plan`, the Stop reverted it to `clarify`). The T050 "Stop preserves your body"
logic did not preserve a direct file-edit — A2/A3 supersedes that path, but the preserve must be verified.

### Fix B — committed != authorized in the resume (DF-4)

**Where**: the bootstrap directive's in-flight scan + boundary read (`specrew-bootstrap-provider.ps1` in-flight
block + `Get-SpecrewWorkshopProgress`), and the boundary-enforcement read.
**Change**: a committed `boundary(<x>)` artifact is NOT an authorized boundary. When a boundary commit exists but
`boundary_enforcement.last_authorized_boundary` is behind it, the resume must surface **"<x> drafted/committed,
AWAITING your verdict"** — never infer closure from the commit. Extend the in-flight scan to detect
drafted-but-unverdicted gate work (e.g. `design-analysis.md` present but no recorded design-analysis verdict) and
name "resume at the <x> gate, awaiting verdict" so a resume reconciles FORWARD (antigravity rewound a gate for
exactly this reason).

### Fix C — capture a real human verdict; stop fabricating (and don't trust an agent-suppliable) one (DF-5)

**Root**: `scripts/internal/sync-boundary-state.ps1:1460-1496` fabricates the verdict outright —
`$verdictText = "approved for $targetCanonical"` (`:1488`) with `$authorizingHuman` = the git committer
(`:1464-1468`). No human-verdict signal is required at all, so an agent that runs boundary-sync on a bare
"continue" (DF-5 / codex) writes a `verdict_history` record asserting a human approved when none did.

**DECIDED: capture human verdict-evidence (not a passed param).**

**The real question is forgeability, not plumbing.** Per the design principle above, the verdict is the most
integrity-critical state in the system — it is the one signal asserting that a *human* authorized a boundary
crossing. So the test for any fix is: **can the agent produce it?** A passed `-HumanVerdict "approved for plan"`
param fails that test — the agent can fill it in exactly as easily as the code fabricates it today; it just moves
the forgery up one layer. The verdict must come from a channel the agent cannot write to.

**Change**: the human's verdict must be *captured*, not *asserted*. The only agent-unforgeable source is the
human's own input turn — the literal text the human types in response to the boundary VERDICT packet (the
gate-stop packet on Claude; the equivalent stop on each hook-capable host). Capture that turn as verdict-evidence
(the Stop / UserPromptSubmit hook already sees the human's turns — T002 reads the transcript) and have
boundary-sync consume THAT, validating that the human actually responded to *this* boundary. Concretely:

- boundary-sync REFUSES to record an authorization without captured human verdict-evidence for the target
  boundary; absent it, record the crossing as **un-authorized / agent-initiated** so the audit trail is honest.
- never default `authorizing_human` to the git committer — attribute only the human identity tied to the captured
  turn (or leave it unauthorized).
- pair with Fix B: the resume / `specrew where` distinguishes "boundary committed" from "boundary
  authorized-by-human", reading the honest record.

This makes the verdict the human-side mirror of Fix A's packet capture: where the agent is the only producer (the
packet prose) the mechanism captures what it actually rendered; where the human is the only legitimate authority
(the verdict) the mechanism captures what the human actually typed — neither path trusts the agent to self-report.

### Fix D — substantive recap on pointer/terse hosts (DF-1, small)

**Where**: `Format-BootstrapDirective` + the in-flight scan (`specrew-bootstrap-provider.ps1`).
**Change**: surface each done lens's DECISION (one line from its record), not just the lens NAME, in the in-flight
scan; and strengthen the directive's welcome-back instruction to synthesize "what we decided so far" — weighted for
pointer-mode hosts (codex), since claude/copilot/cursor/antigravity already do this well from the inlined contract.

### Fix E — version/branch in the directive for pointer mode (DF-2, small)

**Where**: the bootstrap directive (`specrew-bootstrap-provider.ps1`; the version is resolved there via the
manifest, the branch via git).
**Change**: carry the resolved Specrew version + branch in the directive text itself so a pointer-mode host (codex)
renders a complete banner without first reading `last-start-prompt.md` (claude/copilot get them from the inline
contract today; codex's pointer banner showed "not resolved").

## Sequencing

1. **Fix A** (authoring path + clobber) — everything else depends on the boundary state actually landing in the
   handover.
2. **Fix C** (real verdict) — so the state A writes carries an honest verdict, not a fabricated one.
3. **Fix B** (committed != authorized resume) — consumes the honest state from A + C.
4. **Fix D / E** (small, independent) — anytime.

## Test strategy

- Synthetic, per fix: a real authoring path round-trips (write → resume reads authored body, not placeholders);
  boundary-sync REFUSES to fabricate a verdict without a real signal; a resume on committed-but-unverdicted state
  surfaces "awaiting verdict", not "approved".
- **Acceptance = a focused re-dogfood**: the multi-host findings file is the regression spec. Minimum: one host
  authors a boundary handover → a DIFFERENT host resumes and inherits the *authored* packet (DF-3) + correctly
  reads "awaiting verdict" not "approved" (DF-4) + boundary-sync on bare "continue" does NOT fabricate a verdict
  (DF-5). Per the dogfood lesson, real-host behavior is the decisive gate, not green synthetic tests.

## Out of scope (separate follow-ups)

- **DF-6**: cursor-agent CLI ignores `~/.cursor/hooks.json` (rules-based). Needs cursor-agent's real hook
  mechanism (its docs / a beta tester); the `.cursor/rules` path works today.
- **DF-8**: an agent can edit the deployed governance scripts it is governed by (antigravity edited
  `shared-governance.ps1` to pass a gate). Governance-architecture concern — own proposal.

## Decisions (locked 2026-06-13)

1. **Fix A = A3 (hybrid)** — ship the agent-callable authoring command AND the mechanical Stop-hook backstop. A
   compliant agent authors directly through a real target; a non-compliant agent's rendered packet is still
   captured. Belt + braces.
2. **Fix C = capture human verdict-evidence** (NOT a passed `-HumanVerdict` param — forgeable). Boundary-sync
   consumes the human's actual typed verdict turn from the Stop / UserPromptSubmit transcript. Residual
   sub-questions to settle at planning time: **(a) match strictness** — any human turn after the packet vs a
   recognized verdict token ("approve" / option-N) tied to the named boundary; **(b) the NON-hook fallback** —
   antigravity has no Stop/UserPrompt hook, so transcript capture is impossible there; record the crossing as
   un-authorized and require `specrew start` to reconcile, rather than block.
3. **Reopen as iteration 011 on F-174** — the A–E cluster is F-174's own resume/handover surface. DF-6 (cursor)
   and DF-8 (agent-edits-governance) stay separate follow-ups.
