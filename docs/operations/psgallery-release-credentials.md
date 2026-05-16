# PSGallery Release Credentials

Maintainer-facing operations guidance for credentials used by the PowerShell Gallery release workflow.

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
