# PSGallery Release Credentials

Maintainer-facing operations guidance for credentials used by the PowerShell Gallery release workflow.

> Authenticode signing was removed from the active PSGallery publish path in `v0.24.1`; see `file:///C:/Dev/Specrew/proposals/072-psgallery-unsigned-default.md`. The current live release flow requires only the PSGallery API key. Any signing-certificate material below is retained as historical context for the removed pre-`v0.24.1` flow.

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

### Removed Signing Secrets (Historical)

- `SIGNING_CERT_BASE64`
- `SIGNING_CERT_PASSWORD`

These secrets belonged to the removed Authenticode-signing path and are no longer required for current PSGallery publishes.

## First Live Publish Follow-Up

1. Create or rotate `PSGALLERY_API_KEY` if needed, then store it in the repository Actions secrets.
2. Push the approved `v*.*` release tag to `origin`; this should run the dry-run lane only.
3. Inspect the GitHub Actions run and confirm the stamp/WhatIf steps succeeded.
4. Manually dispatch **Publish Specrew module** against that same tag with `release_mode=publish`.
5. After the manual publish run succeeds, verify the new version on PSGallery.

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

## Module-Signing Certificate Renewal (Removed in v0.24.1)

This section is historical context only. Proposal 072 removed the Authenticode-signing flow from the live PSGallery publish path, so these renewal steps no longer apply to current releases unless a future proposal reintroduces signing.

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

Review the PSGallery API key during the annual operations event. Only revisit the historical signing-certificate flow if a future release proposal explicitly restores Authenticode signing.
