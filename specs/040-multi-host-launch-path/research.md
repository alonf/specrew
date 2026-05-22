# Research: Multi-Host Launch Path

**Spec**: [spec.md](./spec.md) | **Plan**: [plan.md](./plan.md) | **Date**: 2026-05-23
**Inputs**: 2026-05-23 multi-host research wave (5 parallel agents: Claude Code, Codex CLI, Google Antigravity, Squad CLI inventory, internal Specrew/Squad coupling audit); Proposal 069 enrichment (commit `e3c47ddd`); 4 clarify decisions.

This file answers the four research tasks that govern F-040's design decisions. Each task lists the primary-doc evidence for its conclusion.

---

## Task 1: Verified per-host CLI launch invocations

**Decision**: Use the per-host invocation shapes below. Each is verified against current CLI documentation or hands-on guides as of 2026-05-23.

### Copilot CLI (baseline — no change)

```text
copilot --agent 'Squad' --add-dir '<project>' -i '<bootstrap-prompt>' [--allow-all] [--autopilot] [--remote]
```

Source: existing `scripts\specrew-start.ps1:3131` literal (current production behavior). Documentation: <https://docs.github.com/en/copilot/how-tos/copilot-cli>.

### Claude Code

```text
claude -p '<bootstrap-prompt>' --add-dir '<project>' [--dangerously-skip-permissions] [--remote-control]
```

Optional `--bare` flag preceding `-p` provides hermetic clean session (no prior conversation memory).

Sources: <https://code.claude.com/docs/en/cli-reference>, <https://code.claude.com/docs/en/headless>, <https://code.claude.com/docs/en/remote-control>. Hands-on confirmation: 2026-05-23 Claude Code research agent.

Key findings:

- `--add-dir <path>` IS the same flag name as Copilot CLI (load-bearing for the dispatch — no flag-name translation needed for working-dir)
- `--dangerously-skip-permissions` is the equivalent of Copilot's `--allow-all` (and Claude's permission system has six modes: `default|acceptEdits|plan|auto|dontAsk|bypassPermissions` via `--permission-mode`)
- `-p` (or `--print`) is the headless one-shot prompt entry — direct equivalent of Copilot's `-i`
- Per-subagent `model:` field in `.claude/agents/*.md` frontmatter enables direct per-role cost routing (relevant for Proposal 068 / F-041)
- `--remote-control` (or `--rc`) is the remote-control flag — streams to claude.ai / Claude app

### Codex CLI

```text
codex exec --cd '<project>' [--full-auto | --yolo] '<bootstrap-prompt>'
```

Sources: <https://developers.openai.com/codex/cli>, AGENTS.md convention. Hands-on confirmation: 2026-05-23 Codex CLI research agent.

Key findings:

- `codex exec` is the non-interactive subcommand (analogous to `copilot -i`)
- `--cd <path>` is Codex's working-directory flag (different from Copilot's `--add-dir`)
- `--full-auto` is the unattended-execution flag; `--yolo` auto-approves dangerous operations
- AGENTS.md at project root provides persistent memory across sessions
- Per-agent `.codex/agents/*.toml` files support per-role `model = "<name>"` override
- No user-defined slash commands today (constrains skill-discoverability surface in FR-009 / User Story 3)
- No native remote-control surface (Codex `--remote` → warn-and-continue per FR-007)

### Antigravity (deferred per clarify Q1)

Captured for posterity, not implemented in F-040:

```text
agy -p '<bootstrap-prompt>' --output-format json [--cwd '<project>']
```

Sources: 2026-05-23 research wave; <https://developers.googleblog.com/build-with-google-antigravity-our-new-agentic-development-platform/>.

Open issues blocking F-040 inclusion:

- Working-directory flag (`--cwd`?) undocumented; needs empirical verification
- `agy --print` session-ID emission is an open issue ([antigravity-cli#7](https://github.com/google-antigravity/antigravity-cli/issues/7)) — affects session-resume contract
- 2026-06-18 Gemini CLI free-tier deadline → users hit billing wall

Specrew already deploys skills to `.agents/skills/` per F-021 — Antigravity's native skill directory IS `.agents/skills/`, so the future Antigravity slice will be partially set up.

---

## Task 2: Flag-translation matrix

**Decision**: Translation lives in `scripts\internal\host-flag-translation.ps1` as a per-host map. F-040 ships translations for `--remote`, `--allow-all`, `--autopilot`. Future per-host flags compose into the same helper as small-fix slices.

### Translation table

| Specrew-side flag | Copilot | Claude | Codex |
|---|---|---|---|
| `--remote` | `--remote` | `--remote-control` | (warn-and-continue, no remote wiring) |
| `--allow-all` | `--allow-all` | `--dangerously-skip-permissions` | `--full-auto` |
| `--autopilot` | `--autopilot` | (drop; informational notice — Claude has no direct equivalent) | `--full-auto` (folds into `--allow-all` mapping) |
| `--autonomous` (Specrew's own) | (no host-side translation — handled by Specrew's lifecycle boundary enforcement per F-039) | (same) | (same) |

Key design decisions:

- **`--autonomous` is NOT a host-side flag** per Proposal 066. It's the Specrew-side opt-in for lifecycle boundary enforcement (F-039). All hosts get the same Specrew-side treatment.
- **`--autopilot` on Claude drops** because there's no clean Claude equivalent. The informational notice tells the user "Claude doesn't have an autopilot mode; use `--autonomous` for unattended runs."
- **`--remote` on Codex warns-and-continues** rather than failing because the spec's User Story 2 explicitly requires warn-and-continue (AC3). Users opting into `--remote` on Codex still get the session, just without remote-control wiring.

---

## Task 3: Host validation flow

**Decision**: Validate host kind before any other Specrew work. The validation flow is:

1. **Parse `-Host <kind>` parameter.** If `<kind>` is in the deferred set (`antigravity`, `auto`), reject with explicit guidance + exit code 1.
2. **Probe PATH for the requested host's binary.** If missing, print install guidance for that host (per-host doc URL) + exit code 1.
3. **Populate `.specrew/start-context.json` `available_hosts` field** via parallel PATH probe for all three supported hosts (copilot, claude, codex).
4. **If the requested host is available, persist `selected_host: <kind>`** in start-context.json and proceed to launch dispatch.

### Why before any Specrew work

Validating early means the user gets fast feedback on misconfiguration. The PATH probe is cheap (~100ms for three parallel `Get-Command` calls using the ForEach-Object -Parallel pattern F-035 introduced).

### Why available_hosts is populated even when one is selected

Future Proposal 104 first-run probe + last-host history feature needs this data. Recording it now (additive field) avoids a follow-up migration when 104 ships.

### Deferred-host guidance text

- `--host antigravity`: "Antigravity host deferred to follow-up slice. See file:///C:/Dev/Specrew/proposals/069-multi-host-launch-path.md (Antigravity preview status). Empirical verification of `agy` working-directory and session-ID emission required before enablement."
- `--host auto`: "Auto-selection deferred to Proposal 104 (Multi-Host Onboarding + Selection Flow). Use `--host copilot|claude|codex` explicitly until F-043 ships. See file:///C:/Dev/Specrew/proposals/104-multi-host-onboarding-and-selection-flow.md."

---

## Task 4: Cross-platform launch parity

**Decision**: Per-host invocations slot into the existing Windows + Linux dispatch branches at `scripts\specrew-start.ps1:3181-3243`. The branch structure stays the same; only the argv list per branch becomes per-host.

### Current dispatch shape (Windows + Linux)

```powershell
# Windows
Start-Process pwsh -ArgumentList @('-NoLogo', '-NoExit', '-Command', $launchScript)

# Linux (deferred-launch via TTY-preserving function context)
$env:SPECREW_DEFERRED_LAUNCH_FILE = $deferredLaunchPath
# Caller picks up the file, sources it as a function
```

In both branches, the final invocation is `& copilot @copilotArgs` (or equivalent), where `@copilotArgs` is the argv splat assembled in `:3169-3178`.

### F-040 dispatch shape

```powershell
$hostKind = Get-SpecrewHostKind  # from -Host parameter or default
$launchInvocation = Get-SpecrewHostLaunchInvocation -Host $hostKind  # returns @{ Binary = '...'; Args = @(...) }

# Both branches now use:
& $launchInvocation.Binary @($launchInvocation.Args)
```

The Windows `Start-Process pwsh ...` and Linux `SPECREW_DEFERRED_LAUNCH_FILE` patterns are unchanged; only the final invocation line is parameterized.

### Cross-platform verification

The existing CI matrix at `.github/workflows/specrew-ci.yml` already runs on Windows + Linux (cross-platform validation per F-019). F-040's integration tests check both branches via `$IsWindows` switch in test setup. No new CI plumbing needed.

---

## Task 5: Host capability comparison (hooks, skills, slash commands, subagents, MCP, project memory)

**Decision**: F-040 manages SKILLS + SLASH COMMANDS (uniformly via existing F-021 multi-host deploy) and applies a **universal coordinator-prompt header** for all hosts. F-040 EXPLICITLY DEFERS hook deployment, MCP wiring, project-memory files, and subagent files to future proposals — those are not blockers for the launch-path MVP but are real divergences worth documenting.

### Capability matrix

| Capability | Copilot CLI | Claude Code | Codex CLI | F-040 treatment |
|---|---|---|---|---|
| **User-defined slash commands** | ✅ `.github/skills/<name>.md` → `/specrew-<name>` | ✅ `.claude/skills/<name>/SKILL.md` (agentskills.io standard) → `/specrew-<name>` | ❌ **NOT SUPPORTED** | F-040 deploys skill files per F-021; FR-013 logs informational note on Codex |
| **Skills as reusable behaviors** | ✅ Same as slash commands | ✅ Same; richer YAML frontmatter | ⚠️ No skill surface; subagents in `.codex/agents/*.toml` cover some overlap | Skills already deployed; F-040 verifies discoverability per host (FR-009) |
| **Hooks (lifecycle interceptors)** | ❌ **None** | ✅ Rich: `PreToolUse`, `PostToolUse`, `SubagentStart`, `Stop`, `TaskCreated`, `TaskCompleted`, more — configured in `.claude/settings.json` | ⚠️ Unclear; subagents have lifecycle but hook surface undocumented at research time | **Out-of-scope.** Future opportunity: F-039 boundary enforcement could move from skill-side gates to Claude's hook layer |
| **Subagents (multi-agent teams)** | ⚠️ Via `--agent <name>` (Squad) | ✅ `.claude/agents/*.md` with YAML frontmatter; `model:` field per-agent | ✅ `.codex/agents/*.toml`; per-agent `model = "..."` | **Out-of-scope.** Proposal 024 Slice 3 owns per-host Crew runtime install |
| **MCP support** | ⚠️ Limited (recent addition) | ✅ First-class via `.mcp.json` project-scope | ✅ First-class via `.codex/mcp.toml` | **Out-of-scope.** Not deployed by F-040 |
| **Per-subagent model override** | ✅ `agentModelOverrides` in `.squad/config.json` | ✅ `model:` in subagent frontmatter | ✅ `model = "..."` in agent .toml | Proposal 068 / F-041 — per-host `selector_strategy` enum |
| **Project memory** | ⚠️ None native | ✅ `CLAUDE.md` at project root | ✅ `AGENTS.md` at project root | **Out-of-scope.** Future Proposal 024 Slice 3 candidate |
| **Working-directory flag** | `--add-dir <path>` | **`--add-dir <path>` (SAME NAME!)** | `--cd <path>` (in `codex exec`) | FR-003/FR-004; per-host invocation builders |
| **Permission bypass** | `--allow-all` | `--dangerously-skip-permissions` | `--full-auto` / `--yolo` | FR-008 flag-translation |
| **Remote control** | `--remote` | `--remote-control` / `--rc` | None | FR-007 flag-translation with Codex warn-and-continue |
| **Bootstrap prompt input** | `-i <prompt>` | `-p <prompt>` (or `--bare -p` hermetic) | `codex exec <prompt>` | FR-003/FR-004; per-host invocation builders |
| **Coordinator persona** | "Squad" via `--agent Squad` | Implicit via `.claude/agents/*.md` deployment + per-launch prompt | Implicit via `.codex/agents/*.toml` + per-launch prompt | **Universal header (FR-011)**: "You are the Crew team coordinator running inside a Specrew-bootstrapped repository." |

### Sources

- Copilot CLI: <https://docs.github.com/en/copilot/how-tos/copilot-cli>; existing `scripts\specrew-start.ps1` baseline
- Claude Code: <https://code.claude.com/docs/en/cli-reference>, <https://code.claude.com/docs/en/hooks>, <https://code.claude.com/docs/en/subagents>, [agentskills.io](https://agentskills.io); 2026-05-23 research agent
- Codex CLI: <https://developers.openai.com/codex/cli>; AGENTS.md convention; 2026-05-23 research agent

### Key findings affecting F-040 scope

1. **Universal header is correct**: per the INDEX.md 2026-05-21 terminology note, "the Crew" is the team role; "Squad" is the npm runtime product. The coordinator persona is the same role regardless of host runtime. Single header line `"You are the Crew team coordinator running inside a Specrew-bootstrapped repository."` works for all three hosts. The Squad-specific runtime paths (rules 12, 35, 37, 42-44) are a separate concern and get stripped only for non-Squad hosts (FR-012).

2. **Codex's no-slash-command limitation is real**: F-021 deploys skill files to `.agents/skills/` (which is also Antigravity's native directory by coincidence), but Codex itself doesn't expose user-defined slash commands. The skill files sit there for future-proof but aren't invokable. FR-013 surfaces this honestly to users running `--host codex`.

3. **Claude's hooks are a major upgrade opportunity for F-039**: F-039's launch-mode boundary enforcement is implemented as Specrew-authored slash-command-layer gates (skill-side). Claude's `PreToolUse` hook could enforce the same boundaries at the host's tool-call layer — mechanically more robust because the host runtime itself refuses the call, not the agent's prose interpretation. This is queued as a future-proposal candidate (likely a new proposal addressing host-native hook deployment, or a Proposal 024 Slice 3 sub-component). Specifically: when F-040 + Proposal 068 + Proposal 070 ship and a non-trivial percentage of work runs on Claude, the case for porting F-039 enforcement to hooks becomes concrete.

4. **MCP wiring + project memory + subagents are all out-of-scope for F-040**: each is a real divergence per-host but none blocks the launch-path MVP. They become important when downstream projects start using non-Copilot hosts at scale — coupled with Proposal 024 Slice 3 (per-host Crew runtime install).

---

## Cross-references

- file:///C:/Dev/Specrew/proposals/069-multi-host-launch-path.md (source proposal, enriched 2026-05-23)
- file:///C:/Dev/Specrew/proposals/024-multi-host-runtime-abstraction.md (Abstraction Surface Inventory section — full Category A/B/C/D taxonomy)
- file:///C:/Dev/Specrew/proposals/104-multi-host-onboarding-and-selection-flow.md (UX layer that builds on F-040)
- file:///C:/Dev/Specrew/proposals/068-cost-aware-model-routing.md (per-host selector_strategy enum)
- file:///C:/Dev/Specrew/specs/039-launch-mode-boundary-enforcement/spec.md (F-039 boundary enforcement; F-040 honors)
- Memory: `[[project-overnight-session-2026-05-22]]` — adjacent feature shipping cadence
- Memory: `[[project-design-session-2026-05-22]]` — research session establishing recommend-don't-enroll pattern
