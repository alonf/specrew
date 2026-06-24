# Hardening Gate: Iteration 001

**Schema**: v1
**Gate ID**: `pre-implementation-hardening`
**Feature Ref**: `specs/200-devin-cli-host/spec.md`
**Iteration Ref**: `specs/200-devin-cli-host/iterations/001`
**Requested Review Class**: `strongest-available`
**Effective Review Class**: `strongest-available`
**Overall Verdict**: `ready`
**Approval Ref**: `—`
**Reviewed By**: Reviewer
**Reviewed At**: 2026-06-24T08:12:01Z

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
| `security-surface` | `security` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Validate host input only through the registry; normalize case without accepting unknown values; contain every generated package path under its registered host folder; reject missing, duplicate, stale, or escaping paths before writing; keep the generator free of command evaluation; use synthetic package fixtures; preserve the accessor collision boundary. | `true` | Iteration 001 accepts command-line host input and imports PSD1 manifests to generate a publish manifest. A malicious/invalid kind or path must not become code execution, path traversal, or an incomplete package. No user hook/config file is modified in this slice. | `—` |
| `error-handling-expectations` | `robustness` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Unknown host input returns actionable live-catalog guidance; invalid manifests or missing contract files fail before FileList mutation/publish; check mode is non-mutating; generator output is written only after full validation; firewall and parity checks fail closed with file/reason details; current manifest remains intact on failure. | `true` | The main failure risks are parameter-binding ambiguity, partial generated output, and a false-green purity test. Each has one explicit failure path and positive plus negative test coverage. | `—` |
| `retry-idempotency-requirements` | `resilience` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | FileList generation is deterministic and byte-idempotent; generate then check must report no drift; deterministic validation/firewall operations never retry; CI reruns consume the same inputs; only later real-host canaries may use one explicitly recorded transient retry. | `true` | The slice mutates a generated manifest segment and runs publish gates repeatedly. Idempotency is required even though there is no network retry loop or transactional database. | `—` |
| `test-integrity-targets` | `verification` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | T002 tests registered/case/unknown input at all three boundaries; T003 uses the production generator for clean, missing, stale, duplicate, escaping, and cross-platform-order fixtures; T004 invokes the production scanner against planted and clean content; T005 packs exactly from FileList; T006 verifies the committed accessor diff is empty. | `true` | The clean-extensibility claim is architectural and can pass falsely if tests inspect only authored files. Tests must exercise the same validator, generator, scanner, and packaging paths used by production/CI. | `—` |
| `operational-resilience-concerns` | `operability` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | CI exposes distinct registry, generation, firewall, and prepublish failures; Windows and Unix runners exercise path/argument handling; generated drift blocks publish; diagnostics identify the owning path and repair action; no scheduled live monitor or automatic CLI upgrade is introduced. | `true` | FileList omission can produce a package that works in the dev tree and fails after installation. Explicit CI/prepublish gates are the operational containment for this iteration. | `—` |
| `host-adapter-seam-purity-and-compatibility` | `architecture` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | T009 defines the sole generic shared hook integration seam; shared code contains no Devin/Windsurf literal; the firewall scans the seam and detects a planted host-specific literal; a no-adapter fixture proves exact pre-feature argv/output behavior; Iteration 002 must repeat these conditions in its own hardening gate before implementation. | `true` | The seam is not implemented in Iteration 001, but its acceptance contract must be fixed now so later Devin work cannot weaken folder-only purity or regress hosts that do not opt into an adapter. This row is planning authority, not Iteration 002 implementation authorization. | `—` |

## Lens Activation (Planning Baseline)

| Lens Ref | Activation | Planned Evidence Path |
| --- | --- | --- |
| `security-baseline@v1.0.0` | required | `specs/200-devin-cli-host/iterations/001/quality/lenses/security-baseline.md` |
| `robustness-baseline@v1.0.0` | required | `specs/200-devin-cli-host/iterations/001/quality/lenses/robustness-baseline.md` |
| `test-integrity@v1.0.0` | required | `specs/200-devin-cli-host/iterations/001/quality/lenses/test-integrity.md` |

## Before-Implement Conditions

| Condition | Status | Evidence Required Before Implementation | Decision |
| --- | --- | --- | --- |
| `iteration-scope` | `closed` | file:///C:/Dev/200-devin-cli-host/specs/200-devin-cli-host/tasks.md limits the first implementation authorization to T002–T006 and 14/20 SP. | Later iteration tasks remain unauthorized. |
| `accessor-collision` | `closed` | T001 evidence proves outcome 2 without editing the accessor; T006 requires a committed no-diff check. | Any accessor edit blocks and returns to planning. |
| `purity-proof` | `closed` | T004 acceptance uses the production scanner for clean and planted content and removes three exceptions. | No new exception is permitted. |
| `future-adapter-contract` | `closed` | T009 carries the explicit planted-literal and no-adapter regression criteria requested at plan approval. | Must be repeated in Iteration 002's gate. |

## Notes

- Runtime evidence, test counts, and mechanical findings remain
  `pending-post-implementation`; `ready` means the planning controls are
  sufficient for a human implementation verdict.
- The auto-resolved React profile is rejected for this feature. The effective
  bounded profile is PowerShell 7, PSD1, YAML/JSON, PowerShell tests, and GitHub
  Actions.
- No hardening row grants implementation authority. The tasks-to-before-
  implement crossing still requires the separate human verdict.
