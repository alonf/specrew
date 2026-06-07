# SC-008 Beta Validation Script (release gate — runtime evidence only)

**Feature**: 171-specrew-refocus
**Gate**: stable promotion is BLOCKED until every step below passes on a real install. File-presence evidence does not satisfy any step (spec SC-008).

## Preconditions

- Fresh downstream project, `specrew init` from the published `-beta.N` module, host CLIs installed for at least TWO hook-bound hosts (Claude + Codex recommended — Codex carries the full triad).

## Steps (each cites journal or live-context evidence)

1. **Deploy verification** — `deploy-refocus-hooks.ps1` ran for each installed host (init/update wiring): Claude `.claude/settings.local.json` carries the SessionStart entry; Codex `~/.codex/hooks.json` carries SessionStart + UserPromptSubmit; user-authored entries byte-untouched. Evidence: file inspection + a re-run proving byte-idempotence.
2. **B2 live (both hosts)** — start a session; the FIRST turn shows the `[specrew-refocus] trigger=b2` grounding in context (ask the agent to quote it). Evidence: journal entry `{trigger: b2, outcome: injected}` + the agent's quote.
3. **B1 live (Claude)** — drive the session until compaction (or `/compact`); the next turn carries `trigger=b1` with the CURRENT stage digest. Evidence: journal + agent quote. Repeat on Codex (`SessionStart source=compact`).
4. **B3 channel-1 live (any host incl. Copilot)** — advance a lifecycle boundary; the sync output ends with `trigger=b3` + the INCOMING stage digest. Evidence: the sync transcript + channel-1 fingerprint file.
5. **B3 hook live (Codex)** — advance a boundary WITHOUT the wrapper (edit the cursor manually), then send a user prompt; the turn carries the b3 injection. Evidence: journal `{trigger: b3, channel: hook, outcome: injected}`.
6. **Dedupe live** — boundary advance via the wrapper, then a user prompt on Codex: NO double payload. Evidence: journal `{outcome: deduped}`.
7. **Kill-switch walk (all three levels)** — env var silences hooks instantly; catalog `enabled: false` silences one trigger durably; `-Remove` deregisters + records opt-out; plain re-deploy respects the opt-out; `-Force` re-enables. Evidence: `--status` output at each step.
8. **Breaker live** — seed a runaway journal (3 same-trigger injected entries) in the session state; next event trips loudly ONCE naming re-enable paths; `--reset-breaker` clears. Evidence: the WARN line + `--status`.
9. **Copilot B1 source-check (deferred verification from T013)** — on Copilot, observe whether `sessionStart` fires after compaction and what `source` carries; record the finding in the research matrix and bind/variance accordingly.
10. **Latency sanity** — session start with hooks feels acceptable (~2s once); no per-tool-call lag anywhere (PostToolUse is unregistered everywhere).

## Recording

Each step's evidence lands in this file (PASS/FAIL + journal citations) at beta time; any FAIL keeps the version beta forever (v0.30.0 precedent) until fixed and re-validated.
