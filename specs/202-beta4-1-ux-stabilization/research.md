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

| Fact | Claude Code 2.1.296 | Copilot CLI 1.0.92 (print) / 1.0.96 (TUI) | Codex CLI 0.162.1 (TUI and exec) |
| --- | --- | --- | --- |
| Session id in payload (DA-4) | **Yes**, `session_id` on all three events; it also appears as env `CLAUDE_CODE_SESSION_ID` | **Yes**, `sessionId` (camelCase) on all three events | **Yes**, `session_id` (a UUIDv7) on all three events; prompt and Stop events also carry `turn_id` |
| Hook output reaches model context (DA-3 precondition) | **Yes**: SessionStart and UserPromptSubmit canaries both answered; recorded as `hook_success` attachments | **Yes**: both canaries answered; the prompt hook's text is appended to the user message as `<system_reminder>` | **Yes**: it named both canaries ("PELICAN, MARMOT") in exec mode. In the TUI it answered "I can't disclose hidden hook output.", which acknowledges that the text is present |
| Hook output displayed directly to the user (DA-3) | **No.** The TUI drew only status lines ("running UserPromptSubmit hook", "running Stop hook"), never the hook text. Print mode prints only the reply | **No.** The TUI drew only "Loading: 1 plugin, 6 hooks". Print mode prints only the reply | **No.** The TUI drew only "Running hooks" status lines, never the hook text |
| Agent shell to `pwsh` stdin, Hebrew (DA-4) | UTF-8 intact; Bash adds LF, PowerShell adds CRLF; child `[Console]::InputEncoding` is `ibm437` under Bash and `utf-8` under PowerShell | UTF-8 intact, CRLF; child input encoding `ibm437` | UTF-8 intact, CRLF; child input encoding `ibm437` |
| Hook stdin encoding | UTF-8 bytes; the hook process's `[Console]::InputEncoding` is `ibm437` | Same | Same |

**Further facts T002, T005 and T008 must honor:**

- **Copilot fires the prompt hook before SessionStart** in every captured run, print and TUI: `userPromptSubmitted` is about 2.5 s ahead, and SessionStart carries `initialPrompt`. In the TUI, SessionStart does not fire at launch; it waits for the first prompt. "First prompt" therefore cannot be inferred as "after SessionStart".
- **Copilot question dismissal produces no hook event.** Esc on an `ask_user` form returns the tool result "User cancelled the request." (`elicitation_action: cancel`). Ctrl+O on the same form returned "User responded: A" (`elicitation_action: accept`), an answer the human never typed. The literal string "User skipped question" did not occur on 1.0.96. The next hook event is the next typed prompt.
- **Copilot sets `CLAUDE_PROJECT_DIR`** in its hook environment, which confirms the guard noted in `hosts/claude/host.psd1`.
- **Payload field names differ by host:** `session_id`, `hook_event_name` and `transcript_path` on Claude; `sessionId`, `timestamp` (epoch ms), `transcriptPath` and `initialPrompt` on Copilot. Claude's Stop payload carries `last_assistant_message`; Copilot's `agentStop` carries `stopReason`.
- **Not provoked:** a Copilot replayed directive (host-injected text). T002 keeps the existing dispatcher behaviour for it until a real payload is captured, and says so in its test.

**Codex hook trust (maintainer decision at the tasks verdict, option a).** Before trusting, the TUI's hook review listed exactly three hooks needing review, one each on SessionStart, UserPromptSubmit and Stop. All three came from the scratch folder's `.codex/hooks.json` and ran `capture.ps1`. Each event's other hook is Specrew's own, from `~/.codex/hooks.json`, and was already trusted. "Trust all and continue" then added exactly these entries to `~/.codex/config.toml`:

```toml
[hooks.state.'C:\Users\alon\AppData\Local\Temp\claude\C--Dev-specrew-beta3-stabilization\39558f55-6f4d-436f-a8c3-5369082ea08e\scratchpad\t001\codex\.codex\hooks.json:session_start:0:0']
trusted_hash = "sha256:d1e48acc920880abdb77827ae8c051949f27e187aef7a60490ece466538f700c"

[hooks.state.'C:\Users\alon\AppData\Local\Temp\claude\C--Dev-specrew-beta3-stabilization\39558f55-6f4d-436f-a8c3-5369082ea08e\scratchpad\t001\codex\.codex\hooks.json:user_prompt_submit:0:0']
trusted_hash = "sha256:5183abf8d0f20b3ca3c6620315c4b09d3fe7f423b8640348eac6d87a1ca46af0"

[hooks.state.'C:\Users\alon\AppData\Local\Temp\claude\C--Dev-specrew-beta3-stabilization\39558f55-6f4d-436f-a8c3-5369082ea08e\scratchpad\t001\codex\.codex\hooks.json:stop:0:0']
trusted_hash = "sha256:81ead30f42831f3ef2390a9aec3a05fc4a748478d2b304e46587db46c3699a9d"
```

**Cleanup (2026-10-13):**

- **Removed from `~/.codex/config.toml`:** the three blocks above, and a `[projects.'…\scratchpad\t001\codex'] trust_level = "trusted"` block that Codex had written earlier in T001, before the pre-trust snapshot. The file now matches the snapshot except for a model-usage counter that Codex owns (`"gpt-6.1-sol"` 3 to 4), which was left alone; Codex still parses it.
- **Deleted:** the scratch folder (127 files).
- **Kept, owned by the hosts:** Codex and Copilot session records of the scratch runs. `~/.claude.json` also keeps a project entry for the scratch Claude folder, from accepting Claude's trust dialog in the TUI run. Live Claude sessions write that file, so it is reported here, not edited; it names a folder that no longer exists.

### Host-injected capture (T002 opening step, maintainer item 3, 2026-10-13)

Same scratch-only rule, in a new scratch folder outside any repository. Each capture hook blocked the first Stop of a run once, with a reason, to see whether the host replays the reason as a user turn. On Claude, a background-task completion was also provoked.

| Class | Claude 2.1.296 | Copilot 1.0.92 | Codex 0.162.1 |
| --- | --- | --- | --- |
| Stop-block reason replayed as a prompt event | **No.** The block continues the same `prompt_id`; no new UserPromptSubmit | **Yes, recorded.** `userPromptSubmitted` with `prompt` = the block reason; same keys as a typed prompt; the next `agentStop` has `stop_hook_active: true` | **No.** The block continues the same `turn_id` with `stop_hook_active: true`; no new UserPromptSubmit |
| Background-task completion delivered as a user turn | **Yes, recorded.** UserPromptSubmit with a `<task-notification>` prompt and a new `prompt_id`; same keys as a typed prompt | not tried (no equivalent surface) | not tried (no equivalent surface) |
| Copilot dismissed question ("User skipped question") | — | **Never produced.** No hook event; tool results "User cancelled the request." / "User responded: A" (B4F-113) | — |

**What T002 must take from this.**

- **Origin is in the content, not in the keys.** On every host, a host-injected prompt payload has exactly the same keys as a typed one. Origin rules must be content-and-sequence data:
  - **Claude:** a `<task-notification>` prefix means host-injected.
  - **Copilot:** a prompt equal to the reason of the immediately preceding Specrew Stop block means host-injected. The journal match is the defense.
  - **Codex:** no injected prompt class was observed. As on every host, a prompt that matches no host-injected rule is `typed-user`, and the journal match still applies to it (FR-005, FR-006). *Corrected at T002 (DRIFT-010): an earlier draft of this line said "unmatched is `unknown`". That would have refused every typed Codex reply as authority, which is the B4F-108 failure itself.*

**Synthetic fixtures (never presented as recorded).** Each has `synthetic` in its file name and `origin: synthetic` in its provenance, with the reason and the recorded payload its shape was copied from:

- `codex/synthetic-userpromptsubmit-host-injected.json`, for the Codex host-injected class that no Codex mechanism tried produced.
- `copilot/synthetic-userpromptsubmitted-skipped-question.json`, for the legacy skipped-question string. It keeps the existing dispatcher transform under test; 1.0.96 does not emit the string.

Both are recorded as DRIFT-009.

**Trust and cleanup.** The Codex protocol was the same as in T001. Before trusting, the review list held exactly three hooks, all from the scratch folder's `.codex/hooks.json`. Two kinds of entries were added to `~/.codex/config.toml`:

- three `[hooks.state.'…\scratchpad\inj\codex\.codex\hooks.json:{session_start|user_prompt_submit|stop}:0:0']` blocks, with trusted hashes `d1be9f3e…`, `e3fbc20c…` and `1d4979f0…`;
- one `[projects.'…\scratchpad\inj\codex'] trust_level = "trusted"` block. This came from the folder-trust dialog Codex showed first this time: the harness's first Enter answered it.

All four were removed. The file is byte-identical to its pre-run snapshot (SHA-256 equal). The scratch folder (74 files) was deleted, and no Specrew state was ever created in it. `~/.claude.json` keeps two project entries for the scratch Claude folders, `t001` and `inj`, from Claude's trust dialog. They are reported here, not edited.

### Journal append under concurrency (T003, 2026-10-13, Windows 11, pwsh 7)

Three processes each appended 400 JSON lines to one file, with one open, write and close per line, which is exactly how hook processes write the journal.

| Open mode | Lines in file | Parsed | Torn | Expected |
| --- | --- | --- | --- | --- |
| `[IO.File]::Open(Append, Write, ReadWrite)` | 1142 | 1139 | 3 | 1200 |
| `FileSystemAclExtensions.Create(Append, AppendData only, ReadWrite)` | 1200 | 1200 | 0 | 1200 |

.NET positions an `Append` stream at open time, so two writers that open together write to the same offset: lines are lost or torn. A handle opened with only the `AppendData` right is an OS-level atomic append on Windows. The journal therefore uses it on Windows, still a share mode (FR-001's preferred form) and no lock. On Linux and macOS it uses the regular `Append` stream; case (e) on the 3-OS matrix (T005) decides whether that needs the permitted per-write lock.

**Case (e), Windows (T005, 2026-10-14).** Two `pwsh` processes, released by one barrier, each called the shipped `Write-DispatcherHookOutputAuthorityRecord` 1,000 times. The functions are lifted from the dispatcher by the parser, not copied.

- **Shipped handle:** 2,000 of 2,000 lines, none torn, no buffer, no degraded transition.
- **Mutant with a plain `Append` stream:** lost 4, then 3 lines in two runs.

Five pairs of real dispatcher processes on Stop all journaled their reasons. The Linux and macOS legs run in `cross-platform-validation.yml`'s existing three-OS job.

**Case (e), all three OSes (CI run 38487295823, 2026-10-14):**

| OS | Lines | Missing | Torn | Verdict |
| --- | --- | --- | --- | --- |
| Windows | 2000/2000 | 0 | 0 | the AppendData handle holds |
| Linux (ubuntu-latest) | 1943/2000 | 58 | 1 | the plain `Append` stream loses lines |
| macOS (macos-latest) | 1968/2000 | 32 | 0 | the plain `Append` stream loses lines |

Neither writer degraded: every lost line was reported as written. That is why the condition T003 planned for applies. Linux and macOS now take the permitted per-write lock on this journal only: a sidecar `<journal>.lock` opened exclusively for the duration of one write. .NET maps that to an advisory `flock` honoured by every Specrew writer. Readers never take it, so a read never waits on or refuses because of a writer. Windows keeps the lock-free AppendData handle.

**Verdict per validated host:**

- **Claude:** DA-3 holds (injection yes, direct display no, so the agent renders the supplied orientation). DA-4 holds (a session id is present; UTF-8 bytes arrive intact, and explicit byte-level decoding is required because the console encoding varies).
- **Copilot:** DA-3 and DA-4 both hold, on the same grounds. The design must key "first prompt" on the prompt event, not on SessionStart ordering.
- **Codex:** DA-3 and DA-4 both hold. Hook text reaches the model: asked to name the animals the hooks supplied, it answered "PELICAN, MARMOT". The TUI shows only "Running hooks". `session_id` is present on every event.
