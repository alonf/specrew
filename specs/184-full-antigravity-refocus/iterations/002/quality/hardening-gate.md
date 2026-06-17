# Hardening Gate: Iteration 002

**Schema**: v1
**Gate ID**: `pre-implementation-hardening`
**Feature Ref**: `specs/184-full-antigravity-refocus/spec.md`
**Iteration Ref**: `specs/184-full-antigravity-refocus/iterations/002`
**Requested Review Class**: `strongest-available`
**Effective Review Class**: `strongest-available`
**Overall Verdict**: `ready`
**Approval Ref**: `—`
**Reviewed By**: Reviewer
**Reviewed At**: 2026-06-17T16:20:00Z

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | `security` | `addressed` | `planning-time-analysis` | `verified-post-implementation` | Treat existing host instruction-file content (`AGENTS.md`, `CLAUDE.md`, `.github/copilot-instructions.md`) as untrusted. The managed-section merge replaces ONLY a clearly delimited Specrew-owned section and preserves all user-owned content byte-for-byte; it must not inject unescaped content or corrupt/truncate the file on a partial write. Shared instruction-delivery core reads `InstructionsFile` from host manifests with no `agy`/Antigravity/host-name literals. Add no runtime dependency. | `true` | T002 delivers the delimited-section merge helper that preserves user content; T003 wires manifest-driven delivery with no host branch; T005's host-coupling firewall negative test and byte-for-byte preservation tests prove it. | `—` |
| `error-handling-expectations` | `error-handling` | `addressed` | `planning-time-analysis` | `verified-post-implementation` | init/update/start instruction delivery fails gracefully: a merge failure must never truncate or corrupt the user's instruction file; a host manifest without an `InstructionsFile` is skipped with a bounded diagnostic; `specrew start` heal of a missing/stale managed section must not clobber user content. Bounded diagnostics only; no file-content leakage. | `true` | T003 wires init/update/start-heal with graceful skip and non-clobbering heal; T005 covers the merge-failure and missing-manifest-field paths. | `—` |
| `retry-idempotency-requirements` | `retry-idempotency` | `addressed` | `planning-time-analysis` | `verified-post-implementation` | init, update, and start-heal are idempotent: re-running replaces only the managed Specrew-owned section, never duplicates it, and leaves user-owned content unchanged. The delimited-section merge is the idempotence boundary; `specrew update` refresh must converge to the packaged source. | `true` | T002 makes the merge primitive idempotent; T003 consumes it from all three entry points; T005 idempotence tests re-run init/update/start-heal and assert a single managed section with unchanged user content. | `—` |
| `test-integrity-targets` | `test-integrity` | `addressed` | `planning-time-analysis` | `verified-post-implementation` | Tests prove behavior, not file presence: byte-for-byte user-content preservation across init/update/start-heal; the EXACT FR-013 guard text present in BOTH the persistent instruction file AND the bootstrap; host-coupling firewall negative test rejecting `agy`/Antigravity literals and host-name branching in shared core; bootstrap immediate-action ordering pinned; `Specrew.psd1` FileList paths exist. Real-host Opus 4.6 and Gemini Flash dogfood evidence is recorded and labeled machine-local. | `true` | T005 delivers the automated behavior coverage (merge, FileList, ordering, firewall); T006 delivers machine-local real-host dual-model evidence; no file-presence-only assertions. | `—` |
| `operational-resilience-concerns` | `operational` | `addressed` | `planning-time-analysis` | `verified-post-implementation` | Host-neutral manifest-driven delivery keeps the host-coupling firewall meaningful (no host-name branches in shared core). Real-host validation carries an honest weak-model caveat (Gemini Flash) rather than a full-parity claim; status/release text stays evidence-gated (SC-018). Release carry-forwards remain OPEN and are NOT closed by iteration 002: beta-before-stable, `MigrateLegacyTopLevelEventMap` legacy-upgrade validation, and reproducible-or-machine-local `agy` evidence. Capacity is 20/20 with zero slack; the split guard is the safety valve. | `true` | T003 keeps delivery manifest-driven; T004 front-loads the bootstrap action and mirrors the guard; T006 records real-host evidence with the Flash caveat; spec SC-018 and the plan's Deferred/Out-Of-Scope keep release labels evidence-gated and carry-forwards open. | `—` |

## Before-Implement Conditions

| Condition | Status | Evidence | Decision |
| --- | --- | --- | --- |
| `condition-a-human-authorization` | `met` | The `tasks -> before-implement` boundary stop was presented and the human authorized implementation. `verdict_history` records `plan -> tasks` (`approved for tasks`) then `tasks -> before-implement` (`approved for before-implement`), under which implementation proceeded. | Implementation MUST NOT start until the human authorizes `tasks -> before-implement`. The plan-boundary approval does not authorize implementation. |
| `condition-b-split-guard-live` | `met` | Plan and tasks Sequencing keep the falsifiable split guard live: per-host handlers instead of a shared manifest projection (T001/T003), or bootstrap/runtime rewrites beyond front-load plus guard wording (T004). | T001 (discovery) runs first; any split-guard trigger STOPS for a human split/defer decision rather than overrunning the 20/20 cap. |
| `condition-c-capacity-discipline` | `met` | Capacity is 20/20 with zero slack; defer strategy is manual (no silent cap raise). | If any task expands beyond its estimate, STOP for a human split/defer decision; do not raise the cap. |
| `condition-d-release-honesty` | `met` | Spec FR-009/SC-018 plus the plan's Deferred/Out-Of-Scope require evidence-gated labels and no full-parity/beta/stable/release claim in iteration 002. | Docs/behavior may ship, but support status stays caveated and release carry-forwards remain open until their own gates pass. T006 preserves the weak-model caveat if Gemini Flash cannot be driven. |

## Post-Implementation Closure (2026-06-18)

Runtime evidence is complete; all five concerns are CLOSED at iteration-closeout
(`Runtime Evidence Status` is now `verified-post-implementation`):

- **security-surface:** byte-for-byte user-content preservation verified (instruction-file-merge 8/8); host-coupling firewall green (no host-name literals in shared core); atomic write (no partial-write corruption).
- **error-handling-expectations:** instruction-deploy 6/6 (graceful skip on missing `InstructionsFile`; non-clobbering start-heal); fail-open delivery in `specrew start`.
- **retry-idempotency-requirements:** idempotence verified (re-run init/update/start-heal -> single managed section, user content unchanged).
- **test-integrity-targets:** behavior coverage (merge, FileList, bootstrap ordering, firewall negative test fail-then-pass), not file-presence; T006 machine-local real-host dual-model evidence recorded.
- **operational-resilience-concerns:** delivery stays manifest-driven (firewall meaningful); the Flash weak-model caveat is preserved (no full-parity claim); SC-018 release carry-forwards remain OPEN.

Before-Implement Conditions are MET: (a) the human authorized `tasks -> before-implement`; (b) no split-guard trigger fired; (c) 20/20 delivered with zero overrun; (d) labels stayed evidence-gated with the Flash caveat and SC-018 carry-forwards open. The condition rows' evidence columns are the before-implement snapshot; this section is the post-implementation closure truth.

## Notes

- Planning-time gate (before-implement): concerns are `addressed` at the
  plan/tasks control level with `Evidence Basis: planning-time-analysis` and
  `Runtime Evidence Status: verified-post-implementation`. Runtime evidence is
  recorded task-by-task during implement/review and re-reviewed before the next
  human stop.
- `Overall Verdict: ready` means ready to present for the implementation
  go-ahead; it does NOT authorize implementation. The human
  `tasks -> before-implement` verdict (condition-a) is the authorization, and it
  is still pending.
- This gate does not weaken the split guard (condition-b): a T001/T003 FAIL or a
  task overrun still STOPS the iteration for a human split/defer decision.
- Capacity is the restored project-global 20 SP cap with no temporary override;
  there is zero slack, so the split guard is the only release valve
  (condition-c).
