---
proposal: 064
title: Slash-Command Multi-Host Correctness (F-021 Surface Restoration)
status: draft
phase: phase-2
estimated-sp: 7
discussion: tbd
---

# Slash-Command Multi-Host Correctness

## Why

F-021 (Proposal 032) shipped a `/specrew.*` command catalog with seven commands (`where`, `status`, `update`, `team`, `review`, `help`, `version`). Empirical verification on 2026-05-20 against current host documentation confirmed **the entire surface is non-functional on every major host today**:

| Bug | Why it breaks |
|---|---|
| **A. Wrong deployment path** | Specrew deploys to `<project>/.copilot/skills/`. No host discovers project skills at that path — Claude Code reads `.claude/skills/`, GitHub Copilot CLI reads `.github/skills/`/`.claude/skills/`/`.agents/skills/`, Codex CLI doesn't read it either. `.copilot/skills/` is valid only at `~/.copilot/skills/` (a personal-home path), not the project root. |
| **B. Illegal name characters** | Specrew claims `/specrew.where` (with a dot). Every host documents skill names as "lowercase letters, numbers, and hyphens only." The discoverable form is `/specrew-where`. |
| **C. Missing frontmatter** | Specrew's SKILL.md files are prose only. GitHub Copilot CLI **requires** YAML frontmatter with `name:` and `description:`. Claude Code makes frontmatter optional but recommends it. |

A user typing `/specrew-where` (let alone `/specrew.where`) in any of the three major host CLIs sees no result today. The seven commands `specrew init` advertises are aspirational documentation, not working surface — a Form-vs-Meaning bug class instance (the deployment looks correct on disk, the meaning is absent).

## What

A single-iteration fix that restores the slash-command surface to functional state across Claude Code, GitHub Copilot CLI, and the host-neutral `.agents/skills/` convention. Six pillars:

1. **Multi-host deployment**: replace single `.copilot/skills/` write with multi-deploy to `.claude/skills/`, `.github/skills/`, `.agents/skills/` (content-identical across all three).
2. **YAML frontmatter on every SKILL.md template**: required `name:` (hyphen form) + `description:` (packed with discovery triggers); optional `allowed-tools:`.
3. **Dot-namespace removal**: every `/specrew.X` → `/specrew-X` in init banners, SKILL.md prose, tests, docs, and forward-looking proposals.
4. **Legacy-path migration**: `specrew update` removes Specrew-managed `<project>/.copilot/skills/specrew-*/` directories on upgrade; leaves non-Specrew contents intact.
5. **New test coverage**: three new integration tests — multi-path deployment, frontmatter validity, migration.
6. **Proposal 058 reframing**: skills become host-neutral via this fix; Proposal 058 narrows to per-host non-skill instruction-file harmonization (`AGENTS.md`/`copilot-instructions.md`/`CLAUDE.md`).

Source spec at `file:///C:/Dev/SpecrewDraft/slash-command-multi-host-correctness.md` with full acceptance criteria (AC1–AC10), out-of-scope list, and rollout sequence.

## How (one-iteration plan)

- Feature branch `024-slash-command-multi-host-correctness` from main
- Squad drives specify → clarify → plan → tasks → implement → review → retro → iteration-closeout → feature-closeout
- PR-at-feature-close per SDLC; merge-commit only
- Version bump to 0.24.0 (Rule 15: `Specrew.psd1`, `.specrew/config.yml`, `extensions/specrew-speckit/extension.yml`)
- Tag `v0.24.0-beta.1` → PSGallery prerelease auto-publish (proven cycle from v0.23.0)
- Validate prerelease in a clean PowerShell session; smoke-test fresh init + assert three skill paths exist + frontmatter valid
- If clean → tag `v0.24.0` stable

## Composition with other proposals

| Proposal | Relationship |
|---|---|
| **F-021 (shipped as Proposal 032)** | The broken surface being fixed; F-024 honors F-021's design intent (slash commands as first-class tool identity), just makes it actually work |
| **030 (Quality Hardening Bundle)** | F-024 retro will surface a Form-vs-Meaning case study; feeds 030's corpus |
| **042 (Specrew Integration Test Suite)** | Three new tests fold into 042's broader matrix when 042 ships |
| **058 (Plugin-Based Multi-Host Distribution)** | Reframes 058's scope (per above); skills are host-neutral after F-024 ships, so 058 narrows to per-host non-skill instruction-file harmonization |
| **060 (Prerelease Channel Staging)** | Proven validation cycle exercised again |

## Acceptance signals

See full AC1–AC10 in the source spec. Headline acceptance: a developer runs `specrew init` in a fresh project, opens Claude Code or Copilot CLI, types `/`, and sees the seven `/specrew-*` commands in the discovery menu. F-021's promise becomes true.

## Cross-references

- Source spec: `file:///C:/Dev/SpecrewDraft/slash-command-multi-host-correctness.md`
- F-021 historical spec: `file:///C:/Dev/Specrew/specs/021-specrew-slash-commands/`
- F-021 proposal: `file:///C:/Dev/Specrew/proposals/032-specrew-slash-commands.md`
- Memory: `[[project-f021-slash-command-path-fix-post-f023]]` — earlier capture (estimated ~3 SP; reality 5–7 SP)
- Memory: `[[project-prerelease-channel-first-empirical-win-2026-05-19]]` — proven validation cycle
- Claude Code skills: <https://code.claude.com/docs/en/skills.md>
- GitHub Copilot CLI add-skills: <https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-skills>
- INDEX: `file:///C:/Dev/Specrew/proposals/INDEX.md`
