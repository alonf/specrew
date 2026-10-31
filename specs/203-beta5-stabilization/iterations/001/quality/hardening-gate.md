# Hardening Gate: Iteration 001

**Schema**: v1
**Gate ID**: `pre-implementation-hardening`
**Feature Ref**: `specs/203-beta5-stabilization/spec.md`
**Iteration Ref**: `specs/203-beta5-stabilization/iterations/001`
**Requested Review Class**: `strongest-available`
**Effective Review Class**: `(pending hardening review)`
**Overall Verdict**: `ready`
**Approval Ref**: `—`
**Reviewed By**: Planner (Claude), planning-time analysis; the reviewer order codex, copilot, claude covers the lenses at implement
**Reviewed At**: 2026-11-01T00:00:00Z

<!--
  Concern Review schema (validator-enforced):
  - Status MUST be one of: `addressed` | `not-applicable` | `deferred-with-approval`.
  - When Status is `addressed`: EvidenceBasis = `planning-time-analysis`, RuntimeEvidenceStatus =
    `pending-post-implementation`, ExpectedControls = concrete controls you will enforce.
  - Overall Verdict is computed: `ready` when every concern is addressed/not-applicable/deferred-
    with-approval; `blocked` otherwise.
-->

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | `security` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | One mint origin: only the typed turn from the host user-prompt event mints, through `Resolve-SpecrewTypedAct` (T003). The four conditions (turn identity, human-authored, phrase standing alone, no record yet) hold on every path including the hook. Recovery paths write only through `Write-SpecrewTypedAct`, which re-reads the cited turn and re-derives the act, so citing a real `confirm` turn cannot mint a verdict (T004). `--approve-round` is removed; no script or `!` approval path. The top-up's reason is the human's text or none. Records keep identities and hashes, not raw prompts. The live-engine pin keeps unreviewed engine code out of the live hooks, and a missing or corrupt pin refuses visibly, never falling back to the worktree source (T002). Paired fixtures: no-human-turn per mint path, and quoted, backticked and pasted non-approval phrases (T013). | `true` | The trust boundary runs between the human's typed turn and the authority stores (verdict ledger, budget-reset fact, stop answers, workshop receipts, review grant). Agent text, tool results, compaction summaries, pasted content, and an agent citing a human turn are on the untrusted side. Measure (b) is the top priority. | `—` |
| `error-handling-expectations` | `robustness` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Every approval-shaped turn that records nothing reports in the same turn with its own reason (form unreadable, writer failed, origin unconfirmed, no pending crossing, boundary mismatch, stage evidence absent), checking the store when it speaks (T006). A plan budget above `co_review_max_rounds` is refused at plan sync and at the snapshot, naming the ceiling and `.specrew/config.yml` (T007). A missing or corrupt pin refuses in plain words with one recovery action (T002). Refusals follow the refusal standard; diagnosis goes to the drift record. | `true` | Failures are disclosed in the same turn and never silently consume a human turn. A refusal never records an approval nobody gave: refusing beats recording (priority b over a). | `—` |
| `retry-idempotency-requirements` | `resilience` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | `Write-SpecrewTypedAct` writes only if the act is unrecorded; an identical existing fact is idempotent success, a conflicting one fails closed (CreateNew). The two Copilot firings of one prompt normalize to one identity, so the second firing is a no-op (T001, T003). A newer act supersedes an older unspent one through an immutable fact, never reuse (T004). A round is reserved before invocation; a release before invocation spends nothing; infrastructure failures spend no round and `infra_failure_cap` consecutive failures advance the host (T008). A second top-up with no round between grants no extra window. | `true` | The plan overrides the resolver's not-applicable to required (plan.md Quality plan; DRIFT-001). Duplicate firings and recovery paths are exactly where a second record would appear. | `—` |
| `test-integrity-targets` | `verification` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Named tests per task (tasks.md): T002 `live-engine-resolution`, T001 `typed-turn-identity`, T003 `typed-act-classifier`, T004 `typed-act-writer`, T005 `verdict-pairing`, T006 `not-recorded-report`, T007 `review-budget-snapshot`, T008 `review-budget-loop`, T011 `presented-check`, T012 `authority-audit`. Every task is RED-first through the shipped dispatcher with recorded real payloads from `tests/fixtures/hook-payloads/`, never the classifier alone. Budget economics invariants are instance-pinned fixtures (FR-043). Synthetic fixtures are marked `synthetic` and never count as recorded-host evidence. New suites are `*.Tests.ps1`, so the census selects them. | `true` | Positive plus negative per FR. Capture behavior is host-specific, so replay of real payloads is required; a smoke test alone is disallowed. | `—` |
| `operational-resilience-concerns` | `operability` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Deployment is explicit: the pin and the `.specify` mirror advance together only after an iteration's review sign-off, in one commit (T014); `deploy-pending.md` lists what is waiting. The pin script shows the pinned commit. Iteration 001's review runs on today's engine, so its costs are recorded as baseline evidence. | `false` | 203 ships no server; its operability surface is which engine code the live hooks run, and whether the human can see it. | `—` |

## Lens Activation (Planning Baseline)

| Lens Ref | Activation | Planned Evidence Path |
| --- | --- | --- |
| `security-baseline@v1.0.0` | required | `specs/203-beta5-stabilization/iterations/001/quality/lenses/security-baseline.md` |
| `robustness-baseline@v1.0.0` | required | `specs/203-beta5-stabilization/iterations/001/quality/lenses/robustness-baseline.md` |
| `test-integrity@v1.0.0` | required | `specs/203-beta5-stabilization/iterations/001/quality/lenses/test-integrity.md` |

## Notes

- This is a planning-time artifact. Runtime evidence (lens execution, test counts, mechanical findings) is
  collected after implementation and recorded in the planned evidence paths.
- T001's host facts (research.md R1 to R4) feed T003 and T006; if the two Copilot firings do not share an
  instant, the identity replacement is brought to the maintainer before T003 lands.
