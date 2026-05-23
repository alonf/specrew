# Feature Specification: Antigravity Host Follow-up Slice

**Feature Branch**: `antigravity-host-followup`
**Created**: 2026-05-23
**Status**: Draft (small-fix slice; awaiting empirical-verification before scheduling)
**Input**: F-040 clarify Q1 deferred Antigravity entirely from F-040 scope: "Antigravity's working-directory flag is undocumented; remote-control surface unverified; 2026-06-18 Gemini free-tier deadline adds risk. Antigravity stays in Proposal 069's scope but ships as a separate small-fix slice after F-040 proves the dispatch pattern."
**Source proposal**: file:///C:/Dev/Specrew/proposals/069-multi-host-launch-path.md (Antigravity preview status section)
**Slice classification**: Per Proposal 067 Small-Fix Slice — code + tests + CHANGELOG + proposal-entry update + INDEX update at ship time; ≤5 SP; trivially revertable.
**Composes with**: F-040 (extends the host enum + dispatch); F-041 (catalog v2 already accommodates `antigravity` host entry); F-042 (cost.yml schema already supports antigravity attribution)

## Why this is a slice, not a feature

F-040 ships the multi-host launch path with three supported hosts (copilot/claude/codex). Antigravity was reserved in the host-kind parser but rejected with explicit deferred-guidance text. This slice fills that gap by adding the fourth host with the documented constraints surfaced as warnings.

Slice scope is intentionally narrow because the empirical verification gaps are real:

1. **`agy --print` working-directory flag undocumented** at F-040 research time (2026-05-23). The slice needs the maintainer to either find the flag in current Antigravity docs OR design around it (shell `cd` before invocation).
2. **`agy --print` session-ID emission is an open issue** ([antigravity-cli#7](https://github.com/google-antigravity/antigravity-cli/issues/7)) — affects session-resume contract.
3. **2026-06-18 Gemini CLI free-tier deadline** — Antigravity users hit a billing wall after that date unless they have Google AI Pro/Ultra ($100/mo) or enterprise Gemini Agent Platform API keys.

## Slice scope (what ships)

| Item | Treatment |
|---|---|
| `specrew start --host antigravity` accepts the kind | Move `antigravity` from `Get-SpecrewDeferredHostKinds` to `Get-SpecrewSupportedHostKinds` |
| `agy` binary detection | Add to F-040 `Get-SpecrewAvailableHosts` parallel probe |
| Launch invocation | `agy -p '<bootstrap-prompt>' --output-format json` per research; working-directory via `Set-Location` before invocation (shell-cwd approach) until empirical verification clears `--cwd` flag |
| Skill verification | `.agents/skills/` already deployed by F-021 — Antigravity's native skill convention. F-040's `Test-HostSkillRoot` works as-is |
| Flag translation | `--remote` → warn-and-continue (no verified Antigravity remote-control surface); `--allow-all` → unverified mapping, ship as warn-and-continue with no flag added; `--autopilot` → drop with notice |
| Coordinator prompt surgery | FR-011 universal Crew header applies; FR-012 Squad-runtime-path strip applies; FR-014 pwsh-form rewrite N/A (Antigravity has slash commands via `.agents/skills/` so slash commands work) |
| 2026-06-18 deadline warning | Surfaced at launch when `--host antigravity` is used and current date >= 2026-06-01 (two weeks before) |
| Session resume | Document the [antigravity-cli#7](https://github.com/google-antigravity/antigravity-cli/issues/7) gap in user-guide; Specrew session-resume contract degraded to "best effort" for Antigravity host |
| F-041 catalog | Catalog v2 schema already supports `antigravity` host entry (Proposal 068 enrichment). F-041's discovery skill can populate it. No changes needed |
| F-042 cost.yml | Schema already supports `host: antigravity`. F-042 records can be written for antigravity-attributed work |

## Out of slice scope

- Empirical resolution of `agy --print` working-directory flag — if user finds documentation, that's a separate small-fix to remove the shell-cwd fallback
- Session-resume parity with other hosts — waits for [antigravity-cli#7](https://github.com/google-antigravity/antigravity-cli/issues/7) resolution upstream
- Antigravity remote-control wiring — waits for upstream surface
- Antigravity per-host Crew runtime install (Proposal 024 Slice 3)
- Migration of any existing Antigravity deferred-guidance test assertions (those become updated assertions for the new functional path)

## Functional Requirements

| FR | Statement |
|---|---|
| FR-001 | `Get-SpecrewSupportedHostKinds` MUST include `antigravity`. `Get-SpecrewDeferredHostKinds` MUST shrink to just `auto` |
| FR-002 | `Get-SpecrewHostBinary -HostKind antigravity` MUST return `agy` |
| FR-003 | `Get-SpecrewHostSkillRoot -HostKind antigravity -ProjectPath <path>` MUST return `<path>/.agents/skills` (Antigravity's native skill convention) |
| FR-004 | `Get-SpecrewHostInstallGuidance -HostKind antigravity` MUST return actionable install guidance citing the official Antigravity install page |
| FR-005 | `Get-SpecrewHostLaunchInvocation -HostKind antigravity` MUST return `@{ Binary = 'agy'; Args = @('-p', '<bootstrap>', '--output-format', 'json') }`. Working directory MUST be set via `Set-Location` before invocation since `--cwd`/`--add-dir` flag is undocumented |
| FR-006 | When `--host antigravity --remote` is used, Specrew MUST emit a warn-and-continue notice (same pattern as Codex `--remote`) and launch without remote wiring |
| FR-007 | When `--host antigravity --allow-all` is used, Specrew MUST emit a warn-and-continue notice ("Antigravity --allow-all mapping unverified; launching with no permission-bypass flag") and launch without the host-side flag |
| FR-008 | When `--host antigravity --autopilot` is used, Specrew MUST drop the flag with an informational notice ("Antigravity has no autopilot equivalent; use --autonomous for unattended runs" — same pattern as Claude) |
| FR-009 | When `--host antigravity` is invoked AND the current date is on or after 2026-06-01 (two weeks before the Gemini deadline) AND no Google AI Pro/Ultra subscription evidence is configured, Specrew MUST emit a warning at the launch summary citing the 2026-06-18 deadline |
| FR-010 | F-040's `Test-HostSkillRoot -HostKind antigravity` MUST work as-is (verifies `.agents/skills/*.md` discoverability) since F-021 already deploys there |
| FR-011 | F-040's `Invoke-SpecrewCoordinatorPromptSurgery -HostKind antigravity` MUST: (a) apply universal Crew header (FR-011 of F-040); (b) apply Squad-runtime-path strip (FR-012 of F-040 — Antigravity is non-Copilot); (c) NOT apply Codex pwsh-form rewrite (Antigravity supports slash commands via `.agents/skills/`) |
| FR-012 | F-040 deferred-host guidance for `auto` MUST remain unchanged (still rejected with Proposal 104 guidance). Only `antigravity` graduates from deferred to supported |

## Acceptance Scenarios

### User Story 1 — Antigravity launch parity with other hosts

**Given** Antigravity CLI (`agy`) is installed on PATH, **When** `specrew start --host antigravity "<task>"` runs, **Then** Specrew invokes `agy -p '<bootstrap>' --output-format json` from the project directory (via Set-Location), reads `.agents/skills/` as the skill root, applies universal Crew header + Squad-runtime-path strip, and launches the lifecycle.

### User Story 2 — Deferred-kind rejection contracts to just `auto`

**Given** `specrew start --host antigravity` runs after this slice ships, **When** the host validator runs, **Then** the launch proceeds (no longer rejected). When `specrew start --host auto` runs, the deferred-guidance pointing to Proposal 104 STILL fires.

### User Story 3 — Gemini deadline warning

**Given** the current date is 2026-06-15 (within two weeks of the Gemini deadline), **When** `specrew start --host antigravity` runs and the user has no Google AI Pro/Ultra subscription evidence in `.specrew/config.yml`, **Then** Specrew emits a clear warning at the launch summary: "Antigravity uses Google's Gemini infrastructure. The Gemini CLI free tier stops on 2026-06-18 (3 days from now). Configure Google AI Pro/Ultra subscription or enterprise API key to continue using Antigravity after that date."

### User Story 4 — Flag-translation degraded-but-honest

**Given** `specrew start --host antigravity --remote --allow-all --autopilot` runs, **When** the launch happens, **Then**:

1. `--remote` → warn-and-continue (no Antigravity remote-control surface verified)
2. `--allow-all` → warn-and-continue (no permission-bypass flag added)
3. `--autopilot` → drop with notice (no Antigravity autopilot equivalent)
4. The user still gets the session but with multiple warnings making the degradation visible

## Implementation Sequence

| Step | Surface | Effort |
|---|---|---|
| Move `antigravity` from deferred to supported in `Get-SpecrewSupportedHostKinds` / `Get-SpecrewDeferredHostKinds` | `scripts/internal/detect-hosts.ps1` | 0.25 SP |
| Add `agy` binary in `Get-SpecrewHostBinary`, install guidance, skill root | `scripts/internal/detect-hosts.ps1` | 0.5 SP |
| Add `antigravity` arm to `Get-SpecrewHostLaunchInvocation` with `agy -p '<bootstrap>' --output-format json` + shell-cwd via Set-Location | `scripts/specrew-start.ps1` | 0.75 SP |
| Add `antigravity` flag-translation mappings (remote/allow-all/autopilot — all warn-or-drop) | `scripts/internal/host-flag-translation.ps1` | 0.5 SP |
| Add 2026-06-18 deadline warning logic | `scripts/specrew-start.ps1` (new helper `Test-AntigravityGeminiDeadlineWarning`) | 0.5 SP |
| Update F-040 `Invoke-SpecrewCoordinatorPromptSurgery` to handle Antigravity (same path as non-Copilot hosts; no Codex pwsh-form rewrite) | `scripts/internal/coordinator-prompt-surgery.ps1` | 0.25 SP |
| Update existing F-040 tests: deferred-guidance test for `antigravity` now becomes a positive test that Antigravity launches; tests for `auto` deferred-guidance preserved | `tests/integration/multi-host-launch-path.tests.ps1` | 0.5 SP |
| New tests: Antigravity argv shape; 2026-06-18 deadline warning fires; flag translations | `tests/integration/multi-host-launch-path.tests.ps1` (extended) | 0.5 SP |
| Update `docs/getting-started.md` host table — Antigravity moves from deferred to supported | `docs/getting-started.md` | 0.25 SP |
| Update `docs/user-guide.md` Multi-Host Launch section — Antigravity row + Gemini deadline note + caveats (working-directory, session-resume) | `docs/user-guide.md` | 0.25 SP |
| Update `proposals/069-multi-host-launch-path.md` — note Antigravity follow-up shipped (alongside the existing shipped marker) | `proposals/069-multi-host-launch-path.md` | 0.25 SP |
| CHANGELOG entry under v0.26.x (slice) or v0.27.0 (depending on bundle scheduling) | `CHANGELOG.md` | 0.25 SP |

Total: ~4.25 SP (within Proposal 067 small-fix slice envelope ≤5 SP)

## Risks

- **`agy --print` working-directory flag empirically broken** — if Set-Location doesn't propagate to `agy` child process correctly, the session has wrong cwd. Mitigation: smoke test on the maintainer's machine before merge; document the constraint in user-guide if it surfaces
- **Session-resume contract weaker than other hosts** — `agy --print` session-ID emission gap means Specrew can't reliably resume a specific Antigravity session. Mitigation: document explicitly in user-guide; Specrew session-resume becomes best-effort for Antigravity until upstream resolves
- **Gemini deadline triggers warning too eagerly** — current implementation warns for two weeks. Mitigation: configurable threshold via `.specrew/config.yml` `antigravity_deadline_warning_lead_days` (defaults to 14)
- **Existing F-040 tests fail (deferred-guidance assertions for antigravity)** — those tests now assert the OPPOSITE behavior (launch works). Mitigation: update the tests as part of the slice; new positive tests replace the deferred-guidance tests for antigravity (auto-rejection tests preserved)

## Scheduling note

This slice is **not on the cost-reduction critical path** (F-040 → F-041 → F-042 → F-043). It can ship in parallel with that sequence or after the sequence stabilizes. User decision: queue as a v0.26.x point release after F-040 merges, or bundle with v0.27.0 (F-041 ship). My recommendation: queue as v0.26.1 small-fix after F-040 merges + user has run the multi-host smoke test. The empirical verification of `agy` working-directory flag needs hands-on testing the user can do post-merge.
