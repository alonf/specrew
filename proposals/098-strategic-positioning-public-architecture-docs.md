---
proposal: 098
title: Strategic Positioning + Public Architecture Documentation
status: candidate
discussion-status: ad-hoc
spec-status: none
relationship-status: clean
phase: phase-2
estimated-sp: 10-15
discussion: ad-hoc 2026-05-22 session
---

# Strategic Positioning + Public Architecture Documentation

## Why

A stranger landing on file:///C:/Dev/Specrew/README.md today cannot answer four basic questions in under 60 seconds:

1. *What is Specrew?* Tool, methodology, framework, or something else?
2. *Why this vs Spec-Kit alone, or Antigravity, or Claude Code's `agents-ui`?*
3. *Will I be locked into GitHub if I adopt this?*
4. *What's the long-term vision?*

The internal proposal corpus (98 entries as of 2026-05-22) contains rigorous answers to each. None of them are surfaced where a visitor will look. Specrew has the strategic clarity; it just hasn't published it.

Empirical signal: an external research document received 2026-05-22 reverse-engineered Specrew's identity from public artifacts and reached a defensible position ("SDLC governance meta-framework, vendor-agnostic, three-tier architecture: Intent / Execution / Governance"). The fact that this had to be reverse-engineered — rather than read directly — is the gap.

Adoption is gated on this. The methodology-first prioritization decision (memory: `project_methodology_first_prioritization_2026_05_16`) targets ~late summer 2026 for external testers. Adoption without positioning is friction. The cost of writing 098 is low; the cost of leaving it unwritten compounds as more potential adopters bounce.

User-stated motivation (2026-05-22):

> "Is there any insights that we can derive [from external research] to improve the project?" — the strongest insight was that positioning is missing, not that any specific competitive analysis is right.

## What (6 Pillars)

### Pillar 1 — Audience-segmented documentation map

Different audiences need different framings. Single "ARCHITECTURE.md" serves none of them well. Five audiences, five entry points:

| Audience | Entry doc | Purpose |
|---|---|---|
| Stranger arriving on GitHub | `README.md` | "What is this in 60 seconds?" + clear next-step links |
| Engineer evaluating tools | `docs/why-specrew.md` (new) | Why this vs Spec-Kit alone, vs Antigravity, vs agents-ui |
| Manager evaluating adoption | `docs/adoption.md` (new) | Cost/benefit/risk; team size; learning curve; rollback story |
| Contributor | `docs/architecture.md` (new) + `CONTRIBUTING.md` (edit) | Where to add things without breaking architecture |
| Researcher / methodologist | `docs/methodology.md` (new) | Intellectual contribution; epistemics; lifecycle theory |

Pillar 1 is the **scaffolding decision** — which docs, who they're for, what they contain. The actual writing happens in Pillars 3-5.

### Pillar 2 — Vocabulary lock + framing choice

Three vocabulary decisions must happen before any doc ships, or fresh inconsistency is built into v1.0:

**Decision A**: "Squad" vs "the Crew" terminology (already in progress per 2026-05-21 INDEX terminology note). 098 cannot ship cleanly while this is mid-transition. Either lock first (small chore) or 098 uses only locked-in terms and explicitly flags "Squad" + "the Crew" as terms-in-transition.

**Decision B**: How to frame Specrew. Candidate framings (test before picking):

- "SDLC governance meta-framework" — intellectually accurate; academically heavy
- "Guardrails for AI-driven development" — concrete; understates the methodology surface
- "Spec-Driven Development with multi-agent execution governance" — full but long
- "Methodology layer for autonomous coding agents" — short, modern; vague on what "layer" means

Recommendation: test all four with sample readers (or AI-generated reader personas) before locking. No silent default.

**Decision C**: How to refer to the underlying agent runtime. "Copilot" today; eventually "Copilot, Claude Code, Codex, …" via Proposal 024. Docs should be drawn for the **multi-host future state** even if implementation is single-host today, otherwise they need rewriting the moment 024 ships.

### Pillar 3 — Three-tier architecture diagram (forward-state)

The core diagram: **Intent (Spec-Kit) → Governance (Specrew) → Execution (multi-host: Squad / Claude Code / Codex / …)**

Drawn for the post-Proposal-024 future, with current state ("phase 1 implementation: Squad-only") called out as a callout box. Mermaid format (composes with Proposal 081 Mermaid Mandate when shipped).

Lives in `docs/architecture.md`. Companion Mermaid in `docs/data-flow.md` showing the artifact lifecycle: human prompt → spec.md → plan.md → tasks.md → tracker sync (per Proposal 101 when shipped) → execution → review → ship.

### Pillar 4 — Vendor-agnostic vs GitHub-first strategic decision

098 cannot be written without answering this. Today's reality:

- Most production code is GitHub-coupled (`gh` CLI, GitHub-themed skill templates, `.github/scripts/`, PR-review integration assumes GitHub)
- Strategic intent (per multiple proposals: 024, 052, 058, 069) is vendor-agnostic
- The github-coupling-investigation memory documents the gap

This proposal **forces the answer** at clarify time. Three positions to choose from:

| Position | Implication |
|---|---|
| Vendor-agnostic (strategic intent) | 098 says so; commits to delivering on Proposals 024/052/058/069/101; existing GitHub coupling is documented debt with explicit replacement timeline |
| GitHub-first (current reality) | 098 says so; multi-host proposals get explicitly de-prioritized; clearer adoption story for GitHub-org users; loses non-GitHub adopters |
| Multi-host architecture, GitHub-only-shipped-today, vendor-agnostic-by-end-of-2026 | Honest middle ground; harder to write convincingly; requires concrete commitments |

Recommendation: third position. But this is a strategic choice the user must make, not the proposal author.

### Pillar 5 — Competitive positioning (carefully scoped)

Cite the *category* Specrew is in, not specific competitor capabilities. Specific competitor specs (Antigravity's "93 sub-agents", agents-ui's WebSocket dashboard, etc.) age fast and may already be inaccurate (the 2026-05-22 research document had several unverifiable details).

Better framing for `docs/why-specrew.md`:

- What category exists today (agent-first IDEs, visual orchestrators, SDD generators, governance meta-frameworks)
- Which category Specrew is in (governance meta-framework + methodology)
- What that category provides that others don't (vendor-agnosticism, methodology rigor, lifecycle gates)
- Honest gaps (we don't replace agents-ui's GUI; we don't host LLM inference; we don't do code generation directly)

Specific competitor names appear once each, as category exemplars, not as detailed comparison charts.

### Pillar 6 — Stability + revision commitment

Positioning docs that ship v1.0 and revise monthly lose credibility. The proposal must commit upfront to:

- **Stable docs**: README, architecture.md, why-specrew.md — revise only on substantive Specrew architecture changes (e.g., when 024 ships). Version-stamped at top.
- **Living docs**: adoption.md, methodology.md — periodic revision welcome; explicit "last reviewed YYYY-MM-DD" footer.

Composes with Proposal 094 (Documentation Update Discipline) — the docs gate catches when changes warrant updating these.

## Functional Requirements

- **FR-001**: Audience-doc map authored in Pillar 1; each doc's audience + purpose explicit
- **FR-002**: README.md rewritten to answer the four basic questions in under 60 seconds for stranger-arriving audience
- **FR-003**: `docs/why-specrew.md` (new) — category-level competitive positioning; no specific competitor capability claims that age fast
- **FR-004**: `docs/architecture.md` (new) — three-tier diagram (Intent / Governance / Execution); drawn for multi-host future; current state callout
- **FR-005**: `docs/data-flow.md` (new) — artifact lifecycle Mermaid diagram
- **FR-006**: `docs/adoption.md` (new) — cost/benefit/risk framing for managers
- **FR-007**: `docs/methodology.md` (new) — intellectual contribution + lifecycle theory for researchers
- **FR-008**: `CONTRIBUTING.md` (edit) — point contributors at architecture.md for boundary education
- **FR-009**: Vocabulary lock decision committed at clarify time (Pillar 2 Decision A)
- **FR-010**: Framing decision committed at clarify time (Pillar 2 Decision B)
- **FR-011**: Vendor-agnostic vs GitHub-first decision committed at clarify time (Pillar 4)
- **FR-012**: Each new doc carries `last-reviewed: YYYY-MM-DD` footer and stability classification (stable / living)
- **FR-013**: Composition with Proposal 013 (Methodology Site) made explicit: 098 owns in-repo docs (technical, audience-segmented); 013 owns external site (rich, narrative). Shared content rendered from a single source.
- **FR-014**: Composition with Proposal 094 (Documentation Update Discipline) — these docs are profile-neutral and subject to the docs gate
- **FR-015**: Composition with Proposal 081 (Mermaid Mandate) — diagrams use Mermaid

## Out of scope

- Marketing site / external blog / Medium articles — that's downstream of Proposal 013
- Detailed competitive-comparison matrices — fragile; out of scope by design
- Translations / internationalization — single language at MVP
- Video / animated content — text-first
- Per-audience interactive demos — out of scope; possibly future
- Locking in API contracts for stability — these docs describe intent, not API contracts

## Effort

- **Pillar 1 (audience map)**: ~1 SP
- **Pillar 2 (vocab + framing decisions)**: ~1 SP (mostly clarify-time work, light authoring)
- **Pillar 3 (architecture + data-flow diagrams)**: ~3 SP — Mermaid + companion prose
- **Pillar 4 (strategic decision, captured in docs)**: ~1 SP (clarify-time; doc reflects the choice)
- **Pillar 5 (competitive positioning in why-specrew.md)**: ~2 SP — careful scoping work
- **Pillar 6 (stability commitment, applied across docs)**: ~1 SP
- **Doc writing across 5 new + 2 edited files**: ~3-5 SP
- **Total**: ~10-15 SP, single iteration. Realistic with re-scoping: 12 SP.

## Phase placement

**Phase 2 — Tier 1 methodology adoption gate**. Adoption is gated on positioning; positioning is gated on this proposal. Ships before any external-tester / public-adoption-window work.

Sequencing recommendation:

1. Vocabulary-lock chore (~1-2 SP) ships first (or vocab-lock Decision A is made and applied inline in 098)
2. 098 ships next; forces the strategic decisions in Pillars 2 + 4
3. Proposal 013 (Methodology Site) ships later, consuming 098's in-repo content
4. Updates to README + architecture.md cadence after 024 ships (multi-host runtime)

## Open questions

1. **Vocabulary-lock first, or inline in 098?** Recommendation: inline if scope is small (just "Squad" vs "Crew"); separate chore if it touches more.
2. **Framing choice (Pillar 2 Decision B)** — defer to clarify time; recommended technique: present 4 candidate framings to 3-5 sample readers (or persona-prompted AI runs); pick highest-clarity-with-lowest-bounce score.
3. **Vendor-agnostic decision (Pillar 4)** — strategic; not for 098 author to decide. Surface as clarify-time blocker.
4. **`docs/why-specrew.md` competitor mentions** — name specific products (Spec-Kit, agents-ui, Antigravity)? Or only categories? Recommendation: name once each as category exemplars; no detailed capability comparison.
5. **Should `docs/methodology.md` cite academic SDD / SE literature?** If yes, citation discipline applies. Recommendation: yes, lightly — sets credibility, but no formal bibliography overhead.
6. **README length budget** — current README is moderate length. Should 098's revised version be tighter or richer? Recommendation: tighter at top (60-sec answer), with structured "learn more" links; total length not significantly longer.
7. **Per-audience docs vs persona-based docs vs one-size-fits-all** — 098 picks per-audience. Other proposals (Proposal 015 Expertise-Aware Adaptive Interaction) propose persona-adaptive content. Worth coordinating at clarify time.
8. **Should this proposal include a one-pager handout** (PDF / Markdown) for sharing? Recommendation: out of scope at MVP; downstream of 013.
9. **Adoption.md is the riskiest doc** — making concrete cost/benefit/risk claims requires data we may not have. Recommendation: ship with "as of YYYY-MM-DD" framing and explicit estimates rather than precision-implying numbers.
10. **Methodology.md audience overlap with academic talks / papers** — Alon presents Specrew externally periodically. Should methodology.md mirror talk content? Recommendation: yes — single source, multiple renderings.

## Risks

1. **Strategic decision (vendor-agnostic vs GitHub-first) gets deferred** — proposal stalls. *Mitigation*: name the decision as a clarify-time blocker; cannot proceed without it.
2. **Framing chosen poorly** — "meta-framework" framing bounces engineers; "guardrails" understates methodology. *Mitigation*: test multiple framings before locking; willingness to revise if early external feedback shows the wrong choice was made.
3. **Competitor positioning ages** — Antigravity 2.0 specifics in research doc were partly fabricated; any docs citing competitor capabilities go stale. *Mitigation*: category-level positioning only; specific capabilities not cited.
4. **Vocabulary lock incomplete at ship** — docs ship with mixed terms. *Mitigation*: lock vocab first OR explicit "terms in transition" callout in 098 docs.
5. **Duplication with Proposal 013 (Methodology Site)** — content forks. *Mitigation*: explicit boundary (098: in-repo technical docs; 013: external rich site); shared content rendered from single source.
6. **Stability commitment broken** — stable docs end up revised frequently. *Mitigation*: explicit revision-trigger discipline (only on architecture changes); version-stamped at top.
7. **Reader fatigue** — too many new docs intimidates instead of clarifying. *Mitigation*: README is the single highest-priority surface; other docs are linked from it but not required reading; clear "start here" pathway.
8. **Researcher / methodologist audience may not exist in adoption-window users** — methodology.md serves no real reader. *Mitigation*: write it last; treat as low-priority; skip if effort overruns.
9. **`docs/adoption.md` claims become marketing claims** — risks setting expectations Specrew doesn't meet. *Mitigation*: hedge language; specific estimates with date-stamped "as of YYYY-MM-DD"; explicit caveats on early-stage methodology.

## Cross-references

- **Composes with**:
  - [013 Methodology Site](013-methodology-site.md) — external public site; 098 is in-repo docs; explicit content-sharing boundary
  - [015 Expertise-Aware Adaptive Interaction](015-expertise-aware-adaptive-interaction.md) — alternative audience-handling model (persona-adaptive); coordinate at clarify
  - [024 Multi-Host Runtime Abstraction](024-multi-host-runtime-abstraction.md) — 098's diagrams drawn for the post-024 state
  - [081 Reviewer Visual Evidence (Mermaid Mandate)](081-reviewer-visual-evidence.md) — diagrams use Mermaid
  - [094 Documentation Update Discipline](094-documentation-update-discipline.md) — these docs participate in the docs gate
  - [097 Coupling Surface Catalog](097-coupling-surface-catalog.md) — README mentions coupling-tracking discipline; adoption.md cites coupling hygiene as a benefit
- **Forces decisions for**:
  - Vendor-agnostic vs GitHub-first strategic position (currently undecided; affects all multi-host proposals)
  - Vocabulary lock (Squad vs Crew)
  - Framing choice (meta-framework vs guardrails vs other)
- **Sources**:
  - External research document received 2026-05-22 (identified positioning gap; some specifics unverified — see memory `project_research_document_2026_05_22`)
  - Memory `project_methodology_first_prioritization_2026_05_16` (adoption-window timing)
  - Memory `project_github_coupling_investigation_2026_05_22` (vendor-agnostic vs GitHub-first state)

## Status history

- 2026-05-22: status set to `candidate`. Drafted in response to external research document identifying positioning gap. Adoption-gate proposal: low effort, high leverage, forces several deferred strategic decisions to clarify time. Awaiting clarify-time decisions on framing, vocabulary, and vendor-agnostic vs GitHub-first stance.
