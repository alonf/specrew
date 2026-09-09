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

---

## B4F-016 - I REPORTED A NEAR-MISS THAT DID NOT HAPPEN, and the same message shows the product getting it RIGHT in one store and WRONG in another

**A withdrawal and a much sharper finding, from one typed turn.**

### The withdrawal

I reported that `approved for review round` produced **silence** - that it was verdict-shaped, matched
nothing, and that the human was told nothing - and I filed it as a live DRIFT-199-I003-095 near-miss.

**That was wrong.** The phrase matched exactly and was captured:

```
.specrew/review/round-approval/pending-round-approval.json
  fact_type       = review-round-approval
  approval_kind   = typed-phrase
  verdict_text    = "approved for review round"
  evidence_source = hook-captured-user-prompt
  observed_at     = 2026-09-09T01:06:31.1730233Z
  spent_at        = null
```

**I checked `start-context.json`'s boundary state and concluded absence from it.** Review-round approval is
not a boundary crossing and does not live there. **An absence claim proves absence only over the store you
looked in** - DRIFT-199-I003-054's rule with `git ls-files` swapped for a JSON file, made while reporting on
that very class. Fifth or sixth instance depending how you count; the count is the point.

**And the question I asked was already answered.** I put two readings of "review round" to the maintainer as
materially different work. The machinery had resolved it: `approved for review round` is the product's own
documented approval phrase, and the action is `specrew review --live --approve-round`. **The human typed
exactly what the product asks for and I treated it as ambiguous** - friction I introduced, on the surface
beta4 exists to fix.

### The finding that replaces it, and it is better

**One typed message hit two capture paths, and they behaved differently:**

| store | what it required | outcome |
| --- | --- | --- |
| `.specrew/review/round-approval/` | an **exact phrase match** (`approval_kind: typed-phrase`) | **correct** - a real approval, recorded as one, unspent |
| `.specrew/runtime/workshop-authority.jsonl` | **any non-whitespace message** | **spurious** - receipt 13, `human-confirmed` / `lens-question`, for a product-domain question never asked |

**Same message. Same instant** - 01:06:31.17Z and 01:06:31.66Z, half a second apart. One store asked what
the human said; the other asked only that they said something.

### Why this sharpens the beta5 fix rather than restating it

B4F-015 said the checkpoint must require assent rather than presence, which is correct and abstract. **This
gives it a working reference implementation inside the same product**: the round-approval capture already
does the discriminating thing - it binds a **phrase** to a **fact_type**, records `approval_kind`, and
carries `spent_at` so the fact can be consumed once and only once.

**The workshop receipt has none of those.** No phrase requirement, no statement of what the turn was
evidence of, no spend marker - so it can be minted by anything and cited any number of times.

**So beta5's fix is no longer a design question.** Make the workshop receipt carry what the round-approval
fact already carries: what was required, what was seen, and whether it has been spent. **The pattern does
not need inventing; it needs copying from the file next door.**

**BETA5**, with B4F-011, B4F-014 and B4F-015.

---

## B4F-017 - THE REVIEW ENGINE REFUSES THE EXACT CHANGE BETA4 SHIPS, and its named remedy would destroy it

**Hit while spending the approved review round.** `specrew review --live --approve-round` refused:

```
review-engine-project-runtime-drifted:
  marker=df8a01650e9665d4d806741b06c22e6a8c12ce493036f98a4c51b577ba7f06d4
  actual=b56b0f25e7263763e74f5dc7c9a0580f31c15ac908ecedd6c35b54ce29273ec5
  run 'specrew update --project-path "C:\Dev\specrew-beta3-stabilization"'
```

**The detection is correct.** The deployed machinery under `.specify/extensions/specrew-speckit` no longer
matches the recorded install marker - **because beta4's fix edited it**, which is the whole point of the
change.

### THE NAMED REMEDY IS FORBIDDEN, and this is the fifth instance of that family

`specrew update` would **overwrite the deployed provider with the installed beta3 bits** - silently
destroying the fix the detector just detected.

**This is DRIFT-199-I003-016's family, and its exact fourth instance repeated**: *a detector naming the
remedy that destroys its own finding.* DRIFT-199-I003-014 recorded the identical trap during the beta3
respin, in the same file, for the same reason: *"The remedy the message names is FORBIDDEN: it says run
`specrew update --project-path ...`, which would overwrite the fix with the 4f4dce52 bits."*

**And what saved it both times was a standing rule, not the control.** In beta3 it was the no-rebuild hold;
here it is that this crew had already read that entry. DRIFT-199-I003-016's own warning applies unchanged:
**a control that only works because an unrelated rule happened to be active is not a control.** The message
is locally sensible, authoritative, and now blocks a required lifecycle stage - which is precisely the
condition under which advice gets followed.

### The sanctioned unblock is a RE-STAMP, not an update

DRIFT-199-I003-053 settled this during the respin: regenerate the marker through the product's own writer
`Write-SpecrewDeployedExtensionMarker`, with the precondition printed before the write, the postcondition
after, and the diff bounded to the authorized files. **Hand-editing the hashes would be exactly the
fabrication DRIFT-199-I003-052 condemns.**

The marker is **not packaged** - absent from `Specrew.psd1`'s FileList and from `extensions/` - so it is
per-project deployment state that every install regenerates. **Nothing ships differently either way.**

### Why it is worth its own entry rather than a line in the fix

**Any beta4-shaped change hits this.** The release edits deployed machinery by design, so every crew that
fixes a deployed script will meet this refusal, be told to run the one command that undoes their work, and
have nothing in the message to warn them. **The refusal should compare direction** - a project AHEAD of its
module must never be told to update as though it were BEHIND - which is the fix DRIFT-199-I003-016 already
named and which is still owed.

**Recorded, not fixed.** The standing rule holds: beta4 ships the registration fix and nothing else.

---

## B4F-018 - THE SPINE FINDING: a claim measured over a narrower set than the claim covers

**This sits ABOVE every other entry in this file, and above most of iteration 003's drift log. Those are
instances. This is the class, and it is a method rather than a bug.**

> **A claim is stated over one set and measured over a narrower one. The measurement is correct. The claim
> is wrong. Nothing in the output distinguishes the two, because the check reports on what it examined and
> the reader hears what was asserted.**

### Why it is the spine and not one more entry

**It has appeared on every surface this project has**, which is what makes it a method rather than a defect
with a location:

| surface | instance |
| --- | --- |
| **production code** | the authority-marker guard catching malformed markers only where the malformation does not collide with a real identifier (DRIFT-199-I003-042); self-leak-lint and mirror-parity holding different scopes over the same content (-034) |
| **tests** | a needle built in LF against a CRLF haystack, so `IndexOf` returned -1 and the test reported its own defect as the script's (DRIFT-199-I003-036); `crossing-owner` red at both commits with nobody comparing WHICH assertions (-051) |
| **the release gate** | the census reporting the product's own dependency refusal as a tree defect, because it ran where the product cannot bootstrap (DRIFT-199-I003-030); "lanes green" read as "tree green" for days (-022) |
| **human rulings** | the remembered "beta2's census succeeded" premise, stated in passing and built upon, with the run list one command away (DRIFT-199-I003-030) |
| **verification controls** | three controls in one session that produced confident answers about nothing (DRIFT-199-I003-039); a mutation proof whose target was already red (-049) |
| **records about the class** | the entry written to record two escape-corruption instances reproduced both of them (DRIFT-199-I003-018) |

**And five more in this session alone, all mine:**

1. **The whitespace grep** - `"invoked, never read"` claimed absent tree-wide; it was present, line-wrapped
   across two lines, so a single-line pattern could not match it. (B4F-003)
2. **The registry regex-hit count** - "124 of 127 integration suites" was a count of `tests/integration/`
   matches inside the manifest text, not of files. The real figure was 11 unnamed. (B4F-009)
3. **The traced route** - B4F-005 attributed the failure to line 550's return, but for that state the
   object is non-null and line 552 would have populated the fields the journal recorded as null. (B4F-007)
4. **The boundary-store absence claim** - `approved for review round` reported as producing silence, because
   the boundary store was checked and round-approval does not live there. (B4F-016)
5. **The bounding control** - a re-stamp check that compared only `managed_files` and reported "BOUNDED AS
   EXPECTED" while `specrew_version` degraded from `0.40.0` to `unknown` outside the set it examined.

**Instance 5 is the one that settles it**: the defect appeared inside the control written specifically to
bound a claim, in the same session that had recorded the class four times.

### THE COUNTERMEASURE IS NOT ANOTHER GUARD, and that is the load-bearing part

**A guard is a checker, and a checker has a scope.** Adding one to catch scope errors reproduces the
problem one level up - which is exactly what DRIFT-199-I003-042 found (a guard whose coverage is decided by
what the bad input happens to say) and what -034 found (two guards whose scopes compose only by accident).
**Every attempt to answer this class with a control has become a new instance of it.**

The two things that have actually worked, every time, across the whole arc:

1. **STATE THE SET.** A count, an absence, a "bounded as expected", a "nothing failed" is not a claim until
   it names what it counted over. *"Zero matches"* is meaningless; *"zero matches for this pattern over
   these files"* can be checked and can be wrong.
2. **VERIFY FROM THE ARTIFACT, NOT THE CHECKER.** Every instance above was caught by reading the thing
   itself - the git diff, the run list, the directory listing, the failing-assertion sets, the file's own
   bytes - and **none was caught by the check that was supposed to cover it.** A checker's green means
   "nothing I examined is wrong", and the reader hears "nothing is wrong".

### What this reorganises

Iteration 003's drift log reads as ninety-nine findings. **It is closer to one finding with ninety-nine
instances**, plus a smaller set about authorization. That is not a criticism of the record - the instances
had to be found individually and each cost something real - but the next reader should meet the class
first, because it predicts where to look and no individual instance does.

**Beta5 owes this a place in the methodology, not a guard in the harness.**

---

## B4F-019 - CENSUS 34297054157 CLASSIFIED: the sweep ran, it was not a timeout, and PRED-BETA4-004's third part FAILED

### First, before any classification: did the sweep execute?

**Yes.** Read from the run artifact rather than from red/green:

- the step `Execute every named test file on disk` **ran and failed** - it is not skipped;
- `Upload census failure diagnostics` **succeeded**, and the artifact carries **five per-file entries** with
  `path`, `kind`, `status`, `exit_code`, `duration_seconds` and `output`.

**So this is a sweep that ran and found failures, not a provisioning death wearing a failure's clothes** -
the distinction beta3 paid for twice (DRIFT-199-I003-026's corrupt-zip transient, and DRIFT-199-I003-030's
census that had never once completed a sweep).

**And the diagnostics artifact is DRIFT-199-I003-022's beta4 item (b), shipped.** That entry recorded the
census writing its diagnostics to ephemeral runner storage and never uploading them, leaving "23 filenames
and no reason for any of them". This run produced per-file output including assertion text. **The item is
closed by evidence rather than by claim.**

**Not a timeout.** The run completed with `conclusion: failure`, so the fifth outcome does not apply.

### The classification

| # | file | attributable to THIS branch? | evidence |
| --- | --- | --- | --- |
| 1 | `pr-review-integration` | **UNDETERMINED** | `NONBLOCK_WARNING_MISSING exit=1`; the test runs the validator E2E and captures only the result token, so the validator's own reason is not in the artifact |
| 2 | `validate-governance-changed-only` | **YES** | the exact three assertions DRIFT-199-I003-053 pinned to W43 deployed-marker drift - caused by editing deployed machinery, which is what beta4's fix does |
| 3 | `no-internal-ids-in-emitted-strings` | **NO** | offender is `shared-governance.ps1:2174 [DRIFT-198]` - a file this branch never touched |
| 4 | `self-leak-lint` | **NO** | Test 9's born-clean guard against **171 pre-existing annotated hits** - the exact count DRIFT-199-I003-028 measured. **Zero unannotated**, and none of the provider hits are mine |
| 5 | `work-kind-runtime` | **YES** | `FAIL: T212 (SC-014): Specrew declares software-feature (feature 182)` |

**I checked whether my own comments leaked**, because the provider sits inside the linted deployed surface
and my comments cite `B4F-007`: `[unannotated]` count is **0**, `B4F` appears **0** times in the lint output,
and my comments carry no DRIFT ids. **I introduced no self-leak.**

### PRED-BETA4-004, resolved against what was fixed in advance

- **Part 1 - my new suite passes in CI: HELD.** `workshop-resolve-prefers-open-feature` is not in the
  failing set.
- **Part 2 - no failure names the provider, `conformance-detection`, or a workshop suite: HELD.**
- **Part 3 - any failure is in a file this branch did not touch: FAILED.** Two of five are this branch's.

**Recording the failure plainly matters more than the two that held.** The prediction's whole value is that
its third part was falsifiable, and it was falsified.

### FINDING: the work-kind test pins the VALUE, so the capability is unusable by the project that ships it

`work-kind-runtime` T212 asserts **`Specrew declares software-feature`**. Declaring `bug-bash` - the
capability's own documented purpose, on the maintainer's ruling - **turns a test red by construction.**

**That is DRIFT-199-I003-084's class**, *assert the property, not the rendering*, and it sharpens
**B4F-006** considerably: the work-kind selection is not merely invisible and defaulted to the heaviest
contract - **it is pinned by a test.** A project cannot change its own work kind without editing a suite,
which is a strong reason nobody ever did.

**The property the test means to hold** is that Specrew dogfoods a valid declaration that resolves to a
shipped lifecycle contract - and the neighbouring assertion already checks exactly that
(`PASS: T212 (SC-014): Specrew dogfoods a .specrew/work-kind.yml`). **The value assertion adds nothing the
property assertion does not, and costs the capability.**

**NOT FIXED.** Two live options and the choice is the maintainer's: revert the declaration to
`software-feature`, or repair the assertion to check the property. **Recorded, stopped, reported.**

### The discriminator for the next dispatch, fixed in advance

The re-stamp (`36a782cb`) landed **after** the dispatched commit `f712345e`, so failures 1 and 2 were both
measured against the drifted marker. **PRED-BETA4-005: on a re-dispatch with the re-stamp in the tree,
`validate-governance-changed-only` goes green, and `pr-review-integration` goes green if and only if its
cause was the same W43 error.** If `pr-review-integration` still fails, its cause is independent and this
entry's UNDETERMINED becomes a separate finding rather than a suspicion.

---

## B4F-020 - THE WORK-KIND REVERT, and a correction of B4F-019 that is the spine finding in my own reading

### The correction first, because B4F-019 is wrong

B4F-019 said `work-kind-runtime` T212 **"pins the VALUE `software-feature`"**, that the assertion **"adds
nothing the property assertion does not"**, and offered repairing the test as a live option. **All three are
wrong, and the maintainer caught it by reading the source.**

Line 57 sits inside a block headed
`# --- SC-014 dogfood self-consistency: Specrew's own capture matches its actual posture (structural) ---`,
beside:

```
work-kind.yml exists · declares software-feature · repository-governance.yml exists
provider: github · release_truth_branch: main · protected/no-force-push/no-deletions · apply_to_admins: true
```

**One invariant, not a value pin.** Specrew IS a software product, so `software-feature` is its true
posture. Declaring `bug-bash` at project scope made the dogfood file **false**, and **the test caught it
correctly**. Repairing it would have been **editing a guard to accept the falsehood it exists to flag** -
B4F-018's exact class, and the most expensive possible instance of it.

**AND THE ERROR IS B4F-018'S OWN SHAPE, in my reading rather than my measuring.** I read the failing
assertion line in isolation instead of the block containing it. **That is now the third instance of this
exact error in this arc:**

| reading | what I read | what contained it |
| --- | --- | --- |
| DRIFT-199-I003-094 | line 627 as a reader | the WRITER function it sits inside |
| B4F-005 | line 564's filter as a validity gate | the unconditional `valid = $true` two lines below |
| **B4F-019** | **line 57 as a value pin** | **the SC-014 self-consistency block it belongs to** |

B4F-005 stated the rule as *when a line is named as a cause, trace to the `return` that carries it.* **It
generalises, and the general form is what B4F-018 already says**: a line read outside the construct that
contains it is a claim measured over a narrower set than it covers. **State predictions and rulings against
the source, not the summary** - here the summary said "pins software-feature" and the source said "asserts
self-consistency", and they lead to opposite fixes.

### The revert

`.specrew/work-kind.yml` is back to `work_kind: software-feature`. **T212 is green again with no test
touched** - verified, all SC-014 assertions pass.

### THIS PROVES B4F-006 RATHER THAN ILLUSTRATING IT

B4F-006 recorded that the work-kind selection is invisible and defaults to the heaviest contract. **The
stronger form, demonstrated rather than argued:**

> **work-kind is declared at PROJECT scope, and beta4's bug-bash character is a FEATURE-level truth. So
> expressing it through the only available lever forced the PROJECT to misdescribe itself.**

**There was no correct value to write.** `software-feature` is wrong for beta4's conduct; `bug-bash` is
wrong for Specrew's posture; and the mechanism offers nowhere else to say it. That is not a defaulting
problem - it is a **missing scope**, and per-feature work-kind is the beta5 item with this as its evidence.

### How beta4 proceeds instead

**Feature 201 closes the way iteration 003 did**: as the reactive defect sweep it honestly is, **under the
`software-feature` contract, with a recorded deviation that its conduct was bug-bash.** No eight-lens
workshop is run for a bug fix. The deviation exists only because the mechanism cannot express per-feature
work-kind - it is a disclosure, not an irregularity to be tidied away.

---

## B4F-021 - THE CENSUS IS DETERMINISTIC, and the three remaining failures are therefore IN SCOPE

**The largest available finding did not materialise, and establishing that took reading the JOB results
rather than the run conclusions - B4F-018 applied to the gate's own output.**

Two runs on the identical SHA `11f47c4b`, an hour apart, with **opposite run conclusions**:

| run | event | prepublish | **full-test-census** | publish-module | run conclusion |
| --- | --- | --- | --- | --- | --- |
| `34104867264` | workflow_dispatch | success | **success** | success | success |
| `34110313527` | push | success | **success** | **failure** | **failure** |

**`full-test-census` succeeded in BOTH.** The entire run-level difference is `publish-module`, and within
it exactly one failing step: **`Create GitHub Release with module zip attached`**. `Stamp and publish`
**succeeded** - the module reached the gallery; only the GitHub Release object failed.

**So:**

1. **The census is NOT non-deterministic.** "A green census gates the tag" is intact. Had the run colours
   been trusted, the conclusion would have been the opposite and it would have stopped the tag.
2. **The census was GREEN at `11f47c4b`.** Therefore the three non-beta4 failures -
   `no-internal-ids-in-emitted-strings`, `self-leak-lint`, `pr-review-integration` - are **genuinely new
   since that commit**, introduced by work landed after it, and **they block the tag whoever caused them.**
3. **All three test files are unchanged since `11f47c4b`** (measured: zero diffs). **The code moved, not the
   tests.**

**One inference tried and withdrawn before it reached a conclusion**: that the clarify-refusal fix
introduced the `no-internal-ids` offender. The `AcceptedForms` block IS new (0 at `11f47c4b`, 4 today), but
**the offending `Provenance` line carrying `DRIFT-198-I011-006` is NOT** - it is present at both commits and
was introduced by `70b4fef3`. **The cause is still open**, and it is being established by running the three
rather than reasoned about.

---

## B4F-022 - THE MERGE-BACK DETACHED A POSITIONAL EXEMPTION: one cause established, two still open

**All three reproduce locally (exit 1 each), so none is CI-only.**

### `no-internal-ids-in-emitted-strings` - CAUSE ESTABLISHED, and the fix is one line

The guard scans string literals in shipped `.ps1` files for internal ids, and exempts a hit when a comment
carrying `specrew-internal-id-ok:` sits **on the same line or the line directly above**:

```powershell
if ($commentLines.Contains($line) -or $commentLines.Contains($line - 1)) { continue }
```

**At `11f47c4b` the exemption was adjacent, and the test was green:**

```
2161   # specrew-internal-id-ok: maintainer-facing rule-table provenance data
2162   ); MarkerMatch = 'any'; Provenance = '... after DRIFT-198-I011-006' }      <- line-1 exempt
```

**Today the clarify-refusal fix has split that one-liner and inserted twelve lines between them:**

```
2161   # specrew-internal-id-ok: maintainer-facing rule-table provenance data
2162   ); MarkerMatch = 'any'
2163+  # AcceptedForms is CONSUMER-FACING ... (10 comment lines)
2172   )
2174   Provenance = '... after DRIFT-198-I011-006' }                              <- 13 lines away
```

**Nothing about the exemption or the string changed. The distance between them did.** The annotation is
still there, still correct, still describing a maintainer-facing field - and it no longer reaches its
subject.

**This is DRIFT-199-I003-060's class arriving by a new route.** That entry found an exemption that could
never fire because its baseline had changed. **This one fired correctly for months and was detached by an
insertion between it and the thing it exempts** - so the failure mode is not a stale predicate but a
**positional binding broken by unrelated editing**, and no reviewer of the clarify fix would have seen it:
the diff reads as adding a consumer-facing message.

**The cause is `e3ccc53f`**, the clarify-refusal fix, arriving through the merge-back - the change
DRIFT-199-I003-091 recorded as never having shipped in beta3 and as carrying to beta4. **It carried this
with it.**

**The fix is to move the annotation to the line directly above `Provenance`** - a comment-only change to a
packaged file. **NOT TAKEN: packaged file, stop-and-report.**

**And the durable form worth naming**: a positional exemption is a hand-maintained adjacency. The guard
could bind the annotation to the *string* rather than to a *line number*, which is the same lesson as
asserting the property rather than the rendering.

### `self-leak-lint` - OPEN

Test 9's born-clean guard fails on **171 annotated hits, zero unannotated** - the exact count
DRIFT-199-I003-028 measured. **I introduced none of them.** But 171 sanctioned hits would also have been
present at `11f47c4b`, where the census was green, so **something about the count or the guard changed and
I have not established which.** The discriminating measurement is the annotated-hit count at `11f47c4b`
against today's; it has not been taken, and no cause is being asserted without it.

### `pr-review-integration` - OPEN

`NONBLOCK_WARNING_MISSING exit=1`. The test runs the validator end-to-end and captures only the result
token, so the validator's own reason is absent from both the CI artifact and the local log. **Its earlier
suspected link to the W43 marker drift is now doubtful** - the marker is re-stamped and `drifted=0`, yet the
failure still reproduces locally. **Cause open.**

**Two of three open is the honest state**, and it is recorded as such rather than rounded into the one that
is solved.

---

## B4F-023 - THE SEAL GATE REFUSED EVERY VALIDATOR RUN IN THE PROJECT, and closeout sealed before writing its own records

**The finding of the day, established by the maintainer running the artifact rather than reading its head.
`pr-review-integration` was never a pr-review defect at all.**

### What was actually happening

Every condition Test 7's soft warning needs is TRUE on this tree - `Active=True Host=github`,
`OptIn.Enabled=True`, `038/001 state.md` matching, `pr-review-resolution.md` absent - and
`validate-governance.ps1` is unchanged since the green tag. **The warning is never reached, because the run
terminates before it.** Test 7's command, whole output, three lines:

```
[validator-scope] explicit-targets (1 iterations)
FAIL [trust-hardening] closed-iteration-edited: Closed iteration
     specs/199-beta3-stabilization/iterations/003 was edited after its closeout seal:
     drift-log.md, review.md, tasks-progress.yml, state.md.
[validator-timing] mode=scoped elapsed_ms=723
```

**The W51 seal gate is project-wide.** It runs on every validator invocation regardless of
`-IterationPath` and exits on the spot - so a broken seal on one iteration **refuses every validator run in
the project**, and every test that drives the validator fails for a reason that has nothing to do with what
it tests.

**That is B4F-013's rule exactly**: *a block upstream hides every defect downstream of it.* Here it hid
whether the pr-review soft warning works at all.

### TWO PRODUCT DEFECTS, both beta5

**(a) Closeout writes the seal BEFORE its own last records.** 003 was sealed `2026-09-08T21:20:27Z` over
dashboard, drift-log, plan, retro, review, state and tasks-progress. Then **`8a7e9f2e` edited `review.md`
AFTER writing the seal, inside the same commit** - the closeout breaking its own seal, in one atomic change.
`71895b38` and `a32434f4` then wrote the DRIFT-097 and prediction records into `drift-log.md` and
`state.md`. **The seal must be the final write of closeout**, and `8a7e9f2e` proves it against itself.

**Why the tag was green**: 003 was not yet sealed when it ran.

**(b) B4F-002 UPGRADED - it is worse than recorded.** The post-seal writer does not merely write a false
value. It flipped 003's `Iteration Status` from `complete` to `not-started`, rewrote `tasks-progress.yml`,
**and thereby put the whole project into a state where the seal gate refuses every validator run.** A
session resume - no user action, no command - can disable validation project-wide.

### THE GATE OFFERS NO REMEDY, which puts it in B4F-017's family

The refusal names the condition and **offers no remedy at all**. The only remedy that exists - a re-seal
through the product's writer - **is not mentioned, because the product treats the condition as impossible.**
Sealed means immutable, and the gate does not consult Post-Ship Amendments. So a human meeting this has a
correct, specific, actionable-sounding failure and **nowhere to go**.

That is the same family as B4F-017's `specrew update`, one step worse: there the named remedy was
destructive; here there is no named remedy at all.

### PRED-BETA4-007, stated before the fresh-project walk runs it

**On a fresh project: close an iteration, resume the session, run the validator - it goes RED on
`closed-iteration-edited`, for files the product itself rewrote.**

If it holds, it is a **beta4 release-note known issue** with the one-line workaround
(`git checkout` the iteration's `state.md` and `tasks-progress.yml`), and **whether it becomes a beta4 fix
is the maintainer's call after the walk, not before.**

### What was done here

003's two writer-dirtied files were restored with `git checkout` (never staged - they re-dirty on every
resume), and **003 was re-sealed on the maintainer's authorization**, bounded: `touched=3` before
(review.md, drift-log.md, state.md), `touched=0` after, and the only changed path in 003 is
`.specrew-iteration-seal.json`. **Nothing touches 003 after that point** - any edit inside it breaks the
seal again, which is why this record lives here and not in 003.

---

## B4F-024 - I READ THE HEAD OF THE OUTPUT AND CALLED IT THE VERDICT

**B4F-018's instance in my reading, the fourth this arc, and it changed a classification.**

I reported `self-leak-lint` as failing on "171 annotated hits, zero unannotated" and classified its cause as
**NOT MINE and unexplained**. **"Zero unannotated" was the FIRST line of the lint's output.** The verdict was
further down:

```
RED: 1 unannotated Specrew-self fact(s): shared-governance.ps1:2169
     matched 'DRIFT-199-I002-029' class self-provenance-id
```

**One unannotated hit, in the AcceptedForms comment block from the same `e3ccc53f` insertion** - the comment
that read *"the same standard the batch settled at DRIFT-199-I002-029"*. The annotated 171 were never the
failure; the suite's own PASS line says so: *"real repo deploy surface green (annotated debt recorded with
reasons)"*.

**The fix is the lint's own doctrine**: deployed teaching states the rule and never cites the internal
record. Reworded to *"the same standard already settled for refusals - name the thing that actually
failed"*.

**The shape, again**: a claim measured over a narrower slice than it covers - here the first screen of an
output rather than the output. **Running the artifact and reading the verdict is what found it**, which is
the countermeasure B4F-018 names, applied by the maintainer to my report.

---

## B4F-025 - FEATURE 201 HAS NO SPEC, AND ITS CLOSEOUT WILL DEMAND ONE

**Measured: feature 201 is the only live workshop candidate in this repository** - it carries both
`lens-applicability.json` and a `spec.md` still holding the `specrew:spec-not-yet-authored` sentinel.

Under the `software-feature` contract - correctly restored per B4F-020 - **201's closeout will demand a
specification it honestly does not have**, because beta4 is a defect sweep whose bug list and root causes
were complete before the feature existed.

**A workshop is NOT run to satisfy that.** Running eight lenses to manufacture a spec for a fix that is
already written, reviewed and mutation-proved would be producing the artifact to satisfy the gate rather
than the work - the failure this project exists to prevent.

**201 closes the way 003 did**: on the maintainer's explicit override, with the deviation stated in the
record - that its conduct was bug-bash, that no spec was authored, and that the mechanism could not express
either because work-kind is project-scoped (B4F-006, B4F-020). **The deviation record must say this
explicitly rather than leaving a reader to infer it from an empty spec.**

---

## B4F-026 - `validate-governance-changed-only`: NOT beta4's, cause identified, and the dispatch is its discriminator

**Four of the five previously-red suites are green** - `pr-review-integration`, `no-internal-ids`,
`self-leak-lint`, `work-kind-runtime`. **`pr-review-integration` going green confirms B4F-023 end to end**:
its soft warning was unreachable only because the project-wide seal gate terminated every validator run.

### The remaining red, read from the output rather than filtered

```
[validator] -ChangedOnly fallback to full validation: base-ref-undetectable (base (unresolved))
[validator] (1/1) validating specs\013-validator-hardening\iterations\002
FAIL ... /013-validator-hardening/iterations/002
  category=missing-artifact | message=Missing required artifact: state.md
[validator-timing] mode=unscoped elapsed_ms=48017 iterations_validated=1 trigger_source=local
```

**The chain**: the fixture's git base ref does not resolve, so `-ChangedOnly` **falls back to unscoped**;
unscoped validation then reaches iterations whose `state.md` the fixture **deliberately strips**
(`Remove-UntouchedStateArtifact`), and fails on the missing artifact. Every failing assertion in the local
set follows from that one fallback - including the scope-banner and `mode=scoped` timing assertions, which
are simply describing the unscoped run they got.

**My first read of this was wrong twice over** and both errors are B4F-018's: I reported the touched
iteration as *skipped* when it was validated and failing, having grepped for `closed-iteration filter`
instead of reading the output; and I compared exit codes rather than assertion sets.

### NOT CAUSED BY BETA4'S DIFF - proved, not asserted

The only beta4 change to this code path is the comment move and reword in `shared-governance.ps1`.
**Inertness proof, with the precondition asserted first** (a proof that compares a file to itself proves
nothing - DRIFT-199-I003-055):

```
versions_differ  = True
before           = 49965 executable tokens
after            = 49965 executable tokens
differing_tokens = 0     -> identical, position for position
```

**A comment-only claim is a byte-level claim and it has been measured**, not reviewed by eye.

### The assertion SETS differ from CI's, so the causes are not assumed to be the same

| | failing assertions |
| --- | --- |
| CI at `f712345e` | explicit-changed-only, auto-scoped-feature-branch, missing-origin-head |
| local, now | those plus should-still-validate-touched, should-skip-untouched, scoped-timing |

**DRIFT-199-I003-051: red-at-both is an unexamined coincidence of exit codes until the sets are compared.**
CI's cause at `f712345e` was consistent with W43 marker drift, which is now cleared (`drifted=0`). **The
local cause is base-ref resolution in the fixture, which is a property of the machine's git state as much as
of the tree** - and DRIFT-199-I003-083's rule cuts both ways: a local result is evidence about the local
environment.

### Classification, and what settles it

**Not beta4's.** Whether it is a real tree failure or local-environment-only is **not established**, and the
instrument that settles it is the **dispatched run** - which is the next step regardless, and which
DRIFT-199-I003-083 already requires as the last green before a tag.

**If it is red on the dispatch, it is a fourth pre-existing blocker beta4 did not cause**, and whether it
holds the tag is the maintainer's decision rather than something to absorb into "fix it and move on".
