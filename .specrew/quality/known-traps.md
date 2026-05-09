# Known Traps

Reusable defect patterns that must be rechecked before feature closure.

| Category | Broken Pattern | Detection Method | Remediation Guidance | Discovery Date | Reapplication Result |
| --- | --- | --- | --- | --- | --- |
| path-resolution | `[System.IO.Path]::GetFullPath($ProjectPath)` or equivalent applied to user-supplied relative paths (PWD vs .NET CurrentDirectory split) | `tests/integration/project-path-resolution-regression.ps1` static scan | Replace with `Resolve-ProjectPath` from `extensions/specrew-speckit/scripts/shared-governance.ps1` | 2026-05-09 | Reapplied 2026-05-09; zero findings recorded in `specs/009-project-path-resolution/quality/trap-reapplication.md`. |
