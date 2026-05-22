# Feature Specification: Multi-Host Launch Path

**Feature Branch**: `040-multi-host-launch-path`
**Created**: 2026-05-23
**Status**: Draft
**Input**: User description: "Cost-reduction first stage — let `specrew start --host claude|codex|copilot|antigravity` launch the appropriate CLI runtime with Specrew's bootstrap context. Tactical MVP slice of Proposal 024 (Multi-Host Runtime Abstraction). Composes with Proposal 068 (cost-aware routing) and Proposal 070 (token economy) to multiply usable budget by alternating across hosts."
**Source proposal**: file:///C:/Dev/Specrew/proposals/069-multi-host-launch-path.md
**Composes with**: Proposal 068 (cost routing), Proposal 070 (token economy), Proposal 104 (onboarding flow), Proposal 024 (architectural endgame)

## Clarifications

### Session 2026-05-23

- Q: Antigravity host scope — ship in F-040 or defer to a follow-up slice? → A: **Defer to follow-up slice.** F-040 ships copilot/claude/codex only. Antigravity's working-directory flag is undocumented; remote-control surface unverified; 2026-06-18 Gemini free-tier deadline adds risk. Antigravity stays in Proposal 069's scope but ships as a separate small-fix slice after F-040 proves the dispatch pattern.
- Q: `--host auto` behavior — simple loop in F-040 or defer to Proposal 104? → A: **Defer to Proposal 104.** F-040 supports explicit `--host copilot|claude|codex`. No `--host` flag means current Copilot default. First-run probe + last-host history is a UX concern owned by Proposal 104 (F-043).
- Q: Per-host skill verification — fatal, warning, or silent? → A: **Non-fatal warning.** Log a warning naming each missing skill but launch the host anyway. Matches current Copilot behavior; user recovers via `specrew init` re-run.
- Q: Coordinator prompt on non-Squad hosts — leave as-is or minimal directive surgery? → A: **Minimal surgery in F-040.** Add per-host prompt-header swap (`You are <Crew Name>...`) and strip the most Squad-specific lines (rules 12, 35, 37, 42-44) for non-Squad hosts. Cleaner external-tester UX. Scope-bump from ~10-12 SP to ~12-15 SP. Proposal 024 Slice 2 still owns the full directive-surgery work; F-040's surgery is a targeted subset.

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Manual host alternation for cost management (Priority: P1)

A Specrew maintainer or external developer holding both Claude Max ($200/mo) and Copilot CLI quota wants to alternate hosts within a project's lifecycle to multiply effective budget. Today `specrew start` always launches `copilot --agent Squad`. After this feature, `specrew start --host claude` launches Claude Code with Specrew's bootstrap context (and a per-host coordinator-prompt surgery applied per FR-011), and `specrew start --host copilot` preserves current behavior verbatim.

**Why this priority**: The cost-reduction strategy depends on alternation. Without per-host launch, the user has no way to shift work onto a host whose budget still has room. This is the unlocking feature for the entire multi-host cost stack (068, 070, 104).

**Independent Test**: Run `specrew start --host claude "Build hello world"` in a fresh project. Verify Claude Code CLI launches (not Copilot CLI), receives Specrew's bootstrap handshake ("Read `.specrew/last-start-prompt.md` and `.specrew/start-context.json` from the project root"), and begins the lifecycle. Verify `specrew start --host copilot` continues to work identically to current behavior.

**Acceptance Scenarios**:

1. **Given** Claude Code CLI is installed on PATH, **When** the user runs `specrew start --host claude "<task>"`, **Then** Specrew invokes `claude -p '<bootstrap-prompt>' --add-dir '<project>'` and persists the host selection in `.specrew/start-context.json` under `selected_host: claude`
2. **Given** Codex CLI is installed on PATH, **When** the user runs `specrew start --host codex "<task>"`, **Then** Specrew invokes `codex exec --cd '<project>' '<bootstrap-prompt>'` and persists `selected_host: codex`
3. **Given** the user runs `specrew start --host antigravity`, **When** the host validator runs, **Then** Specrew exits with "Antigravity host deferred to follow-up slice; see Proposal 069 follow-up" guidance without attempting a launch
4. **Given** the user runs `specrew start --host auto`, **When** the host validator runs, **Then** Specrew exits with "Auto-selection deferred to Proposal 104; use --host copilot|claude|codex explicitly" guidance
5. **Given** no `--host` flag is specified and `.specrew/start-context.json` has no prior `selected_host` entry, **When** `specrew start` runs, **Then** behavior preserves current Copilot-default (richer first-run UX deferred to Proposal 104)
6. **Given** the requested host is not installed on PATH, **When** `specrew start --host <kind>` runs, **Then** Specrew prints actionable install guidance for that host and exits without launching any CLI

---

### User Story 2 — Per-host permission and remote-control flag translation (Priority: P2)

The user wants `--remote` (mobile/web steering) and `--allow-all`/`--autonomous` (permission relaxation) to work across hosts even though each host uses a different flag name. Specrew translates per-host so the user-facing flag surface stays uniform.

**Why this priority**: Without flag translation, users have to memorize per-host flag names — Copilot's `--allow-all` becomes Claude's `--dangerously-skip-permissions`, Codex's `--full-auto`, etc. Specrew's value as a methodology layer is uniformity above the host-specific surfaces.

**Independent Test**: Run `specrew start --host claude --remote "<task>"` and verify the launch invocation includes Claude's `--remote-control` (translated form), not literal `--remote`. Same exercise for `--host copilot --remote` (literal `--remote`) and `--host codex --remote` (warn-and-continue, no remote wiring).

**Acceptance Scenarios**:

1. **Given** `specrew start --host copilot --remote`, **When** the launch is invoked, **Then** Specrew calls `copilot --remote ...` with Specrew's bootstrap context
2. **Given** `specrew start --host claude --remote`, **When** the launch is invoked, **Then** Specrew calls `claude --remote-control ...` (translated flag form) with Specrew's bootstrap context
3. **Given** `specrew start --host codex --remote`, **When** the launch is invoked, **Then** Specrew emits an actionable warning ("Codex CLI doesn't expose a remote-control flag today") and continues the launch without remote wiring (warn-and-continue, NOT fail)
4. **Given** `specrew start --host claude --autopilot --allow-all`, **When** the launch is invoked, **Then** Specrew translates `--allow-all` to Claude's `--dangerously-skip-permissions` (or equivalent `--permission-mode bypassPermissions`) and `--autopilot` is dropped with an informational notice (Claude doesn't have a direct autopilot equivalent; rely on `--autonomous` for unattended runs which is Specrew's own flag per Proposal 066)

---

### User Story 3 — Per-host skill discoverability verification (Priority: P3)

Specrew already deploys slash-command skills to `.claude/skills/`, `.github/skills/`, `.agents/skills/` per F-021 / Proposal 064. When launching on a specific host, Specrew verifies the host-appropriate skill directory is populated so the user gets actionable feedback if skills are missing.

**Why this priority**: A user launching `--host claude` after init expects `/specrew-where` to work inside the Claude session. If the skill files are missing or malformed, the user discovers the failure only when they try the skill mid-session.

**Independent Test**: Delete `.claude/skills/specrew-where/SKILL.md` from a fresh project, then run `specrew start --host claude`. Verify Specrew logs a warning naming the missing skill before launching the host CLI.

**Acceptance Scenarios**:

1. **Given** `specrew start --host claude`, **When** Specrew checks the skill catalog, **Then** missing or malformed files under `.claude/skills/` trigger a non-fatal warning naming each missing skill
2. **Given** `specrew start --host copilot`, **When** Specrew checks the skill catalog, **Then** the corresponding check runs against `.github/skills/`
3. **Given** `specrew start --host codex`, **When** Specrew checks the skill catalog, **Then** Specrew skips deep skill verification (Codex has no user-defined slash-command surface per 2026-05-23 research) and logs an informational note that `.agents/skills/` is deployed as a future-proof path

---

### Edge Cases

- **Multiple hosts installed, no `--host` flag, no prior selection**: Specrew preserves current Copilot-default behavior in F-040; richer first-run UX is deferred to Proposal 104 / F-043
- **Host CLI installed but missing required version**: Specrew probes the binary on PATH but does not enforce version constraints in F-040 (version-gating deferred to future small-fix slices)
- **User invokes `--host claude` on a project that has never used Claude before**: F-040 launches without a per-Claude Crew runtime; Claude operates with Specrew's bootstrap-context handshake only and the minimally-surgically-rewritten coordinator prompt (FR-011). Subagent files for Claude come with Proposal 024 Slice 3. Document this constraint in `start-context.json`'s `crew_runtime_status: bootstrap_only` field
- **`specrew start --host claude --remote --autonomous`**: All three flags compose; Specrew translates `--remote` → `--remote-control`, keeps `--autonomous` (Specrew's own flag per Proposal 066) routed to lifecycle boundary enforcement, translates `--allow-all` (if also set) to `--dangerously-skip-permissions`
- **User invokes `--host antigravity` or `--host auto`**: Specrew rejects with explicit "deferred to follow-up slice" / "deferred to Proposal 104" guidance and a `gh` link to the relevant proposal
- **Force-quit mid-launch (Ctrl+C between host probe and CLI invocation)**: No special handling in F-040; user re-runs `specrew start` and gets fresh probe + launch
- **Coordinator-prompt surgery on Copilot host**: Skipped entirely. Only non-Copilot hosts get surgery per FR-011 to keep Copilot's existing flow byte-identical

## Functional Requirements

| FR | Statement |
|---|---|
| FR-001 | `specrew start` MUST accept a `-Host <kind>` parameter (with `--host` CLI alias) where `<kind>` ∈ {`copilot`, `claude`, `codex`}. Antigravity is reserved as a known host name but rejected with "deferred to follow-up slice" guidance in F-040. `--host auto` is rejected with "use Proposal 104 / F-043 for auto-selection" guidance |
| FR-002 | When `--host copilot` (or no `--host` flag with no prior selection), Specrew MUST preserve current behavior verbatim |
| FR-003 | When `--host claude`, Specrew MUST invoke `claude -p '<bootstrap-prompt>' --add-dir '<project>'` as the launch base; with `--allow-all`, MUST add `--dangerously-skip-permissions` |
| FR-004 | When `--host codex`, Specrew MUST invoke `codex exec --cd '<project>' '<bootstrap-prompt>'` as the launch base; with `--allow-all`, MUST add `--full-auto` (or `--yolo` per the host-flag table) |
| FR-005 | When the requested host's CLI is NOT on PATH, Specrew MUST print actionable install guidance for that host and exit non-zero without launching any CLI |
| FR-006 | Specrew MUST persist the selected host in `.specrew/start-context.json` under `selected_host` and `available_hosts` fields (the latter populated by PATH probe across copilot/claude/codex) |
| FR-007 | Specrew MUST accept a `-Remote` (or `--remote`) switch and translate per-host: copilot → `--remote`, claude → `--remote-control`, codex → warn-and-continue without remote wiring |
| FR-008 | Specrew MUST accept `--allow-all`, `--autopilot`, `--autonomous` switches and translate per-host: copilot keeps `--allow-all`/`--autopilot` natively; claude maps `--allow-all` → `--dangerously-skip-permissions`; codex maps to `--full-auto`. `--autonomous` (Specrew's own flag per Proposal 066) stays as a Specrew-side concept routed to lifecycle boundary enforcement and is NOT translated per-host |
| FR-009 | Specrew MUST perform per-host skill-discoverability verification before launch and log NON-FATAL warnings if expected skill files are missing or malformed on the active host's skill root; launch proceeds anyway |
| FR-010 | The bootstrap context (`.specrew/last-start-prompt.md` + `.specrew/start-context.json`) MUST remain unchanged in shape across hosts; only the invocation command differs. The bootstrap-context body (`last-start-prompt.md`) MUST be regenerated per-host to apply FR-011's minimal coordinator-prompt surgery |
| FR-011 | When the selected host is NOT copilot, Specrew MUST apply minimal coordinator-prompt surgery to the body of `last-start-prompt.md`: (a) replace the opening line `"You are Squad running inside a Specrew-bootstrapped repository."` with a host-appropriate header (`"You are the Crew running inside a Specrew-bootstrapped repository, hosted by <kind>."`); (b) strip directives that reference `.squad/decisions.md`, `.squad/config.json`, `agentModelOverrides`, `sync-squad-model-overrides.ps1` (rules 12, 35, 37, 42-44 per Proposal 024's Category D taxonomy). Other directives stay verbatim; full per-host directive surgery is Proposal 024 Slice 2 |

## Out of Scope

This feature explicitly does NOT include:

- **First-run host detection + offer-to-choose UX** — Proposal 104. F-040 preserves current Copilot-default when no `--host` flag and no prior selection
- **`.specrew/host-history.yml` persistence + `specrew host` command** — Proposal 104
- **`--host auto` smart selection** — explicit `auto` is rejected with guidance in F-040; reserved for Proposal 104
- **Antigravity host** — explicit `antigravity` is rejected with guidance in F-040; reserved for a Proposal 069 follow-up small-fix slice once `agy` working-directory + session-ID issues clear
- **Full coordinator-prompt directive surgery** (all 45 directives per Proposal 024's Category D taxonomy) — Proposal 024 Slice 2. F-040 only does the minimum surgery (header swap + strip rules 12, 35, 37, 42-44) per FR-011
- **Per-host Crew runtime install for Claude/Codex** (subagent files, `.codex/agents/*.toml`, etc.) — Proposal 024 Slice 3. F-040 launches non-Squad hosts in bootstrap-context-only mode
- **Cost-aware model routing** — Proposal 068 / F-041 (next feature)
- **Token economy + cost.yml dashboard surface** — Proposal 070 / F-042
- **Mid-session host switching** — must end session and restart with different `--host` flag
- **Concurrent multi-host execution** — Scenario B of Proposal 024 (~150-200 SP separate effort)
- **Version-gating per host CLI** — F-040 probes PATH only; no minimum-version enforcement

## Composition

- **069 (this feature's source proposal)** — full design surface; F-040 implements it
- **068 Cost-Aware Model Routing** — depends on F-040's host enum; F-041 builds on this
- **070 Token Economy MVP** — cost.yml's `host:` field comes from F-040's selection logic
- **104 Multi-Host Onboarding + Selection Flow** — owns UX layer; F-043 builds on F-040
- **024 Multi-Host Runtime Abstraction** — architectural endgame; F-040 is its tactical MVP (Slice 0 of the 4-slice ladder)
- **064 Slash-Command Multi-Host Correctness** — prerequisite (already shipped as F-021); deploys skills to `.claude/`, `.github/`, `.agents/` which F-040's Pillar 3 verifies per host
- **066 Gate-Respecting Default + `--autonomous`** — composes with F-040's `--autonomous` translation: copilot's native flag stays as-is; other hosts get the Specrew-flagged equivalent via launch-mode boundary enforcement (F-039)
- **F-039 Launch-Mode Boundary Enforcement (shipped)** — F-040 honors the new boundary-authorization helpers; per-host launch invocations are governed by the same boundary discipline as Copilot launches

## Success Criteria (Outcome-Focused)

- `specrew start --host claude` invokes Claude Code with Specrew's bootstrap context (and the minimally-surgically-rewritten coordinator prompt) and the user can complete a `/speckit.specify` → `/speckit.plan` cycle inside Claude
- `specrew start --host copilot` continues to work byte-identically (no regression)
- `specrew start --host codex` invokes Codex CLI with bootstrap context (limited skill-discoverability per Codex's surface)
- `specrew start --host antigravity` and `--host auto` exit with explicit "deferred" guidance (not unhandled error)
- `.specrew/start-context.json` records both the selected host and the available-hosts probe result
- Per-host flag translation works for `--remote`, `--allow-all`, `--autopilot` per FR-007/FR-008 with no regression on Copilot
- Per-host skill verification logs warnings (not blockers) when expected skills are missing
- Cost-reduction value: user can manually alternate hosts within a project, drawing from multiple budgets in turn

## Risks

- **Empirical verification gaps for non-Copilot hosts**: Claude `--add-dir` flag confirmed; Codex `--cd` confirmed. Antigravity deferred entirely per clarify decision. F-040 ships copilot/claude/codex only
- **Coordinator-prompt minimum surgery may miss host-specific terminology**: FR-011 only strips rules 12, 35, 37, 42-44 and rewrites the opening line; other Squad-specific phrasing in the 45 directives (e.g., "Squad team setup", "Squad coordination") remains. Proposal 024 Slice 2 fixes the full surface. F-040's surgery is documented as "minimum viable"
- **Specrew's `--autonomous` flag vs host-native autopilot flags**: subtle: Specrew's `--autonomous` is the Proposal 066 lifecycle-boundary opt-in. Copilot's `--autopilot` is the host's tool-call autopilot. They're independent concerns (per F-039). FR-008 must keep them independent
- **Cross-platform launch parity**: F-040 must work on Windows (`Start-Process pwsh`) AND Linux/macOS (`SPECREW_DEFERRED_LAUNCH_FILE` pattern) for all three hosts. Existing Copilot launch already handles both; per-host launch dispatch must preserve that
