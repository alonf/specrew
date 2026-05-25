# Review: Iteration 005

**Schema**: v1
**Reviewed**: 2026-05-24
**Overall Verdict**: accepted

**Feature**: F-044 Per-Host Architecture Refactor

## Outcome Summary

**APPROVED** — all 8 tasks closed; antigravity launch shape verified against `agy --help`; v0.27.0 bump complete with CHANGELOG entry; 3 new regression test files cover iter-003 + iter-004 + iter-005 changes; doc sweep removes stale 3-host language and adds F-043/F-044 entries.

## Task Verdicts

| Task | Requirement | Verdict | Notes |
| ---- | ----------- | ------- | ----- |
| T001 | FR-003, FR-007 | pass | Antigravity launch now `agy -i <prompt> --add-dir <path>` with `--dangerously-skip-permissions` mapping. Verified by `host-detection-ux.tests.ps1` Test 6. |
| T002 | (release) | pass | ModuleVersion 0.27.0 + CHANGELOG entry documenting F-043 + F-044's 5-iteration arc + versioning-drift note. |
| T003 | FR-013 | pass | `host-detection-ux.tests.ps1` ships 7 assertions; all pass. |
| T004 | FR-013 | pass | `post-bootstrap-output.tests.ps1` ships 5 assertions; all pass. |
| T005 | FR-013 | pass | `skill-templates.tests.ps1` ships frontmatter assertion across 11 templates; all pass. |
| T006 | FR-012 | pass | README + getting-started + user-guide updated; 4-host language consistent; F-043/F-044 in roadmap; baseline bumped to v0.27.0. |
| T007 | (docs) | pass (deferred) | INDEX.md verified to lack the entries; deferred to post-PR-merge chore per "proposals always commit to main" policy. Captured in [drift-log.md](./drift-log.md). |
| T008 | (verify) | pass | All 7 host-related test suites green. |

## Gap Ledger

- No in-scope requirement (FR/SC) gaps: all 5 user-surfaced concerns closed: fixed-now. T007 INDEX.md entries are scheduled as an on-main post-PR-merge chore per the "proposals always commit to main" rule — not a feature-branch gap.

## Verification Evidence

```text
=== Antigravity launch invocation ===
Binary: agy
Args:   -i 'test prompt' --add-dir 'C:\test\proj' --dangerously-skip-permissions

=== Test suites (7) ===
PASS host-registry.tests.ps1
PASS crew-bootstrap-contract.tests.ps1
PASS host-coupling-firewall.tests.ps1
PASS multi-host-launch-path.tests.ps1
PASS host-detection-ux.tests.ps1 (new, 7 assertions)
PASS post-bootstrap-output.tests.ps1 (new, 5 assertions)
PASS skill-templates.tests.ps1 (new, 1 assertion across 11 templates)
```

## Sign-off

Approved for iteration-closeout AND for the F-043 + F-044 bundled PR-to-main. User's antigravity-on-WSL dogfood is the canonical functional review boundary for this iteration's launch fix.
