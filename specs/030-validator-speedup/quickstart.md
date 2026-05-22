# Quick Start: Local Validator Auto-Scope Feature (Proposal 083)

**Feature**: Local Validator Auto-Scope for Feature-Branch Invocations  
**Version**: v0.24.2  
**Target User**: Specrew maintainers and Crew members  

---

## What Changed

When you run `validate-governance.ps1` on a feature branch, the validator now **automatically scopes itself** to only the files and iterations you've changed—without requiring any flags. This reduces validator runtime from ~1+ minute (full-repo) to seconds (scoped).

On `main` branch, the validator still runs full-repo by default (no auto-scope). If you need a deliberate full-repo run on a feature branch, pass `-FullRun` explicitly.

---

## Usage Examples

### Example 1: Feature Branch, Auto-Scope (Default, New)

```powershell
# On feature branch chore-083-local-validator-speedup
# Touching iterations 001, 002 (changes to 3 files)
# Run with NO flags

pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\internal\validate-governance.ps1 `
  -ProjectPath C:\Dev\Specrew-083

# Output:
# [validator-scope] auto-scoped to origin/main...HEAD (2 iterations, 3 files in diff)
# Validator running on changed files only...
# (completes in ~2 seconds instead of ~70 seconds full-repo)
```

### Example 2: On Main, Full-Repo (Default, Unchanged)

```powershell
# On main branch
# Run with NO flags

pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\internal\validate-governance.ps1 `
  -ProjectPath C:\Dev\Specrew-083

# Output:
# [validator-scope] full-repo (on main; 44 iterations)
# Validator running on all iterations...
# (full-repo validation as before)
```

### Example 3: Feature Branch, Force Full-Repo with -FullRun (New Flag)

```powershell
# On feature branch
# Need to run full-repo for feature-closeout validation
# Pass -FullRun explicitly

pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\internal\validate-governance.ps1 `
  -ProjectPath C:\Dev\Specrew-083 `
  -FullRun

# Output:
# [validator-scope] full-repo (-FullRun override; 44 iterations)
# Validator running on all iterations...
# (full-repo validation regardless of feature branch)
```

### Example 4: Explicit -ChangedOnly (Backward Compatible)

```powershell
# Existing scripts with explicit -ChangedOnly still work unchanged

pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\internal\validate-governance.ps1 `
  -ProjectPath C:\Dev\Specrew-083 `
  -ChangedOnly `
  -BaseBranch origin/main

# Output:
# [validator-scope] auto-scoped to origin/main...HEAD (2 iterations, 3 files in diff)
# Validator running on changed files only...
# (behavior unchanged from before Proposal 083)
```

### Example 5: No Remote / Detached HEAD (Graceful Fallback)

```powershell
# On feature branch but .git is missing or in detached HEAD state
# Base ref is undetectable

pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\internal\validate-governance.ps1 `
  -ProjectPath C:\Dev\Specrew-083

# Output:
# [validator-scope] full-repo (base-undetectable; 44 iterations)
# Validator running on all iterations (base branch could not be detected)...
# (gracefully falls back to full-repo instead of failing)
```

---

## Key Behaviors

### When Auto-Scope Applies (New Default)

- ✅ On a **feature branch** (not main/master)
- ✅ Base branch is **detectable** via git
- ✅ **No explicit flags** passed (`-ChangedOnly`, `-FullRun`, `-BaseBranch`)

→ Result: Validator runs **changed-only** by default

### When Auto-Scope Does NOT Apply

- ❌ On `main` or `master` branch → full-repo always
- ❌ `-FullRun` flag explicitly passed → full-repo always
- ❌ `-ChangedOnly` flag explicitly passed → honored as-is
- ❌ Base branch undetectable → graceful fallback to full-repo

### New Flag: `-FullRun`

Pass `-FullRun` to bypass auto-scope and force full-repository validation.

**When to use**:

- Feature-closeout validation (ensure no cross-feature drift)
- After major refactoring (need full validation confidence)
- Explicit override for Squad governance workflows

---

## What You See: `[validator-scope]` Banner

Every validator run now emits a **scope banner** as the first informational line:

```
[validator-scope] auto-scoped to origin/main...HEAD (2 iterations, 3 files in diff)
```

This banner shows:

- **Scope type**: `auto-scoped`, `full-repo`, or reason why full-repo
- **Iteration count**: How many iterations are being validated
- **File count** (if scoped): How many changed files in the diff

Use this banner to verify the validator is running the scope you expect.

---

## Base Branch Detection (What Happens Behind the Scenes)

The validator detects the base branch automatically using this priority chain:

1. **CI Environment** (`$env:GITHUB_BASE_REF`) — If running in GitHub Actions CI
2. **Default Upstream** (`git symbolic-ref refs/remotes/origin/HEAD`) — Pointer to default branch on origin
3. **Conventional Defaults** (`git for-each-ref origin/main origin/master`) — Try main, then master
4. **Fallback** (return `$null`) — No remote or detached HEAD; validator falls back to full-repo

If base branch is detectable, auto-scope applies. If not, the validator gracefully falls back to full-repo with an info banner.

---

## Backward Compatibility

✅ **All existing scripts and automation continue to work unchanged**:

- `-ChangedOnly` with `-BaseBranch` still works exactly as before
- Full-repo runs on `main` still work exactly as before
- Any invocation with explicit flags is honored as-is

No breaking changes. The auto-scope default only applies when **no flags are passed**, which is the new conveniente default for feature branches.

---

## Performance Impact

| Scenario | Before | After | Speedup |
|----------|--------|-------|---------|
| Feature branch touching 1 iteration | ~70 seconds | ~2 seconds | **35×** |
| Feature branch touching 2–3 iterations | ~70 seconds | ~3–5 seconds | **15–20×** |
| Full-repo on main (unchanged) | ~70 seconds | ~70 seconds | — |

Speedup is measured empirically as part of integration test evidence.

---

## Getting Help

- **Spec**: [spec.md](spec.md) — Full requirements and acceptance criteria
- **Plan**: [plan.md](plan.md) — Implementation plan and task breakdown
- **Research**: [research.md](research.md) — Clarifications and technical decisions
- **Data Model**: [data-model.md](data-model.md) — Control flow, state machine, and validation rules

---

## For Crew Members (Squad Governance)

If you're a Crew agent performing local validator runs:

- **By default**: The validator will now auto-scope on feature branches. You don't need to remember to pass `-ChangedOnly`.
- **For explicit full-repo**: Pass `-FullRun` when you need a deliberate full-repo run (e.g., during feature-closeout).
- **For CI**: The GitHub Actions workflow already has auto-scope via `$env:GITHUB_BASE_REF`. No changes needed on the CI side.

The `[validator-scope]` banner appears on every run so you can verify the scope is what you expect.

---

## Summary

**New default**: Feature branches auto-scope locally.  
**Opt-out flag**: Pass `-FullRun` for full-repo validation.  
**Scope visibility**: `[validator-scope]` banner shows scope on every run.  
**Backward compatibility**: All existing scripts continue unchanged.  
**Speedup**: ~35× faster for typical small feature branches; full-repo runs unchanged.

---

## Next Steps

After Proposal 083 ships in v0.24.2:

1. **Try it locally**: Run `validate-governance.ps1` on a feature branch and notice the speedup.
2. **Verify scope**: Check the `[validator-scope]` banner to see what scope ran.
3. **Use `-FullRun` when needed**: If you need full-repo validation on a feature branch, pass `-FullRun`.
4. **Report feedback**: If you encounter unexpected behavior or edge cases, report to spec steward.

---

*Proposal 083: Local Validator Speedup — Auto-Scoped Default for Feature-Branch Invocations*  
*v0.24.2 reliability bundle | Feature validated 2026-05-21*
