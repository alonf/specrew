# Erratum: Iteration 001 hardening-gate runtime-evidence disposition

**Schema**: v1
**Recorded**: 2026-08-29
**Status**: erratum — outside the seal, filed in the **active** iteration (002)
**Subject**: `quality/hardening-gate.md`, the four concerns carrying `RuntimeEvidenceStatus: pending-post-implementation`
**Authority**: maintainer instruction, 2026-08-29 — *"do not edit the sealed gate… record it as an erratum
outside the seal, the way proposal discipline already handles shipped work: preserve the body, record the
pointer."*

---

## Why this file exists instead of an edit

Iteration 001 is **closed and sealed**. Its hardening gate records four concerns as `addressed` with
`RuntimeEvidenceStatus: pending-post-implementation` — the honest **planning-time** posture, written before
implementation and unchanged since. What changed is that iteration 001 now claims `complete`, and a complete
iteration is held to a higher bar than a running one; the gate's own follow-through requirement therefore
began firing, and it fired against the *review of iteration 002* (DRIFT-199-I002-015).

Two things were refused as remedies:

- **Editing the sealed gate.** That is editing preserved history. The validator refuses it, and the maintainer
  has ruled it is the human's act, not a session's. A `pending` that silently becomes `verified` after the
  fact is precisely the record a reader cannot trust.
- **Leaving it undispositioned.** The four concerns owe an honest answer, and the answer exists — it just
  cannot be written inside the seal.

So the body is preserved byte-for-byte and the disposition is recorded here, with the pointer carried in the
verification plan's re-pointed command label. This is the same discipline `proposals/` already applies to
shipped work.

**Why this file lives in iteration 002 and not beside the gate it discusses.** It was first written into
`iterations/001/`, and the validator refused it: *"Closed iteration … was edited after its closeout seal."*
That refusal is correct and it is not a technicality — **adding** a file to a sealed directory is still
changing what the human's verdict accepted, and a reader who diffs the closed iteration would find something
the signoff never saw. The validator's own message names the right home: *"record what needs to change as a
drift entry in the ACTIVE iteration's drift-log.md, where new facts belong. Deliberately superseding closed
history is the human's act, not a session's: until the governed supersede mechanism ships, their explicit
instruction recorded in the active drift log is the path."* That is exactly the shape here: the maintainer's
explicit instruction is recorded in `iterations/002/drift-log.md` (DRIFT-199-I002-015), and this document is
its long form. "Outside the seal" is served more faithfully by a file that is not inside the sealed directory
at all.

## Scope of this erratum — what it does and does not claim

- It **does** record, per concern, what runtime evidence exists on the shipping tree as of 2026-08-29.
- It **does not** amend the sealed gate, change its `Overall Verdict: ready`, or convert any
  `pending-post-implementation` marker to `verified`. Those strings still say what they said.
- It **does not** re-open iteration 001 or claim its review covered these. Iteration 001's review-signoff
  covered the tree at signoff time; the evidence below accrued across 001's implementation and 002's, and is
  named here with its source so a reader can check rather than take it.
- It is **not** a substitute for the beta4 item this exposed (below).

---

## Per-concern disposition

### 1. `security-surface` (security)

**Gate's expected controls**: reparse-tag allowlist fail-closed (cloud family only, hydrate-then-hash-verify;
junction/symlink refusal untouched); continuation authority human-only (single-run grants, agents cannot mint);
`env_refs` names-only pass-through; capture authorizes only from a human verdict turn.

**Runtime evidence that now exists** — registered suites, all in `.specrew/release-gate-suites.txt` and run by
the class-guard and release-gate lanes:

- `tests/continuous-co-review/unit/reparse-tag-policy.Tests.ps1` and
  `reparse-admission-premise.Tests.ps1` — the allowlist and the premise it admits on.
- `tests/continuous-co-review/unit/worktree-containment.Tests.ps1`,
  `inline-reviewer-containment.Tests.ps1`, `isolated-task-containment.Tests.ps1`,
  `tests/unit/pretag-slice4-capture-containment.tests.ps1` — the containment roots.
- `tests/continuous-co-review/unit/human-authority-store.Tests.ps1` and
  `review-authority-store-mutation-gate.Tests.ps1` — that agents cannot mint authority.
- The verdict-capture fabrication fixtures (T032 and the 23 not-approve cases), which the verification plan's
  class-guard lane runs **first**, explicitly because this is the one failure direction that is
  unrecoverable: a false authorization in the ledger is indistinguishable from a real one.

**Honest disposition**: **substantially verified at runtime**, by suites that exist, are registered, and run on
every slice touching this machinery. The one control still carrying no automated runtime proof is the
**OneDrive hydrate-then-hash-verify path on a real cloud-backed file** — the gate's own row anticipated this
and named it as the single manual measurement. It remains manual.

### 2. `error-handling-expectations` (robustness)

**Gate's expected controls**: structured terminal outcomes per failure class; authority contradictions fail
closed and loudly; consumer-shaped failure messages naming the missing piece and the next step; positive and
negative fixtures per failure mode.

**Runtime evidence that now exists**:

- `tests/continuous-co-review/contracts/infrastructure-failure.Tests.ps1` — the terminal-outcome contract,
  including that an infra failure publishes an honest run record **without consuming allowance** (FR-013's
  central claim).
- `tests/continuous-co-review/unit/review-spend-allowance.Tests.ps1` and `time-extension-budget.Tests.ps1`,
  `tests/unit/budget-resolution.tests.ps1` — the spend side of the same rule.
- Iteration 002 added a live exercise of exactly this contract that no fixture could have staged: the covering
  round was authorized, its pre-review verification failed, the reviewer was never invoked, and **zero rounds
  were consumed** (`rounds_used` unchanged on campaign `cmp-199-beta3-stabilization-i002`). The
  invoked-only spend rule behaved as designed on its first unplanned exercise. See iteration 002's
  `plan.md` countable-measures block.
- The refusal-message standard is now a *tested* requirement rather than a planning aspiration: FR-028 and
  FR-033's refusal clause, with `tests/integration/lens-acknowledgment.tests.ps1` and
  `spec-not-yet-authored.tests.ps1` asserting the message says the human's work is safe, names one action,
  and does not assert that Specrew is broken.

**Honest disposition**: **verified at runtime**, and strengthened after 001 sealed. The consumer-shaped-message
half was the weakest part at 001's close and is the part iteration 002 turned into fixtures.

### 3. `retry-idempotency-requirements` (resilience)

**Gate's expected controls**: pause/decision facts written with atomic `FileMode.CreateNew` (identical existing
fact = idempotent success; conflicting fact = corruption, fail closed); no secret provider retries — every
rerun is a new `run_id` consuming a visible human-authorized slot; schema/invariant failures never retried.

**Runtime evidence that now exists**:

- `tests/bootstrap/MarkerAtomicWrite.Tests.ps1` — the atomic-write primitive.
- `tests/integration/boundary-sync-atomic.tests.ps1` and `boundary-sync-atomicity.tests.ps1` — the same
  discipline where boundary state is written.
- `tests/continuous-co-review/unit/review-authority-store.Tests.ps1` — the store's write-conflict semantics
  that the pause fact inherits.

**Honest disposition**: **verified for the write primitive and the store semantics.** The specific
*conflicting-pause-fact-is-corruption* branch is exercised by the store's conflict fixtures rather than by a
fixture staged as a pause collision; that is a real, if narrow, gap, and it is stated here rather than papered
over. The "no silent retries" half is verified structurally — every rerun mints a new `run_id`, which the
allowance suites assert.

### 4. `test-integrity-targets` (verification)

**Gate's expected controls**: FR-to-named-fixture mapping recorded per task; RED-first ordering per FR-023;
paired honesty tests for every economics invariant; negative-path coverage for refusals; the one manual
measurement recorded with a transcribed, scoped proof line.

**Runtime evidence that now exists**:

- The registry is real and counted: **365 suites** in `.specrew/release-gate-suites.txt`, with a **membership
  guard** that fails when a suite is written into no lane — added 2026-08-26 precisely so the next suite
  cannot be written into silence.
- RED-first mutation proving is now a *method rule* (FR-033) rather than a per-task intention, and iteration
  002 carries eleven mutation-proved suites.

**Honest disposition**: **verified, with one correction that belongs on the record.** Iteration 001's own
coverage-evidence artifact carries a form-vs-meaning WARNING — 13 declared tasks against a 462-file diff — and
that warning was accurate. It is not retracted here. What can be said is narrower and true: the FR-to-fixture
mapping exists, the registry is counted rather than asserted, and the counting guard that would have caught
the 45-suites-against-384 miscount (DRIFT-199-I001-134) now exists.

---

## What this erratum does **not** resolve — the beta4 item

**"A closed iteration gates its successor's review."** Recorded 2026-08-29 at the maintainer's instruction as a
beta4 item. The mechanism: a verification plan that names a specific iteration by number goes stale the moment
the next one opens, and an iteration that transitions to `complete` retroactively raises the bar on a gate
written under planning-time rules — so closing an iteration correctly can block the review of the tree that
succeeds it. Neither half is a defect in the gate or in the closeout; it is a **missing hand-off**: the
closeout should re-point the verification plan, or the command should name the *active* iteration rather than a
number, and a `pending-post-implementation` concern should have a defined disposition step at closeout rather
than becoming a permanent blocker on everything after it.

Full account: `specs/199-beta3-stabilization/iterations/002/drift-log.md`, DRIFT-199-I002-015.
