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

