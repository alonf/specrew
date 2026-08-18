# Specrew Development Guidelines

Auto-generated from all feature plans. Last updated: 2026-06-17

## Active Technologies

- PowerShell 7.x plus Markdown/YAML/JSON governance and contract artifacts. + Existing Specrew module/script surfaces, Git CLI, and installed headless AI host CLIs when explicitly configured/authorized; no new dependencies. (197-continuous-co-review)
- Versioned filesystem artifacts only. Durable evidence under `.specrew/review/inline/<run-id>/...`; temporary immutable bundles in per-run workspaces. (197-continuous-co-review)

- PowerShell 7.x plus Markdown/YAML/JSON governance artifacts + `scripts/specrew.ps1`, `scripts/specrew-update.ps1`, `scripts/specrew-start.ps1`, `Specrew.psd1`, `extensions/specrew-speckit/scripts/validate-governance.ps1`, mirrored `.specify/extensions/specrew-speckit/scripts/validate-governance.ps1`, `tests/integration/publish-module-harness.tests.ps1`, `tests/integration/non-specrew-session-bypass.tests.ps1`, and the Spec Kit prompt/workflow surfaces for `/speckit.specify` (049-pipeline-hardening-intake)
- Git-tracked Markdown/YAML/JSON/PowerShell assets under `docs/`, `scripts/`, `extensions/`, `.specify/`, `.github/`, and `specs/049-pipeline-hardening-intake/` (049-pipeline-hardening-intake)

- PowerShell 7.x scripts plus Markdown/YAML/JSON governance artifacts; downstream Specrew config currently pins Spec Kit `0.12.9` and Squad `0.11.0` in `.specrew/config.yml` + `extensions/specrew-speckit` script/template surfaces, `.specify` plan workflow, Squad-native runtime deployment via `deploy-squad-runtime.ps1`, existing governance/evaluation scripts under `tests/integration/` and `tests/support/` (008-quality-profile-foundation)
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
- PowerShell 7.x scripts plus Markdown/YAML/JSON governance artifacts + `scripts/specrew.ps1`, `scripts/specrew-where.ps1`, mirrored `extensions/specrew-speckit` + `.specify/extensions/specrew-speckit` governance scripts, `.specify/feature.json`, `.specrew/iteration-config.yml`, `.specrew/role-assignments.yml`, `specs/**` iteration artifacts, `.specrew/roadmap.yml`, and Git-tracked docs/tests (017-velocity-dashboard)
- PowerShell 7.x scripts plus Markdown/YAML/JSON governance artifacts + `scripts/internal/dashboard-renderer.ps1`, `scripts/specrew.ps1`, (018-velocity-dashboard-visual-richness)
- Git-tracked file artifacts only under `specs/`, `.specrew/`, `.specify/`, `docs/`, (018-velocity-dashboard-visual-richness)
- PowerShell 7.x scripts plus Markdown/YAML/JSON governance artifacts + `scripts/internal/dashboard-renderer.ps1`, `scripts/specrew.ps1`, `scripts/specrew-where.ps1`, mirrored `extensions/specrew-speckit` + `.specify/extensions/specrew-speckit` closeout/validator scripts, `.specify/feature.json`, `.specrew/roadmap.yml`, `specs/**` dashboard artifacts, `docs/dashboard-guide.md`, `README.md`, and dashboard fixture/test harnesses under `tests/` (018-velocity-dashboard-visual-richness)
- Git-tracked file artifacts only under `specs/`, `.specrew/`, `.specify/`, `docs/`, `scripts/`, `extensions/`, and `tests/` (018-velocity-dashboard-visual-richness)
- PowerShell 7+ for runtime scripts and module entry points; Markdown/YAML skill metadata for the slash-command contract + Existing `scripts/specrew.ps1` dispatcher, `Specrew.psm1` alias/module surface, Specrew distribution/update flows, Squad-native SKILL.md deployment surfaces, shared governance/version-check helpers (021-specrew-slash-commands)
- File-based only: legacy `.copilot/skills/` migration targets plus `.squad/templates/skills/`, `.specrew/config.yml`, feature docs under `specs/021-specrew-slash-commands/`, and existing repository scripts/docs (021-specrew-slash-commands)
- PowerShell 7.x for the active runtime/test lane, while preserving existing Specrew PowerShell module compatibility expectations + `scripts/specrew-start.ps1`, `scripts/internal/sync-boundary-state.ps1`, `extensions/specrew-speckit/scripts/scaffold-feature-closeout-dashboard.ps1`, lifecycle sync command wrappers under `extensions/specrew-speckit/commands/`, shared governance helpers, Git CLI (022-hotfix-schema-tests)
- File-based only (`.specrew/`, `.squad/`, `specs/`, `tests/`) (022-hotfix-schema-tests)
- PowerShell 7.0+ (per Specrew.psd1 PowerShellVersion requirement) + PowerShell-Yaml module (for YAML parsing), ConvertFrom-Json -AsHashtable (available in PS 6.0+) (023-legacy-state-read-tolerance)
- Local filesystem state files (JSON, YAML); paths: `.specrew/`, `.specify/`, `.squad/`, `tasks-progress.yml` (023-legacy-state-read-tolerance)
- PowerShell 7.4+ (module code), Markdown (skill templates), PowerShell 5.1 Pester (integration tests) + Specrew PowerShell module (`Specrew.psm1`), Pester v5.3+, Git 2.40+ (024-slash-command-multi-host-correctness)
- Filesystem (Specrew-managed skill deployments in `.claude/skills/`, `.github/skills/`, `.agents/skills/`, legacy `.copilot/skills/`), managed-marker detection via existing hygiene tooling (024-slash-command-multi-host-correctness)
- PowerShell 7.0+ (per `Specrew.psd1`), Markdown skill templates with YAML frontmatter + Specrew PowerShell module/runtime scripts (`Specrew.psm1`, `scripts/*.ps1`, `extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1`), Git, standard PowerShell file/YAML handling already used in-repo (024-slash-command-multi-host-correctness)
- Filesystem only — source templates under `extensions/specrew-speckit/squad-templates/skills/`, active deployment targets `.claude/skills/`, `.github/skills/`, `.agents/skills/`, legacy migration target `.copilot/skills/` (024-slash-command-multi-host-correctness)
- PowerShell 7+ (primary runtime scripts), Markdown docs + Spec Kit CLI (`specify`), Squad CLI (`squad`), Git, module/runtime scripts under `scripts/` and `extensions/specrew-speckit/scripts/` (046-create-spec-branch)
- File-based project artifacts (`.specrew/`, `.specify/`, `.squad/`, `.github/`) (046-create-spec-branch)

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

- 197-continuous-co-review: Added PowerShell 7.x plus Markdown/YAML/JSON governance and contract artifacts. + Existing Specrew module/script surfaces, Git CLI, and installed headless AI host CLIs when explicitly configured/authorized; no new dependencies.

- 049-pipeline-hardening-intake: Added PowerShell 7.x plus Markdown/YAML/JSON governance artifacts + `scripts/specrew.ps1`, `scripts/specrew-update.ps1`, `scripts/specrew-start.ps1`, `Specrew.psd1`, `extensions/specrew-speckit/scripts/validate-governance.ps1`, mirrored `.specify/extensions/specrew-speckit/scripts/validate-governance.ps1`, `tests/integration/publish-module-harness.tests.ps1`, `tests/integration/non-specrew-session-bypass.tests.ps1`, and the Spec Kit prompt/workflow surfaces for `/speckit.specify`

- 046-create-spec-branch: Added PowerShell 7+ (primary runtime scripts), Markdown docs + Spec Kit CLI (`specify`), Squad CLI (`squad`), Git, module/runtime scripts under `scripts/` and `extensions/specrew-speckit/scripts/`

<!-- MANUAL ADDITIONS START -->
  renderer exposed by `scripts/specrew.ps1 where`, `scripts/specrew.ps1 status`,
  and `scripts/specrew-where.ps1`.
  current repository or project status (for example: "show the current project
  status", "where are we in this repo", "summarize roadmap progress for this
  project"). Do **not** route for other status prompts (for example: "what's your
  status?", "show the status of PR #125", "reviewer status"). If intent is
  ambiguous, stay in normal conversational mode rather than forcing the
  dashboard.
  closeout snapshots, `.specrew/roadmap.yml`, validator warnings, docs, and
  fixture-backed tests.
<!-- MANUAL ADDITIONS END -->

<!-- >>> specrew-managed coordinator >>> -->
## How this project works

This project uses Specrew. Work here runs through a spec → plan → implement → review → retro lifecycle,
and each stage boundary is authorized by the human before the next one starts.

**A session opens by orienting the human, not by starting work.** Your first reply shows them, as
visible prose: that Specrew is active and which version and host, where this project currently stands
in the lifecycle, where their artifacts live, what will be asked of them at boundaries, and how you are
adapting to them — the user-profile expertise dials, so they can see what you believe about them and
correct it if it is wrong. The session hook hands you that orientation to SHOW; reading it to orient
yourself is not rendering it, and the difference is invisible from the inside. A human who never sees
it learns this project by being interrupted by it later, at a boundary they did not know was coming,
and cannot correct an adaptation they were never shown. A concrete request in the human's first message
does not replace the orientation: announce what is starting and render the orientation with it.

**New features start with the design workshop.** The `specrew-design-workshop` skill is the discovery,
analysis and design step for a new feature: its lenses gather users, pain, MVP, language and stack,
constraints and limits, with the human, one lens at a time. It comes before the spec. Grounding and
clarification questions belong inside it rather than ahead of it, because it already covers them, and
`speckit-specify` is the spec-writer the workshop leads to rather than a parallel route into the same
work. A spec written before the workshop skips the part that decides what the spec should say — including
when the request already reads as complete, since a clear request is where that shortcut is most
tempting and the assumptions it hides are the ones nobody notices.
Workshop questions are visible prose answered by a typed human reply on every host. Closing or dismissing a
question UI (including Copilot Ctrl+O / `User skipped question`) is an absence, not permission to choose defaults
or record delegation. The governed feature/controller exists before the first grounding question.
User-facing refusals state what could not be completed without asserting that Specrew is broken or at fault.
When true, they say that the human's answers or work are safe, propose one concrete recovery action, and ask
for approval before taking it. Technical diagnosis belongs in the project's drift record, not in the message
shown to the human.

**The rest of the lifecycle runs through the governed commands.** Plan, tasks and implement go through
the per-boundary speckit commands where the host exposes them, otherwise the governed lifecycle scripts:
`.specify/extensions/specrew-speckit/scripts/create-governed-feature.ps1`, `validate-governance.ps1`, and the `sync-*`
boundary wrappers. Those scripts and commands are the machinery of this project. The raw, un-governed
`specify.exe workflow` and the bundled SDD automation bypass the boundary gates and are not used here —
the Specrew-governed scripts above are not that.

**Boundaries are where the human decides.** At each one the work stops, the human re-entry packet is
presented, and the next stage begins after an explicit `approved for <boundary>` reply. A boundary is not
advanced on an assessment that the work is obviously fine; the approval is the mechanism, and code
written without one is outside the process this project follows.

**Where the current state lives.** `.specrew/last-start-prompt.md` holds the launch contract and
`.specrew/start-context.json` holds the lifecycle position — the active feature, the last authorized
boundary, and what is pending. Both are read from the project root before acting, because they describe
where this project currently is rather than what it does in general.
<!-- <<< specrew-managed coordinator <<< -->
