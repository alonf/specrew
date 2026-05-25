# Findings: F-046 Specrew Bug-Bash Bundle

**Feature**: `046-046-bug-bash`  
**Date**: 2026-05-25  

This running ledger documents each defect surfaced during the F-045 v0.27.1 closeout session on 2026-05-25.

---

## Bug 1: Stale-state detector falsely flags `retro` as drift

### Repro

Any feature that progresses `review-signoff` -> `retro` and then has `specrew start` invoked at the `retro` boundary trips:
> Late boundary sync mismatch: review.md is accepted in iteration NNN, but the recorded boundary is 'retro' instead of review-signoff or later.

### Root cause

The allow-list `('review-signoff', 'iteration-closeout', 'feature-closeout')` in `scripts/specrew-start.ps1` line 703 and `scripts/specrew-review.ps1` line 284 omits `retro`. The canonical lifecycle order places `retro` strictly AFTER `review-signoff` and BEFORE `iteration-closeout`.

### Validation criterion

A fixture where boundary state is `retro` and `review.md` has `Overall Verdict: accepted` must NOT trigger any stale-state output. A negative fixture (boundary at `tasks` + accepted `review.md`) must STILL trigger the warning.

### Evidence pointer

- Session memory: [project_stale_detector_retro_false_positive_2026_05_25.md](file:///C:/Users/alon.HOME/.claude/projects/C--Dev-Specrew/memory/project_stale_detector_retro_false_positive_2026_05_25.md)

### Status

Closed (Fixed)

---

## Bug 2: Boundary cursor advances without verdict_history append (architectural)

### Repro

Running `sync-boundary-state.ps1` for any boundary advances `session_state.boundary_type` in `.specrew/start-context.json`, but `boundary_enforcement.verdict_history` remains unchanged and `last_authorized_boundary` stays at the bootstrap-time value.

### Root cause

`sync-boundary-state.ps1` only manages the cursor in `session_state`. The verdict-recording path is invoked exclusively by `specrew start` itself. During single-agent sessions running the entire lifecycle sequentially through chore(boundary) commits without restart, `verdict_history` gets out of sync.

### Validation criterion

Running `sync-boundary-state.ps1 -BoundaryType iteration-closeout` updates BOTH `session_state.boundary_type` and `boundary_enforcement.last_authorized_boundary` and appends a valid new entry to `verdict_history`.

### Evidence pointer

- F-045 iteration 002 closeout commits `eb5c4f86` (sync gap) and `9ca2b19f` (iteration-closeout).

### Status

Closed (Fixed) — with one acknowledged limitation, see Post-Review Note below.

### Post-Review Note (added 2026-05-26 in response to PR #934 Copilot review)

Copilot's PR review correctly identified that the implementation in `scripts/internal/sync-boundary-state.ps1:1103-1109` performs TWO file writes to `.specrew/start-context.json` (one by `Add-SpecrewBoundaryAuthorization` for `boundary_enforcement`, one by `Update-SpecrewStartContext` for `session_state`) rather than one true single-write merged-document update. The spec's "Option A atomicity" goal is therefore achieved as **near-atomic sequential** rather than **strict single-write atomic**.

This is a real architectural limitation. The mitigations in place:

- Each individual write uses `Write-Utf8FileAtomic` (write-temp-then-rename), so each write is filesystem-atomic in isolation.
- The two writes happen sequentially on the same process, same OS, milliseconds apart — the failure window is narrow.
- Both functions carry idempotency guards: `Add-SpecrewBoundaryAuthorization` rejects backward moves (`shared-governance.ps1:1575`), and `sync-boundary-state.ps1:1085` checks `$lastAuthIndex -lt $targetIndex` before invoking the writer. Re-running `sync-boundary-state.ps1` after a crash mid-sequence converges to the correct state.
- The change is still a substantial improvement over the pre-F-046 behavior, where `verdict_history` did not advance at all unless `specrew start` was re-invoked between boundary commits.

True single-write atomicity (compute both deltas in one in-memory context, then `Write-Utf8FileAtomic` once) requires refactoring `Add-SpecrewBoundaryAuthorization`'s public signature to return the modified context instead of persisting itself, plus updating all other callers. That's out of scope for F-046 (a bug-bash bundle). **Queued as a follow-up small-fix slice** for a future iteration to land alongside Proposal 105 (Host-Native Hook Deployment) work.

---

## Bug 3: Scaffolders downgrade accepted artifacts when re-run

### Repro

Re-running `scaffold-reviewer-artifacts.ps1` or `scaffold-retro-artifact.ps1` after review/retro artifacts exist with accepted verdicts replaces custom human evidence/annotations with default template stubs.

### Root cause

Scaffolders write template content without checking if the target file already contains populated verdicts (e.g. `Overall Verdict: accepted`) or customized task verdicts.

### Validation criterion

Compare-before-write. If the target file has populated verdict text or non-stub task verdicts, the scaffolder MUST either skip the write or emit to a sibling `.pending` file with a clear console warning.

### Evidence pointer

- F-045 iteration 001 and iteration 002 `retro.md` "What Didn't Go Well" sections.

### Status

Closed (Fixed)

---

## Bug 4: Boundary-sync prose-name rejection

### Repro

Running `sync-boundary-state.ps1 -BoundaryType implement` results in an immediate parameter binding ValidateSet rejection instead of suggesting the canonical equivalent.

### Root cause

Static parameter validation via `[ValidateSet(...)]` prevents mapping aliases or providing helpful suggestions in case of unrecognized input.

### Validation criterion

Remove `[ValidateSet(...)]` from parameters, and map prose aliases dynamically in the script body (`implement` -> `review-signoff`, `spec` -> `specify`, etc.) or throw a highly clear did-you-mean suggestion.

### Evidence pointer

- F-045 iteration 002 retro.md "What Didn't Go Well".

### Status

Closed (Fixed)

---

## Bug 5: Skill-catalog auto-repair may not fire on recovery path (documentation note)

### Repro / Empirical anomaly

During option A recovery, a warning fired for missing `.claude/skills` despite the auto-repair block existing on the start path.

### Root cause (investigation)

The skill-catalog auto-repair is positioned sequentially *before* the stale-state detection recovery prompt in `specrew-start.ps1`. However, if the per-host skill directory `.claude/skills` exists but is *empty*, `Get-SpecrewSkillCatalogState` resolves `HasMissingRoots` as `$false`, skipping the auto-repair block, while `Test-HostSkillRoot` subsequently fires a warning because no skill files are found in the directory.

### Validation / Resolution

This is a known non-defect in terms of control flow (since auto-repair is not bypassed by the recovery selection). It is downgraded to a documentation note.

### Status

Closed (Documentation Note Added)

---

## Known Non-Defect: tasks-progress.yml timestamp-only rewrite

- **Note**: The minor timestamp-only rewrites to `tasks-progress.yml` observed during the closeout session are a known behavior of the progress helper and are explicitly marked as a non-defect to prevent future re-discovery.
