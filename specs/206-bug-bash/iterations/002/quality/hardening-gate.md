# Hardening Gate: Iteration 002

**Schema**: v1
**Gate ID**: `pre-implementation-hardening`
**Feature Ref**: `specs/206-bug-bash/spec.md`
**Iteration Ref**: `specs/206-bug-bash/iterations/002`
**Requested Review Class**: `strongest-available`
**Effective Review Class**: `(pending hardening review)`
**Overall Verdict**: `ready`
**Approval Ref**: `—`
**Reviewed By**: Reviewer (pending)
**Reviewed At**: 2026-11-15T11:01:32Z
**Post-Implementation Verification**: ✅ review accepted (review sign-off `4fad6f5f`, the maintainer's verdict of 2026-11-17 after four rounds); the four blocking concerns satisfied with runtime evidence in the Concern Review table; all three workflows green on `52c45561`
**Verified At**: `2026-11-17T23:47:35Z`

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
| `security-surface` | `security` | `addressed` | `runtime-evidence` | `recorded` | item 17: the publish case clears and restores `PSGALLERY_API_KEY` itself, and the release script refuses a publish nobody asked for; no test writes the real home (hook-file hashes before and after every run, SC-007); D5's start record is git-ignored and holds paths and hashes only; a resume path outside `-ProjectPath` is refused (item 23) Post-implementation evidence: `tests/unit/release-script-refuses-unasked-publish.tests.ps1` (RED 5/5 `ae620f15`, GREEN `619b1a85`; the publish suite runs in its own Windows job with no secret mapped); `tests/unit/resume-path-inside-project.tests.ps1` (GREEN 8/8 `824e9604`); `tests/unit/start-written-files-record.tests.ps1` (GREEN 10/10 `9930b869`); the home hook files hashed the same before and after every lane run, review round and sync (DRIFT-206-I002-021). | `true` | The trust boundaries are the release credential, the real home folder and the project root. Item 17 can publish to PSGallery; item 23 writes into a repository outside the one start was given. | `—` |
| `error-handling-expectations` | `robustness` | `addressed` | `runtime-evidence` | `recorded` | FR-017's redraw and FR-018's arrival listing warn and never block the seal or un-record a verdict, each with a failing-path test; D6: missing session files start fresh, an unreadable one still refuses (both tested); item 25: a failed probe cleanup is reported, not silent; items 30 and 34: each stop and the outer catch write their message hash Post-implementation evidence: `tests/unit/closeout-dashboard-redraw.tests.ps1` (GREEN 2/2 `7921e149`), `tests/unit/closeout-completed-and-open-rows.tests.ps1` (GREEN 6/6 `217ad08f`), `tests/unit/fresh-clone-first-start.tests.ps1` (GREEN 8/8 `151ba706`), `tests/unit/squad-probe-temp-folder.tests.ps1` (GREEN 4/4 `4bca00ae`), `tests/unit/nightly-tracking-issue.tests.ps1` (24/24 after items 30 `57e0cdbd` and 34 `899f76f8`). | `true` | Failures must be loud and must not undo what a human approved. Today item 25's cleanup and items 30 and 34's stops lose the detail. | `—` |
| `retry-idempotency-requirements` | `resilience` | `addressed` | `runtime-evidence` | `recorded` | FR-018's Completed date is written once, in the same mirror write that moves plan.md to `complete`, and a second capture leaves it unchanged (tested); D5's record is rewritten whole on each start Post-implementation evidence: `tests/unit/closeout-completed-and-open-rows.tests.ps1` (GREEN 6/6 `217ad08f`); `tests/unit/start-written-files-record.tests.ps1` (GREEN 10/10 `9930b869`). | `true` | The capture can run more than once for the same verdict (the duplicate path), so what it writes must be idempotent. | `—` |
| `test-integrity-targets` | `verification` | `addressed` | `runtime-evidence` | `recorded` | a failing test first for every fix; SC-008 to SC-011 each with a negative path; fixtures copy only what git does not ignore and are tested in the preflight layout (lesson 5; items 24 and 29); the census readers track YAML and shell structure, with one fixture per construct (items 31 and 32) Post-implementation evidence: 42 test commits and 43 fix commits, each fix behind a test that failed first with its count in the test commit; SC-008 to SC-011 in `deferred-task-verdict.tests.ps1`, `record-before-approval.tests.ps1`, `closeout-dashboard-redraw.tests.ps1` and `closeout-completed-and-open-rows.tests.ps1`; fixtures green in the preflight layout (T021 `5bfb685f`, T024); the census readers in `every-suite-is-named-by-a-lane.tests.ps1` (83/83 at T031). The review rounds' carried findings in these readers are bug list items 75 to 80 and 86 to 89. | `true` | Iteration 001's defects in this class were fixtures that read the developer's machine and readers that matched lines, not structure. | `—` |
| `operational-resilience-concerns` | `operability` | `not-applicable` | `not-applicable` | `not-needed` | `—` | `false` | No server, service level, telemetry pipeline or on-call surface ships. The nightly's tracking issue is CI automation, already covered by iteration 001's FR-009 work. | `—` |

## Lens Activation (Planning Baseline)

| Lens Ref | Activation | Planned Evidence Path |
| --- | --- | --- |
| `security-baseline@v1.0.0` | required | `specs/206-bug-bash/iterations/002/quality/lenses/security-baseline.md` |
| `robustness-baseline@v1.0.0` | required | `specs/206-bug-bash/iterations/002/quality/lenses/robustness-baseline.md` |
| `test-integrity@v1.0.0` | required | `specs/206-bug-bash/iterations/002/quality/lenses/test-integrity.md` |

## Notes

- Replace every `<placeholder>` and every angle-bracketed instruction with iteration-specific content before crossing the `before-implement` boundary.
- After every row in the table is filled in with a canonical Status, flip the metadata `Overall Verdict` to `ready` (if every concern is `addressed` / `not-applicable` / `deferred-with-approval`) or keep `blocked`.
- Runtime evidence (lens execution, test counts, mechanical-findings results) is collected after implementation lands; the gate is a PLANNING-time artifact and that deferral is intentional.
