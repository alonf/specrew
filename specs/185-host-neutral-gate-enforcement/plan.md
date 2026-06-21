# Implementation Plan: Host-Neutral Lifecycle Gate Enforcement (Feature 185)

**Feature Branch**: `185-host-neutral-gate-enforcement`
**Spec**: `spec.md` | **Continuation**: `CONTINUATION.md`
**Status**: Implemented through `c945fc9f`; governance sync in progress for the D-014 -> D-016 material-work enforcement pivot

## Design Analysis (split-guard check)

The original plan tested a Claude `PreToolUse` gate on the dormant `kind == 'gate'` seat. D-001 rejected that approach empirically: it was expensive per write, Claude-only, and did not reach the non-Claude host that reproduced #2884. The split-guard fired, the maintainer approved the pivot, and the design moved to Stop-hook conformance detection plus host-native turn-end blocking where available.

The current design remains bounded:

- **Conformance authority** rides the existing Stop dispatcher seat and existing bootstrap/conformance provider pattern.
- **Host variability** is declared in manifests through `StopBlockShape`; the core provider emits a host-neutral `<<<SPECREW-STOP-BLOCK>>>` sentinel and does not branch on host names.
- **Authorization state** remains Proposal-065 `verdict_history` plus the `SPECREW-VERDICT-BOUNDARY` marker captured by `HandoverStore.ps1`.
- **Material-work packet enforcement** uses the existing rolling-handover Stop snapshot as its deterministic signal. It does not revive the rejected length-only trigger.
- **Failure posture** is fail-open when transcript, state, or material evidence is unreadable; fail-closed only when bounded evidence proves a missing verdict marker or missing material-work packet.

**Conclusion**: bounded provider/manifest/dispatcher changes; no broad host-model rewrite; no parallel enforcement system.

## Approach (per component)

| Component | Change | FR | File(s) |
|---|---|---|---|
| Cleaning | rewrite rule-9 + specify step/traps harness-free | FR-002 | `extensions/specrew-speckit/refocus/general.md`, `refocus/specify.md` |
| Fallback renderer | host-neutral boundary packet + marker emission for non-Claude hosts | FR-003 | `squad-templates/skills/`, `deploy-squad-runtime.ps1` |
| Verdict capture | capture the exact pending boundary marker, including first crossing | FR-006 | `scripts/internal/bootstrap/HandoverStore.ps1`, `extensions/specrew-speckit/scripts/shared-governance.ps1` |
| Capability declaration | per-host Stop blocking shape and degraded mode | FR-004, FR-007 | `hosts/*/host.psd1` |
| Stop conformance provider | detect intake confusion, raw Spec Kit routing, unauthorized boundary advance, and deterministic material-work packet omissions | FR-007, FR-011, FR-015 | `scripts/internal/specrew-hook-dispatcher.ps1`, `refocus-scopes.json`, `extensions/specrew-speckit/scripts/specrew-conformance-provider.ps1` |
| Material-work signal | reuse rolling handover Stop snapshot to distinguish current material git/file changes from conversation-only refreshes | FR-015 | `scripts/internal/bootstrap/HandoverStore.ps1`, `extensions/specrew-speckit/scripts/specrew-conformance-provider.ps1` |
| Tests | leak, parity, gate detection, capture, stop-block binding, material packet enforcement | SC-002..SC-011 | `tests/` |

## Iteration Breakdown

- **Iteration 1 - Cleaning + capture**: FR-002, FR-003, FR-006. Tests: SC-002 and automated verdict-capture coverage.
- **Iteration 2 - Stop-hook authority**: FR-004, FR-007, FR-011. Tests: parity, gate detection, deployed binding, provider seam, fail-open cases.
- **Iteration 3 - Packet discipline + dogfood**: FR-015 material/boundary packet enforcement, cross-host real-host dogfood, degraded-mode evidence.

## Risks

- **Post-hoc ceiling**: Stop-hook enforcement protects boundary state and turn-end behavior; it is not a per-tool pre-block.
- **Transcript-gated ceiling**: no transcript or unreadable state means the provider fails open and records degraded evidence rather than guessing.
- **Cursor/Codex host variation**: host manifests declare blocking shape; Codex Stop is decision-only except for real stop-block short-circuiting.
- **Material-signal coupling**: material-work enforcement reads the rolling handover activity bullet produced by `HandoverStore.ps1`; if that textual shape drifts, enforcement fails open. This is a maintenance coupling, not a second material inference engine.
- **Source-vs-mirror**: provider changes must stay source/mirror parity-clean between `extensions/...` and `.specify/extensions/...`.

## Next

Record D-016, keep spec/plan synced with the Stop-hook design, then close remaining Proposal-145 gaps: live multi-host dispatch, multi-gate block coverage, material-signal fail-open coverage, and SC-001/006/007 real-host dogfood.
