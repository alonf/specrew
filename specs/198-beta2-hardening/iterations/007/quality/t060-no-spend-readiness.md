# T060 Live-Smoke Readiness and Evidence

**Schema**: v1
**Task**: T060
**Status**: in progress — Windows and WSL Linux are provisioned; local-macOS native preflight passed and run 1 returned valid partial evidence under correction
**Evidence Date**: 2026-07-17
**Readiness Baseline Commit**: `55cf338a6565ce4a2a846473da5f8f51b29e31fa`
**Mac Run 1 Commit**: `6708bf058b708df1c6b6f7492f46bb856154434a`
**Correction Target**: exact pushed commit containing this correction; supplied in the next local-Mac handoff
**Provider Spend**: one Codex/local-Mac invocation (`run-t060-codex-macos-6708bf05-01`)
**Invocation Authorization**: run 1 exact grant recorded; standing maintainer grant now covers the bounded Mac correction sequence only

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

## macOS Readiness and Run 1

The hosted-provider workflow and GitHub Actions credential-secret plan are dropped. T059's successful GitHub-hosted macOS process-group/fake-provider proof remains deterministic evidence only; T060 evidence is honestly labeled `local-machine`.

Native-Terminal preflight passed on macOS 15.5 x64 at exact commit `6708bf058b708df1c6b6f7492f46bb856154434a` and canonical digest `f668677ff652e84f7a05c81964d1a14721a39131`. Codex CLI `0.144.5` was authenticated/file-primary ready, the macOS process-group runtime was ready, the tree was clean, and `provider_invoked` was false. A prior preflight executed inside Codex's own command sandbox failed membership; it spent no review slot and is not native-runtime evidence.

The separately authorized run `run-t060-codex-macos-6708bf05-01` used authorization reference `human-grant-t060-codex-macos-20260717-slot-1`. It invoked exactly once, completed in 101491 ms, verified containment and termination, remained current and clean at the same commit/digest, and published a schema-valid terminal result. The returned package ZIP SHA-256 is `6bcacd8ebd51253821132af718f6165cb650ec4b5be246e3089e3deaeb8e903f`.

Run 1 is immutable valid partial evidence, not a clean smoke and not support promotion:

- major `finding-d36b4c66cb3c1e56`: the returned-package validator trusted mutually agreeing manifest/preflight/result digests instead of independently recomputing the pinned checkout;
- note `finding-8d4f2649e461481c`: campaign auto-resolution produced `DESIGN_CONTEXT_EMPTY` because ignored session files were absent and the selector did not use the command's explicit feature identity.

The bounded correction makes the clean pinned repository an explicit validator input, verifies its origin and exact `HEAD`, independently recomputes the canonical reviewed-state digest, and compares it with every returned authority surface. The campaign selector now resolves context from validated `FeatureId` before mutable-session fallbacks, including the latest available design analysis rather than only the newest iteration directory. A self-consistent forged-digest fixture now fails closed, and a clean multi-feature repository resolves only the requested feature. Focused paired suites pass 21/21, the context suite passes 18/18 with one expected case-sensitive-platform skip, and all 55 registered F-198 suites pass in 569.4 seconds. The correction commit/push and new live Mac rerun remain pending.

After run 1, the maintainer granted all authority needed to finish the Mac tests. This is a scoped standing grant for the Mac correction sequence: each attempt must still have a fresh run ID and recorded reference, invoke once, never retry secretly, and preserve every prior result. It does not authorize the other harness slots.

## Proposed Five-Run Allocation

| Order | Task | Platform | Harness | Rationale | Authorization state |
| --- | --- | --- | --- | --- | --- |
| 1 | T060 | Windows | Cursor | already installed, authenticated, and accepted by the bounded Windows shim resolver | not granted |
| 2 | T060 | Windows | Antigravity | already installed, authenticated, native, and model-list probed | not granted |
| 3 | T060 | Linux | Copilot | native CLI plus PowerShell and transient delegated cgroup production preflight are ready | not granted |
| 4 | T060 | macOS | Codex | native preflight passed; run 1 is valid partial and the bounded correction sequence has standing authority | correction rerun pending |
| 5 | T061 | Windows | Claude | strongest installed reviewer independent of the Codex code-writer; reserved for exact-digest signoff | not granted |

The non-Mac sequence remains execution planning, not a grant. The maintainer's later standing instruction supersedes the per-reply requirement only for finishing the Mac correction sequence; unique run identity, recorded authority, serialization, and no-hidden-retry remain mandatory.

## Current Decision

Commit and push the deterministically verified run-1 corrections, then run one native local-Mac correction attempt with a fresh run ID under the standing scoped grant. No hosted-macOS provider workflow or GitHub Actions credential secret is part of T060.
