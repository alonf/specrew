---
name: "powershell-cli-review"
description: "How to review contract-facing PowerShell CLIs that advertise GNU-style --flags"
domain: "review"
confidence: "high"
source: "earned"
tools:
  - name: "powershell"
    description: "Run live PowerShell invocations and capture real script behavior"
    when: "When a PowerShell script's documented CLI surface must be verified against runtime behavior"
---

## Context
Use this when a standalone PowerShell script documents GNU-style `--flag` arguments. The acceptance question is not whether aliases or parser code look plausible, but whether live invocation binds the documented surface without prompting or silently falling back to defaults.

## Patterns
- Test the exact advertised direct form: `& .\script.ps1 --flag ...`.
- Also test `powershell -NoProfile -File .\script.ps1 --flag ...` when Windows PowerShell host behavior matters.
- Capture output as text with nested PowerShell plus `Out-String` so summary tables can be searched reliably.
- Verify four conditions together: exit code, requested path echoed in output, no fallback default path, and no interactive prompt text.
- For `--dry-run`, confirm the requested target directory still does not exist after the run.

## Examples
- `& .\scripts\specrew-init.ps1 --dry-run --force --project-path C:\Repo\review-target`
- `powershell -NoProfile -File .\scripts\specrew-init.ps1 --dry-run --force --project-path C:\Repo\review-target`

## Anti-Patterns
- Trusting parameter aliases or fallback-parser code without a live invocation.
- Validating only PowerShell-native switches (for example `-DryRun`) when the contract advertises `--dry-run`.
- Calling a dry-run successful when it quietly targeted the current working directory instead of the requested path.
