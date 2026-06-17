---
proposal: 195
title: Quality & Testability Design Lens (Facilitative, Sized by Complexity × AI/Human Interaction)
status: candidate
phase: phase-2
estimated-sp: 8-13
priority-tier: 2
discussion: surfaced 2026-06-16 while auditing whether the design workshop has a QA/testability lens. It does not — "testing-and-quality" is only a SECONDARY category folded thinly into requirements-nfr and observability-resilience, and every other quality surface (the quality-gate lenses robustness/security/test-integrity, and Proposal 145's reviewer) acts at REVIEW time. There is no DESIGN-time lens where the team designs FOR testability and chooses a verification approach before code exists. Grounded in a six-stream best-practices sweep (2025-2026) across languages, frameworks, OS/CI, agentic evals, and test-governance standards; ideas also adopted from addyosmani/agent-skills.
composes-with:
  - 020  # Spec-Scenario Integration Test Mandate
  - 044  # Downstream Quality Baseline Bootstrap
  - 112  # Quality-Tier Routing + Bug-Test-First
  - 163  # Code-Implementation Lens (sibling lens; hosts no test-strategy today)
  - 192  # Test-First (TDD) Workshop Option (this lens HOSTS its decision point)
  - 135  # Per-User-Story Multi-View Design Diagram Coverage
  - 145  # Structured Multi-Phase Reviewer (consumes this lens's decisions at review)
  - 156  # Workshop-Decisions producer manifest
  - 174  # Boundary Variance Disclosure
  - 197  # Continuous Co-Review (the inline shift-left reviewer that consumes this lens as a rubric)
---

# Quality & Testability Design Lens

## Why

The design workshop has 11 lenses (product-domain, architecture, data, ui-ux, security,
integration, devops, requirements-nfr, observability, component, code-implementation).
**None designs for quality or testability.** "testing-and-quality" exists only as a *secondary
category* inside `requirements-nfr` and `observability-resilience`, so it is nobody's primary
responsibility. Every other quality surface acts AFTER code exists: the quality-gate lenses
(`robustness-baseline` / `security-baseline` / `test-integrity`) run at the quality gate, and
Proposal 145's 7-phase reviewer runs at `review-signoff`. By then the design is fixed — if it
is not testable (no seams, hidden global state, no observable outputs) the reviewer can only
file a finding against a decision already cemented.

This is the design-time half of Specrew's anti-vibe-coding mission. A test written next to (or
after) the code it covers tends to assert *what was built*, not *what was specified* (Proposal
192's point). And in the AI-authored era the economics invert: **AI makes test-WRITING cheap,
so test-INTENT becomes the scarce, human-owned thing** — when an agent writes the code, the
test suite is the *primary* trust mechanism, not a safety net. Deciding the verification
approach BEFORE implementation — test strategy, portfolio shape, design-for-testability seams,
quality-attribute scenarios, evaluation approach for any AI/agentic parts, and what is honestly
NOT tested — is a design decision, and design decisions belong in the workshop.

This lens is **facilitative**: it OFFERS and RECOMMENDS a menu and captures the human's choices.
It does not mandate a testing capability. The actual capability is sized by the project.

## What

A new **`quality-testability` design lens** that the workshop facilitates like security or
observability (a co-designed discussion, not a checklist hand-off), owning the
`testing-and-quality` category as PRIMARY and producing a captured, validator-checkable record
that the Proposal 145 reviewer consumes.

### The sizing model (the structural spine)

The lens recommends along **two axes**, never a fixed prescription:

1. **Project complexity / risk** — three tiers the research consistently supports:
   **[S]** simple/hobby/solo · **[M]** moderate team product · **[C]** complex / regulated /
   safety-critical. Risk-based testing (ISTQB; risk = likelihood × impact) is the engine that
   places a feature on this axis.
2. **AI/Human interaction model** — the modern second axis. Two sub-questions: *does the
   SOLUTION contain AI/LLM/agentic code?* (→ its outputs are non-deterministic and need *evals*,
   not asserts) and *who AUTHORS the code — human or agent?* (agent-authored code elevates
   executable specs, property-based, contract, and mutation testing, and demands human review of
   test *intent*, because agents trivially produce assertion-free, coverage-padding tests). The
   governance research is blunt here: **an AI-bearing feature is rarely [S] on testing even when
   the codebase is small.**

The lens recommends the **lowest tier that covers the target** and escalates only on a named
trigger. This is the anti-over-engineering guardrail: tiering is exactly what keeps heavy
testing off trivial projects while fighting under-engineering on serious ones.

### Functional requirements

- **FR-001** — Register the lens: `knowledge/design-lenses/quality-testability.md` + an
  `index.yml` entry + an `applicability-map.json` entry, following the existing lens schema
  (Purpose / Applicability Signals / Design Decision Points / Workshop Conduct / Question Bank /
  Alternative Dimensions / Plan Obligations / Validation Signals).
- **FR-002** — Design Decision Points the facilitator raises (recommend, don't mandate):
  - Portfolio shape: pyramid vs trophy vs honeycomb, sized to where the risk/complexity lives.
  - Test strategy: test-first (TDD) vs test-alongside (hosts Proposal 192's decision).
  - **Design-for-testability**: the seams, dependency boundaries, pure cores, and observable
    outputs that make the design verifiable — and what must change to get them.
  - Which TEST TYPES apply per FR (from the test-type catalog, FR-004), and which explicitly do
    not (with reason).
  - Quality-attribute scenarios (perf / security / a11y / reliability) with *measurable*
    thresholds, not adjectives.
  - Fixture/anchor realism: real vs synthetic, and where synthetic is acceptable (Shape-6 lesson).
  - **AI/agentic evaluation** (conditional, FR-005): how non-deterministic AI parts are evaluated.
  - **AI-driven manual** (FR-006): where an agent-driven exploratory session is the right verification.
  - Coverage intent per type (FR-007) — and the honest non-goal.
  - The test plan + who approves it (FR-008/009).
  - What is explicitly NOT tested, and the honest reason.
- **FR-003** — Workshop Conduct carries three devices adopted from addyosmani/agent-skills: an
  **anti-rationalization table** (rebuts "we'll test later", "it's too hard to test", "the happy
  path works", "coverage is 90%", "tests are green"), a **red-flag list** (tests in the same
  commit as impl with no failing-first evidence; synthetic fixtures where real data is required;
  coverage cited as the only quality signal; mocks that mock the unit under test; zero
  negative/failure tests; snapshot/assertion-free tests), and **evidence gates** (the capture
  floor demands evidence shape, not prose).
- **FR-004** — A data-driven `knowledge/design-lenses/test-types.yml` catalog the lens reads;
  each type carries `executor` (`automation` | `ai-manual` | `human` | `automation+judge`),
  `deterministic`, `coverage_notion`, `applies_when`, and idiomatic-tool pointers. Covers
  automated types (unit, integration, contract, component, e2e, property-based, fuzz, mutation,
  perf/load, stress/soak, security SAST/DAST/SCA, a11y, visual-regression, chaos), the
  **`ai-driven-manual`** type, **`human-manual`**, and the conditional **`agentic-eval`** type.
- **FR-005** — Conditional `agentic-eval` branch (fires only when the design contains
  AI/LLM/agentic code): capture the evaluation approach — structural/canary assertions first,
  then semantic/LLM-as-judge (with bias mitigations) gated on pass@k / N-run thresholds,
  regression/drift gating, agent-trajectory eval, RAG triad where applicable — plus the captured
  eval rubric, dataset reference, and pass threshold.
- **FR-006** — `ai-driven-manual` capture: a session **charter** + where the agent drives the
  session (Playwright MCP / Chrome DevTools MCP / Specrew `verify`/`run`) + the artifacts a
  session produces (session log, evidence, repro = the agent's trajectory, debrief). Framed as
  **supervised autonomy** — agent explores/flags, human reviews before anything enters the suite.
- **FR-007** — Coverage **intent** captured per type (requirement/scenario, branch, and where
  warranted **mutation** coverage) — never a single coverage-% target (the research is emphatic
  that coverage % is a weak goal; mutation + requirement coverage are the honest metrics).
- **FR-008** — Test plan artifact + a greppable, floor-validated capture record with
  `## Test Strategy`, `## Testability`, `## Quality-Attribute Scenarios`, and `## Test Plan`
  sections (always written; one line when a tier is `n/a`). Mirrors the F-141 design co-design
  record floor.
- **FR-009** — Test-plan **approval** recorded at the design-analysis/plan boundary, sized by
  tier (informal team-OK at [S] → formal signed approval at [C]); composes Proposal 155 (typed
  gate packet) and Proposal 113 (acceptance gate). Proposal 145 later verifies execution
  **against the approved plan** — closing the loop: planned → approved → executed → reviewed.
- **FR-010** — Alternative Dimensions per the Specrew Simplest / Reasonable / By-the-book pattern,
  populated from the tier menu in "Research basis" below.
- **FR-011** — Captured decisions flow into Proposal 156's `workshop-decisions.yml`; deviations
  route through Proposal 174's boundary-variance path.
- **FR-012** — Cross-host delivery via the `specrew-design-workshop` skill loading this lens md
  per the F-141 i10 pattern, with FileList + mirror parity; an on-demand
  `quality-testability/testability-checklist.md` supporting file (agent-skills pattern; keeps the
  launch prompt lean).
- **FR-013** — Integration tests for lens registration, conduct delivery, and the capture floor.

### Out of scope (two explicit spillover siblings)

The lens **DECIDES and CAPTURES** the verification approach and produces the test plan. It does
**not BUILD** the executors. That keeps it ~8-13 SP. Two pieces spill out as their own slices:

- **Agentic-eval execution harness** — a real eval harness (eval datasets, LLM-judge calibration,
  CI eval-gating, drift regression) is its own proposal if you want it built, not just decided.
- **Test-plan-approval as a dedicated gate** — whether approval is a section of the plan-gate
  packet or its own boundary touches gate machinery (155/113); resolve as a sibling, not here.

Also out of scope: auto-generating tests from FRs (Proposal 192's "future slice" / a
context-navigator agent); stack-specific CI red→green enforcement (the task contract carries
that); replacing `requirements-nfr` / `observability-resilience` (they keep `testing-and-quality`
as a secondary cross-reference — see Open Question 1).

## Research basis (distilled)

A six-stream 2025-2026 best-practices sweep grounds the lens menu. Full per-language /
per-framework / per-OS matrices become the implementation-time catalog data (FR-004), not
proposal body. What the proposal carries: the tier menu, the choice-changing facts, and curated
sources.

### Baseline menu by tier

- **Simple [S]** — pyramid-shaped unit + a few integration; smoke/sanity; dependency (SCA) +
  secrets scanning; axe-in-CI if public-facing; a growing regression suite; branch coverage as a
  *diagnostic* (no target). TDD optional. *If it touches AI → add a small eval rubric even here.*
- **Moderate [M]** — add a fat integration/trophy layer; component tests; contract tests if
  multi-service; BDD/ATDD for stakeholder-facing rules; property-based on core logic; mutation
  testing on critical modules; load testing; visual regression on key pages; flaky-test
  quarantine; hermetic small tests; factories over fixtures; requirement traceability. *AI
  feature → single-dimension rubrics + a calibrated LLM-judge gate.*
- **Complex / regulated [C]** — honeycomb for microservices; consumer-driven contracts; E2E on
  critical journeys only; fuzzing on parsers/security surfaces; stress + soak; SAST/DAST + OWASP
  ASVS L2/L3; full WCAG 2.2 AA audit + assistive-tech testing; chaos/resilience with game days;
  mutation + requirement coverage as the metrics; cross-platform OS matrix; ISO/IEC/IEEE 29119
  master plan with approved entry/exit/suspension criteria + bidirectional traceability +
  go/no-go summary; rigor scaled to DAL/ASIL/safety-class. *AI feature → continuous evaluation,
  adversarial/safety suites, human-in-the-loop on high-impact paths.*

### Choice-changing facts the lens should surface (not bury)

- **Coverage % is a weak goal** (Goodhart) → use it diagnostically; **mutation + requirement
  coverage** are the honest quality signals — and are *especially* honest for agent-authored
  suites that trivially pad coverage %.
- **Prefer deterministic structural / canary-token assertions before LLM-as-judge** for AI
  outputs; LLM-as-judge has documented position/verbosity/self-preference bias → mitigate
  (order-swap, reference-guided, different-provider judge, human calibration); gate on
  pass@k / N-run thresholds, never a single run.
- **Licensing/governance landmines** to flag at design time: .NET **FluentAssertions v8 went
  commercial** (→ AwesomeAssertions / Shouldly to stay OSS); **Moq SponsorLink** controversy
  (→ NSubstitute). Java **`@MockBean` deprecated (Boot 3.4)** → `@MockitoBean`.
- **Active transitions that are design decisions now**: JS **Jest → Vitest** (new ESM/Vite/TS
  work); Swift **XCTest → Swift Testing** (UI automation stays XCUITest); .NET **VSTest →
  Microsoft.Testing.Platform**; Java **JUnit 5 → 6**; Angular **Vitest is the v21 default**.
- **Real dependencies over in-memory** for meaningful integration tests (**Testcontainers**;
  in-memory H2/SQLite discouraged); **Schemathesis** for OpenAPI-driven testing (Dredd is
  legacy/uncertain).
- **AI-driven manual is supervised-autonomy only** today (computer-use agents still unreliable on
  real desktop tasks) — agent explores/flags, human reviews before the suite.
- Adoption "most-used" claims are **directional** (survey-skewed); the lens recites idiomatic
  defaults, not magnitudes.

### Curated sources

- Test shape / coverage / non-determinism: Fowler *Practical Test Pyramid*, *TestCoverage*,
  *Eradicating Non-Determinism*; Kent C. Dodds *Testing Trophy*; Spotify *Testing of
  Microservices* (honeycomb); web.dev *ta-strategies*; Frontiers 2025 *Test Pyramid 2.0*.
- Types/quality: Stryker (mutation); fast-check + Anthropic *Property-Based Testing with Claude*;
  Go Fuzzing + OSS-Fuzz; Grafana load-testing taxonomy; OWASP ASVS 5.0; Deque axe-core + W3C
  WCAG 2.2; Playwright visual comparisons; principlesofchaos.org; *SWE at Google* (test sizes) +
  Google Testing Blog (flaky tests).
- Governance: ISO/IEC/IEEE 29119 (-2/-3), IEEE 829, ISTQB glossary (risk-based, entry/exit,
  traceability) + ISTQB CT-AI v2.0; DO-178C / ISO 26262 / IEC 62304 for regulated rigor.
- Agentic eval / AI-manual: OpenAI *Evaluation best practices*; promptfoo / DeepEval / Ragas /
  Inspect (UK AISI) / LangSmith / Braintrust / Langfuse / Phoenix; LLM-as-judge bias surveys
  (arXiv 2410.02736, 2410.21819); Playwright MCP + Chrome DevTools MCP; session-based test
  management (charters/debrief).
- Language/framework idioms: official docs (State of JS 2024/25, JetBrains surveys, Vitest /
  Vue / Angular / FastAPI / Spring Boot / .NET / Rails / Swift Testing / Pester docs).
- Skill design devices: addyosmani/agent-skills (`test-driven-development`,
  `code-review-and-quality`, `debugging-and-error-recovery`).

## Effort

- **Iteration 1 (~8-13 SP)**: lens md + conduct (with the three agent-skills devices) +
  `test-types.yml` catalog + index/applicability registration + capture-floor validator +
  supporting checklist + cross-host delivery + tests. Single-iteration shippable, sized like
  Proposals 163/176 (prior lens features).

## Phase placement

Phase-2, design-workshop maturation track — after Proposal 192 (so the TDD decision point lands
here once, not twice) and alongside the Proposal 145 reviewer it feeds. Sequence behind any
in-flight design-workshop-skill changes (the F-141 i10 delivery pattern is the substrate).

## Open questions

1. **(Lead) Overlap boundary.** Confirm the line: this lens = *design-time test strategy &
   testability*; the quality-gate lenses (`test-integrity` etc.) = *review-time execution*;
   Proposal 145 = *review-signoff verification*; `requirements-nfr` / `observability-resilience`
   keep `testing-and-quality` as a *secondary cross-reference* pointing here. Resolve first at spec.
2. Does Proposal 192 get **absorbed** here or **compose**? (Recommend: this lens hosts the
   test-strategy *decision*; 192 keeps its `test-author` scaffold + ordering validator.)
3. Default phase: `specify-clarify-design-analysis` (decide strategy early) or `design-analysis`?
4. Applicability per slice-type: software-feature = yes; docs-only = n/a; bug-bash = a
   reproduction-first variant (composes Proposal 112's Bug-Test-First)?
5. Capture-floor hard-block vs warn-during-adoption (the 145 warn-then-block precedent)?
6. Spin the **agentic-eval execution harness** and **test-plan-approval gate** out as named
   sibling proposals now, or note them as deferred?
7. Keep the full six-stream synthesis as a companion `knowledge/design-lenses/quality-testability-research.md`
   that seeds the catalog data, or rely on the curated sources above?

## Risks

- **Lens proliferation / workshop fatigue** (N+1 lenses) — mitigate via applicability-map gating,
  `n/a-with-reason`, and the lowest-tier-by-default rule.
- **Overlap confusion** with requirements-nfr, observability-resilience, the quality-gate lenses,
  and 145 — mitigate with a crisp purpose boundary at the top of the lens md (Open Q1).
- **Anti-rationalization prose gets skimmed** (the F-141 rule-skimming lesson) — keep it in the
  per-lens md the skill loads on demand, and PoC-test the conduct before scaling.
- **Catalog staleness** (tools/transitions move fast — FluentAssertions, MTP, Swift Testing) —
  the catalog is data (`test-types.yml` + checklist), refreshable without code; the proposal
  carries discriminators, not pinned versions.
- **Misread as over-engineering** — it is the opposite (design-FOR-testability fights
  under-engineering); the two-axis sizing keeps it right-sized per feature.

## Cross-references

- Related proposals: 020, 044, 112, 163, 192, 135, 145, 156, 174, 197; lens-feature precedents 176
  (product-domain) and 163 (code-implementation); 058 (skill deploy), 132 (mirror parity),
  177 (workshop-results skill promotion).
- External: addyosmani/agent-skills; the curated source list above.

## Status history

- 2026-06-16: candidate drafted after a workshop-lens audit confirmed no design-time
  QA/testability lens exists; grounded in a six-stream best-practices sweep + agent-skills ideas.
