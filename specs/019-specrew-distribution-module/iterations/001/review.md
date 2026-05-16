# Review: Iteration 001

**Schema**: v1  
**Reviewer**: Reviewer  
**Reviewed By**: Reviewer  
**Reviewed At**: 2026-05-16  
**Implementation Ref**: commit `99af0e7`  
**Overall Verdict**: needs-rework  
**Explicit Reviewer Verdict**: needs-work  
**Review Boundary**: Review boundary completed with blocking packaged-module allowlist drift; review-verdict-signoff is not yet open.

---

## Summary

Feature `019`, Specrew distribution module, iteration `001`, is **NOT ACCEPTED YET** against implementation commit
`99af0e7`. The Windows-first manifest/import/update/publish-dry-run lanes all revalidated green, but independent review
found that the approved explicit `FileList` strategy is still incomplete on the shipped manifest.

The blocking defect is real and inside the authorized Iteration 001 scope: `Specrew.psd1` does not yet allowlist at
least `scripts\internal\invoke-module-release.ps1` and `templates\github\agents\squad.agent.md`. That means the
published package would not fully satisfy the required bundled-scripts and bundled-GitHub-template contract even though
the current scratch-module tests pass by copying whole directory trees. Until the allowlist and package-shaped evidence
are repaired together, this iteration is **REPAIR-NEEDED** rather than ready for signoff.

---

## FR Findings Summary

| Requirement | Verdict | Findings |
| --- | --- | --- |
| FR-001 | pass | `Test-ModuleManifest .\Specrew.psd1` passed with PowerShell `7.0`. |
| FR-002 | pass | `Import-Module .\Specrew.psd1 -Force` and `Get-Command -Module Specrew` exposed the seven required functions. |
| FR-003 | pass | No external runtime dependencies were introduced beyond PowerShell 7. |
| FR-004 | pass | Author, repository metadata, tags, and build-time version stamping are present and validated by the publish dry-run lane. |
| FR-005 | pass | The current allowlisted bundle is ~`1.668 MB`, comfortably below the `5 MB` ceiling. |
| FR-006 | needs-work | The explicit package allowlist still omits at least `scripts\internal\invoke-module-release.ps1`, so the shipped module does not yet bundle all required Specrew scripts. |
| FR-007 | pass | `extensions\specrew-speckit\` is allowlisted in the manifest. |
| FR-008 | needs-work | The template allowlist still omits `templates\github\agents\squad.agent.md`, so the shipped `templates\` surface is incomplete. |
| FR-009 | pass | Required reference docs (`dashboard-guide.md`, `roadmap-maintenance.md`, operations credentials doc) are bundled. |
| FR-010 | pass | The manifest remains allowlist-based and excludes the repository-only surfaces named by the spec. |
| FR-011 | pass | `scripts\specrew-init.ps1` detects module-vs-clone execution context. |
| FR-012 | pass | Installed-module bootstrap resolves bundled templates from the module root. |
| FR-013 | pass | `.specify\` copy behavior is covered by the installed-module bootstrap fixture. |
| FR-014 | pass | `.squad\` copy behavior is covered by the installed-module bootstrap fixture. |
| FR-015 | needs-work | The published package would not include the full `.github\` bootstrap surface because `templates\github\agents\squad.agent.md` is missing from `FileList`. |
| FR-016 | pass | Per-project generation remains intact (`.specrew\config.yml`, `.squad\decisions.md`, `.squad\identity\now.md`). |
| FR-017 | pass | Bootstrap validation fails closed when the coordinator prompt is absent. |
| FR-018 | pass | Re-running `specrew init` preserves existing surfaces unless forced. |
| FR-019 | pass | Installed-module command logic updates on the next invocation path. |
| FR-020 | pass | `scripts\specrew-update.ps1` implements the template-refresh flow. |
| FR-021 | pass | `.specrew\template-conflicts\*.conflict` artifacts use the approved Git-style marker payload. |
| FR-022 | pass | New templates are added non-destructively during `specrew update`. |
| FR-023 | pass | Removed templates emit `.deletion` review artifacts. |
| FR-024 | pass | The workflow/helper stamp the manifest version from `.specrew\config.yml`. |
| FR-025 | pass | Secret-backed signing plus the approved 1-year dry-run fallback are implemented and validated. |
| FR-026 | human-follow-up | The workflow exists; first live PSGallery publish remains a maintainer-owned manual gate for Iteration 001 and is non-blocking by review direction. |
| FR-027 | pass | The publish workflow composes with the approved Rule 15 tag flow in dry-run/manual-dispatch shape. |
| FR-028 | human-follow-up | `PSGALLERY_API_KEY` is wired and validated for failure reporting, but no live secret was configured in this iteration by design. |
| FR-029 | pass | Missing-secret and invalid live-publish contexts fail visibly in the publish helper/tests. |
| FR-030 | deferred | Delivered loader/init/update surfaces use `Join-Path`, but the broad audit/WSL hardening remains explicitly deferred to Iteration 002 and is non-blocking here. |
| FR-031 | deferred | Windows-first evidence is complete for Iteration 001; Ubuntu/macOS/WSL parity remains deferred to Iteration 002 and is non-blocking here. |
| FR-032 | pass | Core-only compatibility is enforced via the manifest's `CompatiblePSEditions = @('Core')` surface, satisfying the requirement intent. |

---

## User Story Acceptance Surfaces

| User Story | Verdict | Findings |
| --- | --- | --- |
| US1 — First-Time Install | needs-work | Manifest/import checks and the repo-shaped installed-module bootstrap fixture pass, but the actual shipped package is still incomplete because `templates\github\agents\squad.agent.md` is not allowlisted. |
| US2 — Project Bootstrap from Installed Module | needs-work | Bootstrap logic, idempotency, and installed-module `start` handoff are implemented, but the missing shipped GitHub agent template blocks truthful signoff for the package path. |
| US3 — Module Update and Template Refresh | pass | `distribution-module-update.ps1` passed and verified conflict, addition, deletion, and follow-up surfacing behavior. |
| US4 — Module Publishing on Feature Closeout | pass (bounded) | The workflow stamp/sign/dry-run/manual-gate path is implemented and tested; secrets and first live publish remain human follow-up only and are non-blocking here. |
| US5 — Cross-Platform Consistency | deferred | Iteration 001 is Windows-first only. Ubuntu/macOS/WSL parity, Join-Path sweep hardening, and first real publish remain deferred/human follow-up and are not blockers for this review. |

---

## Canonical Concern Verification

| Concern | Implemented | Enforced | Observable | Documented | Verdict | Evidence |
| --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | ✅ | ✅ | ✅ | ✅ | pass | The reviewed slice stays repo-local: PowerShell scripts, manifest/workflow metadata, templates, docs, and dry-run publish automation. No secrets were committed. |
| `error-handling-expectations` | ✅ | ✅ | ✅ | ✅ | pass | Publish dry-run/manual-gate failure paths report clearly, and bootstrap validation now fails closed if the coordinator prompt is absent. |
| `retry-idempotency-requirements` | ✅ | ✅ | ✅ | ✅ | pass | `specrew init` rerun preservation, `specrew update` conflict safety, and publish dry-run/manual-gate behavior all remained repeatable in review. |
| `test-integrity-targets` | ✅ | ⚠️ | ⚠️ | ✅ | needs-work | The current green tests do not yet exercise a manifest-shaped package surface. Review found missing allowlist entries despite passing resource-bundling evidence. |
| `operational-resilience-concerns` | ✅ | ⚠️ | ⚠️ | ✅ | needs-work | Quickstart/evidence document a complete installed-module story, but the published package would still omit required files from the approved distribution contract. |

---

## Validation Evidence

1. ✅ `Test-ModuleManifest .\Specrew.psd1`
2. ✅ `Import-Module .\Specrew.psd1 -Force`
3. ✅ `pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\distribution-module-init.ps1`
4. ✅ `pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\distribution-module-update.ps1`
5. ✅ `pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\distribution-module-publish.ps1`
6. ✅ `pwsh -NoProfile -ExecutionPolicy Bypass -File .\extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath . -IterationPath .\specs\019-specrew-distribution-module\iterations\001`
7. ✅ Bundle-size audit of the current manifest allowlist: ~`1.668 MB`
8. ❌ Allowlist audit of the shipped manifest found missing distributable files, including at least:
   - `scripts\internal\invoke-module-release.ps1`
   - `templates\github\agents\squad.agent.md`

---

## Artifact Truth Verification

1. ✅ `specs\019-specrew-distribution-module\iterations\001\plan.md` now records the open review boundary with repair-needed outcome.
2. ✅ `specs\019-specrew-distribution-module\iterations\001\state.md` now records the blocking allowlist drift and keeps review-verdict-signoff closed.
3. ✅ `specs\019-specrew-distribution-module\iterations\001\drift-log.md` now records the review-discovered implementation drift instead of claiming zero events.
4. ✅ `specs\019-specrew-distribution-module\iterations\001\quality\hardening-gate.md` now records that post-implementation verification is review-blocked by allowlist drift.
5. ✅ Out-of-scope truth is preserved: T041/T054 remain deferred to Iteration 002, and T042/T053 remain human follow-up only.

---

## Defects / Repair Items

1. **R-019-R1 — repair the shipped manifest allowlist**
   - **Files**: `C:\Dev\Specrew\Specrew.psd1`
   - **Required change**: Add the missing distributable entries required by the approved bounded contract, including at least `scripts\internal\invoke-module-release.ps1` and `templates\github\agents\squad.agent.md`.
   - **Why this blocks signoff**: FR-006, FR-008, and FR-015 require those shipped surfaces. Without them, the real PSGallery package is incomplete even though the repository tree is correct.

2. **R-019-R2 — refresh package-shaped evidence after the manifest repair**
   - **Files**: `C:\Dev\Specrew\tests\integration\distribution-module-init.ps1`, `C:\Dev\Specrew\tests\integration\distribution-module-publish.ps1`, `C:\Dev\Specrew\specs\019-specrew-distribution-module\test-evidence\us1-install.md`, `C:\Dev\Specrew\specs\019-specrew-distribution-module\test-evidence\us2-bootstrap.md`, `C:\Dev\Specrew\specs\019-specrew-distribution-module\iterations\001\quality\cross-platform-manual-checklist.md`
   - **Required change**: Re-record proof against the repaired manifest-shaped package surface so the evidence matches what the published module will actually ship.
   - **Why this blocks signoff**: The current tests/evidence pass by staging whole directories, so they over-claim package completeness under the explicit allowlist strategy.

---

## Gap Ledger

- blocking-now — `explicit-filelist-allowlist-drift`: the shipped manifest still omits required distributable files, including `scripts\internal\invoke-module-release.ps1` and `templates\github\agents\squad.agent.md`.
- blocking-now — `package-surface-evidence-overclaim`: the current US1/US2/package-surface tests do not yet prove the approved explicit allowlist contract.
- human-follow-up — `T042/T053` remain maintainer-owned only: GitHub Actions secrets, tag push, manual dispatch, and first live PSGallery publish.
- deferred-scope — `T041/T054`, Ubuntu/macOS/WSL parity, broad embedded-backslash sweep, and first real PSGallery publish remain Iteration 002 or human follow-up work and are not blockers for this boundary.

---

## Task Verdicts

| Task | Requirement | Verdict | Notes |
| --- | --- | --- | --- |
| T001-T006 | Design decisions / clarify locks | pass | The locked decisions remain honored: PSGallery-only, canonical name + fallback, 1-year self-sign, preserve-and-flag, README-led migration, and Windows-first guardrails. |
| T007-T009 | FR-001, FR-002, FR-003, FR-004, FR-032 | pass | Manifest and loader validation passed. |
| T010-T014 | FR-005, FR-006, FR-007, FR-008, FR-009, FR-010 | needs-work | Resource bundling is not yet truthful under the approved explicit allowlist strategy. |
| T015-T019 | FR-011, FR-012, FR-013, FR-014, FR-015, FR-016, FR-017, FR-018 | needs-work | The bootstrap logic is correct, but FR-015 remains blocked until the shipped package actually contains the missing GitHub agent template. |
| T030-T035 | FR-019, FR-020, FR-021, FR-022, FR-023 | pass | Update/template-refresh behavior passed under independent review. |
| T036-T042 | FR-024, FR-025, FR-026, FR-027, FR-028, FR-029 | needs-work | Publish workflow logic is implemented, but the shipped module still omits `scripts\internal\invoke-module-release.ps1` from the manifest allowlist. |
| T050-T056 | SC-001, SC-002, SC-003, SC-004, SC-005, SC-006 | needs-work | The Windows-first evidence set is mostly truthful, but package-surface completeness is still over-claimed under the explicit allowlist contract. |

---

## Verdict

**NEEDS-WORK / REPAIR-NEEDED** — Feature `019`, Specrew distribution module, iteration `001`, is not ready for signoff on commit `99af0e7`.
The blocker is concrete and bounded: the shipped manifest still omits required distributable files, so the package
does not yet match the approved explicit allowlist contract or the installed-module evidence story. Repair the allowlist
and refresh the package-shaped evidence, then route the iteration back for re-review.

---

## Next Action

Authorize the bounded repair items `R-019-R1` and `R-019-R2`. Do **not** open review-verdict-signoff, retro, or
closeout from this review boundary.

---

**Review Boundary Ref**: This artifact records a review boundary with blocking packaged-module allowlist drift. Review-verdict-signoff remains closed pending repair.


