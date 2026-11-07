---
proposal: 217
title: Companion Reviewer Session and Bounded Delegated Driving
status: candidate
phase: phase-3
estimated-sp: 31-48
priority-tier: 2
discussion: maintainer design conversation 2026-11-07 during Feature 203 (beta5 stabilization) - "when I develop Specrew I always use another agent as assistant and reviewer... how can I have it as a built in option or a methodology of Specrew?"; extended the same day - "the assistant has to be the one that always sees the big picture, while the crew sees the task at hand", "the assistant needs to explain to the human more about the status, process, decisions and implications", bounded autonomy - "have a reviewer, and then give it a period of auto driving mode, should be the correct way", and delegated crossings - "the boundary is signed by the driver on behalf of the human with the consent the user gave".
---

# Companion Reviewer Session and Bounded Delegated Driving

## Why

The maintainer develops Specrew with two agent sessions, not one. The **crew** session builds; a
second **companion** session tracks it, verifies its claims against the code and the disk, explains
to the human what each report means, recommends one course of action, and drafts the messages the
human sends back. The human stays the only relay and types every approval in the crew session. This
is an informal practice today. Specrew neither knows about it nor supports it.

### Separation of concerns

The two sessions see the work at different distances, and that difference is the point:

| | Crew | Companion |
|---|---|---|
| Sees | The task at hand: the files, tests and commands of the current task | The big picture: spec, plan, ledger, drift, standing rules, other features and branches, release gates |
| Optimises | Getting the task done | Keeping the feature, the process and the human's decisions sound |
| Talks to the human about | What it did and what it needs | What the position is, what it means, what each option leads to |
| Holds authority | None beyond its task | None of its own. It advises, and acts only on authority the human delegated |

A builder deep in a task has every reason to accept a premise that lets the task finish. A companion
whose only job is the whole picture has no such reason. Proposal 211 makes the same argument for one
stuck gate; this proposal makes it for the whole session.

### Empirical motivation (Feature 203, iteration 001, 2026-11-01 to 2026-11-07)

- **A baseline that cleared the builder's own work was checked.** After a full test run the crew
  reported that the one red suite (`validate-governance-changed-only`, B5F-033) "was already red
  where this branch left main" and asked to file it under T013. It had run the suite on `5bca4fdf`, a
  local `main` checkout stale since June: 1,820 commits behind the branch, with a suite file 84 lines
  different. The real fork point, `git merge-base HEAD origin/main`, is `df1141a8`; since then the
  suite and the validator are unchanged but three engine scripts the validator loads are not. The
  companion found this with three git commands and no rerun, before the placement was approved. The
  crew had honestly marked the comparison "not established"; the error was in an unstated premise,
  and the builder had no reason to doubt a premise that cleared its own work. Rerun on `df1141a8`,
  the suite passed: B5F-033 is a 203 regression, which the stale baseline would have filed as
  pre-existing breakage under an unrelated task.
- **A weaker option was caught before it was chosen.** On T005 (verdict pairing) the crew offered
  three options; the companion checked them against
  `scripts/internal/bootstrap/ConversationCaptureAccessor.ps1` and proposed a fourth (pair the prompt
  event only when the reply names the target boundary and the packet was shown in this session). The
  crew's own check then found the companion's premise incomplete (a bare `approved` still passed).
  The settled design was better than either side's first answer.
- **A compaction hole was found in a correction.** The crew's third correction relied on
  `presented-crossings.json`, which is cleared on every SessionStart, including compaction. The
  companion found it; the crew fixed it with a capture-only `shown-crossing.json` that survives one.
- **The companion also missed things.** The from-boundary bug in `HumanAuthorityStore.ps1`
  (`$_ -ceq $to -or $_ -ceq $from`) was the crew's catch, not the companion's. The value is two
  independent readings, not an infallible reviewer.
- **The human needed explanation, not just reports.** Crew reports are accurate but task-shaped:
  a repeated Stop-hook message asking for a review round, a decision to place a finding under a task,
  a sweep summary of 452 files. The maintainer relied on the companion to say which messages need
  nothing from them, what a decision changes, and what it costs to get wrong.
- **The relay loses data.** Pasted crew messages lost characters; the companion had to parse the
  crew's transcript JSONL with scratchpad scripts to recover exact text. The B5F-033 catch needed
  git access to the same repository, which a paste cannot carry.
- **The companion session is not inert.** It runs in the project folder, so it loads the project's
  `CLAUDE.md` (written for a builder) and receives the full Specrew hook set: SessionStart
  orientation, `[specrew-turn]` tokens, prompt-event markers, and the advisory "another session may
  be active in this worktree". In one turn the hook handed it a turn token that an earlier turn had
  already consumed, so its turn-end declaration was refused. Nothing structurally stops a verdict
  typed into it from being captured as an approval.
- **"You decide" goes to the builder.** In the design workshop the maintainer sometimes answers
  "you decide" on low-risk questions. Today the agent that builds is also the one that decides.

### The Autopilot model

The maintainer's framing: the human sets goals, vision and constraints, reviews and steers, and
carries the responsibility, but can engage a bounded "auto-driving" period. Autopilot is trustworthy
not because it drives well but because it is unambiguous about **when it is on, where it may operate,
how the human takes over, and when it hands back**. Pillars 5 and 6 make those four properties
mechanical.

| Autopilot | Specrew mechanism |
|---|---|
| Engage | A typed grant naming the stretch, the boundaries the driver may sign, a token budget and the stop point (Pillar 5) |
| Where it may operate | Only the stages and boundaries the grant names; some boundaries can never be delegated (Pillar 5) |
| Hands-on-wheel nag | A status digest at a fixed cadence (Pillar 6) |
| Instant takeover | Any typed human message pauses the driver at the next safe point (Pillar 5) |
| Automatic disengage | The hard-stop list (Pillar 5) |
| Driver responsible | The end review over the decision log, with every delegated crossing reversible (Pillar 6) |

### The authority rule does not change

Every boundary is still authorized by the human. What changes is how that authority can reach the
crew: today only as the human's typed reply; with this proposal also as a crossing the driver signs
**on the human's behalf, under a grant the human typed**. For the crew this is a second recorded
kind of authority, not a different rule. The crew never decides whether delegation is allowed; it
recognizes either kind of authority in the ledger. The companion's own charter, not the crew's, is
where signing under a grant is permitted.

## What - Six Pillars

Three levels, each a prerequisite for the next:

- **Level 1 - Assist** (Pillars 1 to 3): the companion holds the big picture, checks the crew and
  briefs the human; the human relays everything.
- **Level 2 - Delegate** (Pillar 4): "you decide" routes to the companion and is recorded as
  delegated.
- **Level 3 - Drive** (Pillars 5, 6): the companion drives a granted segment, signing the boundaries
  the grant names on the human's behalf, and stops at the grant's stop point.

### Pillar 1 - Companion session in its own folder

- `specrew companion` (or `specrew start --companion`) creates or reuses a companion folder outside
  the project (for example under `~/.specrew/companions/<project-id>/`) and opens the companion
  session **there**, not in the project folder, on a host and model the human chooses (a different
  model family from the crew by default, per Proposal 102).
- The companion folder holds the companion's own instruction file (`CLAUDE.md` / `AGENTS.md` for the
  host): the companion charter, the path of the project it tracks, and the authority rules for each
  level. It holds no Specrew project hooks.
- This makes the companion inert by construction: the project's hooks never fire in it, its turns
  never reach the crew's capture readers, and the builder instructions in the project's `CLAUDE.md`
  never load into it. No code has to filter companion sessions out of verdict capture. As defense in
  depth, the capture readers also refuse a prompt event whose session is a registered companion.
- The companion reads the project by path and writes no project file except through the signing
  command of Pillar 5. Its notes and drafts live in its own folder.

### Pillar 2 - Read-only crew feed and repository access

- A structured, read-only view of the crew session: recent turns (verbatim, not pasted), the last
  rendered packet, `.specrew/runtime/pending-verdict-stop.md`, `start-context.json`, iteration
  `state.md`, `tasks-progress.yml`, new drift entries and commits since the last read.
- Exposed as a command (`specrew companion feed --project <path> --since <cursor>`) so it works on
  every host, with an optional host-native notification where the host supports one.
- Read access to the repository itself (git history, the working tree, other branches), because
  premise checks such as a merge base cannot be done from a feed.
- No write path from the companion into the crew session. The human remains the only relay at
  Level 1 and Level 2.

### Pillar 3 - The big picture and the human briefing

The companion charter makes two duties explicit:

- **Hold the big picture.** For every crew report the companion checks the claims against disk and
  git, and checks the report against the whole feature: the spec and its FRs, recorded design
  decisions, the verdict ledger, standing rules the human has given (push permission, home-directory
  writes, commit timing), other in-flight features and the release gates. It names unstated
  premises (which base commit, which home, which engine copy) and checks them.
- **Brief the human.** Each relayed report is turned into: where the feature stands; what changed
  and what it means beyond the current task; whether anything is being asked of the human (and, as
  often, that nothing is); the options with what each leads to and what it costs to reverse; one
  recommendation; and, when the human should reply, the exact message to send. Process mechanics
  (why a hook fired, why a phrase must be typed in a certain place) are explained in plain words
  when they come up, matched to the human's profile dials.

### Pillar 4 - Delegated decisions (Level 2)

- When the human answers a workshop lens, a design-decision prompt or an in-phase crew question
  with a delegation ("you decide", "companion decides"), the question is routed to the companion,
  not answered by the crew.
- The companion's answer is recorded through the existing machinery (`record-design-decision.ps1`,
  `design-decisions.json`) with provenance `human-delegated`, `delegate: companion`, the rationale,
  the evidence it read, and a reversal cost, and carries Proposal 053's visible marker.
- Level 2 delegation never covers a boundary, a release or publish step, or a write outside the
  project. Those questions go back to the human.
- Every delegated decision appears in the next digest (Pillar 6) for the human to confirm or reverse.

### Pillar 5 - Driving grant and delegated crossings (Level 3)

- The human types a grant in the crew session, for example
  `grant companion drive specify to before-implement, budget 3M tokens, stop at review-signoff`. The
  grant is a typed act (same capture rules as a verdict), scoped to one feature, and stored with its
  stages, the boundaries the driver may sign, its budget and its stop point. It rides Feature 203's
  single-grant budget model (T007/T008) rather than adding a second budget system.
- Within the grant the companion answers the crew's in-phase questions directly, through a
  sanctioned channel (not by typing into the crew console), and every answer is logged.
- **Delegated crossings.** At a boundary the grant names, the driver signs the crossing on the
  human's behalf, under five rules:
  1. **Named in advance.** The driver may sign only a boundary the grant lists.
  2. **The normal crossing, reviewed.** The crew renders the full packet and every gate check runs.
     The companion reviews the packet against the big picture (Pillar 3) and stores its review. A
     failing check, an open contradiction with the spec or a recorded decision, or a review the
     companion cannot pass stops the drive and hands it to the human; the driver never signs over
     one.
  3. **Honest provenance.** The ledger entry records `kind: delegated`, the human as authorizing
     human, the companion as signer, the grant id and a link to the stored review. Every reader
     (validators, packets, the end review) can tell a delegated crossing from a typed one, and none
     presents a delegated crossing as typed by the human.
  4. **Never delegable.** Feature closeout, merge to `main`, opening a PR, publish or release, and
     any write into the human's home (hooks, profiles) are never signed by the driver, whatever the
     grant says. Review sign-off is the default stop point; a grant can include it only by naming
     it.
  5. **Reversible.** At the end review the human can reverse any delegated crossing, which reopens
     that stage through the existing correction history.
- **Takeover:** any message the human types in either session pauses the driver at the next safe
  point (the end of the current task step) and reports where it stopped.
- **Automatic disengage** on any of: budget spent; the same gate failing twice; a request for a
  never-delegable action; a decision outside the granted scope; a contradiction with the spec or a
  recorded design decision; the companion and the crew disagreeing twice on the same question.
- A grant expires at its stop point, on disengage, or at session end. It never renews itself.

### Pillar 6 - Digest and decision log

- A status digest at a fixed cadence (every N tasks, every slice of budget, and after every delegated
  crossing): position, tasks done, boundaries signed on the human's behalf, decisions made, budget
  used and remaining, and anything the companion is unsure of. Short enough to read at a glance;
  Pillar 3's briefing rules apply.
- A decision log (append-only, per grant) recording every delegated decision and crossing with its
  assumption, evidence, alternatives rejected and reversal cost. The log is the input to the end
  review and is presented with the stop-point packet.

## How

Suggested slicing, each slice shippable alone:

1. **Slice A - Level 1 (8-12 SP):** the companion folder, launcher and charter (big picture and
   briefing duties); the defense-in-depth refusal in the capture readers; the read-only feed.
   Proven by a test that a verdict typed in a companion session records nothing and says why, and by
   walk scenarios (Proposal 213) where the companion must catch a seeded false premise.
2. **Slice B - Level 2 (5-8 SP):** delegation routing for workshop lenses and design decisions;
   `delegate: companion` provenance; the digest. Proven by a workshop run where a delegated lens is
   answered by the companion and appears in the digest.
3. **Slice C - Level 3 (18-28 SP):** the grant typed act; the sanctioned companion-to-crew answer
   channel; the signing command and a `delegated` evidence source that the verdict readers and
   boundary-sync scripts accept only with a live grant naming that boundary and a stored companion
   review; the one-sentence addition to the crew's launch contract and `CLAUDE.md` (the next stage
   begins after the human's typed approval **or a delegated crossing recorded under the human's
   grant**); takeover, the disengage list, reversal through the correction history; the decision
   log and the stop-point review. Run first as a controlled experiment on a small feature: one
   segment driven, compared with the same segment human-relayed, then progressively longer grants.
   This absorbs Proposal 041's experiment (pass rate by grant scope rather than by fixed autopilot
   level). The "software factory" (a whole feature under one grant) is the end of that progression,
   not its start.

Sequencing: Slice A touches the capture readers that Feature 203 is reworking, and Slices B and C
depend on 203's typed-act machinery (T004) and budget model (T007/T008). Implementation starts after
Feature 203 merges. Until then the practice continues manually, and its catches and misses are
recorded as evidence for this proposal.

## Acceptance criteria

- **AC1** The companion session runs from its own folder, loads its own instruction file and none of
  the project's hooks; a verdict or grant typed in it records nothing in `start-context.json`,
  `verdict_history`, the typed-act store or `design-decisions.json`, and the companion says where
  approvals are typed.
- **AC2** `specrew companion feed` returns the crew's turns verbatim, the pending stop and the state
  files, and writes nothing.
- **AC3** In walk scenarios with a seeded false premise in a crew report (a stale base commit, a
  wrong home, an out-of-date engine copy), the companion names the premise and checks it before the
  human is asked to decide.
- **AC4** Every companion briefing of a crew report states the position, whether anything is asked
  of the human, and, for each option offered, its consequence; checked by a briefing-shape validator
  over recorded companion turns.
- **AC5** A delegated workshop answer is recorded with `provenance: human-delegated` and
  `delegate: companion`, carries the 053 marker, and appears in the next digest.
- **AC6** A grant without stages, a budget or a stop point is refused.
- **AC7** A delegated crossing is recorded with `kind: delegated`, the authorizing human, the
  companion as signer, the grant id and the review link; no packet, validator or report presents it
  as a typed human approval.
- **AC8** The signing command refuses a boundary the grant does not name, a never-delegable
  boundary or action, a crossing whose gate checks fail, and a crossing with no stored companion
  review; one test per refusal.
- **AC9** The crew advances on a delegated crossing exactly as on a typed approval, and on nothing
  else.
- **AC10** Each disengage trigger, and a typed human takeover, stops the driver at the next safe point
  with a report; one test per trigger.
- **AC11** The human can reverse a delegated crossing at the end review, which reopens that stage
  through the correction history.
- **AC12** The decision log lists every decision and crossing made under a grant, and the stop-point
  packet links it.

## Out of scope

- Delegating feature closeout, merge to `main`, PRs, publish or release, or home-directory writes.
- Project-wide or standing autonomy settings: every delegation is a typed grant for one feature, with
  a budget and a stop point. (Proposal 100's `autonomous` mode is re-expressed as a grant.)
- The companion typing into the crew console or editing project files other than through the
  signing command.
- Multi-human teams (one human, one crew, one companion).
- Unattended, multi-feature runs.

## Composition

| Proposal | Relationship |
|---|---|
| [041](041-specrew-autopilot.md) Specrew Autopilot | **Absorbed; 041 withdrawn.** 041's boundary auto-progression becomes delegated crossings under a scoped, recorded grant, and its experiment becomes Slice C's measured progression of grant scopes. 041's safety-critical list becomes the never-delegable list. |
| [100](100-friction-dial.md) Friction Dial | Amended in step with this proposal: its `autonomous` mode is re-expressed as a 217 grant, so Specrew has one autonomy mechanism; its `strict` and `default` verdict-acceptance modes are unaffected. |
| [066](066-gate-respecting-default.md) Gate-Respecting Default + `--autonomous` | Shipped; unchanged by this proposal. A later post-ship amendment may make `--autonomous` shorthand for a grant. |
| [053](053-autopilot-decision-transparency.md) Autopilot Decision Transparency | Mechanism reuse. Decisions made under delegation or a grant carry 053's visible marker and ledger flag, distinguishing `delegated` (the human handed it over) from `auto-resolved` (nobody answered). |
| [040](040-token-economy-governance.md) Token Economy Governance | The grant budget is a token budget; 040's cost guardrails apply to companion and crew together. |
| [102](102-cross-model-independent-reviewer.md) Cross-Model Independent Reviewer | The companion defaults to a different model family from the crew for the same independence reason. |
| [139](139-multi-agent-subagent-orchestration.md) Multi-Agent Subagent Orchestration | Infrastructure neighbour. The companion is a peer session, not a subagent: it survives the crew's compactions and keeps its own context. |
| [145](145-structured-multi-phase-reviewer.md) / [197](197-continuous-co-review.md) Structured Reviewer / Continuous Co-Review | Review per gate (145) or per edit (197); the companion reviews the process and the crew's decisions across a whole session, and its packet review is the precondition for a delegated crossing. |
| [211](211-process-advisor-agent.md) Process Advisor | Same conflict-of-interest argument. 211 never writes a consent artifact; the companion writes one only as a delegated crossing under a typed grant, with provenance that says so. |
| [212](212-reading-validation-at-human-gates.md) Reading Validation at Human Gates | The digest and the stop-point review are where reading validation applies to delegated work. |
| [213](213-assert-walk-harness.md) Walk Harness | AC3 and the Slice C experiments are walk-harness scenarios (seeded premise, grant, delegated crossing, disengage, takeover). |
| Feature 203 T004 / T007 / T008 | Depends on the typed-act machinery (T004) and the single-grant budget model (T007/T008). |

## Risks

- **A delegated crossing read as a human approval.** Specrew has fabricated approvals before
  (DEC-198-GOV-003, the disabled markerless fallback). Mitigation: a distinct `delegated` evidence
  source accepted only with a live grant and a stored review (AC7, AC8), and every human-facing
  surface labels delegated crossings.
- **Rubber-stamp drift.** A human who trusts the companion stops reading. Mitigation: digests list
  each delegated crossing and decision with reversal cost; review sign-off is the default stop point.
- **Shared blind spots.** Two agents can agree on a wrong premise (the companion's incomplete T005
  premise). Mitigation: different model families by default; disagreement is a disengage trigger,
  not something either side resolves alone.
- **Over-explaining.** A briefing longer than the crew report defeats its purpose. Mitigation: the
  briefing follows the human's profile dials and leads with whether anything is asked.
- **Budget overrun.** Mitigation: the grant budget is enforced by the 203 budget model, not by the
  companion's own accounting.
- **Scope creep in grants.** Mitigation: grants are scoped to one feature, name their boundaries and
  expire at the stop point; there is no renewal without a new typed grant.

## Status history

- 2026-11-07 - `candidate`. Drafted from the maintainer's design conversation during Feature 203,
  with the companion practice of that feature as the evidence. The same day the maintainer ruled
  that a driver may sign boundaries on the human's behalf under a typed grant, and that the
  companion runs from its own folder with its own instructions; Proposal 041 withdrawn as absorbed
  and Proposal 100's `autonomous` mode re-expressed as a grant. The B5F-033 rerun on `df1141a8`
  passed, confirming the regression the companion's premise check exposed.

## Cross-references

- [INDEX](INDEX.md)
- [Proposal discipline](../docs/methodology/proposal-discipline.md)
- Feature 203 evidence (on branch `203-beta5-stabilization`): `docs/beta5-findings.md` (B5F-032,
  B5F-033), `specs/203-beta5-stabilization/design-decisions.json`,
  `specs/203-beta5-stabilization/iterations/001/drift-log.md`
