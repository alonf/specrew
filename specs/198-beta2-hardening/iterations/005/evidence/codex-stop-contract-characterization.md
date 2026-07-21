# Codex Stop-contract characterization (F-198 iter-005 T036, spec FR-051)

**Status:** CHARACTERIZATION ONLY — evidence for maintainer review. **No adapter was modified. No commit was made.**
**Date observed:** 2026-07-14 (UTC)
**Installed Codex under test:** `codex-cli 0.144.1`
(`codex --version` → `codex-cli 0.144.1`; executable `C:\Users\alon\AppData\Local\Programs\OpenAI\Codex\bin\codex.exe`; `codex doctor` reports `0.144.3` is available. All probing done against the installed **0.144.1**.)

---

## 1. Headline — the OBSERVED Codex 0.144.1 Stop contract

| Question | Observed answer |
|---|---|
| **Which response shape GATES a Stop force-continue?** | **`{"decision":"block","reason":"..."}` on the hook's STDOUT, exit 0.** This — and only this — force-continues the turn. |
| Does the Codex-manual shape `{"continue":…,"stopReason":…,"systemMessage":…}` gate? | **NO.** Neither `continue:false` nor `continue:true` force-continues; `stopReason`/`systemMessage` are never surfaced. Treated as a plain allow. |
| Does exit code 2 gate (Claude's alternate lever)? | **NO.** Exit 2 + stderr reason is ignored; the stop proceeds. |
| Does the block `reason` reach the next turn? | **YES.** `reason` becomes the continuation prompt — the model received and echoed the exact sentinel from the reason on the next turn. |
| Does allowing Stop (`{}`) terminate? | **YES.** `{}` (or malformed/empty) → the turn completes and exec exits 0. |
| Loop guard? | **Advisory `stop_hook_active` flag** in the Stop input: `false` on the first fire, `true` on every re-fire. **No hard cap observed** (an unconditional blocker looped 26× until the external timeout). Honoring the flag (return `{}` when `true`) terminates cleanly after exactly one force-continue. |
| Does malformed hook output fail VISIBLY? | **NO — silent clean pass.** Non-JSON stdout is ignored with no parse error, no warning, exit 0. The gate fails OPEN. |
| Hook discovery (headless `exec`)? | User-level `$CODEX_HOME/hooks.json` **and** project-level `<cwd>/.codex/hooks.json` are both discovered and fire — **but only if the hook is TRUSTED or `--dangerously-bypass-hook-trust` is passed.** |
| **Trust gate?** | **Untrusted hooks are SILENTLY skipped headlessly** (no receipt, no warning, exit 0). This is the dominant real-world risk, not the response shape. |

### Verdict on FR-051

Specrew's **current model is CORRECT and now VERIFIED** for Codex 0.144.1's headless surface:
`RefocusHookBindings.DispatcherRuntime.StopBlockShape = 'decision-block'` → `{"decision":"block","reason":…}` is exactly the shape that gates. The Codex-manual `{"continue":…,"stopReason":…,"systemMessage":…}` shape that FR-051 flagged as a candidate **does NOT work** on this version — do NOT switch the adapter to it. `DecisionOnlyEvents = ['Stop']` emitting `{}` for non-block Stop is also correct (empty = allow).

**The real gaps the Codex host integration must close are NOT the response shape** — they are (1) the hook **trust gate** (silent headless skip) and (2) malformed/allow both **failing open silently**. See §7.

---

## 2. Hook I/O contract (as Codex 0.144.1 actually delivers it)

**hooks.json format consumed by 0.144.1 = exactly what Specrew deploys today.** The real machine's `~/.codex/hooks.json` (Specrew-deployed, untouched by this probe) and the probe's isolated copy both use:

```json
{ "hooks": { "<Event>": [ { "hooks": [ { "type":"command", "command":"…", "timeout":30 } ] } ] } }
```

Events keyed in **PascalCase** in hooks.json (`SessionStart`, `UserPromptSubmit`, `Stop`); Codex normalizes them to **snake_case** internally (`session_start`, `user_prompt_submit`, `stop`) for the trust-state keys in `config.toml`.

**Stop hook STDIN payload** (Claude-compatible — this is what the hook receives):

```json
{
  "session_id": "019f5d73-…",
  "turn_id": "019f5d73-…",
  "transcript_path": "…/.codex/sessions/2026/07/14/rollout-…jsonl",
  "cwd": "…",
  "hook_event_name": "Stop",
  "model": "gpt-5.6-sol",
  "permission_mode": "bypassPermissions",
  "stop_hook_active": false,
  "last_assistant_message": "PONG"
}
```

Note `stop_hook_active` (loop guard) and `last_assistant_message` (lets a Stop hook inspect whether the required content was rendered — the mechanism Specrew's packet-at-stop check relies on) are both present, exactly like Claude.

**SessionStart STDIN payload:** `{session_id, transcript_path, cwd, hook_event_name:"SessionStart", model, permission_mode, source:"startup"}`.

**Hook response is read from STDOUT as JSON on exit 0.** Exit code and stderr are NOT consulted for gating.

---

## 3. Per-scenario evidence

All runs: `codex exec --json --skip-git-repo-check --dangerously-bypass-approvals-and-sandbox -C <scratch> "<trivial prompt>" </dev/null`, `CODEX_HOME=<scratch>/.codex`, bounded `timeout`. `--dangerously-bypass-hook-trust` added except where noted (Scenario B). Prompt: *"Reply with exactly the single word: PONG …"*. Block `reason` instructed the model to append a unique sentinel `REASONREACHED_<nonce>`.

| # | Response shape emitted by hook | Trust | Stop fires | Result | Interpretation |
|---|---|---|---|---|---|
| **A** | `{}` (empty), events SessionStart+Stop | bypass | **2 receipts (both events)** | turn.completed, exit 0, msg "PONG" | Stop **fires in headless exec**; `{}` **allows** → terminates. Baseline. |
| **B** | `{}` | **none** | **0 receipts** | turn.completed, exit 0, **no warning** | **Untrusted hook silently skipped.** Trust gate = silent fail-open. |
| **C** | `{"decision":"block","reason":"…REASONREACHED_C1…"}` (unconditional) | bypass | **26 fires / ~86 s until timeout (exit 124)** | model echoed `REASONREACHED_C1` on every continuation | **`decision:block` gates** → force-continue; **reason reaches next turn**; no hard loop cap. `stop_hook_active` = `false` (fire 1) then `true` (fires 2–26). |
| **D** | `{"continue":false,"stopReason":"STOPREASON_D1","systemMessage":"SYSMSG_D1"}` | bypass | 1 fire | turn.completed, exit 0; `STOPREASON_D1`/`SYSMSG_D1` never surfaced | **Codex-manual shape does NOT gate** (continue:false variant). No-op allow. |
| **CT** | `{"continue":true,"systemMessage":"…"}` | bypass | 1 fire | turn.completed, exit 0; no continuation | **Codex-manual shape does NOT gate** (continue:true variant either). |
| **E** | `THIS_IS_NOT_JSON_… {{{ <<<` (malformed) | bypass | 1 fire | turn.completed, exit 0; **no parse error / no warning** | **Malformed = silent clean pass.** Gate fails OPEN. |
| **F** | `decision:block` on fire 1, `{}` when `stop_hook_active` true | bypass | **2 fires** | force-continue once (echoed `REASONREACHED_F1`) then allow → turn.completed, exit 0 | **Honoring `stop_hook_active` terminates cleanly** — the correct pattern (matches Specrew's consecutive-block counter). |
| **G** | stderr "EXIT2REASON_G1", **exit code 2** | bypass | 1 fire | turn.completed, exit 0; reason never surfaced | **Exit-2 does NOT gate** (unlike Claude). |
| **PH** | `{}` at project-level `<cwd>/.codex/hooks.json`; CODEX_HOME has NO hooks.json | bypass | **1 fire** | turn.completed, exit 0 | **Project-level hook placement is discovered and fires.** |

`--dangerously-bypass-hook-trust` emits a **visible audit event** in the `--json` stream each run:
``{"type":"error","message":"`--dangerously-bypass-hook-trust` is enabled. Enabled hooks may run without review for this invocation."}``

---

## 4. Discovery rules (per surface)

- **Non-interactive `codex exec` (the surface Specrew's reviewer host adapter uses):** hooks ARE discovered and DO fire — at **both** `$CODEX_HOME/hooks.json` (user) and `<cwd>/.codex/hooks.json` (project). Firing is **gated by hook trust** (see §5).
- **Interactive `codex` (TTY):** **NOT observable in this harness** — Codex 0.144.1 refuses non-TTY interactive invocation (`Error: stdin is not a terminal`), and this execution environment has no PTY (`codex doctor` confirms `stdin/stdout/stderr is terminal = false`). This is an **infrastructure limitation of the probe environment, not a Codex failure.** The real machine's `config.toml` carries persisted `[hooks.state]` `trusted_hash` entries for the Specrew hooks, which is direct evidence that interactive trust was established previously and the interactive hooks do fire there. The **response-shape contract is the same hook engine** across surfaces; the surface-specific difference is trust acquisition (interactive can prompt; headless cannot).
- **`-p` / prompt mode:** N/A for Codex — `codex exec`'s `-p` is `--profile` (config-profile overlay), not a prompt flag. Headless prompting is `codex exec [PROMPT]` or stdin.

---

## 5. The trust gate (root cause of "flaky headless hook-firing")

Codex 0.144.1 gates every hook behind a **persisted trust hash**. In `$CODEX_HOME/config.toml`:

```toml
[hooks.state.'C:\Users\alon\.codex\hooks.json:stop:0:0']
trusted_hash = "sha256:ee3693c4…"
```

(keyed `<hooks.json-absolute-path>:<snake_case_event>:<idx>:<idx>`).

- Interactive Codex can PROMPT to approve a hook and record its `trusted_hash`.
- **Headless `codex exec` cannot prompt → an untrusted hook is SILENTLY skipped** (Scenario B: no receipt, no diagnostic, exit 0).
- `codex exec --dangerously-bypass-hook-trust` runs untrusted hooks for that one invocation and does **NOT** persist trust (verified: the isolated `config.toml` gained no `[hooks.state]` after the bypass runs). It emits the visible audit event quoted above.
- `codex doctor` output has **no hooks/trust health section** — it will not tell Specrew whether a hook is trusted or ever fired (relevant to FR-053: doctor is not a hook-health oracle; a receipt-based probe is needed).

---

## 6. How this maps to Specrew's current Codex model

Current model (`hosts/codex/host.psd1`, `scripts/internal/specrew-hook-dispatcher.ps1`, and the 185 `stop-block-capability-matrix.md`):

- `StopBlockShape = 'decision-block'` → **CONFIRMED correct** for 0.144.1.
- `DecisionOnlyEvents = ['Stop']` emitting `{}` for non-block Stop → **CONFIRMED correct** (empty allows).
- 185 matrix claim "Codex Stop `decision:block` … + built-in `stop_hook_active`" → **CONFIRMED**, with one refinement: the built-in piece is the `stop_hook_active` **flag**; it is **advisory** (the hook must honor it) and there is **no observed hard iteration cap** — do not rely on Codex to self-terminate a runaway blocker. Specrew's own consecutive-block counter is load-bearing (as the 145 HANG analysis already assumed).
- 185 matrix caveat "risk is WHEN it fires (headless flaky)" → **CONFIRMED and root-caused**: the flakiness is the **hook-trust gate**, not the block capability.

---

## 7. Implications for the adapter step (NOT done here — for maintainer decision)

The response shape needs **no change**. The load-bearing follow-ups the observed contract surfaces:

1. **Trust gate (highest priority).** Specrew-deployed Codex hooks fire in interactive sessions only after trust is established; **headless/governed-exec contexts silently skip untrusted hooks.** Options to weigh: seed/verify the `trusted_hash` at deploy time; pass `--dangerously-bypass-hook-trust` for Specrew-owned headless invocations (already the reviewer's doctrine of running codex in a disposable trusted worktree); and have hook-health (FR-053) detect never-fired/untrusted rather than assuming a deployed config is live.
2. **Fail-open on malformed + allow.** Codex does not flag malformed hook stdout — the dispatcher MUST guarantee well-formed `{"decision":"block","reason":…}` (or `{}`), because a malformed emit becomes a silent governance bypass.
3. **Advisory loop guard.** Keep honoring `stop_hook_active` / the consecutive-block counter; Codex will not cap the loop for us.

---

## 8. Isolation attestation

- **Scratch root (all probe work, outside the repo):** `C:\Users\alon\AppData\Local\Temp\codex-probe-6b80b5e288a54e53aece938313b5ea1c`. The governed repo cwd was NEVER entered to run Codex; no probe ran inside `C:\Dev\specrew-beta2-hardening`.
- **User-config isolation via `CODEX_HOME`:** every Codex invocation set `CODEX_HOME` to a scratch `.codex` (auth.json copied read-only from the real dir so exec could authenticate; a minimal `config.toml`). The real `~/.codex/hooks.json` was **read only** (to learn the real format), never written.
- **Real `~/.codex` config files — BEFORE vs AFTER (SHA-256):**
  - `hooks.json`  `B8B7092EF4681D90…` → `B8B7092EF4681D90…` — **UNCHANGED**
  - `config.toml` `84E7B3470ECDB459…` → `84E7B3470ECDB459…` — **UNCHANGED**
  - `auth.json`   `53AB0E54074AAAC5…` → `53AB0E54074AAAC5…` — **UNCHANGED**
  - Top-level churn since BEFORE was limited to volatile sqlite WAL/SHM files (`memories_1.sqlite-wal/shm`, `goals_1/state_5` WAL/SHM) produced by **unrelated live Codex processes on this machine** (locked at snapshot time), NOT by this probe — every probe run used `CODEX_HOME=scratch`. **No restore was required (nothing in the real config was mutated).**
- **Bounded timeouts:** every invocation was wrapped in `timeout` with kill-on-expiry (15–150 s). One run (Scenario C, unconditional blocker) hit its 90 s timeout **by design** to characterize the absent hard loop-cap; it was killed, not hung.
- **No cloud-agent probes.** Only the local installed CLI (`codex exec`, `codex doctor`, `codex --help`) was exercised.

### Infrastructure notes / honest limitations

- **Interactive (TTY) Stop-firing could not be observed** — no PTY in this environment; Codex refuses non-TTY interactive (`stdin is not a terminal`). Characterization covers the **headless `exec` surface** (what the reviewer host adapter uses) plus the shared hook-engine contract. Interactive-surface Stop-block firing should be dogfood-verified separately on a real terminal before relying on it for interactive governance.
- No infra FAILURES occurred (auth worked, exec ran, hooks fired). The only "non-clean" exit was the intentional Scenario-C timeout (exit 124).

---

## 9. Maintainer decision + evidence provenance (2026-07-14)

**Decision:** Flip the `codex` / `cli` host-support tier from `unverified` → **`verified`** (recorded in
`scripts/internal/continuous-co-review/host-support-tier.ps1`, the `codex`/`cli` row, with the provenance +
limitation fields below). This is NOT a bare `verified`: the claim travels with an HONEST split of what was
runner-observed vs human-observed, plus the narrower headless-trust limitation kept SEPARATE from the flip.

**Evidence PROVENANCE (what was observed, and how):**

1. **Stop response-shape gating — RUNNER-OBSERVED (the T036 executable probe, §3 above).** The isolated
   `codex exec` fixture proved that `{"decision":"block","reason":…}` on the hook's stdout at exit 0 is the shape
   that force-continues the turn (Scenario C), that the `reason` reaches the next turn, and that the
   **Codex-manual `{"continue":…,"stopReason":…,"systemMessage":…}` shape does NOT gate** (Scenarios D / CT).
   This is machine-observed behavior of the installed CLI, not a doc reading. Specrew's
   `StopBlockShape = 'decision-block'` is therefore confirmed against the runner.

2. **Interactive trust prompt + subsequent hook execution — HUMAN-OBSERVED (this session).** The maintainer
   exercised the interactive path directly: **Codex displayed its native trust request, the maintainer approved
   it, and the Specrew hook then executed** in that real interactive Codex session. That firsthand observation —
   not the PTY-less fixture — is the evidence for interactive-surface governance. (The §4 / §8 note that the
   isolated harness could not drive interactive stands as an *infrastructure* limitation of the probe box, and is
   now superseded for the trust-acquisition question by this direct human observation.)

**NARROWER headless limitation — recorded SEPARATELY (NOT a whole-CLI downgrade):**

- A **trusted / previously-observed** headless `codex exec` hook **fires and is supported** (Scenario A; the real
  machine's persisted `[hooks.state] trusted_hash`, §5, is direct evidence trust was established there).
- An **UNTRUSTED** headless hook is **silently skipped** (Scenario B) — so for that specific case governance MUST
  **fail / degrade before it is relied upon** (seed/verify the `trusted_hash`, or pass
  `--dangerously-bypass-hook-trust` for Specrew-owned headless invocations, per §7).
- This limitation is a property of the **untrusted-headless** case only. It does **NOT** downgrade the Codex CLI
  surface, and specifically it is **not** a reason to hold the tier at `unverified` just because the isolated,
  PTY-less fixture could not itself drive the interactive trust prompt — the maintainer drove it directly (above).

**Distinct from reviewer suppression.** The reviewer path's INTENTIONAL hook suppression (the reviewer spawns
with `SPECREW_REFOCUS_DISABLE=1` so its own Specrew hooks fire-then-no-op — a reviewer must not govern itself) is
a *deliberate, env-gated* no-op and is kept DISTINCT from this untrusted-headless *silent skip*; the two are not
conflated. (See the Copilot characterization §5 for the general fired-then-suppressed vs never-fired distinction.)
