# Drift Log: Iteration 002

**Schema**: v1

## Summary

**Total drift events**: 1
**Resolution rate**: 100% (1/1 resolved)
**Specification drift**: 0 open implementation-vs-contract drifts; the R-019-V2-R1 through R-019-V2-R22 repair chain is fully resolved and revalidated end-to-end on both Windows 11 and WSL Ubuntu

## Events

### Event 2026-05-18 — R-019-V2 22-sub-iteration repair chain for cross-platform `specrew start` TTY launch

- **Status**: resolved
- **Category**: implementation-drift
- **Detected by**: Human WSL Ubuntu end-to-end verification after Iteration 002 first review verdict (READY-FOR-SIGNOFF, 2026-05-17)
- **Affected artifacts**:
  - `scripts/specrew-start.ps1`
  - `Specrew.psm1`
  - `docs/getting-started.md`
  - `docs/user-guide.md`
  - `README.md`
  - `tests/integration/start-command.ps1`
  - `specs/019-specrew-distribution-module/test-evidence/us5-cross-platform.md`
  - `specs/019-specrew-distribution-module/iterations/002/review.md`
- **Description**: After the Iteration 002 first review verdict (READY-FOR-SIGNOFF), human WSL Ubuntu end-to-end testing revealed that `specrew start` did not successfully launch the Copilot interactive REPL on Linux/WSL. A 22-sub-iteration repair chain (R-019-V2-R1 through R-019-V2-R22) ran before the actual root cause was isolated and fixed.
- **Root Cause**: PowerShell on Linux preserves TTY for native command children (`& nativeCommand`) when invoked from FUNCTION-body context, but strips TTY when invoked from SCRIPT-body context. Same `&` operator; different result. This is a Linux `pwsh` I/O handling difference that no flag combination, prompt-content variation, or in-script PTY wrapper can work around from within a script body. Diagnostic: `function F { & nano }; F` — nano renders TUI when called from function context; from script body it does not.
- **Wrong-Direction Repairs (R1-R20)** — all reverted by R22 except where noted:
  - R1: bash `-c` TTY shim (added quoting failures, output buffering, timing variance; didn't fix the underlying issue)
  - R2: empty-state dashboard crash fix — **UNRELATED, LEGITIMATE, kept**
  - R3: dependency pre-flight checks — **UNRELATED, LEGITIMATE, kept**
  - R4: platform-aware post-bootstrap guidance — **LEGITIMATE, kept**
  - R5: actionable install hints — **LEGITIMATE, kept**
  - R6: bash quoted-bootstrap fix — superseded by R22 removal of bash wrapper
  - R7: distribution-module mode detection correction — **LEGITIMATE, kept**
  - R8: `SPECREW_INVOKED_FROM_MODULE` env-var signal — **LEGITIMATE, kept**
  - R9: reversed R1 bash wrapper; restored direct native invocation — **LEGITIMATE reversal, foundation for R21**
  - R10: removed `-i` bootstrap auto-load and replaced with paste-pattern (wrong direction; reverted by R11)
  - R11: restored `-i` bootstrap auto-load; added `--mode interactive` for non-autopilot path (symptom-chasing; reverted by R22)
  - R12: suppressed `--allow-all` on Linux/macOS (platform-conditional workaround; reverted by R22)
  - R13: `--mode interactive` Windows-only addition (further platform-conditional logic; reverted by R22)
  - R14: path-separator fix in `Get-DisplayPathFromProjectRoot` — **LEGITIMATE, kept** (Linux paths now strip leading `/` correctly when computing project-relative display paths)
  - R15/R16: shortened ask_user bootstrap content (wrong direction; reverted by R22)
  - R17: execvp P/Invoke approach (wrong direction; reverted by R22)
  - R18/R19: in-process script invocation in `Invoke-SpecrewScript` — **LOAD-BEARING for R21, kept**
  - R20: `script(1)` PTY wrapper (wrong direction; reverted by R22)
- **Actual Fix (R21, commit 72d3b51)**:
  - `scripts/specrew-start.ps1` writes the copilot launch args to `$env:SPECREW_DEFERRED_LAUNCH_FILE` (a temp file path pointed by an env var) instead of invoking `& copilot @args` directly from the script body.
  - `Invoke-SpecrewScript` in `Specrew.psm1` (function context, called from user's PowerShell prompt) reads the deferred launch file after the script returns and invokes `& copilot @args` from its own function body.
  - TTY is preserved because the invocation site is a function body called from the user's prompt, not a script body.
  - This is approximately 5 lines of coordination code (write temp file in script; read + exec in function body).
- **Cleanup (R22, commit 6fa14d6)**: Reverted all wrong-direction artifacts from R10-R20: `--mode interactive` flag, platform-conditional `--allow-all` suppression, short ask_user bootstrap content, embedded-content-in-`-i` workaround, `script(1)` PTY wrapper, and execvp P/Invoke approach. Launch args returned to the pre-F-019-V2 design: `--agent Squad [--autopilot] --add-dir <project> -i $bootstrap [--allow-all]` uniformly across both platforms.
- **Additional fix — verb conformance (commit 7b08dfd)**: Module exports now use approved `Verb-Noun` form (`Invoke-Specrew`, `Initialize-Specrew`, `Start-Specrew`, `Update-Specrew`, `Show-SpecrewReview`, `Invoke-SpecrewTeam`, `Show-SpecrewStatus`); CLI-friendly aliases preserved. `Import-Module` no longer emits "unapproved verbs" warning.
- **Legitimate Fixes Preserved** (not reverted; real bugs fixed):
  - **R2-R5**: Unrelated quality improvements (dashboard empty-state, pre-flight checks, platform guidance)
  - **R7-R9**: Distribution-module mode detection; `SPECREW_INVOKED_FROM_MODULE` env-var propagation; direct-invocation restoration
  - **R14**: Path-separator fix in `Get-DisplayPathFromProjectRoot` (Linux paths now compute project-relative display paths correctly)
  - **R18/R19**: In-process script invocation in `Specrew.psm1` (load-bearing for R21)
  - **R21**: Deferred-launch from module function body (THE actual fix)
  - **R22**: Cleanup of wrong-direction artifacts
- **Impact**: ~22 sub-iterations × ~1-2 Premium requests each. The actual fix was ~5 lines of coordination code. This asymmetry highlights the critical importance of minimal-variable root-cause isolation before iterating on workarounds.
- **Resolution path**: R-019-V2-R21 + R22 cleanup + verb-conformance commit 7b08dfd
- **Target disposition**: implementation-repaired (deferred-launch coordination + cleanup of wrong-direction artifacts)
- **Key commits**:
  - `e559d65` — R1 wrong-direction bash wrapper (reverted by R22)
  - `72d3b51` — R21 deferred-launch fix (THE actual fix, kept)
  - `6fa14d6` — R22 cleanup (reverted R10-R20 wrong-direction artifacts)
  - `872b5a8` — uniform `--allow-all` default restored
  - `f998730` — README WSL-validated
  - `7b08dfd` — verb conformance (HEAD)
- **Resolved At**: 2026-05-18T00:00:00Z
- **Resolution Notes**: Cross-platform launch flow verified end-to-end on Windows 11 and WSL Ubuntu (native ext4) 2026-05-18 by Alon Fliess. Both `specrew init` (module-mode messaging) and `specrew start` (Copilot interactive REPL with Squad + `--allow-all` + bootstrap via `-i`) confirmed working identically on both platforms.

## Lessons for Quality Corpus

The following lessons are recorded for corpus inclusion (see `iterations/002/retro.md` for full narrative):

1. **Diagnostic discipline**: For cross-platform behavior issues, isolate the minimal-variable diagnostic before iterating on workarounds. A single `function F { & nano }; F` test would have nailed the root cause in ~30 seconds and saved ~14 sub-iterations of speculative work.
2. **Form-vs-meaning recurrence**: R1-R20 chased symptom shapes (flag permutations, bash wrappers, prompt content shapes, PTY allocators, process layering) while the actual issue was at a different invocation-context layer entirely. Composes with the existing form-vs-meaning corpus row.
3. **Cross-platform sweep scope gap**: T041 audited embedded backslashes but did not audit PowerShell-on-Linux behavioral differences (TTY propagation from script vs function context). Future cross-platform sweeps should include behavioral-divergence tests against a baseline Linux `pwsh` environment.
4. **Deferred-launch pattern reusability**: The script-context-to-function-context handoff via env-var-pointed temp file is a reusable pattern for other Specrew commands that need to launch interactive child processes from script context on Linux.
5. **Cost of the chase**: The asymmetry between repair effort (~22 sub-iterations) and fix size (~5 lines) strengthens the case for the queued Validator Hardening and Quality Hardening Bundle features.

## Resolution Strategies

- **spec-updated**: Update the spec to reflect implementation choice
- **implementation-reverted**: Revert implementation to match spec
- **implementation-repaired**: Repair implementation to deliver promised behavior
- **deferred**: Mark drift as deferred to next iteration
- **human-decision**: Escalate to Alon for resolution
