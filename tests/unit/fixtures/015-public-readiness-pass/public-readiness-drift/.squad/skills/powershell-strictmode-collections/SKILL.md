---
name: "powershell-strictmode-collections"
description: "Keep PowerShell validators stable under Set-StrictMode by normalizing empty and singleton outputs to arrays before Count checks"
domain: "powershell"
confidence: "high"
source: "earned"
tools:
  - name: "view"
    description: "Inspect helper functions and Count-based call sites in the script"
    when: "When a validator crashes on missing Count or singleton pipeline output"
  - name: "rg"
    description: "Find Count usage and collection-producing helpers quickly"
    when: "When auditing a script for strict-mode collection hazards"
  - name: "powershell"
    description: "Reproduce the crash and verify the fix against real inputs"
    when: "When proving the validator now reports real failures instead of throwing"
---

## Context

Use this when a PowerShell script runs with `Set-StrictMode -Version Latest` and accesses `.Count` on values that may come from empty pipelines, optional file reads, or single parsed rows.

## Patterns

- Return arrays from collection helpers (`@(Get-Content ...)`, object arrays from table parsers, array-wrapped target lists).
- Wrap `if (...) { ... } else { @() }` expressions in an outer array subexpression before later `.Count` checks.
- Normalize final pipeline outputs before iterating or indexing if zero/one/many items are all valid states.
- Preserve validation logic; only fix shape/typing so real contract failures still surface.

## Examples

- Optional artifact read: `$reviewLines = @(if (Test-Path $reviewPath) { Get-MarkdownContent -Path $reviewPath } else { @() })`
- Parsed table rows: return `$rows.ToArray()` instead of a generic list object
- Final collection: `$results = @($targets | ForEach-Object { ... })`

## Anti-Patterns

- Relying on implicit pipeline unrolling when later code expects `.Count`
- Silencing the check just to avoid the crash
- Treating a planning iteration's missing optional artifacts as a reason to relax governance rules
