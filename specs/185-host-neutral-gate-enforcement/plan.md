# Implementation Plan: Host-Neutral Lifecycle Gate Enforcement (Feature 185)

**Feature Branch**: `185-host-neutral-gate-enforcement`
**Spec**: `spec.md` | **Continuation**: `CONTINUATION.md`
**Status**: Plan — design analysis complete; split-guard NOT triggered (bounded change throughout)

## Design Analysis (split-guard check)

The locked-scope split-guard fires only if real enforcement requires a **broad host-model rewrite**. It does not:

- **Claude mechanical gate** rides the EXISTING dormant `kind=='gate'` dispatcher seat. Activation = register a gate provider in `refocus-scopes.json` + a provider function (reads 065 `verdict_history`, returns `deny`/`ask`), and register `PreToolUse` in `hosts/claude/host.psd1` with a NARROW matcher (implementation-tool writes when a human-judgment verdict is owed). This is a bounded manifest + provider + deploy change, not a host-model rewrite.
  - *Performance note*: F-184 deliberately left `PreToolUse` unregistered (~920 ms spawn/call). The gate keeps it cheap by firing only on the narrow matcher and biasing to allow — not on every tool call. This is FR-007 + the requirements-nfr decision, a known constraint, not new scope.
- **Non-Claude enforcement** has no per-tool-call permission surface (Antigravity `PreInvocation`/`Stop`). Enforcement is the cleaned harness-free instruction + the host-neutral fallback renderer + the cooperative-and-halt degraded mode — a digest + skill + capability change, no host-model rewrite.

**Conclusion**: bounded changes throughout; the split-guard does NOT trigger; proceed.

## Approach (per component)

| Component | Change | FR | File(s) |
|---|---|---|---|
| Cleaning | rewrite rule-9 + specify step/traps harness-free | FR-002 | `extensions/specrew-speckit/refocus/general.md`, `refocus/specify.md` |
| Fallback renderer | host-neutral gate-stop renderer + marker emission for non-Claude | FR-003 | new `squad-templates/skills/` neutral renderer; `deploy-squad-runtime.ps1` host-scoping |
| Verdict capture | extend marker capture to non-Claude hosts | FR-006 | `scripts/internal/bootstrap/HandoverStore.ps1` |
| Capability declaration | per-host enforcement capability field | FR-004 | `hosts/*/host.psd1` |
| Gate provider | activate the dormant seat (Claude `PreToolUse` narrow matcher) | FR-007, FR-005 | `scripts/internal/specrew-hook-dispatcher.ps1`, `refocus-scopes.json`, `extensions/specrew-speckit/scripts/shared-governance.ps1` |
| Tests | leak (SC-002), parity (SC-003), gate-detection (SC-004), capture (SC-005) | — | `tests/` |

## Iteration breakdown

- **Iteration 1 — Cleaning + capture** (host-uniform, low-risk): FR-002 (harness-free digests), FR-003 (fallback renderer + marker), FR-006 (non-Claude capture). Tests: SC-002 (leak), SC-005 automated half (capture).
- **Iteration 2 — Capability + gate** (host-variable; the split-guard's home): FR-004 (capability declaration on all hosts), FR-007 (gate provider on the seat; Claude `PreToolUse` narrow matcher), FR-005 (enforce-or-halt routing). Tests: SC-003 (parity), SC-004 (gate-detection).
- **Iteration 3 — Dogfood + degraded mode**: SC-001 + SC-005 real-host half (cross-host greenfield dogfood); honest degraded-mode declarations for hookless hosts.

## Risks

- **`PreToolUse` performance** (FR-007): mitigated by the narrow matcher + bias-to-allow; measured against the ~150 ms preflight bar.
- **Non-Claude cannot mechanically block** (the honest limit): the degraded cooperative-and-halt is recorded in the capability declaration + the parity test, not hidden.
- **Over-blocking**: the gate biases to allow on governance-artifact / non-implementation writes.
- **Source-vs-mirror**: edit refocus SOURCE under `extensions/specrew-speckit/`; the `.specify/...` mirror auto-syncs — verify parity in tests.

## Next

Tasks (Iteration 1) -> before-implement -> implement.
