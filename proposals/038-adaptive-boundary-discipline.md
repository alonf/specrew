---
proposal: 038
title: F-016 Adaptive Boundary Discipline (Boundary-Class Refinement)
status: candidate
phase: phase-2
estimated-sp: 10
discussion: tbd
---

# F-016 Adaptive Boundary Discipline (Boundary-Class Refinement)

## Why

F-016 (Substantive Interaction Model, shipped) has a form-vs-meaning gap at its OWN ceremony level: its rule is "stop at every boundary" (form), but the meaning is "stop where human judgment is required." For mechanical repair from a concrete review verdict, requiring human paste-authorization adds friction without adding value.

Empirical motivation 2026-05-16: Squad 0.9.4 introduced "Continuing autonomously" behavior on review-verdict repair cycles. Original interpretation was "boundary breach." User correction: "If the reviewer found problems and Squad knows how to fix them, maybe we just needed a different output — instead of telling the user to review, just continue to run and repair." The reframing: F-016 form rule should refine into a meaning rule that distinguishes three boundary classes.

## What

### Boundary-class taxonomy

| Class | Default behavior | Examples |
|---|---|---|
| **Human-judgment-required** | STOP + wait for authorization | `/speckit.specify`, `/speckit.clarify`, `/speckit.plan`, `/speckit.tasks`, hardening-gate, `/review`, signoff, retro, iteration-closeout, feature-closeout, T-style within-boundary design questions |
| **Mechanical-execution** | ANNOUNCE list + EXECUTE (human can interrupt) + STOP at completion for re-review | Repair from concrete review verdict; bookkeeping post-boundary commits; auto-regenerated artifacts (dashboard snapshots) |
| **Strategic-progression** | STOP + wait | Iteration progression (Iter 1 → Iter 2 within feature); feature progression; phase progression |

For mechanical-execution specifically: human OPT-OUT (interrupt anytime), not OPT-IN (paste authorization).

### Per-class handoff format conventions

| Class | Format | Forbidden pattern |
|---|---|---|
| Human-judgment-required | "What I need from you: <decision>. Recommended: <X>. <substantive rationale per F-016>" | — |
| Mechanical-execution | "Detected issues: <enumerated list>. Executing repair now. Interrupt with 'STOP' if scope is wrong. Will stop at repair-completion for re-review." | Ask + continue (Squad 0.9.4 current bug) |
| Strategic-progression | "Iteration/feature ready to close. Authorize progression to <next> or hold here?" | — |

The forbidden "ask + continue" pattern is the actual breach observed 2026-05-16. The refined methodology makes Squad's behavior either ask-and-wait OR announce-and-continue, not both.

### Five pillars

1. **Boundary-class taxonomy** in coordinator template (`extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md` + mirrors)
2. **Per-class handoff format conventions** with explicit forbidden patterns
3. **Squad coordinator runtime alignment** — extends coordinator template to enforce per-class behavior. Load-bearing pillar; depends on whether Squad upstream respects prompt discipline OR whether we need Multi-Host CORE abstraction for runtime enforcement.
4. **Validator integration** (Validator Hardening gap #11): scan recent handoffs for the forbidden ask+continue inconsistency; detect handoff-prompt vs execution mismatches. WARN initially; FAIL after coordinator-prompt hardening lands.
5. **Documentation refinement**: methodology docs (and Methodology Site when shipped) carry boundary-class taxonomy as first-class concept.

### Out of scope

- Changing Squad upstream behavior (we work via prompt discipline + coordinator-template overrides)
- Re-litigating F-016's three pillars (boundary discipline / essence in console / click-through nav) — those remain valid; this is a refinement on top

## Effort

- **MVP (Option B, Pillars 1-2-4-5, no runtime alignment)**: ~8-10 SP
- **Full (all 5 pillars, requires Multi-Host CORE for Pillar 3 runtime enforcement)**: ~12-15 SP

Recommended: MVP via prompt-only Option B; ship Pillar 3 runtime alignment after Multi-Host CORE (Proposal 024) lands.

## Phase placement

**Phase 2**, between F-019 close and Multi-Host CORE start. Composes with [030](030-quality-hardening-bundle.md) (same form-vs-meaning principle applied at methodology level instead of implementation level — could be folded as a 5th component of the Quality Hardening Bundle).

## Open questions

1. Boundary-class taxonomy granularity: 3 classes or more (e.g., split mechanical-execution into "post-review-repair" vs "autoregenerated-bookkeeping")?
2. Interrupt mechanism for mechanical-execution: how does the human signal "STOP"? Chat message? Squad watches for a marker file?
3. Per-class handoff format: enforced by validator (FAIL on violation) or guidance-only (WARN)?
4. Edge case: review verdict that's PARTIALLY concrete (some explicit repairs + some "needs human judgment" items) — which class?
5. Edge case: iteration progression where the next iteration is OBVIOUSLY just continuation (e.g., F-019 Iter 1 → Iter 2 is already designed) — could that auto-progress?
6. Coordinator template runtime: prompt-only enforcement (Option B) or runtime-level (Option A, needs CORE)?
7. Squad upstream reconciliation interplay: when Squad upstream introduces new autonomous behaviors, who owns the mapping to boundary class?
8. Validator severity: WARN initially, FAIL after maturity?
9. Documentation: where does the taxonomy live (constitution? F-016 docs? methodology site? all three?)
10. Naming: is "Adaptive Boundary Discipline" the right title, or "Boundary-Class Refinement", or something else?

## Risks

- Squad upstream may introduce new autonomous behaviors that don't fit the taxonomy; requires ongoing coordinator-template maintenance
- Distinguishing classes at runtime is ambiguous in some cases; may require fallback to most-conservative (human-judgment-required)

## Cross-references

- Refines [007](007-substantive-interaction-model.md) (shipped F-016)
- Composes with [030](030-quality-hardening-bundle.md) (form-vs-meaning recurrence)
- Composes with [039](039-squad-upstream-reconciliation.md) (boundary-class mapping is part of upstream reconciliation)
- Depends on [024](024-multi-host-runtime-abstraction.md) for Pillar 3 runtime enforcement (Option A path)
- Composes with [004](004-validator-hardening.md) (gap #11 boundary-handoff consistency)

## Status history

- 2026-05-16: captured as memory after Squad autonomous-advance incident, refined via user methodology insight
- 2026-05-18: promoted to candidate proposal during memory→proposals consolidation
