# US4 Publish Evidence

**Iteration**: 001  
**Scope**: workflow, stamp/sign path, and manual gate readiness only  
**Status**: dry-run/manual-gate ready; no live publish performed

## Workflow Surfaces

- `.github\workflows\publish-module.yml`
- `scripts\internal\invoke-module-release.ps1`
- `docs\operations\psgallery-release-credentials.md`

## Evidence Summary

1. **Workflow creation / version stamping / signing / dry-run publish**
   - Command: `pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\distribution-module-publish.ps1`
   - Result: PASS
   - Verified outcomes:
     - `Specrew.psd1` is stamped from `.specrew\config.yml` `specrew_version`
     - `Test-ModuleManifest` still passes after stamping
     - `Specrew.psd1` and `Specrew.psm1` are signed
     - tag pushes stay on the `Publish-Module -WhatIf` lane
     - live publish refuses to run outside a `v*.*` tag ref
     - live publish reports a missing `PSGALLERY_API_KEY` clearly

2. **Manual publish safety model**
   - `push` on `v*.*` tags → always `dry-run`
   - `workflow_dispatch` with `release_mode=publish` → maintainer-only live publish path
   - signing secrets are preferred; dry-run can fall back to an ephemeral 1-year self-signed certificate so Iteration 001 never needs real secrets just to validate the lane

## Human Follow-Up (T042 / T053)

1. Configure repository secrets:
   - `PSGALLERY_API_KEY`
   - `SIGNING_CERT_BASE64`
   - `SIGNING_CERT_PASSWORD`
2. Push the approved release tag to `origin` and inspect the dry-run workflow run.
3. Manually dispatch `Publish Specrew module` against that same tag with `release_mode=publish`.
4. Verify the run completes and then confirm the PSGallery listing/version externally.

## Iteration 001 Truth Note

- No real PSGallery publish occurred in this iteration.
- No credentials were created, uploaded, or committed during this work.
