# Workflow Job Dependencies: Skipped Lanes as Unverified State

**Date**: 2026-05-20  
**Requested by**: Alon Fliess  
**Context**: Feature 024 Iteration 001 (retro-complete)  
**Scope**: Team learning — validation methodology, CI design  

---

## The Issue

Workflow job dependencies can mask unverified lanes as clean. When a job is conditionally skipped (e.g., `if: needs.previous_job.result == 'success'`), the job does not run, and the workflow *reports it as skipped*, not failed. To an observer, "skipped" reads as benign status—the job was not applicable or intentionally bypassed. In reality, a skipped job might represent a lane of testing or validation that was never executed because its dependency failed or was never queued.

**The risk**: A green workflow checkmark can hide unexecuted verification lanes. A partial test suite or incomplete validation gate can be silently skipped while upstream logic appears to succeed.

## Proposal 045 Implication

Proposal 045 (governance enhancement) should treat skipped checks as suspect rather than green. When a workflow marks a job as skipped due to a dependency, the workflow status should either:

1. Propagate the dependency failure up, marking the workflow as failed/incomplete (not green), **or**
2. Record the skipped job as "unverified" in the workflow summary, preventing the workflow from claiming full success.

A workflow with skipped verification lanes cannot truthfully claim that all required checks passed. It can only claim that *executed* checks passed and that *some checks did not run*. That is not the same as "green" in a trust model.

## Team Action

When designing workflow job dependencies, validation gates, or CI checks:

1. **Audit conditional skips**: For each job with a `needs` condition or `if` guard, verify that skipping the job is appropriate when the dependency is incomplete. If the job represents a required validation lane, failure to run it should fail the workflow, not skip it.

2. **Distinguish skip-by-design from skip-by-unavailability**: A job can be intentionally skipped on certain branches (skip-by-design). A job that fails to run because its dependency failed is unverified (skip-by-unavailability). These have different meanings in a verification model.

3. **Preserve verification completeness**: When a feature or iteration relies on a CI gate to verify readiness, ensure the gate measures *actual verification*, not *attempted verification*. An "all checks passed" signal from a workflow with skipped lanes is unreliable.

4. **Document job dependency rationale**: For each conditional job, record whether the skip is acceptable (cosmetic change skips test suite) or problematic (required security scan skipped due to dependency failure). Make the rationale visible to reviewers and downstream users of the workflow status.

## Evidence Base

- Feature 024 Iteration 001: Observed that workflow lanes with conditional dependencies can report success while skipping actual verification steps.
- Related to earlier learning (scribe-validation-scope.md): Local validation was scoped narrowly while CI validated broadly; analogous pattern where workflow lanes present an incomplete picture.

## Cross-References

- Proposal 045: Governance enhancement for check-result truthfulness
- Feature 024 Iteration 001 retro: Form-vs-meaning principle applied to validation
- Known-traps corpus: Add "workflow skipped-job gotcha" entry for future validation design

---

*Captured for team-wide access. No lifecycle artifacts reopened.*
