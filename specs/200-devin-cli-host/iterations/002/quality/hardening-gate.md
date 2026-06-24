# Hardening Gate: Iteration 002

**Schema**: v1
**Gate ID**: `pre-implementation-hardening`
**Feature Ref**: `specs/200-devin-cli-host/spec.md`
**Iteration Ref**: `specs/200-devin-cli-host/iterations/002`
**Requested Review Class**: `strongest-available`
**Effective Review Class**: `strongest-available`
**Overall Verdict**: `ready`
**Approval Ref**: `—`
**Reviewed By**: Reviewer
**Reviewed At**: 2026-06-24T14:10:00Z
**Post-Implementation Verification**: `pending`
**Verified At**: `—`

<!--
  Concern Review schema (validator-enforced):
  - Status MUST be one of: `addressed` | `not-applicable` | `deferred-with-approval`.
  - When Status is `addressed` at planning time: EvidenceBasis = `planning-time-analysis`,
    RuntimeEvidenceStatus = `pending-post-implementation`, ExpectedControls = concrete controls.
  - Overall Verdict is `ready` when every concern is addressed/not-applicable/deferred-with-approval.
-->

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | `security` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Validate host input only through the registry (no hardcoded host list in `specrew start`); keep Devin auth host-owned; preserve user-owned hook/instruction/skill files; keep transcript/export data local and bounded; redact prompts, full transcripts, and credentials from logs and CI evidence; never modify `ConversationCaptureAccessor.ps1`. | `true` | Slice C-1 introduces the Devin package, an in-package handover normalizer, and a shared hook seam; each touches input, user files, or transcript data and must fail closed without leaking or overwriting. | `—` |
| `error-handling-expectations` | `robustness` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Invalid Devin manifest or missing contract handlers fail before any FileList mutation or deploy; hook merge refuses to overwrite an unreadable config; the handover normalizer surfaces a bounded degraded-handover reason rather than mutating the parser when a new shape would be required (FR-012); unknown permission modes do not silently pass. | `true` | The package must fail safely on malformed manifests/handlers and on unreadable user hook config, and the handover path must degrade honestly rather than collide with the unchanged parser. | `—` |
| `retry-idempotency-requirements` | `resilience` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | The in-package ATIF->JSONL normalizer is deterministic and byte-stable on repeated runs; hook merge is idempotent and re-runnable without duplicating entries; no deterministic failure is masked by a retry (live canary retries belong to iteration 003). | `true` | Determinism is the basis for the FR-011 replay proof and for safe `specrew update`/start re-runs; non-idempotent merge or non-deterministic normalization would break both. | `—` |
| `test-integrity-targets` | `verification` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | T008 replays the spike fixture through the **unchanged production parser** (not a mock); T009 asserts the accessor zero-diff; T012 plants a `devin` literal on the shared seam through the **production** firewall scanner and asserts it fails; T013 exercises the real hook-merge and redaction paths; T014 runs the existing five-host + parser goldens. No real-host behavior is mocked away (Feature-197 lesson); live evidence is explicitly iteration 003. | `true` | Tests must exercise production code paths and must not substitute mocks for the real parser, scanner, or deployer; live-host claims are deferred, not faked. | `—` |
| `operational-resilience-concerns` | `operability` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Devin ships `Status=experimental` with honest tested-build metadata; the Windows `sh.exe` hook-runner prerequisite is recorded as an unresolved constraint (its `pwsh` host-neutral attempt and live validation are iteration 003); diagnostics report tested build, event, hook path, selected handover mechanism, result, and a bounded reason code; CI exposes distinct registry/launch/firewall/FileList gates. | `true` | A discoverable-but-experimental package must not over-claim parity; the `sh.exe` gap and the experimental->supported gate must be visible and honest. | `—` |
| `host-adapter-seam-purity-and-compatibility` | `architecture` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | The FR-009 generic root-level direct-event-map ConfigShape is host-NEUTRAL in `deploy-refocus-hooks.ps1`; all Devin specifics live in `hosts/devin/host.psd1`. **Two carried-forward acceptance conditions (from the iteration 001 gate)**: (1) a planted host-specific routing literal on the seam MUST fail the production purity firewall (T012); (2) a package with no adapter MUST preserve exact pre-feature hook output (T014). No `devin` literal in shared/production code. | `true` | This is the concern iteration 001 marked `not-applicable` and explicitly deferred to "a new Iteration 002 hardening gate and authorization"; iteration 002 implements the seam, so it is now addressed with both planted-literal and no-adapter-equivalence controls. | `—` |

## Lens Activation (Planning Baseline)

| Lens Ref | Activation | Planned Evidence Path |
| --- | --- | --- |
| `security-baseline@v1.0.0` | required | `specs/200-devin-cli-host/iterations/002/quality/lenses/security-baseline.md` |
| `robustness-baseline@v1.0.0` | required | `specs/200-devin-cli-host/iterations/002/quality/lenses/robustness-baseline.md` |
| `test-integrity@v1.0.0` | required | `specs/200-devin-cli-host/iterations/002/quality/lenses/test-integrity.md` |

## Before-Implement Conditions

| Condition | Status | Evidence Required Before Implementation | Decision |
| --- | --- | --- | --- |
| `iteration-scope` | `closed` | file:///C:/Dev/200-devin-cli-host/specs/200-devin-cli-host/iterations/002/plan.md limits this authorization to T007–T015 and 19/20 SP (Slice C-1). | Live-host, promotion, and Slice D tasks remain unauthorized. |
| `accessor-collision` | `closed` | T008 normalizes in-package; T009 requires a committed accessor zero-diff check. | Any accessor edit blocks and returns to planning. |
| `seam-purity-proof` | `closed` | T012 acceptance plants a `devin` literal on the shared seam through the production scanner (must fail); T014 proves a no-adapter host preserves pre-feature behavior. | No `devin` literal in shared code; no firewall allow-list growth. |
| `no-mocked-real-host` | `closed` | FR-021 live evidence is deferred to iteration 003; iteration 002 contains zero mocked-away real-host claims. | Devin ships `experimental`; promotion requires the iteration 003 live gate. |

## Readiness Check

**Result**: `ready-for-human-verdict`

| Check | Status | Evidence |
| --- | --- | --- |
| Iteration 001 closed | pass | Iteration 001 is recorded `complete` in `.specrew/closed-iterations.yml`. |
| Execution authorization | pending-human-verdict | No implementation authorization for iteration 002 has been inferred; this gate awaits the human before-implement verdict. |
| Scope and capacity | pass | Iteration 002 is T007–T015 at 19/20 SP; full Slice C (~29 SP) is split at the live-host seam (C-2 -> iteration 003, Slice D -> iteration 004). |
| Bidirectional traceability | pass | Every iteration-002 task maps to >=1 FR/SC; every in-scope FR clause maps to >=1 task; deferred clauses are named. |
| Cross-artifact consistency | pass | The Option B split, unchanged-parser boundary, host-neutral seam, and experimental status agree across spec, plan, and hardening controls. |
| Hardening concern contract | pass | Five canonical concerns plus the now-addressed adapter-seam concern carry concrete controls and pending runtime evidence. |
| Drift and collision guards | pass | No diff to `ConversationCaptureAccessor.ps1`; no iteration 003/004 artifacts scaffolded; the only shared-core change (T012) is host-neutral and firewall-covered. |
| Quality profile | pass-with-documented-override | The effective profile is PowerShell 7 / PSD1 / YAML / JSON / GitHub Actions; repo-level JS detection is rejected for this slice. |
| Team and ownership | pass | Baseline roles plus Security Reviewer checkpoints (T012/T013) are sufficient; no new specialist required before T007. |

## Notes

- This gate re-addresses the adapter-seam concern that iteration 001 marked
  `not-applicable` and deferred here. Both carried-forward acceptance conditions
  (planted-literal fails; no-adapter host preserves behavior) are bound to T012
  and T014.
- No hardening row grants implementation authority. The tasks-to-before-implement
  crossing for iteration 002 still requires the separate human verdict.
- Live pinned-build evidence (FR-021), the FR-011 canary rerun, the `sh.exe`->
  `pwsh` attempt, and the experimental->supported promotion are iteration 003 and
  will be governed by their own hardening gate.
