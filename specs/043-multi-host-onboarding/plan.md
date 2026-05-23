# Implementation Plan: Multi-Host Onboarding + Selection Flow

**Branch**: `043-multi-host-onboarding` | **Date**: 2026-05-23 | **Spec**: [specs/043-multi-host-onboarding/spec.md](./spec.md)
**Input**: Approved spec + Proposal 104 decision matrix (commit `e3c47ddd` on main).

## Summary

Three orthogonal surfaces in one feature:

1. **First-run probe + `host-history.yml` persistence** — `specrew start` without `--host` flag and without prior history runs an interactive prompt (TTY) or exits with guidance (non-TTY). Selection persists for subsequent runs.
2. **`specrew host` CLI command** — `list` / `use` / `status` subcommands for inspection and switching without launching the host.
3. **Category A migration** — Specrew-owned templates relocate from `.squad/coordinator/` to `.specrew/coordinator/`. Greenfield writes new location; brownfield migrates via `specrew update` with a deprecation breadcrumb.

The feature is Slice 1 of Proposal 024's 4-slice ladder. Slice 0 (F-040) shipped the per-host launch dispatch; F-043 layers UX + persistence + Category A relocation on top.

## Technical Context

**Language/Version**: PowerShell 7+ runtime scripts, YAML host-history.yml, Markdown coordinator content
**Primary Dependencies**: F-040's `Get-SpecrewAvailableHosts` + `Get-SpecrewHostBinary` + host enum + selected_host field; existing `Write-Utf8FileAtomic` (atomic file writes); `[Console]::IsInputRedirected` for TTY detection
**Storage**: New `.specrew/host-history.yml`; relocated `.specrew/coordinator/*` (formerly `.squad/coordinator/*`); existing files in `.squad/` for Category B state stay put
**Testing**: New `tests/integration/multi-host-onboarding.tests.ps1` covering FR-001 through FR-013; TTY-detection mocks; brownfield-migration scratch projects
**Target Platform**: PowerShell 7+ on Windows / Linux / macOS (cross-platform per F-019)
**Performance Goals**: First-run probe under 200ms (three parallel Get-Command); host-history.yml read+write under 10ms each; specrew host list under 100ms
**Constraints**: Backwards-compatible with F-040 (existing --host flag still wins); brownfield migration is non-destructive; non-TTY exits with actionable guidance, not hangs

---

## Phase 0 Decisions

| Topic | Decision | Source |
|---|---|---|
| host-history.yml location | `.specrew/host-history.yml` (project-scoped) | clarify Q2 |
| TTY detection method | `[Console]::IsInputRedirected` | edge cases section + F-019 cross-platform precedent |
| Auto-select single available host | Yes (with notice; no prompt) | spec FR-003 |
| Category A migration timing | In F-043 (this feature), not a separate chore | clarify Q3 |
| Breadcrumb file lifetime | One update cycle (~one minor release) | spec FR-009 |
| Category B stays put | `.squad/decisions.md`, `.squad/identity/now.md`, etc. NOT migrated | spec FR-010 |
| `specrew host init <kind>` in v1 | No; per-host Crew runtime install is Slice 3 | clarify Q4 |
| host_resolution field in start-context.json | Yes; records HOW host was resolved + alternatives | spec FR-012 |
| Customized .squad/coordinator content handling | Detect via git diff; preserve customizations in new location | risks section |

## Phase 1 Design Artifacts

- [research.md](./research.md) — TTY detection precedent + brownfield migration mechanics + Category A inventory (cite Proposal 024 audit)
- [data-model.md](./data-model.md) — host-history.yml schema v1 + host_resolution field shape + breadcrumb file format
- [contracts/host-onboarding-interface.md](./contracts/host-onboarding-interface.md) — PowerShell helper signatures for read/write/probe/prompt
- [quickstart.md](./quickstart.md) — rehearsal commands for first-run / specrew host commands / brownfield migration

## Design Scope

### Files and components expected to change during implementation

| Surface | Planned change | Why it exists |
|---|---|---|
| `scripts/internal/host-history.ps1` (new) | Helpers: `Get-SpecrewHostHistory`, `Update-SpecrewHostHistory`, `Test-SpecrewHostHistorySchema`, `Resolve-SpecrewHostFromHistory` | Core persistence layer |
| `scripts/internal/host-runtime-inventory.ps1` (new) | Per-host Crew-runtime install detection: `Test-CopilotRuntimeInstalled` (`.squad/` exists), `Test-ClaudeRuntimeInstalled` (`.claude/agents/`), `Test-CodexRuntimeInstalled` (`.codex/agents/`) | For `specrew host status` per FR-007 |
| `scripts/specrew-start.ps1` | Extend host-selection logic per FR-002 (flag → history → probe → exit); add TTY-prompt code path; record `host_resolution` field in start-context.json (FR-012); persist updated history (FR-004) | Main integration point |
| `scripts/specrew-host.ps1` (new) | Command dispatcher for `list` / `use` / `status` subcommands | New CLI surface |
| `scripts/specrew.ps1` (entry wrapper) | Route `host` subcommand to specrew-host.ps1 | CLI surface |
| `scripts/internal/category-a-migration.ps1` (new) | `Move-SpecrewCategoryAToNewLocation`, `Test-SpecrewCategoryAAlreadyMigrated`, `Add-SpecrewMigrationBreadcrumb`, `Remove-SpecrewMigrationBreadcrumb` (after one update cycle) | Slice 1 relocation logic |
| `scripts/specrew-init.ps1` | Write Category A files to `.specrew/coordinator/` on greenfield (FR-008) | Greenfield path |
| `scripts/specrew-update.ps1` | Run Category A migration on brownfield (FR-009); detect customizations; preserve | Brownfield path |
| `extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1` | Update path references: write coordinator-governance to `.specrew/coordinator/` (was `.squad/coordinator/`); mirror to `.specify/` | Deployer-side change |
| `extensions/specrew-speckit/scripts/validate-governance.ps1` | Read coordinator content from new location; fallback to `.squad/coordinator/` during breadcrumb window (FR-011) | Validator-side change |
| `tests/integration/multi-host-onboarding.tests.ps1` (new) | All 13 FR coverage + 20+ assertions | Verification |
| `docs/user-guide.md` | New "Multi-Host Onboarding" section + `specrew host` command reference | Discoverability |
| `docs/getting-started.md` | Update host-selection step to mention first-run probe (interactive UX) | Discoverability |
| `CHANGELOG.md` | v0.29.0 entry | Rule 15 |
| Version manifests (4 files) | Bump to 0.29.0 | Rule 15 version-consistency |
| `proposals/104-multi-host-onboarding-and-selection-flow.md` | Flip `status: candidate` → `status: shipped`; add shipped-as/version metadata | Proposal lifecycle |
| `proposals/INDEX.md` | Move 104 from Candidate to Shipped; decrement Candidate count | Proposal 028 conventions |

### Files that will NOT change

- F-040's launch-dispatch code (Start-HostSession, Get-SpecrewHostLaunchInvocation) — F-043 builds ON TOP of F-040 but doesn't modify it
- F-041's catalog or cost-routing code — F-043's host_history.yml feeds F-041 reads but doesn't modify F-041
- F-042's cost-tracking code — F-043 doesn't touch cost.yml

## Quality Planning

### Risk dimensions

| Risk | Why it matters | Planned control |
|---|---|---|
| TTY detection unreliable on some pwsh hosts | First-run probe could prompt in CI (bad) or fail to prompt in TTY (worse) | `[Console]::IsInputRedirected` — canonical .NET check; verified in F-019 cross-platform. Tests mock IsInputRedirected for both paths |
| Category A migration breaks customized installs | Some users have edited `.squad/coordinator/specrew-governance.md` | Migration uses git diff against original template to detect customizations; preserves them in new location; warns user when customization detected |
| host-history.yml partial-write corruption | `specrew start` interrupted mid-update could leave malformed file | Atomic write via `Write-Utf8FileAtomic`; validate-on-read with regenerate-on-corruption fallback; schema versioning per Proposal 059 |
| Brownfield projects with both old + new coordinator location | Rare manual-intervention case | F-043 detects, refuses to migrate, prints reconciliation guidance |
| First-run probe slow on resource-constrained machines | Three parallel Get-Command + interactive prompt could feel laggy | <200ms target; F-040 baseline already shows <100ms for the probe |
| Non-TTY exit breaks existing automation | Existing CI scripts assume `specrew start` (no flag) launches Copilot | Migration: only fires on TRULY fresh projects without history; existing projects have implicit history (last_used_host: copilot from prior runs). Docs explicitly recommend passing --host copilot in CI for clarity |
| Validator can't find coordinator-governance during transition | Breadcrumb period must work | FR-011: validator reads new location first; falls back to old during breadcrumb window |

### Required verification evidence

- host-history.yml schema round-trips (write → read → assert equality)
- First-run probe with TTY: prompts user, persists selection
- First-run probe without TTY: exits non-zero with guidance
- Single-available-host auto-select: notice, no prompt
- `specrew host list` shows installed + selected + deferred kinds
- `specrew host use <kind>` updates history without launching
- `specrew host status` shows per-host Crew-runtime install state
- Category A migration on greenfield: files at `.specrew/coordinator/`
- Category A migration on brownfield: files move, breadcrumb at old location
- Validator reads from new location post-migration
- Customized brownfield content preserved through migration
- `host_resolution` field in start-context.json captures the resolution path

---

## Constitution Check

*Gate: must pass before and after design.*

- **Spec Authority Gate**: ✅ Pass — Plan stays inside the approved F-043 spec and 4 clarify defaults
- **Layering Gate**: ✅ Pass — Onboarding logic in new `scripts/internal/host-history.ps1` + `host-runtime-inventory.ps1` + `category-a-migration.ps1`; CLI in new `scripts/specrew-host.ps1`; existing files extended minimally
- **Traceability Gate**: ✅ Pass — Each FR maps to design artifact + test
- **Ownership Gate**: ✅ Pass — Implementer owns helpers + CLI + migration; Reviewer owns customized-content preservation correctness; Spec Steward owns Slice 1 boundary discipline (no Category B migration in F-043)
- **Capacity Gate**: ✅ Pass — ~10 SP single iteration; consistent with Proposal 104's 8-12 estimate
- **Drift/Reconciliation Gate**: ✅ Pass — Defaults documented for all 4 clarify questions
- **Verification Gate**: ✅ Pass — quickstart.md will document rehearsal commands

### Constitution Check Re-Evaluation (Post-Design)

To be completed after research.md, data-model.md, contracts/host-onboarding-interface.md, quickstart.md are written.

---

## Implementation Sequence (preview — full breakdown in tasks.md)

Iteration 001 (target: cover full FR scope in single iteration):

1. **host-history.yml schema + helpers** (~1.5 SP) — `scripts/internal/host-history.ps1`; schema v1
2. **host-runtime-inventory helpers** (~0.5 SP) — `scripts/internal/host-runtime-inventory.ps1`
3. **specrew start host-selection logic extension** (~2 SP) — FR-002 (flag → history → probe → exit); TTY detection; history update post-selection
4. **specrew host CLI command** (~1.5 SP) — `scripts/specrew-host.ps1` + entry wrapper route
5. **Category A migration logic** (~2 SP) — `scripts/internal/category-a-migration.ps1`; customization preservation; breadcrumb management
6. **Init + Update integration** (~1 SP) — `specrew init` writes new location; `specrew update` runs migration on brownfield
7. **Validator updates** (~0.5 SP) — `validate-governance.ps1` reads new location with fallback during breadcrumb window
8. **Integration tests** (~1 SP) — all 13 FR coverage in `tests/integration/multi-host-onboarding.tests.ps1`
9. **Docs + version bump + CHANGELOG + Proposal 104 status flip** (~0.5 SP)

Total: ~10 SP (matches Proposal 104's estimate)

## Out-of-iteration follow-ups

- `specrew host init <kind>` (per-host Crew runtime install — Proposal 024 Slice 3)
- Category B state file migration (Proposal 024 Slice 3 + careful coordination)
- User-global host-history.yml (future, if demand surfaces)
- Mid-session host switching (architectural change; future)
- Multi-developer host coordination (Proposal 010)
- Concurrent multi-host execution (Proposal 024 Scenario B)
