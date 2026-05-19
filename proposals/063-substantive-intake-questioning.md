---
proposal: 063
title: Substantive Intake Questioning at /speckit.specify and /speckit.clarify
status: candidate
phase: phase-2
estimated-sp: 20-25
discussion: tbd
---

# Substantive Intake Questioning

## Why

Specrew's value proposition is **the methodology asks questions the developer didn't know to ask**. A non-expert user has no idea they need to specify tech stack, permission model, deployment target, expected scale, MVP boundaries, or domain context. They expect the methodology to elicit those decisions through structured questioning.

Specrew today does not. Two independent empirical cases confirm the gap:

- **WSL trial 2026-05-18** — Squad silently auto-resolved scope (50 balls max), appearance model (per-ball color + preset materials), without human input. Documented in [[project-wsl-trial-autopilot-clarify-gap-2026-05-18]].
- **Gym subscription test 2026-05-19** — Fresh greenfield project at `C:\Temp\spec023\test`. User asked for "gym subscription management system." Lifecycle ran specify → clarify → plan → tasks → implement with **only two human pauses** (after-tasks, after-review). Squad auto-resolved tech stack from a 13-line `.vscode/settings.json` hint, plus permission model, database choice, frontend type, auth provider, hosting. Documented in [[project-gym-test-intake-questioning-gap-2026-05-19]].

User critique (verbatim, gym test session 2026-05-19):

> "It hasn't asked me anything, I mean the first time it stopped was after the planning. How come? No questions about architecture, design, technology, users and user stories, hosting, many aspects of the problem domain and the solution domain. Of course if I know how to provide a good spec, we do not need this kind of questions, but not all developers know how to provide a good spec."

The first impression of Specrew as a methodology depends on this gap closing. Without it, Specrew is useful only for the "I already know exactly what I want" segment — a small audience. With it, Specrew becomes useful for the much larger "I have an idea, help me sharpen it into a spec" segment.

## What

A mandatory intake-questioning protocol that runs at `/speckit.specify` (initial intake) and `/speckit.clarify` (sharpening), structured around twelve substantive question categories. The protocol applies regardless of autopilot mode — these decisions are on the "never auto-resolve" allow-list (composes with Proposal 053 Pillar 4 and Proposal 038's adaptive boundaries).

### The Twelve Substantive Question Categories (v1 catalog)

Each category produces one or more concrete questions surfaced as boundary handoffs in Substantive Interaction Model format (F-016). Squad waits for explicit user input — autopilot cannot bypass.

| # | Category | What it elicits |
|---|---|---|
| 1 | **Problem and pain** | What problem are we solving? Whose pain? What needs are unmet today? |
| 2 | **Customer and users** | Who is the customer (paying party)? Who are the end users? What roles/personas? |
| 3 | **Security, authn, authz** | Public, authenticated, role-based, multi-tenant, regulated? What identity provider? |
| 4 | **Scale and performance** | Expected concurrent users, request rate, data volume, latency targets, growth curve |
| 5 | **Hosting model** | Local-only, cloud-hosted, serverless functions, containers, on-prem, hybrid |
| 6 | **Framework** | Specific framework preference? (AI may suggest based on category 5 + 11 + 12) |
| 7 | **Architecture style** | DDD, microservices, monolith, layered, hexagonal, event-driven, CQRS, others |
| 8 | **Additional NFRs and constraints** | Availability, compliance (GDPR/HIPAA/PCI/SOC2), data residency, accessibility, i18n |
| 9 | **Time and budget** | Target ship date, effort budget (person-days), money budget |
| 10 | **MVP scope** | What is in the first slice vs deferred? What is the smallest demonstrable thing? |
| 11 | **Technology stack** | Programming languages, frameworks, runtimes, databases, queues, caches |
| 12 | **Domain research** | AI proactively researches the domain + comparable solutions BEFORE forming questions, so questions and recommendations are grounded in real-world context |

### Design constraint: multi-choice with escape hatch

Per user direction (gym test session 2026-05-19):

> "In many questions the Agent can offer options (include other) to the user."

Each question SHOULD present a small set of well-known options when applicable, with two escape hatches:

- **"Other (specify)"** — the user provides a free-form answer that Squad treats as authoritative
- **"I don't know, you decide"** — Squad provides a recommendation grounded in research (category 12), records it as auto-resolved per Proposal 053, and flags it for review at the next boundary

Example (category 5 — Hosting model):

```
What is the hosting model for this system?
  1. Local-only (developer workstation, no deployment)
  2. Cloud-hosted server (single VM or PaaS like Heroku/Render)
  3. Cloud-hosted, container-based (Kubernetes, ECS, ACA)
  4. Serverless / Functions (AWS Lambda, Azure Functions, Cloudflare Workers)
  5. On-premises (customer data center, air-gapped)
  6. Hybrid (specify split)
  7. Other (specify)
  8. I don't know — research and recommend
```

### Design constraint: AI does proactive domain research

Category 12 is meta — the AI is expected to perform research BEFORE finalizing the question set or recommendations. Per user direction:

> "Related research about the domain and the solution - the AI will go and do research to have a better foundation."

Research scope (v1):

- **Domain landscape**: who are typical users, what are typical workflows, what are well-known pain points in this domain
- **Comparable solutions**: what existing products solve adjacent problems, what trade-offs do they make
- **Common tech-stack patterns**: what stacks are typically used for this class of system, what are the major decision points

Research output:

- **Surfaces in handoff** — Squad presents a short "what we learned about this domain" briefing before asking domain-specific questions
- **Informs recommendations** — when the user picks "I don't know, you decide", the recommendation cites the research
- **Persists** — saved to `.specrew/intake/domain-research.md` so future iterations and reviewers can see the foundation

### Boundary integration

Two integration points:

**`/speckit.specify` — Initial intake (cold start)**:

- Run the 12-category interview as part of intake, BEFORE the spec template is filled out
- The interview produces a structured `.specrew/intake/interview.yml` capturing every Q+A pair, autopilot-resolved flag, and source (user / research / default)
- The spec template fills from the interview, NOT from autopilot guesses
- Skip rationale: if a source spec is present and the user explicitly opts out, the interview can be condensed to "verify these are correct" (no skip allowed for cold-start cases)

**`/speckit.clarify` — Sharpening (uncertainty pass)**:

- Re-runs only the categories where the spec has `[NEEDS CLARIFICATION]` markers OR low confidence flags
- Adds a thirteenth pass: **"What questions did we NOT ask that you wish we had?"** — explicit invitation for the user to flag missing categories

### Profile composition

Proposal 052 (Profile System) introduces opt-in profiles for different downstream domains. The 12-category catalog above is the BASELINE profile (applies always). Domain-specific profiles can layer in additional categories:

- **`profile: regulated-healthcare`** adds HIPAA-specific questions (PHI scope, audit retention, access logs)
- **`profile: e-commerce`** adds payment / tax / fulfillment questions
- **`profile: enterprise-saas`** adds tenancy / SSO / billing questions

The baseline 12 categories are NOT optional in a profile — they are the methodology floor. Profiles ADD, not REPLACE.

## How

### Phase 1 — Catalog + boundary scaffolding (~7-10 SP)

- Define the v1 catalog as a versioned data structure at `extensions/specrew-speckit/intake/v1-catalog.yml`
- Each category has: id, title, prompt, options (with rationale), escape-hatch behavior
- New script `extensions/specrew-speckit/scripts/run-intake-interview.ps1` orchestrates the interview as a Squad handoff
- Validator rule (extends Proposal 004 Validator Hardening): spec must reference a populated `interview.yml` before `/speckit.plan` can advance

### Phase 2 — Research engine (~7-10 SP)

- New helper at `extensions/specrew-speckit/scripts/research-domain.ps1` performs targeted research (web search, comparable-product discovery, common-stack survey)
- Output written to `.specrew/intake/domain-research.md`
- Squad's `/speckit.specify` handoff invokes research BEFORE presenting category-specific questions
- Research is checkpointed: if the user has already answered category 1+2, research narrows to that domain instead of generic

### Phase 3 — Composition + profile hooks (~3-5 SP)

- Wire to Proposal 052's profile system: profiles can extend the catalog
- Wire to Proposal 038's "never auto-resolve" allow-list: the 12 categories are universally on the list
- Wire to Proposal 053's auto-resolution flag: when escape-hatch "I don't know" is chosen, mark the resulting decision as `auto_resolved: true` with `auto_resolved_reason: user-deferred`

### Phase 4 — Expertise dial (depends on Proposal 015)

- Once Proposal 015 ships, this catalog can be adaptive:
  - **Novice mode** → all 12 categories asked verbosely with options
  - **Expert mode** → categories collapsed where the user can pre-write them; only flagged unknowns asked
  - **"You decide" mode** → research-driven recommendations across the board, user reviews

## Composition with other proposals

| Proposal | How they relate |
|---|---|
| **038 (Adaptive Boundary Discipline)** | The 12 categories become the universal "never auto-resolve" allow-list; 038 enforces the boundary, 063 specifies what to ask |
| **053 (Autopilot Decision Transparency)** | When escape-hatch "I don't know" → research-driven recommendation, 053's machinery surfaces the auto-resolution |
| **015 (Expertise-Aware Adaptive Interaction)** | Provides the per-user expertise dial that adapts catalog verbosity |
| **044 (Downstream Quality Baseline Bootstrap)** | Reframes from "stack-aware defaults" to "stack-question-driven defaults from the catalog" |
| **052 (Specrew Profile System)** | Provides the extensibility mechanism for domain-specific profile additions |
| **025 (JIT Codebase Cartography)** | For brownfield projects, JIT cartography output feeds category 12's research |

## Open questions

1. **Sequencing**: should the catalog run in fixed order (1 → 12) or adaptive (let the user pick what to answer first)? Adaptive is friendlier but produces more state-machine complexity.
2. **Skip mechanics for resumed specs**: when re-running `/speckit.specify` on an existing spec, how aggressively do we re-prompt? "Verify these" mode seems right but needs design.
3. **Research engine constraints**: does the AI use built-in research (WebSearch / WebFetch) or compose with an MCP research server? Either works; pick based on host portability.
4. **Catalog versioning**: when the v1 catalog evolves to v2, how do we migrate existing `interview.yml` files? Add a `catalog_version` field and a migration script.
5. **MVP definition for category 10**: should Specrew enforce a minimum-bar definition of MVP (e.g., "must include at least one demo path end-to-end") or just record whatever the user says?

## Acceptance signals (deferred to spec)

- Re-run the gym subscription test against post-shipped code: Squad MUST surface at least categories 1, 2, 3, 5, 7, 10 as substantive questions before specify resolves
- Re-run the WSL trial test: scope decisions (max counts, appearance model) MUST appear in category 4 or 10 with options
- New tester (non-expert) can complete intake without prior Specrew knowledge by following the catalog questions

## Cross-references

- [[project-gym-test-intake-questioning-gap-2026-05-19]] — empirical motivation
- [[project-wsl-trial-autopilot-clarify-gap-2026-05-18]] — earlier instance of same pattern
- file:///C:/Dev/Specrew/proposals/038-adaptive-boundary-discipline.md
- file:///C:/Dev/Specrew/proposals/053-autopilot-decision-transparency.md
- file:///C:/Dev/Specrew/proposals/015-expertise-aware-adaptive-interaction.md
- file:///C:/Dev/Specrew/proposals/044-downstream-quality-baseline-bootstrap.md
- file:///C:/Dev/Specrew/proposals/052-specrew-profile-system.md
- file:///C:/Dev/Specrew/proposals/INDEX.md — canonical status index
