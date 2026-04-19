---
name: "bootstrap-cli-probes"
description: "Make bootstrap dependency and capability probes resilient when CLI help/version surfaces are noisy or side-effectful"
domain: "bootstrap"
confidence: "high"
source: "earned"
tools:
  - name: "powershell"
    description: "Simulate failing CLI output and verify cleanup around probe directories"
    when: "When bootstrap scripts depend on CLI --version or --help behavior"
  - name: "view"
    description: "Inspect bootstrap helper functions and cleanup paths"
    when: "When adjusting PowerShell bootstrap probes"
---

## Context
Use this when a bootstrap script decides installability or feature flags by shelling out to external CLIs whose `--version` or `subcommand --help` behavior may vary by shim, installer, or current working directory.

## Patterns
- Prefer the exact command surface you are gating (`tool subcommand --help` for subcommand flags).
- If that probe can mutate the working tree, run it in a disposable repo-local directory and delete the directory afterward.
- Accept the first parseable version line from direct command output, but fall back to package-manager inventory (`uv tool list`, equivalent installers) before declaring detection failure.
- When Copilot runtime detection is needed, prefer the standalone `copilot` CLI surfaces that are actually documented in the current client (`copilot --version`, `copilot help config`) instead of assuming a legacy `gh copilot` extension exists.
- For delegated-agent consent gates, parse documented model metadata from `copilot help config` to infer Claude/Codex family exposure without sending a live model request; if the metadata surface is absent, mark delegated availability unavailable and continue bootstrap.
- Keep bootstrap failures reserved for true missing/incompatible tooling, not probe-noise.
- Validate noisy version behavior with native-command shims (`.exe`/`.cmd`) when the real install path is native, because PowerShell wrapper scripts can surface stderr as PowerShell errors and misrepresent the bootstrap path you are reviewing.

## Examples
- `specify --version` emits `Failed to canonicalize script path` -> read `uv tool list` and parse `specify-cli v0.7.3.dev0`.
- `squad init --help` is the real place to discover `--non-interactive`; run it from a disposable probe directory so accidental init output can be cleaned safely.
- In this Windows environment, `squad --help` is side-effectful and starts workspace setup, while `squad init --help` returns the actual init flags. Probe the subcommand, not the top-level CLI.
- In this Windows environment, `gh copilot` is absent but `copilot --version` and `copilot help config` are available. Use the standalone CLI as the bootstrap detection source of truth.

## Anti-Patterns
- Using top-level CLI help to infer subcommand-only flags.
- Aborting bootstrap because a shim printed an unparseable error before exposing version data elsewhere.
- Probing a side-effectful command inside the user's target project just to inspect help text.
- Treating a PowerShell-script stub as equivalent evidence for a native shim failure mode when the installed command surface is actually native.
