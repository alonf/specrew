---
name: specrew-user-profile
description: Manage your Specrew Crew Interaction Profile — how much Specrew asks, explains, recommends, and auto-decides during specification intake.
---

# specrew-user-profile

**Type**: Configuration Skill
**Schema**: v1
**Status**: Active
**Namespace**: `/specrew`
**Canonical command**: `/specrew-user-profile`

## Purpose

Manage your **Crew Interaction Profile** — four decision-area settings that tell Specrew *how much to
ask, explain, recommend, and auto-decide* for you. Higher settings (7–10) get concise, expert-level
questions and assume you make the call; lower or `auto` settings get more explanation, recommended
defaults, and transparent auto-decisions.

The four visible decision areas are **Product Strategy**, **UX/UI Design**, **Software Architecture**,
and **AI Delivery Planning**. They are display labels for collaboration settings — not job titles you
must hold, and not Specrew's internal **persona lenses** (the perspectives the intake engine applies to
your request). Your profile tunes how Specrew talks to you; the persona lenses are Specrew's internal
analysis machinery and are unaffected by what you choose here.

The profile resolves per current user from a local file (the loader/path rule) and is reused across all
Specrew projects:

- **Windows**: `$env:USERPROFILE\.specrew\user-profile.yml`
- **Unix (Linux/macOS)**: `~/.specrew/user-profile.yml`

## When to Use

- When you want to view your current Crew Interaction Profile
- When you want to change how much Specrew asks/explains/auto-decides in one or more decision areas
- When you want to reset your profile and start fresh
- When troubleshooting substantive intake depth or question flow

## Subcommands

### show

Display the current Crew Interaction Profile with readable descriptions.

**Invocation:**

```text
/specrew-user-profile show
```

**Example output:**

```text
Crew Interaction Profile (current user):
- Product Strategy: 7 (Senior — concise questions; you decide)
- UX/UI Design: auto (Specrew recommends defaults and explains)
- Software Architecture: 9 (Senior — concise questions; you decide)
- AI Delivery Planning: 2 (Learning — Specrew explains and auto-decides with transparency)

To update: use /specrew-user-profile edit or /specrew-user-profile reset
```

### edit

Interactively update your decision-area settings. Prompts for each decision area; press Enter to keep
the current value.

**Invocation:**

```text
/specrew-user-profile edit
```

**Interactive flow:**

1. Displays current settings
2. Prompts for new settings (1-10 or 'auto')
3. Press Enter to keep existing value
4. Saves updated profile

### reset

Delete the profile file, triggering first-run setup on the next `specrew start`.

**Invocation:**

```text
/specrew-user-profile reset
```

**Warning:** This is destructive. The existing profile will be deleted and you will be prompted to
reconfigure on next `specrew start`.

## Implementation

Backed by: `scripts/internal/user-profile.ps1` helper functions.

**Shell invocation:**

```powershell
# Show profile
. C:\Dev\Specrew\scripts\internal\user-profile.ps1
$profile = Get-UserProfile
Show-UserProfileSummary -Profile $profile

# Edit profile
. C:\Dev\Specrew\scripts\internal\user-profile.ps1
Edit-UserProfile

# Reset profile
. C:\Dev\Specrew\scripts\internal\user-profile.ps1
Reset-UserProfile
```

For portable execution from any Specrew-managed project:

```powershell
$userProfileHelper = Join-Path (Get-Module Specrew -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1).ModuleBase 'scripts\internal\user-profile.ps1'
if (Test-Path $userProfileHelper) {
    . $userProfileHelper
    # Then call Show-UserProfileSummary, Edit-UserProfile, or Reset-UserProfile
}
```

## Decision-Area Setting Meanings

| Range | Setting | How Specrew collaborates |
|-------|---------|--------------------------|
| **7-10** | Senior | Concise, expert-level questions; assumes you make the call; minimal auto-decisions |
| **4-6** | Standard | Targeted clarifications |
| **1-3** | Learning | Specrew explains more and auto-decides with transparency annotations |
| **auto** | "you decide for me" | Specrew recommends defaults and explains them |

## Where the Profile Applies

- **Soft everywhere**: the resolved profile is surfaced in session context as soft collaboration
  guidance for all agents — current-user runtime context, **not** shared project truth.
- **Hard-applied only in `/speckit.specify`**: that surface uses your settings to drive per-lens
  question depth and auto-decisions. No other surface hard-applies the profile in this release.

## Compatibility

Display labels are display metadata only. The persisted schema keys (`expertise.*`, including
`ai_research_project_management`) and Specrew's internal persona IDs (including
`ai-researcher-project-manager`) are stable internal contracts and are never renamed or migrated.
Profiles created before this wording correction keep working unchanged — only the visible labels and
explanatory text changed.

## Cross-Platform Path Handling

- **Windows**: `$env:USERPROFILE\.specrew\user-profile.yml`
- **Unix (Linux/macOS)**: `~/.specrew/user-profile.yml`

The profile persists **across all Specrew projects** for the current user. Because it lives in your
home directory and is never written into shared repository artifacts, teammates can run different local
profiles in the same repository without any shared-repository changes.

## Related Commands

- `/speckit.specify` — the only surface that hard-applies the Crew Interaction Profile to tailor intake depth
- `specrew start` — prompts for your Crew Interaction Profile on first run if the profile is missing

## Boundary Safety

This skill modifies user-level configuration only. It does **not** authorize or imply approval to
advance any lifecycle boundary.

## Coexistence

Part of the `/specrew-*` command surface. Coexists with `/speckit.*` without collision.

## See Also

- Feature 049 Iteration 003 specification (engine + profile foundation)
- Feature 049 Iteration 005 / Proposal 141 (Crew Interaction Profile / persona lens separation)
- FR-024: User-level profile persistence
- FR-025: Profile management slash command
- FR-026: Profile summary in specrew start
