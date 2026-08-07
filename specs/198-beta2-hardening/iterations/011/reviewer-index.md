# Reviewer Index: Iteration 011

**Schema**: v1
**Reviewed**: 2026-08-06
**Overall Verdict**: needs-rework

## Summary

- Header: feature=198-beta2-hardening | iteration=011 | branch=198-beta2-hardening | commit_range=d7f27f6a..dc427cbfd1f11c3cd31f512313adb747702ead02
- Verdict: needs-rework
- Requirements: covered=FR-068, FR-066, FR-018 | not_covered=(none)
- Code Surface: files=24 | hotspots=6 | test_to_code=8:5
- Dependencies: changed=0 | new_to_project=0 | vulnerability=unscanned
- Coverage: kind=qualitative | signal=focused_regression
- Operational Signals: escalations=0 | routing_fallbacks=0
- Drift: 0/0 resolved
- Reviewer Index: specs\198-beta2-hardening\iterations\011\reviewer-index.md
- Implementation Briefing: (unavailable)
- Local Open Hints: specs\198-beta2-hardening\iterations\011\reviewer-index.md; specs\198-beta2-hardening\iterations\011\review-diagrams.md; specs\198-beta2-hardening\current-architecture.md

## Read Order

1. [review.md](review.md)
2. [code-map.md](code-map.md)
3. [dependency-report.md](dependency-report.md)
4. [coverage-evidence.md](coverage-evidence.md)
5. security-surface.md omitted: No security-focused team role and no security-keyword task title were found in the iteration plan.
6. [dashboard.md](dashboard.md)
7. [review-diagrams.md](review-diagrams.md)
8. [..\..\current-architecture.md](..\..\current-architecture.md)
9. Implementation briefing unavailable for this iteration

## Artifact Links

- [review.md](review.md)
- [code-map.md](code-map.md)
- [dependency-report.md](dependency-report.md)
- [coverage-evidence.md](coverage-evidence.md)
- security-surface.md omitted: No security-focused team role and no security-keyword task title were found in the iteration plan.
- [dashboard.md](dashboard.md)
- [review-diagrams.md](review-diagrams.md)
- [..\..\current-architecture.md](..\..\current-architecture.md) *(mutable current view)*
- Implementation briefing unavailable
- [.squad\decisions.md](.squad\decisions.md)

## Triage Hints

- Hotspot: .specify/extensions/specrew-speckit/scripts/shared-governance.ps1 (308 changed lines)
- Hotspot: extensions/specrew-speckit/scripts/shared-governance.ps1 (308 changed lines)
- Hotspot: specs/198-beta2-hardening/iterations/011/drift-log.md (1080 changed lines)
- Hotspot: specs/198-beta2-hardening/iterations/011/plan.md (461 changed lines)
- Hotspot: specs/198-beta2-hardening/iterations/011/retro.md (252 changed lines)
- Hotspot: tests/integration/fr068-verdict-demand-reproduction.tests.ps1 (346 changed lines)
- Vulnerability scan: unscanned (No manifest files changed in this iteration.)
- Gap concern: FR-068 evidence half — tree-bound stage evidence, fail-closed unverifiable reasons, strict clarify matcher; validated by round 2 and unchanged since: fixed-now.
- Gap concern: FR-066 arrival state — an unrecordable crossing is distinguishable and the surface names what is missing: fixed-now.
- Gap concern: FR-066 mint guard — NOT delivered; two designs faulted at design level and reverted; enters beta3 as a design spike whose deliverable is the concurrency/failure matrix, priced before implementation. Approved under the named-limitation tag-basis ruling of 2026-08-06: deferred.
- Gap concern: SC-025 composition clause (T091) — scoped to beta3's hook-machinery cluster by the authorized specify touch of 2026-08-03; observed CONSEQUENTIAL in this session's own Stop blocks: deferred.
- Gap concern: T093 campaign-mode halt text — relief valve fired at T090's re-estimate, carried to beta3's first row: deferred.
- Gap concern: DRIFT-198-I011-009 atomic writer succeeds onto a directory destination — shared machinery, every governance writer inherits it: deferred.
- Gap concern: DRIFT-198-I011-002 preflight burns the full timeout, and the `allowance-reset` naming/reachability gap — one beta3 remediation-surface row: deferred.
- Gap concern: DRIFT-198-I011-001 unregistered suite invisible to CI: deferred.

## Replay Digest

SPECREW_REVIEW schema=v1 iter=011 feature=198-beta2-hardening verdict=needs-rework tasks=5/8 reqs=8 files=24 new_deps=0 vuln=unscanned cov=focused_regression escalations=0 drift=0/0 index=specs\198-beta2-hardening\iterations\011\reviewer-index.md
