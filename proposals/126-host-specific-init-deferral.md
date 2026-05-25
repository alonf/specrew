---
proposal: 126
title: Host-Specific Init Deferral (Move Squad/Claude/Codex/Antigravity Bootstrap from `specrew init` to `specrew start --host` First-Run)
status: candidate
phase: phase-2
estimated-sp: 10-15
priority-tier: 3
discussion: surfaced 2026-05-25 during WSL Antigravity dogfood; user direction "we will create a proposal that defer host specific init to the time we select host"; gated on F-044 PR-to-main merging (DONE 2026-05-25); ready to draft now
---

# Host-Specific Init Deferral

## Why

`specrew init` currently runs `squad init` unconditionally — populating `.squad/`, emitting Squad-branded console output (`Let's build your team.` / `Your team is ready. Run squad to start.`), and adding ~5 seconds + console clutter even when the user will never select Copilot (Squad) as their host.

The Specrew bootstrap layer overlays Specrew templates on top of Squad's output, but the **Squad branding leaks through** and produces a methodology-marketing contradiction: README claims "methodology survives the host," but the first impression at `specrew init` is Squad-CLI chatter that's irrelevant to Claude / Codex / Antigravity users.

The bootstrap is Copilot-first by historical accident — Squad was the original (and only) host, so its init was Specrew's init. Multi-host expansion (F-040 / F-043 / F-044 / proposal 124) doesn't preserve that asymmetry well. Specrew's bootstrap should be **host-neutral by default**; host-specific bootstrap should fire **lazily on first-run of `specrew start --host <kind>`**.

This is a methodology question, not a code bug. The architectural shape of the bootstrap layer needs to match Specrew's multi-host claim.

## What

Refactor `specrew init` to perform **only** host-neutral bootstrap. Move host-specific bootstrap to `specrew start --host <kind>` first-run lazy-init, gated by checking whether the host-specific surfaces already exist.

### Pillar 1: Host-neutral `specrew init` (~3-4 SP)

`specrew init` does exactly:

- `.specrew/` scaffold (config.yml, constitution.md, iteration-config.yml, role-assignments.yml)
- `.specify/` scaffold (templates, extensions/specrew-speckit/)
- `.specrew/team/agents/<role>.md` canonical team (per F-044 Slice 9 Crew runtime)
- Slash-command catalog deploy across the 3 canonical roots (`.claude/skills/`, `.github/skills/`, `.agents/skills/`)
- Governance scaffold (`.squad/decisions.md` and `.squad/identity/now.md` if any host might be selected — but NOT `squad init` proper)
- `specrew init` does NOT run `squad init` or any per-host bootstrap

Console output: Specrew-branded only. No Squad / Claude / Codex / Antigravity chatter at `init` time.

### Pillar 2: Lazy first-run host-specific bootstrap (~4-6 SP)

`specrew start --host <kind>` checks whether the host's specific surfaces are deployed. On first-run for a host (deployment markers absent), runs the host-specific bootstrap:

| Host | First-run bootstrap |
|---|---|
| copilot | `squad init` (current Squad CLI) + `.squad/` finalization |
| claude | `.claude/agents/<role>.md` per-host charter deployment (F-044's `Install-ClaudeCrewRuntime`) |
| codex | `.codex/agents/<role>.md` (F-044's `Install-CodexCrewRuntime`) |
| antigravity | `.agents/agents/<role>.md` (F-044's `Install-AntigravityCrewRuntime`) |
| aider | (per Proposal 124) `.aider/agents/<role>.md` |
| amp | (per Proposal 124) similar |
| opencode | similar |
| cursor | similar |

Deployment markers: `.specrew/host-bootstrap-history.yml` tracks first-run-completed per host. Re-runs are idempotent (skip if already deployed unless `--force-bootstrap`).

### Pillar 3: Multi-host bootstrap in one session (~2-3 SP)

If a user is `specrew start --host claude` today and `specrew start --host codex` tomorrow on the same project, both hosts' bootstrap should fire on their respective first-runs without conflict. Pillar 2's history tracking + idempotency cover this. Pillar 3 adds:

- `specrew host bootstrap --host <kind>` command for explicit pre-bootstrapping (useful in CI/scripted setup)
- Documentation in `docs/user-guide.md` Multi-Host section explaining the lazy-bootstrap model

### Pillar 4: Migration path for existing projects (~1-2 SP)

Existing projects (Specrew already initialized via current `specrew init`) won't re-run init. The host-bootstrap-history.yml is absent; lazy detection treats them as fully-bootstrapped for all hosts they've used.

- `specrew start --host <kind>` checks existing host surfaces; if present, skips bootstrap and records "auto-detected" in history.yml
- `specrew update` (or a new `specrew migrate` command) backfills the history.yml for existing projects so future runs follow the lazy model

## How

Total ~10-15 SP across 4 pillars.

| Step | File | Effort |
|---|---|---|
| Pillar 1 host-neutral init refactor | `scripts/specrew-init.ps1`, `scripts/internal/skill-catalog-state.ps1` | 3-4 SP |
| Pillar 2 lazy host-specific bootstrap | `scripts/specrew-start.ps1`, per-host `Install-<Kind>CrewRuntime` extensions | 4-6 SP |
| Pillar 3 explicit `specrew host bootstrap` + docs | `scripts/specrew-host.ps1`, `docs/user-guide.md` | 2-3 SP |
| Pillar 4 migration backfill | `scripts/specrew-update.ps1` or new `specrew-migrate.ps1` | 1-2 SP |
| Integration tests | `tests/integration/host-specific-init-deferral.tests.ps1` (new) | 2 SP |

## Acceptance criteria

- **AC1**: `specrew init` on a fresh project produces NO Squad / Claude / Codex / Antigravity-branded console output
- **AC2**: After `specrew init`, `.squad/`, `.claude/agents/`, `.codex/agents/`, `.agents/agents/` are NOT populated with host-specific charters (governance scaffold like `.squad/decisions.md` may exist but host-specific agent files do not)
- **AC3**: `specrew start --host claude` on a fresh-init project deploys `.claude/agents/<role>.md` files on first-run
- **AC4**: `specrew start --host codex` on the same project subsequently deploys `.codex/agents/<role>.md` files without disturbing the Claude deployment
- **AC5**: `.specrew/host-bootstrap-history.yml` tracks per-host first-run-completed timestamps
- **AC6**: Re-running `specrew start --host claude` skips bootstrap (already-deployed; no console chatter)
- **AC7**: Existing projects (init'd before this proposal lands) are auto-detected as "already bootstrapped for hosts they've used" — no re-bootstrap unless explicitly requested via `specrew migrate` or `--force-bootstrap`
- **AC8**: `specrew host bootstrap --host <kind>` explicitly bootstraps a host without launching it (useful for CI / pre-staging)
- **AC9**: Mirror parity preserved for all touched extension scripts
- **AC10**: README + docs/user-guide accurately describe the lazy-bootstrap model; the multi-host claim is no longer contradicted by `specrew init` output

## Out of scope

- **Removing Squad CLI dependency entirely** — Squad CLI remains the Copilot host's bootstrap mechanism; this proposal just defers WHEN it runs
- **Backward-incompatible breaking changes** — existing projects continue working; migration is opt-in or auto-detected
- **Per-host preference dialogs at init time** — host selection stays at `specrew start --host`; this proposal does NOT add an init-time "which host will you use?" question
- **Bootstrap conflict resolution for projects with multiple host bootstraps in flight** — Pillar 2 handles sequential single-user case; concurrent multi-user is Proposal 010's domain

## Composition

- **Proposal 069 (Multi-Host Launch Path, shipped as F-040)** — direct prerequisite; `--host` flag exists, this proposal makes init match the multi-host claim
- **Proposal 104 (Multi-Host Onboarding + Selection Flow)** — composes; selection UX happens at `start` time, this proposal moves bootstrap to align with that
- **Proposal 108 (Per-Host Crew Runtime Install)** — direct dependency; this proposal's Pillar 2 leverages F-044's `Install-<Kind>CrewRuntime` pattern (already runs on every `start`; this proposal makes the first-run case explicit)
- **Proposal 124 (Multi-Host Catalog Expansion — Tier 1)** — composes; new hosts (Aider / Amp / OpenCode / Cursor) follow the lazy-bootstrap pattern from day one
- **Proposal 105 (Host-Native Hook Deployment)** — composes; hook deployment is also host-specific and should follow the same lazy pattern

## Risks

- **Existing project migration confusion** — Mitigation: auto-detection in Pillar 4; explicit `specrew migrate` command; release notes
- **CI scripts assuming `specrew init` produces host-specific surfaces** — Mitigation: ship `specrew host bootstrap --host copilot` as an explicit pre-step for CI scripts that need it; document in user-guide
- **`squad init` Squad CLI dependency timing shifts** — Mitigation: `squad init` still runs on first `specrew start --host copilot`; same dependency, different timing
- **First-run latency on `specrew start`** — Mitigation: bootstrap is a one-time cost per host; documented expectation; show progress
- **Bootstrap output during `start --host <kind>` first-run may interfere with bootstrap prompt** — Mitigation: bootstrap output completes BEFORE prompt rendering; flow is sequential

## Empirical motivation

2026-05-25 F-044 iter-005 user observation during WSL Antigravity test:

> "we will create a proposal that defer host specific init to the time we select host"

WSL test of `specrew start --host antigravity` succeeded, but `specrew init` chatter included multiple Squad-CLI-branded checkpoints irrelevant to Antigravity users. Console output is the user's first impression of Specrew's methodology promise; Squad branding contradicts the "methodology survives the host" claim from README. Captured at memory `[[host-specific-init-deferral-proposal-candidate]]`.

## Cross-references

- file:///C:/Dev/Specrew/proposals/069-multi-host-launch-path.md
- file:///C:/Dev/Specrew/proposals/104-multi-host-onboarding-and-selection-flow.md
- file:///C:/Dev/Specrew/proposals/108-per-host-crew-runtime-install.md
- file:///C:/Dev/Specrew/proposals/124-multi-host-catalog-expansion-tier-1.md
- file:///C:/Dev/Specrew/proposals/105-host-native-hook-deployment.md
- file:///C:/Dev/Specrew/scripts/specrew-init.ps1 (current host-specific init coupling)
- file:///C:/Dev/Specrew/scripts/specrew-start.ps1 (current first-run check)
- Memory: [[host-specific-init-deferral-proposal-candidate]]

## Status history

- 2026-05-25: gap surfaced during WSL Antigravity dogfood; user direction to draft a proposal.
- 2026-05-26: candidate proposal drafted as part of memory→proposal sweep. Gating cleared (F-044 PR-to-main merged 2026-05-25).
