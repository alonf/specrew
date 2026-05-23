# Iteration 001 Retro: Multi-Host Launch Path

**Feature**: F-040 | **Iteration**: 001 | **Date**: 2026-05-23

## What went well

- **Pre-existing research wave paid off**: the 2026-05-23 five-agent multi-host research session (Claude Code, Codex CLI, Antigravity, internal coupling audit, Claude Code follow-up) gave concrete CLI surfaces, flag names, and the single-load-bearing-literal location (`specrew-start.ps1:3131`) before implementation began. Zero discovery-during-implementation rework.
- **Helper script isolation**: putting the three new helpers (`detect-hosts.ps1`, `host-flag-translation.ps1`, `coordinator-prompt-surgery.ps1`) as standalone files under `scripts/internal/` kept the diff to `specrew-start.ps1` minimal and testable independently. The 15-assertion test suite hit each helper in isolation before touching the integration path.
- **F-021's prior multi-host skill deployment paid off**: skills already landed at `.claude/skills/`, `.github/skills/`, `.agents/skills/`. F-040's Pillar 3 (per-host skill verification) just had to READ what F-021 already deployed.
- **Universal Crew-coordinator header** is a cleaner design than per-host headers. The user's mid-flight correction ("you are the Crew team coordinator, this is the same for all") collapsed what would have been per-host branching into a single literal string change. Less code, less surface area for drift.

## What was hard

- **`$Host` is a PowerShell automatic variable**. Mid-implementation discovery that `$Host` is a read-only constant variable in the runspace caused a wave of test failures. Required renaming the parameter (`-HostKind` everywhere) and several `foreach ($host in ...)` loops (`$hk` instead) to avoid Set-StrictMode triggering "Cannot overwrite variable Host". Caught by tests; not a production regression. **Methodology note**: future Specrew code touching host-aware logic should default to `HostKind` from day one — adding to coding conventions.
- **Double-replacement bug from regex-style global rename**: my first `replace_all` of `$Host` → `$HostKind` ran a second time on already-renamed code, producing `$HostKindKind`. Caught immediately by the test, but a few minutes of debugging time. **Methodology note**: when doing global renames via PowerShell text-replace, scan the diff for double-applied-pattern before committing.
- **Research vs verified empirical gap for Antigravity** — the 2026-05-23 research confirmed `agy -p` as the bootstrap surface but flagged working-directory propagation as undocumented and session-ID emission as an open issue. F-040 deferred Antigravity entirely (clarify Q1) rather than ship a fragile partial implementation. Right call given the time pressure.

## What we'd do differently

- **Spec the `$Host` pitfall in coding conventions** so future Specrew-internal PowerShell code doesn't repeat the issue. Likely a small-fix slice to add a Rule 16 ("PowerShell parameter naming: avoid clashes with automatic variables") to the maintainer rules.
- **Add pre-implementation lint pass for double-replacement risks** in the bulk-rename tooling. Not a Specrew priority but a personal coding-discipline note.

## Lessons learned

- **Cooperative enforcement is honest enforcement.** The plan-boundary review correctly surfaced the gap between F-039's "launch-mode boundary enforcement" name and its actual cooperative mechanism. F-040 documented this honestly in FR-015 rather than overselling it. Proposal 105 picks up the runtime-hook upgrade as a separate, properly-scoped follow-up.
- **The single-load-bearing-literal pattern is powerful.** The 2026-05-23 internal coupling audit named `specrew-start.ps1:3131` as the single dispatch site. F-040's Slice 0 work was almost entirely localized to that one line + four new helper files. The architectural endgame (Proposal 024 full) remains 30+ SP, but the MVP cost was 15.25 SP because of the surgical pinpoint.
- **Methodology-first prioritization paid dividends**: F-040 ships before any external testers are using Claude/Codex hosts, but the foundation is in place when they do arrive. Per the methodology-first prioritization memory, this is the correct sequence.

## Signals for next iteration / follow-up work

- **Proposal 105 (Host-Native Hook Deployment)** is the natural next step — drafted in this session, queued as Phase 2 candidate. F-040 + 105 together would close the cooperative-runtime gap on Claude.
- **Proposal 104 (Multi-Host Onboarding + Selection Flow)** is the UX layer that builds on F-040. ~8-12 SP. Belongs as F-043 after F-041 (Proposal 068 cost routing) + F-042 (Proposal 070 token economy) per the 4-feature sequence.
- **F-041 (Proposal 068 — Cost-Aware Model Routing)** is the immediate next feature now that F-040 ships. Catalog + lean profile + Junior→cheap-model auto-routing.

## Boundary commit + push discipline (Rule 14B)

Implementer committed boundary-phase work in semantic groups during implementation:

- T001-T008 surfaces (param + parser + helpers + dispatch rewrite + persistence)
- T009 test suite
- T010 + T010a documentation
- T011-T014 closeout (version bump + CHANGELOG + proposal status flip + INDEX)

Each commit pushed to origin/040-multi-host-launch-path before boundary signaling.
