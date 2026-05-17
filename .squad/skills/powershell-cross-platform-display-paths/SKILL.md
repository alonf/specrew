---
name: "powershell-cross-platform-display-paths"
description: "Repair PowerShell relative-path display helpers so Windows and Linux/macOS keep project-relative bootstrap paths truthful"
domain: "powershell"
confidence: "high"
source: "earned"
tools:
  - name: "view"
    description: "Inspect helper functions that trim or render project-relative paths"
    when: "When auditing PowerShell scripts for cross-platform path display bugs"
  - name: "powershell"
    description: "Run focused integration scripts after helper changes"
    when: "When validating Windows regressions while repairing Linux/macOS path handling"
---

## Context
Use this when a PowerShell CLI renders project-relative file references for humans or downstream tools and the code was originally written with Windows-only separator assumptions.

## Patterns
- Trim both \ and / when removing trailing root separators or leading relative separators.
- For URI-based relative-path helpers, append the current platform directory separator when building the base URI.
- Only translate / back to \ on Windows; keep Linux/macOS outputs in forward-slash form.
- Add regression coverage that checks both slash styles explicitly and blocks absolute-looking /.specrew/... bootstrap references from reappearing.

## Examples
- scripts\specrew-start.ps1: Get-DisplayPathFromProjectRoot now delegates to a helper that trims both separator styles before removing the root prefix.
- scripts\specrew-review.ps1: Get-RelativePath now keeps / on Linux/macOS instead of forcing \.
- tests\integration\start-command.ps1: load the helper definitions and assert that /repo/project/.specrew/... renders as .specrew/..., not /.specrew/....

## Anti-Patterns
- Calling .TrimEnd('\') or .TrimStart('\') in code that must also run on Linux/macOS.
- Replacing / with \ unconditionally after MakeRelativeUri.
- Relying only on Windows end-to-end output when the bug class is separator-sensitive.

