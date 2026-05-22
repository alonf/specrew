# Tasks: Multi-Host Launch Path (Iteration 001)

**Feature**: F-040 / Proposal 069 | **Spec**: [spec.md](./spec.md) | **Plan**: [plan.md](./plan.md) | **Research**: [research.md](./research.md)
**Iteration**: 001 (target: cover full feature scope in single iteration)
**Total SP**: ~14.5 SP (within 12-15 SP spec range)

## Task list

| ID | Task | Owner | SP | Deps | Test evidence |
|---|---|---|---|---|---|
| T001 | Add `-Host <kind>` parameter to `scripts\specrew-start.ps1` with `--host` CLI alias parser; reject `antigravity` + `auto` with deferred-guidance text + exit 1 | Implementer | 1.5 | - | parameter parsing tests; deferred-guidance text matches research.md Task 3 |
| T002 | Create `scripts\internal\detect-hosts.ps1` — `Test-SpecrewHostAvailable -Host <kind>` + `Get-SpecrewAvailableHosts` (parallel PATH probe using ForEach-Object -Parallel pattern from F-035) | Implementer | 1 | T001 | unit tests for each host detection arm; parallel-probe latency < 100ms |
| T003 | Create `scripts\internal\host-flag-translation.ps1` — per-host map for `--remote`, `--allow-all`, `--autopilot`; `Get-HostFlagTranslation -Host <kind> -SpecrewFlag <name>` returns translated argv tokens or `$null` for "drop" | Implementer | 2 | T001 | flag-translation matrix tests (9 cells per research.md Task 2 table); warn-and-continue case for Codex `--remote` |
| T004 | Create `scripts\internal\coordinator-prompt-surgery.ps1` with two concerns: (a) `Get-SpecrewUniversalCoordinatorHeader` returns the unified `"You are the Crew team coordinator running inside a Specrew-bootstrapped repository."` — applied to ALL hosts per FR-011; (b) `Remove-SquadRuntimePathDirectives -Host <kind>` strips rules 12/35/37/42-44 for non-Copilot hosts only per FR-012 | Implementer | 2 | T001 | prompt-surgery tests: universal header swap verified on all 3 hosts; non-Copilot path has the 4 rules stripped + everything else unchanged; Copilot path retains Squad-runtime-path rules |
| T005 | Create per-host launch-invocation builders inside `scripts\specrew-start.ps1` (or new `scripts\internal\host-launch-builders.ps1`) — `Get-SpecrewHostLaunchInvocation -Host <kind> -Project <path> -BootstrapPrompt <str> -Flags <hash>` returns `@{ Binary = '...'; Args = @(...) }` | Implementer | 3 | T002, T003, T004 | builder tests for copilot/claude/codex; argv shape per research.md Task 1 |
| T006 | Rewrite the load-bearing dispatch literal at `scripts\specrew-start.ps1:3131` to use `Get-SpecrewHostLaunchInvocation`; preserve Windows `Start-Process pwsh` + Linux `SPECREW_DEFERRED_LAUNCH_FILE` branches; Copilot launch path stays argv-identical (the universal header rewrite from T004 is a body-of-prompt change, not an argv change) | Implementer | 2 | T005 | Copilot regression test: argv on Windows + Linux match pre-F-040 verbatim; separate test asserts the universal header rewrite is present in `last-start-prompt.md` for all 3 hosts |
| T007 | Add `Test-HostSkillRoot -Host <kind>` to `scripts\internal\detect-hosts.ps1`; verifies per-host skill directory presence + parses each `SKILL.md` frontmatter; emits non-fatal warnings naming missing/malformed skills | Implementer | 1 | T002 | skill-warning tests: missing skill on each host triggers warning; warning text names the missing skill path |
| T008 | Extend `.specrew/start-context.json` write path in `scripts\specrew-start.ps1` to include additive fields `selected_host`, `available_hosts`, `crew_runtime_status` | Implementer | 0.5 | T002, T006 | start-context persistence test: fields written; existing fields untouched; schema v2 still validates |
| T009 | Create `tests\integration\multi-host-launch-path.tests.ps1` covering all 6 verification-evidence categories from plan.md Quality Planning section | Implementer | 2 | T001-T008 | 25+ assertions in the new file; CI passes on Windows + Linux |
| T010 | Update `docs\getting-started.md` and `docs\user-guide.md` with `--host` usage examples + flag-translation matrix + skill-warning expectations | Implementer | 0.5 | T001-T008 | docs render; example commands runnable |
| T011 | Bump version to 0.26.0 across the four manifests (`Specrew.psd1` ModuleVersion, `.specrew\config.yml` specrew_version, `extensions\specrew-speckit\extension.yml` version, `.specify\extensions\specrew-speckit\extension.yml` version) | Implementer | 0.25 | - | version-consistency validator passes |
| T012 | Update `CHANGELOG.md` with F-040 entry under v0.26.0 | Implementer | 0.25 | T011 | CHANGELOG renders; entry references Proposal 069 + Proposal 024 4-slice ladder |
| T013 | Flip `proposals\069-multi-host-launch-path.md` `status: draft` → `status: shipped`; add `shipped-as: feature-040`, `shipped-version: 0.26.0` | Implementer | 0.25 | T011 | proposal frontmatter validates |
| T014 | Update `proposals\INDEX.md` — move 069 from Draft (16) to Shipped (23); decrement Draft count; increment Shipped count; update phase-breakdown if needed | Implementer | 0.25 | T013 | INDEX renders; counts match |

## Dependency graph

```
T001 ─┬─► T002 ─┬─► T005 ─► T006 ─┬─► T008 ─┐
      │         │                  │         │
      ├─► T003 ─┤                  │         ├─► T009 ─► T010
      │         │                  │         │
      ├─► T004 ─┘                  │         │
      │                            │         │
      └─► T007 ─────────────────────┘         │
                                              │
                                              ▼
T011 ──► T012, T013 ──► T014 ─────────────────► (closeout-ready)
```

T001-T009 form the core feature path. T010-T014 are closeout housekeeping that can interleave but must complete before feature-closeout boundary.

## Iteration-001 acceptance criteria

Tied to FRs in spec.md:

| AC | Validates FR(s) | Task evidence |
|---|---|---|
| AC1 | FR-001 (host parameter parsing) | T001 |
| AC2 | FR-002 (Copilot regression) | T006 |
| AC3 | FR-003 (Claude invocation) | T005 |
| AC4 | FR-004 (Codex invocation) | T005 |
| AC5 | FR-005 (missing-host guidance) | T001, T002 |
| AC6 | FR-006 (start-context persistence) | T008 |
| AC7 | FR-007 (`--remote` translation) | T003, T005 |
| AC8 | FR-008 (`--allow-all`/`--autopilot` translation) | T003, T005 |
| AC9 | FR-009 (skill verification non-fatal) | T007 |
| AC10 | FR-010 (bootstrap-context shape unchanged) | T006, T008 |
| AC11 | FR-011 (universal coordinator-prompt header for ALL hosts) | T004, T005 |
| AC12 | FR-012 (Squad-runtime-path rule strip for non-Copilot hosts) | T004, T005 |
| AC13 | FR-013 (Codex no-slash-command informational note) | T007 |
| AC14 | Antigravity + `--host auto` deferred-guidance rejection | T001 |
| AC15 | Cross-platform parity (Windows + Linux) | T006, T009 |

## Out of iteration

- Antigravity launch invocation (separate small-fix slice once `agy` working-dir verified)
- `--host auto` smart selection (Proposal 104 / F-043)
- Full coordinator-prompt directive surgery for all 45 directives (Proposal 024 Slice 2)
- Per-host Crew runtime install — subagent files, `.codex/agents/*.toml`, `.agents/AGENTS.md` (Proposal 024 Slice 3)
- `--host` flag on `specrew init` (currently init is host-agnostic; defer until user requests)
- Catalog refresh of host model lineups (Proposal 068 / F-041)
- Cost tracking per host (Proposal 070 / F-042)

## Boundary checklist (per F-039 boundary discipline)

- [ ] specify-boundary: completed 2026-05-23 with spec.md + clarify Q&A
- [ ] clarify-boundary: completed 2026-05-23 (4 questions answered)
- [ ] plan-boundary: AWAITING USER VERDICT — spec.md + plan.md + research.md + tasks.md ready for review
- [ ] tasks-boundary: requires plan-boundary verdict to authorize
- [ ] before-implement: requires tasks-boundary verdict
- [ ] review-signoff: post-implementation
- [ ] retro: after review-signoff
- [ ] iteration-closeout: after retro
- [ ] feature-closeout: after iteration-closeout (single-iteration feature)

For the plan-boundary verdict, user is invited to give a compound verdict per F-039's Pillar 2 / AC9 mechanism:

**"approved for tasks-boundary entry AND autonomous progression through feature-closeout"**

This compound shape grants Specrew authorization to advance through the remaining boundaries without re-prompting, leveraging Proposal 066's `--autonomous` posture for the implementation phase while preserving the explicit one-time human-authorization-at-plan that the F-039 enforcement mechanism requires.
