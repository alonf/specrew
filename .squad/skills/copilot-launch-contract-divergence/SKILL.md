---
name: "copilot-launch-contract-divergence"
description: "Keep Specrew's Copilot launch flags aligned with platform-specific REPL behavior"
domain: "runtime"
confidence: "high"
source: "earned"
tools:
  - name: "powershell"
    description: "Run the existing start-command integration coverage after changing launch flags or messaging"
    when: "When `scripts\\specrew-start.ps1` changes Copilot CLI argument composition"
  - name: "view"
    description: "Compare launch code, integration assertions, and test evidence"
    when: "When platform-specific runtime behavior must stay documented and testable"
---

## Context
Use this when `specrew start` changes how it launches Copilot across Windows and Linux/macOS. The runtime contract is not symmetric: the same Copilot CLI flags can keep Windows interactive while breaking Linux/macOS, so launch code, user messaging, tests, and evidence must move together.

## Patterns
- Keep `-i` bootstrap auto-load on every platform.
- Keep `--autopilot` behavior unchanged and mutually exclusive with `--mode interactive`.
- On Windows non-autopilot launches, add `--mode interactive`; add `--allow-all` only when explicitly allowed.
- On Linux/macOS non-autopilot launches, pass `--agent`, `--add-dir`, and `-i` without `--mode interactive` or `--allow-all`, and warn users to expect approval prompts for bootstrap file reads.
- When the launch contract changes, update `scripts\\specrew-start.ps1`, `tests\\integration\\start-command.ps1`, and `specs\\019-specrew-distribution-module\\test-evidence\\us5-cross-platform.md` together.

## Examples
- Feature 019 R13: Windows kept `--mode interactive` to hold the REPL open, while Linux/macOS dropped it because Copilot CLI v1.0.48 already defaults the `-i` flow into the REPL there and exits one-shot when `--mode interactive` is added.
- `pwsh -NoProfile -File tests\\integration\\start-command.ps1` is the regression proof for Windows-side launch composition after these changes.

## Anti-Patterns
- Assuming Windows and Linux/macOS need the same `copilot --agent ... -i` flags.
- Changing launch flags without updating runtime messaging and evidence.
- Re-introducing `--allow-all` or `--mode interactive` on Linux/macOS without fresh live evidence that the CLI behavior changed.
