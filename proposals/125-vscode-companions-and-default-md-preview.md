---
proposal: 125
title: VS Code Companions Bundle (default-md-preview Extension + Curated Companions Docs + Specrew Helper Stub)
status: candidate
phase: phase-2
estimated-sp: 4-6 (extension + docs) + Phase 2c stub for Specrew Helper
priority-tier: 2
discussion: surfaced 2026-05-22 mid-F-039; first-party `default-md-preview` extension intended as the publishing-pipeline test milestone (low scope, generic utility); pre-external-tester onboarding
---

# VS Code Companions Bundle

## Why

Specrew is markdown-heavy: spec.md, plan.md, tasks.md, state.md, drift-log.md, retro.md, review.md, decisions.md, findings.md. VS Code's default opens `.md` in source mode, which is high-friction for boundary review where readers want rendered preview. The 2026-05-22 user diagnosis identified the gap and considered three solutions:

1. Ship `.vscode/settings.json` in `specrew init` — REJECTED (too invasive; asymmetric with Proposal 069 host-agnosticism)
2. Document the snippet in getting-started.md — partial fix (no toggle-back keybinding)
3. Publish a VS Code extension — cleanest separation; opt-in via marketplace; reversible by uninstall; can include `Ctrl+Shift+V` bidirectional toggle

Option 3 is the right shape. Pair with a documentation section recommending companion extensions that Specrew users benefit from. Park the Specrew-specific helper extension idea for later.

## What

Three deliverables, sequenced.

### Deliverable 1: `default-md-preview` VS Code extension (~2-3 SP, separate GitHub repo)

Generic utility extension, NOT branded Specrew (host-agnostic per Proposal 069 alignment). Specrew docs recommend it; reusable for any markdown-heavy project. Ship as standalone GitHub repo + marketplace publish under a generic publisher.

Capabilities:

- Default `.md` files open in preview (`workbench.editorAssociations` override)
- `Ctrl+Shift+V` toggle: from preview → source (uses built-in `markdown.showSource` command scoped `when: "markdownPreviewFocus"`)
- README caveat: `Ctrl+Shift+V` is also "Paste without formatting" in some contexts; the `when` clause prevents shadowing paste in normal source editing
- License: MIT
- Engines: `^1.80.0` VS Code

**Strategic value**: shipping this is the test of the marketplace publishing pipeline (publisher account, signing, marketplace policies; ~30 min one-time setup). Low scope, generic utility, accumulates the publishing muscle before external-tester onboarding generates user demand for first-party VS Code presence.

### Deliverable 2: "VS Code companions" section in `docs/getting-started.md` (~1-2 SP)

Add a new section recommending existing extensions Specrew users benefit from. Categorized by role:

| Category | Extension | Why |
|---|---|---|
| Core | `ms-vscode.powershell` | Specrew is PowerShell-heavy; intellisense, PSScriptAnalyzer, integrated terminal |
| Core | `redhat.vscode-yaml` | Schema-aware editing for `.specrew/*.yml` |
| Core | `davidanson.vscode-markdownlint` | Same linter F-033 (Proposal 088) pre-boundary gate uses; catch violations at edit time |
| Core | `yzhang.markdown-all-in-one` | TOC, table formatting, list management |
| Visualization | `bierner.markdown-mermaid` | Renders mermaid in spec.md / review-diagrams.md; load-bearing once Proposal 081 + Proposal 121 land |
| Visualization | `eamodio.gitlens` | Specrew uses commit hashes pervasively (auth_commit_hash, drift-log, handoffs); click-through reconstruction |
| Workflow | `github.vscode-pull-request-github` | PR-at-feature-close SDLC means PRs are first-class boundary artifacts |
| Workflow | `github.copilot` | Mandatory host runtime in v1; called by `specrew start` |
| Quality of life | `streetsidesoftware.code-spell-checker` | Specrew artifacts are prose-heavy; typos in spec.md are real failure modes |
| First-party | `<publisher>.default-md-preview` | Deliverable 1 above |

### Deliverable 3: Specrew Helper extension stub (Phase 2c follow-up; defer code)

Park as a Phase 2c / external-tester-onboarding follow-up. Separate repo, not bundled with `default-md-preview`. Concrete capabilities to scope when drafting begins:

- Status-bar widget showing active feature + current boundary (`F-NNN · plan-boundary · pending verdict`)
- Snippets for canonical verdict shapes (typing `approved` autocompletes to `approved for <boundary>-boundary entry` with boundary picker)
- Command palette entries: `Specrew: Run Validator`, `Specrew: Open Active Feature`, `Specrew: Show Decisions Ledger`
- Inline rendering of `.squad/decisions.md` ledger as a tree view
- Click-through for `file:///` URIs that bypasses VS Code's external-link prompt for paths inside the workspace
- Schema validation for `.specrew/config.yml` and per-iteration `state.md` frontmatter (composes with Deliverable 2's YAML extension)

Will need its own proposal stub when scoping begins. This proposal flags the idea + composability targets; the proposal becomes a separate candidate when there's appetite for the work.

## How

### Phase 2 — Ship Deliverables 1 + 2

- **Deliverable 1** (~2-3 SP): scaffold the extension repo, write minimal `package.json` + `extension.js` (no activation needed; pure contribution), README with caveat, publish to marketplace. Ship as personal/Specrew-affiliated publisher.
- **Deliverable 2** (~1-2 SP): docs-update slice (per Proposal 055 catalog). Add the companions section to `docs/getting-started.md` with link to Deliverable 1's marketplace page.

### Phase 2c — Scope Deliverable 3

Author the Specrew Helper proposal stub when there's appetite for the work; do NOT do this in the same iteration as Deliverables 1 + 2 (different repo + different scope).

## Acceptance criteria

- **AC1**: `default-md-preview` extension published to VS Code marketplace; installable via `code --install-extension <publisher>.default-md-preview`
- **AC2**: After install, opening a `.md` file from VS Code opens in preview by default
- **AC3**: `Ctrl+Shift+V` while in markdown preview switches to source view
- **AC4**: `Ctrl+Shift+V` in non-markdown contexts still performs the default paste-without-formatting behavior
- **AC5**: Extension is uninstallable cleanly (no `.vscode/settings.json` mutation in the user's project)
- **AC6**: README caveat documents the paste-keybinding interaction
- **AC7**: `docs/getting-started.md` contains a "VS Code companions" section listing all 10 extensions (9 third-party + `default-md-preview`) with one-line purpose
- **AC8**: Deliverable 3 (Specrew Helper) stub captured as a separate proposal candidate when drafting begins (NOT delivered in this proposal)

## Out of scope

- **`.vscode/settings.json` mutation by `specrew init`** — explicitly rejected; too invasive + asymmetric with multi-host story
- **Branded "Specrew Markdown" extension** — keep Deliverable 1 generic; reusable beyond Specrew
- **Cross-IDE preview defaults** (JetBrains, Vim, Emacs) — out; community can port the pattern
- **Specrew Helper extension code** — Deliverable 3 is scope-only; code is its own future proposal
- **`.vscode/extensions.json` workspace recommendations** — could be added but doesn't belong in `specrew init`; documented in getting-started as opt-in

## Composition

- **Proposal 069 (Multi-Host Launch Path)** — Deliverables 1 + 2 are VS Code-specific. Acceptable asymmetry because opt-in, generic, no Specrew affiliation. Deliverable 3 is Specrew-specific but reads `.specrew/start-context.json` regardless of which host launched
- **Proposal 099 (Installed-File SDLC Instruction Audit)** — Deliverable 3's verdict-shape snippets compose directly with 099's "Recognized Verdict Shapes" catalog
- **Proposal 100 (Friction Dial)** — Deliverable 3's status-bar widget naturally surfaces active friction mode
- **Proposal 081 (Reviewer Visual Evidence — Mermaid Mandate)** — Deliverable 2's `bierner.markdown-mermaid` becomes more valuable once 081 + this proposal's sibling 121 ship
- **Proposal 088 (Markdown Lint Pre-Boundary, shipped)** — Deliverable 2's `vscode-markdownlint` recommendation lets users catch violations at edit time so the pre-boundary gate never needs to fire

## Risks

- **Marketplace publishing requires a Microsoft account + publisher ID** — Mitigation: one-time setup; ~30 min; documented in Deliverable 1's release notes
- **`Ctrl+Shift+V` keybinding conflict with paste-without-formatting** — Mitigation: `when: "markdownPreviewFocus"` clause; README caveat
- **Future VS Code API changes break `markdown.showSource`** — Mitigation: pin to API version; monitor VS Code release notes
- **Extension drift from Specrew's needs** — Mitigation: extension is generic; updates orthogonal to Specrew releases

## Empirical motivation

2026-05-22 user observation that `.md` opening in source mode added friction during boundary review. Three alternative solutions considered + dismissed (`.vscode/settings.json` mutation; docs snippet only); the extension approach won on separation + reversibility + keybinding ergonomics. Detailed analysis in memory `[[project-vscode-extension-recommendations-2026-05-22]]`.

## Cross-references

- file:///C:/Dev/Specrew/docs/getting-started.md (Deliverable 2 target)
- file:///C:/Dev/Specrew/proposals/069-multi-host-launch-path.md
- file:///C:/Dev/Specrew/proposals/099-installed-file-sdlc-instruction-audit.md
- file:///C:/Dev/Specrew/proposals/121-review-diagrams-mermaid-template-hardening.md (composes with markdown-mermaid recommendation)
- Memory: [[project-vscode-extension-recommendations-2026-05-22]]

## Status history

- 2026-05-22: gap surfaced; 3-deliverable design captured in memory.
- 2026-05-26: candidate proposal drafted as part of memory→proposal sweep. Scoped Deliverables 1 + 2 for Phase 2; Deliverable 3 stub-only with note that scoping begins when appetite arrives.
