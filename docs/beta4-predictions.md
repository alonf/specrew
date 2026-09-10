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
