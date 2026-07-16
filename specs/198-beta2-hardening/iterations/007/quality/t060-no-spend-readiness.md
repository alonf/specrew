# T060 No-Spend Live-Smoke Readiness

**Schema**: v1
**Task**: T060
**Status**: in progress — discovery complete; Linux and macOS provisioning remain prerequisites
**Evidence Date**: 2026-07-17
**Target Commit**: `55cf338a6565ce4a2a846473da5f8f51b29e31fa`
**Provider Spend**: zero
**Invocation Authorization**: none

## Safety Boundary

These checks used command resolution, production preflight functions, version/status/help commands, the Antigravity model-list command, GitHub runner metadata, and secret/runner-name metadata only. No review prompt was submitted, no candidate result was requested, no campaign grant or spend fact was created, and no provider invocation occurred. Authentication output was reduced to non-secret readiness facts; email, organization, and credential values were not persisted.

## Windows Readiness

The production Windows runtime preflight returned `windows-job-object-runtime-ready`. Every cataloged harness passed its file-primary preflight and resolved through the production Windows launch resolver.

| Harness | Version/readiness evidence | Production launch | Auth readiness |
| --- | --- | --- | --- |
| Claude | Claude Code `2.1.210`; file-primary preflight passed | native executable | logged in through `claude.ai`, Max subscription |
| Codex | Codex CLI `0.144.4`; file-primary preflight passed | native executable | `codex login status` reports ChatGPT login |
| Copilot | GitHub Copilot CLI `1.0.71`; file-primary preflight passed | native executable | local credential directory exists; this CLI exposes login but no read-only status command |
| Cursor | Cursor Agent `2026.06.15-18-00-12-6f5a2cf`; file-primary preflight passed | bounded PowerShell shim accepted by the production resolver | `cursor-agent status` reports logged in; identity was redacted |
| Antigravity | Antigravity `1.1.1`; file-primary preflight passed; `agy models` returned the available model list | native executable | model-list probe succeeded |

Windows is ready for a separately authorized live slot. This does not choose a harness or grant an invocation.

## Linux Readiness

Two WSL distributions contain complementary pieces but neither is currently live-ready as a complete production host.

| Distribution | PowerShell | Native harness | Runtime | Decision |
| --- | --- | --- | --- | --- |
| Ubuntu | `/usr/bin/pwsh` present | none. The inherited Windows Copilot shell wrapper exits `127` because native `node` is absent | cgroup v2 exists but its root is not user-writable | unavailable |
| Ubuntu 24.04 | missing | native Copilot CLI `1.0.27`; local credential directory present | cgroup v2 exists but its root is not user-writable | provisionable, not ready |

The minimal Linux prerequisite is to install PowerShell in Ubuntu 24.04 and create one bounded, run-owned cgroup-v2 root through a root bootstrap, then execute the review as the ordinary user and remove the cgroup root afterward. The Microsoft package source is configured, but installation and cgroup bootstrap were not authorized by the no-spend discovery grant and were not performed.

## macOS Readiness

- GitHub-hosted `macos-latest` is real and its production process-group runtime passed T059 twice.
- GitHub's current macOS 15 and macOS 26 image inventories include PowerShell/Pester but do not list Claude, Codex, Copilot, Cursor, or Antigravity as installed tools.
- Repository runner metadata reports zero self-hosted runners.
- Repository Actions secret metadata contains no provider-specific credential such as `OPENAI_API_KEY`, `CODEX_ACCESS_TOKEN`, `ANTHROPIC_API_KEY`, or `COPILOT_GITHUB_TOKEN`. Secret values were never read.

The minimal macOS prerequisite is therefore a bounded workflow that installs one cataloged CLI on the hosted runner and receives its credential through a dedicated GitHub Actions secret. The recommended allocation uses Codex on macOS so Claude remains available as the independent final reviewer. Installing the CLI, adding/using a credential, and invoking it all require authority beyond this discovery grant; the provider invocation still needs its own separate slot grant.

Official runner inventories consulted:

- https://github.com/actions/runner-images/blob/main/images/macos/macos-15-Readme.md
- https://github.com/actions/runner-images/blob/main/images/macos/macos-26-Readme.md

## Proposed Five-Run Allocation

| Order | Task | Platform | Harness | Rationale | Authorization state |
| --- | --- | --- | --- | --- | --- |
| 1 | T060 | Windows | Cursor | already installed, authenticated, and accepted by the bounded Windows shim resolver | not granted |
| 2 | T060 | Windows | Antigravity | already installed, authenticated, native, and model-list probed | not granted |
| 3 | T060 | Linux | Copilot | the only native Linux harness currently present; requires PowerShell/cgroup provisioning first | not granted |
| 4 | T060 | macOS | Codex | officially installable on hosted macOS; same-host evidence is allowed but labeled weaker | not granted |
| 5 | T061 | Windows | Claude | strongest installed reviewer independent of the Codex code-writer; reserved for exact-digest signoff | not granted |

The sequence is proposed execution planning, not a grant. Each row requires a fresh explicit human authorization immediately before the provider invocation. A finding, invalid result, timeout, or other post-invocation failure stops the sequence; no hidden retry or automatic correction is allowed.

## Current Decision

Do not spend a provider slot yet. Provision and re-run no-spend preflight for Linux and macOS first, commit the campaign execution surface, then request the first explicit provider slot against that exact committed digest.
