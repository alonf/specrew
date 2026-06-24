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
**Post-Implementation Verification**: `recorded`
**Verified At**: 2026-06-24T09:31:18Z

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
| `security-surface` | `security` | `addressed` | `runtime-evidence` | `recorded` | Validate host input only through the registry; normalize case without accepting unknown values; contain every generated package path under its registered host folder; reject missing, duplicate, stale, or escaping paths before writing; keep the generator free of command evaluation; use synthetic package fixtures; preserve the accessor collision boundary. | `true` | Runtime verification passed actionable unknown-host rejection, exact folder/Kind checks, duplicate and escaping-link failures, and package containment. The accessor has no diff and no user hook/config file was modified. | `—` |
| `error-handling-expectations` | `robustness` | `addressed` | `runtime-evidence` | `recorded` | Unknown host input returns actionable live-catalog guidance; invalid manifests or missing contract files fail before FileList mutation/publish; check mode is non-mutating; generator output is written only after full validation; firewall and parity checks fail closed with file/reason details; current manifest remains intact on failure. | `true` | Runtime tests passed unknown-host, missing-file, folder/Kind, stale, duplicate, escaping-link, planted-literal, and stale-projection failure paths. The full validator exposed real state-schema failures and passed only after repair. | `—` |
| `retry-idempotency-requirements` | `resilience` | `addressed` | `runtime-evidence` | `recorded` | FileList generation is deterministic and byte-idempotent; generate then check must report no drift; deterministic validation/firewall operations never retry; CI reruns consume the same inputs; only later real-host canaries may use one explicitly recorded transient retry. | `true` | Repeated generation returned unchanged bytes, check mode passed, and LF/CRLF manifests remained stable on Windows and Linux. No retry was used to hide deterministic failure. | `—` |
| `test-integrity-targets` | `verification` | `addressed` | `runtime-evidence` | `recorded` | T002 tests registered/case/unknown input at all three boundaries; T003 uses the production generator for clean, missing, stale, duplicate, escaping, and cross-platform-order fixtures; T004 invokes the production scanner against planted and clean content; T005 packs exactly from FileList; T006 verifies the committed accessor diff is empty. | `true` | Tests exercised the production validator, generator, scanner, launch path, package-only publish harness, and conversation capture path. The same scanner detected planted runtime literals and passed clean registry-driven content. | `—` |
| `operational-resilience-concerns` | `operability` | `addressed` | `runtime-evidence` | `recorded` | CI exposes distinct registry, generation, firewall, and prepublish failures; Windows and Unix runners exercise path/argument handling; generated drift blocks publish; diagnostics identify the owning path and repair action; no scheduled live monitor or automatic CLI upgrade is introduced. | `true` | Regular, matrix, and prepublish workflows now expose distinct gates. The focused lane passed on Windows and Linux, the package-only harness validated 314 entries, and the uncached full validator passed after two visible repairs. | `—` |
| `host-adapter-seam-purity-and-compatibility` | `architecture` | `not-applicable` | `not-applicable` | `not-needed` | `—` | `false` | Iteration 001 does not implement the adapter seam. Its binding purity, planted-literal, and no-adapter equivalence criteria remain in T009 and require a new Iteration 002 hardening gate and authorization. | `—` |

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

## Readiness Check

**Result**: `ready-for-human-verdict`

| Check | Status | Evidence |
| --- | --- | --- |
| Tasks approval | pass | The persisted lifecycle state records `tasks` as the last authorized boundary. |
| Execution authorization | pending-human-verdict | `Test-SpecrewBoundaryAuthorization` correctly returns blocked for `tasks -> before-implement`; no implementation authorization has been inferred. |
| Scope and capacity | pass | Iteration 001 is T002–T006 at 14/20 SP; the full feature remains 14/15/16 and 45 SP. |
| Bidirectional traceability | pass | 34/34 FR/SC items covered; 17/17 tasks have valid authority and metadata. |
| Cross-artifact consistency | pass | The approved Option B, unchanged-parser boundary, five-entry allow-list shrink, and three-iteration split agree across spec, plan, tasks, and hardening controls. |
| Hardening concern contract | pass | Five canonical concern rows plus the adapter-seam concern are addressed with concrete controls and pending runtime evidence. |
| Drift and collision guards | pass | No unresolved drift event; no diff to `scripts/internal/bootstrap/ConversationCaptureAccessor.ps1`; no Iteration 002/003 artifacts were scaffolded. |
| Quality profile | pass-with-documented-override | The repository-level React detection is rejected for this slice; the effective profile is PowerShell/PSD1/YAML/JSON/GitHub Actions. |
| Team and ownership | pass | Baseline Spec Steward, Planner, Implementer, Reviewer, and Retro Facilitator roles are sufficient; no new specialist is required before T002. |
| Pre-change runtime baseline | pass | `host-registry.tests.ps1`, `host-coupling-firewall.tests.ps1`, `filelist-completeness.tests.ps1`, and `ConversationCapture.Tests.ps1` pass. The firewall baseline is 11 known exceptions; Iteration 001 must remove three and add none. |

## Notes

- Runtime evidence for every Iteration 001 concern is recorded. The future
  adapter-seam concern is not applicable to this slice and remains governed by
  T009 plus a separate Iteration 002 hardening gate.
- The auto-resolved React profile is rejected for this feature. The effective
  bounded profile is PowerShell 7, PSD1, YAML/JSON, PowerShell tests, and GitHub
  Actions.
- No hardening row grants implementation authority. The tasks-to-before-
  implement crossing still requires the separate human verdict.

## Post-Implementation Evidence Notes

- The registry, package generator, firewall, launch path, FileList completeness,
  publish harness, and conversation-capture suites passed.
- Windows and Linux execution exposed and closed two cross-platform issues:
  line-ending preservation and a Windows-only fake path in a test fixture.
- The final artifact tree passed the uncached full-repository validator in
  26.99 seconds after two earlier canonical state metadata failures were
  repaired visibly.
- The enum allow-list is 8 versus the pre-feature baseline of 11; no new
  exception exists.
- T007 and later remain unauthorized and absent from the implementation diff.
