# Dependency Report: Iteration 004

**Schema**: v1
**Reviewed**: 2026-06-03
**Overall Verdict**: accepted

## Summary

- **Dependencies changed**: 0
- **New to project**: 0
- **Vulnerability scan**: unscanned (no manifest files changed)

## Detail

- Pure PowerShell (`scripts/internal/lens-applicability.ps1`) + a JSON data file
  (`applicability-map.json`) + a markdown template edit. No npm/PyPI/NuGet packages, no
  `Specrew.psd1` FileList change, no external tools. JSON is parsed with the built-in
  `ConvertFrom-Json` (no YAML/parsing dependency added).
- The selector is network-free and LLM-free by design (FR-025).

## Risk

- No new runtime dependency, no manifest drift, no new attack surface introduced by iteration 004.
