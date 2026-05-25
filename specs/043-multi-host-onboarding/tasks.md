# Tasks: Multi-Host Onboarding + Selection Flow (Iteration 001)

**Feature**: F-043 / Proposal 104 | **Spec**: [spec.md](./spec.md) | **Plan**: [plan.md](./plan.md)
**Iteration**: 001 (target: cover full FR scope in single iteration)
**Total SP**: ~10 SP
**Dependencies**: F-040 + F-041 + F-042 merged to main (F-043 builds on top of the multi-host launch + cost-routing + cost-tracking foundation)

## Task list

| ID | Task | Owner | SP | Deps | Test evidence |
|---|---|---|---|---|---|
| T001 | Create `scripts/internal/host-history.ps1` with helpers: `Get-SpecrewHostHistory`, `Update-SpecrewHostHistory`, `Test-SpecrewHostHistorySchema`, `Resolve-SpecrewHostFromHistory`. Schema v1 per data-model.md | Implementer | 1.5 | F-042 merged | round-trip read/write; schema validation; corruption recovery |
| T002 | Create `scripts/internal/host-runtime-inventory.ps1` with `Test-CopilotRuntimeInstalled`, `Test-ClaudeRuntimeInstalled`, `Test-CodexRuntimeInstalled` | Implementer | 0.5 | - | unit tests on scratch project layouts |
| T003 | Extend `scripts/specrew-start.ps1` host-selection logic per FR-002: `flag → history → probe → exit-with-guidance`. Add TTY detection via `[Console]::IsInputRedirected`. Add `host_resolution` field write to start-context.json (FR-012) | Implementer | 2 | T001 | first-run probe test (TTY mock); history-resolution test; non-TTY exit-with-guidance test; FR-012 field present |
| T004 | Create `scripts/specrew-host.ps1` with `list`, `use`, `status` subcommand dispatchers per FR-005/6/7. Wire entry alias via scripts/specrew.ps1 | Implementer | 1.5 | T001, T002 | each subcommand invocation test |
| T005 | Create `scripts/internal/category-a-migration.ps1` with `Move-SpecrewCategoryAToNewLocation`, `Test-SpecrewCategoryAAlreadyMigrated`, `Add-SpecrewMigrationBreadcrumb`, `Remove-SpecrewMigrationBreadcrumb`. Customization detection via git diff | Implementer | 2 | - | greenfield write test; brownfield migration test; customized-content preservation test; breadcrumb lifecycle test |
| T006 | Update `scripts/specrew-init.ps1` to write Category A files to `.specrew/coordinator/` on greenfield (FR-008) | Implementer | 0.5 | T005 | greenfield init places files at new location |
| T007 | Update `scripts/specrew-update.ps1` to run Category A migration on brownfield (FR-009); preserve customizations | Implementer | 0.5 | T005 | brownfield update migrates content + leaves breadcrumb |
| T008 | Update `extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1` to write coordinator-governance to `.specrew/coordinator/` (new location). Mirror to `.specify/` per Rule 14B | Implementer | 0.5 | T006 | mirror parity validator; deploy writes new location |
| T009 | Update `extensions/specrew-speckit/scripts/validate-governance.ps1` to read coordinator content from `.specrew/coordinator/` with breadcrumb-window fallback to `.squad/coordinator/` (FR-011). Mirror to `.specify/` | Implementer | 0.5 | T005 | validator reads new location; falls back during breadcrumb |
| T010 | Create `tests/integration/multi-host-onboarding.tests.ps1` covering all 13 FRs | Implementer | 1 | T001-T009 | 20+ assertions; cross-platform; TTY-detection mocks |
| T011 | Update `docs/user-guide.md` with "Multi-Host Onboarding" section + `specrew host` command reference. Update `docs/getting-started.md` step 1 to mention first-run interactive probe | Implementer | 0.5 | T001-T009 | docs render; example commands runnable |
| T012 | Bump version to 0.29.0 across 4 manifests | Implementer | 0.25 | - | version-consistency validator passes |
| T013 | Update `CHANGELOG.md` with F-043 entry under v0.29.0 | Implementer | 0.25 | T012 | CHANGELOG renders |
| T014 | Flip `proposals/104-multi-host-onboarding-and-selection-flow.md` `status: candidate` → `status: shipped`; add shipped-as/version metadata | Implementer | 0.25 | T012 | proposal frontmatter validates |
| T015 | Update `proposals/INDEX.md` — move 104 from Candidate to Shipped; decrement Candidate count | Implementer | 0.25 | T014 | INDEX renders |

## Dependency graph

```
F-042 merged ──► T001 ──┬─► T003 ──► T004 ─┐
                        │                  │
                        └─► T002 ──────────┤
                                           │
                T005 ──► T006 ──► T008 ────┤
                  │                        │
                  ├─► T007                 │
                  │                        │
                  └─► T009                 │
                                           │
                                           ▼
                                   T010 ──► T011
                                           │
T012 ──► T013, T014 ──► T015 ──────────────► (closeout-ready)
```

## Iteration-001 acceptance criteria

| AC | Validates FR(s) | Task evidence |
|---|---|---|
| AC1 | FR-001 (host-history.yml schema) | T001 |
| AC2 | FR-002 (host-selection logic: flag → history → probe → exit) | T003 |
| AC3 | FR-003 (first-run probe with prompt; single-available auto-select) | T003 |
| AC4 | FR-004 (history update post-selection) | T003 |
| AC5 | FR-005 (`specrew host list`) | T004 |
| AC6 | FR-006 (`specrew host use <kind>`) | T004 |
| AC7 | FR-007 (`specrew host status` per-host Crew-runtime detection) | T002, T004 |
| AC8 | FR-008 (greenfield writes to `.specrew/coordinator/`) | T006 |
| AC9 | FR-009 (brownfield `specrew update` migration with breadcrumb) | T007 |
| AC10 | FR-010 (Category B stays at host-native paths) | T005, T010 |
| AC11 | FR-011 (validator reads new location with fallback during breadcrumb) | T009 |
| AC12 | FR-012 (start-context.json `host_resolution` field) | T003 |
| AC13 | FR-013 (non-TTY exit with actionable guidance) | T003 |

## Out of iteration

- `specrew host init <kind>` (per-host Crew runtime install — Slice 3 territory)
- Category B state file migration (Slice 3 work, careful coordination)
- User-global host-history.yml (future)
- Mid-session host switching (architectural change)
- Multi-developer host coordination (Proposal 010)
- Concurrent multi-host execution (Proposal 024 Scenario B)

## Boundary checklist

- [x] specify-boundary: completed 2026-05-23 with spec.md + 4 clarify defaults
- [ ] clarify-boundary: AWAITING user review of clarify defaults (Q1-Q4)
- [ ] plan-boundary: AWAITING user verdict — full artifact suite ready
- [ ] tasks-boundary: requires plan-boundary verdict
- [ ] before-implement: requires tasks-boundary verdict AND F-040 + F-041 + F-042 merged
- [ ] review-signoff: post-implementation
- [ ] retro: after review-signoff
- [ ] iteration-closeout: after retro
- [ ] feature-closeout: after iteration-closeout

## Open questions for user (clarify-boundary review)

The 4 clarify defaults documented inline in spec.md:

1. **Q1 — TTY-or-not behavior**: TTY → interactive prompt; non-TTY → exit with guidance.
2. **Q2 — host-history.yml location**: project-scoped (`.specrew/host-history.yml`).
3. **Q3 — Category A migration timing**: in F-043 (this feature), not separate chore.
4. **Q4 — `specrew host init <kind>`**: NOT in v1; per-host Crew runtime install is Slice 3.
