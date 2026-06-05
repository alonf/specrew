# Robustness Baseline Lens: Iteration 001

**Feature**: 159-update-ux-small-fixes  
**Lens Ref**: robustness-baseline@v1.0.0  
**Phase**: review-signoff

## Planned Review

- Older running module fails closed and exits non-zero.
- Present but unparsable project baseline fails closed before mutation.
- Absent project baseline preserves existing behavior.
- Equal/newer running module preserves existing behavior.
- `specrew update --info` remains read-only.
- Refusal output is actionable and names both `Update-Module Specrew` and `SPECREW_MODULE_PATH`.

## Runtime Evidence Needed

- Complete. `tests/integration/update-command.ps1` exits 0.
- Complete. Test 0 asserts refusal output contains `Update-Module Specrew`, `SPECREW_MODULE_PATH`, project baseline, and no-change text.
- Complete. Test 0 compares before/after protected-surface SHA256 snapshots and does not rely on `git status`.

## Verdict

pass
