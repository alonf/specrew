# Clarify-Residual Findings — Feature 017 Velocity Dashboard

**Source**: External pre-implementation review (Claude Code, in-session collaboration with maintainer)
**Captured at**: 2026-05-15
**Worktree**: `file:///C:/Dev/Specrew-017/`
**Reviewing against**: `file:///C:/Dev/Specrew-017/specs/017-velocity-dashboard/spec.md`
**Stage at capture**: post-clarify, post-plan, post-tasks, pre-implementation (Squad's planning-boundary work in working tree, not yet committed)

## Purpose

This file captures findings identified by an external reviewer during the clarify-to-implementation transition. The findings were NOT discovered by Squad during clarify — they survived the clarify boundary and are recorded here so the review boundary has an explicit checklist instead of relying on the reviewer's recall.

Some findings have been **resolved in progress** by Squad's planning artifacts (notably the `contracts/` directory created during `/speckit.plan`). The status notation distinguishes those from findings still requiring action.

Action expectations are non-binding suggestions. The reviewer at the next review boundary judges severity and disposition.

## Status conventions

- 🔴 **PENDING** — finding still applies; requires action before review-verdict acceptance
- 🟡 **PARTIAL** — Squad has addressed part of the finding via planning artifacts; verify completeness at review
- 🟢 **RESOLVED-IN-PROGRESS** — Squad addressed the finding during planning; verify at review and close

---

## Tier 1 — Process / durability

### T1-1 🟢 RESOLVED-IN-PROGRESS: Planning and repair artifacts are committed on the feature branch

The branch `017-velocity-dashboard` is at `de84fe9` (= main HEAD). Every artifact Squad has created — spec.md (42KB), plan.md (17KB), tasks.md (33KB), data-model.md, research.md, quickstart.md, three contracts files, plus uncommitted edits to `.github/copilot-instructions.md`, `.specify/feature.json`, and `proposals/009-velocity-dashboard.md` — lives in working tree only.

**Risk**: laptop interruption = full loss of clarify + planning work.

**Resolution**: Planning and implementation-repair artifacts are committed in boundary commit `9093f98`. Verify the commit captures everything in this worktree at review.

### T1-2 🟢 RESOLVED-IN-PROGRESS: Spec self-contradicted on lifecycle status

`file:///C:/Dev/Specrew-017/specs/017-velocity-dashboard/spec.md`:
- Line 5: `**Status**: Approved`
- Line 375: `planning authorization was granted at the Feature 017 planning boundary on 2026-05-15`
- Line 269 (TG-004): `this specification does not authorize planning, tasks, or implementation to begin automatically without the next explicit boundary decision.`

These three lines are mutually inconsistent. Squad's own handoffs during clarify said "waiting for planning authorization" while the spec self-declared "Approved" and "planning authorization granted."

**Resolution**: Spec status and oversight text now align with the authorized implementation-repair state in this worktree; no spec-frontmatter claims contradict the one-boundary authorization model.

### T1-3 🔴 PENDING: Proposal 009 status flip is uncommitted on main

`file:///C:/Dev/Specrew/proposals/009-velocity-dashboard.md` on `origin/main` is still `status: draft`. Squad modified it in the feature worktree but the flip becomes real only when the planning-boundary commit lands and (eventually) the PR merges to main. Until then, the public proposal surface (on `main`) is inconsistent with the active feature state.

**Suggested disposition**: confirm at review that the proposal-status flip lands in the planning-boundary commit. This is the manual auto-transition that Proposal 028 ("Public Proposals Surface" Option B) is queued to automate.

### T1-4 🟢 RESOLVED-IN-PROGRESS: Decisions artifact relocated under specs/017

`file:///C:/Dev/Specrew-017/velocity-dashboard-decisions.md` was a real Squad artifact documenting implementation decisions (command wiring, dispatch pattern, etc.) but lived at the repo root rather than under `specs/017-velocity-dashboard/` or `specs/017-velocity-dashboard/iterations/001/`.

**Risk**: artifact gets lost or commit-pollutes the repo root. Feature-scoped artifacts should be feature-co-located per the data-co-location pattern shipped in F-016.

**Resolution**: The artifact now lives at `specs/017-velocity-dashboard/implementation-decisions.md` and references were updated.

### T1-5 🟢 RESOLVED-IN-PROGRESS: `.github/copilot-instructions.md` had duplicated 017 entries

`file:///C:/Dev/Specrew-017/.github/copilot-instructions.md` has **two** "Active Technologies" entries for `017-velocity-dashboard` and **two** "Recent Changes" entries for it. Squad ran whatever auto-generation populates this file twice, producing duplicates.

**Risk**: noise + drift; future readers see contradictory descriptions of the same feature's tech stack.

**Resolution**: Duplicate 017 entries were consolidated to one entry per section; no additional corpus row added in this repair cycle.

---

## Tier 2 — Spec content

### T2-1 🟢 RESOLVED-IN-PROGRESS: Example Dashboard Output had internal math inconsistencies

`file:///C:/Dev/Specrew-017/specs/017-velocity-dashboard/spec.md` lines 145-210 (the illustrative example).

The example is supposed to demonstrate a trustworthy dashboard. The math in it is internally inconsistent:

- **Velocity headline**: `Recent pace: 8.5 points/day (over last 3 closed iterations; 25 total points ÷ ~3 days avg)`
- **Recently shipped totals**: 13+12+9 = 34 SP across the 3 listed features
- **Recent-iterations table**: 12+11+12 = 35 SP across 15 calendar days (5+4+6)
- **Math check**: 35 / 15 = 2.33 SP/day, not 8.5. And the "25 total points" doesn't reconcile with either 34 or 35.
- **Sparkline**: `▁▂▃▂` has 4 data points but velocity says 3-iteration sample.

**Risk**: this is the most embarrassing finding. The feature ships a "trustworthy dashboard" requirement and the spec's own illustrative example fails arithmetic self-consistency. Any reader who runs the numbers will lose confidence in the spec — and by extension, in the dashboard's accuracy claims.

**Resolution**: Example dashboard output was rewritten with consistent totals, velocity math, and confidence mapping.

### T2-2 🟢 RESOLVED-IN-PROGRESS: Iteration naming inconsistency within the same example

Same example block in spec.md lines 145-210 uses two different naming conventions:

- Recent-iterations table: `014-close`, `015-close`, `016-close` (looks like "feature-NNN closeout" labels)
- Full-history summary: `Iteration 011`, `Iteration 012`, ..., `Iteration 016` (looks like "single iteration per feature, numbered by feature ordinal")

But real Specrew features have multiple iterations (F-001 has 10+, F-016 had 2). "Iteration 011" is ambiguous: feature 011's iteration 1? Or the 11th iteration across the project?

**Risk**: the rendering implementation will pick one convention; readers expecting the other will be confused. The variance-table and full-history-summary surfaces should use the SAME naming.

**Resolution**: The spec and example now use `feature-NNN.iter-MM` consistently, and the new FR-037 codifies the convention.

### T2-3 🔴 PENDING: NFR-001 has no quantitative timing budget

`file:///C:/Dev/Specrew-017/specs/017-velocity-dashboard/spec.md` NFR-001: "Dashboard generation must be fast enough to feel natural inside a normal closeout workflow rather than like an extra chore."

**Risk**: F-016 had NFR-001 with a quantitative `+15%` tolerance; the validator measured `+64%` and flagged it. F-017's "fast enough to feel natural" is unverifiable — no test fixture can fail it.

**Suggested disposition**: at review (or pre-review during implementation), set a concrete budget. Examples:
- Dashboard rendering ≤ 1.5s on a 16-feature repo
- ≤ 5% of iteration-closeout workflow duration
- ≤ N ms per feature scanned

The number can be calibrated from Iteration 1's first measurements; lock it in by review.

### T2-4 🔴 PENDING: Grandfathering vs F-017's own iteration-1 closeout (chicken-and-egg)

FR-019 mandates auto-generation at iteration-closeout. FR-022 grandfathers iterations that predate this feature. But F-017's OWN iteration 1 is the first to use the new infrastructure — does iteration 1's closeout produce a `dashboard.md`? The generator may not be fully functional yet at that boundary.

The dashboard-artifact-contract at `file:///C:/Dev/Specrew-017/specs/017-velocity-dashboard/contracts/dashboard-artifact-contract.md` says "post-feature iteration closeouts after rollout must produce `dashboard.md`" — but "after rollout" is ambiguous: does "rollout" mean F-017 merged to main? End of iteration 1? End of iteration 2?

**Risk**: F-017 iteration 1 closes → no dashboard.md → validator warns → repair cycle. OR validator silently accepts a missing artifact and we lose F-017's own dogfood data point.

**Suggested disposition**: at review, lock in the cutover semantics. Options:
- (a) "After feature 017 is merged to main" — F-017 iterations are grandfathered (clean)
- (b) "After F-017 iteration 2 closeout" — F-017 iteration 2 is the first to produce dashboard.md (eats own dogfood)
- (c) "After F-017 iteration 1 closeout" — iteration 1 produces it (aggressive, but tests the auto-invocation path)

Option (a) is the safest. Option (c) is the strongest dogfood test. Pick explicitly.

### T2-5 🟡 PARTIAL: FR-005 plan-vs-reality data source — confirm Squad's data-model addresses it

FR-005 requires a recent-iterations variance table with planned SP, actual SP, delta, and elapsed calendar days. The data source for "planned SP" was not defined in the spec.

Squad created `file:///C:/Dev/Specrew-017/specs/017-velocity-dashboard/data-model.md` and `data-model.md` may resolve this. Verify at review that the data-model contract identifies the canonical source for planned-SP (likely `iterations/<NNN>/plan.md` or `state.md`).

**Suggested disposition**: confirm at review that data-model.md names the path and field. If not, add it. If conflicting paths exist across features (some plans store SP in state.md, others in plan.md), surface that and lock one canonical path.

### T2-6 🔴 PENDING: FR-030 Squad routing classifier is underspecified

FR-030: "Repository/project-status natural-language requests made to Squad ... MUST route to the same dashboard renderer ... Requests asking for other kinds of status MUST remain outside this routing behavior unless they are clearly about repository/project state."

The "clearly about" test is subjective. Squad implementing this needs:
- Positive examples that route: "where are we?", "show project status", "what's shipped recently?", "show repo state"
- Negative examples that do NOT route: "what's the test suite status?", "is CI passing?", "what's the build status?", "what's the status of the merge conflict?"
- Uncertain-classification handling: ask back? Default to dashboard with a one-line disclaimer? Refuse?

**Risk**: this is the same FR-006/FR-009 design tension that consumed ~30 SP of repair cycles in F-016. Underspecified classification behavior produces either over-routing or under-routing, both of which create user-trust damage.

**Suggested disposition**: at review, augment FR-030 with explicit positive/negative example sets and an uncertain-case rule. This is an Iteration 2 deliverable (FR-030 owner role is Interaction steward, delivery window Iteration 2), so the spec can be tightened before Iteration 2 implementation begins.

### T2-7 🟢 RESOLVED-IN-PROGRESS: Data contracts for `roadmap.yml` and `dashboard.md`

Squad created `file:///C:/Dev/Specrew-017/specs/017-velocity-dashboard/contracts/`:
- `roadmap-schema-contract.md` (defines `.specrew/roadmap.yml` schema)
- `dashboard-artifact-contract.md` (defines `dashboard.md` and `closeout-dashboard.md` artifact semantics)
- `dashboard-command-contract.md` (defines command surface)

This preemptively addresses the data-contracts gap I flagged. Verify at review that:
- (a) The roadmap schema covers all FR-010 / FR-011 / FR-012 / FR-013 requirements
- (b) The artifact contract covers FR-020 / FR-021 historical-snapshot + grandfathering rules
- (c) The command contract covers FR-001 / FR-024 / FR-029 / FR-030 surface alignment

If any FR isn't traceable to a contract, the gap stays open and the contracts need extension before Iteration 2.

---

## Tier 3 — Polish

### T3-1 🔴 PENDING: FR-009 placeholder + personal-view echoes F-016's FR-006/FR-009 tension

FR-009: "respond with a clear not-yet-available experience that preserves user trust by explaining the limitation **and then rendering the personal dashboard view**."

This is two behaviors bound to one FR (print explanation AND fall through to render). F-016 hit a 30-SP repair cycle when its FR-006↔FR-009 design conflict went unsplit during clarify.

**Suggested disposition**: split into FR-009a (print explanation) + FR-009b (fall back to personal view) so the contract is explicit. Optionally add a `--Team --strict` mode where fallback is suppressed for tests.

### T3-2 🔴 PENDING: FR-027 vs in-spec Example duplication

FR-027 requires "public-facing documentation MUST include a representative sample" but the spec already has an Example Dashboard Output (lines 145-210). Is FR-027's sample the same one, a different one, or a derived one?

**Suggested disposition**: at review, clarify whether FR-027 documentation reuses the spec example or generates a fresh public-facing example. Pick the simpler path (reuse) and link.

### T3-3 🔴 PENDING: NFR-002 partially restates FR-004's visual policy

NFR-002 says "restrained visual vocabulary that survives monochrome rendering and transcript capture without becoming noisy." FR-004 says the same thing in normative form. Redundancy risks drift when one is edited and the other isn't.

**Suggested disposition**: make NFR-002 reference FR-004 by ID rather than restating: "Visual policy MUST follow FR-004; rendering MUST remain readable in rich and plain-text environments."

### T3-4 🟢 RESOLVED-IN-PROGRESS: "Open Questions for Clarification at /speckit.clarify Time" section header was stale

`file:///C:/Dev/Specrew-017/specs/017-velocity-dashboard/spec.md` line 365: section header still says "Open Questions for Clarification at /speckit.clarify Time" but the body says "This clarification boundary is complete."

**Resolution**: Header renamed to "Clarification Resolution Log" to match the now-closed clarify boundary.

---

## Recommended review-time checklist

At the review boundary, walk through each finding above and emit a verdict for each:
- ACCEPTED: finding holds, repair pending or actioned
- DISPUTED: finding doesn't apply, with reasoning
- DEFERRED: finding holds but disposition is later iteration / future feature
- WITHDRAWN: finding superseded by Squad's planning artifacts

Findings T1-1 through T1-5 should be ACCEPTED and resolved before the planning-boundary commit lands (durability + cosmetic-cleanup work).

Findings T2-1 through T2-4 should be ACCEPTED and resolved before implementation closes (spec correctness affects the shipping artifact).

Findings T2-5, T2-7 should be verified against Squad's data-model and contracts; mark RESOLVED if covered, otherwise raise repair.

Finding T2-6 should be ACCEPTED for Iteration 2 (FR-030 is Iteration 2 scope; tighten before Iteration 2 implementation).

Findings T3-1 through T3-4 are non-blocking polish; DEFER to a refinement pass if Iteration 1 is otherwise clean.

---

## Cross-references

- `file:///C:/Dev/Specrew/specs/016-substantive-interaction-model/iterations/002/retro.md` — F-016 retro that documents the FR-006↔FR-009 design-conflict pattern (cited in T2-6 and T3-1)
- `file:///C:/Users/alon.HOME/.claude/projects/C--Dev-Specrew/memory/project_iteration_011_cleanup_queued.md` — historical iteration grandfathering pattern (relevant to T2-4)
- `file:///C:/Dev/Specrew/proposals/009-velocity-dashboard.md` — public framing reference (relevant to T1-3)
- `file:///C:/Dev/SpecrewDraft/velocity-dashboard.md` — source intent reference

---

End of clarify-residual findings.
