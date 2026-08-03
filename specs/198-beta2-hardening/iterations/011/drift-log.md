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
