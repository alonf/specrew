# Feature Specification: Multi-Host Onboarding + Selection Flow

**Feature Branch**: `043-multi-host-onboarding`
**Created**: 2026-05-23
**Status**: Draft
**Input**: User direction (2026-05-23 multi-host research session): six explicit questions about init timing, host detection, state location, and abstraction layer scope. Documented in Proposal 104 Decision Matrix.
**Source proposal**: file:///C:/Dev/Specrew/proposals/104-multi-host-onboarding-and-selection-flow.md
**Composes with**: F-040 Multi-Host Launch Path (consumes host enum + selected_host + available_hosts + crew_runtime_status fields), F-041 Cost-Aware Model Routing (per-host catalog refresh fires via host-history), F-042 Token Economy MVP (cost.yml host attribution uses host_history.yml resolution), Proposal 024 Multi-Host Runtime Abstraction (Slice 1 of the 4-slice ladder)
**Release urgency**: medium — gates external-tester usability; not on the cost-reduction critical path but unblocks broader adoption

## Clarifications

### Session 2026-05-23

Spec drafted overnight while user is offline. Four clarify defaults documented inline.

- Q1: First-run probe — interactive prompt for host selection, or strict-non-interactive (require explicit --host)? → **Default A: Interactive when stdin is a TTY; non-TTY exits with actionable guidance.** Matches the spec's AC8 (non-interactive runs with no --host and no last-selected exit with guidance, not hang). TTY detection preserves the dev-friendly first-run UX without breaking automation.
- Q2: `host-history.yml` location — `.specrew/host-history.yml` (project-scoped) or `~/.specrew/host-history.yml` (user-global)? → **Default A: Project-scoped (`.specrew/host-history.yml`).** Per-project last-host preference matches the per-project Spec Kit + Squad model. User-global is a future feature if it surfaces real demand.
- Q3: Category A migration timing — happens in F-043 (this feature) or as a separate chore? → **Default A: In F-043.** Slice 1 of the 4-slice ladder explicitly includes Category A relocation (Specrew-owned templates moving from `.squad/` to `.specrew/coordinator/`). Breaking the migration into a separate chore creates a half-state where 043 ships but the relocation hasn't happened.
- Q4: `specrew host` command surface — just `list`/`use`/`status`, or include `init <kind>` for per-host Crew runtime install? → **Default A: Just `list`/`use`/`status` in v1.** Per-host Crew runtime install is Proposal 024 Slice 3 territory; F-043 stays scoped to the UX layer. `specrew host init <kind>` is a natural follow-up small-fix once Slice 3 ships.

## User Scenarios & Testing *(mandatory)*

### User Story 1 — First-run probe makes multi-host frictionless for new users (Priority: P1)

A new external tester runs `specrew init` on a fresh project, then `specrew start "build a thing"` without specifying `--host`. With no prior host history, Specrew probes PATH for the supported hosts (copilot/claude/codex), shows them what's available, and prompts them to pick one. The selection is persisted in `.specrew/host-history.yml` so subsequent `specrew start` invocations use the same host without re-prompting.

**Why this priority**: F-040 ships `--host` as a flag but defaults to Copilot when no flag is provided. For new users who have Claude Code installed but not Copilot CLI, this current behavior leads to "specrew start" failing with "copilot not on PATH" — confusing and frustrating. First-run probe converts this into a friendly question.

**Independent Test**: Run `specrew start` (no flag) in an interactive terminal on a fresh project. Verify Specrew lists available hosts and prompts for selection. Confirm the chosen host gets persisted to `.specrew/host-history.yml`. Run `specrew start` again — verify no re-prompt; the persisted host is used.

**Acceptance Scenarios**:

1. **Given** a fresh project with `.specrew/host-history.yml` absent, **When** `specrew start "<task>"` runs in a TTY with no `--host` flag, **Then** Specrew probes PATH, prints the available hosts (e.g., "Available: copilot, claude"), and prompts "Select a host"
2. **Given** the user selects `claude` at the prompt, **When** the host probe completes, **Then** `.specrew/host-history.yml` is created with `last_selected_host: claude` and the host is launched
3. **Given** `.specrew/host-history.yml` exists with `last_selected_host: claude`, **When** `specrew start "<task>"` runs with no `--host` flag, **Then** Specrew uses claude without re-prompting (matches behavior to F-040's existing flow but reads from history rather than defaulting to copilot)
4. **Given** `specrew start "<task>"` runs in a non-TTY (stdin not a TTY) with no `--host` and no last-selected, **When** the probe-or-prompt step runs, **Then** Specrew exits with explicit guidance: "Non-interactive run: pass --host <kind> explicitly. Available: <list>"
5. **Given** only one host is available on PATH, **When** the probe runs, **Then** Specrew auto-selects with a notice ("Only copilot available; selecting") rather than prompting — single-option auto-select reduces friction
6. **Given** none of the supported hosts are available on PATH, **When** the probe runs, **Then** Specrew prints actionable install guidance for all three (links from F-040's `Get-SpecrewHostInstallGuidance`) and exits non-zero

---

### User Story 2 — `specrew host` command surfaces host status for inspection + switching (Priority: P2)

The user wants three things from a `specrew host` command:

- `specrew host list` — what hosts are available on PATH + which is currently selected
- `specrew host use <kind>` — switch the selected host without launching (just updates `host-history.yml`)
- `specrew host status` — deeper view: which hosts have Crew-runtime installed for this project (`.squad/` vs `.claude/agents/` vs `.codex/agents/`)

**Why this priority**: Without a `specrew host` command, users have to either (a) read `.specrew/host-history.yml` directly, or (b) re-run `specrew start --host <other>` to switch. The dedicated command surface is a small UX improvement that prevents config-file editing for routine operations.

**Independent Test**: After F-043 ships, run `specrew host list` and verify it lists available hosts + selected. Run `specrew host use claude` and verify `host-history.yml` updates. Run `specrew host status` and verify it shows per-host Crew-runtime install state.

**Acceptance Scenarios**:

1. **Given** F-043 ships, **When** `specrew host list` runs, **Then** the output shows: (a) installed hosts on PATH, (b) currently-selected host from `host-history.yml`, (c) reserved-but-deferred kinds (antigravity, auto) with their deferred reason
2. **Given** `specrew host use claude` runs, **When** the command completes, **Then** `host-history.yml` `last_selected_host` is set to `claude` (no launch happens; just persistence)
3. **Given** `specrew host status` runs on a project where Copilot+Squad is the active runtime, **When** the output renders, **Then** it shows: copilot=available+runtime-installed; claude=available+runtime-NOT-installed (bootstrap_only); codex=available+runtime-NOT-installed
4. **Given** `specrew host use <kind>` is invoked with a deferred or unsupported kind, **When** the command runs, **Then** it errors with the same actionable guidance F-040's host validator already produces

---

### User Story 3 — Category A migration moves Specrew-owned templates from `.squad/` to `.specrew/coordinator/` (Priority: P2)

Specrew currently writes some of its OWN templates into `.squad/` because Squad is the only Crew runtime today. After F-040 ships, that coupling is wrong: when Claude becomes a Crew runtime (Proposal 024 Slice 3 territory), Specrew-owned content shouldn't live in `.squad/`. F-043 ships the Category A migration — Specrew-owned templates (`coordinator/specrew-governance.md`, charters, ceremonies, directives, skill templates listed in Proposal 024's coupling-audit Category A) move to `.specrew/coordinator/`. Squad-runtime state (Category B: `decisions.md`, `identity/now.md`, etc.) stays at host-native paths.

**Why this priority**: Without migration, the abstraction is theoretical. F-043 is Slice 1 of the 4-slice ladder; the relocation is the load-bearing change that enables non-Copilot hosts to consume Specrew governance without going through `.squad/`.

**Independent Test**: After F-043 ships, verify on a fresh project that `.specrew/coordinator/specrew-governance.md` exists (and contains the same content that was at `.squad/coordinator/` before). `specrew update` on a brownfield project migrates content non-destructively (old location leaves a deprecation breadcrumb for one update cycle).

**Acceptance Scenarios**:

1. **Given** a greenfield project, **When** `specrew init` runs, **Then** Category A files (Specrew-owned templates per Proposal 024 audit) are written to `.specrew/coordinator/` rather than `.squad/coordinator/`
2. **Given** a brownfield project that already has `.squad/coordinator/specrew-governance.md`, **When** `specrew update` runs, **Then** content migrates to `.specrew/coordinator/specrew-governance.md`; old location keeps a deprecation breadcrumb file pointing at the new location
3. **Given** the breadcrumb period (one update cycle, ~one minor release), **When** `specrew update` runs again, **Then** the breadcrumb file is removed
4. **Given** validate-governance.ps1 reads coordinator-governance content, **When** the validator runs post-F-043, **Then** it reads from `.specrew/coordinator/` (not `.squad/coordinator/`)
5. **Given** Category B files (`.squad/decisions.md`, `.squad/identity/now.md`, etc.), **When** F-043's migration runs, **Then** they are LEFT in place at host-native paths (NOT migrated; that's Proposal 024 Slice 3 work)

---

### Edge Cases

- **TTY detection on Windows PowerShell**: `[Console]::IsInputRedirected` is the canonical check. Linux/macOS use the same property. CI environments (GitHub Actions) report stdin redirected; that's the non-interactive path that exits with guidance (AC4 of US1).
- **Multiple hosts auto-detected but conflicting user expectation**: e.g., user has all 3 hosts but wants codex. F-043's probe + auto-select-when-one-available case (AC5) doesn't fire; multi-host shows the prompt; user picks codex. Same UX as US1.
- **`host-history.yml` corrupted or partially-written**: Specrew tolerates parse errors with a regenerate-and-warn path. Schema versioning (per Proposal 059 pattern) ensures forward-compatibility.
- **`specrew host use <kind>` for a host that's NOT installed**: errors with the install guidance from F-040's `Get-SpecrewHostInstallGuidance` — same UX as `specrew start --host <missing>`.
- **`specrew update` mid-Category-A-migration interrupted**: idempotent — re-run `specrew update` resumes; breadcrumb file disambiguates state.
- **Brownfield project with both `.squad/coordinator/` AND `.specrew/coordinator/` populated** (rare; manual user intervention): F-043's migration sees `.specrew/coordinator/` exists, skips the migration, warns the user to manually reconcile if `.squad/coordinator/` content differs.

## Functional Requirements

| FR | Statement |
|---|---|
| FR-001 | A new file `.specrew/host-history.yml` MUST be created on first `specrew start` invocation. Schema: `host_history: { schema_version: 1, last_selected_host, hosts: { <kind>: { first_used_at, last_used_at, crew_runtime_installed, crew_runtime_path } } }` |
| FR-002 | `specrew start` host-selection logic (in order): (1) `--host` flag if present, (2) `host_history.yml` `last_selected_host` if present, (3) first-run probe with interactive prompt if TTY, (4) non-interactive exit with guidance if non-TTY |
| FR-003 | First-run probe MUST list available hosts (from F-040's `Get-SpecrewAvailableHosts`), exclude deferred kinds (antigravity, auto), and prompt the user to pick. Single available host auto-selects with a notice (no prompt) |
| FR-004 | After any host selection (via flag, prompt, or last-history), Specrew MUST update `host-history.yml`: set `last_selected_host`, set `last_used_at`, ensure the host entry exists; set `first_used_at` if not already set |
| FR-005 | `specrew host list` MUST emit: (a) supported hosts with available-on-PATH + currently-selected status, (b) deferred kinds with their deferred reason |
| FR-006 | `specrew host use <kind>` MUST validate the host kind (reuses F-040's deferred/unsupported rejection), update `last_selected_host` in `host-history.yml`, and NOT launch the host CLI |
| FR-007 | `specrew host status` MUST report per-host Crew-runtime install state: copilot=installed-if-`.squad/`-exists; claude=installed-if-`.claude/agents/`-exists; codex=installed-if-`.codex/agents/`-exists |
| FR-008 | `specrew init` on a greenfield project MUST write Category A files (Specrew-owned templates: coordinator-governance.md, charters, ceremonies, directives, skill templates per Proposal 024 audit) to `.specrew/coordinator/` rather than `.squad/coordinator/` |
| FR-009 | `specrew update` MUST migrate brownfield projects: Category A files at `.squad/coordinator/` move to `.specrew/coordinator/`; a deprecation breadcrumb file at the old location points to the new location for one update cycle |
| FR-010 | Category B files (`.squad/decisions.md`, `.squad/identity/now.md`, `.squad/team.md`, `.squad/config.json`, `.squad/agents/<role>/charter.md`) MUST stay at host-native paths. F-043 does NOT migrate them (that's Proposal 024 Slice 3 work) |
| FR-011 | `validate-governance.ps1` and other validators reading coordinator-governance content MUST read from `.specrew/coordinator/` post-F-043. Fallback to `.squad/coordinator/` only during the one-update-cycle breadcrumb window |
| FR-012 | `.specrew/start-context.json` MUST gain a `host_resolution` field recording HOW the host was resolved (`flag` / `last-selected` / `first-run-prompt` / `auto-single-available`) plus the alternatives available at probe time |
| FR-013 | Non-interactive runs (stdin not a TTY) with no `--host` flag and no `last_selected_host` MUST exit non-zero with actionable guidance ("Non-interactive run: pass --host <kind>. Available: <list>") rather than hang waiting for input |

## Out of Scope

This feature explicitly does NOT include:

- **Concurrent multi-host execution** — Scenario B of Proposal 024. F-043 supports MOVING between hosts (via `--host <other>` flag or `specrew host use`) but only one host runs per session
- **`specrew host init <kind>`** — per-host Crew runtime install (deploy `.claude/agents/`, `.codex/agents/`). That's Proposal 024 Slice 3 territory
- **Category B state file migration** — `.squad/decisions.md`, `.squad/identity/now.md`, etc. stay at host-native paths per FR-010
- **User-global host-history** — `~/.specrew/host-history.yml`. Project-scoped per clarify Q2
- **Mid-session host switching** — same constraint as F-040; end the session and restart with a different `--host`
- **Multi-developer host coordination** — Proposal 010 Multi-Developer Reconciliation. Each developer has their own `host-history.yml`
- **Concurrent host detection capability probing** — deep probing of "which models each host supports" is Proposal 068 / F-041's catalog scope, not F-043

## Composition

- **104 (this feature's source proposal)** — full design surface; F-043 implements all six question decisions
- **069 / F-040 Multi-Host Launch Path (shipped v0.26.0)** — F-043 consumes host enum + selected_host + available_hosts + crew_runtime_status fields
- **068 / F-041 Cost-Aware Model Routing** — F-043's `host_history.yml` informs F-041's per-host catalog refresh decisions
- **070 / F-042 Token Economy MVP** — F-043's host resolution feeds F-042's `host:` field in cost.yml records
- **024 Multi-Host Runtime Abstraction** — F-043 is Slice 1 of the 4-slice ladder (Slice 0 = 069/F-040; Slice 2 = directive surgery; Slice 3 = per-host Crew runtime install)
- **058 Plugin-Based Multi-Host Distribution** — when 058 ships, per-host packaging composes with F-043's per-host Crew-runtime install (the missing Slice 3 work)
- **059 Legacy-State Read-Tolerance + Schema Migration Discipline** — F-043's `host-history.yml` schema versioning follows 059's pattern; brownfield migration in FR-009 is exemplary use of 059's discipline
- **067 Small-Fix Slice Type** — F-043's ship cycle follows 067's contract

## Success Criteria (Outcome-Focused)

- **First-run UX**: new user can run `specrew init` + `specrew start "<task>"` on a fresh project; gets prompted to pick a host from what's installed; choice is remembered
- **`specrew host` command surface works**: `list`, `use`, `status` all behave per FRs 5-7
- **Category A migration**: greenfield projects ship with `.specrew/coordinator/` populated; brownfield projects migrate non-destructively via `specrew update`
- **Validator parity**: validate-governance.ps1 reads from `.specrew/coordinator/` after F-043 without breaking existing projects (breadcrumb period covers transition)
- **Non-TTY graceful**: CI runs and automation get explicit guidance instead of hanging

## Risks

- **TTY detection edge cases** — some pwsh hosts report stdin redirection inconsistently. Mitigation: use `[Console]::IsInputRedirected` which is the canonical .NET cross-platform check; verified in F-019 cross-platform validation
- **Category A migration breaks downstream projects** — if a downstream project has CUSTOMIZED `.squad/coordinator/specrew-governance.md`, the migration must preserve those edits. Mitigation: migration uses `git diff` against the original template to detect customizations; preserves them in the new location
- **`host-history.yml` corruption during partial-write** — if `specrew start` is interrupted mid-update, the file could be empty/malformed. Mitigation: write through `Write-Utf8FileAtomic` (existing helper); validate on read with regenerate-on-corruption fallback
- **Brownfield projects with both old and new coordinator location** — rare manual-intervention case. Mitigation: F-043 detects, refuses to migrate, prints reconciliation guidance
- **First-run probe latency** — three parallel `Get-Command` calls (F-040 pattern). Should be <100ms but on slow filesystems could be more. Mitigation: existing F-040 timing; no new probes
- **Non-TTY exit on automation that expected default-copilot** — if existing CI assumes `specrew start` (no flag) launches Copilot, F-043's non-TTY guidance breaks that assumption. Mitigation: brownfield projects keep last-host-was-copilot as the implicit history; the non-TTY exit only fires on truly fresh projects without any history. F-043 docs explicitly call out the migration: CI scripts should pass `--host copilot` explicitly
