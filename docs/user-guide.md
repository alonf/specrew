# Specrew User Guide

This guide covers the day-to-day Specrew lifecycle: planning, execution, review/demo, retrospective, and drift handling.

## Recommended Downstream Entry Point

After `specrew init`, start feature work with:

```powershell
pwsh -File C:\Dev\Specrew\scripts\specrew.ps1 start
```

`specrew start` is the canonical downstream entrypoint. It prepares the Squad handoff, launches Copilot CLI when available, and tells Squad to drive the full Spec Kit lifecycle with an explicit clarify gate: `specify`, then either `clarify` or a recorded skip rationale, then `plan`, `tasks`, and `implement`. For new-feature and new brownfield runs, the default is to run `clarify` unless the spec is already materially complete for planning. The intended human role is to answer only the unresolved questions Squad cannot safely answer from repo context or current artifacts. You can optionally pass a short plain-language request if you already know the next feature or fix. For new brownfield projects, the handoff now includes discovery from existing code, manifests, docs, and recent git history so Squad can reconstruct the current system baseline, seed the starting spec, and propose concrete stack/domain specialists before it asks broad intake questions. To reduce Copilot CLI blocking, Specrew launches from the project directory, defaults to `--allow-all`, and reuses the current terminal by default; use `--prompt-approvals` for interactive permission prompts or `--new-window` if you explicitly want a detached PowerShell window. Copilot may still ask you to trust the project directory on first launch.

If you want a repeatable mission-completion smoke check of the real handoff boundary, run `tests\manual\copilot-squad-smoke.ps1`. It provisions a fresh repo, runs `specrew init`, runs `specrew start`, and can optionally launch the real Copilot+Squad session for operator-observed end-to-end validation. When launched, the smoke harness now defaults to same-window monitoring so the live session can be observed directly; use its `-NewWindow` switch only when you intentionally want a detached window.

## Lifecycle at a Glance

1. Planning
2. Execution
3. Review/Demo
4. Retrospective

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
pwsh -File C:\Dev\Specrew\scripts\specrew.ps1 team add security-analyst `
  --role "Security Analyst" `
  --charter "Review code for security vulnerabilities, ensure secure coding practices."

# List all current team members
pwsh -File C:\Dev\Specrew\scripts\specrew.ps1 team list

# Update an existing member's charter
pwsh -File C:\Dev\Specrew\scripts\specrew.ps1 team update security-analyst `
  --charter "Updated security review charter..."

# Remove a domain-specific member (baseline roles cannot be removed)
pwsh -File C:\Dev\Specrew\scripts\specrew.ps1 team remove security-analyst
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
3. Reflect the decision in `review.md` verdict notes and next tasks.

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
