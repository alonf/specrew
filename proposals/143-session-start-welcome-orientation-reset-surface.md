---
proposal: 143
title: Session Start Welcome Orientation + Reset Surface (Transparency + Recovery)
status: draft
phase: phase-2
estimated-sp: 15-25
priority-tier: 1
type: tooling
discussion: surfaced 2026-05-29 during F-049 v0.28.0 dogfooding (TelegramFeed downstream-project trial). Maintainer empirically observed Squad Coordinator on Copilot asked "What do you want to build?" with ZERO orientation — no Specrew version, no host indication, no project state, no Crew Interaction Profile acknowledgment. Maintainer-stated directive: "we must provide a message at the beginning, for example, it even doesn't say the Specrew version. It has to tell the user about what it knows before starting. Also there should be a way to reset these parameters." Bulletproof requirement explicit.
composes-with:
  - 015  # Expertise-aware adaptive intake — orientation references the user-profile content this composes around
  - 133  # Specrew Primer (persistent host instructions) — primer + orientation are dual surfaces
  - 140  # Reviewer Instruction Surface — orientation pattern composes with playbook surface
  - 141  # Crew Interaction Profile / Persona Lens Separation — orientation surfaces this
  - 047  # Project Governance Profile — orientation surfaces resolved profile
audience: tooling
---

# Session Start Welcome Orientation + Reset Surface (Transparency + Recovery)

## Why

Empirical motivation (2026-05-29 F-049 v0.28.0 dogfooding):

The maintainer started Specrew in a fresh TelegramFeed downstream project to dogfood F-049's Crew Interaction Profile (Proposal 141) + persona-driven intake. Squad Coordinator on Copilot loaded `.specrew/start-context.json` (which correctly contains the full `user_profile` section per FR-038 — verified empirically) and proceeded directly to asking "What do you want to build?" with ZERO orientation:

- No Specrew version mentioned
- No host indication
- No project state acknowledgment (greenfield / brownfield / existing-continue)
- No Crew Interaction Profile dial summary
- No "I see your existing profile loaded" message
- No path to reset stale profile / configuration

Maintainer's explicit directive: **"we must provide a message at the beginning, for example, it even doesn't say the Specrew version. It has to tell the user about what it knows before starting. Also there should be a way to reset these parameters."**

This is bigger than the FR-038 in-situ visibility gap noted in F-049 iter-5 retro. It's a **systemic transparency + recovery gap** at session start. Users cannot trust a system whose state they cannot inspect, and they cannot recover from bad state they cannot reset.

### What's missing today

| Surface | Should be visible at session start | Currently |
|---|---|---|
| Specrew module version | Yes — "what code is driving this?" | NOT surfaced |
| Active host + capability summary | Yes — "what's the runtime?" | NOT surfaced |
| Project state classification | Yes — "what does this repo look like to Specrew?" | Mentioned in start-context.json but not in coordinator output |
| Crew Interaction Profile (user_profile) | Yes — "what does Specrew know about ME?" | In start-context.json (FR-038 ✓) but coordinator doesn't surface it visibly |
| Last authorized boundary + lifecycle position | Yes — "where am I in the flow?" | In start-context.json but not surfaced |
| Active configuration (capacity, profile, governance) | Yes — "what rules apply?" | NOT surfaced |
| Reset paths | Yes — "how do I undo bad state?" | Not discoverable; no CLI surface |

### What's missing for reset specifically

Today users must:

- Delete `~/.specrew/user-profile.yml` manually + re-run specrew start to trigger first-run prompts
- Delete `.specrew/`, `.specify/`, `.squad/` directories manually for project state reset
- Edit individual fields in `.specrew/start-context.json` for partial state reset
- No CLI command surface (`specrew reset --user-profile` doesn't exist)
- No documented "how to reset X" recipe in user-facing docs
- No `/specrew-reset` skill for in-Crew invocation
- No confirmation prompts (manual `rm` is irreversible)
- No reset audit trail

### Composition with empirical session-start gaps

This proposal addresses gaps surfaced in:

- F-049 iter-5 retro action #2 (FR-038 in-situ exercise): producer works, coordinator doesn't surface
- F-050 iter-1 multi-cycle iteration-closeout (3 decline cycles): partly because stale state files weren't visible to anyone — maintainer didn't know now.md/start-context.json/last-start-prompt.md were stale until cross-reviewer caught it. A welcome-orientation surface would have shown the actual session state earlier
- Cross-reviewer empirical bundle (memory `[[cross-reviewer-3rd-empirical-instance-2026-05-28]]`): 5 of 13 instances were state-truth integrity gaps that became visible only when cross-reviewer read state artifacts. Welcome orientation makes them visible at session start, not at iteration-closeout cross-review

## What — 3 Pillars

### Pillar 1: Welcome Orientation Surface (~6-10 SP)

A structured welcome message the coordinator emits at session start, BEFORE asking the first intake question (greenfield) OR confirming resume (existing-continue).

**Required content** (always present):

```text
╭──────────────────────────────────────────────────────────────────╮
│  Specrew Welcome Orientation                                      │
├──────────────────────────────────────────────────────────────────┤
│  Module version:    <version> [PSGallery: <installed-version>]    │
│  Active host:       <host-kind> (<binary-name>)                   │
│  Project state:     <greenfield-new | existing-continue | recovery>│
│  Project root:      <path>                                        │
│  Lifecycle position:                                              │
│    Last authorized: <boundary> (<feature>/<iteration>)            │
│    Pending next:    <boundary | none>                             │
│                                                                  │
│  Crew Interaction Profile (current user):                         │
│    Product Strategy:        <dial> (<calibration-label>)          │
│    UX/UI Design:            <dial> (<calibration-label>)          │
│    Software Architecture:   <dial> (<calibration-label>)          │
│    AI Delivery Planning:    <dial> (<calibration-label>)          │
│    Preferred intake depth:  <auto | shallow | normal | deep>      │
│                                                                  │
│  Reset paths:                                                     │
│    /specrew-reset            (in-Crew skill — see help)           │
│    specrew reset --help      (CLI reference)                      │
│                                                                  │
│  Specrew governance: enabled                                      │
╰──────────────────────────────────────────────────────────────────╯
```

(ASCII art is illustrative; actual rendering should be plain-text-compatible for monochrome terminals. Rich rendering available where the host supports it.)

**Behavior per project state**:

| Project state | Coordinator action after orientation |
|---|---|
| greenfield-new | "What do you want to build?" intake question |
| existing-continue with pending boundary | "Resume at `<boundary>` for `<feature>/<iteration>`? [yes / no — fresh intake / show details]" |
| recovery (stale state detected) | "Stale-state recovery menu (A/B/C)" with explicit explanation of what's stale |

**Calibration labels** for dial settings (per Pillar 2 of Proposal 141):
- 1-3 or `auto`: "needs guidance"
- 4-7: "balanced"
- 8-10: "expert-level"

**Surface coverage** (per FR scope below):

- Coordinator (specrew-governance.md) — primary surface
- Spec Steward charter — surface profile awareness before first intake question
- Planner, Implementer, Reviewer, Retro Facilitator charters — surface profile awareness in their domain-specific prompts
- `/specrew-where` skill — extends to show the same orientation on demand
- `specrew start` CLI output — emits to stdout before invoking the host

### Pillar 2: Reset Surface (~6-10 SP)

CLI command surface + Crew skill + documented recipes.

**CLI command** (new `specrew reset` subcommand):

```text
specrew reset --user-profile             # Delete ~/.specrew/user-profile.yml
specrew reset --user-profile-area <area> # Reset one dial to auto/null
specrew reset --project-state            # Clean .specrew/start-context.json + last-start-prompt.md + now.md
specrew reset --boundary-history         # Clear .specrew/start-context.json verdict_history (preserve session_state)
specrew reset --skills                   # Re-deploy skill catalog from current module version
specrew reset --all                      # Full reset: user-profile + project-state + skills (DOES NOT touch specs/, .squad/decisions.md, git history)
specrew reset --help                     # List all reset options + what each touches
specrew reset --dry-run <flag>           # Show what would be removed/reset WITHOUT doing it
```

**Confirmation prompts for destructive resets**:

```text
specrew reset --all
  → "This will reset:
       - ~/.specrew/user-profile.yml (current-user dials)
       - .specrew/start-context.json + last-start-prompt.md + start-summary.md
       - .squad/identity/now.md
       - .claude/skills/, .github/skills/, .agents/skills/ (re-deployed from module)
     This DOES NOT touch:
       - specs/<feature>/ directories (your feature work)
       - .squad/decisions.md (audit log)
       - git history
     Proceed? [y/N]"
```

**Reset audit trail**:

Every reset (except `--dry-run`) records an entry in `.squad/decisions.md`:

```text
### 2026-05-29T12:34:56Z — Reset operation

- **Reset scope**: `--user-profile`
- **Invoked by**: <user>
- **Artifacts touched**: ~/.specrew/user-profile.yml (deleted)
- **Rationale**: (free-text from `--reason "..."` flag, optional)
```

**In-Crew skill** (`/specrew-reset`):

Same operations exposed as a Specrew skill so users can invoke reset from within an active Crew session without exiting. Per F-049 iter-3 skill-deployment pattern, deployed to all hosts (`.claude/skills/`, `.github/skills/`, `.agents/skills/`, future `.cursor/rules/`).

### Pillar 3: Discoverability (~3-5 SP)

- **`specrew help`** root command lists `welcome` and `reset` as discoverable verbs
- **`specrew help reset`** shows reset subcommands with explanations
- **Welcome orientation** mentions reset paths in its content (Pillar 1 already does this)
- **README.md + docs/user-guide.md** sections for "What Specrew knows about you" + "Resetting Specrew state"
- **Skill help** (`/specrew-reset --help` or equivalent host-specific) lists in-Crew reset options
- **`specrew-help` skill** (if it exists) extended with reset awareness

### Functional Requirements

- **FR-001**: Coordinator MUST emit a structured Welcome Orientation message at session start BEFORE asking the first intake question (greenfield) OR confirming resume (existing-continue)
- **FR-002**: Welcome Orientation MUST include: Specrew module version, active host, project state, project root, lifecycle position (last authorized + pending next boundary), Crew Interaction Profile dial summary with calibration labels, reset path hints
- **FR-003**: Per project state, coordinator MUST adapt the post-orientation action (intake question / resume confirmation / recovery menu)
- **FR-004**: Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator charters MUST reference the `user_profile` section from `.specrew/start-context.json` and adapt their domain-specific behavior to the relevant dial setting per Proposal 141 calibration rules
- **FR-005**: New CLI subcommand `specrew reset` MUST support `--user-profile`, `--user-profile-area <area>`, `--project-state`, `--boundary-history`, `--skills`, `--all`, `--help`, `--dry-run`
- **FR-006**: Destructive resets (`--user-profile`, `--project-state`, `--all`) MUST prompt for confirmation unless `--force` flag is set
- **FR-007**: Every non-dry-run reset MUST record an audit entry in `.squad/decisions.md` with timestamp, scope, artifacts touched, and optional rationale
- **FR-008**: Reset operations MUST NEVER touch `specs/<feature>/` directories OR `.squad/decisions.md` OR git history (those are protected per audit-trail discipline)
- **FR-009**: In-Crew skill `/specrew-reset` MUST be deployed to all skill-host roots and offer the same reset operations as the CLI
- **FR-010**: `specrew help reset` MUST list all reset subcommands with explanations of what each touches
- **FR-011**: `specrew-where` skill MUST be extended to show the same Welcome Orientation content on demand
- **FR-012**: Welcome Orientation MUST be cross-platform (Windows PowerShell, Linux pwsh, macOS pwsh — no platform-specific terminal escape sequences in plain-text mode)
- **FR-013**: Rich rendering mode (Unicode box-drawing) MUST gracefully degrade to ASCII-safe rendering when host capability or `--ascii` flag is detected (mirrors existing dashboard rendering pattern)
- **FR-014**: Reset audit entries MUST be parseable by `.squad/decisions.md` validator (existing canonical decision-entry schema)
- **FR-015**: Welcome Orientation MUST be FAST (<200ms perceived latency) — no remote calls, no expensive state recomputation; read from already-generated `.specrew/start-context.json`
- **FR-016**: All charter updates MUST mirror to `.specify/extensions/specrew-speckit/squad-templates/` (mirror parity per F-047 FR-014)

### Success Criteria

- **SC-001**: 100% of `specrew start` invocations emit Welcome Orientation BEFORE the first intake question OR resume confirmation OR recovery menu
- **SC-002**: 100% of Welcome Orientation outputs include the 7 required fields (version, host, project state, root, lifecycle position, Crew Interaction Profile, reset paths)
- **SC-003**: 100% of agent charters (Spec Steward + Planner + Implementer + Reviewer + Retro Facilitator + Coordinator governance) reference `user_profile` from `.specrew/start-context.json`
- **SC-004**: All 6 reset subcommands (--user-profile, --user-profile-area, --project-state, --boundary-history, --skills, --all) verified positive + negative paths in integration tests
- **SC-005**: Dry-run mode verified for all destructive subcommands (shows expected actions without performing them)
- **SC-006**: Reset audit trail verified — every non-dry-run reset produces a decisions.md entry parseable by existing schema
- **SC-007**: Cross-platform rendering verified on Windows / Linux / macOS terminals (rich + ASCII modes)
- **SC-008**: Welcome Orientation latency <200ms verified on cold start with existing user-profile + project state
- **SC-009**: Empirical maintainer verification: after this proposal ships, restart `specrew start` in a project with existing profile + lifecycle state → maintainer sees the orientation surface with correct values BEFORE any question — the gap empirically documented 2026-05-29 is closed

## How — Implementation Effort

### Iteration 1: Welcome Orientation Surface (~6-10 SP)

| Component | File | Effort |
|---|---|---|
| Welcome Orientation renderer | `scripts/internal/welcome-orientation.ps1` (new) | 2-3 SP |
| Coordinator governance update | `extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md` + mirror | 0.5-1 SP |
| Spec Steward charter update | `extensions/specrew-speckit/squad-templates/agents/spec-steward/charter.md` + mirror | 0.5-1 SP |
| Planner / Implementer / Retro Facilitator charter updates | charters under `extensions/specrew-speckit/squad-templates/agents/` + mirrors | 1.5-2 SP |
| Reviewer charter update (or extend existing per iter-5 T009) | `extensions/specrew-speckit/squad-templates/agents/reviewer/charter.md` + mirror | 0.5 SP |
| `specrew-where` skill extension to show same orientation | `extensions/specrew-speckit/squad-templates/skills/where.md` + per-host skill deploys | 1-2 SP |
| Unit + integration tests | `tests/integration/welcome-orientation.tests.ps1` | 1-2 SP |

### Iteration 2: Reset Surface (~6-10 SP)

| Component | File | Effort |
|---|---|---|
| `specrew reset` CLI command implementation | `scripts/specrew-reset.ps1` (new) + module export | 3-4 SP |
| Reset subcommand handlers (user-profile, project-state, boundary-history, skills, all) | `scripts/internal/reset/*.ps1` (new directory) | 2-3 SP |
| Audit-log writer integration | `scripts/internal/reset/write-audit.ps1` | 0.5 SP |
| In-Crew skill `/specrew-reset` content + deploy targets | `extensions/specrew-speckit/squad-templates/skills/specrew-reset/SKILL.md` + per-host deploys | 1-2 SP |
| Integration tests for all 6 subcommands + dry-run + confirmation prompts | `tests/integration/reset-surface.tests.ps1` | 2-3 SP |

### Iteration 3: Discoverability + Docs + Cross-Platform Validation (~3-5 SP)

| Component | File | Effort |
|---|---|---|
| `specrew help reset` extension | `scripts/specrew-help.ps1` | 0.5 SP |
| `README.md` + `docs/user-guide.md` additions ("What Specrew knows about you" + "Resetting Specrew state") | 2 files | 1-1.5 SP |
| Skill-help integration (specrew-help skill extension) | `extensions/specrew-speckit/squad-templates/skills/specrew-help/SKILL.md` + deploys | 0.5 SP |
| Cross-platform validation (Linux + macOS rendering) | manual + CI integration | 1-2 SP |

**Total**: ~15-25 SP across 3 iterations.

## Composition

| Proposal | Relationship |
|---|---|
| **Proposal 015** (Expertise-aware adaptive intake) | DIRECT COMPOSER. Welcome Orientation surfaces the profile this composes around. |
| **Proposal 133** (Specrew Primer — Persistent Host Instructions) | DUAL SURFACES. Primer ships durable host instructions; Welcome Orientation ships per-session orientation. Composable: primer instructs hosts to load orientation at session start. |
| **Proposal 140** (Reviewer Instruction Surface) | METHODOLOGY KIN. Both ship per-session-context surfaces (playbook vs orientation). Orientation could reference reviewer-instructions presence in its output. |
| **Proposal 141** (Crew Interaction Profile / Persona Lens Separation) | DIRECT EXTENSION. Iter-5 shipped the profile + start-context.json producer (FR-038). This proposal closes the visibility loop by surfacing it. FR-038-in-situ gap from iter-5 retro is the EMPIRICAL motivation for this proposal. |
| **Proposal 047** (Project Governance Profile) | COMPOSES. Welcome Orientation surfaces resolved governance profile (per-project capacity, quality tier, etc.) when applicable. |
| **Proposal 028** (Proposal Metadata Schema) | COMPOSES. Proposal lifecycle surface (if shipped) could be referenced in orientation output. |
| **Proposal 092** (Specrew Dashboard Web App) | RELATED. Web dashboard shows the same session state; orientation surface is the CLI equivalent. |
| **Proposal 064 + 124** (Slash-Command Multi-Host + Multi-Host Catalog) | DEPLOYMENT MACHINERY. Reset skill + welcome orientation skill deploy through existing per-host pattern. |

## Risks

- **Welcome Orientation rendering noise**: too much content per session start becomes friction. Mitigation: FR-013 ASCII fallback; FR-015 latency cap; user can opt for `--quiet` orientation mode (configured in profile preferences)
- **Reset operations destructive without recovery**: confirmation prompts (FR-006) + dry-run mode (FR-005) + protected paths (FR-008) mitigate; reset audit trail (FR-007) provides forensic trail
- **Skill catalog drift across hosts**: `/specrew-reset` deployed via existing skill-catalog pattern (F-049 iter-3 engine + data); inherits the duplicate-row deploy bug per memory `[[project-specrew-update-deploy-duplicate-rows-2026-05-27]]` — must wait for that fix or include workaround
- **Audit trail bloat**: every reset writes to decisions.md; could grow large in heavy-reset workflows. Mitigation: orientation surface could show last N reset operations as awareness; rotation policy out of scope for v1
- **Cross-platform terminal differences**: Windows PowerShell vs pwsh on Linux vs macOS — Unicode box-drawing renders differently. Mitigation: FR-013 ASCII fallback + auto-detect + explicit `--ascii` flag
- **In-Crew vs CLI mode confusion**: same reset can be invoked from CLI (terminal) or in-Crew (active session); state implications differ. Mitigation: both paths produce IDENTICAL semantic behavior; documented in user-guide
- **Bullet-proof requirement risk**: "bulletproof" is subjective; could grow scope indefinitely. Mitigation: this proposal lists explicit FR-001 through FR-016 + SC-001 through SC-009 as the bulletproof bar; anything beyond is V2 scope

## Out of scope

- Web/dashboard UI for orientation (Proposal 092 territory)
- Multi-developer profile arbitration / sync (Proposal 010 territory)
- Backup/restore mechanism (snapshot before reset; full project archive — out)
- Telemetry on reset usage patterns (not in scope; analytics is a separate proposal)
- Versioned reset history (only "last reset of each scope" tracked; full historical replay out)
- Reset of git state / specs / decisions.md (FR-008 explicitly protects these)

## Phase placement

Phase 2 Tier 1. Maintainer explicit "bulletproof" requirement + empirical session-start gap that affects EVERY future user (downstream adopters) makes this user-trust critical. Ships post F-049 + F-050.

## Status history

- **2026-05-29** — Drafted in direct response to maintainer's explicit "we must provide a message at the beginning ... It has to tell the user about what it knows before starting. Also there should be a way to reset these parameters. I want this feature to be bulletproof" directive during F-049 v0.28.0 dogfooding (TelegramFeed downstream-project trial). Empirical motivation: Squad Coordinator on Copilot in fresh greenfield project asked "What do you want to build?" with ZERO orientation despite `.specrew/start-context.json` having full FR-038-compliant `user_profile` section. Proposal scope = 3 pillars (Welcome Orientation + Reset Surface + Discoverability), 15-25 SP across 3 iterations, priority-tier 1. Replaces what would have been a minimal pre-merge spec-steward charter fix (Option A) with bulletproof systemic answer (Option B). F-049 closeout PR carry-forward checklist updated to reference this proposal as the FR-038-in-situ follow-up.
