---
proposal: 163
title: Code & Implementation Lens (implementation-craft decisions in the design workshop) — RESEARCH-NEEDED
status: candidate
phase: phase-2
estimated-sp: 6-9 (research-dependent; see Research Needed)
priority-tier: 2
discussion: surfaced 2026-06-05 by the maintainer during the testLenses8 / testLenses11 cross-host workshop dogfooding (the wrong-keyboard-layout .NET 10 utility). The 9 design lenses cover WHAT the system is; none covers HOW the code is written. Scope and content are explicitly research-needed before spec conversion.
---

# Code & Implementation Lens (implementation-craft decisions in the design workshop)

## Why

The design-workshop lens catalog has 9 lenses — architecture-core, component-design, requirements-nfr, ui-ux,
data-storage, security-compliance, integration-api, devops-operations, observability-resilience. Every one of
them is about **what the system is**: its structure, its decomposition, its quality attributes, its data, its
trust boundaries, its surfaces. **None covers *how the code is written* — the implementation craft.** Those
decisions (language version, how util code is packaged, whether DI is used, file and function size discipline,
comment policy) are real, consequential, and stack-specific, and today they are made ad-hoc during `implement`
rather than decided with the human up front like every other design dimension.

The maintainer named the gap concretely (testLenses8/11 intake of a .NET 10 utility): the use of programming-
language constructs; the length of files / functions / lines; the amount of comments in code; the use of
dependency injection, builder, and other design patterns; using the latest version of the language; how to
package a utility class (NuGet package vs. a referenced project); and the fact that **each language and
platform has different dilemmas**.

## What (provisional — pending research)

A 10th design lens, `code-implementation` (working name), that the workshop surfaces alongside the others and
that captures implementation-craft decisions as **binding constraints for the implement phase** — the same way
architecture-core captures the decomposition style. Provisional decision points:

- Target language **version** and which modern constructs are in/out (e.g., C# records / file-scoped namespaces;
  TS strictness; Python typing).
- **Dependency injection** and **design-pattern** posture (DI container vs. manual composition; where builder /
  factory / strategy patterns are expected vs. discouraged).
- **Size discipline**: file / function / method length norms and the cognitive-complexity bar.
- **Comment policy**: how much, what kind (intent vs. narration), per [074 commentary standards](074-code-commentary-standards.md).
- **Packaging** of shared/util code: NuGet package vs. project reference vs. internal shared assembly — and the
  equivalent decision in other ecosystems.
- **Per-stack / per-platform dilemmas**: the right defaults differ by C#/.NET, TS/JS, Python, Go, Java, etc.

## The central open question: record-only vs. enforced

This decides the scope, the effort, and the composition, and it is **not yet settled**:

- **Record-only** — the workshop surfaces and records the conventions; the implementer reads them; the reviewer
  judges adherence qualitatively. Cheapest (~6-9 SP), composes cleanly, no new gate.
- **Enforced** — the recorded conventions flow into the implement phase and are checked at review by the
  mechanical anti-pattern / test-integrity checks and/or a new deterministic gate (file/function length, comment
  ratio, banned constructs). Larger, and it risks duplicating [Proposal 145](145-structured-multi-phase-reviewer.md)
  Phase-4 code-quality and the existing mechanical checks unless the boundary is designed.

## Research Needed (before spec conversion) — maintainer-flagged

**The scope and content of this lens are deliberately not decided here.** Convert to a spec only after:

1. **The right decision points** — validate/trim the provisional list against real implementation-craft choices
   that genuinely belong at design time (vs. those better left to lint config or the reviewer).
2. **The per-language / per-platform dilemmas** — research the actual decisions and proven defaults per stack
   (C#/.NET, TS/JS, Python, Go, Java, …) so the lens **recommends established conventions, not invented ones**.
3. **How existing tooling already encodes these** — `.editorconfig`, Roslyn/.NET analyzers, ESLint + tsconfig,
   ruff/black/mypy, gofmt/golangci-lint — so the lens points at the ecosystem's own mechanisms rather than
   re-inventing them, and so an "enforced" mode would configure those tools rather than build a parallel gate.
4. **The record-vs-enforce decision** and its composition with the reviewer (145 Phase 4), the mechanical
   anti-pattern / test-integrity checks, [074](074-code-commentary-standards.md), and the stack-aware tool-
   selection work (per-project tech choices already require human approval).
5. **Lifecycle binding** — where the conventions bind: a design-time decision → an `implement` constraint → a
   review check; and how they appear in the lens-applicability record and (if enforced) any gate.

## Composition map

- [[074-code-commentary-standards]] — the comment-policy decision point is this; 163 decides it at design time.
- [[156-design-analysis-lens-knowledge-catalog]] — 163 adds a lens to the catalog 156 governs (keep 156's deeper
  scope deferred; 163 is one concrete lens, not the catalog mechanism).
- [[145-structured-multi-phase-reviewer]] — Phase-4 code-quality is the review-time counterpart; an enforced 163
  must not duplicate it.
- Stack-aware tool selection — the per-stack dilemmas reuse the stack-aware catalog + the human-approval rule.
- The lens system (Amendments A1–A3 of Feature 141) — 163 is a catalog addition built on that machinery.

## Sizing

- **As a record-only workshop lens: ~6-9 SP.** Almost all of it is *content*, not plumbing: the lens md
  (Decision Points + Question Bank + Workshop Conduct) with the per-stack dilemmas is the bulk (~4-6 SP);
  registration (selector/applicability catalog, the skill's lens map, the `$lensIds` test list), applicability
  heuristic, and tests are mechanical (~2-3 SP).
- **As an enforced lens: more**, and the increment is the research output (the implement-constraint flow + the
  review/mechanical gate or the analyzer-config integration).

## Open questions

- Record-only vs. enforced (the central one above).
- One lens with per-stack sections, or per-stack depth driven by the resolved stack?
- Does it gate the specify or a later boundary, or stay advisory?
- How does it interact with stack-aware tool selection (which already gates per-project tech choices)?
- Is "latest language version" a default-on recommendation or a neutral decision point (LTS vs. latest is itself
  a per-stack dilemma)?

## Risks

- **Invented-not-proven conventions** if the per-stack research is skipped — the lens must recommend the
  ecosystem's established defaults, not the Crew's opinions. (This is why scope/content are research-gated.)
- **Per-stack scope creep** — covering every language well is large; a first version may scope to the resolved
  project stack + a small default set.
- **Overlap with the reviewer / mechanical checks** in an enforced mode — needs an explicit boundary so 163
  decides conventions and 145 / the mechanical checks verify them, without duplication.
