# Stop-Block Capability Matrix — can each host's end-of-turn hook BLOCK the turn-end? (2026-06-20)

**Question:** to render the 6-section re-entry packet AT a stop (not as a too-late next-turn nudge), the hook
must REFUSE the turn-end and force the agent to continue and render the packet before control returns to the
human. Which harnesses can actually do that?

**Method:** per-host primary-source research (official hook docs) + an independent adversarial verifier that
opened the cited sources and tried to refute each "can it block" claim (Proposal-145 report-falsification).
5 researchers + 5 verifiers. Full evidence in the workflow run; key quotes below.

## Verified matrix

| Host | Can block turn-end? | Mechanism (verified) | Loop guard | Evidence |
|---|---|---|---|---|
| **Claude** | ✅ **yes** | Stop `{"decision":"block","reason":...}` (or exit 2) — prevents stopping, continues the SAME turn, `reason` fed to the model | **built-in** `stop_hook_active` + 8-block cap | primary doc code.claude.com/docs/en/hooks |
| **Codex** | ✅ **yes** | Stop `decision:"block"` creates a continuation prompt from `reason` (force-continue); `continue:false` precedence; JSON required on stdout | **built-in** `stop_hook_active` | primary doc developers.openai.com/codex/hooks + PR #14532 merged 2026-03-13 |
| **Copilot** | ✅ **yes** | `agentStop` `decision:"block"` "forces another agent turn using `reason` as the prompt"; stdout-JSON-on-exit-0 (NOT exit-code) | **none built-in** → Specrew must add its own | primary doc docs.github.com/copilot/reference/hooks-reference |
| **Antigravity** | ✅ **yes** | Stop `decision:"continue"` (+ `reason` injected as a system message) prevents the agent stopping and re-enters the loop; any other value allows the stop | **none built-in** → Specrew must add its own | primary doc antigravity.google docs (hooks) |
| **Cursor** | ❌ **no** | `stop` is observational/fire-and-forget; only output `followup_message` auto-submits a NEW user turn AFTER the loop ended (force-continue, not turn-end prevention) | `loop_limit` default 5 | primary doc cursor.com/docs/hooks |

## Headline

**4 of 5 hosts can genuinely block the turn-end** (Claude, Codex, Copilot, Antigravity) — my earlier "Claude-only,
everyone else is good-will" was wrong. Only **Cursor** lacks a same-turn hard block; its strongest lever is
`followup_message` (a re-triggered new turn — the human may momentarily glimpse the packet-less stop before the
appended packet turn), which is the declared degraded mode.

## Per-host caveats that shape the build (capability ≠ guaranteed enforcement)

- **Claude / Codex** — clean: documented block + a built-in loop guard. Codex's risk is WHEN it fires, not whether
  block works: Stop does NOT fire on an Esc-interrupted turn (issue #22858) and exec/headless hook-firing is
  historically flaky (memory) — so a real interactive-host validation is load-bearing before relying on it.
- **Copilot** — block works, but the hook is **fail-open** (a non-zero exit / dispatcher crash lets the turn end
  WITHOUT the packet) and has **no built-in loop guard** → best-effort, not bulletproof; Specrew must gate the
  block on its own per-session state and cap repeats via the dispatcher circuit-breaker.
- **Antigravity** — soft block (`decision:"continue"`); the model can retry stopping next loop, and there is no
  built-in loop guard → Specrew must add once-per-stop dedupe.
- **Cursor** — no hard block; `followup_message` best-effort, capped at `loop_limit` (default 5) after which the
  turn ends packet-less. Current Specrew cursor-stop emission (`{additional_context:...}`) is effectively a no-op
  for stop (cursor's stop only consumes `followup_message`) — so even the best-effort lever is not wired today.

## Design implication

This is exactly FR-004's capability matrix (each host declares its strongest lever + degraded mode) and the
enforce-or-halt north star, now backed by evidence instead of assumption:

- **block-capable hosts (Claude, Codex, Copilot, Antigravity):** at a substantive non-workshop stop where the
  last assistant message lacks the 6-section packet, emit the host's stop-block decision JSON with the packet
  directive as `reason` → force-continue → the agent renders the packet → it stops again → loop-guard (host
  built-in for Claude/Codex; Specrew once-per-stop dedupe for Copilot/Antigravity) → allow.
- **non-block host (Cursor):** emit `followup_message` (best-effort re-triggered turn) — the DECLARED degraded
  mode, dogfood-proven, never silently claimed as a hard block.

The per-host block envelope differs (`decision:block` vs `decision:continue` vs `followup_message`) — that lives
in the dispatcher's existing per-host output-shaping (`Write-InjectionOutput` / the manifest `OutputShape`),
extended with a per-host stop-block shape. The conformance Stop-provider already detects packet-absence; the
change is the DELIVERY (return a block decision instead of a next-turn stdout nudge).
