# T060 No-Spend Live-Smoke Readiness

**Schema**: v1
**Task**: T060
**Status**: in progress — Windows and WSL Linux are provisioned; local-macOS package prepared but not executed
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

Ubuntu 24.04 is now ready for a separately authorized Copilot smoke. PowerShell `7.6.3` was installed from Microsoft's Ubuntu 24.04 product repository; native Copilot remains `GitHub Copilot CLI 1.0.27`. No model was invoked.

The temporary cgroup delegation uses a transient systemd service, not a persistent globally writable cgroup root:

```text
wsl.exe -d Ubuntu-24.04 -u root -e systemd-run --quiet --wait --collect --pipe --uid=alon \
  --property=Delegate=yes --property=Type=exec \
  --setenv=HOME=/home/alon \
  --setenv=PATH=/home/alon/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
  pwsh <bounded T060 command>
```

Inside that service, systemd owns the parent boundary and delegates its cgroup subtree to the ordinary user. The production no-spend preflight created and removed its bounded child cgroup and returned:

```json
{
  "platform": "linux",
  "user": "alon",
  "pwsh": "7.6.3",
  "copilot": "GitHub Copilot CLI 1.0.27.",
  "harness_id": "copilot-cli-file-primary",
  "harness_ok": true,
  "harness_reason": "copilot-file-primary-ready",
  "runtime_id": "linux-cgroup-v2-runtime",
  "runtime_ok": true,
  "runtime_reason": "linux-cgroup-v2-runtime-ready"
}
```

The transient unit was collected after the command. A future live run still requires its own explicit provider slot and must use the same bounded systemd delegation.

## macOS Readiness

The hosted-provider workflow and GitHub Actions credential-secret plan are dropped. T059's successful GitHub-hosted macOS process-group/fake-provider proof remains deterministic evidence only.

T060 now supplies a local-machine package at `scripts/t060-local-macos-smoke.ps1`, a strict returned-package validator at `scripts/validate-t060-local-macos-evidence.ps1`, and exact setup/handoff instructions at `docs/operations/t060-local-macos-smoke.md`. The package:

- requires a clean detached clone at the handoff's exact 40-character commit;
- verifies the public origin URL, canonical reviewed-state digest, Codex CLI/auth status, file-primary harness, and real macOS process-group runtime before spend;
- separates `Preflight` from an explicitly acknowledged `Invoke` mode;
- invokes the synchronous production campaign command at most once with the human-provided run ID and authorization reference;
- labels evidence `local-machine`, preserves the append-only grant/reservation/spend/result store, and hashes the copied preflight/result/report/progress artifacts; and
- accepts valid findings evidence without misreporting it as a clean smoke.

The package has not run on the Mac and therefore promotes no macOS live support. Its preflight and its later one-provider invocation are separate actions; the current grant authorizes neither provider use nor a retry.

The five-case package/validator fixture suite passes valid-pass, valid-findings, tampered-result, false hosted-source/wrong-commit, and single-deliberate-call cases. The complete explicit F-198 registry passes all 55 suites in 603.2 seconds. These are deterministic no-provider tests, not a Mac execution claim.

## Proposed Five-Run Allocation

| Order | Task | Platform | Harness | Rationale | Authorization state |
| --- | --- | --- | --- | --- | --- |
| 1 | T060 | Windows | Cursor | already installed, authenticated, and accepted by the bounded Windows shim resolver | not granted |
| 2 | T060 | Windows | Antigravity | already installed, authenticated, native, and model-list probed | not granted |
| 3 | T060 | Linux | Copilot | native CLI plus PowerShell and transient delegated cgroup production preflight are ready | not granted |
| 4 | T060 | macOS | Codex | run on the maintainer's local Mac; package/validator are prepared and source is labeled `local-machine` | not granted |
| 5 | T061 | Windows | Claude | strongest installed reviewer independent of the Codex code-writer; reserved for exact-digest signoff | not granted |

The sequence is proposed execution planning, not a grant. Each row requires a fresh explicit human authorization immediately before the provider invocation. A finding, invalid result, timeout, or other post-invocation failure stops the sequence; no hidden retry or automatic correction is allowed.

## Current Decision

Do not spend a provider slot yet. Commit and push this provisioning surface, run the package's no-spend preflight on the local Mac, then request the first explicit provider slot against the exact committed digest. No hosted-macOS provider workflow or GitHub Actions credential secret is part of T060.
