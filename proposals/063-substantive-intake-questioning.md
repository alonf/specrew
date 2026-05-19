---
proposal: 063
title: Substantive Intake Questioning at /speckit.specify and /speckit.clarify
status: draft
phase: phase-2
estimated-sp: 25-30
discussion: tbd
---

# Substantive Intake Questioning

## Why

Specrew's value proposition is **the methodology asks questions the developer didn't know to ask**. A non-expert user has no idea they need to specify tech stack, permission model, deployment target, expected scale, MVP boundaries, or domain context. They expect the methodology to elicit those decisions through structured questioning.

Specrew today does not. Two independent empirical cases confirm the gap:

- **WSL trial 2026-05-18** — Squad silently auto-resolved scope (50 balls max), appearance model (per-ball color + preset materials), without human input. Documented in [[project-wsl-trial-autopilot-clarify-gap-2026-05-18]].
- **Gym subscription test 2026-05-19** — Single-sentence prompt "build a gym subscription management system" produced a complete implementation with only two human pauses; Squad auto-resolved tech stack from a 13-line `.vscode/settings.json` hint, plus permission model, database, frontend type, auth provider, hosting — none surfaced as substantive questions. Documented in [[project-gym-test-intake-questioning-gap-2026-05-19]].

User critique (verbatim, gym test session 2026-05-19):

> "It hasn't asked me anything... No questions about architecture, design, technology, users and user stories, hosting, many aspects of the problem domain and the solution domain. Of course if I know how to provide a good spec, we do not need this kind of questions, but not all developers know how to provide a good spec."

User refinement (2026-05-20 follow-up session):

> "If the user provided a good spec, we just need to ask some complementary questions, but if the user provide a single sentence about what he wants to build (vibe coding style), we will ask many questions - like a product, UI/UX / Architect / Project manager professionals at the beginning of a project and at the beginning of any new iteration or spec/proposal implementation. These questions drives the spec and completeness and accuracy and excellence."

The first impression of Specrew as a methodology depends on this gap closing. Without it, Specrew is useful only for the "I already know exactly what I want" segment — a small audience. With it, Specrew becomes useful for the much larger "I have an idea, help me sharpen it into a spec" segment.

## What (9 Pillars)

A persona-driven, adaptive-depth intake interview that runs at `/speckit.specify`, `/speckit.clarify`, new-iteration kickoff, and mid-feature pivot. Full design at the source spec; summary below.

### Pillar 1: Input-quality assessment (new in 2026-05-20 refinement)

Before any questions get asked, the input is scored on a per-category basis. Coverage matrix classifies the intake into one of three modes:

| Coverage score | Mode | Behavior |
|---|---|---|
| ≥ 80% across all 12 categories | **Mode A: Sufficient input** | Quick confirmation pass — present what was inferred, ask user to confirm or revise |
| 50–79% average; isolated weak spots | **Mode B: Targeted clarification** | Skip strong-coverage categories; run interview only on weak spots |
| < 50% average; many categories empty | **Mode C: Vibe coding** | Full professional interview from category 01; AI does proactive domain research first |

The assessment is **transparent** — Squad presents the coverage matrix as the first handoff so the user sees what the AI knows vs. doesn't before the interview begins.

### Pillar 2: Professional personas (new in 2026-05-20 refinement)

Four professional personas, each owning a distinct phase of the interview. Categories are grouped by primary persona; some cross-cut. The interview feels like talking to four specialists who handoff cleanly, not filling out a form:

- **🧠 Product Manager** — Categories 01 Problem/Pain, 02 Customer/Users, 10 MVP Scope
- **🎨 UX Designer** — Category 02 joint with PM; user journey + persona vs role framing
- **🏗️ Architect** — Categories 03 Security, 04 Scale, 05 Hosting, 06 Framework, 07 Architecture style, 08 NFRs, 11 Tech stack
- **📋 Project Manager** — Category 09 Time and Budget
- **🔬 AI Researcher** — Category 12 Domain Research; cross-cutting; informs other personas' recommendations

### Pillar 3: The twelve substantive question categories (v1 catalog)

| # | Category | Persona | What it elicits |
|---|---|---|---|
| 1 | Problem and pain | PM | What problem? Whose pain? Unmet need today? Measurable success outcome? |
| 2 | Customer and users | PM + UX | Customer (paying party) vs end users; roles/personas; environment; accessibility/i18n |
| 3 | Security, authn, authz | Architect | Public/authed/multi-tenant; identity provider; RBAC/ABAC; data sensitivity; compliance regime |
| 4 | Scale and performance | Architect | Concurrent users; growth curve; latency targets; data volume; read/write ratio |
| 5 | Hosting model | Architect | Local/cloud/serverless/containers/on-prem/hybrid; cloud provider; backup/DR posture |
| 6 | Framework | Architect | Backend/frontend framework; ORM; API style |
| 7 | Architecture style | Architect | Monolith/MSA/event-driven/DDD/CQRS; persistence pattern; async/messaging; caching |
| 8 | Additional NFRs and constraints | Architect | Availability SLA; data residency; audit logging; observability; DR RTO/RPO |
| 9 | Time and budget | PM (project) | Ship date; effort budget; money budget; risk appetite; iteration cadence |
| 10 | MVP scope | PM | Smallest demonstrable thing; deferred items; demo path end-to-end |
| 11 | Technology stack | Architect | Programming language; runtime; database; queue; external services |
| 12 | Domain research | AI Researcher | AI proactively researches domain + comparable solutions BEFORE forming questions |

### Pillar 4: Escape hatches on every question

Per user direction:
> "In many questions the Agent can offer options (include other) to the user."

Every multi-choice question presents **"Other (specify)"** + **"I don't know — you decide"** escape hatches. The "I don't know" answer produces a research-grounded recommendation flagged per Proposal 053.

### Pillar 5: Iteration-start intake (broader trigger surface, new in 2026-05-20 refinement)

Intake fires at multiple lifecycle boundaries:

- `/speckit.specify` (cold-start): full v1 catalog adapted by input quality
- `/speckit.clarify` (sharpening): re-prompt incomplete categories + "what did we NOT ask?" probe
- **New iteration kickoff**: lightweight 3-4 question intake (scope, demo, risk, dependencies)
- **Mid-feature pivot**: re-run categories impacted by the pivot
- Brownfield init: pre-fill from repo context where detectable

### Pillar 6: Structured output (`interview.yml`)

Every Q+A produces a structured record at `.specrew/intake/interview.yml` with mode, coverage scores, per-answer source flags (`user-direct` / `ai-recommendation` / `profile-extension`), autopilot flags per Proposal 053. The spec template fills from this record, not from autopilot guesses.

### Pillar 7: Validator integration

A new validator rule blocks `/speckit.plan` if `interview.yml` is missing, incomplete, or has any required category unanswered. Composes with Proposal 004 Validator Hardening + Proposal 030 Quality Hardening Bundle.

### Pillar 8: Profile composition (via Proposal 052)

The 12 categories are the **baseline**. Domain-specific profiles can layer (never replace) — `regulated-healthcare` adds HIPAA/BAA questions; `e-commerce` adds payment/tax/fulfillment; `enterprise-saas` adds tenancy/SSO/billing.

### Pillar 9: Expertise dial (depends on Proposal 015)

When Proposal 015 ships, the input-quality assessment combines with declared user expertise: novice biases toward Mode C; expert biases toward Mode A; "you decide" mode does research-driven recommendations across the board with user review at the end.

## How (implementation phases)

| Phase | Scope | Effort | Ships as |
|---|---|---|---|
| **P1** | Catalog + assessor + interview skeleton + persona definitions | 10-12 SP | v0.25.0-beta |
| **P2** | Research engine + AI Researcher persona | 7-10 SP | v0.25.0-beta (combined with P1) |
| **P3** | Validator + boundary integration | 5-7 SP | v0.25.0 stable |
| **P4** | Profile composition (slipped to Phase 2b per sequencing decision 2026-05-20) | 3-5 SP | v0.26.0 |

Total: 25-30 SP across 3-4 iterations.

Detailed implementation plan, file-by-file scope, AC1-AC15, out-of-scope list, and five worked examples (vibe coding, sufficient input, brownfield, iteration kickoff, mid-feature pivot) live in the source spec.

## Composition with other proposals

| Proposal | Relationship |
|---|---|
| **038 (Adaptive Boundary Discipline)** | The 12 categories become the universal "never auto-resolve" allow-list; 038 enforces the boundary, 063 specifies what to ask |
| **053 (Autopilot Decision Transparency)** | "I don't know — you decide" answers use 053's auto-resolution flagging |
| **015 (Expertise-Aware Adaptive Interaction)** | Provides the per-user expertise dial; refines Mode A/B/C selection |
| **044 (Downstream Quality Baseline Bootstrap)** | Reframes to "stack-question-driven defaults from this proposal's catalog" |
| **052 (Specrew Profile System)** | Provides the extensibility mechanism for domain-specific profile additions |
| **025 (JIT Codebase Cartography)** | For brownfield projects, JIT cartography output feeds category 12's research |
| **030 (Quality Hardening Bundle)** | F-025 retro will surface a Form-vs-Meaning case study; feeds 030's corpus |
| **042 (Specrew Integration Test Suite)** | Gym + WSL replay tests fold into 042's broader matrix post-ship |

## Acceptance signals (full AC1-AC15 in source spec)

Headline acceptance gates:

- **AC13** Re-run gym subscription test post-ship: interview.yml MUST contain substantive answers for categories 01, 02, 03, 05, 07, 10 BEFORE any code is written
- **AC14** Re-run WSL trial test post-ship: category 04 (Scale) explicitly asks "how many balls?" rather than auto-resolving "50 max"
- **AC15** A non-expert tester (no prior Specrew knowledge) can complete an intake and end up with a coherent, decision-grounded spec for their idea

## Cross-references

- **Source spec (full detail)**: file:///C:/Dev/SpecrewDraft/substantive-intake-questioning.md
- [[project-gym-test-intake-questioning-gap-2026-05-19]] — empirical motivation
- [[project-wsl-trial-autopilot-clarify-gap-2026-05-18]] — earlier instance of same pattern
- [[project-post-f024-sequencing-locked-2026-05-20]] — sequencing decisions for when F-025 ships
- file:///C:/Dev/Specrew/proposals/038-adaptive-boundary-discipline.md
- file:///C:/Dev/Specrew/proposals/053-autopilot-decision-transparency.md
- file:///C:/Dev/Specrew/proposals/015-expertise-aware-adaptive-interaction.md
- file:///C:/Dev/Specrew/proposals/044-downstream-quality-baseline-bootstrap.md
- file:///C:/Dev/Specrew/proposals/052-specrew-profile-system.md
- file:///C:/Dev/Specrew/proposals/025-jit-codebase-cartography.md
- file:///C:/Dev/Specrew/proposals/030-quality-hardening-bundle.md
- file:///C:/Dev/Specrew/proposals/042-specrew-integration-test-suite.md
- file:///C:/Dev/Specrew/proposals/INDEX.md — canonical status index
