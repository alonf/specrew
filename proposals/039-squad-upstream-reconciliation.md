---
proposal: 039
title: Squad Upstream Reconciliation
status: candidate
phase: phase-3
estimated-sp: 22
discussion: tbd
---

# Squad Upstream Reconciliation

## Why

Specrew sits on top of Squad as its primary host runtime. Squad upstream evolves independently — new versions introduce new autonomous-execution capabilities, changed prompt-handling semantics, new agent types. Without a reconciliation discipline, Squad upstream changes silently change Specrew's behavior.

Empirical motivation: the Squad 0.9.1 → 0.9.4 bump on 2026-05-16 introduced "Continuing autonomously" behavior on review-repair handoffs. Specrew's coordinator-prompt override did not catch this. Resulting incident: F-019 Iter 1 review repair cycle ran autonomously without explicit human authorization. Subsequent reframing recognized the behavior was actually appropriate for mechanical-execution boundaries (see [038](038-adaptive-boundary-discipline.md)), but the surprise was the issue.

The strategic concern: Specrew's methodology must be robust to Squad upstream evolution, not held hostage by it.

## What

A discipline + tooling combo for tracking, evaluating, and either adopting or overriding Squad upstream changes:

### Five pillars

1. **Upstream change-log mirror** — `.specrew/squad-upstream/changelog.md` captures Squad version pins, release notes, and per-version behavioral deltas observed during testing.

2. **Behavioral-divergence tests** — `tests/squad-upstream/` integration tests that exercise critical Squad behaviors (boundary handoffs, autonomous-execution defaults, prompt-respect, MCP server interaction). Run on every Squad bump.

3. **Coordinator-template version pinning** — explicit dependency declaration between Specrew coordinator-template versions and tested-compatible Squad versions. Bumping Squad requires re-validating the coordinator-template.

4. **Boundary-class mapping** — for each Squad upstream behavior, the coordinator template explicitly maps it to one of the [038](038-adaptive-boundary-discipline.md) boundary classes (human-judgment / mechanical-execution / strategic-progression). New Squad behaviors require explicit classification before adoption.

5. **Reconciliation handoff** — when a Squad bump introduces a divergent behavior, Specrew surfaces it as a structured handoff: "Squad X.Y.Z introduces behavior B; recommended classification = mechanical-execution; coordinator-template impact = additive only. Authorize adoption?"

### Out of scope

- Replacing Squad with an alternative runtime (that's [024](024-multi-host-runtime-abstraction.md))
- Forking Squad
- Contributing back to Squad upstream — separate concern, candidate for a future companion proposal. Strategic context as of 2026-05-29: Squad authors Brady Gaster + Tamir Dresher co-authored "Squad: Human-Led Agentic Teams" at aka.ms/SquadCommandLine (Microsoft Command Line publication) listing 5 acknowledged Squad limitations (role drift, prompt saturation, memory compaction, parallelism pressure, file corruption) that map 1:1 to Specrew's primary feature investments. Tamir is a trusted friend of Alon and the original connector to Brady (see memory `[[reference-tamir-dresher-codevalue-friend-brady-connector-2026-05-29]]`), making the upstream-contribution channel WARM rather than cold. A dedicated upstream-contribution proposal would document the 5-limitations mapping, recommended contribution candidates (drop-box pattern adoption, memory class taxonomy comparison, primer-pattern compaction fix per Proposal 133, etc.), and the Tamir-mediated outreach protocol (inform Tamir first; Tamir loops in Brady).

## Effort

- **Iteration 1** (~12-15 SP): change-log mirror, behavioral-divergence tests for current Squad version, coordinator-template version pinning
- **Iteration 2** (~7-10 SP): boundary-class mapping integration with [038](038-adaptive-boundary-discipline.md), reconciliation handoff workflow

**Total**: ~22 SP

Hard prerequisite: [024](024-multi-host-runtime-abstraction.md) (Multi-Host CORE) — provides the abstraction layer that makes reconciliation possible. Squad upstream changes can be more or less impactful depending on whether they touch the abstraction surface.

## Phase placement

**Phase 3**, after Multi-Host CORE ships. This proposal is the SECOND-layer reconciliation work that builds on top of CORE.

## Open questions

1. Granularity of behavioral-divergence tests: full lifecycle re-run vs targeted behavior probes?
2. Coordinator-template version pinning: hard-fail on mismatch, or warn-and-proceed?
3. Boundary-class mapping for net-new Squad behaviors: who classifies (Squad user, Specrew maintainer, automated heuristic)?
4. Should reconciliation handoffs be required for EVERY Squad version bump, or only minor/major (skipping patch)?

## Risks

- Squad upstream pace may exceed Specrew reconciliation capacity; need lightweight default path for routine bumps
- Behavioral-divergence tests are brittle (depend on Squad upstream version-stable behavior); requires maintenance

## Cross-references

- Hard prerequisite: [024](024-multi-host-runtime-abstraction.md) (Multi-Host CORE)
- Composes with [038](038-adaptive-boundary-discipline.md) (boundary-class taxonomy is the classification target for new Squad behaviors)
- Composes with [004](004-validator-hardening.md) (validator gap #11 catches ask+continue inconsistency that this proposal's reconciliation handoff would surface)

## Status history

- 2026-05-16: captured as memory after Squad 0.9.4 bump exposed reconciliation gap
- 2026-05-18: promoted to candidate proposal during memory→proposals consolidation
