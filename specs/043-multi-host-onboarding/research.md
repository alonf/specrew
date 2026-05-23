# Research: Multi-Host Onboarding + Selection Flow

**Spec**: [spec.md](./spec.md) | **Plan**: [plan.md](./plan.md) | **Date**: 2026-05-23
**Inputs**: Proposal 104 decision matrix (commit `e3c47ddd` on main, 2026-05-23) addressing the user's 6 explicit architectural questions; Proposal 024 Abstraction Surface Inventory (Category A taxonomy); F-040 ship artifacts (host enum, selected_host, available_hosts, crew_runtime_status fields); F-019 cross-platform validation experience.

## Task 1: TTY detection across pwsh hosts (FR-002, FR-013)

**Decision**: Use `[Console]::IsInputRedirected` as the canonical TTY check. Verified across pwsh hosts in F-019 cross-platform validation.

### Evidence

- `[Console]::IsInputRedirected` is .NET's cross-platform check; consistent on Windows (CMD, PowerShell ISE, pwsh, Windows Terminal) and Linux/macOS (bash, zsh, tmux, screen)
- CI environments (GitHub Actions, GitLab CI) report stdin as redirected → non-TTY → exit with guidance (FR-013)
- Interactive terminals (local pwsh, WSL pwsh) report stdin as NOT redirected → TTY → interactive prompt (FR-003)
- Edge case: VS Code integrated terminal — reports TTY correctly; verified during F-019 validation runs

### Why not alternatives

- `Test-Path '/dev/tty'` — Linux-only; doesn't work on Windows
- `$Host.UI.RawUI.KeyAvailable` — host-specific behavior; differs between pwsh versions
- Custom env-var sniffing — fragile; some CI systems set unexpected vars

---

## Task 2: Category A inventory (FR-008, FR-009, FR-010, FR-011)

**Decision**: Adopt Proposal 024 Abstraction Surface Inventory Category A list verbatim. F-043 migrates exactly these files; leaves Category B files at host-native paths.

### Category A files (Specrew-owned templates currently under `.squad/`)

Per Proposal 024 coupling audit:

- `extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md` (the persisted coordinator instructions block)
- `extensions/specrew-speckit/squad-templates/agents/{planner,implementer,reviewer,spec-steward,retro-facilitator}/charter.md` (5 files)
- `extensions/specrew-speckit/squad-templates/ceremonies/{planning,review-demo,retro}.md` (3 files)
- `extensions/specrew-speckit/squad-templates/directives/{spec-authority,traceability,drift-reporting}.md` (3 files)
- `extensions/specrew-speckit/squad-templates/skills/{capacity-planning,drift-check,traceability-check,iteration-resume}.md` (4 files)
- `extensions/specrew-speckit/squad-templates/skills/specrew-{where,status,team,review,help,version,update}/SKILL.md` (7 files)
- `templates/squad/agents/{worf,troi,picard,laforge,data,scribe,spec-steward}/history.md` (7 files)
- `templates/squad/identity/now.md`
- `templates/github/agents/squad.agent.md` (Squad CLI coordinator template — installs the entire Squad coordinator persona)

Total: ~32 files migrating from `.squad/` to `.specrew/coordinator/` (or appropriate subdirs).

### Category B files (Squad-runtime state; STAY at host-native paths)

- `.squad/identity/now.md` (runtime current-state)
- `.squad/identity/wisdom.md` (runtime lessons)
- `.squad/decisions.md` (runtime ledger)
- `.squad/team.md` (runtime team roster)
- `.squad/config.json` (runtime config including agentModelOverrides)
- `.squad/agents/<role>/charter.md` (runtime per-role deployed charter)

Per Proposal 104 Decision Matrix row 5: these are per-host runtime state; the host expects them at these paths. Migrating them would break Squad/Copilot. F-043 explicitly DOES NOT migrate these.

---

## Task 3: Brownfield migration mechanics with customization preservation (FR-009)

**Decision**: Three-phase migration: (1) detect existing `.squad/coordinator/` content; (2) diff against shipped template to detect user customizations; (3) move content to `.specrew/coordinator/` preserving customizations; leave breadcrumb file at old location.

### Detection algorithm

```text
For each Category A file at .squad/coordinator/<path>:
  1. Compute SHA256 of current file
  2. Compute SHA256 of shipped template version (from templates/ directory)
  3. If SHA256 matches: no customization; safe to delete old location after migration
  4. If SHA256 differs: user has customized; copy to .specrew/coordinator/<path>
     AND keep .squad/coordinator/<path> with a breadcrumb suffix (.squad/coordinator/<path>.user-customized.md)
  5. Always write the shipped template to .specrew/coordinator/<path> (with merged customizations if detected via diff)
```

### Breadcrumb format

```text
.squad/coordinator/specrew-governance.md.deprecated
---
# This file has moved.
# Specrew coordinator governance now lives at .specrew/coordinator/specrew-governance.md
# This breadcrumb will be removed in the next specrew update cycle.
#
# If you had customized .squad/coordinator/specrew-governance.md before this migration,
# your customizations have been preserved at .squad/coordinator/specrew-governance.md.user-customized.md
# Please review and merge into .specrew/coordinator/specrew-governance.md manually before deletion.
---
```

### Why git diff for customization detection

- F-019 already detects customizations via SHA256 comparison during update flows
- Git diff is the canonical "what did the user change" surface
- Customized content preservation is critical — silent overwrite would destroy downstream work
- The `.user-customized.md` suffix preserves the user's edits in a clearly-marked file

---

## Task 4: host-history.yml schema (FR-001)

**Decision**: Schema v1 keyed by `host_kind`. Per Proposal 104 spec.

```yaml
host_history:
  schema_version: 1
  last_selected_host: claude
  hosts:
    copilot:
      first_used_at: 2026-04-22T00:00:00Z
      last_used_at: 2026-05-22T18:30:00Z
      crew_runtime_installed: true
      crew_runtime_path: .squad/
    claude:
      first_used_at: 2026-05-23T08:00:00Z
      last_used_at: 2026-05-23T14:15:00Z
      crew_runtime_installed: true
      crew_runtime_path: .claude/agents/
    codex:
      first_used_at: null
      last_used_at: null
      crew_runtime_installed: false
      crew_runtime_path: null
    antigravity:
      first_used_at: null
      last_used_at: null
      crew_runtime_installed: false
      crew_runtime_path: null
```

### Why YAML (not JSON)

- Spec Kit + Specrew config files use YAML throughout (`.specrew/config.yml`, `extensions/*/extension.yml`)
- Consistency reduces parser surface (one YAML lib in PowerShell, not YAML+JSON)
- Human-editable for debugging

### Schema versioning per Proposal 059

`schema_version: 1` is the v1 baseline. Future migrations follow Proposal 059 Legacy-State Read-Tolerance pattern: readers tolerate v1 schemas through v2+ migrations; writers always emit current version.

### Corruption recovery

Reader pseudocode:

```powershell
function Get-SpecrewHostHistory {
    param([string]$ProjectPath)
    $path = Join-Path $ProjectPath '.specrew\host-history.yml'
    if (-not (Test-Path -LiteralPath $path)) { return $null }
    try {
        $content = Get-Content -LiteralPath $path -Raw | ConvertFrom-Yaml -ErrorAction Stop
        if (-not (Test-SpecrewHostHistorySchema $content)) {
            Write-Warning "host-history.yml schema invalid; regenerating from probe"
            return $null
        }
        return $content
    }
    catch {
        Write-Warning "host-history.yml corrupted; regenerating from probe"
        return $null
    }
}
```

Returning `$null` on corruption triggers a fresh first-run probe — degrading gracefully without crashing.

---

## Cross-references

- file:///C:/Dev/Specrew/proposals/104-multi-host-onboarding-and-selection-flow.md (source proposal with 6-question decision matrix)
- file:///C:/Dev/Specrew/proposals/024-multi-host-runtime-abstraction.md (Abstraction Surface Inventory — Categories A/B/C/D taxonomy)
- file:///C:/Dev/Specrew/proposals/069-multi-host-launch-path.md (F-040 — provides host enum + selected_host + available_hosts + crew_runtime_status)
- file:///C:/Dev/Specrew/proposals/059-legacy-state-read-tolerance.md (schema-versioning + brownfield-migration pattern)
- file:///C:/Dev/Specrew/specs/040-multi-host-launch-path/research.md (F-040 per-host CLI surfaces + cross-platform launch parity)
- Memory: `[[project-design-session-2026-05-22]]` — multi-host research wave producing Proposal 104
