---
name: "powershell-regex-matches-safety"
description: "Protect parsed values from later -match operations by copying PowerShell $Matches groups into local variables immediately."
domain: "powershell"
confidence: "high"
source: "earned"
---

# powershell-regex-matches-safety

## When to Use

- A function parses content with `-match` and then loops over lines with more `-match` calls.
- You need the original capture groups later in the function.

## Pattern

1. Run the outer regex match once.
2. Copy every needed capture group from `$Matches` into local variables immediately.
3. Use those local variables after any later `-match` operations.

## Why

PowerShell reuses the ambient `$Matches` variable for every successful `-match`. If you keep reading `$Matches` after a loop that performs more regex matches, later matches can silently overwrite the original capture groups.

## Example

```powershell
if ($content -match '(?ms)^---\s*\r?\n(.*?)\r?\n---\s*\r?\n?(.*)$') {
    $frontmatterBlock = [string]$Matches[1]
    $bodyContent = [string]$Matches[2]

    foreach ($line in ($frontmatterBlock -split '\r?\n')) {
        if ($line -match '^\s*([^:]+):\s*(.*?)\s*$') {
            # Later matches do not clobber $bodyContent
        }
    }
}
```
