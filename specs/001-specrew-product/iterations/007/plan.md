# Iteration Plan: 007

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: retro
**Capacity**: 8/20 story_points
**Started**: 2026-05-06
**Completed**:

## Summary

Iteration 007 hardens lifecycle governance around FR-043, FR-044, and FR-045. The slice turns `.squad\decisions.md` into a script-usable structured ledger, enforces canonical defer evidence before accepted deferred gaps can close, and mirrors active gap-ledger concerns plus routing fallback signals into reviewer navigation.

The implementation stays inside the existing reviewer/governance pipeline. Rather than inventing a second governance artifact system, it extends the shared governance helper, the validator, and reviewer closeout generation so the same persisted iteration packet now carries the no-gap policy end to end.

---

## Scope

### In Scope

- Structured decisions-ledger entries for routing evidence and governance decisions
- Validator enforcement for accepted deferred gaps that lack approved canonical defer entries
- Reviewer-index triage hints that mirror active gap-ledger concerns
- Routing fallback counting from canonical ledger evidence
- Integration coverage for no-gap closure and reviewer-index mirroring

### Out of Scope

- Concurrency-aware team sizing (Iteration 8)
- Junior/Senior ownership-boundary serialization (Iteration 8)
- Multi-lane validation scaffolding (Iteration 9)

---

## Requirements Traceability

| Spec Ref | Requirement | Planned Deliverables | Owner |
|----------|-------------|----------------------|-------|
| FR-043 | Runtime routing evidence | Structured routing-evidence ledger entries, reviewer fallback counting, persisted fallback reasons | Implementer |
| FR-044 | No-gap closure + canonical defer | validator enforcement, canonical defer parsing, accepted-review gate for deferred gaps | Reviewer |
| FR-045 | Critical review gap mirroring | reviewer-index triage hints sourced from active `## Gap Ledger` concerns, contract test coverage | Reviewer + Implementer |

---

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ------ | ----- | ------ | ------- |
| T-701 | Add structured decisions-ledger support for governance evidence | FR-043 | US-2 | 2 | Implementer | done | copilot-agent | 2 | pass |
| T-702 | Enforce canonical defer evidence before accepted deferred gaps can close | FR-044 | US-2 | 2 | Reviewer | done | copilot-agent | 2 | pass |
| T-703 | Mirror active gap-ledger concerns and routing fallback signals into reviewer navigation | FR-045, FR-043 | US-2 | 2 | Reviewer | done | copilot-agent | 2 | pass |
| T-704 | Add integration coverage for no-gap governance and routing evidence | FR-043, FR-044, FR-045 | US-2 | 2 | Implementer | done | copilot-agent | 2 | pass |

**Planned Total**: 8 story_points

---

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 20 | Maximum planned effort before overcommit guidance applies. |
| Iteration Bounding | scope | Governance hardening stays fixed to the no-gap and routing-evidence slice. |
| Time Limit (hours) | n/a | Not used for this scope-bounded iteration. |
| Overcommit Threshold | 1.0 | No overcommit expected at planned capacity 8/20. |
| Defer Strategy | manual | Any approved defer must now be canonical rather than implicit. |
| Calibration Enabled | true | Retro should confirm whether governance hardening continues to fit the current capacity baseline. |

---

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | 1 | Requirement-to-validator and reviewer-surface mapping |
| Implementation | 4 | Shared ledger helper, validator, reviewer artifact updates |
| Review | 2 | Contract-focused integration and governance validation |
| Rework | 1 | Buffer for parser and artifact-shape fixes |

---

## Acceptance Checkpoints

1. Accepted reviews with deferred gap-ledger entries fail validation unless `.squad\decisions.md` contains a matching defer entry with approving human.
2. Reviewer closeout and replay surfaces mirror active `## Gap Ledger` concerns into triage hints instead of reducing them to a generic warning.
3. Runtime routing evidence can be recorded in structured form and reviewer closeout counts iteration-scoped routing fallbacks from canonical ledger evidence.
4. Contract tests cover both the failing and accepted no-gap paths for deferred gaps.

## Notes

- Iteration 007 keeps the reviewer packet authoritative; no separate governance dashboard was introduced.
- The new gap-governance integration test doubles as a scratch-level example of the canonical defer workflow.
