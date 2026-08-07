# PSGallery Release Credentials

Maintainer-facing operations guidance for the PowerShell Gallery release workflow.

> Authenticode signing was removed from the active PSGallery publish path in `v0.24.1`; see
> `proposals/072-psgallery-unsigned-default.md`. The live release path requires only the PSGallery API key.

## Current Tag-Driven Release Flow

- Workflow: `.github/workflows/publish-module.yml`
- Helper: `scripts/internal/invoke-module-release.ps1`
- A push of a `v*.*` prerelease tag automatically selects `publish-prerelease`.
- The Linux Docker prepublication job must pass before the Windows publication job can run.
- The publication job stamps a staged copy of the manifest from the tag, publishes with
  `PSGALLERY_API_KEY`, and creates or updates the corresponding GitHub prerelease.
- A stable tag selects `publish-stable`, but stable promotion always requires its own explicit authority.

`workflow_dispatch` remains an operational fallback for `dry-run`, `publish-prerelease`,
`publish-stable`, or `promote-prerelease`. It is not required for the normal tag-push prerelease path.

## Required GitHub Actions Secret

| Secret | Purpose | Current operational fact |
| --- | --- | --- |
| `PSGALLERY_API_KEY` | Authenticates `Publish-Module` against PSGallery | Present in repository Actions secrets as of 2026-05-18; rotate without exposing its value |

The repository may still contain `SIGNING_CERT_BASE64` and `SIGNING_CERT_PASSWORD`. They are historical
credentials from the removed Authenticode path and are not consumed by current PSGallery publication.

## Prerelease Publication Procedure

1. Merge the approved release PR through the protected branch after all required checks and review pass.
2. Confirm the merge commit is the intended release source and the worktree is clean.
3. Create the approved prerelease tag, for example `v0.40.0-beta2`, at that exact commit and push the tag once.
4. Observe **Publish Specrew module**. Stop on any prepublication, stamping, publication, or GitHub-release
   failure; do not retry or move the tag without a new diagnosis and explicit authority.
5. Record the immutable tag, workflow run URL/ID, and the visible PSGallery listing as release evidence.
6. Verify the published version from a fresh PowerShell process:

   ```powershell
   Find-Module Specrew -Repository PSGallery -RequiredVersion 0.40.0-beta2 -AllowPrerelease
   ```

Publication of a prerelease does not authorize a stable tag or promotion.

## PSGallery API Key Rotation

### Cadence

- Review or rotate annually at the key-creation anniversary.
- Rotate immediately when maintainer ownership changes, exposure is suspected, or authentication fails
  unexpectedly.

### Procedure

1. Generate a PSGallery key scoped to the Specrew module with an appropriate expiry.
2. Replace `PSGALLERY_API_KEY` in repository Actions secrets without logging or copying its value into evidence.
3. Use the workflow's manual `dry-run` mode to validate the staged release path without a live publication.
4. Revoke the old key only after the replacement path succeeds.

## Historical Signing Material

Proposal 072 removed Authenticode signing from current publication. Do not rotate or test the retained signing
secrets as part of a normal release. Reintroducing signing requires a separately approved proposal and updated
workflow contract.
