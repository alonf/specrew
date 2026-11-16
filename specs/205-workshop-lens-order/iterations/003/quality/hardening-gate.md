# Hardening Gate: Iteration 003

**Schema**: v1
**Gate ID**: `pre-implementation-hardening`
**Feature Ref**: `specs/205-workshop-lens-order/spec.md`
**Iteration Ref**: `specs/205-workshop-lens-order/iterations/003`
**Requested Review Class**: `strongest-available`
**Effective Review Class**: `(pending hardening review)`
**Overall Verdict**: `ready`
**Approval Ref**: `—`
**Reviewed By**: Reviewer (pending)
**Reviewed At**: 2026-11-15T11:29:44Z

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
| `security-surface` | `security` | `addressed` | `runtime-evidence` | `recorded` | release notes fetched only from the vendors' official pages, each with URL and date; no fetched text executed; the agenda renderer writes only inside the project (`.specrew/handover/`) as today. Post-implementation evidence (`quality/quality-evidence.md`): T029 (`babf2cf8`) took every fact from official release data fetched on 2026-11-16, listed with URL and date in `code-implementation.md`'s Source Notes; facts the sources did not confirm were left out. No fetched text is executed: the facts are YAML strings read by a pure line function. T034 (`quality/t034-render-check.md`) rendered the agenda in a scratch project; the renderer wrote only `.specrew/handover/workshop-agenda-proposal.json`. The home hook files showed 0 differences around every run. Review round 1 (`run-20261116-095117164-6e1e0a46`) found nothing. | `true` | the trust boundary is unchanged: lens text, a YAML catalog and the agenda script's output; the new facts come from fetched web pages, so unconfirmed facts are left out (FR-030) | `—` |
| `error-handling-expectations` | `robustness` | `addressed` | `runtime-evidence` | `recorded` | a per-stack rule with no date is a test failure, not a silent skip; a date older than 90 days renders the stale marker; non-UTF-8 output is prevented by the script setting its output encoding, and a test round-trips the markers. Post-implementation evidence (`quality/quality-evidence.md`): `code-lens-freshness.tests.ps1` was red first at T027 (`3b85cc06`, 24 problems including 6 rules with no date) and passes from T030 (`79667a2a`); its self-tests prove a removed or non-date value fails, 90 days shows no marker and 91 days shows it. `workshop-agenda-grouping.tests.ps1` round-trips the markers through a Latin-1 console; with the UTF-8 line removed, the round trip fails on all three renders (T031, `cd5b6ba8`). T034 confirmed the real provider bound the pasted block. Both run as named CI steps, green on `a0c6a849` and `ec2638da`. | `true` | failure semantics: a missing or stale date is shown, never hidden; an agenda whose pasted block does not match the stored canonical text still refuses to bind, as today | `—` |
| `retry-idempotency-requirements` | `resilience` | `not-applicable` | `not-applicable` | `not-needed` | `—` | `false` | no retries, keys or shared state: the line function is pure and the agenda renderer keeps its atomic single write | `—` |
| `test-integrity-targets` | `verification` | `addressed` | `runtime-evidence` | `recorded` | FR-030: SC-011 test (date per stack rule, no version in rule text, 91-day fixture stale, 90-day not); FR-032: grouping on the real catalog and a changed-tag fixture, the kept `Selected lenses:` line, UTF-8 round trip; each red first; self-tests swap, remove and reword per item. Post-implementation evidence (`quality/quality-evidence.md`): T027 red first (1 self-test failing, 24 problems) and T028 red first (13 problems), both green from T030 and T031; 11 and 10 self-tests that remove, swap and reword per item; the real catalog, the no-both-spaces render and the changed-tag fixture all checked. Regression on `ebbe1b9b`: 34 of 34 workshop tests, parity and the length budget pass. All three workflows green on `a0c6a849`; review round 1 (`run-20261116-095117164-6e1e0a46`) found nothing. | `true` | positive and negative per FR, checked per item rather than by totals (iteration 002 retro action 1); results in `quality-evidence.md` | `—` |
| `operational-resilience-concerns` | `operability` | `not-applicable` | `not-applicable` | `not-needed` | `—` | `false` | no server, SLO or telemetry: lens text, a catalog, a local script and tests; no calendar-driven CI gate under the recommended design Option A | `—` |

## Lens Activation (Planning Baseline)

| Lens Ref | Activation | Planned Evidence Path |
| --- | --- | --- |
| `security-baseline@v1.0.0` | required | `specs/205-workshop-lens-order/iterations/003/quality/lenses/security-baseline.md` |
| `robustness-baseline@v1.0.0` | required | `specs/205-workshop-lens-order/iterations/003/quality/lenses/robustness-baseline.md` |
| `test-integrity@v1.0.0` | required | `specs/205-workshop-lens-order/iterations/003/quality/lenses/test-integrity.md` |

## Notes

- Replace every `<placeholder>` and every angle-bracketed instruction with iteration-specific content before crossing the `before-implement` boundary.
- After every row in the table is filled in with a canonical Status, flip the metadata `Overall Verdict` to `ready` (if every concern is `addressed` / `not-applicable` / `deferred-with-approval`) or keep `blocked`.
- Runtime evidence (lens execution, test counts, mechanical-findings results) is collected after implementation lands; the gate is a PLANNING-time artifact and that deferral is intentional.
