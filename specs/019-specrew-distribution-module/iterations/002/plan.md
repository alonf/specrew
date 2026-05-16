# Iteration Plan: 002

**Schema**: v1
**Feature**: 019-specrew-distribution-module  
**Branch**: 019-specrew-distribution-module  
**Status**: planning
**Capacity**: 8/20 story_points
**Started**: 2026-05-17
**Created**: 2026-05-17  
**Updated**: 2026-05-17

## Overview

Iteration 002 completes the cross-platform hardening and PSGallery publish-workflow enablement deferred from Iteration 001. This iteration focuses on:

1. **T041 Join-Path Audit/Hardening**: Sweep 104+ embedded-backslash path strings across PowerShell scripts to use `Join-Path` for cross-platform correctness
2. **T054 Cross-Platform Parity Evidence**: Execute Ubuntu CI matrix validation, WSL end-to-end verification (if available), and document evidence in test-evidence/
3. **Publish Workflow Enablement**: Remove/configure manual-approval gate in `.github/workflows/publish-module.yml` so T053 can fire on release-tag push later
4. **Documentation Updates**: Update README and `docs/getting-started.md` from Windows-only to Windows + Linux (Ubuntu via WSL) if evidence supports it

**Scope Lock**: This iteration does NOT include T042 (GitHub Actions secret configuration) or T053 (first real PSGallery publish) — those remain human post-merge follow-up.

## Task Summary

Total tasks: 4 primary tasks (T041, T054, publish-workflow-enablement, docs-update)  
Total effort estimate: 8 Story Points

## Scope Guardrails

- **Locked Iteration 002 Scope**: 104+ embedded-backslash path-string sweep, T041 Join-Path audit, T054 cross-platform parity evidence, `.github/workflows/cross-platform-validation.yml` with Ubuntu CI matrix, WSL Ubuntu end-to-end verification (if available), README + docs updates, PSGallery publish-workflow enablement (remove manual gate)
- **Stop Conditions**: Any FAIL from tests, validator, or hardening gate; any unanswered design question; /review-verdict-signoff; retro; iteration-closeout; feature-closeout; /review if verdict is REPAIR-NEEDED with non-mechanical repairs; token budget exhaustion if cumulative iteration cost > $80; human interrupt if observed
- **WSL Unavailable is NOT a stop**: Record pending-human-execution and continue
- **Mechanical Boundaries Auto-Advance**: Iteration 002 opening/scaffolding, before-implement for Iteration 002 if READY, hardening-gate-and-implementation-auth using the user's authorization text as pre-authorization, /speckit.implement task execution, mechanical repair cycles from concrete review verdicts

## Task Breakdown

### T041: Join-Path Audit and Hardening Sweep

**Effort**: 3 SP  
**Status**: pending  
**Owner**: Implementation Team  
**Trace**: FR-030, research.md R4, `.specrew/cross-platform-backlog.md`

**Description**: Audit all PowerShell scripts in the Specrew codebase for embedded-backslash path construction (e.g., `"$path\subfolder"`, `"C:\path\to\file"`) and refactor to use `Join-Path` for cross-platform correctness. Scope includes:

- `scripts/specrew-init.ps1`
- `scripts/specrew-start.ps1`
- `scripts/specrew-update.ps1`
- `scripts/specrew-team.ps1`
- `scripts/specrew-review.ps1`
- `scripts/specrew-where.ps1`
- `scripts/internal/dashboard-renderer.ps1`
- `extensions/specrew-speckit/scripts/*.ps1`

**Acceptance**:
- All embedded-backslash path strings replaced with `Join-Path`
- Scripts run correctly on Windows (existing behavior preserved)
- Scripts run correctly on Linux/macOS (no path delimiter failures)

### T054: Cross-Platform Parity Evidence

**Effort**: 3 SP  
**Status**: pending  
**Owner**: Implementation Team  
**Trace**: US5 acceptance scenarios, SC-006, `.specrew/cross-platform-backlog.md`

**Description**: Execute cross-platform validation to prove Specrew module works on Windows, Linux (Ubuntu), and macOS. Evidence includes:

1. **Ubuntu CI Matrix**: Create `.github/workflows/cross-platform-validation.yml` with Ubuntu runner; execute `specrew init`, `specrew start`, `specrew where` in clean environment; verify no errors
2. **WSL Ubuntu Verification**: If WSL Ubuntu is available, run end-to-end verification on native ext4 filesystem; document results in `test-evidence/us5-cross-platform.md`; if WSL unavailable, mark pending-human-execution and continue
3. **macOS**: Include macOS runner in CI matrix if trivial; otherwise defer to post-merge human follow-up

**Acceptance**:
- CI matrix runs pass on Ubuntu
- WSL verification documented (or marked pending if unavailable)
- Test evidence in `test-evidence/us5-cross-platform.md` shows cross-platform parity

### Publish-Workflow Enablement

**Effort**: 1 SP  
**Status**: pending  
**Owner**: Implementation Team  
**Trace**: T053, FR-025, `.github/workflows/publish-module.yml`

**Description**: Remove/configure the manual-approval gate in `.github/workflows/publish-module.yml` so the workflow can fire automatically on release-tag push. This enablement allows T053 (first real publish) to execute later as human post-merge follow-up without requiring workflow changes at that time.

**Acceptance**:
- Manual-approval gate removed or configured as optional
- Workflow can fire automatically on `v*.*` tag push
- Workflow still respects secret requirements (PSGALLERY_API_KEY, SIGNING_CERT_BASE64, SIGNING_CERT_PASSWORD)
- Documentation in `docs/operations/psgallery-release-credentials.md` updated if workflow changes affect release procedure

### Documentation Updates

**Effort**: 1 SP  
**Status**: pending  
**Owner**: Implementation Team  
**Trace**: README.md, `docs/getting-started.md`, US5

**Description**: Update README and `docs/getting-started.md` from Windows-only install instructions to Windows + Linux (Ubuntu via WSL) if T041 and T054 evidence supports cross-platform claims. Do NOT overclaim — only update docs if actual evidence validates the claim.

**Acceptance**:
- README mentions Ubuntu/WSL support if evidence validates it
- `docs/getting-started.md` includes Linux install instructions if supported
- No false claims about unsupported platforms

## Effort Model

| Setting | Value | Notes |
| --- | --- | --- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance |
| Capacity per Iteration | 20 | Repository capacity from `.specrew/iteration-config.yml` |
| Planned Effort | 8 | Grouped execution estimate for Iteration 002 |
| Iteration Bounding | scope | Iteration closes only when the approved scope is complete |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time` |
| Overcommit Threshold | 1.0 | No silent overcommit beyond the 20-point ceiling |
| Defer Strategy | manual | Any deferral must be named explicitly |
| Calibration Enabled | true | Retro should compare this grouped baseline against actual delivery |

## Critical Constraints

**⚠️ Locked Scope**: Do not widen into T042 (secret setup), T053 (real publish), feature-closeout, or unrelated cleanup. Scope is locked to T041, T054, publish-workflow enablement, and docs updates.

**⚠️ WSL Unavailable Handling**: If WSL is unavailable, record `pending-human-execution` in test-evidence and continue. This is NOT a stop condition.

**⚠️ Evidence-Driven Documentation**: Only update README/docs if T041 and T054 produce actual validation evidence. Do not fake claims.

## Authorization

- **Iteration 002 Opening**: Authorized 2026-05-17 per explicit human statement: "AUTHORIZE Feature 019 Iteration 002 OPENING + PERMISSIVE OVERNIGHT AUTONOMOUS RUN"
- **Hardening-gate sign-off**: Pre-authorized via permissive overnight autonomous run with stop conditions
- **Implementation authorization**: Pre-authorized via permissive overnight autonomous run with stop conditions

## Reference

Full task details in feature-level tasks.md:  
`file:///C:/Dev/Specrew/specs/019-specrew-distribution-module/tasks.md`
