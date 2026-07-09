# Toolchain Probe Evidence: Spec-Kit 0.12.9 (T001)

**Feature**: 198-beta2-hardening / iteration 001
**Date**: 2026-07-10
**Method**: ephemeral `uvx --from git+https://github.com/github/spec-kit.git@v0.12.9 specify …`
(no global tool mutation), scratch project only
(`…\scratchpad\speckit-probe-001\proj` — never the governed cwd, per
condition-b-scratch-probe-only). Resolved commit at tag v0.12.9:
`80ac47e2576750036409f132a3639c9becae64aa`.

## Findings (each observed from actual CLI output)

1. **`--ai` family is gone; `--integration <key>` is the surface.**
   `specify init --help` lists `--integration TEXT` ("AI coding agent
   integration to use (e.g. --integration copilot)") and no `--ai*` flags.
   A live `specify init --here --integration copilot --script ps
   --ignore-agent-tools --force` completed successfully in the scratch
   project.
2. **`--script ps` SURVIVES** (`--script TEXT: Script type to use: sh or
   ps`); the produced tree contains `.specify/scripts/powershell/` —
   verified `Test-Path` true.
3. **`--ignore-agent-tools` SURVIVES** ("Skip checks for coding agent
   tools like Claude Code"). `--here` and `--force` survive.
4. **Multi-integration exists behind `--force`, with NEW refusal text.**
   A bare `specify integration install claude` beside copilot is refused:
   "Installing multiple integrations is only automatic when all involved
   integrations are declared multi-install safe … retry the same install
   command with --force." — the 0.8.4 message "Integration 'copilot' is
   already installed." is GONE, so `specrew-init.ps1`'s skip-detection
   regex `'(?i)already installed'` no longer matches (would fall to the
   alarming-warn branch). With `--force`: "✓ Integration 'Claude Code'
   installed successfully. Default integration remains: copilot" — the
   D-197-I009-011 single-integration limit is LIFTED on 0.12.9.
   **T002 decision**: upgrade the palette-integration loop (claude, agy)
   to pass `--force` and treat the new refusal text as the skip signal in
   the no-force fallback; revise the D-197-I009-011 comment.
5. **Git extension: NOT added (evidence-based).** `specify extension add
   git` installs `speckit.git.validate / .remote / .initialize / .commit`
   — spec-kit-side git automation including **auto-commit after Spec Kit
   commands**, which would conflict with Specrew's boundary-commit
   discipline. Specrew's governed flow does its own branch/commit work
   (`create-new-feature.ps1`, boundary commits); nothing in our flow
   depends on the git extension. Decision per I1 evidence-first
   minimalism: do not add; re-evaluate only if the 0.12.9 fixture suites
   demonstrate a dependency.
6. **Agent-context extension: fully opt-in at 0.12; not added.** A fresh
   0.12.9 init produces NO `.specify/extensions.yml` and no bundled
   extensions; Specrew's own extension provides the lifecycle hooks.
7. **Our extension's hooks schema LOADS under 0.12.9.** `specify
   extension add --dev C:\Dev\specrew-beta2-hardening\extensions\
   specrew-speckit` installed cleanly in the scratch project;
   `specify extension list` shows: "✓ Specrew Spec Kit Extension
   (v0.40.0) — specrew-speckit — Commands: 12 | Hooks: 4 |
   Priority: 10 | Status: Enabled" (per-event hook lists + priority
   ordering recognized; all 18 command/sync surfaces enumerated in the
   add output).
8. **Init tree shape on 0.12.9**: `.specify/{integrations, memory,
   scripts, templates, workflows, init-options.json, integration.json}`
   + `.github` (copilot surface) + `.vscode`. `integration.json` is new
   vs 0.8.4; `extensions.yml` appears only when an extension is added.

## Environment

- `uv 0.8.17`; the T001 probe used uvx (global tool untouched at probe
  time). At T002 verification the machine toolchain moved to the pins via
  the exact CI commands: `uv tool install --force specify-cli --from
  git+https://github.com/github/spec-kit.git@v0.12.9` (0.8.4 → 0.12.9,
  reversible with the same command @v0.8.4) and
  `npm install -g @bradygaster/squad-cli@0.11.0` (0.9.1 → 0.11.0).

## Squad 0.11.0 probe (T003)

- `npx -y @bradygaster/squad-cli@0.11.0 --version` → `0.11.0`.
- `squad init --non-interactive` in the scratch dir
  (`…\scratchpad\squad-probe-001`) → "Squad initialized." exit 0; the
  `.squad` layout is complete (agents, casting, decisions, fact-checker,
  identity, log, memory, orchestration-log, plugins, rai, templates +
  ceremonies.md, config.json, decisions.md, routing.md, team.md).
- No breaking behavior observed (release notes: adds `squad registry`,
  renames ".NET Aspire"→"Aspire" in help text).

## Suite evidence on the pinned toolchain (T002/T003, 2026-07-10)

- `tests/integration/version-info-states.tests.ps1` — PASS (exit 0) after
  Test 8 was updated from the retired 0.9.0-window lock to the
  single-tested-pin lock (shipped min supported; pre-break 0.9.0 now
  correctly behind-supported).
- `tests/integration/bootstrap-asset-blocker-recovery.ps1` — PASS (exit 0)
  after shim + assertion versions moved to the pins.
- `tests/integration/squad-duplicate-rows.tests.ps1` — PASS (exit 0);
  exercises a REAL `specrew init` (specify 0.12.9 `--integration copilot`
  + squad 0.11.0) — the live no-extensions fixture evidence.
- `tests/integration/deployed-bootstrap-floor.tests.ps1` — PASS (exit 0).
- `tests/integration/command-surface-deploy.tests.ps1` — PASS (exit 0).
- Full suite runs on the PR CI lanes (now pinned 0.12.9 / 0.11.0).

## Consequences carried into T002

- Migrate line ~621: `('init','--here','--integration','copilot',
  '--script','ps','--ignore-agent-tools')` (+ dry-run echo text).
- Palette loop: add `--force`; update skip-detection to the 0.12 refusal
  text; revise the D-197-I009-011 comment (limit lifted at 0.12.9).
- Preflight/doc text: default version 0.12.9.
- No `specify extension add git`; no agent-context extension.
