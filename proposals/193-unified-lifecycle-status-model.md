---
proposal: 193
title: Unified Lifecycle Status Model — Single Source of Truth and Deterministic Propagation
status: candidate
phase: phase-2
estimated-sp: 13-21
priority-tier: 1
discussion: surfaced 2026-06-12 during the Feature 174 iteration-10 work, after a full session spent reconciling drifted lifecycle status across plan.md, state.md, closed-iterations.yml, start-context.json, and the rolling handover. The lifecycle "status" is represented redundantly and maintained by a MIX of deterministic hooks and probabilistic agent edits with no atomic propagation, so the representations drift and the validator catches the drift after the fact rather than preventing it. This proposal extends the determinism Feature 174 gave RESUME state to ITERATION GOVERNANCE state.
---

# Unified Lifecycle Status Model — Single Source of Truth and Deterministic Propagation

## Why

Specrew's lifecycle "status" is not one fact in one place. It is represented redundantly across at least six
artifacts, written by a MIX of deterministic hooks and probabilistic agent edits, with NO atomic
synchronisation between them. The representations drift, and the governance validator catches the drift after
it happens rather than making it structurally impossible.

The 2026-06-11 to 2026-06-12 Feature 174 reconciliation is the evidence. A full working session was spent
reconstructing honestly-qualified closes for iterations 006 and 008, fixing an iteration 008 whose `plan.md`
said `executing` while its `state.md` said `complete`, restoring a `004/state.md` that a task-progress render
had silently reset to `not-started` (twice in the same session), and reconciling a blank `.specify/feature.json`
anchor plus a `from_host: host` mislabel. None of these were caught by whatever introduced them; all were
caught later by the validator, at high cost.

### The representations and their writers

| Representation | Scope | Written by | Nature |
| --- | --- | --- | --- |
| `plan.md` `Status:` | iteration | the agent, by hand at boundaries | probabilistic |
| `state.md` `Current Phase` / `Iteration Status` | iteration | the agent, by hand | probabilistic |
| `.specrew/closed-iterations.yml` | feature index | the agent, by hand at close | probabilistic |
| `plan.md` task-status table | per task | the agent | probabilistic |
| `.specrew/start-context.json` boundary state | live session | sync scripts and the SessionStart hook (agent-triggered advance) | deterministic-ish |
| rolling handover `active_boundary` | resume | the Stop / PostToolUse hook | deterministic |

The validator binds to `plan.md Status` (not to `state.md`), so the human-facing `state.md` can silently
disagree with the authoritative field, and routinely does.

### Two kinds of redundancy

Some redundancy is principled because the consumers differ. `plan.md` is machine-authoritative; `state.md` is
the human narrative; the handover carries its own `active_boundary` deliberately so resume does not depend on
a central anchor that can go blank (the anchorless-workshop case). The rest is an accidental "this should be
one source of truth but is not" smell: the same iteration status living in `plan.md`, `state.md`, and the
closed-index with no single owner. That second kind is the drift source.

### The deeper pattern: a split brain

Feature 174 is moving RESUME and runtime state to deterministic hook-capture, which is reliable. But ITERATION
GOVERNANCE state is still probabilistic agent-maintenance, which is drift-prone. The agent must remember to
update every representation consistently; when it updates one and not the others, the system drifts and only
the validator notices. The "honest state" discipline rule is, today, an agent discipline rather than a
structural guarantee.

## Proposal

Establish a SINGLE canonical source of truth for each status scope and DETERMINISTIC propagation or derivation
to the redundant representations, so a status change is one operation the agent or a hook invokes — never N
hand-edits that can fall out of sync.

1. **Analyse (the audit, first deliverable).** Enumerate every status representation, its writer, its
   consumer, and its drift modes. Classify each redundancy as principled (keep it, with a deterministic
   derivation) or accidental (eliminate it or derive it). Use the Feature 174 reconciliation incidents as the
   concrete drift catalogue, and confirm whether the analysis changes the sizing below.
2. **Design the canonical model.** Pick the source of truth per scope: the iteration status (likely
   `plan.md Status` as the machine field), the per-task status (the plan task table), the feature index
   (`closed-iterations.yml`), the live session boundary (`start-context.json`), and the resume boundary (the
   handover). Define which representations are CANONICAL and which are DERIVED from the canonical one.
3. **A deterministic status primitive.** A single script or cmdlet — for example `Set-SpecrewIterationStatus`
   and `Advance-SpecrewBoundary` — that writes the canonical field AND re-derives and writes every dependent
   representation in one atomic operation (`plan.md`, `state.md`, the closed-index, and the task table), so
   the agent cannot half-update. Boundary commits call it, hooks call it, and the agent never hand-edits the
   redundant copies again.
4. **Shift the validator from catch to prevent.** With one writer and derivation, the cross-representation
   consistency checks become either unnecessary (the redundancy is derived) or a thin guard that the derived
   files match the canonical source. The honest-state rule becomes structurally enforced rather than
   agent-disciplined.

## Scope and sizing

Phase-2 governance hardening. Estimated 13 to 21 story points across analyse, design, the primitive, wiring
the boundary flow and the hooks to call it, and migrating the validator. The exact figure depends on how much
the analysis recommends deriving versus eliminating; the analysis is the first deliverable and may itself
refine the number.

## Priority

Tier 1 (high). Status drift is recurring, high-cost (an entire reconciliation session), and it undermines the
foundational honest-state guarantee that every other governance check assumes. It complements Feature 174 —
which made resume state deterministic — by extending determinism to the iteration governance state, the half
of the split brain still maintained by hand.

## Relationship to other proposals

- Complements Feature 174 (hook-driven session bootstrap and rolling handover): Feature 174 makes the LIVE and
  resume state hook-captured; this proposal makes the ITERATION governance state single-sourced and
  deterministically propagated.
- Related to Proposal 028 (lifecycle hardening and index auto-generation): the closed-index and the proposal
  INDEX are instances of the same "derive, do not hand-maintain" principle.
