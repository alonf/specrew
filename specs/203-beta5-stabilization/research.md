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
- **W0 result (2026-11-02, Copilot 1.0.103, `copilot -p` in a scratch folder):** they do. One prompt reached
  both channels with the same session id, the same prompt text and the same instant to the millisecond
  (`1793629006802` epoch ms on the native channel, `2026-11-02T14:16:46.802Z` on the Claude-hook channel), while
  the two hooks ran 727 ms apart. The decision stands; no replacement is needed. Fixtures with provenance:
  `tests/fixtures/hook-payloads/copilot/one-prompt-two-firings/`. RED for T003:
  `tests/unit/typed-turn-identity.Tests.ps1` (today the binding declares no identity and the prompt path keys on
  the time the hook ran). Also measured: a sub-agent's task text still fires `userPromptSubmitted` with its own
  `sessionId` (equal to `agentId`) and `parentAgentId`, as on 1.0.101 (B4F-147, already handled).

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
- **W0 result, Copilot (2026-11-02, Copilot 1.0.105 TUI, the maintainer pasting in a scratch folder):** no marker
  on either channel. A 9-line paste (877 characters), a one-line paste and a typed line reach both hooks with the
  same fields and only the text; nothing tells a paste from typing, and the maintainer saw both pastes shown in
  full after Enter, like the typed line. So on Copilot the standalone rule (the phrase starts the message, outside
  quotes and backticks, within the size bound) is the only guard: a multi-line paste is excluded by the one-line and
  size rules, and a short one-line paste of a bare phrase is indistinguishable from typing it. There is no host
  signal to tighten the rule with; that residual is stated, not closed. The three prompts also confirm R1 in the
  TUI: each carried the same session id, text and instant to the millisecond on both channels. Fixtures with
  provenance: `tests/fixtures/hook-payloads/copilot/tui-paste/` (all recognized by the deployed hooks; the Claude
  hook copies stand down).
- **W0 result, Codex (2026-11-02, Codex 0.163.0 TUI, the maintainer pasting in a scratch folder):** no marker
  either. The same three prompts reach `UserPromptSubmit` with the same fields and only the text, and Codex's own
  transcript stores them alike (content kind `user.text`, empty `text_elements`). Each carries its own `turn_id`,
  which the deployed hook passes on as the message id. Fixtures with provenance:
  `tests/fixtures/hook-payloads/codex/tui-paste/`.
- **Outcome for T003:** only Claude marks a paste. On Copilot and Codex the rule stays as decided; there is nothing
  per host to tighten it with, and the residual (a short one-line paste of a bare phrase reads as typed) is the
  same on both.

## R3. Visible line (FR-029, DA-4)

- Claude: `additionalContext` reaches the model only; a Stop block reason is shown to the human; `systemMessage`
  is never emitted by the adapter today.
- Copilot: `additionalContext` is model-facing; a Stop block reason is replayed as a new user prompt
  (fixture `copilot/print-userpromptsubmitted-host-injected-stop-reason-replay.json`).
- Codex: `systemMessage` and `stopReason` were never surfaced (198 characterization).
- **Decision**: Claude `systemMessage`, verified in W0 with the maintainer observing; Copilot and Codex have no
  verified channel, so the not-recorded report is a justified stop there and the closing line gets a drift entry.
- **W0 result, Claude (2026-11-02, Claude Code 2.1.314 TUI, the maintainer observing):** a scratch folder with
  only its local settings (`--setting-sources local`), a UserPromptSubmit hook returning a `systemMessage` (A) and
  an `additionalContext` (B), and a Stop hook returning a `systemMessage` (C). On screen, A appeared directly under
  the typed prompt as `UserPromptSubmit says: <text>`, and C directly under the reply as `Stop says: <text>`, on both
  turns. B was not shown. Asked to quote any hook text, the model quoted only B (labelled `UserPromptSubmit hook
  additional context:`), so `systemMessage` reaches the human and not the model, and `additionalContext` the model
  and not the human. The decision stands: on Claude, the not-recorded report is a `systemMessage`, from the prompt
  hook when the cause is known at prompt time and from Stop otherwise. The model does not see it, so a report
  meant for the agent as well still needs `additionalContext` beside it.

## R4. Compaction (FR-019)

- Claude's summary entry (`isCompactSummary`, type user) is treated as not human
  (`ConversationCaptureAccessor.ps1:99-107`); only a test-built entry exists. Copilot and Codex: no evidence beyond
  the SessionStart `source` value `compact`.
- **Decision**: pair verdicts against the pending-crossing record, which does not depend on transcript shape; W0
  records a real Claude compaction entry as a fixture.
- **W0 result (2026-11-02, Claude 2.1.312, a real automatic compaction):** a compaction writes a `system` entry
  (`subtype: compact_boundary`, `compactMetadata` with trigger, token counts and the preserved segment, and
  `logicalParentUuid` to the pre-compaction chain), then the summary as a `user` entry with
  `isCompactSummary: true`, `isVisibleInTranscriptOnly: true` and string content. **The summary entry reuses the
  `promptId` and `turnPosition` of the last prompt before the compaction** (seen in all five compactions of the
  session), and its text quotes the human's earlier messages, including `approved for review round` seven times.
  So a reader that keys a turn on `promptId`, or takes the latest `user` entry, finds the summary as that turn
  unless it checks `isCompactSummary` first. Fixture (shortened and redacted, provenance there):
  `tests/fixtures/hook-payloads/claude/compaction/`. Feeds T003 (a compaction summary yields no act) and T005.

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
