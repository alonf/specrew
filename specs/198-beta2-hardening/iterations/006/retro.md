# Retrospective: Iteration 006

**Schema**: v1
**Date**: 2026-07-16
**Status**: accepted
**Human Approval**: approved for retro, 2026-07-16
**Review Basis**: file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/iterations/006/review.md
**Drift Basis**: file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/iterations/006/drift-log.md

Iteration 006 delivered and independently accepted the bounded review-authority foundation. It did
not complete Beta2: five-harness, three-operating-system production proof and the remaining adapter
work stay in Iteration 007.

## What Went Well

- The replacement architecture stayed deliberately small: pure policy, immutable uniquely named JSON
  facts, exact reviewed-state identity, external Git targets, and synchronous ports. The implementation
  avoided reintroducing a shared mutable result file, generic lock, database, or hidden retry path.
- Strict ingress behaved as designed. The v2 and v5 prose-wrapped candidates remained invalid even
  when they contained useful or apparently passing content; no embedded JSON was salvaged into
  authority. Their evidence remained visible without weakening the approval contract.
- Human-controlled reruns worked. Every paid provider attempt used a new run ID and a separately
  authorized allowance. Findings caused a stop, correction, full-suite verification, commit, and only
  then a separately granted new review.
- The independent review found defects that green tests alone did not establish away: replay precision,
  claim classification, unverified-termination cleanup, ownership metadata, and the duration ceiling.
  Each correction gained a focused regression before the final clean run.
- The file-primary Claude seam converted the repeated transport failure into a deterministic contract:
  the candidate file contains only raw JSON, stdout is non-authoritative, and the exact negative and
  positive regression pair protects both sides of the rule.
- The accepted snapshot passed 52 focused authority/ingress/orchestrator tests, 93 foundation tests,
  all 45 registered F-198 suites, the packaged-artifact checks, and complete bounded traceability.

## What Was Hard

1. The global boundary matcher reused Iteration 003 verdicts for Iteration 006 crossings. Fresh human
   approvals repaired this iteration's authority trail, but the critical engine defect remains open.
   Closeout cannot rely on that ledger, and no quiet point-fix is authorized.
2. Reviewer delivery failed twice at the prompt/transport seam. v2 and v5 together consumed
   1,114,327 milliseconds of paid provider runtime while correctly producing no approval authority.
   The strict controller was right; the adapter contract was incomplete.
3. Review cost was materially larger than the story-point row communicates. Five paid Claude runs
   consumed 2,981,404 milliseconds (49 minutes 41.404 seconds), in addition to a 74,015-millisecond
   no-spend preflight and repeated test suites. Token totals were not safely available and are not
   inferred.
4. The first review-signoff commit exposed governance-schema mismatches only after closure drafting:
   task status used `completed` instead of `done`, hardening evidence enums were noncanonical, and the
   review lacked the canonical task-verdict and gap-ledger sections. A second focused boundary commit
   corrected the metadata and the isolated validator then passed.
5. Isolated validation initially received a relative iteration path that resolved against the caller's
   working directory instead of the supplied project root. Re-running with an absolute isolated path
   produced the intended committed-tree validation. This was process friction, not a product finding.

## Lessons Learned

- Fail-closed ingress and a reliable delivery contract are complementary. Strict parsing protects
  authority, but every production adapter must also make the authoritative channel unmistakable.
- A failed or stale review can still carry useful advisory evidence. It must remain visibly bound to
  its reviewed digest and can guide corrections, but only a complete valid rerun can approve.
- Review capacity needs two ledgers: engineering effort in story points and paid-provider exposure in
  separately authorized slots plus observed wall time. One number cannot represent both.
- Stability-first review was worth the extra rounds. Bounded corrections with full regression runs
  produced a trustworthy foundation; automatically retrying or salvaging output would have reduced
  visible cost while weakening the result.
- Lifecycle validators should run before the first boundary commit, and committed-tree checks should
  use absolute target paths. Schema alignment is cheaper before signoff artifacts are committed.
- Post-review metadata changes must be stated separately from the reviewed implementation snapshot.
  v6 approved the exact implementation digest; later commits record review and retrospective evidence.

## Estimation Accuracy

The plan records equal estimated and actual story points for every task. That is the durable task
accounting, but the zero variance should not be mistaken for precise measurement of reviewer cost.

| Task | Estimated SP | Recorded Actual SP | Delta | Calibration note |
| --- | ---: | ---: | ---: | --- |
| T041 | 1.0 | 1.0 | 0.0 | Foundation mapping and cutover seam stayed bounded. |
| T042 | 1.5 | 1.5 | 0.0 | Contract consolidation stayed within the planned core. |
| T043 | 2.0 | 2.0 | 0.0 | Allowance and rerun policy remained pure and bounded. |
| T044 | 2.0 | 2.0 | 0.0 | State/currentness policy stayed within scope. |
| T045 | 2.5 | 2.5 | 0.0 | Immutable storage and concurrency were the largest planned core slice. |
| T046 | 1.5 | 1.5 | 0.0 | External target work remained bounded. |
| T047 | 1.5 | 1.5 | 0.0 | Strict ingress held; production delivery needed later T050 hardening. |
| T048 | 1.5 | 1.5 | 0.0 | Base orchestration completed; Claude delivery was pulled into T050. |
| T049 | 1.0 | 1.0 | 0.0 | Verification completed, including the 45-suite registry run. |
| T050 | 1.5 | 1.5 | 0.0 | Recorded SP hides five paid runs, four correction stages, and transport hardening. |
| **Total** | **16.0** | **16.0** | **0.0** | Within the 26-SP cap; operational review variance needs separate accounting. |

### Operational Review Calibration

| Signal | Count | Observed duration | Interpretation |
| --- | ---: | ---: | --- |
| No-spend controller preflight | 1 | 74.015 seconds | Failed before provider authority and released its reservation. |
| Paid provider invocations | 5 | 49 minutes 41.404 seconds | v2 through v6; every slot was separately authorized. |
| Complete valid provider results | 3 | 31 minutes 7.077 seconds | v3, v4, and clean v6. |
| Invalid-output provider results | 2 | 18 minutes 34.327 seconds | v2 and v5; useful evidence, no approval authority. |
| Final clean review | 1 | 8 minutes 27.609 seconds | v6, zero findings. |

Iteration 007 should therefore plan engineering SP and provider runtime separately. The planning
baseline should cite observed valid-run time and reserve bounded contingency, while each actual paid
slot still requires explicit human authorization. No blanket rerun allowance follows from this retro.

## Drift Summary

| Drift | Severity | Retro disposition |
| --- | --- | --- |
| DRIFT-198-I006-001 | critical | Open. Fresh scoped verdicts preserve Iteration 006 authority; the matcher fix requires a scoped amendment or engine backlog item. Closeout must not rely on the stale global ledger. |
| DRIFT-198-I006-002 | minor | Resolved with human-authorized owner-glob reconciliation; implementation scope did not change. |
| DRIFT-198-I006-003 | minor | Resolved for Iteration 006 by the authorized Claude file-primary pull-forward. Iteration 007 subtracts this exact slice and retains the remaining adapter matrix. |

There are no hidden gaps inside Iteration 006's bounded acceptance scope. The open matcher defect and
the deliberately incomplete production-adapter scope remain explicit carry-forwards.

## Reviewer-Instruction Triage

| Candidate | Disposition | Reason and next use |
| --- | --- | --- |
| File-primary raw JSON with stdout never authoritative | PROMOTE | Apply as a durable production-adapter prompt rule in Iteration 007, with per-adapter malformed-output fixtures. |
| Stop on findings or invalid output; require a new human-authorized run | PROMOTE | This preserved spend authority and prevented hidden retry throughout T050. |
| Full malformed-output fixture matrix and remaining prompt hardening | DEFER | Explicit Iteration 007 scope; the exact Claude prose-file/raw-file pair is already delivered and must not be duplicated. |
| Salvage or extract an embedded JSON object from prose | DROP | It would convert malformed evidence into authority and contradict the accepted strict-ingress contract. |
| Treat a clean result as permanently current after repository changes | DROP | Currentness belongs to the reviewed digest; later metadata changes must be reported separately. |

## Signals for Next Iteration

- Subtract the delivered Claude candidate-file contract and its exact two-case regression from the
  Iteration 007 estimate; do not implement them twice.
- Complete the full malformed-output matrix, remaining Claude hardening, the other four harness
  adapters, three production OS runtime adapters, five bounded live smokes, and cross-platform proof.
- Keep stability and integrity at P0. Timeout, prompt size, shared-object worktrees, progress, and
  optional safe usage metrics are P1 optimizations and cannot weaken containment or currentness.
- Make progress and accumulated findings available as deterministic retrospective inputs where the
  harness can do so cheaply; absence of live counts must not make a run non-authoritative.
- Preserve the distinction between partial/advisory usefulness and approval authority when the target
  has moved. The implementer must see the reviewed digest and currentness classification.
- Route the boundary-matcher defect through explicit engine scope. Do not fold it silently into
  Iteration 007 adapter work.

## Improvement Actions

| ID | Owner | Next action | Target | Status |
| --- | --- | --- | --- | --- |
| IA-006-01 | Iteration 007 Planner | Subtract the delivered Claude file-primary slice and retain the full remaining adapter/runtime/live-smoke matrix. | Iteration 007 plan | open |
| IA-006-02 | Adapter Implementer | Apply file-primary raw-JSON prompt contracts and strict deterministic malformed-output fixtures to every production harness. | Iteration 007 | open |
| IA-006-03 | Iteration 007 Planner | Add an explicit paid-slot and wall-time budget alongside SP, using the 31-minute valid-run evidence plus bounded contingency; keep authorization per slot. | Iteration 007 plan | open |
| IA-006-04 | Iteration 007 Planner/Engine Maintainer | Promote T033, the append-only ledger-correction door, as the explicit vehicle for DRIFT-198-I006-001; do not point-fix the matcher during closeout. | Iteration 007 plan | open |
| IA-006-05 | Implementer/Reviewer | Run scoped governance validation before the first boundary commit and repeat it against an absolute path in an isolated committed tree. | Every later F-198 boundary | open |
| IA-006-06 | Observability Implementer | Project cheap progress and accumulated findings into durable inputs that can feed retrospective problem descriptions without becoming result authority. | Iteration 007 | open |
| IA-006-07 | Iteration 007 Planner | Reconcile Iteration 003 explicitly: defer superseded T019 pieces with recorded rationale, carry T030–T032 and T034b forward, and map T033 to IA-006-04 before plan approval. | Iteration 007 plan | open |

## Process Notes

- This retrospective is based on committed task, review, drift, test, and immutable run evidence; it
  does not invent token totals or treat equal SP actuals as precise timing measurements.
- The accepted implementation snapshot is commit `2157017f77a225f9497c44ffb013e101bff6f2a7`
  at digest `bedc0172de77fda277f764cd07b90d5af291e2cc`. Subsequent commits contain review and
  retrospective governance records.
- Iteration closeout is not authorized by the review-signoff verdict. It requires a separate human
  decision after this retrospective is validated and committed.
- The maintainer approved this retrospective with an instruction-bearing verdict. That verdict
  authorizes iteration-closeout work only; it does not authorize Iteration 007 planning or execution.
