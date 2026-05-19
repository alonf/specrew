# Contract: Closeout Identity State

**Contract Version**: 1.0.0  
**Feature**: 022-hotfix-schema-tests  
**Effective Boundary**: Plan-complete / pre-implementation

## Overview

This contract defines the required closeout identity output for `.squad/identity/now.md` so the file remains readable to humans and consumable by the existing session-state parser.

## Required Frontmatter

The closeout identity artifact must preserve its human-facing fields and also emit:

- `updated_at`
- `focus_area`
- `active_issues`
- `session_state_active`
- `session_state_boundary`
- `session_state_feature`
- `session_state_feature_path`
- `session_state_iteration`
- `session_state_task`
- `session_state_auth_commit`
- `session_state_recorded_at`

## Behavioral Rules

1. The same file must satisfy both human-readable and machine-readable consumers.
2. Feature 022 scope for schema parity is limited to `.squad/identity/now.md`.
3. Feature-closeout may mark the feature inactive, but the recorded boundary must remain parseable.
4. Human-readable body content must remain substantive and must not collapse into a machine-only template.
5. The parser path used by stale-state validation must not require a special-case closeout parser.

## Validation Contract

- `tests/integration/closeout-identity-schema-parity.tests.ps1` is the planned regression script for FR-004.
- The test must prove the parser can read the closeout output and that a human can still understand the closeout summary.
- Any incompatible change to the closeout identity frontmatter must fail the regression suite clearly.
