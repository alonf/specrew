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

**Total drift events**: 12 (DRIFT-199-I002-001 through -012)
**Resolution rate**: carried per event in its heading (8 resolved-by this iteration's requirements or
instrumentation, 2 spec-updated/human-decision, 2 deferred/open by ruling or scope)
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
- **Class closure**: NONE in this iteration - a precedence rule between provider fragments is beta4
  design work, and inventing one inside a tag batch is the shape the maintainer ruled against for F-2.

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
- **Class closure**: every mutation in this iteration asserts `count == 1` on its target before editing, so
  a duplicated or missing target fails loudly instead of mutating the wrong thing; and the lesson
  generalises beyond mutations - where a thing must exist exactly once, assert that, because no behaviour
  test will.

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

### Resolution Strategies (Unused)

The following resolution strategies remain available if drift is detected later in execution:

- **spec-updated**: Update the spec to reflect implementation choice
- **implementation-reverted**: Revert implementation to match spec
- **deferred**: Mark drift as deferred to next iteration
- **human-decision**: Escalate to Alon for resolution

### Notes

- This artifact was scaffolded before review starts so drift can be logged immediately when detected.
- Counts in the Summary were measured against the entries on 2026-08-29.
