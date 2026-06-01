# Current Architecture: 139-boundary-authorization-prompt-truth

**Source Iteration Ref**: 001
**Last Updated**: 2026-06-01T20:40:00Z
**Status**: release closed

## Summary

Feature 139 changes the generated Specrew lifecycle prompt and supporting governance validators so boundary stop guidance is derived from resolved policy, not beta2-era hard-coded assumptions. The generated future stop contract is the six-section human re-entry packet, and generated start context records the resolved `boundary_enforcement.policy_classes` snapshot.

## Runtime Flow

1. `scripts/specrew-start.ps1` loads boundary policy classes through shared governance helpers.
2. `specrew start` writes `start-context.json` with `boundary_enforcement.policy_classes`.
3. The generated prompt tells the coordinator to stop at human-judgment boundaries such as `clarify -> plan`.
4. The coordinator presents the six-section packet and accepts only explicit boundary approval.
5. Governance validation flags the narrow contradiction where an active feature says `Status: Approved` without human verdict evidence.

## Review Artifacts

- [review.md](file:///C:/tmp/Specrew-main-boundary-auth/specs/139-boundary-authorization-prompt-truth/iterations/001/review.md)
- [reviewer-index.md](file:///C:/tmp/Specrew-main-boundary-auth/specs/139-boundary-authorization-prompt-truth/iterations/001/reviewer-index.md)
- [code-map.md](file:///C:/tmp/Specrew-main-boundary-auth/specs/139-boundary-authorization-prompt-truth/iterations/001/code-map.md)
- [coverage-evidence.md](file:///C:/tmp/Specrew-main-boundary-auth/specs/139-boundary-authorization-prompt-truth/iterations/001/coverage-evidence.md)
- [security-surface.md](file:///C:/tmp/Specrew-main-boundary-auth/specs/139-boundary-authorization-prompt-truth/iterations/001/security-surface.md)
- [review-diagrams.md](file:///C:/tmp/Specrew-main-boundary-auth/specs/139-boundary-authorization-prompt-truth/iterations/001/review-diagrams.md)

## Release Evidence Boundary

Automated pre-publish beta3 smoke evidence was accepted for implementation review. Release closeout then enforced published-host replay before stable promotion: beta3 failed on D-007, beta4 failed on D-008, beta5 exposed D-009 before human replay, beta6 passed Step 11, and stable `v0.30.0` was promoted from `c745258c52c575f4704f4866d2b74b2f50381a5a`. The replay history is tracked in [beta3-smoke-evidence.md](file:///C:/tmp/Specrew-main-boundary-auth/specs/139-boundary-authorization-prompt-truth/smoke/beta3-smoke-evidence.md).
