---
proposal: 072
title: PowerShell Gallery Unsigned Default
status: shipped
phase: phase-2
estimated-sp: 2
shipped-as: bug-fix slice v0.24.1 (2026-05-20)
discussion: ad-hoc 2026-05-20 release-fix handoff
---

# PowerShell Gallery Unsigned Default

## Bug summary

Specrew `0.24.0` shipped to PowerShell Gallery with Authenticode signatures produced from a self-signed certificate. PowerShell treated the signed manifest as untrusted, so `Install-Module Specrew` failed before the module could be used.

## Root cause

The live release path in `.github/workflows/publish-module.yml` and `scripts/internal/invoke-module-release.ps1` always signed the staged module payload. The configured certificate source was self-signed and absent from customer trust stores, so signing converted an otherwise installable package into a failing one. The detailed diagnosis is recorded in `SIGNATURE_VALIDATION_ROOT_CAUSE_ANALYSIS.md`.

## Decision

For `v0.24.1`, remove Authenticode signing from the active PSGallery release path entirely and publish unsigned packages by default. The release workflow still stamps the manifest, validates the staged module, and performs the same dry-run/live publish branching, but it no longer imports certificates, generates fallback certificates, or signs `Specrew.psd1` / `Specrew.psm1`.

## Rationale

This bug-fix slice was pre-resolved by the human before handoff: the urgent need is to restore installability, not to re-open certificate strategy design. Unsigned packages are the safest immediate default because they remove the untrusted self-signed certificate failure without introducing any new trust-distribution requirement for users.

## Out of scope

- Procuring a CA-issued code-signing certificate
- Reintroducing optional signing paths in the live release workflow
- Broader release-process redesign beyond the PowerShell Gallery publish path
- Any tag/publish action for `v0.24.1` itself

## Cross-references

- `SIGNATURE_VALIDATION_ROOT_CAUSE_ANALYSIS.md`
- `CHANGELOG.md`
- `Specrew.psd1`
- `.github/workflows/publish-module.yml`
- `scripts/internal/invoke-module-release.ps1`
- `file:///C:/Dev/Specrew/proposals/031-specrew-distribution-module.md`
- `file:///C:/Dev/Specrew/proposals/055-always-in-flow-bug-fix-lifecycle.md`
- `file:///C:/Dev/Specrew/proposals/060-prerelease-channel-staging.md`
- `file:///C:/Dev/Specrew/proposals/067-small-fix-slice-type.md`
- `file:///C:/Dev/Specrew/proposals/INDEX.md`
