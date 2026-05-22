<p align="center">
  <img src="assets/specrew-icon.png" alt="Specrew" height="100" align="middle" />
  &nbsp;&nbsp;
  <img src="assets/specrew-wordmark-light.svg#gh-light-mode-only" alt="Specrew — Governed Agentic SDLC" height="84" align="middle" />
  <img src="assets/specrew-wordmark-dark.svg#gh-dark-mode-only" alt="Specrew — Governed Agentic SDLC" height="84" align="middle" />
</p>

# Specrew User Guide

This guide covers the day-to-day Specrew lifecycle: planning, execution, review/demo, retrospective, and drift handling.

## Recommended Downstream Entry Point

After `specrew init`, start feature work with:

```powershell
specrew start
```

`specrew start` is the canonical downstream entrypoint. The `specrew` command
resolves through the PowerShell module alias (installed via `Install-Module
Specrew -Scope CurrentUser -SkipPublisherCheck`, or via
`Import-Module C:\Dev\Specrew\Specrew.psd1` from a local clone). For environments
that can't load the module, the direct-script fallback is
`pwsh -File C:\Dev\Specrew\scripts\specrew.ps1 start` — same arguments otherwise.

It prepares the Squad handoff, launches Copilot CLI when available, and tells Squad to drive the full Spec Kit lifecycle with an explicit clarify gate: `specify`, then `clarify`, then `plan`, `tasks`, and `implement`, with skip rationale reserved for resumed specs that are already clarified and materially unchanged. The intended human role is to answer only the unresolved questions Squad cannot safely answer from repo context or current artifacts. You can optionally pass a short plain-language request if you already know the next feature or fix.

For new brownfield projects, the handoff includes discovery from existing code, manifests, docs, and recent git history so Squad can reconstruct the current system baseline, seed the starting spec, and propose concrete stack/domain specialists before it asks broad intake questions. If you start without a grounded request, Specrew keeps Copilot out of autopilot so Squad can ask the next intake question and wait for your answer before it invokes `speckit.specify`.

Once the scope is grounded, Specrew launches from the project directory, reuses the current terminal by default, and auto-loads a compact bootstrap message via `-i` that points Copilot at `.specrew\last-start-prompt.md`, `.specrew\start-context.json`, and the human-readable `.specrew\start-summary.md`. Specrew defaults to **gate-respecting mode** — Squad stops at every lifecycle approval boundary (specify, clarify, plan, tasks, implement, review, retro) and waits for explicit human verdict before advancing. Specrew also defaults to `--allow-all` for tool-call approval (tool invocations between gates run without per-call prompts); use `--prompt-approvals` to keep each tool call interactive. The two flags are independent: `--allow-all` controls tool-call approval; `--autonomous` controls whether Squad advances through lifecycle gates without human input. Pass `--autonomous` only for unattended runs such as overnight execution where you have already authorized the full lifecycle. Pass `--new-window` if you explicitly want a detached PowerShell window.

Copilot remains the mandatory host runtime in v1; optional delegated agents such as Claude and Codex are additive routing choices used for review-heavy and problem-solving-heavy work when enabled. Specrew expects delegated lifecycle runs to leave visible evidence in `.squad\decisions.md`, including the requested agent family, effective agent family, concrete model ID, and fallback reason when routing is not honored. Specrew also applies a **no-gap policy** at review/closure time: known gaps across spec, implementation, tests, docs, or observability must be fixed in the current iteration or explicitly deferred with your approval and recorded evidence before the run is claimed complete. Copilot may still ask you to trust the project directory on first launch.

If you want a repeatable mission-completion smoke check of the real handoff boundary, run `tests\manual\copilot-squad-smoke.ps1`. It provisions a fresh repo, runs `specrew init`, runs `specrew start`, and can optionally launch the real Copilot+Squad session for operator-observed end-to-end validation. When launched, the smoke harness now defaults to same-window monitoring so the live session can be observed directly; use its `-NewWindow` switch only when you intentionally want a detached window.

## Boundary Enforcement (v0.25.0)

Starting in v0.25.0, Specrew enforces lifecycle boundary discipline **mechanically** at the tool-call layer, not just by prose convention. Proposal 065 (Feature 039) ships skill-level authorization gates inside every boundary-advancing skill. The Crew cannot chain past a boundary without an explicit, recognized verdict from you.

### Recognized verdict shapes

When the Crew surfaces a boundary handoff and asks for your verdict, the parser accepts exact shapes only. Ambiguous prose (`looks good`, `yep`, `continue`, `fine`, `okay`) is rejected and re-prompted. The canonical forms:

- `approved for <boundary>-boundary entry` — authorize advance INTO the named boundary
- `approved for <boundary>` — shorter equivalent
- `approved for review-boundary AND review-signoff` — compound, for legitimate two-boundary progression where a substantive review covers both at once
- `rejected for <boundary>` — explicit refusal; Crew returns to clarify or re-plan
- `parked` — hold the current state; no advancement

The full nine boundaries are: `specify`, `clarify`, `plan`, `tasks`, `before-implement`, `review-signoff`, `retro`, `iteration-closeout`, `feature-closeout`.

### Emergency bypass

For migration replays, debugging stuck enforcement, or batch lifecycle work where every-boundary authorization would create unsafe friction:

```powershell
specrew start --bypass-boundary-enforcement --reason "schema migration replay"
```

The `--reason` flag is **mandatory**. Session-scoped (not per-boundary) — one bypass disables enforcement for the whole session, which discourages casual use. Every bypassed boundary writes an audit-trail entry to `.squad/decisions.md`.

### How this composes with `--autonomous`

`--autonomous` (Proposal 066, shipped 2026-05-20) controls whether the host runtime advances **between agent turns** without user input. Boundary enforcement (F-039) controls whether the agent can chain **across boundaries within a single turn**. They are independent:

- `--autonomous` alone: agent advances turn-by-turn but still hits skill-level gates at every boundary
- Boundary enforcement alone (default): gates always fire; turns wait for input
- Both: gates still fire; turns advance without input but every boundary surfaces a directive
- `--bypass-boundary-enforcement`: suspends gates; `--autonomous` still controls turn advancement

## What's New (v0.24.3 + v0.25.0 release bundle)

The v0.24.3 process-optimization bundle and v0.25.0 boundary-enforcement release together shipped substantial discipline and performance improvements. Headline items:

- **F-039 / Proposal 065 — Launch-Mode Boundary Enforcement** (v0.25.0): the section above
- **F-032 / Proposal 090 — Closeout Lifecycle Sync Commands**: `/speckit.specrew-speckit.sync-review-signoff`, `sync-retro`, `sync-iteration-closeout`, `sync-feature-closeout` — canonical sync slash commands that wrap `Invoke-SpecrewBoundaryStateSync` and prevent the non-canonical boundary-string bug class (`feature-closed`, `iteration-closed`, etc.). Use these instead of inline PowerShell at every closeout boundary.
- **F-033 / Proposal 088 — Markdown Lint Pre-Boundary Auto-Fix**: every `Invoke-SpecrewBoundaryStateSync` invocation runs `markdownlint-cli --fix` on changed `.md` files BEFORE any state-file writes. Auto-fixable violations get fixed and surface a directive to commit the fixes as `chore(lint):`. Unfixable violations halt boundary sync with file:line:rule diagnostics.
- **F-034 / Proposal 086 Pillar 1 — Validator Result Memoization**: per-iteration validator results cached at `.specrew/.cache/validator-cache.json` (gitignored). Edit-validate-edit loops drop from ~30s to <100ms on cache hits. Use `-NoCacheRead` to force fresh validation.
- **F-035 / Proposal 084 — Validator Iteration Parallelization**: `validate-governance.ps1` parallelizes iteration validation via `ForEach-Object -Parallel`. Cold-cache 44-iteration runs project ~5× speedup at default throttle 6. `-NoParallel` falls back to serial; `-ThrottleLimit <N>` tunes concurrency.
- **F-036 / Proposal 085 — Closed-Iteration Index**: `.specrew/closed-iterations.yml` records every closed iteration. Validator's full-repo path skips them unless `-IncludeClosed` is set. Use `-RebuildClosedIndex` to regenerate from state.md walk.
- **F-037 / Proposal 086 Pillar 5 — Repetition Detector**: logs validator invocations to `.specrew/.cache/last-commands.log` (FIFO at 20); emits `[validator-repetition-warning]` on the 3rd consecutive identical run against unchanged code. Diagnostic only — non-blocking.
- **F-038 / Proposal 089 minimal slice — PR Review Integration**: validator soft-warning surfaces when host has automated review available (e.g., GitHub Copilot reviewer detected via `gh` CLI + github.com remote) and `pr-review-resolution.md` artifact is missing. Captures Copilot's PR findings into a structured per-iteration artifact.
- **F-031 / Proposal 082 Tier 1 — Boundary Commit + Upstream Push Discipline**: methodology text additions across coordinator-governance.md + all 5 agent charters mandating semantic commit groups before boundary sync and immediate push after each commit. See the "Boundary Commit Discipline" section below.
- **F-030 / Proposal 083 — Local Validator Auto-Scope**: feature-branch `validate-governance.ps1` runs auto-detect the base ref and default to changed-only scope. Use `-FullRun` to force a complete sweep.

## Lifecycle at a Glance

1. Planning
2. Execution
3. Review/Demo
4. Retrospective

## Project Status Dashboard

Use the dashboard whenever you need a one-screen delivery summary:

```powershell
specrew where
specrew status --compact
specrew where --team --no-color
```

> Direct-script equivalent (no module): replace `specrew` with
> `pwsh -NoProfile -File C:\Dev\Specrew\scripts\specrew.ps1`.

The dashboard reads:

- `.specify/feature.json` for the active feature
- `specs/<feature>/iterations/<NNN>/` artifacts for closed and active iteration data
- `.specrew/roadmap.yml` for roadmap phases when present

Closeout workflows now preserve historical dashboard snapshots:

- `specs/<feature>/iterations/<NNN>/dashboard.md`
- `specs/<feature>/closeout-dashboard.md`

These snapshots are generated automatically during iteration-closeout and
feature-closeout scaffolding and are preserved as immutable historical records.

The validator may emit `WARN [dashboard]` lines when roadmap declarations drift
from canonical shipped work or when required dashboard artifacts are missing
after the rollout cutover (historical pre-rollout iterations are grandfathered).

Core iteration artifacts live under `specs/<feature>/iterations/<NNN>/`.

## 1. Planning

Goal: produce a requirement-traceable plan before execution starts.

Minimum artifact: `plan.md`

Helpful scaffold:

```powershell
pwsh -File .\.specify\extensions\specrew-speckit\scripts\scaffold-iteration-plan.ps1 `
  -SpecPath .\specs\001-your-feature\spec.md `
  -IterationNumber 001
```

Checklist:

- Every task maps to requirement IDs
- Effort and owner are filled
- Capacity is explicit
- `plan.md` includes an `## Effort Model` snapshot that matches `.specrew/iteration-config.yml`
- The plan reflects `.specrew/iteration-config.yml` values for effort unit, bounding mode, overcommit threshold, and defer strategy
- If the plan exceeds the configured threshold, `validate-governance.ps1` must fail the planning artifact and name explicit deferral candidates from the lowest-priority requirement slices first
- Status is `planning` until approved

## 2. Execution

Goal: complete tasks while keeping task state and drift evidence current.

Minimum artifacts: `state.md`, `drift-log.md`

Helpful scaffold:

```powershell
pwsh -File .\.specify\extensions\specrew-speckit\scripts\scaffold-iteration-artifacts.ps1 `
  -SpecDirectory .\specs\001-your-feature `
  -IterationNumber 001
```

Checklist:

- Update task status in `plan.md`
- Keep `state.md` current (`Last Completed Task`, `Tasks Remaining`)
- Log drift events with requirement citations in `drift-log.md`

If execution is interrupted, use the resume helper to recover the next task from `state.md` and `plan.md`. The helper repairs stale or partial execution metadata when the task table provides enough information to continue safely:

```powershell
pwsh -File .\.specify\extensions\specrew-speckit\scripts\resume-iteration.ps1 `
  -IterationDirectory .\specs\001-your-feature\iterations\001 `
  -ResumeMode continue
```

## 3. Review/Demo

Goal: record per-task verdicts against requirements.

Minimum artifact: `review.md`

Helpful scaffold:

```powershell
pwsh -File .\.specify\extensions\specrew-speckit\scripts\scaffold-review-artifact.ps1 `
  -IterationDirectory .\specs\001-your-feature\iterations\001
```

Checklist:

- Verdict for each completed task: `pass`, `needs-work`, or `blocked`
- Overall verdict recorded
- Any unresolved drift explicitly called out

## Reviewer-Regression Routing and Lockout-Cap Behavior

Specrew treats a concrete human-found defect in a slice that the Squad reviewer already approved or marked ready as a **Reviewer Regression Event**. The event stays a soft-warning governance signal, but it immediately changes the next review path for that feature:

1. Route to the **lowest stronger reviewer class** that is actually available.
2. If no stronger class exists, route to an **independent reviewer owner at the same class**.
3. If the strongest class is already active and no independent reviewer remains, **hold for explicit human direction** before review continues.

This reviewer-side routing is additive to the existing implementer-side escalation flow; Specrew does not replace the original implementer FR-027 behavior just because a reviewer regression occurred.

### Lockout-cap rule

Reviewer regressions do not allow unlimited implementer rotation. By default, Specrew caps the implementer chain at **two rotations beyond the original implementer**. Once the cap is active, the next revision must be:

- a **human-owned revision**, or
- an **explicitly justified alternate owner** recorded in `.squad\decisions.md`

Specrew does not synthesize another implementer specialist after the cap is reached.

When reviewer closeout artifacts are scaffolded, the lockout-cap handoff is visible in both `reviewer-index.md` and `specrew review`. The following lines were verified against actual `scaffold-reviewer-artifacts.ps1` and `specrew review` output on the lockout-cap fixture:

```text
Lockout Cap: active | chain=3/2 | locked_out=Standard implementer rotation pool (original + 2 rotations exhausted)
Next Owner: Awaiting human-owned revision or explicitly approved alternate owner recorded in `.squad/decisions.md`
SPECREW_REVIEW schema=v1 iter=001 feature=008-sample verdict=blocked tasks=3/3 reqs=3 files=0 new_deps=0 vuln=unscanned cov=not_executed escalations=1 routing_fallbacks=0 cap=active cap_chain=3/2 drift=0/0 index=specs\008-sample\iterations\001\reviewer-index.md
```

### Withdrawal and misreport handling

If a reviewer-regression report is later withdrawn or classified as a misreport, Specrew preserves the ledger audit trail and reverses only the still-pending state created by that event, such as:

- an in-flight reviewer escalation
- an awaiting-human-owned-revision hold
- an alternate-owner path that has not yet completed

Completed ownership changes remain historical fact. Unapproved candidate trap entries derived from the withdrawn event are removed, but already approved corpus entries stay under the normal corpus-change workflow instead of being auto-removed.

## 4. Retrospective

Goal: capture estimation accuracy, drift summary, and improvement actions.

Minimum artifact: `retro.md`

Helpful scaffold:

```powershell
pwsh -File .\.specify\extensions\specrew-speckit\scripts\scaffold-retro-artifact.ps1 `
  -IterationDirectory .\specs\001-your-feature\iterations\001
```

Checklist:

- Task and phase variance captured
- Drift totals and resolutions summarized
- Improvement actions listed

## Troubleshooting

### Review boundary fails with a form-vs-meaning gap

If `validate-governance.ps1` reports a `review-evidence-integrity` failure, the
iteration artifacts declare completed work but the committed git diff since the
iteration baseline is empty. In practice, that usually means implementation was
not committed before review started.

Fix it in this order:

1. Commit the implementation work.
2. Re-run the validator.
3. Rebuild reviewer artifacts if review evidence was already scaffolded.

When you re-run `scaffold-reviewer-artifacts.ps1` with `-Force`, Specrew
overwrites the generated review artifacts after confirmation. Use
`-Confirm:$false` only for non-interactive automation.

**Important**: put human annotations and reviewer notes in `review.md`, not in
generated artifacts such as `code-map.md`, `dependency-report.md`,
`coverage-evidence.md`, or `review-diagrams.md`. Generated artifacts are
regenerated from git state and are expected to be disposable.

## Extending the Team After Bootstrap

Specrew bootstrap always installs and protects the same five baseline governance roles:

- Spec Steward
- Planner
- Implementer
- Reviewer
- Retro Facilitator

Those roles live in the Specrew-managed baseline block inside `.squad\team.md`. They are intentionally deterministic, so do not remove or rewrite that managed block as your customization mechanism.

To add domain-specific help after bootstrap, use Specrew's command-driven team management interface:

```powershell
# Add a new domain-specific member
specrew team add security-analyst `
  --role "Security Analyst" `
  --charter "Review code for security vulnerabilities, ensure secure coding practices."

# List all current team members
specrew team list

# Update an existing member's charter
specrew team update security-analyst `
  --charter "Updated security review charter..."

# Remove a domain-specific member (baseline roles cannot be removed)
specrew team remove security-analyst
```

Replace `C:\Dev\Specrew` with the actual path where you cloned the Specrew repository.

### Optional: Adding Specrew to PATH

For convenience, you can add the Specrew scripts directory to your PATH to use short commands like `specrew team list` instead of typing the full path each time.

**Current Session Only** (temporary, lost when shell closes):

```powershell
$env:PATH = "$env:PATH;C:\Dev\Specrew\scripts"
```

**Persistent** (all future sessions):

```powershell
$currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
$pathEntries = $currentPath -split ";"
if ($pathEntries -notcontains "C:\Dev\Specrew\scripts") {
    [Environment]::SetEnvironmentVariable("PATH", "$currentPath;C:\Dev\Specrew\scripts", "User")
    Write-Host "Added Specrew scripts to user PATH. Restart your shell to apply." -ForegroundColor Green
}
```

After adding to PATH persistently, restart your PowerShell session, then use the short form:

```powershell
specrew start "Build a REST API for user management"
specrew team list
specrew team add my-specialist --role "Role" --charter "Charter text"
```

The `add` command creates all required Squad artifacts atomically: (1) adds a row to `.squad\team.md` outside the baseline block, (2) creates `.squad\agents\<member>\charter.md`, and (3) initializes `.squad\agents\<member>\history.md`. The `update` and `remove` commands modify or delete these artifacts consistently. All commands validate that baseline roles remain protected.

Use this path for additive specialization only. Specrew still expects the baseline governance crew to remain present.

## Brownfield Bootstrap

When `specrew init` detects an existing `.specify/` or `.squad/` directory in the project, it operates in brownfield mode:

1. **Preserves existing configuration**: Existing specs, governance artifacts, and user customizations are never overwritten.
2. **Merges baseline roles**: Specrew's five baseline roles (Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator) are merged into `.squad/team.md` only if they don't already exist.
3. **Reports conflicts**: If existing roles or ceremonies conflict with Specrew's baseline, the script reports them and provides resolution guidance.
4. **Blocks deployment on conflicts**: When conflicts are detected, bootstrap exits with code 5 and deployment is blocked until conflicts are manually resolved.
5. **Supports dry-run**: Use `specrew init --dry-run` to preview changes and generate a reviewable report artifact before applying them.

### Brownfield Dry-Run Artifact

When running `specrew init --dry-run` in brownfield mode, Specrew creates a timestamped report artifact at `.specrew\bootstrap-dry-run-{timestamp}.md` containing:

- Brownfield analysis summary (preserved specs, roles, ceremonies)
- Detected conflicts with resolution guidance
- Warnings and recommendations
- Planned actions that would be performed during actual bootstrap

This artifact provides a reviewable record of the brownfield merge plan before committing to changes.

### Brownfield Merge Analysis

Run `extensions\specrew-speckit\scripts\brownfield-merge.ps1` directly to analyze an existing project's compatibility with Specrew:

```powershell
pwsh -File .\extensions\specrew-speckit\scripts\brownfield-merge.ps1 `
  -ProjectPath .\path\to\existing\project `
  -DryRun
```

The analysis reports:

- **Preserved artifacts**: Existing specs, roles, and ceremonies that will not be modified
- **Mergeable content**: Baseline roles and ceremonies that can be safely added
- **Conflicts**: Naming collisions that require manual resolution
- **Warnings**: Partial platform installations or other non-blocking issues

### Conflict Resolution

If Specrew detects role name conflicts (e.g., an existing "Implementer" role), it:

1. Reports the conflict in the console output
2. Exits with code 5 to prevent deployment
3. Provides guidance to manually merge or rename conflicting roles before re-running bootstrap

The `-Force` flag does NOT bypass conflict checks. Conflicts must be manually resolved before bootstrap can proceed.

1. Record event in `drift-log.md` with exact requirement reference.
2. Decide one resolution path:

- Update spec (tracked change)
- Rework implementation
- Escalate for human decision

1. Reflect the decision in `review.md` verdict notes and next tasks.

## Boundary Commit Discipline

Specrew lifecycle work flows through several boundaries — specify, clarify, plan, tasks, implementation, review-signoff, retro, iteration-closeout, and feature-closeout. At each boundary, the Crew (the agent team executing the lifecycle) produces artifacts: spec.md, plan.md, code, tests, review.md, retro.md, closeout-dashboard.md, decisions ledger entries, and more.

**Commit at every boundary. Push after every commit.** This is the methodology's commit discipline:

- At every lifecycle boundary, the Crew commits the boundary-phase work in semantic commit groups BEFORE invoking `Invoke-SpecrewBoundaryStateSync` or signaling boundary readiness. Working-tree-only changes are not durable boundary evidence — a power loss, working-tree corruption, or `git clean -fd` would erase them.
- After every commit, the Crew pushes the feature branch to `origin/<feature-branch>` immediately. Local-only commits are not upstream-backed-up; a workstation failure loses them.
- The Crew verifies `git rev-parse HEAD` equals `git rev-parse origin/<feature-branch>` BEFORE signaling boundary readiness. The committed evidence reference (commit SHA or hash range) appears in the boundary handoff's `What I just did` section.
- If no `origin` remote is configured (e.g., a local-only project), push silently skips. Commit discipline still applies.

### Why it matters

Without this discipline:

- Boundary-sync's validator passes because it reads working-tree content, but anyone cloning the branch from origin sees no work. The methodology claims discipline it doesn't deliver.
- Premium agent quota is wasted on rejection-redo cycles when boundary signals are issued before the work is committed.
- Audit trail (`.squad/decisions.md`, scribe logs, retro evidence) drifts from actual git history, making methodology evolution decisions harder.

### Per-role responsibilities

- **Implementer** is the primary committer for implementation work. Commits in semantic groups before invoking boundary-sync at implementation → review-signoff.
- **Spec Steward** oversees boundary-commit discipline at every advancement decision. Verifies push parity before signing off.
- **Reviewer** rejects PRs containing WIP at PR-open time as a hard reject. Commit + push first, then re-request review.
- **Retro Facilitator** evaluates commit-discipline at retro and records `boundary-commit-discipline-violations` count as a standard signal.
- **Planner** anticipates commit cadence in plan.md output; each boundary's tasks map to a semantic commit group.

### Enforcement layers

This discipline ships in three tiers:

- **Tier 1 (text-only, this release)**: explicit instructions in the Coordinator governance prompt + all 5 baseline agent charters + this section. The discipline is conveyed; the Crew applies it.
- **Tier 2 (future)**: a validator rule (`boundary-wip-uncommitted` at warning severity) flags WIP-at-boundary in `validate-governance.ps1` output. Surfaces violations without blocking.
- **Tier 3 (future)**: `Invoke-SpecrewBoundaryStateSync` refuses to advance if WIP is present. Auto-push hook after every commit (configurable via `iteration-config.yml`).

Each tier is its own slice; Tier 1 ships first as a methodology-text addition, Tier 2/Tier 3 follow as later releases when empirical data justifies the additional enforcement weight.

## What's Coming

The next release queue focuses on intake quality, expert-developer ergonomics, and multi-host expansion. Active proposals worth tracking:

- **F-040 / Proposal 063 — Substantive Intake Questioning**: persona-driven adaptive intake (PM / UX / Architect / Researcher), 12-category catalog, Mode A/B/C input-quality assessment. Fires at `/speckit.specify`, `/speckit.clarify`, iteration kickoff, mid-feature pivot. The intake interview that stops Squad from auto-resolving scope decisions silently. Source: [Proposal 063](../proposals/063-substantive-intake-questioning.md).
- **Proposal 099 — Installed-File SDLC Instruction Audit**: closes the dogfooding deficit between paste-prompt scaffolding and the discipline carried by installed instruction files (coordinator-governance.md, agent charters, sync command docs). Three small-fix closure slices identified: recognized verdict shapes catalog, reconciliation directive, smaller refinements bundle. Source: [Proposal 099](../proposals/099-installed-file-sdlc-instruction-audit.md).
- **Proposal 100 — Friction Dial**: three canonical modes (strict / default / autonomous) controlling verdict-parser acceptance, reconciliation posture, drift-log granularity, and compound-verdict eligibility. Composes Proposals 015 + 047 + 066 into a coherent surface. Persistence in `.specrew/config.yml`; session override via `specrew start --friction <mode>`. Source: [Proposal 100](../proposals/100-friction-dial.md).
- **Proposal 069 — Multi-Host Launch Path**: `specrew start --host claude|codex|copilot|auto` launches the alternate CLI with the Specrew bootstrap context. Tactical MVP of Proposal 024 (Multi-Host Runtime Abstraction). Composes with Proposals 068 (cost-aware model routing) and 070 (token economy MVP). Source: [Proposal 069](../proposals/069-multi-host-launch-path.md).
- **Proposal 068 — Cost-Aware Model Routing** + **Proposal 070 — Token Economy MVP**: agent-discovered model catalog routes Junior/Implementer tasks to cheap models, Senior/Reviewer tasks to strong. `cost.yml` per iteration tracks token consumption + cost estimate; `specrew where` dashboard gains a COST section.
- **Proposal 098 — Launch Posture Visibility (candidate)**: surfaces enforcement state (`[BYPASS ACTIVE]` indicator, active friction mode) at `specrew start` banner. Companion to Proposal 100 and Proposal 065.

Full proposal catalog with status (Shipped / Draft / Candidate) lives at [proposals/INDEX.md](../proposals/INDEX.md).

## Practical Operating Notes

- Treat the spec as source of truth.
- Keep artifacts small and current; avoid end-of-iteration backfilling.
- Use `validate-governance.ps1` before closing an iteration.

```powershell
pwsh -File .\.specify\extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath .
```

For process-quality scoring (FR-015 Iteration 2 slice), run:

```powershell
pwsh -File .\evaluation\scorers\process-scorer.ps1 -ProjectPath . -AsJson
pwsh -File .\evaluation\scorers\process-scorer.ps1 -ProjectPath . -WriteReport
```

`-WriteReport` produces `evaluation\report.md` with the current process-quality summary plus an explicit Outcome Quality placeholder until the Iteration 3 scorer lands.

## Troubleshooting

### Copilot CLI "Failed to load N skills" warning at startup

If you see this warning after `specrew init`, it is an upstream Copilot CLI behavior, not a Specrew issue. Copilot CLI scans `~/.claude/skills` and `~/.agents/skills` in your home directory. If you also use Claude Code or OpenCode, those directories may contain skills with colon-delimited names such as `ck:foo`; Copilot CLI's parser rejects those names because it only accepts letters, numbers, hyphens, underscores, dots, and spaces.

Specrew's own slash-command surface (`/specrew-where`, `/specrew-help`, `/specrew-version`, `/specrew-update`, `/specrew-team`, `/specrew-review`, `/specrew-status`) uses hyphenated names and is unaffected. To confirm a Specrew skill loaded correctly, run `/skills info specrew-help` inside the Copilot CLI session and verify that Copilot reports the expected Specrew skill path and metadata.

Upstream tracking: <https://github.com/github/copilot-cli/issues/2689>. Copilot CLI does not currently provide a config switch to exclude those directories from scanning. The warning is cosmetic and does not block Specrew's own skills from working.
