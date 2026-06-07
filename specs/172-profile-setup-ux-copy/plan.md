# Implementation Plan: New-User Profile Setup Copy

**Branch**: `172-profile-setup-ux-copy`
**Spec**: `spec.md`
**Proposal**: `proposals/170-new-user-profile-setup-copy.md`
**Status**: implementing

## Scope

This is a small onboarding-copy slice. It changes only the first-run Crew
Interaction Profile setup surface plus targeted tests and traceability.

## Technical Approach

- Keep the existing Crew Interaction Profile metadata as the canonical schema
  and display contract.
- Add setup-only metadata fields:
  - `SetupLabel`
  - `SetupQuestion`
- Add a small `Normalize-CrewInteractionProfileSetupInput` helper for testable
  first-run input parsing.
- Update `Prompt-UserProfileSetup` to:
  - tell new users Enter means recommended defaults;
  - explain scale values as Specrew behavior;
  - ask guidance-oriented questions;
  - show the canonical `DisplayLabel` as the profile area.
- Extend the existing F-049/F-141 integration suite with producer-consumer
  assertions against the setup metadata and normalizer.

## Risks

- Accidentally renaming persisted keys would break existing profiles. The
  implementation avoids this by adding metadata only and by pinning the existing
  labels/keys in tests.
- Manual prompt copy is hard to test end to end because `Read-Host` is
  interactive. The testable surface is the metadata and normalization helper;
  the prompt consumes those values directly.

## Validation

- `pwsh -NoProfile -ExecutionPolicy Bypass -File tests/integration/f049-i003-intake-engine-tests.ps1`
- `npx --yes markdownlint-cli --config .markdownlint.json proposals/170-new-user-profile-setup-copy.md specs/172-profile-setup-ux-copy/spec.md specs/172-profile-setup-ux-copy/plan.md specs/172-profile-setup-ux-copy/tasks.md specs/172-profile-setup-ux-copy/iterations/001/plan.md specs/172-profile-setup-ux-copy/iterations/001/state.md specs/172-profile-setup-ux-copy/iterations/001/drift-log.md`
