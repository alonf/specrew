# Review: Iteration 011

**Schema**: v1
**Reviewed**: 2026-08-06
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

## Pending evidence — T067 (completes this review; closure waits on it)

**PENDING.** Consumer validation on the PUBLISHED bits: install `Specrew 0.40.0-beta2` from the
PowerShell Gallery (no pinning, no module-path override — the real consumer path), exercise the
governed lifecycle, and record the result here. This slot is deliberately explicit: the review of
the release is not complete until the published package — not the repository tree — has been
exercised by a consumer. The iteration-closeout crossing re-mints only after this slot is filled.

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
