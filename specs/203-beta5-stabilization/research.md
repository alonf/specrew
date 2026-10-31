# Research: 203 beta5 stabilization (iteration 001)

Read-only research, 2026-10-31, from the repository's recorded real host payloads
(`tests/fixtures/hook-payloads/<host>/`, provenance in each `provenance.json`: Claude 2.1.296, Copilot
1.0.92/1.0.96, Codex 0.162.1) and source. No agent CLI was run. Items marked **W0** are confirmed by a capture in
a scratch directory before the work item that depends on them.

## R1. Turn identity on the user-prompt event (FR-016, DA-2)

| Field | Claude `UserPromptSubmit` | Copilot `userPromptSubmitted` | Codex `UserPromptSubmit` |
| --- | --- | --- | --- |
| session id | `session_id` | `sessionId` | `session_id` |
| transcript path | `transcript_path` | absent (only on agentStop) | `transcript_path` |
| per-message id | `prompt_id` | none | `turn_id` |
| timestamp | none | `timestamp` (epoch ms) | none |

Copilot running Claude's hooks sends snake_case with an ISO `timestamp` and no `prompt_id`
(`probe/copilot-claude-hooks/probe-userpromptsubmit-1.json`).

- **Decision**: Claude `prompt_id`; Codex `turn_id`; Copilot (both firings) `sha256(session id + timestamp
  normalized to UTC epoch ms + prompt text)`, declared in the binding.
- **Rationale**: a payload-only identity is available at prompt time, with no transcript read; normalizing makes
  the two Copilot firings agree, so one approval records once.
- **Alternatives considered**: transcript entry ids (Copilot's `data.messageId` exists only at agentStop, too late
  for prompt-time capture); prompt hash alone (two identical replies in one session would collide).
- **Open (W0)**: whether both Copilot firings carry the same instant. If not, the replacement comes to the
  before-implement boundary.

## R2. Pasted content (FR-017, DA-3)

- Claude marks larger pastes with `<pasted_content id=N>` (smallest tagged: 673 chars over 8 lines); smaller
  pastes arrive inline. No Copilot or Codex paste evidence exists in the repository.
- `Resolve-SpecrewApprovalForm` (`HumanAuthorityStore.ps1:372`) strips paired paste tags for Claude and applies
  size and one-line rules elsewhere; tests in `tests/unit/approval-form.tests.ps1:81-160`.
- **Decision**: a phrase counts only when it starts the message, outside quotes and backticks, within the size
  bound; Claude strips paste tags first.
- **Rationale**: holds on hosts that do not mark pastes, because a pasted document rarely starts with a bare
  approval phrase and is usually over the bound.
- **Open (W0)**: capture a paste on Copilot and Codex; tighten the rule per host if either inlines a short paste.

## R3. Visible line (FR-029, DA-4)

- Claude: `additionalContext` reaches the model only; a Stop block reason is shown to the human; `systemMessage`
  is never emitted by the adapter today.
- Copilot: `additionalContext` is model-facing; a Stop block reason is replayed as a new user prompt
  (fixture `copilot/print-userpromptsubmitted-host-injected-stop-reason-replay.json`).
- Codex: `systemMessage` and `stopReason` were never surfaced (198 characterization).
- **Decision**: Claude `systemMessage`, verified in W0 with the maintainer observing; Copilot and Codex have no
  verified channel, so the not-recorded report is a justified stop there and the closing line gets a drift entry.

## R4. Compaction (FR-019)

- Claude's summary entry (`isCompactSummary`, type user) is treated as not human
  (`ConversationCaptureAccessor.ps1:99-107`); only a test-built entry exists. Copilot and Codex: no evidence beyond
  the SessionStart `source` value `compact`.
- **Decision**: pair verdicts against the pending-crossing record, which does not depend on transcript shape; W0
  records a real Claude compaction entry as a fixture.

## R5. Reviewer token usage (FR-012)

- `Get-ReviewSafeUsageProjection` reads `runtimeResult.usage`; only the fixture runtime fills it; no harness port
  parses usage. Production always shows `unavailable`.
- **Decision**: each harness port parses host-reported usage from the reviewer's output (Codex from its delivery
  file); otherwise "usage: not reported by <host>". No estimate.

## R6. Narrow-scope review (FR-013, DA-7)

- `specrew review --remediate narrow-scope --scope path:<p>` narrows the reviewer prompt only and labels the run
  `partial` (`worktree-review-orchestrator.ps1:887`); no file filter exists in `review-target-port.ps1`.
- **Decision**: a crew-directed scope materializes the disposable worktree with only the listed paths (sparse
  checkout of the frozen target commit), labelled `scoped`.

## R7. Live engine resolution (clarify instruction, DA-8)

- The handover provider loads `scripts/internal/bootstrap` from the project working tree before
  `SPECREW_MODULE_PATH` or the installed module (`specrew-handover-provider.ps1:82-87`); the navigator resolves
  from the project root first; provider commands resolve from `.specify`, then `scripts/internal`.
- **Decision**: the self-host tree yields to an explicitly set `SPECREW_MODULE_PATH`; the pin is a detached
  checkout outside the worktree (`%USERPROFILE%\.specrew\live-engine\203-beta5-stabilization`).
- **Alternatives considered**: a checkout under `.specrew/` (counted as source, picked up by census and lint);
  the installed module as the pin (machine-wide blast radius).

## R8. Review budget ceiling

- `Get-ReviewCampaignRoundBudgetTotal` reads `co_review_max_rounds` from `.specrew/config.yml`, default 4; the key
  is not set in this project. 202's iterations used 6, 10 and 8 rounds under per-round approvals.
- **Decision**: the ceiling stays the existing key and default; iteration 002's budget is 4 rounds.
