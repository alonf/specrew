---
proposal: 181
title: Live Cross-Host E2E Automation — rotating real-host CI harness (Foundry-brokered keys) asserting hook/stop/handover behavior, time-boxed + change-gated nightly
status: candidate
phase: phase-2
estimated-sp: 20-30 (per-host auth-feasibility-dependent; see Open Questions)
priority-tier: 2
discussion: surfaced 2026-06-10 during the Feature 174 cross-host handover-validation dogfood. BOTH of F-174's serious bugs — the stale handover-provider mirror (silent fail-open, no rolling handover written on ANY host) and the Claude lifecycle-entry skip — reached a hand-driven three-host trial because NO automated test exercises the actual hook-driven RUNTIME behavior (SessionStart bootstrap + banner, gate stops, rolling handover at Stop) against a real AI host. Proposal 042 explicitly deferred real-host CI as cost-prohibitive; this proposal makes it affordable via host rotation + a hard time/token box + a change-gate.
---

# Live Cross-Host E2E Automation

## Why

F-174's hook-driven bootstrap is **runtime** behavior: the SessionStart hook injects a contract, the agent
renders an orientation banner, gate stops fire and wait for a human verdict, and the Stop hook writes a rolling
handover. **None of that is exercised by today's automated tests** — they check file shapes, provider
byte-parity, and provider output in isolation. The two most serious F-174 defects both escaped every gate:

- The **handover-provider mirror skew** (the deployable mirror was a stale pre-iter-5 copy that called a dropped
  `-Sections` param against the iter-5 store) made the Stop handover **fail open silently on every host** — no
  rolling handover was ever written. Caught only by hand-reading `.specrew/handover/` after a manual `/exit`.
- The **Claude lifecycle-entry skip** (Claude free-ran the contract straight to code) — caught only by comparing
  three hand-driven trials' artifacts.

Both are **cross-host runtime behaviors** that a deterministic, file-shape test cannot see. **Proposal 042**
(Integration Test Suite) deliberately scoped real-host CI **out of scope** ("Real-Squad / real-Copilot
integration in CI — Premium quota cost prohibitive on every push") and chose recorded/replay fixtures. That was
right for per-push determinism, but it leaves the actual cross-host hook behavior unverified between hand-driven
dogfoods. The existing `specrew-confidence-lane.yml` is the **seed**: a weekly Squad+Copilot smoke harness — but
it is single-host (Copilot+Squad), **skips when auth is missing**, and asserts smoke-launch, not
hook/stop/handover behavior.

This proposal **generalizes that seed** into a rotating, real-host, behavior-asserting e2e — made affordable by
three cost controls 042 lacked: **host rotation**, a hard **time/token box**, and a **change-gate**.

## What

A CI workflow that, on each run, picks **one** AI host (rotating `claude → codex → copilot → …` so the full set
is covered over successive runs), provisions it with a real model via **Azure AI Foundry**-brokered keys, drives
a **short** governed feature **headlessly** in a container, and **asserts the hook-driven runtime behaviors**.

### The run

1. **Pick the host** for this run from a rotation cursor (so over N nights all hosts are covered).
2. **Provision:** install the host CLI in the container, point it at a Foundry-brokered model + key (per-host
   auth — see Open Questions; this is the feasibility crux).
3. **`specrew init`** a fresh synthetic project.
4. **Launch headlessly** (`-p` / `exec` / the host's equivalent) on a SHORT, well-scoped feature (e.g. "a small
   CLI todo store") — enough to trigger the workshop, not a marathon.
5. **Drive the workshop:** scripted answers for the first few lens questions, then **"accept all / you decide"**
   to fast-forward to the gates. The goal is to exercise the flow, not to co-design deeply.
6. **Assert the hook-driven behaviors** (the part that catches the F-174 bug classes):
   - SessionStart bootstrap fired **and the orientation banner rendered** — the lifecycle-ENTRY behavior; this
     assertion would have caught the **Claude skip**.
   - The lifecycle actually advanced: `spec.md` written, a gate **STOP surfaced for a human verdict** and did NOT
     auto-cross.
   - The **rolling handover was written at Stop** with a real (non-placeholder) body — this assertion would have
     caught the **handover mirror skew** (host-independent, silent fail-open).
   - Refocus / discipline surfaces appeared where expected.
7. **Upload** the transcript + `.specrew/runtime` + the handover artifacts for inspection.

### Cost controls (the part 042 lacked)

- **Host rotation** — ONE host per run. Full coverage accrues over the rotation period, not on every run. Cuts
  per-run token cost ~3x versus running all hosts each night.
- **Hard time + token box** — a wall-clock ceiling AND a token ceiling; the run **aborts (and reports)** rather
  than burning unbounded tokens if a host loops or stalls. This is the safeguard against endless token waste.
- **Change-gate (nightly-only-on-change)** — the nightly runs ONLY if `HEAD` changed since the last successful
  e2e run. No code change → no run → no tokens. (Proposal 087's nightly truth-check runs unconditionally because
  the validator is free; **live-host runs cost real money**, so the change-gate is essential here.)

### Cadence + safety

Nightly schedule (the Proposal 087 cron+`workflow_dispatch` pattern), **gated on change**; plus on-demand
`workflow_dispatch`. **Scheduled + `main`-branch ONLY** — never untrusted PRs (secrets-exfiltration risk; see
Risks).

## Open questions (the hard parts — named honestly)

1. **(LEAD) Per-host headless auth feasibility.** Claude and Codex take API keys cleanly via env. **Copilot
   CLI's auth is GitHub-account-based and may NOT accept a Foundry-brokered key at all** (hence "if possible").
   Resolve per host: which hosts can run headless on Foundry keys, and what is the fallback for those that can't
   (skip-with-report? a different broker? a recorded fixture for that host)? **This gates the proposal's host
   set** and is the first thing to settle at clarify.
2. **Foundry as the broker.** Azure AI Foundry brokers models (incl. Anthropic + OpenAI families) behind one key
   surface — confirm each host CLI can be pointed at a Foundry endpoint/key (base-URL override, env var) and the
   model-name mapping per host.
3. **Driving a MULTI-TURN workshop headlessly.** The workshop is several turns (per-lens questions); "accept all"
   must be scripted per host's headless input model (one-shot `-p` vs an interactive `exec` with queued answers).
   Determine the per-host scripted-answer mechanism.
4. **The change-gate's memory.** Where is "last successfully-tested SHA" stored — a workflow cache, a git
   tag/note, a commit-status, or a tiny state file? Skip when `HEAD == last-tested-SHA`; handle force-push and
   first-run.
5. **The token-box mechanism.** How to cap + measure spend per host (provider usage API? a max-output / transcript
   -length proxy? a hard wall-clock as the backstop?).
6. **Determinism vs reality.** Live hosts are non-deterministic; assertions must be **behavior-shaped** (banner
   rendered? handover body authored? gate stopped?), not output-exact, with a flake/retry policy.

## Risks

- **Secrets exfiltration** — Foundry keys in CI must be **scheduled + `main`-only**, NEVER exposed to
  untrusted-PR workflows (a malicious PR could print the key). Use GitHub Environment protection / scheduled-only
  secret scoping.
- **Token cost runaway** — the time/token box + the change-gate are the mitigations; without them a looping host
  burns unbounded spend. The box must be a **hard** ceiling, not advisory.
- **Flakiness** — live hosts vary run-to-run; behavior-shaped assertions + a quarantine/retry policy (per 042)
  are required, else the lane cries wolf and gets ignored.
- **Auth fragility** — host CLIs evolve their auth; the lane needs a currency check and a **graceful
  skip-with-report** when a host can't authenticate (don't fail the whole lane on one host's auth break).
- **Coverage latency** — rotation means any single night covers one host; a host-specific regression is caught
  within one rotation period, not immediately. Acceptable for a nightly safety net; **documented, not silent**
  (the run logs which host it covered and which it skipped).

## Composition with other proposals

| Proposal | Relationship |
| -------- | ------------ |
| [042](042-specrew-integration-test-suite.md) (Integration Test Suite, candidate) | 181 is the **live-host counterpart** to 042's deterministic/recorded suite. 042 explicitly deferred real-host CI as cost-prohibitive; 181 makes it affordable. 042 covers per-push determinism; 181 covers cross-host runtime behavior on a gated cadence. |
| [087](087-push-to-main-validator-scoping-and-nightly-truth-check.md) (Nightly Truth-Check, shipped) | The cron + `workflow_dispatch` precedent. 181 **adds the change-gate** because live hosts cost tokens, not just CI minutes. |
| `specrew-confidence-lane.yml` (existing) | The single-host weekly Squad+Copilot smoke seed 181 generalizes — rotation + real keys + behavior assertions instead of skip-on-missing-auth smoke. |
| [139](139-multi-agent-subagent-orchestration.md) (Multi-Agent Orchestration, candidate) | Shares the **Layer-2 headless host-process invoke contract** (every host's `-p`/`exec`). 181's per-host headless launch is the same seam 139 needs; they can share the host-invoke adapter. |
| [060](060-prerelease-channel-staging.md) (Prerelease Channel Staging) | A prerelease tag is a natural extra trigger — every beta fires the live lane once. |
| Feature 174 / [180](180-pretooluse-lifecycle-entry-gate.md) | 181 is the **regression net** that would have caught both F-174 bugs automatically — the handover skew and the Claude lifecycle-entry skip. |

## Sizing

~20–30 SP, per-host auth-feasibility-dependent. The bulk: the **per-host headless auth + launch adapter** (the
research-heavy part — Open Question 1), the scripted-workshop driver (multi-turn → accept-all), the
behavior-shaped assertions (banner / gate-stop / handover-body), the change-gate + token-box plumbing, and the
secrets/security hardening. **Lower end** if only Claude + Codex prove headless-on-Foundry-feasible (Copilot
skipped-with-report); **upper end** if all three plus robust flake handling.

## Phase placement

Phase 2 — the same "green CI baseline / trustworthy self-development" band as 042. Sequence **after** the F-174
work it regression-nets (so there is stable hook behavior to assert against) and after the Open-Question-1 auth
spike (which decides the host set and therefore the real scope).

## Status history

- 2026-06-10: captured as candidate from the Feature 174 cross-host dogfood — both serious F-174 bugs (the
  handover-provider mirror skew and the Claude lifecycle-entry skip) escaped every automated gate and were caught
  only by a hand-driven three-host trial. The lead unknown is per-host headless auth on Foundry-brokered keys
  ("if possible" for Copilot); convert to a spec only after that feasibility spike.
