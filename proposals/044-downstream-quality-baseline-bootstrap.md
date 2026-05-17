---
proposal: 044
title: Downstream Quality Baseline Bootstrap
status: candidate
phase: phase-2
estimated-sp: 10
discussion: tbd
---

# Downstream Quality Baseline Bootstrap

## Why

When `specrew init` bootstraps a new downstream project, Specrew currently provisions Spec Kit + Squad + governance scaffolds but does NOT provision the project's QUALITY baseline: lint configs, style configs, CI configs, code-formatter configs, etc.

User signal 2026-05-16: "how we make sure that down stream projects of Specrew are following the gurdrial rules (Lint, SonarQube, StyleCop or other tools)?"

The principle: Specrew's value isn't just "spec-driven AI lifecycle"; it's "spec-driven AI lifecycle with quality guardrails baked in." A bootstrapped Specrew project should arrive with sensible quality-tool defaults appropriate to its stack.

## What

Extend `specrew init` to bootstrap quality-tool configs per the detected/declared project stack.

### Stack-aware quality config catalog

Per stack, ship a default config bundle:

- **PowerShell**: `.markdownlint.json`, `.editorconfig`, `PSScriptAnalyzer.psd1`, GitHub Actions lint lane
- **.NET/C#**: `.editorconfig`, StyleCop config, SonarQube `sonar-project.properties`, `dotnet format` config
- **Node.js/TypeScript**: ESLint config, Prettier config, `tsconfig.json` strict mode, vitest/jest config
- **Python**: ruff/black config, `pyproject.toml` strict mypy, pre-commit hooks
- **Go**: golangci-lint config, gofmt enforcement
- **Java**: SpotBugs / Checkstyle / PMD configs, Maven/Gradle plugins
- **Rust**: clippy config, rustfmt config

### Three pillars

1. **Stack-aware config catalog** — `extensions/specrew-speckit/quality-bootstrap/<stack>/` directories with default configs per stack. Versioned alongside Specrew.

2. **Init prompt for stack selection** — `specrew init` asks "which quality stack(s) do you want to bootstrap?" with detected-from-repo defaults. Composes with [043](043-structured-question-protocol.md) menu UX.

3. **Per-project override** — `.specrew/quality/quality-baseline.yml` records which configs were bootstrapped and at which version. Drift-validator runs on this; user can opt out of specific lints with recorded rationale (composes with stack-aware-tool-selection memory entry).

### Validator integration

The "category-level mandate + stack-aware catalog" pattern (from `feedback_stack_aware_tool_selection`) extends here: Specrew mandates "must have a lint config" (category-level); the catalog provides examples (stack-aware); the user accepts/overrides at init time with recorded rationale.

### Out of scope

- Specrew opining on specific tool choices (we provide defaults; downstream user chooses)
- Bootstrapping SonarQube/CodeClimate/etc. cloud accounts (just the local config files)
- Migration tooling for existing projects (init is for greenfield/brownfield-with-empty-quality-surface; pre-existing configs are preserved)

## Effort

- **Iteration 1** (~6-8 SP): PowerShell + .NET + Node.js stack catalogs + stack-detection heuristic + init prompt integration
- **Iteration 2** (~4-6 SP): Python + Go + Java + Rust + per-project drift validator

**Total**: ~10-14 SP

## Phase placement

**Phase 2**, after [035](035-session-state-durability.md). Composes with [043](043-structured-question-protocol.md) for menu UX (or just text fallback if 043 hasn't shipped).

## Open questions

1. Stack detection heuristic: file-extension scan? Manifest file detection (package.json, .csproj, etc.)? Hybrid?
2. Should `specrew init` REQUIRE quality bootstrap (mandatory) or OFFER it (optional with `--no-quality-bootstrap` skip)?
3. Default configs per stack: opinionated (matches Specrew's own baseline) or industry-standard (matches each stack's common conventions)?
4. Per-project drift validator: should it FAIL or WARN when bootstrapped configs are modified post-init?
5. Versioning: each stack catalog versioned independently or in lockstep with Specrew releases?

## Risks

- Opinionated default configs may not match downstream user's existing conventions; need clear opt-out path
- Configs go stale as toolchains evolve; need maintenance cadence

## Cross-references

- Composes with [043](043-structured-question-protocol.md) (menu UX for stack selection)
- Composes with [008](008-nfr-governance.md) (NFR baseline categories — quality bootstrap is one NFR category)
- Composes with `feedback_stack_aware_tool_selection` memory entry (stays in memory as the policy principle)
- Possible composition with [037](037-psscriptanalyzer-lint-cleanup.md) (Specrew's own PowerShell stack catalog seeds the bootstrap)

## Status history

- 2026-05-16: captured as memory after user asked about downstream guardrails
- 2026-05-18: promoted to candidate proposal during memory→proposals consolidation
