# F-040 Feature Closeout Dashboard

**Feature**: F-040 Multi-Host Launch Path
**Source proposal**: Proposal 069 (now status:shipped)
**Shipped as**: v0.26.0
**Closeout date**: 2026-05-23
**Branch**: `040-multi-host-launch-path`

## Delivery summary

| Metric | Planned | Actual | Variance |
|---|---|---|---|
| Story points | 12-15 SP (initial) → 14.5-15.25 SP (Option A + clarify additions) | 15.25 SP | within revised range |
| Iterations | 1 | 1 | 0 |
| FRs delivered | 15 (FR-001 through FR-015) | 15 | 0 |
| ACs verified | 17 (AC1 through AC17) | 17 | 0 |
| Test assertions | 15+ | 15 (all pass) | 0 |

## Pillars delivered

| Pillar | Source | Status |
|---|---|---|
| Pillar 1: Host detection | Proposal 069 | ✅ Shipped (scripts/internal/detect-hosts.ps1) |
| Pillar 2: `--host` parameter dispatch | Proposal 069 | ✅ Shipped (specrew-start.ps1 + Get-SpecrewHostLaunchInvocation) |
| Pillar 3: Per-host skill verification | Proposal 069 | ✅ Shipped (Test-HostSkillRoot — non-fatal warning per clarify Q3) |
| Pillar 4: `--remote` flag pass-through with per-host translation | Proposal 069 (expanded 2026-05-21) | ✅ Shipped (scripts/internal/host-flag-translation.ps1, 9-cell matrix) |
| Pillar 5: True host abstraction | Proposal 069 deferred | ⏳ Deferred to Proposal 024 Slice 3 |

## Clarify decisions honored

| Question | Decision | Implementation |
|---|---|---|
| Q1: Antigravity scope | Defer to follow-up slice | `--host antigravity` rejected with explicit guidance |
| Q2: `--host auto` | Defer to Proposal 104 | `--host auto` rejected with explicit guidance |
| Q3: Skill verification | Non-fatal warning | Test-HostSkillRoot writes warnings; launch proceeds |
| Q4: Coordinator prompt surgery | Minimal in F-040 | Universal header (FR-011) + Squad-runtime-path strip for non-Copilot (FR-012) |
| Q5: Hooks/skills/slash-commands | F-040 manages skills + slash-commands; defers hooks | Hook deployment tracked as Proposal 105 (drafted in this session) |
| Q6 (post-plan, Option A): Enforcement scope | Cooperative everywhere; runtime upgrade as Proposal 105 | FR-013 Codex info note + FR-014 Codex pwsh-form + FR-015 user-guide cooperative-vs-runtime asymmetry section |

## Follow-up work queued

| Item | Vehicle | When |
|---|---|---|
| Antigravity launch invocation | Follow-up small-fix slice off Proposal 069 | After empirical `agy` working-dir + session-ID verification |
| `--host auto` smart selection + `host-history.yml` UX | Proposal 104 / F-043 | After F-041 + F-042 ship |
| Full coordinator-prompt directive surgery (all 45 directives) | Proposal 024 Slice 2 | Phase 2 (after multi-host adoption signal) |
| Per-host Crew runtime install (.claude/agents/, .codex/agents/) | Proposal 024 Slice 3 | Phase 4-5 architectural endgame |
| Host-native hook deployment for runtime boundary enforcement | Proposal 105 (drafted) | Phase 2 candidate, ~14-16 SP |
| Cost-aware model routing | Proposal 068 / F-041 | Immediate next feature |
| Token economy MVP | Proposal 070 / F-042 | After F-041 |

## Files changed (summary)

- 3 new helper scripts under `scripts/internal/`: detect-hosts.ps1, host-flag-translation.ps1, coordinator-prompt-surgery.ps1
- 1 modified core launcher: scripts/specrew-start.ps1 (single dispatch literal rewrite + parameter wiring)
- 1 new integration test suite: tests/integration/multi-host-launch-path.tests.ps1
- Docs: docs/getting-started.md + docs/user-guide.md
- Version manifests: Specrew.psd1 + .specrew/config.yml + extensions/specrew-speckit/extension.yml + .specify/extensions/specrew-speckit/extension.yml (all bumped to 0.26.0)
- CHANGELOG.md: v0.26.0 entry
- proposals/069 frontmatter: status:draft → status:shipped, shipped-as: feature-040, shipped-version: 0.26.0
- proposals/INDEX.md: 069 moved to Shipped (23); Draft count decremented to 15

## Sign-off

All boundary verdicts received (user compound verdict at plan boundary: "approved for tasks-boundary entry AND autonomous progression through feature-closeout"). Closeout authorized 2026-05-23.
