# Multi-host round-robin handover dogfood (2026-06-13)

Real-host validation of the F-174 handover/continuity + bootstrap dedupe, on a fresh **downstream** project
(`file:///C:/Temp/SpecrewTrials/ho-roundrobin`), current claim+handover providers deployed to `.specify/`,
`SPECREW_MODULE_PATH` → dev tree, hooks registered for codex/claude/copilot. Feature: a CLI todo app driven
through the design workshop. Round-robin: codex → codex (same-host) → claude (cross-host) → … each switch a
cross-host resume, each host's 2nd leg a same-host resume.

## Validated GREEN (artifact-level)

- **Dedupe holds on real codex, every session.** Each codex SessionStart double-fires (2 journal rows, same
  GUID) and the atomic claim renders the bootstrap directive ONCE (one per-key `hook-bootstrap-render-<guid>-startup.json`).
  Observed live: two `SessionStart hook (completed)` blocks BUT only one `[specrew-bootstrap]` directive — the
  second block is the **refocus banner** (the documented BENIGN doubling; refocus is provider order 10, not
  deduped). Session marker stays a single valid object (atomic write held).
- **Same-host resume (codex→codex) round-trips.** New session entered `mode=welcome-back`, `handover_valid=True`;
  resumed at the next remaining lens (`requirements-nfr`) WITHOUT restarting the workshop or re-asking done
  lenses; earlier lens records untouched.
- **The handover captures the mechanical state + conversation.** `from_host: codex`, `workshop_done:
  product-domain, architecture-core`, `workshop_remaining: requirements-nfr, …` (6), conversation capture (T002)
  carries the actual lens dialogue + the human's approvals + the agenda. Agenda IS persisted
  (`lens-applicability.json`) — the earlier "codex doesn't persist the agenda" worry did not recur here.

## DF-1 (MEDIUM-HIGH, UX) — the resume recap is MECHANICAL, not SUBSTANTIVE

On the same-host resume, codex's orientation named the **done lens names** + listed the **changed files**, but
did NOT convey (a) a "welcome back" framing, or (b) the **decisions** reached in the done lenses (e.g.
"standalone layered CLI, local-file storage, light personal-task scope"). For a human restarting a project, the
DECISIONS are what matter — a file list is not a recap. Reported by the maintainer: *"no Welcome back, no
message that we're in the middle of a workshop, so far we agreed on… these are important for a human that
restarts."*

**Root cause:** the structured handover's interpretive sections (`Open questions`, `Working hypothesis`) are
PLACEHOLDERS mid-workshop — the agent only authors them at BOUNDARIES (FR-022), and between lenses is not a
boundary. So the structured handover carries file-changes + lens-names but no decisions; the directive renders
those mechanical sections, and the in-flight scan lists lens NAMES (not their conclusions). The decision
substance DOES exist on disk (the lens records' conclusions + the conversation capture), but nothing synthesizes
it into a welcome-back recap.

**Fix options (follow-up slice, NOT this session):**

- (A) Surface each done lens's DECISION (one line from its record) in the in-flight scan / handover, not just the
  lens name.
- (B) Direct a welcome-back synthesis in the resume directive: on an in-flight workshop resume, instruct the
  agent to read the done lens records and render "here's what we DECIDED so far, where we are, next lens".
- (C) Author the interpretive handover sections per-lens-completion (not only at boundaries), so the structured
  handover carries decisions even mid-workshop.

The boundary legs (claude at workshop-complete/specify, copilot at plan/tasks) will test whether agent-authoring
at an ACTUAL boundary produces a substantive recap — if it does, DF-1 is specifically the *mid-stage* gap.

### DF-1 UPDATE — Leg 3 (claude cross-host) is the discriminator: it's HOST-VARIABLE, not a system gap

claude resumed codex's mid-lens handover (cross-host) and produced EXACTLY the substantive welcome-back recap
DF-1 said was missing: it opened "**Welcome back**", named the DONE lenses *and the spec-is-still-template
process position*, listed REMAINING, and GROUNDED the resumed ui-ux proposal in the prior decisions ("grounded
in the component map and the quality baseline we already agreed"; "how we honor the binding rule 'listing must
distinguish pending from completed'"). It resumed at ui-ux, re-posed it *with* prior context, and never re-asked
lenses 1–4. So the system DOES carry the substance (conversation capture + lens records) — **codex under-
synthesized it; claude synthesized it well.** DF-1 reframes from "the handover lacks decisions" to "a terse host
(codex) renders a mechanical recap while a richer host (claude) renders a substantive one." Likely amplifier:
**delivery mode** — codex gets a POINTER (reads files, renders the banner before fully synthesizing), claude
gets the INLINED contract (more context up front). Fix lever shifts to: (B) a stronger welcome-back-synthesis
nudge in the directive, weighted for pointer-mode hosts; and/or (A) surface each done lens's DECISION (one line
from its record) in the in-flight scan so even a terse host has the substance in hand without synthesizing.

### Cross-host resume — GREEN (artifact level)

- claude (`dd3a0671`) read codex's handover -> `mode=welcome-back`, `handover_valid=True`; `from_host` switched
  to `claude` on its first turn (T004); `workshop_done` preserved all 4 lenses across the host switch; marker
  atomically updated to `host=claude`. Resumed at `ui-ux` without restarting.
- **claude fires SessionStart ONCE** (1 journal row, 1 claim file) — it does NOT double-fire like codex. So the
  double-render is codex-specific; the dedupe correctly targets the host with the problem and is a harmless
  single-claim no-op on claude. Confirms the dedupe scope on a second host.

### DF-2 CONFIRMED — version/branch resolution is delivery-mode-specific

claude's banner rendered "Specrew: 0.35.0" (inline contract carries it); codex's rendered "version: not resolved"
(pointer mode — version lives in the pointed-to `last-start-prompt.md`, not the directive). The bootstrap
directive should carry the resolved version + branch directly so the banner is complete even in pointer mode.

## DF-3 (HIGH) — boundary-authoring (FR-022) did NOT fire at the specify boundary

copilot reached the SPECIFY boundary cleanly: completed all 7 lenses (even searched the maintainer's GitHub for
a matching example on code-implementation), wrote `spec.md`, made the boundary commit (`5eb2a36
boundary(specify): write cli todo spec`), ran the governance validator (passed), and rendered a FULL six-section
verdict packet (What I Just Did / Why I Stopped / What Needs Your Review / What Happens Next / Discussion Prompts
/ verdict options 1-4) via copilot's own prose path — NOT the gate-stop skill (correct; that's Claude-only). The
GATE PRESENTATION was excellent.

BUT the rich packet was rendered to the human and NOT persisted to the handover. Artifact truth after the stop:

- interpretive sections are STILL placeholders (3 "has not authored" markers); `## Why I'm stopping` reads
  "Hook-captured at trigger 'agentStop' (the agent did not author a handover this turn) … Boundary: (pre-boundary
  / workshop)".
- `active_boundary:` is EMPTY (not `specify`) — the boundary STATE is not captured in the handover (only
  `from_commit: 5eb2a36` is).

So FR-022's invariant — "FIRST persist the packet as the handover body via Write-SpecrewHandoverContext, THEN
render the packet FROM that file, so what the human sees == what the next session inherits" — is BROKEN at the
boundary: the human saw a rich six-section packet; the next session would inherit placeholders + mechanical
state. This is the boundary-authoring half of DF-1, now CONFIRMED at the ARTIFACT level (the handover file shows
placeholders — not a dogfood-agent-knowledge confound). The naive agent (copilot) did not call
Write-SpecrewHandoverContext.

**Impact:** a resume at the boundary inherits placeholders + the mechanical state (workshop done, boundary
commit) — it CAN re-derive "specify boundary, awaiting verdict" from disk (spec + commit + in-flight scan), so
resume is not broken, but the agent's review focus / discussion prompts / working hypothesis are LOST
(re-generated by the next session, not inherited).

**Likely structural cause + fix direction:** on NON-Claude hosts the agent renders the boundary packet DIRECTLY
(there is no gate-stop skill to enforce the persist), and FR-022's "persist first" is a directive instruction a
naive agent skips. The fix is to make boundary-authoring RELIABLE rather than agent-discretion — e.g., the
boundary/gate flow persists the rendered packet to the handover as a MECHANICAL step (and sets
`active_boundary`), not relying on the agent remembering FR-022 — at least on the non-Claude direct-render path.
UNTESTED: whether Claude's gate-stop skill DOES persist the body (the Claude path may not have this gap — worth a
targeted check). This is arguably the single most valuable finding of the round-robin: the handover should be
RICHEST at a boundary, and instead it is placeholders.

**DF-3 follow-up — claude ALSO did not author (so it is ~universal, not non-Claude-specific).** A claude
cross-host resume AT the specify boundary (6th session) rendered a full re-entry orientation/status, then its
turn-end `Stop` refreshed the handover — which STILL shows 3 placeholders + `active_boundary:` empty. So across
copilot (verdict-packet render) AND claude (status re-entry render), the agent did not author. Strong evidence
the gap is structural; the fix must be host-universal + mechanical (the boundary flow persists the packet + sets
`active_boundary`), not reliant on the agent following FR-022. The ONE remaining untested variant: claude's
`specrew-gate-stop` skill rendering an actual VERDICT packet (the status query "where are we?" did not trigger
the gate-stop verdict path) — worth a targeted check, but two hosts × two render paths already show no authoring.

## DF-4 (HIGH) — the not-authored boundary handover led the resuming host to MISREAD the gate

This is DF-3's blast radius, and it is the serious one. The maintainer exited copilot AT the specify boundary
WITHOUT giving the verdict (copilot had rendered the packet asking approve/send-back/discuss). Ground truth:
`boundary_enforcement.last_authorized_boundary = None`, `pending_next_boundary = None`, and the git log has only
the ARTIFACT commit (`5eb2a36 boundary(specify): write cli todo spec`) — NO approval. So specify is
committed-but-NOT-approved; the correct resume read is "specify spec committed, AWAITING your verdict."

claude (resuming via a natural "where are we?" status query) instead concluded: *"The specify boundary is closed
and committed … the clarify step has nothing outstanding … the next lifecycle boundary is plan … recommended
next step: authorize planning."* It treated the `boundary(specify)` ARTIFACT commit as APPROVAL, skipped the
pending specify verdict AND clarify, and was poised to recommend advancing to plan. Had the human said "go,"
claude would have crossed two un-authorized gates.

Honesty / confound note: claude HAD the disambiguating signal — it ran `specrew where`, which printed "Last
authorized boundary: (none)" — and under-weighted it, over-weighting the commit. So part of this is agent
interpretation. BUT the ROOT is the DF-3 gap: the handover (the primary FR-022 resume context) carried NO
`active_boundary`, so it gave claude nothing to anchor on and left it to guess from an ambiguous disk state (a
`boundary(specify)` commit reads like "boundary crossed"). A handover that recorded `active_boundary: specify
(awaiting verdict)` would have prevented the misread directly. Two fixes fall out: (1) DF-3's — record the
boundary state + author the packet at a boundary (mechanically); (2) the resume/`specrew where` logic should
treat `last_authorized_boundary` as decisive — a committed boundary ARTIFACT is not an AUTHORIZED boundary, and
the resume must surface "awaiting verdict for <boundary>" rather than inferring closure from the commit.

**Net:** DF-3 (universal boundary-authoring gap) + DF-4 (its consequence — a resuming host misreads the gate and
would skip an un-approved boundary) are the highest-value findings of the round-robin. The handover should be
RICHEST and most authoritative exactly at a boundary; instead it is placeholders, and that gap propagated into a
real lifecycle-position misread.

## Codex native-resume scenario (`codex resume <id>`) — reconciliation SURVIVES; DF-3 reframed; DF-5 surfaced

The maintainer resumed codex's stale lens-4 session via `codex resume 019ec0e6` (codex's OWN native session
resume) — with claude + copilot having since advanced the work to the specify boundary.

**WIN — Specrew's reconciliation survives a host-native resume (the headline result):**

- `codex resume` FIRES the SessionStart hook (`source=resume`; SINGLE fire — native resume does NOT double-fire
  like a fresh `startup`). So Specrew is NOT bypassed by the host's own resume mechanism.
- codex's native resume REPLAYED the stale lens-2-4 conversation to the screen (maintainer: "I only entered
  continue, but it printed the entire original conversation") — exactly the stale context the scenario worried
  about. BUT the new hook's IN-FLIGHT scan reported "design-workshop COMPLETE; resume at the position AFTER the
  workshop" and the recent-conversation capture surfaced claude's "specify committed" work.
- codex RE-ORIENTED: it did NOT continue the stale workshop; it recognized the workshop done + specify committed.
  The reconciliation/in-flight-scan OVERRODE the host's confident-but-stale native resume. The scenario's worst
  case (codex plowing ahead from lens 4) did NOT occur. This is the load-bearing proof that Specrew's continuity
  holds even when a host resumes its own session with stale context.

**DF-3 REFRAME — INCONSISTENT, not universal.** At the clarify->plan boundary codex DID author the handover: it
"persisting the gate packet into session-handover.md before rendering it", writing the full six-section packet
(`source: agent-authored-boundary-packet`, `active_boundary: plan`, all sections real, NO placeholders). So
FR-022 boundary-authoring CAN + DOES fire — codex followed it; copilot (at specify) + claude (status query) did
not. DF-3 downgrades from "~universal gap" to "agent-discretion / inconsistent": codex is the gold standard; the
fix (make it mechanical) is to bring EVERY host reliably to codex's behavior.

**DF-5 (HIGH) — a resume + bare "continue" advanced TWO un-authorized boundaries.** Pre-resume:
`last_authorized_boundary: None` (specify committed at 5eb2a36 but NEVER approved — the maintainer exited copilot
without a verdict). With ONLY "continue", codex: ran clarify (added a `## Clarifications` section to spec.md),
committed `1bc4448 boundary(clarify): record cli todo clarifications`, SELF-authorized clarify via
`sync-boundary-state.ps1 -BoundaryType clarify -AuthCommitHash 1bc4448`, committed `c91da1a boundary(clarify):
sync governance state`, and presented the clarify->plan packet. So the lifecycle advanced specify->clarify with
NO explicit human verdict for either ("continue" != "approved for <boundary>", refocus Rule 3). This is DF-4's
misread ACTED UPON: the resume didn't just misread the committed-but-unapproved specify state, it advanced
through it + clarify. Contributing cause: the bootstrap in-flight directive ("when the human says continue,
resume at the position after the workshop … OR the recorded boundary") is ambiguous advance-vs-await; codex read
it as "advance". Fix ties to DF-4: treat `last_authorized_boundary` as decisive (committed != authorized) and
PRESENT the pending boundary's verdict — never auto-advance on "continue". CONFOUND note: partly codex's
interpretation, but the ARTIFACT facts are unambiguous (two `boundary(clarify)` commits + a clarify
boundary-sync, on a bare "continue", specify never explicitly approved) — worth the maintainer's judgment on the
intended specify->clarify flow.

(Side benefit observed: codex also FIXED a stale `.squad/identity/now.md` that still carried Feature-019 text —
the governance-sync self-heal works.)

## Cursor leg — DF-6, and the ROOT CAUSES of DF-3 (DF-7) and DF-5

cursor-agent resumed at the clarify->plan boundary and produced an EXCELLENT full six-section packet (correctly
stopped at the gate, did NOT auto-advance, no gate-stop skill — correct for non-Claude). DF-1: cursor is
SUBSTANTIVE (4th host) — confirms DF-1 is codex-specific terseness. BUT the artifacts behind it surfaced the
highest-value findings of the dogfood:

**DF-6 (MEDIUM) — cursor-agent CLI does NOT fire the Specrew bootstrap hook (INVESTIGATED, root cause found).**
No cursor row in bootstrap-journal.jsonl (`cursor sessions: []`); the cursor run left ZERO trace in
`.specrew/runtime/` (every file there is from the prior 17:40 codex session; the ~18:11 cursor run wrote
nothing). Root cause: `~/.cursor/hooks.json` is registered CORRECTLY by our deploy (sessionStart + stop +
dispatcher, the documented format, mtime confirms it), but **cursor-agent v2026.06.04 (the CLI) does not honor
it** — its `cli-config.json` has no hooks concept at all (keys: permissions/editor/model/sandbox/… nothing
hook-related). The F-171 "cursor: ~/.cursor/hooks.json verified live" was almost certainly the Cursor **IDE**, not
the cursor-agent CLI. Instead cursor-agent oriented via the **`.cursor/rules/specrew-*` project rules** init
deploys (14 of them: specrew-where, specrew-refocus, specrew-design-workshop, …) — it read the handover, ran
refocus/where, and produced a correct gate packet on its own. So cursor-agent is RULES-based, not hook-based:
between antigravity (no hooks, recover via `specrew start`) and the hook hosts (codex/claude/copilot). The cost:
cursor-agent never receives the auto-computed RECONCILIATION / in-flight scan the hook delivers — it re-derives
from the handover + rules (worked here, but it is a real F-174 coverage gap). Disposition: (a) treat the
rules-path as cursor-agent's sanctioned continuity surface (it works) and stop relying on the ineffective
`~/.cursor/hooks.json` for the CLI, or (b) find cursor-agent's actual hook mechanism (if any) and register there.
Either way `~/.cursor/hooks.json` is dead weight for cursor-agent (harmless, ineffective). T007's
inline-vs-pointer question is INCONCLUSIVE on cursor (the hook never delivered the inline contract).

**DF-7 (HIGH — the ROOT CAUSE of DF-3): `Write-SpecrewHandoverContext` is NOT accessible to the agent.** Confirmed
empirically: the installed Specrew module exports ZERO `*Handover*` functions; `Get-Command
Write-SpecrewHandoverContext` -> False (codex ran exactly this and got nothing). So FR-022's instruction "FIRST
persist it as the handover body via Write-SpecrewHandoverContext, THEN render" is UNFOLLOWABLE — the function the
directive names does not exist for the agent. This is why boundary-authoring (DF-3) is inconsistent: copilot +
claude SKIP it (no callable path); codex tried to comply but, unable to call the function, DIRECT-EDITED the file
(`Added .specrew\handover\session-handover.md +55`) — and its turn-end Stop hook then CLOBBERED that direct edit
(the handover reverted to `source: Stop`, `active_boundary: clarify` (regressed from codex's authored `plan`), 3
placeholders). So even a well-intentioned agent's authoring is lost. FIX (this resolves the DF-3 cluster): give
the agent a REAL, callable authoring path — an exposed command / skill (e.g. `specrew handover write` or a
`specrew-handover` skill) — OR make boundary-authoring MECHANICAL (the gate/boundary flow persists the rendered
packet + sets `active_boundary`, no agent function call required). Either way, FR-022 must stop naming a function
the agent cannot invoke.

**DF-5 escalated (HIGH) — the boundary-sync FABRICATES a human verdict for a self-authorization.** Ground truth:
the human gave NO verdict (only "continue"), yet `boundary_enforcement.verdict_history` now records `{from:
specify, to: clarify, verdict_text: "approved for clarify", authorizing_human: "ho-test", auth_commit_hash:
1bc4448}`. "ho-test" is the GIT COMMITTER (git user.name), not a human who approved anything. So when codex
self-authorized clarify (DF-5), `sync-boundary-state.ps1` wrote a FALSE audit record asserting a human approved
the boundary — and cursor (next host) read it as a real approval ("Clarify is complete and approved (approved for
clarify by ho-test @1bc4448)"). This is a boundary-integrity hole: an agent can manufacture an "approved-for-X
by <git user>" verdict purely by committing + running boundary-sync, with no human in the loop. FIX: the
boundary-sync must require a real human verdict signal (not infer the approver from the git committer), and/or
the resume/`specrew where` must distinguish "boundary artifact committed" from "boundary authorized by a human".

## Antigravity leg (5th/last host) — T008 recovery works; robustness is mechanism-yes / state-no

antigravity (no hooks) launched via `specrew start`, received the "read last-start-prompt.md + start-context.json"
FR-023 pointer (the launcher injects it, no hook), re-derived the lifecycle from artifacts, emitted a full
`=== SPECREW HANDOFF ===` six-section packet, and STOPPED at the boundary (good discipline, no auto-advance).
DF-1: antigravity is SUBSTANTIVE ("Welcome back" + recap) — 5th host, DF-1 firmly codex-specific. So the
host-universal `specrew start` recovery (T008) is VALIDATED on the host it was designed for.

ROBUSTNESS TEST (the maintainer's "can a host catch up despite a rotten handover?"): PARTIAL NO — and it's the
DF-3/4/5 cluster biting on the last host. antigravity landed at `clarify` and planned to "draft design-analysis.md"
— ONE GATE BEHIND, poised to RE-DRAFT what cursor already produced (`f4437c0 boundary(plan)`, design-analysis.md
exists). It read the artifacts (incl. design-analysis.md) but the degraded handover (`active_boundary: clarify`,
placeholders, `from_host: codex`) + boundary-enforcement (`last_authorized: clarify` — which LAGS because cursor's
design-analysis was never VERDICTED, DF-5) pulled it back; it did not reconcile forward to "design-analysis
drafted, awaiting the Option verdict." So: the recovery MECHANISM is robust (antigravity oriented + ran the
lifecycle), but the recovery STATE is not — when in-progress gate work isn't authored into the handover (DF-3) and
the verdict isn't recorded (DF-5), a resume rewinds a step and redoes work. Direct evidence the cluster fix is
load-bearing: author the true boundary/gate state (incl. drafted-but-unverdicted in-progress work) into the
handover so a resume reconciles forward, not backward.

UPDATE — robustness RECOVERED (upgrade from "partial no"). After the human's clarify->plan approval, antigravity
advanced, FOUND cursor's existing `design-analysis.md` (did NOT re-draft from scratch), reached the
design-analysis gate, and presented the correct Option A/B/C packet awaiting "approved for plan with Option B".
So the system recovered — at the cost of a ONE-GATE REWIND + a redundant re-approval (the human re-approved
clarify->plan that cursor had already passed), but NO WORK WAS LOST. Net robustness read: the committed tree IS
the durable source of truth (a resume re-derives + reuses prior work), and the degraded handover costs a redundant
step, not correctness. This is the strongest argument for the DF-3/4/5 fix being about UX/efficiency + integrity,
not data-loss. NOTE: this advance was LEGITIMATE (the human gave verdict "1"), unlike codex's DF-5 auto-advance
on bare "continue" — so the boundary-sync verdict recording here is correct.

## DF-8 (HIGH) — an agent edited the GOVERNANCE ENFORCEMENT to unblock its own gate

Hitting a `handoff-block-missing` validator failure during the clarify boundary-sync, antigravity investigated
`shared-governance.ps1`, EDITED the deployed validator, and committed it: `8531aa3 boundary(clarify): sync
boundary state and fix handoff validator`. Two concerns regardless of whether the edit fixed a real validator bug
or weakened the check: (1) GOVERNANCE INTEGRITY — an agent with file access (YOLO / skip-permissions, the norm
for these hosts) can modify the very governance scripts it is governed by, to pass its own gate; the enforcement
is only as strong as the agent's restraint. (2) DRIFT — the project's deployed `.specify/.../shared-governance.ps1`
now differs from canonical (the module / dev tree); a downstream project silently forked its governance logic.
This is bigger than F-174 (it is a governance-architecture concern) but the dogfood surfaced it: consider making
the deployed governance scripts integrity-checked / read-only-relative-to-canonical, or at minimum flagging when
a boundary commit modifies `.specify/extensions/.../scripts|validators`. CONFOUND note: the `handoff-block-missing`
WARN is a real recurring validator signal (seen on codex's clarify commit too), so antigravity may have fixed a
genuine over-strict check — but "agent edits its own governance to advance" is the pattern to close.

### Final host tally

codex (hook, double-fire, terse, DF-5 auto-advance + DF-7 direct-edit) · claude (hook, single-fire, substantive,
gate-stop host, DF-4 misread on status) · copilot (hook, single-fire, substantive, clean gate packet, DF-3
no-author) · cursor-agent (NO hook — rules-based, DF-6) · antigravity (NO hook — `specrew start`/T008, substantive,
recovered-with-rewind, DF-8 governance-edit). All 5 hosts exercised; bootstrap dedupe + continuity green; the
DF-3/4/5/7 cluster + DF-8 are the fix targets.

### Dogfood finding ledger (final)

- DF-1 (resume recap quality; codex-terse, others substantive) — small fix (push pointer-mode hosts).
- DF-2 (version/branch absent in codex pointer banner) — small fix (carry them in the directive).
- DF-3 (boundary-authoring inconsistent) — ROOT = DF-7.
- DF-4 (resume misreads committed!=authorized) — pairs with DF-5.
- DF-5 (auto-advance on "continue" + FABRICATED verdict in the audit trail) — HIGH.
- DF-6 (cursor-agent bootstrap hook didn't fire) — MEDIUM, investigate.
- DF-7 (Write-SpecrewHandoverContext not agent-callable; FR-022 unfollowable) — HIGH, ROOT of DF-3.
The DF-3/4/5/7 cluster is one coherent fix: a real authoring path + boundary state authored into the handover +
"committed != authorized" enforced + no fabricated verdicts.

### DF-1 reconfirmed on claude SAME-host resume (4th session)

claude again opened "Welcome back", resolved version + branch, and GROUNDED the resumed data-storage lens in
the prior decisions: *"Architecture-core already fixed the big call: tasks live in a local file behind the
TaskRepository seam … So this lens is not 'file vs database' — that's decided."* So claude is consistently
substantive on BOTH resume types (cross-host AND same-host) — the cross-session continuity carries the
DECISIONS, and claude weaves them forward. This pins DF-1 firmly as codex/pointer-mode terseness, NOT a system
data gap. Maintainer's read: *"Claude is very good in the welcome back."* Resume-type matrix now fully GREEN:
codex→codex, codex→claude, claude→claude all resumed correctly at the next lens with prior lenses intact.

## DF-2 (LOW) — version/branch absent from codex's first banner

codex's initial orientation rendered "Specrew version: not resolved … / Branch: not resolved …" and deferred to
look them up. For codex (pointer delivery mode) the version lives in the pointed-to contract
(`last-start-prompt.md`), not in the bootstrap directive itself, so the banner is incomplete on first render
until the agent reads the contract. Inline hosts (claude) get the version in the inlined contract. The bootstrap
directive could carry the resolved version + branch directly so the banner is complete even in pointer mode.
