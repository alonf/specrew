# Drift Log: Iteration 003

**Schema**: v1
**Total drift events**: 38 (DRIFT-199-I003-001 through -038)
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

### DRIFT-199-I003-018 - a literal backspace byte sat inside a cited path for a day; then the entry written to record it reproduced the same bug twice (self-inflicted, three instances, guard now clearly owed)

- **Instance 1, found by reading.** DRIFT-199-I003-008 recorded the walk directory as `C:\Temp` + a raw
  **0x08** byte + `eta3-tagwalk`. Written by me, from a Python string in which the path separator followed
  by `b` was consumed as a backspace escape. A terminal renders the result as `C:\Tempeta3-tagwalk`; a
  reader following it finds nothing. Repaired.
- **Instance 2, found earlier this batch.** The same cause put a raw **0x01** into `.squad/decisions.md`,
  where a path segment beginning `199` was consumed as an octal escape.
- **Instance 3, and it is the one that settles the argument: THE ENTRY WRITTEN TO RECORD INSTANCES 1 AND 2
  REPRODUCED BOTH OF THEM.** Quoting the offending escape sequences in prose re-triggered them - the
  backspace vanished from the sentence describing the backspace, and the octal escape put a fresh 0x01
  into the sentence describing the octal escape. Caught by re-running the sweep on the committed file,
  **after** the commit that claimed the record was clean.
- **The lesson, now concrete rather than general.** "Be careful with escapes" did not survive contact with
  the very next paragraph. The mechanical fix is mechanical: **every string in a script that writes a
  governance record is a raw string**, without exception, because the strings most likely to contain a
  path or an escape are the ones documenting paths and escapes. This file was rewritten that way and that
  is why it is correct.
- **What it corrupted is still the aggravating part.** DRIFT-199-I002-040 ruled, after a near-retraction,
  that *an evidence claim must name its directory, because in prose two paths differing by a suffix read
  as one place.* The rule was followed and the citation was still unusable. **Precision requires the byte,
  not the intent** - and a record that silently drops bytes cannot be audited by reading it, which is the
  only way these were found.
- **On the guard I named as owed and did not write**: I recorded that decision as deliberate, to avoid a
  second unratified pre-plan item (DRIFT-199-I003-014). **Instance 3 weakens that reasoning and I am not
  reversing my own ruling silently.** Stated for the maintainer instead: a control-character assertion
  over `specs/**/*.md` and the release record is roughly five lines, the failure has now occurred three
  times including once inside its own correction, and every instance was found by a human reading rather
  than by any check. The counter-argument is unchanged - it is pre-plan work in an iteration whose plan
  boundary has not been crossed. **The call is the maintainer's; the sweep has been run and the tree is
  clean as of this commit either way.**
- **Class closure**: NONE - corrected in place, guard owed and now argued for rather than merely named.

### DRIFT-199-I003-019 - the escape-corruption class is repository-wide and one instance SHIPS: a swept 2,371 files, five carriers, one of them in the module's FileList (pre-existing, inside the tag, REPORT-ONLY)

**Found by generalising the sweep that caught DRIFT-199-I003-018 from one file to the whole repository.**
The two instances I had were mine and recent. They are not the class.

- **Sweep**: 2,371 markdown files across `specs/**`, `docs/`, `.squad/`, `templates/**`, `.specify/**`,
  `extensions/**`, `.specrew/**`. **Five files carry control bytes**, none of them mine, all pre-existing:

| File | Bytes | What the corruption ate |
| --- | --- | --- |
| `templates/squad/agents/picard/history.md` | `0x1b` | *"transition to `<ESC>xecuting` phase"* - `\e` consumed the `e` of **executing** |
| `specs/050-cursor-host-support/iterations/001/review.md` | `0x07 0x08` (x3) | *"valid values: pass \| `<LF>`eeds-work \| `<BS>`locked"* and *"set Overall Verdict to `<BEL>`ccepted"* - `\n`, `\b`, `\a` each ate the first letter of **needs-work**, **blocked**, **accepted** |
| `specs/050-cursor-host-support/iterations/003/review.md` | `0x07 0x08` (x3) | the same three, same file shape |
| `.squad/decisions.md` | `0x07 0x08 0x1b` | (the `0x01` instance already recorded) |
| `.squad/decisions-archive.md` | `0x00 0x07 0x1b` | includes a **NUL** |

- **One mechanism, six escape characters.** Every instance is a backslash immediately before a word, in a
  non-raw string: `\e`, `\n`, `\b`, `\a`, `\1`, `\0`. **The same cause as my two**, which means the class
  predates this batch and my instances are its fifth and sixth, not its first.
- **WHAT MAKES ONE OF THEM DIFFERENT: `templates/squad/agents/picard/history.md` SHIPS.** Measured, not
  assumed - it is named in `Specrew.psd1`'s FileList, and the deployed copy in this project's
  `.squad/agents/picard/history.md` **carries the same 0x1b**, while the other twelve agent histories are
  clean. So the corruption reaches every project that installs the module.
  - **Severity, honestly bounded**: an ESC before `x` is not a valid ANSI sequence, so nothing executes; the
    cost is that one word of shipped agent guidance is destroyed, and a control byte sits in text that is
    fed to a model as context.
- **The two `050` review records are the more interesting corruption even though they do not ship**, because
  of *what* was eaten: the **canonical verdict enum values** in the text that tells a reviewer what the
  valid values are. A reviewer reading that file is told the values are `pass | eeds-work | locked` and to
  set the verdict to `ccepted`. **The instruction defining the enum is the thing that lost its letters** -
  and every one of those three words is a string the validator matches exactly.
- **RETRACTION, made before reporting rather than after.** My first pass flagged four agent charters
  (`implementer`, `planner`, `retro-facilitator`, `spec-steward`) as corrupted. **They are clean.** The
  check was a heuristic - "mentions needs-work but not blocked" - and those charters simply never use the
  word *blocked*. Re-measured for actual control bytes: `ctrl=NONE` on all four. Recorded because this
  batch's rule is that a wrong finding is recorded with the same weight as a right one
  (DRIFT-199-I002-014, -025), and because the near-miss has a lesson: **the sweep must test for the bytes,
  never for a proxy that correlates with them.**
- **NOT FIXED, and the reasoning is the tag's**: all five files are pre-existing and **already inside
  `4f4dce52`** - the tagged, built, installed and walked bits. Repairing them would be new work outside a
  tag that is deliberately frozen, on the instruction that nothing else enters it. **Report-only.** The
  repairs and the owed control-character guard belong to the same beta4 item, and the guard is now
  justified by five independent instances rather than by my two.
- **Class closure**: NONE. The class is now measured rather than suspected, which is the whole change from
  DRIFT-199-I003-018: that entry argued for a guard from three self-inflicted instances; this one shows
  the guard would have caught a shipping defect that predates the batch.

### DRIFT-199-I003-020 - the recovery close executed in the field on the stranded specimen: the last unproven tag-relevant row, and BOTH publish gates are now complete (POSITIVE CONTROL EVIDENCE)

**The second of the two gates the publish was held for.** Maintainer's field report, 2026-09-01.

- **Where, exactly** - and the precision matters here more than anywhere else in this batch, because two
  directories differing by a suffix are what nearly retracted a true finding (DRIFT-199-I002-040/-041):
  **`C:\Temp\ConsoleFractal`** - the ORIGINAL stranded specimen, **not** the `-stranded-backup` copy that
  carried the earlier `confirm-lens` evidence. Host: **codex**. Bits: **4f4dce52**, installed, no rebuild.
- **What executed**: `confirm-intake-lens`'s **recovery branch** - the transition from `confirmed-complete`,
  which is the state that used to refuse it - closing `product-domain` on a project that had genuinely been
  stranded in the field rather than on a fixture posed into that state.
- **The four things checked, and each answers a specific way this could have been wrong:**
  1. **It consumed the preserved receipt** - so the human's typed turn was the authority, not a marker the
     machinery minted for itself. This is the batch's own line: *machinery may restore a fact that
     re-enables a human decision; it may never write a fact that constitutes one.*
  2. **The confirmed agenda was left untouched** - the recovery re-opened exactly the lens that was stuck
     and nothing adjacent. A recovery that resets the agenda would have been a data-loss path wearing a
     fix's clothes.
  3. **The record validated at the checkpoint** - the artifact the next gate reads is well-formed, not
     merely written.
  4. **It ran on the ORIGINAL specimen.** The whole point of holding for this gate was that the earlier
     evidence came from a copy, and the copy had been touched. The state under test here is the one the
     defect actually produced.
- **This is the guard-scope principle's positive case, and it is worth naming as such.** The batch's most
  quoted finding is *the fixture wrote the precondition the product denies* - a control proved against a
  state only the test could create. **This proof is the exact opposite**: the precondition was written by
  the defect, in the field, before anyone knew it would be needed, and the fix was run against it
  untouched. That is the strongest evidence tier this project has, and it is available for exactly one
  reason - the stranded project was preserved instead of being repaired at the time.
- **EVIDENCE TABLE - the last unproven tag-relevant row closes:**

| Row | Status | Location |
| --- | --- | --- |
| T018 / FR-027 - `confirm-lens` + both contract fixes | field-proved | `C:\Temp\ConsoleFractal-stranded-backup` |
| T018 / FR-027 - intake path, fresh project | field-proved (2026-09-01) | `C:\Temp\beta3-tagwalk`, claude, 4f4dce52 |
| **T018 / FR-027 - recovery path from `confirmed-complete`** | **field-proved (2026-09-01)** | **`C:\Temp\ConsoleFractal`, codex, 4f4dce52** |
| T017 / FR-026 - constrained readers | field-proved, happy path | `C:\Temp\beta3-tagwalk` |

  **No tag-relevant row is unproven.** The rows that remain non-field-proved are the ones scoped out and
  said so: T017's refusal behaviour on a malformed artifact, and the clarify-refusal fix - which is
  deliberately outside the tag (DRIFT-199-I003-014) and therefore not tag-relevant by construction.
- **BOTH PUBLISH GATES COMPLETE.** DRIFT-199-I003-008 asked whether anything had been walked on the bits
  that ship. Both halves of its answer now exist: a fresh project through clarify with zero stops, and the
  recovery branch on the specimen that motivated it.
- **Class closure**: none owed - this is evidence. The durable control remains the one -008 named and -015
  repeated: a release-gate walk on the tag-candidate build, automated, so the next tag does not depend on
  someone asking the question.

### DRIFT-199-I003-021 - two post-gate observations for the beta4 register: a compaction-triggered receipt re-ask, and a positive-ledger line (REGISTER ONLY - not action items, and the fix freeze holds)

**Recorded at the maintainer's direction as register entries for the beta4 batch. Neither is acted on now;
the freeze on fixes holds until the publish is done.**

- **Observation 1 - a compaction-triggered receipt re-ask on a lens close.** Known family (**F-2**). One
  retype; **the human's answers were safe throughout**, which is the property that makes it a register
  entry rather than a gate. Worth noting for beta4 that it landed on a *lens close* - the workshop path
  this batch spent its largest single effort on - so the receipt machinery is the surface where context
  compaction and typed-turn authority meet, and that intersection is where the family should be attacked
  rather than at any one call site.
- **Observation 2 - a positive-ledger line: the recovery conduct in this session's tail was exemplary,
  per the maintainer.** Recorded because this log is overwhelmingly a record of what went wrong, and a
  register that only counts failures gives a false picture of the same work. The specific thing worth
  keeping: the stranded project was **preserved rather than repaired** when it was first found - which is
  what made DRIFT-199-I003-020's field proof possible at all, weeks later. **The instinct to fix a broken
  thing immediately would have destroyed the only specimen that could prove the fix.**
- **Status**: REGISTER ONLY. No fix, no guard, no scope change in this batch.

### DRIFT-199-I003-022 - the batch never once ran the gate the release actually hangs on, and the publish sat blocked for two days without anyone noticing (OPEN; the beta4 item is one line)

**Measured 2026-09-02.** The `v0.40.0-beta3` tag push triggered `publish-module.yml` on 2026-08-31.
`prepublish-validation` passed, **`full-test-census` failed with 23 of 404 test files**, and
`publish-module` was skipped. **The gallery has nothing.** Nobody looked for two days.

- **The gate's own banner is the guard-scope principle, written by this project, in the file that then
  went unrun**: *"the per-round lanes named 45 suite files while 384 existed, so 'lanes green' was
  reported as 'no failing tests' for days while twelve suites were red."* The comment continues: *"the
  lanes stay fast and curated on purpose; this is the cadence where slow is affordable, and the rule is
  that a tag cannot be cut on lane-green alone."*
- **And that is exactly what this batch did.** Two review rounds, two field walks, a covering round on the
  tree that ships, and a tag ceremony - all on curated lanes. **The census was never run once.** The
  batch's most-quoted finding is *a fixture wrote the precondition the product denies*; this is its
  sibling: **the guard against lane-green-is-not-tree-green was itself only ever checked against lanes.**
- **Two failures, not one, and the second is the worse one:**
  1. **The gate was never dry-run before the tag.** A release-gate dry run belongs in the pre-tag
     checklist, beside the walk requirement DRIFT-199-I003-008 already named.
  2. **The failure was silent for two days.** The tag ceremony ended with a report that the release was
     staged and ready to publish. Nothing in that report was false, and the publish was already dead at
     the time it was written. **A gate that fails after the ceremony declares success needs to say so to
     someone**, and nothing did.
- **A third gap found while triaging, and it makes any future failure equally opaque**: the census prints
  `Full diagnostics: C:\Users\runneradmin\AppData\Local\Temp\specrew-full-sweep-failures-<guid>.json` -
  **written to ephemeral runner storage and never uploaded as an artifact.** The run keeps a list of 23
  filenames and no reason for any of them. Reproducing the failures locally was the only route to a cause,
  which is precisely the diagnosability class beta4 already owns.
- **Resolution**: OPEN. Three beta4 lines, and they are cheap: (a) a release-gate dry run in the pre-tag
  checklist; (b) upload the census diagnostics JSON as a run artifact; (c) surface a failed publish
  somewhere a human sees it without going to look.
- **Class closure**: NONE in this batch - the fix freeze holds, and every one of these touches release
  machinery, which is the last thing to change while a publish is blocked.

### DRIFT-199-I003-023 - three false measurements in one triage, each caught by its own control: the cost of a tooling boundary, recorded while it is fresh

**Recorded because the triage that found DRIFT-199-I003-022 produced three wrong answers first**, and each
would have been reported as fact had it not been checked. The batch's rule is that a wrong finding is
recorded with the same weight as a right one.

1. **Empty git dates read as "new".** `git log --diff-filter=A` returned nothing for every path, and the
   shell comparison `[[ "?" < "2026-08-09" ]]` sorted all 23 into *new since beta2*. **The evidence was
   absent and the code reported a conclusion anyway.**
2. **CRLF in a path list broke every lookup.** The list was written from Python without `newline=''`, so
   each path carried a trailing `\r`; `git cat-file -e` failed on all 23 and they read as *new in beta3*
   a second time, by a different mechanism. **Two independent bugs produced the same wrong answer, which
   is what made it briefly convincing.**
3. **A "docs-only confirmed" printed after its own `cd` had failed.** A worktree checkout died on a
   Windows long-path limit; the `cd` that followed failed; the verification command then ran in the wrong
   directory, found nothing staged, and printed a pass.
- **What caught all three: a control that had to move.** The third answer only broke when a known-old file
  (`version-checks.tests.ps1`) was asserted to be *pre-existing at beta2* and the check said otherwise. **A
  verification with no negative control cannot distinguish "nothing is wrong" from "nothing was measured"**
  - which is the same shape as DRIFT-199-I003-011's silent validator, one layer down, in my own tooling.
- **Class closure**: NONE, and the practice is the control, not a guard: **every sweep asserts a known
  positive and a known negative before its result is believed.** Recorded here because this triage is the
  third place in one batch where an empty result was nearly reported as a clean one.

### DRIFT-199-I003-024 - the census triage: TWO failures are real on the tagged tree, proven against a beta2 control, so this is a respin decision and not ours (STOPPED AND REPORTED)

**Triage of the 23 census failures from run 33443223172.** Method: run every failing file against a clean
checkout of the tagged tree (`C:\Temp\b3census` = 4f4dce52), then, for any file **byte-identical to
v0.40.0-beta2**, run it again against a beta2 checkout (`C:\Temp\b2base2`) **on the same machine with the
same harness**. That second run is the control: with the environment held constant, a pass-then-fail
isolates the change to the product tree.

**THE PRIOR WAS WRONG, and the numbers say so plainly.** The hypothesis was that the failures are
overwhelmingly this batch's own new test files. They are not:

| Provenance vs v0.40.0-beta2 | Count |
| --- | --- |
| **Byte-identical** to beta2 (passed its census unchanged) | **11** |
| Modified in beta3 | 6 |
| New in beta3 | 6 |

Seventeen of twenty-three pre-existed; eleven are unchanged. No hypothesis about new tests can explain
eleven files that passed the beta2 census in the exact bytes they still have.

**Local reproduction against the tagged tree: 12 pass, 11 fail.**

**THE TWO CONFIRMED REAL-TREE FAILURES** - unchanged test, passes at beta2, fails at the tag, same machine:

1. **`tests/unit/pretag-slice3-certify-findings.tests.ps1`** - its fixture can no longer be minted:
   *"scoped fixture mint failed: [specrew-governance] WARN CROSSING_NOT_MINTED_OWED_ARTIFACTS_ABSENT The
   'before-implement' -> 'review-signoff' crossing was not opened: 'review-signoff' owes review.md for
   iteration 001."* **This is the batch's own owed-artifact gate refusing a crossing the fixture used to be
   allowed to open.** And it is this batch's most-quoted finding turned exactly around: *the fixture wrote
   the precondition the product denies* - except here the product learned to deny it, on purpose, and the
   fixture was never updated. Whether the new refusal is CORRECT is not in question; it is deliberate work.
   What is in question is that an unchanged test encoding the old contract is red **inside the tag**.
2. **`tests/integration/code-rules-skill-multihost.tests.ps1`** - *"FAIL: T052: checkpoint procedure cannot
   contradict the record-before-structured-entry order."* Unchanged test, passing at beta2, failing at the
   tag: skill content changed in beta3 in a way this assertion rejects.

**One confirmed environmental**: `tests/integration/refocus-digests.tests.ps1` **fails at beta2 too**, in
the same local environment. It is not attributable to the beta3 tree.

**The remaining twenty are NOT isolated, and the record says so rather than rounding them into a verdict:**
- **12 pass locally on the tagged tree.** They failed only on the runner, which makes them
  census-environment *candidates* - fresh runner, no installed module, working-directory and path-length
  assumptions. **Candidates, not proof**: my machine is not the runner either, and a pass here is evidence
  about here.
- **8 fail locally and are new or modified in beta3**, so no unchanged-file control exists for them. They
  are consistent with real-tree and consistent with tests authored against a developer environment, and
  this triage cannot separate those two without more work.

**STOPPED, per the standing instruction.** The rule was: if any failure is real on the tagged tree, stop
and report - it is a respin decision with re-walk implications and it belongs to the maintainer. **Two are
real, with controls.** Nothing was fixed, no workflow was touched, the tag was not moved.

**And the recovery path that was hoped for does not exist**, read from `publish-module.yml` rather than
assumed: no `ref:` on any of the three checkouts and no `git checkout <tag>` anywhere, so `workflow_dispatch`
takes **both the workflow definition and the tree from the same dispatched ref**; `release_tag` only supplies
a label (`$effectiveRefName`), while the package is built from the checked-out tree (`$src = Join-Path '.'
$file`). A dispatch on `main` would in any case be **refused** by the workflow's own guard - *"Dispatch tag
'<tag>' already exists at <sha>, but this workflow run expects <sha>. Refusing to publish divergent
content."* That guard is the tag-names-the-bytes invariant enforced in code, and it is working. **Census
harness fixes on `main` cannot reach a publish of 4f4dce52 without moving the tag.**

- **Diagnostic scaffolding left in place** for whoever takes the decision: `C:\Temp\b3census` (4f4dce52) and
  `C:\Temp\b2base2` (v0.40.0-beta2), plus per-file results at the session scratchpad's
  `triage23-results.json`.
- **Class closure**: NONE. The decision is the maintainer's; the beta4 items are in DRIFT-199-I003-022.

### DRIFT-199-I003-025 - a whole-tree gate is only as meaningful as the tree's file classification, and nobody had ever checked it (OPEN; the correction is reclassification, never exclusion)

**The census promises to execute every named test file on disk. It kept that promise. What nobody had
checked is whether everything in `tests/` is a test.**

- **The shape, found while triaging**: `tests/unit/coverage-line-names-its-campaign.tests.ps1` reads this
  repository's own **gitignored runtime state** - `.specrew/start-context.json` and whatever review
  campaigns happen to be on disk - and its case 2 depended on the ambient coincidence that the active
  iteration differed from the campaign's. In any fresh clone `Get-SpecrewReviewCoverageState` answers
  `available=$false`, the function returns an empty line, and the file fails before its second case runs.
  **It could never have passed in a clean checkout.** That is not a fixture gap. It is a **developer probe
  living in `tests/`** - a thing that measures the live instance, misfiled as a thing that tests the code.
- **Why it went unnoticed for the life of the file**: the curated lanes never named it, and the census -
  the only reader that would have - **was never run until 2026-08-31** (DRIFT-199-I003-022). A promise to
  run everything on disk is only a guarantee about the code if the disk holds only runnable things, and
  the check that would have told us was the one nobody ran.
- **MAINTAINER RULING, 2026-09-02: per-file exclusion from the census is NOT available.** The gate is
  all-or-nothing and the publish job depends on it, so an exclusion means editing the census's own subject
  set - **carving a hole in the only reader that looks at the whole tree**. That is the hand-enumerated-set
  defect this batch has recorded repeatedly (the lanes naming 45 of 384), at maximum stakes. The gate is
  not weakened to fit the tree.
- **The correction is CLASSIFICATION, and every remaining failure gets one of exactly three**, with
  evidence per file:
  1. **Genuine test with a closable fixture gap** - fix it, proportionately.
  2. **Developer probe requiring ambient repo state** - relocate it out of the census's discovered set
     (`tools/probes/`, or off the discovered pattern), carrying a comment that says it needs live repo
     runtime state, cannot run in a fresh clone, and is run by hand. **This corrects a misfiling rather
     than weakening a gate**, and the census keeps its every-test-on-disk promise honestly, because the
     file was never a test on disk in the first place.
  3. **Real product defect** - STOP AND REPORT. That is a packaged file and the maintainer's decision.
- **The distinction that makes this safe**: an exclusion list says *this test may fail*. A relocation says
  *this was never a test*. The first hides a red; the second fixes a lie about what the directory holds.
- **Class closure**: NONE yet. The durable guard is a classification check - nothing under the census's
  discovered pattern may depend on gitignored runtime state - which is beta4 work alongside the pre-tag
  dry run.

### DRIFT-199-I003-026 - the dry-run's first act was catching a transient that would have silently blocked the publish for the SECOND consecutive release (POSITIVE CONTROL EVIDENCE)

- **What happened, 2026-09-01**: the `workflow_dispatch` dry-run on `respin/beta3-census` failed in
  **`prepublish-validation`**, before the census had even finished:
  `Install-Package: Package 'Specrew' failed to be installed because: End of Central Directory` ->
  `Docker build FAILED. Blocking publication.`
- **Not a tree defect.** That step builds the publish-test container, which installs Specrew **from
  PSGallery**; "End of Central Directory" is a corrupt zip mid-download. Nothing in the respin branch is in
  that path - the branch touches five files, all tests, harness and workflow - and the same step passed on
  the tag push two days earlier. Re-run and move on.
- **THE POINT, and it is the whole justification for the rehearsal**: on a tag push this failure looks
  exactly like the census failure did - a red job, a skipped publish, an empty gallery, and **nobody
  watching**. It would have blocked the publish silently **for the second consecutive release**, on a
  cause entirely unrelated to the first. The dry-run turned a silent two-day outage into a re-run.
- **What it says about the beta4 surfacing item**: the case for it no longer rests on one incident. Two
  consecutive releases, two unrelated causes, the same failure mode - **the publish stops and the room
  finds out later**. A gate that can fail after the ceremony declares success needs to tell someone.
- **Class closure**: NONE. The dry-run is now this release's practice (maintainer ruling); automating it
  into the pre-tag checklist, and surfacing a failed publish, remain the beta4 lines in
  DRIFT-199-I003-022.

### DRIFT-199-I003-027 - a computed guard caught a hand-maintained list drifting DURING the operation meant to correct a hand-maintained list (POSITIVE CONTROL EVIDENCE; and the standing rule for classification)

**The best positive-ledger entry of the respin, and the maintainer's own assessment.**

- **What happened, 2026-09-02.** Relocating the misfiled probe out of `tests/`, I first *repointed* the two
  registries that named it - `tests/f198-regression-suite.ps1` and `.specrew/release-gate-suites.txt` -
  from the old path to the new one. `every-suite-is-named-by-a-lane` went red immediately: *"the disk
  census found at least as many suites as the plan names."*
- **It was right, and the reason is the point.** A probe that has left `tests/` must not still be **named
  as a suite**, or the registries start lying in the other direction: they would claim suite coverage for a
  file that is no longer a suite. Removed from both instead; the guard went green.
- **Why this is the entry worth keeping**: a computed guard caught a hand-maintained list drifting **during
  the very operation whose purpose was to correct a hand-maintained list**. The batch's recurring finding is
  the hand-enumerated set going stale (the lanes naming 45 of 384; the FileList omissions; the exclusion
  list this ruling refused). Here the countermeasure fired against its own author, mid-correction, on a
  mistake that would have been invisible in review - the diff read as a tidy path update.
- **THE STANDING RULE, recorded in the words the distinction was drawn in:**
  > **An exclusion says *this test may fail*. A relocation says *this was never a test*.**
  The first hides a red. The second fixes a lie about what the directory holds. Per-file census exclusion
  stays refused (DRIFT-199-I003-025); relocation is available, and it carries the burden of proof below.
- **THE BAR FOR A CATEGORY-2 CALL, because this is the classification that could quietly become the
  exclusion mechanism** (maintainer, 2026-09-02): a file is a developer probe only if it
  **CANNOT PASS IN A FRESH CLONE BY CONSTRUCTION** - it depends on gitignored runtime state, ambient
  campaigns, a live `.specrew/`, or another artifact no clean checkout has.
  - `coverage-line-names-its-campaign` qualified on exactly that evidence: in a fresh clone
    `Get-SpecrewReviewCoverageState` answers `available=$false`, the line comes back empty, and the file
    fails its FIRST assertion. It could never have passed in CI at all.
  - **"Needs a fixture I would rather not build" is NOT category 2.** A test that merely needs a laborious
    fixture is **category 1 with a cost, and cost is not a category.** The campaign-budget fixture that
    `coverage-line`'s successor will need is expensive; that expense is not what moved the file - its
    inability to pass by construction is.
  - **Every category-2 call states its evidence in that form**, naming the specific ambient artifact and
    the assertion that fails without it, so a reader can check the claim rather than take it.
- **Class closure**: the guard already exists and already fired - that is the whole entry. What is owed is
  the beta4 classification check: nothing under the census's discovered pattern may depend on gitignored
  runtime state.

### DRIFT-199-I003-028 - the self-leak firewall has a self-service exemption with no granting policy: the guard-scope pattern inside a guard's own escape hatch (OPEN; beta4 is a POLICY decision, not a rewrite backlog)

**The six leaked drift IDs were the symptom. This is the finding.**

- **What was fixed today**: six unannotated self-provenance citations in the deploy surface -
  `confirm-workshop-lens.ps1`, `shared-governance.ps1` (x3), `specrew-conformance-provider.ps1`,
  `workshop-authority-store.ps1` - rewritten to state the abstract rule with no identifier. Lint green.
- **THE REFRAME, and it is the sharper statement (maintainer, 2026-09-02).** The defect is **not 153
  citations**. It is that **anyone may add `specrew-self-ok: <reason>` and nobody adjudicates the reason.**
  The marker grants itself. So the firewall is **advisory wherever the marker appears** and binding only
  where it does not - which means **the six that were red were red only because nobody bothered to mark
  them.** Marking them would have been a one-line change that passed the gate and shipped the same defect.
- **This is the guard-scope pattern inside a guard's own escape hatch**, and that is the sharpest form the
  batch has recorded. The pattern elsewhere: a control whose scope is decided by hand drifts from what it
  claims to cover (the lanes naming 45 of 384; the FileList omissions). Here the *escape* from a control is
  decided by hand, by the same person the control is meant to constrain, at the moment they are constrained.
- **THE MEASURED INVENTORY, recorded as a count and an open question - NOT as a violation tally:**

| Identifier kind | Sanctioned hits |
| --- | --- |
| `F-NNN` feature ids | 91 |
| `DRIFT-...` ids | 40 |
| `R-...` | 14 |
| `D-...` | 8 |
| **Total self-provenance-id** | **153** |

  (Plus 18 non-provenance sanctioned hits - registry, delivery-assumption, stack-assumption,
  maintainer-id - for 171 annotated overall.)
- **THE BETA4 ITEM IS THE POLICY, NOT THE REWRITE.** "Rewrite 153 comments" is the wrong shape: it treats
  an unadjudicated hatch as a backlog and would leave the hatch open afterwards. The work is **decide the
  granting policy, then classify against it.**
  - **Starting draft, the maintainer's, to be argued rather than adopted**: *a self-citation is legitimate
    when Specrew itself is the subject the reader must understand, and illegitimate when it is a pointer
    to a record the reader cannot open.*
  - On that line, **most of the 40 fall on the wrong side, and probably the 91 too** - a downstream reader
    has no referent for `F-174` any more than for `DRIFT-199-I002-020`. **Classification is the work**, and
    it belongs to the beta4 workshop, not to a tag batch.
- **What today's fix does and does not settle**: it removes six citations that had no marker. It does not
  touch the 153 that do, and it does not close the hatch. Both facts are stated so no reader mistakes a
  green lint for a resolved question.
- **Class closure**: NONE. The executable guard would be an adjudication step - a marker requires an
  approver, or the reason is checked against a stated policy - and there is no policy to check against yet.
  That ordering is the whole point of the entry.

### DRIFT-199-I003-029 - read and write BYTES when the claim is byte-level: one rule from two near-misses, and the second time this respin a verification caught its verifier (TOOLING NOTE + POSITIVE CONTROL EVIDENCE)

**Two mechanisms, one rule, both measured today.**

1. **The CRLF near-miss.** The six comment rewrites were applied with Python's default text mode, whose
   universal-newline translation silently converted **CRLF to LF across four entire files** (all four are
   pure CRLF: 8,204 / 1,977 / 578 / 301 CRLF, zero bare LF). The change was about to be described as
   "comments only". **It was every line in four packaged files.**
   - **The inertness proof caught it.** Tokenizing before and after and comparing non-comment tokens
     surfaced `LineContinuation` differences whose text looked identical to the eye - a backtick plus a
     newline whose newline had changed. Restored from snapshot, re-applied with `newline=''` on BOTH read
     and write, re-proved: 1,544 / 43,784 / 13,639 / 4,162 code tokens identical, position for position.
2. **The heredoc collapse**, already recorded as the mechanism behind earlier corruptions: this shell
   collapses doubled backslashes inside heredocs, so `chr(92)`, `chr(10)` and forward slashes are used
   instead of escapes in any script that writes governed content.
- **THE RULE, one line covering both**: **read and write BYTES, not text, whenever the claim being made is
  byte-level.** Text mode is a convenience that silently normalises exactly the things a byte-level claim
  is about - line endings, encodings, escapes. A "comments only" claim, a hash-equality claim, and a
  mirror-parity claim are all byte-level claims.
- **POSITIVE LEDGER: this is the SECOND time this respin that a verification caught its own verifier.**
  The first was the lane guard catching the registry repoint mid-relocation (DRIFT-199-I003-027); this is
  the inertness proof catching the whole-file rewrite hiding under the comments-only claim. Both were
  mistakes of mine that would have read as tidy in review. **The pattern worth keeping: a proof is only
  worth running if it can fail, which is why the inertness proof carries a negative control demonstrating
  it detects a real code change hidden under a comment change.**
- **Class closure**: the practice is the control - byte mode, negative controls, and no byte-level claim
  accepted without a proof that could have failed.

### DRIFT-199-I003-030 - the census had never been a meaningful measurement of the tree: it ran where the product cannot bootstrap, and reported the product's own dependency refusal as a tree defect (OPEN; this is DRIFT-199-I003-022's CAUSE)

**The reframe this respin earns, and it is larger than the four tests it explains.**

- **What the gate was actually measuring.** A bare `windows-latest` runner has no `uv` and ships
  **Node 22.23.2**. `specrew init` therefore fails its OWN dependency check, and every test that
  bootstraps a project dies with `Bootstrap failed: Missing required dependencies`. The census recorded
  those as failing test files. **They were the product correctly refusing to run on an unsupported
  machine.** A whole-tree gate that runs where the product cannot bootstrap is not measuring the tree.
- **THE CONSUMER QUESTION, answered at source rather than assumed** (maintainer, 2026-09-02): a real user
  on Node 22 running `specrew init` gets:
  ```
  Outdated dependencies:

    [Windows] Node.js v22.23.2 (required: 24.0+)
        Update from https://nodejs.org/

  Install all required dependencies before running specrew init.
  ```
  and **exit code 4**. It names the tool, the version found, the version required, one concrete reachable
  action, and it fails closed with a distinct code. **By this batch's own refusal standard that message is
  correct** - `scripts/init/preflight.ps1:85` carries the hint and `scripts/specrew-init.ps1:366` renders
  it. **This is NOT a beta4 refusal-standard item.** The consumer path and the runner path are the SAME
  path, and the message was clear on both. Nobody read it, because it was buried inside a failing test in
  a gate nobody had run.
- **AND THE DEPENDENCY FLOOR DID NOT MOVE**, measured rather than presumed: `Required = '24.0+'` is
  **identical at `v0.40.0-beta2` and at `4f4dce52`**. So this is **not** a beta3 release-notes line about a
  raised floor. Nothing about the product's requirements changed.
- **CORRECTED 2026-09-02 - THE PREMISE BELOW WAS FALSE, AND THE CORRECTION MATTERS MORE THAN THE ENTRY.**
  This entry originally read: *"the census passed once, on 2026-08-09 ... that run was green because the
  runner satisfied the requirement at the time ... it is evidence that one runner image, on one day, could
  bootstrap."* **There was no green run to explain.**
  - **Read from the run list and git history, not remembered:** the census entered
    `publish-module.yml` in **commit `31107fef`, 2026-08-26** - **eighteen days AFTER** the
    `v0.40.0-beta2` tag of 2026-08-08. `git merge-base --is-ancestor 31107fef v0.40.0-beta2` reports it is
    **not** an ancestor, and the workflow at that tag contains the string `full-test-census` **zero**
    times. The successful beta2 publish run of 2026-08-09 **did not include a census job at all.**
  - **Every run that has ever contained the job has failed**: the beta3 tag run of 2026-08-31 and all four
    respin dry-runs. **The census has never passed. There is no green census run in this project's
    history.**
- **THE CORRECTED FINDING IS SIMPLER AND WORSE**: a whole-tree gate was written, **wired into the publish
  path**, and **never once completed a sweep** - because its runner could not bootstrap the product. It
  was not a gate that used to work and drifted. It has never worked, and it was load-bearing from the day
  it was added.
- **HOW THE FALSE PREMISE GOT HERE, recorded because the mechanism is the point.** It rested on a
  **remembered characterization that nobody checked** - *"beta2's census succeeded on 2026-08-09"* - stated
  in passing and then built upon. **This is the third instance this fortnight of that mechanism**, after
  the crew's wrong integrity finding and the retracted host-regression diagnosis, and **the first that
  originated with the maintainer**. It is also the second time in this batch that I propagated a claim
  about a component without invoking the component, which is the batch's own standing rule
  (*before acting on a claim about a component, invoke the component*) applied to a claim about a CI job:
  **the run list was one command away and neither of us ran it.**
- **What survives**: DRIFT-199-I003-032's reading rule, now trivially true - no baseline exists because the
  gate is days old and has never been green. The eleven remaining failures are a **FIRST MEASUREMENT, not
  a set of regressions**, and the release record must not call any of them a regression on the artifact's
  authority. Per-file local controls remain the only instrument that can date a failure, and the tests are
  much older than the gate, so an individual one may still be long-broken - `refocus-digests` already is,
  confirmed at beta2.
- **This belongs beside DRIFT-199-I003-022 as its CAUSE.** That entry recorded that the batch never ran the
  gate the release hangs on. This one records why running it would have been necessary but not sufficient:
  **the gate itself was not measuring what its banner claims** until the runner was provisioned to run the
  product. Fixed today in the workflow; recorded because the fix is younger than the belief it corrects.
- **Class closure**: NONE. The durable guard is a runner-provisioning assertion - the census refuses to
  report a tree verdict from a machine that cannot bootstrap the product - which is beta4 work beside the
  pre-tag dry run.

### DRIFT-199-I003-031 - the census and CI provisioning steps are now duplicated with nothing checking they agree: the hand-enumerated-set pattern, in the workflow file (RECORD ONLY, not fixed; beta4)

- **What was done today**: the census job was given Node 24, markdownlint-cli, `uv`, the specify CLI and
  the squad CLI, mirroring `specrew-ci.yml` **step for step**, with `SPEC_KIT_VERSION` and `SQUAD_VERSION`
  pinned at workflow scope to the same values that lane uses.
- **What that fixes and what it does not.** Pinning the two versions stops those VALUES drifting apart.
  **It does nothing about the STEPS.** There are now two hand-maintained provisioning sequences, and
  **nothing checks that a dependency added to one reaches the other.** Add a tool to the CI lane tomorrow
  and the census keeps passing while measuring a runner that no longer matches - which is precisely the
  failure this entry's neighbour describes, re-armed.
- **This is the hand-enumerated-set pattern, in the workflow file** - the batch's most-recorded shape,
  after the lanes naming 45 of 384, the FileList omissions, the exclusion list that was refused, and the
  suite registries the lane guard caught mid-relocation. **Fourth surface, same defect.**
- **The computed form**: a shared composite action both jobs reference, so the provisioning has ONE
  definition and adding a dependency reaches every consumer by construction.
- **RECORD ONLY, deliberately.** Authoring a composite action is workflow refactoring during a blocked
  publish, and the standing rule is that release machinery is the last thing to change while a publish is
  blocked. **Beta4.**
- **Class closure**: NONE. Named, not closed, and named specifically so the duplication is not mistaken
  for the fix.

### DRIFT-199-I003-032 - this project has never had a census baseline, so nothing in the artifact may be read as regression-versus-longstanding without a local control (READING RULE for the 22)

**The consequence of DRIFT-199-I003-030, stated plainly because it changes how every remaining
classification must be read.**

- **The one green census was green because the runner happened to satisfy Node 24 that day.** The floor did
  not move; the runner drifted to Node 22. So that run measured a machine that could bootstrap the product,
  on one day, once. **It is not a baseline.**
- **Therefore every failure in the 22 is "new" only in the sense that nobody ever looked.** There is no
  prior census result that means anything, so the artifact cannot answer "did this break recently" for any
  file in it. A reader who treats the 22 as a regression list is reading a history that does not exist.
- **THE READING RULE**: nothing in the census artifact is classified as regression-versus-longstanding
  **on the artifact alone**. The only instrument that can answer that question here is a **local control** -
  same machine, same harness, only the tree varying between `v0.40.0-beta2` and `4f4dce52`.
  - Those controls remain valid and are the reason two calls in this respin are trustworthy:
    `refocus-digests` fails at beta2 too (**longstanding**), and `self-leak-lint` passes at beta2 and fails
    at the tag with **beta2's own test file** (**regression**, and the only category-3 of the batch).
  - **The runner has no history worth comparing against.** Its verdicts are valid about the tree TODAY and
    say nothing about when a failure began.
- **Why this matters beyond bookkeeping**: the natural way to triage 22 failures is to ask which are new.
  That question has no answer here, and asking it anyway produces confident wrong answers - which is the
  shape this batch has recorded repeatedly (the summariser's severity counts; the ahead-count read off the
  adjacent row). **The available question is "is it real on the tagged tree", and it is answered per file
  by running it, not by comparing runs.**
- **Class closure**: NONE. A baseline begins to exist the first time the census is green; until then this
  rule stands.

### DRIFT-199-I003-033 - a duplication defect that was WRONG AT BIRTH rather than drifted, and byte-comparison is structurally blind to it (new entry in the guard-scope catalog; the sharpest form of DRIFT-199-I003-031)

**Every duplication defect this fortnight was DRIFT - copies that diverged over time. This one was wrong
the moment it was written, and no amount of byte-checking could ever have caught it.**

- **What happened**: the census provisioning was mirrored from `specrew-ci.yml` **step for step**, including
  `--from "git+...@v${SPEC_KIT_VERSION}"`. Those CI jobs run **ubuntu-latest**, where `${VAR}` is a shell
  variable that expands. The census runs **windows-latest** under **pwsh**, where `${VAR}` is a PowerShell
  variable that does not exist. It expanded to **empty**, `uv` tried to fetch tag `v`, and the job died
  before the sweep - so no diagnostics artifact was produced either.
- **The copy was TEXTUALLY FAITHFUL and CONTEXTUALLY WRONG.** The same characters mean different things in
  bash and pwsh. There was no moment at which the two agreed and then diverged; **the copy was defective at
  the instant it was made.**
- **AND THIS IS WHY BYTE-COMPARISON CANNOT CATCH IT.** `ProviderMirrorParity` and the mirror-parity checks
  this project relies on assert **byte-identity** between copies. That is exactly the right guard for
  copies that **execute in the same context** - the `extensions/` and `.specify/extensions/` mirrors, where
  identical bytes mean identical behaviour. It is **structurally blind** to copies that execute in
  DIFFERENT contexts, where identical bytes mean DIFFERENT behaviour and the correct copy is a
  *non*-identical one.
- **The unasked question, and it is the finding**: **nobody has ever asked which mirrors are which.** The
  project has same-context mirrors (byte-identity is correct) and cross-context mirrors (byte-identity is
  actively wrong), and one guard applied to both. A cross-context pair that passes byte-parity may be
  passing *because* it is broken.
- **It proved itself within minutes of being written down.** DRIFT-199-I003-031 recorded the duplication
  hazard; the very change that recorded it shipped this defect. That is not irony worth enjoying - it is
  evidence that naming a hazard does not protect against it, which is the batch's own repeated finding
  (*writing a rule down does not make you apply it*).
- **Resolution**: OPEN, beta4, and it is now TWO items rather than one: (a) the shared composite step from
  DRIFT-199-I003-031, which removes the copy; (b) **classify every mirror as same-context or
  cross-context**, and stop asserting byte-identity on the cross-context ones. (b) is the larger finding
  and would not have been visible without (a) failing.
- **Class closure**: NONE. The fix applied today (`${{ env.VAR }}`, evaluated by GitHub before any shell
  sees it) removes the instance by making the reference context-free, which is the right local answer and
  not the guard.

### DRIFT-199-I003-034 - self-leak-lint and mirror-parity have DIFFERENT SCOPES over the SAME content, and they compose only by accident (OPEN; beta4, same catalog as -033)

**The maintainer's question, answered at source**: during the mirror-drift window my `extensions/` copies
were clean of the six leaked ids and the `.specify/` copies still carried them - **and self-leak-lint was
green.** Did its scope ever include the mirrors?

- **NO.** `scripts/internal/lint-self-leak.ps1:32` defines the scanned surface as
  `$ConsumerDeployedPrefixes = @('templates/', 'squad-templates/', 'extensions/specrew-speckit/')`.
  **`.specify/extensions/specrew-speckit/` is not in it.** The linter never looked at the mirrors, so its
  green was accurate about what it checks and silent about half the content that ships to a project.
- **Two guards, different scopes, same content:**
  - **self-leak-lint** reads `extensions/...` and not `.specify/...`;
  - **mirror-parity** asserts `.specify/...` is byte-identical to `extensions/...` and says nothing about
    content.
  A file can therefore **pass one while the other would fail it**, and in the drift window exactly that
  happened - lint green on a clean primary, parity red on a mirror carrying the forbidden ids. **Only the
  census, running both, could see the disagreement.**
- **THEY COMPOSE, BUT BY ACCIDENT AND NOT BY DESIGN.** Together they are sound: parity forces the copies
  identical, and the lint checks one of them, so the pair is covered. **Nobody wrote that down, nobody
  designed it, and nothing states the dependency.** The moment parity is relaxed for any file - a
  legitimate move for a cross-context mirror, which DRIFT-199-I003-033 argues will be needed - **the lint's
  blindness becomes live and no guard covers the mirror's content at all.**
- **Not shipping-relevant today**: `.specify/**` has **zero** FileList entries, so the mirrors are not
  packaged. This is about the guard graph, not this tag.
- **Same catalog as -033**, and the two findings are one question: **which guard covers which surface, and
  do the answers overlap or merely appear to.** Beta4 gets both together.
- **Class closure**: NONE. The fix is a stated scope map - each guard naming the surface it covers, and a
  check that the union covers the deployed surface - which is beta4 work.

### DRIFT-199-I003-035 - the count went UP because the gate got STRONGER, and the arithmetic in the first report did not close (READING NOTE; the number goes in the release record)

- **Run 1: 22 failures. Run 3: 25.** A reader who sees `22 -> 25` will conclude the respin made things
  worse. **The opposite is true**, and the release record says so in those words.
- **Resolved FROM THE ARTIFACT, not from a summary** (the first report said "ten mirror failures", which
  did not reconcile):

| Bucket | Count |
| --- | --- |
| Survived from run 1 | 12 |
| Cleared | 10 |
| **New** | **13** |
| ... of which mirror-parity | **9** |
| ... of which non-mirror | **4** |

  12 survived + 13 new = 25. The four non-mirror entries are `conformance-material-turn-gate`,
  `release-model`, `session-orientation-rendered`, `workshop-material-packet-language`.
- **Why the total rose**: provisioning the runner to the product's own declared floor made the census
  **measure more of the tree**. `boundary-sync-markdownlint-gate` needs markdownlint and could not run
  before; now it does. **More measurement found more findings.** The gate did not weaken - it began
  working. Nine of the thirteen were a single defect of mine (mirrors not synced after the comment
  rewrite), caught immediately by byte-parity.
- **The provisioning is legitimate precisely because the floor is the product's own**: Node 24 is
  unchanged since beta2, so provisioning to it makes the census measure the tree. It would only be
  cheating if it provisioned **past** what a real consumer needs.
- **And the arithmetic error is the hand-enumerated-set pattern once more - this time in the report about
  it.** A count stated from memory rather than recomputed from the source. The rule this project already
  has applies to its own prose: **name the scope of a count, and recompute it from the artifact.**
- **Class closure**: NONE - this is a reading note and a correction.

### DRIFT-199-I003-036 - the line-ending class: three instances, three DIFFERENT mechanisms, and -029's rule only covered two (extends DRIFT-199-I003-029)

**Three line-ending defects this fortnight. They are a class precisely BECAUSE they do not share a
mechanism** - a single-mechanism bug is an instance; three routes to the same corruption is a class.

1. **Normalisation on READ, in a comparison** (DRIFT-014's neighbourhood): a deployed-manifest comparison
   normalised line endings, so a Windows checkout and an edited file compared equal.
2. **Rewriting on WRITE** (DRIFT-199-I003-029): text-mode IO converted CRLF to LF across four packaged
   files while claiming to change only comments. Caught by the inertness proof.
3. **A needle built in the wrong convention** (2026-09-02, `spec-not-yet-authored`): the test extracts a
   source block from `create-governed-feature.ps1` by `IndexOf` on a multi-line end marker built with
   `` `n `` separators. The file is **pure CRLF - 170 CRLF, 0 bare LF** - so the LF-form marker is absent
   and the CRLF form present. `IndexOf` returned -1 and the test threw *"the stub block could not be
   located"*, reporting its own defect as the script's.
- **-029's rule covered 1 and 2 and NOT 3.** *"Read and write bytes when the claim is byte-level"* was
  **satisfied** here: the match was byte-level, deliberately. The needle was built in the wrong convention.
- **THE RULE NEEDS ITS SECOND HALF**:
  > **When you byte-match, the needle must come from the haystack's own convention** - on Windows,
  > constructed from the file's own bytes, never typed as a source literal.
- **AND THIS ONE WAS WRONG AT BIRTH**, in DRIFT-199-I003-033's exact sense: that marker was never going to
  match, from the moment it was typed. It is the second wrong-at-birth defect of the respin, after the
  bash-in-pwsh copy, and it strengthens that entry's argument - **byte-comparison and byte-matching both
  fail silently when the two sides come from different conventions**, and neither drift-detection nor
  parity-checking can see it.
- **Where the false conclusion nearly landed**: the natural reading was that the test encoded a pre-fix
  shape of a script this batch changed - a plausible story that would have made T020's shipped fix look
  suspect. **The product was never at fault**; T020's stub behaviour is field-proved on a fresh feature.
  Fixed by normalising the haystack before the match, so the test no longer passes only where git happens
  to deliver LF.
- **Class closure**: NONE as an executable guard. The available control is the extended rule above.

### DRIFT-199-I003-037 - a census failure can arrive with NO readable reason at all, and the harness has nothing to say when it does (OPEN; beta4 diagnosability, harness-side)

**Established from the artifact, and it refines a hypothesis rather than confirming it.**

- **The two symptoms**:
  - `module-packaging-identity.tests.ps1` - exit 1, stdout **empty**, stderr **1,906 bytes beginning
    literally `#< CLIXML`**, carrying a serialized `S="progress"` record. PowerShell serializes a child's
    non-output streams to stderr as CLIXML, so progress records arrive as XML.
  - `authority-control-consumer-guard.Tests.ps1` - exit 1, **both streams empty**, captured output is a
    single newline (1 byte).
- **THE HYPOTHESIS WAS THAT THE HARNESS READS THE WRONG STREAM. It does not.**
  `tests/full-powershell-test-sweep.ps1:122` composes the report as **stdout + stderr concatenated**. Both
  streams are read. **Neither carried the test's assertion text.**
- **So the CLIXML is noise filling a gap, not the cause of it.** The corrected finding is narrower and
  more useful: **a test can fail in the census with no readable reason on any stream, and the harness
  reports that as either XML or silence** - and both look identical to a defect in the test. Two files, one
  harness-side diagnosability gap.
- **Both pass locally**, so whatever they emit locally does not survive the census's capture. The cause is
  not yet established and is NOT assumed - establishing it needs a local reproduction of the capture path,
  which is the next step and is deliberately not being guessed at here.
- **WHAT WAS DELIBERATELY NOT DONE**: setting `$ProgressPreference` in the census step would not reach the
  tests - the sweep spawns each file in its own `pwsh -File` child - and the one place it would reach
  carries an explicit warning that wrapping the child invocation **once converted a real failure into a
  false green**. That contract is not being touched to improve a diagnostic. The warning is worth more
  than the fix would have been.
- **Class closure**: NONE. The beta4 shape is that the census must never report a failure it cannot
  explain: if both streams are empty, say so as its own condition rather than presenting emptiness as the
  test's output.

### DRIFT-199-I003-038 - the release gate could not explain a failure anywhere in the tree: two opposite causes, one diagnosability hole, 36.7% of files silent and the rest reporting a helper's line number (SUPERSEDES the separate reads in -037 and the line-9 note)

**One entry, because the two halves are one gap seen from opposite sides.** Every file in the census
subject set is either a Pester file or a hand-rolled assertion script, and **neither kind could tell you
why it failed.**

- **HALF ONE - the Pester files report NOTHING, because structured failure data exists and was thrown
  away.** The sweep ran them with `Output.Verbosity='None'`, so a failing Pester file produced **zero
  bytes on both streams**. Reproduced exactly: `authority-control-consumer-guard.Tests.ps1` at
  `Verbosity='None'` gives **exit 1, stdout 0 bytes, stderr 0 bytes**; the same file at `Detailed` names
  the failure - *"DERIVED: every declared authority control has a production consumer - Expected $null or
  empty ... but got 'the'"*, Passed 6 / Failed 1. **The reason existed the whole time and the harness
  discarded it by configuration.**
- **HALF TWO - the script files report a line number that is always the same line, because no structured
  failure data exists at all.** They use hand-rolled asserts, so every failure surfaces as an exception at
  the line where the helper throws - `throw "FAIL: $Message"` inside `Assert-True`, or
  `function Fail(...) { throw ... }`. `workshop-state-transition-table` and `boundary-correction-ledger`
  both report **line 9** regardless of which assertion failed. **The line number carries zero diagnostic
  information; the `$Message` text is the entire signal.**
- **THE SHARE IS THE FINDING** (measured 2026-09-02): **147 of 401** census files are Pester -
  **36.7%**. So for more than a third of the tree the gate could report THAT a file failed and never WHY,
  and for the remaining 63% it reported a location that is the same for every failure in the file. **This
  is not a two-test annoyance. It is the diagnosability hole at the centre of the gate**, and it compounds
  the diagnosability priority already ruled top of beta4.
- **THE FIX IS STRUCTURAL, NOT A VERBOSITY FLIP** - measured before committing, because raising verbosity
  fixes silence by substituting flood, which is the same failure wearing the other mask:

| | failing file | passing file |
| --- | --- | --- |
| `Verbosity='Detailed'` | 1866 bytes, mostly Pester banner | **1579 bytes on a PASS** |
| `Verbosity='None'` + **`-PassThru`** | **557 bytes naming the test and its ErrorRecord** | **0 bytes** |

  Across 401 files a green run under `Detailed` would emit roughly **600KB of noise**. `-PassThru` returns
  a result object whose `Failed` entries carry their own `ErrorRecord`; the sweep now prints only those,
  keeps the console silent, and propagates the exit code by hand (`Run.Exit` would terminate before the
  reporting runs). **Real reason on failure, nothing on success, no firehose.**
- **The script half is NOT fixed here.** Giving hand-rolled asserts a structured failure location means
  either adopting Pester in 254 files or teaching the helpers to report their caller - both are beta4
  work, and neither belongs in a tag batch. **Recorded as owed, with the Pester half done.**
- **Sequencing note**: `module-packaging-identity` fails only in CI and **passes locally at both
  verbosity levels** (exit 0, Passed 9). Its cause is deliberately NOT being guessed at - the reporting
  fix above is the instrument that will make it state its own reason on the next dispatch. Chasing a
  CI-only failure blind, with the tool that removes the guesswork already in hand, is the expensive path.
- **THE EXIT-CODE CONTROL, run before the change was trusted and recorded because the failure direction is
  catastrophic.** Removing `Run.Exit=$true` means the child's exit code is now propagated BY HAND -
  `exit ([int]($r.FailedCount -gt 0))`. That is the same shape as the warning already in this file: wrapping
  the child invocation once converted a real failure into a FALSE GREEN. If the manual propagation drops a
  case, **147 files go permanently green and the gate reports success on a broken tree** - strictly worse
  than the silence it replaced, because **silence stops a publish and a false green does not.**
  **Two-direction control, run through the REAL sweep** (not a reimplementation of its command
  construction, which would prove only that the copy works):

| direction | exit | sweep ran | evidence |
| --- | --- | --- | --- |
| known-FAILING Pester (`authority-control-consumer-guard`) | **1** | yes | `FAILED: ...authority-control-consumer-guard.Tests.ps1 (pester, 9.61s)`, summary `failed=1` |
| known-PASSING Pester (`module-packaging-identity`) | **0** | yes | summary `failed=0`, `all named test files green` |

  **Both directions preserved. No false green.**
- **IT TOOK TWO FALSE RESULTS TO GET THERE, and both are recorded because the first looked like a
  finding.** (1) The control first invoked the sweep as `pwsh -File sweep.ps1 -ExcludeRelativePath $array`;
  **`-File` cannot bind an array**, so every element after the first became a positional argument, the
  sweep died on argument binding, and **both** cases exited 1 - rendering as one `OK` and one `WRONG`,
  which reads exactly like a defect in the exit code. (2) The second inlined 400 quoted paths into an
  encoded command and hit the Windows command-line length limit. **Neither ran the subject.**
  - **What made the third attempt trustworthy was a SUBJECT-RAN ASSERTION**: require the sweep's own
    summary line in the output before believing any exit code. Same lesson as the earlier control that
    read a proxy instead of the bytes - **a verification with no proof-of-execution cannot distinguish
    "nothing is wrong" from "nothing was measured".**
- **AND IT PRODUCED A REAL FINDING**: `module-packaging-identity` **passes through the sweep locally**
  (`failed=0`). Its census failure is genuinely **CI-only**, now confirmed through the real harness rather
  than by direct invocation - which is why the next step is to read run 5 rather than guess at a cause.
- **THE CONSEQUENCE, and it explains the gate's HISTORY rather than just its defect.** A gate that cannot
  say why is expensive to ever get green, and this project has paid that cost in the open: **the beta3 tag
  run failed on 2026-08-31 and the failure sat unread for two days** (DRIFT-199-I003-022). **Opacity does
  not merely slow diagnosis - it trains people to stop reading the signal.** A gate whose failures cannot
  be acted on becomes a gate nobody looks at, and then its red is indistinguishable from its silence.
  **That is the argument for why the owed script half is not cosmetic**: 254 files still report a location
  that is the same for every failure they contain, and every one of those is a future failure someone has
  to reverse-engineer before they can act on it.
- **THE TWO HALVES ARE NOT EQUIVALENT, and the record must not flatten them.**
  - **Pester: TOTAL.** Zero bytes on both streams. Nothing to read, nothing to act on, no way to tell a
    real failure from a harness fault.
  - **Script: DEGRADED BUT WORKABLE.** The real reason IS present - the `$Message` text names it - and only
    the *location* is wasted, because the hand-rolled helper is where the throw happens.
  - **After this fix the census can explain 147 files properly and still reports a useless line number for
    254.** This entry is **NOT CLOSED**, and a reader who sees the Pester half fixed should not infer
    otherwise.
- **Class closure**: PARTIAL, and deliberately labelled so. The Pester half is closed in the harness, with
  its exit-code direction controlled. The script half (254 files) and the empty-output condition are owed
  to beta4.
