# Code Map: Iteration 008

**Feature**: F-044 | **Iteration**: 008 — Closeout Documentation + 2-Iteration Calculator Walkthrough + Three-Section Handoff Format Regression Fix

## Production code touched (canonical templates — deployed to downstream projects on `specrew init`/`specrew start`)

| File | Change | Why |
|---|---|---|
| `extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md` | Rule 14A: replaced one-line three-section directive with full canonical template + welcoming-tone mandate. New paragraph distinguishing boundary-stop handoffs from in-flight progress updates | T006 — three-section format regression fix; restore structural prominence |
| `extensions/specrew-speckit/squad-templates/agents/spec-steward/charter.md` | New `### Boundary handoff format (Feature 016 Pillar 1)` subsection in How I Work | T007 — was 0 of 5; now 1 |
| `extensions/specrew-speckit/squad-templates/agents/planner/charter.md` | Same subsection | T007 — was 0 of 5; now 2 |
| `extensions/specrew-speckit/squad-templates/agents/reviewer/charter.md` | Same subsection | T007 — was 0 of 5; now 3 |
| `extensions/specrew-speckit/squad-templates/agents/retro-facilitator/charter.md` | Same subsection | T007 — was 0 of 5; now 4 |
| `extensions/specrew-speckit/squad-templates/agents/implementer/charter.md` | Same subsection added explicitly (previously only mentioned format incidentally via Proposal 082 commit-discipline section) | T007 — was 1 of 5 incidental; now 5 of 5 explicit |
| `.specify/extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md` | Same as canonical | T006 — mirror discipline |
| `.specify/extensions/specrew-speckit/squad-templates/agents/{5 charters}/charter.md` | Same as canonical | T007 — mirror discipline |

## Documentation touched

| File | Change | Why |
|---|---|---|
| `README.md` | "What's working today" lifecycle bullet extended with closeout explanation + link to user-guide section | T001 — closeout documentation |
| `docs/getting-started.md` | New Step 5 "Close the iteration (and the feature)" — verdict shapes + closeout-vs-pause distinction | T002 — closeout documentation |
| `docs/user-guide.md` | Three new major sections: "What you'll see at every boundary" (T008), "Closing iterations + features" (T003), "Walkthrough: a two-iteration calculator" (T004) | T003 + T004 + T008 |

## Iteration artifacts produced

- `iterations/008/plan.md` (authored at iter-008 start; updated mid-iteration with T006/T007/T008 expansion; finalized at close)
- `iterations/008/state.md` (canonical-schema end-of-iteration summary)
- `iterations/008/scope.md` (bug-by-bug closure + Proposal 109 candidate out-of-scope note)
- `iterations/008/drift-log.md` (drift #1 mid-iteration expansion; drift #2 `.specify/` mirror discipline)
- `iterations/008/code-map.md` (this file)
- `iterations/008/review.md` (task verdicts + verification evidence)
- `iterations/008/retro.md` (canonical-schema retro: Estimation Accuracy + Phase Variance + Drift Summary + Improvement Actions + What Went Well + What Didn't Go Well + Methodology Lessons + Carry-Over + Velocity)

## Tests run + verdicts

- Markdownlint: 0 violations across all 14 touched files (3 docs + 5 canonical charters + 1 governance + 5 .specify/ mirror charters + 1 .specify/ mirror governance — wait, that's 15 — checking... actually 3 + 6 + 6 = 15. Counting once each: README, getting-started, user-guide, governance canonical, 5 charters canonical, governance .specify, 5 charters .specify, plus 7 iter-008 artifacts = 22 files total; all clean)
- Validator (governance): iter-008 directory passes canonical-schema lens

## What this iteration did NOT change

- No production .ps1 code (only template + docs files)
- No tests added (the validator + markdownlint sweep are the tests)
- No proposal status changes (Proposal 109 candidate ships as separate commit to main)
- No INDEX.md changes (proposals commit to main only)
