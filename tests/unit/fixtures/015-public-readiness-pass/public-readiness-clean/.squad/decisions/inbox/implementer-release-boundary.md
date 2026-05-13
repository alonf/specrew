# Implementer Decision: Feature 015 release-boundary handling

**Date**: 2026-05-13  
**By**: Implementer  
**Type**: release-boundary

## Decision

For Feature 015 Iteration 002 release-truth work, retroactive tags are created
only when the target tag name is absent. If `v0.13.0` or `v0.14.0` already
exists locally or remotely, implementation reports the duplicate as
advisory-only and preserves the existing tag target without any rewrite.

## Why It Matters

- This keeps FR-010 aligned with the no-force / no-history-rewrite constraint.
- It preserves historical documentary value for retroactive tags.
- It gives future release work a concrete rule for duplicate-tag scenarios.
