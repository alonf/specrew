# Drift Log: Iteration 003

**Schema**: v1
**Total drift events**: 18 (DRIFT-199-I003-001 through -018)
**Resolution rate**: 3 resolved this session; 1 open to beta4 as a class fix; 2 recorded as evidence and
lessons rather than defects

> **Why iteration 002's late findings live here.** 002 is closed and sealed, and the seal's entire worth is
> that nothing gets added. This batch settled the question the hard way: when the 001 hardening-gate erratum
> was written into the sealed directory, the validator refused it and named the ACTIVE iteration as the
> right home (DRIFT-199-I002-015). New facts about a closed iteration belong to the open one. That precedent
> was recorded by this session and then violated by it an hour later — see DRIFT-199-I003-006.

---

### DRIFT-199-I003-001 — iteration 002's FR-030 cycle fix, field-proved by this iteration's first plan sync (POSITIVE CONTROL EVIDENCE)

**This iteration's first record is the proof of its predecessor's fix, and that is deliberate.** 003 is not
a throwaway: it is the iteration beta4 opens anyway, whose first act happens to be the one place that proof
can be taken.

- **The measurement, taken before any interpretation:**

  ```
  store state going in : last_authorized_boundary = iteration-closeout
  plan mirror BEFORE   : **Status**: planning
  plan mirror AFTER    : **Status**: planning
  sync output          : no warning, no refusal, no error
  ```

- **Why this is the condition that mattered.** Round 3 graded `cycle-reset-mirror-wedge` **blocking**: the
  truth gate replayed the GLOBAL last-authorized boundary into the current iteration, so a new iteration's
  first plan sync — while the store still named the PREVIOUS iteration's `iteration-closeout` — wrote its
  plan scaffold forward from `planning` to `complete`. The mirrors are forward-only, so nothing moved it
  back, and the next `tasks` sync rejected it. Every next-iteration cycle wedged, deterministically, against
  an acceptance bar whose own words name a wedged gate.
- **Why this is stronger than the replay that found the fix incomplete.** The pre-tag replay
  (`tools/smoke/greenfield-cycle-replay.ps1`) **seeded** `last_authorized_boundary`. Here it arrived through
  fourteen recorded verdicts and a genuinely sealed 002; the scaffold came from the governed
  `scaffold-iteration-plan` path; the sync was the governed wrapper. **Nothing was staged.**
- **What it does not prove.** Only the first plan sync of a new cycle. The `tasks` sync that would reject a
  `complete` plan mirror has not run here, because no work has happened in 003.
- **Resolution**: resolved. The fix carried a named gap — replay-proved, not field-proved — through
  review-signoff, the retro and the closeout, and the maintainer made 003's plan sync a gating step before
  the tag precisely so the gap would close before shipping rather than after. It closed.
- **Class closure**: `tests/integration/cycle-reset-mirror.tests.ps1` guards the behaviour and is
  mutation-proved on both the writer cap and the checker cap. This entry adds the field observation the
  suite cannot supply.

### DRIFT-199-I003-002 — the iteration seal can never capture the final mirror state (open; beta4 class fix)

**Structural, not incidental**, and it is three of this batch's own pieces meeting:

1. The **seal is written inside the closeout sync** (T022's fix moved it after the dashboard render).
2. The **closeout verdict lands after that sync, by definition** — the sync produces the packet the verdict
   answers.
3. **T021 advances the mirrors on that verdict.**

So the authorization that completes the closeout necessarily changes two files the seal has already hashed.
**Every closeout on beta3 drifts by exactly `plan.md` and `state.md`.** This is DRIFT-199-I002-038's window
(artifact precedes authorization) composing with T021's mirror advance under T022's guard.

- **Measured on 002's closeout:**

  ```
  at seal time : plan.Status=retro     CurrentPhase=retro              IterationStatus=ready-for-review
  after verdict: plan.Status=complete  CurrentPhase=iteration-closeout IterationStatus=complete
  drifted      : plan.md, state.md
  ```

  The values after the verdict are **correct** — 002 is complete. Only the seal's snapshot is stale.
- **Resolved for 002 by a deliberate re-seal** through `Write-SpecrewIterationSeal` (the engine's own
  writer, never a hand edit), journalled to `.specrew/runtime/authority-repairs.jsonl`. **The re-seal holds**,
  and that was verified against the writers rather than assumed: `Get-SpecrewCrossingMirrorMap` shows
  `iteration-closeout` is the highest row (`complete` / `iteration-closeout` / `complete`), `feature-closeout`
  maps to `$null`, and `sync-boundary-state.ps1:912` and `:947` exclude `feature-closeout` from re-mirroring.
  Nothing later touches these files. Result: `drifted=0`.
- **Two alternatives rejected, each in one line.** Reverting the records to their sealed values would make
  them **false** to satisfy a checksum, inverting the honest-state rule the checksum exists to serve.
  Leaving it drifted is the 153-line lesson: **a standing alarm everyone learns to ignore is worse than no
  alarm.**
- **BETA4 CLASS FIX, two candidate shapes recorded and neither chosen tonight**:
  - **exclude the derived mirror lines from the seal manifest** — sealing a derived value binds the seal to
    state that authorization must change; or
  - **re-stamp the seal at crossing write**, so the last writer is the sealer.
  Decided there, not here: **the asymmetry rule says the seal writer is the irreversible side**, and an
  unreviewed change to it risks more than the noise it removes.
- **Release note**: beta3 ships the known issue — after the closeout verdict the seal reports 2 drifted
  mirror files; re-seal through the engine's writer once the verdict has landed.
- **Class closure**: NONE here — the fix is a beta4 design choice between two shapes, and picking one inside
  a tag batch is the shape this batch has repeatedly ruled against.

### DRIFT-199-I003-003 — T018's field evidence, located precisely, with the recovery path NOT claimed

**Written after a measurement of the wrong directory nearly retracted a true finding.**

- **WHERE IT IS**: `C:\Temp\ConsoleFractal-stranded-backup` — **not** `C:\Temp\ConsoleFractal`. A reader
  checking the original finds `workshop: {}`, two receipts and **zero** lens-phase receipts, and correctly
  concludes nothing was closed there. **Cite the backup path or the citation is worse than none.**
- **What the backup durably supports**, read from its artifacts:
  - the fixed machinery is present — `confirmed-complete` appears five times in the transition table and
    `confirm-intake-lens` is in the writer;
  - **11 receipts, 9 lens-phase, all `architecture-core`**, latest `2026-08-30T15:37:54Z`;
  - the controller records `architecture-core` with **`moved_on: True`**, `confirmation: human-confirmed`,
    `confirmation_scope: lens-question`, and the receipt under **`human_turn_receipt`**;
  - `workshop/architecture-core.md`, `workshop/product-domain.md`, `workshop/product-domain.yml` written.
- **FIELD-PROVED: the `confirm-lens` path and both FR-027 contract fixes.** The entry carries
  `human_turn_receipt` — the canonical name round 1 found the writer had spelled `turn_receipt` — and a
  `confirmation_scope` taken from the receipt rather than from a table in the writer. **Both round-1 fixes
  are visible in a real project's durable record**, which is stronger evidence than the round-trip suite
  that proves them.
- **NOT CLAIMED: the recovery path (`confirm-intake-lens` from `confirmed-complete`).** The controller lists
  **only** `architecture-core`; there is no `product-domain` workshop entry, which is the one artifact an
  intake close through the writer would leave.
  - **And the behavioural argument does not rescue it.** It is tempting to reason that the walk "proceeded
    past a state both operations refused before the fix" — but closing `architecture-core` from
    `confirmed-complete` was **never** blocked; `confirm-lens` has always been allowed from that state. What
    the deadlock blocked was `product-domain`, and that is precisely the closure with no durable record.
    **The observed closure is one the pre-fix code also permitted, so it evidences nothing about the
    recovery path.** Precision over generosity.
  - The recovery path stays **mutation-proved only** (case 7c). Its field proof would be a `product-domain`
    entry appearing in a controller whose agenda is already confirmed.

### DRIFT-199-I003-004 — two byte-similar project directories side by side: proposal 136's Shape 6, as a class rather than an error

- A field-proof claim was measured against `C:\Temp\ConsoleFractal` and found unsupported — correctly, for
  that directory. The session that produced the evidence had run in `C:\Temp\ConsoleFractal-stranded-backup`.
  **The measurement was right, the universal claim drawn from it was wrong, and the missing fact was which
  directory the session ran in.**
- **This is proposal 136's Shape 6 family.** That proposal is motivated by a measured incident — an
  instruction pasted into the wrong project's shell *"because identical-looking PowerShell prompts gave no
  visual cue which Specrew session was active"* — with the maintainer's own assessment recorded there:
  *"It is going to happen a lot, since we are using multiple shell windows concurrently."* Two directories
  differing by a `-stranded-backup` suffix, in one parent, are the same hazard one layer over: **no visual
  differentiation at the moment of attention-switching.**
- **The walk got lucky, and the record says so**: the backup carried the same fixes, so the session
  exercised the code under test. Had the backup predated the fix, the walk would have produced a field proof
  of the wrong machinery and nothing would have contradicted it.
- **Filed as a class**: the countermeasure is not "be careful which directory" — that is the workaround
  proposal 136 exists to replace. It is Layer 0 visual differentiation, plus the local habit this incident
  demonstrates: **an evidence claim must name its absolute path, because in prose two paths differing by a
  suffix read as one place.**
- **Class closure**: NONE — the guard is proposal 136's, out of this batch's scope. The local practice is
  applied in DRIFT-199-I003-003.

### DRIFT-199-I003-005 — a measurement is valid at its instant; a claim about state other writers still touch must be re-measured after the last writer (two instances, same week, both self-caught)

- **Instance 1 — the tripwire.** Its thresholds were evaluated against figures that were true when read, and
  the wire's own firing could not be verified because it was an instruction in a plan note rather than
  machinery.
- **Instance 2 — the seal.** `drifted=0` was measured immediately after the closeout sync and **was true at
  that instant**. It drifted afterwards, when the verdict advanced the mirrors, and the snapshot was
  reported as a standing property without re-measuring after the last writer ran.
- **The lesson, stated once for both**: a measurement is a statement about an instant. Turning it into a
  claim about state requires knowing that no further writer will touch that state — and in a system where
  authorization itself writes, the last writer is often the one that lands after the report.
- **Both were caught by the same method** the rest of this fortnight's real findings were: running the thing
  again rather than trusting the earlier reading.
- **Class closure**: NONE as an executable guard — no check can assert that a claim was re-measured. The
  operational form is the one the seal case now demonstrates: **re-check after the verdict, not after the
  sync.**

### DRIFT-199-I003-006 — the seal caught its own author editing sealed records, an hour after that author recorded the precedent it enforces (POSITIVE CONTROL EVIDENCE)

**The sharpest entry on the positive ledger, and the seventh.**

- **What happened.** Corrections to T018's and T017's evidence lines were written directly into iteration
  002's `drift-log.md` and `review.md` — a **closed, sealed** iteration. The validator refused with
  `closed-iteration-edited`, naming all four affected files.
- **By the same session that had recorded the precedent.** DRIFT-199-I002-015 records the 001 erratum being
  refused from the sealed directory and the validator naming the ACTIVE iteration as the right home. That
  entry was written by this session, roughly an hour earlier. **The rule was known, written down, and cited
  — and not applied.**
- **Reverted, not worked around**: `git checkout -- specs/.../002/`, and the corrections now live here,
  which is where the precedent said they belonged all along.
- **Why it is positive evidence rather than an error report.** The control did the whole job: it refused, it
  named every affected file, and its message named the correct destination so the recovery needed no
  invention. **A seal that only refused its author's opponents would be worth much less than one that
  refuses its author.**
- **The companion sentence, earning itself again**: *writing a rule down does not make you apply it — the
  only detector that has worked is running the subject.* Here the subject was the validator, and running it
  is the only reason the sealed records are intact.
- **Class closure**: the seal and the `closed-iteration-edited` check ARE the closure and already ship. What
  this adds is the record that they fired on their own author, which is the property that makes a control
  worth its cost.

### DRIFT-199-I003-007 — a closed iteration fails its own validation, for the second time in one feature (open; beta4 owns it, and this is its second occurrence)

**DRIFT-199-I002-015 said this would happen again. It happened again, to the iteration that recorded it.**

- **On closing, 002 immediately produced two findings it had not produced while running:**
  1. *"Complete iterations must record a Completed date in plan.md"* — 002's plan has none.
  2. *"hardening-gate.md still requires runtime evidence or explicit closure follow-through for concern(s):
     security-surface, error-handling-expectations, retry-idempotency-requirements, test-integrity-targets,
     operational-resilience-concerns"* — the planning-time posture, unchanged since before implementation.
- **Neither can be repaired.** Both live in `specs/.../002/`, which is sealed. Editing either is the
  violation the seal refused an hour ago (DRIFT-199-I003-006). **A complete iteration is held to a higher
  bar than a running one, and it acquires that bar at the exact moment it becomes unable to change.**
- **This is the identical shape 001 produced**, recorded then as: *a verification plan that names a specific
  iteration goes stale the moment the next one opens; the closeout should re-point it.* Beta4 was given the
  item. **Nothing in beta3 changed, so 002 reproduced it exactly** — which is the instance-not-class pattern
  once more, this time visible as a prediction that came true inside the same feature.
- **What was done, following 001's precedent rather than inventing a remedy**: the verification plan is
  re-pointed at the ACTIVE iteration (`iteration-003-governance`, `plan_id f199.i003.slice.v1`), and 002's
  two findings are dispositioned here rather than in the sealed directory. 003 validates clean.
- **What is NOT done**: 002's hardening-gate concerns are not given a runtime-evidence disposition here. 001
  received one as an erratum, and the same treatment for 002 is honest work that belongs with a decision
  about whether the closeout should produce it automatically — which is the beta4 item.
- **The Completed date is a real gap in 002's record**, not a validator artefact: a complete iteration
  should carry its completion date. It cannot be added without breaking the seal, which is itself the
  argument for the beta4 fix — **the closeout should write it before sealing, since afterwards nobody can.**
- **Class closure**: NONE — the fix is the beta4 item DRIFT-199-I002-015 already filed, now with a second
  measured occurrence and a sharper statement: **a closeout must write everything a complete iteration will
  be judged on BEFORE it seals, because after the seal the iteration cannot answer any new question asked
  of it.** That is the same root as DRIFT-199-I003-002's seal-ordering defect, one level up: the seal is
  taken before the state it must certify is final.

### DRIFT-199-I003-008 — the reviewer accepted accumulated incremental proofs in place of a final walk on the shipping artifact, and one question caught it (open until the tag-candidate walk runs)

- **The correction, and its attribution.** Every row in the tag's evidence table was earned on an
  **intermediate build**. No proof in it was taken against the artifact that would actually ship. The crew
  assembled five field-proved rows across three days and presented them as the tag's evidence; **the
  maintainer asked one question — has anything been walked on the final bits — and the answer was no.**
- **The second half of the same question, and it is the sharper one.** `confirm-intake-lens` — the recovery
  path, and **the first path every greenfield user executes** — has never succeeded in the field **on any
  build**. The backup walk's controller carries no `product-domain` entry, so what it proved was
  `confirm-lens` only. That is the path whose absence deadlocked every new project before the fix, and it is
  the one with no field evidence at all.
- **T018's row is corrected accordingly**: `confirm-lens` and both FR-027 contract fixes are field-proved
  (`C:\Temp\ConsoleFractal-stranded-backup`); **the intake close is unproven in the field on every build to
  date**, not merely unproven on the tag candidate.
- **Fourth instance this fortnight of the cheapest instrument outperforming every layer above it**, and the
  first where it fired BEFORE the mistake rather than after:
  1. the engine's own integrity check, against a wrong finding the crew had argued convincingly;
  2. a fresh project on the accused host, against a wrong host-regression diagnosis;
  3. a mutation that produced zero failures, against a guard that reimplemented its subject;
  4. **one question about the shipping artifact, against an evidence table nobody had disputed.**
  Three of those were corrections after the fact. This one prevented the publish.
- **What accumulated proofs actually establish**: that each fix worked when it was written. What they cannot
  establish is that the assembled artifact works — which is the same distinction this batch already recorded
  twice, as *mutation proving shows a control is wired to its own test, not to the system*, and as *a
  fixture writes the precondition the product denies*. **Here it is one level up again: incremental proofs
  show the parts worked at the moment each was proved, not that the shipped whole works now.**
- **Resolution**: **RESOLVED 2026-09-01.** The tag-candidate walk ran and passed - see
  DRIFT-199-I003-015. The build was prepared and verified (commit `4f4dce52`, content `21c05ad9...`, 414
  files byte-verified, stamp verified against installed contents); the walk directory
  `C:\Temp\beta3-tagwalk` was confirmed not to exist beforehand and is visually distinct from every
  neighbour, which mattered after DRIFT-199-I003-004. **The question this entry records - has anything been
  walked on the final bits - now has the answer it did not have: yes.**
- **Class closure**: NONE yet — the durable fix is a release-gate step requiring a walk on the tag-candidate
  build before publish, which is beta4's greenfield smoke path (already prototyped at
  `tools/smoke/greenfield-cycle-replay.ps1`) promoted into the release lane and extended to cover intake.
  Naming it here so the next tag does not depend on someone asking the question again.

### DRIFT-199-I003-009 — the Copilot walk: six behaviours field-proved on a third host, and none of them closes the publish gate (POSITIVE CONTROL EVIDENCE)

**Third host, and the first field evidence on Copilot for any of this batch's work.** Recorded as evidence;
the standing gaps below are recorded with equal weight, because this walk substitutes for neither.

- **What ran clean**, per the maintainer's field report:
  1. **The positional-binding refusal fired correctly** — an agenda array was refused *at the door* rather
     than landing in `-Confirmation`. That is DRIFT-199-I002-029's second half proved in the field: the
     `ValidateSet` used to catch this loudly while naming the wrong parameter, and `PositionalBinding =
     $false` now reports the failure where it happens. The deployed writer carries the marker twice.
  2. **A mangled binding value was restored to its readable hyphenated form** in the re-record — the
     name/value asymmetry refusal doing its job with a human acting on it correctly, which is the outcome
     the reworded message was written for.
  3. **Five `confirm-lens` closures ran clean**, with the acknowledgment line on every reply — FR-028 (T019)
     field-proved, five times, on a host that had never exercised it.
  4. **Reviewer selection followed INT-006 end to end**, with the authorization written by the command
     rather than by hand.
  5. **The stub-then-spec ordering held** — FR-029 (T020) proved on a third host.
  6. **The specify packet's marker carries its crossing identity** — FR-024's binding (T014/T015) visible in
     a real packet on a third host, not only in this repository's own boundaries.
- **LANDED 2026-08-31**: the specify verdict was captured from the typed turn, so **typed-turn verdict
  capture is now field-proved on all three hosts** - claude, codex and copilot. That is the mechanism the
  whole boundary model rests on: an approval is authorization only because a hook read the human's own
  typed words out of the transcript. It had two hosts' evidence this morning. **Both packets rendered on
  this host also carried their crossing identity in the marker** (FR-024), so the capture attached to the
  crossing the controller had recorded rather than to an inferred one.
- **What this walk does NOT do**, stated with the same emphasis as the passes: **it does not touch
  `confirm-intake-lens`.** Five `confirm-lens` closures are five exercises of the path that already had
  field evidence. The intake close remains at zero field executions on every host and every build.
- **Class closure**: none needed — this is evidence, and the controls it exercises already ship with their
  guards. Its value is host diversity: three of these six behaviours had field evidence on exactly one host
  before today.

### DRIFT-199-I003-010 — the specify gate reads product-domain from its records and receipt, never from the controller entry: the records-versus-controller split in a third reader (open; one beta4 line)

**Verified at source rather than assumed**, on the maintainer's instruction to check whether the specify
preflight could pass while a controller carries no `product-domain` entry. It can, and here is why:

- `design-analysis-gate.ps1:460` iterates **`$selected`** and demands a `workshop` record for each id.
  **`product-domain` is never in `selected`** — the agenda catalog excludes it by construction
  (`confirm-workshop-agenda.ps1:148`), which is the whole of DRIFT-199-I002-027. So the loop that would
  demand a controller entry never asks about the intake lens.
- The gate checks product-domain by two other routes instead:
  - **its typed-turn RECEIPT** — `Get-SpecrewWorkshopAuthorityReceipt ... -Phase 'product-domain'`
    (line 447), refusing with *"product-domain has no typed human reply receipt; Ctrl+O/dismissal is not
    delegation"*;
  - **its ON-DISK record** — `specs\<feature>\workshop\product-domain.yml` (line 1061) for the
    load-bearing research-needed block.
- **So a project can pass the specify preflight with the records present, the receipt present, and no
  controller entry at all** — which is precisely the state the stranded ConsoleFractal was in.
- **The class, and why it is one line rather than a batch item**: this is the **records-versus-controller
  split** already recorded twice — the agenda confirms from on-disk records
  (`confirm-workshop-agenda.ps1:131-139`) while the controller entry stays absent, which is how a project
  reaches `confirmed-complete` with an unclosed intake lens (DRIFT-199-I002-027's stranded case). **This is
  a third reader on the records side of the same split.** Each reader is individually correct; together they
  mean the controller entry is optional for every gate that matters, which is what let the stranded state
  exist unnoticed.
- **Not a defect in this gate.** Reading the receipt and the record is arguably the *better* check — it
  verifies the human's typed turn and the artifact, rather than a derived marker. The beta4 question is
  whether the controller entry is authoritative for anything, and if not, why the writer maintains it.
- **Resolution**: OPEN, **one beta4 line**, filed with the arbitration work beside DRIFT-199-I002-038: decide
  which of the controller entry and the on-disk records is authoritative for intake, and make every reader
  consult the same one.
- **Class closure**: NONE — picking the authoritative side is a contract decision, and this batch has
  repeatedly ruled against making those inside a tag batch.

### DRIFT-199-I003-011 - the clarify gate refused a correct record and named nothing; and the validator that "passed" never looks at clarify at all (FIXED at the refusal; the validator gap is one beta4 line)

**Two findings from one field observation on the Copilot walk, and they are not the same finding.** Both
were verified at source on the maintainer's instruction rather than accepted from the report.

**Finding A - the refusal named neither the expected form nor the mismatch (FIXED, guarded).**

- **What the gate actually requires**, read from the contract rather than inferred:
  - `Boundary clarify`, `Kind content`, `Paths {spec.md}`, `MarkerMatch any`, two markers:
    - `(?ms)^##[ \t]+Clarifications ... ^###[ \t]+Session[ \t]+\d{4}-\d{2}-\d{2}` - the dated session block
      the governed clarify flow writes;
    - `(?im)^[ \t]*[-*][ \t]+\*\*Clarify Disposition\*\*[ \t]*:[ \t]*skip\b[^\r\n]{20,}` - a recorded skip
      whose reason is at least 20 characters.
- **What the human saw**: `spec.md required content`. A hand-authored, semantically-correct zero-question
  `## Clarifications` record was refused, and the message named neither what was expected nor what did not
  match. The only move left is trial and error, and that is what the walk did: it ran the validator, got a
  pass, and re-ran the governed flow until the canonical evidence appeared. **The requirement is a pair of
  regexes; a human cannot be asked to read them, and nothing else told them.**
- **This is DRIFT-199-I002-029's standard - name the thing that actually failed - applied to a content
  contract**, which is where the batch had not applied it. Fixed at cause: the contract now carries a
  consumer-facing `AcceptedForms` describing both accepted shapes in prose (including the 20-character
  minimum, which is invisible in the regex), and the refusal renders them plus the sentence that the
  human's file is fine and nothing they wrote is lost.
- **The contract is NOT weakened.** The same unrecognised record is still refused; only the message
  changed. Guard: `tests/unit/clarify-refusal-names-the-form.tests.ps1`, which asserts the refusal still
  fires, that it names both forms, and that each named form actually satisfies the contract - so the
  message can never describe a shape that would fail. **Mutation-proved**: disabling the `AcceptedForms`
  lookup turns 5 assertions red.

**Finding B - the validator passed because it never looks at clarify (OPEN, one beta4 line).**

- **NOT the DRIFT-199-I002-038 family.** That family is two readers with jointly unsatisfiable
  requirements. This is simpler and, for a reader, worse: **`validate-governance.ps1` contains ZERO
  mentions of `clarify`, `Clarifications`, or `Clarify Disposition`.** It did not disagree with the sync
  gate; it never examined the boundary.
- **Why that is worse than a disagreement**: a disagreement is visible - two messages contradict and
  someone investigates. Silence reads as assurance. "The validator passed" is the sentence that ended the
  walk's investigation and sent it to trial and error, and it was true and irrelevant at the same time.
- **Class**: this is the coverage-versus-verdict shape - a checker's green means "nothing I check is
  broken", and the human reads "nothing is broken". The hook-event-coverage work (T024) fixed exactly this
  for hook health by making the report state its own coverage. **The validator has no such statement.**
- **Resolution**: OPEN, one beta4 line - either extend the validator to the boundary content contracts, or
  have it state which boundaries it does not examine. Not in this batch: extending validator coverage
  before a tag would change what a green validator means on the tree that ships.
- **Class closure**: the pinned fact is guarded (case 3 of the suite above asserts the validator's silence
  on clarify, so a future reader cannot mistake this for a disagreement) but the gap itself is not closed.

**Why this fix exists inside a publish hold - an instruction collision, owned by the maintainer.**

- **The two instructions.** The clarify relay said *"fix the refusal to name the expected form"*. The
  message that followed it said *"hold all fixes"*. The first was followed, and the maintainer's ruling is
  that following it was correct: **the collision is theirs, recorded here as theirs.**
- **Recorded because a later reader would otherwise reconstruct it wrongly.** A product change landing
  during a hold, with no note, reads as an agent that ignored a hold - the most damaging possible
  misreading of this record, and one the artifacts alone cannot refute. It was not that. It was two
  instructions in sequence that could not both be satisfied, and the earlier one was acted on before the
  later one existed.
- **What this batch already knows about it.** Sequencing is the batch's recurring human-side failure mode -
  four typed approvals were spent on one signoff because *my* sequencing put commits between the request
  and the approval (DRIFT-199-I002-036's neighbourhood). This is the same shape from the other side, and it
  is worth the symmetry: **the instruction stream is a shared artifact, and either party can order it into
  a contradiction.** Neither instance was carelessness; both were ordinary work moving faster than the
  record of it.
- **No control proposed, deliberately.** Nothing can machine-detect that two natural-language instructions
  conflict. What is available is what happened here: the conflict is named, attributed, and the work is not
  quietly re-classified to fit whichever instruction won.

### DRIFT-199-I003-012 - the clarify boundary requires an iteration that a LATER boundary creates: an accidental owed-artifact, confirmed accidental from the refusal's own remedy text (OPEN; fix identified, held for a ruling)

**The maintainer asked whether this owed-artifact is intended for clarify or accidental. It is accidental,
and the proof is inside the refusal itself.**

- **What happened in the field**: the clarify boundary sync refused to render its packet until
  `iterations/001/` existed, on a feature that had only just been specified.
- **The mechanism**, at `scripts/internal/sync-boundary-state.ps1`: every boundary must resolve an
  iteration number unless it is in the exclusion list `@('before-specify', 'specify', 'feature-closeout')`.
  **`clarify` is absent from that list.**
- **It is accidental, on three independent readings:**
  1. **The refusal contradicts itself.** Its own remedy sentence says *"Create the iteration first (the
     plan boundary scaffolds `iterations/001/`)"* - and **plan comes AFTER clarify**. A boundary is
     demanding an artifact that only a later boundary produces. No intended requirement can be satisfied
     only by running past the gate that demands it.
  2. **Clarify is feature-level everywhere else.** Its content contract is `feature-file` scoped to
     `spec.md`; it writes nothing under `iterations/`; and it is absent from the truth gate's
     iteration-scoped boundary list. Only this one exclusion list disagrees.
  3. **The neighbours it belongs with are already excluded.** `before-specify` and `specify` are the two
     boundaries that precede iteration scaffolding, and clarify sits between `specify` and `plan` - in the
     same pre-iteration window, and by the same reasoning.
- **The fix is one list entry** (`clarify` added to the exclusion list) and it is written, not applied.
  **HELD FOR A RULING, deliberately**, because of this batch's own rule: adding a boundary to an exclusion
  list is *relaxing an owed-artifact requirement on the tree that ships*, and even a requirement that is
  demonstrably accidental should not be relaxed inside a tag batch on my own judgment. Flagging it rather
  than growing the batch quietly.
- **Consequence if left**: a greenfield project reaching clarify before plan is blocked until someone
  scaffolds `iterations/001/` by hand or skips clarify. The walk got past it by running the governed flow,
  which happened to create what was missing - so the defect is survivable and invisible, which is why it
  survived to a third host.
- **Class**: the guard-scope family - a requirement written for the iteration-scoped boundaries applied to
  a feature-scoped one because the list, not the boundary's own contract, decides.

### DRIFT-199-I003-013 - the verdict menu is mangled at the reader on Copilot, at EVERY boundary: placeholders eaten as HTML, option lines collapsed into one (OPEN; high in the beta4 UX list, confirmed at source, not tag-blocking)

**Reported from the field on every boundary packet of the Copilot walk; both mechanisms confirmed at
source rather than accepted.**

- **What the human saw**: `approved for plan approved for plan -  changes needed:  discuss prompt 1` -
  one run-together line, every placeholder gone.
- **Mechanism 1 - the placeholders are parsed as HTML.** `<to>`, `<your instructions>`, `<what to change>`
  are angle-bracketed, and a markdown renderer that permits inline HTML treats them as unknown tags and
  drops them. The line that survives intact is the one line with no placeholder, which is why
  `approved for plan` reads twice and the other two read as bare labels with nothing after them.
- **Mechanism 2 - the option lines collapse.** Both source emitters
  (`extensions/specrew-speckit/squad-templates/skills/gate-stop.md:64` and
  `scripts/internal/launch-contract.ps1:565`) present the four options as **two-space-indented lines
  inside a fenced block**. Two spaces is not a code indent - four is - so once the fence is not carried
  through into the rendered message, the four lines are one paragraph joined by single newlines, and every
  markdown renderer collapses those to spaces.
- **The source text is correct and the reader is wrong**, which is the family this belongs to: the same
  shape as the `specs//` empty-segment rendering - correct at the source, wrong at the reader, varying by
  host. A host-independent surface cannot rely on a fence surviving the trip.
- **Severity: high in the beta4 UX list, and NOT tag-blocking** - the maintainer's call, and the walk is
  the evidence for it: the first option remained readable and typed capture worked on this host at every
  boundary. **But it is the primary human-decision surface, mangled on a supported host, at every
  boundary** - and this batch's own ruling is that an interface must not offer a control it cannot honour.
  A menu whose three instruction-bearing options render as empty labels is that failure one step earlier:
  the human cannot see that approve-with-instructions and send-back exist at all.
- **Fix shape (the maintainer's, cheap and renderer-proof)**: backtick-quote every placeholder and emit
  the options as a true markdown list - one dash per option - in the gate-stop skill and the
  pending-verdict template across all host mirrors. **One refinement worth carrying into the fix**: make
  each option a list item whose text is an inline code span rather than a bare bullet. Backticks make the
  angle brackets literal in every renderer AND the code span keeps the phrase copy-exact, which a bare
  bullet does not - a human copying a bulleted line copies the dash with it, and the captured phrase must
  be exact. A bullet is not a selection affordance, so the 2026-08-12 no-numbering ruling is untouched:
  that ruling bars numbers and pickers, not list structure.
- **Scope when it lands - the complete emitter set, from a finished repository-wide search rather than
  from the two files that happened to be in front of me.** Four authored sources:
  - `extensions/specrew-speckit/squad-templates/skills/gate-stop.md` **and its `.specify/` mirror** - the
    skill template deployed to every host;
  - `.claude/skills/specrew-gate-stop/SKILL.md` - the deployed Claude skill, a separate copy of the text;
  - `scripts/internal/launch-contract.ps1` - which RENDERS the menu into every project's
    `.specrew/last-start-prompt.md`;
  - `scripts/internal/coordinator-prompt-surgery.ps1` - three host-package variants (lines 206, 222, 228)
    where the options appear **inline in a prose sentence, not as lines at all**. That is a fourth
    rendering of the same menu with a different failure mode, and per the surgery's own host branching it
    is the shape a non-Claude package ships.
  - **Two GENERATED surfaces carry it into each project** and must be re-rendered, not hand-edited:
    `.specrew/last-start-prompt.md` and `.specrew/handover/session-handover.md`.
  - The search also returned **~105 further hits, all under `.scratch/`** - fixture projects and two
    archived module versions (0.17.9, 0.18.0). Named so the next reader does not mistake the count for the
    blast radius: **7 real surfaces, not 112.**
- **The search finished; nothing was edited.** This item is beta4-triaged and stays so (maintainer ruling,
  2026-08-31). The located set is the deliverable.
- **Class closure**: NONE yet. The guard that would close it is a renderer-shape assertion over every
  emitter - no placeholder outside a code span, no option list that depends on a fence surviving - which
  is a beta4 item alongside the fix.

### DRIFT-199-I003-014 - the clarify refusal fix is iteration 003's first PRE-PLAN work item: implemented before the plan that would authorize it, disclosed as exactly that (open until beta4 planning ratifies it)

**Maintainer ruling, 2026-08-31: the fix stands and is not reverted.** It is reproduced, guarded and
mutation-proved. What is irregular is not the work but its position in the lifecycle, and the position is
what this entry records.

- **The irregularity, stated plainly.** `specs/199-beta3-stabilization/iterations/003/plan.md` is a STUB:
  an empty task table, `Status: planning`, and its own note saying *"Add task rows only for work that is
  traceable to the scoped requirements above."* The clarify fix is implemented product code in an
  iteration whose plan boundary has not been crossed. **There is no task row for it, and I did not write
  one** - authoring a task row is the plan boundary's work, and inventing one to make finished code look
  planned is the failure this project exists to prevent.
- **It was implemented under a mis-sequenced reviewer instruction** (the collision recorded in
  DRIFT-199-I003-011), not on my own initiative and not on an inference that a gate was obviously wrong.
- **This is the W76/W77 shape, and naming the shape is the point**: post-authorization work recorded as
  exactly what it is, rather than back-fitted into the record as though the authorization had come first.
  W77's own lesson applies to itself here - *a workaround the operator discovers is not a control* - so the
  disclosure is the artifact, not a plan row that would make the irregularity disappear.
- **Ratification is deferred to beta4 planning**, where it is either adopted as planned work with a
  requirement citation or unwound. Until then this entry, and the disclosure line in 003's plan Notes, are
  the only records that assert it exists. **The default if beta4 planning never looks is NOT silent
  adoption** - an unratified pre-plan change is an open item, and this entry stays open to say so.
- **What it does NOT affect: the tag.** The tag is `4f4dce52` and does not contain this commit. beta3 ships
  the bare `spec.md required content` refusal, and neither owed walk can field-exercise the fix, because
  the walks run the installed 4f4dce52 bits under a standing no-rebuild rule. The fix's evidence tier is
  therefore **guard- and mutation-proved, zero field executions** - the same tier the batch has insisted on
  stating precisely everywhere else.
- **MECHANICAL SHADOW, measured after the fact and NOT resolved**: because the fix edits deployed
  machinery on a tree whose installed module is the 4f4dce52 build, `validate-governance.ps1` now reports
  on **17 iterations** - every one it validates - *"The deployed Specrew machinery under
  .specify/extensions/specrew-speckit does not match what was installed (modified:
  scripts/shared-governance.ps1) ... a local edit to them makes this run's result unreliable rather than
  merely different."* Confirmed to be exactly that one file and nothing else.
  - **The remedy the message names is FORBIDDEN**: it says run `specrew update --project-path ...`, which
    would overwrite the fix with the 4f4dce52 bits. The standing no-rebuild/no-reinstall rule holds until
    both walks finish, and it holds here too. **Not run.**
  - **This is the drift-detection control working, not failing** - it caught a local patch to deployed
    machinery within minutes of the patch landing, named the exact file, and refused to let its own PASS
    verdicts be read as unqualified. Positive-control evidence.
  - **But it is a real cost of the pre-plan position, and it is disclosed rather than absorbed**: for as
    long as this state persists, every validator run in this repository self-reports as unreliable, so
    "the validator passed" cannot be cited as clean evidence for anything until the fix is either shipped
    in a build or unwound. Iteration 003 itself still PASSES on its own checks.
- **ACCEPTED by the maintainer, 2026-09-01, as stated**: the cost is bounded and disclosed, because *the
  tag's evidence predates the fix and the walks run on installed bits*. Recorded as an acceptance rather
  than a resolution - the condition still exists, and the sentence that bounds it is the reason it is
  tolerable, not a reason it is absent.
- **Class closure**: NONE, and none is possible - no check can distinguish authorized pre-plan work from
  unauthorized. The control is disclosure at the moment it happens, which is what this is.

### DRIFT-199-I003-015 - the tag-candidate walk: a brand-new project reached clarify on the final 4f4dce52 bits with ZERO governance stops not about the work (POSITIVE CONTROL EVIDENCE; DRIFT-008's open question answered)

**The walk this batch was held for.** `C:\Temp\beta3-tagwalk`, claude host, feature
`001-ai-usage-monitor`, init through the clarify boundary, on the installed 4f4dce52 build with no rebuild,
no reinstall and no `specrew update` at any point. Maintainer's field report, 2026-09-01.

- **THE HEADLINE MEASUREMENT: zero governance stops that were not about the work.** Set beside the datum
  that opened the UX programme - the first HelloWinUIReactive walk, **nine stops by the specify boundary**
  (maintainer's figure, from that walk's field report) - this is the before and after of the stabilization,
  **the same activity measured at both ends**. Neither number is a benchmark and neither was produced by an
  instrument: both are counts a human made while walking a new project. That is exactly what makes the pair
  worth keeping - it is the only measurement of this fortnight's work taken in the units the work was
  actually for.
  - **The comparison is honest about what changed and what did not.** Nothing in the batch loosened a gate.
    The stops that disappeared were the ones that were never about the work: messages that withheld the
    fact that made them actionable, controls correct alone and hostile together, remedies unreachable from
    the reader's state. The gates that caught something real all still fire - that was the standing rule
    for the whole batch, and this measurement is what it bought.
- **THE ROW THAT WAS THE REASON FOR THE HOLD: `confirm-intake-lens` closed `product-domain` on a fresh
  project.** **First field execution of the intake path on any build**, receipt and records verified in the
  walk transcript. This is the path whose absence deadlocked every greenfield workshop at its first lens,
  the first path every new user executes, and the one that stood at zero field executions through three
  hosts and a fortnight of work. **DRIFT-199-I003-008's sharper half is closed.**
- **Evidence table, updated - the two rows that moved:**

| Row | Before this walk | After | What moved it |
| --- | --- | --- | --- |
| **T017 / FR-026** - the constrained readers | repository-only; never executed outside this repo | **field-proved (happy path)** | Its reader executed **downstream, via the product-domain validator, on a successful close** - on a fresh project, on the final bits. The gap named in 002's review record (`confirm-workshop-lens.ps1:299` validates only `product-domain` and `code-implementation`, and the backup walk closed `architecture-core`, so the reader was never invoked) is closed by a walk that closed `product-domain`. |
| **T018 / FR-027** - intake path | `confirm-lens` field-proved; **intake close unproven on every build** | **intake path field-proved** | `confirm-intake-lens` closed `product-domain` on a brand-new project, receipt and records verified. |

  **Scope of the T017 row, stated rather than implied**: *happy path*. The reader ran on a successful
  close. Its refusal behaviour on a malformed lens artifact is still repository-only.
- **Also field-proved in the same pass**: T020's stub rendered **and was correctly explained to the human
  unprompted** - the stub-then-spec ordering doing the thing it was written for rather than merely
  occurring; specify's verdict captured **with its crossing identity** (FR-024); and clarify ran a real
  three-question pass.
- **CAVEAT, recorded with the same weight as the passes: the walk ran on claude, not codex.** Two
  consequences, neither of them closed by this result:
  1. **The Codex fresh-project capture datum was not collected.** It was the reason a codex walk was
     specified in the first place.
  2. **The HelloWinUIReactive capture mystery remains an open beta4 diagnostic** - why that project
     specifically stopped producing captures has no established cause, and nothing here bears on it.
  A green walk on one host is evidence about that host. The batch has been strict about this in every
  other row and the strictness does not lapse because the result is good.
- **Class closure**: the durable control is still the one DRIFT-199-I003-008 named - a release-gate step
  requiring a walk on the tag-candidate build before publish, `tools/smoke/greenfield-cycle-replay.ps1`
  promoted into the release lane and extended to cover intake. **This walk satisfied that step by hand.**
  Beta4 owes the automation, or the next tag depends on someone remembering again.

### DRIFT-199-I003-016 - a validator whose named remedy would have DESTROYED the thing it detected: the fourth remedy-wrong-for-state instance, and the first caught by a standing rule rather than by luck

**Extends the catalogue in DRIFT-199-I002-026** (sealed iteration 002; recorded here because that record
cannot be amended, and the family is the point).

- **The instance.** `validate-governance.ps1` correctly detected that deployed machinery differed from the
  installed module - the clarify fix - and named its remedy: *"Restore them with: `specrew update
  --project-path ...`"*. **Following it would have overwritten the fix the validator had just detected**,
  silently, with the older bits.
- **The four, and the four different failure directions:**
  1. **DRIFT-199-I002-021** - `specrew update` told to a project AHEAD of its installed module. *Damage.*
  2. **DRIFT-199-I002-018** - the wedged pause sending the reader around a closed loop. *No exit.*
  3. **DRIFT-199-I002-026** - a host telling the reader to switch to the host they were already on. *No-op.*
  4. **This one** - a detector naming the remedy that destroys its own finding. *Self-defeating.*
  Note that 1 and 4 are **the same command** in two different states, which is the family's whole thesis:
  `specrew update` is directional and the message is not.
- **WHAT IS NEW, and it is the reason this instance is worth its own entry: it was caught by a standing
  rule, not by luck.** The three prior instances were each noticed after someone had already followed the
  advice, or been trapped by it. This one was disarmed before it could act, by the maintainer's standing
  no-rebuild/no-reinstall rule for the duration of the walks. **A rule written to protect the tag's
  identity happened to be the only thing standing between a correct detector and the destruction of the
  code it detected.**
- **And that is luck of a different kind, which the entry should say plainly.** The rule was not written
  for this. Had the hold not been in force, the message was locally sensible, authoritative, and repeated
  on 17 iterations - the conditions under which advice gets followed. **A control that only works because
  an unrelated rule happened to be active is not a control.**
- **Resolution**: OPEN, beta4, with the family. The fix is the one DRIFT-199-I002-026 already named and
  this instance sharpens: **a refusal must know the reader's state before naming an action**, and for this
  message specifically that means comparing direction - a project AHEAD of its module must never be told
  to run `specrew update` as though it were BEHIND.
- **Class closure**: NONE. Recorded as the fourth instance so the family's count is honest and so the
  "caught by a standing rule" fact does not get remembered as "the control worked".

### DRIFT-199-I003-017 - natural-language authority conflicts have no detector: one beta4 item, from two instances pointing in opposite directions

**Maintainer ruling, 2026-09-01: this goes to beta4 beside the instruction-corpus work, as one item.**

- **The two instances, and they are symmetric:**
  1. **The maintainer's instruction collision** (DRIFT-199-I003-011): *"fix the refusal to name the
     expected form"* followed by *"hold all fixes"*. The first was acted on before the second existed.
  2. **My sequencing** (DRIFT-199-I002-036's neighbourhood): commits placed between a verdict request and
     its approval, spending **four typed human approvals** on one signoff.
- **What they have in common is the load-bearing part**: both spent human authority, both were ordinary
  work moving faster than the record of it, and **nothing in the system detected either.** Every
  authority control this project has operates on a *single* instruction - is this phrase a verdict, does
  this crossing exist, did a human type it. **None of them looks at two instructions together**, and a
  contradiction only exists between two.
- **Why it belongs beside the instruction-corpus work rather than as a gate**: the corpus is the only place
  where the instruction stream is treated as an artifact with a history rather than as a series of
  independent events. A conflict detector, if one is possible at all, is a property of that history.
- **Stated honestly: it may not be buildable.** Two natural-language instructions can conflict in ways no
  parser will see, and a detector with false positives at an authority boundary would be worse than none -
  it would train people to dismiss it. The item beta4 receives is the **question**, with two measured
  instances attached, not a specification.
- **What is available today, and it is what both instances actually got**: name the conflict, attribute it,
  and do not re-classify the work to fit whichever instruction won.
- **Class closure**: NONE. This is the beta4 item.

### DRIFT-199-I003-018 - a literal backspace byte sat inside a cited path in this log for a day, and only reading the record found it (self-inflicted; guard owed, not written)

- **What was there.** DRIFT-199-I003-008 recorded the walk directory as `C:\Temp` + **0x08** +
  `eta3-tagwalk`. Written by me, via a Python string where `` was an escape rather than a path
  separator. A terminal renders it as `C:\Tempeta3-tagwalk`; a reader following it finds nothing.
- **Second instance of the same cause**, and that makes it a class: octal escapes previously wrote a 0x01
  into `.squad/decisions.md` (`specs99` becoming chr(1) + "99"). **Python escape sequences and Windows
  paths, in a script that writes governance records.**
- **What it corrupted is the aggravating part.** DRIFT-199-I002-040 established this batch's rule after a
  near-retraction: *an evidence claim must name its directory, because in prose two paths differing by a
  suffix read as one place.* The very next thing to break was a named directory - **the rule was followed
  and the citation was still unusable.** Precision requires the byte, not just the intent.
- **How it was found**: by reading the record, in the same pass that read it for content. No check looks
  for control characters in lifecycle artifacts. A sweep run afterwards found this one and confirmed every
  other record clean.
- **Guard OWED, deliberately NOT WRITTEN**: a control-character assertion over `specs/**/*.md` and the
  release record is a five-line test, and it is exactly the kind of five lines that turns into a second
  unratified pre-plan item (DRIFT-199-I003-014). **Named here as owed; it lands with beta4 planning or
  with the beta4 fix batch.** The sweep exists as a one-liner in this entry's history until then.
- **Class closure**: NONE. Corrected in place; the guard is owed.
