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

## T092 certification, attempt 1 — DID NOT RUN, and did not cost a round

**Result**: `preflight-failed:harness`, `runtime_outcome: preflight-failed`, `Invoked: False`,
`harness_id: "unselected-harness"`, elapsed **614.5s**. Run `run-f198-i011-230717a9-certify`.

**No allowance was spent — verified against the facts, not inferred.** The campaign store shows
`spend/` **empty** and `releases/` holding one record with `reason: "preflight-failed:harness"`. The
pre-invocation release returned the slot exactly as FR-058 requires, so the grant
(`certification-i011-auth-integrity-2026-08-06`, 1 slot) is intact and **the 3-round cap is
untouched**. This is the allowance model working correctly under failure: no provider was invoked,
so nothing was charged.

**Cause: mine.** The invocation omitted `--host`, so no reviewer harness ever resolved. The catalog
has `codex` allowed and installed at rank 85 — the reviewer of record, and the one that preserves
independence while `claude` is the code writer (`copilot`'s row is explicitly suspended for exactly
that reason).

### DRIFT-198-I011-002 — preflight burns the FULL timeout to discover it selected no harness

- **Status**: open; **routed to beta3 under the zero-slack rule** (outside FR-066/FR-068/FR-018 and
  not an authorization-integrity defect)
- **Severity**: minor mechanism, real consumer cost
- **Observed**: with no host resolvable, the run sat `requested` for **614.5 seconds** and then failed
  preflight. `harness_id` was `unselected-harness` from the first written fact onward — the
  `requested.json` and `reserved.json` records both carry it — so the condition was **knowable at
  reservation time**, before any waiting began.
- **Why it matters**: ten minutes of wall clock to learn that a required argument was missing. A
  consumer hits this on their first misconfigured review and has no signal for the whole budget; the
  failure text arrives only after the timeout it never needed to spend. It also interacts badly with
  the round ceiling's UX: the run looks like it is reviewing.
- **Required correction (deferred)**: fail preflight IMMEDIATELY when no harness resolves, naming the
  unresolved host and the `--host` flag. The `unselected-harness` sentinel already exists and is
  already written into the reservation record — nothing new needs detecting, only checking.

## T092 certification, attempt 2 — RAN, and did NOT certify

`run-f198-i011-ee78a818-certify`, harness `codex-cli-file-primary`. **Invoked: True, Completion:
complete, Currentness: current, validated-findings 4, `can_approve_current: false`.** Round 1 of 3
spent — legitimately this time.

**Two blocking and two major, ALL inside FR-066/FR-068, all defects in the corrections just
delivered.** Nothing routes to beta3 under the zero-slack rule; this is in-scope rework.

**Every finding was verified against the source before being accepted** — the -042 discipline, run
on a reviewer this time rather than on myself. All four hold.

### DRIFT-198-I011-003 (BLOCKING) — evidence is checked on the live tree, the crossing is bound to an immutable one

The pending crossing verifies against its immutable boundary commit/tree.
`Get-SpecrewBoundaryStageEvidence` checks artifacts with `Test-Path`/`Get-Content` on the **mutable
live filesystem**. So: the artifact is absent, the message says produce it and stop again, the agent
produces it — and on the next stop the *same old* `pending_crossing` is still valid while the live
file now passes the gate. **The marker then authorizes a commit/tree that never contained the
artifact**, and the artifact may be uncommitted entirely.

True by construction: I used `Test-Path` against a path derived from persisted config, with no
reference to the crossing's `artifact_state_id`. **This is a time-of-check defect that turns my own
correction into a false-authorization path** — the precise failure FR-068 exists to prevent,
reintroduced by FR-068's fix.

### DRIFT-198-I011-004 (BLOCKING) — the recovery instruction authorizes the crossing it failed to record

T089's `boundary-unrecordable` message tells the user to run the start/bootstrap path. Boundary sync
has **already persisted `session_state.boundary_type`** before the crossing write fails. On recovery,
`specrew-start.ps1:2643` calls `Initialize-SpecrewBoundaryEnforcementState -CurrentBoundary
$boundaryTypeForInit` — creating `last_authorized_boundary` **equal to the current boundary, with no
verdict history**. Verified at that line.

So the failed first crossing is converted into an *authorized* cursor and disappears, instead of
being mechanically recorded for a human verdict. **FR-066's core invariant, defeated by FR-066's own
remedy.** The correction I shipped to stop a boundary passing silently instead makes it pass
*authorized*.

### DRIFT-198-I011-005 (MAJOR) — the gate demands a verdict when evidence could not be VERIFIED

My fail-open design returns `Satisfied=true / Checked=false` for unknown boundaries, unresolvable
feature paths, missing iteration identity and every read error — and `Set-SpecrewStageEvidenceGate`
then leaves the ordinary demand intact. FR-068 says a demand MUST NOT be emitted unless the evidence
exists; "could not check" is not "exists".

Worse, and verified: **`Get-SpecrewBoundaryStageEvidence` never uses its `$ProjectRoot` parameter** —
it appears exactly once, in the param block — and the caller passes `'.'`. The function trusts the
persisted absolute `feature_path`, so a stale path into another checkout can satisfy the gate with
**foreign artifacts**. I wrote a containment bug into a containment-adjacent gate.

### DRIFT-198-I011-006 (MAJOR) — a heading or negated prose falsely satisfies clarify

The contract requires a dated session block or a recorded skip-with-rationale. The implementation
accepts any `## Clarifications` heading and a loose skip regex. Verified: the string
`clarifications must not be skipped` matches my pattern and marks the stage satisfied. A placeholder
heading or an empty section does the same.

**The contract was ruled correct and the implementation does not enforce it** — the gap is between
the authored rows and the matcher, not in the rows.

### Assessment, stated plainly

Three of these four are defects *in the corrections themselves*, and two of those hand back the exact
false-authorization the requirements exist to prevent. This is the "locally right, wrong about the
consequence graph" shape a third time — but this round it was the reviewer that walked the graph, not
me. The reproduction-first and consequence-interrogation practice that killed two wrong designs
pre-construction did not extend to the design I did ship.

## Option 3 PRICED, 2026-08-06 — sane, and the expectation holds

Bounded pricing pass before any code, per the ruling. **The re-cut reuses machinery that already
exists, in the same file as the defective gate.**

| Evidence for the price | Finding |
| --- | --- |
| `artifact_state_id` **is already a git tree id** — `Get-SpecrewGitArtifactStateId` resolves `<commit>^{tree}` and the crossing stores it. It is available at the gate today; nothing new is computed. | 1 |
| `Test-ReviewCitedFilesInTree` (same file) already does the exact presence pattern: resolve the tree hash, `git ls-tree -r --name-only`, normalize separators, and set a **`TreeResolved`** flag. That flag is precisely the fail-closed signal finding 3 asks for — "the tree could not be read" is already distinguishable from "the file is absent". | 1, 3 |
| Content reads for the clarify row have a pattern too (`cat-file blob` in the review target port); `git show <tree>:<path>` is the one small addition. | 4 |
| Paths become **tree-relative** and are read via `git -C $ProjectRoot`, so there is no absolute live path left to redirect — the foreign-checkout hole closes structurally rather than by validation. | 3 |

**Price: 5.5 SP.**

| Work | SP |
| --- | ---: |
| `artifact_state_id` re-cut — read evidence from the bound tree, tree-relative paths, fail-closed on unreadable tree | 2.0 |
| Recovery instruction + start/bootstrap DETECTS an existing failed crossing and refuses to cursor over it (bootstrap's initialize-at-current semantics deliberately untouched) | 1.5 |
| Tightened clarify matcher — dated session structure or a positive structured skip record | 0.5 |
| RED-first fixtures for all four, proven red before each fix | 1.5 |

Recertification is already inside T092's existing 2.5 SP.

### Budget arithmetic, uncompressed

| | Before | After |
| --- | ---: | ---: |
| Iteration 011 planned | 20.0 | **25.5** |
| Capacity | 20 | 20 |
| Position | at cap | **OVER by 5.5** |

**This is internal rework of 011's own deliverables — the zero-slack rule routed EXTERNAL work, and
this is not that.** The overrun is recorded at the number it actually is. Compressing these estimates
to make the cap appear to hold is exactly what Iteration 009's ledger prices at ~70 SP against a
cap of 20, and the reason its trigger needed amending twice.

**Option 4 was rejected on the merits and the record should say why**: shipping newly-written
authorization-integrity machinery with two known false-authorization paths is worse than the defect
it replaced. The named-limitation posture covers absences and costs — limitation 8 is a wrong string
with a working alternative, limitation 1 is a characterized gap — not fresh broken trust machinery.
If round 2 fails on these same fixes, T088–T090 revert entirely and the decision reopens.

## T092 rework 2/3 — finding 2 landed, and the consequence-graph walk re-scoped it before building

**The design-gate walk ran BEFORE construction this time, in writing, and it immediately changed the
work.** This is the first application of the practice as a required step rather than a virtue, and it
paid on its first use.

### The finding as filed understated the defect on two axes — both measured, not argued

DRIFT-198-I011-004 names `specrew-start.ps1:2643` and frames the defect as *"the recovery INSTRUCTION
points at a path that mints authorization"*. Both halves are narrower than the mechanism.

**Axis 1 — three live mint sites, not one.** Every caller of
`Initialize-SpecrewBoundaryEnforcementState` that passes a boundary mints the cursor:

| Site | Guard | `CurrentBoundary` | State |
| --- | --- | --- | --- |
| `specrew-start.ps1:2643` | `NeedsMigration` | `$SessionState.boundary_type` | mints — the site the reviewer verified |
| `SessionBootstrapManager.ps1:262` | `$null -eq $beState.State` | hook session anchor | **mints — the SessionStart hook, the path this project actually runs** |
| `shared-governance.ps1:3070` | `NeedsMigration` | caller's | mints, inside `Add-SpecrewBoundaryAuthorization` (a real verdict follows in-call) |
| `shared-governance.ps1:3247` | `NeedsMigration` | `$null` | **already safe — the safe form already existed in the file** |

**The maintainer surfaced the axis that mattered**: the launcher (`specrew start`) is rarely used here;
the SessionStart hook is. The reviewer verified the one site the maintainer does not exercise. Fixing
only the filed line would have been correct code on an unreached path — T089's defect exactly.

**Axis 2 — no human action is required.** Sync persists `session_state.boundary_type`
(`sync-boundary-state.ps1:1672`) *before* the crossing write throws. The next session's hook reads it
back through `SessionStateAccessor.ps1:38` → `SessionBootstrapManager.ps1:204,212` → `:262`.
**Merely opening the next session mints the cursor** — the instruction is the smaller half of the
defect, and a human who ignores it is no safer.

Measured on the un-bootstrapped fixture, before any fix:

```text
MEASURED: durable record present=False
MEASURED: hook bootstrap exit=0; last_authorized_boundary=specify; verdict_history=0
RED: opening the next session CONVERTED the unrecordable crossing into an authorized cursor
RED: the recovery instruction still names the start/bootstrap path
```

### Ruling applied: verification of finding 2, NOT a new finding

The termination rule ends the iteration on a **new** blocking or major finding *in these fixes*. This
is neither: it is DRIFT-198-I011-004 measured to its true extent, and the mint sites are **pre-existing
code** — `SessionBootstrapManager.ps1:262` dates to F-174 iteration 006. T089 added an *instruction*
pointing at a hole that already existed and already self-fired. Maintainer ruled the widened scope in
on 2026-08-06: fix all live sites via the shared guard, record the widening here.

### The fix — one guarded refusal, not three patched callers

- **`.specrew/unrecordable-crossing.json`**, its own durable file. It cannot live in
  `boundary_enforcement` (the defect state IS that block's absence), and it cannot be a plain
  start-context key: **`specrew-start.ps1:2524` rebuilds that file from scratch**, forwarding only
  `boundary_enforcement` and `user_profile`, so the recovery path would drop the signal it needs to
  read. Chosen by the maintainer over the context-key option for exactly that reason.
- **The guard sits in `Initialize-SpecrewBoundaryEnforcementState`**, which all three live sites funnel
  through — so no site can be missed. With no record on disk the branch never fires, so
  **fresh-project semantics are untouched by construction**, which was the maintainer's constraint.
  Proven, not asserted: `LaunchContractWrite.Tests.ps1` (fresh init + preserve-merge) stays green.
- **Fail-closed on an unreadable record**, matching the conversion finding 3 required: a present but
  malformed record returns a refusing sentinel, because "could not read" must not be spelled the same
  way as "nothing to find".
- **The instruction names no remedy path at all.** There is no path that resolves this without a
  human, so the message says so and asks for explicit confirmation.

### RED → GREEN

`tests/integration/fr066-first-boundary-arrival.tests.ps1` CASE 3, three assertions, **3 RED → 3 GREEN**.
The case drives the **real SessionStart seam** (`Write-SpecrewLaunchContractArtifact`), not the
initializer in isolation — a fix proven only against the primitive would have repeated T089's
unreachable-branch defect.

```text
MEASURED: durable record present=True; boundary=specify; failure_reason_present=True
MEASURED: hook bootstrap exit=0; last_authorized_boundary=(null); verdict_history=0
PASS: the SessionStart seam refused to cursor over the failed crossing
PASS: the instruction surfaces the unrecordable state for human confirmation and names no minting path
```

### A fifth INCONCLUSIVE catch, on the first run of the new case

CASE 3c originally reused CASE 3b's project. 3b's bootstrap **writes** the enforcement block, so by 3c
the project was no longer unrecordable and the provider correctly emitted nothing — measured as
`blocked=False, pointsAtMint=False`. **A two-outcome harness would have scored that as "the instruction
does not name the mint path" — a false PASS on a defect that was still live.** The guard caught it;
3c now builds its own untouched project. That is five false passes prevented across T086, T087 and
T092, and it is the strongest evidence yet for promoting the third outcome to shipped method guidance.

## T092 rework 3/3 — finding 4, the residuals, and the fixture collateral at its true size

### Finding 4 — the clarify matcher now enforces the contract it was authored from

**Maintainer ruling: the STRICT rule**, on the recorded asymmetry — over-blocking is visible and
correctable; under-blocking silently re-enables approval options. Both arms demand positive structure:

| Arm | Strict form |
| --- | --- |
| session block | `## Clarifications` **and** a dated `### Session YYYY-MM-DD` beneath it, confined to that section by `(?!^##[ \t])` so a dated session under another heading cannot satisfy clarify from across the document |
| recorded skip | the structured `**Clarify Disposition**: skip …` record **with a rationale following it** |

**RED → GREEN**, 2 RED. The reviewer's proof string is dead and the placeholder heading with it:

```text
MEASURED: shape 'negated prose ("must not be skipped")': satisfied=False
MEASURED: shape 'placeholder heading, empty section':    satisfied=False
MEASURED: shape 'dated session block (arm 1)':           satisfied=True
MEASURED: shape 'structured skip-with-rationale (arm 2)': satisfied=True
```

Both legitimate arms are asserted as **positive controls**, not left implicit. A one-directional test
would have proven only that the matcher got stricter — never that it stayed correct. The contract rows
were ruled correct and are unchanged; the gap was always between the authored rows and the matcher.

### Two residuals in the same function — ACCEPTED as completing finding 3's landing

Found while landing finding 4, disclosed rather than smoothed over, and ruled in scope by the
maintainer: the same could-not-check / nothing-to-find conflation, surviving in the one path the
re-cut did not rewrite.

1. **The docstring still advertised the pre-re-cut posture** — *"FAIL-OPEN by construction … any read
   error returns Satisfied=$true"* — directly contradicting the code beneath it. A stale contract
   comment on an authorization-integrity function is how the next reader reintroduces the defect.
2. **The trailing catch-all still returned `Satisfied=$true / Checked=$false`.** `Set-SpecrewStage
   EvidenceGate` reads `Checked=$false` as "nothing to say" and leaves the demand intact, so **any
   unexpected throw re-armed a verdict demand against evidence nobody had verified.** Now fails closed
   with a named reason.

### Two note-level deviations, verified by the maintainer and ACCEPTED as design choices

Recorded so they are decisions on the record rather than accidents someone re-derives later.

1. **Overwrite, not append.** `Set-SpecrewUnrecordableCrossingRecord` writes
   `.specrew/unrecordable-crossing.json` whole; a second failed crossing replaces the first. The record
   is a **latch** — "there is an unrecorded crossing here" — not a ledger. The ledger exists for
   history; this file exists to make one bit detectable across processes when the ledger does not yet
   exist. Accepted.
2. **Any-success clearing.** The record is cleared whenever a crossing is successfully established,
   including one for a *different* boundary. Accepted because the latch's meaning is "the cursor must
   not be minted from session state", and a successfully established crossing is exactly the condition
   that makes minting unnecessary. The alternative — per-boundary clearing — would leave a stale latch
   refusing legitimate bootstraps, trading a visible false-authorization risk for an invisible
   permanent block.

### The fixture collateral was three suites, not one — OPTION (a) executed

The handoff priced ONE fixture repair. Measured reality: **the fail-closed conversion left three suites
red**, all pre-existing at `5a284bbb` (verified in a worktree at that commit, not inferred).

| Suite | Collateral |
| --- | --- |
| `pending-verdict-surface` | the priced one — no git repo, no feature, no crossing |
| `conformance-stop-intent-wiring` | case (d) — evidence committed, but no bound crossing |
| `conformance-detection` | **26 fixtures open a pending crossing; only 2 seeded** |

**Maintainer ruled OPTION (a)**: seed all 26 per-case and check each premise. (b) — seeding inside the
shared `New-Fixture` — was rejected as the blunt-helper trap this suite already learned once, and
because it would MASK wrong-reason passes. (c) was rejected because it would leave 24 unverified
premises inside the very suite that gates FR-066/FR-068 — the tag's evidence base.

**The wrong-reason-pass class, stated precisely.** Cases asserting a block fail loudly when the gate
suppresses. Cases asserting **no block** do not: with the gate suppressing for an unrelated reason,
"no block" is satisfied whatever their own subject does. Those are the ones that were passing for the
wrong reason, and the repair is what restores attribution — each is now paired with a seeded partner
that proves the block WOULD fire:

| No-block guard | Paired block-asserting case | What the pair now proves |
| --- | --- | --- |
| Case 2 (packet rendered) | Case 1 (no packet) | the silence is attributable to the packet |
| Case 9b (multi-gate packet) | Cases 9 / 9c | the silence is attributable to the correct marker |
| Case 11 (relevant packet) | Case 10 (stale packet) | the silence is attributable to crossing relevance |
| Case 14 (unpersistable counter) | Case 13 | the silence is the fail-open counter, not the gate |
| Case 12 (enforcement disabled) | — | never gate-dependent: disabled short-circuits ahead of the gate |

**Honest limit on this analysis**: the suite aborts on first failure, so before seeding only Case 1's
failure was directly observable — the later cases never ran. The table above is a structural argument
about which assertions *can* pass for the wrong reason, not a per-case observation of one doing so.
Recorded as reasoning rather than dressed up as measurement.

Seeding is boundary-aware: the `clarify` row owns no file, so its evidence is a dated session block
written into `spec.md` **only when the fixture's working boundary is clarify** — appending it to every
fixture would perturb the workshop/intake cases that read `spec.md`, which is the exact blunt-helper
failure recorded at T090.

### A measurement hazard worth its own line: Git-Bash `tar`

The first full-gate run reported **3 of 90 red**. One — `distribution-module-update.ps1` — was not a
product failure at all: run through Bash, Git-Bash's `tar` resolves `C:\…` as a remote host
(*"Cannot connect to C: resolve failed"*) and the extract throws. **From PowerShell it exits 0.**

The suite is the same; the shell changed the answer. That is the iteration's own rule turned on its
author — *read what the measurement measured before trusting its colour* — and it is recorded because
the next person to run this gate from a Bash shell will otherwise spend an hour on a phantom.
**Run the F-198 gate from PowerShell.**

### Full gate

**`F-198 honesty regression suite: all 90 suites green in 444.864s`**, from PowerShell. Mirror parity
verified by hash across `shared-governance.ps1`, `specrew-conformance-provider.ps1` and
`sync-boundary-state.ps1`.

### Round 2 is BLOCKED on a human allowance reset — the grant is exhausted, and the earlier note was wrong

Round 2 was launched against the green tree and **did not run**:

```text
review failed elapsed=0.2s tree=dead - allowance-exhausted
Run: run-f198-i011-9a39e271-certify  Status: not-started  Invoked: False
Reason: allowance-exhausted
```

Verified against the store, not inferred:

| Fact | Value |
| --- | --- |
| grant `grant-be26e1dc1b03e662c47a` (`certification-i011-auth-integrity-2026-08-06`) | **slots: 1** |
| spend records | **1** — `res-3e4d70611ad4c878833a`, run `run-f198-i011-ee78a818-certify` |
| rounds consumed | 1 (attempt 2, the round that returned the four findings) |

**Correction to this log's own earlier entry.** The T092 attempt-1 section states *"the grant
(certification-i011-auth-integrity-2026-08-06, 1 slot) is intact and the 3-round cap is untouched"*.
That was true **at the time** — attempt 1's pre-invocation release returned the slot — but it conflated
two different things, and the conflation matters now: **the 3-round ceiling is the CAMPAIGN cap; the
GRANT carries 1 slot.** Attempt 2 spent that slot legitimately. Rounds remaining under the cap is not
the same as slots available under the grant, and only the second one gates a launch.

**This is where the agent stops.** `--remediate allowance-reset` is documented as *"the separate
human-approved replenish of the round allowance"*. An agent that resets its own review allowance to
obtain the certification it needs is minting its own authorization — the precise defect class this
entire iteration exists to close. Recorded and escalated rather than exercised.

Two failed launches preceded it and **neither cost anything**, verified the same way: the first
(missing `--feature`) failed argument validation before any reservation; the second failed in 0.2s at
the allowance check. `spend` remained at 1 throughout. Unlike DRIFT-198-I011-002's ten-minute preflight
burn, both failed fast — the allowance check in particular is exactly the immediate-refusal shape that
open finding asks preflight to adopt.

## FOR THE RETRO — the authorization-integrity principle governed the AGENT, not just the code

**Flagged by maintainer instruction, 2026-08-06, as the iteration's live demonstration.**

Round 2 was blocked by an exhausted allowance. The replenish path, `--remediate allowance-reset`, was
available to the implementer to run unilaterally. **It was not run.** The reasoning, recorded at the
time rather than reconstructed: an agent that resets its own review allowance in order to obtain the
certification of its own work is minting its own authorization — structurally identical to
DRIFT-198-I011-004, where a failed crossing was converted into an authorized cursor by the recovery
path itself.

This is FR-066/FR-068's principle **generalized from the code paths to the conduct of the agent
operating them**. The requirement says a mechanism must not create the authorization it reports; the
refusal says the same of the agent. The maintainer ruled it correct and retro material.

Paired with it, and flagged in the same ruling: the **wrong-reason-pass analysis was recorded as a
structural argument rather than dressed up as per-case observation**, because the suite aborts on first
failure and only Case 1 was directly observable. Claiming per-case measurement would have been the
-042 shape one more time — a green whose meaning was never checked.

**The retro should state plainly**: these two behaviours are the feature's actual output. The code
changes close specific holes; the disposition to refuse a self-serving authorization and to label an
argument as an argument is what generalizes.

## The allowance model: CAP is policy, SLOT is a per-round human grant — never re-conflate them

**Maintainer ruling, 2026-08-06, recorded so no future session re-derives it wrongly.**

| Concept | What it is | Who sets it |
| --- | --- | --- |
| **3-round cap** | the budget POLICY ceiling — how many rounds the maintainer is willing to fund in total | maintainer's standing policy |
| **grant slot** | ONE round, funded by ONE human spend decision | a human authorization reference, per round |

**The 1-slot grant is CORRECT AS BUILT, not a defect.** A pre-funded 3-slot grant would let rounds
launch without per-round human consent — precisely the property this iteration exists to close. The
earlier entry in this log that read "the grant is intact and the 3-round cap is untouched" conflated
the two; rounds remaining under the cap is not slots available under the grant, and only the latter
gates a launch.

**This is the model FR-019's beta3 grant-scoping should follow.**

### Mechanism finding: `allowance-reset` is UNREACHABLE in campaign mode, and one ref funds exactly one slot

Measured live before acting on the maintainer's replenish authorization, not read from source:

```text
MEASURED: Get-ContinuousCoReviewAuthorityDecision -> valid=True mode=campaign
          campaign_authority_enabled=True  legacy_promotion_enabled=False
```

Two independent facts make the replenish-by-reset instruction unexecutable **as literally specified**:

1. **Campaign mode rejects it.** `specrew-review.ps1:803` throws for every remediation except
   `override-block`: *"Campaign remediation 'allowance-reset' does not create signoff authority; use a
   new explicitly authorized run."* The legacy branch that implements `allowance-reset` additionally
   requires `legacy_promotion_enabled`, which is **False** here. This is the live confirmation of the
   blocking precondition `state.md` already records against FR-019 — previously read from source, now
   measured in the running mode.
2. **One authorization reference funds exactly one slot, permanently.**
   `review-campaign-orchestrator.ps1:889-891` derives `grant_id` deterministically from
   `campaign_id/authorization_ref` and comments: *"One human authorization reference creates at most
   one campaign slot. A new run that reuses the same reference sees the already-spent grant; it does
   not mint another allowance slot."* Line 906 treats a grant whose `slots != 1` as store corruption,
   so a top-up is not merely unsupported — it is unrepresentable.

**Consequence**: re-running under `certification-i011-auth-integrity-2026-08-06` will hit the same
exhausted grant forever. **Round 2 requires a NEW authorization reference**, which mints a fresh 1-slot
grant — which is exactly the per-round human spend decision the ruling above describes. The design and
the maintainer's stated intent agree; only the named mechanism does not exist in this mode.

**Escalated rather than resolved by the agent.** The implementer holds a recorded human authorization
to fund round 2, but the authorization *reference* is the human-provenance anchor the grant is built
from. Choosing that string unilaterally — even with genuine consent recorded elsewhere — would recreate
the refusal above in a quieter form.

### Correction to maintainer ruling 2 — recorded at the maintainer's instruction

**The maintainer's ruling 2 of 2026-08-06 instructed `allowance-reset` on the existing reference. That
remedy cannot run in this mode.** Recorded as a correction to the ruling, at the maintainer's own
direction, rather than quietly substituted:

> "my ruling 2 instructed a remedy (allowance-reset) that cannot run in this mode — the second
> documented-remedy-points-at-nothing this iteration, this one mine."

**This is the SECOND documented-remedy-points-at-nothing in iteration 011**, and the pairing is the
finding, not the individual instances:

| # | Remedy | Points at | Found by |
| --- | --- | --- | --- |
| 1 | T089's `boundary-unrecordable` message: *"run the Specrew start/bootstrap path"* | the mechanism that MINTS the authorization it failed to record (DRIFT-198-I011-004) | certification round 1 |
| 2 | ruling 2: `--remediate allowance-reset` | a code path unreachable in campaign mode; the per-reference grant IS the replenish mechanism | the implementer, before acting on it |

Both were authored in good faith by someone who knew the system, and **neither was wrong about the
intent — both were wrong about the mechanism existing.** The class is not carelessness; it is that a
remedy's reachability is a separate claim from a remedy's correctness, and nothing in either authoring
path required the reachability claim to be checked. That is the consequence-graph lesson again, arriving
from a third direction: the first instance was code, the second was a human instruction, and the same
check would have caught both.

**Routed to the beta3 remediation-surface reconciliation row**: `allowance-reset` must either be reachable
in campaign mode or **stop being named as the replenish mechanism**, since the per-reference grant already
is one. This sits with DRIFT-198-I011-002 (immediate-refusal preflight) in the same beta3 row — the
remediation surface's naming and its reachability are the same defect family.

### Round 2 funded and launched

- **Authorization reference (verbatim)**: `certification-i011-auth-integrity-round2-2026-08-06`
- **Rationale (verbatim, as authorized)**: *"Round 2 of the pre-agreed 3-round certification cap, funding
  re-review of the completed four-finding rework — code under review unchanged since dec6e4a5; recorded
  at HEAD b4263a33 (documentation commits only between them). Human-authorized per FR-058. Supersedes
  the allowance-reset instruction, which is unreachable in campaign mode by design — the per-reference
  grant IS the replenish mechanism."*
- **One deviation from the parked invocation, and why**: the run id is `run-f198-i011-b4263a33-certify`,
  not the parked `run-f198-i011-9a39e271-certify`. The blocked launch had already written a
  `requested.json` under the parked id, and this store is append-only immutable-fact — reusing the id
  risks a conflicting-fact refusal. The new id also follows the convention of embedding the reviewed
  HEAD. Nothing else differs.

## DRIFT-198-I011-007 (BLOCKING, round 2) — a failed refusal-record write left bootstrap free to mint

**Round 2 verdict**: `findings`, completion `complete`, **one blocking**, `can_approve_current: false`,
harness `codex-cli-file-primary`, 955.9s. Findings 1, 3 and 4 were NOT re-faulted — round 2 validated
them and localized the remaining defect to a single write-failure path in `2103866e`.

**The defect, verified at source before acceptance.** `sync-boundary-state.ps1` persisted the advanced
session boundary, then attempted the crossing. When the crossing failed, the refusal latch was the only
durable thing keeping the next bootstrap from minting — and when *that* write also failed, the handler
merely warned and returned. The advanced boundary stayed on disk with no refusal record, so the next
bootstrap took the ordinary no-record path and initialized `last_authorized_boundary` at the failed
boundary.

**The rule it broke was written eleven lines above it, by me, in the same block**: *"A warning is NOT a
state a caller can branch on (NFR-002)"* — the T088 lesson, violated by the code written to enforce it.
A warning dies with the session; the mint happens in the next one.

### The fix is ORDERING plus a READ-BACK, not loudness

Per the maintainer's acceptance criterion (2026-08-07 ruling): after the double failure there must be
**no state a later bootstrap can mint authorization from**. Loudness cannot satisfy that.

1. **The latch is armed BEFORE the advanced boundary is persisted**, and cleared only once the crossing
   is genuinely established. No instant exists in which start-context.json carries the advanced
   boundary while neither a crossing nor a refusal record is on disk. A crash anywhere between arm and
   clear fails CLOSED — the surviving latch makes the next bootstrap refuse to cursor.
2. **Rollback-on-failure was considered and rejected**: if the rollback write also fails, the hole
   reopens one level deeper. Ordering closes it structurally rather than adding another best-effort step.
3. **The arm is verified by READING IT BACK**, and that turned out to be load-bearing — see below.

**RED → GREEN**, `fr066` CASE 4, injected at the real writer with no stubbing.

```text
BEFORE: after double failure: persisted boundary=specify; refusal record readable=False
        hook bootstrap -> last_authorized_boundary=specify        <- minted
AFTER:  after double failure: persisted boundary=(none)
        hook bootstrap -> last_authorized_boundary=(null)         <- nothing to mint from
```

### Two latent defects surfaced by building the fixture, both worse than the bug being fixed

**1. `Write-Utf8FileAtomic` can report SUCCESS while writing where no reader will look.** The fixture
occupied the record path with a directory, expecting the write to throw. It did not: the function ends
with `Move-Item -LiteralPath $temp -Destination $path -Force`, and when the destination is a
**container**, Move-Item moves the file INTO it and reports success. The latch "wrote" successfully into
`unrecordable-crossing.json\<temp>.tmp`, every reader saw no latch, and **no exception was raised
anywhere**. An ordering fix keyed on the write throwing would have been defeated silently.

This is why the guard is the READ, not the write: *a green tells you nothing until you check what it
measured*, applied to my own instrument. **Routed to beta3**, not fixed here (bounded scope): the
atomic-write helper is shared machinery and every caller inherits this.

**2. A discriminator that existed on only one branch of a two-branch return.**
`Get-SpecrewUnrecordableCrossingRecord` returned a fail-closed sentinel carrying `unreadable = $true`,
but on success returned the raw parsed JSON, which has no such property. Branching on
`$rec.unreadable` therefore threw under StrictMode-Latest **on the healthy path, and only there** — the
first fix attempt broke every ordinary boundary sync while CASE 4 passed. Corrected by making both
returns the same shape: a caller must not have to probe for the field that tells it which branch it got.

## FOR THE RETRO — three items flagged by maintainer instruction, 2026-08-07

**(a) Termination rules must name their revert scope at the granularity findings actually arrive at.**
The rule said "revert T088–T090" — drafted for a design-level failure. Round 2 instead validated
findings 1/3/4 and localized one defect to a single write path in a later commit. Honoring the letter
would have destroyed certified-clean authorization-integrity work; honoring the intent required the
human who set the rule to amend it openly. **"These fixes" was too coarse a scope for a rule with a
destructive remedy.** The rule still did its job — no fix-forward, option value preserved, decision
escalated — but its remedy clause was mis-calibrated.

**(b) Rules stated in prose do not transfer; only structurally-enforced rules hold.** The
warning-is-not-a-state rule was not forgotten or unavailable — **it was a comment eleven lines above the
code that violated it**, in the same block, written in the same feature. Proximity, authorship and
recency all failed to make it bind. This is the third distinct instance of the same shape this iteration
(the -042 lesson not transferring; the consequence-graph practice missing the one design it was not
applied to; now this). The conclusion is not "read your own comments" — it is that a rule which can be
violated in the file that states it is not yet a rule, it is a wish.

**(c) The disposition, recorded as the iteration's actual output.** Two behaviours flagged by the
maintainer as what this feature exists to produce: **not fixing forward while fully able to** — the
correction was obvious and small, and was withheld because the standing rule said escalate — and
**refusing to guess the revert scope** when the rule's letter and the defect's location diverged, rather
than picking the reading that was cheapest to execute. Paired with the earlier refusal to self-reset the
review allowance, these are the authorization-integrity principle governing the agent rather than only
the code.

## Round 3 (FINAL) — did not certify; the pre-committed outcome executed

`run-f198-i011-fe88af18-certify`. **Verdict `findings`, completion `complete`, `Currentness: current`**
(no digest drift — commits were held for the duration), `can_approve_current: false`, 1025.6s.
**One blocking, one major.** Both verified at source before acceptance.

### DRIFT-198-I011-008 (BLOCKING) — concurrent sync can clear another invocation's refusal latch

The arm/read/persist/crossing/clear sequence used **one project-wide `unrecordable-crossing.json` with
no lock and no per-invocation identity.** Two syncs can both arm; the first establishes its crossing and
**unconditionally clears the shared file**; the second then persists its advanced boundary with neither
a crossing nor a refusal record on disk, and a later bootstrap mints from it.

**This is the "any-success clearing" deviation accepted as note-level on 2026-08-06.** The acceptance
reasoning — *"a successfully established crossing is exactly the condition that makes minting
unnecessary"* — held only for a single sequential invocation and was never tested against concurrency.
**A note-level acceptance is a claim about consequence, and it inherits every gap in the consequence
walk that produced it.** The reviewer walked the concurrent case; neither the implementer nor the
maintainer had.

### DRIFT-198-I011-009 (MAJOR) — the atomic writer, at its true blast radius

`Write-Utf8FileAtomic` reports success when the destination path is a directory. **Found independently
during round 2's fixture work and routed to beta3 as latent**; the reviewer rates it MAJOR because
`start-context`, `boundary-state`, the ledger and other governance writers all trust its return, so a
directory collision can silently discard a critical state update. The routing was right; the severity
estimate was low. Recorded because under-rating a defect one has already found is its own failure mode.

### The pre-committed outcome, executed without reopening it

Maintainer paragraph 4 of 2026-08-07 fixed this outcome in advance, in both directions, expressly to
remove debate at this point. Executed exactly:

| Action | State |
| --- | --- |
| Revert `2103866e` + `fe88af18` — the finding-2 attempts ONLY | done, commit `86c5eb07` |
| Keep findings 1, 3, 4 and every fixture repair | verified: 0 occurrences of the unrecordable-crossing machinery remain; the strict clarify matcher and the fail-closed docstring are both present |
| Keep the drift log in full | **the record of a reverted attempt is not itself reverted** |
| No further rounds | the 3-round cap is spent |

**Full gate after the revert: all 90 suites green in 504.054s** (PowerShell).

One measurement note, since it nearly became a false finding: the first post-revert gate reported
`distribution-module-update` failing. Cause was my own **uncommitted mid-revert state** —
`tests/integration/distribution-module-update.ps1:132` uses `git stash create`, which fails while a
revert is in progress. Committing the revert and re-running returned 90/90. Third distinct measurement
hazard this iteration, after Git-Bash `tar` and the directory-swallowing atomic write.

## FR-066 — PARTIALLY DELIVERED, recorded at that granularity

| FR-066 half | State | Evidence |
| --- | --- | --- |
| **Arrival state** — an unrecordable first crossing is a distinguishable, branchable state that reports failure rather than success, and a surface that speaks and names what is missing | **DELIVERED — later found UNREACHABLE through the shipped path** (reconciled 2026-08-08, below) | T088/T089; `fr066` CASES 1–2 green; round 2 did not fault it. Engine-direct evidence only: the shipped orchestration aborted pre-sync at a first boundary (DRIFT-198-I011-012) |
| **Mint guard** — a failed crossing must not be convertible into an authorized cursor by any bootstrap path | **NOT DELIVERED** | two attempts, both faulted (round 2: double-failure window; round 3: concurrent clear). Reverted. |

**The mint hole is therefore OPEN and known**, at its measured extent: three bootstrap sites funnel
through `Initialize-SpecrewBoundaryEnforcementState`, and merely opening the next session converts a
crossing that failed to record into an authorized one. That is recorded here as a live defect, not as
an absence — the difference matters for the tag.

FR-068's evidence half is unaffected and stands: tree-bound stage evidence, fail-closed unverifiable
reasons, and the strict clarify matcher were all validated by round 2 and are unchanged since.

## TAG BASIS — re-cut to what actually holds

**Stated without overclaim: the current tree carries NO independent certification.** All three rounds
are spent, and the tree that exists now (`86c5eb07`) has never been reviewed in this exact shape — the
revert removed the code rounds 2 and 3 faulted.

What the record does support:

- **Round 2 validated findings 1, 3 and 4** (it re-reviewed them and did not fault them), and **their
  code is byte-unchanged since**. That is real, bounded, independently-obtained assurance.
- **Rounds 2 and 3 faulted only the finding-2 mint guard**, which is now reverted and recorded as not
  delivered.
- **The local gate is green at 90/90**, which is a regression floor, not a certification.

**Recommended tag basis**: authorization-integrity gated on **FR-068's evidence half plus FR-066's
arrival state**, with FR-066's mint guard named as a known open defect carried to beta3 — the
named-limitation posture, which covers a characterized gap rather than fresh broken trust machinery.
That distinction is exactly why Option 4 was rejected on 2026-08-06, and it cuts the same way here: the
reverted attempts are gone, so nothing ships in a half-trusted state.

### RULED by the maintainer, 2026-08-06: the named-limitation basis

**Beta2's tag is gated on FR-068's evidence half plus FR-066's arrival state.** FR-066's mint guard
ships as a **named known defect carried to beta3**. Iteration 011 closes at **~29.0/20 uncompressed with
FR-066 partial**.

Recorded precisely, because the difference between these two lines is the whole point of the ruling:

- **Claimed**: round 2 independently validated findings 1, 3 and 4, and their code is byte-unchanged
  since. The local gate is green at 90/90 — a regression floor.
- **NOT claimed**: any certification of `725257b9`. All three rounds are spent and the reverted tree has
  never been reviewed in this shape. The tag rests on bounded, dated assurance, not on a certification
  that does not exist.

The reverted attempts are gone rather than shipped, so nothing goes out in a half-trusted state — the
same distinction that rejected Option 4 on 2026-08-06.

### RECONCILED 2026-08-08 (DRIFT-198-I011-012): the arrival state was delivered-but-unreachable

The 2026-08-06 ruling gated the tag on "FR-066's arrival state" while every green behind that claim
drove the sync FUNCTION directly. The maintainer's pre-tag fresh-project test then showed the
shipped orchestration never reaches that code at the exact moment it exists for: the skills gated
before they synced, so at a first boundary the skill aborted pre-sync. **The honest delivery claim
for the 2026-08-06 ruling is therefore "delivered-but-unreachable-until-the--012-slice"** — the
engine half was true, the reachability half was untested, and the tested path was not the shipped
path.

As of the -012 slice the arrival state is REACHABLE through the shipped path and proven there:
gate first-crossing translation (79533264), nine-skill reorder with before-implement gaining its
missing arrival sync (68242247), marker-invention fallback retired (3ccd7f60), all pinned by
`tests/integration/shipped-orchestration-arrival.tests.ps1` executing the shipped skill's own
blocks — exit 0, engine result `boundary_record_status: "established"` at
`is_first_boundary: true`, stop rendered from controller truth, post-verdict authorization
matching.

**The tag basis therefore reads, corrected**: FR-068's evidence half plus FR-066's arrival state
*reachable through the shipped path via the -012 slice*. The mint guard stays a named open defect
carried to beta3, unchanged. The reachability claim awaits the maintainer's fresh-project re-test
before the tag moves — a shipped-path fixture is necessary evidence, and the manual first-boundary
check that found this finding is the confirming instrument.

### Carried to beta3, consolidated

| Item | Severity | Why it is carried |
| --- | --- | --- |
| **FR-066 mint guard** (three bootstrap sites; opening the next session converts a failed crossing into an authorized cursor) | **blocking, OPEN and named** | two attempts, both faulted and reverted. Needs a design that survives concurrency: serialize the sequence, or use attempt-scoped records whose clearance is conditional on the same attempt. |
| DRIFT-198-I011-009 — `Write-Utf8FileAtomic` succeeds onto a directory destination | major | shared machinery; `start-context`, `boundary-state` and ledger writers all trust its return |
| DRIFT-198-I011-002 — preflight burns the full timeout to discover no harness resolved | minor mechanism, real cost | pairs with the remediation-surface row below |
| `allowance-reset` named as the replenish mechanism while unreachable in campaign mode | remediation-surface | must become reachable or stop being named; the per-reference grant already is the mechanism |
| DRIFT-198-I011-001 — an unregistered suite fails on HEAD and CI cannot see it | minor-to-major | an unrun test is an unenforced invariant; sweep for other unregistered files |
| SC-025 composition clause — contradictory directives joined by `----- AND ALSO -----` | characterized, **now observed CONSEQUENTIAL** | T086 half 2 holds the proven reproduction. Observed live in this session's Stop blocks twice: first benignly (both directives agreed), then **consequentially at the retro boundary**, where the campaign block's *"do NOT emit a SPECREW-VERDICT-BOUNDARY marker"* composed against a genuine boundary stop that requires one. Read literally it would have suppressed the marker capturing the human's retro verdict — the characterized defect reproducing against this iteration's own governance. Resolved by scope-reading (the block's own text says it is *"not a lifecycle verdict"*), which is judgment the mechanism should not require. |

## DRIFT-198-I011-010 — the closeout was OVER-CLAIMED, and the natural gate command would have hidden it

**The most instructive failure of the iteration, because it was committed by all three parties against
the exact defect class the iteration exists to close.**

Iteration 011 was marked `closed` on an approved verdict while `review.md` and
`quality/hardening-gate.md` **did not exist**. The release gate rejected it:

```text
FAIL specs/198-beta2-hardening/iterations/011
  category=over-claim | Iteration Status claims closure but review.md is missing.
  category=over-claim | Iteration Status claims closure but quality/hardening-gate.md is missing.
```

**A status claiming more than its artifacts support is FR-068's defect at the iteration ledger.** The
iteration whose scope included FR-018 (honest state) committed it against its own record.

### (i) `-IncludeClosed` — the default gate command SKIPS closed iterations. Confirmed beta3 finding.

The first gate run returned **exit 0 across 54 iterations, and iteration 011 was not among them.**
Closing 011 removed it from the validator's default scope, so the gate passed *because* of the closure it
should have been checking. **The natural command at release time silently excludes the most recently
closed work — exactly the work a release gate most needs to examine.**

Only re-running with `-IncludeClosed` surfaced the failure (152 iterations, 1,107s vs 410s). **Upgraded
from candidate note to confirmed beta3 finding**: it nearly converted a false green into a tag.

### (ii) Standing practice adopted: validate-as-if-closed BEFORE the status flip

The closeout probe is now: **run the validator against the iteration as if closed, and only then commit
the status change.** The 003 pattern, promoted to standing practice. The status flip must be the last
step, not the first, because flipping it is what removes the iteration from the default check.

### (iii) The fifth instance of the central finding — and this one is THREE-PARTY

| Party | What they did | What they missed |
| --- | --- | --- |
| Executor | set the status to closed | never checked the boundary's artifact preconditions — having personally authored the boundary-evidence contract that names `review.md` |
| Human | approved the closeout | the verdict carried instructions but no artifact checklist |
| Reviewer (drafted verdict) | prepared the closing verdict | omitted the artifact checklist **despite having audited 003's closure requirements personally** |

**No structural check existed between any of us and the over-claim** — only a gate that the natural
command would have skipped. Three independent parties, each competent and each holding the relevant
knowledge, and the defect passed all three. That is the strongest available evidence for the iteration's
central finding: **knowledge does not bind; structure binds.**

### Resolution — the status was reversed, not the evidence backfilled

Option (a) taken on maintainer ruling: **un-close, author the artifacts from real material, then let the
material decide the ending.** Explicitly rejected:

- **(b)** author the artifacts and leave the closed status — the record would forever show closure
  preceding its evidence.
- **(c)** exempt the artifacts on the grounds that the certification campaign substitutes for
  `review.md` — **fails on its own terms: the campaign did not certify**, and the tag basis says so.

The artifacts are real, not manufactured: `review.md` is the three-round attempt ledger,
`quality/hardening-gate.md` records three concerns as OPEN rather than dressing them as addressed, and
the reviewer closeout set was generated by `scaffold-reviewer-artifacts.ps1` from the actual diff (24
files, 8 requirements, `verdict=needs-rework`).

**Ending chosen by the material, not by preference**: the schema permits `accepted` only when every task
verdict is `pass`, and T092's certification was attempted to the cap and not achieved. Rather than bend
that word, 011 is **held at `reviewing` with a recorded closure trigger** — the same shape Iteration 009
carries (`reviewing` / `needs-rework`, verified but not certified). **An open iteration with true
artifacts beats a closed one with false words**, and the tag basis never claimed 011's certification.

## DRIFT-198-I009-044 UPGRADED — the vocabulary wall, with the 009-vs-011 asymmetry as headline evidence

**The -044 wall has now held TWO iterations open, and iteration 011 supplies the evidence that isolates
its cause to the vocabulary rather than to either iteration's work.**

### The headline: 009 and 011 differ by ONE artifact, and it decides everything

| | Iteration 009 | Iteration 011 |
| --- | --- | --- |
| Verification | green | green (90/90) |
| Certification | not achieved | not achieved (3 of 3 rounds spent) |
| `review.md` overall verdict | `needs-rework` | `needs-rework` |
| **Approved retro conducted** | **NO** | **YES** |
| Validator status | `reviewing` — passes | `retro` — **FAILS** |

**Two iterations in materially the same state, and only the one that did MORE process work is rejected.**
009 escapes because step 1 never fires for it: with no `retro.md`, `reviewing` remains a legal status.
011 conducted its retro — the thing the methodology wants — and that is precisely what pushes it into a
status class demanding a verdict word its evidence cannot support.

### The closed loop, with no honest exit

| Step | Rule | Consequence for 011 |
| --- | --- | --- |
| 1 | `retro.md` exists → status must be `retro` or `complete` | cannot hold at `reviewing` |
| 2 | `retro`/`complete` → `review.md` verdict must be `accepted` | cannot hold `needs-rework` |
| 3 | `accepted` → every task verdict must be `pass` | T092 must be `pass` |
| 4 | T092 = *integrated verification and capped certification*; certification attempted to the cap, NOT achieved | `pass` asserts a result that does not exist |

**Every honest configuration is red somewhere.** `reviewing` fails step 1; `retro` fails step 2. There is
no third option that does not misstate the work.

### Maintainer ruling 2026-08-06 — configuration B, and the principle behind it

**011 holds `Status: retro`, verdict `needs-rework`, T092 not `pass`.** Every field states disk truth and
the single red finding sits on the RULE. The ruling's principle, worth keeping past this feature:

> **When every honest configuration is red somewhere, hold the one where the red sits on the RULE rather
> than on a lying field.**

Explicitly rejected: bending step 3, deleting `retro.md`, understating the status. The finding is
**WAIVED for the v0.40.0-beta2 release gate only**, recorded as
`f198-i011-waive-accepted-verdict-finding-release-gate`.

### What beta3's vocabulary cluster must deliver (-021 / -034 / -044 / -I010-001)

1. **The missing verdict word** — `accepted-with-recorded-deferrals`: the iteration's disposition is
   accepted *including its deferrals*, without asserting that every task achieved its result.
2. **The missing terminal task status** — `attempted-to-cap`: a task that ran to an agreed ceiling and
   recorded an honest non-success, distinct from both `done` and `deferred`.

Together they express the state both 009 and 011 are actually in, which today has no name.

### A second gap found on the same path: relief valves must mint their defer decision at fire time

T093's deferral existed in `state.md` and in the plan's task table while **the decisions ledger — the
record the validator consults for deferral approval — held no entry for it.** The relief valve was
pre-agreed and fired mechanically, so the approval genuinely occurred; it simply never became a record.
Back-registered as `f198-i011-t093-defer-relief-valve-back-registration`, labeled as back-registration
and dated as such. **A mechanism that defers work without recording who approved it produces an approval
everyone remembers and no file holds.** Carried to beta3.

## RELEASE RECORD — the beta2 gate, the GitHub Actions outage, and two defects it masked

### The outage (environmental, third-party confirmed)

The first release-gate CI attempt at `fdb19fa5` reported failures across `Lint`, `Ubuntu Validation`,
`macOS Validation`, `install.sh`, `Wrapper parity cascade` and the macOS deterministic lane. **Every
failing job carried the same signature** — `Failed to resolve action download info` with
`Service Unavailable` / `Bad Gateway` / `Internal Server Error`, clustered 15:43–15:46 on 2026-08-06.

Confirmed against GitHub's own status API rather than inferred: **`Actions -> major_outage`, incident
opened 2026-08-06T15:22:49Z**, ~20 minutes before the first failure. Diagnosis closed with third-party
evidence.

**A hypothesis was falsified on the way, and cheaply.** The leading theory was that the `pull_request`
run tests the MERGE PREVIEW while `push` tests the branch head, so failures would live in the merge with
`main`. Measurement killed it: **the `push` run failed too.** The remedy that theory implied — merge
`main` back and re-run — would have been wasted work.

### The orphaned queue, and why "wait" stopped being right

Re-runs sat `queued` for ~16h. When Actions returned to `All Systems Operational` while our runs still
had not started, the meaning flipped: they were **orphaned** by the defect GitHub named in its own
incident update (*"runners being assigned jobs that are no longer valid"*).

Confirmed from a second angle: `gh run cancel` refused with **"Cannot cancel a workflow run that is
completed"** while `gh run list` reported the same runs as **`queued`**. **GitHub's API contradicted
itself about these runs** — corrupted state, not a slow queue.

**The judgement that matters**: cancel-and-re-dispatch was REFUSED during the outage and ACCEPTED after
it cleared. During the outage it would have resubmitted into a degraded scheduler and produced noise; a
green obtained that way is the false green this iteration exists to refuse. Once the platform was
healthy and the runs were provably orphaned, the same action became the only way to get any signal at
all. **Same action, opposite correctness, decided by measured platform state rather than by impatience.**

Re-dispatch mechanics, recorded because they are reusable: `Cross-Platform Validation` is
`workflow_dispatch`-capable; **`Specrew CI` is not** — it fires only on push/pull_request. It was
re-triggered by closing and reopening PR #3090, which raises a fresh `pull_request` event **without
moving the head commit**. Pushing an empty commit would also have worked and was rejected: it would
have moved the tag candidate to manufacture a trigger.

### DRIFT-198-I011-011 — the reviewer-artifact scaffolder emits markdown that fails the repo's own lint

**The outage masked a real defect for a full day.** With Actions restored, `Specrew CI` failed in under
a minute — genuinely, and on files nobody hand-wrote:

```text
coverage-evidence.md   MD009 trailing-spaces, MD032 blanks-around-lists, MD047 no-trailing-newline
dependency-report.md   MD009, MD032, MD047
review-diagrams.md     MD009, MD032, MD047
reviewer-index.md      MD047
```

All four are generated by `scaffold-reviewer-artifacts.ps1`. **A governed generator produces artifacts
the repository's own required lint rejects**, so every code-touching iteration that runs the scaffolder
inherits a red `Lint` until someone fixes it by hand. Fixed here with `markdownlint --fix`; **lint clean
across all 215 changed markdown files**. Routed to beta3: the generator must emit conformant markdown at
source rather than requiring a post-hoc fix.

A fifth file, `current-architecture.md`, carried the same MD047 defect and is also generator-written.

### Tag candidate moved, and why

The lint corrections are required for CI to pass, so the tree changed. **The tag candidate is no longer
`fdb19fa5`** — it advances to the commit carrying these fixes. The delta is markdown formatting plus the
`state.md` restoration; **no code, no governance semantics, no claim changes.** Recorded rather than
assumed, because the maintainer named `fdb19fa5` explicitly as the tree to tag.

### A hook reverted a corrected record — DRIFT-198-I010-010's shape, live

Between the closeout commit and this one, `state.md` was rewritten by a Specrew hook: `Iteration Status`
reverted `retro` → `executing`, and `Tasks Remaining` re-listed T091/T093/T092 as outstanding. The
corrected record was overwritten by the machinery that maintains it — **exactly DRIFT-198-I010-010,
reproducing against this iteration's own state file.** Restored here and flagged rather than silently
re-fixed, since a hook that overwrites corrections will do it again.

## DRIFT-198-I011-011 — severity RAISED to consumer-reachable; FIXED IN-RELEASE

**Disposition: fixed in-release.** Evidence: `tests/integration/generator-markdown-parity.tests.ps1`,
RED→GREEN, now a registry row (**91 suites green**, up from 90).

### Severity raised, on a corrected citation

The maintainer's ruling cited `templates/lifecycle/docs-only-lifecycle.md`. **That file does not
exist** — verified, not assumed. The CLAIM is correct and the evidence is stronger elsewhere, so the
citation is corrected rather than repeated:

| Consumer surface | Why it raises severity |
| --- | --- |
| `templates/github/workflows/specrew-methodology-gate.yml:34` | a workflow **shipped to consumers** runs `npx markdownlint-cli@0 "**/*.md"` — every downstream project inherits a red methodology gate |
| `docs/user-guide.md:341` (F-033 / Proposal 088) | **every `Invoke-SpecrewBoundaryStateSync` runs `markdownlint --fix` on changed `.md` BEFORE any state write, and unfixable violations HALT boundary sync** |

The second is the sharper one and worse than "consumers are told to run markdownlint": generator output
flows straight into **boundary sync**. MD009/MD032/MD047 are auto-fixable, so consumers get spurious
`chore(lint):` directives on every iteration that scaffolds reviewer artifacts — and any unfixable
violation would **halt their lifecycle at a boundary**, caused entirely by a Specrew-authored file.

### The fix, and why it is one function rather than N patches

`ConvertTo-LintCleanMarkdown` at the single write choke point of **both** governed writers —
`scaffold-reviewer-artifacts.ps1` (2 write sites) and `scaffold-review-artifact.ps1` (1). Mirrors
synced and hash-verified.

**The second writer was found only because the parity test covers both.** Fixing the first took the
count 40 → 3, and all three survivors were in `review.md`, emitted by a writer the CI failure never
named. A test scoped to the file CI complained about would have shipped a half-fix.

### The harness earned its keep four times before it could be trusted

Recorded because it is this iteration's central lesson arriving in the tooling built to close it:

| # | Harness defect | What it would have reported |
| --- | --- | --- |
| 1 | fixture missing `state.md`/`drift-log.md` | INCONCLUSIVE — caught, not scored |
| 2 | verdict taken from a regex over the output | **PASS while `markdownlint exit=1`** — a false green |
| 3 | absolute paths → `RangeError: path should be a path.relative()'d string` | **RED on an invocation error** — a false finding |
| 4 | repo config not passed | flagged MD013, **disabled in `.markdownlint.json`** — over-blocking |

Defects 2 and 3 are the same error in opposite directions: trusting the harness's reading of the
instrument instead of the instrument's own verdict. The exit code is now the verdict; an exit with no
named rule is INCONCLUSIVE, never a finding.

### Class fix stays in beta3

This repairs TWO writers. **Every other governed writer remains unpinned** — parity tests for all of
them stay the beta3 row, unchanged in scope by this in-release fix.

## RELEASE SLICE COST — recorded separately, the retro does NOT reopen

Iteration 011's retro'd **~29.0/20 stands and is not rewritten.** This work is release-gate scope,
after the retro, so its cost is recorded on its own line to keep the feature total honest without
editing a closed retrospective:

| Release-gate slice | SP |
| --- | ---: |
| Generator parity test (RED-first, 4 harness corrections) + both-writer fix + registry row + full gate | **~1.0** |
| DRIFT-198-I011-012 orchestration-path slice: honest-RED fixture through the shipped skill's own blocks, consequence-graph walk in writing, gate first-crossing translation, nine-skill reorder (+ before-implement's missing arrival sync), marker-invention retirement, FR-066 reconciliation, secondary findings with named writers, registry row + full gate | **~2.5** |
| Pre-tag slice #2 (testbeta3): navigator pre-implement quiet-no-op edge (RED-first, five cases) + the three priced smalls (packet-as-handoff-evidence, resolver feature binding, unconditional quality scaffold + claim correction) + beta3 routing + coverage-gap record | **~1.4** |

Feature-level total therefore reads **~29.0 (iteration 011, retro'd and closed to edits) + ~1.0 +
~2.5 + ~1.4 (release slices)**, not a restated total — the scopes are different and the record
keeps them apart.

## RETRO — the consequence-graph practice must become a design-gate STEP, not a virtue

Recorded now, while it is sharp, and it is the sharpest lesson this iteration produced.

The practice of walking every consumer of every flag before building **killed two wrong designs
pre-construction**: T088's "supply the missing marker" (measurement showed silence, not a marker-less
block) and T090's `HasPendingVerdict=false` (which would have broken verdict capture). Both saves
were real and both were cheap.

**It missed the one design it was not applied to.** The shipped evidence gate checks a mutable live
tree while the marker authorizes an immutable bound tree — one consumer, unwalked — and that produced
a false-authorization path in the code written to prevent false authorization. The independent
reviewer walked the graph the implementer didn't.

**The lesson is not "apply it harder."** A practice applied intermittently is indistinguishable from
luck, and this iteration has the control group to prove it: two applications, two saves; one
omission, one blocking defect. **It must become a named design-gate step — walk every consumer of
every flag you touch, in writing, before building** — so the record shows whether it was done rather
than whether it occurred to someone.

The reviewer being the backstop worked. The point of making the practice structural is that it should
not need to.

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

## DRIFT-198-I011-012 (BLOCKING, pre-tag) — the shipped orchestration gates BEFORE it syncs; FR-066's arrival state is unreachable through the shipped path

**Found by the maintainer's pre-tag manual test on a fresh consumer project (`C:\Temp\testbeta2`,
frozen as evidence) — not by any engine test.** The tag is held; `main` carries this as a known
standing red until the slice closes. Requirement: FR-066 (first-boundary arrival state).

### The mechanism, verified at source

In `extensions/specrew-speckit/commands/speckit.specrew-speckit.sync-specify.md`:

| Order | Line | What runs | At a FIRST boundary |
| --- | --- | --- | --- |
| block 1 | 28 | `Test-SpecrewBoundaryAuthorization` | **throws** — no authorization can exist yet — aborting the skill |
| block 2 | 40 | `sync-boundary-state.ps1` (the arrival sync) | **never reached** |

So no crossing is recorded, no `pending-verdict-stop.md` is written, and the gate-stop skill's
no-artifact fallback then instructs the agent to INVENT a marker (observed: `specify -> specify`,
July's F1 signature). FR-066's arrival-state code is delivered and correct — and unreachable at the
exact moment it exists for.

### Why every engine test missed it

The existing suites invoke the sync FUNCTION directly. That proves the engine records an arrival
correctly — and it does. It cannot prove the shipped ORCHESTRATION ever calls it. **The tested path
was not the shipped path.** This is the third instance of the reachability class (T089's unreachable
branch; finding 2's three-mint-site funnel; this), and the sharpest: it survived two releases
because every green pointed at the engine.

### Evidence status at this commit — recorded honestly, nothing banked

`tests/integration/shipped-orchestration-arrival.tests.ps1` is committed WITH this entry, in exactly
this state:

**Ordering RED: honest and recorded.** The fixture reads the shipped skill itself — not a copy —
and measures the authorization gate (line 28) preceding the arrival sync (line 40).

**Behavioral RED: explicitly UNPROVEN.** Two probe runs produced REDs that could not be attributed
to the product refusing — probe contamination, refused rather than banked:

1. `-CurrentBoundary ''` — parameter-binding failure: the probe failing, not the product refusing.
2. `-CurrentBoundary 'intake'` — the RED could not be attributed to the product's first-boundary
   refusal rather than canonical-vocabulary rejection of `'intake'` itself. Whether the
   authorization surface can represent a first crossing AT ALL — the `intake -> specify` crossing
   that `Get-SpecrewPendingBoundaryCrossing` emits vs the vocabulary
   `Resolve-SpecrewCanonicalBoundaryType` accepts — is an open question under evidence-only
   investigation, and its answer decides the fix's shape.

A third gap, seen at source while committing: the shipped block computes its own `$currentBoundary`
(defaulting to `'specify'` when `session_state.boundary_type` is missing or blank), so a probe
passing `'intake'` does not replicate the shipped computation it claims to test. **A RED that fires
for the wrong reason is refused, not banked** — it is the mirror image of the green that measures
nothing.

### Scope

Release-gate scope, pre-tag; iteration 011's retro'd ~29.0/20 does not reopen. Cost lands on the
release-slice cost line when the slice closes. Orchestration-path fixtures as a class are the
structural cure for the reachability class and belong in the release gate — the beta3 row carries
them. The fixture is deliberately NOT registered in `tests/f198-regression-suite.ps1` while RED (a
red workflow is a stop); registering it green is an obligation of the slice's close, under the same
ruling as T092: a deliberate RED must never quietly become a skipped test.

## DRIFT-198-I011-012 — the consequence-graph walk, in writing, before the reorder

Maintainer verdict 2026-08-08: Option 1 (gate-internal first-crossing translation), with the
implementation lead "derive targetFrom as null and let the matcher's dormant arm do the work", and
the constraint that ordering enforcement stays where it lives. This walk is the named design-gate
step the retro promoted: every consumer of every surface the change touches, walked before building.

### The honest RED, banked first (commit 74594c35)

The repaired probe executes the shipped skill's own fenced blocks against a bootstrapped fresh
consumer project. Four REDs, zero INCONCLUSIVE, each firing for the product's reason — including the
runtime kill-shot: after writing the exact entry the capture writer mints (`{from: null, to:
specify}`), the gate still answers `blocked: No persisted authorization matched specify -> specify`.
The detector measured live: `pending=True, from=null, markerFrom=intake`.

### What the arrival sync writes, and who consumes each write

| Sync write | Consumers (verified at source) |
| --- | --- |
| `session_state.boundary_type` (the working cursor) | pending-crossing detector; unreconciled read's legacy arm; conformance provider; the skills' own `$currentBoundary` computation |
| `pending_crossing` scope (`intake -> specify` at first arrival) | `Get-SpecrewPendingVerdictState` scoped read (integrity + re-derive cross-check); verdict capture's expected-marker derivation; unreconciled read's working-boundary arm; ratchet |
| `pending_next_boundary` | state validator (canonical-only field); informational readers |
| `.specrew/runtime/pending-verdict-stop.md` | the gate-stop skill (controller truth for the marker); Stop-hook packet renderer; retired/refreshed post-capture by `Sync-SpecrewPendingVerdictArtifactAfterAuthorization` |
| ledger + `.squad` claims + lint pass + dashboards | decision ledger readers; unchanged by this slice |

### Ordering authority: the ratchet owns it; the gate defers

`Invoke-SpecrewBoundaryStateSync` calls `Invoke-SpecrewBoundaryRatchetGate` before recording
(`scripts/internal/sync-boundary-state.ps1:1556`). The ratchet's contract states the design intent
verbatim: **"the FIRST unapproved crossing still records mechanically … a SECOND advance while that
crossing is unapproved is refused … re-syncing the SAME boundary stays allowed."** Sync-then-gate is
therefore not a new policy — it is the ratchet's own contract, currently unreachable through the
skills because the advancement gate aborts the skill before the sync runs. The gate translation
adds no ordering logic; skipped-boundary refusal stays in the ratchet (verified: an unauthorized
skip is refused at the SYNC, before any recording).

### The dormant-arm lead: CONFIRMED, with in-repo precedent

`Get-SpecrewUnreconciledBoundary` already calls the shared matcher with **no `-FromBoundary`**
(shared-governance.ps1:3004) — the null-targetFrom arm (2916) is the unreconciled primitive's
existing convention for exactly this question. The gate fix aligns the live gate with that
convention in first-crossing mode only: when the effective `last_authorized_boundary` is null and
the requested boundary is the first canonical boundary, pass targetFrom null. It matches recorded
reality (`{from: null}` entries are all any writer mints — `Add-SpecrewBoundaryAuthorization`
resolves a non-null from-side canonically, so `intake` can never be written into history), and it
cannot loosen later crossings (trigger requires a null cursor AND requested == order[0]).

### The walk's biggest finding: the marker-invention fallback is LOAD-BEARING for boundaries 2..N

Three facts compose:

1. Post-capture, `Sync-SpecrewPendingVerdictArtifactAfterAuthorization` re-derives pending state,
   gets none (cursor == working), and REMOVES `pending-verdict-stop.md`.
2. The next ask is minted only by a SYNC: the next boundary's own sync (arrival ask), or a re-sync
   of the authorized boundary via `-OpenNextCrossingWhenBoundaryAuthorized`
   (sync-boundary-state.ps1:1680) — nothing mints at capture time.
3. Under gate-first ordering, every skill's first pass aborts BEFORE its sync.

So at every boundary after capture there is a window with NO artifact and NO pending ask, and the
gate-first skill aborts inside it — which is precisely when the gate-stop skill's no-artifact
fallback tells the agent to infer a marker. **The shipped flow for boundaries 2..N has been standing
on the invention crutch the whole time**: linearly the invented marker happens to be correct, so it
looked like working machinery; at the first boundary the inference produced `specify -> specify`
(July's F1), and at over-advances it names the wrong crossing. Consequence, binding on sequencing:
**all nine gate-carrying skills reorder BEFORE the fallback clause is replaced** — retiring the
crutch first would strand every boundary after specify. The audit below records per-skill verdicts,
but the reorder is not optional per skill.

### The reordered flow, walked end-to-end

- **First boundary**: work → sync records arrival (ratchet passes: nothing unreconciled), mints
  `intake -> specify` + artifact → gate refuses (no entry yet) → stop WITH controller truth →
  capture writes `{null -> specify}`, cursor moves, artifact retired → flow proceeds; any re-run of
  the skill re-syncs idempotently (ratchet allows same-boundary), `OpenNext` mints the advance ask,
  and the translated gate now matches the recorded entry (probe leg D turns green).
- **Normal boundary X**: work → sync mints `prev -> X` + artifact → gate refuses → stop with truth →
  capture `{prev -> X}` → proceed. The ask is machinery-minted at every stop; no inference remains.
- **Over-advance recovery**: working jumped ahead on a fresh project → sync still mints the FIRST
  unpaid crossing (`intake -> specify`, IsMultiBoundaryGap) → the stop demands the earliest
  boundary, one approval at a time — conformance Cases 11b/11c behavior preserved.
- **Unauthorized skip**: sync for a later boundary while an earlier crossing is unapproved → the
  RATCHET refuses before recording — ordering enforcement untouched by the gate change.

### Gate-result consumers under the translation

- The nine skills consume `.Authorized`, `.Reason` (thrown), and pass `.CurrentBoundary` /
  `.RequestedBoundary` / `.DirectiveSentinel` to `Write-SpecrewBoundaryAuthorizationDirective`. In
  first-crossing mode the result reports the crossing in marker vocabulary (`intake`), so the
  directive writer learns the same from-side tolerance the crossing-identity minting already has
  (shared-governance.ps1:1443 pattern). `verdict_history` vocabulary is untouched.
- The 3a run surfaced a latent directive bug fixed in the same touch: the blocked/authorized
  directive text backtick-escapes `$currentCanonical`, rendering the VARIABLE NAME literally to the
  human ("Boundary $currentCanonical -> specify requires…") — measured in the probe's block-1
  output.
- The enforcement decision-ledger entry's `Current Boundary` line is a free-text field (only the
  `Boundary` title field resolves canonically) — safe to carry `intake`.

### Named, not solved here: the second-feature arrival edge

The crossing detector has exactly one reset edge (`iteration-closeout -> plan`). A SECOND feature in
the same project leaves the cursor at `feature-closeout`, from which no `-> specify` crossing can be
minted. Feature 198's own ledger began `{null -> specify}` only because this worktree was fresh.
Same reachability class, adjacent scope — recorded for the beta3 vocabulary/reset cluster, not
expanded into this release slice.

### Killed by the walk

- Capture-side `from: 'specify'` self-edges (Option 3) — falsified before the verdict; stays
  never-offerable.
- Ordering checks inside the gate — rejected; the ratchet owns ordering and already refuses skips.
- 3c before the reorder — would strand boundaries 2..N (the crutch discovery above); sequencing
  locked as: gate fix → nine-skill reorder → fallback replacement.

### The nine-skill audit and reorder (3b executed)

Every gate-carrying skill audited at source; every one carried the gate-first pattern; all nine
reordered (arrival sync before the advancement gate, gate last with the controller-truth render
instruction). Mirrors under `.specify/` synced and hash-verified.

| Skill | Gate-first | From-side (kept) | Arrival sync before the fix | Action |
| --- | --- | --- | --- | --- |
| sync-specify | yes (gate 28 / sync 40) | computed, `'specify'` fallback | present, unreachable | reordered; workshop gate stays pre-work |
| sync-clarify | yes | `'specify'` | present, post-gate | reordered |
| sync-plan | yes | `'clarify'` | present, post-gate | reordered |
| sync-tasks | yes | `'plan'` | present, post-gate | reordered |
| before-implement | yes | `'tasks'` | **ABSENT — no sync in the skill at all** | reordered + arrival sync ADDED |
| sync-review-signoff | yes | `'before-implement'` | present, post-gate | reordered |
| sync-retro | yes | `'review-signoff'` | present, post-gate | reordered |
| sync-iteration-closeout | yes | `'retro'` | present, post-gate | reordered |
| sync-feature-closeout | yes | `'iteration-closeout'` | present, post-gate | reordered |

The hard-coded from-sides are retained: for non-first crossings they are the exact vocabulary the
capture writer mints (`{cursor -> X}`), so the gate matches recorded reality. `before-implement`
was the sharpest audit find after sync-specify: it gated with NO arrival sync anywhere in the
skill, so its pending ask depended entirely on off-skill machinery.

Semantics note, recorded as a deliberate trade: work-before-authorization at each skill's own
boundary is the ratchet's stated contract ("the FIRST unapproved crossing still records
mechanically; a SECOND advance is refused"). A skill invoked out of order now performs its work
before the ratchet refuses at the sync — governance holds (nothing advances, nothing records), and
the refusal is consumer-legible; the wasted work is visible instead of a silent gate-abort with no
artifact.

### GREEN through the shipped path (the fixture's full contract)

After gate fix + reorder, `tests/integration/shipped-orchestration-arrival.tests.ps1` exits 0 with
every leg measured live: ordering (sync 32 < gate 53); block 2's engine result
`boundary_record_status: "established", is_first_boundary: true`; `pending_crossing`
`intake -> specify`; `pending-verdict-stop.md` present with the `intake -> specify` marker; the
advancement gate blocking with `` Boundary `intake -> specify` requires explicit human
authorization ``; and the gate authorizing after the capture-minted `{from: null, to: specify}`
entry. The orchestration was the subject under test, end to end.

## DRIFT-198-I011-012 — secondary findings (3e), each with its writer named

### (1) MOST SERIOUS — a reviewer authorization written outside the 028 ceremony, by version-skewed 0.39.0 machinery

The evidence chain, from the frozen `C:\Temp\testbeta2`:

- Bootstrapped 2026-08-07 23:17 local under `specrew_version: "0.40.0"` — which exists ONLY as the
  dev tree (installed modules: 0.39.0, 0.38.0, 0.37.0, 0.32.0 — no 0.40.0).
- `reviewer-hosts.json` was created 2026-08-08 00:49:33 — 92 minutes AFTER bootstrap, mid-session,
  by runtime machinery, not by project scaffolding.
- Its codex row: `allowed: true`, `authorization_ref: "workshop-001-linkcheck"`,
  `model_source: "human-entered"`, `model: "chatgpt"`. All other rows carry the contract-clean
  defaults (`allowed: false`, `authorization_ref: null`).
- The workshop record EXISTS and is human-confirmed: 001-linkcheck's code-implementation lens
  (`confirmation: human-confirmed`, `confirmation_scope: lens-question`) records "Reviewer: codex,
  human-selected (intake brief + strongest independent host), authorization-ref
  workshop-001-linkcheck".
- `workshop-001-linkcheck` appears NOWHERE in the 0.40.0 tree nor in any installed module — the
  row was synthesized at runtime from the workshop answer.
- With `SPECREW_MODULE_PATH` unset and no 0.40.0 module installed, the deployed wrapper's path-2
  resolution dispatches to the INSTALLED newest module — 0.39.0 — whose reviewer-hosts writers
  (`specrew-review.ps1`, `worktree-review-orchestrator.ps1`) carry NO stale-install guard; that
  refusal exists only in the sync wrapper.

**Verdict against the 028-fixed shape** (`docs/data-contracts.md:131`: the authorization writer is
`specrew review --host <h> --authorization-ref <ref>` — human authorization — plus installed-state
refresh): structurally conformant; non-codex defaults clean; the codex authorization is
**human-real but ceremony-bypassed** — workshop machinery converted a lens answer into registry
authorization rows the contract reserves for the explicit ceremony — with **provenance
overclaimed** (`model_source: "human-entered"` for a model value the human never entered) and the
write **executed by version-skewed 0.39.0 code inside a 0.40.0-governed project**. Correcting this
slice's own earlier framing, honestly: this is NOT fabricated-from-nothing (the first reading);
the human decision is real and recorded — the defect is the bypassed ceremony, the overclaimed
provenance fields, and the skewed writer the 0.40.0 tree cannot vouch for. The write also violates
the DRIFT-198-I009-028 write-scope contract pinned by
`tests/continuous-co-review/unit/reviewer-host-grant-write-scope.Tests.ps1` — a grant writes ONE
field of ONE row; this write set `allowed`, `authorization_ref`, `model_source`, and `model`
together.

Routed to beta3: (a) review-side writers gain the sync wrapper's stale-install refusal; (b) a
workshop-lens reviewer selection flows INTO the 028 ceremony (minted via `specrew review --host`)
instead of writing registry rows directly; (c) `model_source` records its true source.

### (2) The state.md re-revert — third strike, writer NAMED

- The write pair at 2026-08-07T22:36:31Z: `tasks-progress.yml` `updated_at` at `.017Z`, `state.md`
  `Updated` at `.078Z` — one writer pass, 60ms apart.
- `.specrew/runtime/hook-bootstrap-render-8d74ccea-…-clear.json` is stamped the SAME second —
  **the writer is THIS session's SessionStart (/clear) bootstrap**: its task-progress refresh
  (`scripts/internal/task-progress.ps1`, loaded by `specrew-start.ps1` /
  `coordinator-resume.ps1`) regenerated state.md's managed block from `tasks-progress.yml`.
- Root cause, which the third strike finally surfaces: the closure correction lives ONLY in
  state.md's narrative; `tasks-progress.yml` still records T091/T093/T092 as pending. The
  generator faithfully re-asserts yml-truth over narrative-truth at every session start — so
  restoring state.md alone re-reverts at the NEXT start. The durable fix is reconciling the yml's
  terminal statuses (needs a maintainer ruling on the exact statuses) or teaching the generator
  the recorded closure attempt. Until one lands, every restore is temporary and this entry is the
  standing explanation.
- state.md and tasks-progress.yml are restored to the committed corrected record with this entry.

### (3) The timestampless pending_next_boundary mutation (-010 family)

`Test-SpecrewBoundaryAuthorization`'s blocked path writes state (`pending_next_boundary` set to
the requested boundary) through `Set-SpecrewBoundaryEnforcementState`, which stamps
`generated_at_utc` only when the field is absent — an existing stamp is preserved stale, so the
mutation is invisible in the file's own dating. The -010 family shape: machinery mutating records
without honest self-dating. Recorded, not fixed in this slice.

### (4) The reachability class, third instance — structural cure named

Consolidated: T089's unreachable branch; finding 2's three-mint-site funnel; -012's
gate-before-sync. The cure is the orchestration-path fixture class — execute the shipped skill's
OWN blocks against a real project — now instantiated once
(`shipped-orchestration-arrival.tests.ps1`) and routed to beta3 as a per-shipped-skill release-gate
requirement, alongside the second-feature reset edge named by the walk.

## PRE-TAG SLICE #2 — the testbeta3 re-test (maintainer manual test, frozen at `C:\Temp\testbeta3-842854746`)

### The navigator pre-implement contradiction — FIXED (commit f2c2c7d8)

Fully characterized at source: `Get-ReviewCampaignNavigatorScopeApplicability` turned applicability
ON at bare iteration-directory existence while the auto-fire path stays implement-only — so every
consumer at design-analysis received a standing review-required Stop block that nothing could ever
satisfy. The testbeta3 journal is the evidence: `campaign-not-applicable:no-active-iteration`
flipped to `no-authoritative-campaign-result` at 2026-08-08T01:13:28Z when
scaffold-iteration-artifacts created `iterations/NNN`, four standing stops followed, and the
maintainer freed the session by hand at 01:21.

The fix is the i009 quiet-no-op family's missing edge: at the design-analysis cursors (`plan`,
`tasks`) applicability returns quiet not-applicable and the packet gate is never consulted;
auto-fire stays implement-only; pre-code reviews remain human-CLI-initiated. The WORKING position
decides (session cursor, then the pending crossing's working boundary, then the authorized
cursor) — the first fix draft used the authorized cursor and the pre-existing v2
missing-iteration fail-closed case caught it: a pending crossing INTO `before-implement` is the
implement window's edge, not design-analysis. RED-first: five new cases (standing-block
reproduction at plan/tasks, the journal-flip sequence, the v2 cursor shape, and two
gate-still-consulted guards at before-implement/review-signoff); suite 29/29 after.

### The three priced smalls — together ~0.9 SP, under the ~1 SP cap, so FIXED (commit fad2a8ee)

| Small | Defect | Fix |
| --- | --- | --- |
| (a) handoff WARN | the trust-hardening check recognized only the legacy `=== SPECREW HANDOFF ===` block — WARN at every healthy stop on hosts where Rule 46 forbids duplicating it | the six-section packet (three anchored headings) counts as handoff evidence; legacy stays recognized; prose still fails |
| (b) resolver binding | a bare `resolve-quality-profile.ps1` invocation resolved feature-blind (never consulted feature.json) | defaults the feature from `.specify/feature.json`, fail-open |
| (c) quality scaffold | the quality/ subtree was Phase-2/contract-gated while the launch contract claims it unconditionally | claimed set emitted unconditionally; `trap-reapplication.md` stays Phase-2-gated |

(c) carried a second mismatch cutting the OTHER way: the launch contract promised
`Overall Verdict: ready` by default while the generator correctly defaults to `blocked` with
placeholder rows. A ready-by-default gate would wave hardening through unreviewed — the CLAIM was
corrected (`scripts/internal/launch-contract.ps1`), the gate was not weakened.

### Routed to beta3, no pre-tag action (maintainer ruling 2026-08-08)

- F9 numeric-label acceptance — vocabulary work.
- The ceremony-bypassed reviewer-authorization writer (the 3e finding above) — reaffirmed.
- The composition/priority interleaving — the maintainer-observed instance is recorded with the
  SC-025 composition row above.
- The campaign directory-vs-content activation design question — with the iteration-N+1
  cycle-reset adjacency named by the consequence-graph walk as the same family: activation keyed
  on directory existence is what this slice's navigator defect and the -012 arrival defect share.

### RELEASE RECORD — the consumer review-touch coverage gap, named not papered

The consumer review-touch on the fixed review-engine bits was NOT obtained: the test
environment's module quarantine (bit-pinning) made the CLI door unreachable, and the navigator
door carried the pre-implement defect above until this slice. Coverage claimed instead, at its
true extent: the frozen article-amplifier round-15 replay plus every self-hosted certification
run since i009 exercised file-primary delivery, candidate composition, and exclusion honoring on
the fixed engine. The gap is named here so the tag rests on stated coverage, not implied coverage.

### Dry-run correction: the first fix quieted the PATTERN, not the INSTANCE

Reviewer-verified against scratch reproductions of testbeta3's state: at 01:13:28 the working
boundary was still **clarify** — before-plan scaffolds the iteration BEFORE any plan sync advances
the cursor — and cursor=clarify + iteration-present still returned `campaign-applicable`, so the
standing block returned at the design-analysis retry. The five RED cases had reproduced the
pattern (a plan/tasks cursor) rather than the journal's exact state; the flip fixture even
ADVANCED the cursor to plan before scaffolding — modeling the defect as I imagined it, not as it
happened.

Corrected under the same ruling framework: an instance-pinning RED first (cursor=clarify,
iteration present, session-scoped feature_path — RED proven, `campaign-packet-gate-failed` where
quiet was owed), then the quiet window stated as the INVERSION so no future cursor rejoins the
gap: with an iteration present, the campaign surface is LIVE from `before-implement` onward (plus
the legacy `implement` alias); every earlier resolved canonical working cursor is quiet
not-applicable; unresolved cursors stay fail-closed applicable. Suite 32/32.

**Method rule recorded, alongside the fixture-discipline rules this iteration already produced:
reproduce the INSTANCE first, always — generalize to the class only after the exact observed
state is pinned red.** A fixture that reproduces the imagined shape of a defect can go green while
the defect stands.

### Found by the quarantine: two fixtures were green by borrowing the installed module

The maintainer's module quarantine (bit-pinning) removed the installed Specrew modules mid-slice,
and the full gate promptly went red on the fr066/fr068 fixtures — not from either slice's changes
(both bisected clean at the file level, and the engine's `boundary-unrecordable` read verified
correct at HEAD) but because those fixtures' provider children resolved
`ConversationCaptureAccessor` through the `Get-Module -ListAvailable` fallback: an AMBIENT
installed 0.39.0 module, not the tree under test. The registry exported `SPECREW_MODULE_PATH`
only to pester-kind suites; script-kind suites ran bare, so their governed children leaned on
whatever install happened to exist. With the accessor gone, `$canAssess` stayed false and the
provider fell silent — the exact silence T089 exists to prevent, produced by the harness instead
of the product.

Fixed at the harness choke point: the registry runner pins `SPECREW_MODULE_PATH` to the repo for
every child suite. Both fixtures verified green under the pin. The class lesson is the -012 lesson
inverted: **the tested path must be the shipped path — including the bits it LOADS.** The
quarantine was the instrument that caught a borrowed-bits green that had held since the fixtures
were registered; recorded with credit.

### Verification path to the tag

After this slice: the maintainer resumes testbeta3 (the scaffold is intact — the standing block
should simply go quiet), then the certify re-run under a fresh reference, then `v0.40.0-beta2`.
The tag waits on both.
