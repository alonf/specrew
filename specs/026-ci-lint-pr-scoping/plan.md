# Implementation Plan: PR Lint Scoping

**Branch**: `026-ci-lint-pr-scoping` | **Date**: 2026-05-20 | **Spec**: [spec.md](spec.md)

## Summary

Scope pull-request validation to only changed iterations, reducing CI latency without sacrificing governance coverage. Single deliverable bundle: `-ChangedOnly` switch parameter, `Get-ChangedIterations` helper function, workflow conditional logic, integration test, and changelog entry.

## Structure

### Single Phase: PR Lint Scoping (Chore)

**Goal**: Modify `extensions/specrew-speckit/scripts/validate-governance.ps1` and `.github/workflows/specrew-ci.yml` to scope PR validation to changed iterations only. On PR events: compute changed files via `git diff --name-only --diff-filter=d base..head`, identify touched `specs/*/iterations/<N>/` directories, include global state checks (`.specrew/`, `.squad/identity/`, `.specify/feature.json`), and skip full `specs/` tree scan. On push-to-main: full-repo validation unchanged.

**Deliverables**:

- `-ChangedOnly` switch parameter in `extensions/specrew-speckit/scripts/validate-governance.ps1`
- `Get-ChangedIterations` helper function (compute changed files, identify touched iteration paths, include global-state surfaces)
- Workflow conditional in `.github/workflows/specrew-ci.yml` (if pull_request, pass `-ChangedOnly`; if push to main, omit)
- Integration test in `tests/integration/validate-governance-changed-only.tests.ps1` (prove touched-iteration-only behavior + global-state inclusion + unscoped regression guard)
- Changelog entry in `CHANGELOG.md`

**Validation**:

- Integration test verifies scoped validation runs only on changed iteration directories
- Unscoped regression guard ensures unmodified iterations are not validated in PR path
- Push-to-main workflow retains full-repo validation (unchanged truth-check)

## Dependency Notes

- No external dependencies on prior features
- Validation infrastructure (`validate-governance.ps1`) already present
- Git CLI available for `git diff` computation
- Validation lane: single integration test covers full scoping contract

## Scope Boundaries

**In scope**:

- `-ChangedOnly` switch parameter in `validate-governance.ps1`
- `Get-ChangedIterations` helper function (surface enumeration for changed iterations)
- Workflow YAML conditional in `specrew-ci.yml` (if pull_request, pass `-ChangedOnly`; if push, full-repo)
- Integration test proving touched-iteration-only behavior + global-state inclusion + unscoped regression guard
- Changelog entry

**Unchanged**:

- Push-to-main full-repo validation (no changes to full path)

**Deferred** (per spec):

- No proposal entry, no INDEX update, no version bump
