---
proposal: 013
title: Methodology Site
status: candidate
phase: phase-2
estimated-sp: 20
discussion: tbd
---

# Methodology Site

## Why

Specrew's philosophy and methodology — squad agents, governance, hardening gates, retros, the learning loop, the corpus-row graduation pipeline — needs a landing experience that the in-repo README can't deliver. A cold-arrival visitor to the GitHub repo needs:

- A 30-second elevator pitch
- The "why Specrew vs raw Spec Kit" answer
- A conceptual overview of squad agents, governance, hardening gates
- The learning-loop story
- A getting-started walkthrough

The README is for engaged developers; the methodology site is for the broader audience of people deciding whether Specrew is worth their attention.

## What

A GitHub Pages site published from `docs/site/` or similar:

**Sections**:

1. **Landing page** — elevator pitch, key differentiators
2. **Why Specrew vs raw Spec Kit** — concrete: governance + lifecycle boundaries + hardening gates + retros + validator-enforced rules
3. **Methodology overview** — squad agents, hardening gates, retros, corpus row graduation (the meta-framework angle)
4. **The learning loop** — retros → corpus → enforcement pipeline; how recurring patterns graduate from passive guidance to validator-enforced rules
5. **Getting started** — 5-minute happy path: `specrew init`, `specrew start`, first feature, first iteration
6. **Lifecycle diagram** — visual map of the 7 boundaries (specify → clarify → plan → tasks → implement → review → retro → closeout)
7. **Examples / showcases** — Clipboard corpus (ClipBoard2 → ClipBoard6) as worked examples showing methodology evolution
   plus a future gallery slot for Feature 017 velocity dashboard snapshots so
   the site can reuse real closeout artifacts as lightweight showcase material
8. **For contributors** — pointer to CONTRIBUTING.md, methodology Discussion category, corpus-row-candidate issue template
9. **Roadmap** — phase model + current focus + what's next

**Architecture**:

- Tool: MkDocs Material (subject to stack-aware human approval at clarify time)
- Source: `docs/site/` (separate from internal-developer docs)
- Build: GitHub Action on push to main; deploys to `gh-pages` branch
- Domain: Start with `<handle>.github.io/specrew`; custom domain later if warranted

## Effort

- **Iteration 1 (~10-12 SP)**: Infrastructure (MkDocs setup, GitHub Action, gh-pages publishing) + landing page + methodology overview
- **Iteration 2 (~8-12 SP)**: Remaining content sections (learning loop, getting started, lifecycle diagram, examples/showcases) + polish
- **Total**: ~15-25 SP

## Phase placement

Phase 2 — not load-bearing for the methodology itself (Specrew works without a site), but load-bearing for first-impression equity when the repo goes public. After Proposal 015 (Learning Loop Closure) so the learning-loop content is empirically grounded.

## Open questions

1. MkDocs Material vs Docusaurus vs Hugo? (Recommended: MkDocs Material; revisit at clarify)
2. Inline render Mermaid diagrams or static images?
3. Multi-version support (e.g., site reflects v0.x vs v1.0)?
4. Search functionality — built-in or external?
5. Comment/discussion integration on each page or methodology-discussion-only?
6. Translation support — defer or design-in?

## Risks

- **Content rot**: site stays current vs ships once. Mitigation: tie to release events (every minor version bump triggers site rebuild + manual content review).
- **Audience scope creep**: trying to serve both engaged contributors and curious passersby in one site. Mitigation: clear navigation hierarchy; landing page is for passersby, sub-pages are for engaged.
- **Tool lock-in**: MkDocs vs other generators. Mitigation: content is markdown; tool can be swapped if needed.

## Cross-references

- Composes with: Proposal 028 (Public Proposals Surface) — site links to `/proposals/` as the roadmap surface
- Composes with: Proposal 012 (Visual Artifact Extension) — diagrams embed in site
- Placeholder integration: Feature 017 dashboard snapshots (`dashboard.md` /
  `closeout-dashboard.md`) can become showcase inputs once the methodology site
  starts publishing examples
- Sources from: weekend article + conference talk material
- Audience: cold-arrival public visitors (distinct from engaged contributors)

## Status history

- 2026-05-14: candidate captured during pre-public-flip planning
