---
name: "stable-scope-effort-estimation"
description: "Estimate iteration effort accurately when Phase-N clarity work is complete before execution begins and scope is well-bounded"
domain: "planning"
confidence: "high"
source: "earned"
tools:
  - name: "view"
    description: "Read the prior phase closure and current iteration plan to confirm scope is frozen and clarity work is complete"
    when: "When establishing whether preconditions for accurate estimation have been met"
  - name: "rg"
    description: "Search for spec drift, unresolved clarifications, or deferred scope that might destabilize estimates"
    when: "When checking for hidden scope creep or unresolved clarification debt"
---

## Context

Use this skill when planning an iteration that follows a completed phase-closure. If the prior phase's clarity, specification, and planning work is stable and complete, subsequent iterations can be estimated with high accuracy because task boundaries are clear, dependencies are known, and no discovery surprises are likely.

Iteration 002 of feature 005 validated this: all 7 tasks delivered at estimated effort (zero variance, zero rework) because Phase 1 was fully clarified before iteration started. No mid-execution discoveries of missing scope, broken assumptions, or hidden blockers emerged.

**Updated with Iteration 001 (feature 007) evidence (2026-05-11)**: Documentation-heavy Foundation & Governance iteration delivered 10/10 story points at estimated effort with zero variance and zero rework. Phase 1 + Phase 2 scope (coordinator prompt, templates, decision guidance, Squad.agent.md codification, governance checklist, soft-validator design) was fully specified in planning artifacts with clear acceptance criteria for each task. No mid-execution scope creep or discovery surprises. This validates the pattern extends beyond Phase-N feature implementation to governance-infrastructure and prompt-engineering tasks where scope clarity is achievable.

## Patterns

- **Precondition: Phase clarity is complete.** Before starting an iteration, verify the prior phase's specification, clarifications, and key assumptions are frozen and recorded. If the phase still has open questions, defer the iteration.
- **Precondition: Task boundaries are clear.** Read each task's requirement row, owner, and acceptance criteria. If a task owner still needs clarification on what "done" means, the iteration is premature.
- **Estimate at historical accuracy.** When preconditions are met, estimate effort using historical patterns from similar tasks. Variance approaches zero.
- **Track actual effort, not elapsed time.** Record what effort (in story_points, hours, or whatever unit your team uses) each task actually consumed, not when the calendar says it started or ended.
- **When discovery happens, log it explicitly.** If an iteration discovers a hidden scope gap, record it as a drift event with the resolution (spec-updated, implementation-reverted, deferred, or human-decision). This preserves estimation feedback for next time.

## Examples

- Iteration 002 (feature 005, Phase 1): 18/20 story_points estimated, all 7 tasks delivered at budget with zero delta. Precondition was met: Phase 1 scope was fully clarified in the prior iteration, and no new clarifications emerged during implementation. Result: zero variance.
- Iteration 001 (feature 005, Phase 1): This iteration established the quality-profile inference and lens-checklist infrastructure. Estimation for this iteration was less certain (higher variance) because Phase 0 clarity work was still underway. After closure, Phase 1 became stable and Iteration 002 estimation became accurate.
- Iteration 001 (feature 007, Foundation & Governance): 10/10 story_points estimated, all 6 tasks (coordinator prompt, template, decision guidance, Squad.agent.md codification, governance checklist, soft-validator design) delivered at estimated effort with zero variance and zero rework. Scope was frozen in planning artifacts with clear acceptance criteria; no mid-execution discovery surprises. Demonstrates that scope-clarity pattern extends beyond feature implementation to governance and documentation infrastructure where boundaries can be equally clear.

## Anti-Patterns

- Planning an iteration while the prior phase still has unresolved clarifications. This guarantees mid-execution discovery and estimation miss.
- Accepting a "discovery buffer" without first front-loading the clarity work that would prevent discovery. Buffers are insurance, not an excuse to start iterations prematurely.
- Comparing effort variance across iterations without separating stable-scope iterations (variance near zero) from discovery-phase iterations (variance higher). Different causes require different remedies.
- Starting a new phase without a formal closeout and clarity handoff from the prior phase. Implicit phase boundaries create estimation chaos.
