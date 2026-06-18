# Reviewer Spawn Contract

## Purpose

Defines the host-neutral headless-floor adapter contract for Proposal 197. Iteration 001 established the adapter floor. Iteration 002 repairs the send-back by making adapters transport-only: they receive one composed `ReviewPrompt` generated from `ReviewRequest.v2` plus the canonical reviewer instruction file and return either valid `FindingsResult` stdout JSON or deterministic `InfrastructureFailure` evidence.

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

- Path/reference to immutable per-run `ReviewRequest.v2` bundle.
- Path/reference or stdin content for the composed `ReviewPrompt` produced by the prompt composer.
- Explicit provider/model request and authorization reference.
- Timeout.
- Working-directory/ref policy.
- Output schema request: `FindingsResult.v1`.

The composed prompt is the only runtime instruction authority. It MUST include the content/hash of `scripts/internal/continuous-co-review/code-review-agent.md`, design-context content/sources, exact diff/change-set content, round number, prior findings, visibility policy, do-policy, and `FindingsResult.v1` output contract.

## Adapter output

- Valid stdout JSON matching `findings-result.schema.json`; or
- Structured `InfrastructureFailure` category for missing provider, unauthorized provider/model, unavailable requested model, timeout, nonzero exit, empty stdout, invalid JSON, schema mismatch, command invocation failure, or fallback exhaustion.

## Rules

- Use safe argument arrays or equivalent APIs; do not concatenate untrusted shell strings.
- Spawn one fresh reviewer process per attempt.
- Reviewer is read-only by contract and must not edit source files, stage commits, push, or mutate Specrew state.
- Pass supported host read-only/no-write flags or equivalent controls where available, and record when a host has no supported flag.
- Run the uniform source/Git/Specrew mutation guard around invocation; any mutation invalidates the run as unsafe.
- Adapters are transport-only. They must not own Proposal 145 rubric text, workshop-decision policy wording, prior-finding semantics, durable writes, gate verdicts, or reviewer-definition content.
- Native host-folder or agent-file copies are best-effort mirrors only. Runtime correctness MUST NOT depend on a host auto-loading those files; the injected composed prompt must be sufficient when mirrors are absent, stale, or ignored.
- Do not persist raw prompts, raw provider transcripts, full stdout/stderr, credentials, tokens, environment variables, token stores, unrelated private config, or secret values by default.
- Availability fallback is at most one pre-authorized alternate and must record requested and actual host/model.
- Runtime review must not depend on live web search.
- A no-reviewable-diff checkpoint must not spawn a reviewer; it writes `ReviewRunSkipped` and pass/no-op `GateVerdict`.
