# Research: Per-Host Conversation-Transcript Exposure (F-174 iter-010, T002)

**Schema**: v1
**Recorded**: 2026-06-11 (during iteration-010 implementation; maintainer-directed research)
**Method**: parallel web-research agents against PRIMARY-SOURCE docs (raw markdown bytes, not summarizer
output) + empirical inspection of REAL on-disk transcript files from live codex/cursor/copilot/claude
sessions on the maintainer's machine.

## Question

For conversation capture (T002, FR-022): does each host expose the session conversation transcript to its
Stop-hook — via a payload field (like Claude's `transcript_path`) or a known on-disk path — so the hook can
read a recent-dialogue tail into the handover?

## Verdict: real-capture on ALL FOUR hook-capable hosts (antigravity excluded — no hooks)

| Host | Stop event | Transcript handle (payload) | On-disk location (empirical) | Confidence |
| --- | --- | --- | --- | --- |
| Claude | Stop / PostToolUse | `transcript_path` (.jsonl) | `~/.claude/projects/<proj>/<session>.jsonl` | known |
| Codex | Stop | `transcript_path` **+ `last_assistant_message`** | `~/.codex/sessions/YYYY/MM/DD/rollout-*.jsonl` | high (developers.openai.com/codex/hooks) |
| Copilot | agentStop / Stop | `transcriptPath` (camel) / `transcript_path` (Pascal) | `~/.copilot/session-state/<id>/events.jsonl` | high (raw github/docs bytes) |
| Cursor | stop | `transcript_path` **+ `CURSOR_TRANSCRIPT_PATH` env** | `~/.cursor/projects/<proj>/agent-transcripts/<id>/<id>.jsonl` | high (raw cursor.com/docs bytes) |
| Antigravity | (no hooks) | none | — | n/a (recovers via `specrew start` + reconciliation, T008) |

## The transcript FILE FORMATS are heterogeneous (and undocumented for 3 of 4)

Pinned empirically from real files; this is why the capture is format-RESILIENT (4-tier ladder), not a rigid
per-host parser:

- **Cursor**: `{"role":"user|assistant","message":{"content":[{"type":"text","text":...}]}}` — cleanest. NOTE
  Cursor REDACTS portions of assistant messages (`[REDACTED]` in-source) — the most lossy host.
- **Claude**: `{"type":"user|assistant","message":{"content":[{"type":"text","text":...}]}}`.
- **Codex**: event-typed — `{"type":"response_item","payload":{"type":"message","role":...,"content":[{...,"text":...}]}}`;
  roles include `developer`/`system` (skipped); line 1 is a giant `session_meta` header (a *tail* skips it).
- **Copilot**: event-typed — `{"type":"user.message|assistant.message","data":{"content":"<string>"}}`; the
  ROLE is in the type prefix (no `data.role`).

## Stability + caveats (the maintenance reality)

- The transcript_path FIELD is part of each host's public hook contract → stable. We read the path the host
  HANDS us (never reconstruct it) → immune to on-disk location changes.
- The FILE FORMAT is internal and can drift. **Codex explicitly documents "the transcript format is not a
  stable interface for hooks and may change over time."** The 4-tier ladder degrades gracefully (raw tail +
  visible note), never breaks (capture is additive over the durable git/fs base + agent sections).
- **Windows codex stdin bug** (openai/codex#23784): non-ASCII content can malform the stdin JSON → prefer
  reading `transcript_path` from disk over trusting the stdin string. Directly relevant (this repo is Windows).
- **Hard-kill** (SIGKILL/crash/power-loss) fires NO hook on ANY host → the non-durable conversation tail since
  the last capture is unrecoverable; only durable git/fs state survives (documented as the universal floor).

## How drift gets DETECTED (deferred to a separate proposal)

Committed fixtures (`tests/bootstrap/fixtures/conversation/*.jsonl`) are FROZEN snapshots — they catch OUR
parser regressions but NOT live host format drift. Live drift detection requires a real-host CI canary
(nightly, Docker + BYOK, provider-news breaking-change scan, version-gated per-host format test). Filed as a
separate high-priority proposal (`proposals/<n>-cross-host-transcript-format-drift-canary.md`).

## Source URLs

- Codex: <https://developers.openai.com/codex/hooks> · <https://github.com/openai/codex/issues/23784>
- Copilot: <https://docs.github.com/en/copilot/reference/hooks-reference> (raw: github/docs main content/copilot/reference/hooks-reference.md)
- Cursor: <https://cursor.com/docs/hooks>
