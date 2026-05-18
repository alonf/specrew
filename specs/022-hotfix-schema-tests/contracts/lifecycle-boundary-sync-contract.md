# Contract: Lifecycle Boundary Sync

**Contract Version**: 1.0.0  
**Feature**: 022-hotfix-schema-tests  
**Effective Boundary**: Plan-complete / pre-implementation

## Overview

This contract defines the ordered synchronization behavior required across the seven lifecycle boundaries.

## Required Boundaries

The system must emit consistent synchronization state for:

1. `specify`
2. `clarify`
3. `plan`
4. `tasks`
5. `review-signoff`
6. `iteration-closeout`
7. `feature-closeout`

## Behavior Contract

1. Each boundary must update the state surfaces used by restart validation.
2. `.squad/decisions.md` must receive one ordered `Boundary sync:` entry per boundary.
3. The persisted `auth_commit_hash` must be durable and must not remain the literal value `HEAD`.
4. Late-boundary sync failures must remain observable to restart validation or lifecycle evidence review.
5. Feature-closeout may clear `.specify/feature.json` only after the state surfaces have been synchronized.

## Validation Contract

- `tests/integration/lifecycle-boundary-sync.tests.ps1` is the planned regression script for FR-009.
- The script must simulate all seven boundaries in order and verify the ordered ledger history.
- The script must also prove that missing or misplaced late-boundary synchronization remains visible rather than silently passing.
