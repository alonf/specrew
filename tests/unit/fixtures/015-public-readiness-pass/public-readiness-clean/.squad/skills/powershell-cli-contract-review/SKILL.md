---
name: "powershell-cli-contract-review"
description: "Review standalone PowerShell CLIs against their documented flag surface and interactive contract"
domain: "review"
confidence: "high"
source: "earned"
tools:
  - name: "powershell"
    description: "Run the script through both documented and PowerShell-native invocation surfaces"
    when: "When a PowerShell bootstrap script advertises GNU-style flags or interactive prompts"
  - name: "rg"
    description: "Verify required probes and banned concerns are present or absent in code"
    when: "When checking requirement traceability for a CLI implementation"
---

## Context
Use this when reviewing a standalone PowerShell script that is presented as a contract-facing CLI. These reviews fail easily when the implementation only works via PowerShell-native switches while the documented `--flag` surface, prompt wording, or required probes are unverified.

## Patterns
- Validate the exact documented invocation first (for example `.\script.ps1 --dry-run`) before accepting equivalent PowerShell-native forms such as `-DryRun`.
- For advanced scripts that support GNU-style flags, set `CmdletBinding(PositionalBinding = $false)` and parse `ValueFromRemainingArguments` explicitly so `--flag` tokens cannot misbind into typed positional parameters.
- Capture a live interactive transcript and compare it to the contract fields, not just to the existence of `Read-Host`.
- Prove GNU-style `--flag` support through the exact live script surface (`& .\script.ps1 --flag ...` from PowerShell), not only through nested harnesses or equivalent helper wrappers. Those wrappers can mask that the advertised surface still ignores `--*` arguments.
- Search the implementation for each required external probe/API call; a missing mandated probe is a material gap even if adjacent probes succeed.
- Separate graceful degradation from completeness: a fallback path can be correct while the overall slice still fails for missing contract behavior.
- Confirm banned concerns (billing, cost, routing) are absent with direct code search instead of inference.

## Examples
- `scripts\specrew-init.ps1` accepted `-DryRun` but `--dry-run` misbound as `SpecKitVersion`; that is a contract failure on the advertised standalone surface.
- `scripts\specrew-init.ps1` needed both `PositionalBinding = $false` and explicit `CliArgs` parsing so `--dry-run --project-path <dir>` worked on the advertised standalone surface without breaking PowerShell-native switches.
- A re-review must re-run the exact contract surface after a parser fix; in this repo, code that looked correct still left `& .\scripts\specrew-init.ps1 --dry-run --force --project-path <dir>` prompting interactively and targeting the current directory.
- The FR-022 consent prompt showed agent name plus access path, but omitted availability even though availability was required in the prompt contract.
- A delegated-agent probe based on `copilot help config` degraded correctly when unavailable, but the missing `gh api /user` probe still blocked acceptance.

## Anti-Patterns
- Passing a script because the logic works when invoked with internal or shell-specific syntax the contract never promised.
- Treating persistence or summary output as proof that the interactive consent display matched the requirement.
- Assuming required probes exist because related detection code is nearby.
