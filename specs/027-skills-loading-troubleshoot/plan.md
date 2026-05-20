# Implementation Plan: Skills-Loading Warning Documentation + Proposal 072 Cleanup

**Branch**: `027-skills-loading-troubleshoot` | **Date**: 2026-05-20 | **Spec**: [spec.md](spec.md)

## Summary

Deliver two bounded documentation fixes: a user-guide troubleshooting note for the benign Copilot CLI skills-loading warning, and a Proposal 072 / PSGallery credentials cleanup that removes dead references and marks the removed signing flow as historical.

## Deliverables

- Add a Troubleshooting subsection to `docs/user-guide.md` describing the upstream Copilot CLI warning, the reason it appears, and how to confirm Specrew's own skills loaded.
- Apply Option B for Proposal 072 by removing dead references to `SIGNATURE_VALIDATION_ROOT_CAUSE_ANALYSIS.md`.
- Update `docs/operations/psgallery-release-credentials.md` so only the active PSGallery API key flow is described as current, while the removed signing flow remains as historical context.
- Record the clarify skip rationale in `.squad/decisions.md`.
- Create minimal slice artifacts: `spec.md`, `plan.md`, `tasks.md`, and `retro.md`.

## Validation

- Run `markdownlint` on every markdown file touched by the slice.
- Verify no skill deployment code, skill manifests, or `SKILL.md` content changed.
- Confirm Proposal 072 no longer points at the missing analysis file.

## Option Decision

Option B applies. The untracked `SIGNATURE_VALIDATION_ROOT_CAUSE_ANALYSIS.md` working artifact contains more detail than Proposal 072, but preserving it in this slice would require disproportionate markdown repair for a 1-2 SP docs chore. Keeping Proposal 072 self-contained is the smaller and safer fix.
