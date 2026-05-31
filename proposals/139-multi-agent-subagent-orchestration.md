---
proposal: 139
title: Multi-Agent Subagent Orchestration (Claude First, Multi-Host Extensible)
status: candidate
phase: phase-2
estimated-sp: 17-28
priority-tier: 1
discussion: surfaced 2026-05-27 during F-049 close + sequencing conversation; user direction explicit ("Support multi-agent at least for Claude — speed up and reduce cost"); empirically motivated by F-049's lifecycle re-runs burning Opus tokens on grep/explore/validator-run work that Haiku subagents could handle 10-15x cheaper + post-compaction discipline drop (Shape 3c) when single-Claude-instance context overflows; this current session itself used Explore + general-purpose subagents repeatedly during F-049 — empirical demonstration of the model Specrew should formalize. **Amended 2026-05-31** to add Claude dynamic workflows (v2.1.154+ / Opus 4.8 era, May 2026) as additional Pillar 1 substrate alongside the Task/Agent tool API — script-orchestrated parallel dispatch (up to 16 concurrent subagents per phase, capped at 1000 per run) with stricter context isolation than conversational subagents.
---

# Multi-Agent Subagent Orchestration

## Why

Specrew today assumes a **single-agent linear session model** for the active host (Claude Code, Codex CLI, Copilot CLI, Antigravity). The agent does ALL the work in one context: substantive reasoning, code editing, file grep, validator runs, dependency research, test execution. This has two real production costs that empirical dogfooding has surfaced:

### Cost 1: Token economics

Single-agent Claude session burns Opus tokens (~$15/MTok input, $75/MTok output) for EVERY task — including tasks that Haiku ($1/MTok input, $5/MTok output) or Sonnet ($3/MTok input, $15/MTok output) could handle equally well. Concrete examples from F-049:

- **Grep / file search** — "find all references to X" — Haiku is functionally equivalent to Opus for this work; ~15× cheaper input + ~15× cheaper output
- **Validator runs** — invoking `validate-governance.ps1` + parsing output — Haiku-tier reasoning sufficient; Opus burns tokens for boilerplate
- **Cross-iteration index scanning** — Proposal 085 closed-iteration index — Haiku reads YAML
- **Dependency research** — npm/nuget metadata fetch + summarization — Sonnet ample; Opus wasteful
- **Mermaid diagram authoring** — template-driven; Sonnet sufficient

F-049 at ~48 SP across 4 iterations + 3 major scope absorptions estimated 6-10× more Opus tokens than necessary if subagent routing was in place. Even at conservative 5× ratio, that's substantial cost on a single feature.

### Cost 2: Context-window pressure → compaction → Shape 3c

Single-agent session accumulates ALL tool output in one context: grep results, file reads, validator output, web fetches, agent reasoning, prior conversation. Context fills; auto-compaction triggers; methodology discipline drops (Shape 3c per `[[shape5-reviewer-approves-working-tree-only-state-2026-05-27]]` family) — Specrew has multiple empirical incidents:

- **F-024 boundary-compaction breach** — Squad emitted "waiting for human approval" handoff; Copilot autopilot continued anyway BEFORE compaction. Memory `[[project_f024_boundary_compaction_breach_2026_05_20]]`
- **F-046 Antigravity 4-gate autopilot bypass** — blew through review-signoff → retro → iteration-closeout → feature-closeout without handoff blocks
- **F-048 Codex branch-push discipline gap** — ~10 boundary commits accumulated locally; branch never pushed despite standing rule

Subagent isolation eliminates this class entirely: grep dumps + validator output land in isolated subagent contexts; main coordinator context stays clean + methodology-focused. The post-compaction discipline-drop window narrows dramatically because compaction triggers less often.

### Empirical demonstration (this session)

The Claude Code session producing Proposals 137, 138, and now 139 USED subagents heavily for the F-049 work:

- `general-purpose` subagent for cross-codebase scoping during F-049 iter-1 + iter-2
- `Explore` subagent for ripgrep-style code searches during F-049 boundary reviews
- WebFetch tool (effectively a subagent) for Spec-Kit + Squad multi-dev research above

That pattern wasn't formalized; it was ad-hoc. Specrew should formalize the discipline so EVERY host adapter supports it AND coordinators KNOW to use subagent dispatch for the work classes that warrant it.

### Strategic context

- **Spec-Kit has no subagent orchestration** (verified via repo audit) — Specrew innovation
- **Squad's `squad triage --execute` runs single-loop** (verified via repo audit) — no concurrent agent execution
- **Claude Code natively supports Task/Agent tool** with subagent_type — first-class subagent surface
- **Codex CLI** has limited subagent surface today; may improve
- **Copilot CLI / Antigravity** have no subagent surface today

This is multi-host adapter territory: build the contract Claude-first; extend to other hosts as their subagent surfaces mature.

## What — Six Pillars

### Pillar 1: Subagent contract per host (~3-5 SP, +0.5-1 SP for dispatch-kind dimension)

Define a `SubagentInvoker` interface in Specrew's runtime abstraction (composes with Proposal 024 Multi-Host Runtime Abstraction CORE):

```powershell
$invoker = Get-SubagentInvoker -ProjectRoot $resolvedProjectRoot
$invoker.Kind                           # 'claude' | 'codex' | 'copilot' | 'antigravity' | 'none'
$invoker.IsActive                       # capability flag
$invoker.SupportsParallelDispatch       # capability flag
$invoker.SupportedSubagentTypes         # array of supported subagent role keys
$invoker.SupportedDispatchKinds         # array — 'task-tool' | 'dynamic-workflow' (Claude only, v2.1.154+) | 'powershell-parallel' (degraded)

# Invocation:
$result = $invoker.InvokeSubagent(@{
    subagentType = 'code-search'       # role key from catalog
    description = 'short description'
    prompt = 'detailed task prompt'
    isolation = 'context'              # 'context' (default) | 'worktree' (when worktree-needed)
    dispatchKind = 'task-tool'         # 'task-tool' (default, conversational) | 'dynamic-workflow' (script-orchestrated parallel, Claude only)
    runInBackground = $false
}) -ErrorAction Stop
```

**Dispatch-kind selection** (substrate choice):

- `task-tool` — Claude Code's Task/Agent tool API. Conversational subagent, single-stream, suitable for one-shot lookups (code-search, dependency-research, single quality analysis). Default for all hosts that have a Task tool.
- `dynamic-workflow` — Claude Code's dynamic workflows (v2.1.154+, Opus 4.8 era, May 2026). Script-orchestrated; dispatches up to 16 concurrent subagents per phase / 1000 per run; intermediate results held in script variables (NOT chat context) — stricter context isolation than `task-tool`. Suitable for parallel fan-out work (per-iteration validator runs, per-flavor design analysis, per-persona intake lenses, per-phase reviewer dispatch). Claude-only; other hosts fall back to `task-tool` or `powershell-parallel`.
- `powershell-parallel` — fallback for hosts without subagent surface; PowerShell `ForEach-Object -Parallel` (Proposal 084 mechanism). No model-level isolation, but enables parallel work without subagent surface.

Per-host adapters in `extensions/specrew-speckit/scripts/host-adapters/`:

- `claude-subagent-adapter.ps1` — wraps BOTH Claude Code's Task/Agent tool API (native subagent surface) AND Claude Code's dynamic-workflows runtime (v2.1.154+). Adapter selects substrate per `dispatchKind` parameter; falls back to `task-tool` when `dynamic-workflow` requested but Claude version < 2.1.154
- `codex-subagent-adapter.ps1` — wraps Codex CLI's available subagent surface (limited today; placeholder + degraded-mode); supports `task-tool` only when Codex matures, `powershell-parallel` fallback meanwhile
- `copilot-subagent-adapter.ps1` — degraded-mode adapter (no native subagent; falls through to single-agent execution + cost-routing only); `powershell-parallel` for fan-out work
- `antigravity-subagent-adapter.ps1` — degraded-mode adapter (no native subagent; falls through); `powershell-parallel` fallback
- `none-adapter.ps1` — fallback when host is unsupported or detection fails

Mirror parity per F-047 FR-014.

### Pillar 2: Specrew-defined subagent catalog (~4-6 SP, +0.5 SP for dispatch-kind defaults)

Catalog of subagent role types in `.specify/subagents/catalog.yml` (data-driven per the engine + data architecture pattern from F-049 iter-3 work). Each role specifies a `preferred_dispatch_kind` that the adapter substrate-switch honors when the active host supports it (Claude `dynamic-workflow` for parallel-dispatch roles; `task-tool` for conversational-fit roles; other hosts fall back per Pillar 1's substrate matrix):

```yaml
schema: "v1"
subagents:
  - key: code-search
    description: "Ripgrep-style code search across project files; returns matching paths + line excerpts"
    preferred_tier: haiku        # cost-aware routing (Pillar 3); haiku for grep-class work
    preferred_dispatch_kind: task-tool   # single conversational stream; not parallel
    isolation: context           # context-isolated subagent (default)
    primary_use_cases:
      - "find all references to X"
      - "locate definitions matching pattern Y"
      - "scan multiple files for terminology Z"

  - key: validator-runner
    description: "Invokes validate-governance.ps1 + parses output + returns structured findings"
    preferred_tier: haiku
    preferred_dispatch_kind: dynamic-workflow   # parallel per-iteration fan-out; script-aggregate
    isolation: context
    parallel_dispatch: true       # multiple validator runs can dispatch in parallel
    primary_use_cases:
      - "validate iteration N at HEAD"
      - "validate feature-level governance"
      - "scope-limited validator for specific path"

  - key: dependency-research
    description: "npm/nuget/PyPI/RubyGems metadata fetch + summarization; license info; alternatives"
    preferred_tier: sonnet
    preferred_dispatch_kind: task-tool   # single-target lookup; conversational fit
    isolation: context
    primary_use_cases:
      - "research dependency X (license, alternatives, last-update, etc.)"
      - "compare dependencies X vs Y for feature decision"
      - "check if dependency has CVE history"

  - key: quality-analyzer
    description: "Spec Kit /speckit.checklist generation; quality-lens evaluation; form-vs-meaning checks"
    preferred_tier: sonnet
    preferred_dispatch_kind: task-tool   # single artifact at a time
    isolation: context
    primary_use_cases:
      - "generate per-feature requirements quality checklist (Proposal 138 Pillar 1)"
      - "evaluate spec.md against quality lens"

  - key: design-alternative-lens
    description: "Per-flavor design analysis lens (simplest/reasonable/by-the-book per Proposal 137)"
    preferred_tier: sonnet
    preferred_dispatch_kind: dynamic-workflow   # 3 flavors fan out in parallel via script orchestration
    isolation: context
    parallel_dispatch: true       # 3 design flavors can analyze in parallel
    primary_use_cases:
      - "produce 'Simplest' flavor analysis for feature X"
      - "produce 'Reasonable' flavor analysis"
      - "produce 'By the book' flavor analysis"

  - key: intake-lens
    description: "Per-persona-lens substantive intake (Product Manager / UX / Architect / AI Researcher per F-049 iter-3)"
    preferred_tier: sonnet
    preferred_dispatch_kind: dynamic-workflow   # 4 personas fan out in parallel via script orchestration
    isolation: context
    parallel_dispatch: true       # 4 persona lenses can run in parallel
    primary_use_cases:
      - "intake from Product Manager lens"
      - "intake from Architect lens"
      - "intake from UX lens"
      - "intake from AI Researcher / Project Manager lens"

  - key: reviewer-agent
    description: "Independent reviewer subagent for review-signoff boundary (composes with Proposal 102 cross-model independent reviewer + Proposal 145 Structured Multi-Phase Reviewer per-phase parallelism)"
    preferred_tier: opus
    preferred_dispatch_kind: dynamic-workflow   # 7-phase Reviewer (Proposal 145) — independent phases (e.g., NFR + code-quality + test-coverage) dispatch in parallel; dependent phases (branch-hygiene → functional-correctness) stay sequential within the workflow script
    isolation: context
    parallel_dispatch: true
    primary_use_cases:
      - "review feature implementation against spec at HEAD H"
      - "verify Pillar 5 file-tree-presence checks"
      - "evaluate review.md evidence integrity"
      - "dispatch Proposal 145 7-phase reviewer with per-phase substrate selection"

  - key: research-explorer
    description: "Open-ended research across web + docs + repo for ambiguous questions"
    preferred_tier: sonnet
    preferred_dispatch_kind: task-tool   # conversational follow-up + drill-down fits one-stream model
    isolation: context
    primary_use_cases:
      - "research best practices for X across multiple sources"
      - "investigate prior art for design decision Y"

  - key: state-truth-auditor
    description: "Cross-artifact state-truth audit (Proposal 142 expansion territory): boundary-state artifacts (start-context.json + now.md + last-start-prompt.md + plan.md + state.md + decisions.md + hardening-gate.md + dashboard.md timing + validator-summary timestamp). Empirically motivated by F-051 Iter-1 closeout 5-cycle Codex cross-review pattern (2026-05-31) where depth-N self-audit consistently missed depth-N+1 issues."
    preferred_tier: sonnet
    preferred_dispatch_kind: dynamic-workflow   # ~8-10 artifact-pair coherence checks dispatch in parallel; script-aggregate findings
    isolation: context
    parallel_dispatch: true
    primary_use_cases:
      - "audit boundary-state coherence across all 8+ load-bearing artifacts at iteration-closeout"
      - "verify frontmatter ↔ body internal consistency per artifact"
      - "cross-check decisions.md iteration_number vs start-context.json iteration_number"
      - "verify dashboard.md render timing vs declared boundary state"
```

Catalog is **data-driven**: adding a new subagent role = adding a YAML row + a prompt template; engine traversal stays stable. Domain-specific extensions in `subagents/extensions/<domain>.yml` (mirroring the engine + data architecture from F-049 iter-3 FR-029).

### Pillar 3: Cost-aware routing (absorbs Proposal 068 minimal slice) (~3-5 SP)

Each subagent role has a `preferred_tier` (haiku | sonnet | opus). Host adapter maps tier to concrete model based on `.specrew/model-catalog.yml` (Proposal 068's mechanism):

```yaml
# .specrew/model-catalog.yml
catalog_version: "1.0"
models:
  - tier: haiku
    claude_model: "claude-haiku-4-5-20251001"
    codex_model: "gpt-4o-mini"
    copilot_model: "gpt-4o-mini"
    cost_per_mtok_input: 1.0
    cost_per_mtok_output: 5.0
  - tier: sonnet
    claude_model: "claude-sonnet-4-6"
    codex_model: "gpt-4o"
    copilot_model: "gpt-4o"
    cost_per_mtok_input: 3.0
    cost_per_mtok_output: 15.0
  - tier: opus
    claude_model: "claude-opus-4-7"
    codex_model: "o1-preview"
    copilot_model: "o1-preview"
    cost_per_mtok_input: 15.0
    cost_per_mtok_output: 75.0
routing:
  default_subagent_tier_override: null    # use catalog defaults
  cost_profile: lean                       # lean | balanced | premium
```

Per `cost_profile`:

- **lean**: aggressively use haiku for any work haiku can handle; sonnet only when explicitly required; opus only for reviewer-agent + complex reasoning
- **balanced** (default): use preferred_tier from catalog
- **premium**: upgrade haiku → sonnet, sonnet → opus across the board

This is the minimal viable cost-routing slice of Proposal 068 — formalizes per-subagent tier selection. Full Proposal 068 (agent-discovered model catalog via `/specrew-research-models` skill) ships as follow-up.

### Pillar 4: Validator + boundary-check parallelization (extends Proposal 084) (~2-4 SP, +1 SP for dynamic-workflow substrate)

Proposal 084 (shipped feature-035) added PowerShell `ForEach-Object -Parallel` to validator iteration. Extend this with subagent dispatch using the Pillar 1 substrate matrix:

- `extensions/specrew-speckit/scripts/validate-governance.ps1` gains optional `-UseSubagents` flag + `-DispatchKind` parameter (`auto` | `task-tool` | `dynamic-workflow` | `powershell-parallel`)
- When `-UseSubagents` set + Claude session active + `dynamic-workflow` substrate available (v2.1.154+): dispatch per-iteration validator runs as a single dynamic workflow that spawns up to 16 concurrent Haiku-tier subagents (one per iteration); results aggregate in script variables and return as a single structured payload — main coordinator context stays clean
- When Claude session active but `dynamic-workflow` unavailable (older Claude Code): fall back to per-iteration Task/Agent tool subagents (`task-tool` substrate); same Haiku tier; intermediate results land in main context (acceptable for small iteration counts)
- When non-Claude host active: fall back to `powershell-parallel` (Proposal 084 mechanism); cost-routing via Pillar 3 still applies for model selection on single-agent invocations
- Boundary-check passes (handoff detection, verdict-history lookup, mirror parity, review evidence integrity) dispatched as parallel subagents via the same substrate-switch logic
- **State-truth audit dispatch** (composes with Proposal 142): the `state-truth-auditor` catalog role (Pillar 2) ships as a `dynamic-workflow` dispatch that fans out 8-10 artifact-pair coherence checks in parallel and aggregates findings — empirically motivated by the F-051 Iter-1 closeout 5-cycle Codex cross-review pattern where depth-N self-audit consistently missed depth-N+1 issues (one round of dynamic-workflow dispatch ≈ all 5 sequential cross-review rounds collapsed)

For Specrew's own dogfooding: F-049 boundary-state validation runs across all 4 iterations + 28 tasks; serial single-agent approach = N×Opus tokens; parallel subagent approach via `dynamic-workflow` = 1×Opus for coordination + N×Haiku for execution + script-aggregate (no per-iteration result pollution in main context).

### Pillar 5: Context-window protection (~1-2 SP)

Each subagent runs in isolated context per Pillar 1's contract. This protects the main coordinator context from:

- Grep result dumps (sometimes 1000+ lines)
- Validator output (boundary-state JSON, severity-ranked findings)
- Web fetch responses (sometimes large HTML/markdown extractions)
- Dependency research summaries
- Per-flavor design-alternative analyses (when Proposal 137 ships)

**Substrate-relative isolation strength** (per Pillar 1 dispatch-kind choice):

- `task-tool` subagents: results return INTO the main conversation as tool output. Better than no isolation (the subagent's intermediate reasoning + tool calls stay in subagent context) but the final payload lands in main context.
- `dynamic-workflow` subagents: results held in JS script variables, NOT in the main chat context. Strict improvement — even the final payload can be filtered/aggregated/summarized via the orchestration script before any text returns to main context. **Net effect: dynamic workflows reduce main-context growth dramatically more than task-tool subagents for parallel-dispatch work.**
- `powershell-parallel` (degraded mode): no model-context isolation; PowerShell variable scope only. Equivalent isolation strength to task-tool for the per-iteration script context.

Reduces compaction trigger frequency → reduces Shape 3c post-compaction discipline drop window → improves methodology adherence durability across long sessions. Composes with Proposal 133 (Specrew primer for compaction recovery) as defense-in-depth. The dynamic-workflow substrate closes the compaction-vulnerability bug class (F-024 / F-046 / F-048 / Shape 3c) more comprehensively than originally planned — main context growth from validator + audit + research subagents drops to near-zero when work runs via dynamic workflows.

### Pillar 6: Multi-host extension (deferred — V2 scope)

V1 ships **Claude-first** because Claude Code has the most mature subagent surface. V2 follow-up extends per-host:

- **Codex CLI**: when Codex CLI exposes formal subagent API (currently limited)
- **Copilot CLI / Antigravity**: when those hosts expose subagent surfaces (none today)
- **Future hosts**: any host added via Proposal 124 (Multi-Host Catalog Expansion) needs SubagentInvoker adapter

Pillar 1's per-host adapter contract is forward-compatible; V2 = filling in real adapters for hosts that gain subagent support. Codex/Copilot/Antigravity ship as degraded-mode adapters in V1 (no parallelization; cost-routing still applies via Pillar 3 for model selection on single-agent invocations).

## How

V1 is single-iteration shippable at ~15-25 SP. Suggested iteration breakdown:

| Iter | Scope | SP |
|---|---|---|
| 1 (V1 — recommended single iter) | Pillars 1+2+3+4+5: Claude subagent invoker (BOTH `task-tool` + `dynamic-workflow` substrates) + catalog with `preferred_dispatch_kind` + cost-routing + validator parallelization with substrate switch + context-window protection; per-host adapters as stubs (Codex/Copilot/Antigravity degraded-mode with `powershell-parallel` fallback) | 17-28 |
| 2 (V2 — separate follow-up feature) | Pillar 6: Codex subagent adapter when surface matures; Aider/Amp adapters per Proposal 124 catalog expansion | (separate feature) |

Splittable within V1 if appetite calls for it:

- **V1a (foundation)**: Pillars 1+2 — adapter contract (both substrates) + catalog with dispatch-kind defaults (~8-12 SP); ships independently as foundation
- **V1b (routing + parallelization)**: Pillars 3+4+5 — cost-routing + validator parallelization via substrate-switch + context isolation (~9-16 SP); depends on V1a

But single-iter is preferred because the pillars compose tightly.

## Acceptance criteria

- **AC1**: `Get-SubagentInvoker` returns the correct `Kind` for active host (claude | codex | copilot | antigravity | none) AND the correct `SupportedDispatchKinds` (Claude with v2.1.154+: `task-tool` + `dynamic-workflow`; older Claude: `task-tool` only; other hosts: `task-tool` if available + `powershell-parallel` fallback)
- **AC2**: Claude adapter invokes Claude Code's Task/Agent tool API (`task-tool` dispatch) AND Claude Code's dynamic-workflows runtime (`dynamic-workflow` dispatch when v2.1.154+) with correct subagent_type mapping per catalog
- **AC3**: Codex/Copilot/Antigravity adapters return degraded-mode (single-agent execution + cost-routing + `powershell-parallel` fallback for fan-out) without errors
- **AC4**: Catalog at `.specify/subagents/catalog.yml` loaded + validated; adding new subagent role = YAML row addition (data-only, no script change); `preferred_dispatch_kind` field honored by adapter substrate-switch when host supports it
- **AC5**: Cost-aware routing per `.specrew/model-catalog.yml` correctly maps subagent tier → concrete model per host; `cost_profile` (lean | balanced | premium) honored
- **AC6**: `validate-governance.ps1 -UseSubagents -DispatchKind auto` dispatches per-iteration validator runs via the optimal substrate (dynamic-workflow on Claude v2.1.154+; task-tool on older Claude; powershell-parallel on other hosts); aggregates results correctly across substrates
- **AC7**: Empirical token-cost measurement: F-049-equivalent feature using subagents shows ≥5× reduction in Opus token consumption vs single-agent baseline; record evidence in `tests/integration/subagent-cost-measurement.tests.ps1`
- **AC8**: Context-window-size measurement: long-session simulation (50+ tool calls including grep + validator + research) with subagent dispatch shows ≥3× reduction in main coordinator context growth vs single-agent baseline; **AC8-extended**: dynamic-workflow dispatch shows additional ≥2× reduction over task-tool dispatch for parallel-fan-out work (Claude v2.1.154+ only)
- **AC9**: Per-host adapter implementations mirror parity preserved (`extensions/specrew-speckit/scripts/host-adapters/` ↔ `.specify/extensions/...`)
- **AC10**: Integration tests cover subagent invocation + parallel dispatch (both substrates) + cost-routing + catalog loading + degraded-mode fallback for non-Claude hosts + Claude-version detection for dynamic-workflow availability
- **AC11**: Documentation: `docs/user-guide.md` (or new `docs/multi-agent.md`) explains subagent model + substrate selection + when to use which dispatch kind + cost implications + Claude-version requirements

## Out of scope (V1)

- **Codex CLI native subagent support** — wait until Codex matures its subagent surface; V2 follow-up
- **Copilot CLI / Antigravity native subagent support** — neither has surface today; V2+ when available
- **Full Proposal 068 implementation** — V1 absorbs the minimal cost-routing slice; agent-discovered model catalog via `/specrew-research-models` skill remains Proposal 068's separate scope
- **Cross-model independent reviewer** — Proposal 102 territory; composes but separate
- **Subagent-to-subagent messaging** — V1 supports coordinator → subagent only; subagent-to-subagent coordination is V2+ scope
- **Persistent subagent sessions** — V1 subagents are ephemeral (per-task); long-running specialist subagents are V2+ scope
- **Per-developer subagent customization** — V1 catalog is project-level; per-developer overrides compose with `~/.specrew/user-profile.yml` (F-049 iter-3 work) in V2+

## Composition

| Proposal | Relationship |
|---|---|
| **Proposal 024 (Multi-Host Runtime Abstraction CORE)** | Direct foundation — Pillar 1's `SubagentInvoker` interface composes with 024's per-host runtime abstraction |
| **Proposal 068 (Cost-Aware Model Routing)** | Direct absorption — Pillar 3 ships the minimal viable slice of 068's cost-routing model; full 068 (agent-discovered model catalog) remains separate scope |
| **Proposal 023 (Reactive Specialist Lifecycle)** | Adjacent — 023 is about specialist agent activation during lifecycle; this proposal is about parallel subagent dispatch within a single host. 023 + 139 = full specialist orchestration story |
| **Proposal 084 (Validator Iteration Parallelization — shipped)** | Direct extension — Pillar 4 extends 084's PowerShell `-Parallel` mechanism with subagent dispatch |
| **Proposal 086 P1 (Memoization — shipped)** | Direct composer — subagent results can be memoized per 086 P1; reduces redundant subagent invocations |
| **Proposal 105 (Host-Native Hook Deployment)** | Direct composer — host-adapter pattern shared between 105 (hooks) and 139 (subagents); same Multi-Host Adapter Registry |
| **Proposal 124 (Multi-Host Catalog Expansion Tier 1)** | Composes — new hosts (Aider, Amp, OpenCode, Cursor) added per 124 need SubagentInvoker adapter alongside hook + launch adapters |
| **Proposal 137 (Design Alternatives Analysis Gate)** | Direct composer — each design-alternative-lens subagent (Pillar 2 catalog `design-alternative-lens` role) lets 137's 3 flavors analyze in parallel; reduces design-analysis boundary latency |
| **Proposal 138 (Spec Kit Underutilized Surfaces)** | Direct composer — `/speckit.checklist` + `/speckit.analyze` are ideal subagent candidates (both read-only; Sonnet-tier; quality-analyzer role from Pillar 2 catalog) |
| **Proposal 102 (Cross-Model Independent Reviewer)** | Adjacent — reviewer-agent subagent role (Pillar 2 catalog) provides part of 102's mechanism; 102's cross-model verification is a richer V2 follow-up |
| **F-049 iter-3 engine + data architecture (FR-028..FR-031)** | Pattern match — same engine + data philosophy: subagent catalog as YAML data; per-domain extensions as data-only additions; engine logic stable |
| **Proposal 133 (Specrew Primer — drafting candidate)** | Direct composer for Pillar 5 — primer + subagent isolation = defense-in-depth against compaction-vulnerability + post-compaction discipline drop |
| **Proposal 010 + Proposal 134 (Multi-Developer)** | Adjacent — multi-dev story (multiple humans) is separate from multi-agent story (multiple AI agents); both compose to enable "multiple humans + multiple AI agents per human" scaling |
| **Proposal 039 (Squad Upstream Reconciliation)** | Strategic — Squad's `squad triage --execute` runs single-loop with no concurrent execution; subagent orchestration is upstream-contribution candidate per `[[reference-brady-gaster-squad-inventor-2026-05-25]]` |

## Strategic upside

**Multi-agent orchestration is upstream-contribution territory** — Squad has zero subagent support today (verified via repo audit; `squad triage --execute` is single-loop). Specrew shipping this is genuine methodology innovation, not catchup. Same channel as Proposal 137 + 138 + 039 for Brady Gaster dialog.

**Cost reduction is empirically measurable** — F-049 burned estimated 5-10× more Opus tokens than necessary. Shipping V1 with AC7 cost-measurement test creates the baseline + ongoing measurement. Once external users adopt (~Sept 2026), cost savings scale with user count.

**Context-window protection composes with Proposal 133 primer** — Together, primer (re-injects methodology after compaction) + subagent isolation (reduces compaction trigger frequency) = comprehensive defense against the entire compaction-vulnerability bug class (F-024 / F-046 / F-048 / Shape 3c). Multi-layered methodology durability.

## Risks

- **Claude Code subagent API may evolve** — Anthropic's subagent surface is relatively new; could change in non-backward-compatible ways. Mitigation: Pillar 1's adapter contract isolates API churn to a single adapter file; version pinning in Specrew's tested Claude Code version
- **Cost-routing accuracy depends on model-catalog freshness** — model pricing changes (recent example: Copilot pricing pivot per `[[project-cost-aware-model-routing-urgent-2026-05-24]]`); catalog can drift. Mitigation: Proposal 068 full implementation includes agent-discovered catalog refresh; V1 ships with manual catalog + `specrew update` migration
- **Subagent dispatch overhead** — for trivial work, subagent dispatch overhead may exceed savings. Mitigation: catalog `preferred_tier` + slice-type-aware applicability; trivial single-grep ops stay in main agent context
- **Per-host adapter maintenance burden** — every new host (Proposal 124 expansion) needs SubagentInvoker adapter. Mitigation: degraded-mode default; per-host adapter is small (~50-100 lines); same shape as Proposal 105 host-native hook adapters
- **AC7 cost measurement methodology** — comparing single-agent vs subagent token cost requires controlled experiment design; risk of noisy/unreliable comparison. Mitigation: AC7 specifies "F-049-equivalent feature" — replay-style controlled experiment with same task sequence; record evidence transparently
- **V2 scope creep** — pressure to add Codex/Copilot/Antigravity subagent adapters in V1. Mitigation: Pillar 6 explicit V2 deferral; degraded-mode adapters in V1 keep cost-routing benefit available everywhere

## Acceptance signals (operational)

- **Signal 1**: Subagent token cost ≥5× lower than single-agent equivalent for F-049-equivalent feature (AC7 empirical)
- **Signal 2**: Main coordinator context growth ≥3× slower than single-agent for long sessions (AC8 empirical)
- **Signal 3**: Compaction-triggered events per feature should drop measurably post-V1 vs pre-V1 baseline; tracked via F-049-style methodology-discipline incidents
- **Signal 4**: Per-iteration validator runtime drops measurably for multi-iter features (parallel subagent dispatch via Pillar 4)
- **Signal 5**: External adopters (post-2026-09 window) cite cost efficiency + context durability as Specrew differentiators

## Status history

- 2026-05-27: candidate proposal drafted during F-049 close + sequencing conversation. User direction explicit: raise priority of multi-agent Claude support; speed up + reduce cost. Six pillars; 15-25 SP; V1 Claude-first with degraded-mode for other hosts. Empirically motivated by F-049 token economics + Shape 3c post-compaction discipline drop incidents + this session's empirical demonstration of subagent value (Explore + general-purpose subagents used repeatedly during F-049 work).
- 2026-05-31: **amendment — Claude dynamic workflows added as additional Pillar 1 substrate.** Claude Code v2.1.154+ (Opus 4.8 era, May 2026) shipped script-orchestrated dynamic workflows: up to 16 concurrent subagents per phase, capped at 1000 per run, intermediate results held in JS script variables (NOT chat context). Discovered via user-flagged `/effort xhigh+workflow` mode in Claude Code session. The dynamic-workflows substrate is a strict capability upgrade over the Task/Agent tool API for parallel-dispatch + context-isolation work classes — same architectural goal as Pillar 1, more capable substrate. Amendment scope (~+2-3 SP, total 17-28): (a) Pillar 1 adds `SupportedDispatchKinds` capability + `dispatchKind` parameter; (b) Pillar 2 catalog schema gains `preferred_dispatch_kind` per role; (c) Pillar 4 validator-parallelization gains substrate-switch logic; (d) Pillar 5 context-protection notes dynamic-workflow is strict improvement; (e) new `state-truth-auditor` catalog role added (empirically motivated by F-051 Iter-1 closeout 5-cycle Codex cross-review pattern); (f) AC1/AC2/AC6/AC8/AC10/AC11 expanded for substrate-aware testing. No fundamental redesign; existing Pillar 1 contract generalizes cleanly to multiple substrates per host. Composition with Proposal 145 (Structured Multi-Phase Reviewer) strengthened — 7-phase reviewer dispatch uses dynamic-workflow on Claude for independent-phase parallelism.

## Cross-references

- **Empirical motivation**: F-049 lifecycle re-runs (high Opus token consumption); F-024 / F-046 / F-048 compaction-vulnerability incidents; this session's empirical demonstration; **F-051 Iter-1 closeout 5-cycle Codex cross-review pattern (2026-05-31)** — depth-N self-audit consistently missed depth-N+1 issues; one round of dynamic-workflow-dispatched state-truth-auditor ≈ all 5 sequential cross-review rounds collapsed
- **Strategic motivation**: Squad upstream has no subagent orchestration (verified via repo audit 2026-05-27 — `bradygaster/squad` README + docs); Spec-Kit has no subagent orchestration (verified via repo audit 2026-05-27 — `github/spec-kit` README + docs); both single-agent-loop designs. **Claude Code dynamic workflows (May 2026)** validate the architectural direction — Anthropic shipped substrate exactly matching what Pillar 1 anticipated; Specrew layered on top gets both substrates (task-tool + dynamic-workflow) at the cost of one adapter
- file:///C:/Dev/Specrew/proposals/024-multi-host-runtime-abstraction.md — direct foundation
- file:///C:/Dev/Specrew/proposals/068-cost-aware-model-routing.md — Pillar 3 absorbs minimal slice
- file:///C:/Dev/Specrew/proposals/023-reactive-specialist-lifecycle.md — adjacent specialist activation story
- file:///C:/Dev/Specrew/proposals/084-validator-iteration-parallelization.md — Pillar 4 extension foundation (shipped)
- file:///C:/Dev/Specrew/proposals/086-validation-pipeline-performance-bundle.md — Pillar 1 memoization composer (shipped)
- file:///C:/Dev/Specrew/proposals/105-host-native-hook-deployment.md — shared host-adapter pattern
- file:///C:/Dev/Specrew/proposals/124-multi-host-catalog-expansion-tier-1.md — new hosts need adapter
- file:///C:/Dev/Specrew/proposals/137-design-alternatives-analysis-gate.md — 3 design flavors parallelize via subagents
- file:///C:/Dev/Specrew/proposals/138-spec-kit-underutilized-surfaces.md — checklist + analyze are subagent candidates
- file:///C:/Dev/Specrew/proposals/102-cross-model-independent-reviewer.md — reviewer subagent role partial provision
- file:///C:/Dev/Specrew/proposals/010-multi-developer-reconciliation.md — multi-human story (separate from multi-agent)
- file:///C:/Dev/Specrew/proposals/134-tooling-version-reconciliation-multi-dev.md — multi-dev tooling-version story
- file:///C:/Dev/Specrew/proposals/039-squad-upstream-reconciliation.md — upstream contribution pattern
- Memory: [[reference-brady-gaster-squad-inventor-2026-05-25]] — strategic upstream channel
- Memory: [[specrew-primer-persistent-host-instructions-2026-05-26]] — Pillar 5 composes for compaction defense-in-depth
- Memory: [[project-f051-iter1-closeout-5-cycle-lesson-2026-05-31]] — empirical motivation for the new `state-truth-auditor` catalog role; depth-N self-audit < depth-N+1 cross-review pattern
- Memory: [[project-proposal-150-agent-support-hardening-2026-05-31]] — Codex reframing pattern; Items 4+5 of 150 (command manifest + structured hardening updater) reduce subagent-substrate-selection friction
- Anthropic: [Dynamic workflows docs](https://code.claude.com/docs/en/workflows) — Pillar 1 `dynamic-workflow` substrate reference
- Anthropic: [Introducing dynamic workflows in Claude Code (blog)](https://claude.com/blog/introducing-dynamic-workflows-in-claude-code) — capability announcement (May 2026)
- INDEX: file:///C:/Dev/Specrew/proposals/INDEX.md
