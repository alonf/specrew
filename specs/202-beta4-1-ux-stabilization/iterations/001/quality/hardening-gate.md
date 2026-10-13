# Hardening Gate: Iteration 001

**Schema**: v1
**Gate ID**: `pre-implementation-hardening`
**Feature Ref**: `specs/202-beta4-1-ux-stabilization/spec.md`
**Iteration Ref**: `specs/202-beta4-1-ux-stabilization/iterations/001`
**Requested Review Class**: `strongest-available`
**Effective Review Class**: `(pending hardening review)`
**Overall Verdict**: `ready`
**Approval Ref**: `—`
**Reviewed By**: Planner (Claude), planning-time analysis; the codex co-review covers the lenses at implement
**Reviewed At**: 2026-10-13T17:20:00Z

<!--
  Concern Review schema (validator-enforced):
  - Status MUST be one of: `addressed` | `not-applicable` | `deferred-with-approval`. The validator
    rejects placeholder values like `tbd`. Pick a real status per concern before implementation.
  - When Status is `addressed`: EvidenceBasis = `planning-time-analysis`, RuntimeEvidenceStatus =
    `pending-post-implementation`, ExpectedControls = concrete controls you will enforce.
  - When Status is `not-applicable`: EvidenceBasis = `not-applicable`, RuntimeEvidenceStatus =
    `not-needed`, ExpectedControls = `—`. Rationale must explain WHY this concern does not apply.
  - When Status is `deferred-with-approval`: same evidence fields as `addressed`, AND the Approval
    column must reference an approval record (decision or defer) with a recorded human approval.
  - Overall Verdict is computed: `ready` when every concern is addressed/not-applicable/deferred-
    with-approval; `blocked` otherwise. Update the metadata above when you change the table.
-->

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | `security` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Hook output never mints a receipt: paired never-mint and mint-once fixtures for every authority invariant (FR-005/006). Origin is decided by declared host data and named registry transforms only, never by free-text inference; the "selection channel" inference is removed (T004). Journals store hashes, event names and timestamps only, never prompt or draft text (T003 hashes-only assertion). The draft intake (T014) writes only under `.specrew/runtime/turn-end/<ownerHash>/` and is git-ignored. No new dependencies (workshop binding `new-dependencies: none`). T001 fixtures carry no environment values. | `true` | The trust boundary runs between host-supplied hook input (prompt text, replayed or injected text, dismissal results) and the authority stores (workshop receipts, the verdict ledger). An authority write must originate in a typed human turn. Sensitive flows: receipt minting, verdict capture and the out-of-band authorization writer. The ledger is append-only, and legacy entries are never rewritten (FR-026). | `—` |
| `error-handling-expectations` | `robustness` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Failure modes: journal lock contention, a held lock, an unwritable journal, a legacy `.unhealthy` marker, a missing pointer, a stale pointer for another branch, a draft with invalid UTF-8, and a gate refusal with several missing layers. Each failure has a single transition path into a degraded state: append fails, then bounded retry, then the outage buffer, then a health-journal entry, then same-turn disclosure with consumed status, then self-recovery on the next good append. There is no permanent latch. Each mode gets a positive and a negative test (T003, T004, T005 cases a to e, T010, T013, T014). Recovery wording follows `feature-202.rule.recovery-wording-no-implied-loss`. | `true` | Failures degrade and are disclosed in the same turn; they never block silently, and they never imply loss when nothing is lost. Incomplete state (buffered records) is flushed, then removed, and the flush is idempotent. A refusal names its cause and the producing step (FR-020). Technical diagnosis goes to the drift record, not to the human-facing message. | `—` |
| `retry-idempotency-requirements` | `resilience` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Journal append retry is bounded to at most 5 attempts within 250 ms (DA tuning value). Outage-buffer flush is idempotent: a re-flush of already-appended records leaves the journal unchanged (dedupe by record hash). The approving receipt for a recovery is recorded once. Presented-crossing memory is keyed per (session, crossing id), so a repeat Stop never repaints (T006). Case (e) runs two real `pwsh` processes appending at once on three operating systems (T005, DRIFT-003). | `true` | The plan overrides the resolver's not-applicable to required (plan.md Quality plan; maintainer-agreed at the plan verdict). B4F-108's trigger is two hook processes sharing one journal, and the fix depends on retry, buffering and idempotent recovery. | `—` |
| `test-integrity-targets` | `verification` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Each task maps its FRs to named tests (tasks.md): T002 `turn-record-contract`, T003 `hook-output-journal`, T004 `receipt-disclosure`, T005 `cross-host-workshop` plus `journal-fault-injection`, T006 `crossing-presentation`, T007 `presented-check`, T008 `orientation-order`, T009 `dials-parity`, T010 `feature-resolver`, T011 `new-feature-reset` (SC-009), T012 `resume-from-disk`, T013 `design-analysis-gate`, T014 `turn-draft-intake`. Every task is RED-first through the shipped launcher and dispatcher, never the shared path directly. T001 real-host fixtures (`tests/fixtures/hook-payloads/`) drive the contract tests. A twin-copy parity test fails on a one-byte drift. Evidence artifacts: T015 friction table, validator run against the known baseline, live-walk script. | `true` | Coverage is positive plus negative per FR; failure-mode FRs (FR-001..005, FR-008, FR-020, FR-021) need a fault-reproducing RED fixture, and a smoke test alone is disallowed. Fixtures are pinned to real recorded payloads, not hand-written shapes. The real recorded set includes a host-injected prompt on Claude (`<task-notification>`) and on Copilot (Stop-reason replay). Two classes no host produced have synthetic fixtures, marked `synthetic` in the file name and `origin: synthetic` in provenance (DRIFT-009): the Codex host-injected prompt, and the Copilot "User skipped question" string. Tests that use a synthetic fixture say so in the test name, and a synthetic fixture never counts as recorded-host evidence. | `—` |
| `operational-resilience-concerns` | `operability` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | A health journal records degraded and recovered transitions (hashes and timestamps only). `specrew status` and `where` show one health line (T004). The orientation line reports a degraded journal. A legacy `.unhealthy` marker is migrated to an ordinary degraded state. The CI workflow change for case (e) uses the existing OS matrix only, with no new jobs and no publication or deployment change, and the diff is reviewed like code (DRIFT-003). | `false` | 202 ships no server, SLO or on-call surface. Its operability surface is local: the hook journal's health and its visibility to the human. The resiliency dimension is required (plan Quality plan), so this concern is addressed rather than marked not-applicable. | `—` |

## Lens Activation (Planning Baseline)

| Lens Ref | Activation | Planned Evidence Path |
| --- | --- | --- |
| `security-baseline@v1.0.0` | required | `specs/202-beta4-1-ux-stabilization/iterations/001/quality/lenses/security-baseline.md` |
| `robustness-baseline@v1.0.0` | required | `specs/202-beta4-1-ux-stabilization/iterations/001/quality/lenses/robustness-baseline.md` |
| `test-integrity@v1.0.0` | required | `specs/202-beta4-1-ux-stabilization/iterations/001/quality/lenses/test-integrity.md` |

## Notes

- This is a planning-time artifact. Runtime evidence (lens execution, test counts, mechanical findings) is collected after implementation and recorded in the planned evidence paths.
- T001's measurements (research.md, Open facts) feed T002, T008 and T014. Hook stdin arrives as UTF-8 bytes on every measured host while the hook process's console input encoding is `ibm437`, so explicit byte-level UTF-8 decoding is a security and robustness control, not a preference.
