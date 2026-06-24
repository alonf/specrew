# Devin Stop-Payload and Handover Spike

**Feature**: 200-devin-cli-host
**Iteration**: 001
**Date**: 2026-06-24
**Result**: Outcome 2 — ATIF export plus Devin-local normalization

## Environment

- Devin CLI: `devin 2026.7.23 (3bd47f77)`
- Operating system: Windows x86_64
- Mode: `devin -p` with a synthetic fixed canary and `--export`
- Hook sources: standalone `.devin/hooks.v1.json` and equivalent config-wrapped
  Claude-format hooks, used together to cross-check loading and firing
- Sensitive data: none; only synthetic canary text was retained in this report

## Stop Payload Result

The real Stop hooks fired after ATIF export and received:

```json
{"hook_event_name":"Stop","stop_hook_active":false}
```

No assistant-message or transcript-path field was present. Tier-3 event-payload
handover is therefore unavailable on the tested build.

The same session also proved:

```json
{"hook_event_name":"SessionStart","source":"startup"}
{"hook_event_name":"UserPromptSubmit","prompt":"Reply with exactly: SPECREW_DEVIN_STOP_CANARY_200_WITH_SH"}
```

## Export Ordering and Shape

The Devin log recorded export before Stop-hook completion:

```text
Exported conversation to evidence/conversation-with-sh.atif.json
Stop hook payload captured after export
```

The export was ATIF v1.7 with `steps[]`. Relevant turns use:

- `source: "user"` with a string `message`
- `source: "agent"` with a string `message`

## Unchanged-Parser Proof

A scratch normalizer mapped ATIF steps to the parser's existing Claude-like JSONL
shape:

```json
{"type":"user","message":{"content":[{"type":"text","text":"Reply with exactly: SPECREW_DEVIN_STOP_CANARY_200_WITH_SH"}]}}
{"type":"assistant","message":{"content":[{"type":"text","text":"SPECREW_DEVIN_STOP_CANARY_200_WITH_SH"}]}}
```

The unchanged `Get-SpecrewConversationTail` path returned:

```text
- **user:** Reply with exactly: SPECREW_DEVIN_STOP_CANARY_200_WITH_SH
- **assistant:** SPECREW_DEVIN_STOP_CANARY_200_WITH_SH
```

Result: `UNCHANGED_PARSER_CAPTURE_PASS`.

No edit to `scripts/internal/bootstrap/ConversationCaptureAccessor.ps1` is
required. The production normalizer remains owned by `hosts/devin/`.

## Windows Hook-Runner Finding

The CLI loaded all declared hooks, but command hooks failed with:

```text
Effects evaluator failed for hook None: Failed to spawn command: program not found
```

Adding `C:\Program Files\Git\bin` (which contains `sh.exe`) to the Devin process
`PATH` made SessionStart, UserPromptSubmit, and Stop hooks execute. This conflicts
with the installed changelog statement that general Windows non-interactive shell
execution now defaults to PowerShell and no longer requires Git Bash.

This is a tested-build compatibility constraint, not a Specrew parser issue.
Devin remains experimental until implementation and prerelease evidence handle
or document the prerequisite honestly.

## Planning Verdict

- Tier-3 payload fallback: rejected by evidence.
- ATIF plus in-package normalization: accepted by evidence.
- New parser shape / Slice B: not required for the first landing.
- Full handover: remains in Feature 200 scope.
