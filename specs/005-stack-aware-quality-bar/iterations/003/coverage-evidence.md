# Coverage Evidence: Iteration 003

**Schema**: v1
**Reviewed**: 2026-05-08
**Overall Verdict**: accepted

## Test Strategy

- Implementation briefing: (unavailable)
- Review-time strategy: rerun the Phase 2 planning and hardening regression lanes plus live gate/validator commands against `iterations\003`.

## Tests Run

| Command | Result | Pass Count | Fail Count | Duration | Exit Code | Notes |
| ------- | ------ | ---------- | ---------- | -------- | --------- | ----- |
| & '.\\tests\\integration\\quality-profile-foundation.ps1' | pass | 1 | 0 | 00:00:02.4600000 | 0 | PASS: Quality profile foundation scaffold and Phase 1/Phase 2 planning contracts expose versioned quality assets, bounded hardening metadata, preserve local overrides, and define recognized-stack/custom-composition expectations |
| & '.\\tests\\integration\\hardening-gate-contract.ps1' | pass | 1 | 0 | 00:00:01.6600000 | 0 | PASS: Hardening-gate fixtures keep blocked, approved-deferral, and ready scenarios deterministic with reviewable rationale and human-approved deferral evidence |
| & '.\\tests\\integration\\quality-evidence-governance.ps1' | pass | 1 | 0 | 00:00:05.9100000 | 0 | PASS: Quality evidence governance regressions passed. |
| & '.\\tests\\integration\\gap-governance.ps1' | pass | 1 | 0 | 00:00:02.3400000 | 0 | PASS: Reviewer index mirrors active gap concerns and routing fallback evidence |
| & '.\\extensions\\specrew-speckit\\scripts\\run-hardening-gate.ps1' -ProjectPath . -IterationPath '.\\specs\\005-stack-aware-quality-bar\\iterations\\003' -OutputFormat Json | pass | 1 | 0 | 00:00:00.7100000 | 0 | Returned `OverallVerdict=ready` with no blocking concerns for Iteration 003. |
| & '.\\extensions\\specrew-speckit\\scripts\\validate-governance.ps1' -ProjectPath . -IterationPath '.\\specs\\005-stack-aware-quality-bar\\iterations\\003' | pass | 1 | 0 | 00:00:00.8700000 | 0 | Passed after the iteration lifecycle metadata was aligned to review-state truth. |

## Coverage Estimate

- Kind: qualitative
- Label: focused_regression
- Tool: unknown

## Coverage-to-Requirements

| Requirement | Test Files / Commands |
| ----------- | --------------------- |
| FR-010 | cmd:& '.\\tests\\integration\\quality-profile-foundation.ps1' |
| FR-016 | cmd:& '.\\tests\\integration\\quality-profile-foundation.ps1' |
| FR-018 | cmd:& '.\\tests\\integration\\quality-profile-foundation.ps1' |
| FR-031 | cmd:& '.\\tests\\integration\\quality-profile-foundation.ps1', cmd:& '.\\tests\\integration\\hardening-gate-contract.ps1', cmd:& '.\\tests\\integration\\quality-evidence-governance.ps1', cmd:& '.\\extensions\\specrew-speckit\\scripts\\run-hardening-gate.ps1', cmd:& '.\\extensions\\specrew-speckit\\scripts\\validate-governance.ps1' |
| FR-032 | cmd:& '.\\tests\\integration\\hardening-gate-contract.ps1', cmd:& '.\\extensions\\specrew-speckit\\scripts\\run-hardening-gate.ps1' |
| FR-033 | cmd:& '.\\tests\\integration\\hardening-gate-contract.ps1', cmd:& '.\\tests\\integration\\quality-evidence-governance.ps1', cmd:& '.\\tests\\integration\\gap-governance.ps1', cmd:& '.\\extensions\\specrew-speckit\\scripts\\validate-governance.ps1' |
| FR-034 | cmd:& '.\\tests\\integration\\quality-profile-foundation.ps1' |
| FR-038 | cmd:& '.\\tests\\integration\\quality-profile-foundation.ps1', cmd:& '.\\tests\\integration\\hardening-gate-contract.ps1' |
| FR-039 | cmd:& '.\\tests\\integration\\quality-profile-foundation.ps1', cmd:& '.\\tests\\integration\\quality-evidence-governance.ps1' |
| FR-040 | cmd:& '.\\tests\\integration\\quality-profile-foundation.ps1' |
