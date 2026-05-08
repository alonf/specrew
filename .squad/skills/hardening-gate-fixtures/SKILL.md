---
name: "hardening-gate-fixtures"
description: "Build truthful hardening-gate fixture scenarios for blocked, approved-deferral, and ready contract coverage."
domain: "governance"
confidence: "high"
source: "earned"
---

## Context

Use this when Phase 2 fixture work needs deterministic hardening-gate scenarios before the final validator or orchestration path is fully implemented.

## Patterns

- Mirror the shipped hardening-gate schema exactly: metadata block plus `## Concern Review` table.
- Cover all required concern families in each scenario, not just the one that changes the verdict.
- For `blocked`, keep at least one blocking concern at `tbd`.
- For `approved-deferral`, add a canonical `.squad\decisions.md` entry with the same approval reference cited in the artifact.
- For `ready`, keep every blocking concern `addressed` or truthfully `not-applicable`.
- Update iteration lifecycle artifacts in the same change so fixture delivery status stays truthful.

## Anti-Patterns

- Creating an `approved-deferral` fixture without human approval evidence.
- Omitting concern rows and assuming later tests will infer them.
- Advancing later User Story 2 tasks while fixture-only work is still the active scope.
