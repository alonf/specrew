---
proposal: 014
title: Red Team Agent
status: candidate
phase: phase-2
estimated-sp: 22
discussion: tbd
---

# Red Team Agent

## Why

Specrew's existing quality stack is comprehensive but **all conformance-oriented** — every gate asks: "did the declared work conform to the declared design?"

What no current gate provides:
- **Adversarial security perspective**: not "are secrets externalized?" (checklist) but "if I were an attacker, what's my entry point?"
- **Cross-feature systemic risk**: per-iteration scope misses "what's the systemic risk of a 5000-line validator?"
- **Architectural assumption auditing**: the Reviewer checks what's declared; no one challenges the declarations
- **What-isn't-here analysis**: Iteration 1 of Feature 016's FR-006↔FR-009 design conflict consumed ~30 SP of repair cycles. A red-team review at clarify time asking "are these FRs consistent?" would have saved 3 days.
- **Scale / stress thinking**: what does `.squad/decisions.md` look like at 50MB?

A Red Team agent fills the design-challenging gap that conformance-checking gates structurally cannot.

## What

A new Squad agent that performs holistic adversarial review at **feature-closeout** (not per-iteration). Reads the entire feature artifact set, adopts four adversarial personas, and produces a `red-team-findings.md` report attached to the feature.

**Four personas**:
1. Security attacker — "how would I abuse this?"
2. Scale stressor — "what breaks at 100x?"
3. Supply-chain attacker — "what's the dependency-poisoning surface?"
4. User-error attacker — "what if the user does something the design didn't anticipate?"

**Findings policy**: non-blocking. Surfaces concerns for human consideration; high-severity findings become corpus-row candidates or next-feature scope items via the established graduation pipeline.

**Composability with existing gates**:
- Hardening gates do predefined per-concern checks; Red Team adversarially probes those concerns + concerns that weren't predefined
- Reviewer verifies Expected Controls met; Red Team challenges whether the Controls were the right ones
- Retro Facilitator captures reactive lessons; Red Team does proactive what-could-go-wrong
- The existing gates are conformance-checking; Red Team is design-challenging

## Effort

- **Iteration 1 (~12 SP)**: Agent charter + 4 persona skills + coordinator-prompt rule for feature-closeout trigger
- **Iteration 2 (~10 SP)**: Refine personas based on dogfooding + integration with corpus-row graduation pipeline + soft-validator rule for missing red-team-findings artifact
- **Total**: ~20-25 SP

## Phase placement

Phase 2 slot 2.7+ — after queued graduation candidates (bypass detector, spec-reconciliation detector) and Feature N Learning Loop Closure ship. Reasoning:
- Learning Loop Closure formalizes the corpus-row graduation pipeline that Red Team findings will feed
- The graduation candidates handle some adversarial-detection patterns mechanically, reducing Red Team's load
- Red Team's value is highest after the lifecycle stabilizes

## Open questions

1. Trigger frequency: feature-closeout only? Also at feature-start for design review?
2. Personas extensible per-project via `.specrew/quality/red-team-personas.yml`?
3. Blocking severity: critical findings hard-fail closeout, or all findings advisory? Default: all advisory (the value is the perspective, not the gate).
4. Findings cross-pollination: auto-graduate critical findings to known-traps, or explicit human curation?
5. Cross-feature analysis: look at last feature in isolation, or compare against prior N features for systemic patterns?
6. Output format: structured markdown only, or also JSON for tooling?
7. Persona invocation: separate per-persona skills aggregated by agent charter, or one agent adopting personas sequentially?
8. Feature scope: `specs/<feature>/` only, or also touched files outside specs?

## Risks

- **Token cost**: full adversarial review per feature is expensive. Mitigation: feature-closeout-only triggering, not per-iteration.
- **False positives**: persona prompts produce noise. Mitigation: findings ranked by severity; only critical findings escalate.
- **Methodology accumulation**: another agent adds prompt complexity. Mitigation: keep agent charter focused; share personas as discrete skills.

## Cross-references

- Composes with: Proposal 008 (NFR Governance), Proposal 015 (Learning Loop Closure), Proposal 011 (Architecture Intent Checkpoint)
- Justified by: Feature 016 Iter 1 FR-006↔FR-009 design conflict (~30 SP repair cost)
- Feeds: corpus-row pipeline at `.specrew/quality/known-traps.md`

## Status history

- 2026-05-15: candidate captured following user observation that "the most important projects had a red team responsible for going over the solution"
