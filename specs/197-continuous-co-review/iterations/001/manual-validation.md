# Manual Real-Host Validation: Iteration 001

**Schema**: v1
**Feature**: 197-continuous-co-review
**Iteration**: 001
**Purpose**: Maintainer-performed real-host acceptance for SC-012 before feature closeout. This is not automated live cross-host CI; Proposal 181 plus Proposal 194 own that future lane. Iteration 002 repairs this runbook so validation uses the implemented orchestrator/prompt-composer path and never a handwritten common prompt.

## Prerequisites

- Work in a clean checkout of this feature branch with the development tree module loaded:
  `Import-Module 'C:\Dev\197-continuous-co-review\Specrew.psd1' -Force`
- Set the self-host path for this repository:
  `$env:SPECREW_MODULE_PATH='C:\Dev\197-continuous-co-review'`
- Install and authenticate only the host CLI being tested.
- Use the planted fixture at:
  `file:///C:/Dev/197-continuous-co-review/specs/197-continuous-co-review/iterations/001/planted-design-violation.diff`
- Ensure Iteration 002 reviewer-definition repair is present: `scripts/internal/continuous-co-review/code-review-agent.md`, `ReviewRequest.v2`, and the prompt composer that injects the canonical instruction into the adapter-bound prompt.
- Expected result for every available host: a parseable blocking finding that names the violated design decision: "reviewer host behavior must be reached through the reviewer-host-adapter interface, not direct host-condition branching."

## Per-Host Commands

These commands are maintainer-run only. They keep automated live cross-host CI out of Iteration 001 scope and exercise each real host through the same implemented orchestrator/prompt-composer path. Do **not** paste a handwritten prompt into `claude -p`, `codex exec`, `copilot -p`, `cursor-agent -p`, or `antigravity -p`; the host adapter must receive the composed prompt generated from `ReviewRequest.v2` and `code-review-agent.md`.

Use this command shape after replacing `<host>` with the row-specific host value and setting `<baseline-ref>` to the checkpoint baseline that makes the planted diff reviewable:

```powershell
Import-Module 'C:\Dev\197-continuous-co-review\Specrew.psd1' -Force
. 'C:\Dev\197-continuous-co-review\scripts\internal\continuous-co-review\_load.ps1'

$providerRequest = [pscustomobject]@{
  requested_host    = '<host>'
  requested_model   = $null
  authorization_ref = 'manual-sc-012'
  timeout_seconds   = 120
  fallback_policy   = 'none'
}

Invoke-ContinuousCoReviewCheckpointReview `
  -RepoRoot 'C:\Dev\197-continuous-co-review' `
  -CheckpointId 'manual-sc-012' `
  -BaselineRef '<baseline-ref>' `
  -RunId "manual-sc-012-<host>" `
  -ProviderRequest $providerRequest `
  -DesignContextRefs @(
    'specs/197-continuous-co-review/spec.md',
    'specs/197-continuous-co-review/implementation-rules.yml',
    'specs/197-continuous-co-review/iterations/001/design-analysis.md'
  ) `
  -SchemaRoot 'C:\Dev\197-continuous-co-review\specs\197-continuous-co-review\contracts' `
  -RunRoot 'C:\Dev\197-continuous-co-review\.specrew\review\tmp'
```

The orchestrator must build `ReviewRequest.v2`, compose the prompt with `scripts/internal/continuous-co-review/code-review-agent.md`, exact change-set content, design-context content, round number, prior findings, visibility policy, do-policy, and output contract `FindingsResult.v1`, then invoke the matching transport-only adapter.

| Host | CLI version command | Exact validation command |
| ---- | ------------------- | ------------------------ |
| Claude | `claude --version` | Use the orchestrator command shape with `<host>` = `claude` and adapter `reviewer-host-adapter-claude-prompt`; the adapter performs `claude -p` with the composed prompt. |
| Codex | `codex --version` | Use the orchestrator command shape with `<host>` = `codex` and adapter `reviewer-host-adapter-codex-exec`; the adapter performs `codex exec` with the composed prompt. |
| Copilot | `copilot --version` | Use the orchestrator command shape with `<host>` = `copilot` and adapter `reviewer-host-adapter-copilot-prompt`; the adapter performs `copilot -p` with the composed prompt. |
| Cursor | `cursor-agent --version` | Use the orchestrator command shape with `<host>` = `cursor` and adapter `reviewer-host-adapter-cursor-agent-prompt`; the adapter performs `cursor-agent -p` with the composed prompt. |
| Antigravity | `antigravity --version` | Use the orchestrator command shape with `<host>` = `antigravity` and adapter `reviewer-host-adapter-antigravity-prompt`; the adapter performs `antigravity -p` with the composed prompt. |

## Pass/Fail Rule

Pass only when the host returns a valid `FindingsResult` with at least one unresolved `blocking` finding that names the violated design decision. A crash, empty output, malformed output, infrastructure failure, or non-finding result is recorded as fail or not-run with notes.

## Results Table

| Host | CLI Version | Result | Finding ID / Evidence | Notes | Date |
| ---- | ----------- | ------ | --------------------- | ----- | ---- |
| Claude | | | | | |
| Codex | | | | | |
| Copilot | | | | | |
| Cursor | | | | | |
| Antigravity | | | | | |
