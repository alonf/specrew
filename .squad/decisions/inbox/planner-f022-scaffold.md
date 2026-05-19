# Planner Decision: Feature 022 Scaffold Repair

**Date**: 2026-05-18
**Feature**: 022-hotfix-schema-tests
**Decision Type**: Planning prerequisite repair

## Summary

Restored the missing Iteration 001 before-plan scaffold for Feature 022 without entering `/speckit.plan`.

## Decision

- Used `extensions/specrew-speckit/scripts/scaffold-iteration-plan.ps1` to create the initial `plan.md` stub.
- Did **not** use `scaffold-iteration-artifacts.ps1` for the remaining iteration-start artifacts because the helper failed on dry-run with the exact error:
  - `scaffold-iteration-artifacts.ps1: The property 'Count' cannot be found on this object. Verify that the property exists.`
- Created truthful minimal `state.md`, `drift-log.md`, and `quality/hardening-gate.md` scaffolds manually so the before-plan gate can be rerun against a real iteration-start artifact set.

## Impact

- Feature 022 now has the expected `iterations/001` scaffold.
- The planning ceremony remains unopened; these artifacts only repair the prerequisite boundary.
