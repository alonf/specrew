---
proposal: 071
title: VS Code Copilot Chat as a First-Class Specrew Host
status: candidate
phase: phase-2
estimated-sp: 10-12
discussion: tbd
---

# VS Code Copilot Chat as a First-Class Specrew Host

## Why

User feedback 2026-05-20:

> "There are people who prefer to use rich UI, so using VSCode, Codex app and Claude app is their preference."

Specrew's current host strategy targets terminal-based CLI hosts: Copilot CLI (today), Claude Code CLI (today), Codex CLI (Proposal 069). Many developers spend their day inside VS Code and would rather drive Specrew from the **Copilot Chat window** than switch to a terminal session.

Today's empirical state in VS Code:

| Surface | Status | Why |
|---|---|---|
| VS Code integrated terminal → `specrew start` | ✓ works | terminal-equivalent; full lifecycle runs in the spawned Copilot CLI subprocess |
| `.github/copilot-instructions.md` loaded by Chat | ✓ works | VS Code Copilot Chat reads this natively, so Chat has Specrew project context for ad-hoc questions |
| `/specrew-where`, `/specrew-help`, etc. in the Chat slash menu | ✗ not visible | F-024 deploys these as Copilot CLI / Claude Code skills under `.github/skills/`, `.claude/skills/`, `.agents/skills/`; VS Code Chat uses a different convention (`.github/prompts/*.prompt.md`) which Specrew does not write to |
| Squad coordinator inside Chat | ✗ not available | `.github/agents/squad.agent.md` is a Copilot CLI agent format; VS Code Chat uses `.github/chatmodes/*.chatmode.md` and extension-registered participants |
| Driving the lifecycle (specify / clarify / plan / tasks) from Chat | ✗ not supported | requires either Chat-mode awareness or an extension-registered participant |

The gap is closable for **VS Code Chat specifically** without writing a VS Code extension, just by writing the workspace files VS Code Chat already reads natively. That makes it a high-leverage tactical proposal — small SP, big UX impact for the rich-UI-first segment.

The Codex app (cloud) and Claude app (desktop/web) are explicitly **out of scope** for this proposal — they have different extensibility models with no workspace-file surface to write to. They are tracked as candidate follow-up proposals (see Pillar 7).

## What

### Pillar 1: VS Code slash-command parity (`/specrew-*` in the Chat menu)

Write `.github/prompts/specrew-{where,status,update,team,review,help,version}.prompt.md` — one prompt per F-024 command. Each prompt:

- Has valid YAML frontmatter (per VS Code Copilot Chat's prompt-file schema)
- Instructs Chat to invoke the corresponding shell command via Chat's tool-use capability and surface the output
- Documents the boundary semantics (e.g. `/specrew-help` is discovery-only, does not advance any lifecycle boundary — matching F-024's SKILL.md contract)

Content is host-aware (acknowledges the Chat surface) but **mechanically equivalent** to F-024's SKILL.md files — same command catalog, same boundary semantics, same not-found fallback (`/specrew-help`).

### Pillar 2: Squad coordinator chat mode

`.github/chatmodes/squad-coordinator.chatmode.md` that switches the Copilot Chat window into Squad coordinator behavior:

- Loads `.specrew/last-start-prompt.md` and `.specrew/start-context.json` as the authoritative handoff
- Follows the same lifecycle conventions as Squad in Copilot CLI (specify → clarify → plan → tasks → implement)
- Honors F-016 and F-066 boundary discipline — pauses at every human-approval boundary, never auto-resolves substantive intake
- Surfaces handoff-format scoping per F-014 (only the three approval handoffs use the structured format)

**Boundary acknowledgment**: this Chat-mode can drive the lifecycle by invoking workspace tools (file ops, shell-out for `validate-governance.ps1`, `resolve-quality-profile.ps1`, etc.). It **cannot** spawn new Copilot CLI processes the way a terminal Squad can. That is acceptable for the workspace-file-based lifecycle; the gap closes further if Pillar 6 (extension) eventually ships.

### Pillar 3: `specrew init` extends the bootstrap

Extend the bootstrap orchestrator to write `.github/prompts/` and `.github/chatmodes/` alongside the existing `.github/skills/`. Purely additive:

- CLI hosts (Copilot CLI, Claude Code, Codex CLI) ignore the new files
- VS Code Chat picks them up natively
- No conflict with existing `.github/copilot-instructions.md`

`specrew update` propagates new versions of the prompt/chatmode files into existing projects on the same migration discipline that F-024 follows for `.github/skills/`.

### Pillar 4: Multi-host coexistence + content discipline

`.github/copilot-instructions.md` is already deployed by Specrew and serves both Copilot CLI and VS Code Chat. The new prompt/chatmode files must compose cleanly:

- Prompts are **discovery triggers**, not redefinitions of the instructions
- The chatmode points to `copilot-instructions.md` for governing prose, not reinventing it
- Validator rule: detect duplicate instruction content across `copilot-instructions.md`, `prompts/*.prompt.md`, and `chatmodes/*.chatmode.md` (composes with Proposal 004 validator hardening)

### Pillar 5: Documentation

Add `docs/vscode-host.md` (or extend `docs/user-guide.md`) explaining:

- What works from the VS Code Chat window today (slash commands, chatmode, ad-hoc questions with project context)
- What still requires the integrated terminal (`specrew start` itself, full Squad CLI lifecycle for greenfield init)
- The recommended workflow: open VS Code → integrated terminal does `specrew start` → Squad runs in terminal → use Chat window as a sidecar for `/specrew-where`, ad-hoc code questions, and lightweight slice work
- Link to F-024 source spec and this proposal for the architecture rationale

### Pillar 6 (deferred — separate follow-up proposal): VS Code Marketplace extension

A real `@specrew` chat participant via the VS Code Extension API would offer:

- True `specrew start` from Chat (the extension shells out)
- Live status panel
- Inline approval prompts that integrate with VS Code's notification surface
- First-class participant registration so `@specrew` appears alongside `@workspace`, `@github`, etc.

This is a much larger lift: TypeScript, build pipeline, marketplace publishing, signing, update channel, security review. **Defer until Pillars 1–5 prove the user demand empirically.** Track as a future proposal (provisional number 072+ when scoped).

### Pillar 7 (out of scope — candidate follow-up proposals): Codex app and Claude app hosts

The user explicitly flagged these as "I am not sure how easy is to implement" — and they are right that the work is structurally different:

| Host | Extensibility surface | Why this proposal does NOT cover it |
|---|---|---|
| **Codex app** (OpenAI's hosted Codex experience) | Cloud-side agent extensibility model; no workspace-file convention equivalent to VS Code Chat | Requires server/MCP-style integration, not file-write; cannot reuse `.github/*.md` artifacts |
| **Claude app** (web at claude.ai + desktop apps) | Project-scoped custom instructions exist; no slash-command surface for workspace files | Could use MCP server as the integration point, but that is a different architectural pattern |

Each is potentially a separate candidate proposal once empirical demand justifies the work. Specrew's prioritization signal is concrete user requests, not speculative coverage.

## How (one-iteration plan)

- Feature branch from `main` (per SDLC; merge-commit only)
- Squad drives specify → clarify → plan → tasks → implement → review → retro → closeout
- New templates under `extensions/specrew-speckit/templates/github/` (or wherever bootstrap templates live):
  - 7 × `prompts/specrew-*.prompt.md`
  - 1 × `chatmodes/squad-coordinator.chatmode.md`
- Extend `specrew-init.ps1` / bootstrap orchestrator to deploy the new files; extend `specrew update` for migration
- Integration tests:
  1. After fresh `specrew init`, the 7 prompt files exist with valid frontmatter
  2. After fresh `specrew init`, the chatmode file exists with valid frontmatter
  3. Existing F-024 deploy paths (`.claude/skills/`, `.github/skills/`, `.agents/skills/`) still work (no regression)
  4. `.github/copilot-instructions.md` content is byte-identical to the pre-change baseline (additive only)
  5. `specrew update` migrates an existing project from a pre-F-NNN state to the new layout without overwriting human edits
- Manual smoke: open VS Code → fresh `specrew init` → type `/` in Copilot Chat → verify `/specrew-*` commands appear in the menu → invoke one and verify it runs the underlying shell command
- Version bump per Rule 15 (`Specrew.psd1`, `.specrew/config.yml`, `extensions/specrew-speckit/extension.yml`)
- Tag `vX.Y.Z-beta.1` → PSGallery prerelease → manual smoke in VS Code → tag stable

## Composition with other proposals

| Proposal | Relationship |
|---|---|
| **F-024 (shipped — Proposal 064)** | Slash-command catalog. This proposal adds a fourth deploy path (`.github/prompts/`) for the same catalog, host-adapted for VS Code Chat. |
| **058 (candidate) Plugin-Based Multi-Host Distribution** | This proposal is either a slice of 058 (the workspace-file-based portion) or a precursor (validates the per-host workspace-file harmonization shape before 058's broader plugin packaging lands). |
| **069 (draft) Multi-Host Launch Path** | Complementary: 069 covers CLI hosts (`specrew start --host claude\|codex\|copilot`), this covers a chat-host workspace-file surface. Both compose under the eventual 024 abstraction. |
| **024 (candidate) Multi-Host Runtime Abstraction CORE** | If 024 ships first, this proposal becomes a simpler consumer; if this ships first, it informs 024's host-shape interface. |
| **F-016 / F-066 (shipped)** | The Squad chatmode in Pillar 2 MUST respect the same boundaries as CLI Squad (gate-respecting default; pause at every approval boundary). |
| **052 (candidate) Specrew Profile System** | `vscode-host` could be modeled as an opt-in profile that gates the additional file deploys, if always-on deploy is undesirable. |
| **004 / 030 (validator hardening + quality bundle)** | Pillar 4's content-duplication rule plugs into the validator. |
| **042 (candidate) Specrew Integration Test Suite** | The new tests fold into 042's broader matrix when 042 ships. |

## Acceptance signals

- **AC1**: After fresh `specrew init` in a clean project, `.github/prompts/specrew-{where,status,update,team,review,help,version}.prompt.md` all exist with valid YAML frontmatter conforming to VS Code Copilot Chat's prompt-file schema
- **AC2**: After fresh `specrew init`, `.github/chatmodes/squad-coordinator.chatmode.md` exists with valid YAML frontmatter
- **AC3**: Opening the project in VS Code, opening Copilot Chat, and typing `/` surfaces `/specrew-where` through `/specrew-version` in the discovery menu
- **AC4**: Invoking `/specrew-where` from VS Code Chat runs the equivalent shell command and shows the dashboard inside the Chat surface
- **AC5**: Activating the `squad-coordinator` chatmode causes the chat to behave as Squad coordinator: loads `.specrew/last-start-prompt.md`, surfaces lifecycle state, pauses at the same boundaries CLI Squad pauses at
- **AC6**: Existing F-024 surface in Copilot CLI and Claude Code remains unchanged (regression check; the 21-file × 7-command matrix from F-024's smoke remains green)
- **AC7**: `.github/copilot-instructions.md` content remains coherent with the new prompt files — no duplicate instruction content, no contradictions, no broken references (validator-enforced per Pillar 4)
- **AC8**: A non-CLI-preferring tester (using only VS Code + Copilot Chat) can complete an end-to-end iteration: spec authoring + clarify + plan + tasks + implement — surfacing the same handoffs and boundaries the CLI flow does, accepting that `specrew start` itself still runs in the integrated terminal

## Cross-references

- F-024 source proposal: file:///C:/Dev/Specrew/proposals/064-slash-command-multi-host-correctness.md
- Proposal 058 (plugin-based multi-host distribution): file:///C:/Dev/Specrew/proposals/058-plugin-based-multi-host-distribution.md
- Proposal 069 (multi-host launch path): file:///C:/Dev/Specrew/proposals/069-multi-host-launch-path.md
- Proposal 024 (multi-host runtime abstraction CORE): file:///C:/Dev/Specrew/proposals/024-multi-host-runtime-abstraction.md
- VS Code Copilot Chat customization docs: <https://code.visualstudio.com/docs/copilot/copilot-customization>
- VS Code prompt files documentation: <https://code.visualstudio.com/docs/copilot/copilot-customization#_prompt-files>
- VS Code custom chat modes documentation: <https://code.visualstudio.com/docs/copilot/copilot-customization#_custom-chat-modes>
- INDEX: file:///C:/Dev/Specrew/proposals/INDEX.md
