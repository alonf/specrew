# PSGallery Release Credentials

Maintainer-facing operations guidance for credentials used by the PowerShell Gallery release workflow.

## Iteration 001 Release Boundary

- Workflow: `.github/workflows/publish-module.yml`
- Helper: `scripts/internal/invoke-module-release.ps1`
- Safety model:
  - `push` on `v*.*` tags runs the **dry-run** lane only
  - a live publish requires `workflow_dispatch` with `release_mode=publish`
- Iteration 001 explicitly stops short of a real PSGallery publish; the first live publish remains a human-owned follow-up.

## Required GitHub Actions Secrets

| Secret | Purpose | Human follow-up |
| --- | --- | --- |
| `PSGALLERY_API_KEY` | Authenticates `Publish-Module` against PSGallery | Create/rotate in PowerShell Gallery, then add it in repository Actions secrets |
| `SIGNING_CERT_BASE64` | Restores the 1-year self-signed signing certificate PFX for live publish | Generate/export the PFX, Base64-encode it, and store the encoded value as a secret |
| `SIGNING_CERT_PASSWORD` | Unlocks the PFX restored from `SIGNING_CERT_BASE64` | Store the matching export password as a separate secret |

## First Live Publish Follow-Up

1. Create or renew the self-signed code-signing certificate with `-NotAfter (Get-Date).AddYears(1)`.
2. Export the certificate to PFX, Base64-encode it, and add/update the three required repository secrets above.
3. Push the approved `v*.*` release tag to `origin`; this should run the dry-run lane only.
4. Inspect the GitHub Actions run and confirm the stamp/sign/WhatIf steps succeeded.
5. Manually dispatch **Publish Specrew module** against that same tag with `release_mode=publish`.
6. After the manual publish run succeeds, verify the new version on PSGallery.

## PSGallery API Key Rotation

### Cadence

- **Routine review/rotation**: once per year, at the calendar anniversary of the key's creation
- **Rotate immediately if**:
  - module-maintainer ownership changes
  - you suspect the key leaked
  - publish authentication fails unexpectedly
  - the annual review finds the key is older than 12 months

### Rotation Procedure

1. Generate a new API key on `PowerShellGallery.com`, scoped to the Specrew module, with an appropriate expiration.
2. Update the GitHub Actions secret (`PSGALLERY_API_KEY`, or the workflow's equivalent secret name) to the new value.
3. Run the publish workflow through its **manual-dispatch dry-run path** to confirm authentication without performing a real publish.
4. Revoke the old API key only after the dry run confirms the new key works.

## Module-Signing Certificate Renewal

### Cadence

- **Routine renewal**: once per year, aligned to the annual PSGallery credential review
- **Renew immediately if**:
  - certificate material is suspected to be exposed
  - signing fails unexpectedly during publish validation
  - maintainer ownership changes and you want fresh certificate custody

### Renewal Procedure

1. Generate a new self-signed code-signing certificate with `-NotAfter (Get-Date).AddYears(1)`.
2. Export the certificate to a password-protected PFX, Base64-encode it, and update the GitHub Actions secrets (`SIGNING_CERT_BASE64`, `SIGNING_CERT_PASSWORD`).
3. Run the publish workflow through its **manual-dispatch dry-run path** to confirm signing succeeds without performing a real publish.
4. Archive the old certificate material for historical signature verification after the new certificate is validated.
5. Record the renewal date and set the next annual reminder.

## Annual Operations Event

Review the PSGallery API key and the self-signed signing certificate together in one annual operations event so release credentials stay in sync and the renewal flow stays warm.
