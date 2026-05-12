# Decisions

**Schema**: v1  
**Feature**: 008-sample-ledger  
**Last Updated**: 2026-05-10

## Decision Log

### D001 - Ledger Testing Configuration

- **Date**: 2026-05-10
- **Type**: configuration
- **Decision**: Enable reviewer-regression ledger consistency testing
- **Rationale**: Test duplicate detection, consolidation, and corpus-disabled scenarios
- **Participants**: Test maintainer

---

## Reviewer-Regression Decisions

### reviewer-regression-escalation: Reviewer regression RR-2026-05-10-001

- **Type**: reviewer-regression-escalation
- **Affected Requirement**: FR-001, FR-002, FR-003, FR-004, FR-015
- **Affected Iteration**: iteration 001
- **Next Action**: continue-review-routing
- **Rationale**: Escalating from copilot to claude after human-found defect in approved slice
- **Decision Details**:
  - **Event ID**: RR-2026-05-10-001
  - **Feature**: specs/008-sample
  - **Routing Outcome**: escalate-to-stronger-class
  - **Selected Reviewer Class**: claude
  - **Selected Reviewer Owner**: claude-reviewer-b
  - **Hold Active**: false
- **Recorded**: 2026-05-10T10:00:00Z
