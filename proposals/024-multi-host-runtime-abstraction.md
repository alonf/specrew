---
proposal: 024
title: Multi-Host Runtime Abstraction (Serial — Scenario A)
status: candidate
phase: phase-4-or-5
estimated-sp: 65
discussion: candidate captured 2026-05-12; rescoped 2026-05-15; enriched 2026-05-23 with Abstraction Surface Inventory from internal coupling audit
---

# Multi-Host Runtime Abstraction (Serial)

## Why

Specrew today runs on GitHub Copilot CLI as the primary host. Squad is the orchestration runtime that drives the lifecycle. The methodology itself is theoretically host-neutral — the governance, lifecycle boundaries, validator rules don't depend on which AI host executes them.

But the implementation is currently coupled to Copilot CLI's agent definitions and Squad's specific orchestration patterns. This coupling has two real costs:

1. **Throttling vulnerability**: continuous Specrew development on a single host (Copilot) can trigger that host's rate limits, blocking work
2. **Team-adoption blocker**: real development teams have heterogeneous AI tool preferences — some devs use Copilot, others Claude Code, others Codex, others local models. Standardizing a team on ONE AI host is unrealistic. Without host heterogeneity, team adoption is structurally limited.

This proposal abstracts the host-runtime layer so Specrew becomes a methodology that **any** AI host can implement, AND each developer on a team can use their preferred host while Specrew's governance + multi-developer reconciliation handle coordination.

## What

A host-neutral governance layer above multiple AI runtimes:

1. **Canonical state** at `.specrew/*` — host-neutral truth surface (decisions, config, governance, validator rules)
2. **Provider projection** — each AI host (Copilot, Claude Code, Codex, CAO, etc.) projects the canonical state into its own format
3. **Per-host adapter layer** — host-specific files (`.github/agents/`, `.claude/agents/`, etc.) are generated from canonical state, not hand-edited
4. **Pragmatic first non-Squad provider**: CAO (Claude's agent orchestrator) as proof-of-concept — demonstrates the abstraction works

## Effort

- **Core (M0-M2)**: ~65 SP
- **Full (M0-M5 with all major hosts)**: ~125 SP

Phased delivery:

- M0: canonical state + Copilot projection (existing as baseline)
- M1: CAO projection (first non-Squad provider)
- M2: validator + governance host-neutrality
- M3-M5: additional providers (Codex, custom)

## Phase placement

**Phase 4 OR early Phase 5 — prerequisite for genuine team adoption.**

Previous framing was Phase 6 "conditional on non-Copilot demand." Re-framing 2026-05-15: real dev teams have heterogeneous AI tool preferences. Team adoption (Phase 5's stated goal in the consolidated plan) requires Multi-Host Runtime as a prerequisite, NOT a conditional follow-up. The "non-Copilot demand" trigger fires the moment Specrew has team users.

Sequencing implication: Multi-Host Serial ships BEFORE Multi-Developer Reconciliation, because the canonical-state abstraction in `.specrew/*` is the foundation that Multi-Developer Reconciliation builds on.

## Scenario A vs Scenario B

This proposal covers **Scenario A** specifically: serial, switchable single-active host. One host runs at a time; switch hosts when needed (e.g., when Copilot throttles, switch to Claude Code). Canonical state in `.specrew/*` enables seamless resume on the new host.

**Scenario B** (concurrent multi-host — one developer driving 3 hosts on 3 features simultaneously) is a separate, more ambitious capability that combines Multi-Host + Multi-Developer Reconciliation + concurrent-orchestration UI. ~150-200 SP combined effort. Deferred to a separate future feature ("Concurrent Multi-Host Orchestration"). Captured for future analysis; NOT in scope for this proposal.

For team adoption, Scenario A is sufficient. Each developer uses their preferred host; coordination happens at PR boundary via Multi-Developer Reconciliation.

## Open questions

1. Canonical state schema — how host-neutral can it be?
2. Provider projection — code-generated or schema-driven?
3. Per-host capability differences — how to handle (e.g., Codex doesn't have skills)?
4. Adapter testing — how to validate projections across hosts?
5. Demand signal — what triggers the M0-M2 build?

## Risks

- **Premature abstraction**: building for hosts no one uses. Mitigation: defer until non-Copilot demand exists.
- **Lowest-common-denominator design**: forcing all hosts into a uniform shape loses host-specific power. Mitigation: canonical state is INTENT; host-specific features can extend per-host.
- **Maintenance burden**: every host adapter must keep up with methodology evolution. Mitigation: schema-driven projections minimize per-host code.

## Cross-references

- Composes with: Proposal 010 (Multi-Developer Reconciliation) — this proposal is now framed as a Phase 5 prerequisite; team-adoption scenario depends on both
- Composes with: Proposal 026 (Refactor Track) — R5 coordinator-prompt modularization composes with this work
- Future complement: Concurrent Multi-Host Orchestration (Scenario B) — not yet a proposal; queued for analysis after Scenario A ships

## Status history

- 2026-05-12: candidate captured during host-coupling discussion
- 2026-05-13: Phase 6 placement (conditional on non-Copilot demand)
- 2026-05-15: re-framing after empirical Copilot-throttling experience + team-adoption analysis. Phase placement promoted from Phase 6 conditional to Phase 4-or-5 prerequisite. Scenario A (serial) vs Scenario B (concurrent) distinction made explicit; Scenario B split to separate future-feature candidate. Further analysis pending before spec drafting.
- 2026-05-23: enriched with internal Specrew↔Squad coupling audit (see Abstraction Surface Inventory below) + cross-host research findings (Claude Code, Codex CLI, Antigravity). The audit identified that **Specrew does not use Squad lifecycle hooks** — all boundary enforcement is on-disk state + slash commands — so any host that can run PowerShell + respond to slash-command-shaped instructions can be substituted. This finding plus Proposal 104's 4-slice ladder (Slice 0 = Proposal 069 single-line dispatch → Slice 1 = onboarding flow + Category A relocation → Slice 2 = Category D directive surgery → Slice 3 = this proposal in full) makes 024 a graduated path rather than a single cliff.

---

## Abstraction Surface Inventory (2026-05-23 coupling audit)

The 2026-05-23 internal audit of every Specrew↔Squad touch point yielded a four-category taxonomy. This section is the empirical ground truth for what 024 must abstract.

### Category A — Squad-installed content (Specrew-owned templates under `.squad/`)

Specrew writes these into `.squad/` during init/update. **Specrew-owned methodology surfaces** — moving them to `.specrew/` is a clean relocate (covered by Proposal 104 Slice 1):

- `extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md` — the persisted coordinator instructions block
- `extensions/specrew-speckit/squad-templates/agents/{planner,implementer,reviewer,spec-steward,retro-facilitator}/charter.md`
- `extensions/specrew-speckit/squad-templates/ceremonies/{planning,review-demo,retro}.md`
- `extensions/specrew-speckit/squad-templates/directives/{spec-authority,traceability,drift-reporting}.md`
- `extensions/specrew-speckit/squad-templates/skills/{capacity-planning,drift-check,traceability-check,iteration-resume}.md`
- `extensions/specrew-speckit/squad-templates/skills/specrew-{where,status,team,review,help,version,update}/SKILL.md`
- `templates/squad/agents/{worf,troi,picard,laforge,data,scribe,spec-steward}/history.md` and `templates/squad/identity/now.md`
- `templates/github/agents/squad.agent.md` — the Squad CLI coordinator template

Deployer: `extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1` (whole file is Category A — copies templates into `.squad/agents/<role>/charter.md`, `.squad/ceremonies.md`, `.squad/team.md`, `.squad/routing.md`, `.squad/casting/registry.json`, and overlays the coordinator-governance managed block into `.github/agents/squad.agent.md`).

Fallback scaffold: `scripts/specrew-init.ps1:1275-1407` (`Initialize-SquadFallbackScaffold`) — **canonical inventory of what Category B state actually needs to exist** when Squad CLI is unavailable.

### Category B — Squad-runtime state (Squad writes; Specrew reads for observability)

Squad-owned during execution; Specrew reads for dashboards, validation, and resume. **Stays at host-native paths** (per Proposal 104 Decision Matrix row 5):

- `.squad/identity/now.md` — read at `scripts/internal/sync-boundary-state.ps1:21`, `validate-governance.ps1:744-745`, `scripts/specrew-start.ps1:1486`
- `.squad/identity/wisdom.md` — read at `shared-governance.ps1:648,1802`
- `.squad/decisions.md` — read at `sync-boundary-state.ps1:22`, `shared-governance.ps1:256,3384`, `validate-governance.ps1:417-430,1373`, `scripts/specrew-start.ps1:2977` (ledger_path in start-context.json)
- `.squad/team.md` — parsed at `validate-governance.ps1:1638-1694`, `specrew-team.ps1:120`, `specrew-start.ps1:980,1314`
- `.squad/config.json` — `Get-SquadConfigPath`/`Get-SquadConfig`/`Set-SquadModelOverrides` at `specrew-start.ps1:2356-2412`. **Most structurally Squad-specific feature in the codebase** — `agentModelOverrides` honored by Squad for per-agent model routing. Other hosts have host-specific equivalents per Proposal 068's `selector_strategy` enum.

### Category C — Squad-CLI invocations (Specrew shells out)

**The launch line — single most coupled point in the codebase**:

```text
scripts/specrew-start.ps1:3131
'copilot --agent ''{0}''{1} --add-dir ''{2}'' -i ''{3}''{4}'
```

Surrounding plumbing: `specrew-start.ps1:13` (canonical `'Squad'` default), `:3163` (host-existence probe), `:3169-3178` (arg assembly), `:3181-3243` (Windows `Start-Process pwsh` vs Linux deferred-launch via `SPECREW_DEFERRED_LAUNCH_FILE`).

**Squad CLI invocations (init/update)**: `specrew-init.ps1:1067-1103` (probe `squad init --non-interactive`), `:2251-2275` (run squad init or fall back to scaffold), `:931-932` (`npm install -g @bradygaster/squad-cli@<version>`), `specrew-update.ps1:520-527, :466`.

**Spec Kit invocation is also host-flagged**: `specrew-init.ps1:2205,2209` — `specify init --here --ai copilot --script ps --ignore-agent-tools`. The `--ai copilot` is Spec Kit's equivalent of `--agent Squad`: hard-coded to one host, but Spec Kit itself accepts `claude`/`codex`/etc.

**CI workflows (audit-critical)**: `.github/workflows/specrew-ci.yml:188-189, 263-264` (`npm install -g "@bradygaster/squad-cli@${SQUAD_VERSION}"`), `specrew-confidence-lane.yml:31-43`, `squad-heartbeat.yml`.

### Category D — Coordinator-governance prompt content (deepest abstraction surface)

**Two distinct surfaces**:

- **D1 (session-time prompt)** — `scripts/specrew-start.ps1:2612-2686` (`Get-CoordinatorPrompt`), opens with `"You are Squad running inside a Specrew-bootstrapped repository."`, 45 numbered directives. Written to `.specrew/last-start-prompt.md`. The `-i` flag tells the host to **read** the file — handshake is host-agnostic; **body is host-coupled**.
- **D2 (persisted coordinator instructions)** — `extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md`, overlaid into `.github/agents/squad.agent.md` as the `specrew-governance` managed block.

**Squad-specific directives inside the 45-rule prompt** (need rewriting per host, not just relocating):

- Rules **35, 37, 42-44** — name `.squad/decisions.md`, `.squad/config.json`, `agentModelOverrides`, `sync-squad-model-overrides.ps1`
- Rule **12** — `.squad\decisions.md` skip rationale
- Phrasing throughout — "Squad team setup", "Squad coordination", "Squad-driven work"
- `speckit.*` agent/command names (rules 7-9, 16-21, 27-30) — Spec Kit's slash commands, installed by `specify init --ai copilot`. Other hosts get them installed differently (Claude Code: `/speckit.*` skills; Codex: TBD).

**Methodology directives that are already host-agnostic** (rules 1-11, 13-16, 19-34, 38-41) — lifecycle ordering, intake discipline, quality bar, artifact contract, drift discipline, no-gap policy. These survive any host swap.

### Lifecycle-hook audit (load-bearing finding)

**Specrew does not use Squad-provided lifecycle hooks.** All boundary enforcement is **Specrew-authored, host-agnostic, on disk**:

- `scripts/internal/sync-boundary-state.ps1` (`Invoke-SpecrewBoundaryStateSync`) writes canonical boundary state
- Closeout sync slash commands (`/speckit.specrew-speckit.sync-{review-signoff,retro,iteration-closeout,feature-closeout}`) wrap that function
- The host (Squad/Copilot) is just an executor of slash commands — it does not push hook events back to Specrew

**This is the single biggest abstraction enabler**: Specrew governs lifecycle via on-disk state + slash commands, not via host APIs. Any host that can run PowerShell scripts and respond to slash-command-shaped instructions can be substituted in.

Claude Code's hooks system (PreToolUse / PostToolUse / SubagentStart / Stop / TaskCreated / TaskCompleted) and Antigravity's hooks system are **upgrade opportunities**, not requirements — Specrew's portable contract works without them; they would enable richer real-time governance once 024 ships.

### Existing host-detection logic (already partly host-aware)

- `scripts/specrew-init.ps1:2181-2199` — `Get-AgentDetection` + `Resolve-AgentSelection` already enumerate Copilot + delegated agents (claude/codex). Used by `--agents` flag.
- `scripts/specrew-init.ps1:1023-1255` — agent catalog (copilot, claude, codex), `Get-PreferredEnabledAgent`, `effectiveAgent` routing — currently scoped to **delegated agents** (which agent provides Junior/Senior work), not host selection.
- `extensions/specrew-speckit/scripts/shared-governance.ps1:374-385` (`Get-ActiveSkillRoots`) — **the multi-host pattern that already works**: enumerates `.claude/skills/`, `.github/skills/`, `.agents/skills/` and deploys all SKILL.md files to every active host root.

The delegated-agent catalog and `Get-ActiveSkillRoots` together prove the abstraction is mechanically achievable; the missing piece is a **launch-host** dimension (which CLI binary to invoke), distinct from the **delegated-agent** dimension.

### Bootstrap-context portability audit

- **Handshake (`-i` content)**: `Get-CopilotBootstrapInput` produces `"Read .specrew/last-start-prompt.md and .specrew/start-context.json from the project root before doing anything else."` **Replayable verbatim to Claude/Codex/Antigravity.** Already host-portable.
- **Body (`last-start-prompt.md`)**: contains Squad-specific directives and `speckit.*` references — **host-coupled (Category D)**.
- **State (`start-context.json`)**: includes `agent: 'Squad'`, `delegated_routing_evidence.ledger_path: '.squad\decisions.md'`, `squad_model_overrides` — **host-coupled**.

Key architectural insight: **launch handshake is portable; prompt body and state document are not.**

### Required abstraction helpers (the 024 API)

Derived from concrete touch points above:

| Helper | Replaces | Coupled call sites |
|---|---|---|
| `Get-SpecrewHostKind` (`copilot`/`claude`/`codex`/`antigravity`/`auto`) | hardcoded `'Squad'` default + `copilot` binary probe | `specrew-start.ps1:13, 3163` |
| `Get-SpecrewHostLaunchInvocation -Host <kind>` | literal `copilot --agent Squad ... -i ...` | `specrew-start.ps1:3131, 3169-3178, 3181-3243` |
| `Get-SpecrewCoordinatorInstructionsPath -Host` | `.github/agents/squad.agent.md` literal | `deploy-squad-runtime.ps1:496-558`, `specrew-init.ps1:813, 2016, 2028` |
| `Get-SpecrewIdentityNowPath` / `Get-SpecrewDecisionsLedgerPath` / `Get-SpecrewTeamRosterPath` / `Get-SpecrewAgentCharterPath -Role` | `.squad/identity/now.md`, `.squad/decisions.md`, `.squad/team.md`, `.squad/agents/<role>/charter.md` literals | `sync-boundary-state.ps1:21-23`, `validate-governance.ps1:744,1638`, `shared-governance.ps1:256,648`, `specrew-start.ps1:1486-1487, 2479-2481, 2651, 2676, 3260-3261`, `specrew-team.ps1:120-176, 433` |
| `Set-SpecrewModelOverrides -Host` / `Get-SpecrewModelOverridesPath -Host` | `.squad/config.json` + `agentModelOverrides` plumbing | `specrew-start.ps1:2356-2412, 3417, 3464`, `sync-squad-model-overrides.ps1` (whole file). Dispatches on Proposal 068's `selector_strategy` enum. |
| `Get-SpecrewCoordinatorPrompt -Host <kind>` (strips/remaps host-mechanics directives 12, 35, 37, 42-44 + `speckit.*` references for non-Squad hosts) | `Get-CoordinatorPrompt` opening line + 45 numbered directives | `specrew-start.ps1:2612-2686` (entire function) |
| `Install-SpecrewHostRuntime -Host <kind>` (CLI install + version validation per host) | `npm install -g @bradygaster/squad-cli@...` + `Test-SquadInitSupportsNonInteractive` | `specrew-init.ps1:926-932, 1067-1103, 2250-2275`, `specrew-update.ps1:520-527, 466`, all three `.github/workflows/*.yml` |
| `Initialize-SpecrewCoordinatorState -Host <kind>` (creates per-host minimal state surface) | `Initialize-SquadFallbackScaffold` | `specrew-init.ps1:1275-1407` |
| `Get-SpecKitHostFlag -Host <kind>` | hardcoded `specify init --ai copilot` | `specrew-init.ps1:2205, 2209` |

**Smallest viable first slice (matches Proposal 069's MVP scope)**: introduce `Get-SpecrewHostKind` + `Get-SpecrewHostLaunchInvocation` and rewrite the single literal line `scripts/specrew-start.ps1:3131` to dispatch on host. Categories A and B continue to write under `.squad/` for Squad runs; a parallel `.specrew/coordinator/` is added for Claude/Codex/Antigravity runs (Proposal 104). Category D's directive surgery (rules 12, 35, 37, 42-44 + `speckit.*` references) is the second slice.

### 4-slice ladder (interaction with Proposals 069 + 104 + this proposal)

| Slice | Owner proposal | Scope | SP |
|---|---|---|---|
| **Slice 0** | 069 | Single-line dispatch at `specrew-start.ps1:3131` + per-host launch invocations + per-host smoke verification + `--remote` translation | 10-12 |
| **Slice 1** | 104 | Onboarding + selection UX (`host-history.yml`, first-run probe, `specrew host` command) + Category A relocation to `.specrew/coordinator/` | 8-12 |
| **Slice 2** | 024 (partial) | Coordinator-prompt directive surgery (rules 12, 35, 37, 42-44 + `speckit.*` per-host variants) + per-host coordinator-instructions file generation | 15-20 |
| **Slice 3** | 024 (full) | All 9 abstraction helpers above + host-neutral protocol + per-host Crew-runtime install for non-Copilot hosts + concurrent-execution foundations (Scenario B groundwork) | 30-40 |

Slices 0-2 ship serially. Slice 3 is the architectural endgame (~30-40 SP residual after Slices 0-2 absorb the easier work). **Full 024 effort of 65 SP redistributes**: ~10-12 SP to Slice 0 (069), ~8-12 SP to Slice 1 (104), ~15-20 SP to Slice 2, ~30-40 SP to Slice 3. Total combined effort unchanged; ship cadence becomes 4 small slices instead of one cliff.

### Cross-host research summary (2026-05-23)

The 2026-05-23 research wave (parallel agent investigation across Claude Code, Codex CLI, Antigravity CLI) found:

- **Claude Code** has the richest native primitives: subagents (`.claude/agents/*.md` with YAML frontmatter), hooks at every lifecycle event (PreToolUse/PostToolUse/etc.), MCP first-class, `opusplan` built-in cost-routing primitive, agent teams (experimental). Closest native peer to Squad's team concept.
- **Codex CLI** has solid subagent system (`.codex/agents/*.toml`), AGENTS.md memory, MCP, session resume, but **no user-defined slash-command surface**. Limits skill-portability.
- **Antigravity CLI** has CLI bootstrap (`agy -p`) closest to Copilot's `copilot -i`. Skills land at `.agents/skills/` — **Specrew's existing F-024 multi-host deploys are already Antigravity-compatible by accident**. MCP first-class. Critical date: **Gemini CLI free tier ends 2026-06-18** — affects pricing for Antigravity-host users.
- **No host has a native append-only governance audit log** equivalent to Squad's `decisions.md`. Specrew owns this surface regardless of host.
- **No host has a native lifecycle-boundary contract** equivalent to Specrew's 9 canonical boundaries. Specrew owns this regardless of host.

These findings are absorbed into Proposals 069 (per-host launch surfaces), 068 (per-host model-selection mechanisms), 070 (per-host token-reporting surfaces), and 104 (onboarding + state-location decision matrix).
