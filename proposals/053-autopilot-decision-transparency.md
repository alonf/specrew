---
proposal: 053
title: Autopilot Decision Transparency (Surface Auto-Resolutions in Artifacts)
status: candidate
phase: phase-2
estimated-sp: 3
discussion: tbd
---

# Autopilot Decision Transparency

## Why

Squad's "best guess on autopilot" pattern silently resolves clarify questions and intermediate decisions when the human doesn't answer within timeout. This is sometimes appropriate (e.g., minor field defaults) and sometimes a real product/scope decision the user would have wanted to weigh in on.

**Empirical evidence (WSL trial 2026-05-18)**: a fresh-project trial silently baked two substantive scope decisions into specs without human input:

- "50 balls max for v1" — recorded as a "documented v1 performance assumption" but actually a product scope decision (50 vs 500 balls = completely different implementation strategy)
- "Per-ball color + small preset material library" — recorded as the feature-002 scope without asking what materials the user actually wanted

The decisions weren't wrong, but they were **invisible**. The user discovered them by reading the resulting artifacts and noticing scope had been chosen for them.

This proposal closes the visibility gap. Squad can still auto-resolve under timeout, but every auto-resolution gets a visible marker in the resulting artifact AND a summary line in the next user-facing handoff. The user sees what got decided without their input and can choose to override before the decision is locked downstream.

This is **strictly less ambitious than Proposal 038** (which would make clarify questions hard-stop for substantive decisions). 053 is the small "make it visible" fix; 038 is the larger "make it discriminating" fix. Both can ship; 053 should ship first as a cheap UX hardening, then 038 makes the deeper governance change.

## What

### Pillar 1: Mark auto-resolved fields in artifacts

When Squad auto-resolves a clarify question (or any decision) without explicit human input, the resulting artifact entry gets an explicit marker.

**Before (current behavior)**:

```markdown
- Q: Maximum ball count for v1 → A: 50 balls max for v1 performance.
```

**After (proposed)**:

```markdown
- Q: Maximum ball count for v1 → A: 50 balls max for v1 performance.
  **Auto-resolved**: no human input within timeout (default selected from documented performance assumption). Review before locking downstream.
```

The marker is unmistakable when reading the spec. Reviewers, auditors, and the original user can see at a glance which decisions were human-driven vs autopilot-resolved.

### Pillar 2: Surface auto-resolution summary in handoffs

Every Squad handoff that includes auto-resolved decisions includes a top-level summary section:

```
## Auto-resolved decisions in this run

Squad applied default values for these decisions without explicit human input:
- Max ball count: 50 (clarify Q from /speckit.clarify)
- Appearance scope: per-ball color + preset materials (clarify Q from /speckit.clarify)

If any of these aren't what you wanted, revise the spec before /speckit.plan locks the contract downstream.
```

The summary appears in the user-facing console output, NOT just buried in `.squad/decisions.md` — that file is reference; the handoff is the actionable surface.

### Pillar 3: Decision-ledger record with auto-resolution flag

Every auto-resolved decision logged to `.squad/decisions.md` includes an explicit `auto_resolved: true` flag plus `auto_resolved_reason: timeout` (or `safe-default`, `documented-assumption`, etc.).

This enables:

- Retros: filter decisions.md for `auto_resolved: true` to see what got skipped
- Validators: future validator rules can warn if N+ auto-resolutions happen in a single feature (signal that human attention is needed)
- Analytics: count auto-resolution rate over time

### Pillar 4: Scope guardrail on what can be auto-resolved

Even with full transparency, certain decisions should NEVER auto-resolve. Squad's coordinator-prompt gains an explicit "never auto-resolve" allow-list:

- Spec-level scope decisions (max counts, target platforms, security model, data retention)
- Architecture decisions (framework choice, persistence model, deployment target)
- Compatibility pins (minimum versions, dependencies, API contracts)
- Anything that affects what gets built vs how it gets built

For decisions in this allow-list, Squad MUST hard-stop and wait for human input, regardless of autopilot policy. The transparency markers (Pillars 1-3) apply to lower-stakes decisions where autopilot fallback is reasonable.

This pillar is the bridge to Proposal 038 — it pre-establishes the human-judgment-required class without requiring the full three-class taxonomy yet.

## Effort

**~3 SP, single iteration.** Roughly:

- Coordinator-prompt update to teach Squad to mark auto-resolved fields (~0.5 SP)
- Artifact template updates to include the marker pattern (~0.5 SP)
- Decision-ledger schema update: `auto_resolved` + `auto_resolved_reason` fields (~0.5 SP)
- Handoff template updates: top-level auto-resolution summary section (~0.5 SP)
- "Never auto-resolve" allow-list in coordinator-prompt (~0.5 SP)
- Tests: confirm auto-resolutions get marked correctly; allow-list items hard-stop (~0.5 SP)

## Phase placement

**Phase 2, fast follow-up.** Slots into the post-F-020 queue as a small UX hardening. Composes with:

- **Proposal 038 (Adaptive Boundary Discipline)** — this proposal pre-establishes the "never auto-resolve" allow-list; 038 builds out the full three-class taxonomy. Ship 053 first as cheap UX win; 038 follows as deeper governance.
- **Proposal 047 (Project Governance Profile)** — once 047 lands, the auto-resolution policy becomes a governance dial: `clarify_autopilot: { transparent | hard-stop-for-scope | always-hard-stop }`. 053 establishes the marker mechanism; 047 makes policy configurable.

## Open questions

1. **Marker syntax**: `**Auto-resolved**: ...` (bold prefix) vs `> Auto-resolved: ...` (blockquote) vs HTML comment `<!-- auto-resolved -->` (invisible to readers)? Recommend bold prefix — visible but not visually loud.
2. **"Never auto-resolve" allow-list scope**: hardcoded in coordinator-prompt v1, or configurable per project from start? Recommend hardcoded for v1; 047 makes it configurable later.
3. **Auto-resolution timeout window**: how long does Squad wait before defaulting? Current behavior seems immediate; should there be an explicit wait window? Defer to 047.
4. **Retro integration**: should the retro template include an "Auto-resolved decisions review" section by default? Useful for capturing whether autopilot choices held up.
5. **Validator rule**: should a future validator flag specs with N+ auto-resolved decisions as "human review recommended before plan"? Could ship in this proposal or defer to Proposal 004 validator hardening follow-up.
6. **Multi-host neutrality**: the marker pattern should work identically whether Squad, Claude Code, or Codex is driving (per Proposal 024 Multi-Host CORE).
7. **Backward compatibility**: existing artifacts with unmarked auto-resolutions — leave alone (historical) or run a one-time migration to flag retroactively? Recommend leave alone; only enforce going forward.
8. **Marker on derived artifacts**: if a plan or task list inherits an auto-resolved scope decision from the spec, does the marker propagate? Probably yes — the marker traces the decision lineage.
9. **Console rendering**: when handoff prose includes the marker in agent UIs, should renderers visually highlight it (color, icon)? Defer to F-018 visual-richness follow-up.

## Risks

- **Marker noise**: if every minor field default gets marked, specs become visually cluttered. Mitigation: only mark NON-trivial auto-resolutions (clarify questions, scope decisions); skip cosmetic defaults like timestamp formatting.
- **Allow-list completeness**: the "never auto-resolve" list may miss substantive decisions Squad encounters. Mitigation: start broad (anything that affects what-vs-how); allow expansion as feedback surfaces; ultimately resolved by Proposal 038's three-class taxonomy.
- **Squad workaround**: if autopilot is aggressively enabled, Squad might "auto-resolve" by paraphrasing the question to avoid the allow-list match. Mitigation: pattern-match on decision semantics, not literal question wording; review with adversarial framing during testing.
- **User fatigue**: even with transparency, users may not read auto-resolution summaries. Mitigation: visual prominence in handoffs; bold + early-in-output positioning; can't force reading but can make it conspicuous.
- **Bypasses retro lesson 1 from F-020**: F-020 retro Lesson 1 was about canonical bookkeeping staying current. Auto-resolution markers must be preserved through scope-correction repairs (e.g., the F-020 Iter 1 review-rerun repair) — markers shouldn't disappear when artifacts get touched up.

## Cross-references

- **Proposal 038 (Adaptive Boundary Discipline)** — this proposal pre-establishes Pillar 4's "never auto-resolve" allow-list; 038 generalizes via three-class taxonomy
- **Proposal 047 (Project Governance Profile)** — makes auto-resolution policy configurable as a governance dial
- **Proposal 004 (Validator Hardening)** — could add a "N+ auto-resolutions in spec" rule
- **Proposal 024 (Multi-Host CORE)** — marker pattern must be host-neutral
- **Proposal 015 (Expertise-Aware Adaptive Interaction)** — composes; expert users may opt for more autopilot, novice users opt for less
- **WSL trial 2026-05-18** — the empirical observation that motivated this proposal; 50-ball max + appearance-scope decisions silently baked into specs

## Status history

- 2026-05-18: candidate captured after WSL trial on fresh-project (Moment20 physics simulation) silently auto-resolved two substantive scope decisions during clarify. Squad's "best guess on autopilot" pattern is sometimes correct, but invisible auto-resolutions hide product/scope decisions from human review. This proposal makes them visible without (yet) preventing them.
