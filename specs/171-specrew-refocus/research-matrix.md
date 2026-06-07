# Host Hook-Surface Research Matrix (T013)

**Feature**: 171-specrew-refocus · **Iteration**: 002
**Researched**: 2026-06-07 (all sources fetched live this date — none answered from memory, per the gate's test-integrity control)
**Headline finding**: the host landscape moved decisively since the repo's Proposal-105-era research — **every host except Antigravity now has a verifiable, injection-capable hook surface**, including Copilot (the maintainer's re-verification instinct was correct: "no hook surface" is obsolete).

## Per-host findings

### Claude Code — VERIFIED (binding shipped iteration 001; contract re-verified)

- **Source**: <https://code.claude.com/docs/en/hooks> (fetched 2026-06-07)
- **Events**: 30 incl. `SessionStart` (`source: startup|resume|clear|compact`), `UserPromptSubmit`, `PostToolUse`, `PreCompact`, **`PostCompact`** (side-effect only, no injection), `Stop`, `Setup`
- **Injection**: `hookSpecificOutput.additionalContext` on 11 events incl. SessionStart, UserPromptSubmit, PostToolUse; capped 10,000 chars; wrapped in a system reminder
- **Config**: `~/.claude/settings.json` · `.claude/settings.json` (project, shareable, **NO trust prompt** — treated like `.github/workflows`) · `.claude/settings.local.json` (per-user, gitignored — our C6 placement)
- **C6 verification CLOSED**: project-local hooks require no approval prompt; the per-user placement stands on the no-clone-surprise rationale, not on trust-prompt avoidance
- **TG-004 re-evaluation input**: `UserPromptSubmit` supports `additionalContext` → a per-HUMAN-prompt B3 (~1 fire per user message) replaces the rejected per-tool-call PostToolUse

### Codex CLI — VERIFIED, FULLY BINDABLE (richest match)

- **Source**: <https://developers.openai.com/codex/hooks> (fetched 2026-06-07)
- **Events**: `SessionStart` (matcher `source: startup|resume|clear|compact` — **identical vocabulary to Claude**), `PreToolUse`, `PermissionRequest`, `PostToolUse`, `PreCompact`, **`PostCompact`** (supports `systemMessage`), `UserPromptSubmit` (**`additionalContext`**), `SubagentStart/Stop`, `Stop`
- **Injection**: `additionalContext` on SessionStart, UserPromptSubmit, PreToolUse, PostToolUse, SubagentStart ("added as extra developer context")
- **Config**: `~/.codex/hooks.json` · `~/.codex/config.toml` `[hooks]` · `<repo>/.codex/hooks.json` · `<repo>/.codex/config.toml` (layers merge with startup warning)
- **Binding decision**: **bind B1 (SessionStart source=compact) + B2 (startup|resume|clear) + B3 (UserPromptSubmit additionalContext)**; per-user analog = `~/.codex/hooks.json`? — NO: per-project-per-user file absent; nearest C6-conformant target = repo `.codex/hooks.json`… which is shareable. Placement decision: write to **`<repo>/.codex/hooks.json`** ONLY if gitignored in the project, else `~/.codex/hooks.json` with a project-path self-gate (the dispatcher already self-gates on `.specrew/`). Recorded as the binding's placement rule.

### Copilot CLI — VERIFIED, BINDABLE (the obsolete "no surface" finding is OVERTURNED)

- **Sources**: <https://docs.github.com/en/copilot/reference/hooks-configuration> + <https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/use-hooks> (fetched 2026-06-07); GA per <https://github.blog/changelog/2026-02-25-github-copilot-cli-is-now-generally-available/>
- **Events**: `sessionStart` (stdin has `source` — **values unverified in fetched docs**), `userPromptSubmitted`, `preToolUse` (fail-CLOSED: crash/timeout denies), `postToolUse` (**`additionalContext`**), `postToolUseFailure`, `agentStop`, `subagentStart/Stop`, `errorOccurred`, **`preCompact`** (`trigger: manual|auto`) — **no PostCompact found**
- **Injection**: `additionalContext` on sessionStart, notification, postToolUse, postToolUseFailure, subagentStart
- **Config**: `.github/hooks/*.json` (repo) · `~/.copilot/hooks/` (user) · `.github/copilot/settings.local.json` (**per-user project-local analog exists** — C6-conformant)
- **Caveats**: prompt hooks fire only for NEW interactive sessions (not resume, not `-p` mode); B1 mapping depends on whether `source` distinguishes compaction — **verify locally at binding implementation** (Copilot is installed on this machine)
- **Binding decision**: **bind B2 (sessionStart) + B3 (userPromptSubmitted/postToolUse — choose per local payload verification)**; B1 = pending local `source`-value verification, else documented variance (preCompact exists but is pre-, not post-)

### Cursor — VERIFIED, BINDABLE (B1 documented-variance)

- **Source**: <https://cursor.com/docs/hooks> (fetched 2026-06-07)
- **Events**: `sessionStart` (**`additional_context`** output — snake_case!), `postToolUse` (**`additional_context`**), `beforeSubmitPrompt`, `preCompact` (observational: trigger, context_usage_percent, … — **no injection, no PostCompact**), `stop` (`followup_message`), `beforeShellExecution` (permission contract), `afterFileEdit`, …
- **Config**: `<project>/.cursor/hooks.json` (project) · `~/.cursor/hooks.json` (user); Enterprise/Team layers above
- **Field-shape note**: snake_case (`session_id`, `additional_context`) vs Claude/Copilot camelCase contracts — the dispatcher's per-host output shaping must map this
- **Binding decision**: **bind B2 (sessionStart additional_context) + B3 (postToolUse additional_context for shell tools, OR beforeSubmitPrompt if injection is supported there — verify locally)**; **B1 = documented variance** (no post-compaction injection event exists)

### Antigravity — hook surface EXISTS; binding DEFERRED-WITH-PATH

- **Sources**: <https://antigravity.google/docs/hooks> (page is JS-rendered; primary contract NOT extractable via fetch) · <https://github.com/google-antigravity/antigravity-sdk-python/blob/main/google/antigravity/hooks/README.md> (SDK hooks: `PostToolCallHook`, `PreToolCallDecideHook`, `OnToolErrorHook`, `OnInteractionHook`, `PreTurnHook/PostTurnHook`; Inspect/Decide/Transform categories) · search corroboration: hooks.json in `.agents/` or `~/.gemini/config/`, before-model-call system-instruction injection
- **Honest classification**: hook-capable per multiple corroborating sources, but the **agent-manager hooks.json event vocabulary + stdin/stdout contracts were not verifiable from fetchable primary docs today**. Per the matrix-gates-bindings rule: NO binding from unverified contracts.
- **Path**: local empirical verification (agy is installed on this machine) — queued behind Codex/Copilot/Cursor bindings; until then Antigravity ships channels 1+2 with documented variance.

## Latency analysis (retro lesson #1: measurement-first)

- Our handler cost is host-independent: **pwsh cold spawn ~900ms** (10-run measurement, iteration-001 review). This rejects per-TOOL-CALL events for pwsh-based handlers on EVERY host, not just Claude.
- Acceptable frequencies: per-SESSION events (~2s incl. engine spawn, once) and per-HUMAN-PROMPT events (~1s before processing a user message — humans type slower than tools fire).
- **TG-004 re-evaluation conclusion**: B3's cheap home is `UserPromptSubmit`-class events (Claude + Codex verified `additionalContext`; Copilot `userPromptSubmitted` pending payload check). Engine-inlining (single-spawn dispatcher) remains the follow-up optimization candidate to halve session-start cost.

## Trigger-mapping decision table

| Trigger | Claude | Codex | Copilot | Cursor | Antigravity |
|---|---|---|---|---|---|
| B1 post-compaction | SessionStart `source: compact` (SHIPPED) | SessionStart `source: compact` | pending local `source` verification | **documented variance** (no event) | deferred |
| B2 launch/resume | SessionStart `startup\|resume\|clear` (SHIPPED) | SessionStart `startup\|resume\|clear` | sessionStart (new sessions only — resume gap noted) | sessionStart | deferred |
| B3 boundary-cross | channel 1 (TG-004a); candidate move: UserPromptSubmit | UserPromptSubmit `additionalContext` | userPromptSubmitted / postToolUse (verify payloads) | postToolUse `additional_context` | deferred |
| Settings placement (C6) | `.claude/settings.local.json` (SHIPPED) | repo `.codex/hooks.json` if gitignored, else `~/.codex/hooks.json` + self-gate | `.github/copilot/settings.local.json` or `~/.copilot/hooks/` + self-gate | `~/.cursor/hooks.json` + self-gate (project hooks.json is shareable) | deferred |

## T014 estimate revision (recorded for the plan)

The matrix confirms **three** immediately bindable hosts (Codex, Copilot, Cursor) with **three different config formats and two field-casing conventions** — T014's 3.0 SP planning estimate was set against an assumed smaller surface. Revised: **6.0 SP** (per-host deploy writer + dispatcher event-shape normalization + fixtures per host), iteration total **12.5/20 SP** — within cap, no deferral required; revision recorded in plan.md notes per estimation-honesty discipline.
