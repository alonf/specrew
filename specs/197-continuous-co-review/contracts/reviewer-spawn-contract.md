# Reviewer Spawn Contract

## Purpose

Defines the host-neutral headless-floor adapter contract for Proposal 197 Iteration 001. Adapters translate one `ReviewRequest` bundle into one fresh reviewer process and return either valid `FindingsResult` stdout JSON or deterministic `InfrastructureFailure` evidence.

## Supported headless floor

| Adapter ID | Host command floor | Planned reviewer-domain filename |
| --- | --- | --- |
| `claude-prompt` | `claude -p` | `reviewer-host-adapter-claude-prompt.ps1` |
| `codex-exec` | `codex exec` | `reviewer-host-adapter-codex-exec.ps1` |
| `copilot-prompt` | `copilot -p` | `reviewer-host-adapter-copilot-prompt.ps1` |
| `cursor-agent-prompt` | `cursor-agent -p` | `reviewer-host-adapter-cursor-agent-prompt.ps1` |
| `antigravity-prompt` | `antigravity -p` | `reviewer-host-adapter-antigravity-prompt.ps1` |

Do not name any Proposal 197 reviewer file `provider-adapter.ps1` or reuse ambiguous F-184 provider-file names.

## Adapter input

- Path/reference to immutable per-run ReviewRequest bundle.
- Explicit provider/model request and authorization reference.
- Timeout.
- Working-directory/ref policy.
- Output schema request: `FindingsResult.v1`.

## Adapter output

- Valid stdout JSON matching `findings-result.schema.json`; or
- Structured `InfrastructureFailure` category for missing provider, unauthorized provider/model, unavailable requested model, timeout, nonzero exit, empty stdout, invalid JSON, schema mismatch, command invocation failure, or fallback exhaustion.

## Rules

- Use safe argument arrays or equivalent APIs; do not concatenate untrusted shell strings.
- Spawn one fresh reviewer process per attempt.
- Reviewer is read-only by contract and must not edit source files, stage commits, push, or mutate Specrew state.
- Do not persist raw prompts, raw provider transcripts, full stdout/stderr, credentials, tokens, environment variables, token stores, unrelated private config, or secret values by default.
- Availability fallback is at most one pre-authorized alternate and must record requested and actual host/model.
- Runtime review must not depend on live web search.
- A no-reviewable-diff checkpoint must not spawn a reviewer; it writes `ReviewRunSkipped` and pass/no-op `GateVerdict`.
