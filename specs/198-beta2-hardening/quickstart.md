# Quickstart: Controlled External Review

**Feature**: 198-beta2-hardening
**Status**: Iteration 007 plan-time acceptance guide
**Last verified**: 2026-07-16 (foundation only)

## Current Safety Rule

The checked-in authority mode is still `legacy`. Do not switch it manually. Iteration 007 changes to `campaign` only after the public command, all five adapters, all three runtime ports, deterministic three-OS proof, and five separately authorized live smokes pass.

## Inspect Available Reviewer Harnesses Without Spending

```powershell
pwsh -NoProfile -File scripts/specrew-review.ps1 --list-hosts
```

This performs discovery/presentation only. It does not reserve or spend a provider slot.

## Verify the Delivered Foundation

```powershell
Invoke-Pester -Path tests/continuous-co-review/unit/review-authority-core.Tests.ps1,
  tests/continuous-co-review/unit/review-authority-store.Tests.ps1,
  tests/continuous-co-review/unit/review-result-ingestor.Tests.ps1,
  tests/continuous-co-review/unit/review-campaign-orchestrator.Tests.ps1
```

Expected at the Iteration 007 baseline: the Iteration 006 authority suite is green, strict ingress rejects prose-wrapped candidate content, and no production-completeness claim is made.

## Iteration 007 Acceptance Scenario

After T060, the public review command must provide this operator flow without adapter-specific authority logic:

1. Select one installed harness and perform cheap target/store/contract/containment/harness/runtime preflight.
2. Require a human grant for exactly one provider invocation and create a new run ID.
3. Freeze an external Git target, keep the origin unchanged, and write the versioned invocation into run-owned staging.
4. Launch the reviewer under the platform runtime controller. The reviewer writes one raw JSON object to the candidate file; stdout is informational only.
5. On timeout, kill the complete descendant tree, verify death and stream closure, then publish a terminal result containing the timeout reason and any valid partial findings.
6. Show stage/heartbeat/timing/currentness information. Findings against a moved target remain advisory and visible; they cannot approve the current tree.
7. Publish controller-owned immutable JSON plus derived Markdown. Only a complete, valid, current, contained, terminated pass can approve.
8. A rerun always uses a new run ID and a separately authorized slot. There is no hidden retry.

## Completion Proof

- One deterministic adapter/failure matrix runs on Windows, Linux, and macOS.
- One paid live smoke runs for each of Claude, Codex, Copilot, Cursor, and Antigravity, distributed so every OS has at least one live run.
- Four harnesses prove the staged public path across all three OSes; the fifth runs after the campaign-mode cutover commit and also serves as exact-digest independent signoff. Failure blocks completion and returns for human authorization.
- Evidence records harness/model, OS, run ID, exact digest, duration, containment, termination, validation, currentness, and result paths.

Generic gate/artifact target adapters are intentionally absent from this quickstart; they remain Beta3 scope.
