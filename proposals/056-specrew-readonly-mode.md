---
proposal: 056
title: Specrew Readonly Mode (Concurrent-Session Inspection Safety)
status: candidate
phase: phase-2
estimated-sp: 12
discussion: tbd
---

# Specrew Readonly Mode

## Why

A maintainer often wants to **inspect** Specrew state — check the dashboard, read specs/proposals/decisions, ask questions about the project, validate state — without any risk of mutating files, creating commits, or disturbing a primary Squad session already running on the same project.

This need surfaces concretely in three patterns:

1. **Concurrent-session safety**: when one Squad session is actively driving F-022 implementation, the maintainer wants a SECOND session for inspection ("what's the current dashboard say? what does the F-021 retro lesson 6 actually say? show me proposal 057's open questions") without risking collisions on shared state files. Observed during 2026-05-18 / 2026-05-19 conversations: multiple incidents where concurrent sessions stepped on each other (orphan commits to wrong branches, Proposal 053 created in parallel by another session, INDEX.md potential race).

2. **CI-safe runs**: a CI pipeline wants to invoke `specrew where` or `specrew update --info` to capture state for a build report, with mathematical certainty that the CI run produces zero side effects. Today's runs theoretically could mutate `.specrew/last-start-prompt.md` or session-state files; readonly removes the theoretical risk.

3. **Read-mostly contributors**: a contributor wants to read the project's spec / proposal / decision artifacts and ask questions about them, but doesn't want any chance of accidentally authoring an artifact during exploration. Readonly mode lets them browse safely.

Without readonly mode, every Squad session has full write capability — slash commands, agent invocations, hook firings, decision-ledger writes, session-state writes, file mutations. The maintainer must mentally "be careful not to mutate" during inspection. That's a real cognitive tax + real failure modes.

This proposal establishes a `specrew start --readonly` mode that explicitly enforces inspection-only semantics: all reads succeed; all mutations are blocked.

## What

### The principle

**Readonly mode = inspection-only.** All read operations succeed. All write operations are blocked at the tool/agent layer. The session can answer questions, render dashboards, run validators in observe-mode, and consult Squad agents for opinion — but cannot create commits, modify files, write to the decision ledger, update session state, or trigger lifecycle boundaries.

### Activation: `--readonly` flag

```bash
specrew start --readonly
```

Or, post-Proposal 058 (Plugin-Based Distribution):

```text
/specrew.start --readonly
```

Or as a configurable governance dial (Proposal 047): `governance.default_mode: readonly`.

When activated:

- Visual banner at session start: `⚠️ SPECREW READONLY MODE — inspections only, no mutations`
- All Specrew slash commands behave per their readonly contract (see below)
- Squad coordinator-prompt loads readonly variant
- Session-state files NOT updated on activation (preserves the primary session's state)

### Three enforcement layers

#### Layer 1: Tool-level write blocker

The plugin/module's tool dispatch intercepts file-mutation operations and refuses them:

- `Edit`, `Write`, `NotebookEdit` → return permission error
- `Bash` / `pwsh` operations that mutate (`rm`, `mv`, file redirection, `git commit`, `git push`, `git branch`, `Remove-Item`, `Set-Content`, `Out-File`) → blocked
- Read operations (`Read`, `Glob`, `Grep`, `git log`, `git diff`, `git status`, `Get-Content`) → permitted

#### Layer 2: Squad coordinator behavior

Squad's coordinator-prompt loads a readonly variant that teaches Squad:

- "You are in readonly mode. Do not invoke writing agents. Do not call `/speckit.*` lifecycle commands. Do not modify any files. Do not commit or push."
- "Respond to inspection / question / analysis queries only. Reviewer + Spec Steward may opine on a design without writing artifacts."
- "If the user asks for a mutation (e.g., 'commit this'), refuse with the readonly explanation and suggest restarting without `--readonly`."

#### Layer 3: Governance state suppression

When readonly is active:

- `.specrew/last-start-prompt.md` NOT regenerated (preserves primary session's prompt)
- `.specrew/start-context.json` NOT updated (preserves primary session's context)
- `.squad/identity/now.md` NOT modified
- `.squad/decisions.md` NOT appended to
- No boundary-sync writes
- No feature-claim writes
- Session state files are READ but never written

This is what makes readonly safe for concurrent-session use: the primary session's state surfaces are immutable from the readonly session's perspective.

### Allowed operations (illustrative)

| Category | Operations |
|---|---|
| Dashboard | `specrew where`, `specrew where --worktrees`, `specrew status` |
| Version info | `specrew update --info`, `specrew version` (when Proposal 050 ships) |
| Help / catalog | `specrew help`, `/specrew.help` |
| File reads | Read any spec, plan, retro, closeout, decisions, proposal, code, memory |
| Validators | `validate-governance.ps1` invoked with `--observe-only` flag (no evidence writes) |
| Git inspection | `git log`, `git diff`, `git status`, `git blame`, `git show` |
| Squad agents in advisor mode | Reviewer or Spec Steward respond with opinion without writing artifacts |
| Question-answering | "What does FR-005 of Feature 022 actually require?" — full read access to compose the answer |
| Memory recall | Read any memory entry; respond about historical decisions |
| Proposal review | Read any proposal; compare against others; identify dependencies |

### Blocked operations

| Category | Blocked |
|---|---|
| File mutations | Any Edit / Write / NotebookEdit |
| Git mutations | commit, push, branch creation, merge, checkout that creates state |
| Lifecycle commands | `/speckit.specify`, `/speckit.clarify`, `/speckit.plan`, `/speckit.tasks`, `/speckit.implement`, `/speckit.review`, etc. |
| Write-mode slash commands | `/specrew.update --apply` (read-only `--info` permitted), `/specrew.team add`, `/specrew.review --create-artifact` |
| Decision-ledger writes | No `.squad/decisions.md` appends |
| Session-state writes | No `last-start-prompt.md`, `start-context.json`, `now.md` updates |
| Boundary-sync | No `Invoke-SpecrewBoundaryStateSync` calls |
| Feature claiming | No `.specify/feature.json` modifications |

### What readonly does NOT do

- Does NOT replace the primary `specrew start` mode. Read-write remains default.
- Does NOT bypass authentication or access control. A readonly session has the same file-read access the user has.
- Does NOT prevent the user from manually mutating files via OTHER tools (their text editor, raw `git commit`, etc.). The readonly enforcement is at the Specrew/Squad layer; external tools are out of scope.
- Does NOT modify the underlying lifecycle. A boundary that requires a mutation can't be advanced in readonly; it just halts with an explanation.

## Effort

~12 SP, single iteration.

- `--readonly` flag plumbing through `specrew start` + module entrypoints (~1 SP)
- Tool-level write blocker (intercept Edit/Write; intercept mutating Bash/pwsh) (~3 SP)
- Squad coordinator-prompt readonly variant (~2 SP)
- Governance state suppression (suppress writes to last-start-prompt / start-context / now.md / decisions / boundary-sync) (~2 SP)
- Visual banner at session start + readonly indicator throughout the session (~1 SP)
- Validator observe-only mode (suppress evidence-artifact writes) (~1 SP)
- Tests: confirm reads succeed; confirm writes blocked; confirm concurrent-session safety (~1 SP)
- Documentation: when to use readonly; usage examples; limitations (~1 SP)

## Phase placement

**Phase 2.** Smallest of the post-F-022 queue items at ~12 SP. Independent — no dependencies on other proposals. Could ship as a fast follow-up after F-022 closeout.

**Priority tier**: Tier 2 (UX changes + methodology emphasis). Addresses real friction observed during this session (multi-session coordination friction). Composes well with the rest of the post-F-022 queue.

**Sequencing**: ship anywhere in Phase A or early Phase B. No tight dependencies; can slot wherever there's a small-feature opening.

## Composition with existing queue

| Proposal | Composition |
|---|---|
| **Proposal 010 (Multi-Developer Reconciliation)** | Readonly is the read-side complement. 010 handles coordinated WRITES; readonly avoids needing coordination at all for READS. Together they enable safe multi-session work. |
| **Proposal 014 (Red Team Agent)** | Red Team runs in readonly mode by design (observe + opine, don't break). Readonly mode is the substrate. |
| **Proposal 032 / F-021 (Slash-Command Surface, shipped)** | Each slash command needs a read/write tag for the readonly filter. F-021's catalog can be annotated. |
| **Proposal 047 (Project Governance Profile)** | `default_mode: readonly` becomes a configurable dial. CI defaults to readonly. |
| **Proposal 050 (Version Surface Discoverability)** | `specrew version` is the canonical readonly inspection command. |
| **Proposal 052 (Specrew Profile System)** | Profile-specific readonly modes (e.g., docs profile defaults to readonly except for doc files). |
| **Proposal 054 (Pre-Merge Lifecycle Verification Gate)** | CI runs the gate in readonly mode by default. Readonly is the right substrate for verification work. |
| **Proposal 055 (Always-In-Flow + Bug-Fix Lifecycle)** | Readonly is the "no flow needed" case — no change is being made; no slice required. Compose without overlap. |
| **Proposal 058 (Plugin-Based Distribution)** | Plugin install registers `--readonly` semantics per host. Slash command `/specrew.start --readonly` works in the plugin model. |

## Open questions

1. **Should readonly auto-detect from environment?** E.g., if `$env:CI=1`, default to readonly. Recommend yes for CI defaults; user can override with `--read-write` if they really mean it.
2. **How does readonly handle accidental write attempts?** Silent block? Loud error? Recommend loud error with explanation ("This session is in readonly mode. To enable writes, restart with `specrew start` (without `--readonly`).").
3. **How does readonly interact with autopilot?** Recommend orthogonal — autopilot in readonly is just non-blocking inspection (no decisions to make if no writes can happen). But the flags shouldn't entangle.
4. **Does readonly suppress session-state writes entirely or write to a sandbox?** Recommend: suppress entirely. A sandbox is its own complexity; the simpler semantics is "no writes at all".
5. **How does readonly handle MCP servers that mutate external state (e.g., a GitHub Issues adapter that creates issues)?** Recommend: tag MCP servers with read/write disposition; block writing MCPs in readonly. Per Proposal 057's adapter pattern.
6. **Should there be a `--readonly-with-temp` mode that allows writes to a temp directory only?** Defer to v2; v1 is binary (full readonly or full read-write).
7. **What about validator runs that need to write a transient log?** Recommend: validator runs in observe-only mode write logs to a temp directory, not to `.specrew/log/`.
8. **How does readonly handle the F-020 boundary-event sync function?** Suppress entirely — boundary-sync is a write operation by definition.

## Risks

- **User confusion when writes are blocked**: clear error messages mitigate.
- **Inconsistency across Specrew commands**: each Specrew command needs to honor readonly. Mitigation: central tool-dispatch layer enforces consistently.
- **Squad coordinator-prompt drift**: maintaining two coordinator variants (read-write + readonly) doubles the prompt-maintenance work. Mitigation: shared core prompt + small readonly overlay; minimize divergence.
- **External tools bypass**: a user could still mutate files via their editor while in a readonly session. Mitigation: clearly documented limitation — readonly enforces Specrew layer only, not the user's broader environment.
- **MCP-server side effects**: an MCP server that creates GitHub Issues (e.g., via the GitHub MCP) could mutate external state from within a readonly session. Mitigation: MCP servers tagged with read/write disposition; readonly blocks writing MCPs.
- **Performance**: tool-level intercept may add latency to every operation. Mitigation: cheap check; readonly state is a simple boolean.

## Cross-references

- **[Proposal 010 (Multi-Developer Reconciliation)](file:///C:/Dev/Specrew/proposals/010-multi-developer-reconciliation.md)** — read-side complement
- **[Proposal 014 (Red Team Agent)](file:///C:/Dev/Specrew/proposals/014-red-team-agent.md)** — composes; readonly is Red Team's natural substrate
- **[Proposal 032 / F-021 (Slash-Command Surface)](file:///C:/Dev/Specrew/proposals/032-specrew-slash-commands.md)** — per-command read/write tagging
- **[Proposal 047 (Project Governance Profile)](file:///C:/Dev/Specrew/proposals/047-project-governance-profile.md)** — `default_mode: readonly` dial
- **[Proposal 050 (Version Surface Discoverability)](file:///C:/Dev/Specrew/proposals/050-version-surface-discoverability.md)** — readonly-friendly version commands
- **[Proposal 052 (Specrew Profile System)](file:///C:/Dev/Specrew/proposals/052-specrew-profile-system.md)** — profile-specific readonly defaults
- **[Proposal 054 (Pre-Merge Lifecycle Verification Gate)](file:///C:/Dev/Specrew/proposals/054-pre-merge-lifecycle-verification-gate.md)** — CI runs gate in readonly
- **[Proposal 055 (Always-In-Flow + Bug-Fix Lifecycle)](file:///C:/Dev/Specrew/proposals/055-always-in-flow-bug-fix-lifecycle.md)** — readonly is the "no slice needed" case
- **[Proposal 057 (Roadmap Spine + Adapters)](file:///C:/Dev/Specrew/proposals/057-roadmap-spine-input-adapter-pattern.md)** — adapters tagged with read/write disposition
- **[Proposal 058 (Plugin-Based Multi-Host Distribution)](file:///C:/Dev/Specrew/proposals/058-plugin-based-multi-host-distribution.md)** — plugin registers `--readonly` semantics per host
- **Memory: [Readonly mode candidate (2026-05-18)](file:///C:/Users/alon.HOME/.claude/projects/C--Dev-Specrew/memory/project_readonly_mode_proposal_candidate_2026_05_18.md)** — original capture

## Status history

- 2026-05-18: candidate captured after multi-session coordination friction observed during F-022 work (concurrent sessions creating Proposal 053 in parallel, orphan commits to wrong branches, INDEX.md potential races). Readonly mode identified as the read-side complement to Proposal 010 (multi-developer write coordination).
- 2026-05-19: drafted as full proposal during the post-F-022 consolidation pass. Tier 2 (UX) placement; Phase 2 (small, independent, can ship anywhere in the post-F-022 queue).
