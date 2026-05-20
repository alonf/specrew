# Bug-Fix Specification: PSGallery Unsigned Default

**Branch**: `proposal-072-unsigned-default`  
**Created**: 2026-05-20  
**Status**: Implemented  
**Input**: Human-directed bug-fix slice for the `v0.24.1` Authenticode-signing failure

## Problem Statement

Specrew `0.24.0` published signed module artifacts with a self-signed certificate. PowerShell rejected the signed manifest on install because the certificate chain terminated at an untrusted root, making the PSGallery package unusable.

## Clarify

- Skipped: Bug-fix slice; diagnosis + fix pre-resolved by human prior to handoff; nothing material to clarify.

## Scope

- Remove Authenticode signing from the live PSGallery release path.
- Keep release stamping, staged-manifest validation, and PSGallery publish mode routing intact.
- Bump the product/version surfaces to `0.24.1`.
- Record the shipped bug-fix in `CHANGELOG.md`, `proposals/072-psgallery-unsigned-default.md`, and `proposals/INDEX.md`.

## Acceptance Criteria

1. `.github/workflows/publish-module.yml` no longer passes signing secrets or signing flags into the release script.
2. `scripts/internal/invoke-module-release.ps1` no longer imports, generates, or applies Authenticode signatures in the live release path.
3. `Specrew.psd1`, `.specrew/config.yml`, `extensions/specrew-speckit/extension.yml`, and `.specify/extensions/specrew-speckit/extension.yml` align on version `0.24.1`.
4. `CHANGELOG.md` records `0.24.1` as the unsigned-default bug-fix release and reopens an empty `Unreleased` section.
