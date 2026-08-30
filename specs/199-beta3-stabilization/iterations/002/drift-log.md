# Drift Log: Iteration 002

**Schema**: v2

<!--
  Markdown authoring note (Specrew lifecycle convention):

  When you add new drift events to this file, watch for MD032 (blanks-around-lists).
  A sentence ending with a colon, immediately followed by a bullet list, is the most
  common violation. Always put a BLANK LINE between the colon line and the list.

  The F-033 pre-boundary markdownlint gate runs markdownlint-cli --fix on .md
  changes before every boundary-sync write, so most violations auto-fix — but the
  blank line you write in the first place avoids the cleanup churn.
-->

## Summary

**Total drift events**: 34 (DRIFT-199-I002-001 through -034)
**Resolution rate**: carried per event in its heading (11 resolved by this iteration's requirements,
instrumentation, a same-session fix, or - for -014 - the withdrawal of a wrong finding; 2
spec-updated/human-decision; 2 deferred to beta4 by ruling or scope). The two that blocked the covering round
are both cleared: -014 was withdrawn as a mistaken diagnosis and its 19 real entries re-stamped, and -015 was
resolved by re-pointing the verification plan and dispositioning iteration 001's concerns in an erratum
outside its seal.
**Specification drift**: one spec amendment, recorded as DRIFT-199-I002-002

## Events

### DRIFT-199-I002-001 — TB-1 and TB-6 reproduced live on the shipping tree at 001's closeout (resolved-by FR-024, FR-032)

**Recorded verbatim from the maintainer, 2026-08-29, watching it happen:**

> TB-1 fired live. The closeout capture immediately minted crossing-6f2f32905a4eb56
> (iteration-closeout → plan) at commit 2d758a21, while
> specs/199-beta3-stabilization/iterations/ still contains only 001/ — no 002 directory, no
> plan.md, no design-analysis.md. A crossing demanding approved for plan exists over a stage
> with nothing in it, exactly as at 928c76e. It was also rendered into the reviewer session,
> which produced none of it — TB-6, in the same breath. Both recommended tag-blockers
> reproduced themselves on the shipping tree at the next boundary after being catalogued.
>
> Had the reviewer session rendered the options as its hook instructed, I was three retries
> deep and one paste away from authorizing a plan boundary over an empty directory. That is
> the argument for TB-1 half 2 and it is no longer theoretical.
>
> [TB-6] is not "the wrong session gets asked once" — it fires on every Stop, every turn,
> regardless of topic, for as long as any crossing is open, so a second session cannot hold an
> ordinary conversation in a governed project. It shares its design question with TB-1 and
> item eight: is this actor the one that owes this?

- **Observed, measured by the working session**: at 10:24:30Z the Stop hook wrote the
  `retro -> iteration-closeout` authorization (verdict 8) and in the same second minted
  `iteration-closeout -> plan` (`crossing-6f2f3290...`, commit `2d758a21`, tree `90be7bff`,
  `Multi-boundary gap: true`), then instructed this session to render the packet with the plan
  marker. The stage-evidence read was *unverifiable* - no iteration identity in the bound tree -
  which does not suppress the demand: the carve-out TB-1 turns on. The working session withheld
  the marker by hand under FR-024 half 2 and did the plan stage's work instead. This is not a
  reconstruction from a prior walk; it is a reproduction on the tree that ships, with the
  maintainer watching, one turn after the fix was designed.
- **Rebind or re-mint, determined from source rather than assumed**: the plan sync re-mints.
  `Set-SpecrewPendingBoundaryCrossingScope` derives `artifact_state_id` from the commit it is
  given (HEAD at sync time), builds a new identity through `New-SpecrewBoundaryCrossingIdentity`,
  and replaces `pending_crossing` with it; only when the new identity equals the existing
  `crossing_id` is `recorded_at` preserved. So once the tree carries iteration 002's artifacts and
  the plan sync runs, `crossing-6f2f3290...` is superseded by a new identity bound to the new
  commit and tree - never approved, never rebound. One consequence worth its own line: the
  verdict marker text is the same for both identities (`iteration-closeout -> plan`), so a marker
  rendered against the empty-stage crossing would still have captured against its successor;
  withholding it was the only safe act.
- **Citation**: FR-024 (mint gate and withhold), FR-032 (the owing actor); the crew brief's TB-1
  (KeyContextAI iteration 003, three crossings at `928c76e`).
- **Resolution**: fixed in this iteration - the live-filesystem mint gate at all three minting
  mechanisms, the packet re-mint guard, the withhold discipline stated once and mirrored
  everywhere (FR-024); the crossing record carries its owning session and the Stop-hook demand
  fires only there (FR-032).
- **Class closure**: the three share one rule - the actor that produced an arrival owes its
  packet, its mirrors and its evidence, and ownership is recorded with the artifact. Mutations:
  the ladder replays when the mint gate is removed; a second session's Stop demands a packet when
  the owner check is removed.

### DRIFT-199-I002-002 — the spec grows FR-024..FR-033 for the tag batch (spec-updated, human-decision)

- **Observed**: 2026-08-29, at the opening of iteration 002. The ten batch items (seven from two
  field walks, item eight from DRIFT-199-I001-152, item nine from the first sealed closeout, item
  ten - TB-6 - from DRIFT-199-I002-001) are not in spec.md's FR-001..FR-023, and the plan's spine
  is FR-to-task traceability.
- **Citation**: TG-004 - scope is closed "unless it blocks the acceptance bar itself; the
  reconciliation path ... is a drift-log entry citing the governing FR plus a maintainer ruling".
- **Ruling**: the maintainer accepted the report (2026-08-29), added item eight, ruled the split of
  TB-3, the class scope of item eight, the merged F-1/B-6 writer, the TB-4 sibling reader, item
  nine and item ten, and ruled the six remaining items and the UX programme to beta4.
- **Resolution**: spec-updated - User Story 8, FR-024..FR-033, SC-011..SC-020, TG-003 and TG-004
  amended in file:///C:/Dev/specrew-beta3-stabilization/specs/199-beta3-stabilization/spec.md.
- **Class closure**: NONE - a spec amendment under TG-004's own exception is the governed path,
  not a defect.

### DRIFT-199-I002-003 — the closeout seal is written before the dashboard it seals (resolved-by FR-031)

- **Observed**: 2026-08-29, at iteration 001's closeout, the first closeout under the W51 seal.
  `sync-boundary-state.ps1` runs index -> seal -> dashboard render; `dashboard.md` carries a
  `Captured At` timestamp, so the re-render always changes bytes and the seal never matches. The
  validator then refused the closeout it had just produced (`closed-iteration-edited:
  dashboard.md`), and the background full validation printed that one finding 253 times.
- **Citation**: the seal's own contract ("written LAST at iteration-closeout, after every record
  has landed"); W77's class (a sync's own write refused by its own gate).
- **Recovery taken**: re-sealed through `Write-SpecrewIterationSeal` after the render;
  `Test-SpecrewIterationSealIntegrity` clean; recorded in 001's retro rulings.
- **Resolution**: fixed in this iteration under FR-031 (maintainer ruling: "guaranteed, not
  conditional ... every tester's first closeout fails").
- **Class closure**: the seal becomes the closeout sync's last write, with a test asserting the
  seal hashes the rendered dashboard.

### DRIFT-199-I002-004 — a verdict behind a leading quote bar is classified as discuss, silently (resolved-by FR-010, this iteration)

**Recorded with the weight the maintainer assigned it, 2026-08-29:**

> It bit me directly. My approved for iteration-closeout failed because the verdict was pasted
> with a leading quote bar, and nothing said so until the recap. A silently-ignored authorization
> phrase is DRIFT-012's shape and it cost two retries. Give it the same weight as the others.

- **Observed**: the maintainer's closeout verdict began with the terminal quote bar `▎` and then
  `approved for iteration-closeout — ...`; `Test-SpecrewHumanVerdictToken` returned
  `Action=discuss, IsApproval=False` because the leading-approval-phrase rule saw the bar first
  and the discuss clause then matched "Prompt 1:". No refusal, no journal line; the Stop capture
  would have fallen back to the already-recorded retro pair. The retro verdict had captured only
  because its first line carried no bar. The working session caught it with a read-only check and
  asked once for the bare phrase - two retries for the maintainer, the recap being the first
  place anything said so.
- **Citation**: FR-010 and User Story 3 ("the maintainer's verdicts always capture") - an existing
  requirement of this feature, so the fix traces to FR-010 and needs no new requirement; W54's
  class and DRIFT-012's shape (the silently ignored near-miss authorization phrase).
- **Resolution**: fixed in this iteration as an FR-010 defect: when a verdict-shaped turn is not
  captured, the capture says so and names what it received and what would capture (SC-020). The
  recognizer is not widened.
- **Class closure**: silent fallback to an older pair is the defect, not the classification; the
  leading-quote-bar turn is the pinned fixture.
- **Second instance, same day**: the plan verdict of 2026-08-29 was typed as `approved for plan -
  three instructions.` after four paragraphs that began "Don't confirm prompt 1's map as
  written"; `Test-SpecrewHumanVerdictToken` returned `Action=send-back, IsApproval=False` - the
  leading text, not the phrase, decided the classification, and again nothing said so. The
  maintainer had written "bare phrase first, no quote bar" and put it first among the verdict
  lines rather than first in the message. Second pinned fixture for T024: leading prose before the
  phrase; the disclosure names the classification and the leading text.

### DRIFT-199-I002-005 — one repo-level validator finding printed once per validated iteration (deferred, beta4)

- **Observed**: 2026-08-29. The trust-hardening `closed-iteration-edited` finding was printed once
  per iteration validated - 153 lines describing one fact.
- **Citation**: the refusal standard (B-4.1), inverted: naming every instance of something that
  has one.
- **Resolution**: deferred to beta4 with the refusal standard (maintainer ruling 2026-08-29).
- **Class closure**: NONE - the closure is beta4's standing check over every refusal surface,
  and nothing in this iteration touches the validator's report shape.

### DRIFT-199-I002-006 — a stale round allowance in the decision slot of the plan packet (resolved-by T025, honest labelling)

**Recorded from the maintainer, 2026-08-29:**

> Your packet contradicts itself on the allowance. You measured that "1 of 4 remaining" belongs to
> 001's closed campaign and that 002 gets a fresh 4 - then the coverage line three paragraphs later
> still reports 1 of 4 rounds remaining in the position a reader takes the current constraint from.
> It nearly cost a wrong decision: I recommended against the split partly on that scarcity. Stale
> number in the decision slot. [...] Same family as the refusal standard - the number in the
> decision slot must be the number that governs the decision.

- **Observed**: the plan boundary packet for iteration 002 carried, verbatim as the stop artifact
  instructs, `Review coverage: ... 1 of 4 rounds remaining` - iteration 001's closed campaign
  (`cmp-199-beta3-stabilization-i001`, 3 of 4 used) - in the same message whose measurement said
  002's covering round runs under its own campaign with 4 rounds. The maintainer's allowance
  premise for the one-iteration ruling was formed on the stale number before the measurement
  corrected it.
- **Cause, read at source**: `Get-SpecrewReviewCoverageState` resolves the feature's latest
  campaign and the coverage line (`shared-governance.ps1:6977`) reports its budget without naming
  which campaign or iteration it belongs to; the stop artifact then instructs the packet to include
  the line verbatim in Why I Stopped.
- **Citation**: the refusal standard's instance clause (B-4.1), applied to a number rather than a
  refusal: the figure in the decision slot must be the figure that governs the decision.
- **Resolution**: folded into T025 and LANDED (2026-08-29). The maintainer's condition held at
  implementation: `Get-SpecrewReviewCoverageState` already returns `campaign_id`
  (`cmp-<feature>-i<NNN>`) and the active iteration is already in `session_state`, so the line now
  names the campaign its figure was read from and, when the active iteration has none, says that it
  starts with a fresh allowance - changing what the line SAYS and not what it selects. Measured on
  this repository: `... 1 of 4 rounds remaining in campaign cmp-199-beta3-stabilization-i001
  (iteration 001); iteration 002 has no campaign yet, so it starts with a fresh allowance.`
- **Class closure**: candidate - every figure rendered into a packet's decision slot names the
  record it was read from.

### DRIFT-199-I002-007 — FR-030's enumeration named a derived value as a mirror (spec-updated, human-decision)

- **Observed**: 2026-08-29, at the plan verdict. The enumerated-mirrors finding (item eight) listed
  `state.md` Iteration Status beside Current Phase and `plan.md` Status; the design draft then
  proposed a map writing `reviewing` into it. Verified against source: Iteration Status is written
  by `task-progress.ps1` (lines 565, 593, 601, 608) from task progress in its own enum, and
  `tracker-honesty-check.tests.ps1:139-146` proves the enum check fails closed on non-canonical
  values. As drafted, the truth gate would have refused a value the engine's own writer produces,
  and every project holding `ready-for-review` would have broken on upgrade - TB-4's
  producer/consumer defect and DRIFT-008's non-canonical-value stop, reintroduced by the mirror
  fix.
- **Ruling (maintainer, verbatim in substance)**: the framing was the maintainer's own; Iteration
  Status is derived, not a mirror, and only its closeout value is boundary-driven; a consistency
  relation is the right truth check for it; `plan.md` Status remains the actual mapped copy;
  adopt both existing vocabularies with no migration.
- **Resolution**: spec-updated - FR-030 re-worded (copies versus the derived value; each file's
  existing enum; consistency relation); contract and plan follow.
- **Class closure**: the enumeration names, per mirror, whether it is a copy or a derived value
  and which writer owns its enum; a truth check is written against that, never against the
  boundary name alone.

### DRIFT-199-I002-008 — the phrase exists at prompt-submit; the capture already runs there, and the session did not look (resolved-by T024, and a session rule)

**The maintainer's question, 2026-08-29, at the before-implement verdict:**

> Your typed-phrase capture runs at Stop, but the phrase exists at UserPromptSubmit - the start of
> the turn, not the end. That is why every boundary costs two human round trips that no gate log
> records [...]. The fact needed is available before the machinery consults it, which is TB-3's
> shape for the third time. It is T024's code path; determine whether the capture can move to
> where the phrase first appears, and if it can, fold it in.

- **Determined from source and measured**: the capture ALREADY runs where the phrase first
  appears. The Claude host binding registers `UserPromptSubmit` (`hosts/claude/host.psd1`,
  `TurnStartCapability = exact`), the handover provider is registered for that event
  (`refocus-scopes.json`), the dispatcher hands the prompt text through `--last-user-message`
  (`specrew-hook-dispatcher.ps1:1167-1171`), and `HandoverStore.ps1` routes a `UserPromptSubmit`
  source into `Invoke-SpecrewBoundaryVerdictCapture` with the prompt text - the W45 prompt-entry
  path. Measured against the ledger: the plan verdict was recorded at 12:15:59Z and the session's
  first tool call of that turn ran at 12:16:32Z; tasks 14:44:32Z versus 14:44:56Z;
  before-implement 16:18:06Z versus 16:18:47Z. Three of the day's verdicts were written at
  prompt-submit, before the session did anything. The retro verdict alone (01:49:03Z) was not in
  the store when that turn began and landed at Stop; its text classifies as `approve` and is not a
  machinery envelope, and prompt-entry outcomes are not journaled, so its cause is not
  determinable from the record - which is itself the gap T024 closes.
- **So where did the round trips come from?** Mostly from this session. After the memory note
  that once said "capture writes at Stop only", the session ended three turns "so the write
  could land" without reading the store first - and for two of them (plan, tasks) the store
  already held the verdict. The maintainer paid two messages for an assumption the machinery had
  already falsified. The third cause of friction named at the retro (write latency) therefore
  splits again: a real Stop backstop (the retro verdict), and an agent assuming Stop-only against
  the evidence on disk.
- **Citation**: FR-010 (verdicts always capture); TB-3's shape (the fact needed is present and
  unread - this time by the session, not the machinery).
- **Resolution**: folded into T024 - (a) the prompt-entry capture journals every outcome
  (`captured` / `not-approval:<action>` / `no-pending-state` / `machinery-envelope`) so a missed
  capture is diagnosable, and (b) the disclosure line fires at prompt-entry, in the same turn's
  injected context, where the phrase first appears - not at the recap. And a session rule,
  recorded here and in the session's own memory: read `last_authorized_boundary` at the start of
  every turn after a verdict; end a turn to let a write land only when the store shows the
  verdict unrecorded AND the classifier says approve - that is the Stop backstop, and it is the
  exception.
- **Class closure**: the disclosure at the point of first appearance, journaled; the session rule
  closes the agent half.

### DRIFT-199-I002-009 — the task ledger's own writer produces a status its own boundary preflight refuses (resolved-by T021)

- **Observed**: 2026-08-29, marking T014 done through the governed path. `Set-TaskComplete` (the only
  ledger writer for an iteration past the first, since tasks.md checkboxes are read for iteration
  001 only) writes `status: "complete"` into `tasks-progress.yml` - its `ValidateSet` is
  `pending | in-progress | complete | blocked`. Every consumer speaks `done`: the boundary
  preflight's task-state check allows `pending | in-progress | done | blocked | needs-rework |
  deferred` and FAILED live (`task-state fail: tasks-progress.yml contains an invalid status or
  disagrees with state.md Tasks Remaining`), the validator's task enum is `planned | in-progress |
  done | needs-rework | deferred | blocked`, and iteration 001's ledger reads `done` throughout
  (written by the checkbox derivation, never by this writer). Left as is, iteration 002's own
  review-signoff preflight would refuse on a value the engine wrote.
- **Citation**: FR-030's class (a producer writing a value its consumer refuses - TB-4's family;
  DRIFT-199-I002-007's shape, third instance this iteration); FR-023 (every fix through the shipped
  path - which is how this surfaced).
- **Resolution**: folded into T021, the mirror/vocabulary task: `Set-TaskStatus` writes `done` for
  completion and accepts `complete` as an input alias, so the ledger holds the one word every
  consumer reads; T014's ledger entry is re-synced then. The ledger is NOT hand-edited in the
  meantime - the record shows exactly what the writer produced, and the preflight's refusal stands
  as the measurement until T021 lands (T021 is the next task in the planned order).
- **Class closure**: the mutation for T021 - a task completed through `Set-TaskComplete` passes the
  boundary preflight's task-state check; revert the writer and the check goes red.

### DRIFT-199-I002-010 — the plan predicted a test flip that FR-024 does not cause (open; scope note, no fix here)

- **Observed**: 2026-08-29, landing T015. The plan and the design analysis both listed
  `fr068-verdict-demand-reproduction` HALF 2 among the flips this batch owns - "documented as designed
  to invert when beta3 fixes the composition". It did not invert, and it should not have: read at
  source, HALF 2 characterises a DIFFERENT composition from the one FR-024 fixes.
- **What FR-024 fixed (T014, T015)**: one provider's own surface no longer offers a verdict for a
  crossing whose stage owes artifacts - the packet, the stop artifact, the skill copies, Rule 53 and
  the discipline texts now say one thing.
- **What HALF 2 measures**: the DISPATCHER concatenating two different providers' block fragments -
  the conformance provider's "emit the verdict marker" and the co-review navigator's "do NOT emit a
  marker" - joined by `----- AND ALSO -----` (`specrew-hook-dispatcher.ps1:1292`) with no precedence
  and no conflict detection. Two correct surfaces, hostile when delivered together: the same class,
  a different instance, and one this batch's ten items never scoped.
- **Citation**: FR-024 (what was fixed); the crew brief's composition-defect class (B-4.2, beta4's
  walk harness: "human does an ordinary thing, two gates disagree").
- **Resolution**: open, no fix in this iteration - the characterization stays green because what it
  characterises is still true. The plan's owned-flip list is corrected rather than the test. Proposed
  disposition: beta4, with the composition tests, where dispatcher-level precedence between
  co-occurring block directives is the actual design question. Named here so the next reader does not
  mistake a passing characterization for an unfixed FR-024.
- **The shape it shares, noted at the maintainer's instruction (2026-08-29)**: this is the same problem as
  the instruction corpus - **a rule stated in more than one place with nothing deciding which wins**. T015
  fixed one instance of it in the TEXT layer (the gate-stop skill, Rule 53, the refocus files and the
  methodology table each carried a verdict-rendering rule, and they disagreed; they now carry one
  statement). HALF 2 is the same defect one layer down, in the DELIVERY layer: two providers each emit a
  correct directive, the dispatcher concatenates them with `----- AND ALSO -----`, and nothing arbitrates.
  Fixing the text layer does not touch it, which is exactly why the predicted flip did not happen.
- **Resolution**: open, beta4 - and worth more than a failed prediction, per the maintainer: a real
  composition defect and a new finding. Its home is the composition tests, where the design question
  ("when two correct directives are delivered together, which one governs") can be answered once for both
  layers instead of twice.
- **Class closure**: NONE - a precedence rule between provider fragments is beta4 design work, and inventing
  one inside a tag batch is the shape the maintainer ruled against for F-2. The guard cannot be written before
  the rule it would enforce exists: a composition test asserting "which directive governs" has no correct
  answer to assert until beta4 decides one. Recorded against the beta4 composition-test programme so the guard
  is written with the rule rather than after it.

### DRIFT-199-I002-011 — a patch applied twice left a duplicated block in a shipped script (resolved at T025)

- **Observed**: 2026-08-29, during T025's mutation audit. The audit's mutation setup asserted that its
  target line appeared exactly once and failed - `create-governed-feature.ps1` carried the FR-029 stub
  block TWICE. Cause: T020's patch script aborted partway on an unrelated anchor AFTER writing that file,
  and the re-run applied the same block a second time.
- **Why it mattered less than it could have, and why it is recorded anyway**: the block is idempotent (the
  second copy re-reads the file it just wrote and leaves the stub alone), so the shipped behaviour was
  correct and every T020 assertion passed. That is exactly the shape worth recording: a defect a green
  suite cannot see. It was found only because the mutation audit asserts a UNIQUE target before mutating -
  the count assertion, not the test, is what caught it.
- **Citation**: FR-033 (mutation proving; every fix asserts observable state) and the standing rule that a
  structural assertion which cannot see a disabled call is not a test.
- **Resolution**: the duplicate block removed, the script re-parsed clean, the mirror re-synced, T020's
  suite re-run green, and the T020 mutation then executed properly against the de-duplicated file (the
  template-only guard removed -> red, restored -> green).
- **The CLASS, recorded at the maintainer's instruction (2026-08-29)** - this is a new member of the
  family this feature has been cataloguing, and it is not one of the ones already named:

  > Not a control that does nothing, not a test that certifies the defect, but **a defect a green suite is
  > structurally incapable of seeing**.

  The stub block was duplicated and every T020 assertion passed over it, because the duplication was
  IDEMPOTENT: the second copy re-read the file the first had written and correctly left it alone. No
  behavioural test could have caught it - the behaviour was right. What caught it was the mutation audit's
  own precondition, `count == 1` on the line it was about to edit.

  **The reusable lesson: asserting the cardinality of the subject set is itself a detector.** A behaviour
  test asks "does this do the right thing"; a cardinality assertion asks "is there exactly one of it", and
  that question finds duplication, silent absence, and accidental re-application - failure modes where the
  observable behaviour is indistinguishable from correct. It costs one line and it is the only thing that
  saw this. Sibling instances already in the record: the verification plan naming 45 suites while 384
  existed (DRIFT-199-I001-134, a count nobody compared), and the drift log's own summary claiming 78
  entries against 152 (corrected at the 001 retro). Same shape, three times: the number of things was
  never asserted, so the wrong number of things went unseen.

  **The lesson stated at its actual level, per the maintainer (2026-08-29) - and this is the correction
  that matters, because the narrower version would have been mis-learned:**

  > The lesson is not "check mirrors", it is **"never enumerate a subject set by hand when something
  > already computes it"**.

  "Check mirrors" is a checklist item, and a checklist item generalises to nothing: it would have been read
  as *add a mirror step to the next patch* and left every other hand-enumerated set exactly as exposed.
  What actually failed was **hand-enumeration where a computation existed**. The mirror map was written out
  by hand when `Get-SpecrewCrossingMirrorMap` computes it; the verification plan's suite list was written out
  by hand when the filesystem enumerates it; the drift log's summary count was typed when the headings could
  be counted. In every case a hand-written set was believed over a computed one, and the divergence was
  invisible because nothing compared them.

  The operational form is a rule about **where a set comes from**, not about how carefully it is checked:
  if something already computes the set, call it; if nothing does, write the computation first and let it
  be the enumeration; and where a set must be stated by hand, assert its cardinality against the computed
  one so the divergence is loud. This is the same root as DRIFT-199-I002-014, arrived at from the opposite
  direction - there a control was **hand-reimplemented** instead of invoked, and the reimplementation's
  answer was reported as the control's defect. Enumerating by hand and reimplementing by hand are one
  mistake: **restating what the machinery already does, then trusting the restatement.**
- **Class closure**: every mutation in this iteration asserts `count == 1` on its target before editing, so
  a duplicated or missing target fails loudly instead of mutating the wrong thing. The generalised closure is
  the maintainer's rule above: FR-030's crossing writer owns every enumerated mirror **because it computes
  the enumeration** (`Get-SpecrewCrossingMirrorMap`), not because a human remembered to check them - which is
  the difference between the fix that holds and the checklist that decays.

### DRIFT-199-I002-012 — the tripwire cannot fire: the Actual column is the estimate copied across (resolved by re-instrumentation)

**The maintainer's finding, verified before authorizing the covering round (2026-08-29):**

> Every task's actual equals its estimate exactly - T014 3.0/3.0, T015 2.0/2.0, T016 1.5/1.5, all twelve.
> That is the second iteration running; 001's actuals summed to precisely its 13.1 capacity line. The
> actuals column is not measurement, it is the estimate copied across. Which makes the tripwire
> unfireable: "stop and re-plan if review or rework exceeds the direct estimate by 2x" cannot trigger
> when the recorded actual is definitionally the estimate. I specified a control that, as instrumented,
> can never fire - the inert-control family arriving inside the governance instrument built to catch it,
> which is the thirteenth-odd instance and the first one I authored.

- **Confirmed on the record**: iteration 002's twelve Actual cells were written by this session as copies
  of the Effort cells at completion time; the sum (19.0) matches the capacity line by construction, not by
  measurement. Iteration 001's retro said the same thing in prose - "per-task effort was not time-tracked;
  the timestamps are batch stamps written at landing, not effort" - and then still summed Actuals to
  exactly 13.1. Two iterations, the same non-measurement, reported both times as if it were data.
- **Why it is the sharpest instance of the family so far**: the inert control is INSIDE the governance
  instrument built to catch inert controls. The plan states a safeguard ("stop and re-plan at 2x") whose
  input can never move; a reader of plan.md would reasonably believe the iteration is protected by it.
- **Citation**: the 001 retro's lesson 1 (an authority and its mirror belong to one writer with a truth
  check between) applied to a MEASUREMENT and its claim; FR-033's separate-tracking clause; the
  maintainer's plan-verdict instruction that review and rework be tracked separately so the next retro can
  say which figure was right.
- **Resolution — re-instrumented, not time-tracked** (the maintainer's ruling: "do not fix this with time
  tracking; inventing hours would be worse"). Three countable measures replace the copied number, all of
  them already produced by the machinery:
  1. **Review rounds consumed** - the campaign budget's own counter (`rounds_used` in the review
     authority store), which no one can copy from an estimate.
  2. **Rework commits** - commits on this branch after the round is delivered whose subject is a fix
     rather than a record, countable with `git log`.
  3. **Calendar days between round delivery and signoff** - the 001 retro already measured calendar
     ("roughly eight times the implementation calendar"), so the unit was known to work here.
  The tripwire is restated against those three, and the per-task Actual column is relabelled for what it
  actually is (landing effort at the estimate, unmeasured) rather than presented as measurement.
- **Class closure**: a plan may not state a threshold whose input is not independently produced. The three
  measures above come from the campaign store, git history and dates - none of them writable by the
  session that would trip the wire.

### DRIFT-199-I002-013 — a class guard caught an internal requirement id in a shipped script (resolved same session)

- **Observed**: 2026-08-29, in the covering round's pre-review verification. The `f199-class-guards`
  command failed on `no-internal-ids-in-emitted-strings`: `create-governed-feature.ps1:149` contained the
  literal `FR-001: System MUST`, which T020 had used to recognise the upstream spec template.
- **Why it is a real defect and not a false positive**: W46's rule is that a shipped script must not carry
  Specrew's internal requirement ids, because a downstream reader has no referent for them and they collide
  with the consumer's own FR namespace. A detection pattern is still a string in a shipped file, and a
  consumer grepping their own spec ids would find Specrew's.
- **Resolution**: the template is now recognised by its placeholders (`[Brief Title]`,
  `System MUST [specific capability]`, `[FEATURE NAME]`) - unique to the template and carrying no id. The
  T020 suite additionally asserts the stub contains no `FR-\d{3}` at all. Guard green.
- **Class closure**: the guard already exists and already ran; what it proves is that the class-guard lane
  earns its place - this defect was introduced by a task that had nothing to do with requirement ids, which
  is exactly the case the permanent lane was created for (DRIFT-199-I001-017).

### DRIFT-199-I002-014 — I reported an engine defect that does not exist, and a ruling was made on it (resolved; the finding is withdrawn)

**This entry replaces the finding that stood here. The finding was wrong. The record of it being wrong is the
point of the entry, so the original claim is quoted rather than deleted.**

- **What I reported, 2026-08-29**: that the deployed-extension integrity check "cannot tell a Windows checkout
  from an edit" — that of 74 reported hash mismatches, *"55 are byte-identical once line endings are
  normalised"*, that the check therefore had a *"74% false-positive rate on the platform it runs on"*, and
  that it *"is not currently evidence."* I offered three options and asked for a decision, because it blocked
  the covering round.
- **The maintainer ruled on it** — take option (a), fix the comparison rather than `.gitattributes`, with a
  reason that was correct and general: *"Specrew ships to projects that own their own .gitattributes and their
  own autocrlf, and a check that only agrees with its manifest when the consumer's config matches ours is
  broken by design for the people it is meant to protect."*
- **What is actually true**: `Get-SpecrewDeployedExtensionManifest`
  (`extensions/specrew-speckit/scripts/shared-governance.ps1`) **already normalises line endings** before
  hashing — it reads bytes, skips binaries via a NUL scan, and does `.Replace("\r\n", "\n")` on the text
  before computing SHA-256. The engine's own check, run directly, reports **19 drifted, 0 missing** — all
  nineteen this batch's deliberate deployed edits, and **zero line-ending noise**. There was never a 55-file
  false-positive population.
- **How I got it wrong**: I measured with my own Python script that hashed **raw on-disk bytes**, compared that
  against the manifest, and attributed the difference to the engine. I never ran the engine's own comparison
  before reporting on it. The 74/55/19 split is a property of *my* script, not of the control I was auditing.
- **Sharper still**: the source I was about to "fix" carries a comment, three lines above the code, recording
  that this exact normalisation was added after a previous false-refusal — *"a false refusal waiting for the
  first project that commits .specify/"*. The fix I proposed had already been made, for the reason I restated
  as new.
- **Why this is a first-class drift event and not an embarrassment to bury**: a wrong finding reached a
  boundary and produced a maintainer ruling. Had the ruling been executed as written, I would have edited a
  correct control to make it do what it already did, and the batch would carry a change whose justification was
  false. The gate that would have caught this is the one this project already names in another form: **evidence
  means running the control, not reasoning about it.** Method rule (FR-033) requires runtime evidence for
  claims about behaviour; I applied that to the code under change and not to the code I was accusing.
- **Class**: **a diagnosis that reimplements the subject instead of invoking it.** The auditor writes its own
  version of what the control does, compares against the artifact, and reports the divergence as the control's
  defect — when the divergence is between two implementations, only one of which ships. It is the mirror image
  of DRIFT-199-I002-011: there, hand-enumeration missed something a computation would have caught; here,
  hand-reimplementation invented something the real computation would have denied. Same root:
  **never restate what something does when you can make it do it.**
- **Resolution**: the finding is **withdrawn**. No comparison fix is made, because none is needed — the ruling's
  premise did not hold, and the standing rule that nothing here weakens a gate that caught something real
  applies to this gate too: it caught exactly the 19 real edits, with no noise. The 19 were **re-stamped**
  through the engine's own writer (`Write-SpecrewDeployedExtensionMarker`), which is the intended remedy for
  deliberate deployed edits; the check now reports 0 drifted, 0 missing.
- **What survives of the ruling, and is recorded rather than acted on**: the maintainer's reason for preferring
  a comparison fix — that a consumer with different `autocrlf` must not get a false refusal — is *already*
  satisfied by the normalisation, and that is worth knowing rather than assuming. The related observation
  that `.gitattributes` line 7 omits `*.ps1` from its LF list remains true as a fact about this repo, but it is
  now known **not** to affect the integrity check, so the optional-hygiene item is raised on its own merits
  (consistency of committed line endings) and not as a protection for this control. Recorded as beta4 optional
  hygiene, explicitly not bundled here, per the maintainer's instruction.
- **The same mistake was made twice, one level apart, and the second time by the reviewer**
  (recorded at the maintainer's instruction, 2026-08-29, in their words):

  > I got DRIFT-014 wrong in the same way you did, one level up: I checked that line endings differ and
  > never checked whether the thing I was ruling on already handled them. The file name was in your report.

  This belongs in the record because the failure mode is not "an agent reasoned badly" - it is that **a
  wrong finding survived a review boundary and became a ruling**. The crew's job at that point is to
  implement the ruling; had the tree not been checked first, a correct control would have been edited to
  make it do what it already did, and the batch would carry a change whose justification was false. The
  guard that actually held was running the control before changing it - which is the same rule the class
  below names, applied by whoever touches the code, not by whoever authored the finding.
- **Class closure**: NONE - no automated guard is possible, and the reason is worth stating rather than
  hiding: the failure was in **how a claim was formed**, not in any code that could be made to fail a test. There is no
  fixture that catches "the auditor reimplemented the subject instead of invoking it", because the
  reimplementation lives in the auditor's scratch work, not in the tree. What exists instead, and is
  executable:
  1. **The control itself is now in the verification plan's path** - `iteration-002-governance` runs
     `validate-governance.ps1`, which runs `Test-SpecrewDeployedExtensionIntegrity`. A real regression in the
     normalisation would surface as a failing verification command, not as an analysis.
  2. **The method rule already covers it and was simply not applied here**: FR-033 requires runtime evidence
     for claims about behaviour. The correction is to apply it to the code being *accused*, not only to the
     code being *changed* - which is a one-line extension of an existing rule rather than a new control, and
     is recorded as such in FR-033's method-rule text rather than as a new requirement.
  Closing this with a fabricated guard would be the same mistake in a new costume: asserting a control exists
  because it would be tidy if it did.

### DRIFT-199-I002-015 — a closed iteration's hardening gate blocks its successor's review (open; BLOCKS the covering round)

- **Observed**: 2026-08-29, same command. `iteration-001-governance` also failed on: *"hardening-gate.md
  still requires runtime evidence or explicit closure follow-through for concern(s): security-surface,
  error-handling-expectations, retry-idempotency-requirements, test-integrity-targets"*.
- **What is actually true**: iteration 001's hardening gate records those four concerns as `addressed` with
  `RuntimeEvidenceStatus: pending-post-implementation` - the planning-time posture, written before
  implementation, and unchanged since long before this batch. What changed is that iteration 001 now claims
  `complete`: the closeout this session recorded under the maintainer's verdict. A complete iteration is
  held to a higher bar than a running one, and 001's gate never received its post-implementation record.
- **Why nothing was done to it here**: iteration 001 is CLOSED AND SEALED. Editing its hardening gate is
  editing preserved history, which the validator itself refuses and the maintainer has ruled is the human's
  act, not a session's. The alternative - pointing the verification plan at the ACTIVE iteration - is a
  project-config change that would silently narrow what the review's own preflight checks, and is a
  decision rather than a repair.
- **The verification plan is pinned to a closed iteration**: `plan_id: f199.i001.slice.v3`, and its
  governance command names `specs/199-beta3-stabilization/iterations/001`. Iteration 002 is the tree under
  review. Whichever way the above is decided, that pin is now stale.
- **Resolution — RESOLVED 2026-08-29 under the maintainer's ruling**, in three parts, none of which touches
  the seal:
  1. **The sealed gate is not edited.** *"Do not edit the sealed gate"* - it is preserved history, the
     validator refuses it, and a `pending` that quietly becomes `verified` after the fact is exactly the record
     a reader cannot trust.
  2. **The verification plan is re-pointed at the ACTIVE iteration.** `plan_id` is now `f199.i002.slice.v1` and
     the governance command is `iteration-002-governance`, naming
     `specs/199-beta3-stabilization/iterations/002`. The re-pointed command's label carries why, so the next
     reader does not have to reconstruct it.
  3. **The four concerns get an honest disposition OUTSIDE the seal**, as an erratum -
     `specs/199-beta3-stabilization/iterations/002/erratum-iteration-001-hardening-gate-disposition.md` -
     following the discipline `proposals/` already applies to shipped work: *preserve the body, record the
     pointer*. It states per concern what runtime evidence now exists and names, rather than hides, the two
     places where evidence is still thin: the OneDrive hydrate-then-hash-verify path (manual, as 001's own gate
     anticipated) and the conflicting-pause-fact branch. It does not amend the gate, change its verdict, or
     claim 001's review covered evidence that accrued afterwards.
- **A gate corrected the fix while it was being made, and this is the good outcome, not a detour**: the erratum
  was first written into `iterations/001/` - beside the gate it discusses, which felt like the helpful place -
  and the validator refused it: *"Closed iteration ... was edited after its closeout seal."* The refusal is
  right, and not on a technicality: **adding** a file to a sealed directory still changes what the human's
  verdict accepted, and anyone diffing the closed iteration would find something the signoff never saw. The
  message then named the correct mechanism itself - *"record what needs to change as a drift entry in the
  ACTIVE iteration's drift-log.md, where new facts belong ... until the governed supersede mechanism ships,
  their explicit instruction recorded in the active drift log is the path"* - which is precisely this entry,
  carrying the maintainer's explicit instruction, with the erratum as its long form. Worth recording for two
  reasons: it is a refusal that met the project's own standard (it named what was wrong, why it matters, and
  the one action), and it shows the seal discipline holding against a well-intentioned edit, which is the case
  it actually has to survive.
- **Recorded as a BETA4 ITEM at the maintainer's instruction**: *"a closed iteration gates its successor's
  review."* The mechanism has two halves and neither is a defect in the gate or in the closeout - it is a
  **missing hand-off**. A verification plan that names an iteration by number goes stale the moment the next one
  opens; and an iteration transitioning to `complete` retroactively raises the bar on a gate written under
  planning-time rules, so *closing an iteration correctly can block the review of the tree that succeeds it*.
  The fix belongs where the transition happens: the closeout should re-point the plan, the command should name
  the active iteration rather than a number, and a `pending-post-implementation` concern should have a defined
  disposition step at closeout instead of becoming a permanent blocker on everything after it.
- **Class closure**: the class is real and now named - **a verification plan that names a specific iteration
  goes stale the moment the next one opens**. Closed here by re-pointing; closed structurally in beta4 by making
  the closeout own the re-point.

### DRIFT-199-I002-016 — the covering round found three real defects in this batch's own fixes, and the summariser demoted every one of them (two fixed, one pinned; the demotion observed, not fixed)

- **The round**: run `run-20260829-214056323-db3b4944`, campaign `cmp-199-beta3-stabilization-i002`,
  2026-08-29. Reviewer host `codex`, independent of the code writer (`claude`). 909s, containment verified,
  completion complete, currentness current, verdict `findings`, `can_approve_current: false`.
- **What it found — three findings, all confirmed against the code by this session before reporting.** Each
  is in code THIS iteration wrote, and two of them are members of families this feature exists to catalogue:
  1. `workshop-receipt-contract` (`extensions/specrew-speckit/scripts/confirm-workshop-lens.ps1:217`) - the
     governed lens checkpoint writes the receipt as `turn_receipt`, but the canonical reader
     (`scripts/internal/bootstrap/ProjectMetadataAccessor.ps1:641`) reads `human_turn_receipt`. Confirmed:
     the two names do not match, so the receipt is invisible to the reader and the next workshop-state read
     returns `workshop-completed-human-turn-receipt-invalid` instead of advancing. The same block maps
     `human-skipped` to scope `lens-question` (line 199) while the canonical table (lines 581-583) requires
     `explicit-skip`, and its `ValidateSet` omits `human-delegated` entirely. **This is FR-027 failing at
     exactly the thing it was written to fix**: a lens answer the human gave that the machinery cannot read.
  2. `foreign-owner-still-stop-blocked`
     (`extensions/specrew-speckit/scripts/specrew-conformance-provider.ps1:1651`) - the `owner-differs`
     branch sets `$blockReasonOwnerScoped = $true`, and **that is the only occurrence of the variable in the
     file**. It is set and never read; the shared tail still emits `<<<SPECREW-STOP-BLOCK>>>`, so a
     non-owner session is still force-continued until the cap. **A textbook inert control - inside the fix
     (FR-032/TB-6) whose entire purpose was to stop interrupting sessions that do not own the crossing.**
     Twelfth-odd instance of the family, and the second this batch has introduced rather than removed.
  3. `bare-marker-bypasses-crossing-id` (`scripts/internal/bootstrap/HandoverStore.ps1:781`) - marker
     parsing makes `@ crossing-...` optional and the capture guard compares identities only when the
     captured marker supplied one, so a bare `<from> -> <to>` marker still authorizes the current scoped
     crossing. Confirmed, and the code comment says so out loud: *"A bare marker (no identity) keeps
     today's capture until T015 makes every renderer emit the identity."* **T015 did not.**
     `.claude/skills/specrew-gate-stop/SKILL.md:96` - the renderer this host actually follows - still
     instructs the bare form. So the binding the maintainer folded into T001/T010 is bypassable by the very
     renderer it was meant to bind.
- **And the test certifies it.** `tests/unit/crossing-mint-gate.tests.ps1:183` asserts
  *"a bare marker authorizes plan -> tasks today (T015 flips this deliberately)"* - a green assertion whose
  own text says a later task was supposed to invert it. **Second catalogued family in one round: a test that
  certifies the defect.** The suite passes, and it passes *because* the defect is present.
- **The instrument's own defect, observed and NOT fixed here (B-3 is not in this batch, maintainer ruling)**:
  the reviewer graded all three `major`. The summariser demoted all three to `minor`
  (`demoted: true`, `demoted_from: "major"` on every finding in `result.json`) with the stated reason
  *"no concrete failure scenario, so it cannot gate"*. **That reason is contradicted by the finding text it
  is attached to** - each of the three descriptions contains a concrete failure scenario, and this session
  reproduced all three from the code. The demotion is therefore not a judgement call that went the other
  way; it is a rationale that the record itself refutes. Reported to the maintainer from the RAW findings at
  their instruction, precisely because the summary would have shown three minors.
- **RECLASSIFIED 2026-08-30, maintainer ruling: B-3 is a RECORD defect, not a summariser defect, and that
  raises its beta4 priority.** The distinction is not academic and the evidence is in this campaign's own
  durable state. The restored pending-pause fact reads:

  > `major_count: 0`, `minor_count: 3`, `demoted_count: 3`

  **Those are the stored counts, not a rendering.** A presentation-layer demotion would leave the record
  intact and mis-display it; this writes the demoted grade into the campaign's persistent state. The raw
  findings do preserve `demoted_from: "major"`, so nothing is destroyed - but **any future reader doing
  arithmetic over this campaign sees zero majors on a round that graded three.** Every consumer that counts
  rather than reads inherits the wrong number: budget reasoning, gating decisions, retro figures, and any
  later claim about what this batch's review found. B-3 has been filed as "the summariser demotes
  severities"; it is "the demotion is written into the record", which is a different defect with a
  different blast radius.
- **Citation**: FR-027, FR-032, FR-024; FR-033 (mutation proving - see below); the inert-control family
  catalogue; the standing rule that nothing here weakens a gate that caught something real.
- **What this says about the method, and it is not comfortable**: eleven suites in this iteration were
  mutation-proved, and all eleven are green. They did not catch any of these three, because each mutation
  proved the control it was written for and none of them asked whether the control's OUTPUT matched the
  contract its consumer reads (1), whether a flag it set was ever read (2), or whether a documented residual
  had actually been closed by the task that promised to close it (3). Mutation proving shows a control is
  wired to its own test. It does not show the control is wired to the system.
- **Resolution — the maintainer's disposition, 2026-08-29, and what was done under it.**
  *"Findings 1 and 2 are not scope growth and I am not treating them as such: they are this batch's own work
  being incomplete. A fix that does not work is not a fix."* Both fixed here. Finding 3 handled differently,
  on the maintainer's reading that it is *"a partial improvement rather than a regression"* - a bare marker
  falls back to pre-batch behaviour and T014 already refuses a superseded identity - so carrying the renderer
  work is defensible, but *"what is not defensible is the test."*
  1. **Finding 1 (FR-027) - FIXED.** The entry is written as `human_turn_receipt`, the name the canonical
     reader reads. `confirmation_scope` is now **the scope the receipt itself carries**, not one derived from
     a table in the writer - which removes the wrong `human-skipped -> lens-question` mapping at its cause
     rather than by correcting one row, and makes `human-delegated` work by construction (it is now in the
     `ValidateSet` too). A receipt with no scope is refused rather than written into an entry the reader
     would reject. `$receiptScope` had been read at line 116 and never used: the same set-never-read shape as
     finding 2, feeding the same defect.
  2. **Finding 2 (FR-032) - FIXED.** `$blockReasonOwnerScoped` is now declared beside `$blockReason` and
     **consumed** in the shared tail: when a different live session owns the crossing, the composed text
     leaves as an ordinary informational injection and the stop is released, instead of leaving as
     `<<<SPECREW-STOP-BLOCK>>>`. The loop-guard increment taken for a block that is no longer issued is
     released, so a foreign session cannot spend the owner's cap. Note on how invisible it was: the flag was
     assigned in one branch and **declared nowhere**, so under `Set-StrictMode -Version Latest` the tail
     could not have read it without throwing - "set and never read" was the only shape it could have had.
  3. **Finding 3 (FR-024) - the expired justification removed, the gap pinned.** The renderer work is
     carried. `tests/unit/crossing-mint-gate.tests.ps1` case 4c no longer says "T015 flips this
     deliberately"; it states what is true (a bare marker captures), why it is deferred (pre-batch fallback;
     the superseded-identity case is genuinely refused; closing it is a multi-host skill change), and what
     would close it - with the closing assertion written out, disabled, beside it so the closure is a
     deletion rather than a fresh piece of design. The same expired claim was in the source comment at
     `HandoverStore.ps1` and in the suite's header; both now say the same true thing.
- **Mutation proof (FR-033, mandatory), and the suites had to be repaired before they could prove anything**:
  - Finding 1: reverting the field name turns cases 2, 2b and 2c red, and case 2b now reports the real
    production failure verbatim - `status: invalid/workshop-completed-human-turn-receipt-invalid`. Reverting
    the scope to a local table turns case 2c red. **Two repairs were needed first.** The suite's own case 2
    asserted `$entry.turn_receipt` - it pinned the writer's invented name, a THIRD instance of a test
    certifying the defect, and one this session wrote. And the fixture never set `human_turn_contract`, so
    the canonical reader **skipped its receipt check entirely**: case 2b called itself the round trip while
    the far side's validation was switched off. The fixture now declares the contract, so the seam is
    actually exercised.
  - Finding 2: disabling the consumer turns crossing-owner case 3 red. That case previously asserted the
    informational TEXT and the absence of the marker, and passed against the defect, because nothing looked
    at **how the text left**. It now asserts the delivery mechanism on both sides - no `SPECREW-STOP-BLOCK`
    for the foreign session (case 3), and one still present for the owner (case 4), so releasing the block
    cannot silently release it for everyone.
  - Both mirrors verified byte-identical in the same commit.
- **The rule this produced**: FR-033 now carries the maintainer's ruling as a binding method rule -
  *mutation proving shows a control is wired to its own test, never that it is wired to the system* - with
  its two consequences: a fix crossing a seam owes a writer-and-reader case, a fix whose control is a flag
  owes a case asserting the flag's effect, and where the far side has a switch that disables its own check
  the fixture must turn it on. The general instrument (a contract test exercising writer and reader in one
  case) is recorded for beta4's composition harness, beside the two-gates-disagree scenarios.
- **Three things the maintainer put on the record as having gone right** (recorded because a drift log that
  only holds failures teaches the wrong lesson about which behaviours to repeat):
  1. A finding was **withdrawn when the evidence turned against it**, after it had already been argued
     convincingly and ruled on (DRIFT-199-I002-014).
  2. The validator was **allowed to refuse** the erratum written into the sealed directory, and the erratum
     was moved rather than forced - the seal discipline holding against its own author.
  3. **Invoked-only spend released attempt 1 rather than consuming it** - FR-014 working on its first real
     exercise, which is why this round was still round 1 of 4.
- **Class closure**: the guards were named before the fixes were authorized, so they could not be invented
  afterwards to fit whatever got built. Two of the three are now in place, and the third is deliberately not:
  1. **DONE** - the round-trip guard: `workshop-lens-checkpoint` case 2b runs writer and canonical reader in
     one case, against a fixture that declares `human_turn_contract` so the reader's own validation is on.
     Case 2c does the same for a skipped lens, where the scope differs.
  2. **DONE for the instance, OPEN as a lane** - `crossing-owner` cases 3 and 4 assert the flag's EFFECT on
     both sides. The generalisation - a lane-wide assertion that every `$blockReason*` the provider sets is
     consumed on some path - is beta4 work: it is a static property of the provider, and writing it as a
     class guard is the same shape as the existing membership guard. Recorded there rather than improvised
     here.
  3. **DELIBERATELY NOT CLOSED** - the residual-certifying assertion at case 4c is retained, because the
     renderer work it depends on is carried. What changed is that it no longer certifies anything: it states
     the gap, the reason for deferral, and the closure condition, and carries its own inverse disabled beside
     it. A pinned known gap is a different artifact from a green claim of correctness, and the maintainer's
     rule is the distinction - *do not leave a passing assertion whose justification has expired.*

### DRIFT-199-I002-017 — the coverage figure lost its campaign label in the report, one layer above the fix that adds it (resolved same session)

- **Observed**: 2026-08-29. The maintainer read the coverage line quoted in this session's report -
  *"3 of 4 rounds remaining"*, with no campaign named - and asked whether T025's DRIFT-006 fix was
  narrower than it had been reported: firing only for a non-current campaign rather than always.
- **Checked rather than assumed, which is what the instruction asked for**: it is not narrower. In
  `Get-SpecrewReviewCoverageLine`, the campaign is named in the `elseif` branch whenever `campaign_id` is
  non-empty - unconditionally. Only the extra *"iteration N has no campaign yet, so it starts with a fresh
  allowance"* clause is conditional, and correctly so: it fires when the campaign belongs to a different
  iteration than the active one. The live output ended `...3 of 4 rounds remaining in campaign
  cmp-199-beta3-stabilization-i002.`
- **The defect was mine, in the report**: I abbreviated the line when quoting it and dropped the campaign
  label. **That is the exact failure T025 fixed, reintroduced one layer up.** The fix puts the label on the
  figure so a figure in a decision slot carries the instance it belongs to; a paraphrase that drops the
  label restores the original defect at the point where a human actually reads it - which is the only point
  that ever mattered.
- **Why it is recorded rather than waved off as a typo**: the same reasoning that made DRIFT-006 worth
  fixing applies here. The maintainer formed a hypothesis about a shipped control being narrower than
  claimed, on the strength of a quote, and would have been right to. A control that labels its output is
  defeated by the first person who re-types the output without the label.
- **Citation**: DRIFT-199-I002-006 and T025; the human-facing ID-glossing discipline, which is this rule's
  sibling - carry the referent with the identifier every time it is shown.
- **Resolution**: resolved. The check is recorded above so the question is not re-opened, and the practice
  correction is narrow and permanent: **quote a decision-slot figure verbatim, or not at all.** Truncating
  a governed line for readability is the one place where readability is not the goal.
- **Class closure**: NONE - the subject is a report written in prose, and no executable guard can assert
  what a session chose to paste. Naming the practice is the whole of the available remedy, which is why it
  is written as a rule ("verbatim, or not at all") rather than as a resolution to be careful.

### DRIFT-199-I002-018 — the orchestrator pause write had never once succeeded; the campaign wedged and its refusal blamed a writable folder (root cause found and fixed; the restore itself is blocked on a schema decision)

- **Observed**: 2026-08-29. Round 2 was launched on the reworked tree and **did not run**:
  `run-20260829-233216091-188cc8f4`, `Invoked: False`, `status: paused`,
  `reason: review-round-paused:pause-record-missing-for-completed-round`. No round was consumed - the
  campaign still reads 1 of 4 used, so FR-014's invoked-only spend held again.
- **What the refusal told the human**: *"A review round finished, but Specrew could not save the record of
  what it found... What to do: check that Specrew can write to its own folder under
  .specrew/review/authority, then run the review again."*
- **THREE separate defects, each verified rather than inferred:**
  1. **The stated cause is wrong.** `.specrew/review/authority` is writable (verified by a write probe).
     More decisively, `Add-ReviewCampaignRoundPause` was replayed against a *copy* of the live store with
     round 1's own `result.json` and the same arguments, and it **succeeded** - writing exactly the file
     that is missing, `runs/<run-id>/pending-pause.json`. The write path is not broken. The human is being
     sent to check a permission that is fine, which is the refusal standard failing at its first clause:
     name what is actually wrong.
  2. **The real diagnosis was destroyed at the moment it happened.** The call site
     (`review-campaign-orchestrator.ps1:2096`) is wrapped in `try { ... } catch { $roundPause = $null }` -
     a bare catch that discards the exception object entirely. The fail-soft is defensible on its own terms
     and its comment argues for it well (*"a pause that cannot be recorded must not destroy a review the
     human already paid for"*). What is not defensible is that it swallows the CAUSE as well as the
     failure: nothing is journalled, nothing is warned to stderr, and the downstream guard - which reads
     the absence hours later - has no information at all. So it invents one. **A fail-soft that discards
     its exception guarantees that whatever reads its absence will misdiagnose it.** This is the same
     family as the strict-mode entry in FR-033: the louder failure was unavailable, so the defect took the
     only shape it could.
  3. **The recovery the message names cannot work, and the two commands point at each other.** The refusal
     says to answer with `specrew review --live --pause-choice <1|2|3>`. That path calls
     `Get-ReviewCampaignPendingPause`, which returns **null** here (verified read-only against the live
     store), so it prints *"No review round is waiting for your answer... Start one with: specrew review
     --live --approve-round"* and exits 1. `--approve-round` then reaches the very guard that produced this
     refusal, which says to answer the pause. **A closed loop with no CLI exit.** Each message is locally
     correct and helpful; composed, they are a trap. Same shape as DRIFT-199-I002-010: two correct
     surfaces, nothing arbitrating between them.
- **A latent fourth, found while diagnosing and NOT the cause here**: there are two publish paths that pass
  `-Invoked $true`, and only one of them writes a pause. `review-campaign-orchestrator.ps1:2086` publishes
  and then calls the pause writer at 2096; `review-run-reconciler.ps1:191` publishes an invoked result and
  **never** writes a pause (zero call sites in that file). The guard's comment reasons carefully about a
  pause write that *fails*, and does not consider a publish path that never *attempts* one. Any round closed
  by reconciliation therefore wedges the campaign exactly as it is wedged now. Round 1 was not that case -
  its `runtime_outcome` is `completed`, not `abandoned` - so this is a real latent defect, recorded as such
  and not claimed as this incident's cause.
- **ROOT CAUSE — found within minutes of adding the trace, and only because of it.** The maintainer's rule
  (*every fail-soft owes a trace*) was applied to this very catch as part of the reconciler fix. The first
  test run after that change printed:

  > `[specrew-review] WARN REVIEW_PAUSE_WRITE_FAILED campaign 'cmp-demo' run 'run-one': The variable
  > '$FeatureId' cannot be retrieved because it has not been set.`

  `Invoke-ReviewCampaignRun` calls `Add-ReviewCampaignRoundPause` with `-ProjectName $FeatureId` and
  `-RepoRoot $RepoRoot`, and **declares neither**: line 2097 was the only mention of `$FeatureId` anywhere
  in the function's body. Under `Set-StrictMode -Version Latest` the call therefore threw on argument
  binding **every time it ran**, so the orchestrator's pause write had *never once succeeded*. The pattern
  was copied from the caller's own working call site (line 1717), where both variables do exist; the copy
  landed in a function where they do not.
- **The sharpest form of the fail-soft lesson, and it is sharper than "the cause was unknown"**: the guard
  worked. Strict mode detected the undeclared variable, loudly, on every single run - and a bare
  `catch { $roundPause = $null }` threw the detection away. This is not a case of a defect being
  undetectable. **It was detected, correctly, thousands of times, and the detection was discarded at the
  moment it was produced.** The fail-soft did not merely fail to help; it actively destroyed a working
  control's output. That is why "every fail-soft owes a trace" is a rule and not a preference.
- **What was previously recorded here, and why it was right at the time**: this entry originally declined to
  state a root cause - *"the write path works, the store is writable, the pause is genuinely absent, and the
  failure is unreproducible because the code chose not to record it"* - because asserting an unsupported
  cause is what DRIFT-199-I002-014 cost. That refusal is preserved rather than deleted: it was correct on
  the evidence then available, and the cause became available only after the code was changed to record it.
  The lesson is not "should have guessed harder"; it is that **the diagnosis was purchasable, and the price
  was one line of stderr.**
- **Fixes, both mutation-proved**:
  1. `Invoke-ReviewCampaignRun` now takes `$FeatureId` and `$RepoRoot` as real parameters, passed from
     `Invoke-ReviewCampaignCommand`, which has both. Passed rather than derived: the caller knows them, and
     a derivation would be a second guess at something already known. An empty `FeatureId` falls back to the
     campaign identity so a display-only field can never again be the reason a pause is lost.
  2. `review-run-reconciler.ps1` writes the pause on its own invoked-publish path. **Any path that spends a
     round owes the pause that lets the human answer for it** - the rule the guard's own comment gestured at
     without stating. Fixed before round 2 rather than deferred, on the maintainer's ruling: an interrupted
     long round is exactly the exposure the next round carries, and round 1 already died once at preflight.
  3. Both fail-softs keep their tolerance and lose their silence: stderr in both, plus a durable
     `.specrew/runtime/review-pause-write-failures.jsonl` trace on the orchestrator path.
- **The guards that did not exist**: no test asserted that a terminal round writes a pause. The orchestrator
  suite had twenty-one green cases over this exact code path and not one of them asked. Added: the terminal
  case now asserts both halves - `$result.pause` (the return value) and `pending-pause.json` read back
  through `Get-ReviewCampaignPendingPause` (the durable fact the blocking guard actually reads), because the
  defect was invisible in the first and detectable only in the second. The reconciliation case asserts the
  same. Reverting either fix turns the suite red.
- **Citation**: FR-013 (structured terminal outcomes per failure class; consumer-shaped failure messages
  that name the missing piece and the exact next step - all three clauses fail here); FR-014 (invoked-only
  spend, which HELD); the refusal standard in FR-033.
- **Resolution**: OPEN, and it blocks round 2. The recovery is to restore the missing pause fact from round
  1's own published result - deterministic, derived entirely from `result.json`, and carrying no human
  judgement - after which the maintainer's typed pause choice can be recorded normally. **Not done without
  approval**: it is a write into the review authority store, and while the pause FACT is machinery catching
  up rather than continuation authority (the DECISION is the human's), an agent repairing the authority
  store on its own initiative is the shape iteration 001's security-surface concern exists to prevent.
- **THE RESTORE — done 2026-08-30 under maintainer approval, option 2 (journal-only provenance).**
  Searchable identifiers, so this record is reachable from any entry point: campaign
  **`cmp-199-beta3-stabilization-i002`**, run **`run-20260829-214056323-db3b4944`**, journal
  **`.specrew/runtime/authority-repairs.jsonl`**, fact
  **`.specrew/review/authority/campaigns/cmp-199-beta3-stabilization-i002/runs/run-20260829-214056323-db3b4944/pending-pause.json`**
  (sha256 `d2445d7c9148ebe27e02edd695462f1a5cedcb9c21d808b2bd642cda3f0a2288`).
  - **The line it sits on**: machinery may restore a fact that RE-ENABLES a human decision; it may never
    write one that CONSTITUTES one. `pause_decision` facts on record: **0**, asserted by the restore
    script itself. The prompt is back; the choice is not written.
  - **Provenance is journal-only, and the fact is byte-for-byte what the engine writes.** Condition 2 as
    originally set - that the restored fact be self-identifying - could not be met:
    `PendingPauseFact` has a CLOSED allowed-field contract (`review-authority-core.ps1:728`) and the store
    refused the added block with `review-store-corruption:invalid-contract:PendingPauseFact:unknown-field:restoration`.
    The maintainer's ruling (2026-08-30) substituted **discoverability by search** for co-location, on the
    stated ground that the repaired fact is no longer the only durable trace: it is one of five, alongside
    the root cause, the fix, the mutation-proved case, this entry, and the repair journal. *"A change of
    evidence and not a change of resolve - if I could not name what changed, we would take option 3 and
    leave the campaign wedged."*
  - **PROVENANCE, CARRIED HERE RATHER THAN CITED**, because both the fact and the journal are gitignored
    (`.gitignore:76` and `:30`) and a future auditor working from the committed tree would otherwise reach
    a pointer to a file they do not have:
    - Reconstructed from that run's own `result.json`
      (sha256 `58f54d74febbcb36ea8638c5c62e5602e9d3cb276d62a464a74c1b986af2bad9`); nothing was defaulted, and
      the script stops rather than defaulting any field it cannot derive.
    - `observed_at` = `2026-08-29T21:56:05.3776575+00:00`, taken from `result.ended_at` - **the moment the
      pause should have been written**, not the time of the repair.
    - `project_name` derived from the campaign identity, which encodes it. Display-only.
    - Restored values: `rounds_used` 1, `budget_total` 4, `blocking_count` 0, `major_count` 0,
      `minor_count` 3, `demoted_count` 3, `evidence_state` produced.
  - **A guard caught the repair itself, and this is worth more than the repair.** The first two attempts
    both wrote `observed_at` as `08/30/2026 00:56:05` - a LOCAL-CULTURE datetime - because
    `ConvertFrom-Json` coerces an ISO timestamp into a `[datetime]` and a bare `[string]` cast then renders
    it in the current culture. The store refused it: `review-authority-timestamp-invalid`. Its validator's
    own comment says exactly why it exists - *"Validate the shape before parsing so culture-permissive
    inputs such as local dates can never become authority."* **A defect introduced by the repair of a
    defect, caught by a guard written for precisely that case.** It was masked on the first attempt by the
    unknown-field refusal firing first, which is a small lesson of its own: a fact that fails two contracts
    reports one, and fixing the reported failure does not mean the fact is sound.
  - **Rolled back twice before it landed**, from the pre-repair snapshot at
    `.specrew/runtime/authority-snapshot-pre-pause-restore-08302026005605` (568 files), with the store
    verified byte-identical by `diff -r` after each rollback. The attempt, the rollback and the successful
    restore are all three journalled, so the journal does not read as a single clean act.
- **Class closure**: NONE - the guards belong with the fixes, and the fixes are beta4 review-economics work
  rather than tag-batch scope. Named now so they are not invented later: (1) the fail-soft must journal the
  exception it swallows, because an absence with no record is unreadable to every later consumer; (2) every
  path that publishes with `Invoked: true` must write a pause, asserted by cardinality - the two call sites
  compared, which is DRIFT-199-I002-011's rule applied to publish paths; (3) a composition test for the
  pause/approve pair, since each message is right alone and they form a loop together - the same
  two-gates-disagree harness beta4 already owes.

### DRIFT-199-I002-019 — a control paid for itself: the timestamp guard caught a defect the REPAIR introduced (positive control evidence, recorded deliberately)

**This entry records a control WORKING. It is filed as a first-class event, at the maintainer's instruction
(2026-08-30), because the ledger has been one-sided about which controls justify themselves — and this
session established the principle itself: a drift log holding only failures teaches the wrong lesson about
which behaviours to repeat.**

- **What happened**: while repairing the dropped pause fact (DRIFT-199-I002-018), the restore script derived
  `observed_at` from round 1's published `result.ended_at` - the correct source, and the one the maintainer's
  own condition required. `ConvertFrom-Json` coerces that ISO string into a `[datetime]`, and the script's
  `[string]` cast then rendered it **in the current culture**: `08/30/2026 00:56:05`.
- **What caught it**: `Test-ReviewAuthorityTimestamp` (`review-authority-core.ps1:96-110`) refused the write
  with `review-authority-timestamp-invalid:pending-pause[run-...].observed_at`. It validates the SHAPE with
  an explicit ISO-8601 regex before parsing, and its comment states exactly why it exists:

  > *"Validate the shape before parsing so culture-permissive inputs such as local dates can never become
  > authority."*

  It also documents why it uses `TryParse` rather than the by-ref `TryParseExact` overload - PowerShell 7.5
  binds that inconsistently on Windows. Someone wrote that guard for a hypothetical, explained the
  hypothetical, and the hypothetical arrived.
- **Why it is the clearest case of a control paying for itself in the fortnight**: a repair of a defect
  introduced a defect, into the **authority store** - the artifact whose entire worth is that its facts are
  true - and the guard stopped it at the boundary. Had it not, the campaign would have carried a pause fact
  timestamped in a local culture, which is precisely the "authority that cannot be compared across machines"
  failure the guard names. And the writer was not careless in an obvious way: it derived from the right
  source, refused to default anything, and still produced a wrong value through a language coercion.
- **The contrast that makes the point**: this batch has catalogued eleven-plus inert controls, a test
  certifying a defect, a tripwire that could not fire, and a fail-soft that destroyed its own diagnosis.
  Against that, here is a control that is cheap, specific, documented, and correct - and it earned its place
  on an input nobody predicted, written by the repair rather than by the feature.
- **Citation**: FR-033's method rules; the maintainer's standing rule that nothing here weakens a gate that
  caught something real - this gate caught something real, in this session, against this session's own work.
- **Resolution**: no action. The repair was corrected to round-trip timestamps explicitly
  (`([datetimeoffset]$Value).ToUniversalTime().ToString('o')`) and the fact then wrote and read back clean.
- **Class closure**: the control IS the closure, and it already exists. What is added is the record that it
  fired, so the next person weighing whether shape-validation-before-parse is worth its lines has one
  measured instance instead of an argument.

### DRIFT-199-I002-020 — the machinery reports one problem at a time, at two different scales (cross-reference; open, beta4)

- **The single-artifact form, measured this session**: the first pause-restore attempt produced a fact that
  violated **two** contracts at once - an unknown `restoration` field and a culture-formatted `observed_at`.
  The store reported the unknown field. Fixing that revealed the timestamp. **A fact that fails two
  contracts reports one, and fixing the reported failure does not mean the fact is sound.**
- **The walk-scale form, the maintainer's finding from the HelloWinUIReactive walk**: serial halting gates -
  **N latent defects cost N round trips**, because each gate halts on the first problem it finds and the next
  is invisible until the previous is fixed.
- **The cross-reference, at the maintainer's instruction (2026-08-30): these are the same family at
  different scales.** In both, the machinery reports one problem at a time while **the reader infers there
  was only one**. That inference is the defect, and it is not the reader's mistake: a refusal that names one
  cause reads as a complete diagnosis, because that is what a refusal normally is. The cost is paid in round
  trips at walk scale and in false confidence at artifact scale - "I fixed what it told me" produces a fact
  that is still wrong.
- **Why it is worth naming as one thing**: the two look unrelated in a backlog - one is a CLI ergonomics
  complaint, the other a validator ordering detail - so they would be fixed separately, or one would be
  fixed and the other left. Named as a family, the remedy is one idea: **a gate that can see more than one
  problem should report all of them, and a gate that cannot should say that it stopped at the first.** The
  second half is nearly free and is the part that repairs the reader's inference.
- **Resolution**: OPEN, beta4. Belongs with the composition-test programme, which is already where the
  "two correct surfaces, nothing arbitrating" findings (DRIFT-199-I002-010, -018's closed loop) are pooled.
- **Class closure**: NONE - the guard is a property of how gates report, and writing it before beta4 decides
  the reporting contract would pin behaviour the design has not chosen yet. Named here so it is fixed as a
  family rather than twice.

### DRIFT-199-I002-021 — one refusal message, two opposite situations, and following it in the wrong one destroys work (open; beta4 refusal standard)

- **Observed**: 2026-08-30, relaying the pause choice for round 2. Two refusals in
  `scripts/internal/review-engine-resolution.ps1` fired in sequence:
  - `:254` `review-engine-project-runtime-drifted: marker=768a08fc...; actual=e6852005...`
  - `:258` `review-engine-version-mismatch: installed=...; project=...`

  **Both end with the same remedy: `run 'specrew update --project-path "<project>"'`.**
- **The remedy is directional, and the message is not.** `specrew update` deploys the INSTALLED module's
  files into the project. That is:
  - **Correct** when the project has drifted BEHIND the installed module - the ordinary consumer case, where
    the project is stale and the module is the source of truth.
  - **DESTRUCTIVE** when the project is AHEAD of the installed module - which is this case, and which is the
    NORMAL case for anyone developing Specrew itself. Here the project carried today's pause fixes
    (`$FeatureId`/`$RepoRoot` as real parameters; the reconciler's invoked-publish pause) and the installed
    module was 0.40.0, which predates them. Following the message literally would have deployed 0.40.0 over
    the fixes and **reverted them** - silently, since a deploy reports success.
- **Two different states produce one message with one remedy.** Nothing in either refusal asks which
  direction the difference runs, and `:258` even prints both hashes - it HAS the information needed to tell
  the cases apart and does not use it to change the advice.
- **Why this one is worth more than the sibling findings**: the supported path exists and is documented -
  `scripts/internal/install-local-build.ps1` states it in its own header (*"Installing the module is only
  one side... refuses every review when the two disagree"*), and the correct sequence is build-from-HEAD
  first, THEN update. That knowledge is what made the difference here. **A beta tester working on the engine
  would not have it**, would follow the refusal as written, and would lose their work to a command that
  reported success.
- **The family, and why it sharpens the case for the beta4 item**: same shape as DRIFT-199-I002-014 (a
  refusal stating a cause that was not the cause) and DRIFT-199-I002-015/-018 (locally correct messages that
  compose into a closed loop). **This is the first instance where following the advice causes DAMAGE rather
  than wasting time.** The refusal-standard work has been argued on diagnosability and friction; this is the
  argument from data loss.
- **Citation**: FR-033's refusal standard; the beta4 UX programme (maintainer ruling 2026-08-28 raising UX
  to top beta4 priority on diagnosability and composition grounds).
- **Resolution**: OPEN, beta4, with the refusal-standard work. The fix is small and the information is
  already present: compare the direction, and say either *"your project is behind the installed module - run
  specrew update"* or *"your project is AHEAD of the installed module - install the current build first
  (scripts/internal/install-local-build.ps1), then update; running update now would replace your project's
  newer engine."*
- **Class closure**: NONE - the guard belongs with the beta4 refusal contract, and inventing a message
  format here would pin wording the refusal standard has not settled. Named so it is fixed as part of that
  contract rather than as a one-off string edit.

### DRIFT-199-I002-022 — round 2: the fail-soft rule was applied to one swallow of two, and the convergence tripwire fires (open; RETURNED TO THE MAINTAINER, no third round spent)

- **The round**: `run-20260830-003634780-04d58169`, campaign `cmp-199-beta3-stabilization-i002`, 2026-08-30.
  Reviewer `codex`, independent of the code writer. 981s; containment verified; completion complete;
  currentness current; verdict `findings`; `can_approve_current: false`. Rounds used **2 of 4**.
  Target `2f9b3bac`.
- **THE FIX PROVED ITSELF AT RUNTIME, and this is the first non-mutation evidence for it**: round 2's own
  run directory contains a `pending-pause.json` **written organically** by the engine
  (`rounds_used: 2`, `budget_total: 4`). The `$FeatureId`/`$RepoRoot` parameter fix is therefore confirmed
  by the machinery doing the thing it had never once done, not merely by a suite going red when reverted.
- **Three findings. Two graded `major` by the reviewer and demoted to `minor`; one graded `minor`.** All
  three verified against the code by this session before reporting.
  1. **`pause-write-error-still-swallowed`** (`review-campaign-orchestrator.ps1:809`) - reviewer **major**,
     shown minor. **CONFIRMED, and it is a defect in this session's own fix.** `Add-ReviewCampaignRoundPause`
     wraps its store write in `try { ... } catch { $recorded = $false }` and then **returns normally** with
     `recorded = false`. Both caller-side catches this session added therefore never fire on a genuine
     authority-store write failure - the callers see a successful return, and the orchestrator hands back a
     non-null pause object. So `REVIEW_PAUSE_WRITE_FAILED` and the durable trace are emitted for an argument
     -binding failure (which is what the root cause turned out to be, and why the trace worked) but **not**
     for the failure mode the trace was written to diagnose. *"Every fail-soft owes a trace"* was applied to
     the outer swallow and not the inner one; there were two in the chain.
     - **The guard is also half-blind, and that is worth saying plainly**: the new assertion
       `$result.pause | Should -Not -BeNullOrEmpty` would PASS with `recorded = false`, because the object is
       returned either way. The sibling assertions - `pending-pause.json` on disk, read back through
       `Get-ReviewCampaignPendingPause` - would catch it. The suite survives this by one assertion, which is
       luck rather than design, and the design lesson is the same one FR-033 already carries: assert the
       durable effect, not the return value.
  2. **`global-marker-misassigns-owner`** (`shared-governance.ps1:1451`) - reviewer **major**, shown minor.
     **CONFIRMED.** With no explicit `SessionId` and no `SPECREW_SESSION_ID`,
     `Get-SpecrewCrossingOwnerIdentity` falls back to the **project-wide** `.specrew/runtime/session-marker.json`,
     which SessionBootstrapManager overwrites on every SessionStart. Session A starts, session B starts in the
     same worktree, A runs boundary sync - and A's child process records **B** as `pending_crossing.owner`.
     Because B is live, the conformance provider then suppresses the packet in A (the session that did the
     work) and demands it from B. **FR-032/SC-019 is not merely defeated, it is inverted.** This is not a
     defect in this session's round-1 fixes; it is a pre-existing defect in the feature those fixes belong
     to, which round 1 did not reach. The maintainer's own working style is the exposure: parallel sessions
     in shared worktrees.
  3. **`numeric-approval-docs-stale`** (`docs/methodology/lifecycle-discipline.md:108`) - reviewer **minor**,
     not demoted. **CONFIRMED at three places: lines 58, 108 and 122.** The guide still calls `1` / `option 1`
     *"the sole authorization signal"* while the gate-stop contract forbids numbered options and holds that
     numeric labels are non-authoritative. **This is not a docs nit**: the file is a DEEP SOURCE loaded into
     agent context by the refocus hook, so it actively teaches the behaviour that caused a measured incident -
     a numbered option was offered, the human's `1` was not captured, and the agent edited and committed on
     the strength of it. Same family as DRIFT-199-I002-010: a rule stated in more than one place with nothing
     deciding which wins, here between the instruction corpus and the contract.
- **THE CONVERGENCE TRIPWIRE FIRES, and no third round was spent.** The maintainer's rule (2026-08-29):
  *"round 2 is the last round unless it finds something that is not a fix for its own findings... If it finds
  new defects in these two fixes, that is not a cue to iterate; it is a signal to stop and ask whether this
  batch is converging at all, and it comes back to me before a third round is spent."* Finding 1 is exactly
  that - a new defect in this session's own fix. **Returned to the maintainer unfixed.** Findings 2 and 3 are
  the other half of the rule: neither is a fix for round 2's own findings, so they are new ground rather than
  the regress the rule was written to prevent.
- **The base rate, stated because the maintainer priced the rule against it**: twelve tasks produced three
  regressions; fixing those exposed three test defects; fixing those produced one more defect in the fix
  itself. Each cycle is smaller than the last - three, then one - but the rate is not zero, and the question
  the rule exists to force is whether that is convergence or a floor.
- **Citation**: FR-033 (the fail-soft trace rule, applied incompletely here); FR-032/SC-019 (finding 2); the
  convergence rule recorded in `plan.md`; the beta4 refusal/instruction-corpus programme (finding 3).
- **Resolution — the maintainer's ruling, 2026-08-30, and what was done under it.**
  - **On convergence, the CLASS is the signal and the count is the weaker one** (maintainer): round 1 found
    three distinct modes - a name mismatch across a seam, a set-never-read, a test certifying a defect. The
    rework found those same three modes again, in the tests. Round 2 found ONE instance of a rule established
    during the previous cycle. *"Fewer instances of already-named modes is convergence; novel modes would not
    be. We are no longer in the second case."* And the decisive framing: *"convergence is not the real answer,
    because you never reach zero on a codebase this well instrumented - you reach a decision."*
  - **Finding 1 - DEFERRED to beta4, because it is what triggered the rule.** *"That is the rule working, not
    a dodge."* The root cause is fixed and proved at runtime; what remains is diagnosis quality for future
    unknown write failures - important, not a tag blocker. The admission stands unedited on the maintainer's
    instruction, as being *"worth more than the fix would be"*: **the suite survives this by one assertion,
    which is luck rather than design.**
  - **Finding 2 - FIXED, and it was undersold in this entry's first draft.** T023 was one of the ten
    tag-blocking items. Under parallel sessions in a shared worktree it does not merely fail, it **inverts**:
    the packet is suppressed in the session that did the work and demanded from the one that did not. That is
    *worse than the TB-6 it fixed* - the original produced noise, this produces a governance stop landing in
    the wrong window - and the exposed configuration is the one this project runs in. *"A tag-blocking fix
    that is wrong in the maintainer's own setup is not shippable."*
    The fix: `Get-SpecrewCrossingOwnerIdentity` trusts the shared, last-writer-wins marker for attribution
    ONLY when it cannot be ambiguous - exactly one live session, counted from the per-session
    `conformance-sessions` directories the provider already maintains. With more than one, ownership reads
    `unknown`, which resolves to indeterminate and renders the demand project-wide: noisy, the pre-FR-032
    behaviour, and never wrong about who owes what. **A wrong owner is worse than no owner** (method rule 12,
    fail open on the diagnosis and out loud - the refusal is written to stderr, not swallowed).
    `Set-SpecrewPendingBoundaryCrossingScope` also gained `-SessionId`/`-HostKind`, so a caller that KNOWS its
    identity binds exactly and never reaches the fallback. **Flagged rather than grown**: threading a session
    id from each host's hook into the sync chain - which today carries none at all, no parameter and no env
    seam - is the complete binding and is beta4.
    Mutation-proved: disabling the ambiguity gate turns `crossing-owner` case 8 red. Cases 8b and 8c pin the
    two halves the fix must not break - a single live session still resolves to its identity (FR-032 is not
    made inert), and an explicit session id wins over the marker even under concurrency.
  - **Finding 3 - FIXED, by deletion.** *"It is a deletion and it is actively teaching a measured defect."*
    All three passages in `docs/methodology/lifecycle-discipline.md` (lines 58, 108, 122) now say the typed
    phrase is the sole authorization signal and that a number is not one of its forms, with the two-host
    measurement recorded inline. Instruction-layer causation, F-3's family: the file is loaded into agent
    context by the refocus hook, so the guidance was the mechanism.
- **SEQUENCE, fixed by the maintainer with a hard edge**: fixes 2 and 3 -> the walk, both parts -> fix what
  the walk finds -> **round 3, which is the LAST round**. Two remain in the allowance and one is spent.
  Whatever round 3 finds is recorded and triaged to beta4 unless it would block a tester's first hour.
  *"There is no round 4, and I am committing to that now rather than deciding it under the pressure of a
  fresh finding."*
- **Class closure**: NONE - the fixes are the maintainer's call under the convergence rule, and inventing
  guards for changes that may not be authorized is the shape this batch has repeatedly ruled against. Named
  in advance: (1) treat `recorded = false` as the fail-soft diagnostic path in both callers, or propagate the
  cause, and assert the DURABLE effect rather than the returned object; (2) bind boundary sync to the
  invoking session identity, or use a per-session marker instead of the last session started anywhere in the
  project; (3) remove the numeric-approval path from the guide, or scope it to a surface that still renders
  approval as option 1.

### DRIFT-199-I002-023 — the walk: two greenfield fixes proved in a real project, and one new defect that only a real project could show (fixed same session)

**The validation walk the maintainer moved AHEAD of review-signoff, exactly so this would be found before
signoff rather than after it.** Project: `C:\Dev\HelloWinUIReactive`, updated to the build from `cb497fe2`.

- **T016 PROVED IN THE FIELD.** HelloWinUIReactive has **no git remote** - the no-origin condition T016
  addresses, and one this repository cannot reproduce from inside itself. The specify preflight now reports:
  - `pushed-head` -> **not-applicable**: *"Release model 'pr-flow' governs closeout delivery only; nothing is
    owed to origin."*
  - `verdict-commit-durable` -> **not-applicable**: verdicts bind to commit `11705e27` and later gates
    resolve it back.
  Both origin-dependent checks stand down in a project with no origin. This is the TB-3/FR-025 split doing
  in a real consumer what its mutation could only assert.
- **T020 PROVED IN THE FIELD.** A second feature was created in that project
  (`002-settings-page-where`). The scaffolded spec is the stub, verbatim: the `specrew:spec-not-yet-authored`
  sentinel, **zero** placeholders and **zero** `FR-\d{3}` ids, the sentence *"This specification has not been
  written yet, and that is deliberate"*, and the two prohibitions the original walk violated - *"do not write
  requirements into it, and do not delete it."*
- **NEW DEFECT, FOUND ONLY BECAUSE THE WALK RAN — and it is the sharpest kind of refusal defect: specific,
  confident and false.** The specify preflight reported:

  > `owed-artifact  fail  Boundary 'specify' is missing owed evidence: spec.md.`

  **`spec.md` exists on disk.** Naming the same project with `-Feature 001-reactive-ui-tutorial` makes the
  identical check **pass**. The cause: with no resolvable feature - the ordinary state of a project whose
  `start-context.json` carries no `feature_ref`, which is exactly what an interrupted walk leaves behind -
  `$base` is `$null`, and every owed path was added to `$missing` unconditionally. **Nothing was checked, and
  a definite absence was reported anyway.**
  - **Two readers of one contract, disagreeing, and the wrong one is the one a human meets.** FR-024's
    `Test-SpecrewBoundaryOwedArtifactsOnDisk` - written in THIS iteration - already draws the distinction and
    returns `Absent=$false` with no feature identity, because *a positive ABSENT reading refuses loudly while
    UNVERIFIABLE keeps today's behaviour* (method rule 12). Verified directly against the same project: the
    mint-side reader says `Absent=False`, the preflight said missing. Same family as DRIFT-199-I002-010 and
    -020: two surfaces, nothing arbitrating.
  - **Resolution — FIXED same session.** The preflight now separates the two answers: unresolvable feature ->
    `not-applicable`, with a message that names the actual limit and the one action (*"could not resolve which
    feature it belongs to, so nothing was checked... pass -Feature <feature-ref>, or record the active feature
    in .specrew/start-context.json"*). A resolvable feature still checks for real, so the fix does not blind
    the control. Verified against the live walk project: the failing case now reads `not-applicable`.
  - **Mutation-proved**: restoring the unconditional-missing behaviour turns two assertions in
    `tests/unit/gate-preflight.Tests.ps1` red - one that no file is called absent when none was looked for,
    one that a named feature still passes.
- **What the walk could NOT do, stated rather than glossed**: T017 and T018 need a workshop with **typed human
  answers**. The new feature's controller exists before the first question (as CLAUDE.md requires) and carries
  `human_turn_contract: typed-turns-v1`, `agenda_status: pending-confirmation`, empty agenda - so the fresh
  workshop is staged and waiting. Simulating those answers would fabricate exactly the evidence this walk was
  moved earlier to obtain. **Handed back to the maintainer**: two or three lenses is the stated bar - whether
  the controller advances on confirmation, and whether a lens record is validated where it can still be fixed.
- **An observation, deliberately NOT filed as a defect**: `create-governed-feature.ps1` printed
  `BRANCH_NAME: 002-settings-page-where` while `git branch --list` shows only `master`. The governed script
  RELAYS that value from the upstream scaffold rather than creating the branch itself, so whether a branch was
  owed here is a question about upstream behaviour in a no-remote repository, not an established defect.
  Recorded as a thing to check, not a thing to claim - DRIFT-199-I002-014's rule.
- **Citation**: FR-025 (T016), FR-029 (T020), FR-024 (the absent/unverifiable distinction the preflight was
  missing), method rule 12, FR-033's refusal standard.
- **Class closure**: the guard is the new `gate-preflight` case above, and the generalisable form is already
  named in FR-024's own comment: **a check that cannot look must say it did not look.** Reporting a specific
  absence is a claim about a file; reporting unverifiable is a claim about the check. They are different
  sentences and only one of them can be false about the world.

### DRIFT-199-I002-024 — two of the ten tag-blocking items shipped nothing, and every guard they passed was true (fixed same session)

**The maintainer's finding, 2026-08-30, before the workshop ran:** `confirm-workshop-lens.ps1` is absent
from `Specrew.psd1`'s `FileList` - the only one of the 45 extension scripts missing, with its sibling
`confirm-workshop-agenda.ps1` listed at line 113. *"It exists in both mirrors, passes parity, passes its
mutation tests, and reaches no downstream project. HelloWinUIReactive has T020's stub and not the lens
writer, which is why."*

- **THE PACKAGE IS THE FileList.** `New-ReleaseStageRoot` (`scripts/internal/module-packaging.ps1:245`)
  stages exactly the manifest's entries and nothing else. Absence from it is absence from the installed
  module, and therefore from every project - independent of mirrors, parity, and suites.
- **The class was COMPUTED, not eyeballed, and it found a second.** Every file added since tree `1b50ae60`
  was diffed against the FileList: **917 files added, 2 of them machinery, and BOTH absent.**
  1. `extensions/specrew-speckit/scripts/confirm-workshop-lens.ps1` — T027/FR-027, the governed lens
     checkpoint writer. **T018 did not ship.**
  2. `scripts/internal/constrained-yaml.ps1` — FR-026 (TB-4), the shared constrained-YAML reader. **TB-4 did
     not ship.** The maintainer checked extension scripts and found the first; the second is in a different
     file type, which is precisely why the instruction was to check the class.
- **The second is worse than merely missing.** `code-implementation-lens.ps1:175` and
  `product-domain-lens.ps1:153` both load it as `if (Test-Path -LiteralPath $path) { . $path }` - so
  downstream the file is silently skipped, `Get-SpecrewConstrainedYamlParseFailureMessage` is simply
  undefined, and FR-026's whole purpose (a constrained reader that NAMES the representation it could not
  parse) is unavailable. **A silent degrade guarding a file that was never packaged.** Both dependents are
  in the FileList; only the thing they depend on was not.
- **Verified end to end rather than assumed**: before, both absent from the installed module and from
  `C:\Dev\HelloWinUIReactive`. After adding the entries, rebuilding (412 -> **414 files**), reinstalling and
  updating the project: both present in the module, and `confirm-workshop-lens.ps1` present in the project
  **carrying the FR-027 fixes** (`human_turn_receipt`, receipt-carried scope).
- **THE MIRROR-PARITY RULING WAS WRONG, and the maintainer recorded it as theirs**: *"I told you the parity
  test guarded the inert-fix hazard and to rely on it instead of building a second guard. It covers
  divergence between mirrors, not omission from the package. Your original instinct — that a fix can pass
  its tests and stay inert — was right in a way neither of us located."* Both mirrors were byte-identical
  the whole time. Parity was true and irrelevant: two identical copies of a file that ships to nobody.
- **Resolution**: both entries added in sorted position (`psd1-sort.ps1` clean), and a new guard registered
  in the CLASS-GUARD lane, `tests/unit/package-filelist-completeness.tests.ps1`. It **computes** the omission
  set - for every directory the FileList already covers, every same-kind file on disk must be listed -
  because a hand-enumerated guard over a hand-enumerated manifest repeats the defect one layer up
  (DRIFT-199-I002-011's rule, applied to the guard itself). `docs/` is excluded by name and with a reason:
  it is selectively packaged by design, 11 of 28. Mutation-proved: removing either entry turns both the
  instance case and the computed class case red.
- **Class closure**: the computed guard above. The generalisable statement is the one that made it findable:
  **a fix is not shipped until something a consumer runs can reach it**, and mirrors, parity and green
  suites are all upstream of that question.

### DRIFT-199-I002-025 — a host-regression diagnosis, RETRACTED by the maintainer; the per-event guard it motivated is kept on its own merits

**RETRACTED, 2026-08-30, by the maintainer who made it, within hours of making it:**

> *"Retract the Codex host finding before you act on it — I was wrong. UserPromptSubmit fires on Codex CLI
> 0.151.0: a fresh project at C:\Temp\ConsoleFractal minted a product-domain receipt with
> `source_event: UserPromptSubmit`, `host_kind: codex` today. Whatever blocked HelloWinUIReactive, it is not
> a host-level event regression, and I do not have its cause. Do not build per-event hook health on my
> say-so; the per-event idea stands on its own merits but the motivating diagnosis was mine and it was
> wrong."*

**The original report, preserved because a retraction that deletes its own subject teaches nothing**:
Codex CLI 0.151.0 in `C:\Dev\HelloWinUIReactive` was observed writing SessionStart and Stop receipts and no
`UserPromptSubmit` receipts, with two typed replies producing nothing. **The observation about that one
project stands; the inference to a host-level regression does not.** Its cause is unknown and is not
diagnosed here.

**What I did with the retraction.** The guard is KEPT - the maintainer's ruling - and its justification was
**rewritten in code**, not just here: the header of `hook-health-receipt.ps1` and every comment and assertion
message in `tests/unit/hook-event-coverage.tests.ps1` now state that the motivating diagnosis was retracted
and that no assertion claims anything about any host's behaviour. Leaving a true guard standing on a false
story would have made the story load-bearing.

**This is the second wrong finding to survive into a ruling this batch, and the direction reversed.** In
DRIFT-199-I002-014 I produced a wrong finding and the maintainer ruled on it; here the maintainer produced
one and I began building on it. The structural point is the same and worth stating once: **a finding that
reaches a boundary becomes an instruction, and neither role has a monopoly on being wrong.** What caught it
both times was the same thing - running the subject rather than reasoning about it.

- **What I verified, and what verification did NOT establish.** I confirmed the store's contents -
  99 receipts, all `source_event: UserPromptSubmit`, all `host_kind: codex`, last `2026-08-28T20:48` - and
  reported that as independent reproduction. **It was not.** It reproduced the OBSERVATION (that project's
  store has no recent receipts) and I let it stand as support for the DIAGNOSIS (the host stopped firing the
  event), which the same evidence cannot distinguish from a dozen project-local causes. Confirming a symptom
  is not confirming a cause, and the write-up did not keep them apart.
- **THE GAP THE GUARD CLOSES, which is independent of the retracted story**: `hook_status` classifies
  AGGREGATE liveness (*is there a fresh, well-formed receipt*); per-event checking exists for
  **registration** and for **arrival of SessionStart only**. **Registered is not fired**, and nothing
  compared the declared set against the arrived set. The maintainer's framing of what is ours survives the
  retraction intact: *"Making Codex fire the event may not be yours to fix. Detecting that a required event
  is not firing, and refusing to claim governance when it is not, is."*
- **Both sets were already computable, and nothing compared them.** Receipts are keyed per
  `(host, surface, event)` as `<host>-<surface>-<event>.json`; that project's store held
  `codex-cli-sessionstart.json` and `codex-cli-stop.json` and **no `codex-cli-userpromptsubmit.json`.** The
  declared set is equally available from the host manifest's `RefocusHookBindings` Registrations. **The
  identical shape as DRIFT-199-I002-024**: the package was the manifest and nothing checked what sat beside
  it unlisted; here the health verdict is the receipt store and nothing checked what was declared and absent.
- **Why health said healthy - the FOURTH guard-scope instance in one day**: `hook_status` classifies
  AGGREGATE liveness (*is there a fresh, well-formed lifecycle receipt*) rather than per-event arrival. Its
  per-event checking covers **registration** - `Get-SpecrewHookMissingEventRegistrations` asks whether each
  declared event has a Specrew entry in the config - and its per-event **arrival** check covers SessionStart
  only. Registered is not fired. That gap is why this needed a diagnostic session instead of surfacing at
  the first missed receipt.
- **Resolution — the detection is fixed here; the host behaviour is not ours.**
  `Get-SpecrewHookEventCoverage` (in the non-protected receipt module, the designated extension point)
  computes declared vs observed and names the difference. Run against the live project it reproduces the
  maintainer's diagnosis exactly: *declared* `SessionStart, UserPromptSubmit, Stop`; *observed*
  `sessionstart, stop`; **missing `UserPromptSubmit`**; `complete=False`.
  - **A precision error caught in my own first draft, recorded because it is the same family**: the initial
    flag fired only when EVERY capture event was silent - and `Stop` IS alive here, so it read false on the
    exact case it was written for. A typed reply is minted at `UserPromptSubmit`, so `Stop` firing is not
    evidence that an approval can be recorded. Replaced with `prompt_capture_silent`, which reports the
    typed-capture path on its own terms and reads **true** here.
  - **`determinable`**: a host whose manifest does not resolve declares nothing, and the function reports
    unknown rather than manufacturing a refusal from a missing manifest - the absent-versus-unverifiable
    distinction from DRIFT-199-I002-023, applied before it could be got wrong again.
  - Guard `tests/unit/hook-event-coverage.tests.ps1`, registered in the CLASS-GUARD lane. Mutation-proved:
    removing the declared-vs-observed comparison turns four assertions red.
- **Citation**: FR-033's refusal standard; the beta4 guard-scope principle (this is its fourth instance);
  DRIFT-199-I002-024 (same computable-sets-never-compared shape).
- **Class closure**: the computed guard above. **Registered is not fired, and aggregate liveness is not
  per-event arrival** - wherever a control declares a set and observes a set, the comparison is the control.
- **Still open, and correctly framed this time**: why `C:\Dev\HelloWinUIReactive` specifically stopped
  producing `UserPromptSubmit` receipts, when the same host on a fresh project produces them. A
  PROJECT-LOCAL question with no established cause, recorded for beta4's host-support work. The walk moved
  to Claude Code.

### DRIFT-199-I002-026 — "name one reachable action" is insufficient: the action has to be reachable from the state the reader is in (open; beta4 refusal standard)

- **The maintainer's finding, 2026-08-30**: the Codex session's own advice was *"open this project through
  the verified Codex CLI"* **while it was already running on the Codex CLI.**
- **Third instance in a single day of remedy text that is locally sensible and unreachable from the
  reader's actual state**, and the three failure directions are all different:
  1. **DRIFT-199-I002-021**: `run specrew update --project-path` told to a project AHEAD of its installed
     module - following it would have **reverted** the fixes. *Damage.*
  2. **DRIFT-199-I002-018**: the wedged pause sent the reader to `--pause-choice`, which found no pending
     pause and redirected to `--approve-round`, which returned to the pause guard. *A closed loop.*
  3. **This one**: a host telling the reader to switch to the host they are on. *A no-op.*
- **What it establishes about the standard we have been writing to**: FR-033's refusal clause requires a
  refusal to name what is wrong, say the human's work is safe, and give **one concrete action**. All three
  refusals above satisfy that clause completely. **The clause is necessary and not sufficient** - an action
  is only concrete relative to a state, and none of these knew the reader's. The missing requirement:
  **a refusal must be reachable from the state the reader is in, and that means the refusal has to know
  that state.**
- **Applied immediately, in the one refusal written today**: `Get-SpecrewHookEventCoverageRefusal` names the
  host the reader is actually on and offers a **different** one, and its guard asserts that it does not
  reproduce the "open it on the host you are already using" shape. One instance is not the fix; the standard
  is beta4's.
- **Citation**: FR-033's refusal standard; the beta4 UX programme (maintainer ruling 2026-08-28, UX raised
  to top beta4 priority on diagnosability and composition grounds - this is the diagnosability half, with
  three measurements behind it).
- **Resolution**: OPEN, beta4, with the refusal-standard contract. The concrete form: a refusal that
  proposes a host, a command, or a mode must first establish that the reader is not already in it.
- **Class closure**: NONE - the guard belongs with the beta4 refusal contract, and a bespoke check for each
  refusal would be the hand-enumeration this batch keeps ruling against. The one guard written today covers
  the one refusal written today, and is not claimed as covering the class.

### DRIFT-199-I002-027 — T018 deadlocked the first lens of every greenfield workshop, and the suite was green because its fixture wrote a state the real flow cannot produce (fixed)

**The maintainer's finding, 2026-08-30, from starting an ordinary new project** - not from any test.
`confirm-workshop-lens.ps1` refused any lens absent from the controller's `selected` list. `selected` holds
the technical lenses the agenda chose. **`product-domain` is never in it and structurally cannot be** - it
is the intake lens that PRODUCES the agenda. So the governed writer had no path to close the first lens of
every workshop, and every greenfield feature stopped there.

- **Verified structurally rather than taken on report** (three independent sources, all in the shipped code):
  1. `confirm-workshop-agenda.ps1:148` builds the selectable catalog as
     `... | Where-Object { $_ -cne 'product-domain' }` - the intake lens is **excluded from `selected` by
     construction**, and line 98 requires *"at least one technical lens"*.
  2. The design-workshop skill's step 7 names the writer as *"the ONE thing that closes a lens"* and
     explicitly lists **`product-domain`** among the lenses whose own artifact it validates. So the agent is
     instructed to close the intake lens with a writer that structurally refuses it.
  3. The transition table already carried a `pending-product-projection` state class - *pending agenda,
     exactly one workshop key, and it is `product-domain`* - **a legal state nothing could legally produce.**
     The design anticipated this; only the writer did not.
- **The two refusals compose into a closed loop**, the pause-recovery shape again: line 94 says *"confirm the
  workshop agenda first"*; the agent goes to confirm the agenda; `confirm-workshop-agenda.ps1:138` says the
  product-domain records must be persisted first; closing product-domain is what persists them. Each message
  correct alone, jointly a trap.
- **A SECOND blocker, found only because the first was not fixed in isolation.** Intake turns are minted
  under `phase: 'product-domain'` - measured in the field, HelloWinUIReactive's store holds 12 of them -
  while the writer looked the receipt up under `phase: 'lens'`. Fixing only the membership check would have
  moved the deadlock one line down and told the human *"no typed reply from you is on record"* about a reply
  that was. **A fact that fails two contracts reports one** (DRIFT-199-I002-020), now measured a second time.
- **Why the suite was green, and this is the fourth time this week mutation-green failed to predict field
  behaviour**: every fixture in `workshop-lens-checkpoint.tests.ps1` passed `product-domain` to `-Selected`
  inside a **confirmed** agenda - a state the real flow cannot produce. The fixture wrote the precondition
  the product denies. Mutation proving showed the control wired to its own test; the test was wired to a
  fiction.
- **Resolution — fixed at all three gates, scoped so the technical path is untouched**:
  1. **One definition of the intake set.** `Get-SpecrewWorkshopIntakeLenses` / `Test-SpecrewWorkshopIntakeLens`
     in the authority store, now read by the agenda catalog too. The set was previously implied in three
     places that could not disagree out loud (the catalog filter, the `pending-product-projection` class, the
     receipt phase ValidateSet) and the writer knew none of them.
  2. **A transition cell that exists**: `confirm-intake-lens`, allowed from `pending-empty` and
     `pending-product-projection` - which is exactly how the controller REACHES
     `pending-product-projection`. `confirm-lens` still requires `confirmed-complete`.
  3. **The receipt phase matches the turn**: intake lenses are looked up under their own phase.
  Mutation-proved independently: reverting any one of the three turns four assertions red.
- **Two fixture defects of my own, found by writing the field-shaped case and recorded rather than quietly
  fixed**: `return , @('product-domain')` double-wrapped the array so `-ccontains` was always false; and
  `selected = $(if ($PreAgenda) { @() } ...)` collapsed to `$null`, because an empty array emits nothing to
  the pipeline - and `@($null).Count` is **1**, so the fixture read as one selected lens and classified
  `pending-inconsistent`. Both were caught in minutes by a test shaped like the field; neither would have
  been caught by any amount of mutation of the old fixture.
- **Citation**: FR-027 (T018/T027); FR-033's method rules; DRIFT-199-I002-020 (two contracts, one report);
  the beta4 guard-scope principle.
- **THE FIX WAS INSUFFICIENT, AND ONLY THE RESUMED PROJECT COULD SHOW IT** (2026-08-30). The maintainer
  directed the walk to `C:\Temp\ConsoleFractal` - already deadlocked at this gate - rather than a fresh
  one, on the ground that *"case 7 is a better fixture than the ones before it, and it is still a fixture."*
  That was decisive within minutes. Its real state:

  > `agenda_status: confirmed`, `agenda_confirmation: human-confirmed`, six technical lenses in `selected`
  > (product-domain not among them, as expected), and **`workshop` EMPTY** - the intake lens never recorded.

  Resolved read-only against the shipped table, that state is `confirmed-complete`, where **both operations
  refused**: `confirm-intake-lens` because the state was no longer pending, `confirm-lens` because
  product-domain is not in `selected` and structurally never will be. **The pending-only fix unblocked new
  workshops and left every already-advanced project exactly as stuck.**
- **How that state is reachable, which I had not seen**: `confirm-workshop-agenda.ps1` requires the
  product-domain **records on disk** (`product-domain.md`/`.yml`) and not the controller **entry**, so a
  workshop can pass the agenda with the intake lens still unclosed. Every project that did so is stranded.
- **Resolution — `confirmed-complete` added to the intake transition**, as the recovery path rather than for
  symmetry, and verified read-only against the live ConsoleFractal controller (`allowed=True`). Case 7c pins
  it, including that recovery does **not** smuggle product-domain into `selected`: the agenda the human
  confirmed is left exactly as they confirmed it. Mutation-proved: dropping `confirmed-complete` turns two
  assertions red.
- **What this says about the evidence hierarchy, and it is the reason the maintainer sent me to a real
  project**: my case 7 fixture could not have invented this state, because I did not know it was reachable.
  A fixture encodes what its author believes the product can do; the states it cannot imagine are exactly
  the ones that strand real users. **A resumed failing project is not a slower version of a test - it is a
  different kind of evidence**, and it caught a shipping defect that a green suite, a mutation proof and a
  field-shaped fixture all missed in the same hour.
- **One measurement I could not confirm, stated rather than smoothed over**: the brief described *"twelve
  real intake receipts"* in that project; its `workshop-authority.jsonl` holds **2** (one `product-domain`
  phase, one `agenda` phase, both `source_event: UserPromptSubmit`). The twelve-receipt figure matches
  HelloWinUIReactive's store, not this one. It changes nothing about the finding - one intake receipt is all
  the gate needs - and it is recorded because the last time a count was carried between projects without
  checking, it became a wrong diagnosis (DRIFT-199-I002-025).
- **Class closure**: cases 7, 7b and 7c in `tests/integration/workshop-lens-checkpoint.tests.ps1`, and the
  fixture's new `-PreAgenda` mode, which builds the state a brand-new feature is ACTUALLY in. The
  generalisable rule is the one the maintainer drew, and it now heads the beta4 guard-scope principle:
  **the fixture wrote the precondition the product denies.**

### DRIFT-199-I002-028 — method rule 12 was applied to checks and never to writers, and the repair path is gated on the wrong step (open; beta4)

Both recorded at the maintainer's instruction, as *"the reason this is a deadlock rather than an error"*.

- **1. A GOVERNED WRITER THAT REFUSES MUST STILL LEAVE A LEGAL NEXT MOVE.** Method rule 12 - fail open on the
  diagnosis, out loud - has been applied consistently to CHECKS: the owed-artifact preflight now reports
  unverifiable rather than absent (DRIFT-199-I002-023); crossing ownership reports unknown rather than
  guessing (DRIFT-199-I002-022); the coverage guard reports undeterminable rather than manufacturing a
  refusal. **It was never applied to WRITERS.** The T018 refusals were each individually correct and left
  the reader with no legal move at all - *"close one of the agreed topics instead: "* naming nothing, and
  *"confirm the workshop agenda first"* pointing at a step that required the very thing being refused. **A
  refusal with no reachable next move is a deadlock wearing the costume of a diagnosis.**
  - Applied immediately where this session touched it: the intake and technical transition refusals now
    carry different actions, because they fail for opposite reasons and one shared sentence cannot name a
    move available from both; and the membership refusal names `(none yet - the agenda has not been
    confirmed)` rather than an empty list. One writer is not the class.
  - **The general form for beta4**: every governed writer's refusal paths owe the same audit a check's do -
    what is the reader's next legal action from HERE, and does the message name it. This is the writer-side
    half of DRIFT-199-I002-026's state-awareness: an action must be reachable, and a refusal that leaves
    none is the extreme case.
- **2. THE REPAIR PATH IS GATED ON THE WRONG STEP.** To get out of the deadlock the agent had to ask the
  human to authorize **preparing a read-only proposal that changes nothing**. *"Preparing should be free;
  only applying should need a human. That single change would have made this incident and the campaign wedge
  cheap instead of expensive."*
  - The cost is measurable across this batch: the review-campaign wedge (DRIFT-199-I002-018) took a
    diagnostic session, a rollback, and two maintainer decisions before anything could be proposed; this
    deadlock took another. In both, the expensive part was not the repair but the round trip to be allowed
    to draft one.
  - **The principle**: human authorization is for CONSEQUENCE, not for effort. A read-only proposal has no
    consequence - it changes no artifact, spends no allowance, and authorizes nothing - so gating it buys no
    safety and costs a boundary. The gate belongs on APPLY.
- **Resolution**: OPEN, beta4, with the refusal-standard and repair-path work. Neither is a tag blocker; both
  are why the tag batch has been expensive.
- **Class closure**: NONE - both are contract-level changes (a refusal-path audit across every governed
  writer; a prepare/apply split in the repair authority), and writing either as a bespoke guard here would
  be the hand-enumeration this batch keeps ruling against.

### DRIFT-199-I002-029 — two refusals that describe what they checked and misdescribe what went wrong (both fixed; T018 proved in the field)

**T018 IS PROVED, on the state that broke it.** The maintainer closed `product-domain` in
`C:\Temp\ConsoleFractal` through the **recovery** path and `architecture-core` through **`confirm-lens`** -
both transitions exercised on a real, previously-deadlocked project rather than a fixture. That is the
evidence this iteration was missing, and it is the first time a greenfield-path fix in this batch has been
confirmed by anything other than its own suite.

Two defects surfaced during that run. Both are the same family, and both were verified at source here
before being touched.

- **1. The binding refusal named the wrong field, confidently.** `ProjectMetadataAccessor.ps1:245` validated
  name and value in a single `-or`:

  > name `^[a-z][a-z0-9.-]{0,63}$` - dot and hyphen, **no underscore**
  > value `^[a-z0-9][a-z0-9._-]{0,127}$` - dot, hyphen **and underscore**

  The workshop was rejected for the NAME `decomposition_style`; the refusal
  (`specrew-conformance-provider.ps1:1770`) said *"decision '<name>' has value '<value>'"*, **printed a value
  that was perfectly valid**, and offered a **casing** example (`ihttpclientfactory`, not
  `IHttpClientFactory`) with nothing to do with underscores. *"The agent recovered by trial rather than by
  reading the message."*
  - **The wording was downstream of the cause**: a single `-or` cannot say which side failed, so the conflict
    record carried nothing to name and the message named the wrong thing. Fixed at the source - the conflict
    now carries `failed_field`, `failed_text` and `failed_rule`, and the refusal has separate branches that
    name the field that failed and the rule that failed it. The name branch says the value needs no change;
    the casing example lives only where casing is the problem.
  - **The asymmetry**: *"two patterns differing in exactly the character that trips people is a trap."*
    Documented here and at the validator, and **pinned by tests in both directions** so it cannot drift while
    the schema question is open: an underscore IS legal in a value, and a dot IS legal in a name. Widening
    what the validator ACCEPTS is a contract change and was not made mid-batch; **beta4 decides whether the
    name pattern gains `_` or the difference is surfaced where an author meets it.** Recommendation on the
    record: gain the underscore - the rule's purpose is stable lowercase tokens, and `_` is one.
- **2. A six-element `-Agenda` array was absorbed across positional parameters** in
  `confirm-workshop-lens.ps1`, landing an agenda string in `-Confirmation`. The `ValidateSet` caught it
  **loudly, which is correct** - but the message named `Confirmation` while the cause was `Agenda`. Fixed
  with `[CmdletBinding(PositionalBinding = $false)]`: every parameter must be named, so the failure now
  reports as *"A positional parameter cannot be found that accepts argument..."* - at the place it happened.
  Verified by invoking the writer positionally in the guard, not by reading the source.
- **THE FIFTH INSTANCE, and the reason the beta4 standard needs a stronger clause** (maintainer, 2026-08-30):
  with the `specrew update` advice (-021), the closed-loop pause recovery (-018), the Codex-CLI advice
  (-026) and DRIFT-199-I002-020, this is five. *"The refusal accurately describes what it checked and
  misdescribes what went wrong... the standard's clause cannot just be 'name one reachable action', it has
  to be 'name the thing that actually failed.'"*
- **Citation**: FR-033's refusal standard; DRIFT-199-I002-026 (reachable-from-here) and -020 (two contracts,
  one report), which this completes into one clause.
- **Class closure**: `tests/unit/refusal-names-what-failed.tests.ps1`, in the class-guard lane. It pins the
  attribution in both directions, the asymmetry in both directions, that the name branch carries no casing
  advice, and that a positional call fails as a positional problem. Mutation-proved on both fixes.

### DRIFT-199-I002-030 — round 3: a BLOCKING-graded finding, demoted to minor, and it wedged every next iteration (fixed; 2 and 4 to beta4)

- **The round**: `run-20260830-160011946-a3d8338c`, 2026-08-30, reviewer `codex`, 856s; containment verified;
  completion complete; currentness current; verdict `findings`; `can_approve_current: false`. **Rounds used
  3 of 4.** Target `df2edd1f`. The last round under the convergence rule.
- **Four findings. The reviewer graded ONE BLOCKING and three MAJOR. All four were shown as `minor`.** This
  is the first `demoted_from: "blocking"` in the campaign, and it is the strongest evidence yet for
  DRIFT-199-I002-016's reclassification of B-3 as a RECORD defect: the campaign's durable counts now read
  `blocking_count: 0` for a round whose reviewer reported one.
- **FINDING 1 - `cycle-reset-mirror-wedge` - reviewer BLOCKING - REPRODUCED EMPIRICALLY, not read.**
  `sync-boundary-state.ps1:917` passes the **global** `last_authorized_boundary` into
  `Sync-SpecrewCrossingMirrors` with the **current** iteration number. On the first `plan` sync of a NEW
  iteration the global last authorization is the PREVIOUS iteration's `iteration-closeout`, so the new
  iteration's plan scaffold is forward-written past its own state. Measured on a fixture:

  > `BEFORE: **Status**: planning` -> first plan sync -> `AFTER: **Status**: complete`
  > -> later `plan` authorization -> `AFTER plan auth: **Status**: complete`

  The mirror is forward-only by design, so nothing moves it back, and the following `tasks` sync rejects a
  plan mirror reading `complete` where `planning` is required. **Every next-iteration cycle wedges,
  deterministically.** This directly contradicts the batch's own acceptance bar - *"a consumer completes
  their first feature without hitting an endless review loop, A WEDGED GATE, or a sentence they cannot
  understand"* - and the mechanism is this iteration's own FR-030/T021 work.
- **FINDING 2 - `hook-event-guard-unwired` - reviewer MAJOR - CONFIRMED, and it is mine from today.**
  `Get-SpecrewHookEventCoverage` has **zero production callers**: the only references are its own definition
  and its own test file. **I built an inert control**, hours after naming the inert-control family
  repeatedly in this same log, and its suite is green because it exercises the helper directly. The guard
  detects that prompt capture is silent and nothing asks it, so boundary flows still present approvals that
  cannot be recorded. *A control that exists but never runs* - the twelfth-odd instance, and the second this
  batch has introduced rather than removed.
- **FINDING 3 - `bare-marker-bypasses-identity` - reviewer MAJOR - the KNOWN, PINNED residual.** This is
  case 4c, deliberately retained with its closure condition after the maintainer's ruling that carrying the
  renderer work was defensible. The reviewer is right on the merits and is describing a gap the record
  already declares - including that *"the regression test explicitly preserves this as a known gap"*, which
  is what a pinned gap looks like from outside. Not new; the closure condition is unchanged.
- **FINDING 4 - `fresh-state-mirror-fields-missing` - reviewer MAJOR - CONFIRMED at source.** The fresh
  `state.md` scaffold omits `Current Phase` and `Iteration Status`; the mirror writer deliberately refuses to
  invent them (`'state.md has no Current Phase line; not invented'`, `shared-governance.ps1:3823`); and the
  truth checker validates `Current Phase` only when already nonempty. Three individually correct rules that
  jointly permit early `plan`, `tasks` and `before-implement` crossings to complete with no state mirror and
  **no mismatch reported** - FR-030's "every enumerated mirror agrees immediately after each crossing" is not
  met on a fresh iteration. Same composition shape as DRIFT-199-I002-010 and -018.
- **Convergence status**: round 3 was the last round and there is no round 4. Findings 2, 3 and 4 are
  recorded for beta4 under the standing triage. **Finding 1 is the exception that triage names**: it is a
  deterministic wedge, and a wedged gate is the acceptance bar this batch exists to clear. Recorded with its
  reproduction so the decision is made on evidence rather than on a severity label the record had already
  demoted to `minor`.
- **Citation**: FR-030/T021 (findings 1 and 4); the acceptance bar in the feature spec; DRIFT-199-I002-016
  (B-3 as a record defect - now demonstrated on a `blocking` grade); the inert-control family (finding 2).
- **Resolution — the maintainer's ruling, 2026-08-30, and what was done under it.**
  *"Your triage rule does not cover it: that rule was for newly discovered pre-existing defects, and this is
  a regression T021 introduced. Same ruling as round 1's findings 1 and 2 - the batch's own work being
  incomplete is not scope growth, and a fix that wedges every second iteration is not a fix."* And on the
  commitment: *"No round 4. The commitment was about rounds and not about fixes, and it carried its
  exception clause for this exact case."*
  - **FINDING 1 - FIXED.** The replay is now capped at the boundary being synced: a stored authorization
    LATER than the boundary in hand is not written into this iteration's copies. **The direction of the
    error is why the cap is the right shape** - under-mirroring is recoverable (the next sync at that
    boundary advances it), over-mirroring is not, because the mirrors are forward-only. Where the two risks
    are asymmetric, the guard belongs on the irreversible side.
  - **FINDING 2 - WIRED, not shipped inert.** *"An absent guard is honest; a dead one is a false negative
    waiting for someone to trust it."* `Get-SpecrewHookEventCoverage` is now computed inside
    `Resolve-SpecrewHookHealth` - which already had the project root and host - and carried on every health
    result as `missing_events` / `prompt_capture_silent`; `Format-SpecrewHookHealthReport` renders a
    PER-EVENT COVERAGE block naming the missing event and stating *"Registered is not fired."* A computed
    field nobody renders would have been the same defect one layer up, so the report assertion is part of
    the guard. Mutation-proved: unwiring the resolver turns five assertions red.
  - **FINDING 4 - CHECKED RATHER THAN ASSUMED, and it is genuinely separate.** The maintainer asked whether
    scoping the replay also closes the scaffold-omission path. Measured: with the cap applied, a fresh
    `state.md` carrying no `Current Phase` line still produces **0 mirror issues** after a `plan` crossing,
    and the line is still absent. The cap governs WHICH boundary is replayed; finding 4 is about a mirror
    the writer will not invent and a checker that only validates a line already present. Two different
    defects in one subsystem. Filed to beta4 on its own.
  - **FINDING 3** - unchanged, to beta4 as the pinned residual.
- **A DEFECT I INTRODUCED IN THE GUARD FOR THIS FIX, caught by my own mutation run and recorded rather than
  quietly repaired.** The first version of `cycle-reset-mirror.tests.ps1` **reimplemented the cap inside a
  test helper** instead of invoking the truth gate. Both mutations of the production code therefore produced
  **ZERO failures** - the suite passed against a reverted fix. That is exactly the class this batch
  catalogued twice (DRIFT-199-I002-014: *a diagnosis that reimplements the subject instead of invoking it*),
  reproduced by me inside the guard written to prove the fix for a defect of the same family, hours after
  writing the rule down. Rewritten to call `Invoke-SpecrewIterationStateTruthGate` in a child process; the
  mutation now fails with the production symptom verbatim (`is: complete`). A second mutation - capping
  unconditionally - initially passed too, because no case discriminated the direction; case 3 now pins that
  a `plan` authorization stays `planning` at a `review-signoff` sync rather than being inflated to
  `reviewing`.
- **Guard**: `tests/integration/cycle-reset-mirror.tests.ps1`, registered in the slice lane (whose pinned
  result count moved 24 -> 25, which is that pin working as designed). It builds the cycle boundary no
  existing mirror fixture crossed, because every one of them starts mid-iteration.
- **THE SCRATCH REPLAY WAS RUN, AND IT WAS NOT REDUNDANT.** The maintainer asked, before signoff, whether a
  scratch replay against real machinery was cheap enough to be worth doing now, or whether finding 1 should
  ship on fixture evidence. It cost about ten minutes, and it **found a second defect the fixture could not
  reach**:
  - Replaying a closed iteration 002 plus a fresh 003 through `Invoke-SpecrewBoundaryStateSync` - the real
    top-level entry, the whole sync path rather than the truth gate alone - showed the mirror correctly NOT
    wedged (`003 plan AFTER: planning`), and then **two truth-gate issues** saying 003's plan and state were
    *"behind the authority record"*, advising the human to *"re-run the boundary sync for
    'iteration-closeout'"*.
  - **That advice re-creates the wedge the writer's cap had just prevented.** `Get-SpecrewCrossingMirrorIssues`
    read the same GLOBAL `last_authorized_boundary` the writer had stopped trusting: the silent forward-write
    had become a loud, wrong refusal. Fixing one side of a comparison and not the other left the defect in
    place with better manners.
  - Fixed with the same ceiling (`-BoundaryCeiling`, passed from the gate). Re-run end to end: both issues
    gone, 003 stays `planning`, closed 002 untouched. Case 2b pins it; mutation-proved.
  - **RECORDED AS TWO FAMILIES AT ONCE, at the maintainer's instruction, because the pairing is why it
    would have been expensive in the field:**
    1. **One side of a comparison fixed while the reader kept trusting the value the writer had stopped
       trusting.** A comparison has two ends and they share an assumption; repairing the writer's end left
       the checker asserting against a premise nothing else still held. This is the general form of
       DRIFT-199-I002-020 (*a fact that fails two contracts reports one*) applied to a FIX rather than to a
       fact: **fixing one side of a shared assumption relocates the defect rather than removing it.**
    2. **A refusal whose own remedy re-creates the defect it is refusing.** *"Re-run the boundary sync for
       'iteration-closeout'"* is precisely the action that forward-writes the new iteration's copies - the
       wedge the writer's cap had just prevented. Same shape as the `specrew update` advice
       (DRIFT-199-I002-021), which would have reverted the fixes it was offered to protect, and the sixth
       instance of the refusal family.
    **Why the pairing is the expensive part**: alone, either is survivable - a half-fix eventually surfaces,
    and a wrong remedy is usually ignored once. Together they are a trap that PAYS to be followed: the
    refusal is loud, specific, and actionable, and following it restores the original defect while the
    reader believes they have just repaired it. In the field this is the difference between a bug and a
    bug that costs a session.
- **The honest limit that remains**: the replay still SEEDS `last_authorized_boundary`, because a fully real
  cycle needs captured human verdicts across a whole iteration. It is a large step from fixture toward field
  - the full sync path on real machinery - and it is not the field. **The field proof arrives when 003
  actually opens**, and until then finding 1's evidence is: mutation-proved at the gate, end-to-end on the
  real sync path with a seeded store, and not yet observed in a genuine cycle.
- **Class closure**: NONE - the guards belong with whatever is authorized, and are named in advance so they are
  not invented afterwards: (1) a cycle test that runs closeout -> next-iteration plan -> tasks and asserts
  the plan mirror still reads `planning`, which no existing suite does because every fixture starts
  mid-iteration; (2) a production caller for the coverage guard, or its removal - an inert guard is worse
  than none because it retires the question; (3) the fresh scaffold writes the mirror lines it will later be
  judged on.

### DRIFT-199-I002-031 — T017's evidence is weaker than its label, and the signoff must say so in the longer form (recorded for review-signoff)

- **The label would carry it dishonestly.** "Mutation-proved only" is the accurate category and it
  understates the situation. The precise statement, which the maintainer instructed be kept in exactly this
  form:

  > T017 (FR-026, the constrained readers) is **not merely mutation-proved**. Its shared reader,
  > `scripts/internal/constrained-yaml.ps1`, was **absent from `Specrew.psd1`'s FileList and began shipping
  > today** (DRIFT-199-I002-024). **No downstream project has ever executed it.**

- **Why the distinction matters at a signoff**: "mutation-proved only" describes a normal, common evidence
  tier - a control whose tests pass and which has not yet been seen in the field. It implies the code has at
  least been *present* in the field and merely unobserved. That is not this case. Until today the file was
  not in the package at all, so its two dependents (`code-implementation-lens.ps1`,
  `product-domain-lens.ps1`) silently skipped loading it - `if (Test-Path) { . $path }` - and the FR-026
  refusal wording was simply undefined in every consumer project. The tier is not "untested in the field";
  it is **"has never run outside this repository."**
- **The general rule this is an instance of**: an evidence LABEL is a summary, and a summary that rounds a
  distinct situation into a familiar category is the same defect as the review record rounding `blocking` to
  `minor` (DRIFT-199-I002-030). At a signoff, where the label is the thing a human reads, the longer form
  wins.
- **Resolution**: carried verbatim into the review-signoff evidence statement, at the maintainer's
  instruction, rather than compressed to its tier name.
- **Class closure**: NONE - this is a rule about how an evidence statement is written, not a control. The
  nearest executable guard is the FileList completeness suite that would now catch the shipping gap itself
  (`tests/unit/package-filelist-completeness.tests.ps1`); nothing can assert that prose chose the longer
  form, and claiming otherwise would be the inert-guard shape this batch keeps recording.

### DRIFT-199-I002-032 — a human pressed stop, the write had already completed, and the agent did not know (open; beta4)

- **What happened, 2026-08-30.** The maintainer interrupted a tool call specifically to prevent a commit.
  The compound command was `git add -A && git commit && git log` followed by a review run; **the commit half
  completed before the interrupt took effect** and `5bf6ca25` entered history. Only the review run was
  stopped. I did not notice, and reported afterwards as though nothing had landed.
- **How it was caught, and this is the uncomfortable part**: not by any control. I found it because a
  timeline I printed for an unrelated reason contained a commit my own account said did not exist - **I
  caught myself contradicting myself.** The maintainer's assessment is exact: *"You found it by noticing you
  were contradicting yourself, which is the only detector we have and is not one."*
- **The general statement**: **an interrupt is not a guarantee, and an agent that cannot tell what completed
  before an interrupt cannot report accurately afterwards.** Every claim made after an interrupted call rests
  on an assumption about where the interrupt landed, and nothing verifies that assumption. The failure is
  silent by construction: the agent's own narrative is internally consistent, because it is built from what
  the agent *intended* to run.
- **Why it is more serious than the commit it produced**: the commit was harmless (three gate-written files,
  invisible to the reviewed-state digest - established below). The reporting error was not. For roughly an
  hour I attributed an invalidated approval to that commit, and built a severity assessment on the
  attribution. **A wrong belief about what completed propagates into every subsequent claim**, and this
  session has already recorded what a wrong finding costs once it reaches a boundary (DRIFT-199-I002-014 and
  -025).
- **Resolution**: OPEN, beta4. The concrete ask is small and mechanical: after an interrupted tool call, an
  agent must be able to establish what actually completed - a durable record of side effects per call, or at
  minimum a convention of re-reading state rather than narrating intent. Recorded as its own entry at the
  maintainer's instruction because it is a property of the harness contract, not of this batch.
- **What was done here**: `5bf6ca25` was reverted (`7f7876ec`), on the maintainer's instruction that *"a
  commit I moved to prevent should not stand silently"* - and only after establishing the revert was free:
  it touches `.specrew/**` only, which the reviewed-state digest excludes, so the revert commit does not
  itself invalidate anything. Digest before and after: `71fe4cde` both.
- **Class closure**: NONE - the guard belongs to the harness (knowing what completed), not to Specrew, and
  writing a Specrew-side check for it would be a control over something Specrew does not observe.

### DRIFT-199-I002-033 — the partial-signoff approval is invalidated by a records-only commit: W77's carry, scoped to one acceptance kind (open; beta4)

- **The chicken-and-egg, with the mechanism established rather than assumed.** A partial-signoff approval
  binds to the reviewed-state digest. Writing the records that a signoff requires moves that digest, which
  invalidates the approval that was captured to permit the signoff.
- **THREE MEASUREMENTS, because two of my claims about this contradicted each other and the maintainer
  caught it:**
  1. **The binding already uses the reviewed-state digest.** Measured: the digest's `tree_id` and the
     pending override's `target_tree_id` are the same value, `71fe4cde3323...`. So the principled fix
     "bind to the digest rather than the raw git tree" was **already in place** - `reviewed-state-digest.ps1`
     excludes `.specrew/**`, `.git/**`, `.squad/**` and `.specify/**`, and the binding honours it.
  2. **The gate's own writes do NOT move the target.** Two consecutive attempts with no commit between
     produced the identical target. `signoff-gate/latest.json` is rewritten with a fresh timestamp on every
     attempt and is invisible to the digest, exactly as designed. **My "it never terminates" call was wrong**
     - I inferred non-termination from the timestamp churn without testing whether the churn moved the
     target. Symptom taken for cause, and the third time this week that running the subject beat reasoning
     about it.
  3. **The mover was a records-only commit.** `5bf6ca25` (three files, all `.specrew/**`) left the digest
     unchanged - proved by computing the digest in a worktree at the preceding commit: `71fe4cde` both
     sides. The actual mover was `20c4f33c`, a drift-log and plan commit under `specs/**`, made between the
     first refusal and the approval.
- **`specs/**` inclusion is CORRECT and is not the defect** (maintainer ruling): it holds the spec, plan,
  tasks and drift log - content a reviewer must see. Excluding it to solve this would blind the digest to
  the artifacts the review exists to examine.
- **The right fix, which uses machinery that already exists**: `Get-SpecrewCarriedSignoffOverrideAuthorization`
  already carries an acceptance across a records-only delta - W77 built exactly this. **It was scoped to one
  acceptance kind, and the partial-signoff override is another.** Extend the carry to the class. Nothing
  about what the digest measures changes.
- **W77's family recurring after its own fix, and this is the sixth instance-not-class finding of the batch**:
  W77 solved the problem for the acceptance kind in front of it. The carry was written as an instance rather
  than as a rule about authorizations-versus-records-deltas, so the next authorization kind reproduced it.
- **Resolution**: OPEN, **beta4, not now** (maintainer ruling): pre-existing rather than a batch regression,
  and it does not block a tester's first hour - it blocks review-signoff, which is deep in the lifecycle.
- **The operational rule used to close 002, recorded because a workaround is not a control**:
  **approve, retry immediately, and commit records only afterwards.** W77's own entry said that "the operator
  discovers a workaround" is not a control - **and that is now true of W77's fix as well as of the original
  defect.** An entry whose remedy is an operator habit has documented the defect, not closed it.
- **Class closure**: NONE - the carry extension is beta4 work on existing machinery, and writing a guard here would pin behaviour the extension has not yet chosen. Named so it is
  fixed as a class: any authorization that binds to the reviewed-state digest owes the same records-delta
  carry, and the guard is the one W77 already has, applied to every acceptance kind rather than to one.

### DRIFT-199-I002-034 — a valid human authorization was discarded in silence for being followed by more text (open; the message half fixed, the source half awaits a ruling)

- **Measured, 2026-08-30, on the fourth attempt.** The maintainer typed a valid partial-signoff approval
  three times; signoff refused three times; **the phrase was never wrong.** The third attempt failed for a
  reason none of the machinery reported: the approval was **captured, evaluated, and thrown away in
  silence.**
- **The mechanism, at source.** `HumanAuthorityStore.ps1:106` matches
  `(?is)^approved\s+for\s+partial\s+review\s+signoff\s*[-:]\s*(?<rationale>.+?)\s*$`. With the `s`
  flag and no `m` flag, **`rationale` is everything from the dash to the END OF THE ENTIRE MESSAGE** - not
  the sentence attached to the phrase. Line 109 then rejects `-gt 2000` characters and `return $null`s.
  - The third approval carried the same rationale plus two further instruction paragraphs: **2193
    characters** by the regex's reading, over the cap, dropped.
  - The second and fourth approvals were the rationale alone (~760 characters) and both captured.
    Identical phrase, identical rationale; the only variable was what followed it in the message.
- **Why this is the sharpest refusal defect of the batch.** The human did everything right. The gate then
  reported `latest-result-not-current` - **true, and about something else entirely.** There was no message
  anywhere naming the cause, because the discard happens in a function that returns `$null` and says
  nothing. Three families at once, all previously catalogued here:
  1. **A fail-soft with no trace** (DRIFT-199-I002-018): the discard is silent by construction.
  2. **A refusal that names what it checked, not what went wrong** (DRIFT-199-I002-029, the sixth
     instance): the gate faithfully reports staleness while the actual event was a dropped authorization.
  3. **An unreachable remedy** (DRIFT-199-I002-026): the message's action was to re-type the phrase, which
     is exactly what had just been done and just been discarded.
- **And the direction is the one that matters least and still hurts**: it DISCARDS an authorization rather
  than inventing one, so the failure is safe. It is also a hard block - the human cannot proceed and cannot
  learn why - which is the definition the maintainer set for tag relevance: *"stuck, not inconvenienced."*
- **What was fixed here (the message half, on the maintainer's instruction to fix the refusal text before
  the tag)**: the partial-coverage refusal now names the ORDERED sequence - refresh the pending request by
  running the gate, then approve **as the whole message with nothing after it**, then retry - and states
  that writing records between those steps moves the state the approval was bound to and is not a rejection
  of the human's reasoning. Guard: `tests/unit/partial-signoff-refusal-names-the-sequence.tests.ps1`,
  mutation-proved.
- **PART (2) IS NOW FIXED AT SOURCE, on the maintainer's ruling 2026-08-31** - landed immediately rather
  than queued, because no approval was in flight after signoff completed and boundary crossings re-mint on
  tree movement rather than dying, so this was the safe window to touch that file.
  - A phrase that MATCHED and was then rejected now says so, on stderr, and **says what to do**: it names
    the actual cause (rationale too long or too short, with the measured length), names the part nobody
    would guess (*"everything after the dash counts, including anything you wrote further down the same
    message"*), gives the retype instruction (*whole message, nothing after it*), and states that nothing
    is wrong with the human's decision. The maintainer's requirement, met by its own standard: the
    replacement for a silent drop must tell the human what to do, not only what happened.
  - The drop is also **journalled** to `.specrew/runtime/authority-capture-drops.jsonl` with its reason and
    measurement - every fail-soft owes a trace, and this one is the reason that rule exists.
  - **A phrase that never matched stays silent**, and the guard pins that too: making every message a
    diagnostic would be the opposite error, and it is the one an over-eager fix would make.
  - Guard: `tests/unit/authority-capture-never-drops-silently.tests.ps1`, in the class-guard lane, driving
    the real capture function in a child process so it asserts on what a human would actually see.
    Mutation-proved on both branches (restoring the bare `return $null` turns 7 assertions red; silencing
    the no-request branch turns 2 red).
- **What is NOT fixed, and is beta4 by the batch's own precedent**: the remaining source-side half.
  **Bound the rationale to its own paragraph** rather than to end-of-message. This is the better fix and the
  actual semantic defect - a rationale is the reason attached to the phrase, not the remainder of the
  conversation. It goes to beta4 with the refusal work, **by this batch's own precedent**: changing what
  counts as a rationale is a contract change, and the identical shape was declined mid-batch on the
  binding name/value asymmetry (DRIFT-199-I002-029). The maintainer had ruled all three parts before the
  tag and accepted the split instead: *"your split is correct by the rule I endorsed there, and it stands."*
- **Citation**: FR-033's refusal standard, sharpened to *name the thing that actually failed*; method rule
  12; DRIFT-199-I002-018, -026, -029, -033.
- **Class closure**: the message guard above closes the operator-facing half only, and says so. The source
  half has no guard because no fix is authorized yet; naming a guard for an unbuilt fix is the shape this
  batch has repeatedly ruled against.

### Resolution Strategies (Unused)

The following resolution strategies remain available if drift is detected later in execution:

- **spec-updated**: Update the spec to reflect implementation choice
- **implementation-reverted**: Revert implementation to match spec
- **deferred**: Mark drift as deferred to next iteration
- **human-decision**: Escalate to Alon for resolution

### Notes

- This artifact was scaffolded before review starts so drift can be logged immediately when detected.
- Counts in the Summary were measured against the entries on 2026-08-29.
