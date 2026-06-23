---
proposal: 201
title: SDD-Framework Profile Abstraction & Dynamic Gate Sequence
status: candidate
phase: phase-3
estimated-sp: program-scale (60-100+ SP across many features; far over the 20 cap — see Sequencing)
priority-tier: 3
discussion: 2026-06-23 SDD-abstraction audit + a 5-stream landscape survey. Spec-Kit is hardwired/unabstracted (112 `speckit` files, 223 `.specify` refs, `plan.md`×159, governance namespaced to `extensions/specrew-speckit`, no SDD abstraction) — the inverse of the cleanly-abstracted host dimension. The survey (OpenSpec, Kiro, spec-workflow-mcp, BMAD v6, Agent OS v3, Tessl + others) shows SDD lifecycle SHAPES diverge across-axis AND per-version, so a fixed gate sequence cannot cover the field. Captures the research so it is not lost; know-not-do (no commitment to add a second SDD soon).
---

# SDD-Framework Profile Abstraction & Dynamic Gate Sequence

## Why

Specrew layers governance + **enforced** approval gates on top of a Spec-Driven Development (SDD) framework — today, GitHub Spec-Kit, hardwired. To support a second SDD (OpenSpec or another) you must first abstract the SDD-framework dimension. The 2026-06-23 audit shows this is the **inverse of the host dimension**: hosts are cleanly abstracted (`hosts/` package + registry + firewall); the SDD layer is hardwired everywhere:

- **112 files** reference `speckit`; **223** raw `.specify/` literals with **no central resolver**; the entire governance layer is the single `extensions/specrew-speckit/` extension; **no SDD-framework abstraction exists**.
- Spec-Kit's **artifact filenames are assumed pervasively**: `plan.md` (159 refs), `spec.md` (68), `tasks.md` (33).
- The lifecycle is Specrew's **core**, not its edge — so the blast radius is large.

The landscape survey then surfaces the deeper finding: SDD lifecycle **shapes diverge fundamentally** (and shift per-version), so Specrew's gate sequence — today a hardcoded constant — must become a property of the SDD profile.

This proposal captures the research durably. It is **know-not-do**: the value now is the abstraction insight shaping current design; building it is gated on a concrete decision to add a second SDD.

## The core insight: Specrew's differentiation is enforcement, not the gate points

The survey's strongest finding: across nearly every SDD framework, **approval gates are conventional, not enforced** — OpenSpec ("by convention"), Spec-Kit ("no automation forces advancement"), Kiro's Quick Plan (bypasses gates entirely); only spec-workflow-mcp's dashboard approvals and BMAD v6's PASS/CONCERNS/FAIL come close. Specrew **enforces** (deterministic gates, hooks, verdict capture).

So the right architecture is **Specrew as the phase-sequence-agnostic enforcement layer that clamps onto whatever shape an SDD profile declares.** That positioning ("the enforcement layer for any SDD") generalizes far better than "support OpenSpec," and it is the strategic reason the abstraction is worth its (substantial) cost.

## Today's coupling (audit)

The gate order is the one bright spot — centralized in a single function, `Get-SpecrewCanonicalBoundaryTypes` (`extensions/specrew-speckit/scripts/shared-governance.ps1`):

```
specify → clarify → plan → tasks → before-implement → review-signoff → retro → iteration-closeout → feature-closeout
```

It is a **blend of two layers**:

- **Front half** (`specify/clarify/plan/tasks`) = *Spec-Kit's lifecycle phases*.
- **Back half** (`before-implement/review-signoff/retro/iteration-closeout/feature-closeout`) = *Specrew's own governance overlay, which is SDD-independent.*

Honest nuance: changing the gate **order** is cheap (one function). Changing what each phase **means** is the real cost — what `specify` produces, what `.specify/` resolves to (223), the artifact filenames (260), the phase names literal'd across 43 files. "Centralized in one function" is *not* "half-abstracted."

## Governing principle (mirrors Proposal 200)

| Rule | Statement |
|---|---|
| **Co-design, not sequential** | Build the SDD seam **against a concrete second SDD**, not speculatively against Spec-Kit alone. An abstraction built against one implementation leaks — exactly the host lesson: the `hosts/` seam looked clean until *contemplating Devin* surfaced the `Specrew.psd1` FileList leak (Proposal 200). The second SDD is the forcing function. |
| **Profile-only** | A new SDD = a new SDD-profile package and nothing else SDD-specific. |
| **Cleanup-not-coupling** | Every Spec-Kit hardcode (`.specify`, `plan.md`, the `specify` CLI, the phase list) is fixed **generically** (profile-driven), benefiting all SDDs. |
| **Proof** | A firewall-style structural test: no `.specify` / `speckit` / `specify`-CLI literal outside the SDD profile; the allow-list shrinks. Mirrors the host-coupling firewall. |

## What an SDD profile must declare

Reuse the host-package pattern (registry + contract + firewall). Each `sdd/<kind>/` profile declares:

- **Directory convention** + a single root resolver (replaces the 223 `.specify/` literals).
- **Init command** (`specify init` vs `openspec init`) + a version contract (composes with `supported-versions.yml`).
- **Artifact set + phase→artifact mapping** (replaces `plan.md`/`spec.md`/`tasks.md` hardcodes with profile-named artifacts).
- **The native lifecycle phases (the shape)** — including non-linear shapes (change/delta-centric, spec-as-source).
- **Command surface** (slash commands) + the per-host generated-file integration (already structurally shared — OpenSpec uses the same per-tool skills + slash-commands + `AGENTS.md` pattern Specrew/Spec-Kit use).
- **The boundary→gate mapping**: which native boundaries Specrew's governance overlay attaches to.

## Dynamic gate sequence (the crux) — map to canonical intent boundaries

Rather than each profile declaring an arbitrary gate sequence, define a small, fixed set of **canonical intent boundaries** — the governance-meaningful checkpoints Specrew enforces — and have each SDD profile **map its native phases onto them**. Candidate canonical boundaries: *align-on-what → align-on-how → authorize-build → verify → close*. This keeps Specrew's enforcement layer fixed and SDD-agnostic while the SDD shape varies.

The profile mapping must accommodate fundamentally different shapes, proven by the survey:

- **Linear doc-phase** (Spec-Kit, Kiro 3-phase, spec-workflow-mcp 5-phase, BMAD v6, Agent OS v3): a near-1:1 map.
- **Change/delta-centric** (OpenSpec: `propose → apply → sync → archive` against a living `specs/` baseline): ~2 natural gate points (post-`propose`/pre-`apply`, pre-`archive`).
- **Spec-as-source** (Tessl: a regeneration loop, not a pipeline): gates around spec-approval, not phase transitions.

And it must be **per-version**: frameworks shift across versions (BMAD v4's 7-persona pipeline → v6's 4-phase model; Agent OS v3 dropped two phases; Tessl moved its spec-as-source mechanics off-core). Profiles are keyed per-framework **and** per-version-range (composes with 187/198 dependency monitoring).

## Candidate SDDs + fit

| SDD | Shape (axis) | Gate model | Fit with Specrew's enforcement |
|---|---|---|---|
| **Spec-Kit** (current) | linear doc-phase | conventional, ~7 boundaries | native (the first profile) |
| **spec-workflow-mcp** | linear doc-phase + dashboard | dashboard approvals (strongest existing enforcement) | **best-aligned alternative** |
| **BMAD v6** | phase→workflow→artifact | PASS/CONCERNS/FAIL readiness gates | **well-aligned** |
| **Kiro** | linear doc-phase | per-phase (IDE); proprietary | host IS Kiro — different integration shape |
| **OpenSpec** | change/delta-centric | anti-gate by design (~2 points) | **philosophical mismatch** — see below |
| **Tessl** | spec-as-source | spec-approval loop; commercial | shape-incompatible with a linear gate model |

**OpenSpec specifically is the philosophical outlier.** Its pitch is *"fluid, no phase gates, iterate freely"*; users choose it *because* it is gate-free. Enforcing mandatory gates on it produces something neither audience wants, and it cuts against Specrew's own principle (Specrew fights under-engineering; OpenSpec's "iterate freely" is closer to the thing Specrew counters). **Recommendation:** if a second SDD becomes real, co-design the seam against a **gate-aligned** one (spec-workflow-mcp or BMAD v6); use **OpenSpec as a shape stress-test fixture** (it proves the delta-centric path through the profile), not the first production target.

## Functional requirements (sketch)

- **FR-001** — SDD-profile package abstraction: a `sdd/<kind>/` profile registry + contract mirroring `hosts/_contract.md` + `_registry.ps1` (the only file SDD-neutral core calls).
- **FR-002** — Single SDD-root resolver replaces the 223 `.specify/` literals.
- **FR-003** — Profile-driven artifact-name mapping replaces `plan.md`/`spec.md`/`tasks.md` hardcodes.
- **FR-004** — Canonical intent-boundary model (fixed) + per-profile phase→boundary mapping; `Get-SpecrewCanonicalBoundaryTypes` becomes profile-derived; supports non-linear shapes.
- **FR-005** — Per-version profiles (version-range keyed; composes with 187/198).
- **FR-006** — A concrete second SDD profile (co-design target; recommend a gate-aligned one) as the forcing function.
- **FR-007** — The enforcement layer (deterministic gates / hooks / verdict capture) binds to abstract intent boundaries, not Spec-Kit phase names.
- **FR-008 (proof)** — Firewall-style structural test: no `.specify` / `speckit` / `specify`-CLI literal outside the SDD profile; allow-list shrinks; generated artifacts exempt (as in 200).
- **FR-009** — Specrew's governance overlay (review-signoff / retro / closeouts) explicitly decoupled from SDD phases — it is the portable asset.

## Success criteria

- **SC-001** — A second SDD added = a new `sdd/<kind>/` profile package; no SDD-specific literal outside it (firewall-proven).
- **SC-002** — The full lifecycle runs on a second SDD with Specrew's gates **enforced** at the profile's mapped boundaries (real-host validation).
- **SC-003** — Existing Spec-Kit projects unchanged (the Spec-Kit profile is just the first profile; regression-clean).
- **SC-004** — Boundary sequence + artifact names are **100% profile-derived** — zero hardcoded `.specify`/`plan.md` in core.
- **SC-005** — A non-linear-shape SDD (OpenSpec delta-centric) is expressible by the profile model (shape stress-test), even if never adopted in production.

## Risks & mitigations

- **Program-scale scope** (60-100+ SP). → Not a feature; a multi-feature arc. Don't start without the co-design trigger.
- **High blast radius** (223 + 159 + 43 touchpoints; lifecycle is core). → Co-design discipline + the firewall test contain it; the canonical-intent-boundary model limits churn to a mapping layer.
- **Premature abstraction** — building against Spec-Kit alone yields a leaky, Spec-Kit-shaped seam. → Hard rule: do not begin until a concrete gate-aligned second SDD is chosen (co-design).
- **Philosophical-fit trap** — the abstraction's existence must not pressure adopting a mismatched SDD (OpenSpec) just because it's now possible. → Keep "shape stress-test" and "production target" distinct.
- **Version drift** — per-version profiles add maintenance. → Fold into 187/198 monitoring.

## Relationship to other proposals

- **200 (Devin host clean-extensibility proof)** — the **direct methodological template**: co-design + firewall proof + profile-only. This is "200 for the SDD dimension."
- **024 (multi-host runtime abstraction)** + `hosts/_contract.md` / the host-coupling firewall — the analogous abstraction on the host dimension; reuse registry + contract + firewall.
- **187 (volatile dependency monitoring)** + **198 (self-host currency)** — per-version profiles + SDD version-drift.
- **139 (subagent orchestration)** — orthogonal (the Crew-runtime dimension).
- No existing SDD-framework abstraction proposal — this is greenfield.

## Sequencing (program, gated on the co-design trigger)

Do **not** start until a second SDD is chosen. Then, co-design against it:

1. **Phase 1 — Spec-Kit profile extraction** (extract dir resolver + artifact mapping into a Spec-Kit profile; behavior-identical; firewall asserts the existing 5-host-style invariant for SDD).
2. **Phase 2 — Canonical intent-boundary model** (fixed boundary set + Spec-Kit phase→boundary map; `Get-SpecrewCanonicalBoundaryTypes` becomes profile-derived; governance overlay decoupled).
3. **Phase 3 — Second SDD profile** (the gate-aligned co-design target) + real-host validation.
4. **Phase 4 — Shape stress-test** (express OpenSpec's delta-centric shape through the profile to prove generality).

## Open questions

1. Which gate-aligned second SDD to co-design against — spec-workflow-mcp (dashboard enforcement) or BMAD v6 (PASS/CONCERNS/FAIL)?
2. Is the canonical-intent-boundary model (profiles map native phases → fixed Specrew boundaries) the right abstraction, vs per-profile arbitrary sequences? (The former keeps enforcement fixed; strongly preferred.)
3. Is OpenSpec worth a real profile, or only a shape stress-test fixture?
4. Should host packages and SDD profiles share a common "extension package" meta-pattern (both are registry + contract + firewall)? A unified extension-package framework could serve both dimensions.
