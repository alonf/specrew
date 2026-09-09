# Beta4 findings, before feature 201 has an iteration drift log

**Why this file exists.** Iteration 199/003 is sealed, so nothing can be appended there. Feature 201 has no
iteration yet - `iterations/NNN/` is scaffolded at the plan boundary. These entries move into 201's drift
log when it exists. Companion to `docs/beta4-scope.md` and `docs/beta4-predictions.md`.

---

## B4F-001 - CORRECTS DRIFT-199-I003-094's MECHANISM: the fix target moves from the projection to the resolve, and the conclusion survives unchanged

**Reviewer-confirmed, 2026-09-09.** The recorded chain was *"line 627 reads
`.specrew/handover/workshop-question.json`; 1117 sets `workshopIntermediate` from it; 1479 makes
`workshopQuestionWins` require it."* It was built from grep line numbers without reading the functions
containing them.

- **Line 627 is inside `Update-SpecrewWorkshopQuestionHandover` (line 623) - the WRITER.** It writes the
  file atomically when the decision is valid and **DELETES** it when the decision is null or invalid.
- **That function's own comment states the opposite of the chain**: *"A small local projection makes an
  interrupted workshop resumable without becoming authority. Classification never reads this file; the
  exact, strict feature/iteration applicability artifact decides."*
- **Line 1116 sets `$workshopIntermediate` from a live re-resolve**, not from disk:
  `$workshopQuestion = Resolve-SpecrewWorkshopQuestionPause ...`, with the comment *"Re-resolve only to
  enrich the non-authoritative handover projection with the visible question."*
- **The one production reader is `workshop-authority-store.ps1:435`** (`Write-SpecrewWorkshopAuthorityReceipt`),
  which returns `$null` when the file is absent - so a typed reply cannot be bound to a question.

**THE CONCLUSION SURVIVES INTACT**: both symptoms follow from the resolve returning nothing valid. One
cause, two symptoms, exactly as -094 said.

**WHAT CHANGES IS THE FIX TARGET.** -094's countermeasure - *opening a lens writes the pending question* -
**writes the projection while leaving the resolve broken.** Under it the receipt would mint against a
question the classifier does not agree is open, and the packet symptom would persist. **The fix belongs at
`Resolve-SpecrewWorkshopQuestionPause`.**

**Every other reference to the file in this repository is a TEST that hand-writes it** -
`conformance-detection`, `workshop-agenda-confirmation`, `workshop-material-packet-language`,
`workshop-typed-turn-authority`. That is DRIFT-199-I003-052's provenance shift: the fixtures fabricate the
artifact, so **no test exercises the path that produces it**. A fix at the resolve has no existing test that
would notice it working.

---

## B4F-002 - THE WRITER FOUND: a session RESUME rewrote a sealed, closed iteration's state to a false value, 97 minutes after the seal - and the seal did not prevent it

**The specimen was preserved and NOT repaired, on the reviewer's instruction.** The false value is still in
the working tree; the patch and file copies are in the session scratchpad. Repairing first would have
destroyed the reproduction.

### The chain, read end to end rather than inferred

```
coordinator-resume.ps1:165   Get-TaskProgressSummary        <- a GET verb
  task-progress.ps1:815        function Get-TaskProgressSummary
  task-progress.ps1:827          if (Test-Path $planPath) { Sync-IterationTaskProgress ... }   <- the write
  task-progress.ps1:635            function Sync-IterationTaskProgress
  task-progress.ps1:501              Update-IterationStateFromTaskProgress   -> state.md
  task-progress.ps1:451              Set-TaskProgressManagedSummary          -> the generated block
```

`scripts/specrew-start.ps1:62` dot-sources the same helper.

### The trigger: opening a session. Nothing else.

No user action, no command, no boundary, no verdict. The bootstrap record immediately preceding the write
reads `mode = 'welcome-back'`, `source = 'resume'`, `concurrent_session = True`.

### The timing, measured from file metadata rather than from any account

| event | UTC |
| --- | --- |
| `.specrew-iteration-seal.json` written | **21:20:27.903** |
| bootstrap journal (`source = resume`) | **22:57:57.823** |
| `tasks-progress.yml` rewritten | **22:57:57.928** |
| `state.md` rewritten | **22:57:57.967** |

**97 minutes after the seal. 105 milliseconds after the bootstrap.**

### What it wrote

`**Iteration Status**: complete` became `**Iteration Status**: not-started`, with a generated block reading
*"Execution has not started yet."* - on the iteration that shipped `v0.40.0-beta3`.

### AND THE VALUE IS CORRECT BY THE WRITER'S OWN RULE, which is the uncomfortable part

`Update-IterationStateFromTaskProgress` derives the status from the task table. 003's `tasks:` key is empty,
and an empty table derives `not-started` (`task-progress.ps1:571`, `:610`). **The writer is not
malfunctioning.** It is doing exactly its job on an iteration that should never have been its subject. This
is the maintainer's own settled vocabulary from the iteration-closeout ruling - `Iteration Status` is
derived from task progress with its own writer and its own enum, and **only the closeout value is
boundary-driven** - meeting an iteration whose closeout value the derivation does not know about.

### A `Get-` verb with a write side effect

`Get-TaskProgressSummary` writes. On the resume path a read-named call mutates spec records. Recorded as its
own defect because it is what makes the write invisible at the call site: `coordinator-resume.ps1:165` reads
as a query.

### THE LARGER FINDING: THE SEAL DID NOT HOLD

**Measured**: `task-progress.ps1` contains **zero** occurrences of `seal`, `closed-iteration` or any
equivalent, and neither caller has one. Nothing in the chain asks whether the iteration is closed.

**The seal is a hash record, not a lock.** It can detect drift after the fact; nothing consults it before
writing. **A seal whose name implies immutability and whose behaviour permits rewriting is the guard-scope
pattern applied to the artifact this project uses to prove an iteration is settled** - the escape from the
control is simply that no writer was ever taught to ask.

**It belongs beside DRIFT-199-I003-090, and the two compose:**

- **DRIFT-090's class** is what makes the false value *dangerous*. `Iteration Status` is scope-determining:
  `complete` filters the iteration out of validation (measured in DRIFT-199-I003-089), and `not-started`
  puts a closed iteration back **into** validation carrying an empty task table.
- **This entry is what let it be *written*.** The field's blindness is one defect; the seal's silence is a
  second, and neither implies the other.

**AND IT IS STRICTLY WORSE THAN DRIFT-199-I003-002.** That entry established that the seal can never capture
the *final* mirror state, because authorization writes after it - a bounded staleness window closing when
the verdict lands. **This is an unbounded write window that reopens on every session resume, forever.**

### Blast radius: not specific to 003

The only condition on the write is `Test-Path $planPath`. **Every closed, sealed iteration has a `plan.md`**,
so every one of them is rewritable by a session resume that resolves it as the active iteration. 003 is
where it was caught, not where it is possible.

### PRED-BETA4-002, stated now so the reproduction is not argued afterwards

**While `start-context.json` still names feature 199 / iteration 003, the next session resume in this
worktree will rewrite `state.md` again** and move its mtime, with no user action. If it does not, the
trigger is narrower than the resume path and the diagnosis above is incomplete at the caller rather than at
the writer.

### Countermeasure shape - NOT taken, stop-and-report

1. **The sync refuses when the iteration is closed or sealed** - `closed-iterations.yml` and the seal file
   both already exist and are never consulted. The same two-artifacts-never-compared shape as every other
   enforcement rule this fortnight produced.
2. **`Get-TaskProgressSummary` stops writing, or is renamed to say that it does.**

Both touch `scripts/internal/task-progress.ps1`, which is packaged. **Nothing was changed.**

---

## B4F-003 - THE ORIENTATION ASSERTS ITS TEXT IS THE DEPLOYED TEXT, AND HERE IT IS THE PACKAGED TEMPLATE'S - with a retraction of how this was first reported

**The finding is real and its source is named.** The clause *"they are invoked, never read - their behaviour
is described here, so a surprising result is reported, not investigated in their source"* is
DRIFT-199-I003-064's fix. It lives in `templates/coordinator-instructions.md` - **packaged** (one FileList
entry) and **4052 bytes**, the exact size DRIFT-199-I003-064 records for its trimmed final wording.

**Whitespace-normalised measurement across both sides:**

| file | carries the clause |
| --- | --- |
| `templates/coordinator-instructions.md` (packaged template) | **yes** |
| `CLAUDE.md` (this repository's deployed instructions) | no |
| `AGENTS.md` | no |
| `.github/copilot-instructions.md` | no |
| `.specify/.../squad-templates/coordinator/specrew-governance.md` | no |

**So the SessionStart hook renders the packaged template and labels it *"the same text deployed in AGENTS.md
/ CLAUDE.md"*, and in this repository those differ.** DRIFT-199-I003-064 says why, and says it was
deliberate: *"CHANGED IN THE PACKAGED TEMPLATE, not in this project's copy, so it reaches new projects."*
The change was right; **the label the hook puts on it is what is false**, and it is false on the first
surface a session ever renders.

**That makes it cheaper than an anomaly.** It is bidirectional drift (DRIFT-199-I003-076) with a named
source and a known cause, so the fix is a choice between two one-line moves: re-deploy this repository's
instruction files from the template, or stop the hook asserting equality it does not check.

### RETRACTION, recorded with the same weight as the finding

**This was first reported as *"the clause appears zero times anywhere in the tree"*. That was wrong.** The
clause is present in the packaged template, **line-wrapped** across lines 35-36 as `**they are invoked,` /
`never read**`. A single-line `grep` for `"invoked, never read"` cannot match it.

**This is DRIFT-199-I003-054's rule, committed by the session that had read it that morning**: *a grep
proves absence only over the pattern it searched; absence of a match is evidence about the pattern, not
about the repository.* It is the same defect as the `.specrew-extension-runtime.json` filename that matched
neither alternative of its search - and it produced the same shape of error, a confident absence claim over
a set that was never the repository.

**What would have caught it**: normalising whitespace before matching, which is the second half of
DRIFT-199-I003-036's rule - *build the needle from the haystack's own convention* - applied to a prose file
where the convention is a hard wrap at 100 columns.

---

## B4F-004 - PRED-BETA4-001 RESOLVED: the file is ABSENT, and the journal cannot say why

**Stated at `072239e2`; resolved at the Stop hook of the turn that rendered feature 201's first workshop
question.**

- **`.specrew/handover/workshop-question.json`: ABSENT.** The prediction held.
- **`.specrew/runtime/workshop-authority.jsonl`: still does not exist.** No receipt could have been minted.

**The Stop record for that turn, read from `conformance-journal.jsonl`:**

```
event            = 'stop-block-cap-announce'
recorded_at      = '2026-09-08T23:41:44.9550878Z'
block_kind       = 'material'
workshop_scope   = None
workshop_feature = None
workshop_iteration = None
workshop_lens    = None
intake           = False
dx_lat_len       = 3538
dx_packet_present = False
```

**The resolve returned nothing - all four workshop fields are null - and the material block fired**, which
is both symptoms of B4F-001 reproduced on demand, in this tree, on a question I rendered deliberately.

**BY THE MEANINGS FIXED IN ADVANCE, THIS IS THE FOURTH BRANCH: *absent, no reason recorded anywhere*.** The
journal carries the classification (`block_kind = material`) and four nulls, and **never says which of the
three candidate causes fired** - feature applicability, iteration applicability, or question detection. My
three other pre-committed branches are **indistinguishable from the instrument the product provides.**

**That is a sharper result than any of them would have been**, and it is DRIFT-199-I003-045 restated exactly
where it costs most: *the journal names the classification, never the decision.* **Beta4's first item cannot
be fixed before it can be diagnosed** - a fix at the resolve has no instrument that would show it working,
and no existing test exercises the path (B4F-001).

**THE SHARPEST OPEN THREAD, named rather than guessed at**: `dx_lat_len = 3538`. The message that turn was
materially longer than 3538 characters, so the captured last-assistant text may be truncated - which would
move the cause toward question detection by a capture mechanism rather than by the resolve's own
preconditions. **Not established, and deliberately not inferred**: establishing it needs the transcript
compared against the captured length, which is one measurement and belongs to whoever takes this item.

**Bootstrap journal records carry no timestamp field at all**, so the record that immediately preceded
B4F-002's write could only be dated by file mtime. Recorded here beside the other diagnosability gap because
it is the same defect in a second journal.

---

## B4F-005 - MECHANISM ESTABLISHED: the punctuation heuristic is real and is NOT what blocked this; the resolve never looked at feature 201 at all

**Tested rather than implemented, on instruction.** The reviewer's hypothesis was that question detection
depends on a line ending in `?`. **Both halves were checked, and they separate.**

### The heuristic is real, and this session would fail it every time

`specrew-conformance-provider.ps1:564`, confirmed verbatim:

```powershell
$questionLines = @($LastAssistantText -split "`r?`n" | Where-Object { $_.TrimEnd().EndsWith('?') } | Select-Object -Last 1)
```

**Measured over this session's transcript - all 34 assistant text messages: ZERO have a line ending in
`?`.** That includes message `[17]` (8430 characters, 71 lines), the last assistant text before the failing
Stop, which *contains* a question mark but never at a line end. The prediction the heuristic makes about
this agent's prose is correct: it would find nothing, every time.

### BUT IT DOES NOT GATE VALIDITY, and that is the half that kills it as the cause

Read the control flow rather than the line. Two lines below the filter:

```
566  $result.valid = $true                # unconditional
581  $result.question = $question         # null is fine
582  $result.message_hash = Get-SpecrewFireIdentity -Parts @(..., $LastAssistantText)
```

**A message with no `?`-terminated line still returns `valid = $true`, still causes the projection to be
written, and still carries a bindable `message_hash`.** The heuristic degrades the *readable* `question`
field in a projection whose own comment says it is not authority. **It cannot be what stopped registration**,
because had line 564 been reached at all, `workshop-question.json` would exist.

### The actual mechanism, traced through the guard chain

`$ActiveFeatureRef` and `$ActiveIterationNumber` come from the start context, which names
**`199-beta3-stabilization` / `003`** - the CLOSED feature.

| line | what happens |
| --- | --- |
| 531 | `$ActiveIterationNumber` is `003`, non-empty, so `$scope = 'iteration'`, `$iteration = '003'` |
| 545 | `Get-SpecrewWorkshopLifecycleState -FeatureRef 199-beta3-stabilization -IterationNumber 003` |
| - | **`specs/199-beta3-stabilization/iterations/003/lens-applicability.json` DOES NOT EXIST** (verified) |
| 550 | `$state` is null, so scope / feature_ref / iteration_number are left **null** and the function returns |

**Feature 201 was never consulted.** The resolve did not fail to recognise the workshop question - **it never
looked at the workshop that was open.** This matches the journal exactly: all four `workshop_*` fields null,
which is the one outcome the punctuation path cannot produce.

**PRED-BETA4-001's predicted mechanism is therefore PROVEN**, having been recorded as unproven in B4F-004.
The stale start context is the cause. The journal could not confirm it; the control flow does.

### The truncation is real, separate, and did not cause this

`dx_lat_len = 3538` against message `[17]`'s actual **8430** characters. **The capture truncates.** But the
full 8430-character message has zero `?`-terminated lines too, so truncation changes nothing here. Confirmed
as its own defect, queued behind this one exactly as instructed.

### THREE SPECIFICATIONS, THREE MISSES, AND THEY SHARE ONE SHAPE

| reading | what it named | why it was wrong |
| --- | --- | --- |
| DRIFT-199-I003-094 | line 627 "reads" the file | 627 is a path assignment inside the WRITER |
| B4F-001's correction | the live re-resolve is the gate | correct, but the gate is upstream of it |
| this one | line 564's filter decides detection | the filter feeds a field; `valid` is set unconditionally two lines later |

**Every one was right about the line and wrong about whether the line decides anything.** The rule this
earns, and it is cheap: **when a line is named as a cause, trace to the `return` that carries it.** A filter,
an assignment and a guard look identical in a grep hit.

### WHAT THE EVIDENCE SUPPORTS ABOUT THE FIX - stated as scope, not taken

The resolve must consult **the feature whose workshop is open**, not the one the start context happens to
name. And that reframes the blast radius:

**THE DECISIVE OPEN QUESTION, NOT ESTABLISHED**: the start context is stale **by construction** between
feature creation and the first boundary sync - a new feature's workshop always runs while the context still
names its predecessor. If that is what fires, **the block hits the second and every later feature in any
project**, not just this tree, and Casio and `beta3-tagwalk` worked only because they were *first* features
with no predecessor to name. **That is a much larger scope than "this tree is unusual" and it shapes the fix
rather than merely following it**, so it is in scope under the standing rule. It needs one test: a second
governed feature in a scratch project, with the first one closed.

---

## B4F-006 - THE WORK KIND IS COMPLETE MACHINERY THAT NOBODY IS OFFERED: a silent resolution whose default is the heaviest contract

**`bug-bash-lifecycle.md` ships.** So do `docs-only-lifecycle.md`, `devops-lifecycle.md` and
`software-feature-lifecycle.md`, beside `work-kinds.yml`, `work-kinds.schema.json`, `work-kind-common.ps1`,
`work-kind-validator.ps1`, a deployed `templates/work-kind/`, a CI workflow and four test suites. **The
capability is finished. It was simply never selected.**

### What bug-bash actually asks for

| required evidence | beta4's status |
| --- | --- |
| bug list, each with a reproduction or failing signal | **already written** - six items in `docs/beta4-scope.md` |
| root cause per bug | **already written** - the drift log's measured causes |
| fix evidence | owed |
| regression tests | owed |
| closeout note | owed |

Flow: `bug-list + root-cause -> fix -> regression-tests -> review -> closeout -> merge`.

**There is no workshop, no spec, no design lenses, no plan/tasks ceremony in it.** The drift log *is* the
bug list, and it was complete before feature 201 was created.

### The declaration is inherited, and it names a feature from two features ago

`.specrew/work-kind.yml` reads `work_kind: software-feature`, and its own note begins *"Feature 183 (this
branch)"*. It is a **project-level** file, so 199 inherited it and 201 inherited it, and nothing at feature
creation asked. Its note even records the tension it was written under: *"uses bug-bash conduct for the
individual fixes while retaining software-feature release discipline."*

### It explains iteration 003 retroactively

003 fought a dashboard it could not produce, a task row it never had, a Task Verdicts table with no
reviewer, and a campaign that never ran. **The honest closure was right; the finding is one level up.** 003
was reactive stabilization measured against a planned-feature contract, and **bug-bash may have fitted it
without a single deviation.** Two work items in a row have now paid full feature ceremony for work that had
a lighter contract sitting unused in the same directory.

### THE FINDING IS THE SELECTION, NOT THE CAPABILITY

**A work kind resolves silently, its default is the heaviest contract, and nothing at feature creation asks
which applies.** That is not a missing capability - it is **a shipped one nobody is offered**, which is
squarely beta4's own first-run theme: a stranger meets the heaviest ceremony the product has, for work that
may warrant the lightest, and is never shown that a choice existed.

**Deferred under the standing rule** unless declaring it removes the workshop dependency in front of the
registration fix - which it does, and which is why it was read now rather than later.

**DECLARED 2026-09-09.** `.specrew/work-kind.yml` now reads `work_kind: bug-bash`, and the resolver confirms
`Kind: bug-bash -> templates/lifecycle/bug-bash-lifecycle.md`, `Exists: True`. The project-level consequence
is written into the file itself, above the value, so the next reader meets a decision rather than an
inheritance: **this makes the project a bug-bash project until someone changes it back, and beta5 must
revisit it if beta5 carries features rather than defects.**

---

## B4F-007 - ANSWERED: the block does NOT require a missing controller. Any stale ref produces it, so every second-and-later feature in every project is affected

**The scope question from B4F-005, tested rather than reasoned.**

### Method, with the setup stated because the setup is what decides the answer

`Get-SpecrewWorkshopLifecycleState` was loaded from `scripts/internal/bootstrap/ProjectMetadataAccessor.ps1`
in a subprocess. **The file was first parsed by AST and confirmed to contain ZERO top-level non-function
statements**, so loading it cannot execute anything - the load-time-behaviour precaution DRIFT-199-I003-062
established. Preconditions were printed, not assumed. File mtimes were captured before and after, because a
`Get-` verb already wrote once today (B4F-002) and the verb is not evidence.

### Result

| case | controller on disk | status | reason |
| --- | --- | --- | --- |
| **f201 feature-scope, workshop OPEN - POSITIVE CONTROL** | present | **`active`** | `workshop-pre-agenda-active` |
| f199 / i002, workshop COMPLETE | **present** | **`invalid`** | `workshop-workshop-intake-invalid` |
| f199 / i001, workshop COMPLETE | **present** | **`invalid`** | `workshop-workshop-intake-invalid` |
| f199 / i003, the never-planned stub | absent | `absent` | `workshop-applicability-absent` |

`files_mutated_by_test = 0`.

**THE POSITIVE CONTROL IS WHY THE NEGATIVES MEAN ANYTHING.** Without it, four non-active results are
indistinguishable from a harness that never reached its subject - the defect DRIFT-199-I003-039 catalogues
three instances of in one session. 201 returning `active` with `current_lens = 'product-domain'` proves the
function runs and reads a live controller.

### The answer

Provider line 550 tests `$null -eq $state -or [string]$state.status -ne 'active'`. **All three stale-ref
cases fail that test.** The missing controller changes only the `reason` string; it is not what causes the
block.

**So the trigger is the stale ref itself, and iteration 003's stub is not required.** A start context naming
any previous feature whose workshop is complete produces the same block. **Every second-and-later feature in
every project is affected**, and Casio and `beta3-tagwalk` worked because they were first features with no
predecessor to name. **The fix is a scope correction with the general blast radius, not a narrow one keyed
to this tree's anomaly.**

### A CORRECTION TO B4F-005, and it is mine - the fourth reading in this chain

B4F-005 traced the observed failure to line 550's return. **That cannot be right.** For 003 the state is
non-null (`status = 'absent'`), so line 552's `if ($null -ne $state)` would set `scope`, `feature_ref` and
`iteration_number` - **yet the journal recorded all four as null.** The all-null signature matches the
EARLIER return at line 532, `workshop-active-iteration-missing` - **the reason PRED-BETA4-001 originally
named and then rejected.**

**What survives is stronger than what it replaces**: the stale ref is the cause, now proven by direct test
against a positive control rather than by reading control flow. **Which of the two returns it takes does not
change the fix**, since both are downstream of pointing the resolve at the wrong feature. But the record
must not claim a path it has not established.

**Fifth instance of the shape B4F-005 itself named** - right about the line, wrong about whether that line
is what decides - committed by the entry that named it, one turn later. The rule survives its author, which
is the only test of a rule that matters here.

---

## B4F-008 - THE ORIENTATION GUARD'S DISCHARGE IS PER-TURN, so a compliant session renders the banner on every turn

**Three firings, measured across this session.**

| turn | orientation rendered | stop |
| --- | --- | --- |
| 1 | yes, in full, opening the reply | blocked at a later stop |
| 4 | yes, forced by the guard | went through |
| 5 | no | **blocked** |

**The guard reads the CURRENT turn's last assistant message and has no memory that the orientation was ever
shown.** Its only discharge is re-rendering, so the condition returns on every turn that does not repeat the
banner - and a session that complies renders the full orientation every single turn.

**That is DRIFT-199-I003-074's shape exactly**: *a report that renders no packet can never satisfy the packet
test that discharges it.* Here the discharge is a thing the design intends to happen once. For a new user it
is the banner on every turn, which is the repetition that reads as broken - and it is the same surface
DRIFT-199-I003-080 is already in beta4 scope for.

**Not investigated further and not fixed.** Recorded per the standing rule. **Beta5**, beside the capture
truncation, the post-seal writer and the orientation-text drift.

---

## B4F-009 - THE FIX: the workshop resolve selects the feature whose intake controller is open

**Beta4's one shipped change.** Bug-bash evidence, in the order its contract asks for it.

### Bug

A workshop question could not be registered, so no receipt could mint and no lens could close. Reproduced on
demand in this tree (B4F-004) and measured to affect **every second-and-later feature in any project**
(B4F-007).

### Root cause

`Resolve-SpecrewWorkshopQuestionPause` selected the workshop from `.specrew/start-context.json`'s
`session_state`, which names the **lifecycle's** feature. After any completed feature that is the
**previous** one, and it is stale by construction from feature creation until the first boundary sync. The
resolve then looked up a completed workshop - or an iteration absent under the new feature - and returned
nothing active, silently.

### Fix

`specrew-conformance-provider.ps1`, plus its `.specify/` mirror, byte-identical.

- The call site computes `$workshopIntakeCandidates`: features whose `spec.md` still carries
  `<!-- specrew:spec-not-yet-authored -->` **and** which have a feature-level `lens-applicability.json`.
  It reuses the `$specs` enumeration already taken, so it adds no directory walk.
- The resolve prefers a **unique** candidate whose controller reports `active`, at feature scope, over the
  start-context pair.

**Three properties make it safe, and each is asserted by the test rather than argued. Property 1 is stated
here AS IT HOLDS AFTER REVIEW, not as it was first claimed - see B4F-010, where the first version of it was
false and the review caught it:**

1. **It never displaces an active workshop.** When both the candidate path and the start-context path
   resolve active on *different* features, the resolve refuses with `workshop-resolve-ambiguous` rather than
   choosing. Exactly one active path may win.
2. **It cannot capture design-analysis.** That workshop is iteration-scoped and its spec IS authored, so it
   can never be an intake candidate.
3. **It does not guess.** More than one open intake workshop is ambiguous and falls through to the previous
   behaviour rather than picking one - which would manufacture a binding no human made.

**Both call sites patched.** The provider calls the resolve **twice**, and the first anchor matched only
one. Caught by checking rather than by trusting the anchor; a half-applied fix here would have been silent,
which is the two-writers family (DRIFT-199-I003-048). Case 6 of the test now pins it.

### Regression test

`tests/integration/workshop-resolve-prefers-open-feature.tests.ps1`, registered in the **`f199-class-guards`**
lane (`every-suite-is-named-by-a-lane` went red on the unregistered file and named the remedy; green after,
56 -> 57 suites).

**It drives the resolve and never writes `workshop-question.json`** - because every existing fixture in this
area hand-writes that file, which is precisely why none of them could notice a defect in its production
(B4F-001).

**It carries its own positive control (Case 1)**, on the reviewer's instruction: a test that sets up the
stale ref and asserts a negative passes just as happily when it never reached the function, and would join
the fixtures that could not notice. Case 1 asserts an open feature resolves **active** in the same run, and
the file exits INCONCLUSIVE rather than reporting a verdict if that control does not hold.

Six cases: positive control; the regression; candidate validation; a negative control that must stay
non-valid; ambiguity refused; and every call site passing the parameter.

### Mutation proof

Target **GREEN first** (DRIFT-199-I003-047), then the candidate adoption disabled at exactly one site:

```
baseline_exit           = 0
mutation_sites          = 1
mutant_exit             = 1   -> only CASE 2's three assertions red; the positive control still passed
restored_byte_identical = True
mirror_identical        = True
post_restore_exit       = 0
```

**Only the regression case discriminated**, which is what distinguishes a proof from a test that fails for
any reason.

### Reported, not acted on

**SETTLED - and the first report of it was wrong.** It was reported as *"names 124 of 127 integration
suites"*. That number was a count of `tests/integration/` **regex hits inside the manifest text**, not a
count of files - the count-scope defect (DRIFT-199-I003-047) in the very entry that refused to act without
knowing the rule. **The real figure is 11 integration suites unnamed, not 3.**

Measured properly, the rule is clean and the refusal to add was right for a better reason than caution:

| coverage | suites |
| --- | --- |
| named by a per-round LANE only | 50 |
| named by the RELEASE GATE only | 338 |
| named by both | 7 |
| **named by NEITHER** | **0** |

**The two registries are complements over all 395 suites on disk, not overlapping lists.** A suite belongs
to one or the other; the 7 in both are permanent class guards. The new test is registered in a lane, so it
is fully covered, and adding it to the gate would put it in a 7-file overlap with no reason to be there.
**No change needed.**


---

## B4F-010 - REVIEW FINDING ON 905c5601: safety property 1 was false, and the fix could displace the workshop a human was actually answering

**Found by the reviewer against the code, reproduced here with a control before it was accepted, and fixed
in the same session. Recorded because a claimed safety property that does not hold is worse than an
unclaimed one - it stops the next reader checking.**

### What was claimed, and why it was wrong

905c5601 claimed: *"It cannot suppress a working workshop. It only ever turns a non-active result into an
active one."* **Not true as written.** When the candidate resolved active, `$ActiveFeatureRef` was replaced
and `$intakeCandidate` stayed non-empty, so the block guarded by `IsNullOrWhiteSpace($intakeCandidate)` was
skipped entirely: scope stayed `feature` and **the start-context path was never attempted at all.**

**Property 2 did not cover this, and that is the instructive part.** The risk was never that a
design-analysis workshop becomes an intake candidate - it cannot. The risk is that a *different* candidate
**displaces** it.

### The consequence is worse than the block it replaced

Feature A is mid-workshop and the human is answering its lens. Someone scaffolds feature B. B is the unique
intake candidate and its pre-agenda controller reads active, so the resolve registers **B's** question.
**The human's typed reply then mints a receipt against B's question.** A's checkpoint finds no receipt; B
carries one it never earned.

**That is a human reply bound to a question they never saw** - precisely what property 3 already refuses
between two candidates, happening instead between a candidate and the start context. Narrow, and not worse
than the unconditional failure it replaced - **but narrow was this defect's description too**, and it fires
in multi-feature projects, which is where the product is meant to earn its keep.

### Reproduced before it was accepted, and the first attempt to reproduce it FAILED HONESTLY

Case 7 was written first and its **precondition assertion caught a fixture defect rather than reporting a
verdict**: a completed lens entry needs its own `workshop/<lens>.md` record and a `human_turn_receipt` that
validates against the real hook-owned authority store, so the design-analysis fixture was `invalid`, not
`active`. Three assertions "failed" against a control that had never reached its subject - DRIFT-199-I003-039
exactly, caught by the rule this file was built with.

**Fabricating an agenda receipt to force the fixture active was available and was refused** - that is the
fixture-fabrication defect (DRIFT-199-I003-052) this test exists to avoid. The fixture was rebuilt in the
shape Case 1 already proves active, and only then did Case 7 fail for the right reason.

### The fix, and why neither obvious ordering is safe alone

**Resolving the start-context path first and falling back to the candidate has the mirror failure**: a
previous feature whose iteration workshop was left active after closeout would win over a new feature's
intake - the original defect with its precedence flipped. **Neither order is safe on its own.**

So both paths are resolved and then compared, and **exactly one active path may win**:

- candidate active, start-context not - the candidate wins (the original fix, preserved);
- start-context active, candidate not - the start context wins (unchanged behaviour);
- **both active on different features - refuse with `workshop-resolve-ambiguous`**, because nothing can tell
  which question the human is answering;
- both naming the same feature - no conflict.

**Property 1 now holds by construction rather than by claim**, which is the whole point of the change.

### Evidence

Two cases added (7 and 8), and the mutation proof re-run against **both** sites with the target green first:

```
baseline_exit           = 0
M1 candidate never adopted   -> exit 1, CASE 2 + CASE 8 red
M2 ambiguity refusal removed -> exit 1, CASE 7 red
restored_byte_identical = True
mirror_identical        = True
post_restore_exit       = 0
```

**Disjoint failure sets**: each site is independently guarded, so removing either is caught by a different
case. Case 8 exists specifically to prove the new guard did not weaken the original fix.

---

## B4F-011 - THE FIX SURFACED A DEFECT THE BLOCK WAS HIDING: five `human-confirmed` receipts for a question nobody was asked

**Found immediately after the fix landed, by checking a claim rather than asserting it - and the claim being
checked was one I had just written into the record.**

### The measurement

`.specrew/runtime/workshop-authority.jsonl` did not exist in this tree at any point before the fix. It now
holds **five receipts**, minted 00:26:46Z to 00:44:12Z, every one of them:

```
feature_ref        = '201-first-run-experience'
phase              = 'product-domain'
lens               = 'product-domain'
confirmation       = 'human-confirmed'
confirmation_scope = 'lens-question'
source_event       = 'UserPromptSubmit'
```

**The product-domain question was never asked in any of those turns.** The workshop is deliberately held.
Every one of those typed turns was a code review of the fix.

### The mechanism, and it is NOT caused by the fix

`Write-SpecrewWorkshopAuthorityReceipt` binds a typed turn to whatever `workshop-question.json` currently
names. The projection is rewritten at every Stop while a workshop is open, and its `message_hash` is
computed from the **last assistant message** - whatever that message happened to be. Nothing anywhere asks
whether the human was answering a question. `human-confirmed` / `lens-question` are what a lens-phase
receipt is labelled, not a finding about the reply.

**So this is pre-existing and it is documented** - the design-workshop skill states it plainly: *"the SC-026
gate ... cannot see transcript truthfulness; that integrity is on you."* What is new is only that it is now
**visible in this tree**, because the block had prevented any projection from existing at all.

**That is the finding worth keeping: fixing the block did not create this, it REVEALED it.** A defect that
suppresses a whole subsystem also suppresses every defect downstream of it, and the downstream ones arrive
together the moment it is repaired. The same will be true for anything else that was waiting behind the
registration block.

### The live hazard, stated so nobody trips on it

**Those five receipt ids are on disk, they validate, and citing any of them would close `product-domain`
with a fabricated agreement.** The lens has had no question asked and no answer given. When 201's workshop
resumes, the question must be asked and answered, and the receipt cited must be the one bound to that
exchange. **None of the five may be used.**

### Disposition

**BETA5, with the refusal-standard items** - it is the integrity gap the skill already names, and the
standing rule holds. Recorded now because the evidence is on disk today and because the next person to open
this workshop will find five receipts that look like agreement.

---

## B4F-012 - REVIEW CLOSE-OUT: two items recorded, neither blocking

### 1. A coverage gap the fixture change created, named rather than smoothed

Case 7 proves the ambiguity refusal **between two intake workshops at feature scope**. The concern that
produced it was an **iteration-scoped design-analysis** workshop being displaced.

**The code path is the same** - both paths resolve, both active, different features, refuse - so the
design-analysis case *is* covered by the guard. **It is not covered by a test.** An honest design-analysis
fixture needs a closed lens with a `workshop/<lens>.md` record and a `human_turn_receipt` that validates
against the real hook-owned store, and fabricating one was refused (DRIFT-199-I003-052).

**The consequence is worth stating as a general fact rather than an excuse: some states can only be reached
through the product, not staged around it.** A test suite that insists on staging everything will either
fabricate its preconditions or silently skip those states, and this project has already paid for the first.

**Assigned**: the second-feature walk, which is already on the list, gains a specific assertion - drive a
scratch project to design-analysis, scaffold a second feature, and confirm the resolve **refuses rather than
binds**.

**And the thing to keep**: Case 7's precondition assertion caught the dead fixture *before* the verdicts
under it were read. Without it, three green assertions would have proved nothing and looked like a pass.

### 2. The refusal does not reach the human

When both paths are active the resolve returns `workshop-resolve-ambiguous`. **That reason lands in the
journal.** `workshopIntermediate` goes false, and the human gets an ordinary material-work packet with **no
indication that two workshops are open, or which two.**

Existing class, not new, and it belongs with the **refusal-standard** items rather than inside this fix: a
refusal must name what failed and what the reader can do. **BETA5.** Recorded here in one line so the next
person who hits it finds the reason without reading a journal.

### 3. The registry rule, recorded so nobody re-derives it

**The per-round lanes and the release gate are COMPLEMENTS, not overlapping lists**: over all 395 suites on
disk - 50 lane-only, 338 gate-only, 7 in both, and **zero covered by neither**. A suite belongs to one or
the other; the 7 in both are permanent class guards. **A lane-registered suite needs no gate entry.**

---

## B4F-013 - THE RULE: a block upstream hides every defect downstream of it, and they surface together when it is lifted

**Promoted from an observation in B4F-011 to a stated rule, because it predicts rather than explains.**

> **A defect that suppresses a subsystem also suppresses every defect downstream of it. Lifting the block
> does not reveal them one at a time - it reveals all of them at once, and they arrive looking like
> regressions caused by the fix.**

**The instance that produced it.** The registration block meant no workshop question was ever projected in
this tree, so no receipt could ever mint. B4F-011's over-eager confirmation was therefore *unobservable* -
not absent, unobservable. It appeared within minutes of the fix, and the natural reading of its arrival was
that the fix caused it. **It did not.** The mechanism is untouched by the fix and predates it.

**Why this is worth a rule rather than a note**: the arrival pattern is indistinguishable from a regression,
so the default reaction to it is wrong. Anything found immediately after a block is lifted needs its
provenance established - *was this reachable before?* - before it is attributed to the change.

### It predicts, and here is the standing prediction it makes

**Expect more of B4F-011's kind during the router-skill crew's eight-lens re-close.** That is the **first
time the downstream path runs on real work** rather than on this tree's review traffic. Registration,
receipt minting, lens checkpoints and confirmations have never been exercised end to end on a genuine
workshop under this machinery.

**What that means operationally**: findings from that re-close are *new visibility*, not new breakage, until
shown otherwise - and they should be recorded before they are worked around. The brief handed to that crew
is `docs/beta4-router-skill-crew-brief.md`.

### Siblings

Same family as the census (DRIFT-199-I003-030/-035): provisioning the runner so the product could bootstrap
made the count go **up**, because the gate began measuring more of the tree. **The gate did not weaken - it
started working**, and more measurement found more findings. This entry is that shape one level up, in
product behaviour rather than in a gate.

---

## B4F-014 - WHAT A RECEIPT PROVES, restated: a turn, not an assent

**The definition, to be used wherever the record previously implied more.**

> **A receipt proves that a typed human turn occurred while a question was projected. It does not prove the
> reply answered that question.** `confirmation: human-confirmed` with `confirmation_scope: lens-question`
> is **evidence of a turn, not of assent**, and the record carries nothing that can tell the two apart.

**Five receipts minted from code-review messages validate identically to five minted from real answers.**
That is measured, not argued - it is B4F-011.

### Where the record is corrected by this

- **B4F-001** said the file's absence means *"a typed reply cannot be bound to a question."* True as
  written, and it must not be read in reverse: its presence does not mean a reply **answered** one.
- **B4F-009** described the chain as `resolve -> projection -> receipt -> lens closes`. Correct as a
  mechanism, **and it is not a chain of proof.** Only the first two links are machine-verified. The last
  link - that the human's turn was an answer - rests on the agent having actually asked the question and
  reported honestly, which the design-workshop conduct already places on the agent and no gate can check.
- **PRED-BETA4-003's resolution** said *"a receipt can now mint where it could not before."* True, and
  narrower than it sounds: what became possible is the **binding**, not the **agreement**.

**The practical consequence, stated once**: a lens may be recorded `human-confirmed` only for a question
actually surfaced and actually answered. The receipt id is the *evidence trail* for that claim, never the
claim itself.

---

## B4F-015 - THE DEFECT IS AT THE READER, NOT THE WRITER: an honest evidence record promoted to authority downstream

**The reader-side statement of B4F-011/B4F-014's class, and it sharpens them rather than repeating them.**

### The mint site is honest, and says so in its own words

`scripts/internal/bootstrap/HandoverStore.ps1:1101`, verified at source:

```powershell
# The workshop RECEIPT is not one of them: it records that a phrase was seen, which is
# evidence rather than authority, and it belongs only to the branch the human types into.
if ((Get-Command Write-SpecrewWorkshopAuthorityReceipt -ErrorAction SilentlyContinue) -and
    -not [string]::IsNullOrWhiteSpace($LastUserMessage)) {
```

**The only condition is that the message is not whitespace.** No content inspection, and **no
redirect-shaped reply escapes it** - a correction, a question and an agreement all mint identically.

**But the writer is not the defect.** Its comment states precisely what it is doing: *a phrase was seen,
which is **evidence rather than authority***. It never claims assent. **It is honest about its own tier.**

### The defect is that a lower-tier fact is read as a higher-tier one

**The checkpoint treats a PRESENT receipt as the close.** So evidence is promoted to authority *downstream*
of an honest write, and nothing between the two records the promotion.

**That is the same shape as the boundary record trusting its own `auth_commit_hash`** (DRIFT-199-I003-097,
under DRIFT-199-I003-090's class): the fabrication risk does not live where the fact is written, it lives
**where a lower-tier fact is consumed as a higher-tier one.** In both cases the writer is doing its job and
the reader is asking the wrong question of the answer it gets.

### Why this matters for the disagreement case specifically

The confirm case was already covered by "type `move on` and nothing else". **The redirect case was left as a
trap**: a maintainer who disagrees with a presented lens and types the correction into the open workshop
mints a receipt, and a presence-reading checkpoint records the lens as closed **against the objection it
just received.** The natural human action produces the opposite of its intent, silently.

`docs/beta4-router-skill-crew-brief.md` now carries both halves, including an explicit redirect path -
because a rule that only names the safe action leaves the unsafe one as the default.

### It strengthens the beta5 fix, and names its two halves

1. **The receipt must carry what it is evidence OF** - the question it was bound to, and that it records a
   turn rather than an assent. Today the tier is stated in a source comment and nowhere in the record.
2. **The checkpoint must require assent, not mere presence.** A receipt whose reply was not an answer must
   not be citable as a close.

**BETA5**, with B4F-011, B4F-014 and the refusal-standard items. The standing rule holds; nothing here is
fixed in beta4, and the disclosure in `docs/release-notes-v0.40.0-beta4.md` is what beta4 ships instead.
