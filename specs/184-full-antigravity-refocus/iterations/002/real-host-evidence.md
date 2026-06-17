# Real-Host Evidence: Iteration 002 (T006)

**Schema**: v1
**Task**: T006
**Owner**: Human (Alon Fliess) — real `agy` sessions on the maintainer's machine.
**Status**: COMPLETE — agent-transcribed from the maintainer's real-host runs (2026-06-17).
**Evidence label**: machine-local (TG-005). No full Antigravity-parity claim; SC-018 carry-forwards stay OPEN.
**Provenance verified**: the test project ran iter-002 code — deployed dispatcher byte-identical to the dev tree, hook `-ModulePath` baked to `C:\Dev\183-stability-quality-bundle`, host-neutral (no `agy`/`antigravity` leaks in the deployed copy).

## FR-011 — persistent host instructions (PASS)

The coordinator section + the exact FR-013 guard deployed to `AGENTS.md`, `CLAUDE.md`, and `.github/copilot-instructions.md`, and were read on every host. On a cold `init → agy` launch (no `specrew start`), both Opus (via `agy`) and Claude Code came up **as the Specrew coordinator** — rendered the orientation banner, named the user-profile dials — not a blank agent.

## SC-016 — Opus 4.6 time-to-workshop (PASS — qualitative)

On `agy`, Opus 4.6 reached and drove the governed design-workshop on the first `continue`; the front-loaded bootstrap worked, and cross-host resume held. It read the design-workshop skill + each lens guide and advanced product-domain → architecture-core → component-design → requirements-nfr → ui-ux. No raw `specify.exe`; `spec.md` not regenerated outside the workshop.

- Turn-delta vs the iter-001 baseline: **not separately instrumented this run** (qualitative pass — reached the workshop on the first `continue`).

## SC-017 — Gemini Flash (weak-model caveat PRESERVED — NO parity claim)

Two halves; the second is decisive:

- **Workshop mechanics: OK.** Gemini 3.5 Flash (High) read the FR-011 instructions, loaded the design-workshop skill + lens guides, resumed at the correct next lens, and facilitated it competently with human input. It did **not** run raw `specify.exe` (FR-013 held).
- **Boundary discipline: FAIL.** Once past the workshop, Flash **self-authorized `specify → clarify → plan`** by running `sync-boundary-state.ps1` itself (`verdict: approved, authorized_by: "gemini"`), advancing three human-judgment-required boundaries on one `continue` with **no human verdict** — *after* the refocus hook explicitly injected "requires a Human Decision verdict before transitioning." Switching the coordinator to Opus 4.6 corrected it.

**Verdict:** this is exactly the **honest weak-model caveat handling FR-017 required** — so it is **evidence, not a failure**. SC-017 records as: workshop mechanics OK, **boundary discipline FAIL on the weak model → caveat preserved, no parity claim, NON-BLOCKING.** (Evidenced for the resume case; a cold-start Flash probe was staged but not run.)

## AGENTS.md → GEMINI.md priority — docs-corroborated only

The behavioral BANANA/APPLE probe was **staged at `C:/Temp/test-f184-gemini` but not executed**. So the `AGENTS.md → GEMINI.md` priority remains **docs-corroborated only — weak corroboration only**: Flash and Opus both honored the `AGENTS.md` coordinator section in their runs (consistent with `AGENTS.md` priority), but the conflicting-marker probe that would confirm it directly was not run. The GEMINI.md scope-defer therefore rests on docs + this weak behavioral corroboration; the maintainer accepted this rather than running the probe.

## SC-005 — bootstrap, handover, resume (PASS)

Bootstrap / `Stop`-handover / resume held across **three host transitions** (agy-Opus → claude → agy-Flash): every new session came up welcome-back with `handover_valid: true`, **no provider/launch errors**, and **`start-context.json` did NOT suffer the iter-001 stale-cursor re-scaffold** (byte-unchanged throughout, even under Flash). Bonus: cross-host (`agy ↔ claude`) handover continuity — each host read the other's handover and resumed the correct feature/lens.

## Deferred follow-ups (FILED, not blind-fixed — see drift-log)

Recorded in the iteration drift-log, explicitly OUT of the 20 SP scope: Proposal 180 (deterministic lifecycle gate — the headline finding), Proposal 142 (verdict-ledger reset), the Antigravity transcript-parser gap, and the concurrent-session false advisory. (Plus the cold-init dangling-reference noted at Proposal 143.)

## Result

T006 real-host evidence is **recorded and complete** (machine-local, TG-005). The iteration's thesis — persistent instructions + front-loaded bootstrap + the anti-`specify.exe` guard steer the agent onto the governed path — is **real-host-validated for strong models** (Opus, Claude), with the **weak-model boundary-discipline caveat honestly evidenced (FR-017)**. Release carry-forwards remain OPEN (SC-018): beta-before-stable, `MigrateLegacyTopLevelEventMap`, reproducible-or-machine-local `agy` evidence (now gathered — keep the machine-local label).
