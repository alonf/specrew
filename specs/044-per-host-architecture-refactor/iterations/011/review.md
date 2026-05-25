# Review: Iteration 011

**Schema**: v1
**Reviewed**: 2026-05-25
**Overall Verdict**: accepted

**Feature**: F-044 Per-Host Architecture Refactor

## Outcome Summary

**APPROVED** — all 5 tasks closed. Interactive host-selection menu now defaults to the highest-priority installed host per the priority order Claude → Codex → Copilot → Antigravity. `--host` flag non-interactive default remains `copilot` for CI/automation predictability (user-chosen two-defaults Option 1).

## Task Verdicts

| Task | Requirement | Verdict | Notes |
| ---- | ----------- | ------- | ----- |
| T001 | FR-011 | pass | 4 manifests gain `MenuPriority` field (claude=1, codex=2, copilot=3, antigravity=4). Copilot manifest comment notes `--host` flag default is independent |
| T002 | FR-011 | pass | `_registry.ps1` sort changed from alphabetical to `Sort-Object Priority, Kind` (priority-first, kind tie-break). Default priority 999 for missing field |
| T003 | FR-013 | pass | Updated Test 1 expected order; new Test 1b asserts all 4 hosts declare expected MenuPriority values. 15/15 assertions PASS |
| T004 | FR-012 | pass | README + getting-started + user-guide explain the two-defaults model. Markdownlint clean |
| T005 | FR-012 | pass | iter-011 artifacts + final lint + commit + push |

## Gap Ledger

- No in-scope requirement (FR/SC) gaps: all user-surfaced concerns closed: fixed-now. (Future enhancement candidates — unique-priority validator rule, unified single-default model — are deliberately out-of-scope; iter-011 implements user-specified Option 1 precisely.)

## Verification Evidence

```text
=== iter-011 verification ===
PASS host-registry.tests.ps1: 15 assertions
  - Test 1: Registry discovers all 4 hosts in MenuPriority order (claude, codex, copilot, antigravity)
  - Test 1b: All 4 hosts declare correct MenuPriority (claude=1, codex=2, copilot=3, antigravity=4)
  - Tests 2-15: existing assertions all still pass
PASS Direct invocation: Get-RegisteredHostKinds returns [claude, codex, copilot, antigravity] in priority order
PASS Markdownlint: 0 violations across README + getting-started.md + user-guide.md
PASS Validator (governance): iter-011 directory passes canonical-schema lens
```

## Real-world verification (deferred to user)

The canonical empirical test for iter-011 is whether the user's next `specrew start` (in a fresh greenfield project with multiple hosts installed) sees Claude as `[default 1]` in the menu — confirming both the priority order and the empirical methodology-rigor mapping from the cross-host smoke test.

## Sign-off

Approved for iteration-closeout. iter-011 is a tight bug-fix slice ready to join PR #844.
