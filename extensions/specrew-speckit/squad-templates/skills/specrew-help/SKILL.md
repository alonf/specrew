---
name: specrew-help
description: Show the full Specrew slash-command catalog and provide next-step guidance.
---

# specrew-help

**Type**: Discovery Skill
**Schema**: v1
**Status**: Active
**Namespace**: `/specrew`
**Canonical command**: `/specrew-help`

## Purpose

Show the full Specrew slash-command catalog and provide next-step guidance. This is the **canonical fallback catalog** for every supported environment — reliable even when host-native `/specrew-` discovery is unavailable or incomplete.

## When to Use

- When a user wants to discover available Specrew commands.
- When the host environment does not surface inline slash-command suggestions.
- When a first-time Specrew user needs orientation.
- When a user types `/specrew-help` or asks: "What Specrew commands are available?", "How do I use Specrew?", "Show me Specrew help".
- As a discovery fallback in any environment where `/specrew-` suggestions are degraded or unknown.

## Boundary Safety

This skill provides **discovery and help information only**. It does **not** authorize or imply approval to advance any lifecycle boundary. It must never replace or absorb `/speckit.*` lifecycle help.

## Invocation

```text
/specrew-help
```

No arguments are accepted in v1. The command always shows the full catalog.

Backed by: built-in catalog help output in `scripts/specrew.ps1` (help mode)

## Outputs

The full v1 `/specrew-*` slash-command catalog:

| Command | Description | Notes |
| --- | --- | --- |
| `/specrew-where` | Show the current Specrew project status dashboard | |
| `/specrew-status` | Alias for `/specrew-where` | Produces identical output |
| `/specrew-update` | Refresh Specrew-managed assets and supported platform baselines | |
| `/specrew-team` | Manage Squad team members and baseline-role composition | |
| `/specrew-review` | Trigger or inspect the review-oriented workflow | |
| `/specrew-help` | Show this catalog | |
| `/specrew-version` | Show the installed Specrew version and slash-command compatibility state | |

Next-step guidance:

- New to Specrew? Start with `/specrew-where` to see your project status.
- Need to set up a project? Use `specrew init` from the terminal.
- Want to see available Spec Kit lifecycle commands? Use `/speckit.help` (separate namespace).

## Failure Guidance

| Failure mode | Behavior |
| --- | --- |
| Unsupported argument passed | Rejected; this command takes no arguments in v1 |

## Coexistence

Part of the `/specrew-*` command surface. The Specrew catalog help must never absorb or shadow `/speckit.*` lifecycle commands. Both namespaces remain independently discoverable.

## See Also

- `/specrew-where` — project status dashboard
- `/specrew-version` — version and compatibility state
