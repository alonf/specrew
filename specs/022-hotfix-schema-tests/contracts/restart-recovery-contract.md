# Contract: Restart Recovery

**Contract Version**: 1.0.0  
**Feature**: 022-hotfix-schema-tests  
**Effective Boundary**: Plan-complete / pre-implementation

## Overview

This contract defines the operator-facing stale-state recovery behavior at `specrew start`.

## Entry Paths

### Interactive stale-state entry

When stale state is detected, `specrew start` must:

1. Explain that stale state was detected.
2. Show the detected reasons.
3. Present actionable A/B/C recovery choices.
4. Accept the operator's selection instead of exiting immediately.

### Explicit recovery entry

When the operator runs `specrew start --recover`, the command must:

1. Bypass the blocking stale-state gate.
2. Enter recovery mode directly.
3. Explain why recovery mode exists and what the next step is.
4. Leave approval/autopilot-style behavior unchanged.

## Behavior Rules

1. `--recover` is a recovery-intent control, not an approval-mode control.
2. Recovery mode must remain available after a recently shipped feature leaves stale session state behind.
3. Invalid or empty interactive input must remain user-visible and recoverable.
4. Restart recovery must not widen Feature 022 into a broader workflow redesign.

## Validation Contract

- `tests/integration/start-recovery-flow.tests.ps1` is the planned regression script for FR-015.
- The script must prove both the interactive stale-state path and the explicit `--recover` path.
- The script must demonstrate that a shipped feature no longer blocks restart behind an unusable stale-state failure.
