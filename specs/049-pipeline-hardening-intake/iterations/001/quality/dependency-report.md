# Dependency Report: Iteration 001

**Schema**: v1
**Feature**: 049-pipeline-hardening-intake
**Iteration**: 001
**Updated**: 2026-05-27

## External Dependencies

### Docker Base Images

| Dependency | Version | Source | Usage | License | Risk Level |
|------------|---------|--------|-------|---------|------------|
| `mcr.microsoft.com/powershell` | `lts-ubuntu-22.04` | Microsoft Container Registry | Docker pre-publish harness base image | MIT | LOW |

**Rationale**: Official Microsoft-maintained PowerShell container image with Ubuntu 22.04 LTS. Provides stable cross-platform PowerShell execution environment for pre-publish validation.

**Update Strategy**: LTS tag (`lts-ubuntu-22.04`) automatically tracks the latest PowerShell LTS release on Ubuntu 22.04. Explicit version pinning not required for CI validation harness.

**Fallback**: If MCR is unavailable, Docker build will fail and block publication (acceptable — production PSGallery publish should not proceed without validation).

---

### PowerShell Modules

| Dependency | Version | Source | Usage | License | Risk Level |
|------------|---------|--------|-------|---------|------------|
| Specrew | `0.27.6` | PSGallery | Baseline version for upgrade-path testing | MIT | LOW |

**Rationale**: Baseline stable version installed inside Docker container to validate that candidate packages can successfully upgrade from current production version.

**Version Pin**: `0.27.6` is the current production stable version as of 2026-05-27. This pin should be updated to the next stable version after each production release.

**Update Trigger**: When Specrew v0.28.0 ships as stable, update `tests/Dockerfile.publish-test` line 18 to:
```dockerfile
RUN pwsh -Command "Install-Module -Name Specrew -RequiredVersion 0.28.0 -Repository PSGallery -Scope AllUsers -Force -AllowClobber"
```

**Fallback**: If PSGallery is unavailable during Docker build, build will fail and block publication (acceptable — validation requires network access to PSGallery).

---

## Internal Dependencies

### PowerShell Scripts

| Dependency | Type | Usage | Stability |
|------------|------|-------|-----------|
| `scripts/specrew-update.ps1` | Internal script | Bug 2 fix: PSGallery-first version check | Stable |
| `templates/github/scripts/deploy-squad-runtime.ps1` | Template script | Bug 1 fix: key-based Squad merge | Stable |
| `scripts/internal/test-publish-harness.ps1` | Internal script | 5-phase E2E validation logic | New (stable) |

**Notes**:
- `test-publish-harness.ps1` is new in this iteration. Registered in `Specrew.psd1` FileList to ensure it ships with the module.
- `specrew-update.ps1` and `deploy-squad-runtime.ps1` are existing scripts modified in this iteration.

---

### Git Repository Dependencies

| Dependency | Type | Usage | Stability |
|------------|------|-------|-----------|
| `.specrew/config.yml` | Config file | Version pin validation (Prop 134) | Stable |
| `Specrew.psd1` | Module manifest | Version metadata and FileList | Stable |
| `.github/workflows/publish-module.yml` | GitHub Actions workflow | Pre-publish harness execution gate | Modified (stable) |

**Notes**:
- `.specrew/config.yml` must exist and contain `specrew_version` field for harness Phase 3 validation.
- `Specrew.psd1` must contain valid `FileList` array for harness Phase 2 validation.
- Workflow modification adds a new step; existing steps remain unchanged.

---

## Version Pin Summary

### Explicit Pins

| Artifact | Pinned Version | Location | Update Strategy |
|----------|----------------|----------|-----------------|
| Docker baseline module | `0.27.6` | `tests/Dockerfile.publish-test` line 18 | Update after each stable release |
| Docker base image | `lts-ubuntu-22.04` | `tests/Dockerfile.publish-test` line 15 | Track LTS automatically |
| Current module version | `0.27.6` | `Specrew.psd1` `ModuleVersion` | Bump on release |
| Config version | `0.27.6` | `.specrew/config.yml` `specrew_version` | Keep in sync with manifest |

### Pin Drift Detection (Prop 134)

Harness Phase 3 validates that:
```
.specrew/config.yml specrew_version == Specrew.psd1 ModuleVersion
```

If mismatch detected, harness fails with:
```
FAIL: Version pin DRIFT detected!
Config declares X.Y.Z but manifest declares A.B.C
Prop 134 requires these versions to be synchronized.
```

---

## Network Dependencies

### PSGallery API

**Endpoint**: `https://www.powershellgallery.com/api/v2/`  
**Usage**:
- Docker harness: Install baseline Specrew v0.27.6
- Bug 2 fix: Query latest published version in `specrew update --info`

**Fallback Strategy**:
- **Docker harness**: Fail build if PSGallery unavailable (acceptable — validation requires network access)
- **Bug 2 runtime**: Fall back to module manifest version if PSGallery query fails (graceful degradation)

**Rate Limits**: PSGallery API has no documented rate limits for public package queries. CI execution frequency (release attempts) is low enough to avoid any practical rate limiting.

---

## Dependency Risk Assessment

### HIGH Risk Dependencies

None.

### MEDIUM Risk Dependencies

None.

### LOW Risk Dependencies

All dependencies in this iteration are low-risk:
- **Docker base image**: Official Microsoft-maintained LTS image
- **Baseline module**: Stable production version from PSGallery
- **Internal scripts**: Under version control, tested via T001/T019
- **PSGallery API**: Public, stable, no authentication required

---

## Dependency Change Log

### Added in Iteration 001

- `mcr.microsoft.com/powershell:lts-ubuntu-22.04` — Docker base image for pre-publish harness
- Specrew v0.27.6 from PSGallery — baseline module for upgrade-path testing
- `scripts/internal/test-publish-harness.ps1` — new internal dependency (registered in FileList)

### Modified in Iteration 001

- `.github/workflows/publish-module.yml` — added Docker harness execution step
- `scripts/specrew-update.ps1` — modified version check logic (Bug 2 fix)
- `templates/github/scripts/deploy-squad-runtime.ps1` — modified table merge logic (Bug 1 fix)
- `Specrew.psd1` — added `scripts/internal/test-publish-harness.ps1` to FileList

### No Longer Used

None. No dependencies were removed or deprecated in this iteration.

---

## Maintenance Recommendations

### Baseline Version Updates

**When**: After each stable release to PSGallery

**Action**: Update `tests/Dockerfile.publish-test` line 18 to install the new stable version as baseline.

**Example**: When v0.28.0 ships:
```dockerfile
RUN pwsh -Command "Install-Module -Name Specrew -RequiredVersion 0.28.0 -Repository PSGallery -Scope AllUsers -Force -AllowClobber"
```

### Docker Image Updates

**When**: Ubuntu 24.04 LTS ships (expected ~2024-04)

**Action**: Evaluate migration from `lts-ubuntu-22.04` to `lts-ubuntu-24.04`.

**Compatibility Check**: Test harness execution on new base image before updating production workflow.

### PSGallery API Changes

**Risk**: PSGallery API v2 may eventually be deprecated in favor of v3.

**Mitigation**: Monitor PSGallery announcements for API version changes. `Get-PSGalleryLatestVersion` function in `specrew-update.ps1` abstracts API access; API version change can be isolated to that function.

---

## CI Environment Dependencies

### GitHub Actions Runner

**Runner Image**: `windows-latest`  
**Usage**: Publish workflow execution (Docker build and run require Windows container support)

**Docker Availability**: GitHub Actions `windows-latest` runners include Docker Desktop (Windows containers) by default. No explicit Docker installation step required.

**Fallback**: If Docker unavailable on runner, workflow will fail with clear error message. This is a hard dependency — pre-publish harness cannot run without Docker.

### GitHub Actions Secrets

**Required Secrets**:
- `PSGALLERY_API_KEY` — Required for module publication to PSGallery (not used by harness itself)

**Harness Independence**: Docker harness does NOT require PSGallery API key. It only queries public endpoints (module download) and performs local validation.

---

## Summary

- **External Dependencies**: 2 (Docker base image, baseline Specrew module)
- **Internal Dependencies**: 3 scripts, 3 config files
- **Version Pins**: 4 explicit pins (all documented with update strategies)
- **Network Dependencies**: 1 (PSGallery API with graceful degradation)
- **Risk Level**: All dependencies are LOW risk
- **Maintenance**: Baseline version update required after each stable release

**Overall Assessment**: Dependency footprint is minimal, well-documented, and maintainable.

---

**Reviewer**: Reviewer (Antigravity Coordinator)  
**Review Date**: 2026-05-27
