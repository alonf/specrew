# Dependency Report: Iteration 003

**Schema**: v1
**Reviewed**: 2026-06-03
**Overall Verdict**: accepted

## Summary

- **Dependencies changed**: 0
- **New to project**: 0
- **Vulnerability scan**: unscanned (no manifest files changed in this iteration)

## Detail

- Iteration 003 is pure PowerShell editing two existing scripts (`scripts/auto-detection.ps1`,
  `scripts/specrew-start.ps1`) and adding/extending PowerShell test suites. No `Specrew.psd1`
  FileList entries, no npm/PyPI/NuGet packages, no external tools were added or changed.
- The origin/main merge (`8609760c`) brought 0.31.0 + Feature 140 dependencies (install.sh,
  shell wrappers); those belong to Feature 140's review, not this iteration, and do not affect
  the 141 surface.

## Risk

- No new attack surface, no new runtime dependency, no manifest drift introduced by iteration 003.
