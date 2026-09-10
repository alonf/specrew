# Beta4 predictions, stated before their runs

**Why this file exists.** `docs/beta4-scope.md` records the standing practice: *state predictions before
running anything whose outcome could be rationalised afterwards, and commit them first*. Iteration 003's
drift log is SEALED, so a prediction cannot be appended there. Feature 201 does not exist yet. This file is
the home for a prediction that has to be committed before either of those is true, and each entry moves to
the owning feature's drift log once that feature has one.

---

## PRED-BETA4-001 - will opening feature 201's workshop register `.specrew/handover/workshop-question.json` in THIS repository?

**Stated 2026-09-09, before feature 201 was scaffolded and before any workshop question was rendered.**

### The measured starting state, taken first

| fact | value |
| --- | --- |
| `.specrew/handover/workshop-question.json` | **absent** |
| `.specrew/runtime/workshop-authority.jsonl` | **does not exist anywhere in this tree** |
| feature 199's workshop records | 7 lenses, written 2026-08-10 |
| `start-context.json` `feature_ref` | `199-beta3-stabilization` - a **closed** feature |
| `start-context.json` `boundary_type` | `feature-closeout` |
| `start-context.json` `session_state.active` | `false` |

**So no technical lens has ever been opened in this tree under the current typed-turn machinery.** Feature
199's workshop predates the receipt store, which is why the store is absent rather than empty.

### A CORRECTION TO DRIFT-199-I003-094's MECHANISM, verified at source before the prediction was written

The handover carried this chain: *line 627 reads `.specrew/handover/workshop-question.json`; 1117 sets
`workshopIntermediate` from it; 1479 makes `workshopQuestionWins` require it.* **The first two links are
wrong**, read from `extensions/specrew-speckit/scripts/specrew-conformance-provider.ps1` in this tree:

- **Line 627 is inside a WRITER, not a reader.** It is the path assignment in
  `Update-SpecrewWorkshopQuestionHandover` (line 623). When the decision is valid the function writes the
  file atomically; when the decision is null or invalid it **DELETES** the file.
- **That function's own comment states the opposite of the chain**: *"A small local projection makes an
  interrupted workshop resumable without becoming authority. Classification never reads this file; the
  exact, strict feature/iteration applicability artifact decides."*
- **Line 1116 sets `$workshopIntermediate` from a LIVE RE-RESOLVE**, not from the file:
  `$workshopQuestion = Resolve-SpecrewWorkshopQuestionPause ...` with the last assistant text and the
  controller state as inputs. The comment two lines above says it re-resolves *"only to enrich the
  non-authoritative handover projection with the visible question"*.
- **The one production reader is the receipt writer.** `workshop-authority-store.ps1:435`
  (`Write-SpecrewWorkshopAuthorityReceipt`) reads the file and returns `$null` when it is absent, so a
  typed reply cannot be bound to a question.

**Every other reference to the file in this repository is a TEST that hand-writes it** -
`conformance-detection`, `workshop-agenda-confirmation`, `workshop-material-packet-language`,
`workshop-typed-turn-authority`. That is DRIFT-199-I003-052's provenance shift exactly: the fixtures
fabricate the artifact, so no test exercises the path that produces it.

**What survives and what does not.** DRIFT-199-I003-094's CONCLUSION survives - one cause, two symptoms.
Its MECHANISM does not. The single point is `Resolve-SpecrewWorkshopQuestionPause` returning valid; the
file is that resolve's OUTPUT, and an input only to receipt minting:

```
Resolve-SpecrewWorkshopQuestionPause --valid?--> workshopIntermediate --> workshopQuestionWins --> packet or light form
                                     |
                                     +--writes--> workshop-question.json --read by--> receipt mint --> lens can close
```

**AND THAT RELOCATES THE FIX.** DRIFT-199-I003-094's countermeasure - *opening a lens writes the pending
question* - writes the projection without repairing the resolve. Under it the receipt would mint against a
question the classifier does not agree is open, and the packet symptom would persist. **The fix belongs at
the resolve, not at the projection.**

### THE PREDICTION

**The file will be ABSENT after the turn in which feature 201's first workshop question is rendered.**

**The reasoning, so it is falsifiable rather than a guess.** The write is gated on the resolve returning
valid, and the resolve consumes the active feature reference, the active iteration number and the boundary
state. This tree currently presents that resolve with a state **no fresh project can be in**: a start
context naming a CLOSED feature at `feature-closeout` with `session_state.active: false`, and a sealed
iteration 003. A fresh project has one feature, no closed predecessor and no sealed iteration.

**One line of reasoning was considered and REJECTED, recorded because it is the tempting one.** The resolve
carries `workshop-active-iteration-missing` (provider line 532), and feature 201 will have no `iterations/`
directory until the plan boundary scaffolds one - which looks like a clean explanation. **It cannot be the
whole story**: DRIFT-199-I003-092 records the Casio walk closing 5 of 5 technical lenses on a greenfield
project, which is impossible if a missing iteration blocked registration for every new feature. The
iteration argument is kept as a candidate reason, not as the prediction's basis.

### WHAT EACH OUTCOME MEANS, fixed in advance

| outcome | conclusion |
| --- | --- |
| **PRESENT**, `phase: product-domain` | The resolve works here. This tree is neither immune nor blocked at intake, and the block lives DOWNSTREAM of the agenda. Beta4's first item narrows to the agenda-to-technical-lens transition - the same narrowing DRIFT-199-I003-099 performed on -097, by the same method. |
| **ABSENT**, reason names feature or iteration applicability | The stale start context is the distinguisher. The block is a CARRY-OVER-PROJECT condition rather than a greenfield one, beta4's first item is scoped to the wrong reproduction, and the fix is in the resolve's preconditions. |
| **ABSENT**, reason names question detection | The resolve did not recognise the rendered question. The defect is detection, and DRIFT-199-I003-094's proposed countermeasure would paper over it. |
| **ABSENT**, no reason recorded anywhere | DRIFT-199-I003-045 restated where it costs most - the journal names the classification, never the decision - and beta4's first fix is diagnosability, not the workshop. |

**The instrument**: `.specrew/runtime/conformance-journal.jsonl` for the turn, plus the presence, `phase`
and `feature_ref` of `.specrew/handover/workshop-question.json` itself.

### RESOLVED 2026-09-09: the file is ABSENT, and the journal cannot say why

**The prediction held.** The file was not written; `workshop-authority.jsonl` still does not exist. The Stop
record carries `block_kind = material` with `workshop_scope`, `workshop_feature`, `workshop_iteration` and
`workshop_lens` all null - the resolve returned nothing, and both symptoms reproduced.

**By the meanings fixed above, this is the FOURTH branch, not the second.** The journal names no reason, so
the three candidate causes are indistinguishable from the instrument the product provides. **The reason
predicted - the stale start context - is still the leading candidate and is NOT established**; predicting
the outcome correctly for a reason the instrument cannot confirm is a held prediction with an unproven
mechanism, and it is recorded as exactly that.

Full record: `docs/beta4-findings.md`, B4F-004.

---

## PRED-BETA4-003 - will the fix fire in THIS tree, at the Stop of the turn that shipped it?

**Stated 2026-09-09, before the Stop that tests it, with the fix in the working tree.**

The fix is live in `extensions/specrew-speckit/scripts/specrew-conformance-provider.ps1` and its mirror. The
resolve runs at every Stop regardless of whether a workshop question was asked, so this turn is a free field
test of the change on the tree that produced it.

**The precondition, measured rather than assumed**: this tree has **exactly one** intake candidate -
`201-first-run-experience` - being the only feature whose `spec.md` still carries the not-yet-authored
sentinel and which also has a feature-level `lens-applicability.json`. Uniqueness is required; the fix
refuses to guess between two.

**PREDICTION: `.specrew/handover/workshop-question.json` will EXIST after this turn's Stop**, carrying
`feature_ref: 201-first-run-experience` and `phase: product-domain` - on a turn where the start context
still names closed feature `199-beta3-stabilization` / iteration `003`, exactly the state that produced
PRED-BETA4-001's absence.

**`question` is expected to be EMPTY or absent, and that is not a failure of this prediction.** No line of
this message ends in `?`, and provider line 564 detects a question only that way (B4F-005). That heuristic
populates a display field and does not gate the write. **If the file appears with an empty `question`, both
facts are confirmed at once**: the fix works, and the punctuation heuristic is real but not load-bearing.

| outcome | conclusion |
| --- | --- |
| **file present, `feature_ref` = 201** | The fix is field-proved on the tree that shipped it, on the exact state that reproduced the defect. |
| **file present, `feature_ref` = 199** | The candidate was resolved but the wrong ref was carried through - a defect in the fix, caught immediately. |
| **file absent** | Something upstream of the candidate logic returns first - most likely the `HasPendingVerdict` or accessor guards - and the fix is incomplete for the live hook path even though it passes at the function level. |

### Two observations from the turn this prediction was written in

- **A LIVE INSTANCE OF DRIFT-199-I003-080, on beta4's first turn.** The session-start contract requires the
  orientation to be rendered as visible prose BEFORE other work. The maintainer's first message required
  three documents to be read before anything else. **The reads were done first and the orientation was
  rendered after them.** That is the same collision the ordering item exists for - a concrete first-message
  request displacing the orientation - and it happened to the session that had just read the entry
  describing it. Recorded as evidence for the in-scope ordering item, not as a separate finding.
- **THE SESSION-START HOOK RENDERED INSTRUCTION TEXT THAT EXISTS NOWHERE IN THIS REPOSITORY.** Its block is
  labelled *"the same text deployed in AGENTS.md / CLAUDE.md, repeated here for convenience"* and contains
  the clause *"they are invoked, never read - their behaviour is described here, so a surprising result is
  reported, not investigated in their source"* (DRIFT-199-I003-064's fix). Measured: that clause appears
  **zero** times in `CLAUDE.md`, `AGENTS.md` and `.github/copilot-instructions.md`, and the sentence
  *"not investigated in their source"* appears **zero** times anywhere in the tree. The hook renders from
  the INSTALLED module; the deployed files are this repository's own copies. **The label is false in this
  tree** - the orientation's own claim about where its text lives does not hold. This is
  DRIFT-199-I003-076's bidirectional drift on a first-run surface, and it is reported rather than acted on.

### RESOLVED 2026-09-09: the file is PRESENT, on feature 201, with an empty question

**PRED-BETA4-003 held in every particular**, measured from disk at
`.specrew/handover/workshop-question.json`, written `2026-09-09T00:42:47Z`:

```json
{
  "schema": "v3",
  "status": "workshop-active",
  "scope": "feature",
  "feature_ref": "201-first-run-experience",
  "lens": "product-domain",
  "phase": "product-domain",
  "agenda_status": "pending-confirmation",
  "question": "",
  "message_hash": "1010cf7061cdb142591b014358ec4767f882ecc581762ae5d7709ce7f422cf69",
  "artifact_path": "...\specs\201-first-run-experience\lens-applicability.json"
}
```

**This is the field proof, and it is taken on the exact state that produced the defect**: the start context
still names closed feature `199-beta3-stabilization` / iteration `003`, which is what returned nothing valid
in PRED-BETA4-001. The same tree, the same stale ref, the opposite outcome.

**`question` is empty and `message_hash` is not**, which was predicted and which confirms both facts at
once:

- **the fix works** - the resolve found the open feature and the projection was written;
- **the punctuation heuristic (provider line 564) is real but NOT load-bearing** - no line of that message
  ended in `?`, so no question text was captured, and the write happened anyway with a bindable hash.

**So a receipt can now mint** where it could not before. That is the whole chain the defect broke:
resolve -> projection -> receipt -> lens closes.

**CORRECTION, made within a minute of writing the sentence it replaces.** This entry first said
*"`.specrew/runtime/workshop-authority.jsonl` is still absent, because no workshop question has been
answered since the fix landed."* **That was false and was not checked before it was written.** The store
exists and holds **five receipts**, all `201-first-run-experience` / `product-domain`, minted between
00:26:46Z and 00:44:12Z from the reviewer's typed turns.

**So the chain is proved further than predicted - resolve, projection, AND receipt mint.** It also surfaced
a defect the block had been hiding, which is recorded as B4F-011: **those five receipts answer no question
the human was ever asked**, and none of them may be cited when the product-domain lens is eventually closed.

---

## PRED-BETA4-004 - what the dispatched census will say about THIS branch

**Stated 2026-09-09, before the dispatch, with no run in existence.** DRIFT-199-I003-083's rule is that the
last green before a tag must be a DISPATCHED run, because a local sweep and CI differ precisely in
environment and any failure living in that difference is invisible to the local proxy. So this run can tell
me something my six green local suites cannot, and the expectation is fixed first.

**What this branch changed**: `specrew-conformance-provider.ps1` and its mirror, one new integration suite,
one lane registration, `.specrew/work-kind.yml`, and documentation.

**PREDICTION, in three parts, each independently falsifiable:**

1. **`workshop-resolve-prefers-open-feature` passes in CI.** It builds its own temp fixture and reads only
   tracked sources, so it has no dependency on gitignored runtime state - the category-2 condition that
   makes a file unable to pass in a fresh clone (DRIFT-199-I003-025).
2. **No failure names `specrew-conformance-provider.ps1`, `conformance-detection`, or any workshop suite.**
3. **Any failure that does appear is in a file this branch did not touch**, and is therefore a fact about
   the tree since the last green census (`43815938`, 2026-09-04, 400 files, 0 failures), not about this fix.

**I am NOT predicting the run is green overall.** I have not measured what landed on this branch's ancestry
since 2026-09-04, and claiming a whole-tree result from six curated local suites is the exact error
DRIFT-199-I003-022 records - lanes green reported as tree green.

| outcome | conclusion |
| --- | --- |
| green | the fix ships clean and the tree is green on a dispatched run, which is the gate's own standard |
| red, only in untouched files | the branch is clean; the failures are a separate fact about the tree and are triaged, not attributed here |
| **red naming my new suite** | it depends on something the local environment supplies and CI does not - DRIFT-199-I003-083's shape, and my own test would have joined the fixtures that cannot notice |
| **red naming the provider or a workshop suite** | the fix has an environment-dependent effect the local runs could not see, and it blocks the tag until understood |

---

## PRED-BETA4-006 - the clean dispatch, stated before it runs

**Committed before the workflow is dispatched. The review does not gate this dispatch; it gates the tag.**

Since census `34297054157` (which ran at `f712345e` and failed on five files), the tree has gained: the
lint fixes restoring the detached exemption and dropping an internal id from consumer text; the work-kind
revert to `software-feature`; the marker re-stamp; 003's re-seal; `specrew update` after installing HEAD;
201's authored specification; and the control-naming corrections to the regression suite.

**THE PREDICTION, in four parts:**

1. **The sweep EXECUTES.** `Execute every named test file on disk` runs rather than being skipped, and the
   diagnostics artifact uploads. Checked from the run artifact before any classification, because a
   provisioning death and a sweep failure look identical at run level.
2. **The five prior failures are GREEN — `validate-governance-changed-only` included.** The four others were
   verified locally after their fixes; that fifth is the one carrying real risk, and it is named here rather
   than hedged.
3. **Any failure is in untouched code.** Nothing this branch changed fails.
4. **A timeout is reported as a timeout**, never folded into "failed". `34297054157` completed in failure;
   if this one exceeds its budget instead, that is a fifth outcome and it gets its own name.

**ITEM 4's PREDICTION, carried in and still standing.** `validate-governance-changed-only` was green in CI
at the tag and red at `cee33756`, and the local cause found - base-ref undetectable, unscoped fallback -
matches CI's three assertions better than W43 did:

| outcome | conclusion |
| --- | --- |
| **red with the same three assertions** | W43 was misattributed; the cause landed with the merge-back and it is **in scope** |
| **green** | W43 held, and the marker re-stamp plus the update cleared it |

**Either way the dispatch decides, not a local run** - DRIFT-199-I003-083, whose rule is that the last green
before a tag must be a dispatched workflow run.

**The tag is cut only on the SHA a green dispatch ran on.**

---

## PRED-BETA4-008 - the single sanctioned re-dispatch on 22772117

**Meaning fixed before dispatch. ONE re-run on the same SHA. There is no third run.**

Census `34346555521` on `22772117` left two failures, both in files **byte-unchanged since the last green
census**, both green in that census and in the run before this one. Verified at source, their assertions are
runner-bound:

**`DispatcherLargeStdout.Tests.ps1:71`**

```powershell
Assert-True ($sw.Elapsed.TotalSeconds -lt 15) ("... ({0:N1}s, well under the 20s timeout)" -f ...)
```

**It gates on 15 seconds and its message names 20.** The observed 17.9s failed a **15s** budget while the
text claimed it was well under 20 - which is why the failure first read as a pass reported as a failure. The
comment above it states the design: the provider timeout is 20s + Kill, and *"15s cleanly separates the two
even under moderate load"*. **17.9s is between the separator and the real ceiling: a slow runner, not a
deadlock.** Every payload assertion passed - no truncation, no deadlock - and the provider under test is a
stub, so **none of beta4's code is on that path.**

**`squad-init-closed-stdin.tests.ps1:209`**

```powershell
if ([int]$result.timeout_child_pid -le 0 -or [bool]$result.timeout_child_alive) {
    Write-Fail 'timeout did not prove that the complete fake Squad descendant process tree was terminated'
}
```

**Two conditions, one message.** `pid -le 0` is **could not observe**; `child_alive` is **observed alive**.
The output cannot say which fired, and "did not prove" is the could-not-observe reading - an absent
measurement, not a surviving process.

### THE PREDICTION

**Both pass on the re-run.**

| outcome | conclusion, fixed now |
| --- | --- |
| **both green** | Confirmed **runner-bound**. `22772117` has its green run and is the tag SHA. |
| **either red again** | **NOT flakiness. A real blocker.** Nothing is tagged until it is understood. |

**AND THERE IS NO THIRD RUN.** A single re-dispatch with its meaning fixed in advance is a discriminator. A
second re-run of a red census is a lottery, and it is refused - it would convert the gate into a dice roll
nobody named, on the release the gate exists to protect.

### RESOLVED 2026-09-09: both green. Runner-bound confirmed, and `d4a89ab7` has its green run.

**Run `34354188094`, `conclusion: success`, all three jobs green:**

```
full-test-census      success
prepublish-validation success
publish-module        success
```

**The sweep executed** - `Execute every named test file on disk`: **success**, not skipped. Checked before
the verdict was accepted, as every census result in this arc has been.

**By the meaning fixed before the dispatch: both timing assertions are CONFIRMED RUNNER-BOUND.** They failed
once at 90% of a budget the message misreported, on files byte-unchanged since the last green census, and
passed on the next run of the same code. **This was the single sanctioned re-dispatch. There is no third
run, and none is needed.**

**One entry in the diagnostics artifact on a GREEN run**, read rather than assumed:
`tests\direct-exit.tests.ps1`, output `DIRECT-EXIT-SENTINEL`. **That file does not exist in the
repository** - it is a transient fixture written by `tests/unit/full-sweep-direct-exit.tests.ps1`, a unit
test *of the sweep* that proves the harness captures a direct exit. **It is a passing test's by-product, not
a swallowed failure**, which is why the job is green. Worth one beta5 line only: a diagnostics artifact that
carries a failure-shaped entry on a green run will mislead someone eventually.

**THE TAG SHA IS `d4a89ab7`** - the SHA the green dispatch ran on, which is the rule. It carries
`22772117`'s code exactly; the three commits between them are docs-only with zero census subject files
(measured in B4F-034). The branch head has since moved past it with records, which is the normal shape -
records live outside the tag (DRIFT-199-I003-040).

---

## PRED-BETA4-010 - fix 1, the agenda-clearing trap. Stated before the code.

**Why the two halves cannot be shipped separately**, established at source before predicting:
`confirm-workshop-agenda.ps1` refuses to render **or** confirm an agenda unless the `product-domain` typed
receipt **and both** `workshop/product-domain.md` / `.yml` are on disk. **So every project whose
`agenda_status` is `confirmed` necessarily carries them.**

- **The control alone would re-strand** DRIFT-199-I003-020's projects: refusing any lens not in `selected`
  once confirmed also refuses `confirm-intake-lens` from `confirmed-complete`, which is the recovery that
  entry field-proved on the original stranded specimen.
- **The trigger removal alone leaves the trap**: the clearing still reads as data loss to the next crew.
- **Together they are safe**, because completion derived from the guaranteed records makes the stranded
  case report *complete* - so the recovery the control forbids is no longer needed by anyone.

### THE PREDICTION, four parts, each falsifiable

1. **POSITIVE CONTROL, and it names its path.** Against
   `tests/fixtures/beta4-agenda-clearing/001-mdlink-checker/`, `Get-SpecrewWorkshopLifecycleState` reports
   `product-domain` as completed - `completed` is **non-empty** - and it does so **from the RECORDS**, since
   that fixture's controller `workshop` map is empty. The test asserts *which path supplied it*, because a
   control that does not name its path can certify a path it never took (B4F-028).
2. **The guard refuses.** `confirm-workshop-lens.ps1` refuses `product-domain` against that fixture's
   confirmed state, and the message **states the clearing is normal** and **names
   `workshop/product-domain.md`** as the durable record.
3. **The stranded case is NOT re-stranded.** A confirmed controller with an empty `workshop` map and the
   records present reports **complete**, so no `confirm-intake-lens` recovery is required. DRIFT-199-I003-020's
   ground is held.
4. **MUTATION.** With the guard removed, running the writer against the preserved fixture **corrupts it** to
   `workshop-record-not-selected` - the router-skill outcome, reproduced on demand. If the mutation does not
   corrupt it, the fixture is not the state I think it is and the guard is unproven.

**Fixed in advance**: if (1) fails, the trigger removal is in the wrong place and the guard must not ship
alone. If (4) survives, the guard is untested regardless of what (2) reports.

### THE VERDICT ON PRED-BETA4-010, and two of its four parts were wrong

**Part 1 - REVISED BY THE MAINTAINER BEFORE THE CODE, then PASSED as revised.** I predicted `completed`
would become non-empty. The maintainer ruled instead: surface intake completion as `intake_completed`,
leave `completed` and `remaining` alone. **That ruling was right and mine would have broken things** -
`tests/bootstrap/ProjectMetadataAccessor.Tests.ps1` pins `completed` by exact count in two places
(`-eq 1`, `-eq 2`), and no production script reads `.completed` at all (checked: every `.completed` hit
outside tests is `completed_at` in `task-progress.ps1`). As revised: `intake_completed = True`,
`intake_evidence` naming both records, `completed` still `[]`, **and it names its path** - Case 1 asserts
the controller's `workshop` map is empty in the same breath, so the map cannot have supplied the value.

**Part 2 - PASSED.** The writer refuses, the message says the topic is already complete, names
`workshop/product-domain.md`, states that the empty list is the normal post-agenda state, and names the
next agreed topic as the legal move.

**Part 3 - THE PREMISE WAS WRONG, AND SO WAS THE ONE UNDER IT.** I argued the blanket refusal was safe
because "every project whose `agenda_status` is `confirmed` necessarily carries the product-domain records".
Two errors:

- The **script** writer guarantees them; the **skill** does not. `squad-templates/skills/design-workshop.md`
  still instructs the agent to hand-write `agenda_status: confirmed` (lines 379, 394). A second writer with
  no record guarantee, and it is the one an agent actually uses.
- More importantly, **the records were never a discriminator**. `workshop-lens-checkpoint.tests.ps1`
  Case 7c's own comment says the stranded state is reachable *precisely because* the agenda writer requires
  the records on disk rather than the controller entry - so the stranded project **has the records too**.
  So does the receipt I had proposed as the discriminator in B4F-041. **Both candidate discriminators are
  present in both states.**

**Part 4 - the mutation could not have said what I said it would, and the maintainer saw that first.** With
reader tolerance in place the corrupted controller no longer reads `workshop-record-not-selected`; the
maintainer pre-empted this ("your mutation output is the corrupted fixture, and it must read valid under
tolerance"). Reproduced exactly: guard removed, both receipts present, the writer runs to completion,
`workshop_keys_after = [product-domain]`, and that file reads `active` / `valid` under the tolerance.

**Four mutations, disjoint failure sets, target green before each**: M1 guard removed -> Cases 5+6 only;
M2 tolerance removed -> Case 3 only; M3 completion hard-wired -> Case 2 only; M4 the agenda sentence dropped
-> Case 8 only. All restored byte-identical, mirror synced, post-restore green.

**M1 also killed an assertion of mine that was green for the wrong reason** - see B4F-042.

---

## PRED-BETA4-011 - fix 2, the turn-end declaration. Stated before the code.

**The principle being built**, in the maintainer's words: *the hook verifies artifacts the agent's scripts
wrote, never the agent's prose.* The agent supplies facts as parameters; the script decides what to render;
the hook checks that the script ran for this session and this turn.

**What the surfaces look like before the change**, read rather than remembered:

- `Test-SpecrewReentryPacketPresent` scores >= 4 of 6 header phrases in the flattened last assistant
  message. Prose scoring.
- The W25 orientation lane reads up to **200 transcript lines** and scans them for banner prose, because a
  compliant session was told 188 times that its orientation was never shown.
- `Get-SpecrewMaterialRuntimeState` already scopes per-session state under
  `.specrew/runtime/conformance-sessions/<sha256(host|session)>/`, and already owns `orientation-rendered.json`
  at that path. So (b) replaces WHO writes that file, not where it lives.
- Skills deploy from `squad-templates/skills/*.md` as `specrew-<basename>`, so `turn-end.md` there becomes
  `specrew-turn-end` with no catalog change.

### THE PREDICTION, six parts, each falsifiable

1. **The identity handshake is the failure mode, and it is tested first.** The script and the hook must
   derive the *same* record path or the refusal fires on every compliant turn - strictly worse than what it
   replaces. Prediction: deriving it in ONE shared function that both dot-source makes a mismatch
   impossible, and a test that runs the script and then asks the provider's own resolver returns a
   byte-identical path. **If this fails, nothing else in fix 2 matters.**
2. **Well under a second.** `declare-turn-end.ps1` measured over at least 10 runs, worst case **under
   400 ms**, and **no `git` invocation and no transcript read on any path**. The timing alone does not
   settle it: if any path shells out or opens the transcript, the claim fails regardless of the clock.
3. **Host-neutral.** Zero host names in the script outside the identity value it copies from
   `session-marker.json` - falsifiable by grep for claude/codex/copilot/cursor/antigravity.
4. **Four branches, exhaustive and disjoint**: in-flight -> silent; boundary -> verified against
   `pending-verdict-stop.md`; conversational -> silent; absent with material work by this session -> exactly
   ONE refusal naming the command and its parameters. A read-only second session in the same project
   receives no advisory.
5. **The retirements are real, not shadowed.** After the change, `Test-SpecrewReentryPacketPresent`, the
   STOP-INTENT marker parse and the material-owner baseline attribution have **zero live callers**, proved
   by a tree-wide grep excluding the tests that assert their absence. Attribution becomes the declaring
   session.
6. **(d) closes the receipt hole.** With `present-workshop-question.ps1` writing the projection, the
   candidate scan requiring it, and line 564's punctuation heuristic gone, **a receipt cannot mint without a
   declared question**. That is the direct control on B4F-012's class - the ConsoleFractal specimen's four
   `architecture-core` receipts minted against a refusal, which is not a question anyone asked.

**Fixed in advance**: if (1) fails the build is abandoned rather than patched, because a handshake that can
drift is a refusal engine. If (2) fails, this is a per-turn cost nobody should accept and the design goes
back. If (5) shows a live caller, the retirement is a claim and not a fact.

### PRED-BETA4-011 PART 5: **FALSIFIED.**

**The prediction claimed zero live callers for the retired surfaces; both have live callers and one is a
live bypass.**

Stated as: *"After the change, `Test-SpecrewReentryPacketPresent`, the STOP-INTENT marker parse and the
material-owner baseline attribution have **zero live callers**, proved by a tree-wide grep."* Of the three,
only the first was retired. The independent second pass found the other two live and reproduced both:

- **The STOP-INTENT marker parse is live** at `specrew-conformance-provider.ps1:1611`, and it does not
  merely survive - it **overrides the new requirement**. An `intermediate` classification releases the stop
  with no turn-end record and no named pending item, so the declaration contract is optional for any agent
  that emits the old HTML comment. An alternate old contract, still accepting.
- **Material-owner attribution is live** at lines 885-891 and 1069-1073, still inferring ownership from the
  shared worktree delta and whichever session observes it first. Its probe wrote `owner='claude|reader-A'`
  for an edit session B made. **B4F-049's first member is therefore live in production even after the token
  handshake landed**, which is the part that makes this worse than an unfinished chore.

**What I did wrong, precisely**: I wrote part 5 as a prediction about the finished fix and then reported
progress against a build in which those two retirements had not been done. The grep that would have
falsified it was never run, because I had it filed as owed work rather than as a claim already made. **A
prediction about a later state is not evidence about the current one**, and listing something as "owed" does
not suspend a claim already written down.

**Consequence for the order of work**: the retirements move to the FRONT of the tail, ahead of every test
conversion. A converted test proves nothing about a contract that can be skipped.

---

## PRED-BETA4-012 - fix 3, the clarify refusal. Stated before the code.

**Read from disk first**: `sync-boundary-state.ps1:404` exempts exactly `before-specify`, `specify`,
`feature-closeout`; the `-f` at 407 binds only to the last string of a `+` chain, so `{0}` renders verbatim;
and `pending-verdict-stop-artifact.tests.ps1` both passes `-IterationNumber '001'` AND seeds `iterations/001`
in `New-TestProject`, so the pre-plan state the router-skill crew hit was never exercised by the suite that
covers this script.

### THE PREDICTION, three parts

1. **A clarify sync on a feature with NO `iterations/` directory and NO `-IterationNumber` records the
   crossing.** Falsifiable by a new fixture built without the iteration seed: `pending-verdict-stop.md` is
   written with `specify -> clarify`. Today that fixture THROWS at line 405.
2. **The refusal message renders the path.** For a non-exempt boundary (`plan`) with no iteration, the
   message names the actual `iterations` directory and contains no literal `{0}`. Today it contains `{0}`.
3. **MUTATION**: with `clarify` removed from the exemption again, part 1's fixture goes red and only it.

**Fixed in advance**: if part 1 fails after the change, the exemption is not where the refusal comes from
and I have the wrong line. If part 3 survives, the new fixture is not the pre-plan state I think it is.

**PRED-BETA4-012 VERDICT: all three parts held.** (1) the pre-plan clarify sync records `specify -> clarify`
with no `iterations/` and no `-IterationNumber`; (2) the `plan` refusal names the actual iterations directory
and contains no `{0}`; (3) with `clarify` removed from the exemption, the pre-plan fixture fails and the
older clarify case - iteration seeded, number passed - stays green, which is precisely how the defect shipped
through a green suite since `aa25909b`.

---

## PRED-BETA4-013 - fix 4, the advertised-but-unshipped skill. Stated before the code.

**Decision: DEPLOY, not de-advertise**, and why: the backing script `scripts/internal/user-profile.ps1` is
already in the package FileList, so every consumer install has the functionality and lacks only the entry
point. Removing the advertisement would remove the door to a room that already exists, and leave users
hand-editing `~/.specrew/user-profile.yml` - which is what the beta4 release note currently tells them to do.
The generic deployment route (`squad-templates/skills/<name>.md` -> `specrew-<name>`) is proven by fix 2's
own skill and needs no catalog change.

**Read from disk first**: the skill exists only in `.claude/skills/` (dogfood); it is absent from
`squad-templates/skills/`; and its SKILL.md hard-codes `C:\Dev\Specrew\scripts\internal\user-profile.ps1` at
lines 103, 108 and 112, while line 119 already has the module-resolving form. So it cannot ship as-is.

### THE PREDICTION, four parts

1. After `squad-templates/skills/user-profile.md` is added, `Get-LegacySpecrewSkillDefinitions` enumerates
   `specrew-user-profile` - the deploy surface includes it with no catalog change.
2. The shipped template contains **no** `C:\Dev\` path. Falsifiable by grep.
3. `package-filelist-completeness` passes with the template in the FileList; it FAILS before the entry is
   added, naming the file - which is the guard doing its job.
4. A `deploy-squad-runtime.ps1 -DryRun` into a scratch project lists a would-create action for
   `specrew-user-profile` under every active skill root.

**Fixed in advance**: if (1) fails, the generic route has a filter I have not read and the skill needs a
catalog entry instead; if (4) fails, the template is enumerated but not deployed, and the advertisement
stays a lie.

**PRED-BETA4-013 VERDICT: all four parts held.** (1) `Get-LegacySpecrewSkillDefinitions` enumerates
`specrew-user-profile` as a generic skill scoped to all hosts, 17 definitions total, no catalog change;
(2) zero `C:\Dev` paths in the shipped template; (3) the package guard FAILED naming the file before the
FileList entry and passes after; (4) a `-DryRun` deploy into a scratch project lists 12 would-act lines for
`specrew-user-profile` across the active skill roots.

## PRED-BETA4-014 - finding 1's closure and the timestamp helper. Stated before the code.

**Ruled**: closure 1 (the hook hands the token to the agent at turn start; `declare-turn-end.ps1 -Token`)
with closure 2 (refuse when more than one live token exists, naming both) as the fallback for the ambiguous
case only. Liveness is CONSUMPTION: the hook deletes its session's token at Stop after judging the
declaration, so live means unconsumed.

**Read from disk first, and it changes the build**: the registry row for the conformance provider
(`refocus-scopes.json`) lists `Stop, agentStop, stop, SessionStart, PostToolUse` - **not** `UserPromptSubmit`
or `PreInvocation`. The provider's turn-start lane exists and the tests drive it directly, but the
dispatcher never invokes it at a turn start. Every live token in this project's runtime was issued by
`SessionStart` (`capture_event` on the beside-it baseline, four sessions checked), all carrying `turn-1`.
So in production the token is issued ONCE PER SESSION, not per turn. Consumption at Stop with no
re-issuance at the next turn start would leave every turn after the first with no token - absence on every
declaration. The registry row therefore gains the two turn-start events as part of this build, and that is
B4F-053.

### THE PREDICTION, six parts, each falsifiable

1. **Two sessions, token given**: A and B each hold an unconsumed token; a declaration with `-Token <A>`
   is written under A's directory and stamps A's token, with B's untouched; A's Stop credits it and B's Stop
   does not. Symmetric for B.
2. **Two sessions, no token**: refused - non-zero exit, no record written under either session - and the
   refusal names BOTH session directories and the `-Token` parameter.
3. **Unknown token**: `-Token` with a value no live session holds is refused, non-zero, no record, and the
   refusal names the value it was given.
4. **Stale-token shape**: one unconsumed token left by a dead session plus one live session. Without
   `-Token`: refused (it is the two-live shape from where the script stands). With `-Token <live>`:
   accepted and written under the live session. After the live session's Stop consumes its token, a
   token-less declaration is refused AGAIN for the same reason - the leftover costs every token-less
   declarer a refusal until it is removed, and the refusal names the leftover's path so a human can.
5. **Consumption**: after a Stop that judged the declaration and did not block, the session's token file
   is gone; a Stop that BLOCKS leaves it in place, so the forced re-run of the same turn declares with the
   same token and is accepted. The next `UserPromptSubmit` issues a fresh token only when none is present.
6. **The turn-start line**: at `UserPromptSubmit`/`PreInvocation`/`SessionStart` the provider's stdout is
   exactly one line, under 240 characters, carrying the token and the script path; the dispatcher wraps it
   in the host's injection envelope. The elapsed cost of the extra provider launch at each prompt is under
   one second as run (pwsh startup dominates, as measured for PRED-BETA4-011 part 2).

**The timestamp helper**: one function, `ConvertTo-SpecrewUtcTimestamp`, returns the same instant for the
four shapes JSON can hand back (ISO string, coerced `[datetime]` of Kind Unspecified, `[DateTimeOffset]`,
unix milliseconds) - asserted by a test that feeds all four forms of one instant and expects equality - and
the three sites read through it. The mutation that reverts the cooldown site to the string-cast reparse
turns the cooldown test red on this machine's zone; the helper's own test stays green under that mutation,
which is the point: the helper is right and the site was wrong.

**Fixed in advance**: if (2) is not reachable because the dispatcher's B3 gating swallows the
conformance fragment, the line is being delivered on the wrong path and I have misread `Test-B3ShouldInject`'s
scope (it is written as refocus-only). If (6) exceeds a second, the lane is doing more than a token write and
a print, and the extra work moves out of the turn-start path.

**Visibility of the turn-start line to the HUMAN is measured per host, not predicted**: for Claude Code it
is observed in this session after the deploy; for the other four hosts the host's documented handling of the
injection envelope is cited and marked as documented rather than observed.

### PRED-BETA4-014 VERDICT: four parts held, two missed on a clause each, the helper's part held.

Suites: `turn-end-session-identity.tests.ps1` (rewritten: 47 assertions), `conformance-detection.tests.ps1`
(89, Case 2e added), `timestamp-read.tests.ps1` (new, 24), class-guard lane 16 suites green plus the four
neighbouring conformance suites.

1. **Held.** `-Token <A>` lands under A carrying A's token, B has no record; symmetric for B (Case 1b).
2. **Held.** Two live, no `-Token`: exit 2, no record under either, the refusal names both session
   directories, the parameter, and the `[specrew-turn]` line (Case 1a).
3. **Held.** An unknown token: exit 2, no record, the value named (Case 1c).
4. **MISSED on its last clause.** Refused without `-Token` while both are live, accepted with it, the
   leftover's path and issue time named - all held (Case 2). But after the live session's Stop consumes its
   token, a token-less declaration is **accepted, under the dead session**, because the leftover is then
   exactly one live token and the ruling accepts exactly one. I predicted "refused again"; the ruling's own
   text says otherwise and the build follows the ruling. The record is orphaned (that session's hook never
   runs again), the declarer's own hook finds nothing and refuses at Stop - a refusal, not a false credit -
   and the next turn start re-issues for the live session, restoring the two-live refusal that names the
   leftover. The corner that stays open: a host that issues NO token (absence) sharing a project with a
   crashed token-issuing session declares under the dead session every time and its hook never names the
   leftover. All five hosts issue tokens; absence arises only when the turn-start hook itself did not run.
   Recorded in B4F-053 as the residual; the test pins the ruled behaviour so a change to it is a decision.
5. **Held.** The non-blocking Stop consumes the token; the next `UserPromptSubmit` issues a fresh one and
   the old one is refused by name (Case 3). A blocking Stop keeps it (identity Case 3b, on the evidence-gate
   block; detection Case 2e, on the boundary block) and the forced re-run declares under the same token and
   is credited by the Stop that then consumes it (Case 2e). A second turn-start event for an open turn reuses
   the unconsumed token rather than orphaning the line already handed out (Case 3).
6. **Held on shape, MISSED on the bound.** One line, 200 characters, wrapped by the dispatcher in the host
   envelope (Case 3, Case 5 through the deployed dispatcher). Elapsed as run: **815, 842, 865, 1012,
   1120 ms** over five runs - two of five over a second. The split, in-process: store load 90 ms, turn-delta
   load 8 ms, path resolution 23 ms, **git snapshot 136 ms (T070's live baseline)**, baseline write 34 ms,
   **token write 11 ms**; the provider's own parse and early return 130-220 ms; bare `pwsh` startup
   280-450 ms. The fixed-in-advance clause assumed the excess would be in the lane. It is not: the token
   lane is 35 ms. The cost is the provider process itself - a 2,200-line script launched to do a small
   lane - and the T070 capture that B4F-053 shows was never running at prompt in production. Moving
   either is structural (a dedicated light turn-start provider, or concurrent provider launches in the
   dispatcher) and is named for the maintainer rather than done inside this fix.

**The helper: held.** One instant in four shapes reads equal to the millisecond, under `he-IL` too; a bare
stamp reads as UTC; the three sites read through it and the text assertion proves no site parses on its own.
The mutation (`-MutateCooldown`, the string-cast re-parse restored) reds exactly the two cooldown
assertions on this machine's +180-minute zone and nothing else. One correction to the helper's own comment
from the measurement: the coercion hands back Kind **Local** for a designated string on this pwsh, not
Unspecified; the helper was already right for both and the comment now says so.

**Visibility of the turn-start line to the human, per host** - the envelope is measured; the human side is
what each host documents for that envelope, observed only where this crew could observe it:

| host | turn-start event | envelope the dispatcher emits | reaches the agent | visible to the human |
| --- | --- | --- | --- | --- |
| Claude Code | `UserPromptSubmit` | `hookSpecificOutput.additionalContext` | observed in this session after the deploy (the line arrives in the agent's context on the next prompt) | documented: `additionalContext` is added to the model's context and is not rendered in the transcript; the human sees it only in verbose/transcript view (Ctrl+O). Not observed from the crew's side - the maintainer's screen is the instrument |
| Copilot CLI | `userPromptSubmitted` | `additionalContext` | documented | documented: model-facing; not rendered to the human |
| Codex | `UserPromptSubmit` | `hookSpecificOutput.additionalContext` | documented | documented: model-facing; not rendered |
| Cursor | `beforeSubmitPrompt` | `additional_context` | documented | documented: model-facing; not rendered |
| Antigravity | `PreInvocation` | `injectSteps[].ephemeralMessage` | documented | documented: ephemeral, model-facing; not rendered |

So on every host the line is the agent's, not the human's - which is what it should be: it carries a token
and a command, and a human would gain nothing from seeing it. The human-facing consequence is the opposite
one: a declaration that goes wrong is now refused with a message that names the line, so the human sees the
name of a thing they were never shown. The refusal texts say where it comes from ("the hook hands one out at
each turn start") for exactly that reason.

---

## PRED-BETA4-015 - the census at the final SHA. Stated before the dispatch.

**The SHA**: the branch head at dispatch. Code last moved at `15d702f8`; `79d7585f` and this record are
docs-only. Since the last green census (`d4a89ab7`, run `34354188094`, 2026-09-09) the tree has gained 30
non-docs files: fixes 1-4, the fix-2 tail, the timestamp helper, finding 1's closure and B4F-053's registry
row, and 14 test files (six of them new or rewritten in this arc).

**Before the dispatch, the same sweep the census runs is running locally** - `full-powershell-test-sweep.ps1
-MaxParallel 4 -PerFileTimeoutSeconds 420`, 407 named files, in flight at 75/407 as this is written. It is
run first because the touched-surface pass before it found FOUR census subjects red (three stale tests, one
real regression - `15d702f8`), and a census that reds on something a local sweep would have found spends the
one sanctioned re-dispatch on nothing. **If the local sweep reds, the census is not dispatched until the red
is classified and either fixed or predicted.**

### THE PREDICTION

1. **`full-test-census` green, sweep executed, 407 named files, 0 failures.** All three jobs green
   (`prepublish-validation`, `full-test-census`, `publish-module` in dry-run).
2. **Every one of the 14 changed test files passes on the runner**, including the two rewritten in this
   session (`turn-end-session-identity`, 47 assertions; `timestamp-read`, 24) and `conformance-detection`
   at 89. The identity suite's Case 5 copies the extension scripts into a scratch project and runs the
   DEPLOYED dispatcher; that path has no dependency the runner lacks.
3. **The two timing assertions that were runner-bound at `34346555521`** (byte-unchanged since) pass. If
   either reds AGAIN on the same runner-bound signature and on files byte-unchanged since `d4a89ab7`,
   that is the single sanctioned re-dispatch with its meaning fixed now: green on re-run confirms
   runner-bound and the re-run SHA is the tag SHA; red again is a real blocker, and there is no third run.
   **A red on ANY file changed since `d4a89ab7` is not runner-bound by definition, gets no re-run, and is
   fixed before any further dispatch.**
4. **The diagnostics artifact carries exactly one entry on the green run**: `tests\direct-exit.tests.ps1`
   with `DIRECT-EXIT-SENTINEL`, the known by-product of `full-sweep-direct-exit.tests.ps1` (recorded at
   PRED-BETA4-006's resolution). A second entry is something new and is read before the verdict is
   accepted.

**Fixed in advance**: the tag SHA is the SHA the green dispatch ran on, whatever the branch head has moved
to with records since. Fix 5 is not in this tree and is not what the census measures; it waits on the
maintainer's word.

## PRED-BETA4-016 - the Claude gate-stop skill still teaches composition. Stated before the code.

**Found by the local sweep** (`skill-templates.tests.ps1` red: `turn-end.md` had no YAML frontmatter) and by
reading the template beside it: `gate-stop.md`, the Claude-host boundary-stop skill, still instructs the
agent to COMPOSE the six-section packet, the four typed responses and the marker by hand. Fix 2 made the
script the one renderer and every hook directive name it (B4F-051's loop was two contracts disagreeing);
this skill is the last producer still teaching the old contract, and on Claude it runs at every boundary
stop. The cost is one refusal per boundary stop, forever, on the host most used here.

### THE PREDICTION, three parts

1. `declare-turn-end.ps1 -Kind boundary` at a pending crossing renders the four sendable lines
   (`approved for <to>`, `approved for <to> - <your instructions>`, `changes needed: <what to change>`,
   `discuss prompt 1`) under `## What I Need From You`, above the marker; with `-Owed` it renders the
   FR-024 withhold paragraph in the gate-stop skill's own words ("I am not offering a verdict here ...
   indistinguishable in the ledger from an approval of real work") with NO lines and NO marker. Asserted by
   new cases in `turn-end-update-transition.tests.ps1`.
2. `gate-stop.md` routes the stop through the script - one command, output verbatim - and keeps its
   descriptive contract (what the script renders, the no-selection-affordance ruling, the withhold rule),
   so `gate-stop-skill.tests.ps1` stays green unchanged: its assertions pin the PROPERTIES of the surface,
   and the surface is the same.
3. `skill-templates.tests.ps1` green with `turn-end.md`'s frontmatter; `Get-LegacySpecrewSkillDefinitions`
   still enumerates 17.

**PRED-BETA4-016 VERDICT: all three parts held.** (1) the script renders the four sendable lines under
`## What I Need From You` with the marker as the very last line, numbers the discussion prompts so
`discuss prompt 1` names something, and with `-Owed` renders the withhold paragraph in the skill's words
with no lines and no marker - eleven new assertions in `turn-end-update-transition.tests.ps1`; (2)
`gate-stop.md` routes through the script and `gate-stop-skill.tests.ps1` stays green unchanged (its
mirror-parity case caught the un-synced `.specify` copy first, which is that case doing its job); every
gate-stop copy - template, `.specify` mirror, dogfood `.claude/skills` - is byte-identical and
`withhold-discipline.tests.ps1` is green; (3) `skill-templates.tests.ps1` green, 17 definitions. One
measurement detail: the script's lines end in `[Environment]::NewLine`, CRLF on Windows, so line-anchored
assertions carry `\r?$`.

## PRED-BETA4-017 - the reviewer scaffold's null method call. Stated before the code.

**Reproduced from the consumer** (router-skill, `specs/001-agentic-architecture-skills/iterations/001`,
`-DryRun`): `scaffold-reviewer-artifacts.ps1: You cannot call a method on a null-valued expression`, at line
1347 in `Get-SensitiveTouchpoints` - `(Get-Content -LiteralPath $absolutePath -Raw -Encoding UTF8).ToLowerInvariant()`.
`Get-Content -Raw` on an EMPTY file returns `$null`, and the consumer's changed set contains three
`.gitkeep` files. Every invocation form fails because the sensitive-touchpoint scan runs on every form,
`-DryRun` included, and a `.gitkeep` under a skill's `assets/` is an ordinary shape.

### THE PREDICTION, three parts

1. `reviewer-artifacts.ps1` with an empty file added to the changed set FAILS before the fix with that exact
   message and PASSES after, with the empty file simply contributing no touchpoint.
2. The consumer's iteration, `-DryRun`, gets PAST line 1347 after the fix; whether it completes depends on
   the rest of its shape and is reported as found, not predicted.
3. Four sibling sites of the same class (`deploy-squad-runtime.ps1:1006`, `refocus.ps1:329` and its
   `scripts/internal` mirror, `instruction-file-merge.ps1:42` - all `(Get-Content -Raw).Trim()`) are
   recorded, not fixed here: they read files the product itself writes, none reproduced, and a fix without
   a measurement is the class this record refuses.

**PRED-BETA4-017 VERDICT: (1) held after one fixture correction, (2) held, (3) as stated.** (1) The first
fixture placed the empty file untracked, and the mutation (fix reverted) stayed GREEN - the changed set is
`git diff <baseline>` over tracked paths, so an untracked file never reached the scan and the fixture
measured nothing. Staged, the mutation reds with the consumer's exact message and the fixed code is green;
the digest's `files=` counts moved 4->5 and 6->7 because the fixture has one more changed file, which is what
the digest counts. (2) The consumer's iteration `-DryRun` now completes past line 1347 and lists its
would-create actions - the reviewer artifact set can be scaffolded there. (3) The four sibling sites are in
B4F-057. `feature-017-dashboard-core` is red locally before and after this change (`specrew where` on the
fixture) and is unchanged since the green census; classified with the other worktree/environment-bound reds
at dispatch.

## PRED-BETA4-018 - why the Stop lane never reaches the counter here. Stated before the code.

**Measured, idle machine, this project, the deployed provider**: `Stop` for a session whose orientation
receipt exists takes **28.0 s** direct; through the dispatcher it is killed at the 20 s provider budget -
`WARN PROVIDER_FAILED provider 'conformance' timed out; skipped` - after `last-fire.json` (written at ~1.7 s)
and before the counter step, the token consumption, the journal row, and the navigator (`PROVIDER_BUDGET
... skipped`). That is the reviewer's live measurement explained: consumption and the counter ARE deployed
(`Remove-SpecrewTurnToken` is in the `.specify` copy); the Stop path that steps them is not reached.

**The 20 s, split with markers**: 1.7 s to the block decision; then **21.3 s** between the orientation
lane's guard and `$blockKind`, of which `Get-SpecrewReviewCoverageState` is **20.4 s**, of which
`Get-ContinuousCoReviewReviewedStateDigest` is **19.1 s**: `git add -A` on the seeded temp index is 135 ms,
`Get-ContinuousCoReviewMachineryPaths` 4.3 s, and **the per-path denial loop 14.0 s over 5,792 tracked
paths** - `Test-ContinuousCoReviewDigestPathDenied` called once per path, each call re-resolving the path
comparison and scanning 78 literal machinery paths plus 12 patterns in PowerShell, ~2.4 ms a call. The
digest runs at every MATERIAL stop in any project that has a delivered review campaign and the self-host
engine beside it; consumers do not carry `scripts/internal/continuous-co-review/`, so the coverage state
has no digest there and the lane is cheap - this is the dogfood repo's cost, and it is the repo where every
fix is proven.

### THE PREDICTION, three parts

1. A first-segment PREFILTER in the digest loop - a path is handed to the predicate only when its first
   segment matches the first segment of a literal machinery path or of a `/**` pattern, and every path is
   handed over when any non-`/**` wildcard pattern exists - produces the **identical tree id**
   `5b0513f67acd6336b194584615ad91b81fb80f01` on this repo's current state, and identical ids on the
   engine's own digest fixtures (the `path-identity` and reviewed-state suites stay green unchanged).
2. The digest drops from ~19 s to under 6 s here (the machinery resolver's 4.3 s remains and is named,
   not fixed); the deployed conformance Stop completes under the 20 s budget through the dispatcher, the
   counter steps, the token is consumed, the navigator is no longer budget-skipped.
3. Mutation: with the prefilter's fallback removed (a non-`/**` pattern no longer forces the full scan), a
   fixture with a wildcard denylist pattern such as `*.tmp` reds - the prefilter is only safe because the
   fallback exists.

**PRED-BETA4-018 VERDICT: (1) held; (2) held after a second cut and a cache; (3) held.** (1) The prefilter
produced the identical tree id on the same worktree state, three runs (`eda24cdb...`, `9894770f...`,
`28559f26...` as the tree moved under the session), and the machinery set from the pruned walk is
`Compare-Object`-identical (78 paths). (2) The loop fell from 14.0 s to ~1 s and the marker walk from
4.3-9.3 s to 1.2 s, but the digest still ran 6-12 s and the dispatcher's Stop still timed out - the budget is
20 s for THREE providers, and the handover alone is 5 s on an 18 MB transcript. So a third cut: the digest
is cached by worktree content state - miss 9.5 s, hit 212 ms, `-NoCache` identical. The cache's first home
(`.specrew/runtime`) was wrong and three engine suites said so: on a repository that does not ignore that
directory the cache file appeared in `git status`, a worktree mutation the verification runner refuses and a
change to the very listing the key is built from. It lives in the git directory now (`--git-path`), which is
never in a listing or a tree; the three suites and the new one are green. End to end through the deployed
dispatcher under the 20 s budget: a material Stop with no declaration BLOCKS in 9.9 s with the material
refusal (before this fix, it was killed before deciding anything); after `declare-turn-end -Token`, the Stop
credits it in 8.1 s, the counter steps 8 -> 9 and the token is consumed. What still blocks at that point is
the NAVIGATOR's review gate for the probe session - this repo's own gate, now reachable. (3) The mutation
that drops the wildcard fallback reds exactly the wildcard case and nothing else.

### PRED-BETA4-015, RESTATED FOR THE FINAL SHA

**The SHA**: the branch head after this record's commit - code last moved at `4b247894`. Since
`c166125c` the tree gained: the gate-stop reconciliation and the script's four sendable lines
(`b24e4336`), the reviewer scaffold's empty-file fix (`0be4a6e6`), the self-leak allowlist (`d9e00b95`),
and the review-digest cost fix (`4b247894`). Since the last green census (`d4a89ab7`): 37 non-docs files
and 19 test files.

**The local sweep, done**: 407 files, 16 not passed - 12 TIMEOUTS at 420 s under a four-wide local run
that also had this session's probes on the same machine (every one of them green at `d4a89ab7` on the
runner and unchanged since, except `launch-contract-characterization` which was green alone in this
session), and 4 FAILED: `skill-templates` (fixed, `b24e4336`), `self-leak-lint` (fixed, `d9e00b95`),
`pr-review-integration` (WORKTREE-BOUND: its validator run flags this worktree's uncommitted edits to a
sealed iteration's records - the maintainer's own, present since session start - as
`closed-iteration-edited`; the committed content is unchanged since the green census, so a clean checkout
does not see it), and `validate-governance-changed-only` (FAILED at 1,157 s under load; re-run alone before
the dispatch - its verdict is recorded below before the run id). `feature-017-dashboard-core` is red locally
before and after every change here (`specrew where` on its fixture) and is unchanged since the green census:
environment-bound, classified with `pr-review-integration`.

**The prediction stands as written, parts 1-4, with one amendment to part 2**: the changed test files are
now 19 and include `reviewer-artifacts.ps1` (a staged empty file in its changed set, digests moved 4->5
and 6->7), `turn-end-update-transition` (eleven boundary-render assertions), and the new
`reviewed-state-digest-cost.Tests.ps1` (three cases; the cache lives in the git directory so the runner's
clean checkout sees no status change). **A red on any of these is branch-introduced and gets no re-run.**

**Before the dispatch, the two re-runs**: `validate-governance-changed-only` alone, idle: exit 1 in 741 s -
the explicit `-ChangedOnly -BaseBranch main` case reports `full-repo (base-undetectable)`, so the fixture's
`main` did not resolve in its workspace under this repo's `.scratch`. The subject files - the test, the
validator, `shared-governance.ps1`'s base resolution - are byte-unchanged since the green census, and the
fixture's own git recipe resolves `origin/main` in a clean temp directory here. Classified
ENVIRONMENT-BOUND with the cause not established, and predicted GREEN on the runner's clean checkout; if
it reds there, it is an unchanged file that was green at `d4a89ab7` and gets the single re-dispatch with
its meaning fixed - green confirms environment-bound, red again is a real blocker. `lifecycle-boundary-sync`
alone was still running past fifteen minutes at dispatch (1 PASS so far, no FAIL); unchanged since the green
census, same classification.

## PRED-BETA4-019 - the review round the Stop gate asked for, and the maintainer approved. Stated before the run.

**The gate fired live**: after the digest fix put the Stop lane under budget, the navigator reached its
decision on this session for the first time and asked for a review round - B4F-047's gate, on the repo
where B4F-047 says it is unsatisfiable. The maintainer typed `approved for review round`. The run is the
REPO entry (`scripts/specrew.ps1 review --live --baseline-ref origin/main --host claude --approve-round`),
not the installed alias, because the engine under test is this tree's.

### THE PREDICTION

1. **No campaign is created and no round is spent.** The engine resolves the feature from the lifecycle
   position - `199-beta3-stabilization` at `feature-closeout`, iteration 003, closed - or from the branch's
   own feature `201-first-run-experience`, which has no `iterations/`; either way the campaign's iteration
   binding fails and the command refuses, naming the missing or closed iteration, non-zero exit. This is
   B4F-047 (2) measured on its own subject.
2. **If it does launch**: a live round over the diff `origin/main...HEAD` (30 commits), the reviewer is
   whichever provider the engine resolves on this host, the round is recorded under
   `.specrew/review/authority/campaigns/`, and the findings file is harvested from the file, not stdout
   (the codex-reviewer convention). That outcome falsifies part 1 and is the better one for the release; it
   is recorded as found.

**Fixed in advance**: whichever branch runs, the typed approval is counted as ONE typed authorization
toward B4F-061's measure, and the navigator's block that asked for it is B4F-047's fourth witness either way.

**PRED-BETA4-019 VERDICT: part 1 held in outcome, missed in mechanism.** No campaign was created and no
round was spent: exit 1 in 3 s. But the refusal was not the iteration binding - it was
`review-engine-project-runtime-drifted: marker=b56b0f25...; actual=aa1fa054...; run 'specrew update'`, which
is **B4F-027**, still standing: the review engine reads a runtime marker the extension re-stamp does not
write, and its only named remedy is the update that destroys beta4's deployed tree. B4F-027's `actual=`
was `b56b0f25...` when it was recorded; that value is now the `marker=` side and `aa1fa054...` the actual -
the marker moved once (the deployed extension was re-stamped in this arc) and the engine's expectation did
not follow. The command never reached the iteration binding B4F-047 (2) describes, so that part is
unmeasured, not refuted. `specrew update` was NOT run, per B4F-027. The typed approval is ONE authorization
for B4F-061's count, and the block that asked for it is B4F-047's fourth witness: a gate that asks for a
round the engine cannot run in this project.

## PRED-BETA4-020 - fix 5, reversed: beta4 does not ship with the seal defect. Stated before the code.

**Ruled on measured cost**: after closeout, the next session's resume rewrote the sealed iteration
(`task-progress.ps1` wrote `ready-for-review` at 15:58Z; the capture's advance had written `complete` twenty
minutes earlier) and the session oriented from its own rewrite and asked for a verdict the ledger shows
captured. Three post-seal writers, one illness (B4F-063), on the feature named first-run-experience.

**The rule, scoped for beta4**: an authorized writer touching a sealed iteration re-seals after its write;
an unauthorized writer skips sealed iterations and journals the skip. Authorized: the verdict capture's
advance (`Sync-SpecrewCrossingMirrors`, shared-governance.ps1) and the closeout dashboard render
(sync-boundary-state.ps1) - both seal after writing. Unauthorized: `Update-IterationStateFromTaskProgress`
and `Sync-IterationTaskProgress` (task-progress.ps1) - check the seal and skip. Plus `specrew reseal`,
wrapping `Write-SpecrewIterationSeal` with the precondition and the postcondition printed, and the
trust-hardening refusal naming it. Beta5 carries the deeper ordering: seal at authorization, not at arrival.

**Read from disk first**: the closeout render already seals after itself (FR-031/T022, `sync-boundary-state.ps1`
~2109) - the KeyContextAI drift `added=dashboard.md` is the deployed beta3 order, not this tree's. The
verdict capture's advance does NOT re-seal: `Sync-SpecrewCrossingMirrors` writes state.md and plan.md and
returns. The resume path is `coordinator-resume.ps1:165 -> Get-TaskProgressSummary -> Sync-IterationTaskProgress
-> Update-IterationStateFromTaskProgress`, and neither function looks for a seal. KeyContextAI's iteration
002 today: `checked=True drifted=state.md,retro.md added=dashboard.md`.

### THE PREDICTION, five parts

1. **Closeout -> verdict -> seal intact.** A fixture sealed at closeout, then advanced by
   `Sync-SpecrewCrossingMirrors -AuthorizedBoundary iteration-closeout`: state.md and plan.md move to
   `complete`, and `Test-SpecrewIterationSealIntegrity` reports nothing touched, because the advance
   re-sealed; the seal's `source` names the authorization. Mutation - the advance does not re-seal -
   reds exactly this case.
2. **Resume on a sealed iteration leaves it untouched.** `Get-TaskProgressSummary` on a sealed iteration
   returns the summary from the existing records, writes neither state.md nor tasks-progress.yml (hashes
   identical before and after), and the handover journal carries `sealed-iteration-write-skipped` naming
   the writer. Mutation - the skip removed - reds exactly this case, with state.md's status rewritten to
   the derived value.
3. **A KeyContextAI-shaped fixture** (sealed, then state.md and retro.md edited and dashboard.md added)
   is refused by the validator's trust gate naming `specrew reseal`; `specrew reseal` prints the
   precondition (the drifted, missing and added paths), re-seals, prints the postcondition (nothing
   touched), and the gate then passes.
4. **`specrew reseal` refuses to seal an iteration that has no seal** - it re-seals, it does not seal for
   the first time; closeout does that - and refuses an iteration that is not closed in
   `closed-iterations.yml` or its own state.md; both refusals name what was looked for.
5. **Field proof**: `specrew reseal` on `C:\Dev\SpecrewProjects\KeyContextAI` (`001-layout-autocorrect`,
   iteration 002) prints `drifted=state.md,retro.md added=dashboard.md` as the precondition and
   `touched=0` as the postcondition, and the repo validator's trust gate on that project reports no
   `closed-iteration-edited`.

**Fixed in advance**: if (2) cannot skip without breaking the summary the resume orients from, the summary
is read from the existing files instead of synced - a resume orients from the ledger, it does not write
it. If a project has no `closed-iterations.yml` entry for a sealed iteration, the seal file itself is the
closed marker for (4).

**PRED-BETA4-020 VERDICT: all five parts held, with one shape the test taught.** (1) The advance moves
state.md and plan.md to `complete` and the seal is intact after, `source =
authorized-reseal:crossing-mirrors:iteration-closeout`, journaled; `-MutateNoReseal` reds exactly Case 1's
three assertions. (2) `Get-TaskProgressSummary` on a sealed iteration returns a summary, changes no record
(SHA-256 of every file identical), state.md still `retro`, the skip journaled naming
`task-progress:Sync-IterationTaskProgress`; `-MutateNoSkip` - a SITE mutation, task-progress.ps1's two
guards replaced by `if ($false)` in a temp copy - reds exactly Case 2's four, with state.md and
tasks-progress.yml rewritten, which is the consumer's exact shape. The first draft of that mutation
redefined the shared `Test-SpecrewIterationSealed` helper instead, which also disabled the authorized
re-seal and redded Case 1 - a mutation that hits two sites discriminates nothing; that is why it is a site
mutation now. (3) The KeyContextAI-shaped fixture is refused naming `specrew reseal --feature 001-fixture
--iteration 001`, the verb prints `drifted=state.md,retro.md ... added=dashboard.md` then `touched=0`, the
gate passes after. (4) Both refusals name what they looked for; a call without `--iteration` names the
parameter. (5) Field proof on KeyContextAI, verbatim: gate errors 1 before (`retro.md, state.md,
dashboard.md`); `precondition ... sealed 2026-08-27 21:17:16 UTC by 'iteration-closeout'; drifted=state.md,retro.md
missing= added=dashboard.md`; `postcondition ... touched=0`; gate errors 0 after; the full validator prints
no `closed-iteration-edited` (`iterations_validated=2`). The seal's `sealed_at` is read through the
timestamp helper - the fourth site of PRED-BETA4-014's pattern, caught in the verb's first output, which
printed the coerced [datetime] in the machine's culture.

### PRED-BETA4-015 VERDICT on run `34502784677` (`16febe88`): RED - four files, all four branch-introduced, none runner-bound

`prepublish-validation` success; `full-test-census` failure (408 files, failed=4, `caller_contaminated=False`);
`publish-module` skipped. Part 1 falsified; part 3's runner-bound clause is not reached - no red was on an
unchanged file. Read from the run's own diagnostics artifact, each red classified:

| file | cause, from the record | class |
| --- | --- | --- |
| `every-suite-is-named-by-a-lane` | `reviewed-state-digest-cost.Tests.ps1` was committed with no lane naming it | mine; named in the class-guard lane's Pester list |
| `validate-governance-changed-only` (3 cases) | the fixture's seed commit fails silently and every scoped case reads `base-undetectable`; locally the cause is `.specrew/runtime` copied under `.scratch/` with paths past 260 chars (`git add -A` exit 128, "Filename too long"). With the runtime dir excluded and the seed step proving its commit, the same three cases STILL red - now on the deployed-extension integrity check: the fixture copies this repo's `.specify/extensions/specrew-speckit`, whose marker records hashes for 164 managed files, and nine deployed copies had been synced from source since `1c519b22` without a re-stamp (`refocus-scopes.json`, `confirm-workshop-lens`, `conformance-turn-delta`, `scaffold-reviewer-artifacts`, `shared-governance`, `specrew-conformance-provider`, `validate-governance`, `workshop-authority-store`, `gate-stop.md`). On the runner the committed tree carries the same inconsistency, which is why it redded there too. | mine, twice: a fixture that fails silently, and a marker drift committed nine times |
| `turn-end-update-transition` (7) | the material Stop did not block on the runner; green here in every run, including under the runner's CI environment variables; the suite printed nothing that could say why | mine; unexplained - diagnostics added (the provider's own output, the baseline files, `git status`) so the next run names the cause |
| `turn-end-session-identity` Case 3b (2) | the evidence-gate Stop did not block on the runner; same shape, same disposition | mine; unexplained - diagnostics added |

**Dispositions**: the marker is re-stamped, bounded - 164 entries, 9 hashes changed, nothing else in the
diff, `drifted=0 missing=0`, `specrew_version 0.40.0` intact - the same bounded re-stamp as `1c519b22`, and
the lesson it teaches is recorded: **every sync of a deployed copy must re-stamp**, and a class guard that
checks it is beta5's (the census caught it four commits late). The fixture is repaired. The two turn-end
reds are the honest gap: they were not reproducible here, so the next census is the instrument, and they
carry their diagnosis into it.

**No re-dispatch of `16febe88`**: the tree moves anyway - fix 5 reversed (PRED-BETA4-020) lands before the
next dispatch - so the next census is a NEW prediction on a new SHA, not the sanctioned re-run of this one.

### PRED-BETA4-020, SCOPE CORRECTED MID-BUILD, and the verdict re-run against the corrected scope

**The correction, on what was measured**: the seal at closeout ARRIVAL froze `retro` in; the verdict's
advance wrote `complete` after it; the resume writer wrote `ready-for-review` after it. A seal that freezes
a pre-verdict value is wrong regardless of what follows (the relayed "second iteration cannot start" was an
inference, struck: a plan sync with `-IterationNumber 002` explicit touched nothing in 001). So the rule is
not "authorized writers re-seal" - it is **seal at authorization, as the verdict capture's last act, never
at arrival**; the resume writers skip; `specrew reseal` for the rest. The `Invoke-SpecrewAuthorizedReseal`
half of the first build is gone; `Invoke-SpecrewCloseoutSeal` runs after the advance in
`Add-SpecrewBoundaryAuthorization`, and the arrival sync seals nothing.

**Added prediction (the re-walk's next step)**: closeout arrival -> verdict -> plan sync for the next iteration
-> 001's seal intact; red under seal-at-arrival. **Held**: Case 1b passes; under `-MutateSealAtArrival` it
reds with `touched: plan.md,state.md` - the verdict's own write - which is the consumer's flag, and under
`-MutateNoSkip` it reds with `touched: state.md,tasks-progress.yml` - the resume writer through the plan
sync's `Get-TaskProgressSummary` with the start-context iteration still 001 - which is the consumer's second
witness. Parts 1-5 as previously recorded hold under the corrected scope with Case 1 driven through the real
`Add-SpecrewBoundaryAuthorization` (33 assertions green). `delivery-durability-seal` Case 6, which pinned
T022's arrival-side order, now pins the corrected one: no seal in the sync, the seal after the advance in
the authorization.

## PRED-BETA4-021 - the census at the final SHA, second dispatch. Stated before the dispatch.

**The SHA**: the branch head after this record's commit - code last moved at `ea98457a` (fix 5 at
`0ed113d2` beneath it). Since the red census on `16febe88`: fix 5 (seal at authorization, the resume
writers' skip, `specrew reseal`, the refusal naming it), the deployed marker re-stamped over every mirror
synced since `1c519b22`, the changed-only fixture repaired and its seed step made to prove itself, the
digest suite named by a lane, and diagnostics in the two turn-end suites.

### THE PREDICTION, four parts

1. **`full-test-census` green**: 409 named files, 0 failures; `prepublish-validation` and `publish-module`
   (dry-run) green. The four reds of `34502784677` are each answered above.
2. **The two turn-end suites**: green on the runner. If either reds again, the diagnostics it now prints -
   the provider's own output, the baseline files, `git status` - name the cause in the diagnostics
   artifact, and it is fixed from that output, not guessed at. It is branch-introduced either way and gets
   no re-run.
3. **`validate-governance-changed-only`**: green - the workspace mirrors the tracked tree and the marker
   matches the mirrors, which is the state the runner's clean checkout has.
4. **The diagnostics artifact** carries the one known entry (`direct-exit.tests.ps1`'s sentinel) and no
   other.

**Fixed in advance**: any red on a file unchanged since `d4a89ab7` with the runner-bound timing signature
gets the single sanctioned re-dispatch with its meaning fixed; a red on any changed file is fixed first.
The tag SHA is the SHA the green dispatch ran on.

## PRED-BETA4-022 - a verdict is one line: the capture predicate refuses a message that continues. Stated before the code.

**Read from this repository's own record first**: `.specrew/review/round-approval/pending-round-approval.json`
is a live (`spent_at: null`) review-round approval whose `verdict_text` is 136 lines - a Copilot shell
transcript from the router-skill project, pasted into the reviewer session here with the typed phrase
still at its top. `captures.jsonl` holds it twice: at 18:28:54Z from `UserPromptSubmit` with `IΓ\xc7\xd6ll`
(the UTF-8 bytes of a right single quote read as a code page) and at 18:31:32Z from `Stop` with `I’ll`;
different `response_hash`, so the cross-channel dedupe that exists for exactly this did not fire. The
maintainer's approval for another project, minted in this one. **It is not spent** - the statement in
this session that the approval had been spent was wrong; the approved round refused on B4F-027's marker
before spending anything, and the pending fact is untouched.

**The mechanism**: W56 (DRIFT-199-I001-125) made every authority recognizer decide on the phrase's own
LINE so that "approved for review round" followed by an instruction block would not be refused; the
boundary-verdict recognizer's leading-clause doctrine is the same shape. Both therefore accept a message
whose first line is the phrase and whose remaining 135 lines are anything at all.

**The rule, ruled**: a verdict is the phrase plus at most the documented same-line instruction form; a
message that continues into multi-line content is REFUSED, not minted - and the refusal is disclosed, so
the human retypes one line rather than wondering why nothing happened.

### THE PREDICTION, five parts

1. `Test-SpecrewReviewRoundApprovalPhrase` on the recorded 136-line text returns not-matched with
   `Reason = multi-line-refused`; on `approved for review round` alone, and on `approved for review round -
   run it against 002` (same line), matched as before. The three sibling typed-authority recognizers that
   share the approval-line helper (pause decision, withdrawal, allowance reset) refuse the same way.
2. `Test-SpecrewHumanVerdictToken` on `approved for plan` followed by a line break and any non-empty
   content returns `Action = refused-multi-line`, not an approval; the same phrase with a same-line
   instruction (`approved for plan - keep the API`) is still an approval.
3. The round-approval writer, handed a multi-line message, writes NOTHING - no capture row, no pending
   fact - and appends `authority-refused-multi-line` to the handover journal naming the phrase kind and
   the line count; the boundary capture discloses the same way through the existing not-captured
   disclosure, whose message says to retype the phrase on one line.
4. The recorded specimen, replayed through the writer in a scratch project, is refused - the cross-project
   verdict cannot be minted again.
5. Mutation: the multi-line guard removed from the round-approval recognizer - the specimen mints, the
   suite's Case 1 goes red and nothing else does.

**Fixed in advance**: the pending fact in THIS repository is left as it is - unspent, recorded - because
the product's only void path is the human's own typed withdrawal (`Write-SpecrewApprovalWithdrawal`), and
the maintainer's ruling is never to hand-edit it. The line the product recognizes as a withdrawal is
reported to the maintainer.

### PRED-BETA4-022 VERDICT - held on the recorded specimen; three deviations from the statement, each recorded

**Measured on the record itself** (the 136-line `verdict_text` read from
`.specrew/review/round-approval/pending-round-approval.json`, not a stand-in):
`Test-SpecrewReviewRoundApprovalPhrase` -> `Matched=False Reason=multi-line-refused`; the sweep names
`review-round-approval`, 136 lines, first line `approved for review round`; the writer at
`UserPromptSubmit` and at `Stop` returns nothing and no pending file exists; the one table the hooks call
(`Invoke-SpecrewTypedAuthorityCapture`) mints nothing, writes one drop row (`reason: multi-line`,
`line_count: 136`) and the stderr line; the only files under the scratch project afterwards are the
exhausted-turn ledger and the drops journal. **The cross-project verdict cannot be minted again** (part 4).

**Part 1 - held, with one deliberate deviation.** The withdrawal recognizer is NOT under the rule. It
removes authority; its own doctrine is that a false negative runs a review the human said to stop; a
multi-line refusal there would fail open. The coverage-deferral recognizer (shared-governance's local
copy) IS under it, which the statement did not name. **Part 2 - held.** **Part 3 - held, journal renamed**:
the drop goes to `.specrew/runtime/authority-capture-drops.jsonl` as `authority-phrase-matched-but-rejected`
with `reason: multi-line`, the ledger and event the partial-signoff override already uses for "the phrase
matched and was then rejected", written ONCE per turn from the capture table rather than per writer; the
boundary path journals `verdict-not-captured-disclosed` with `action: refused-multi-line` and its sentence
is branched so it does not blame the first line. Both disclosures reach the turn through the prompt-entry
provider's inject stdout (Cases 4b, 6, 7).

**Part 5 - the mutation, as measured.** The statement said "Case 1 goes red and nothing else does"; it was
written before the cases were designed, and the guard is read by more than one. With
`Test-SpecrewAuthorityMessageContinues` answering "no" to everything (the pre-fix build), the in-suite
control (Case 6) mints the specimen into a 136-line `verdict_text` in a child process - the record,
reproduced. **The whole-suite run under that mutation, on the committed tree (`5017d004`)**: 7 red -
Case 1, Case 2 (the two store siblings; the shared-governance deferral copy stays refused), Case 4, Case 4b,
Case 6 (its anchor is gone), the reversed W56 case, the UNCONDITIONAL control; Case 3, W75 and Case 5
green - exactly the cases that read the guard, as predicted before the run. **The boundary-path guard
removed** (`Test-SpecrewHumanVerdictToken`): 2 red in the suite (Case 3, the reversed W75 case) and
`capture-disclosure` Case 6's six disclosure assertions red; its "crossing stays un-authorized" assertion
stays GREEN, because `Add-SpecrewBoundaryAuthorization` already refused the multi-line text with
`VERDICT_CAPTURE_FAILED ... did not parse into an authorized boundary verdict` - on the boundary path the
pre-fix defect was silence, not a mint (B4F-065 records it).

**What the test caught that the build did not**: the first guard called the static
`[regex]::Split(text, pattern, 2)` - the `2` is a `RegexOptions` there, not a count - so it examined line
two only. The recorded specimen was refused anyway (line two is `Thought for 1s`) and every part above
would have "held"; W56's reversed blank-line case (phrase, blank line, block) went red and named it. A
prediction that held on the specimen alone would have shipped a guard that any paste with a blank line
after the phrase walks through.

### PRED-BETA4-021 VERDICT - census 34518281283 on `25f3dfaa`: RED, 3 files, all mine, each read from its own output; superseded by ruling

`prepublish-validation` green; `full-test-census` red on 3 of 409; `publish-module` skipped. **Part 1 did not
hold. Part 2 held in the way that mattered**: the two turn-end suites redded again and their new diagnostics
named the cause - `WARN ASSESSMENT_UNAVAILABLE the conversation accessor could not be loaded; enforcement for
this stop was skipped (fail-open)`. The provider resolves `scripts/internal/bootstrap` from the project tree,
then `SPECREW_MODULE_PATH`, then an installed Specrew module; a fixture has no bootstrap dir, the runner has
no installed module, this machine has one. That is why the suites were green here on both censuses and red
there on both: an environmental resolver, not a timing signature. `conformance-detection.tests.ps1` - green
on the runner - has always pinned `SPECREW_MODULE_PATH` to the repo root for exactly this reason; the two
suites now do the same. **Part 3 held** (`validate-governance-changed-only` green). **Part 4**: the artifact
carried the three, not the sentinel alone.

The third red, `sealed-iteration-writers` Case 3: `drifted=retro.md,dashboard.md,state.md` on the runner
against an assertion written for `state.md,retro.md,...` - the seal manifest's enumeration order is the
filesystem's. The assertion compares the set now.

**What was NOT proven locally, said plainly**: a runner simulation that hid the installed module by editing
`PSModulePath` was INERT - a child `pwsh` re-adds the user module path at startup - so the committed suites
passed under it and it discriminated nothing. What is proven in-process: the resolver, extracted from the
provider's AST and called with the module hidden and the variable unset, returns nothing; with the pin it
returns the repo's bootstrap dir. The runner is the discriminator for the green, and by ruling this census
is superseded: the next one, after fix 6, is the one that counts.

## PRED-BETA4-023 - fix 6: one derivation of the plan sync's target iteration. Stated before the code and before either fixture runs.

**Verbatim from the router-skill project**: the plan-boundary sync run as `-BoundaryType plan -IterationNumber
002` reports `boundary_record_status: established` for 002 and, in the same invocation, WARNs
`CROSSING_NOT_MINTED_OWED_ARTIFACTS_ABSENT - 'plan' owes plan.md for iteration 003 (expected under
...iterations\003) and it does not exist`. One invocation, two derivations of the target iteration.

**Read from the code, not from memory - where the second derivation lives**: the sync writes the session
cursor at `$effectiveIterationNumber` (002) through `Update-SpecrewStartContext`, THEN calls
`Set-SpecrewPendingBoundaryCrossingScope`, which reads `session_state.iteration_number` (002, just written)
and hands it to `New-SpecrewPendingCrossingScope` -> `Test-SpecrewBoundaryOwedArtifactsOnDisk`. That check
carries its own rule: "iteration-closeout -> plan opens the NEXT iteration", `$iteration + 1` -> 003. The
rule was written for the closeout AUTHORIZATION's rebind (`Add-SpecrewBoundaryAuthorization`), where the
cursor still sits on the CLOSED iteration (001) and the crossing it opens is for the next one (002). Applied
to the plan sync, whose cursor already names the target, it overshoots by one. Both callers pass "the
cursor"; the check cannot tell which one it was handed; so it guesses, and guesses right for one caller.

### The answer to the fixture question, stated BEFORE the run

**Does the check target 003 in fixture (a) - 001 closed and sealed, 002 scaffolded through
`scaffold-iteration-plan.ps1` in the product's own order, then the plan sync for 002?** YES. The +1 is
applied to the value the sync itself just wrote; nothing about who scaffolded 002 or when enters it. The
defect is universal to every second-and-later iteration's plan sync, not a consequence of the pre-scaffold
the maintainer instructed on the router-skill project. **Fixture (b)** (the router-skill shape, 002 scaffolded
before the sync) targets 003 too, and adds a second consequence: if the closeout authorization's rebind had
already minted the closeout -> plan crossing (002/plan.md existed at authorization), the plan sync's
constructor returns `$null` on the refusal and OVERWRITES `pending_crossing` with null - the sync destroys
the crossing the verdict opened.

### THE FIX, scoped

`Test-SpecrewBoundaryOwedArtifactsOnDisk` derives nothing: the iteration it is handed IS the iteration the
entered stage owes. `New-SpecrewPendingCrossingScope` - the one gated constructor every minting path goes
through - resolves the target ONCE, from a fact the record carries: when the crossing being opened is
iteration-closeout -> plan and the crossing's WORKING boundary is iteration-closeout (the cursor still on
the closed iteration: the authorization's rebind, or a closeout re-sync), the target is cursor + 1; when the
working boundary is plan (the plan sync has moved the cursor), the cursor is the target. The sync derives
nothing of its own; the value it recorded is the value the check reads.

### THE PREDICTION, four parts

1. **Fixture (a)**, before the fix: the plan sync for 002 exits 0, reports 002 established, WARNs
   `owes plan.md for iteration 003`, and leaves `pending_crossing` null. After the fix: exits 0, no WARN,
   `pending_crossing` = `iteration-closeout -> plan` with `working_boundary: plan`, and the journal carries
   no `crossing-mint-refused` row naming 003.
2. **Fixture (b)**, before the fix: the closeout authorization mints closeout -> plan (002/plan.md exists);
   the plan sync for 002 then WARNs on 003 and nulls the crossing. After the fix: the crossing survives the
   sync - same `from`/`to`, `working_boundary` now plan - and no WARN.
3. **The closeout authorization's own path is unchanged**: with 002 NOT scaffolded, the rebind still refuses
   naming `plan.md for iteration 002` (the FR-024 gate, correct target); with 002 scaffolded, it mints.
   `clarify-refusal-names-the-form` and `gate-preflight` (the check's other readers) stay green.
4. **Mutation** (`-MutateIndependentDerivation`: the +1 restored inside the check, in a temp copy of the
   module tree the sync wrapper resolves through): fixtures (a) and (b) both go red on 003, and part 3's
   "correct target" assertions - which the +1 happened to satisfy - stay green, which is why the mutation
   is of the check and not of the constructor.

**Then**: a module build from the fixed SHA for the router-skill machine - install only, no `specrew update`
there; the sync wrapper resolves through the module. The census on `25f3dfaa` is superseded; the next one is
the one that counts. PRED-BETA4-009's closeout-to-second-iteration extension has its second witness.

### PRED-BETA4-023 VERDICT - held; the fixture question answered by the run: universal

**RED-FIRST, on the unfixed tree** (`8dcedca8` + the scaffolder repair only): 10 red. Fixture (a) - the
product's own order - `refusals: 002,003`: the rebind named 002 (correct), the plan sync named 003, no
crossing minted. **So the answer to the question stated before the run is YES: the check targets 003 in
(a) too; the defect is universal to every second-and-later iteration's plan sync, not a consequence of the
instructed pre-scaffold.** Fixture (b) - the router-skill shape - the rebind minted closeout -> plan
(`working_boundary: iteration-closeout`), the plan sync named 003 and nulled it.

**Parts 1-3 held after the fix** (25 green): (a) exits 0, records 002, asks for nothing, mints
`iteration-closeout -> plan` with `working_boundary: plan`; (b) the verdict's crossing survives the sync
with the working boundary moved to plan; the rebind still refuses naming 002 with plan.md absent and mints
with it present. The journal event is `crossing-not-minted-owed-artifacts-absent` (the statement wrote
`crossing-mint-refused`; a naming slip, the assertion reads the real one).

**Part 4, one deviation**: the mutation reds (a) and (b) on 003 as predicted - 13 red - and ALSO the
rebind's "names 002" assertions, which the statement said would stay green. They cannot: with the +1
restored in the check and the constructor's derivation in place, the authorization's rebind derives twice
(001 -> 002 -> 003). The statement reasoned from the old code, where the check's +1 was the only one. The
compounding is the measurement that the derivation now has exactly one home; a mutation that left the
rebind green would mean it had two.

**Found on the way** (B4F-067): the scaffolder failed on a one-FR spec before either fixture could run;
fixed alongside, the fixture's spec is the test.

**Next**: the module build from the fixed SHA for the router-skill machine (install only, no `specrew
update` there); the census that counts is the one after this.

**PRED-BETA4-023 FIELD WITNESS** (router-skill project, maintainer's relay, 2026-09-11): through the module path
alone - the project's deployed extension still at `d4a89ab7`, the installed module at `6f1bdaa7` - the identical
plan sync that had targeted 003 minted the `iteration-closeout -> plan` crossing for 002 on the first re-run
after the install. The fix reaches a consumer without `specrew update`, which is the deployment shape the
timeline requires.

## PRED-BETA4-024 - fix 2 item (c): the review advisory is scoped to the declaring session's material. Stated before the code.

**Read from the record and the code, not from memory.** Item (c) was scoped in B4F-047 (3): "attribution
becomes the declaring session, and a read-only second session in the same project receives no advisory.
Its test is in the fix-2 tail." What was BUILT under that heading is the conformance half only:
`conformance-detection` Case PH-ms - a read-only session that declares conversational is not billed for the
other session's surface by the CONFORMANCE provider (order 40). The review advisory the reviewer session has
now received seventeen consecutive times - `Specrew review - these files have not been reviewed yet` - is
the CO-REVIEW NAVIGATOR's campaign stop block (order 50, `worktree-navigator.ps1`: `Build-ReviewCampaignNavigatorStopBlock`
on every route but review-current/review-running/pause-pending), and it has no session in it anywhere: the
provider takes `--host-kind` and `--transcript-path`, never `--session-id`, and blocks every Stop in the
project while the tree's digest is unreviewed. **(c) was never built for the review advisory. The field is
right; no fixture contradicts it because none exists.**

**The design, one handshake, no inference**: the conformance provider already judges THIS session's
declaration at Stop and steps its turn counter afterwards. It now leaves that judgment beside the counter,
in the session's own state root - `turn-material.json`: `{ turn_id, declaration_kind
(conversational|in-flight|boundary|absent), material, judged_at }` - before the counter steps. The navigator
provider (which runs AFTER it, by the dispatcher's order) receives the same `--session-id` the dispatcher
already passes to every provider, resolves the same state root through the same `Get-SpecrewTurnEndPaths`,
and reads the judgment: a session that declared **conversational**, or declared nothing and was judged
**not material**, gets NO campaign stop block this Stop; in-flight, boundary, or absent-with-material gets
it as today; a `pause-pending` route is never quieted (an unanswered pause is the human's decision owed,
not a file attribution); a judgment that is not THIS Stop's (turn id not current or current-1, or older than
120 s) is ignored and today's behavior stands. The decision carries its `route` so the provider can tell.

### THE PREDICTION, five parts

1. **The conformance provider writes the judgment.** `turn-end-session-identity` Case 3: after the Stop that
   accepted a conversational declaration, `turn-material.json` under S3's state root reads
   `declaration_kind: conversational`, `turn_id: turn-1`, `material: false`; Case 3b (a blocking Stop, no
   declaration): `declaration_kind: absent`.
2. **The read-only second session receives no advisory**, through the REAL conformance provider and the
   navigator provider in the dispatcher's order: session A declares conversational, its Stop runs
   conformance then the navigator (a stub navigator that always returns the `review-required` block, in a
   temp module tree the provider resolves through) -> no `<<<SPECREW-STOP-BLOCK>>>` on stdout, and the
   navigator journal says `quiet (session declared conversational)`. Session B, same project, declares
   in-flight -> the block. That is the field shape: seventeen advisories after seventeen accepted
   conversational declarations become zero.
3. **The block still fires where it should**: no judgment on disk (a host that never ran conformance) ->
   block; judgment absent-with-material -> block; boundary -> block; `pause-pending` -> block even for the
   conversational session; a stale judgment (turn id two behind, or `judged_at` 10 minutes old) -> block.
4. **Nothing else in the navigator changes**: `continuous-co-review-navigator.Tests.ps1`,
   `campaign-stop-authority`, `advisory-names-the-humans-act`, `deployed-mirror-parity`,
   `conformance-detection` (PH-ms included) and `turn-end-session-identity` stay green.
5. **Mutation** (`-MutateUnscoped`: the provider's gate replaced by `if ($false)` in the temp copy): part 2's
   session-A assertions go red - A receives the block - and nothing else does. Part 3's cases are the
   positive controls naming their paths.

**Fixed in advance**: if part 2 stays green under the mutation, the stub is not the path the field takes and
the test proves nothing about the reviewer session's seventeen. If the field test - the reviewer session's
next Stop on the module built from this SHA, after an accepted conversational declaration - fires an
eighteenth time, the fixture contradicts the field and the tree is not final.

### PRED-BETA4-024 VERDICT - held; one under-count in part 5, recorded

**Part 1 held**: Case 3 reads `{turn_id: turn-1, declaration_kind: conversational, material: false}` and the
counter reads turn-2 afterwards; Case 3b reads `absent` for the turn the counter still names. **Part 2
held**: through the real conformance provider and the navigator provider copy over the stub, the reviewer
session (declared conversational) gets nothing and the journal says `quiet ... session declared
conversational`; the working session (declared in-flight) gets the block; the reviewer still gets nothing
afterwards. **Part 3 held**, every path: no judgment, absent-with-material, boundary, pause-pending against
the conversational session, a wrong turn id, a ten-minute-old judgment, no session id - all block; and
absent-and-not-material is quiet (a read-only session on a host without declarations). **Part 4 held**:
`conformance-detection` (228 s, PH-ms included), `turn-end-update-transition`, `turn-end-session-identity`
(52), `continuous-co-review-navigator` (36), `campaign-stop-authority` (22), `advisory-names-the-humans-act`
(17), `deployed-mirror-parity`, `ProviderMirrorParity`, `hook-event-coverage`, `package-filelist-completeness`,
`every-suite-is-named-by-a-lane` - green.

**Part 5, under-counted**: the mutation reds 5, not 3 - the reviewer session's three AND the two quiet
positive controls in part 3 ("declared nothing, judged not material: quiet"; "the same conversational
judgment is quiet again once the pause is gone"). They are the same gate, and the statement should have
counted them. Nothing outside the gate moved.

**Found on the way**: `ConvertFrom-Json` hands an ISO timestamp back as a local-kind `[datetime]`; the
freshness read now converts that to a UTC instant rather than round-tripping it through a culture string.

**Field test owed**: the reviewer session's next Stop on the module built from this SHA, after an accepted
conversational declaration. That, not this suite, is what settles (c).

## PRED-BETA4-025 - PRED-BETA4-015 restated for the final SHA, third dispatch. Stated before the dispatch.

**The tree is called final** at the branch head after this record's commit. Since `25f3dfaa` (census 2,
superseded by ruling): the one-line verdict rule (`5017d004`, B4F-065), the census-2 answers (`ccef2492`:
the turn-end suites pin `SPECREW_MODULE_PATH`, the reseal precondition compares a set), fix 6 (`6f1bdaa7`,
B4F-066/067, field-witnessed on the router-skill project through the module path alone), and fix 2 item (c)
for the review advisory (`d0312a4a`, B4F-068), each with its prediction stated first and its verdict
recorded. The tag SHA is the SHA the green dispatch ran on.

### THE PREDICTION, four parts

1. **`full-test-census` green**: every named file, 0 failures; `prepublish-validation` and `publish-module`
   (dry-run) green. The three reds of `34518281283` are each answered from their own output (PRED-021
   verdict): the two turn-end suites now resolve the bootstrap dir through the pin, the seal suite's Case 3
   compares a set.
2. **The two turn-end suites green on the runner** - this is the part no local run could discriminate (the
   runner simulation was inert; the in-process resolver probe is what stands). If either reds again, its
   diagnostics name the cause and it is fixed from that output; no re-run.
3. **The four suites added since census 2 green on the runner**: `plan-sync-target-iteration` (the real sync
   wrapper through `SPECREW_MODULE_PATH`), `review-advisory-session-scope` (the real conformance provider
   over a stub navigator), the extended `round-approval-typed-authority` and `capture-disclosure`. Each ran
   green here; each pins the module path the runner lacks.
4. **The diagnostics artifact carries the one known entry** (`direct-exit.tests.ps1`'s sentinel) and no other.

**Fixed in advance**: a red on a file unchanged since `d4a89ab7` with the runner-bound timing signature gets
the single sanctioned re-dispatch with its meaning fixed; a red on any changed file is fixed first and the
tree is not final. **Separately owed and not settled by this census**: the reviewer session's next Stop
after an accepted conversational declaration, in a checkout whose deployed extension carries `d0312a4a`
(the gate lives in the deployed providers, not in the module) - an eighteenth advisory means the tree is
not final regardless of the census.

## PRED-BETA4-026 - B4F-043's third consumer instance: a verdict typed with no crossing pending gets one line back. Stated before the code.

**Read from the code**: `Get-SpecrewVerdictCaptureDisclosure` (HandoverStore.ps1) returns `$null` the moment
`HasPendingVerdict` is false, and returns `$null` when the pending crossing's phrase is not in the text - so
`approved for before-implement` typed before the tasks -> before-implement crossing was minted was silent
(the router-skill project, three retypes in one day), and `approved for plan` typed while tasks ->
before-implement is pending is silent too. The audible standard already exists one file over: "a phrase
that matched and was then rejected is a human trying to authorize something, and their attempt must never
vanish" (the partial-signoff override, DRIFT-199-I002-034). It is extended to the boundary family in that
one function: a verdict-shaped reply (`Test-SpecrewHumanVerdictToken` says approval and names a boundary)
with no pending crossing gets one line back naming what is pending, or that nothing is, and the last
authorized boundary; a verdict-shaped reply naming a boundary OTHER than the pending crossing's gets one
line back naming the pending crossing. Both journal `verdict-not-captured-disclosed` with `action`
`no-pending-crossing` / `other-boundary-named`. Ordinary conversation still produces nothing.

### THE PREDICTION, four parts

1. No pending crossing, last authorized `tasks`, human types `approved for before-implement` at prompt entry:
   the disclosure reads "NOT recorded ... no crossing is pending ... the last authorized boundary is 'tasks'
   ... send it again when the crossing is presented"; journaled with `action: no-pending-crossing`; the
   ledger is unchanged. Through the provider, the same sentence reaches the inject stdout.
2. Pending `tasks -> before-implement`, human types `approved for plan`: the disclosure names the pending
   crossing (`tasks -> before-implement`) and the phrase that would authorize it; `action:
   other-boundary-named`; the ledger is unchanged.
3. Silence where silence is right: no pending crossing and ordinary prose (`What is the status?`) -> nothing;
   no pending crossing and a send-back (`changes needed: ...`) -> nothing. Cases 1-7 of `capture-disclosure`
   stay green.
4. Mutation (the two new branches removed): parts 1 and 2 go red, nothing else.

### PRED-BETA4-026 VERDICT - held; the fixture had to be the consumer's shape

**Parts 1-3 held**, with one thing learned on the way: the first no-pending fixture kept the cursor one
boundary ahead of the last authorization (`before-implement` over `tasks`), and `Get-SpecrewPendingVerdictState`
derives a LEGACY crossing from that gap - so a verdict there was a clean approval, not a lost one, and the
new branch never ran. The consumer's shape is the cursor still AT the last authorized boundary, the next
sync not yet run; with that fixture the disclosure fires, names `tasks` and the retype, journals
`no-pending-crossing`, and reaches the inject stdout. Part 2 (`approved for plan` against a pending
`tasks -> before-implement`) names the pending crossing and its phrase. Silence controls green. **Part 4**:
the two branches removed -> 8 red (Cases 8-9's disclosure assertions; the two silence controls and the
ledger checks stay green, as they should).

**PRED-BETA4-023, field note**: fix 6 held at plan, tasks and before-implement on the router-skill project,
each sync minting its crossing, extension still at `d4a89ab7`.

### PRED-BETA4-025 VERDICT - census 34533964445 on `19ec5d0c`: RED, one file, mine, branch-introduced, fixed from its own output

`prepublish-validation` green; `full-test-census` red on **1 of 410**: `timestamp-read` Case 5, "the turn-end
store contains no timestamp parse of its own" - the class guard for the timestamp helper caught a
`[DateTimeOffset]::Parse` I put into `Test-SpecrewTurnMaterialVerdictQuiet` (fix 2 item (c)) reading
`judged_at`. Branch-introduced on a changed file: fixed first, no re-run - the read now goes through
`ConvertTo-SpecrewUtcTimestamp` like every other read in that store (timestamp-read 21, session-scope 24,
identity 52 green; the (c) mutation still 5 red). It did not show locally because that suite was not in
the consumer list I ran for (c); the runner ran everything, which is what a census is for.

**Part 1 did not hold** (one red). **Part 2 HELD**: both turn-end suites green on the runner for the first
time since `16febe88` - the `SPECREW_MODULE_PATH` pin was the cause, as the diagnostics said. **Part 3 held**
for the three suites that ran unchanged: `plan-sync-target-iteration`, `round-approval-typed-authority`,
`capture-disclosure` green on the runner; `review-advisory-session-scope` green too. **Part 4 held** (the
artifact carried the one red and nothing else). `19ec5d0c` is not the tag SHA; four fix commits landed
after it anyway (B4F-070/071/072). The next census runs on the head after this repair.

## PRED-BETA4-027 - PRED-015 restated for the head after the census-3 repair, fourth dispatch. Stated before the dispatch.

Since `19ec5d0c`: B4F-043's third instance (`eaf98a4f`), rule 1's sentence (`205ee340`), the ledger-printed
readiness verdict line (`5901096e`), and the census-3 repair (`cd16e987`). The prediction is PRED-025's,
with part 1 narrowed to what changed: **`full-test-census` green, 411 named files, 0 failures**;
`timestamp-read` green on the runner (the store has no parse of its own again); the four suites added since
census 2 and `readiness-verdict-line` green; `prepublish-validation` and the dry-run publish green; the
diagnostics artifact carries the sentinel and nothing else. A red on any changed file is fixed first; the
single sanctioned re-dispatch is reserved for a runner-bound red on a file unchanged since `d4a89ab7`. The
tag SHA is the SHA the green dispatch ran on.

## PRED-BETA4-028 - R1: an authority check never trusts a cache; a metadata key is not tree equality. Stated before the code.

**From the independent review** (`~/AppData/Local/Temp/specrew-beta4-review-ebb7597f.md`, GPT-6 Astra, out
of engine, against `v0.40.0-beta3..ebb7597f`): the digest cache I added for B4F-057 keys on HEAD, the
exclusions, the porcelain listing and each listed file's length and mtime. Repro A: `core.filemode=false`, a
staged file, `git update-index --chmod=+x` - porcelain, bytes, size and mtime unchanged, index mode changed,
tree identity changed, cache returns the old id. Repro B: same-length content with the mtime put back - the
key cannot see it. And `Get-ContinuousCoReviewSignoffGateDecision` (the authority) consumed the cached read.

**Measured before deciding**: the pruned walk did most of B4F-057's work - the direct computation on the
self-host repo is now 2.2-2.8 s (was 18-37 s); the cache saves ~2 s per read. So the cache can leave every
authority path without re-breaking the Stop budget.

**The fix, as ruled**: the digest is DIRECT by default. A new `-AllowCache` switch opts in, and only the
advisory Stop-hook path passes it: the navigator's campaign packet decision at Stop, the navigator's
older-tree note, the checkpoint identity, and the conformance provider's coverage line. The signoff gate,
the campaign orchestrator, the evidence recorder, the verification-plan runner, the review CLI, the
validator and every other reader compute the identity. The key gains the index mode of every listed entry
regardless (`git ls-files -s` on the listed paths), so Repro A cannot fool the advisory path either; Repro B
remains what a metadata key cannot see, which is why no authority reads it.

### THE PREDICTION, four parts

1. **Repro A**: after `--chmod=+x` on a staged file under `core.filemode=false`, the default read and the
   `-AllowCache` read both return the new id (index mode is in the key), equal to each other and different
   from the id before the chmod.
2. **Repro B**: same-length content, mtime restored: the default read returns the new id; the `-AllowCache`
   read returns the STALE id - stated, journaled nowhere, tolerated only because nothing authoritative reads
   it.
3. **The gate**: `Get-ContinuousCoReviewSignoffGateDecision` (or the packet decision with the cache off) reads
   the tree directly - a Repro-B change after a cache fill produces a decision whose `current_tree_id` is the
   direct id.
4. **Mutation**: `-AllowCache` restored on the gate's digest call - part 3 goes red; the three existing
   cost-suite cases and parts 1-2 stay green.

## PRED-BETA4-029 - R2: readiness has a cycle, not an ordinal. Stated before the code.

**From the review**: `readiness-verdict.ps1` compared ordinal lifecycle positions, so iteration 001's
`iteration-closeout` (later in the list than `before-implement`) read as authorization for iteration 002's
implementation: "READY for implementation" with the last authorized boundary `iteration-closeout` and
`iteration-closeout -> plan` pending. Fix 6's class - no cycle identity - in a script written after fix 6.

**The fix**: readiness derives from authorization for the CURRENT feature and iteration. `iteration-closeout`
as the last authorized boundary never satisfies a readiness question for a later iteration: when the ledger's
last authorization is `iteration-closeout`, the current cycle has no authorizations yet, and readiness is
BLOCKED naming that. Within a cycle the ordinal comparison stands (`review-signoff` after `before-implement`
is still READY for it).

### THE PREDICTION, three parts

1. The reviewer's product-order fixture (closeout 001 through `Add-SpecrewBoundaryAuthorization` -> scaffold
   002 through the scaffolder -> the real plan sync for 002 -> readiness): BLOCKED, naming that the last
   authorization is the previous iteration's closeout and that `iteration-closeout -> plan` is pending.
2. The four existing cases keep their answers (tasks -> BLOCKED; before-implement -> READY; review-signoff
   -> READY; plan -> BLOCKED).
3. Mutation: the ordinal comparison restored - part 1 goes red, parts 2 stay green.

### PRED-BETA4-028 VERDICT - held

Parts 1-2 held on the reviewer's shapes as suite cases (Repro A: direct and advisory agree on the post-chmod
tree, different from before; Repro B: the advisory read is stale, the default read is not - the limit,
stated). Part 3 held in the form the record can hold cheaply: the class guard enumerates the advisory sites
and reds on any other `-AllowCache`, and the gate file's two authority reads are asserted direct. Part 4
held: `-AllowCache` restored on the gate's digest call reds the guard (1 of 6); the mode dropped from the key
reds Repro A (1 of 6); the three prior cases and the other new ones stay green. The reviewer's own fixtures,
replayed against the fix, agree between direct and advisory on the ids the review quoted as direct.

### PRED-BETA4-029 VERDICT - held

Part 1 held on the reviewer's exact steps, run on `plan-sync-target-iteration` fixture (a) and on the
reviewer's retained fixture: BLOCKED, "the last authorization is the previous iteration's closeout; this
iteration has no authorization yet; the pending crossing is 'iteration-closeout -> plan'". Part 2 held: the
four existing cases keep their answers (Case 1's wording assertion now accepts "authorized through 'tasks'"
for the cursor-only legacy ledger). Part 3 held: the ordinal comparison restored reds the cycle case in the
line suite and the product-order case in the plan-sync suite, nothing else.

## PRED-BETA4-030 - PRED-015 stated for the FINAL SHA, fifth dispatch, by ruling. Stated before the dispatch.

The tree is final at the branch head after this record's commit: `ebb7597f` plus the independent review's
R1 and R2 (`35d5e86e`, B4F-073) and the coordinator-template mirror sync that the release-model mirror check
demanded. Census 4 (`34538115842`, on `ebb7597f`) is superseded by this one and is read when it lands, not
re-run. The module installed on this machine is built from this SHA, and the router-skill project updates
ONCE, to this build - that update is the turn-end contract's field test.

### THE PREDICTION

1. **`full-test-census` green**: every named file (411), 0 failures; `prepublish-validation` and the dry-run
   publish green. Since `ebb7597f`: the digest is direct by default with the index mode in its key (31
   targeted suites green here, `conformance-detection` 279 s included), readiness has a cycle, the
   coordinator mirror is synced (`release-model` green here; it was red at `5901096e`-`ebb7597f` and census 4
   will show it).
2. **The diagnostics artifact carries the sentinel and nothing else.**
3. **The install**: `install-local-build.ps1` from this SHA stamps the module with this commit, byte-verified.

A red on any changed file is fixed first and the tree is not final. The single sanctioned re-dispatch is
reserved for a runner-bound red on a file unchanged since `d4a89ab7`. The tag SHA is the SHA the green
dispatch ran on.

**PRED-BETA4-030, part 3 held before the census landed**: `install-local-build.ps1` from `ef80591d` packaged
423 files, byte-verified, stamp `ef80591d` / `c8f4f3de…` in `…\Modules\Specrew .40.0` (was `6f1bdaa7`).
The router-skill project's one `specrew update` to this build is the turn-end contract's field test.

### PRED-BETA4-027 VERDICT - census 34538115842 on `ebb7597f` (superseded): RED, 2 files, one cause, already fixed in the final SHA

`boundary-commit-discipline` and `release-model` both red on the same fact: the coordinator template's
deployed mirror (`squad-templates/coordinator/specrew-governance.md`) was not synced when `5901096e` added the
verdict-line rule to the source. Found locally on the same day by the R1 consumer run (`release-model`),
synced in `35d5e86e`, which is in `ef80591d`; `boundary-commit-discipline` re-run here: green. Read, not
re-run; census 5 on `ef80591d` is the one that counts. Everything else on the runner - 409 files - was green,
including `timestamp-read` after the census-3 repair.

## PRED-BETA4-031 - R2 follow-up: readiness reads EFFECTIVE scoped authority, never raw history. Stated before the code.

**From the follow-up review** (`~/AppData/Local/Temp/specrew-beta4-followup-d8be7878.md`): the cycle loop I
wrote for R2 iterates `$state.State['verdict_history']` - the raw ledger, which deliberately retains
approvals a scoped correction invalidated - while `last_authorized_boundary` came from `EffectiveState`.
Reproduced through the real correction API: effective authority `tasks`, effective approvals none,
readiness READY. Fixture retained at `beta4-corrected-01be1aa7…`; replayed here before the fix: READY.

**The fix, one line**: the cycle is derived from `$state.EffectiveState['verdict_history']` - the projection
`Get-SpecrewEffectiveBoundaryEnforcementState` already computes for every other reader - so an invalidated
approval is never recovered from immutable raw history.

### THE PREDICTION

1. The correction-API reproduction as a suite case (a historical `tasks -> before-implement` approval, the
   current scoped crossing, a scoped invalidation through `Add-SpecrewBoundaryAuthorizationCorrection`
   resulting in `tasks`): effective verdicts 0, readiness BLOCKED.
2. The reviewer's retained fixture, replayed: BLOCKED.
3. Every existing readiness case (seven) keeps its answer.
4. Mutation - the raw ledger read restored: part 1 red, nothing else.

### PRED-BETA4-031 VERDICT - held

The correction-API reproduction is a case in `readiness-verdict-line` (25 green): before the correction the
approval is current and readiness is READY (control); after `Add-SpecrewBoundaryAuthorizationCorrection`
invalidates it for the scoped crossing - effective authority `tasks`, effective approvals 0, raw history still
1 - readiness is BLOCKED. The reviewer's retained fixture (`beta4-corrected-01be1aa7…`) replayed: BLOCKED,
"this iteration's cycle is authorized through 'tasks'". The seven existing cases keep their answers;
`plan-sync-target-iteration` and `boundary-correction-ledger` green. Mutation - the raw read restored - reds
the correction case and nothing else.

**Local full sweep, informative (ran while the R1/R2 tree was being edited; `caller_contaminated=True`)**:
3 red of 412 - `boundary-commit-discipline` (the coordinator mirror, since synced), `validate-governance-changed-only`
(green on re-run), and `pr-review-integration`, which runs the validator on THIS repository and now meets
`closed-iteration-edited` on the maintainer's uncommitted `specs/199…/003` edits before it reaches the soft
warning it looks for - an environment fact of this worktree, green on every census's clean checkout.

## PRED-BETA4-032 - PRED-015 stated for the final SHA, sixth dispatch, after the R2 follow-up. Stated before the dispatch.

The tree is final at the branch head after this record's commit: `ef80591d` plus the R2 follow-up
(`a1696673`, one product line and its case). Census 5 (`34542233608`, on `ef80591d`) is superseded and read
when it lands. The prediction is PRED-030's with part 1 unchanged in substance: `full-test-census` green,
every named file, 0 failures; `readiness-verdict-line` at 25; `prepublish-validation` and the dry-run publish
green; the artifact carries the sentinel only. The module is reinstalled from this SHA, byte-verified, and
the router-skill project updates once, to this build.
