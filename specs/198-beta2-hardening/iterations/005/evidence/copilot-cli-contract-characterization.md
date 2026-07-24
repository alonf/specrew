# Copilot CLI contract characterization — INSTALLED-executable probe (F-198 iter-005 T037, spec FR-052)

**Status: CHARACTERIZATION ONLY (evidence).** No Specrew host adapter, dispatcher, or catalog was modified.
The adapter / opt-in decision is a SEPARATE step for the maintainer, informed by this evidence.

- **Task**: F-198 iteration-005 T037 — observe the INSTALLED Copilot CLI's hook-discovery + agentStop contract
  by direct executable probe; distinguish INTENTIONAL reviewer suppression from ACCIDENTAL governance bypass.
- **Spec**: FR-052 (Copilot CLI contract verification).
- **Probed**: 2026-07-14, live against the installed executable (nothing answered from memory or docs alone).
- **Installed version**: `GitHub Copilot CLI 1.0.70` (`copilot --version`).

---

## 1. Isolation attestation (non-negotiable controls — all honored)

| Control | How it was honored |
|---|---|
| Fresh scratch dir OUTSIDE the repo | All `copilot` runs executed in `%TEMP%\copilot-probe-1c7bce6609c6493f8d9af35edcb3b7bf` (and per-scenario subdirs). NO invocation ran inside `C:\Dev\specrew-beta2-hardening`. |
| Do NOT mutate persistent USER config | Every run set **`COPILOT_HOME`** (documented: "override the directory where configuration and state files are stored; defaults to `$HOME/.copilot`") to an isolated scratch home. The real `~/.copilot` was never the active config dir. |
| Snapshot before / verify after / restore if mutated | `~/.copilot` snapshotted before (2003 files: relative path + size + SHA-256). Re-snapshotted after: **BYTE-FOR-BYTE UNCHANGED — 0 differences, 2003 files**. The Specrew user hook `hooks\specrew-refocus.json` hash intact (`72E075…C9DD`). No restore needed. |
| Bounded timeouts, kill-on-timeout | Every invocation went through a bounded runner (`ProcessStartInfo` + `WaitForExit(ms)` + `taskkill /T /F` on expiry). No probe hung. |
| Record installed version | `1.0.70` (above). |
| No cloud-agent probes | Only local `copilot -p` / `copilot -i` / `copilot help`. No `--remote`, no cloud tasks. |
| Repo working tree | No probe artifact written to the repo tree (probe writes went to `%TEMP%` + the agent scratchpad). This evidence file is the only intended repo output. |

**Auth note (enables full-turn isolation):** turns completed (EXIT 0, real model output) even with `COPILOT_HOME`
redirected to an empty scratch dir — so Copilot's credential is machine-level (Windows Credential Manager / keyring),
NOT stored under `.copilot`. This let every agentStop/loop test run in COMPLETE isolation from the real user config.

---

## 2. How Specrew currently models the contract (the OBSERVE baseline — NOT rewritten)

Read from source (no speculative edit):

- **`hosts/copilot/host.psd1`** — `RefocusHookBindings`:
  - `SettingsFile = '~/.copilot/hooks/specrew-refocus.json'` (hooks-dir model, `OwnsSettingsFile = $true`).
  - `Registrations`: `sessionStart` → dispatcher `SessionStart`; `agentStop` → dispatcher `agentStop`; `TimeoutSec = 30`.
  - `DispatcherRuntime.StopBlockShape = 'decision-block'`; baked caveats: *"Copilot agentStop `{"decision":"block","reason":…}` forces another agent turn. CAVEATS: fail-open (a non-zero exit lets the turn end packet-less) and NO built-in loop guard → the provider's own consecutive-block cap is the loop guard here."*
- **`scripts/internal/specrew-hook-dispatcher.ps1`** — `Write-StopBlockOutput` emits, for `decision-block`,
  `{"decision":"block","reason":<reason>}` (compressed) on **stdout**; kill-switch check at line 46
  (`SPECREW_REFOCUS_DISABLE` → early no-op, exit 0).
- **`scripts/internal/specrew-hook-launch.ps1`** — the deployed user hook's actual command; kill-switch first
  (lines 34-37: `SPECREW_REFOCUS_DISABLE` → no-op exit 0), then resolves the project's dispatcher up-tree from
  `.specify/…/specrew-hook-dispatcher.ps1`; if none found → no-op exit 0 (fail-open).
- **`scripts/internal/continuous-co-review/reviewer-host-catalog.ps1:69`** — the reviewer invocation:
  `copilot --allow-all-tools --allow-all-paths --no-ask-user --no-custom-instructions --no-color --log-level none -p "<prompt>"`.
- **`scripts/internal/continuous-co-review/worktree-reviewer.ps1:1438`** — the reviewer spawn sets
  `$psi.Environment['SPECREW_REFOCUS_DISABLE'] = '1'` (does **not** redirect `COPILOT_HOME`); the comment states the
  reviewer inherits the environment so its OWN global Specrew hooks fire while it reviews, and the kill-switch
  makes them no-op (inherited by hook child processes).
- **Prior documented model to re-verify** — `specs/171-specrew-refocus/research-matrix.md` (docs-based, 2026-06-07):
  *"prompt hooks fire only for NEW interactive sessions (not resume, not `-p` mode)"*, explicitly flagged
  *"verify locally at binding implementation."* **This probe is that local verification.**

The deployed user hook's base64 `-HostBinding` decodes to (confirms the manifest is what is live on disk):

```json
{"BootstrapDeliveryEvents":["SessionStart"],"B3DeliveryEvents":["PostToolUse","UserPromptSubmit"],
 "RefocusTriggerByEvent":{"PostToolUse":"b3","UserPromptSubmit":"b3"},"SuppressedRefocusEvents":[],
 "OutputShape":"additionalContext","DecisionOnlyEvents":[],"BootstrapDeliveryMode":"inline",
 "StopBlockShape":"decision-block"}
```

### CLI hook surface (from `copilot --help` + `copilot help config` / `help environment`)

- `-p, --prompt <text>` — non-interactive, **exits after completion**. `-i, --interactive <prompt>` — interactive, auto-runs the prompt. `--allow-all-tools` — required for non-interactive mode.
- **No `--hooks` / `--no-hooks` CLI flag.** Hook control is CONFIG, not flag:
  - `disableAllHooks` (config, default `false`) — "disable all hooks (repo-level and user-level)".
  - `hooks` (config) — "inline hook definitions… In global `config.json` these act as **user-level** hooks; in repo `settings.json` they act as **repo-level** hooks." (Same schema as `.github/hooks/*.json`.)
  - `trustedFolders` (config) — "list of folders where permission to read or execute files has been granted." **This is the repo-hook opt-in (see §3).**
- `--no-custom-instructions` disables **AGENTS.md custom instructions only** — it does **NOT** disable hooks (separate mechanism). So the reviewer catalog's `--no-custom-instructions` is unrelated to hook suppression.
- `COPILOT_HOME` env var relocates the whole config/state/hooks dir (the isolation lever used here).

---

## 3. Observed behavior per scenario (user/repo × interactive/`-p`)

Method: an isolated `COPILOT_HOME` whose hooks write a sentinel line per fired event (event name, cwd,
and the JSON payload Copilot passes on stdin). Discovery = which sentinels appear after a bounded run.

| # | Scenario | User vs repo | Mode | Result |
|---|---|---|---|---|
| A | user hooks, every event | **user** (`$COPILOT_HOME/hooks/*.json`) | `copilot -p` | **FIRES** — `sessionStart`, `userPromptSubmitted`, `agentStop` all fired; turn completed (`hello`). |
| F | user hooks, every event | **user** | `copilot -i "…"` (interactive) | **FIRES** — `sessionStart`, `userPromptSubmitted`, `agentStop` all fired. |
| C1 | repo hooks (`.github/hooks/*.json`), fresh **untrusted** git project | **repo** | `copilot -p` | **DOES NOT FIRE** — turn completed (`ok`) but no repo hook fired. |
| C2 | same repo hooks, project added to `trustedFolders` | **repo** | `copilot -p` | **FIRES** — all repo events fired. Only change between C1→C2 was the trust entry. |

### Observed event payloads (`-p`, new session)

- `sessionStart`: `{"sessionId","timestamp","cwd","source":"new","initialPrompt":…}` — **`source:"new"`** for a fresh `-p` session (relevant to the B1 post-compaction `source` question: a compaction `source` value was not observed here because single-shot `-p` performs no compaction).
- `userPromptSubmitted`: `{"sessionId","timestamp","cwd","prompt":…}`.
- `agentStop`: `{"sessionId","timestamp","cwd","transcriptPath","stopReason":"end_turn"}`.

### Does `-p` need an opt-in to load PROJECT/REPO hooks? — YES, and the exact opt-in

- **`-p` does NOT load repo/project hooks by default** (C1: untrusted fresh project → repo hooks silent, even with `--allow-all-tools`).
- **The opt-in is FOLDER TRUST**: the project folder must appear in **`trustedFolders`** (written to `$COPILOT_HOME/settings.json`). Once trusted, `-p` loads and fires repo hooks (C2).
- Interactive mode grants trust via a prompt the first time a folder is opened; `-p` is non-interactive and cannot prompt, so an **untrusted** folder's repo hooks are **silently skipped** — this is the accidental-bypass surface (see §5). `--allow-all-tools` / `--allow-all` do NOT auto-trust for hook-loading purposes (C1 used `--allow-all-tools`).
- **USER-level hooks are NOT trust-gated** — they fired in `-p` from an untrusted cwd (A, F). Specrew's governance rides the USER-level hook (`~/.copilot/hooks/specrew-refocus.json`), so it is **not** subject to the repo-trust gate.

---

## 4. agentStop contract — blocking / continuation / allow / loop / fail-open

Probe: an isolated user hook that emits `{"decision":"block","reason":"PROBE-BLOCK #N…"}` on stdout (exit 0) up
to a durable per-run counter cap, then emits nothing.

- **BLOCK forces another agent turn** — each `{"decision":"block","reason":…}` produced another turn (verified 2×, then 5×).
- **`reason` delivery = a NEW user prompt** — on every continuation, **`userPromptSubmitted` fired again** and the model responded to the `reason` text as if the user had typed it. This is a **re-prompt / new turn**, NOT a Claude-style same-turn continuation. Matches the docs' "forces another agent turn using `reason` as the prompt."
- **ALLOW terminates** — when agentStop emitted nothing (cap reached / no decision), the session ended (EXIT 0).
- **Loop scope** — every continuation stayed within **one `sessionId`** (new turns, same session). `sessionStart` fired **once** per session; `userPromptSubmitted` + `agentStop` are per-turn.
- **NO built-in loop guard** — Copilot honored **5 consecutive blocks** with no self-imposed stop; only the probe's own counter terminated it. Confirms the manifest caveat: Specrew's conformance-provider consecutive-block counter is the SOLE loop guard. (`--max-autopilot-continues`, default 5, is an autopilot-mode control and did NOT cap `-p` agentStop blocking. The exact ceiling beyond 5, if any, was not probed — cost-bounded.)
- **Delivery channel** — the block is honored via **stdout JSON at exit 0** (the probe hook wrote JSON to stdout and exited 0). Confirms "stdout-JSON-on-exit-0, NOT exit-code."
- **FAIL-OPEN on malformed / failing agentStop** — three invalid outputs were each tested and **all let the turn end cleanly with no block, no loop, no hang**:
  - non-decision garbage text on stdout → turn ended (fail-open);
  - truncated/invalid JSON (`{"decision":"block"`) → turn ended (fail-open — a malformed block does NOT block);
  - non-zero exit (exit 1) → turn ended (fail-open).
  Implication: the block works ONLY with a well-formed `{"decision":"block","reason":…}` at exit 0; any dispatcher crash, non-zero exit, or malformed stdout silently degrades to a packet-less turn-end.

---

## 5. Reviewer suppression (INTENTIONAL) vs downstream governance bypass (ACCIDENTAL) — the required distinction

Probe D: an isolated user hook that faithfully replicates the launcher kill-switch — if `SPECREW_REFOCUS_DISABLE`
is set it logs `HOOK_FIRED=YES` then no-ops (emits nothing); otherwise it injects governance context. Run through
REAL Copilot firing, both ways:

| Run | Env | Hook fired? | Result |
|---|---|---|---|
| D1 — normal governed `-p` | (none) | **YES** | `RESULT=GOVERNED` — additionalContext injection emitted. |
| D2 — reviewer-mode `-p` | `SPECREW_REFOCUS_DISABLE=1` | **YES** | `RESULT=SUPPRESSED` — kill-switch no-ops it; no injection. |

**The load-bearing distinction:**

- **INTENTIONAL reviewer suppression** = the hook **FIRES**, then the launcher/dispatcher kill-switch
  (`SPECREW_REFOCUS_DISABLE=1`, set on the reviewer process at `worktree-reviewer.ps1:1438`, inherited by hook
  children) makes it a **deliberate no-op**. Because `copilot -p` DOES fire user hooks (§3), the real
  `~/.copilot/hooks/specrew-refocus.json` fires during a review — and it is the env-var, not any load failure,
  that stops it governing itself. Deliberate, process-scoped, reversible.
- **ACCIDENTAL downstream bypass** = the hook **does NOT fire at all**, so governance is silently absent with no
  deliberate gate. Empirically this **does NOT happen for USER-level hooks in `-p`** (A/F: they fire). It **DOES
  happen for REPO-level hooks in an untrusted `-p` folder** (C1) — repo hooks silently skipped with no error.

So the two are cleanly separable by a single observable: **did the hook fire?** Reviewer suppression = *fired then
env-gated no-op*. Accidental bypass = *never fired*. Specrew avoids the accidental-bypass surface by delivering
governance through the USER-level hook (not trust-gated), and suppresses the reviewer via the env kill-switch.

**Adapter-relevant caution (for the maintainer's separate decision, NOT acted on here):** IF Specrew ever routes
`-p`-mode governance through a **repo-level** hook, it would be silently gated in any **untrusted** folder. Per
FR-052 the resolution must be EITHER set the documented opt-in (add the folder to `trustedFolders`) whenever
governance is expected, OR report that mode `unsupported` — never silently claim it is gated. The current
user-level delivery sidesteps this; a repo-level path would not.

---

## 6. Deltas vs the prior documented model

- **CONFIRMED**: agentStop `{"decision":"block","reason":…}` blocks + force-continues; `reason` becomes the next prompt; allow terminates; stdout-JSON-at-exit-0; **no built-in loop guard**; **fail-open** on non-zero exit. `StopBlockShape='decision-block'` matches the live deployed hook.
- **NEWLY VERIFIED**: the repo-hook `-p` opt-in is **folder trust** (`trustedFolders`); user hooks are not trust-gated; `agentStop.stopReason="end_turn"` and `sessionStart.source="new"` payloads; malformed/truncated block JSON also fails open (not just non-zero exit).
- **OVERTURNED** (for 1.0.70): the 2026-06-07 research-matrix caveat *"prompt hooks fire only for NEW interactive sessions (not `-p` mode)"* is **empirically false** — `sessionStart`, `userPromptSubmitted`, and `agentStop` all fire from user-level hooks in `copilot -p`. The "verify locally" flag on that line resolves to: **`-p` DOES fire user lifecycle hooks.**

---

## 7. Limitations / honest gaps (not infra failures — no infra failure occurred)

- **Resume mode not probed** — only NEW `-p` and NEW interactive (`-i`) sessions were tested. Hook firing under `--resume`/`--continue` was not exercised (the governance-relevant path is new sessions).
- **Interactive repo-hook trust prompt not driven** — the repo-hook trust gate was verified on the `-p` side (C1/C2). The interactive first-open trust prompt is inferred from the `trustedFolders` config model, not separately driven headlessly (a TUI trust prompt needs a real PTY).
- **Repo-hook location** — verified the `.github/hooks/*.json` dir form. The alternative `.github/copilot/settings.json` `hooks`-key form (also documented) was not separately exercised.
- **Loop-guard ceiling above 5** — verified NO guard through 5 consecutive blocks; the exact built-in ceiling (if any) beyond 5 was not probed to bound AI-credit cost.
- **No infra failures.** Every probe ran to a clean, bounded result; auth worked under `COPILOT_HOME` redirection.

---

## 8. Appendix — reproduction

- Isolation lever: `COPILOT_HOME=<scratch>` per run; bounded runner with `taskkill /T /F` on timeout.
- Probe root: `%TEMP%\copilot-probe-1c7bce6609c6493f8d9af35edcb3b7bf` (disposable).
- Representative non-interactive invocation:
  `copilot -p "<prompt>" --allow-all-tools --no-color --log-level none` with `COPILOT_HOME` set to a scratch home containing `hooks/probe.json` (sentinel hooks per event).
- Repo-hook opt-in reproduction: write `$COPILOT_HOME/settings.json` = `{"trustedFolders":["<project>"]}` → repo `.github/hooks/*.json` then fires in `-p`.
- agentStop block reproduction: sentinel hook emits `{"decision":"block","reason":"…"}` on stdout at exit 0 → forces a continuation turn (reason as new prompt).
- Reviewer-suppression reproduction: same hook run with `SPECREW_REFOCUS_DISABLE=1` in the process env → hook fires but no-ops.
- Baseline/after `~/.copilot` snapshots retained in the probe dir (`baseline-usercopilot-snapshot.txt`, `after-usercopilot-snapshot.txt`) — 2003 files, 0 diff.
