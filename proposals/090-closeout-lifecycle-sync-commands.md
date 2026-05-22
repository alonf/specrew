---
proposal: 090
title: Closeout Lifecycle Sync Commands (Structural Fix for Crew-Bypass Bug Class)
status: shipped
shipped-as: feature-032
shipped-in: v0.24.3
phase: phase-2
estimated-sp: 5-8
actual-sp: 6.5
discussion: tbd
---

# Closeout Lifecycle Sync Commands (Structural Fix for Crew-Bypass Bug Class)

## Why

Specrew's `extensions/specrew-speckit/extension.yml` declares 4 sync commands plus 3 Spec Kit hooks that cover the **early** lifecycle phases:

| Lifecycle phase | Sync command | Auto-fires via hook? |
|---|---|---|
| `specify` | `sync-specify` | No (Crew-invoked) |
| `clarify` | `sync-clarify` | No (Crew-invoked) |
| `plan` | `sync-plan` | No (Crew-invoked); `before_plan` hook fires for validation |
| `tasks` | `sync-tasks` | No (Crew-invoked); `after_tasks` hook fires for validation |

The **closeout half of the lifecycle has zero automated coverage**:

| Lifecycle phase | Sync command | Auto-fires via hook? |
|---|---|---|
| `review-signoff` | ❌ none | ❌ no hook |
| `retro` | ❌ none | ❌ no hook |
| `iteration-closeout` | ❌ none | ❌ no hook |
| `feature-closeout` | ❌ none | ❌ no hook |

The Crew must manually invoke `pwsh -File .specify/extensions/specrew-speckit/scripts/sync-boundary-state.ps1 -BoundaryType <enum> ...` with the correct enum string for each closeout phase. When the Crew fails (skips, uses a non-canonical string, or edits state files directly), state drifts silently.

### Empirical evidence — three manifestations in 24 hours

The 2026-05-22 Feature 030 / Proposal 083 lifecycle exposed all three failure modes:

| Manifestation | What broke | Detection |
|---|---|---|
| **`.specify/feature.json` not cleared at feature-closeout** | Crew manually edited 3 of 4 state files; skipped `Clear-SpecrewActiveFeature` (which only fires inside the canonical sync) | GitHub Copilot PR review on PR #462 |
| **`session_state_active: true` after feature-closeout** | Crew bypassed sync; `active = if ($BoundaryType -eq 'feature-closeout') { 'false' } else { 'true' }` (line 253) never fired | Maintainer ran `specrew start`; saw "not clean" detection |
| **`session_state_boundary: feature-closed`** (non-canonical) | Crew invented the string `feature-closed` — grep across all Specrew code returns zero matches; canonical string is `feature-closeout` | Same `specrew start` recovery-mode detection |

The same Crew session also wrote `iteration-closed` (non-canonical) in `iterations/001/state.md` instead of `iteration-closeout`. Four distinct manifestations of the same root cause.

The F-029 baseline-hygiene fix (which added `active=false` to the canonical sync) is **correct but unreachable** — it only fires when the canonical sync is called, which the Crew didn't do for any closeout phase.

### Strategic motivation

Without a structural fix:

- The Crew-bypass bug will recur on every closeout phase of every future feature
- Each recurrence costs ~10-30 min of catch-and-fix wall-clock (cumulative across feature transitions, this adds up to hours per week)
- `specrew start`'s state-detection logic gets noisier (recovery-mode false positives)
- Maintainer trust in the lifecycle erodes

A structural fix — making canonical sync **the only easy path** for closeout phases — eliminates the bug class instead of detecting symptoms.

### User direction (2026-05-22)

> "Isn't this script run on hook? ... I am going to sleep. Draft proposal 90 and implement it, follow Specrew process and make sure all files are there."

The user's question pinpointed the architectural gap before drafting. This proposal closes it.

## What (4 Pillars)

### Pillar 1 — 4 new sync commands

Mirror the existing `sync-specify`/`sync-clarify`/`sync-plan`/`sync-tasks` shape for the four closeout phases. Each new command lives at:

`extensions/specrew-speckit/commands/speckit.specrew-speckit.sync-<phase>.md`

(plus the mirror at `.specify/extensions/specrew-speckit/...`)

Commands to create:

1. **`sync-review-signoff`** — invoked after the Crew commits review-boundary artifacts (review.md, drift-log.md, state.md updates). Wraps `Invoke-SpecrewBoundaryStateSync -BoundaryType review-signoff` with the correct enum value baked in.

2. **`sync-retro`** — invoked after retro.md is committed. Wraps `Invoke-SpecrewBoundaryStateSync -BoundaryType retro`. NOTE: per ValidateSet on `sync-boundary-state.ps1:188`, the canonical enum doesn't currently include `retro` as a distinct boundary — closure happens at `iteration-closeout`. This proposal proposes ADDING `retro` to the ValidateSet so retro has a first-class sync slot. (Alternative: route retro through the existing iteration-closeout sync; less explicit. Choose the explicit path.)

3. **`sync-iteration-closeout`** — invoked after closeout-dashboard.md is committed. Wraps `Invoke-SpecrewBoundaryStateSync -BoundaryType iteration-closeout`.

4. **`sync-feature-closeout`** — invoked after INDEX update + state-file feature-closure commits. Wraps `Invoke-SpecrewBoundaryStateSync -BoundaryType feature-closeout`. This is the command that triggers `Clear-SpecrewActiveFeature` + `active=false` per existing line 253/781 logic. **THIS IS THE COMMAND THAT BLOCKS THE BUG CLASS.**

Each command file follows the existing template (`sync-tasks.md`):

````markdown
---
description: "Persist session-state metadata after feature-closeout"
---

# Sync Feature-Closeout Boundary State

After feature-closeout artifacts are committed, run:

```powershell
$featureJson = Get-Content -LiteralPath .\.specify\feature.json -Raw -Encoding UTF8 | ConvertFrom-Json
$featureRef = Split-Path -Leaf $featureJson.feature_directory
$iterationsRoot = Join-Path $featureJson.feature_directory 'iterations'
$iterationNumber = if (Test-Path -LiteralPath $iterationsRoot -PathType Container) {
    @(Get-ChildItem -LiteralPath $iterationsRoot -Directory | Sort-Object Name -Descending | Select-Object -First 1)[0].Name
}
pwsh -File .\.specify\extensions\specrew-speckit\scripts\sync-boundary-state.ps1 -ProjectPath . -BoundaryType feature-closeout -FeatureRef $featureRef -IterationNumber $iterationNumber
```

If the sync fails, stop and report the exact file-write error before continuing.
````

### Pillar 2 — Extend `extension.yml` provides list

Update `extensions/specrew-speckit/extension.yml` (and mirror) to declare the 4 new commands:

```yaml
provides:
  commands:
    # ... existing 7 commands ...
    - name: speckit.specrew-speckit.sync-review-signoff
      file: commands/speckit.specrew-speckit.sync-review-signoff.md
      description: "Persist session-state metadata after review-signoff"
    - name: speckit.specrew-speckit.sync-retro
      file: commands/speckit.specrew-speckit.sync-retro.md
      description: "Persist session-state metadata after retro"
    - name: speckit.specrew-speckit.sync-iteration-closeout
      file: commands/speckit.specrew-speckit.sync-iteration-closeout.md
      description: "Persist session-state metadata after iteration-closeout"
    - name: speckit.specrew-speckit.sync-feature-closeout
      file: commands/speckit.specrew-speckit.sync-feature-closeout.md
      description: "Persist session-state metadata after feature-closeout"
```

No new HOOKS — Spec Kit's hook system fires on `/speckit.*` lifecycle commands (`/speckit.plan`, `/speckit.tasks`, `/speckit.implement`). The closeout phases don't have `/speckit.*` commands in upstream Spec Kit, so we can't add hooks at the Spec Kit level. The sync commands are explicit slash-command targets the Crew (or maintainer) invokes via `/speckit-specrew-speckit-sync-<phase>` (per Spec Kit's command discovery).

### Pillar 3 — Add `retro` to the canonical boundary ValidateSet

Per `scripts/internal/sync-boundary-state.ps1` line 188:

```powershell
return @('specify', 'clarify', 'plan', 'tasks', 'review-signoff', 'iteration-closeout', 'feature-closeout')
```

There's no `retro` boundary today. Retro state is implicitly tracked between review-signoff and iteration-closeout. To give the new `sync-retro` command a target, ADD `retro` to the ValidateSet at:

- Line 188 (in `Get-CanonicalBoundaryTypes` / similar)
- Line 222 (parameter ValidateSet on `Invoke-SpecrewBoundaryStateSync`)
- Line 253 (the `active = if ...` ternary — set `active = 'true'` for retro since the iteration is still active)
- Line 670 (parameter ValidateSet on the public entry function)

This is a small additive change; doesn't break existing code paths.

### Pillar 4 — Validator rule: canonical boundary + active/boundary consistency

A new validator rule in `extensions/specrew-speckit/scripts/validate-governance.ps1` (and mirror) catches the bug class even if the Crew tries to bypass:

**Rule: `Test-SessionStateBoundaryCanonical`** — runs against `.specrew/start-context.json`, `.specrew/last-start-prompt.md`, `.squad/identity/now.md`, and `specs/<feature>/iterations/<NNN>/state.md`. Two assertions:

1. **Canonical-string assertion**: every `session_state_boundary` value (and the iteration's `Current Phase` field) MUST be in the canonical set `{specify, clarify, plan, tasks, review-signoff, retro, iteration-closeout, feature-closeout}`. Strings like `feature-closed`/`iteration-closed` hard-fail.

2. **Active/boundary consistency assertion**: `session_state_active: true` combined with `session_state_boundary` in `{iteration-closeout, feature-closeout}` is logically inconsistent (closure boundaries imply terminal/inactive state) — hard-fail with directive to invoke the canonical `sync-iteration-closeout` or `sync-feature-closeout` command.

Both rules use existing validator patterns (auto-scoped via Proposal 083; composes with Proposal 086 Pillar 1 memoization when that ships).

## How (implementation plan)

This is a feature-shaped slice — bigger than a small-fix slice because it touches the extension manifest + 4 new commands + sync-script ValidateSet + new validator rule + mirror parity + tests + charter updates.

| Step | File | Effort |
|---|---|---|
| Create 4 new sync command .md files | `extensions/specrew-speckit/commands/speckit.specrew-speckit.sync-{review-signoff,retro,iteration-closeout,feature-closeout}.md` (+ mirror) | 1 SP |
| Update `extension.yml` `provides.commands` list | `extensions/specrew-speckit/extension.yml` (+ mirror) | 0.25 SP |
| Add `retro` to ValidateSet in `sync-boundary-state.ps1` (4 sites: line 188, 222, 253, 670) | `scripts/internal/sync-boundary-state.ps1` | 0.5 SP |
| Add `Test-SessionStateBoundaryCanonical` validator rule | `extensions/specrew-speckit/scripts/validate-governance.ps1` (+ mirror) + helper in `shared-governance.ps1` (+ mirror) | 1.5 SP |
| Update charter prose (Implementer, Spec Steward, Reviewer, Retro Facilitator) to instruct Crew to use the new sync commands instead of inline PowerShell or manual state-file edits | `extensions/specrew-speckit/squad-templates/agents/<role>/charter.md` (+ mirror) — 4 files × 2 mirrors = 8 files | 0.5 SP |
| Update coordinator governance rule 5 (gate phase transitions) to document the new commands | `extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md` (+ mirror) | 0.25 SP |
| Tests: integration test for each of 4 new commands (verify they invoke sync correctly + state files end up in canonical state); integration test for validator rule (catches non-canonical strings + active/boundary contradiction) | `tests/integration/closeout-lifecycle-sync-commands.tests.ps1` (new) + `tests/integration/session-state-boundary-canonical.tests.ps1` (new) | 1.5 SP |
| Mirror parity sweep | both mirrors | 0.25 SP |
| CHANGELOG entry + INDEX update (move 090 to Shipped) | docs | 0.25 SP |

**Total: ~6-8 SP.** Small feature.

**Ship target**: v0.24.3 release (the post-v0.24.2 process-optimization bundle). Slots FIRST in the bundle (highest priority — fixes a bleeding root cause).

## Composition with other proposals

| Proposal | Relationship |
|---|---|
| **Proposal 032** (Specrew Slash-Command Surface, shipped) | This proposal extends Spec Kit's slash-command surface with 4 new sync commands. Same infrastructure. |
| **Proposal 082 Tier 2** (validator rule for `boundary-wip-uncommitted`) | Sibling validator rule. Both detect "Crew didn't run the canonical mechanism." Bundle naturally with Tier 2 if shipped together. |
| **Proposal 083** (Local Validator Auto-Scope, shipped) | This proposal's validator rule benefits from 083's auto-scope — only checks state files in the diff. |
| **Proposal 086 Pillar 1** (Memoization, queued) | The new validator rule is cacheable per 086 P1 once that ships. |
| **Proposal 088** (Markdown Lint Pre-Boundary Auto-Fix, queued) | Same gate-at-boundary architectural pattern. Both shipped together would form a "boundary integrity bundle". |
| **Proposal 089** (PR Review Integration, queued) | Same composition. |
| **Proposal 030** (Quality Hardening Bundle, draft) | Could absorb this proposal if shipped together later. Standalone ship is cleaner. |

## Acceptance signals

- **AC1**: 4 new command files exist at canonical paths in both `extensions/specrew-speckit/commands/` and `.specify/extensions/specrew-speckit/commands/`. SHA256 mirror parity verified.
- **AC2**: `extension.yml` lists all 4 new commands in `provides.commands`. Verified by yaml parse + content check.
- **AC3**: `sync-boundary-state.ps1` ValidateSet at lines 188, 222, 253, 670 includes `retro`. Verified by content check + integration test running `Invoke-SpecrewBoundaryStateSync -BoundaryType retro ...` succeeds.
- **AC4**: `Test-SessionStateBoundaryCanonical` validator rule rejects `feature-closed`, `iteration-closed`, `review-signed`, or any other non-canonical string in any session_state_boundary field. Verified by integration test.
- **AC5**: `Test-SessionStateBoundaryCanonical` rejects `session_state_active: true` combined with `session_state_boundary in {iteration-closeout, feature-closeout}`. Verified by integration test.
- **AC6**: Charter updates present and reference the new sync commands by name. Verified by methodology-surface verification test (grep pattern, similar to Proposal 082 Tier 1's verification approach).
- **AC7**: Running the canonical sync via each new sync command produces correct state files (active=false for feature-closeout; feature.json cleared; canonical boundary string). Verified by integration test.
- **AC8**: Mirror parity across `extensions/specrew-speckit/` + `.specify/extensions/specrew-speckit/` for all touched files.

## Out of scope

- **Auto-invocation of sync at lifecycle boundaries** (e.g., a daemon that fires sync when state.md changes). Spec Kit's hook system doesn't support this for closeout phases. Future enhancement could be a file-system watcher or git pre-commit hook; out of scope here.
- **Migration of existing repos with `feature-closed`/`iteration-closed` strings**: this proposal's validator rule will flag legacy strings; a one-time migration chore can fix them in-place. Out of scope; migration ships as a separate chore.
- **Slash-command auto-completion / discoverability UX**: out of scope; relies on Spec Kit's existing slash-command discovery surface.
- **Removing the old inline-PowerShell invocation pattern from charters entirely**: out of scope; the inline pattern is preserved as a fallback for environments where slash commands aren't available, but charters direct the Crew toward the new sync commands by default.
- **Cross-host adaptation**: Spec Kit slash commands work on all Spec Kit hosts (Copilot, Claude Code, Codex). Multi-host work in Proposal 024 is unchanged.

## Cross-references

- **User direction (2026-05-22)**: "Isn't this script run on hook? ... Draft proposal 90 and implement it, follow Specrew process and make sure all files are there."
- **Empirical evidence**: 4 manifestations on F-030/083 (feature.json not cleared + active stayed true + `feature-closed` + `iteration-closed`), detailed in commits `28f938f`, `48b49df`, `7c92146`
- [Proposal 032](032-specrew-slash-commands.md) — shipped: slash-command surface this proposal extends
- [Proposal 082](082-boundary-commit-and-upstream-push-discipline.md) — Tier 1 shipped; Tier 2 sibling validator-rule slot
- [Proposal 083](083-local-validator-speedup.md) — shipped: this proposal's validator rule reuses auto-scope
- [Proposal 086](086-validation-pipeline-performance-bundle.md) — queued: Pillar 1 memoization composes with this rule
- [Proposal 088](088-markdown-lint-pre-boundary-auto-fix-discipline.md) — queued: same architectural pattern
- [Proposal 089](089-pr-review-integration-address-pr-review-gate.md) — queued: same composition
- INDEX: file:///C:/Dev/Specrew/proposals/INDEX.md
