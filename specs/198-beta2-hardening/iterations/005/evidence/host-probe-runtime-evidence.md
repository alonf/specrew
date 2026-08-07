# Host-support probe runtime evidence (F-198 FR-051/FR-052; review finding f2, run 20260714T215545754)

**Purpose**: the DIGEST-BOUND runtime evidence that backs the `codex/cli` and `copilot/cli` `verified`
host-support tiers — the reviewer's f2 finding demanded reproducible, digest-matched recorded-run evidence of
the actual host probes rather than one-off session characterization. These probes are COMMITTED and
REPLAYABLE from a fresh checkout; their recorded runs bind to the reviewed digest via the T018 recorder.

## The committed, replayable probes

- **`tests/host-probes/codex-stop-contract-probe.ps1`** — drives the installed `codex exec` headless surface
  and asserts the response-shape contract STRUCTURALLY (fire-count of a sentinel-appending Stop hook; no
  dependence on model output): `{"decision":"block"}` GATES (force-continues → the Stop hook re-fires, ≥2
  fires), `{}` allows (1 fire, no continue), and the Codex-manual `{"continue":…}` shape does NOT gate (1
  fire). Emits a `SpecrewTestResult`.
- **`tests/host-probes/copilot-hook-firing-probe.ps1`** — drives the installed `copilot -p` headless surface
  and asserts the FR-052 distinction: USER-level hooks FIRE from an UNTRUSTED cwd (governance rides the user
  hook; not trust-gated), while REPO-level hooks from an untrusted folder do NOT fire (the `trustedFolders`
  gate). Emits a `SpecrewTestResult`.

Both probes run in scratch dirs OUTSIDE the repo with `CODEX_HOME` / `COPILOT_HOME` redirected, snapshot the
real user-config files (sha256) before and VERIFY them byte-unchanged after, use bounded timeouts with
tree-kill, and DEGRADE HONESTLY: if the CLI or its auth is absent, the probe emits `result='skipped'` (never a
false green) — so a reviewer worktree without the installed CLI records `unverifiable-here`, and a real green
requires the CLI + auth (the maintainer's machine, where the evidence binds).

## Recorded runtime results (2026-07-15, this machine)

- **codex probe** (`codex-cli 0.144.4`): **3/3 PASS** — A (allow, 1 fire) · C (block gates, ≥2 fires) · D
  (continue-shape does not gate, 1 fire); real `~/.codex` config byte-unchanged (3 files).
- **copilot probe** (`GitHub Copilot CLI 1.0.70`): **2/2 PASS** — user hooks fire in `-p` from an untrusted
  cwd; repo hooks do not fire untrusted; the real Specrew user-hook file byte-unchanged.

Recorded via `Invoke-ContinuousCoReviewRecordedRun` with `-RequireResult` against each probe's
`SpecrewTestResult` at the reviewed digest; the digest-keyed machine records live in the co-review
evidence store (`.specrew/review/test-evidence/<committed-digest>.json`, `command_succeeded=true`,
`counts.passed` = the scenario count, `failed = 0`).

## Honest scope (what these probes do and do NOT claim)

- They reproduce the RUNNER-OBSERVABLE headless contract that backs the `verified` tiers' response-shape
  gating (codex) and user-hook firing / trust distinction (copilot).
- They do NOT reproduce the codex INTERACTIVE trust-prompt acquisition — a PTY-less probe environment cannot
  drive it. That remains HUMAN-OBSERVED provenance (the maintainer exercised it 2026-07-14), recorded on the
  `codex/cli` tier row and in the T036 characterization, and is honestly labeled as human-observed, never
  claimed as runner-reproduced.
- The tier rows in `host-support-tier.ps1` now cite these probe scripts as the runner-observed evidence
  source; the provenance TRAVELS WITH the claim (a bare `verified` is never surfaced).
