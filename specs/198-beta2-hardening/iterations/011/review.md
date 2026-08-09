# Review: Iteration 011

**Schema**: v1
**Reviewed**: 2026-08-06
**Updated**: 2026-08-10 — the T067 published-bits record folded into its reserved slot; closure-position addendum added
**Overall Verdict**: needs-rework
**Feature**: 198-beta2-hardening
**Phase**: review — **NOT concluded at iteration-closeout**; see "Why this iteration does not close"
**Disposition of record**: the named-limitation tag basis, recorded in
file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/iterations/011/drift-log.md

## Verdict

**Verification: PASS. Certification: NOT ACHIEVED.** Two separate claims, and this iteration ends with
one of each — the same shape Iteration 009 recorded, and for the same reason: the local gate is green
while independent review did not certify.

- **Verification**: `F-198 honesty regression suite: all 90 suites green` (PowerShell). A regression
  floor, not a certification.
- **Certification**: three rounds spent of a three-round cap. Round 1 returned four validated findings;
  round 2 validated findings 1/3/4 and faulted the finding-2 fix; round 3 faulted its replacement. The
  finding-2 attempts were reverted. **The shipping tree carries no certification, and the tag basis
  says so explicitly.**

`accepted` is not available and has not been taken. In this methodology `accepted` at
iteration-closeout means *the iteration's recorded disposition is accepted, including its deferrals* —
but the schema permits it only when **every** task verdict is `pass`. T092's deliverable is *integrated
verification and capped certification*; certification was attempted to the cap and not achieved, so
`pass` would assert a result that does not exist. **The word is not bent to reach a closure.**

## Task Verdicts

| Task | Requirement | Verdict | Notes |
| ---- | ----------- | ------- | ----- |
| T086 | FR-068 | pass | Both halves reproduced RED-first; half 1 green after T090. Two fixture defects found and recorded before the evidence was trusted. |
| T087 | FR-066 | pass | Three RED assertions, all green after T088/T089. Premise was wrong and was corrected on measurement rather than reshaped. |
| T088 | FR-066 | pass | The unrecordable crossing is a branchable state; `success=false`; `IsFirstBoundary` gained its first consumer. Round 2 did not fault it. |
| T089 | FR-066 | pass | The surface speaks and names what is missing; no approval options, no marker. Round 2 did not fault it. |
| T090 | FR-068 | pass | Both branches gated from one shared helper; the stop-artifact writer gated too. Re-cut to read evidence from the crossing's bound tree, fail-closed on unverifiable. Round 2 validated it. |
| T091 | FR-068 | needs-work | Deferred to beta3's hook-machinery cluster by recorded human decision (2026-08-03, `.squad\decisions.md`). SC-025's composition clause is scoped out by name, not left uncovered. |
| T093 | FR-018 | needs-work | Deferred to beta3's first row when T090's re-estimate fired the pre-agreed relief valve. |
| T092 | FR-066, FR-068, FR-018 | needs-work | Verification PASS (90/90). **Certification NOT ACHIEVED** across the full 3-round cap. FR-066's mint guard was attempted twice, faulted twice, and reverted. |
| T067 | SC-014, NFR-002 | pass | Published-bits consumer validation concluded 2026-08-10: Gallery install (no pinning), full governed lifecycle on a blind consumer project, six boundary verdicts faithfully captured, build + signoff with recorded residuals through the identity-bound disposition route. Retro/iteration-closeout not exercised — recorded coverage gap. Findings consolidated in the beta3 carry ledger; validate-not-promote boundary held (no stable promotion). |

## Gap Ledger

- FR-068 evidence half — tree-bound stage evidence, fail-closed unverifiable reasons, strict clarify matcher; validated by certification round 2 and byte-unchanged since: fixed-now.
- FR-066 arrival state — an unrecordable crossing is a distinguishable branchable state and the surface names what is missing: fixed-now.
- FR-066 mint guard — NOT delivered; two designs faulted at design level and both reverted; enters beta3 as a design spike. Approved deferral recorded in .squad\decisions.md as `f198-i011-named-limitation-tag-basis`: deferred.
- SC-025 composition clause — scoped to beta3's hook-machinery cluster by the authorized specify touch; approved deferral recorded in .squad\decisions.md as `f198-i011-t091-defer-sc025-beta3-vehicle`: deferred.
- FR-018 campaign-mode halt text (T093) — carried to beta3's first row when T090's re-estimate fired the pre-agreed relief valve; approved deferral BACK-REGISTERED in .squad\decisions.md as `f198-i011-t093-defer-relief-valve-back-registration` — the relief valve was pre-agreed as a plan-verdict instruction and fired mechanically, so this registers a decision that demonstrably occurred rather than one invented afterwards: deferred.

## Why this iteration does not close

Closure requires an `accepted` overall verdict, which requires every task `pass`. T092 cannot be `pass`
without asserting a certification that was attempted to the cap and not achieved.

**This iteration is therefore held at `retro` with a recorded closure trigger**, rather than closed
on a verdict word that outruns its evidence. That is the same failure mode this iteration exists to
close — a status claiming more than the artifacts support — and it was already committed once here: the
iteration was briefly marked closed on 2026-08-06 without `review.md` or `quality/hardening-gate.md`,
and the release gate rejected it as `over-claim`. The status was reversed rather than the evidence
backfilled beneath it.

**Closure trigger**: iteration 011 closes when beta3 delivers FR-066's mint guard from its design spike,
at which point FR-066 is whole and T092's certification claim can be re-made against a tree that carries
it. Until then the iteration is honestly open, and **the beta2 tag proceeds on the named-limitation
basis, which never claimed 011's certification.**

**Closure position addendum (2026-08-10)**: the trigger above predates the release and the
beta3/beta4 split ruling (2026-08-09), which moved the FR-066 mint-guard design spike into
beta4's tail — under that split the trigger would hold 011 open across two whole betas. With the
T067 record complete, the maintainer directed that the iteration-closeout crossing be presented
on this record: T092 stays `needs-work`/`deferred` exactly as written — no word is bent — the
mint-guard debt carries in
file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/beta3-carry-ledger.md, and the
human verdict at that crossing is the ruling of record that supersedes the trigger.

## Release Certification — the beta2 tag lineage (2026-08-09)

Three consecutive independent certification rounds (codex, file-primary, independent of the code
writer) ran against the tag candidate under maintainer-confirmed authorization references
(FR-058), each verified at source before adjudication:

| Run | Head | Verdict | Findings | Adjudication |
| --- | --- | --- | --- | --- |
| `run-f198-beta2-c0c3cda6-certify` | `c0c3cda6` | `findings` | 4 blocking / 2 major / 1 minor | f2/f3/f4/f6/f7 fixed instance-first in pre-tag slice #3; f1/f5 recorded residual (maintainer verdict) |
| `run-f198-beta2-4e7d002c-certify` | `4e7d002c` | `findings` | 2 blocking new / 1 major new / 2 expected residuals | the blocking pair fixed in pre-tag slice #4; the link-escape routed to the documented link class (maintainer verdict) |
| `run-f198-beta2-0fa26271-certify` | `0fa26271` | `findings` | 2 blocking new / 2 expected residuals / 1 routed re-report | the maintainer's TRAJECTORY RULING: proceed on this terminal, no fourth certify; both new blockings to beta3 design owners (release-claim limitations 12/13) — a third new layer in the capture-order and containment classes means the class needs a design owner, not another patch |

The terminals are immutable in the authority store under
file:///C:/Dev/specrew-beta2-hardening/.specrew/review/authority/campaigns/cmp-198-beta2-hardening-i011/
(runs `run-f198-beta2-c0c3cda6-certify`, `run-f198-beta2-4e7d002c-certify`,
`run-f198-beta2-0fa26271-certify`). The tag basis `67a5d7bc` differs from the certified head
`0fa26271` by 15 files, zero of them code (the documentation-only closure plus main-side records
carried by the merge target's own reviewed history) — the measured delta is recorded in the drift
log and on PR #3318. The expected residuals across all three rounds are the two long-known defects
this iteration's record already carries: the FR-066 mint guard (limitation 7's predicted
rediscovery, three consecutive re-reports) and DRIFT-198-I011-009 (the atomic writer).

## T067 — published-bits consumer validation (recorded 2026-08-10; the dogfood evidence)

**RECORDED — this is the slot reserved above, now filled.** `Specrew 0.40.0-beta2` was installed
from the PowerShell Gallery (no pinning, no module-path override) and the governed lifecycle was
exercised end to end on a blind consumer project at file:///C:/Temp/t067-linkcheck/ (frozen
evidence, mechanically archived — hash table in
file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/iterations/011/state.md).

- **Install, the real consumer path**: the default corporate `-Scope CurrentUser` location under
  OneDrive Known Folder Move was refused by the review engine's integrity check
  (cloud-placeholder reparse points); the run proceeded on a byte-identical local copy with
  hashes verified (carry-ledger T067-F1). The refusal is the shipped reparse posture working;
  the unusable default path is the finding.
- **Six boundary verdicts faithfully captured** across the lifecycle — hook-captured verbatim
  where the crossing existed, the design-analysis decision transcribed with disclosure (the
  documented limitation-10 path), and the signoff verdict through the identity-bound disposition
  route. No marker invention anywhere.
- **The product was built and signed off with recorded residuals**: the implement phase ran
  end-to-end clean on published bits (nine tasks, a boundary commit each, 212 tests at
  warnings-as-errors, live-external dogfood exit 0); the bounded verification run
  (`run-review-signoff-10`) re-raised zero of 35 prior findings, and its three new findings were
  accepted through `override-block --ack-reason` → `boundary-human-disposition` — the
  residual-acceptance vocabulary works end to end on published bits.
- **The tag basis held on published bits**: the FR-068 stage-evidence gate refused an
  evidence-less crossing live (no approval options, no marker, recovery named — "produce,
  COMMIT, stop again so the crossing rebinds"), and the sync ratchet cleanly refused a duplicate
  boundary sync. None of the run's findings regresses the authorization-integrity basis the tag
  gates on.
- **Coverage gap, recorded**: retro and iteration-closeout were NOT exercised on the consumer
  project — the run ended at review-signoff with the product signed off.
- **Findings**: eight findings (T067-F1..F8; headline F8 — the campaign has review quality but
  no review economics, with the settled pause/decision-surface design and instrument panel) and
  eight observations (obs-1..obs-8), all NEW — none among the release's twelve known issues —
  consolidated with the maintainer's beta3/beta4 split ruling in
  file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/beta3-carry-ledger.md.

Task verdict: **pass** — T067's deliverable was to exercise the published package on the real
consumer path and record the result faithfully; both halves are done. The findings are product
findings recorded against beta3/beta4, not failures of this task, and the validate-not-promote
boundary held: no stable promotion occurred or is implied by this record.

## Notes

- Every task verdict above is drawn from measured evidence recorded in
  file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/iterations/011/drift-log.md — RED→GREEN
  transitions, campaign terminals, and gate runs — not from recollection.
- The three certification terminals are immutable in the authority store under
  file:///C:/Dev/specrew-beta2-hardening/.specrew/review/authority/campaigns/cmp-198-beta2-hardening-i011/
- The `override-block` disposition on `run-f198-i011-fe88af18-certify` registers the maintainer's
  already-made named-limitation decision. It is not a certification and does not assert one.
- Process findings are in
  file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/iterations/011/retro.md
