# Feature Specification: beta5 stabilization

**Feature Branch**: `203-beta5-stabilization` (branched from main at `df1141a8`)
**Created**: 2026-10-31
**Status**: Draft
**Input**: Maintainer intake of the beta5 backlog (`docs/beta5-findings.md` B5F-001 to B5F-015, plus the
beta4 items marked as beta5 work, including B4F-142), 2026-10-29. Scope, design and constraints come from
the completed design workshop: product-domain plus seven lenses, each closed by a typed maintainer reply
with a recorded receipt. The records are under `specs/203-beta5-stabilization/workshop/`.

## Clarifications

### Session 2026-10-31 (specify verdict and clarify)

- Q: Does a fix made after the last clean round that touches only tests need another round? → A: Yes, no
  test-only exemption; the round is scoped to the files the fix changed (FR-013).
- Q: Which deterministic-gate steps do the Windows census shards replace? → A: None. The gate stays the
  Linux lane with all its steps; the 12 script-style suites join the census and also stay in the gate
  (FR-035, FR-036).
- Q: The B5F-004 table? → A: As proposed, with one check: `evidence-absent` is a crew repair, so convert it
  if the verdict writer already refuses over missing artifacts. Checked at clarify against the source:
  - When the bound tree is **checked and the artifacts are absent**, the verdict writer already refuses
    (the capture path records `verdict-refused-stage-evidence-absent` and authorizes nothing), the
    boundary sync withholds the pending-verdict artifact, and the post-capture handover withholds it
    too. That case is **converted**. Its refusal reaches the human only as a crew-side warning today, so
    it joins the FR-026 branches as "stage evidence absent".
  - When the evidence **cannot be verified** (no bound tree id, or the tree is unreadable), the writer
    deliberately does not refuse, so that a component hiccup cannot drop a real verdict, and a bare
    marker still captures. In that case the block is the only thing that keeps an approval from being
    offered over unverifiable work, so it is **kept** for that case alone.
- Q: Does `pres-boundary-packet` stay a keep? → A: Only for a packet that is absent or missing its
  decision-bearing parts (approval line, marker, options). A reworded content line is not a block. The
  root cause of today's three declared-vs-reply blocks is the packet written twice and checked word for
  word; verify the reply itself at Stop instead (FR-046). Maintainer ruling at clarify.
- Clarify verdict instructions (2026-10-31): the unverifiable-evidence block stays as written; the plan
  proposes the review budget with its reasoning; FR-046 moves to iteration 1; and the plan MUST state when
  203's changes reach the live hook copies that govern this feature's own boundaries, with the maintainer's
  preference that they reach them only after an iteration's review, so a half-built capture never judges
  the maintainer's approvals.
- Q: Iterations? → A: Two. Iteration 1 ends with a short Claude-only capture check (a verdict typed after a
  compaction, a quoted phrase, a pasted phrase); the full three-host walk stays at the end of iteration 2
  (FR-045).

## Governing direction

Per-round review approvals go. The maintainer approves a review budget once, inside the before-implement
verdict: the plan states the budget in rounds and a reviewer host order (codex, then copilot, then
claude). Within the budget the review cycle runs without asking: a clean result ends the review, and a
fix-needed result means fix, then the next round. The human is stopped only when (a) the budget is spent,
(b) the crew wants to dispute or defer a finding, (c) a finding needs the human's judgment, or (d) the
next reviewer host is outside the approved order. The per-round approval guarded against runaway cycles;
the budget, the reservation before invocation, and the fix decision now do that job.

Authority correctness outranks friction. Where a fix trades one for the other, refusing to record beats
recording an approval nobody gave (requirements-nfr, priority b, a, c, d, f, e).

## Scope

- **A. Review budget model.** Absorbs B4F-115, B4F-121, B4F-061, B4F-126, B4F-152, B5F-012 and the
  residues of B4F-116/150, B4F-117, B4F-140/137, B4F-058 and B4F-054. Reviewer token usage is shown,
  never enforced.
- **B. Approval capture correctness.** B4F-112, B4F-151 and the capture residues from A.
- **C. Stops that carry no decision.** B5F-004 (the stop-reason audit below), B5F-011 (every waiting turn
  ends with what to type), and the one-reply workshop confirmation.
- **D. Lifecycle.** B5F-014: a merged feature's claim is never released.
- **Rider: CI.** B5F-013, B5F-015, B4F-079, B4F-119, B4F-158 (the gating half), B4F-142.

**Out of scope**: candidate feature 204 (maintainer, 2026-10-31), which is required before 0.40.0
stable: init and bootstrap B5F-006 to B5F-010; the SpecKit upgrade 0.12.9 to 1.2.x; the decision between
Squad 0.11.0 to 1.1.0 and keeping the pin until Phase 3; a refresh of the code-rules catalog (last changed
2026-08-15); and the release rule that before any stable release every dependency moves to its latest
stable version in a beta of that line, or carries a recorded reason, with a publish-workflow check on
stable tags. 203 keeps the SpecKit 0.12.9 and Squad 0.11.0 pins and the current catalog, and ships as a
beta of the 0.40.0 line, not as stable. Also out: B5F-001, B5F-002,
B5F-003, B5F-005; B4F-125 (dropped by the maintainer); B4F-158's record-state half (backlog); the
remaining beta4 items marked beta5 (dashboards, host tiers, Ctrl+O and others); the automated walk
(B4F-145); token enforcement.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - I approve a review budget once (Priority: P1)

The maintainer approves the plan's review budget inside the before-implement verdict. The review then runs
round after round on the approved hosts without asking, until the code is clean or the budget is spent. A
spent budget costs one typed top-up, which also starts the next round.

**Why this priority**: B4F-061 measured six typed authorizations for one review boundary; B4F-115 and
B4F-121 stopped the maintainer for approvals already given or while a round was running. This story removes
the class rather than each symptom.

**Independent Test**: plan a feature with a two-round budget, approve before-implement, and drive a review
with one fix-needed round, one clean round, a spent budget and a top-up through the shipped entry points;
count the typed authorizations and the stops.

**Acceptance Scenarios**:

1. **Given** a plan stating 2 rounds and the order codex, copilot, claude, **When** the maintainer types
   `approved for before-implement`, **Then** the review grant holds `budget_total = 2` and that host order,
   citing the verdict, and a later edit to the plan does not change it.
2. **Given** a granted budget with rounds left, **When** a round returns fix-needed, **Then** the crew fixes
   within the approved tasks and the next round starts with no human stop.
3. **Given** a round returns clean, **Then** the review ends and the sign-off packet follows.
4. **Given** `rounds_used = budget_total`, **When** the cycle wants another round, **Then** no reviewer is
   invoked and stop (a) is shown with `approved for allowance reset` and `stop the review here`, each stating
   its consequence.
5. **Given** stop (a), **When** the maintainer types `approved for allowance reset`, **Then** another
   `budget_total` rounds are granted and the next round starts in the same turn sequence, with no second
   approval.
6. **Given** a plan budget above the configured ceiling, **When** the plan states it or the verdict snapshots
   it, **Then** it is refused, and the refusal names the ceiling and where it is set.
7. **Given** a plan written before 203 with no budget, **When** the first review is due, **Then** it meets
   stop (a) at once and the top-up grants the rounds.
8. **Given** three consecutive infrastructure failures on codex (N = 3 for the example), **Then** no round is
   spent and the next round runs on copilot; when the order is exhausted, stop (d) is shown.
9. **Given** the next host would be outside the approved order, **Then** stop (d) offers `allow reviewer
   <host>` and `stop the review here`.
10. **Given** a round completes, **Then** its result shows host-reported token usage or "usage: not reported
    by <host>", and the sign-off shows the total.

---

### User Story 2 - Nothing is recorded that I did not give, and what I give is recorded the first time (Priority: P1)

Every approval, top-up, stop answer and workshop reply is recorded once, from the typed turn the human
actually gave, the first time they give it, including after a context compaction. No path records an
approval from a quoted phrase, a phrase in backticks, pasted content, a compaction summary, agent text, or
an agent citing a real human turn.

**Why this priority**: measure (b) is the top-priority measure. B4F-112 lost a verdict across a compaction;
the backstop double-recorded approvals before 202; in this session the allowance reset was written by the
agent with an agent-authored reason.

**Independent Test**: fault fixtures drive every mint path with no human turn and with non-approval phrases;
per-host replay from recorded real payloads, including a compaction between the packet and the reply; an
audit joins every authority record to a typed human turn.

**Acceptance Scenarios**:

1. **Given** a human turn that quotes `approved for allowance reset` mid-message, in backticks, or inside
   pasted content, **Then** nothing is minted (the maintainer's workshop messages are the reference case).
2. **Given** no human turn, **When** the turn-end path, the transcript backstop or a writer CLI runs,
   **Then** nothing is minted.
3. **Given** a packet, then a compaction, then the typed verdict, **Then** the verdict is recorded against the
   waiting boundary in that turn, on each host.
4. **Given** plan waits, **When** the maintainer types `approved for tasks`, **Then** nothing is recorded and
   the mismatch is reported in the same turn.
5. **Given** an agent cites the maintainer's real `confirm` turn to a writer, **When** the writer asks for a
   verdict, **Then** the writer re-derives the act from that turn, finds a workshop reply, and mints no
   verdict.
6. **Given** the maintainer types `approved for allowance reset`, **Then** the hook mints the top-up and its
   reason is the maintainer's own text or none.
7. **Given** a newer typed act of the same kind while an older one is unspent, **Then** an immutable
   supersession fact retires the older one, which is never reused.

---

### User Story 3 - When something I typed is not recorded, I am told in the same turn (Priority: P1)

If a standalone approval phrase is seen and nothing is recorded, for any reason, the human is told in that
turn what was looked for, what it was taken for, and that nothing was recorded, in plain words.

**Why this priority**: B4F-151 records nothing and says nothing; B4F-112 silently fell back to an older
pair. Measure (c), no false "not recorded", depends on the same reports checking the store when they speak.

**Independent Test**: drive each no-record branch (form unreadable, writer failed, origin unconfirmed, no
pending crossing, boundary mismatch) and assert the report appears with its own reason.

**Acceptance Scenarios**:

1. **Given** the approval form cannot be read, **When** the maintainer types a standalone approval, **Then**
   the turn shows that nothing was recorded and why, and the diagnosis goes to the drift record.
2. **Given** an approval that was recorded, **Then** no "not recorded" report appears.
3. **Given** a host with no visible-line channel, **Then** the report is a stop, kept in the B5F-004 audit,
   because the human must act.

---

### User Story 4 - Stops only when I have a decision to make, and every wait says what to type (Priority: P2)

Every stop reason that remains protects authority or asks for a decision the human must make. Every turn
that waits on the human ends with one line naming what to type. Any text a hook blocks with is written for
the human. A workshop confirmation costs one reply.

**Why this priority**: B5F-004, B5F-011, B5F-012; the second agenda confirmation in this workshop is the same
class as B4F-061.

**Independent Test**: the B5F-004 table below, ruled by the maintainer, then a census of stop reasons on the
three-host walk; a waiting turn without the closing line gets one supplied; a "confirmed, with these
changes" reply saves without a second ask.

**Acceptance Scenarios**:

1. **Given** a waiting turn without the closing line, **Then** the line is supplied without blocking the turn
   (or a drift entry is recorded on a host that can only add it by blocking).
2. **Given** a hook must block, **Then** its text is plain words for a human with no internal codes, and crew
   guidance goes through the non-blocking context channel where the host has one.
3. **Given** a workshop agenda or lens is answered "confirmed, with these changes", **Then** the crew either
   saves against the amended text or applies the changes and saves without asking again.

---

### User Story 5 - CI catches on a pull request what the release would catch (Priority: P2)

Every test the publish census can fail on also runs on every pull request into main; no suite in `tests/` is
invisible; a lint failure on a record no longer hides a test failure.

**Why this priority**: B5F-015 cost a fix pull request and a second release dry run; B4F-079 and B4F-158
hid the deterministic gate for weeks; B4F-119 found seven suites nobody runs.

**Independent Test**: the census-to-PR parity test; the census selection check; a pull request with a lint
failure still runs the deterministic gate.

**Acceptance Scenarios**:

1. **Given** a pull request into main, **Then** the census runs sharded, with the same selection and
   exclusions as the publish workflow, as a required check.
2. **Given** a new `.ps1` under `tests/` that is neither a census suite nor on the reviewed non-suite list,
   **Then** the selection check fails.
3. **Given** a markdown lint failure, **Then** the deterministic gate still runs and lint fails as its own
   required check.
4. **Given** the coordinator fragment is composed, **Then** the composed `.github/agents/squad.agent.md`
   passes lint, and push lint covers dot-directories.

---

### User Story 6 - A merged feature's claim is released (Priority: P3)

When a feature's merge is observed, its claim leaves the active-features record, with a release record.

**Why this priority**: the claims of 198, 199 and 202 are still held; 203's own closeout would hit it.

**Independent Test**: a fixture project with a merged feature branch; start a session and run a boundary
sync; check the claim and the release record.

**Acceptance Scenarios**:

1. **Given** a claimed feature whose branch is merged into main, **When** a session starts or a boundary
   syncs, **Then** the claim is released with a release record.
2. **Given** a feature closed out but not merged, **Then** its claim stays.

---

### User Story 7 - The hook-output journal holds one line per append (Priority: P3)

Under concurrent writers, the hook-output journal holds exactly one line per append except after a
flusher crash; the cause of the one-second lock wait on Linux is known.

**Why this priority**: B4F-142, four Linux CI occurrences; nothing decides on this journal, so it is
correctness of a record, not of authority.

**Independent Test**: fault-injection case (e) with an exact line count on all three operating systems; a
crash-recovery case asserting duplicates only from the crashed flusher's claim.

**Acceptance Scenarios**:

1. **Given** four writers and two flushers with no crash, **Then** the journal holds exactly as many lines as
   appends.
2. **Given** a flusher crashes holding a claim, **Then** a later flusher re-flushes the stale claim, and any
   duplicate lines come only from that claim.

---

### Edge Cases

- A top-up typed twice: the reset moves the counting origin; a second reset with no round between is
  harmless and grants no extra rounds beyond one window.
- A verdict-shaped reply while no crossing waits: reported, nothing recorded.
- A compaction between a stop (a) and the top-up: the top-up pairs with the pending pause fact, not the
  transcript chain.
- A plan edited after the before-implement verdict: the grant keeps the snapshot; the edit is drift.
- Infrastructure failures alternating with real rounds: the consecutive count resets on a completed round.
- A deferral typed without a destination: not offered; if typed, reported as not recorded.
- A host whose user-prompt event carries no message id: the explicit per-host substitute identity applies.
- A pull request that only touches docs: the census still runs (no path filter).
- A stale buffer claim whose flusher is alive but slow: the age bound decides; a duplicate is possible only
  through crash recovery.

## Requirements *(mandatory)*

### Functional Requirements

**A. Review budget (US1)**

- **FR-001**: The plan MUST state a review budget: a number of rounds (0 or more) and an ordered list of
  reviewer hosts.
- **FR-002**: A plan budget above the configured ceiling MUST be refused when the plan states it and when the
  before-implement verdict snapshots it. The refusal MUST name the ceiling and where it is set.
- **FR-003**: Recording the before-implement verdict MUST snapshot the plan's rounds and host order into the
  single review grant, citing that verdict. The review engine MUST NOT read the plan's budget after the
  snapshot.
- **FR-004**: There MUST be one runtime counter, `rounds_used` against the snapshotted `budget_total`. A round
  MUST be reserved before the reviewer is invoked; no reservation, no invocation. A reservation released
  before invocation MUST spend nothing.
- **FR-005**: Within the budget, a clean round MUST end the review and a fix-needed round MUST lead to a fix
  within the approved tasks and the next round, with no human stop.
- **FR-006**: The review MUST stop the human only for (a) budget spent, (b) a dispute or deferral, (c) a
  judgment call, (d) a next host outside the approved order, including an exhausted order. No stop MUST ask
  for a round. No review stop MUST occur outside implement. No block MUST exist whose only purpose is to make
  the crew run the next round.
- **FR-007**: `approved for allowance reset` MUST record the existing budget-reset fact, grant another
  `budget_total` rounds and start the next round. The hook MUST mint it from the typed turn; its reason MUST
  be the human's own text or none.
- **FR-008**: A plan with no stated budget MUST get `budget_total = 0`.
- **FR-009**: An infrastructure failure MUST NOT spend a round. After N consecutive infrastructure failures on
  a host (N a named configuration value set in the plan), the cycle MUST move to the next host in the
  approved order; when the order is exhausted it MUST stop at (d).
- **FR-010**: The per-round approval MUST be removed: its phrase, the one-slot-per-authorization grant, and
  the `--approve-round` CLI.
- **FR-011**: Review stops MUST use one layout (why; what happened, counted; the one decision; sendable lines
  each stating its consequence) and these lines: `approved for allowance reset`; `stop the review here` (the
  sign-off lists what remains uncovered); `defer finding <id> to <backlog item or iteration>` (a destination is
  required); `drop finding <id>`; `fix finding <id>`; `allow reviewer <host>`; free text for a judgment call.
- **FR-012**: Each round result MUST show host-reported token usage or "usage: not reported by <host>"; the
  sign-off MUST show the total. Usage MUST NOT be estimated or enforced.
- **FR-013**: A fix made after the last clean round, including a fix that touches only tests, MUST get the
  next round within the budget; there is no test-only exemption (B4F-054 residue, maintainer ruling
  2026-10-31). That round MUST be scoped to the files the fix changed, through the engine's existing
  narrow-scope path, so a late fix costs a small round, not a full one. When the budget is spent, stop (a)
  applies and `stop the review here` lists the fix as unreviewed. Tests are reviewed because a weakened
  assertion is how measure (b) would silently stop being proven.

**B. Approval capture (US2, US3)**

- **FR-014**: Only the typed turn delivered by the host's user-prompt event MAY mint authority. The turn-end
  path, the transcript backstop and any writer CLI MUST only recover a missed hook event, under FR-015.
- **FR-015**: On every path, including the hook, a mint MUST require: a turn identity; a human-authored turn
  (not a compaction summary, tool result or agent text); the phrase standing alone (not quoted, not in
  backticks, not inside pasted content); no existing record for that identity.
- **FR-016**: Before the plan fixes the mechanism, each host MUST be checked for whether its user-prompt event
  carries a per-message id. Where it does not, the substitute identity MUST be defined explicitly per host in
  the plan.
- **FR-017**: Before the plan fixes the mechanism, each host MUST be checked for how pasted content reaches the
  hook (marked, placeholder, or plain text), and the plan MUST state how FR-015's standalone rule applies on
  each.
- **FR-018**: One classifier MUST read each typed turn exactly once and route it to exactly one act: boundary
  verdict, top-up, stop answer, or workshop reply.
- **FR-019**: A verdict-shaped reply MUST be paired with the durable pending-crossing record, not with a marker
  reached by walking the transcript; a compaction summary MUST NOT count as a human turn; the fallback to an
  older pair MUST be removed.
- **FR-020**: A verdict-shaped reply naming a different boundary than the one waiting MUST be reported and MUST
  record nothing.
- **FR-021**: The newest typed act of a kind MUST supersede an older unspent one through an immutable
  supersession fact; the older one MUST NOT be reused.
- **FR-022**: A writer given a turn identity MUST re-read that turn, mint only the act the classifier derives
  from it, and only if that act is unrecorded.
- **FR-023**: Authority records MUST store turn identities and hashes, not raw prompts; phrase text MUST be kept
  only where a stop answer needs its argument (a deferral's destination).
- **FR-024**: Every round reservation MUST cite the grant and the reset that opened the current window; every
  stop answer MUST cite its turn identity. An audit MUST join every authority record to a typed human turn and
  fail on any record without one.
- **FR-025**: No script or `!` command MAY be offered to the human as a way to approve.
- **FR-026**: Every branch that sees a standalone approval phrase and records nothing MUST report it in the same
  turn with its own reason (form unreadable, writer failed, origin unconfirmed, no pending crossing, boundary
  mismatch, stage evidence absent). The report MUST say in plain words what was looked for and what it was taken for, MUST check the
  store when it speaks, and MUST send the diagnosis to the drift record.
- **FR-027**: The report MUST use the visible-line channel (FR-029); on a host without one it MUST be a stop,
  recorded as a keep in the B5F-004 audit.

**C. Stops and confirmations (US4)**

- **FR-028**: Every stop and force-continue reason MUST be classified keep, drop or convert per the B5F-004
  table below, as ruled by the maintainer at specify, and implemented accordingly. Every block that remains
  MUST be capped on every host, including the navigator on Copilot, which has no cap today. The rc-current
  route (a passing review reaching the block branch) MUST be confirmed by a test and fixed if it is a defect.
- **FR-029**: Every turn that waits on the human MUST end with one line naming what to type. The check MUST
  supply a missing line and MUST NOT block. Each host's mechanism for adding a visible line MUST be verified;
  where a host can only add it by blocking, a drift entry MUST be recorded instead of blocking.
- **FR-030**: Crew guidance MUST go through the host's non-blocking context channel where it has one; any text
  a hook blocks with MUST be plain words written for a human, with no internal codes, and MUST pass the
  banned-noun check.
- **FR-031**: A workshop agenda or lens confirmation MUST cost one reply: "confirmed, with these changes" MUST
  either save against the amended text or have the crew apply the changes and save without asking again.
- **FR-032**: Every capture, review and CI refusal 203 touches MUST follow the refusal standard: what could not
  be completed, that the human's answers are safe where true, one recovery action, a request for approval;
  diagnosis in the drift record.

**D. Lifecycle (US6)**

- **FR-033**: A feature's claim MUST be released when its merge is observed, checked at session start and at
  every boundary sync, with a release record. It MUST NOT be released at the closeout approval.

**Rider: CI (US5)**

- **FR-034**: The census sweep MUST run as a required, sharded check on every pull request into main, with the
  same selection and exclusion list as the publish workflow; a test MUST assert that parity. No path filter.
- **FR-035**: The shard count MUST be sized against the account's concurrent-job limit so shards and lanes do
  not queue behind each other. The deterministic gate MUST stay as the Linux lane with all its steps; the
  Windows shards replace none of them, because a Linux run is not a duplicate of the Windows census run
  (maintainer ruling at the specify verdict). The Linux and macOS curated lanes MUST stay.
- **FR-036**: The census MUST select every `.ps1` under `tests/` except a reviewed list of non-suites; an
  unclassified file MUST fail the selection check. The 12 script-style suites the gate runs MUST join the
  census and also stay in the gate. Each of B4F-119's seven failing suites MUST be fixed or retired, with a
  record either way.
- **FR-037**: The deterministic gate MUST NOT depend on lint; lint MUST remain its own required check.
- **FR-038**: The coordinator fragment MUST pass lint (MD046); push lint MUST cover dot-directories (keeping the
  `.squad`, `.specify` and runtime exclusions); a test MUST lint the composed `.github/agents/squad.agent.md`;
  the interim `.markdownlintignore` entry MUST be removed.

**Journal (US7)**

- **FR-039**: A buffer flusher MUST skip a claim another flusher made recently and re-flush only a stale claim
  (its flusher gone, or past an age bound). The journal MUST hold exactly one line per append except for
  duplicates from a crashed flusher's claim, which are accepted.
- **FR-040**: The cause of the one-second lock wait on Linux CI MUST be measured (hold time and holder) before
  any change to the lock budget.
- **FR-041**: Every authority record, refusal and drift entry MUST carry the turn identity; review ones MUST also
  carry the campaign id. The degraded-journal health line on `specrew status` and `specrew where` stays.

**Test evidence**

- **FR-042**: Every mint path MUST have no-human-turn fault fixtures and non-approval phrase fixtures (quoted,
  in backticks, pasted), paired with a legitimate-path test. Cross-host tests MUST run through each host's real
  adapter with recorded real payloads, captured in scratch directories only, including a compaction between
  packet and reply.
- **FR-043**: Every budget economics invariant (FR-004, FR-006, FR-008, FR-009) MUST ship as a fixture written
  to fail first, through the shipped entry points.
- **FR-044**: The three-host walk (Claude, Copilot, Codex), manual with records, MUST include on each host: a
  verdict typed after a compaction; a review with at least one fix-needed round; a spent budget and a top-up;
  one disputed finding; one plan without a budget. It MUST record the stop reasons and the authorization count
  per boundary.
- **FR-046**: The Stop check MUST verify a boundary packet from the reply itself: it blocks only when the
  packet is absent or misses a decision-bearing part (the approval line, the boundary marker, the response
  options). A reworded content line MUST NOT block. Verifying the reply MUST be preferred over comparing it
  word for word with a second, separately authored copy of the packet (pres-declared and
  pres-boundary-packet, B5F-004).
- **FR-045**: Iteration 1 MUST end with a short Claude-only capture check, manual with records: a verdict
  typed after a compaction, a standalone approval phrase quoted mid-message, and one inside pasted content.
  The first is recorded once in its own turn; the other two record nothing.

### B5F-004 stop-reason audit

**Source**: a read-only census of the hook source (2026-10-31), from code, not runs. Blocks come from two
providers only, conformance and the co-review navigator, plus one dispatcher fallback, and reach Claude,
Codex and Copilot alike. Claude and Codex block only the first stop in a chain (`stop_hook_active`);
Copilot relies on the conformance cap of 3, and the navigator has no cap there.

**Rule** (ui-ux): keep a stop only if it protects authority or a decision the human must make. Authority
is protected where a record is written (the writer refuses); a Stop block that only makes the crew repair
something duplicates that refusal and is converted.
**Convert** means: crew guidance into the host's non-blocking context for the next turn, a supplied
visible line for the human, or a drift entry; the refusal at the writer stays.

| Reason | What triggers it | Proposed | Why |
|---|---|---|---|
| boundary | a crossing waits and the reply carries no packet for it | keep | the human's verdict is the decision |
| boundary-capture-miss | the human typed the approval phrase and it was not recorded | keep where no visible line; else convert | FR-026/FR-027: the human must re-type |
| evidence-absent (checked and absent) | a crossing waits and the bound tree lacks the stage's artifacts | convert | the verdict writer already refuses; its refusal joins FR-026 |
| evidence-absent (unverifiable) | the stage's evidence cannot be checked against the bound tree | keep | the writer does not refuse this case, so the block is the only guard |
| boundary-unrecordable | a boundary was reached and could not be recorded | keep | authority integrity; the human must know |
| pres-boundary-packet (decision parts) | the packet is absent, or misses the approval line, the boundary marker or the options | keep | the decision must reach the human |
| pres-boundary-packet (reworded content) | a content line of the packet is reworded in the reply | convert | not a block: the decision parts are present (fired 09:36 on 2026-10-31 over a reworded discussion line) |
| pres-declared | other declared lines are missing from the reply | convert | crew-only; supply or guide next turn |
| pres-workshop-agenda | the agenda was proposed but never shown | keep | the confirmation binds only to a shown agenda |
| workshop-conflict | two recorded workshop answers disagree | keep | the human decides which holds |
| wr-unreceipted | product answers have no typed-reply receipt | keep | the human must give the answer |
| wr-agenda-unconfirmed | a lens opened before the agenda was confirmed | keep | the human must confirm |
| wr-agenda-mismatch | records no longer match the confirmed agenda | keep | the human must re-confirm |
| wr-prescaffold, wr-product-not-persisted, wr-agenda-reformatted, wr-binding-name, wr-binding-value, wr-binding-unknown, wr-applicability-absent, wr-default | workshop record repairs the crew can make | convert | crew-only; the workshop writers already refuse |
| unauthorized-source | product source written before the before-implement approval | keep | protects the implement authority |
| in-flight-exhausted | in-flight declared more than 3 turns running | keep | the human decides whether to keep waiting |
| material-workshop | a workshop turn touched files outside the workshop records | convert | crew-only |
| material-undeclared | the worktree changed and no turn end was declared | convert | crew-only; the closing-line check supplies (FR-029) |
| material-token-mismatch | the declaration carries another session's token | convert | crew-only |
| cap-announce | the cap of 3 released a repeated block | convert | a visible line, not a fourth block |
| disp-withheld | a block reason could not be recorded safely | convert | a visible line |
| continue-directive | nothing produces it any more | drop | unreachable |
| orientation | its flag is never set | drop | unreachable |
| coverage-decision | review allowance exhausted and source moved past the last review | drop | replaced by stop (a) |
| pause-surface | a review pause is outstanding | keep | becomes the one surface of stops (a) to (d) |
| rc-human-decision | advisory findings need a human disposition | keep | stop (b) or (c) |
| campaign-gate-failed | review authority could not be read | keep, as stop (c) | fail closed; the human approves the repair |
| rc-required | no review covers the files; asks for `approved for review round` | drop | the per-round approval goes (FR-010) |
| rc-stale | the last review covers an older snapshot | drop | the next round runs within the budget (FR-005) |
| rc-actionable | the review has actionable findings | drop | fix-needed means fix, then the next round |
| rc-current | a passing review lands in the block branch | drop | appears to block on a pass; to confirm as a defect |
| legacy-blocking | legacy co-review blocking verdict | drop | superseded by FR-005 |
| rc-timeout, rc-partial | the last review timed out or finished partly | convert | infrastructure failure under FR-009 |
| rc-failure | about 14 invalid, missing or failed review-state messages | convert | infrastructure under FR-009; integrity under stop (c) |
| rc-pause-fallback | a pause is pending but its surface could not be built | convert | falls back to the stop surface under the refusal standard |

**Totals**: 41 reasons (39 reachable); evidence-absent and pres-boundary-packet are each split in two rows
at clarify, so 43 rows. Keep 15, convert 20, drop 8.

**Root cause of the declared-vs-reply blocks** (three on 2026-10-31: pres-declared at 08:43 and 09:27,
pres-boundary-packet at 09:36): the packet is authored twice, once declared to the turn-end script and once
in the reply, and the two are compared word for word, so any rewording of the second copy blocks. The
direction (FR-046) is to verify the reply itself at Stop for its decision-bearing parts rather than compare
it with a second authored copy. Of the review-related 13, two remain as stops (pause-surface,
rc-human-decision) plus campaign-gate-failed as stop (c). Ruled by the maintainer at the specify verdict.
The `declare-turn-end.ps1` refusals (unknown token, ambiguous session, unreadable or invalid draft) are
crew-only script refusals, not stops, and are not changed.

### Deterministic gate inventory (for FR-035)

The gate runs on `ubuntu-latest` (`.github/workflows/specrew-ci.yml`, job `deterministic-gate`). Besides
checkout, it installs the toolchain (Node 24, markdownlint-cli, uv, the specify CLI, the squad CLI) and runs
27 test steps:

| Group | Steps | In the census today? |
|---|---|---|
| Suites matching the census pattern | deploy-extension missing-source tolerance; FileList completeness; bootstrap resolver guard; the `tests/bootstrap/*.Tests.ps1` suite; task progress tracking; iteration state truth; version info states; boundary-sync markdownlint gate; version checks; module-path announce origin; managed runtime sidecar; managed-skill stuck-preserving; gate-stop skill; GitHub Actions Node runtime pins | yes (on Windows) |
| The same group, POSIX-relevant | `unix-resolver-path-semantics.tests.ps1` ("POSIX branch runs on this Ubuntu lane") | yes, but its POSIX branch only runs on Linux |
| Script-style suites outside the census pattern | `f198-regression-suite.ps1`; `manual/review-production-harness-dry-run.ps1`; bootstrap to iteration; bootstrap asset blocker recovery; brownfield conflict handling; validate versions CLI behavior; drift scenario; iteration resume; planning effort model; planning overcommit; process quality report; process quality scorer | no (they join the census under FR-036) |

The contract lane (`needs: deterministic-gate`) runs `validation-contract-lane.ps1` and the start-command
first-run regression. **Ruled at the specify verdict**: the gate stays as the Linux lane with all its steps;
the Windows shards replace none of them; the 12 script-style suites join the census and stay in the gate.

### Traceability & Governance Requirements *(mandatory)*

- **TG-001**: Each user story MUST map to one or more functional requirements (table below).
- **TG-002**: Each requirement MUST identify expected owner role(s) (table below).
- **TG-003**: Each requirement MUST identify intended iteration or delivery window (table below; the plan
  confirms the split).
- **TG-004**: Any known spec/implementation conflict MUST include an explicit reconciliation path. Known:
  - 202's one-slot grant and per-round approval, superseded by FR-003, FR-004 and FR-010;
  - 202's round budget default of 4, superseded by FR-001 and FR-008;
  - 202's `beta4-line-sync` rule, replaced by the main-sync-before-implement-packet rule;
  - B4F-158's fix direction, of which only the gating half is in scope.

| Story | Findings | Requirements | Owner roles | Iteration (proposed) |
|---|---|---|---|---|
| US1 | B4F-115, B4F-121, B4F-061, B4F-126, B4F-152, B5F-012, B4F-054, B4F-058 | FR-001 to FR-013, FR-043 | Implementer; Reviewer (codex); maintainer for the walk | 1 |
| US2 | B4F-112, B4F-116/150, B4F-117, B4F-140/137 | FR-014 to FR-025, FR-042, FR-045 | Implementer; Reviewer (codex); maintainer for the Claude capture check | 1 |
| US3 | B4F-151, B4F-112 | FR-026, FR-027 | Implementer; Reviewer | 1 |
| US4 | B5F-004, B5F-011, B5F-012 | FR-028 to FR-032 | Implementer; maintainer rules the audit table | 2 |
| US4 (part) | B5F-004 (declared-vs-reply blocks) | FR-046 | Implementer | 1 (maintainer, clarify verdict) |
| US5 | B5F-013, B5F-015, B4F-079, B4F-119, B4F-158 | FR-034 to FR-038 | Implementer; maintainer rules the gate inventory | 2 |
| US6 | B5F-014 | FR-033 | Implementer; Spec Steward | 2 |
| US7 | B4F-142 | FR-039 to FR-041 | Implementer | 2 |
| all | measures (a) to (f) | FR-044 | Maintainer (walk); Implementer (records) | 2 closeout |

### Key Entities

- **Review budget (plan)**: rounds and reviewer host order as the plan states them.
- **Review grant**: the snapshot of the budget taken at the before-implement verdict, citing it; holds
  `budget_total` and the host order.
- **Round reservation**: taken before a reviewer is invoked; cites the grant and the latest reset; spent on
  invocation or released before it.
- **Budget-reset fact**: the top-up; moves the counting origin; minted from a typed turn.
- **Pause fact**: one of the four stop conditions; the only thing that stops the human in a review.
- **Typed turn identity**: the host message id, or the explicit per-host substitute.
- **Supersession fact**: retires an older unspent act of the same kind.
- **Pending-crossing record**: the durable record of the boundary waiting for a verdict.
- **Claim release record**: written when a merged feature's claim is released.
- **Census selection**: the census suite set plus the reviewed non-suite list.

## Success Criteria *(mandatory)*

### Measurable Outcomes

In priority order (b, a, c, d, f, e). `assumed` until the three-host walk measures them.

- **SC-001 (b)**: 0 authority records without a joined human typed turn, in the audit over the walk and the
  fixtures; 0 mints from the non-approval phrase fixtures and the no-human-turn fixtures.
- **SC-002 (a)**: 0 re-types on the walk: every typed approval is recorded with its own turn identity by the
  end of that turn, including a verdict typed after a compaction on each host.
- **SC-003 (c)**: 0 false "not recorded" reports on the walk and in the fixtures.
- **SC-004 (d)**: 0 review stops on the walk outside budget spent, dispute or deferral, judgment call, and host
  outside the order.
- **SC-005 (f)**: on the walk, a review boundary costs at most the sign-off verdict plus one approval per top-up
  (baseline: six per boundary, B4F-061); every workshop confirmation costs one reply.
- **SC-006 (e)**: 0 census-failable tests missing from the pull request checks, by the parity test.
- **SC-007**: case (e) of the journal fault suite shows an exact line count on Windows, macOS and Linux in every
  CI run from the fix to the 203 closeout.
- **SC-008**: after 203's merge is observed, 0 merged features' claims remain in the active-features record.
- **SC-009**: the validator run at closeout shows no new failures in the known-baseline categories.

## Assumptions

- The stack is unchanged: PowerShell 7.x, Markdown, YAML, JSON, GitHub Actions YAML. No new dependency
  (code-implementation).
- The craft rules are inherited from 202 with the 203 changes in `implementation-rules.yml`; main is merged in
  before each before-implement packet, never after the approval.
- The existing layered hooks plus the review campaign fact store are kept; no new subsystem
  (architecture-core).
- The repository is public, so CI cost is wall-clock, not minutes.
- Per-host facts are `research-needed` and load-bearing for FR-015 to FR-017 and FR-029: the user-prompt
  event's message id, pasted-content delivery, and the visible-line mechanism (Claude has `systemMessage`;
  Copilot and Codex to be checked). They are answered before the plan fixes the mechanism.
- Copilot's token reporting is `research-needed`, not load-bearing.
- Copilot also runs the Claude hooks, so hook changes affect both hosts.
- Reviews run on codex in disposable external worktrees; its file-delivery quirk is not a review failure.

## Governance Alignment *(mandatory)*

- **Spec Steward**: the spec-steward role. The maintainer owns scope.
- **Iteration Facilitator**: the coordinator session for 203, under the maintainer's boundary verdicts.
- **Capacity Model**: two iterations (maintainer ruling at the specify verdict): (1) authority core, US1 to
  US3, plus FR-046 (moved at the clarify verdict), ending with the Claude-only capture check (FR-045); (2) stops, CI rider, lifecycle and journal, US4 to
  US7, ending with the three-host walk (FR-044). The plan sets the effort model.
- **Drift Signals**: the feature drift log from plan onward; workshop bindings reconciled across lenses; the
  validator against the known baseline; continuous co-review within the approved budget.
- **Human Oversight Points**: every lifecycle boundary needs an explicit typed `approved for <boundary>`. The
  before-implement verdict approves the review budget. The four review stops are the only in-review human
  stops.
