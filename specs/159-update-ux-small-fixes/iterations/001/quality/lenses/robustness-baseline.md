# Robustness Baseline Lens: Iteration 001

**Feature**: 159-update-ux-small-fixes  
**Lens Ref**: robustness-baseline@v1.0.0  
**Phase**: before-implement planning

## Planned Review

- Older running module fails closed and exits non-zero.
- Present but unparsable project baseline fails closed before mutation.
- Absent project baseline preserves existing behavior.
- Equal/newer running module preserves existing behavior.
- `specrew update --info` remains read-only.
- Refusal output is actionable and names both `Update-Module Specrew` and `SPECREW_MODULE_PATH`.

## Runtime Evidence Needed

- Update-command regression run.
- Explicit output assertions for refusal message.
- Before/after protected-surface snapshots.
