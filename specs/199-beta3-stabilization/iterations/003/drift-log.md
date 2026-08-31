# Drift Log: Iteration 003

**Schema**: v1
**Total drift events**: 10 (DRIFT-199-I003-001 through -010)
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
- **Resolution**: OPEN until the tag-candidate walk runs. The build is prepared and verified (commit
  `4f4dce52`, content `21c05ad9...`, 414 files byte-verified, stamp verified against installed contents);
  the walk directory `C:\Tempeta3-tagwalk` is confirmed not to exist and is visually distinct from every
  neighbour, which matters after DRIFT-199-I003-004.
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
- **Pending, and it upgrades one more row when it lands**: the specify verdict, when captured, adds
  **typed-turn verdict capture on copilot** to the evidence.
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
