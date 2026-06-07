---
proposal: 171
title: CI Wire User-Profile Intake Integration Tests
status: candidate
phase: phase-2
estimated-sp: 2-4
priority-tier: 2
type: test-integrity-small-fix
discussion: surfaced 2026-06-07 during Proposal 170 review; P170 assertions were added to a local-only integration test file that is not wired into CI
composes-with:
  - 030  # Quality Hardening Bundle
  - 141  # Crew Interaction Profile / Persona Lens Separation
  - 145  # Structured reviewer evidence discipline
audience: maintainers, CI owners
---

# CI Wire User-Profile Intake Integration Tests

## Why

Feature 172 added Proposal 170 assertions to
`tests/integration/f049-i003-intake-engine-tests.ps1`, proving the new
Crew Interaction Profile setup metadata and input normalization locally.

Review found a pre-existing inert-test pattern: the whole integration file is
not wired into any CI workflow. That means 172's new assertions are useful
local evidence but do not automatically protect the branch in CI.

This should not block 172 because the gap predates the feature and 172 did not
worsen it. It should be filed rather than fixed blindly because some integration
tests in this area are Windows-coupled, and blind CI wiring can break
multi-host/Linux validation.

## What

Add CI coverage for the user-profile/intake integration suite, but only after a
Linux-safety check decides whether the existing file is portable or needs a
Windows-only job lane.

Implementation shape:

1. Audit `tests/integration/f049-i003-intake-engine-tests.ps1` for Windows-only
   assumptions.
2. Run it on Windows and Linux locally or in CI dry-run where available.
3. If portable, add it to the existing integration CI workflow.
4. If Windows-coupled, wire it to a Windows lane and record the portability
   blocker as a follow-up.
5. Add a CI-level assertion or workflow grep so future integration test files
   cannot remain silently local-only when used as review evidence.

## Acceptance Criteria

- **AC1**: The proposal-to-spec conversion includes a Linux-safety audit before
  CI wiring.
- **AC2**: The suite runs in CI on the correct OS lane and fails the check if
  P170 assertions regress.
- **AC3**: Any Windows-only coupling is documented with a concrete reason and a
  follow-up if portability is deferred.
- **AC4**: Review evidence distinguishes local-only test runs from CI-reached
  test runs.
- **AC5**: A future feature that adds assertions to local-only integration tests
  is warned or blocked before review-signoff.

## Out Of Scope

- Rewriting the intake engine test suite.
- Making every historical integration test cross-platform in this slice.
- Changing Proposal 170 behavior.
- Treating the pre-existing local-only status as a blocker for Feature 172.

## Effort

Estimated 2-4 SP:

| Work item | Estimate |
| --- | --- |
| Linux-safety audit and local smoke | 0.5-1 SP |
| CI workflow wiring | 0.5-1 SP |
| Inert-test detector or workflow assertion | 0.75-1.5 SP |
| Documentation/evidence updates | 0.25-0.5 SP |

## Status History

- 2026-06-07: Created from maintainer review note on Feature 172.
