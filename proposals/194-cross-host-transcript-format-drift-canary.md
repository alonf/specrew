---
proposal: 194
title: Cross-Host Transcript-Format-Drift Canary (Live BYOK Detection of Conversation-Capture Breakage)
status: candidate
phase: phase-2
estimated-sp: 8-14
priority-tier: 2
discussion: surfaced 2026-06-12 during Feature 174 iteration-010 T002 (best-effort conversation capture). The maintainer asked the load-bearing maintenance question - "what is the chance a provider changes the transcript file and breaks the solution, and how would we even know?" Committed fixtures catch OUR parser regressions but are FROZEN snapshots that stay green while a live host silently drifts; only a real-host canary detects upstream drift. The maintainer offered a Foundry BYOK key and the Docker + GitHub Actions shape, and specified: nightly; an agent step that scans each provider's news/changelog for Specrew-breaking changes and FAILS the run naming the change; version-gated so only a provider with a NEW version runs its format test; install the provider in the container and use BYOK.
---

# Cross-Host Transcript-Format-Drift Canary

## Why

Feature 174 iteration-010 T002 added best-effort **conversation capture**: the Stop-hook reads each host's
session transcript (via the documented `transcript_path` / `transcriptPath` / `CURSOR_TRANSCRIPT_PATH`
handle) and renders a bounded "Recent conversation" tail into the rolling handover. The capture is
format-resilient by construction (a 4-tier ladder: structured per-host parse -> raw bounded tail with a
visible note -> payload `last_assistant_message` -> honest floor) and is additive over the durable git/fs
base, so a format change DEGRADES gracefully and never breaks. But two facts make silent quality erosion a
real risk:

1. **The transcript FILE formats are internal and undocumented for three of four hosts** (Codex, Copilot,
   Cursor), pinned only empirically from real session files. **Codex explicitly documents that "the transcript
   format is not a stable interface for hooks and may change over time."**
2. **Committed fixtures cannot detect drift.** `tests/bootstrap/fixtures/conversation/*.jsonl` are frozen
   snapshots of each format as of 2026-06-11. They catch OUR parser regressions, but they stay GREEN when a
   live host changes its real format - the test never sees the new bytes. Only a test that runs the ACTUAL,
   CURRENT host CLI against the real capture path catches upstream drift.

This proposal is the **drift DETECTOR**: a live, real-host canary that fails loudly when a provider's
transcript format (or hook contract) changes in a way that degrades capture, so the per-host parser gets
updated on a small, scheduled cadence instead of eroding unnoticed until a downstream user reports a poor
handover.

## Relationship to existing proposals (compose, do not duplicate)

- **Proposal 181 (Live Cross-Host E2E Automation)** already specifies the EXPENSIVE shared infrastructure:
  a rotating real-host CI harness (Foundry-brokered keys, headless host launch, nightly + change-gate, hard
  time/token box) that asserts hook-driven RUNTIME BEHAVIORS (SessionStart banner, gate stops, rolling
  handover at Stop). This proposal **reuses 181's harness** and adds the orthogonal **format-drift**
  dimension that 181 does not cover. If the maintainer prefers, 194 can be FOLDED INTO 181 as its
  "conversation-capture format assertion + provider-news change-gate" sub-feature rather than shipped
  standalone - flagged explicitly for that decision.
- **Proposal 042 (Specrew integration test suite)** is the umbrella that deferred real hosts as
  cost-prohibitive; 194 is a narrowly-scoped, affordability-engineered slice of that real-host gap.
- **Feature 174 T002** is the motivating dependency; `specs/174-hook-driven-session-bootstrap/iterations/010/research-host-transcript-exposure.md`
  is the per-host exposure + format record this canary protects.

This research also **invalidates a stale blocker in Proposal 105**, which states "Codex hook deployment
deferred until Codex hook surface is documented; Copilot has no hook surface." Both are now documented with
transcript fields (Codex: developers.openai.com/codex/hooks; Copilot: agentStop `transcriptPath`).

## What

A scheduled GitHub Actions workflow that, per hook-capable host (Claude, Codex, Copilot, Cursor), confirms
the CURRENT live host still produces a transcript the capture parser understands - and fails, naming the
cause, when it does not. Antigravity is out of scope (no hooks -> no capture -> nothing to canary).

### Pillar A - Nightly, version-GATED execution (the affordability lever)

- Runs on a **nightly cron** plus `workflow_dispatch`, never per-PR (avoids flaky-CI blocking merges and
  per-PR API cost).
- **Version gate**: each run first resolves the installed/latest version of each host CLI and compares it to
  the last-canaried version recorded in a small state file (e.g. `.github/canary-host-versions.json`). A
  host's format test runs **only when that host has a NEW version** (or on a forced dispatch). A run where no
  host changed is a fast no-op. This bounds API spend to "only when a provider actually shipped."

### Pillar B - Provider-news breaking-change scan (fail with the named change)

- An **agent step** in the run searches each provider's release notes / changelog / hook-reference docs for
  changes since the last canaried version that could break Specrew (transcript format/path, hook event
  contract, payload field renames, stdin shape). The agent returns a structured verdict per host.
- If the agent finds a **breaking change**, the run **FAILS with an error message that names the specific
  change and the source URL** (e.g. "Codex 0.140.0 changelog: rollout transcript schema changed `content[]`
  to `parts[]` - conversation capture parser `Get-SpecrewConversationTurnFromLine` needs the codex branch
  updated; https://..."). This catches drift even before the format test runs, and turns an opaque "capture
  got worse" into a precise, actionable signal.

### Pillar C - Live format test (install the host + BYOK, canary-token assertion)

- For each host with a new version, the container **installs the real host CLI** and authenticates via
  **BYOK** (the maintainer's Foundry key as a repo secret; `COPILOT_SOURCE=foundry` etc.).
- Drives a minimal headless session with a **canary token**: prompt the model to emit a unique marker
  (`codex exec "Reply with exactly: CANARY-<run-id>"`), let the Stop-hook fire, then assert the rolling
  handover's "Recent conversation" section contains the canary token (the assistant turn captured from the
  CURRENT format) AND the prompt text (the user turn). Deterministic despite LLM nondeterminism - the
  assertion is on the token + structural facts, never free-form content.
- On failure, **diff the live transcript file against the committed fixture** for that host to show exactly
  what changed, so the parser fix is a few lines in one per-host branch.

### Per-host feasibility (phased)

| Host | Headless | Auth | Phase |
| --- | --- | --- | --- |
| Claude | `claude -p` | ANTHROPIC_API_KEY / Bedrock / Foundry | 1 (clearest) |
| Codex | `codex exec` | OpenAI / Foundry | 1 (clearest) |
| Copilot | `copilot -p` (verify headless) | GitHub token + `COPILOT_SOURCE=foundry` | 2 |
| Cursor | `cursor-agent --print` | API key | 2 |
| Antigravity | - | - | n/a (no hooks) |

Ship Claude + Codex first; add Copilot + Cursor as their headless/auth stories firm up.

## Honest limits

- The canary tests only the host VERSIONS in the container; a user on a newer build could hit drift before
  the nightly catches it. Mitigation: the container installs the latest host CLI each run, and the in-runtime
  4-tier ladder already degrades gracefully + emits a visible "unrecognized format" note, so drift is
  survivable and detectable in the handover itself even between canary runs.
- Hard-kill (no hook fires) is not a format-drift concern and is out of scope.
- Cost is real but bounded by the version gate + 1-turn sessions + nightly cadence + host rotation.

## Acceptance (sketch)

- A scheduled workflow that, given a host version bump, installs the host, runs a canary-token session under
  BYOK, and asserts the handover captured the token; fails with a transcript diff on mismatch.
- A provider-news scan step that fails the run naming a detected breaking change + source URL.
- A version-state file gating per-host execution; a no-change run is a fast no-op.
- Claude + Codex live in phase 1; Copilot + Cursor designed-for in phase 2.
