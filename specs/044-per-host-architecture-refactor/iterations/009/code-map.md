# Code Map: Iteration 009

**Feature**: F-044 | **Iteration**: 009 — Bare file:/// URI Enforcement (Smoke-Test Regression Fix)

## Production code touched (canonical templates — deployed to downstream projects)

| File | Change | Why |
|---|---|---|
| `extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md` | Rule 14A: explicit "BARE `file:///` URIs, NOT markdown-link form `[name](file:///...)`" mandate inside the canonical template + welcoming-tone block. 2 supporting bullets updated to say BARE | T001 — close wording gap |
| `extensions/specrew-speckit/squad-templates/agents/spec-steward/charter.md` | Existing What I just did bullet says BARE; new bold "Bare URI, not markdown link form" paragraph | T002 — close wording gap |
| `extensions/specrew-speckit/squad-templates/agents/planner/charter.md` | Same | T002 |
| `extensions/specrew-speckit/squad-templates/agents/reviewer/charter.md` | Same | T002 |
| `extensions/specrew-speckit/squad-templates/agents/retro-facilitator/charter.md` | Same | T002 |
| `extensions/specrew-speckit/squad-templates/agents/implementer/charter.md` | Same | T002 |
| `.specify/.../specrew-governance.md` | Same as canonical | T001 — mirror discipline |
| `.specify/.../agents/{5 charters}/charter.md` | Same as canonical | T002 — mirror discipline |
| `docs/user-guide.md` "What you'll see at every boundary" | Updated example block + new paragraph explaining bare-URI requirement + re-prompt guidance | T003 — user-facing docs |

## Iteration artifacts produced

- `iterations/009/plan.md` (authored at iter-009 start)
- `iterations/009/state.md` (canonical-schema end-of-iteration summary)
- `iterations/009/scope.md` (bug-by-bug closure)
- `iterations/009/drift-log.md` (no drift events)
- `iterations/009/code-map.md` (this file)
- `iterations/009/review.md` (task verdicts + verification evidence)
- `iterations/009/retro.md` (canonical-schema retro)
- `iterations/009/pr-review-resolution.md` (placeholder for Copilot PR review findings)

## Tests run + verdicts

- Markdownlint: 0 violations across 13 touched files
- Validator (governance): iter-009 directory passes canonical-schema lens

## What this iteration did NOT change

- No production .ps1 code (only template + docs text)
- No new tests added (the validator + markdownlint sweep + user smoke-test are the verification surface)
- No proposal status changes
- No INDEX.md changes
