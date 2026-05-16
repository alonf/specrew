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

### Annual Operations Note

When T006 certificate guidance is added, review it in the same annual operations event as this API-key review so release credentials stay in sync.
