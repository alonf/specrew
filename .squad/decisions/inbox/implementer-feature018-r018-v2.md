# Implementer Decision: Feature 018 bounded repair R-018-V2

**Date**: 2026-05-15  
**By**: Implementer  
**Type**: bounded-repair

## Decision

For Feature 018 review repair `R-018-V2`, the dashboard renderer must no longer use
`[Console]::IsOutputRedirected` as a live rich-mode eligibility gate. Instead, the
live `scripts\specrew-where.ps1` entrypoint temporarily primes UTF-8 when rich mode
has not already been disabled by explicit operator controls, then restores the
caller console state on exit.

## Why It Matters

- Fresh PowerShell review runs were receiving a misleading redirected-output fallback
  diagnosis even when the real issue was pre-render UTF-8 state.
- Moving the UTF-8 priming to the entry script keeps diagnostics truthful and leaves
  the shared renderer focused on directly verifiable eligibility checks.
- Restore-on-exit protects caller state so the repair stays bounded and safe for
  repeated local CLI use.

## Scope Guardrail

This decision is limited to Feature 018 review repair `R-018-V2a` / `R-018-V2b` /
`R-018-V2c`. It does not authorize review acceptance, retro opening, or any broader
terminal-capability redesign beyond the bounded repair.
