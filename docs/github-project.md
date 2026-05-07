# Specrew GitHub Project Board

## Overview

Specrew's development is tracked primarily through local task artifacts: iteration plans, state files, and review documents stored in the specification directory. GitHub Issues and the GitHub Projects V2 board are synchronized from those artifacts for visibility, but they are not the authoritative source of truth.

**Authoritative source**: `specs/001-specrew-product/iterations/NNN/plan.md` and iteration state artifacts  
**Project board**: [https://github.com/users/alonf/projects/10](https://github.com/users/alonf/projects/10)

## Source-of-Truth Hierarchy

1. **Authoritative (required)**: Iteration plan, state, drift log, review, and retro artifacts in `specs/001-specrew-product/iterations/NNN/`
2. **Derived mirror**: GitHub Issues created from iteration plans and lifecycle artifacts
3. **Visibility layer**: GitHub Projects V2 board showing synchronized issue status

All iteration execution, status movement, and closure decisions are recorded first in local artifacts. GitHub Issues and the project board are *synchronized from* these artifacts, not the other way around.

## Board Layout

- **Status field**: Todo, In Progress, Done
- **Standard views**: Board view, Table view, Roadmap view
- **No custom columns**: Following Squad's documented default board layout

## Automation

### What syncs automatically

The repository now contains `.github/scripts/sync-specrew-board.ps1` and `.github/workflows/specrew-project-sync.yml`.

On every push that changes iteration artifacts, the workflow:

1. Creates or updates one **lifecycle issue** per active iteration
2. Creates or updates one **task issue** per task row in `plan.md`
3. Re-runs when `drift-log.md` changes so lifecycle mirrors stay aligned to authoritative drift evidence
4. Adds synchronized issues to GitHub Project `alonf/10`
5. Updates the board **Status** field from authoritative local state
6. Closes mirrored issues when the local artifacts reach terminal completion

### Status mapping

| Local artifact state | Board status | Labels |
| --- | --- | --- |
| Iteration `planning` | Todo | `phase:planning` |
| Iteration `executing` | In Progress | `phase:executing` |
| Iteration `reviewing` | In Progress | `phase:reviewing` |
| Iteration `retro` | In Progress | `phase:retro` |
| Iteration `complete` / `abandoned` | Done | `phase:complete` / `phase:abandoned` |

Task issues stay aligned to task-table status and review verdicts, while the lifecycle issue reflects the iteration phase itself.

### Local execution

You can run the same sync locally with a GitHub-authenticated CLI session:

```powershell
pwsh -File .\.github\scripts\sync-specrew-board.ps1 -Repository alonf/specrew -ProjectOwner alonf -ProjectNumber 10
```

## Local Execution Path

Specrew self-development uses GitHub as a **review and visibility path**, not as the system of record.

1. Update the authoritative local artifacts first: `plan.md`, `state.md`, `drift-log.md`, `review.md`, and `retro.md`.
2. Run the sync path so the mirrored lifecycle/task issues and Project board reflect that local state.
3. Execute task work from a Squad issue branch named `squad/{issue-number}-{slug}`.
4. When parallel issue work is needed, prefer a dedicated `git worktree` per mirrored task issue; otherwise use the same branch naming convention in the main checkout.
5. Open a standard GitHub PR back to the active integration branch after the local artifacts and task implementation are both updated.

For Iteration 001 self-development, the active integration branch is `001-specrew-product`; per-task issue branches and optional worktrees should target that branch instead of making GitHub Issues or the board authoritative.

## Capability Status

The unattended GitHub Actions workflow is now fully operational.

- Repository secret `SPECREW_PROJECT_TOKEN` has been configured with a token holding `repo` and `project` scopes.
- The sync script is implemented and tested; manual sync is operational and updates the mirrored issues/project board from local iteration artifacts.
- Workflow automation is ready to trigger on push to `main` or `001-specrew-product` when iteration artifacts change.
- Unattended board maintenance is no longer blocked.

## Squad Integration

Specrew keeps the default Projects V2 layout and uses automation only as a mirror of local-first execution.

- Local task artifacts drive iteration execution; GitHub artifacts are secondary mirrors
- The board uses Squad's documented default layout
- No custom board columns were introduced
- No Spec Kit-side project-management extension was added

## References

- Spec: `specs/001-specrew-product/spec.md` (Clarifications: GitHub Projects V2 board)
- Iteration 0 Plan: `specs/001-specrew-product/iterations/000/plan.md`
- Protocol: `.squad/protocol.md` (iteration lifecycle and role responsibilities)
- Workflow: `.github/workflows/specrew-project-sync.yml`
- Script: `.github/scripts/sync-specrew-board.ps1`
