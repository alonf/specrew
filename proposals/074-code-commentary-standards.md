---
proposal: 074
title: Code Commentary Standards (Multi-Level Convention + Preference Dial)
status: draft
phase: phase-2
estimated-sp: 12-15
discussion: tbd
---

# Code Commentary Standards

## Why

Specrew's Implementer agent today follows a strict minimalist commenting convention — closely modeled on the "default to no comments" stance in coordinator instructions: only add a comment when the WHY is non-obvious. That convention is defensible for some codebases, but it is materially wrong for many real-world scenarios:

### Empirical observation (2026-05-21 smoke trial)

A fresh `specrew init` snake-game smoke test produced a working .NET 8 solution with multiple C# projects, public types (`GameSession`, `GameSessionFactory`, `Direction`, `FoodItem`, `GameOptions`, `ConsoleSizeValidator`, `InputMapper`, `GameFrameComposer`, etc.) — and **none of those public APIs carry XML doc comments**. The consequence:

- **IntelliSense in VS Code / Visual Studio / Rider shows nothing** when a downstream consumer hovers over a public method or type. The C# tooling experience that every working C# developer expects is silently missing
- **Reviewers (human and agent) cannot understand intent** without reading the implementation. Public-API surface ceases to be self-describing — a regression from the spec's intent of contract-driven design
- **Onboarding cost rises** for anyone joining the project later, including future AI agents resuming the work

This is not a Squad-specific bug — it follows directly from the current minimalist convention. But the convention is mis-tuned: it correctly suppresses noise comments while also suppressing **load-bearing contract documentation**.

### User direction (2026-05-21)

The user articulated the right shape directly:

> "We need multiple level of comments: On contract/public/interface - for example in C# we have XML docs. When we have complex code and we want to explain the concepts, when we took a decision to do something not clear and we want to write why. Beside that we may want to ask the human dev the level of comments they want. For example they may want comments for non-developers, or a text book level, or they just want comments as they should be to tell the story only when the code itself doesn't tell the story."

And:

> "We also need to think about languages and tool supports - for example in C#, intellisence uses the XML doc."

The fix is not "add more comments everywhere" — it is **structured comment categories with a user-configurable preference dial, mapped to language-idiomatic conventions** so the tooling (IntelliSense, language servers, doc generators) actually consumes them.

## What (6 Pillars)

### Pillar 1: Comment category taxonomy (always-applicable structure)

Four orthogonal comment categories, ordered by load-bearing weight:

| Category | When | Default expectation |
|---|---|---|
| **Contract** | Public/exported types, methods, properties, interfaces | **Always required** for public APIs in languages whose tooling consumes structured doc comments (XML doc in C#, JSDoc in TS/JS, docstring in Python, Javadoc in Java, doc-comment in Rust, godoc in Go). Mandatory regardless of preference-dial setting |
| **Why-rationale** | Non-obvious decisions, workarounds, hidden constraints, surprising behavior, tradeoffs explicitly made | Added at the point of the surprise — at most a few lines. Encouraged across all dial settings |
| **Concept** | Complex algorithms, domain logic, multi-step protocols, state machines | Added at the top of the relevant section. Frequency depends on dial setting |
| **Inline narration** | Per-line or per-block "what is happening here" | Generally avoided unless dial is `educational`/`textbook` |

The Contract category is what makes the IntelliSense / language-server experience work. It is the one category Specrew's current convention is silently failing on.

### Pillar 2: User preference dial (4 levels)

Captured at init-time or via `.specrew/config.yml`. Composes with Proposal 047 (Project Governance Profile) when 047 ships — until then lives as a standalone `commentary.level` key.

| Level | Contract docs | Why-rationale | Concept | Inline narration | Audience |
|---|---|---|---|---|---|
| **`minimalist`** | required for public APIs | when truly non-obvious | rare | none | "code tells the story unless it can't" |
| **`standard`** (default) | required for public APIs | encouraged for any non-trivial decision | encouraged for complex sections | none | working developers + reviewing agents |
| **`educational`** | required for public APIs | richer narrative with examples | required for any non-trivial section | encouraged for unfamiliar idioms | non-experts in the language or domain |
| **`textbook`** | required for public APIs with usage examples | rich rationale with tradeoff discussion | required with rationale and alternatives | required for instructional clarity | tutorial / teaching / blog-post audience |

The default is `standard`. The minimalist tier is preserved for users who deliberately want spartan codebases — but with the explicit guarantee that contract docs are **still required**.

### Pillar 3: Language and tooling convention catalog

Each language's comment idiom maps to the four categories. The Implementer agent consults the catalog when writing code. Initial catalog covers:

| Language | Contract | Why-rationale | Tool consumer |
|---|---|---|---|
| **C#** | `/// <summary>`, `<param>`, `<returns>`, `<exception>`, `<remarks>` | `//` inline | IntelliSense, DocFX, language server |
| **TypeScript / JavaScript** | JSDoc (`/** @param @returns @throws @example`) | `//` inline | TypeScript LSP, ESLint plugins, JSDoc generator |
| **Python** | docstring (PEP 257; Google / NumPy / Sphinx style configurable) | `#` inline | Pylance, IDE tooltip, Sphinx |
| **Java** | Javadoc (`/** @param @return @throws`) | `//` inline | Javadoc generator, IDE tooltip |
| **Go** | `// FunctionName` immediately preceding exported identifier (godoc convention) | `//` inline | godoc, pkg.go.dev, gopls |
| **Rust** | `///` doc comments (Markdown supported) | `//` inline | rustdoc, rust-analyzer |
| **PowerShell** | comment-based help (`<# .SYNOPSIS .DESCRIPTION .PARAMETER .EXAMPLE #>`) | `#` inline | `Get-Help`, IntelliSense in VS Code PowerShell extension |
| **Swift** | `///` triple-slash doc comments (Markdown supported) | `//` inline | Xcode quick help, DocC |
| **Kotlin** | KDoc (`/** @param @return @throws`) | `//` inline | IntelliJ quick doc, Dokka |
| **Ruby** | YARD (`# @param @return @example` above method) | `#` inline | YARD, RBS tooling |

Languages not in the initial catalog fall back to "respect the language's idiomatic convention for doc-comments." The catalog is extensible via Proposal 052 (Profile System) — a profile can add language entries or override defaults.

### Pillar 4: Implementer agent integration

Update the Implementer charter and the Specrew coordinator instructions to consult the dial + language catalog when writing code:

- When the active file's language is in the catalog, contract-category comments are mandatory on every public/exported declaration
- Why-rationale comments are added at the point of any non-obvious decision (workaround, performance tradeoff, deliberate non-idiomatic choice)
- Concept and inline narration are added per the dial setting
- The Implementer does NOT add ceremonial or self-evident comments — the minimalist filter still applies at the bottom of the hierarchy

Replace the current "default to no comments" instruction with the multi-level convention. Preserve the existing intent of "don't add noise comments" by routing it through the dial — at `minimalist`, inline narration is still suppressed.

### Pillar 5: Reviewer agent integration + validator rule

Reviewer charter and the review-evidence scripts gain a contract-docs verification check:

- At review-phase, scan changed files in the iteration
- For each public/exported declaration in a supported language, verify a contract comment exists in the language-idiomatic form
- Missing contract docs surface as a review verdict failure with severity proportional to the dial setting (HARD-FAIL at `educational`/`textbook`; soft warning at `minimalist` if the API truly is internal)
- This check is opt-in per the dial — projects on `minimalist` dial with no public-API surface won't trigger it

The validator rule composes with Proposal 004 (Validator Hardening) and runs at the same governance plane.

### Pillar 6: Init-time capture and config persistence

`specrew init` asks (or pre-fills based on profile choice) the project's commentary level:

- Default: `standard` (encouraged)
- Asked once at init; persists in `.specrew/config.yml` under `commentary.level`
- Changeable later via `specrew config set commentary.level <value>` (composing with Proposal 033 Governance CLI when 033 ships)
- Profile system (Proposal 052) can pre-set the dial: `educational` profile defaults to that level

When Proposal 015 (Expertise-Aware Adaptive Interaction) ships, the dial can be adjusted by inferred expertise: a self-declared novice user gets `educational` proposed; an expert gets `minimalist` or `standard`.

## How (one-iteration plan)

- Feature branch from `main` (likely `029-code-commentary-standards` or matching feature-number)
- Squad drives specify → clarify → plan → tasks → implement → review → retro → closeout
- PR-at-feature-close per the SDLC
- New files:
  - `extensions/specrew-speckit/skills/commentary-conventions/SKILL.md` (and deploy paths under .claude/.github/.agents per F-024) — Implementer reads this to know the active dial and language catalog
  - `extensions/specrew-speckit/scripts/validate-commentary.ps1` (or fold into validate-governance.ps1) — contract-docs verification check
  - `extensions/specrew-speckit/data/commentary-catalog.yml` — language-to-convention mapping
  - Tests at `tests/integration/commentary-conventions.tests.ps1` covering: dial respected per project, contract docs detected in each major language, missing-contract-docs flagged at appropriate severity
- Modified files:
  - `.squad/agents/implementer/charter.md` — incorporate the commentary convention
  - `.squad/agents/reviewer/charter.md` — incorporate the verification check
  - `extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md` — update the coordinator instruction set
  - `.specrew/config.yml` template — add `commentary.level: standard` default
  - `docs/user-guide.md` — document the dial and what each level does
- CHANGELOG entry under `## Unreleased` → `### Added`

## Composition with other proposals

| Proposal | Relationship |
|---|---|
| **047 (Project Governance Profile, candidate)** | The commentary dial is a natural fit for 047's dial catalog. If 047 ships first, `commentary.level` slots in as one of its dials. If 074 ships first, the dial lives standalone in `.specrew/config.yml` and gets absorbed into 047's structure when 047 lands |
| **052 (Specrew Profile System, candidate)** | Domain-specific profiles can override commentary defaults: `educational` profile sets `level: educational`; `enterprise-saas` keeps `standard`; an explicit `tutorial-content` profile sets `textbook` |
| **015 (Expertise-Aware Adaptive Interaction, candidate)** | User expertise can adjust the dial: declared novice → `educational`; declared expert → `minimalist` or `standard`; "you decide" → research-grounded recommendation |
| **004 (Validator Hardening, shipped)** | The contract-docs verification check plugs into the same validator-governance plane established by F-013 |
| **033 (Specrew Governance CLI, draft)** | `specrew config set commentary.level <value>` lands as part of 033's CLI surface |
| **042 (Specrew Integration Test Suite, candidate)** | The new commentary-convention tests fold into 042's broader matrix when 042 ships |
| **008 (NFR Governance, draft)** | Comment quality is a maintainability NFR; 008's NFR-tier model could classify commentary requirements as conditional NFRs |
| **F-016 / F-066 (boundary discipline, shipped)** | The Implementer's commentary decisions occur during the implement phase; reviewer verification occurs at the review boundary. Both layers are governed by the existing boundaries |

## Acceptance signals

- **AC1**: A fresh `specrew init` with `commentary.level: standard` (default) produces an implementation phase where the Implementer agent adds language-idiomatic contract comments to every public/exported declaration in supported languages (verified by re-running the snake-game smoke and inspecting C# files for XML doc presence)
- **AC2**: The same smoke project re-implemented with `commentary.level: minimalist` produces contract docs on public APIs but suppresses inline narration — proving the dial is respected
- **AC3**: The same project with `commentary.level: educational` produces additional concept and inline-narration comments
- **AC4**: The reviewer scaffolder / validator rule flags a missing public-API contract comment as a verdict failure at `standard`/`educational`/`textbook`, and as a soft warning at `minimalist`
- **AC5**: The language convention catalog includes at minimum: C#, TypeScript, Python, Java, Go, Rust, PowerShell. Each language entry resolves correctly during implementation
- **AC6**: A non-C# project (e.g. a TypeScript-only spec) uses JSDoc conventions correctly without manual override
- **AC7**: The `commentary.level` configuration persists across iterations and is readable by both Implementer and Reviewer agents within a single Squad lifecycle run
- **AC8**: Existing Specrew dev-repo code is not retroactively modified — this convention applies to NEW code from F-074 forward. Retroactive backfill of existing modules is a separate optional chore slice
- **AC9**: When the smoke project's snake-game implementation is replayed with this feature shipped, every public C# type has `/// <summary>` documentation and IntelliSense displays meaningful descriptions in VS Code

## Out of scope

- Retroactively adding comments to existing Specrew codebase modules (separate optional chore)
- Language conventions not in the initial catalog (extensible via profile system; not blocking)
- Auto-generating comments from code (different problem; AI-assisted comment generation is a separate proposal candidate)
- Doc-generator integration (DocFX, Sphinx, Javadoc tooling) — out of scope; consumers can run their own generators against the language-idiomatic comments this proposal produces
- Mandatory comment style guides (e.g. "use Google docstring style" vs "NumPy style" in Python) — out of scope; pick the project's existing convention or use the language default

## Cross-references

- **Empirical motivation**: 2026-05-21 smoke trial at `C:/Temp/specrew-024-host-smoke-184119/src/SnakeGame.*/` showing uncommented public C# APIs
- **User direction**: 2026-05-21 chat session, request to draft "a proposal to update the instructions about comments in code"
- Proposal 047 (Project Governance Profile, candidate): file:///C:/Dev/Specrew/proposals/047-project-governance-profile.md
- Proposal 052 (Specrew Profile System, candidate): file:///C:/Dev/Specrew/proposals/052-specrew-profile-system.md
- Proposal 015 (Expertise-Aware Adaptive Interaction, candidate): file:///C:/Dev/Specrew/proposals/015-expertise-aware-adaptive-interaction.md
- Proposal 004 (Validator Hardening, shipped): file:///C:/Dev/Specrew/proposals/004-validator-hardening.md
- Proposal 033 (Specrew Governance CLI, draft): file:///C:/Dev/Specrew/proposals/033-specrew-governance-cli.md
- Proposal 042 (Integration Test Suite): file:///C:/Dev/Specrew/proposals/042-specrew-integration-test-suite.md
- Proposal 008 (NFR Governance, draft): file:///C:/Dev/Specrew/proposals/008-nfr-governance.md
- INDEX: file:///C:/Dev/Specrew/proposals/INDEX.md
