# Specrew Development Guidelines

Auto-generated from all feature plans. Last updated: 2026-05-14

## Active Technologies
- PowerShell 7.x scripts plus Markdown/YAML/JSON governance artifacts; downstream Specrew config currently pins Spec Kit `0.8.4` and Squad `0.9.1` in `.specrew/config.yml` + `extensions/specrew-speckit` script/template surfaces, `.specify` plan workflow, Squad-native runtime deployment via `deploy-squad-runtime.ps1`, existing governance/evaluation scripts under `tests/integration/` and `evaluation/scorers/` (008-quality-profile-foundation)
- Git-tracked Markdown/YAML assets under `.specrew/` plus feature and iteration artifacts under `specs/<feature>/`; machine-readable mechanical findings stored as JSON sidecars (008-quality-profile-foundation)
- PowerShell 7.x scripts plus Markdown/YAML/JSON governance artifacts; downstream Specrew config remains rooted in `.specrew/*.yml` + `extensions/specrew-speckit` scripts/templates, `.specify` planning workflow, existing Phase 1 quality-profile/evidence contracts, iteration governance scripts, and deterministic integration coverage in `tests/integration/` (008-quality-profile-foundation)
- Git-tracked Markdown/YAML/JSON under `.specrew/`, `extensions/specrew-speckit/templates/quality/`, and `specs/<feature>/iterations/<NNN>/quality/`; Phase 2 adds a versioned known-traps corpus plus hardening/lens evidence artifacts (008-quality-profile-foundation)
- PowerShell 7.x plus Markdown/YAML/JSON governance artifacts + `extensions/specrew-speckit` governance scripts/templates, `.specify` planning workflow, feature-local planning artifacts, and deterministic integration tests under `tests/integration/` (008-quality-profile-foundation)
- Git-tracked Markdown/YAML/JSON in `specs/005-stack-aware-quality-bar/`, `.specify/`, `.specrew/`, and `extensions/specrew-speckit/` (008-quality-profile-foundation)
- PowerShell 7.x plus Markdown/YAML/JSON governance artifacts + `extensions/specrew-speckit` governance scripts (`manage-escalation-state.ps1`, `shared-governance.ps1`, `sync-squad-model-overrides.ps1`, `validate-governance.ps1`), `.specrew` runtime config, `.squad` routing/ledger artifacts, and feature-local spec artifacts (008-reviewer-escalation-symmetry)
- Git-tracked Markdown/YAML/JSON in `specs/008-reviewer-escalation-symmetry/`, `.specrew/`, `.squad/`, `.github/agents/`, and `extensions/specrew-speckit/` (008-reviewer-escalation-symmetry)
- PowerShell 7+ (`pwsh`) for the bootstrap banner function; Markdown (CommonMark) for documentation files + None — plain Markdown + existing PowerShell function; no new packages or tooling (010-onboarding-resume-visibility)
- File system only — four existing files in the Specrew repository (010-onboarding-resume-visibility)
- PowerShell 7.x automation plus Markdown/YAML/JSON governance artifacts + Existing Specrew Spec Kit extension surfaces, Squad/Copilot startup guidance, PowerShell validator/test scripts, Markdown contracts and checklists (012-keep-descriptive-refs)
- Git-tracked repository files only (`.md`, `.ps1`, `.yml`, `.json`); no database changes (012-keep-descriptive-refs)
- PowerShell 7.x + `extensions/specrew-speckit/scripts/validate-governance.ps1`, `shared-governance.ps1`, `scripts/specrew-start.ps1`; Git working-tree inspection via `git status --porcelain` (013-validator-hardening)
- Git-tracked Markdown governance artifacts (`specs/*/iterations/*/state.md`, `quality/hardening-gate.md`, `plan.md`, `review.md`, `retro.md`, `.github/copilot-instructions.md`, `.specrew/quality/known-traps.md`) (013-validator-hardening)
- PowerShell 7.x automation plus Markdown/YAML/JSON governance artifacts + `extensions/specrew-speckit/validators/handoff-governance-validator.ps1`, coordinator prompt/checklist surfaces under `extensions/specrew-speckit/`, `specs/001-specrew-product/contracts/coordinator-handoff-template.md`, `.github/agents/squad.agent.md`, `.squad/templates/squad.agent.md`, `.specrew/quality/known-traps.md`, existing integration tests under `tests/integration/` (014-handoff-format-scoping)
- Git-tracked repository artifacts only (`.md`, `.ps1`, `.json`, `.yml`); no database or external state changes (014-handoff-format-scoping)
- PowerShell 7 (script extension), Markdown (all documentation artifacts), Git (tag operations) + `validate-governance.ps1` and `shared-governance.ps1` (existing); standard (015-public-readiness-pass)
- Filesystem only — Markdown files at repo root and under `docs/`, `specs/`, and `extensions/specrew-speckit/` (015-public-readiness-pass)
- PowerShell 7 for validator/test automation, Markdown for prompt/contracts/docs, Git commit metadata for boundary-signature inspection + `extensions/specrew-speckit/scripts/validate-governance.ps1`; `extensions/specrew-speckit/scripts/shared-governance.ps1`; `extensions/specrew-speckit/validators/handoff-governance-validator.ps1`; coordinator prompt surfaces under `extensions/specrew-speckit/prompts/` and `.github/agents/` (016-substantive-interaction-model)
- Filesystem + Git history + `.squad/decisions.md` authorization ledger + `.specrew/quality/known-traps.md` corpus (016-substantive-interaction-model)

- Markdown, YAML, PowerShell (Spec Kit extension assets). + Spec Kit >= 0.8.4 (extension starter template), Squad >= 0.9.1 (extension structure: skills/ceremonies/directives) (001-specrew-product)

## Project Structure

```text
src/
tests/
```

## Commands

npm test; npm run lint

## Code Style

Markdown, YAML, PowerShell (Spec Kit extension assets).: Follow standard conventions

## Recent Changes
- 016-substantive-interaction-model: Added PowerShell 7 for validator/test automation, Markdown for prompt/contracts/docs, Git commit metadata for boundary-signature inspection + `extensions/specrew-speckit/scripts/validate-governance.ps1`; `extensions/specrew-speckit/scripts/shared-governance.ps1`; `extensions/specrew-speckit/validators/handoff-governance-validator.ps1`; coordinator prompt surfaces under `extensions/specrew-speckit/prompts/` and `.github/agents/`
- 015-public-readiness-pass: Added PowerShell 7 (script extension), Markdown (all documentation artifacts), Git (tag operations) + `validate-governance.ps1` and `shared-governance.ps1` (existing); `.specrew/config.yml` specrew_version bump from 0.1.0-dev to 0.14.0 (version source-of-truth)
- 014-handoff-format-scoping: Added PowerShell 7.x automation plus Markdown/YAML/JSON governance artifacts + `extensions/specrew-speckit/validators/handoff-governance-validator.ps1`, coordinator prompt/checklist surfaces under `extensions/specrew-speckit/`, `specs/001-specrew-product/contracts/coordinator-handoff-template.md`, `.github/agents/squad.agent.md`, `.squad/templates/squad.agent.md`, `.specrew/quality/known-traps.md`, existing integration tests under `tests/integration/`


<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->
