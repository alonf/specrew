# Reviewer-Result-Delivery — Cross-Harness Capability Survey (iter-007, 2026-06-25)

**Question:** today continuous co-review fires async at a Stop hook and the verdict is only collected at the
agent's NEXT stop. The maintainer wants the agentic-harness pattern — **dispatch → don't block → be WOKEN
with the result** (Claude's background-task + completion-notification). Can each host do that natively, or must
it fall back to a portable floor? Surveyed via 5 parallel researchers (primary sources: official docs + each
CLI's own `--help`/binary, locally where installed). Honest-uncertainty mandate; Claude row corrected from
direct in-session evidence (the survey itself ran on the mechanism in question).

## Capability matrix (co-review-relevant view)

| Host | Idle AUTO-WAKE (push) | Bg dispatch → block-collect | Turn-end hook BLOCK+INJECT | Sync blocking cmd (cap) | User `/review` trigger | Self-poll timer |
|---|---|---|---|---|---|---|
| **Claude Code** | ✅ event push (task/bg + completion notify) | ✅ Task/bg + notify | ✅ `Stop` block+inject (~10K out cap) | ✅ ~10 min | skills | ✅ `/loop`/ScheduleWakeup (~1m–1h, 7-day) |
| **Copilot CLI** v1.0.65 | ❌ no idle-push | ✅ `task mode:background` + `read_agent wait:true` (~300s) | ⚠️ `stop` hook — **OFF in `-p` by default** (`GITHUB_COPILOT_PROMPT_MODE_REPO_HOOKS=true`) | ✅ **60 min** | ✅ `/review` + `/security-review` + bundled `code-review.agent.yaml` | ⚠️ `/every`/`/after` (experimental, session-lifetime only) |
| **Gemini CLI** v0.43 (Antigravity headless path) | ❌ native (3rd-party tmux MCP only) | ⚠️ subagent — **synchronous/blocks** (~10 min) | ✅ `AfterAgent` **deny+feedback → agent retries** (Claude-compat hooks, `hooks migrate`) | ✅ **~5 min** (tight) | ⚙️ custom TOML commands | ❌ |
| **Codex CLI** v0.142 | ❌ (`notify` fires **outward** on `agent-turn-complete`) | ⚠️ subagent — synchronous/blocks | ⚠️ `Stop` exists; **`SessionStart` does NOT fire under `codex exec` headless** (empirical) | ✅ no documented cap | ✅ `/review` | ❌ |
| **Cursor-agent** 2026.06 | ❌ ("background agents" = cloud-VM/IDE-notify, different surface) | ❔ headless unverified | ⚠️ `stop` followup loop — **does NOT fire headless `-p`** (empirical; contradicts a staff claim) | ✅ unknown cap | ⚠️ interactive only (`-p` non-interactive) | ❌ headless |
| **Antigravity** (app) | ❔ async-first by design (bg agents + **Inbox**) but Inbox notifies the **HUMAN**, not the agent loop; agent-auto-wake **Unknown/contested** (Inbox reportedly removed) | ❔ | ⚠️ JSON hooks (events not enumerated) | ❔ | ⚠️ `/schedule` claimed, contested | ❔ contested |

Human pause/resume = ✅ on **all** hosts (approval models + `--resume`/`--continue`) — the reliable bottom floor.

## The three-tier reading

1. **Idle auto-wake (push) — Claude ONLY.** A completed background review re-injects into the live agent's
   turn with no agent action. Confirmed unique today (the maintainer's "best mechanism is what Claude has" is
   literally true). Copilot is the near-miss (background subagent + `read_agent wait:true` is dispatch+collect,
   but not idle-push).
2. **Turn-end hook BLOCK+INJECT ("reap-with-teeth") — portable-ish MIDDLE.** Most hosts can, at the next
   turn-end, BLOCK the agent and inject the verdict so it must be addressed before proceeding: Claude `Stop`,
   Gemini `AfterAgent` (deny+feedback→retry), Copilot `stop`, Cursor `stop`-followup, Codex `Stop`. **BUT
   headless reliability is the catch:** Codex `SessionStart` dead under `exec`; Cursor `stop` dead headless;
   Copilot hooks off in `-p` by default. Gated per host.
3. **Blocking synchronous review — UNIVERSAL FLOOR.** Every host can run a review command and wait inline
   (`Invoke-LiveReview` / a host subagent), capped by the host's shell timeout: Gemini ~5m (tightest), Claude
   ~10m, Copilot ~60m, Codex/Cursor uncapped-or-unknown. Plus user-triggered `/review` (Codex, Copilot
   built-in) and the human-gated poll. This is the guarantee that works everywhere.

## Design implication — floor + accelerators (per-host adapter, Proposal-139 seam)

- **FLOOR (all 5, the host-neutral guarantee):** agent runs a BLOCKING synchronous review and waits, OR the
  human triggers `/review`, OR async-fire + human-gated poll (`specrew review --status`/`--wait`). Reviews must
  fit the host's shell-timeout (chunk if not).
- **ACCEL tier 1 — hook block+inject reap** where the turn-end hook fires reliably (interactive Claude/Codex/
  Copilot/Cursor; Gemini `AfterAgent`): the navigator's next-turn reap BLOCKS + injects the verdict.
- **ACCEL tier 2 — true async auto-wake:** Claude native (background task + notification); Copilot near-native
  (`task` bg + `read_agent wait`/`/after`). Best UX where available; everyone else degrades to tier-1/floor.
- Per-host adapter selects the HIGHEST tier the host supports — same seam as the reviewer-host adapters and
  the read-only-posture flags.

## Caveat that bites Specrew TODAY

Specrew's current co-review **relies on the Stop hook** (fire at Stop, reap at next Stop). The survey shows the
turn-end hook is **NOT uniformly reliable headless** (Codex `exec`, Cursor `-p`, Copilot `-p`). The EnglishIntake
codex fire worked because it was **interactive** (interactive codex DOES fire). So target **interactive
hook-firing** for the reap accelerator and the **blocking-command floor** for headless — do not assume the Stop
hook fires headless on Codex/Cursor/Copilot.

## Maintainer's three fallback ideas — all validated

- "Claude auto-wait for background" → Claude's native auto-wake (the only host).
- "other hosts: recommend the user run the review as a slash command" → Codex `/review`, Copilot `/review`
  (+ bundled code-review agent) are built-in; Gemini/Cursor via custom/interactive slash.
- "run in background + ask the user to type when to check / continue" → the human-gated poll floor (all hosts;
  human pause/resume is universal).
