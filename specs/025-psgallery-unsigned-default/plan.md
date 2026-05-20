# Implementation Plan: PSGallery Unsigned Default

**Branch**: `proposal-072-unsigned-default` | **Date**: 2026-05-20 | **Spec**: [spec.md](spec.md)

## Summary

Execute the pre-resolved `v0.24.1` release-path bug fix by removing Authenticode signing from the active PSGallery publish flow, aligning the version surfaces to `0.24.1`, and recording the shipped slice in the changelog/proposal artifacts.

## Validation

- Run the release script in `dry-run` mode to confirm staged stamping + summary output still work without signing.
- Run the scoped release integration script for `invoke-module-release.ps1`.
