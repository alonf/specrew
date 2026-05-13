# Reviewer Regression Ledger

**Schema**: v1.0.0  
**Created**: 2026-05-09  
**Source of Truth**: This append-only ledger is the authoritative record of all reviewer-regression events reported across all features and iterations in this repository.

## Purpose

This ledger records every concrete defect a human reports in a slice that a Squad reviewer previously approved or marked ready. Each event triggers reviewer-side governance handling per spec 008 FR-001 through FR-015.

## Governance Rules

1. **Append-Only**: Records are never deleted or rewritten. Withdrawals append new entries with the withdrawal reference.
2. **Deduplication**: Duplicate reports for the same approved slice and defect attach to the existing active chain rather than creating separate entries.
3. **Soft-Warning Classification**: All reviewer-regression events are recorded as soft-warning governance signals (per spec 008 FR-007). They do not automatically invalidate a feature but trigger escalation or hold paths based on available routing options.
4. **Carry-Forward**: Reports landing after an iteration is closed append immediately and carry their escalation state to the next active iteration without reopening closed history.

## Record Schema

Each event entry must include:

- **Event ID**: Stable identifier (e.g., `RRE-001`)
- **Feature**: Path to affected feature directory
- **Iteration**: Iteration reference when reported
- **Slice**: Approved slice or artifact that was found defective
- **Prior Reviewer Verdict**: `approved`, `ready`, or equivalent outcome
- **Prior Reviewer Class**: Reviewer reasoning class used for the prior verdict
- **Prior Reviewer Owner**: Reviewer identity that produced the prior verdict
- **Defect Description**: Human-readable summary of the defect
- **Defect Source Location**: File/path/location cited
- **Event Status**: `active`, `resolved`, or `withdrawn`
- **Severity**: Always `soft-warning`
- **Escalation Action**: `stronger-class`, `same-class-independent-owner`, `human-direction-hold`, or `none-yet`
- **Escalated To Class**: Effective reviewer class after escalation (if applicable)
- **Same-Class Fallback Owner**: Independent reviewer owner at same class (if applicable)
- **Carry Forward Iteration**: Next active iteration when report lands after close (if applicable)
- **Candidate Trap Status**: `not-applicable`, `offered`, `approved`, `skipped-corpus-disabled`, or `removed-on-withdrawal`
- **Withdrawal Reference**: Link to withdrawal record (if event is withdrawn)
- **De-Escalation Outcome**: Clean-pass outcome when active chain resolves
- **Recorded At**: ISO datetime when logged

## Example Record Template

```markdown
### RRE-{NNN}

- **Feature**: `specs/XXX-feature-name`
- **Iteration**: `NNN`
- **Slice**: `iteration NNN slice description`
- **Prior Reviewer Verdict**: `approved`
- **Prior Reviewer Class**: `copilot`
- **Prior Reviewer Owner**: `Reviewer`
- **Defect Description**: Brief summary of defect
- **Defect Source Location**: `path/to/file.ext:line`
- **Event Status**: `active`
- **Severity**: `soft-warning`
- **Escalation Action**: `stronger-class`
- **Escalated To Class**: `codex`
- **Same-Class Fallback Owner**: (none)
- **Carry Forward Iteration**: (none)
- **Candidate Trap Status**: `not-applicable`
- **Withdrawal Reference**: (none)
- **De-Escalation Outcome**: (pending)
- **Recorded At**: `2026-05-09T12:34:56Z`
```

---

## Event Records

*No reviewer-regression events have been recorded yet.*

---

## Ledger Statistics

- **Total Events**: 0
- **Active Events**: 0
- **Resolved Events**: 0
- **Withdrawn Events**: 0
- **Strongest Escalation Ever Reached**: (none)
- **Last Updated**: 2026-05-09T20:00:00Z
