# Implementation Plan: Multi-Host Launch Path

**Branch**: `040-multi-host-launch-path` | **Date**: 2026-05-23 | **Spec**: [specs/040-multi-host-launch-path/spec.md](./spec.md)
**Input**: Approved feature specification + 4 clarify decisions (Antigravity deferred, `--host auto` deferred, non-fatal skill warnings, minimal coordinator-prompt surgery in F-040). Source proposal: file:///C:/Dev/Specrew/proposals/069-multi-host-launch-path.md (enriched 2026-05-23 with verified per-host CLI surfaces).

## Summary

Replace the single hard-coded launch invocation at `scripts\specrew-start.ps1:3131` with a per-host dispatcher. The dispatcher reads a `-Host <kind>` parameter (copilot|claude|codex), validates the host, probes PATH, applies per-host flag translation (`--remote` → host-appropriate flag; `--allow-all`/`--autopilot` → per-host permission flag), runs per-host skill-discoverability verification, applies minimal coordinator-prompt surgery for non-Squad hosts (FR-011), persists the selection in `.specrew/start-context.json`, and invokes the host CLI.

The bootstrap-context handshake ("Read `.specrew/last-start-prompt.md` and `.specrew/start-context.json` from the project root") is already host-portable verbatim per the 2026-05-23 internal coupling audit (Proposal 024's Abstraction Surface Inventory) — only the launch invocation and the body of `last-start-prompt.md` need per-host treatment.

Antigravity and `--host auto` are accepted by the parser but rejected with explicit "deferred" guidance (no silent fall-through). This keeps the surface stable so future small-fix slices can enable them without parser changes.

## Technical Context

**Language/Version**: PowerShell 7+ runtime scripts, Markdown governance artifacts, JSON state
**Primary Dependencies**: `scripts\specrew-start.ps1` (host dispatch, flag translation), `extensions\specrew-speckit\scripts\shared-governance.ps1` (no changes expected; bootstrap-context handshake already host-portable), `.specrew\start-context.json` schema v2 (no migration; new fields are additive)
**Storage**: `.specrew\start-context.json` (existing schema v2 from F-039; F-040 adds `selected_host` + `available_hosts` + `crew_runtime_status` fields)
**Testing**: New `tests\integration\multi-host-launch-path.tests.ps1` for per-host invocation shape + flag translation + missing-host guidance + skill warnings + persistence
**Target Platform**: Windows PowerShell / PowerShell 7 with mirror-safe behavior across `.specify` and extension copies
**Performance Goals**: Launch-time PATH probe stays under 100ms (three `Get-Command` calls in parallel via ForEach-Object -Parallel pattern from F-035)
**Constraints**: Copilot launch path stays byte-identical (no regression); per-host invocations are isolated dispatch arms; minimal prompt surgery for non-Squad hosts is opt-in via host kind
**Scale/Scope**: Three supported hosts in F-040 (copilot, claude, codex); two reserved-but-deferred (antigravity, auto); single iteration; ~12-15 SP

---

## Phase 0 Decisions

| Topic | Decision | Source |
|---|---|---|
| Per-host launch invocations | Use research-verified shapes: copilot `copilot --agent Squad ... -i`; claude `claude -p ... --add-dir`; codex `codex exec --cd ...` | research.md Task 1 + Proposal 069 enrichment |
| Working-directory flag | claude `--add-dir <path>` (same name as Copilot, confirmed); codex `--cd <path>` (in `codex exec` subcommand) | research.md Task 1 |
| Permission-flag translation | `--allow-all` → copilot `--allow-all`, claude `--dangerously-skip-permissions`, codex `--full-auto` | research.md Task 2 |
| Remote-control translation | `--remote` → copilot `--remote`, claude `--remote-control`, codex warn-and-continue | research.md Task 2 |
| Coordinator-prompt surgery scope | Two separate concerns: (a) **universal header rewrite** for ALL hosts (`"You are the Crew team coordinator..."` replaces the Squad-specific opening line — per FR-011 + INDEX.md 2026-05-21 terminology note); (b) **Squad-runtime-path strip** for non-Copilot hosts only (rules 12/35/37/42-44 per FR-012) | clarify decision Q4 (refined 2026-05-23) |
| Host capability handling | F-040 manages skills + slash-commands (uniformly via existing F-021 deploy); defers hooks/MCP/CLAUDE.md/AGENTS.md/subagents | research.md Task 5 |
| Skill-verification policy | Non-fatal warning naming each missing skill; launch proceeds | clarify decision Q3 |
| Antigravity / `--host auto` posture | Accept in parser, reject with "deferred" guidance | clarify decisions Q1 + Q2 |
| Host validation timing | Validate host kind before any other Specrew work; missing CLI = exit-1 with install guidance | research.md Task 3 |
| Selection persistence | `.specrew/start-context.json` gains `selected_host`, `available_hosts`, `crew_runtime_status` additive fields | data-model.md |
| Cross-platform launch parity | Reuse existing Windows `Start-Process pwsh` and Linux `SPECREW_DEFERRED_LAUNCH_FILE` patterns; per-host invocations slot into both branches | research.md Task 4 |

## Phase 1 Design Artifacts

- [research.md](./research.md) — five research tasks: verified CLI surfaces, flag-translation evidence, host-validation flow, cross-platform launch parity, host capability comparison (hooks/skills/slash-commands/subagents/MCP/project-memory)
- [data-model.md](./data-model.md) — additive fields on `.specrew/start-context.json` schema v2
- [contracts/host-launch-interface.md](./contracts/host-launch-interface.md) — per-host invocation builders, flag-translation helper, skill-verification helper signatures
- [quickstart.md](./quickstart.md) — exact rehearsal commands for each host + each flag-translation matrix cell + missing-host guidance + skill-warning surface

## Design Scope

### Files and components expected to change during implementation

| Surface | Planned change | Why it exists |
|---|---|---|
| `scripts\specrew-start.ps1` | Add `-Host <kind>` parameter + `--host` CLI alias parser; introduce `Get-SpecrewHostKind`, `Get-SpecrewHostLaunchInvocation`, `Test-SpecrewHostAvailable`, `Get-HostFlagTranslation` helpers; rewrite line 3131 dispatch | Single load-bearing literal per 2026-05-23 coupling audit |
| `scripts\internal\detect-hosts.ps1` (new) | Probe PATH for `copilot`, `claude`, `codex`; return availability map; populate `available_hosts` in start-context.json | Encapsulates the detection logic; testable in isolation |
| `scripts\internal\host-flag-translation.ps1` (new) | Per-host `--remote`, `--allow-all`, `--autopilot` translation map; warn-and-continue helper for unsupported flags | First instance of the per-host flag-translation framework; future flags compose in |
| `scripts\internal\coordinator-prompt-surgery.ps1` (new) | (a) Universal header rewrite for ALL hosts (`"You are Squad..."` → `"You are the Crew team coordinator..."`) per FR-011; (b) For non-Copilot hosts only: strip Squad-runtime-path directives (rules 12/35/37/42-44) per FR-012 | Minimum viable per clarify Q4 (refined 2026-05-23) |
| `extensions\specrew-speckit\scripts\shared-governance.ps1` | No changes expected; bootstrap-context handshake already host-portable. If skill-verification helper is needed in shared-governance, add `Test-HostSkillRoot -Host <kind>` | Mirror parity preserved automatically (no edits → no mirror sync needed) |
| `.specrew\start-context.json` schema | Additive fields `selected_host`, `available_hosts`, `crew_runtime_status` — backwards-compatible with v2 | No schema bump; F-039's schema v2 already accommodates additive fields |
| `tests\integration\multi-host-launch-path.tests.ps1` (new) | Per-host invocation shape; flag translation matrix; missing-host guidance; skill warnings; persistence | Standalone test suite per Proposal 042 conventions |
| `CHANGELOG.md` | Entry under "Unreleased" for v0.26.0 noting per-host launch path | Per Rule 15 |
| `Specrew.psd1` `ModuleVersion`, `.specrew\config.yml` `specrew_version`, `extensions\specrew-speckit\extension.yml` `version`, `.specify\extensions\specrew-speckit\extension.yml` `version` | Bump to 0.26.0 | Per Rule 15 version-consistency validator |
| `proposals\069-multi-host-launch-path.md` | Flip `status: draft` → `status: shipped`; add `shipped-as: feature-040`, `shipped-version: 0.26.0` | Per proposal lifecycle |
| `proposals\INDEX.md` | Move 069 from Draft to Shipped section | Per Proposal 028 conventions |

### Files that will NOT change

- `extensions\specrew-speckit\scripts\sync-boundary-state.ps1` — F-039's boundary enforcement is host-agnostic; no per-host modifications needed
- `extensions\specrew-speckit\squad-templates\coordinator\specrew-governance.md` — host-coupled directives stay; F-040's surgery is at *render time* in `coordinator-prompt-surgery.ps1`, not at source template. Proposal 024 Slice 2 owns source-template surgery
- All `.specify\extensions\specrew-speckit\*` files — no changes to extension content; mirror unchanged

## Quality Planning

### Risk dimensions

| Risk | Why it matters | Planned control |
|---|---|---|
| Copilot regression | F-040's primary contract is "no change to default flow" (behavioral) — the universal header swap is a deliberate behavioral change per FR-011 + INDEX.md 2026-05-21 terminology, but launch CLI invocation stays argv-identical for `--host copilot` and no-`--host` paths | Integration test asserts argv-identical Copilot invocation (launch path); separate test asserts header rewrite happened in body of `last-start-prompt.md` |
| Per-host invocation shape errors | Wrong flag name = silent broken launch | research.md Task 1 cites every flag with primary-doc URL; integration tests assert exact argv shape |
| Cross-platform parity | Windows uses `Start-Process pwsh`; Linux uses `SPECREW_DEFERRED_LAUNCH_FILE` | research.md Task 4 documents both paths; integration tests exercise both pattern via `$IsWindows` switch |
| Coordinator-prompt surgery missing terminology | "Squad" still appears in 40+ directives even after rule strip | Mitigation: FR-011 is documented as "minimum viable"; Proposal 024 Slice 2 is the full fix; visual diff in test suite ensures the four targeted rules are stripped and nothing else |
| Empirical verification gaps | Antigravity working-dir flag undocumented; codex `--cd` recent | Mitigation: Antigravity deferred entirely per clarify Q1; codex `--cd` flag empirically verified by research.md Task 1 before commit |
| Recovery from missing host | User invokes `--host claude` on machine without Claude | Mitigation: PATH probe before launch; explicit install guidance with documentation URL |

### Required verification evidence

- Per-host invocation argv shape (3 hosts × 2 flag-combo variants = 6 minimum cases)
- Flag translation matrix: `--remote`, `--allow-all`, `--autopilot` × 3 hosts = 9 cases
- Missing-host guidance: 3 cases (each host CLI missing → install guidance prints)
- Skill-warning surface: 3 cases (missing skill on each host triggers warning)
- `.specrew/start-context.json` schema additive-field validation
- Cross-platform branches: Windows + Linux launch paths both verified (CI matrix already exists)
- Coordinator-prompt surgery: universal header rewrite verified on all 3 hosts + 4 rules stripped on non-Copilot hosts only + everything else unchanged
- Antigravity / `--host auto` rejection: explicit deferred-guidance text + exit code 1

---

## Constitution Check

*Gate: must pass before and after design.*

- **Spec Authority Gate**: ✅ Pass — Plan stays inside the approved F-040 spec and the 4 clarify decisions
- **Layering Gate**: ✅ Pass — Launcher responsibilities (host dispatch, flag translation) stay in `scripts\specrew-start.ps1` + `scripts\internal\*`; coordinator-prompt surgery is render-time only (not source-template modification); no shared-governance changes
- **Traceability Gate**: ✅ Pass — Each FR maps to a research task + a test case
- **Ownership Gate**: ✅ Pass — Implementer owns dispatcher + helpers; Reviewer owns per-host invocation shape verification; no Spec Steward intervention needed for this scope
- **Capacity Gate**: ✅ Pass — 12-15 SP single iteration; well within sustainable scope
- **Drift/Reconciliation Gate**: ✅ Pass — F-040 explicitly reconciles "Antigravity in spec → deferred per clarify Q1"; same for `--host auto`
- **Verification Gate**: ✅ Pass — quickstart.md will document exact rehearsal commands for each host + each flag combo

### Constitution Check Re-Evaluation (Post-Design)

To be completed after research.md, data-model.md, contracts/host-launch-interface.md, quickstart.md are written.

---

## Implementation Sequence (preview — full breakdown in tasks.md)

Iteration 001 (target: this single iteration covers full feature scope):

1. **Host parameter + parser** (~1.5 SP) — `-Host` parameter, `--host` CLI alias, validation, deferred-host rejection
2. **Host detection + PATH probe** (~1 SP) — `scripts\internal\detect-hosts.ps1`, parallel probe, `available_hosts` in start-context
3. **Per-host launch invocations** (~3 SP) — three dispatch arms in `Get-SpecrewHostLaunchInvocation`; cross-platform parity
4. **Flag translation helper** (~2 SP) — `scripts\internal\host-flag-translation.ps1`; remote / allow-all / autopilot per host
5. **Coordinator-prompt surgery** (~2 SP) — `scripts\internal\coordinator-prompt-surgery.ps1`; (a) universal header rewrite for ALL hosts; (b) Squad-runtime-path strip for non-Copilot hosts only
6. **Skill-discoverability verification** (~1 SP) — `Test-HostSkillRoot` per host; non-fatal warnings
7. **start-context.json persistence** (~0.5 SP) — additive fields: `selected_host`, `available_hosts`, `crew_runtime_status`
8. **Integration test suite** (~2 SP) — `tests\integration\multi-host-launch-path.tests.ps1` covering all 6 verification-evidence categories
9. **Docs + version bump + CHANGELOG** (~1 SP) — getting-started + user-guide updates; Rule 15 version sync
10. **Proposal status flip + INDEX update** (~0.5 SP) — 069 → shipped; INDEX move

Total: ~14.5 SP, in the 12-15 SP range from the spec.

## Out-of-iteration follow-ups

- Antigravity launch invocation (separate small-fix slice once `agy` working-dir verified)
- `--host auto` smart selection (Proposal 104 / F-043)
- Full coordinator-prompt directive surgery (Proposal 024 Slice 2)
- Per-host Crew runtime install (Proposal 024 Slice 3)
- `--host` flag for `specrew init` (currently init is host-agnostic; defer if user requests later)
