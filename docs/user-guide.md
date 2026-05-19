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

Once the scope is grounded, Specrew launches from the project directory, reuses the current terminal by default, and auto-loads a compact bootstrap message via `-i` that points Copilot at `.specrew\last-start-prompt.md`, `.specrew\start-context.json`, and the human-readable `.specrew\start-summary.md`. Specrew defaults to `--allow-all` to reduce tool-approval blocking after the scope is grounded. Use `--prompt-approvals` for interactive permission prompts or `--new-window` if you explicitly want a detached PowerShell window.

Copilot remains the mandatory host runtime in v1; optional delegated agents such as Claude and Codex are additive routing choices used for review-heavy and problem-solving-heavy work when enabled. Specrew expects delegated lifecycle runs to leave visible evidence in `.squad\decisions.md`, including the requested agent family, effective agent family, concrete model ID, and fallback reason when routing is not honored. Specrew also applies a **no-gap policy** at review/closure time: known gaps across spec, implementation, tests, docs, or observability must be fixed in the current iteration or explicitly deferred with your approval and recorded evidence before the run is claimed complete. Copilot may still ask you to trust the project directory on first launch.

If you want a repeatable mission-completion smoke check of the real handoff boundary, run `tests\manual\copilot-squad-smoke.ps1`. It provisions a fresh repo, runs `specrew init`, runs `specrew start`, and can optionally launch the real Copilot+Squad session for operator-observed end-to-end validation. When launched, the smoke harness now defaults to same-window monitoring so the live session can be observed directly; use its `-NewWindow` switch only when you intentionally want a detached window.

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
