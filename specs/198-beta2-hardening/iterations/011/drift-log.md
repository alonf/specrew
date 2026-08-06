# Drift Log — Iteration 011

Scope: FR-066, FR-068 (evidence half), FR-018. The zero-slack rule is binding — externally-arriving
work outside that scope is recorded here and routed to beta3 by default, never absorbed. The single
exception is an authorization-integrity defect, which stops for the maintainer's decision.

## T086 — FR-068 reproduction, RED-first evidence

**Harness**: file:///C:/Dev/specrew-beta2-hardening/tests/integration/fr068-verdict-demand-reproduction.tests.ps1
**Run**: 2026-08-03 against HEAD, before any correction. **Exit 1, two RED assertions — as required.**

### Half 1 — premature verdict demand: REPRODUCED

Fixture: the observed crossing exactly — `before-implement -> review-signoff`, with the
review-signoff stage carrying **0 of 4** of its artifacts (`review.md`, `reviewer-index.md`,
`code-map.md`, `coverage-evidence.md` all absent). Measured against the real conformance provider:

```text
MEASURED: review-signoff stage artifacts present in the fixture: 0 of 4 (none — the stage produced nothing)
MEASURED: provider emitted a stop-block: True; emitted a verdict demand: True; branch: legacy-unscoped
MEASURED: block text: "Specrew: boundary state is pending, but your last message did not expose the
          verdict marker for the pending boundary crossing. Render the full six-section re-entry
          packet NOW as your message, then stop again: ..."
RED: the provider demands a verdict for review-signoff while the stage has produced NO artifacts
RED: the demand names no missing artifact — a corrected surface must name what the stage owes
```

The defect is confirmed at the mechanism, not merely in the transcript: **nothing in the provider's
block warrant consults stage evidence**, so a stage that has produced nothing still draws a demand
for a boundary packet and verdict marker.

**Branch note, load-bearing for T090.** `Get-SpecrewPendingVerdictState` has two branches and they
word the demand differently. This fixture exercised the **legacy-unscoped** branch; the transcript's
verbatim *"Give the explicit verdict 'approved for …'"* comes from the **scoped** branch, which
requires a real `pending_crossing` record. **T090 must gate BOTH branches** — fixing only the scoped
wording would leave the same defect reachable through the unscoped path. Building the scoped-branch
fixture is carried into T090 rather than left implicit.

### Half 2 — contradictory composition: REPRODUCED EXACTLY

Two providers at the real co-occurring orders (conformance 40, navigator 50) driving the real
dispatcher:

```text
MEASURED: dispatcher exit=0; emit-directive present=True; forbid-directive present=True; separator present=True
```

One delivered message carries both *"emit the verdict marker as the LAST line"* and *"do NOT emit a
SPECREW-VERDICT-BOUNDARY marker"*, joined by `----- AND ALSO -----`. Concatenation, no precedence, no
conflict detection — the 2026-07-25T17:40:45Z shape, reproduced in a harness rather than cited from
a log.

Because SC-025's composition clause is scoped to beta3, half 2 is a **characterization record, not a
gate**: it asserts today's defective behaviour so beta3 inherits a proven reproduction. When beta3
resolves composition these assertions MUST fail; that failure is the signal to update them, not a
regression. The harness prints this inversion so a future reader cannot mistake it.

### Two fixture defects found and corrected before the evidence was trusted

Recorded because both are the failure mode this feature keeps re-learning, and the second was caught
only because the first made me re-check.

1. **Silence scored as success.** The first revision omitted the transcript. The provider cannot
   assess a turn it cannot see, so it emitted nothing — and the harness scored that silence as
   *"half 1 satisfied"*. That is DRIFT-198-I009-042's shape exactly: a green that measures nothing.
   Corrected by making the transcript part of the fixture **and** by making "no block at all" a
   third outcome — `INCONCLUSIVE — a FIXTURE defect, not evidence` — rather than folding it into
   pass/fail.
2. **A surface form asserted instead of the behaviour.** The second revision matched only the scoped
   branch's verbatim phrase, so it scored a real unscoped verdict demand as *"no demand"* — and
   reported PASS while the defect was live in the output it had just captured. Corrected by
   detecting the behaviour across both known surface forms and recording which branch fired. This is
   what surfaced the branch note above, which changes T090's scope.

**Neither defect was found by the harness failing.** Both were found by reading the measured output
against the claim being made about it. The lesson is the one iteration 010 recorded and it did not
transfer on its own: a passing assertion is not evidence until you have checked what it measured.

## T087 — FR-066 fixtures, RED-first evidence

**Harness**: file:///C:/Dev/specrew-beta2-hardening/tests/integration/fr066-first-boundary-arrival.tests.ps1
**Run**: 2026-08-03 against HEAD, before any correction. **Exit 1, three RED assertions.**

### Case 1 — sync reports success after failing to establish the crossing: REPRODUCED

Fixture: a genuine pre-bootstrap project — schema `v1`, no `boundary_enforcement` block, arriving at
its first `specify` boundary. Measured against the real `sync-boundary-state.ps1`:

```text
MEASURED: sync success=True; has_pending=False; marker=(null); artifact_written=False; degrade-warning emitted=True
RED: sync reports SUCCESS with has_pending=false and no artifact, after failing to establish the
     crossing — indistinguishable from a legitimate "no pending verdict"
RED: the failure is surfaced only as a Write-Warning — a warning is not a state a caller can branch
     on (NFR-002: legitimate paths announce themselves)
```

`Set-SpecrewPendingBoundaryCrossingScope` throws, the `catch` at `sync-boundary-state.ps1:1660`
swallows it to a warning and sets `HasPendingVerdict = $false`, and the sync then returns success.
**The two states — "no verdict is pending" and "I could not record the crossing" — are the same
value on the wire.** No caller can distinguish them, which is precisely why no consumer branches on
the failure.

### Case 2 — the premise was wrong, and the measurement is worse than the premise

The case was authored expecting the Antigravity *"headers but no marker"* shape. Measurement says
otherwise:

```text
MEASURED: provider exit=0; faulted=False
MEASURED: provider blocked=False; announces a BOUNDARY stop=False; supplies marker text=False
RED: the provider runs and emits NOTHING at a first boundary whose crossing was never established
```

The provider does not emit a marker-less boundary block on an un-bootstrapped project — **it runs
successfully and says nothing at all.** So a brand-new project's very first boundary passes with no
enforcement surface whatsoever, while sync reports success. That is quieter and worse than the shape
the case was written to catch: a marker-less block at least tells the human a boundary exists.

The marker-less block belongs to a **different** state — enforcement present, crossing scope absent —
which T086 already exercises. Recorded as measured rather than reshaped to fit the premise; this is
the same discipline that disproved DRIFT-198-I009-042.

**Consequence for T088/T089**: the correction cannot be only "supply the missing marker". A first
arrival that cannot be recorded must become a state the provider can see and speak to. Silence is
the current behaviour, not an absence of behaviour.

### Requirement audit before T088 builds — FR-066 did NOT cover the measured shape

Maintainer-directed check, 2026-08-03: read FR-066's text against the silent-pass shape before
building the reshaped correction. **Result: the text did not cover it, and it was amended rather
than reinterpreted.**

Clause-by-clause against the measured behaviour:

| FR-066 clause | Silent shape |
| --- | --- |
| record established BEFORE the first packet renders | **not triggered** — no packet renders |
| a packet MUST NOT create the state it reports | **not triggered** — no packet |
| the arrival sync MUST establish the cursor baseline | **VIOLATED** |
| a packet rendered ahead of sync presents no options/marker | **not triggered** — no packet |
| "recorded mechanically" means before the human is asked | **not triggered** — no human is asked |

**Four of five MUSTs are conditioned on a packet rendering.** Only one is violated, and the text is
silent on what must happen when the sync *cannot* establish the record. Nothing required the failure
to be distinguishable from "no pending verdict"; nothing required any surface at all in the
unrecorded state — yet both are exactly what T088/T089 must build. Building them under the unamended
text would have been an unstated broadening.

Corroborating the diagnosis: FR-066's own Evidence block cites three first-arrival failures, and
**all three are emit-the-wrong-thing failures** — a wrong block (DRIFT-198-I008-055), a forced
generic packet (DRIFT-198-I008-060), headers without a marker (the Antigravity gap). The requirement
was drafted against that family; the silent-pass family was never in view.

**Amendment applied** under the maintainer's conditional authorization, using the SC-025
authorized-touch pattern: two MUSTs added to FR-066 — the failure must be a distinguishable state
and MUST NOT report success, and the surface MUST speak and name what is missing. Recorded in the
spec's Clarifications under Session 2026-08-02/03.

### Two more fixture defects, both caught by the INCONCLUSIVE guard

The guard adopted from T086 paid for itself immediately — twice, on its first use:

1. **Wrong un-bootstrapped shape.** The fixture used schema `v2` with no enforcement block.
   `NeedsMigration` is `Exists AND schema in (v0,v1) AND enforcement is null`
   (`shared-governance.ps1:1797`), so a v2 context with no block is **malformed**, not
   un-bootstrapped — the ledger read throws fail-closed long before the crossing path. Reported
   INCONCLUSIVE, not passed.
2. **Missing `.squad/active-features.yml`.** The specify boundary upserts a feature claim; without
   the directory the atomic write threw and the probe again never reached the decision. Reported
   INCONCLUSIVE, not passed.

Both would have been silent false results under a two-outcome harness: the first would have looked
like "sync correctly refused", the second like "no boundary surface needed". **Three of the four
fixture defects found across T086 and T087 would have read as passes.** The third outcome is not
bookkeeping — it is what separates a measurement from a wish.

## T088 + T089 — FR-066 corrections, and the fix that changed nothing

**T087 is now GREEN on all three assertions** (`exit 0`), from three RED. Both amended MUSTs hold.

### T088 (sync side) — the unrecordable crossing is a branchable state

```text
MEASURED: boundary_record_status=unrecordable; failure_reason_present=True; is_first_boundary=True
MEASURED: sync success=False; has_pending=False; artifact_written=False
PASS: sync distinguishes "could not establish the crossing" from "no pending verdict"
PASS: the failure travels as a branchable state, not only as console text
```

`RecordStatus`/`FailureReason` now travel from the catch, `success` is false when the record could
not be established, and **`IsFirstBoundary` has a consumer for the first time** — it was computed in
`shared-governance.ps1` and read by nothing anywhere in the tree.

### T089 (provider side) — the surface speaks and names what is missing

```text
MEASURED: provider blocked=True; announces a BOUNDARY stop=False; supplies marker text=False
MEASURED: block text: "BOUNDARY REACHED BUT NOT RECORDABLE: this project arrived at 'specify'
          before its boundary approval ledger was initialized, so the crossing could not be
          recorded and no verdict can be captured for it yet. Missing: the project's
          boundary-enforcement state ..."
PASS: the provider does not present a boundary crossing that was never established
```

A new `boundary-unrecordable` status in `Get-SpecrewPendingVerdictState`, and a matching block kind
in the provider — deliberately **not** `'boundary'`, so no approval options and no verdict marker are
ever offered. Both halves are load-bearing: silence hides the boundary, and a marker would capture a
verdict against a crossing that does not exist.

### The correction that looked right and changed nothing

Worth its own entry, because it is a new failure shape for this iteration's record.

The first T089 revision was **complete and correct in isolation** — the primitive returned
`boundary-unrecordable` when probed directly, and the provider had a matching branch. Re-running T087
showed the provider still silent. The cause: the transcript-read gate keys on `$hasPending`, and this
state is deliberately **not** pending. So `$lastAssistantText` stayed null, `$canAssess` was false,
and `$blockWarranted` could never become true. **The branch was unreachable.**

Diagnosis went through the provider's own diagnostic journal — which was not written either,
narrowing it to a path that never reached the journal write. The fix moves `$boundaryUnrecordable`
up beside `$hasPending` and adds it to the gate.

**A review of the diff would have approved it.** The code was right; the reachability was not. This
is the same family as T082's containment claim — locally correct, and wrong about coverage — and it
was caught only by re-running the fixture against the changed code rather than trusting the change.
That is the third distinct instance in this iteration of *the green tells you nothing until you
check what it measured.*

### Regression

`pending-verdict-stop-artifact`, `pending-verdict-surface`, `boundary-ratchet`,
`conformance-stop-intent-wiring`, `dispatcher-stop-block` — all exit 0.
`conformance-detection.tests.ps1` — **all 76 cases pass**.

**Mirror parity maintained**: `shared-governance.ps1` and `specrew-conformance-provider.ps1` are
byte-identical between `extensions/specrew-speckit/scripts/` and the deployed
`.specify/extensions/specrew-speckit/scripts/`, verified by hash. Provider-mirror divergence is a
recurring defect class in this feature.

## T090 — FR-068's evidence half, delivered

**T086 half 1 is GREEN.** The demand is gone and replaced by a message naming the missing artifact:

```text
MEASURED: provider emitted a stop-block: True; emitted a verdict demand: False; branch: none
MEASURED: block text: "BOUNDARY NOT READY FOR A VERDICT: 'review-signoff' has produced none of the
          evidence its stage owes, so there is nothing to approve yet. Missing: review.md. A verdict
          recorded now would authorize an empty increment, and the ledger could not tell it apart
          from an approval of real work — so no approval options and no verdict marker are offered."
```

Both branches gate from **one shared helper** (`Set-SpecrewStageEvidenceGate`) so they cannot drift —
fixing only the scoped branch would have been the T082 shape exactly.

The contract is authored as a durable artifact per the maintainer's instruction:
file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/boundary-evidence-contract.md

### The third surface, found by asking who else consumes the marker

Suppressing the demand in the provider was not sufficient. **The pending-verdict stop artifact is what
the packet renderer reads the marker out of**, and it composes boundary/approval-phrase/marker from
the crossing without consulting the evidence flag — so a suppressed demand would still have handed
over a marker for an empty increment. That is a partial correction under a complete-sounding claim,
one surface over from T082's. The artifact writer is now gated too.

### The fixture-flip cost was real, and smaller than estimated

Five suites had fixtures that represent a project *at* a boundary without the evidence that boundary
owes. Each correctly started measuring the gate instead of its own subject. All were seeded:
`pending-verdict-stop-artifact` (clarify + the iteration set), `conformance-detection` (cases 16b and
16pb), `conformance-stop-intent-wiring` (case d). **The predicted ~70–80 assertion blast radius did
not materialize — because the design keeps `HasPendingVerdict` true.** That is the re-estimate's
design rejection paying off measurably, not just in argument.

One method note worth keeping: seeding inside the shared `New-Spec` helper of the 76-case suite
perturbed an unrelated intake case. **A shared fixture helper is too blunt an instrument for a
behaviour only some cases depend on** — reverted to a named `New-BoundaryStageEvidence` applied
per-case, on purpose.

### Regression

`fr068-verdict-demand-reproduction`, `fr066-first-boundary-arrival`, `pending-verdict-stop-artifact`,
`pending-verdict-surface`, `verdict-capture-blocks`, `boundary-correction-ledger`, `boundary-ratchet`,
`HookVerdictCapture`, `dispatcher-stop-block`, `launch-mode-boundary-enforcement`,
`boundary-sync-atomic`, `conformance-stop-intent-wiring` — all exit 0.
`conformance-detection` — **all 76 cases pass.** Mirror parity verified by hash.

## DRIFT-198-I011-001 — an unregistered suite fails on HEAD, and CI cannot see it

- **Status**: open; **routed to beta3 under the zero-slack rule, NOT absorbed**
- **Severity**: minor-to-major — an unrun test is an unenforced invariant
- **Observed**: `tests/unit/boundary-authorization-prompt-truth.tests.ps1` exits 1 on HEAD:
  *"Status: Approved with verdict evidence should pass validation … No iteration directories with
  plan.md yet."*
- **Not mine, and proven so**: stashing every T090 change and re-running reproduces the same
  failure. The cause is a validator/fixture interaction, not the stage-evidence gate.
- **Why CI is green anyway**: the suite is **not registered** in
  `tests/f198-regression-suite.ps1`, so nothing runs it. That is the finding — the failure is
  incidental, the invisibility is structural, and it is the same class as this iteration's own
  deliberate-RED registration obligation on T092.
- **Rule applied**: outside the FR-066 / FR-068 / FR-018 scope and not an authorization-integrity
  defect, so it is recorded and routed rather than fixed here. **011 records; it does not absorb.**
- **Required correction (deferred to beta3)**: fix the suite, register it, and sweep for other
  unregistered test files so the registry's coverage is a fact rather than an assumption.

## FOR THE RETRO — a practice that has earned promotion to shipped method guidance

**Flagged for the retro facilitator by maintainer instruction, 2026-08-03.** This is a process
finding, not a test note, and it should not be discovered by reading two tasks' evidence.

### The running total

**Three of the four fixture defects found across T086 and T087 would have read as PASSES** under an
ordinary two-outcome harness:

| # | Task | Defect | Two-outcome reading |
| --- | --- | --- | --- |
| 1 | T086 | transcript omitted; provider emitted nothing | "half 1 satisfied" ✅ **false pass** |
| 2 | T086 | asserted the scoped branch's phrase; unscoped demand missed | "no demand" ✅ **false pass** |
| 3 | T087 | schema `v2` used for the un-bootstrapped shape; ledger threw fail-closed | "sync correctly refused" ✅ **false pass** |
| 4 | T087 | `.squad/active-features.yml` absent; claim upsert threw | INCONCLUSIVE (caught by the guard) |

**The INCONCLUSIVE third outcome has now paid for itself four times in two tasks.** That is past the
threshold where a practice becomes a rule.

### Two candidate rules for the shipped method guidance

Both belong in
file:///C:/Dev/specrew-beta2-hardening/docs/methodology/lifecycle-discipline.md, not only in this
feature's record — every downstream consumer writing a RED-first fixture hits the same trap.

1. **INCONCLUSIVE is a required third outcome.** A harness MUST distinguish *the defect is absent*
   from *the probe never reached the code path*, and report the latter as a fixture defect. Folding
   "no signal at all" into pass/fail is precisely how DRIFT-198-I009-042's first harness revision
   lied, and it recurred twice more here on the very next attempt.
2. **Read the measured output against the claim being made about it.** Defects 1 and 2 above both
   *passed their own assertions*. **Neither was found by a harness failing** — the exit code was
   green, and would have stayed green. They were found by looking at what the green actually
   measured. This is the practice that made the -042 lesson transfer; the lesson did not transfer
   on its own the first time, and the record should say so plainly.

The second rule is the harder one to institutionalize, because it cannot be automated: it is a
discipline about not trusting your own instrument. The first rule is its mechanical proxy and should
ship as a checkable convention.

## Deliberately NOT registered in the regression suite yet

`tests/f198-regression-suite.ps1` does **not** register this harness, and that is intentional: it is
RED by design until T090 lands, and registering it now would turn the whole registry red and break
the method rule that a red workflow is a stop.

**Obligation on T092**: before Iteration 011 closes, this harness MUST be registered in the suite and
MUST be green on half 1. An unregistered test is one nobody runs — leaving it out permanently would
convert a deliberate RED into a silently skipped one, which is the same class of defect as the
`.pending` scaffolder byproducts.

The same applies to T087's harness
(file:///C:/Dev/specrew-beta2-hardening/tests/integration/fr066-first-boundary-arrival.tests.ps1),
RED by design until T088/T089 land. **Both harnesses are registered together at T092, and neither
closes the iteration while unregistered.** The maintainer's ruling of 2026-08-03 stands as written:
a deliberate RED must never quietly become a skipped test.
