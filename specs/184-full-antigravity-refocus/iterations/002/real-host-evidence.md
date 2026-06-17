# Real-Host Evidence: Iteration 002 (T006)

**Schema**: v1
**Task**: T006
**Owner**: Human (Alon Fliess) — the agent CANNOT produce this; it requires real `agy` sessions on the maintainer's machine.
**Status**: PENDING — awaiting the maintainer's real-host run.
**Evidence label**: machine-local (TG-005) until reproduced; no full Antigravity-parity claim until this lands (SC-018).

## What to run

Install the iteration-002 prerelease (or run from this dev tree via `SPECREW_MODULE_PATH`), then in a scratch project:

1. `specrew init` — deploys the coordinator section into `AGENTS.md` / `CLAUDE.md` / `.github/copilot-instructions.md` (the manifest-declared `InstructionsFile`s) and the front-loaded bootstrap guard.
2. Launch `agy` (Antigravity) with a NEW feature request — once on **Opus 4.6**, once on **Gemini Flash**.

## Evidence to capture

### SC-016 — Opus 4.6 time-to-workshop

- [ ] Opus 4.6 reaches the design workshop **faster** than the iter-001 manual path (or records a concrete reason it could not be measured).
- Iter-001 baseline (turns/prompts to workshop): _<fill>_
- Iter-002 (this run): _<fill>_
- Verdict: _<faster / same / slower / not-measurable + reason>_

### SC-017 — Gemini Flash follows the governed workshop

- [ ] Gemini Flash follows the governed workshop and does **NOT** invoke `specify.exe workflow` / the raw bundled SDD engine.
- Observed: _<fill — did Flash drive the governed workshop? did it shell out to `specify.exe`?>_
- Verdict: _<drives-workshop / weak-model-caveat-preserved (could not drive)>_
- If Flash still cannot drive the lifecycle, KEEP the weak-model caveat explicit — do not claim full parity.

### Behavioral `AGENTS.md → GEMINI.md` priority (the GEMINI.md defer's linchpin)

This is the carry the GEMINI.md scope-defer rests on. It is currently docs-corroborated only (the official Antigravity page is JS-rendered), so it MUST be confirmed behaviorally.

- [ ] Plant a CONFLICTING, identifiable instruction in the Specrew-deployed `AGENTS.md` vs a `GEMINI.md` in the same project, and confirm which one `agy` honors.
- Marker in `AGENTS.md`: _<fill — e.g., "always answer with the word BANANA">_
- Marker in `GEMINI.md`: _<fill — e.g., "always answer with the word APPLE">_
- `agy` honored: _<AGENTS.md marker / GEMINI.md marker>_
- **Verdict**: `AGENTS.md` wins → the defer is **PROVEN** (deploy-to-`AGENTS.md` is correct, `GEMINI.md` handling stays out of scope). `GEMINI.md` wins → **STOP and surface** — the defer flips to in-scope and needs a human split/defer decision on `GEMINI.md` handling.

### SC-005 / regression — F-183 behavior intact

- [ ] Bootstrap injection, `Stop` handover, and exit/re-entry resume still work on `agy` (no provider/launch errors).

## Result

- Overall: _<fill — PASS (with `AGENTS.md` priority confirmed) / FAIL / weak-model-caveat-preserved>_
- Evidence files / transcripts: _<fill — paths or attachments; label machine-local per TG-005>_
- Release carry-forwards remain OPEN (SC-018): beta-before-stable, `MigrateLegacyTopLevelEventMap` legacy-upgrade validation, and reproducible-or-machine-local `agy` evidence.
