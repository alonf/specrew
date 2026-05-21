---
description: "Iteration 001 review-scope task ledger for Proposal 083"
---

# Tasks: Iteration 001 Review Scope (Feature 030)

**Feature**: 030-validator-speedup  
**Iteration**: 001  
**Locked Implementation Commit**: `eeeb90e`  
**Implementation Range**: `edf4104...eeeb90e`

---

## Review-Scope Tasks

### validator-auto-scope-core

- [x] Confirm `Get-SpecrewLocalScopeBaseRef` follows the approved priority chain.
- [x] Confirm feature-branch auto-scope, explicit `-ChangedOnly`, `-FullRun`, and base-undetectable fallback stay requirement-aligned.
- [x] Confirm `[validator-scope]` is emitted as the first informational output on all required execution paths.

### governance-doc-sync

- [x] Confirm coordinator guidance names the feature-branch auto-scope default and the explicit `-FullRun` opt-out.
- [x] Confirm Reviewer charter wording tells the Crew what evidence to expect for local validator review.
- [x] Confirm `CHANGELOG.md` records Proposal 083's motivation and opt-out behavior.

### integration-regression-coverage

- [x] Confirm the locked integration lane covers explicit `-ChangedOnly`, auto-scope, missing `origin/HEAD`, `-FullRun`, on-main behavior, no-remote fallback, and detached HEAD fallback.
- [x] Confirm the review honors the human lock on implementation evidence instead of rerunning the suite.

### mirror-parity-audit

- [x] Confirm the reviewed diff preserves parity between `extensions/specrew-speckit/` and `.specify/extensions/specrew-speckit/`.
- [x] Confirm no review-scope gap remains open inside the authorized implementation range.

---

## Notes

- This ledger exists to keep the iteration-local review packet truthful after the feature-level artifacts were approved and implementation landed without a prior iteration scaffold.
- Review-boundary work remains limited to documentation, evidence, and lifecycle truth surfaces.
