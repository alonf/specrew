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

---

## B4F-027 - THE REVIEW ROUND CANNOT RUN: a second runtime marker, drifted since before the last green census, whose only named remedy destroys beta4

**The round was approved, unspent, and could not be spent. The blocker is pre-existing and is not beta4's.**

### The refusal, unchanged after two re-stamps

```
review-engine-project-runtime-drifted:
  marker=df8a01650e9665d4d806741b06c22e6a8c12ce493036f98a4c51b577ba7f06d4
  actual=b56b0f25e7263763e74f5dc7c9a0580f31c15ac908ecedd6c35b54ce29273ec5
  run 'specrew update --project-path "..."'
```

**Byte-identical to the first refusal** - the same `marker=` and the same `actual=` - after two successful
re-stamps of the extension marker that both ended `drifted=0`. **That is the tell: the review engine does
not read the marker that was re-stamped.**

### There are TWO runtime markers over deployed content, with two checkers

| marker | scope | checker | basis |
| --- | --- | --- | --- |
| `.specify/.../.specrew-extension-runtime.json` | 164 managed files | `Test-SpecrewDeployedExtensionIntegrity` | per-file |
| `scripts/internal/continuous-co-review/.specrew-runtime.json` | 61 files | `review-engine-resolution.ps1:253` | one **logical** bundle SHA |

`review-engine-resolution.ps1:215` resolves `$projectRuntime = <project>/scripts/internal/continuous-co-review`,
and the stored `runtime_bundle_sha256` is `df8a0165...` - **the refusal's `marker=` exactly.**

**Re-stamping one does nothing for the other.** That is DRIFT-199-I003-034's class - two guards, different
scopes, overlapping content, composing only by accident - with a third instance and a live cost: it blocks a
required lifecycle stage.

### PRE-EXISTING, and the proof does not depend on the hash basis

| fact | value |
| --- | --- |
| co-review runtime files changed between `11f47c4b` and HEAD | **0** |
| stored `runtime_bundle_sha256` at `11f47c4b` | `df8a0165...` |
| stored `runtime_bundle_sha256` today | `df8a0165...` - identical |

**Neither side moved.** The drift is byte-for-byte the same as it was at the last GREEN census, so it
**predates beta4 entirely** and cannot have been caused by it. It never blocked the census because **the
census does not invoke the review engine** - only `specrew review` does.

**A NUMBER I WITHDRAW BEFORE PUBLISHING IT.** In flight I measured "44 of 61 files drifted" by comparing raw
per-file SHA-256 against the marker's entries. The writer's own comment says the bundle hash is a **logical**
hash that *"normalizes managed-text encoding and line endings"* - **a different basis**, so that figure
measured the wrong thing and is not reported as a finding. B4F-018 again, caught before it reached a
conclusion this time. **The pre-existing verdict above stands on its own evidence: nothing on either side
changed.**

### The remedy problem, which is B4F-017 at its worst

- **`specrew update` is FORBIDDEN** - it would overwrite the deployed provider with installed beta3 bits and
  **destroy beta4's fix**. It is the only remedy the message names.
- **The sanctioned extension re-stamp does not reach this marker.**
- **The writer is not a callable standalone.** It lives inline in `deploy-squad-runtime.ps1:956`, computing
  from locals (`$continuousReviewRuntimeSource`, `$currentRuntimeManagedFiles`) inside the deploy routine -
  so there is no `Write-...Marker` to invoke the way `Write-SpecrewDeployedExtensionMarker` was.
- **A targeted re-stamp has precedent**: `6e0ffb4b`, *"chore(beta3): re-stamp the project runtime before
  review-signoff"*, changed exactly 4 lines of this file. **How it was produced is not established**, and
  guessing at it would be writing a governance digest by inference.

**STOPPED AND REPORTED.** This needs the maintainer's ruling: it writes a governance artifact, the product's
own remedy is destructive, and the drift is not beta4's to absorb.

---

## B4F-028 - PREDICATE (A) TESTED AND REJECTED, and the control meant to decide it does not cover the path

**Implemented, run, reverted. The decision rule would have shipped a dead fix on a green control.**

### What (A) did

(A) qualified an intake candidate only when its controller shows an underway workshop - `agenda_status`
confirmed, a real `agenda_turn_receipt`, a non-empty selection, or a recorded lens. Applied to source and
mirror, parse clean, mirror identical. Result on the eight-case suite:

| case | under (A) |
| --- | --- |
| **1 - POSITIVE CONTROL** | **PASS** |
| 2 - the regression the fix exists for | **FAIL** (3 assertions) |
| 7 - ambiguity refusal | **FAIL** (2) |
| 8 - the guard must not weaken the fix | **FAIL** (2) |

**Seven assertions red. The fix is dead under (A)** - a stale ref no longer yields to the open workshop,
which is the entire defect B4F-007 measured.

### AND CASE 1 PASSED ANYWAY, which is the finding

**Case 1 resolves through the START-CONTEXT path, not the candidate path.** It passes
`-ActiveFeatureRef $openRef`, so the context path finds the open workshop and returns valid before the
candidate logic matters. **Under (A) it stays green while the thing it was chosen to certify is broken.**

**So "run Case 1 first; pass, ship (A)" would have shipped a dead fix on a green control.** That is
B4F-018's shape in the TEST DESIGN rather than in a measurement: a control exercising a narrower path than
the claim it certifies. The other cases caught it only because they were run anyway.

**The correction to the suite is cheap and owed**: Case 1's assertions should state which path resolved
them, so a control cannot silently certify a path it never took.

### The deeper result: durable state cannot distinguish the two cases

| | untouched stub (201) | genuine second feature, FIRST question |
| --- | --- | --- |
| `agenda_status` | pending-confirmation | pending-confirmation |
| `agenda_confirmation` | pending | pending |
| `agenda_turn_receipt` | `pending` | `pending` |
| `selected` / `workshop` | 0 / empty | 0 / empty |

**Byte-identical.** The only difference is whether a question was posed in the turn.

**That also defeats "underway or presented" when `presented` must be durable**: on the first question's
turn there is no durable record of it yet, because the projection that would record it is the thing being
gated.

**Why (B)-narrowed was rejected, recorded as instructed**: it puts the projection - and therefore the
receipt the resolve needs to advance - behind line 564's question-mark heuristic. A missed detection would
silently re-block a live workshop, and that is the one failure beta4 cannot ship.

**So no predicate over durable state both excludes an untouched stub and admits a genuine first question.**
Recorded as an open beta5 design question rather than resolved by guess.

### It does not block beta4, because the ruling's own item 3 ends it independently

Authoring 201's specification removes the not-yet-authored marker, so **201 stops qualifying as a candidate
regardless of the predicate**. Measured: intake candidates in this repository **1 -> 0**. The receipts and
the every-turn advisory end here with no provider change at all.

**A trap found on the way**: the first draft of that specification KEPT 201 a candidate, because it named
the marker token in prose and the scan matches it anywhere in the file. Reworded to describe the marker
without spelling it. Same shape as DRIFT-199-I003-018 - the record about a defect reproducing it.

### Restore rehearsal - the snapshot is a restore path, not a hope

Restored the gallery snapshot into a scratch module root and imported it in a clean process: **411 files,
import succeeded, version 0.40.0, stamp commit `11f47c4b`, 16 commands exported.** The pre-beta4 gallery
build is recoverable, and has now been recovered once.

### RESOLUTION - beta5's candidate fix, and it supersedes "open design question" above

**The predicate is not discoverable from durable state because nothing durable records the act of posing.
So the act declares itself.**

> **The workshop skill DECLARES the posed question durably at the moment it poses it, and the candidate scan
> requires that declaration. Declared, not detected.**

- **It removes the punctuation dependency entirely.** Detection asks a heuristic to infer what happened;
  declaration records it. Line 564's `?` heuristic stops being load-bearing for anything.
- **It separates the two states that are currently byte-identical**: an untouched stub has no declaration; a
  genuine second feature's first question has one, written by the skill in the same turn it asks.
- **It is the same pattern as the turn-end intent** recorded alongside it - the agent states what it did
  rather than leaving a hook to infer it from output shape. Two findings, one mechanism.

**BETA5, as a candidate resolution rather than an open question.** Beta4 ships the fix as-is; the stub
condition is disclosed in the release notes and pre-flighted in the crew brief instead.

---

## B4F-030 - THE REVIEW CAMPAIGN REQUIRES AN ITERATION THAT A BUG-BASH FEATURE LEGITIMATELY NEVER HAS

**B4F-025's prediction landing, and a third instance of the remedy-wrong-for-state family.**

### What happened

The round is no longer blocked by runtime drift - the build-then-update cleared that. It now refuses with:

```
review-campaign-active-iteration-unresolved

The human's typed approval was NOT spent - nothing ran. Once the feature is named,
run this again; their approval is still standing.
```

**Two halves, and they deserve opposite verdicts.**

### The good half, recorded because this log skews to failures

**That refusal is the standard working.** It names the condition, states plainly that **the human's typed
approval was NOT spent**, confirms the approval still stands, and gives one concrete action. Nobody has to
wonder whether a round was burned. **Compare B4F-017's `specrew update`, whose named remedy would have
destroyed the fix.** This one protects the human's authority and says so.

### The bad half: the named remedy does not clear the condition

**I took the named action - `--feature 201-first-run-experience` - and the refusal is byte-identical.**

The real condition is not an unnamed feature. It is that **feature 201 has no `iterations/` directory at
all**: it never reached the plan boundary, by the maintainer's explicit ruling that a defect sweep does not
run planning ceremony. `specs/201-first-run-experience/` contains exactly `lens-applicability.json` and
`spec.md`.

**Third instance of remedy-wrong-for-state** (DRIFT-199-I003-016's family, after `specrew update` twice):
the message describes a state the reader is not in, and following it changes nothing.

### And this is B4F-025's prediction landing

B4F-025 recorded that 201's closeout would demand a specification it honestly does not have. **The review
stage demands an iteration on the same grounds** - the `software-feature` contract expects planning
artifacts that bug-bash conduct deliberately never produced, and work-kind is project-scoped so the
distinction could not be declared (B4F-006, B4F-020).

### Three ways forward, and the first carries a real hazard

1. **Scaffold `iterations/001` for 201.** It is the artifact the campaign wants. **But DRIFT-199-I003-086
   measured iteration scaffolding ADVANCING boundary state as a side effect** - `boundary_type: plan`
   written 32 seconds after the scaffold, with no verdict. That is DRIFT-199-I003-097's defect triggered
   deliberately, and it is not something to do unasked. (Feature scaffolding does not do this - B4F-020
   measured that separately.)
2. **Skip the governed round, record the deviation.** The fix already had a full adversarial review that
   found a real defect - property 1 was false, the ambiguity guard exists because of it - and that review
   is recorded across B4F-010 and its commits. The deviation would say: reviewed, not campaign-recorded.
3. **Run the round against a different scope** that resolves an iteration - none is honest here, since
   199/003 is sealed and closed and this work is not its.

**STOPPED AND REPORTED. The approval is still unspent and still standing.**

---

## B4F-031 - OPTION (4) EXECUTED TO THE REVIEWER, WHICH NEVER RAN: a CLI/model mismatch, not an empty review

**Everything up to the reviewer worked. The reviewer itself returned a 400 and produced nothing.**

### What was built, and it is reusable

Export at `C:\Temp\beta4-codex-review-20260909-142846`, outside the project:

| artifact | bytes |
| --- | --- |
| `diff.patch` - `b62ba968..HEAD` restricted to the fix's files | 31,989 |
| `files/` - full HEAD content of all three touched files (2086 + 8230 + 254 lines) | 618,901 |
| `REVIEW-PROMPT.md` - **the engine's own template**, rendered | 4,634 |

**The prompt is the engine's, not an improvisation.** It was rendered from
`scripts/internal/continuous-co-review/reviewer-candidate-prompt.md` through the engine's own
`Test-ReviewFilePrimaryPromptTemplate`, which returned **`template_contract_valid = True`** - so it carries
the eleven contract rules the harness enforces, including raw-JSON-only, single-reviewer-session (no
delegation), risk-based completion, and the finding budgets. **Zero unsubstituted placeholders.** Output
would have had the shape the engine harvests.

### What the reviewer did

**Nothing.** `candidate-result.json` was never created, and the log is not an empty stream - it carries an
explicit refusal:

```
ERROR: {"type":"error","status":400,"error":{"type":"invalid_request_error",
"message":"The 'gpt-6-astra' model requires a newer version of Codex.
Please upgrade to the latest app or CLI and try again."}}
```

`codex-cli 0.151.0`; `~/.codex/config.toml` pins `model = "gpt-6-astra"`.

**This is reported as "the reviewer never ran", NOT as "the file was empty".** An empty findings file would
mean a review happened and found nothing; this is a review that did not happen. Conflating them is exactly
the mislabel the codex-delivers-via-file lesson exists to prevent, and the distinction survives here because
the log was read rather than the exit code.

**Two things were deliberately NOT done**, because each decides something that is not mine to decide:

- **Overriding the model** (`-c model=...`). Which model reviewed the code is evidence about the review, and
  substituting one the maintainer did not choose would put a different reviewer's identity into the record.
- **Upgrading the Codex CLI.** An install action on the machine the maintainer presents from, two days
  before the conference.

### A SEPARATE FINDING: a scratch directory is not hook-free for codex

The log shows `hook: SessionStart` and `hook: UserPromptSubmit` firing **in the scratch directory**.
`specrew update` deployed codex hooks **user-level** to `C:\Users\alon\.codex\hooks.json` (13:05 today),
not per-project - as its own output said at the time: *"codex hooks deployed to C:\Users\alon\.codex\hooks.json"*.

**So the standing probe-hygiene rule - never probe an agentic CLI in a governed cwd, use scratch directories
- does not fully hold for codex.** The hooks follow the user, not the working directory. Harmless here (a
scratch directory has no governed state to mutate), but the rule's premise is weaker than it reads and the
next person relying on it should know. **Beta5, with the deployment-surface items.**

---

## B4F-032 - A PROJECT INSTALL WRITES USER-LEVEL FILES AND DOES NOT SAY SO - the hook is a strict no-op, the undisclosed global write is the finding

**Not filed as harmless. The no-op was measured; the disclosure gap is what remains.**

### The hook IS a strict no-op outside a Specrew project - measured, not assumed

Ran the deployed launcher directly for all three events, from a scratch directory that is not a Specrew
project, watching both that directory and `~/.specrew`:

```
SessionStart       exit=0  stdout_bytes=0
UserPromptSubmit   exit=0  stdout_bytes=0
Stop               exit=0  stdout_bytes=0

files_created  = 0
files_modified = 0
STRICT_NO_OP   = True
```

**So a codex session in an unrelated directory is not silently governed, and probing there does not mutate
state.** That half of the standing rule survives, and it now rests on a measurement rather than on
assumption.

### The finding: `--project-path` performs USER-LEVEL writes and discloses them as project output

`specrew update --project-path .` wrote **three files outside the project**, reported in the same flat list
as the project's own deployments:

| host | hook target | scope |
| --- | --- | --- |
| claude | `<project>/.claude/settings.local.json` | **project** |
| antigravity | `<project>/.agents/hooks.json` | **project** |
| cursor | `~/.cursor/hooks.json` | **USER** |
| codex | `~/.codex/hooks.json` | **USER** |
| copilot | `~/.copilot/hooks/specrew-refocus.json` | **USER** |

**A command whose only path parameter names a project changed three files that outlive it and affect every
other project on the machine.** The output lines are truthful and give the paths; nothing marks them as
global, and nothing asks. A reader scanning a long deploy log reads them as more project deployment.

**The requirement**: the install must **disclose the global write as global** - name it as a machine-level
change, separately from project deployment, before or as it happens.

### The probe-hygiene premise, corrected - and the correction is not the one proposed

The standing rule was *never probe an agentic CLI in a governed cwd; use scratch directories*. The proposed
correction was that scratch directories are hook-free **"for Claude and Copilot only"**.

**Measured from the update's own output, that is wrong about Copilot.** Copilot's hooks are USER-level
(`~/.copilot/hooks/specrew-refocus.json`). The hosts whose hooks are confined to the project are **Claude
and Antigravity**:

> **Scratch directories are hook-free for CLAUDE and ANTIGRAVITY only. Cursor, codex and copilot install
> hooks at user level, so they fire in every directory on the machine.**

**They still fire harmlessly** - `STRICT_NO_OP = True` above - but "no hooks run" and "hooks run and do
nothing" are different claims, and only the second is true for those three.

**BETA5**, with the deployment-surface items: disclose the global write, and keep the no-op measured rather
than assumed, since it is the only thing making the user-level deployment acceptable.

---

## B4F-033 - CENSUS 34346555521 CLASSIFIED: every part of PRED-BETA4-006 held, and the two remaining failures are unchanged files that were green twice

### First, before classification: the sweep executed

`Execute every named test file on disk` **ran and failed** - not skipped - and
`Upload census failure diagnostics` **succeeded**, carrying two per-file entries with assertion text. **A
sweep that ran and found things, not a provisioning death wearing a failure's clothes.** Not a timeout: the
run completed with `conclusion: failure`.

### PRED-BETA4-006, resolved against what was fixed in advance

| part | outcome |
| --- | --- |
| 1. the sweep executes | **HELD** |
| 2. the five prior failures are green, `validate-governance-changed-only` included | **HELD - all five green** |
| 3. any failure is in untouched code | **HELD** |
| 4. a timeout is named a timeout | n/a - completed in failure |

**Five failures down to two, and the two are not this branch's.**

### ITEM 4's PREDICTION RESOLVES, and it resolves against my doubt

`validate-governance-changed-only` is **GREEN**. By the meaning fixed in advance: **W43 held, and the marker
re-stamp plus the update cleared it.** DRIFT-199-I003-053's original attribution was correct, and B4F-026's
suspicion - that the local base-ref cause matched CI's three assertions better than W43 did - **is
withdrawn.** The local failure was about the local environment, exactly as DRIFT-199-I003-083 cuts both ways.

### The two remaining failures, measured

| file | changed since `b62ba968` | changed since `11f47c4b` (last green census) | in the previous run's failures |
| --- | --- | --- | --- |
| `tests/bootstrap/DispatcherLargeStdout.Tests.ps1` | **0** | **0** | no - it was green |
| `tests/integration/squad-init-closed-stdin.tests.ps1` | **0** | **0** | no - it was green |

**Both files are byte-unchanged since the last green census, were green in that census, were green in the
previous run, and fail now.** Their assertions are timing and process-lifetime claims:

- *"large-stdout: returned fast - no pipe deadlock (**17.9s**, well under the **20s** timeout)"* - a pass
  message reported as a failure, at **90% of its budget**;
- *"timeout did not prove that the complete fake Squad descendant process tree was terminated"*.

### THE FINDING: the census is deterministic for content and NOT for timing

**B4F-021 established the census was deterministic** - two runs on `11f47c4b` with identical job results.
**That stands, and this refines it rather than contradicting it**: those runs agreed because nothing
timing-sensitive tripped. Here, **unchanged files that passed twice now fail**, so the gate's verdict on a
fixed tree is not a function of the tree alone.

**That matters for the release rule.** "Tag only on the SHA a green dispatch ran on" assumes green is a
property of the SHA. **With timing-sensitive tests in an all-or-nothing gate, green is partly a property of
the run** - so a red census no longer distinguishes "this tree is broken" from "this runner was slow", and
re-running until green quietly converts a gate into a lottery nobody named.

**This is the diagnosability family again** (DRIFT-199-I003-037/-038): a gate whose failures cannot be acted
on trains people to stop reading it.

**BETA5**: either give the timing assertions budgets that survive a loaded runner, or move them off the
all-or-nothing gate as environment-bound - the category DRIFT-199-I003-025 already defined and refused to
let become an exclusion list.

---

## B4F-034 - THE REVIEW DEVIATION, taken as option (3), and this run's beta5 items

### The review deviation

**Beta4's fix is shipped REVIEWED BUT NOT CAMPAIGN-RECORDED**, on the maintainer's ruling, and the deviation
is stated here rather than left implied.

- **A real adversarial review happened.** It found that safety property 1 was false and that the fix could
  displace a workshop a human was actually answering. That defect was reproduced against a control, fixed
  two-directionally, and mutation-proved at both guarded sites with disjoint failure sets. The record is
  B4F-010 and its commits.
- **The governed campaign could not run.** Three attempts, three distinct refusals, each traced:
  `review-engine-project-runtime-drifted` twice (B4F-017, B4F-027 - a second runtime marker the extension
  re-stamp never reached, cleared by build-then-update), then
  `review-campaign-active-iteration-unresolved` (B4F-030 - the campaign needs an iteration that bug-bash
  conduct legitimately never produces).
- **The out-of-engine reviewer never ran** (B4F-031): the export and the engine's own contract-valid prompt
  were built, and codex returned a 400 because its CLI is older than its pinned model. **That is
  reviewer-never-ran, not an empty review.**
- **The maintainer's typed approval was never spent and is still standing.** Every refusal said so
  explicitly, which is the refusal standard working.
- **The export is kept** at `C:\Temp\beta4-codex-review-20260909-142846` - diff, full file contents, and the
  rendered prompt - so the review is one command away whenever a model is named. **A finding from it is a
  fix with its own commit, named before any re-dispatch, never folded in silently.**

### Beta5 items from this run

**(a) Timing assertions inside an all-or-nothing gate make green partly a property of the RUN.** They should
report the measured value and gate on a **margin against a calibrated baseline**, or live in a report-only
lane. As it stands, a red census cannot separate *this tree is broken* from *this runner was slow*.

**(b) `squad-init-closed-stdin.tests.ps1:209` must separate "observed alive" from "could not observe."**

```powershell
if ([int]$result.timeout_child_pid -le 0 -or [bool]$result.timeout_child_alive) {
    Write-Fail 'timeout did not prove that the complete fake Squad descendant process tree was terminated'
}
```

**Two conditions, one message** - an absent measurement and a surviving process are indistinguishable in the
output. One is a missing observation, the other is a real leak, and they need different messages because
they need different responses.

**A sibling worth fixing with it**: `DispatcherLargeStdout.Tests.ps1:71` **gates on 15 seconds and its
message names 20**, so a genuine budget failure reads as a comfortable pass. **An assertion's message must
name the threshold the assertion enforces.**

**(c) The single fixed-meaning re-dispatch is the sanctioned discriminator, and a second re-run of a red
census is refused.** One re-run whose meaning is fixed in advance distinguishes runner-bound from real. A
second converts the gate into a lottery, on the release the gate exists to protect.

### A deviation in executing the re-dispatch, recorded rather than left to surface at tag time

The ruling was to re-dispatch **on `22772117`**. The run went out on **`d4a89ab7`**, because the
PRED-BETA4-008 commit was pushed before dispatching and `workflow_dispatch --ref <branch>` takes the branch
head. **Measured**: the delta is three commits, two files, **both under `docs/`, zero census subject files**
- so the run measures identical code and its verdict is valid evidence about the same tree. **The tag SHA is
the maintainer's to settle**, and it is surfaced now rather than discovered at the tag.

---

## B4F-035 - STEP 1 AND 2 DONE, AND THE CREW HANDOVER IS BLOCKED BY A CONTROLLER BETA4 DOES NOT TOUCH

### Step 1: installed == tagged

Built and installed from the tag SHA with a guaranteed return to the branch:

```
packaged 414 files from d4a89ab7
byte verification: all 414 packaged files match
stamp verified against installed contents
stamp_commit = d4a89ab7   content = bbe308f8...   INSTALLED_EQUALS_TAGGED = True
branch restored, dirty_after = 0
```

The crew and the walk will now run on the build that gets published, not on `356e3295` - the accumulated-
proofs-on-intermediate-builds error DRIFT-199-I003-008 recorded and had to withdraw.

### Step 2: the router-skill project is updated, and the pre-flight found a blocker

`specrew update` moved **61 files** there onto the tag build. Then the pre-flight ran, and it found two
things - **one of them a defect in the brief I wrote.**

**(a) MY PRE-FLIGHT WAS SCOPED TO THE WRONG STAGE.** It scanned for features whose spec still carries the
unauthored marker - an **intake** check. **The router-skill crew is resuming TECHNICAL LENSES**, past
intake with an authored spec, so the check returned **0** and my own guidance for 0 said *"the feature you
mean to work has no open intake. Check you are in the right project"* - which would have sent the crew
chasing a non-problem.

**B4F-018's shape in an artifact I authored**: the claim was *the crew can start*; the check measured *an
intake workshop is open*. **Replaced with a check that asks the machinery** -
`Get-SpecrewWorkshopLifecycleState` per feature, exactly one must report `active` - which is the same
question the resolve itself asks.

**(b) THE ROUTER-SKILL CONTROLLER IS INVALID**, and the corrected pre-flight is what surfaced it:

```
001-agentic-architecture-skills    status=invalid   reason=workshop-record-not-selected
```

**Verified at source.** `ProjectMetadataAccessor.ps1:602` invalidates a controller when any workshop record
names a lens absent from `selected`:

```powershell
foreach ($recordProperty in $records.PSObject.Properties) {
    if ([string]$recordProperty.Name -cnotin $selected) { ... 'workshop-record-not-selected' ... }
```

**Measured**: `workshop` = `['product-domain']`; `selected` = the eight technical lenses;
**`product-domain` is in the record map and not in the selection.** And the technical agenda **deliberately
excludes** `product-domain` (DRIFT-199-I003-079), so the two cannot both be right.

### THIS IS THE THIRD FINDING ON THAT RESTORE, AND THE DECISIVE ONE

DRIFT-199-I003-092 examined the `product-domain` restore and concluded the clearing was cosmetic and the
correct response was to do nothing - the Casio walk left it alone and closed five lenses.
DRIFT-199-I003-093 corrected its mechanism (journaling stopped; the receipt was not consumed).

**Neither established what the restore actually left behind: a structurally INVALID controller.** The entry
that put `product-domain` into the workshop map is what the accessor now rejects. **-092's advice was right
and the repair had already happened.**

### Consequences, stated plainly

- **Beta4's fix does not clear this.** The workshop is not blocked by question registration; the controller
  is rejected before any of that matters.
- **The crew handover cannot proceed** until the controller is valid.
- **There is no sanctioned repair for this state.** Hand-editing `lens-applicability.json` is forbidden by
  the workshop conduct, and `repair-workshop-controller-state.ps1` covers pre-agenda state only and declines
  past it (DRIFT-199-I003-093). **Same shape as B4F-030 and B4F-017: a real condition with no reachable
  remedy.**
- **It is not beta4's to absorb.** Recorded, brief updated with it as a named known blocker, and reported.

---

## B4F-036 - THE ROUTER-SKILL CONTROLLER REPAIRED, and two beta5 items with priority

### The repair, bounded and verified

Authorized by the maintainer's typed instruction, executed with precondition and postcondition printed:

```
before : invalid / workshop-record-not-selected
         workshop = [product-domain]; selected = the eight technical lenses; agenda_status = confirmed
after  : ACTIVE / workshop-active / current_lens = architecture-core, remaining = 8

other controller properties changed : 0
workshop evidence files changed     : 0   (9 lens records + product-domain.yml + implementation-rules.yml + spec.md)
runtime stores touched              : 0   (receipt store and conformance journal, by hash AND mtime)
REPAIR_VERIFIED = True
```

Written the product's own way - **atomic temp-and-move, UTF-8 without BOM**, the
`Write-SpecrewLensAtomicUtf8NoBom` pattern from `confirm-workshop-lens.ps1:56`. Never `Set-Content`, never
a hand-edited digest. Committed in the router-skill project as `e1181f0` with the authorization quoted
verbatim. **Pre-flight now passes: exactly one active workshop.**

**Recorded as a documented gap, not a preference**, and both halves were verified at source before the
ruling stood:

| writer | refusal |
| --- | --- |
| `confirm-workshop-agenda.ps1:112` | refuses unless `agenda_status` is `pending-confirmation`; this one was `confirmed` |
| `repair-workshop-controller-state.ps1:105-106` | `throw 'workshop-repair-only-pending-state-supported'` |

**No sanctioned path reaches a post-agenda controller.** That is why the repair was done by hand under
explicit typed authorization rather than by a writer, and why it is written down that way.

**And the nine lens decision records were on disk the whole time**, untouched. Only the controller's
*projection* of them was wrong - which is what made a bounded repair the right size of act.

### BETA5, priority

**(a) `repair-workshop-controller-state.ps1` must cover post-agenda states**, at minimum
`workshop-record-not-selected`, **under the existing proposal + typed-authorization mechanism** it already
has. The mechanism is right; only its reachable state set is too narrow. Today a project in this state has a
real condition, a correct detector, and **no reachable remedy** - the shape B4F-017, B4F-030 and this entry
now share three times over.

**(b) THE WRITER WROTE A RECORD THE READER REJECTS.** The lens writer produced a `product-domain` entry in
the workshop map; the accessor (`ProjectMetadataAccessor.ps1:602`) rejects any record naming a lens absent
from `selected`; and the technical agenda **excludes `product-domain` by construction**
(`confirm-workshop-agenda.ps1:148`, DRIFT-199-I003-079). **Two components disagree about what a valid
controller is, and neither is wrong on its own terms.**

**One of the two must change, and it must be decided rather than left:**

- the **writer** enforces the reader's invariant and refuses to record a lens that is not selected; **or**
- the **reader** tolerates intake-lens records, since `product-domain` is legitimately outside the technical
  agenda.

**Leaving both as they are is the third option and it is the one that produced this.** It is the
records-versus-controller split (DRIFT-199-I003-010) reaching the point where it stops a workshop rather
than merely disagreeing.

---

## B4F-037 - THE CODEX HARVEST: one major finding, classified FIX, reproduced and repaired

**Amends B4F-031.** That entry recorded the reviewer never running. **It ran on retry after the Codex CLI was
updated** - `codex-cli 0.153.4`, **model `gpt-6-astra`**, the model actually used. **B4F-031's first-attempt
record stands exactly as written**; this is the sequel, not a correction of it.

**Two further attempts were needed, and all three causes were mine, not codex's:**

1. **A stale deadline.** `__DEADLINE__` was rendered at 14:28 as *now + 20 minutes*; the retry ran at 15:56.
   Codex declined: *"The host clock is already past the supplied deadline"*, and reported **no source files
   read, no findings established** - a correct refusal.
2. **No git metadata** in the export directory.
3. **A read-only sandbox**, so the result file could not have been written even had it reviewed.

Fixed all three - fresh deadline, `git init` on the export, `--sandbox workspace-write` - and the review ran:
**55,868 tokens, `verdict=findings`, 4 examined paths**, all four of the supplied files.

**This is three attempts, and it is not "retry until it works": each failed for a different, identified,
fixed cause.** The first two produced no review and were reported as such.

### FINDING F001 - severity major - classified FIX

> *Multiple intake candidates bypass the ambiguity guard when the context is active.*

**Reproduced against a live control before it was accepted** (CASE 9), then repaired. Full text and the
repair are in commit `b3387794`. In short: collapsing to null whenever more than one candidate was offered
left `candidateActive` false, so the guard **could not fire**, and an active start context was returned as
valid - **a second open workshop made the resolve less cautious than one**, and the caller persists that
feature with the last assistant question.

**Codex located it precisely** - the branch, the guard line, the two cases that miss it and why, and the
concrete fixture pair that exposes it. It is the second real defect an independent review has found in this
fix, after property 1 (B4F-010).

### THE MUTATION PROOF SURVIVED, AND THAT WAS THE MOST USEFUL RESULT

Removing the new multi-candidate refusal **did not turn the suite red**. Once every candidate is validated,
CASE 9 is already caught by the *existing* candidate-vs-context guard - so the case written for the new
refusal **never discriminated it**.

**CASE 10 exists because of that**: two active candidates with an **inactive** context, where without the
refusal the resolve takes the first active candidate and silently picks between two open workshops. Both
mutations now kill it.

**A guard with no case that fails when it is removed is a guard nobody is testing** (DRIFT-199-I003-060) -
and here the proof caught it in the same session it was written, rather than 22 days later.

### AND CASE 5 WAS RE-POINTED - flagged, not done quietly

Case 5 asserted *"two open workshops are ambiguous"*, but its second candidate `'102-another-open'` **has no
directory, no controller and no workshop**. It never tested two open workshops; it tested two candidate
**strings**. **The label overclaimed what the fixture measured** - B4F-018's shape, in a control I wrote.

It now asserts what it actually covers: **a phantom name must not block a live workshop**. Genuine
two-active ambiguity is CASE 9. **Coverage increases and no assertion was weakened to accommodate the fix** -
but an existing green assertion changed, so it is named here for the maintainer to overrule.

**Classification summary**: 1 finding, **1 fix**, 0 record, 0 dispute.

---

## B4F-038 - `/specrew-user-profile` IS ADVERTISED BY THREE SURFACES AND SHIPPED BY NONE - and this session reproduced the defect on every turn

**Walk finding, first minute. Verified here before recording.**

### Measured

| fact | value |
| --- | --- |
| tracked in this repo | **yes** - `.claude/skills/specrew-user-profile/` |
| occurrences in `Specrew.psd1` FileList | **0** |
| present in the deployable skill set (`squad-templates/skills/`, 16 entries) | **no** |
| any `user-profile` item under `extensions/` | **one**, and it is `directives/user-profile-awareness.md` - a directive, not the skill |
| deployed in three consumer-shaped projects (maintainer's count) | **0 of 37 skills** |

**Advertised by three surfaces**, all verified: `scripts/specrew-init.ps1` (the completion message),
`specrew-bootstrap-provider.ps1` (the session banner) and
`squad-templates/coordinator/specrew-governance.md` (the launch contract).

**So it is dogfood-only.** It works here, which is exactly why nobody noticed - **the tree Specrew is
developed in is not shaped like the trees it creates** (DRIFT-199-I003-068), and this is that finding on the
product's first-minute surface.

### THE ALTERNATIVE, and it needs no command

The profile is **user-level**, at `~/.specrew/user-profile.yml`. **The four dials are real and correctly
named** - verified on disk:

```yaml
expertise:
  software_architecture: 10
  ui_ux: 6
  product_management: 7
  ai_research_project_management: 6
```

Each is `1`-`10` or `null`, persists across every project for that user, and editing the file is sufficient.
**Nothing about the settings is broken; only the advertised route to them.**

### AND THIS SESSION REPRODUCED IT ON EVERY TURN

**The orientation banner rendered in this session has told the maintainer to run `/specrew-user-profile
edit` on every single turn.** In this repository that command exists. **In a consumer project it does not.**

The banner takes that instruction from the same source that misleads users, so **the agent reproduces the
defect verbatim, with the product's own authority behind it** - and a user who follows it gets nothing, from
the one surface designed to invite correction. That is what makes this a first-run item rather than a
documentation nit: it is in the paragraph whose entire purpose is to let a human correct what the system
believes about them.

**The dials the banner reported were accurate** - `10 / 6 / 7 / 6` maps to expert / mid / mid / mid. **The
content was right and the remedy was unavailable**, which is the harder failure to notice.

### Disposition

- **Beta4**: known issue in the release notes, in plain words, with the file path and the four dials so the
  reader can act without the command.
- **Beta5**: **ship the skill.** And `preferences.preferred_intake_depth` is written by the helper
  (`user-profile.ps1:258/292/532`) and defaulted in `Read-IntakeYaml.ps1:266`, but **nothing reads it to
  change behaviour** - a setting the product offers, stores, and ignores. Same family as
  DRIFT-199-I003-060's dead exemption: written, honoured by nothing.

---

## B4F-039 - TWO CONSUMER-PROJECT OBSERVATIONS, live on `d4a89ab7`. Neither blocks.

Both from the router-skill session, on the tag-candidate build.

### (1) A full six-section packet after every clarify answer - the three-gates finding, in the field

The crew rendered the complete re-entry packet after **each** clarify answer, with
**`Why I Stopped: mid-clarify, not a boundary`**.

**The packet names its own redundancy in its second heading.** That is DRIFT-199-I003-071/-072's exact
shape - there the packet's *What Needs Your Review* read *"Nothing new to review"*, and the ruling was that
**interrupting a conversation to report internal state the human cannot act on is a design error, not a
rough edge.** Here the packet does not merely lack a reason; **it states that it has none.**

**And the standing rule already says so.** The always-true refocus core carries it verbatim:
*"Clarify-stage ambiguity questions are NOT packet stops."* So this is not an unspecified case - **the rule
exists, is deployed, is loaded into the agent's context every session, and did not hold.** That is the
instruction-layer family again (DRIFT-199-I003-041/-047): *a rule that depends on recollection will not be
applied*, now measured on the clarify surface rather than in a control.

**Cost, in the units that matter here**: one clarify pass is several questions, so a human answering three
clarify questions receives three full six-section packets, each announcing it is not a boundary. **The
first-run cost of that is the same one beta4's theme exists for.**

### (2) "Two live sessions", owner unknown - presence counted as liveness

The specify sync reported **two live sessions** and recorded the crossing owner as **unknown**.

**Verified on disk** in the router-skill project's `.specrew/runtime/conformance-sessions/`:

| session directory | `captured_at` | recorded `head` |
| --- | --- | --- |
| `8c283057...` | 2026-09-09 19:51 | current |
| `33b42de4...` | 2026-09-09 15:13 | `e1181f0b` - the controller-repair commit |
| `41644c60...` | **2026-09-08 19:37Z** | `01519e32` - **long superseded** |

**`turn-baseline.json` carries `schema_version`, `capture_event`, `captured_at`, `head`, `key`,
`dirty_user_file_count`, `entries` - and NO liveness field.** No `alive`, no `last_seen`, no `pid`, no
`heartbeat`, no `expires_at`. **The count of directories on disk IS the count of live sessions**, so a
session record from roughly twenty-one hours earlier, pinned to a commit that no longer exists in the
working head, is counted as live.

**That is presence read as liveness** - the same shape as a template's presence mistaken for its content
(DRIFT-199-I003-086/-089): an artifact's existence taken as evidence of a state it does not assert.

**AND IT IS FR-032's FIRST FIELD FIRING.** DRIFT-199-I003-050 recorded that FR-032 - the crossing-owner /
concurrent-session path - shipped with **no passing automated test and no field proof**, because a
single-session walk structurally cannot stage two concurrent sessions. **This is that field evidence
arriving, and it is a false positive**: the "second session" is a stale directory, not a concurrent human.
The owner-unknown disclosure then behaved exactly as designed - it failed open and said so, which is the
half that worked.

**Beta5 shape**: a session record needs a liveness signal - a heartbeat, an expiry, or a process check - and
the counter must consult it. Until then, "two live sessions" means "two session directories exist", and the
two are not the same claim.

---

# BETA5 ITEM 1 - ABOVE EVERYTHING ELSE DEFERRED

**DO NOT START UNTIL BETA4 IS TAGGED.** Recorded now because it is the maintainer's top UX complaint and
because the measurement is cheap today and expensive to reconstruct later.

## B5-001 - THE STOP-INTENT CLASSIFIER WAS BUILT ON THE HOOK SIDE AND NEVER DELIVERED TO THE AGENT

**FR-045a's classifier is wired, tested, and reads two markers. Nothing ever teaches the agent to emit
either one.**

### Measured

`SPECREW-STOP-INTENT` appears in **exactly four files** in the whole repository:

| file | role |
| --- | --- |
| `scripts/internal/continuous-co-review/stop-intent-contract.ps1` | **the classifier** - defines both markers at lines 37-38 |
| `tests/continuous-co-review/unit/stop-intent-contract.Tests.ps1` | unit test |
| `tests/integration/conformance-stop-intent-wiring.tests.ps1` | wiring test |
| `specs/198-beta2-hardening/spec.md` | the spec that defined it |

| instruction surface | files teaching the markers |
| --- | --- |
| `refocus/` | **0** |
| `squad-templates/directives/` | **0** |
| `knowledge/` | **0** |
| skills | **0** |
| commands | **0** |

**Built, tested, specified - and never taught to the only party that can produce the input.**

### The consequence is deterministic, not probabilistic

`stop-intent-contract.ps1:112` is the fail-safe:

```
return 'real' ... 'no current-turn continue marker with authorization, no async in flight,
                   and no other trigger; normal real-stop enforcement applies'
```

**Absent a marker, EVERY stop classifies as `real` and owes a packet.** Rule 9's *"after material work"*
clause then makes the agent render one. **So every material turn, in every session, forever, takes the
fail-safe path** - and the stop-that-is-not-a-stop, which exists in code, has never once been reachable.

**FIELD EVIDENCE WAS ALREADY IN HAND.** This session's own conformance journal, read at its first Stop,
carries that exact reason string verbatim. The classifier has been announcing the cause of the complaint in
its own diagnostic output the entire time.

### The class

**Same family as the inert controls this arc has recorded, and the purest instance yet.**
DRIFT-199-I003-060's exemption *could never* fire - its condition was unreachable. **This one CAN fire;
nothing ever asks it to.** A contract with a reader, a test, and no writer - which is why every test passes
and the behaviour never appears.

---

## The beta5-preview scope, sized

### (1) Instruction layer

- **Rule 9 rewritten** from *"after material work"* to **"boundary gate or decision owed"**.
- **In-flight ends are one line plus the intermediate marker.**
- **In-phase continuation carries the continue marker.**
- **Orientation once per session, never inside a packet.**
- **One test asserting the directive teaches the markers** - so the writer can never go missing again while
  the reader stays green.

### (2) Hook advisories, gated on the three conditions

- **Actual work by THIS session** - which requires fixing the **cross-session material-owner
  misattribution**.
- **Elapsed time since the last advisory.**
- **Content unchanged means silence.**

### (3) The review-required advisory

Gated on **this-session material**.

### Acceptance - counted, on the beta4-mdlink walk

- **packets per turn**
- **banners per session**
- **advisories on a read-only session**

Counted rather than judged, on a real walk rather than in this tree.

---

## B4F-040 - DRIFT-199-I003-012 REACHED A CONSUMER, and the fixture masked it twice

**The clarify boundary requires an iteration that a LATER boundary creates.** Recorded during the beta3
respin as DRIFT-199-I003-012, where the fix was *"one list entry, written, not applied - HELD FOR A
RULING"*. **The ruling never came, beta3 shipped, and the router-skill project hit it at clarify on
`d4a89ab7`.** That is the cost of a held fix, measured rather than argued.

### Verified here

`scripts/internal/sync-boundary-state.ps1:404`:

```powershell
if ([string]::IsNullOrWhiteSpace($effectiveIteration) -and
    $BoundaryType -notin @('before-specify', 'specify', 'feature-closeout')) {
```

**`clarify` is absent from the exemption list**, and clarify runs before any iteration exists.

**Shipped since `aa25909b` (2026-08-12)** - confirmed by `git log -S` on the list itself. **That postdates
the `v0.40.0-beta2` tag of 2026-08-08, so beta3 is affected and beta2 is not.**

### FOUR NEW FACTS BEYOND -012

**1. The governed command omits the parameter the script requires.** The sanctioned `sync-clarify` path
does not pass `-IterationNumber`, so **following the governed route cannot satisfy the gate** - the only way
through is the parameter the command does not offer.

**2. THE FIXTURE MASKED IT TWICE.** Measured: **27 sync-related test invocations pass
`-IterationNumber '001'`**, *and* the fixtures **seed `iterations/001`**. Both the parameter and the
directory. **So the pre-plan state - no iteration on disk, no parameter supplied - was never exercised by
anything**, and the suite is green on a state the product cannot actually reach.

**B4F-018 in a fixture**: the tests measured a narrower world than the claim "clarify works" covers, and the
narrowing was in the setup, which is the part nobody prints.

**3. THE REFUSAL'S `{0}` IS UNFORMATTED**, and it is a bug this project has already fixed once:

```powershell
throw ("… it belongs to. " +
    "No iteration was given and none was found under {0}. " +
    "Create the iteration first … -IterationNumber with the one you mean." -f (Join-Path $featurePath 'iterations'))
```

**`-f` binds to the LAST string literal of the `+` chain, not to the concatenated whole.** The `{0}` sits in
the *middle* fragment, so it renders verbatim and the path never appears - while `-f` substitutes into a
fragment that has no placeholder.

**DRIFT-199-I003-063 found this exact bug** in the scaffold's four messages and added a guard asserting no
placeholder survives in any line. **That guard is scoped to `scaffold-reports-what-it-did`, so it does not
reach this file.** The instance was fixed; the class was not - **a guard scoped narrower than the defect it
was written for**, which is B4F-018 once more, one level above the fixture.

**4. The refusal contradicts itself, as -012 recorded**: it tells the reader to *"create the iteration first
(the plan boundary scaffolds `iterations/001/`)"* - and **plan comes after clarify**. A boundary demanding
an artifact only a later boundary produces.

### Disposition

- **Beta4**: known issue in the release notes with the workaround (`-IterationNumber 001`) and a note that
  the literal `{0}` is cosmetic.
- **Beta5, or with (C) if the tag reopens**: exempt `clarify` at `:404` **or** put the parameter in the
  command; **add a no-iteration fixture case** so the pre-plan state is exercised at all; **fix the format
  string** - and consider whether the -063 guard should cover every refusal rather than one scaffold.

---

## B4F-041 - THIRD INSTANCE OF THE POST-AGENDA REPAIR TRAP, and the writer-side guard is NOT a table change

**Reads above B4F-036's beta5 item (b) - this is the concrete case that item is about.**

### The instance

Fresh walk, `beta4-mdlink` on `d4a89ab7`, feature 1 at agenda confirmation. The crew watched the
`product-domain` `moved_on` entry **vanish from the workshop map when the agenda was confirmed**, read it as
silent data loss, found `repair-workshop-controller-state.ps1` refuses post-agenda state, and **proposed
re-running `confirm-workshop-lens.ps1` for `product-domain`** - the exact unsanctioned repair that left the
router-skill controller `workshop-record-not-selected` (B4F-035).

**Measured before answering**: `status=active`, `valid=True`, `agenda=confirmed`,
`next=architecture-core`, `selected=[architecture-core, code-implementation]`, `workshop keys=[]`,
`product-domain.md`/`.yml` intact. **The clearing is the product's normal post-agenda state**
(DRIFT-199-I003-092).

**Third instance.** Casio left it alone and closed five lenses; router-skill re-ran the writer and corrupted
its controller; this crew proposed the same and was talked out of it. **The outcome depended on the agent's
discipline, and discipline is not a control.**

### THE GUARD CANNOT LIVE IN THE TRANSITION TABLE, and the table says why in its own words

```powershell
'confirm-intake-lens' { $stateClass -in @('pending-empty', 'pending-product-projection', 'confirmed-complete') }
```

The comment above that cell is explicit:

> **`confirmed-complete` IS IN THIS SET BECAUSE OF A STRANDED PROJECT, not for symmetry.** … The
> pending-only fix unblocked NEW workshops and left every already-advanced project exactly as stuck -
> shipping it would have stranded the projects it was written to save.

**So closing that cell re-strands exactly what DRIFT-199-I003-020 field-proved a recovery for.** A blanket
post-agenda refusal is the wrong fix and would undo hard-won ground.

**And here is why the trap exists at all**: the two states are **identical at the table's resolution**.

| | stranded (recovery needed) | healthy (clearing is normal) |
| --- | --- | --- |
| `agenda_status` | confirmed | confirmed |
| `workshop` map | **empty** | **empty** |
| state class | `confirmed-complete` | `confirmed-complete` |

**The table cannot tell them apart, so the guard cannot be a table row.**

### The discriminator that does exist

**A `product-domain` receipt in the authority store.** In the stranded case the intake lens was *never
closed* - no receipt was ever minted. In the healthy case it *was* closed, a receipt exists, and the entry
was then cleared by agenda confirmation as designed.

### Estimate

**Location**: `extensions/specrew-speckit/scripts/confirm-workshop-lens.ps1`, after the transition check
passes, gated on `$isIntakeLens` and a confirmed agenda. **No transition-table change.**

**Shape**: look up a `product-domain` receipt; if one exists, refuse through the existing
`New-SpecrewLensCheckpointRefusal` with a summary saying **the topic is already recorded and the empty
workshop list is the normal state after the agenda is confirmed**, and an action naming the legal next move
(close the next technical lens). If no receipt exists, allow - that is the stranded case.

**Diff**: roughly **15-25 lines** in one file plus the byte-identical `.specify/` mirror. The refusal helper,
the receipt reader and the intake-lens predicate all already exist and are already imported.

**Tests**:

1. **healthy post-agenda** - receipt present, `workshop` empty → **refuses**, and the message states the
   clearing is normal.
2. **stranded post-agenda** - no receipt, `workshop` empty → **still allowed**, so DRIFT-199-I003-020's
   recovery is preserved. *This is the case that must not regress.*
3. **pre-agenda** (`pending-empty`) → unchanged.
4. **mutation**: remove the receipt check → case 1 goes red **and only case 1**.

**The maintainer decides whether it rides with (C).** Recorded with the estimate rather than implemented.

---

# BETA4 REOPENS

**`d4a89ab7` stays as the candidate that FAILED the fresh walk. Nothing is tagged.**

## Why, in one sentence that is not about a bug count

**On the main workshop path, the product invited a corrupting repair - and the outcome depended on the
agent's discipline, which is not a control.**

Three encounters, three different outcomes, same state: Casio left the clearing alone and closed five
lenses; the router-skill crew re-ran the lens writer and corrupted its controller into
`workshop-record-not-selected`; the `beta4-mdlink` crew proposed the same repair and was talked out of it
(B4F-041). **The variable each time was the judgement of whoever was sitting there.**

A release whose correctness depends on an agent noticing that a normal state is normal has not shipped a
control. It has shipped a hazard with a good track record.

## PRED-BETA4-009 - stated now, before the fix set, for the re-walk

**A fresh project completes feature 1 through `approved for specify` and reaches feature 2's first question
with:**

| counted | required |
| --- | --- |
| repair proposals | **0** |
| packets at non-boundaries | **0** |
| orientations per session | **1** |
| advisories on a read-only session | **0** |
| feature 2's first typed reply registers | **yes** |

**Counted on a RECREATED `C:\Dev\walks\beta4-mdlink`, not judged.** Each number is a count a human can take
while walking, in the units the work is actually for - the same instrument that produced *nine stops by the
specify boundary* and later *zero governance stops not about the work*.

**Feature 2's first question is the load-bearing one**: a first feature has no predecessor to name, so only
the second exercises the defect beta4 exists to fix.

## The fixture is preserved, because the state is not reproducible on demand

`tests/fixtures/beta4-agenda-clearing/001-mdlink-checker/`, copied from the failed walk **before the project
is recreated**:

```
agenda_status       = confirmed
agenda_confirmation = human-confirmed
selected            = [architecture-core, code-implementation]
workshop keys       = []            <- the clearing the crew read as data loss
agenda keys         = [architecture-core, code-implementation]
workshop/product-domain.md, .yml    <- intact, which is the whole point
```

**This is the exact post-confirmation state the trap fires on**, produced by the product itself on a real
walk rather than posed by a fixture - the strongest evidence tier this project has
(DRIFT-199-I003-020's principle: the precondition was written by the defect, in the field, before anyone
knew it would be needed).

---

## B4F-042 - THE SANCTIONED RECOVERY AND THE CORRUPTING REPAIR ARE THE SAME OPERATION

**Found while executing fix 1, by an existing green test going red.** This is the largest finding of the
reopen and it reverses a conclusion this project has been carrying since 2026-09-01.

**SCOPE OF THE CLAIM, corrected 2026-09-09 after the maintainer refused the first wording.** The finding was
first written as if the specimen's history had been measured. It had not: what was measured was a
*reconstruction* under beta3's writer and reader. The mechanism below is proven that way and stands on its
own. The specimen evidence came afterwards, is reported separately in **THE SPECIMEN, RECONCILED**, and is
kept apart from the mechanism on purpose - the first version blurred them, and that is the error being
corrected.

### The mechanism, proven by reconstruction

**How the write happens, at both revisions that matter**: `confirm-workshop-lens.ps1` sets
`$workshopMap[$Lens] = $entry` **unconditionally** - `be573254` (2026-08-30, the writer ConsoleFractal ran)
line 274, HEAD line 341. There is no intake branch. The same loop copies the existing map whole
(`foreach ($property in @($workshop.PSObject.Properties))`), which is why a later technical close preserves
whatever is already there rather than dropping it.

**How the reader treats it**: `workshop-record-not-selected` was introduced in `ff86a1e6` (2026-07-22) and
has rejected a `workshop` key outside `selected` ever since - verified with `git log -S` over the accessor,
which returns that commit and no earlier one.

**So: closing `product-domain` from a confirmed agenda writes a key the reader has rejected for seven
weeks.** That is the whole mechanism, and it needs no specimen.

### What happened

The fix-1 guard made `tests/integration/workshop-lens-checkpoint.tests.ps1` **Case 7c** fail. Case 7c is
DRIFT-199-I003-020's ground: *"a project that confirmed its agenda without ever closing the intake lens can
still recover."* It was written from a real deadlocked project, and the recovery it pins was **field-proved
on the original stranded specimen** on four separate checks.

Rather than adjust it, I reconstructed what the recovery **leaves behind** and read it:

```
post-recovery workshop keys    = [product-domain]
product-domain records on disk = 2

pre-fix reader (beta3 as shipped)  -> invalid | False | workshop-record-not-selected
post-fix reader (tolerance)        -> active  | True  | workshop-active
```

**The sanctioned recovery produces `workshop-record-not-selected`.** That is the same reason the router-skill
project was found under after a crew "restored" the cleared entry (B4F-035). **The recovery that was
field-proved and the repair that bricked a controller are the same operation.** Only their reputations
differed.

### THE SPECIMEN, RECONCILED - and it was the other copy

**The maintainer's correction was right about what had been shown, and their reading of the archive was of
the copy the 2026-09-01 proof did not run on.** DRIFT-199-I003-020 is explicit on this point, because the
distinction is the whole reason it was held for:

> **`C:\Temp\ConsoleFractal`** - the ORIGINAL stranded specimen, **not** the `-stranded-backup` copy that
> carried the earlier `confirm-lens` evidence.

Both copies survive at `C:\Dev\SpecrewSpecArchive\_temp-trials\`. Read (the archive was **not** written to -
each was copied to a temp root and the `4f4dce52` lens catalog restored there, because the archive was
stripped of `.specify/` and the accessor otherwise stops at `workshop-lens-catalog-missing` before reaching
the check at issue; that catalog's lens-id set is identical to HEAD's):

| | `ConsoleFractal` (the 09-01 copy) | `ConsoleFractal-stranded-backup` |
| --- | --- | --- |
| `workshop` keys | **`[product-domain]`** | the six technical lenses |
| keys not in `selected` | **`[product-domain]`** | none |
| beta3's reader | **`invalid` / `workshop-record-not-selected`** | `complete` / valid |
| reader with the fix | `active` / valid | `complete` / valid |

**The backup is exactly as the maintainer described it** - six technical lenses, no `product-domain` key -
and that is what the technical-close path produces. It is the touched copy. **The original carries the
state.**

**WHAT IS STILL NOT PROVEN, and the wording keeps it that way**: the *date* of that controller write. Both
archived controllers carry an mtime of 2026-09-08 23:38, which is when the archive was made, so no timestamp
attributes the key to 09-01. What attributes it is that the only writer of a `product-domain` workshop key
is `confirm-workshop-lens.ps1 -Lens product-domain`, and DRIFT-199-I003-020 records that operation running
on this copy. **The specimen carries the output; the record says the operation ran there. That is the claim,
and it is not a measured history.**

### Why four field checks missed it

DRIFT-199-I003-020 checked four things: the receipt was consumed, the agenda was untouched, the record
validated at the checkpoint, and it ran on the original specimen. Each is a real check. **None of them
asked the reader.** The entry was written, the artifacts were well-formed - and the accessor that every Stop
classification consults called the result invalid. *A write that validates at the writer is not a write the
reader accepts*, and this batch now has two instances of that gap.

### An unrelated thing the specimen shows, recorded because it was in front of me

The 09-01 copy's receipt store holds **four `architecture-core` lens receipts** (2026-08-31, 21:06 to
21:20) and its map holds **no `architecture-core` key**. Four typed human turns were minted and none of them
closed anything. The cause is on disk and needs no theory: `specs/001-console-fractal/workshop/` in that
copy contains only `product-domain.md` and `.yml`, so every attempt was refused for a missing lens record.
**Four receipts spent against a refusal the human had no way to see.** Related to DRIFT-199-I003-021's
compaction re-ask observation but not the same thing - that one was a re-ask, this is four turns bound to a
refusal. Carried to beta5 with the receipt-vs-assent items; not acted on here.

### And the two states are not distinguishable

Case 7c's own comment says the stranded state is reachable *because* `confirm-workshop-agenda.ps1` requires
the product-domain **records on disk** rather than the controller entry. So the stranded project **has the
records** - and a receipt. A healthy post-agenda project has both as well, because confirming an agenda
clears the map by design.

| | stranded | healthy |
| --- | --- | --- |
| `agenda_status` | confirmed | confirmed |
| `workshop` map | empty | empty |
| `product-domain.md` / `.yml` | **present** | **present** |
| `product-domain` receipt | **present** | **present** |

**Both discriminators I proposed are present in both states**: the receipt (my B4F-041 estimate) and the
records (PRED-BETA4-010's premise). There is no on-disk discriminator, and there does not need to be - what
un-deadlocks a stranded project is the **reader tolerating the intake key**, not the write.

### A GREEN ASSERTION WAS CHANGED, and it is the most sensitive one in the batch

**Case 7c now asserts the opposite of what it asserted**: the reopen is refused, the entry is not written,
the controller is byte-unchanged. The case, its fixture and its comment are kept - the comment now records
what the recovery actually produced and why the case was reversed, so nobody restores it from the old
reasoning. **Flagged here rather than left in a diff.**

### The retire-or-no-op decision, made on evidence

The maintainer asked: `confirm-intake-lens`'s `confirmed-complete` cell has no caller left - retire it or
make it a no-op with a message.

**Decision: the cell stays; `confirm-workshop-lens.ps1` refuses downstream of it.** Removing it moves the
refusal into the transition table, whose intake text says *"Ask for the workshop plan to be repaired"* - and
`repair-workshop-controller-state.ps1:105` refuses every agenda that is not `pending-confirmation`, so that
remedy clears nothing. That is the remedy-wrong-for-state family (B4F-030) shipped deliberately. **A
permission nothing can use, behind a refusal that tells the truth, beats a refusal that sends the reader
somewhere that cannot help.** The table comment now says this, so the cell is not deleted later as dead.

### A mutation caught a green assertion of mine that proved nothing

M1 (guard removed) left Case 5's two loudest assertions - *"refuses rather than writing"* and *"THE
CONTROLLER IS BYTE-UNCHANGED"* - **green**. Without a `product-domain` receipt the writer refuses one check
later anyway, so those assertions never depended on the guard. The fixture now takes `-WithIntakeReceipt`
for that case, and under M1 both go red. **The field project had that receipt**; the fixture that omitted it
was testing a state the defect does not occur in.

### Carried to beta5

- **The skill is a second controller writer with no guarantees.** `design-workshop.md` (379, 394) instructs
  the agent to hand-write `agenda_status: confirmed`. Every invariant `confirm-workshop-agenda.ps1` enforces
  is optional on that path. The residual branch of the new guard exists only because of it.
- **`confirm-workshop-lens.ps1` writes a controller shape the accessor can reject.** The writer validates its
  own artifacts and never asks the reader whether the result is readable. One assertion at the end of the
  write - read the controller back through `Get-SpecrewWorkshopLifecycleState` - would have caught both this
  and B4F-035 at the moment of the write.

---

## B4F-043 - A RECOGNIZED VERDICT WITH NOTHING PENDING IS DROPPED IN SILENCE, and the standard for this already exists

**Router-skill session at design-analysis, `d4a89ab7`.** A human types a phrase the capture recognizes, no
crossing is pending, and nothing is said. The human has no way to tell an accepted approval from a
discarded one.

**The standard is already written, in the same tree, for a different phrase family.**
`HumanAuthorityStore.ps1` handles the partial-review-signoff override exactly as this finding asks:

> `YOUR APPROVAL WAS NOT RECORDED. The phrase matched, but no partial-coverage approval is currently
> outstanding for this project, so there was nothing for it to authorize. Nothing is wrong with your
> decision.`

and its comment states the rule in general terms: *"A phrase that did NOT match stays silent: that is
ordinary conversation. A phrase that DID match and was then rejected is a human trying to authorize
something, and their attempt must never vanish."*

**So this is not a new standard to invent - it is an existing one that reached one phrase family and not
the boundary family.** The capture must answer audibly, naming the crossing that IS pending or saying
plainly that none is.

---

## B4F-044 - THE ITERATION SCAFFOLD CONSULTS NO AUTHORIZATION, and DRIFT-199-I003-086 is what that costs

**Measured at source**: `extensions/specrew-speckit/scripts/scaffold-iteration-plan.ps1` contains **zero**
references to authorization state - no `last_authorized_boundary`, no `Get-SpecrewPendingVerdictState`, no
`boundary_enforcement`. It scaffolds and it sets boundary state, and nothing asks whether the crossing it
implies was ever approved.

**DRIFT-199-I003-086 is the recorded instance**: iteration 003's own scaffold set `boundary_type: plan`
at 15:40:40 with no plan authored and no crossing authorized - in this project, by this project's own
tooling.

**In the router-skill session the scaffold advanced no state.** That is the finding's honest shape: the
outcome was fine and **nothing checked**. A control that happens not to fire is not a control.

---

## B4F-045 - THE DESIGN DECISION HAS NO CAPTURE AT ALL - fix 2 item (f)

**The gap, stated as three facts that are each checkable:**

1. **`approved for plan with Option N` is defined nowhere.** It is not in the launch contract, not in the
   skills, not in the capture.
2. **The boundary grammar cannot carry it.** The approval anchor
   (`ConversationCaptureAccessor.ps1:229`) admits an option only as a LEADING prefix and **caps it at
   `[12]`** - so a three-option design decision cannot be expressed at all, and the trailing
   `with option N` form falls inside the boundary remainder rather than being read as a choice.
3. **So the crew recorded the choice as prose in `design-analysis.md`** - the one place nothing validates.

**And the skill forbids the shortcut that would have avoided it.** `design-workshop.md:337` -
*"Co-design - do NOT hand down finished options"* - requires the options to be co-built with the human.
The methodology demands a real choice at design-analysis and the machinery offers nowhere to put it, so
the choice lands in prose and the gate cannot see it.

**Building as fix 2 item (f)**: `record-design-decision.ps1` writing a declared artifact the gate
validates, under **its own phrase family** so it can never be confused with a boundary verdict. Distinct
by construction rather than by convention: a decision phrase that does not begin with the approval verb
cannot match the boundary anchor, and the test asserts that in both directions.

---

## B4F-046 - THE HANDOFF-EVIDENCE CHECK AND THE SYNC ORDER DISAGREE (beta5, seal-ordering family)

The validator expects the handoff packet **before** the boundary commit; the sync writes it **after**
(`sync-boundary-state.ps1:1756` validates the handoff text, `:2072` records the evidence). Same family as
the seal-ordering items: a check and a writer that each behave correctly and disagree about when.

**Deferred to beta5 at the maintainer's direction.** Recorded here so the family has all its members in
one place.

---

## B4F-048 - THE INDEPENDENT REVIEW DID NOT COMPLETE, and what it found before it died

**Numbering note**: commit `181d4b57` cites this entry as B4F-047. It was renumbered when the maintainer assigned B4F-047 to the vacuous-control finding below, which is the more significant of the two. The commit message is left as written rather than rewritten; this line is the cross-reference.

**Model that actually ran: `gpt-6-astra`** (provider openai), codex-cli 0.153.4 in both shells - the 400 that
blocked the earlier attempt is gone. Range `b62ba968..b99b448b`, 46 commits, 47 files exported in full.

**IT DID NOT FINISH.** `candidate-result.json` was **never written**; the run ended on
`You've hit your usage limit ... try again at 3:57 AM` after 98,355 tokens. **Reported as not written, not
as a clean review.** Areas (b) fail-open on new provider paths, (d) the three retirements, and (e) the eight
converted cases were **not reached**.

**But it ran real probes before it stopped** - it wrote and executed its own `review-probes.ps1` against the
committed code rather than reading it. Those outputs are facts and are harvested here from the log.

### PROBE 1 - two sessions in one project: A's declaration lands in B's directory. CONFIRMED.

```json
{"probe":"A declares after B overwrites project marker","A_record_exists":false,"B_record_exists":true}
```

Session A declares; the record appears under **B's** path. Cause: `declare-turn-end.ps1` takes its identity
from `.specrew/runtime/session-marker.json`, which is **project-wide** and stamped by whichever session
started last - while the hook uses the `--session-id` its host passed it. **A is refused for a declaration it
made, and B is credited with one it did not.**

### PROBE 2 - the in-flight bound can be laundered by one intervening kind. CONFIRMED.

```
turn-1 in-flight      run=1     turn-2 conversational run=0
turn-3 in-flight      run=1     turn-4 conversational run=0
turn-5 in-flight      run=1     ...  turn-9 in-flight run=1
```

**The run resets to 1 every time and the bound never trips.** An agent that says "still waiting" and
"nothing to report" alternately can wait forever on the same item. This is exactly the laundering the
maintainer asked about, and the answer is yes.

### PROBE 3 - a failed counter increment leaves a stale declaration accepted. CONFIRMED.

```json
{"probe":"counter write failure","result":-1,"turn":"turn-1","old_record_accepted":true}
```

When `Step-SpecrewTurnCounter` cannot write, it returns `-1`, the turn id does not advance, and the previous
turn's declaration satisfies every later stop. It is silent: the provider swallows the failure.

### PROBE 4 - the clean path holds.

```json
{"probe":"resume after declaration but before Stop","turn":"turn-1","existing_kind":"boundary"}
{"probe":"exhaustion on a clean wait","declared_run":4,"exhausted":true,"next_turn":"turn-4"}
```

A crash between the declaration and the Stop increment leaves the declaration intact and still matching; the
bound trips at 4 on an unbroken run and the refusal names the repeated item. **These two are the design
working as intended, and are recorded because a register that lists only failures misdescribes the same
work.**

### CLASSIFICATION

| # | finding | class | why |
| --- | --- | --- | --- |
| 1 | in-flight laundering | **FIX** | it defeats the bound completely; the bound is the only control on the one kind no artifact can verify |
| 2 | cross-session declaration | **FIX** | the handshake is what PRED-BETA4-011 part 1 named as the abort condition; it holds for one session and breaks for two |
| 3 | silent counter-write failure | **FIX** | a permanent, undiagnosable bypass, and the provider's own convention for this is fail-open **with a WARN** |

**The review must be re-run after 03:57 for (b), (d) and (e)**, which are the areas it never reached - and
(d), the deletions, is the class it was most needed for.

---

## B4F-047 - THE REVIEW GATE IS VACUOUS EVERYWHERE IT COULD HAVE HELPED, and unsatisfiable where it fires

**The maintainer's finding, recorded at their direction as the sharpest vacuous-control instance in this
arc.** Three parts, each verified at source.

### (1) The gate is a no-op at every boundary but one, and the file says so itself

`scripts/internal/continuous-co-review/signoff-gate-wiring.ps1`, line 17, in its own header:

> `Invoke-ContinuousCoReviewSignoffGateIfEnabled` … **is a no-op for every boundary except
> `review-signoff`.**

So specify, clarify, plan, tasks, before-implement and implement all pass with **nothing asking whether any
of it was reviewed**. Unbounded production work lands in a governed project and the review evidence gate
never speaks until a boundary most features reach last, if at all.

**This is not a bug in the wiring - it is the wiring working as designed, and the design is the finding.** A
control placed where it cannot act is indistinguishable, from inside, from a control that is satisfied.

### (2) And feature 201 cannot reach that boundary anyway - the loop closes

- The gate routes to **`review-required` / `no-authoritative-campaign-result`**
  (`review-signoff-evidence-gate.ps1:864`), whose message tells the agent to get a round approved and run
  the campaign.
- The campaign cannot be created: `review-campaign-orchestrator.ps1:1342` throws
  **`review-campaign-active-iteration-unresolved`** unless an iteration identity resolves.
- **Feature 201 has no `iterations/` directory at all**, by the maintainer's own ruling that a defect sweep
  does not run planning ceremony (B4F-030).

**So the gate is silent now and unsatisfiable later.** Every boundary before review-signoff asks nothing;
review-signoff asks for something the feature's own work kind guarantees it cannot produce. Neither half
fails loudly.

### (3) The Stop-side advisory blocked a read-only reviewer session repeatedly today

While the **working** session's cap store records only `material` and `boundary-evidence-absent` subjects -
so the advisory that interrupted the reviewer was attributed to neither.

**The honest limit on this evidence, stated rather than glossed**: absence is proven only over that one cap
store. That is enough to establish the DIRECTION - a read-only session was interrupted by an advisory the
working session's own record does not account for - and it is cross-session attribution, which is exactly
what fix 2 item (c) makes impossible by scoping attribution to the declaring session.

### DISPOSITION

- **(3) is beta4**, through fix 2 item (c) as already scoped: attribution becomes the declaring session, and
  a read-only second session in the same project receives no advisory. Its test is in the fix-2 tail.
- **(1) and (2) are beta5**, filed with **per-feature work-kind**, which they are entangled with rather than
  merely adjacent to: **review is a required stage of the `bug-bash` contract, and the engine has no path to
  it for a feature without iterations.** Fixing the gate's placement without fixing work-kind scope would
  move a vacuous control to a boundary that still cannot satisfy it.
- **The release notes disclose** that beta4's own repair was reviewed by codex **out of engine**, not by a
  governed campaign, and why - because the engine has no path to review this feature, which is finding (2)
  applied to this very release.

---

## B4F-049 - B4F-018's ATTRIBUTION COROLLARY: three defects, one root - inferring WHO from shared project state

**Recorded at the maintainer's direction.** B4F-018 was the spine finding - a claim measured over a narrower
set than it covers. This is its attribution counterpart, and it has three members already found in this arc:

| defect | what it inferred | from what shared state | how it failed |
| --- | --- | --- | --- |
| material-owner attribution | which session did the work | a baseline **diff** over the project tree | a read-only session was charged with another session's dirty files |
| workshop typed-turn receipts | that the human answered **this** question | **any** typed message in the conversation | five `human-confirmed` receipts minted for a question never asked |
| turn-end identity | whose turn is being declared | the **project-wide** `session-marker.json` | session A declared, the record landed under B; A refused, B credited |

**One root: each asked shared project state a question only a specific party could answer.** A tree diff
does not know who edited; a message does not know which question it answers; a project-wide marker does not
know which session is speaking. Every one of them was a reasonable inference and every one produced a
confident wrong answer, because **an inference has no way to report that it was guessing**.

**The corollary, which is the reusable part**: *have the party that knows declare it.* Not a better
inference - a different shape.

- Material owner -> retired; attribution is now the declaring session.
- Turn-end identity -> the hook issues a per-turn token into its own session directory; the script echoes
  it; the Stop accepts only its own token. **A project-scoped file cannot answer a session-scoped question**,
  so the read was deleted rather than hardened.
- Workshop receipts -> **still open**, and it is the third member: a receipt still mints against any typed
  message rather than against a declared question. Fix 2 item (d) is that declaration, and B4F-012's class -
  four receipts spent against refusals on the archived specimen - is the same defect seen from the other end.

**The test for whether a future control belongs to this family**: if it answers "who" or "which" by reading
state that more than one party writes, it is inferring, and it will be confidently wrong at least once.

### A SECOND, SMALLER ROOT, recorded because it has now bitten twice in one batch

`ConvertFrom-Json` silently coerces an ISO-8601 string into a `[datetime]`.

1. The design-decision record failed its own read-back verify: a `recorded_at` the script had just written
   came back as a `[datetime]` and failed a `[string]` type check.
2. The turn-token ordering compared two tokens as EQUAL because re-parsing the coerced value lost the
   sub-second part - so the newest-wins sort was arbitrary, and the losing session could not recover.

**Both were caught by a verify step rather than by a test**, which is the argument for verify steps. The
durable fix in each case was to stop depending on a type surviving JSON: check presence rather than type,
and order by a number that cannot be coerced into something else.

---

## B4F-051 - THE SECOND PASS, ITS SEVEN FINDINGS, AND A DISPUTED REVIEWER IDENTITY

**Numbering note**: commit `b8936d67` cites this entry as B4F-050. It was renumbered when the maintainer
assigned B4F-050 to the work-kind finding below. This is the SECOND such collision (B4F-047/048 was the
first), and the cause is that two parties allocate from one sequence. A fix is proposed at the end of
B4F-050 rather than left to happen a third time.

**The scoped second pass completed** where the first did not: `candidate-result.json` written (14,449
bytes), verdict `findings`, areas `b`/`d`/`e` exactly as scoped, 20 paths examined, **7 findings, every one
at `confidence: certain`**, each with a probe it ran against the real code. It also **withheld** a
session-token mismatch it encountered, because identity was out of scope - a reviewer that respects a scope
boundary it could have quietly crossed.

### MODEL PROVENANCE IS DISPUTED, NOT CHOSEN

**The reviewer's identity is the evidence this release leans on**, so the disagreement is recorded rather
than resolved by picking one:

| source | claim |
| --- | --- |
| the run log (`codex-stdout-run5.log`, and run4 before it) | **`gpt-6-astra`** |
| the result file's own `model` field | **`gpt-6`** |

**Two claims that disagree, and neither was verified against the serving side.** A release note that leans
on this must say so.

A third value, `gpt-5.1-codex-max`, was briefly recorded here and is **struck**: it was the maintainer's, it
has no source in the export - `gpt-5` appears zero times in the result file and in either run log - and the
maintainer has said plainly that it was produced rather than read. It is kept in this sentence only so the
strike is visible; it is not a claim.

### THE SEVEN FINDINGS, ALL CLASSIFIED FIX

| # | area | severity | finding |
| --- | --- | --- | --- |
| 4 | d | medium | **the STOP-INTENT parse is live and bypasses the declaration contract** |
| 5 | d | medium | **material-owner attribution is live and still misattributes across sessions** |
| 3 | d | medium | the BOUNDARY recovery directive still demands the prose packet and never names the script |
| 2 | b | medium | the candidate resolver returns before its own loop when there is no anchor |
| 7 | e | medium | Case 5b is RED, not merely inert |
| 6 | e | medium | Case 19 is inert - restoring its marker would not change its assertion |
| 1 | b | low | a boundary assessment that cannot read the transcript is silent - no journal row, no warning |

**None is a record-and-defer and none is disputable**: each names a concrete failure with the code that
proves it. The order of repair is the maintainer's: **the two retirements first**, because a converted test
proves nothing about a contract that can be skipped.

---

## B4F-050 - `bug-bash` IS A MARKDOWN CHECKLIST: the contract has no enforcement behind it

**BETA5, above the per-feature work-kind item and entangled with it.** The maintainer's finding, verified at
source and found to be stronger than stated.

### THE MEASUREMENT

`bug-bash` appears in **exactly one product script** - `work-kind-validator.ps1` (and its `.specify/`
mirror). **Zero** occurrences in `validate-governance.ps1`, `sync-boundary-state.ps1`,
`shared-governance.ps1` and `create-governed-feature.ps1`.

**And the one place it does appear enforces nothing.** The validator's own header:

> *"Defaults to ADVISORY (warns, never blocks). **Fail-open everywhere**: malformed/missing input degrades
> to a WARN, never a crash or a spurious block."*

Its single `bug-bash` branch (line 171) groups the kind **with** `software-feature` rather than giving it
distinct behaviour, inside a check its own comment calls *best-effort, fail-open*. So the strongest
statement is not that enforcement is thin - it is that **there is none, in a component that never blocks
even when it fires**.

**The contract is therefore a markdown checklist, and every gate is built for `software-feature`.**

### THE CONSEQUENCES, ALL OBSERVED IN THIS ARC

| consequence | where it was seen |
| --- | --- |
| its five evidence items have **no checker** | this finding |
| feature creation scaffolds an intake controller the work kind never resolves, which then asserts an open workshop on **every Stop** | B4F-025 |
| review is named a **required stage** and is unreachable, because campaigns key to an iteration bug-bash never creates | B4F-030, B4F-047 |
| the declaration is **project-scoped**, so it cannot describe one feature without making the project false | B4F-006, B4F-020 |

**The conclusion, in the maintainer's words**: *choosing `bug-bash` today is opting OUT of enforcement, not
into a different enforcement, and nothing can tell a disciplined bug-bash from none.* That last clause is
the vacuous-control test applied to a whole work kind - which puts this finding in the same family as
B4F-047 rather than beside it.

### THE CANDIDATE RESOLUTION - cheaper than a parallel enforcement path

**The iteration is a CONTAINER, not a ceremony.** Campaigns key to it, the validator scopes to it, closeout
seals it, the clarify sync needs it. Bug-bash dropped the *plan ritual* and, with it, the *artifact* the
machinery is keyed to - and those are two different things that were discarded together.

**So: let `bug-bash` scaffold a minimal iteration with no plan ceremony.** One artifact, no ritual, and
every existing gate keeps working because the thing it keys to exists.

**This requires B4F-044 fixed first**: scaffolding currently advances boundary state while consulting no
authorization at all, so making the scaffold do more before that is fixed would widen a control that does
not check anything.

**Evaluate against the alternative before choosing**: teaching every gate a second vocabulary. That is the
larger change, it multiplies the number of places a work kind can be misread, and each new gate would then
have to learn two contracts instead of one.

### NUMBERING, RULED - and the dual-prefix proposal is struck

B4F-047/048 and B4F-050/051 both collided. The proposal that followed - a separate `B4F-Cnnn` stream for
crew findings - is **withdrawn on the maintainer's ruling**, for two reasons that are both better than the
proposal:

- **The one who holds the document allocates.** The maintainer describes a finding; the crew gives it its
  number; the maintainer cites numbers back and never assigns one. A number the maintainer proposed was an
  inference of the next value from a stale read of shared state - **B4F-049's corollary applied to
  identifiers**, and the same mistake as the three it names.
- **A second scheme would encode who found a thing into an identifier not meant to carry it.** Provenance
  belongs in the entry, not in its name.

The two stale commit citations (`181d4b57` -> B4F-048, `b8936d67` -> B4F-051) stay as written, with the
cross-references in the entries they point at.

---

## B4F-052 - THE CONFIRMATORY PASS: the repairs confirmed, and three more, one of them mine

**Scoped as ruled**: identity, the retirements as completed, the converted cases, and explicitly the
session-token mismatch the second pass withheld. `candidate-result.json` written, verdict `findings`,
21 paths examined, 3 findings all `certain`. Provenance as before and still disputed: the run log says
`gpt-6-astra`, the result field says `gpt-6`, neither verified against the serving side.

### CONFIRMED - what it set out to check

- **The withheld mismatch is repaired.** The reviewer confirmed the runtime-root token is now found on a
  host that passes no session id, that the losing session recovers when its next turn starts last, and
  that a fresh token rejects a pre-crash declaration.
- **The owner-attribution retirement is complete**, tree-wide including the mirrors, and **the retained
  `continue` directive is unreachable** - leaving it one release was safe.
- **All 87 detection checks pass and the converted cases have meaningful subjects**, restored Case 19
  included. The crew's prose-scoring mutation redding exactly Cases 2 and 2c is *"the expected set for an
  additive prose-acceptance mutation"* - the reviewer's words.

### THREE FINDINGS, CLASSIFIED

| # | area | severity | finding | class |
| --- | --- | --- | --- | --- |
| 2 | retirements | medium | **an in-flight declaration released a PENDING-BOUNDARY stop** | **FIX** - done |
| 3 | identity | low | the render cooldown re-parsed a JSON-coerced timestamp as local time | **FIX** - done |
| 1 | identity | medium | with two sessions, the newest-token semantics can credit B for A's declaration | **FIX** - needs a ruling |

**Finding 2 is a bypass I introduced, and it is the important one.** The retired STOP-INTENT lane was
entered only for a MATERIAL stop; the replacement I wrote assigned `intermediate` for *any* unexhausted
in-flight declaration, and the shared `$blockWarranted` then suppressed *every* refusal - including a
pending boundary. Reproduced by the reviewer: `-Kind in-flight -Pending 'verification job'` at a pending
`clarify -> plan`, provider exits 0 with empty output. **Background work could suppress the packet the
human's verdict depends on.** Retiring the parser was complete; the replacement had widened the exemption
past the lane's scope. Fixed by restoring the `material`-only guard; Case 2d is the reviewer's probe and
goes red under the guard's removal and under nothing else.

**Finding 3 is the THIRD instance of one root** - `ConvertFrom-Json` coercing an ISO timestamp - after the
design-decision read-back and the token ordering. Casting the coerced `[datetime]` back to a string drops
the UTC designator and the fraction; re-parsing it reads local time. Measured on this machine's zone: a
render 0.5 s old looked ~3 hours old, and the 45-second in-flight cooldown was bypassed. Same durable fix as
the other two: the cooldown reads a number, `rendered_ms`.

**Finding 1 is real and the ruling's own collision semantics leave it open.** With two sessions, the script
resolves to the NEWEST token, so A's declaration lands under B when B started last. A's Stop finds no record
and refuses with the *generic* message - the mismatch predicate needs a record to compare, and A has none, so
the collision is not named for A. **B's Stop finds a record carrying B's own token and credits it**, though B
never declared. "Credits neither" is therefore not achieved: B is credited. A's recovery on its next turn is
confirmed but does not undo B's credit.

The script cannot know which session invoked it; that is the limit the ruling accepted. Three ways to close
the gap, each with a cost the maintainer should weigh rather than the crew:

1. **The hook hands the token to the agent at turn start** (in its turn-start output) and the script takes
   `-Token`. Unambiguous - the party that knows tells the party that acts - but it depends on the agent
   passing a value, and the newest-token discovery remains as the fallback when it does not.
2. **The script refuses to declare when more than one live token exists**, naming the collision. Fails
   closed at the writer and credits neither, but two long-running sessions could block each other until one
   turn ends, since a token stays live until its session's next turn start.
3. **Accept newest-wins**, as now, and document that a second session can be credited for the first's
   declaration. Rejected by the ruling as written, so listed only for completeness.

## B4F-053 - THE TURN TOKEN WAS ISSUED ONCE PER SESSION, because the provider was never registered for the turn start

**Found by reading the record before building finding 1's closure**, not by a test: the tests drive the
conformance provider directly with `-Event UserPromptSubmit`, and that path works. The dispatcher selects
providers by the registry row's `events`, and the conformance row in `refocus-scopes.json` has read
`["Stop", "agentStop", "stop", "SessionStart", "PostToolUse"]` since `f8df5f8a` (198). No `UserPromptSubmit`,
no `PreInvocation`. The provider's turn-start lane - the T070 live baseline capture AND the fix-2 token
issue - therefore ran at `SessionStart` only.

**Evidence from this project's own runtime**, four sessions with a token on disk: every `turn-token.json`
carries `turn_id: turn-1`, and the `turn-baseline.json` beside each says `capture_event: SessionStart`. The
handover provider, which IS registered for `UserPromptSubmit`, has journal rows with
`"source":"UserPromptSubmit"` - so the event reaches the dispatcher; it is the conformance row that does not
subscribe. Case PH-prompt in `conformance-detection.tests.ps1` asserts that "Claude's real UserPromptSubmit
provider path refreshes the live baseline" and is green, because it calls the provider, not the dispatcher.
It is a vacuous control of B4F-047's kind: it proves the lane, and the lane was unreachable.

**What it cost before this**: the token was a per-SESSION identity, not per-turn. For the two-session
collision that is still an identity, so the mismatch check was not wrong; but the per-turn claim in the
store's comments was false in production, and the T070 baseline was captured at session start rather than at
each prompt, so the material-work delta compared against the session's opening state for every turn - the
`exact-turn` attribution mode could only ever be reached in a test.

**Why it is fixed now rather than filed**: finding 1's ruled closure defines liveness by consumption - the
hook deletes the token at Stop. Without per-turn re-issuance, consumption would leave every turn after the
first with no token, and the declaration would degrade to absence forever. The registry row gains
`UserPromptSubmit` and `PreInvocation`; the dispatcher test that reaches the lane THROUGH the dispatcher is
the control PH-prompt should have been.

**Cost added**: one more provider launch per prompt on every host. Measured in PRED-BETA4-014 part 6.

**Landed, and what it costs now that it runs**: the row gains `UserPromptSubmit` and `PreInvocation`; the
token is issued once per turn, handed to the agent in one 200-character line, and consumed by the Stop that
ends the turn. Identity Case 5 reaches the line through the DEPLOYED dispatcher, which is the control
PH-prompt was not. The per-prompt cost, measured in PRED-BETA4-014 part 6: 815-1120 ms as run, of which
the token lane is 35 ms; the rest is a `pwsh` launch, the provider's parse, and the T070 git snapshot that
this finding shows was never taken at prompt in production. **Two per-prompt provider launches now run on
every host** (handover, then conformance). The lever is structural - a light dedicated turn-start provider,
or concurrent provider launches in the dispatcher - and is the maintainer's call, named here for beta5.

**Residual, ruled semantics**: a token-issuing session that crashes leaves a token; while another session
is live the leftover makes every token-less declaration a named refusal (the ruled cost). When no other
token is live, the leftover is the one live token and a token-less declaration lands under the dead
session - orphaned, refused at the declarer's own Stop, never credited. A host whose turn-start hook did not
run (absence) sharing a project with such a leftover hits that every turn and is never told the leftover's
path. Nothing ages a token out, by ruling; the identity suite pins the behaviour so a change is a decision.

## B4F-052 finding 1, closed as ruled

Closure 1 with closure 2 as the fallback for the ambiguous case only; closure 3 (newest-wins) is gone from
the store, asserted on the text. The hook hands the token to the agent at turn start (`[specrew-turn]`, one
line), `declare-turn-end.ps1 -Token` writes under the session holding it, an unknown token fails closed
naming the value, no token with exactly one live is accepted, no token with more than one is refused naming
both sessions and the parameter, no tokens is absence. Liveness is consumption: the hook deletes its token
at the Stop that ends the turn and keeps it across a block. Every directive that names the script carries
`-Token`. The reviewer's two-session probe runs under all four branches, plus the stale-token shape, in
`turn-end-session-identity.tests.ps1`; the end-to-end token-across-a-block shape on the real boundary
fixture is `conformance-detection.tests.ps1` Case 2e. PRED-BETA4-014 holds the verdicts, including the two
clauses that missed.

## B4F-054 - A CAMPAIGN FED BY ITS OWN FIXES: the stale-review advisory cannot tell a product change from a verification edit (beta5)

**Reported by the maintainer from the router-skill campaign `cmp-001-agentic-architecture-skills-i001`**:
three rounds, 7 findings then 5, each round reviewing the previous round's fixes, each fix adding
verification surface - a test, a fixture, an evidence file. The stale-review advisory re-armed on every moved
tree with no distinction between a product change and a fixture edit, so the campaign was fed by its own
fixes until the human stopped it.

**The mechanism, read from the engine**: staleness is a digest comparison.
`Get-ContinuousCoReviewReviewedStateDigest` (reviewed-state-digest.ps1) hashes every non-machinery path in
the tree - machinery is stripped by the one resolver the worktree strip also uses, and *everything else is
in*, `tests/` and fixtures included. The navigator's `review-stale` route ("your last review no longer covers
these files") fires when the working-tree digest no longer matches the reviewed one. A round's fixes are
answered by tests and fixtures; those move the digest exactly as a product edit does; the next Stop reads the
moved tree as unreviewed; a new round opens on the tree the previous round's fixes produced. The loop has no
terminating case as long as every round's response includes verification surface - which a good response
always does.

**What it should distinguish**: the *product surface* (what the reviewer's findings are about) from the
*verification surface* (what closes a finding). A round whose only movement since the reviewed digest is
verification surface - tests, fixtures, evidence, records - answering that round's findings should be able
to CLOSE the round, not re-arm it. This is B4F-047's neighbour: that finding says the review gate is vacuous
where it could help and unsatisfiable where it fires; this one says that once it does fire, it cannot stop.
Candidate shapes, not decided here: a second digest over the product surface only, with staleness judged on
that one and the verification surface recorded as covered by the round it answers; or a per-round "response
set" the navigator subtracts before comparing. Either way the rule is the same: **a fix's verification is
part of the fix, not a new subject for review.**

**Beta5, review-machinery family, beside B4F-047 and B4F-046.**

## B4F-055 - THE DEMOTION RULE OVERRULED THE REVIEWER ON FORM: two findings rated major, demoted for lacking a literal clause, judged the substantive ones (beta5)

**Reported by the maintainer from the same campaign**: the severity classifier demoted two findings codex
rated `major` to `minor` for lacking a concrete failure scenario, and the crew judged those two the
substantive ones of the round.

**What the rule is, read from the engine**: `Resolve-ReviewFindingGatingEligibility`
(review-result-ingestor.ps1, T005 / FR-006, maintainer ruling 2026-08-10 "demote, never discard"). A
`blocking` or `major` finding whose description does not satisfy `Test-ReviewFindingStatesFailureScenario`
lands below the gating floor as `minor`, with the original severity kept in `demoted_from` and a note
prepended to the description. The test is **deliberately the literal clause**: a `Failure scenario:` header
followed by at least twelve characters - "not a heuristic read of the prose", by its own comment, because "a
contract is explicit by construction; the generosity lives in the CONSEQUENCE".

**What it protects**: the human's rounds. An observation with no failure scenario can be reported but
cannot cost the human a round - the gold-plating economics, attacked where they bite. And it makes the
reviewer-prompt contract bind rather than decorate: a prompt is a request; the rejection is what makes it a
contract. Both are right, and the fail direction ("demote, never discard") is the right one for a rule that
will misfire.

**What it cost here**: the rule tests for a HEADER, and a reviewer that argued the failure in prose without
writing the header was overruled on form. The two findings the crew judged substantive were demoted below
the floor by a string match; the five that passed the match gated the round. That inverts the rule's
purpose in the one case it was written to serve - the reviewer that found something real - and it is not a
misfire the human can see at the moment it matters, because the demoted findings are carried as ordinary
minors in the follow-up list.

**Should the classifier overrule the reviewer?** Not on form alone. Three shapes, for the maintainer:

1. **A demotion is a question back to the reviewer, not a verdict.** A gating finding without the clause is
   returned to the reviewer once - "state the failure scenario or accept minor" - before it is graded. The
   contract stays literal and binding; the reviewer, who knows whether there is a scenario, answers. One
   extra exchange per unclaused finding, bounded.
2. **A demotion is visible at the gate, not only in the follow-up list.** The round's human-facing surface
   names every demoted finding with its reviewer severity beside the gating ones, so the human can promote
   one with a typed reply. Cheapest; keeps the rule; moves the judgement to the human who pays for rounds.
3. **Widen the detector.** Accept a scenario expressed as `when ... then ...` or `->` prose. The rule's own
   comment rejects this, and rightly: a heuristic read of prose is a detector guessing at intent, which is
   the class fix 2 just retired on the conformance side.

The crew's reading: (1) keeps every property the rule was written for and fixes the one it lacks; (2) is
the floor if (1) is too costly; (3) is not taken. **Beta5, review-machinery family, with B4F-054.**

## B4F-056 - PARTIAL SIGN-OFF IS THE DESIGNED CLOSE, not the exception, and its packet should say what it covers (beta5)

**Reported by the maintainer from the router-skill campaign**: the sign-off rule - the latest review must
have seen the tree - combined with every finding producing a fix means a campaign terminates only on a
zero-finding round or a partial sign-off. Given B4F-054 (every fix moves the tree the rule compares against),
a zero-finding round on the CURRENT tree is the rare case; the ordinary end of a campaign that was answered
well is a partial sign-off over a delta the latest round did not see.

**So partial sign-off is the designed close.** Its packet today asks the human to compose the reason - to
say, in their own words, why signing off over an unreviewed delta is acceptable. That is the wrong party
composing: the engine knows the delta (the paths that moved since the reviewed digest) and knows what
covers it (the tests and fixtures added in answer to the round's findings, the runs that executed them). The
packet should ENUMERATE the uncovered delta and the verification covering each part of it, and ask the
human to confirm or contest that coverage - the same shape as every other packet in this product: the
machine states the facts, the human decides.

**Beta5, review-machinery family, with B4F-054 and B4F-055.** The three are one item seen from three
sides: the review cannot stop (054), it grades the wrong thing on the way (055), and its stopping ceremony
puts the composition on the human (056). A design that fixes the first may dissolve the third.

## B4F-057 - THE STOP LANE WAS KILLED BEFORE THE COUNTER ON EVERY MATERIAL STOP HERE: the review digest cost 18-37 s of a 20 s budget

**The reviewer's live measurement, explained.** Four unconsumed `turn-token.json` files, no
`turn-counter.json`, the same token re-injected turn after turn, every declaration overwriting `turn-1.json`.
The maintainer asked which it was: consumption not deployed, or the Stop path not reached. **Measured: the
code is deployed (`Remove-SpecrewTurnToken` in the `.specify` copy) and the path is not reached.** Through
the deployed dispatcher, on an idle machine, `Stop` for a session with an orientation receipt:
`PROVIDER_FAILED provider 'conformance' timed out; skipped` at the 20 s budget, after `last-fire.json` (1.7 s)
and before the counter step, the token consumption, the journal row; the navigator then
`PROVIDER_BUDGET ... skipped`. Direct, the same Stop took 28.0 s.

**Where the time went, marker by marker**: 21.3 s between the orientation lane's guard and `$blockKind`,
of which `Get-SpecrewReviewCoverageState` 20.4 s, of which `Get-ContinuousCoReviewReviewedStateDigest`
19.1 s: `git add -A` on the seeded temp index 135 ms; `Get-ContinuousCoReviewMachineryPaths` 4.3-9.3 s (a
recursive marker walk that descended into `.scratch` - 37,899 files - and discarded every hit there
afterwards); **the per-path denial loop 14.0 s** over 5,792 tracked paths, `Test-ContinuousCoReviewDigestPathDenied`
once per path at ~2.4 ms a call. The coverage state - and so the digest - runs at every MATERIAL stop in
any project with a delivered review campaign AND the self-host engine beside it. Consumers do not carry
`scripts/internal/continuous-co-review/`, so their coverage state has no digest and their Stop lane is
cheap: this is the dogfood repo's cost, on the repo where every fix is proven.

**Three changes, each identity-preserving, each proved on the same tree** (PRED-BETA4-018):

1. The denial loop hands a path to the predicate only when its first segment can match a literal
   machinery path or a `<prefix>/**` pattern; any other wildcard pattern forces the full scan. Same
   predicate, same result - the tree id is byte-identical - 14 s to ~1 s.
2. The marker walk prunes the volatile roots at the top level instead of discarding afterwards; the
   machinery set is identical (`Compare-Object` empty), 9.3 s to 1.2 s.
3. The digest is cached by worktree CONTENT state - HEAD, the porcelain listing, and each listed file's
   size and mtime - under `.specrew/runtime`, which the identity already excludes and `.gitignore` already
   hides. Miss 9.5 s, hit 212 ms, `-NoCache` identical; a modified tracked file, an added untracked file each
   change the id; a write into the runtime dir does not. Nothing here can make the digest wrong, only slower.

**After the three**: through the dispatcher the conformance provider completes (counter 7 -> 8, token
consumed) and it is now the NAVIGATOR that times out at the remaining budget - it takes 9-18 s of its own
on this repo (engine load, registry, checkpoint diff), the same class one provider later. Handover 5 s,
conformance ~4 s, navigator ~9 s: 18 s against a 20 s budget shared by all three, and under any load the
last one dies. The 20 s was chosen for Codex's 30 s ceiling and is not raised here. **Named for the
maintainer, with the navigator's own 9 s as the next measurement.**

**What this changes about the record**: every Stop-lane assertion in this repo since the census at
`d4a89ab7` ran against a provider that was being killed mid-lane in production while passing its tests -
the tests drive the provider directly with no budget. The class is B4F-047's again: a control that cannot
fail where the product does. The identity suite's Case 5 goes through the dispatcher for the turn-START
lane; nothing yet goes through it for Stop under the real budget. Beta5: a dispatcher-path Stop test with
the production budget on a tree of this size.

## B4F-058 - THE SIGN-OFF'S OWN RECORDS INVALIDATE ITS COVERAGE, so the human accepts twice (beta5)

**From the router-skill review-signoff at `d4a89ab7`**: committing `review.md` and `quality-evidence.md`
moved the tree past the partial-signoff binding, and the human had to accept the same partial sign-off
twice. The mechanism is B4F-054's digest over every non-machinery path, applied to the records the
sign-off itself writes. **Coverage must bind to the SOURCE surface, excluding the records the sign-off
writes** - the same surface split B4F-054 asks for, applied at the binding rather than at the advisory. One
fix serves both; recorded separately because the symptom is a human cost at the boundary, not an advisory
loop. Beta5, review-machinery family.

## B4F-059 - TWO GATES DISAGREE ON TASK-STATE VOCABULARY (beta5, decided: one vocabulary)

**From the router-skill review-signoff**: the boundary sync accepts only `pending | in-progress | done` in
`tasks-progress.yml`, while the state's Task Outcomes table uses `blocked`. A task that is blocked is a
real state a human needs to see, and a vocabulary the sync refuses is a state the ledger cannot carry.
**One vocabulary, decided**: the sync's enum is the authority, and `blocked` joins it - with a required
reason - rather than the state table dropping it, because "blocked, and why" is exactly the fact a
re-entry packet exists to surface. The template, the validator and the sync change together. Beta5.

## B4F-060 - `run-mechanical-checks.ps1` FAILS WHEN THERE IS NOTHING TO SCAN (beta5, the refusal standard again)

**From the router-skill review-signoff**: on a stack with no discoverable PowerShell sources the script
exits 1. "Nothing to scan" is a NOT-APPLICABLE result with a reason, not a failure - the refusal standard:
say what was looked for, where, and that none was found, and exit 0 with the not-applicable recorded in
the evidence, so a sign-off over a non-PowerShell stack does not carry a red it has to explain away. Beta5.

## B4F-061 - SIX TYPED AUTHORIZATIONS FOR ONE BOUNDARY: campaign decisions are gated like crossings (beta5, measured on the re-walk)

**From the router-skill review-signoff**: `approved for review round`, `run another round`, `stop the
review here` (refused), `partial signoff`, `partial signoff` again after the sign-off's own records moved
the tree (B4F-058), `approved for review-signoff`. Three were decisions; three were mechanism. Campaign
decisions - round approvals, pause choices, partial acceptances - are gated like crossings, under a
boundary that is itself a crossing, so one boundary costs one verdict plus N.

**Options to evaluate, as the maintainer put them, with the crew's first read:**

1. **Campaign decisions internal to the review stage, one verdict at its end**, the packet enumerating
   rounds run, findings fixed, and the uncovered delta. Cleanest count; it moves the per-round decision
   from a typed authorization to a stage-internal choice, which is right only if a round's cost (budget,
   time) is something the human agreed to once at the stage's start.
2. **`run another round` and `approved for review round` as one phrase.** Removes one mechanism
   authorization per round with no design change; cheap and should ride regardless of (1).
3. **Partial acceptance bound to the source-surface digest** so the sign-off's own records cannot
   invalidate it - B4F-058, and it removes one of the six outright.
4. **`stop` after a round with findings presents the partial acceptance directly, delta enumerated, one
   typed reply**, instead of refuse-then-ask - B4F-056's packet, arriving at the moment the human asked
   to stop rather than after a refusal.

**The measure is fixed now**: typed authorizations per boundary, counted on the re-walk. Six is the
baseline; (2)+(3)+(4) alone read as three; (1) as one plus whatever the stage asks at its start. Beta5,
review-machinery family - with B4F-054, -055, -056, -058 this is one design item seen from five sides.

## B4F-018, adopted downstream: a consumer promoted "proven without exercising its subject" to a standing reviewer focus

**From the router-skill retro on `d4a89ab7`, for the release notes and the talk's evidence**: iteration 001
estimated 22 SP, actual 29 (+32%), and every point of the variance sits in three validation tasks, each added
by a review round that found a check passing without exercising its subject. The retro made that phrase a
standing reviewer focus for the project. B4F-018's rule, taken up by a consumer on its own numbers rather
than handed down - which is the strongest evidence a methodology finding can have. The five governed-script
surprises the retro files are all already in this record; `0be4a6e6` (the reviewer scaffold on an empty
changed file, PRED-BETA4-017) closes one; B4F-058, -059, -060 and the sign-off count in B4F-061 are the
rest, beta5.

## B4F-002, field-confirmed on a consumer, with two things it did not say yet

**Router-skill project, `d4a89ab7`, iteration 001 at RETRO**: a resumed session's hook rewrote `state.md`
and `tasks-progress.yml` - `Iteration Status` set to `ready-for-review`, a value outside the canonical enum
and wrong for the stage. The crew restored both with `git checkout` per the maintainer's standing
instruction and re-mirrored the phase by hand. The writer is the chain B4F-002 read end to end
(`coordinator-resume.ps1` -> `Get-TaskProgressSummary` -> `Sync-IterationTaskProgress` ->
`Update-IterationStateFromTaskProgress`), and the consumer's specimen adds two facts to it:

1. **The writer derives a status the validator's own enum rejects.** `ready-for-review` is not a canonical
   iteration status; the state writer and the state validator disagree on the vocabulary, which is
   B4F-059's shape one file over. A writer that can emit a value its reader refuses will be refused at the
   next gate for a value the human never chose.
2. **It fires on an OPEN iteration at a stage past review, not only on a sealed one.** B4F-002's specimen
   was a closed, sealed iteration; the consumer's was open and at retro. The seal was never the boundary of
   the defect - the GET-verb write is - so the fix is the writer, not the seal, and the beta5 item reads that
   way: a resume derives nothing into an iteration's records past the stage the records belong to.

## B4F-062 - THE VELOCITY DASHBOARD REPORTS PLANNED POINTS AS DELIVERED (beta5)

**From the same retro**: the velocity dashboard reports 22 SP delivered for iteration 001, while the
retro's calibrated actual is 29. The dashboard's number is scope closed - the planned points of the tasks
marked done - not effort spent; it is not calibration data and is labelled as if it were. Either the
dashboard reads the retro's calibrated actual once it exists, or its column is named for what it counts.
Beta5, beside B4F-018's field adoption: the +32% that the consumer found is invisible on the surface that
claims to show it.
