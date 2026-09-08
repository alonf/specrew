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
