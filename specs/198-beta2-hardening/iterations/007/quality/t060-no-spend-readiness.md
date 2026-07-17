# T060 Live-Smoke Readiness and Evidence

**Schema**: v1
**Task**: T060
**Status**: in progress — local-macOS Codex proof is clean; Windows and WSL Linux remain provisioned for the three unspent T060 harnesses
**Evidence Date**: 2026-07-17
**Readiness Baseline Commit**: `55cf338a6565ce4a2a846473da5f8f51b29e31fa`
**Mac Run 1 Commit**: `6708bf058b708df1c6b6f7492f46bb856154434a`
**Correction Target**: `b1ae8b47aece4e0f4a017dc1e8896708fc2c8700`
**Mac Run 2 Digest**: `7dcc6b4da0bf006f24b7c8fa5ed08c56fa42704c`
**Provider Spend**: two Codex/local-Mac invocations (immutable partial run 1; clean correction run 2)
**Invocation Authorization**: the bounded standing Mac grant is fulfilled; the later minimum-budget standing authority covers one required base proof for each remaining harness

## No-spend Readiness Boundary

The readiness checks used command resolution, production preflight functions, version/status/help commands, the Antigravity model-list command, GitHub runner metadata, and secret/runner-name metadata only. Those checks did not invoke providers. The two separately identified Mac live runs are recorded below. Authentication output was reduced to non-secret readiness facts; email, organization, and credential values were not persisted.

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

Correction run `run-t060-codex-macos-b1ae8b47-02` used authorization reference `standing-mac-grant-20260717-attempt-02` against exact commit `b1ae8b47aece4e0f4a017dc1e8896708fc2c8700` and digest `7dcc6b4da0bf006f24b7c8fa5ed08c56fa42704c`. It invoked exactly once, completed in 210898 ms, and returned complete/pass/current/valid evidence with verified containment/termination and zero findings. Independent validation exited `0` with `package_valid=true`, `smoke_clean=true`, and no errors. The invoke exited `0`; the ZIP SHA-256 is `9e359c121ffae46bb24ed8761749a11492a7d58adad4591f43a3e703d6d09351`. The Mac proof is complete, and run 1 remains immutable partial evidence.

## Windows Cursor Attempts 01–02 — No Provider Spend

At commit `f1e69d0a9f1b32237ec56ba24d596b67bddc86fe` and canonical digest `51d677696810999d09179ba726f7aae425e680c1`, both Windows harness/runtime preflights and the Linux delegated-cgroup preflight passed with `provider_invoked=false`. Authorized run `run-t060-cursor-windows-f1e69d0a-01` then failed before provider invocation while the production target port checked out a deeply nested tracked fixture beneath its default Windows temp prefix. The controller published `preflight-failed`, released the reservation, retained result/report authority, and recorded zero spend facts; Cursor free credit was not consumed.

The first correction used short sibling `.t060-targets` and `.t060-staging` roots and exposed the generated report path for every pre-invocation terminal result. It passed 66 focused tests, all 56 registered F-198 suites, scoped governance, CI, and new exact-commit Windows/Linux no-spend preflights.

Standing-authority attempt `run-t060-cursor-windows-7089edcf-02` at commit `7089edcffc742b3479a2e52df1be534e52e571ee` and digest `f6b9dbf1a6bcad4957b2ab6adac8d9d060ce736d` nevertheless stopped before provider invocation: the actual longest tracked path still reached 265 characters because the disposable directory leaf retained the full run ID. The improved package preserved manifest/result/report/progress, released the reservation, and recorded zero spend facts. Attempt 02 consumed no Cursor free credit.

The definitive `DRIFT-198-I007-003` correction retains the short roots and replaces the run-ID-sized disposable leaf with a stable 16-hex-character token, while retaining the complete run ID in immutable authority metadata. The deterministic boundary test reads the actual longest tracked path from `HEAD` and proves the bounded leaf remains below 260 characters. All 93 focused target/runtime/harness tests pass, followed by all 56 registered F-198 suites in 626.3 seconds and scoped Iteration 007 governance with historical warnings only. CI and a fresh exact-commit three-platform preflight are required before attempt 03.

After this no-spend failure, the maintainer authorized all remaining requirements subject to the minimum required budget. This standing authority covers one successful required base proof per remaining harness, each with a unique run ID and authorization reference. It does not cover speculative probes, duplicate clean reviews, or hidden retries; any non-clean result stops the serialized sequence.

## Proposed Five-Run Allocation

| Order | Task | Platform | Harness | Rationale | Authorization state |
| --- | --- | --- | --- | --- | --- |
| 1 | T060 | Windows | Cursor | Free/Auto completed a current review; three findings corrected locally | corrected run 06 authorized after no-spend gates |
| 2 | T060 | Windows | Antigravity | already installed, authenticated, native, and model-list probed | one base attempt covered by minimum-budget standing authority |
| 3 | T060 | Linux | Copilot | native CLI plus PowerShell and transient delegated cgroup production preflight are ready | one base attempt covered by minimum-budget standing authority |
| 4 | T060 | macOS | Codex | clean correction run 2 at exact commit/digest; run 1 preserved as partial evidence | complete |
| 5 | T061 | Windows | Claude | strongest installed reviewer independent of the Codex code-writer; reserved for exact-digest signoff | one base attempt covered by minimum-budget standing authority |

The standing Mac instruction is fulfilled. The later minimum-budget authority covers only the required remaining base sequence; unique run identity, recorded authority, serialization, and no-hidden-retry remain mandatory.

## Windows Cursor Attempt 03 — Invoked, Incomplete

At commit `c3b48c00382500e937ef370aaff8f0ee67efa768` and digest `ca94546d9dcd86b61af25597f887c776125fe268`, CI run `29585675046` and all three exact-commit preflights passed without provider use. Standing-authority run `run-t060-cursor-windows-c3b48c00-03` then invoked Cursor exactly once. The target remained clean/current and Job Object containment/termination were verified, but no candidate was produced. The immutable result is `completion=none`, `verdict=incomplete`, `validation=not-produced`, `runtime_outcome=terminated`, `failure_reason=reviewer-process-exit-code:1`, with zero findings.

Cursor's local transcript evidence resolves the opaque exit: all four branches ended with its usage-limit error. The run inherited mutable CLI configuration selecting `Composer 2.5 Fast`, while the package did not record a model. The maintainer reported the dashboard still showed 20% overall included usage remaining, so the evidence supports a selected-pool/request-cost failure rather than proven global account exhaustion.

`DRIFT-198-I007-004` makes a Cursor model explicit and evidence-bearing. The no-spend preflight must find the exact ID in the authenticated account-visible model list; the process receives `--model gpt-5.4-mini-low`; preflight and manifest record it; and the shared prompt prohibits model-backed subagent delegation. This is a lower-cost smoke choice visible to the free account, not a claim that Cursor guarantees it as a free model. Attempt 03 is one spent incomplete invocation and is never retried under its old grant.

## Windows Cursor Attempts 04–05 — Free/Auto Proof and Findings

Commit `11a0129e94ba471da8126b28c19fd875ca0feb87`, digest `fce377ffeb2ed7ff65f9b7cc4389dbefa7e637a3`, passed all local gates, CI run `29588052164`, and exact-commit no-spend preflight. Authorized attempt 04, `run-t060-cursor-windows-11a0129e-04`, selected `gpt-5.4-mini-low` and was rejected immediately by Cursor: Free plans can only use Auto. That result is preserved and was not retried under the same ID or authorization.

A separate no-spend preflight recorded `auto`, after which authorized attempt 05, `run-t060-cursor-windows-11a0129e-05`, invoked exactly once. Cursor completed in 251687 ms, wrote the raw candidate file, preserved clean/current origin identity, and returned valid evidence with verified Job Object containment and termination. It published three current findings: the public campaign path dropped `--model`, the Windows runtime could write its spend fact before checking for Job Object degradation, and ingress did not enforce unique candidate `local_id` values.

`DRIFT-198-I007-005` corrects all three. The public path now carries the model into production-port construction; Windows rejects and reaps degraded containment before `onStarted`; and strict candidate validation rejects duplicate ordinal local IDs. Paired regressions plus adjacent authority/campaign/public/runtime/harness/T060 suites pass 105/105, all 56 F-198 suites pass in 529.8 seconds, and scoped Iteration 007 governance passes with historical warnings only. No provider was invoked. The maintainer authorized these corrections and one remaining Free/Auto run 06 after CI and exact-commit preflight complete the no-spend gates.

## Current Decision

Preserve the clean Mac result and every immutable Cursor attempt. Finish full no-spend correction gates, then spend only authorized Cursor Free/Auto run 06. A clean run advances to the serialized Antigravity/Windows, Copilot/Linux, and T061 Claude proofs; any non-clean result stops. No hosted-macOS provider workflow or GitHub Actions credential secret is part of T060.
