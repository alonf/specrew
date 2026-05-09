# Quickstart: Reviewer Escalation Symmetry and Lockout-Chain Cap

This quickstart describes the validation path for the planned reviewer-regression governance slice. It is a planning artifact only; it does **not** claim that implementation already exists.

## Prerequisites

- PowerShell 7+
- Approved `specs/008-reviewer-escalation-symmetry/spec.md`
- This feature's `plan.md`, `research.md`, `data-model.md`, and contract artifacts
- A scratch project or fixture with `.specrew/` and `.squad/` governance assets

## 1. Confirm the planned artifact contract

Review:

- `specs/008-reviewer-escalation-symmetry/plan.md`
- `specs/008-reviewer-escalation-symmetry/data-model.md`
- `specs/008-reviewer-escalation-symmetry/contracts/reviewer-regression-governance.md`

Verify that the plan is explicit about:

- reviewer regression ledger at `.specrew/reviewer-regression-log.md`
- active-iteration `reviewer-regression-state` mirror in `state.md`
- `.squad/config.json` reviewer-regression runtime projection
- repaired blocker semantics: soft-warning by default, hold only on FR-004/FR-010 paths
- conditional known-traps behavior

## 2. Validate the core reviewer-regression path

Once implementation exists, simulate:

1. a reviewer-approved slice
2. a human-found concrete defect in that slice
3. a new reviewer-regression event

Expected outcome:

- a ledger entry is appended
- the next reviewer class becomes the next stronger enabled class when one exists
- otherwise the system chooses an independent reviewer owner at the same class
- if neither exists, review moves to explicit human-direction hold

Planned validation command:

```powershell
pwsh -NoProfile -File .\tests\integration\reviewer-regression-event.ps1
```

## 3. Validate lockout-chain cap behavior

Simulate repeated implementer rotations after reviewer regressions on the same feature.

Expected outcome:

- the chain stops after the configured cap (default: two rotations beyond the original implementer)
- the next revision goes to a human by default
- an alternate owner is allowed only with an explicit `.squad/decisions.md` record
- cap activation appears in state, decisions, and the user-facing handoff summary

Planned validation command:

```powershell
pwsh -NoProfile -File .\tests\integration\lockout-chain-cap.ps1
```

## 4. Validate withdrawal and carry-forward handling

Run two separate scenarios:

### Withdrawal / misreport

- report a reviewer regression
- activate routing state from it
- withdraw the event before the pending routing completes

Expected outcome:

- only still-pending routing/hold state is reversed
- completed ownership changes remain in history
- unapproved trap proposals are removed

```powershell
pwsh -NoProfile -File .\tests\integration\reviewer-regression-withdrawal.ps1
```

### Closed-iteration carry-forward

- close an iteration
- report a reviewer regression after closure
- start the next active iteration

Expected outcome:

- the closed iteration remains untouched
- the event is logged immediately
- the next active iteration is seeded with the unresolved reviewer-regression state

```powershell
pwsh -NoProfile -File .\tests\integration\carry-forward-closed-iteration.ps1
```

## 5. Validate ledger and governance consistency

The implementation must keep the ledger, iteration state, runtime config, and decisions ledger aligned.

Planned validation commands:

```powershell
pwsh -NoProfile -File .\tests\integration\reviewer-regression-ledger.ps1
pwsh -NoProfile -File .\tests\integration\gap-governance.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File .\extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath .
```

Expected PASS conditions:

- reviewer-regression entries use the agreed schema
- cap-activation and withdrawal decision records are present when required
- reviewer regressions are treated as soft-warning events unless a defined hold path is active
- active reviewer-regression state in `state.md` matches `.squad/config.json`

## 6. Validate conditional known-traps behavior

Two cases must be covered:

1. **Corpus present**: offer candidate trap entries for approval and append only after approval.
2. **Corpus absent/disabled**: record `skipped-corpus-disabled` and continue without error.

This behavior is conditional and must **not** create the corpus automatically.

## Validation Outcome

The feature is ready for implementation when:

1. the reviewer-regression source of truth, state mirror, and runtime projection are all explicit
2. same-class independence and maximum-strength hold behavior are defined
3. lockout-cap visibility is mandatory in decisions/state/handoff
4. withdrawal and carry-forward rules preserve history while fixing active state
5. the validation commands above are the agreed regression lanes for the future implementation slice
