# Hardening Gate: Iteration 001

**Schema**: v1
**Gate ID**: `pre-implementation-hardening`
**Feature Ref**: `specs/184-full-antigravity-refocus/spec.md`
**Iteration Ref**: `specs/184-full-antigravity-refocus/iterations/001`
**Requested Review Class**: `strongest-available`
**Effective Review Class**: `strongest-available`
**Overall Verdict**: `ready`
**Approval Ref**: `—`
**Reviewed By**: Reviewer
**Reviewed At**: 2026-06-17T00:00:00Z

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | `security` | `addressed` | `runtime-evidence` | `recorded` | Treat Antigravity hook payloads, transcript paths, workspace paths, and `.agents/hooks.json` as untrusted input. Sanitize `conversationId` before filesystem use; never write a global `unknown` state file when a real id exists; never log transcript content; preserve user-owned hook entries; add no runtime dependency. | `true` | T002/T005/T007/T008 evidence proves real `conversationId` state keys, no global `unknown` state when a real id exists, user hook preservation, manifest-driven runtime binding, and machine-local real-host `agy` execution without upgrading evidence labels beyond what was observed. | `f184-implementation-through-completion-2026-06-17` |
| `error-handling-expectations` | `error-handling` | `addressed` | `runtime-evidence` | `recorded` | Hook, provider, state, and config failures fail open for the host session with bounded diagnostics and recovery guidance. No prompt/transcript leakage; no session block; no parity claim when evidence is missing. Negative-path tests must cover provider failure, state failure, hook/config failure, and B3 no-injection paths. | `true` | T003/T007/T008 evidence proves fail-open dispatcher behavior, bounded diagnostics, no transcript echoing, no ordinary-turn B3 injection, and honest machine-local support labels. | `f184-implementation-through-completion-2026-06-17` |
| `retry-idempotency-requirements` | `retry-idempotency` | `addressed` | `runtime-evidence` | `recorded` | Antigravity hook install/remove is idempotent and owns only Specrew entries. Re-running `PreInvocation` on ordinary turns must not duplicate B3 injection; dedupe/breaker state must be per session; competing marker checks must distinguish own marker from real concurrent sessions. | `true` | T001/T003/T004/T005/T008 evidence proves exactly-once B3 on a real boundary crossing, unchanged resume without reinjection, per-session state/dedupe, own-marker `same-session` classification, competing-marker preservation, and idempotent hook install/remove. | `f184-implementation-through-completion-2026-06-17` |
| `test-integrity-targets` | `test-integrity` | `addressed` | `runtime-evidence` | `recorded` | Tests must prove behavior, not file presence: real `conversationId` state keys, no global `unknown`, B3 exactly once on real boundary crossings, no ordinary-turn B3, no own-marker advisory, competing-marker advisory, config preservation, F-183 regression guards, mirror parity, and real-host `agy` evidence. | `true` | T001-T008 evidence covers the planned behavior checks with automated Pester, mirror/FileList readiness, host-coupling firewall, Proposal 145 review, and real-host `agy` proof; release validation remains a separate beta-before-stable obligation. | `f184-implementation-through-completion-2026-06-17` |
| `operational-resilience-concerns` | `operational` | `addressed` | `runtime-evidence` | `recorded` | User-facing docs and fallback guidance must include `agy`, hook install/remove/status, `/permissions`, `enableTerminalSandbox`, and `specrew start --host antigravity`. Full/verified/stable labels remain blocked until real-host evidence and beta-before-stable release validation pass. Temporary 26 SP capacity override must be restored at retro/closeout. | `true` | T006/T008 and retro evidence record Antigravity docs/recovery guidance, evidence-gated support wording, machine-local real-host proof, release carry-forwards, and restoration of the project-global 20 SP cap. | `f184-implementation-through-completion-2026-06-17` |

## Before-Implement Conditions

| Condition | Status | Evidence | Decision |
| --- | --- | --- | --- |
| `condition-a-discovery-first` | `closed` | T001 is first in sequence and blocks T002-T005 unless `fresh-boundary-cursor`, `exactly-once-b3`, and `bounded-host-model` all PASS. | Implementation may start with T001 only; failed discovery triggers a human split/defer stop. |
| `condition-b-human-authorization` | `closed` | User directive on 2026-06-17: "You are clear to implement all... Next stop gate ... AFTER the complete implementation." | Tasks, before-implement, and implementation may proceed without another human stop; the next human gate is post-implementation. |
| `condition-c-release-honesty` | `closed` | Spec FR-009/FR-010 and plan T006/T008 require evidence-gated labels and no full Antigravity claim before real-host proof. | Documentation parity depth may be implemented before proof, but support status remains pending until T008 evidence. |

## Notes

- Planning-time gate (before-implement) started as `planning-time-analysis` /
  `pending-post-implementation`. At iteration-closeout the runtime evidence is
  recorded task-by-task in T001-T008 and re-reviewed under Proposal 145 before
  the human stop.
- This gate does not weaken the split guard. T001 FAIL evidence still stops the
  iteration for a human split/defer decision.
- The temporary 26 SP capacity override is part of this gate's operational
  controls and must be restored to the baseline 20 SP cap at retro/closeout.
