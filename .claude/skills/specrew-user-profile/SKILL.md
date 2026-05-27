---
name: specrew-user-profile
description: Manage your Specrew user expertise profile for persona-driven specification intake.
---

# specrew-user-profile

**Type**: Configuration Skill
**Schema**: v1
**Status**: Active
**Namespace**: `/specrew`
**Canonical command**: `/specrew-user-profile`

## Purpose

Manage the user-level expertise profile that tailors persona-driven specification intake to your experience level. The profile persists cross-platform at `~/.specrew/user-profile.yml` (Unix) or `$env:USERPROFILE\.specrew\user-profile.yml` (Windows) and is reused across all Specrew projects.

## When to Use

- When a user wants to view their current expertise settings
- When a user wants to update their expertise dials for one or more personas
- When a user wants to reset their profile and start fresh
- When troubleshooting substantive intake depth or question flow

## Subcommands

### show

Display the current user expertise profile with readable descriptions.

**Invocation:**

```text
/specrew-user-profile show
```

**Example output:**

```
Expertise Profile:
- Product Manager: 7 (Senior)
- UX/UI Specialist: 4 (Standard)
- Architect: 9 (Senior)
- AI Researcher / Project Manager: auto (system decides)

To update: use /specrew-user-profile edit or /specrew-user-profile reset
```

### edit

Interactively update expertise dials. Prompts for each persona; press Enter to keep the current value.

**Invocation:**

```text
/specrew-user-profile edit
```

**Interactive flow:**

1. Displays current settings
2. Prompts for new ratings (1-10 or 'auto')
3. Press Enter to keep existing value
4. Saves updated profile

### reset

Delete the user profile file, triggering first-run setup on the next `specrew start`.

**Invocation:**

```text
/specrew-user-profile reset
```

**Warning:** This is destructive. The existing profile will be deleted and you will be prompted to reconfigure on next `specrew start`.

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

## Expertise Dial Meanings

| Range | Level | Behavior |
|-------|-------|----------|
| **7-10** | Senior | Nuanced senior-level questions; minimal auto-decisions |
| **4-6** | Standard | Standard questions with targeted clarifications |
| **1-3** | Learning | System auto-decides with transparency annotations |
| **auto** | "I'm new, you decide" | System chooses defaults for this persona |

## Cross-Platform Path Handling

- **Windows**: `$env:USERPROFILE\.specrew\user-profile.yml`
- **Unix (Linux/macOS)**: `~/.specrew/user-profile.yml`

The profile persists **across all Specrew projects** for the current user.

## Related Commands

- `/speckit.specify` — Uses the expertise profile to tailor intake depth
- `specrew start` — Prompts for expertise ratings on first run if profile is missing

## Boundary Safety

This skill modifies user-level configuration only. It does **not** authorize or imply approval to advance any lifecycle boundary.

## Coexistence

Part of the `/specrew-*` command surface. Coexists with `/speckit.*` without collision.

## See Also

- Feature 049 Iteration 003 specification
- FR-024: User-level expertise profile persistence
- FR-025: Profile management slash command
- FR-026: Profile summary in specrew start
