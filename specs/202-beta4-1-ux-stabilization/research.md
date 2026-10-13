# Research: 202 beta4.1 UX stabilization

Phase 0 decisions. Each one was settled at the workshop or at the design-analysis co-design. Two facts stay open and are measured by T001.

| Topic | Decision | Rationale | Alternatives considered |
| --- | --- | --- | --- |
| Host input normalization | One shared `ConvertTo-SpecrewTurnRecord`. Hosts declare field maps and origin rules as data, and may name one transform from a shared registry (DA-1) | No adapter scripts exist today; two divergent normalizers exist; data bindings keep a new host cheap | Per-host adapter scripts; leaving normalization in the dispatcher |
| Journal concurrency | A share mode permitting concurrent appends first; a per-write lock on that journal only if case (e) shows torn or interleaved lines | Workshop lens 4 and code lens 7; the 199 concurrency rule amended | Generic lock framework (rejected); retry only (a backup, not the fix) |
| Degraded trust | Precise fail-closed through a per-process outage buffer | Workshop security lens, option b | Blanket fail-closed (today's deadlock); fail open |
| Presentation memory | Per (session, crossing id). Context gap = changed crossing id or reviewed artifacts, SessionStart new/resume/compact, or 8 hours. HEAD alone is not a gap | DA-2 amended: bookkeeping commits caused repaints | Turn-counter keying (today's failure) |
| Orientation order | Supplied as system output on the session's first prompt; no agent duplicate on direct-display hosts | DA-3: no host can reorder an emitted reply | A Stop-time demand (today's failure) |
| Draft path | stdin into `declare-turn-end.ps1`, stored per session; explicit UTF-8 | DA-4; B4F-065 encoding history | The agent computes the path |
| Feature identity | In-flight controller or crossing, then the pointer for this branch, then the branch as a hint; always disclosed | DA-5: the branch is not the feature | Branch-first reconciliation (the original FR-018) |
| Tuning | Retry at most 5 attempts within 250 ms; long gap 8 hours | Agreed at design-analysis | — |

## Open facts (T001 measures them in scratch directories, never in a governed worktree)

1. Per validated host: does the hook payload carry a session id? (DA-4: if not, that host's draft path is per-token.)
2. Per validated host: which hook output is displayed to the user directly? (DA-3: where it is, the orientation is system-rendered and the agent does not render it.)

Any host that cannot meet the agreed design on these facts is reported at the before-implement boundary.

## T001 measurements (2026-10-13)

**Method.** Every run was in a scratch directory under the session scratchpad, outside any repository; the governed worktree was not touched.

- **Capture hooks.** A capture hook on SessionStart, the prompt event and Stop copied raw stdin bytes, and printed a canary sentence as hook output.
- **Model context.** A canary that reaches the model shows that hook output is injected into model context.
- **Direct display.** Each interactive TUI ran under a Windows pseudo console, and every byte it drew was recorded. A canary on screen would show direct display.
- **Encoding.** The DA-4 encoding probe had each host's agent pipe `שלום עולם` through its own shell tool into `pwsh`, and recorded the received bytes on disk.
- **Fixtures.** Payloads are in `tests/fixtures/hook-payloads/<host>/`, with `provenance.json` (host version, UTC time, scratch path, byte count, SHA-256; no environment values).

| Fact | Claude Code 2.1.296 | Copilot CLI 1.0.92 (print) / 1.0.96 (TUI) | Codex CLI 0.162.1 |
| --- | --- | --- | --- |
| Session id in payload (DA-4) | **Yes**, `session_id` on all three events; it also appears as env `CLAUDE_CODE_SESSION_ID` | **Yes**, `sessionId` (camelCase) on all three events | **Not captured.** Codex loaded the three scratch hooks but will not run hooks until they are trusted (TUI: "3 hooks are new or changed... Trust all and continue"). Indirect evidence only: this repo's bootstrap journal records Codex `dedupe_key` values shaped like session UUIDs |
| Hook output reaches model context (DA-3 precondition) | **Yes**: SessionStart and UserPromptSubmit canaries both answered; recorded as `hook_success` attachments | **Yes**: both canaries answered; the prompt hook's text is appended to the user message as `<system_reminder>` | Not captured (same trust block) |
| Hook output displayed directly to the user (DA-3) | **No.** The TUI drew only status lines ("running UserPromptSubmit hook", "running Stop hook"), never the hook text. Print mode prints only the reply | **No.** The TUI drew only "Loading: 1 plugin, 6 hooks". Print mode prints only the reply | Not captured (same trust block) |
| Agent shell to `pwsh` stdin, Hebrew (DA-4) | UTF-8 intact; Bash adds LF, PowerShell adds CRLF; child `[Console]::InputEncoding` is `ibm437` under Bash and `utf-8` under PowerShell | UTF-8 intact, CRLF; child input encoding `ibm437` | UTF-8 intact, CRLF; child input encoding `ibm437` (measured: the probe needs no hook) |
| Hook stdin encoding | UTF-8 bytes; the hook process's `[Console]::InputEncoding` is `ibm437` | Same | — |

**Further facts T002, T005 and T008 must honor:**

- **Copilot fires the prompt hook before SessionStart** in every captured run, print and TUI: `userPromptSubmitted` is about 2.5 s ahead, and SessionStart carries `initialPrompt`. In the TUI, SessionStart does not fire at launch; it waits for the first prompt. "First prompt" therefore cannot be inferred as "after SessionStart".
- **Copilot question dismissal produces no hook event.** Esc on an `ask_user` form returns the tool result "User cancelled the request." (`elicitation_action: cancel`). Ctrl+O on the same form returned "User responded: A" (`elicitation_action: accept`), an answer the human never typed. The literal string "User skipped question" did not occur on 1.0.96. The next hook event is the next typed prompt.
- **Copilot sets `CLAUDE_PROJECT_DIR`** in its hook environment, which confirms the guard noted in `hosts/claude/host.psd1`.
- **Payload field names differ by host:** `session_id`, `hook_event_name` and `transcript_path` on Claude; `sessionId`, `timestamp` (epoch ms), `transcriptPath` and `initialPrompt` on Copilot. Claude's Stop payload carries `last_assistant_message`; Copilot's `agentStop` carries `stopReason`.
- **Not provoked:** a Copilot replayed directive (host-injected text). T002 keeps the existing dispatcher behaviour for it until a real payload is captured, and says so in its test.

**Verdict per validated host:**

- **Claude:** DA-3 holds (injection yes, direct display no, so the agent renders the supplied orientation). DA-4 holds (a session id is present; UTF-8 bytes arrive intact, and explicit byte-level decoding is required because the console encoding varies).
- **Copilot:** DA-3 and DA-4 both hold, on the same grounds. The design must key "first prompt" on the prompt event, not on SessionStart ordering.
- **Codex:** DA-4's encoding half holds. The session-id half and DA-3 are **unmeasured**, because the hook-trust prompt is a human decision.
