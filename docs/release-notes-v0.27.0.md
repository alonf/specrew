# Specrew v0.27.0 — First 4-host release

**Released**: 2026-05-25

## TL;DR — The headline

**v0.27.0 is the first release where external users can run the full Specrew lifecycle against four different AI host CLIs**: GitHub Copilot, Claude Code, OpenAI Codex, and Google Antigravity. Pick at launch time with `--host`:

```powershell
specrew start "<task>"                  # interactive menu (priority: claude → codex → copilot → antigravity)
specrew start --host copilot "<task>"   # non-interactive default — most-tested host
specrew start --host claude  "<task>"   # Claude Code with Specrew's bootstrap
specrew start --host codex   "<task>"   # OpenAI Codex CLI with Specrew's bootstrap
specrew start --host antigravity "<task>"  # Google Antigravity (agy)
```

The same governance, audit-trail durability, and boundary discipline runs on every host. **Switching hosts mid-feature is supported and a first-class workflow** — see the new ["Switch your AI host mid-feature" section in the README](../README.md) for the killer-feature narrative.

## Why this matters

Before v0.27.0, Specrew's methodology layer worked on Copilot only. Other hosts could launch but weren't first-class methodology citizens. **v0.27.0 makes methodology the constant; the host becomes a variable.** This unlocks:

- **Cost optimization** — alternate between hosts to multiply effective budget (your $200/mo Claude Max subscription, plus Copilot quota, plus Codex CLI, plus Antigravity)
- **Resilience to model regressions** — when one host's model changes upstream, switch hosts and keep working without losing context
- **Strength matching** — route review-heavy work to stronger models, implementation to faster/cheaper ones (Squad's per-role routing already does this on Copilot; the per-host architecture makes the same pattern available across hosts)
- **Avoid vendor lock-in** — your project's spec/plan/iteration artifacts are the source of truth; the host can change without losing project state

## What's new

### F-043: Multi-Host Onboarding + Selection Flow

Shipped from [Proposal 104](../proposals/104-multi-host-onboarding-and-selection-flow.md). Highlights:

- **`specrew host list/use/status` CLI** — manage host preferences explicitly
- **Host-history persistence** — `.specrew/host-history.yml` tracks first-used + last-used per host
- **Interactive numbered menu** — when `--host` is omitted in a TTY, Specrew shows installed hosts sorted by methodology-rigor priority (Claude → Codex → Copilot → Antigravity) and an `(not installed)` group with install URLs
- **Two-defaults model** — interactive menu defaults to highest-priority installed host; `--host` flag non-interactive default stays `copilot` for CI/automation predictability

### F-044: Per-Host Architecture Refactor

Shipped from [Proposal 108](../proposals/108-specrew-init-refactor-and-crew-runtime-abstraction.md). 9 iterations, 65.5 SP delivered. Highlights:

- **Per-host package registry** — `hosts/{copilot,claude,codex,antigravity}/` directories each declare a manifest + handlers + coordinator-prompt rules. Adding a 5th host requires ZERO edits to existing files
- **5-function host contract** — every supported host implements `New-<Kind>LaunchInvocation`, `ConvertTo-<Kind>Flag`, `Test-<Kind>RuntimeInstalled`, `Get-<Kind>Signals`, `Install-<Kind>CrewRuntime`. Mechanically extensible
- **Canonical Crew source-of-truth** — `.specrew/team/agents/<role>.md` is the canonical Crew identity for Spec Steward / Planner / Implementer / Reviewer / Retro Facilitator. Translates to each host's native subagent format on every `specrew start` (Squad `.squad/agents/`, Claude `.claude/agents/`, Codex `.codex/agents/`, Antigravity `.agents/agents/`)
- **Antigravity graduated to supported** — `agy -i <prompt> --add-dir <path> [--dangerously-skip-permissions]` launch shape verified
- **`scripts/specrew-init.ps1` refactored** — 2,428-line monolith split into 8 focused `scripts/init/*.ps1` files; testability + maintainability improved
- **Boundary-sync hardening** — `$env:SPECREW_MODULE_PATH` for child-process inheritance + 3-priority resolution chain + stale-install detection
- **Linux portability** — `scaffold-reviewer-artifacts.ps1` + the process-quality scorer, now under `tests/support/process-quality-scorer.ps1`, cross-platform-safe (verified via Antigravity WSL dogfood)
- **Methodology UX prominence** — three-section handoff format (`What I just did` / `Why I stopped` / `What I need from you`) restored to canonical-template prominence in coordinator-governance + all 5 agent charters; bare `file:///` URI requirement made explicit (markdown-link wrapping breaks PowerShell terminal Ctrl+Click)
- **Documentation depth** — closeout-of-iteration + feature-closeout explained in README + getting-started + user-guide; new "Walkthrough: a two-iteration calculator" narrative

## For external users — what you can now do

1. **Try Specrew on YOUR preferred AI host** — install Claude Code / Codex CLI / Antigravity / Copilot CLI (any one), then `specrew start` will discover what you have and offer it
2. **Switch hosts mid-feature** — close your session, restart with `specrew start --host <other>`, pick up at the same boundary with full context preserved (the spec, plan, tasks, decisions ledger live in on-disk artifacts, not agent memory)
3. **Use the interactive menu** — if you have multiple hosts installed, just `specrew start "<task>"` and pick from the priority-sorted menu
4. **Define your Crew once** — `.specrew/team/agents/<role>.md` is the canonical definition; Specrew translates to each host's format on every launch

## Known limitations

### Antigravity host caveats

- **Methodology-discipline is cooperative, not enforced** — Antigravity at the Gemini Flash tier in our 2026-05-25 smoke test was observed skipping plan-approval gates and accepting hotfixes outside the iteration lifecycle. [Proposal 105](../proposals/105-host-native-hook-deployment.md) (host-native PreToolUse hooks) addresses this structurally in a future release. Until then: pair Antigravity with a higher-tier model OR prefer Claude / Copilot for methodology-critical work.
- **Bug-fix-without-regression-test pattern** — observed empirically on Antigravity hotfixes in the smoke test. Mitigate by explicitly asking the Crew to write a failing test BEFORE the fix. [Proposal 112](../proposals/112-quality-tier-routing-runtime-verification-bundle.md) Pillar 4 will eventually enforce this; until then, prompt discipline matters.
- **Empirical smoke-test on Linux** — verified end-to-end via Antigravity-on-WSL run, but Windows-native Antigravity smoke-test is not yet documented. First Windows users may report install-quirk issues.

### Per-host coordinator overlay

Copilot users get a `.squad/coordinator-overlay.md` file containing the canonical Crew coordination directives. Claude / Codex / Antigravity users get the same coordination behavior via the bootstrap prompt, but **no overlay file is materialized** (less discoverable). Functionally equivalent; a future iteration may unify this.

### Codex has no user-defined slash commands

Codex CLI's surface differs from Claude / Copilot — there are no `/foo` user-defined slash commands. Specrew's Crew uses `pwsh -File .specify/.../sync-boundary-state.ps1` as the boundary-advance mechanism on Codex instead of `/speckit.specrew-speckit.sync-*` slash commands. Functionally equivalent; surface is just different.

### Squad runtime is Copilot-specific

Squad (the npm multi-agent runtime) is currently a Copilot-only Crew runtime. Non-Copilot hosts get the canonical Crew via the per-host translation in F-044's Slice 9, but multi-agent role-routing (the `.squad/config.json` model-override system) only fires on Copilot today. [Proposal 024](../proposals/024-multi-host-runtime-abstraction.md) tracks the cross-host runtime abstraction.

## Migration from v0.26.0

`specrew update --module` brings you to v0.27.0. Your existing `.specrew/`, `.specify/`, `.squad/` directories are preserved. The first `specrew start` after the update:

- Auto-creates `.specrew/team/agents/<role>.md` from your existing Squad team (if it exists)
- Translates canonical Crew to each host's native format on launch
- Existing iterations + spec + plan + tasks artifacts are untouched

No manual migration steps required.

## Verification

PR #844 ships with all 6 CI gates green:

- Lint (markdownlint + PSScriptAnalyzer + iteration-governance validator) ✅
- Ubuntu Validation ✅
- macOS Validation ✅
- test (Test-LegacyStateReaders) ✅
- Contract lane ✅
- Deterministic gate ✅

12 of 12 CI integration tests pass. All 12 F-044 iteration directories pass governance validator. Cross-platform path handling verified on Linux/WSL via Antigravity dogfood.

## Versioning note

Internal version: ModuleVersion `0.27.0` in `Specrew.psd1`, `specrew_version` `0.27.0` in `.specrew/config.yml`, extension manifests at `0.27.0`. The feature-aligned versioning convention (F-019 → 0.19.0) is intentionally not restored in this release — multiple features bundled into single minor versions since v0.24.x. A future methodology decision will revisit naming.

## Acknowledgments

This release was empirically validated through a 4-host smoke test running the same C++ DirectX dice-app prompt against Antigravity, Claude, Codex, and Copilot. The smoke test produced 3 follow-up proposal candidates (109, 110, 112) capturing methodology gaps observed during real cross-host use. Empirical dogfooding drives methodology evolution.

## What's next

- [Proposal 109](../proposals/109-open-feature-awareness-and-multi-feature-switching.md) — Open-Feature Awareness + Multi-Feature Switching
- [Proposal 110](../proposals/110-specrew-update-experience.md) — Specrew Update Experience
- [Proposal 111](../proposals/111-git-hook-markdownlint-enforcement.md) — Git-Hook Markdownlint Enforcement
- [Proposal 112](../proposals/112-quality-tier-routing-runtime-verification-bundle.md) — Quality-Tier Routing + Runtime Verification + 4 more pillars
- F-041 (Cost-Aware Model Routing) and F-042 (Token Economy MVP) — sequenced for v0.28.0 unless re-prioritized
