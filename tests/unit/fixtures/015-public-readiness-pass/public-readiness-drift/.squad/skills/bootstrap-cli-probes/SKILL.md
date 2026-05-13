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
- When a Rich/Python CLI only exposes version information through a styled subcommand, set process-local UTF-8 output (`PYTHONIOENCODING=utf-8`) for the probe so redirected capture on Windows does not turn a healthy install into a false `UnicodeEncodeError`.
- If version probes pass but the real bootstrap command still fails on upstream release assets, preflight the exact `init` invocation in a disposable directory and repair from the official upstream source before touching the user workspace.
- For dependency-health fixes, prove three layers separately: a healthy live install, a broken command shim that must still fail clearly, and the truth of any end-to-end bootstrap docs if a downstream bootstrap issue still exists.
- When docs claim a greenfield bootstrap works without `-Force`, require one live non-interactive bootstrap run to complete on a git-only repo; a command that merely launches `specify init` and then waits still counts as a live blocker, not a docs footnote.
- When Copilot runtime detection is needed, prefer the standalone `copilot` CLI surfaces that are actually documented in the current client (`copilot --version`, `copilot help config`) instead of assuming a legacy `gh copilot` extension exists.
- For delegated-agent consent gates, parse documented model metadata from `copilot help config` to infer Claude/Codex family exposure without sending a live model request; if the metadata surface is absent, mark delegated availability unavailable and continue bootstrap.
- Keep bootstrap failures reserved for true missing/incompatible tooling, not probe-noise.
- Validate noisy version behavior with native-command shims (`.exe`/`.cmd`) when the real install path is native, because PowerShell wrapper scripts can surface stderr as PowerShell errors and misrepresent the bootstrap path you are reviewing.

## Examples
- `specify --version` emits `Failed to canonicalize script path` -> read `uv tool list` and parse `specify-cli v0.7.3.dev0`.
- `specify --version` rejects the flag, but `specify version` succeeds when the probe sets `PYTHONIOENCODING=utf-8`; treat that as healthy and reserve `uv tool list` for fallback inventory only.
- `validate-versions.ps1` accepts a live Spec Kit install through `specify version`, but `bootstrap-to-iteration.ps1` still skips because `specify init --integration` fails; the fix is valid only if user docs describe that remaining limitation instead of promising full bootstrap artifact creation.
- `validate-versions.ps1` and its shim tests pass, but `bootstrap-to-iteration.ps1` stalls with `specify init --here --ai copilot --script ps --ignore-agent-tools` still running in a non-interactive git-only repo; reject any guide that says this path "does not require `-Force`" until a live run proves it.
- `specify version` is healthy and `validate-versions.ps1` passes, but a live `specify init --here --ai copilot --script ps --ignore-agent-tools --force` fails with `No matching release asset found for copilot (expected pattern: spec-kit-template-copilot-ps)`; docs must call out that current greenfield bootstrap is still blocked after dependency validation, with an actionable workaround or explicit stop condition.
- `specify version` is healthy, but `specify init --here --ai copilot --script ps --ignore-agent-tools --force` fails with `No matching release asset found for copilot`; run the same init in a disposable probe directory, then repair via `uv tool install --force specify-cli --from git+https://github.com/github/spec-kit.git@v0.8.4` before retrying the real workspace bootstrap.
- `squad init --help` is the real place to discover `--non-interactive`; run it from a disposable probe directory so accidental init output can be cleaned safely.
- In this Windows environment, `squad --help` is side-effectful and starts workspace setup, while `squad init --help` returns the actual init flags. Probe the subcommand, not the top-level CLI.
- In this Windows environment, `gh copilot` is absent but `copilot --version` and `copilot help config` are available. Use the standalone CLI as the bootstrap detection source of truth.

## Anti-Patterns
- Using top-level CLI help to infer subcommand-only flags.
- Aborting bootstrap because a shim printed an unparseable error before exposing version data elsewhere.
- Treating package-manager inventory as proof that a CLI command is healthy when every live command probe still fails.
- Trusting a passing `specify version` check when the real `specify init` path has never been exercised against the currently installed source.
- Declaring a dependency-health slice done while docs still imply end-to-end bootstrap success even though a separate bootstrap command failure is still live.
- Treating "correct flags" as equivalent to "working bootstrap" when the corrected command still blocks on interactivity in the real entrypoint.
- Treating yesterday's disclosed blocker (for example Unicode encoding) as sufficient documentation when today's live failure mode has changed to a confirmation prompt or missing release asset.
- Probing a side-effectful command inside the user's target project just to inspect help text.
- Treating a PowerShell-script stub as equivalent evidence for a native shim failure mode when the installed command surface is actually native.
