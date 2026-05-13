---
name: "powershell-gnu-flag-binding"
description: "Make PowerShell script CLIs honor GNU-style --flags consistently across pwsh and Windows PowerShell hosts"
domain: "cli-design"
confidence: "high"
source: "earned"
tools:
  - name: "powershell"
    description: "Exercise script invocations through both direct execution and Windows PowerShell -File"
    when: "When a PowerShell script advertises GNU-style flags and behaves differently by host"
  - name: "view"
    description: "Inspect the param block and any fallback argument parser"
    when: "When deciding whether aliases or parser changes are the narrowest fix"
---

## Context
Use this when a PowerShell script exposes a GNU-style `--*` surface but must still run correctly under both `pwsh` and Windows PowerShell, including `powershell -File script.ps1`.

## Patterns
- Keep `[CmdletBinding(PositionalBinding = $false)]` on the script entry point.
- Add hyphenated `[Alias()]` names for options that PowerShell will not bind natively from `--flag value` forms (for example `dry-run`, `project-path`, `no-agents`).
- Retain an explicit remaining-arguments parser for `--flag=value` forms and for host/version combinations that still pass GNU-style tokens through unbound.
- Validate both direct invocation (`& .\script.ps1 --flag`) and Windows PowerShell `-File` invocation because their binding behavior differs.

## Examples
- `--dry-run --project-path C:\Work\Demo` binds through aliases under Windows PowerShell `-File`.
- `--agents=all` continues to flow through the explicit remaining-arguments parser.
- `scripts\specrew-init.ps1` combines aliases plus `ValueFromRemainingArguments` to cover both forms without rewriting the bootstrap flow.

## Anti-Patterns
- Replacing the whole param block with manual string parsing when only a few hyphenated aliases are missing.
- Assuming `pwsh` and Windows PowerShell treat `--flag value` the same way.
- Dropping the fallback parser after adding aliases; that breaks `--flag=value` forms PowerShell still leaves unbound.
