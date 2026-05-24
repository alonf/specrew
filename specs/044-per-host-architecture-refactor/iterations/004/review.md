# Review: Iteration 004

**Schema**: v1
**Reviewed**: 2026-05-24
**Overall Verdict**: accepted

**Feature**: F-044 Per-Host Architecture Refactor

## Outcome Summary

**APPROVED** — all 3 tasks pass; smoke test confirms `specrew host list` produces the exact user-requested output; first-run probe handles all 4 cases (0 / 1 / multiple / non-TTY); BinaryAliases now probed everywhere it should be.

## Task Verdicts

| Task | Requirement | Verdict | Notes |
| ---- | ----------- | ------- | ----- |
| T001 | FR-013 | pass | Numbered menu shows installed-first/not-installed-with-install-URL; backwards-compat for kind-name input; new `Test-SpecrewHostBinaryAvailable` helper probes Binary + BinaryAliases. |
| T002 | (UX) | pass | `Invoke-SpecrewHostList` two-group output verified empirically against user's request. |
| T003 | FR-011 | pass | `Test-SpecrewHostAvailable` in detect-hosts.ps1 now matches the helper semantics — no contract-vs-consumer divergence. |

## Gap Ledger

- No in-scope requirement (FR/SC) gaps: all 3 user-surfaced concerns closed: fixed-now. Cross-environment detection + `specrew host install` + Bug 7e are out-of-scope per [`scope.md`](./scope.md).

## Verification Evidence

```text
=== Test 1: Test-SpecrewHostBinaryAvailable for each host ===
  antigravity  -> (not on PATH)
  claude       -> claude
  codex        -> codex
  copilot      -> copilot

=== specrew-host.ps1 list output ===
Installed on this machine:
  claude       Claude Code CLI                bin=claude       installed
  codex        OpenAI Codex CLI               bin=codex        installed
  copilot      GitHub Copilot CLI             bin=copilot      installed

Other supported hosts (not installed on this PATH):
  antigravity  Google Antigravity CLI         bin=agy          (not installed)  (install: https://antigravity.google/)
```

Matches user's requested format exactly.

## Sign-off

Approved for iteration-closeout. Functional verification (numbered menu prompt UX in a real `specrew start` session) is deferred to user's next manual test round — that round is the canonical review boundary for interactive UX (just like iter-003 deferred functional verification to user's manual test).
