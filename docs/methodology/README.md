# Specrew Methodology Documentation

This directory contains the methodology contract that governs Specrew development. The documents serve multiple audiences — implementers, reviewers, AI agents, and external contributors — with role-specific reading paths.

## Documents

| Document | Audience | Purpose |
|---|---|---|
| [lifecycle-discipline.md](lifecycle-discipline.md) | **All participants** (implementers + reviewers) | Shared methodology: the session bootstrap model (hook-driven auto-orientation + rolling-handover continuity), boundary discipline, spec authority, traceability, drift, committed-tree durability, lifecycle metadata, spec coverage verification, release process discipline (repo/CI/package-registry/prerelease-vs-stable), and the Form-Without-Runtime-Compliance Shape Catalog (8 shapes). |
| [review-instructions.md](review-instructions.md) | **Reviewers** (human + AI) | Review-specific guidance: how to bootstrap a review session, review method (8 steps), common failure modes, approval/rejection criteria, when to recommend cross-reviewer verification, verdict format + naming discipline, severity guidance, reviewer mindset, and how to verify agent diagnoses against hallucination. |
| [proposal-discipline.md](proposal-discipline.md) | **Both implementers + reviewers** | Proposal management: how to create / update / discuss / validate proposals, the validation consistency rules, and the strategic composition patterns observed in Specrew's proposal ecosystem. |
| [design-workshop-methodology.md](design-workshop-methodology.md) | **All participants** (human developers + AI agents) | The Design Workshop methodology: the facilitated, lens-driven human-agent design conversation at specify/intake and the design-analysis stop — core principles (render-before-asking, co-design before options, honest confirmation provenance), the eleven-lens / three-band catalog (product-domain first, the nine technical lenses, then code-implementation auto-on for code-writing features), the seven-phase workshop flow, the artifact contract, anti-patterns, and the workshop reviewer checklist. |
| [superpowers-comparative-analysis.md](superpowers-comparative-analysis.md) | **Methodology designers** | Comparative analysis of `obra/superpowers`: reusable execution and review patterns, limits, proposal ownership, and the adopt/adapt/reject decisions behind Proposals 139, 145, and 207. |

## Reading Paths by Role

| Reader role | Read in this order |
|---|---|
| **Iteration reviewer** (review-signoff, retro, iteration-closeout) | `review-instructions.md` end-to-end + `lifecycle-discipline.md` (Boundary Discipline / Spec Authority / Traceability / Drift / Committed-Tree Durability / Lifecycle Metadata / Spec Coverage Verification / Shape Catalog) |
| **Feature-closeout / PR / Release reviewer** | All of iteration reviewer reading + `lifecycle-discipline.md` (Release Process Discipline section: Repository / SDLC Steps 5-14 / CI / Package Registry / Prerelease-vs-Stable / Reviewer Checklist by Boundary) |
| **Proposal reviewer** (any commit touching `proposals/*.md`) | `review-instructions.md` (Bootstrap + Source of Truth + Review Method) + `proposal-discipline.md` end-to-end |
| **Implementer / Crew agent** | `lifecycle-discipline.md` end-to-end (this is the shared contract you must honor); `design-workshop-methodology.md` end-to-end before facilitating any specify-intake or design-analysis workshop; skim `review-instructions.md` for awareness of reviewer expectations (skip Approval/Rejection Criteria + Verdict Format + Severity Guidance — those are reviewer-only judgment surfaces); `proposal-discipline.md` if creating/updating proposals |
| **Design-workshop facilitator or reviewer** (specify-intake, design-analysis stop) | `design-workshop-methodology.md` end-to-end — facilitators follow the Workshop Flow phases; reviewers apply the Reviewer Checklist + Common Anti-Patterns sections |
| **AI agent acting in any role** | Read everything in this directory. `review-instructions.md` Bootstrap section addresses cold-start orientation for AI sessions. |
| **First-time reader / new contributor** | Start with `lifecycle-discipline.md` Purpose + Boundary Discipline; then `review-instructions.md` Reviewer Mindset; then jump to role-specific reading per the table above |

## How These Documents Are Maintained

These documents are version-controlled with Specrew itself. Updates land via Specrew lifecycle (proposal → feature → iteration → review-signoff) like any other deliverable. When a new dogfooding incident reveals a methodology pattern, the relevant document gets updated; the empirical-provenance sections track which incidents motivated which rules.

Cross-references between the documents in this directory use relative paths (`./review-instructions.md`, `../proposals/INDEX.md`, etc.) so the docs remain navigable from any location in the Specrew tree.

## Provenance

These documents originated as a single `ReviewInstructions.md` maintained outside the Specrew repository (`C:/Dev/SpecrewReviewInstructions/`). Co-located into `docs/methodology/` so:

- AI reviewers can cite specific sections in `rejected for <boundary>` verdicts (concrete guidance > vague hints)
- Implementers have transparent visibility into reviewer expectations (transparent contract, not hidden rubric)
- Multi-machine access (laptop + desktop) follows the repo, no sync drift
- External contributors have methodology access without needing personal dev folders
- Version-controlled methodology evolution becomes a first-class concern alongside code evolution

The original local file is preserved as historical reference; future updates flow through `docs/methodology/` and propagate back to local working copies via standard git pull.
