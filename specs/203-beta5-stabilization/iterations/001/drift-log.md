# Drift Log: Iteration 001

**Schema**: v2

## Summary

**Total drift events**: 2 (DRIFT-001 to DRIFT-002)
**Resolution rate**: 2 of 2 handled locally; both carry an open product class for the backlog
**Specification drift**: 0

## Events

### DRIFT-001 — the quality-profile resolver read the stack as Node plus a browser SPA (observation, recurring)

- **Observed**: 2026-10-31, plan stage, `resolve-quality-profile.ps1 -ProjectPath .`. The resolver matched the
  presets `node-rest-with-postgres` (score 90) and `react-spa-public` (score 80), declared stack surfaces "Node.js
  http-api" and "TypeScript browser-spa", and marked concurrency-correctness, resiliency and
  retry-idempotency-and-recovery not-applicable. The repository's product is a PowerShell module with host hooks.
  202's plan recorded the same misreading on 2026-10-13.
- **Requirement**: the plan's quality planning inputs (before-plan step 3); spec FR-042, FR-043 depend on the
  concurrency and retry dimensions being required.
- **Resolution**: corrected by hand in plan.md, "Quality plan (resolved profile, corrected)": stack surfaces
  replaced, and the three dimensions made required with rationale. Recorded at the maintainer's plan verdict.
- **Class closure**: OPEN — the resolver will misread the next feature in this repository too. Backlog candidate:
  the resolver should weigh the repository's own module manifest and language mix over preset keyword matches,
  and say when its reading is low-confidence.

### DRIFT-002 — the agent-context script removed an unrelated line from .github/copilot-instructions.md (observation)

- **Observed**: 2026-10-31, plan stage, `.specify/scripts/powershell/update-agent-context.ps1 -AgentType copilot`.
  The script changed the "Last updated" date and removed the `046-create-spec-branch` entry from the recent-changes
  list, leaving a stray blank line. It added no 203 technology, because the stack is unchanged.
- **Requirement**: none of 203's; a generated surface changed outside the feature's scope.
- **Resolution**: reverted with `git checkout -- .github/copilot-instructions.md` before the plan commit; the file
  is unchanged in 203's history. Recorded at the maintainer's plan verdict.
- **Class closure**: OPEN — the B4F-111 family (generated-surface churn and ordering). Backlog candidate: the
  agent-context update must not drop existing entries, and a no-new-technology run should leave the file
  untouched.
