# Iteration State: 011

**Schema**: v1
**Current Phase**: complete
**Iteration Status**: complete
**Closed**: 2026-08-09T22:21:33Z (registry entry via `Add-SpecrewClosedIterationEntry`) on the hook-captured `approved for iteration-closeout` — see the Closeout notes; the accepted-verdict finding is waived scoped (decision `f198-i011-waive-accepted-verdict-finding-iteration-closeout-gate`) and `review.md` keeps `needs-rework`
**Closure Attempt (REVERSED)**: closed 2026-08-06T13:19:56Z on an approved verdict, then **un-closed the
same day** when the release gate (`validate-governance.ps1 -IncludeClosed`) rejected the closure as
`over-claim`: the status claimed closure while `review.md` and `quality/hardening-gate.md` did not exist.
The verdict was real; the artifacts were not. **The status was reversed rather than the evidence
backfilled under it**, so the record never shows closure preceding its evidence.
**Last Completed Task**: T067 — the published-bits consumer validation (concluded 2026-08-10)
**Tasks Remaining**: (none — T091/T093 deferred to beta3 by recorded decision; T092 terminal `deferred` at its cap)
**In Progress**: (none)
**Baseline Ref**: d7f27f6a
**Updated**: 2026-08-09T22:04:13.0000000Z

## Execution Summary

<!-- specrew:task-progress-summary:begin -->
- Execution is complete; the iteration awaits its closeout crossing.
- Task progress: 6 complete, 0 in-progress, 3 deferred (beta3), 0 blocked.
- Latest completed task: T067
<!-- specrew:task-progress-summary:end -->

| Task | Status | Evidence |
| --- | --- | --- |
| T086 | done | FR-068 reproduction, both halves, RED-first |
| T087 | done | FR-066 fixtures RED-first; premise corrected on measurement |
| T088 | done | Unrecordable crossing is a branchable state; `success=false` |
| T089 | done | Provider speaks and names what is missing; T087 fully green |
| T090 | done | Both branches gated from one helper; T086 half 1 GREEN; contract authored |
| T091 | deferred | Composition half → beta3 hook-machinery cluster |
| T093 | deferred | Relief valve fired at T090's re-estimate → beta3 first row |
| T092 | deferred (ran to the cap; did NOT certify) | 3 of 3 rounds spent. R1: 4 findings. R2: validated findings 1/3/4, 1 blocking on the finding-2 fix. R3 (current digest): 1 blocking + 1 major. Finding-2 attempts reverted per the pre-committed ruling; gate green 90/90 |
| T067 | done | Published-bits consumer validation, concluded 2026-08-10: Gallery install (no pinning), full governed lifecycle on a blind consumer project, six boundary verdicts faithfully captured, product built and signed off with recorded residuals. Retro/iteration-closeout not exercised — recorded coverage gap. Findings consolidated in the beta3 carry ledger |

## Delivery Position — FR-066 PARTIAL, FR-068 evidence half DELIVERED

| Requirement | State |
| --- | --- |
| FR-068 evidence half | **delivered** — tree-bound stage evidence, fail-closed unverifiable reasons, strict clarify matcher; validated by round 2, unchanged since |
| FR-066 arrival state | **delivered** — the unrecordable crossing is branchable and the surface names what is missing |
| FR-066 mint guard | **NOT delivered** — two attempts, both faulted (double-failure window; concurrent latch clear). Reverted. **The mint hole is OPEN and known.** |

**The current tree carries no independent certification**: all three rounds are spent and `86c5eb07`
has never been reviewed in this exact shape. Round 2's validation of findings 1/3/4 stands, and their
code is byte-unchanged since — that is the assurance the tag rests on. The green 90/90 gate is a
regression floor, not a certification.

**TAG BASIS RULED 2026-08-06 — named-limitation.** Beta2 gates on FR-068's evidence half plus FR-066's
arrival state; FR-066's mint guard ships as a named known defect carried to beta3. Iteration 011 **records**
at **~29.0/20 uncompressed with FR-066 partial** and is held open — see the closure trigger below. The beta3 carry list is consolidated in
file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/iterations/011/drift-log.md

## Release Sequence — v0.40.0-beta2 SHIPPED (2026-08-09)

The beta2 tag was cut and published after four pre-tag release-gate slices, each recorded on its own
cost line in the drift log's release-slice table, **separate from the retro'd ~29.0/20** which does
not reopen:

| Pre-tag slice | Scope | SP |
| --- | --- | ---: |
| DRIFT-198-I011-012 | first-boundary arrival reachable through all nine shipped skills; gate first-crossing translation; marker-invention retirement; FR-066 reconciled | ~2.5 |
| Slice #2 (testbeta3) | navigator pre-implement quiet edge (inversion); three priced smalls; engine-under-test registry pin | ~1.4 |
| Slice #3 (certify findings) | marker cannot bypass the evidence refusal; capped refused boundaries never demand a marker; Ordinal git-tree evidence matching; feature.json containment; launch-contract claim | ~1.2 |
| Slice #4 (certify findings) | capture refuses checked-and-absent crossings loudly; separator-boundary containment; three-outcome distinction travels | ~1.0 |

**Release outcome, measured**: merge commit `67a5d7bc` (PR #3318) inside a 35-second lower-restore
window (2026-08-09T00:44:39Z–00:45:14Z, both settings restored and read back — the durable record
is the PR comment); annotated tag `v0.40.0-beta2` at the merge commit naming the release claim as
the position of record; publish workflow green including the tag-time prepublish gate; Gallery
listing live 2026-08-09T00:48:33Z with the Prerelease flag; GitHub release carrying the
twelve-item known-issues body. **Tag-basis correction, disclosed**: the certified head is
`0fa26271`; the tag basis differs by 15 files, zero of them code — the three documentation-only
closure commits plus main-side records predating this branch's base (proposals, methodology docs,
and the 2026-07-17 repository-governance reconciliation record), carried by the merge target's own
reviewed history. Certification lineage: `run-f198-beta2-c0c3cda6-certify`,
`run-f198-beta2-4e7d002c-certify`, `run-f198-beta2-0fa26271-certify` — the third adjudicated by the
maintainer's trajectory ruling (two expected residuals; one link-class routing; two beta3 design
owners, release-claim limitations 12/13).

**T067 COMPLETE (2026-08-10)** — the published-bits consumer validation concluded: `0.40.0-beta2`
installed from the Gallery (no pinning; the OneDrive cloud-placeholder refusal met the documented
workaround — byte-identical local copy, hashes verified), the full governed lifecycle exercised on
a blind consumer project at file:///C:/Temp/t067-linkcheck/, six boundary verdicts faithfully
captured, the product built and signed off with recorded residuals through the identity-bound
disposition route. Retro and iteration-closeout were NOT exercised there — a recorded coverage
gap. Eight findings (T067-F1..F8) and eight observations — all NEW, none among the release's
twelve known issues, none regressing the tag's authorization-integrity basis — are consolidated
with the maintainer's beta3/beta4 split ruling in
file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/beta3-carry-ledger.md. The full
outcome record fills the pending-evidence slots this paragraph reserved in `review.md` and
`quality/hardening-gate.md`.

## Closure Trigger — why 011 is honestly OPEN

**The schema vocabulary blocks an honest closure, and the words were not bent to reach one.**

Closure requires `Overall Verdict: accepted`, which the schema permits only when **every** task verdict is
`pass`. T092's deliverable is *integrated verification and capped certification*. Verification passed
(90/90); **certification was attempted to the full 3-round cap and not achieved.** Marking T092 `pass`
would assert a result that does not exist, so `review.md` records `needs-rework` and the iteration is held
at `retro` — past its approved retrospective, but not closed.

**Closure trigger**: iteration 011 closes when **beta3 delivers FR-066's mint guard** from its design
spike — at which point FR-066 is whole and T092's certification claim can be re-made against a tree that
carries it.

**The beta2 tag proceeds with 011 honestly open.** The named-limitation basis never claimed 011's
certification, so nothing downstream depends on this closure. An open iteration with true artifacts beats
a closed one with false words.

### Closure position addendum (2026-08-10) — T067 complete; maintainer-directed closeout crossing

The trigger above was written 2026-08-06, before the release and before the beta3/beta4 split
ruling (2026-08-09) moved the FR-066 mint-guard design spike into beta4's small-fix tail — under
that split, the recorded trigger would hold 011 open across two whole betas. With the T067 record
complete (the last pending-evidence slot filled), the maintainer directed on 2026-08-10 that the
iteration-closeout crossing be presented on this record: T092 remains `needs-rework`/`deferred`
exactly as recorded — no word is bent — the mint-guard debt carries in
file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/beta3-carry-ledger.md, and the
human verdict at that crossing is the ruling of record that supersedes the trigger.

### Evidence mechanical freeze (2026-08-10)

Policy-freeze became mechanical-freeze (carry-ledger item G): both frozen evidence directories are
archived as read-only zips, zip entry counts verified equal to source file counts, SHA-256
recorded here as the tamper-evidence.

| Source (frozen) | Archive (read-only) | SHA-256 | Size | Entries |
| --- | --- | --- | --- | --- |
| file:///C:/Temp/testbeta3-842854746/ | file:///C:/Temp/testbeta3-842854746-frozen-20260810.zip | `8FB791F895C3A3172E7E8340041316F74E776E522E0439EC7B63D49175CFF151` | 4,411,777 B | 1,646 = source |
| file:///C:/Temp/t067-linkcheck/ | file:///C:/Temp/t067-linkcheck-frozen-20260810.zip | `F6B737B5AEACFA983F84072CF3835A3D30ED1BC52F85DFC76AC66B79E4B78713` | 10,596,204 B | 2,936 = source |

`testbeta3-842854746` carries its recorded integrity annotation (accidental resumed session
`659f661d` touched four files 2026-08-09 00:00–00:48; the canonical record is unaffected and the
exact delta is recoverable from that session's transcript — carry-ledger item G). The archive
freezes the directory as-is, annotation and all.

### Closeout notes (2026-08-10)

Recorded under the maintainer's instruction-bearing retro approval (2026-08-10):

- **Fresh stop-surface evidence from this closure session** (F5/stop-surface family; recorded
  here per instruction, the committed carry ledger unedited): (1) the first iteration-closeout
  sync, invoked without an iteration identity, minted the pending `review-signoff -> retro`
  crossing but wrote no pending-verdict artifact; (2) a retro-boundary sync was then refused by
  the ratchet naming `iteration-closeout` as the waiting step while the authorization store held
  `review-signoff -> retro` pending — a dual-governor surface, adjudicated by the authorization
  store; (3) the FR-068 evidence gate refused the boundary stop because the crossing carried no
  iteration identity — the fail-closed unverifiable path this iteration shipped, validated live
  against its own crossing; re-syncing with `-IterationNumber 011` re-established the record and
  produced the authoritative stop artifact. Archaeology: the handover journal's
  `marker-cursor-mismatch` events (2026-08-06T15:30Z) show the reversal-era retro/closeout
  approvals bounced at capture (`retro -> iteration-closeout` against an authorized cursor of
  `review-signoff`) — which is why this closure re-registers them. Mid-turn after the 2026-08-10
  verdict reply, the durable store still read `review-signoff`: verdict capture is Stop-gated on
  this host — a watch item for the capture-ordering class.
- **Chore carried to the beta3 window** (maintainer instruction 2026-08-10; this note is the
  carry record, the ledger file unedited): install `markdownlint-cli` on the Specrew CI runner
  (`npm install -g markdownlint-cli` in the workflow) so
  `tests/integration/generator-markdown-parity.tests.ps1` stops reporting INCONCLUSIVE — the
  standing main red, failing on main since 2026-08-07 including the release merge commit.
- **Alignment PR #3503** (the Review Proof line in `docs/release-notes-v0.40.0-beta2.md`
  corrected to the measured 15-file statement; the tag-pinned copy predates the correction by
  design): all checks green except the standing main red; maintainer-approved to merge over it.
  Normal and admin merges are refused by base-branch policy (one approving review required; the
  failing required `Deterministic gate`; `enforce_admins` on), so the release-precedent
  lower-restore window awaits the maintainer's own execution; PR state at recording: OPEN,
  MERGEABLE.
- Stray empty root file `clarify` deleted per the same instruction.
- **Closure registered (2026-08-10)**: `approved for retro` (2026-08-09T23:10:30Z) and
  `approved for iteration-closeout` (2026-08-09T23:14:59Z) both hook-captured into the durable
  verdict history (crossings `crossing-97351dea…` and `crossing-7b96a185…`, bound tree `7852b277`
  at commit `48be8825`); iteration 011 appended to the closed-iteration index via
  `Add-SpecrewClosedIterationEntry` (closed_at anchored to the closeout sync,
  2026-08-09T22:21:33Z); the accepted-verdict finding waived scoped by decision
  `f198-i011-waive-accepted-verdict-finding-iteration-closeout-gate`; `review.md`'s overall
  verdict stays `needs-rework` — no word bent. The dashboard auto-render at the closeout sync is
  verified (F-040 Fix B working live).
- **Two capture defects root-caused live during this closure** (beta3 findings; reproductions in
  the session transcript): (1) an instruction-bearing approval whose instruction text contains
  the word "prompt" is classified `Action=discuss` and silently fails to capture — a legitimate
  approve-with-instructions verdict never recorded, with no journal event; (2) capture tests only
  the FIRST human turn after each marker, so a non-verdict turn (an accidental bash-input)
  permanently shadows a later genuine approval of the same marker. Both verified by running
  `Get-SpecrewCapturedBoundaryVerdict` read-only against the live transcript
  (`not-approval:none` → `Reason=captured` after a clean re-ask). Also observed: `'clarify'`
  inside quoted filename prose parsed as a NAMED BOUNDARY by the verdict classifier — a
  vocabulary hazard. Joins the capture-order and stop-surface clusters.
- **Limitation 11 observed live at closure**: after the closeout authorization, the crossing
  detector auto-minted its single reset edge (`iteration-closeout -> plan`) though no next
  iteration exists; the feature-closeout boundary is reached by explicit sync instead —
  carry-ledger cluster D evidence (the feature-cycle edge).
- Campaign `review-stale` fired five times across this closure session, each on a records-only
  delta, each adjudicated against the standing trajectory ruling with no spend — the F5 count is
  part of this record.

### Superseded closure attempt (retained for the record)

**Closed 2026-08-06T13:19:56Z, then REVERSED the same day.** Closed on an explicit
`approved for iteration-closeout` (approve-with-instructions),
following `approved for retro` and the retro boundary packet. Closeout actions executed:

| Action | Result |
| --- | --- |
| Iteration registered closed | file:///C:/Dev/specrew-beta2-hardening/.specrew/closed-iterations.yml — `198-beta2-hardening / 011 / 2026-08-06T13:19:56Z`, written through `Add-SpecrewClosedIterationEntry` rather than hand-edited |
| Campaign disposition | `override-block` recorded on `run-f198-i011-fe88af18-certify` by the maintainer; **no round re-funded** |
| Disposition rationale (verbatim) | *"the named-limitation tag basis explicitly does not claim certification of the final tree; this disposition formally registers that already-made human decision."* |

The disposition **registers** a human decision already made in the tag-basis ruling; it does not create
one, and it does not assert certification the tree does not have.

A `tasks-progress.yml` is authored alongside this file rather than left to be auto-created later.
Iteration 010 had none, one was minted all-pending mid-life, and the summary writer overwrote a
corrected record with "not-started" for delivered work (DRIFT-198-I010-010). Authoring the tracker
at plan time removes the condition that defect needs — and it worked: the tracker carried the real
statuses, so the generated summary above recomputed to disk truth instead of overwriting it.

## Objective

Close the two authorization-integrity defects from the consumer manual test — FR-066 and FR-068 —
where a human can be led to authorize an increment that does not exist.

## Authorization

- **Phase 1 (specify + clarify)**: approved 2026-08-02. The spec carries the FR-019 scope
  amendment and FR-066/FR-067/FR-068, with SC-022..SC-025.
- **Phase 2 (plan → tasks → before-implement)**: approved 2026-08-03/06. Implementation authorized; T086–T090 delivered.

## Scope

FR-066 and FR-068 only, with criteria SC-023 and SC-025. FR-019 and FR-067 are deferred on the
measured estimate, not on preference — see `plan.md`.

## Capacity Position — ~29.0/20, OVER BY ~9.0, uncompressed

**Superseded 2026-08-06 (second time), and recorded at the number it actually is.** Certification
round 1 returned four validated findings — two blocking, two major, all defects in 011's own
corrections — and the rework is internal to this iteration's deliverables, so the zero-slack rule does
not route it.

| | Planned | Running total |
| --- | ---: | ---: |
| Iteration 011 as approved | 20.0 | 20.0 |
| Option 3 rework (findings 1–4 + RED-first fixtures) | +5.5 | 25.5 |
| Fixture collateral at measured size (option (a), 3 suites not 1) | +3.5 | **~29.0** |

**Capacity 20. Position: OVER by ~9.0.** The estimates are NOT compressed to make the cap appear to
hold — that is precisely what Iteration 009's ledger prices at ~70 SP against a cap of 20, and the
reason its trigger needed amending twice.

**Maintainer ruling 2026-08-06: beta2 still gates on 011.** The tag basis is authorization-integrity by
explicit ruling; this overrun is honest rework of the tag-gating machinery itself, and re-cutting the
tag to avoid finishing trust machinery was already rejected as option 4 — same logic, same answer.

### Superseded capacity note (retained for the record) — 20.0/20, exactly at cap

The iteration measured **21.5 SP against a capacity of 20**. T091 (3.0 SP, FR-068's composition
half) was deferred to beta3, bringing it to 18.5; **T093 (1.5 SP) was then added by maintainer
instruction on 2026-08-03** to fix the campaign-mode halt text, putting the iteration at **exactly
20.0/20 with zero external slack.** T092's internal correction allowance is intact.

**Superseded 2026-08-06**: T090 re-estimated 4.0 → 5.5 SP at its start gate and the pre-agreed relief valve fired, deferring T093 to beta3's first row. Its 1.5 SP covers T090's gap exactly, so the iteration total is unchanged at 20.0/20.

FR-068's composition clause no longer holds this iteration open: the maintainer's authorized specify
touch names the beta3 hook-machinery cluster inside SC-025 itself, so the requirement closes
honestly rather than hitting the DRIFT-198-I009-044 wall.

## Tasks Boundary — completed 2026-08-03

- **T086–T093 breakdown**: authored, with owners, effort, ownership globs, sequencing, and
  dependencies.
- **Bidirectional traceability**: **PASS** for Iteration 011 — 8/8 tasks map to an FR by record;
  FR-066, FR-068 and FR-018 all have covering tasks; SC-023 and SC-025's evidence clause are
  covered, and SC-025's composition clause is scoped-out by name rather than left uncovered.
- **`tasks.md` backfill (DRIFT-198-I010-007)**: Iterations 009, 010 and 011 sections landed in the
  same pass. Iteration 009's check is recorded **PARTIAL, not PASS** — it was planned against
  F-labels rather than FRs, so the FR-direction check cannot be computed, and claiming PASS would
  repeat the unverified-coverage error this feature has already made twice.

## Open Obligations Carried Into This Iteration

- **The full consumer-severe set measures ~52 SP** — three iterations, not the two the carried
  instruction assumed. FR-019 alone is ~19 plus certification; FR-067 ~14 plus certification. The
  beta2 tag's basis therefore needs a maintainer ruling: gate on authorization-integrity alone, or
  on the whole set and move the tag.
- **FR-019 has a blocking precondition to settle before it is scheduled**: the repo runs in
  campaign mode, where `specrew-review.ps1:803` rejects every remediation except `override-block`,
  so the two paths FR-019 changes are unreachable in the live mode today.
- **`tasks.md` backfill (DRIFT-198-I010-007)** — DISCHARGED at the tasks boundary: Iterations 009, 010 and 011 sections landed, with 009 recorded PARTIAL rather than PASS.

## Blockers

- **Last Escalated**: (none)
