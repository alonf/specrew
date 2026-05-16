---
proposal: 032
title: Specrew Slash-Command Surface
status: draft
phase: phase-2
estimated-sp: 7
discussion: tbd
---

# Specrew Slash-Command Surface

## Why

Specrew lives inside Squad/Copilot CLI sessions. Spec Kit's lifecycle agents surface as proper slash commands — `/speckit.specify`, `/speckit.clarify`, `/speckit.plan`, and so on. Specrew's own user-facing commands do not. A user typing `/specrew.` in Copilot CLI gets zero suggestions today.

Three workarounds exist:
1. Natural-language routing (`Show me the project status` → `specrew where` via FR-030 from Feature 017)
2. Asking Squad to run it ("Run specrew where")
3. `!`-prefix shell escape (`! pwsh -File .\scripts\specrew.ps1 where`)

All three work but none feels first-class. The asymmetry — `/speckit.*` present, `/specrew.*` absent — signals "Specrew is just orchestration around Spec Kit." That understates what Specrew actually is: a governance methodology with its own commands, validators, lifecycle artifacts, and discovery surface.

For public flip, identity-equity matters. Visitors who see Specrew has no slash commands will assume Specrew is parasitic on Spec Kit rather than a complementary first-class tool. A proper `/specrew.*` surface fixes that perception while improving day-to-day UX for everyone working inside Squad/Copilot sessions.

## What

A set of `/specrew.*` slash commands registered as Squad skills, ingested at `specrew init` time, and surfaced as proper Copilot CLI commands.

### Five pillars

1. **Slash-command skill definitions** — `.squad/skills/specrew-<command>/SKILL.md` files declare slash-command name, description, invocation pattern, argument forwarding rules, and help text for each user-facing command
2. **Invocation routing** — Squad recognizes `/specrew.where` and routes to the underlying dispatcher (`scripts/specrew.ps1 where`) via existing infrastructure
3. **Discovery + help integration** — `/specrew.help` shows the full catalog; Copilot CLI tab-completion surfaces available commands when user types `/specrew.`
4. **Distribution bundling** — skills ship as part of the Specrew Distribution Module; `specrew init` copies them into user projects
5. **Coexistence with `/speckit.*`** — additive, no naming collisions; both command namespaces work cleanly in the same session

### Initial command catalog

| Slash command | Underlying script | Description |
|---|---|---|
| `/specrew.where` | `specrew-where.ps1` | Render the project velocity dashboard |
| `/specrew.status` | alias for `/specrew.where` | Alias for `/specrew.where` |
| `/specrew.update` | `specrew-update.ps1` | Update Specrew templates and configuration |
| `/specrew.team` | `specrew-team.ps1` | Manage Squad team roster and members |
| `/specrew.review` | `specrew-review.ps1` | Trigger or inspect a Specrew review session |
| `/specrew.help` | built-in catalog | Show the full Specrew slash-command catalog |
| `/specrew.version` | reads `.specrew/config.yml` | Show installed Specrew version |

## Effort

- **Iteration 1 only**: ~5-8 SP across the 5 pillars
- Single iteration. Half-day to one-day focused work.

Combined with Specrew Distribution Module (Proposal 031): ~15-20 SP total, still feasible as a single iteration. Recommended sequencing combines both into one feature for narrative coherence ("Specrew becomes installable AND surfaces as a first-class tool" in one shipped feature).

## Phase placement

**Phase 2, pre-public-flip priority** — alongside Specrew Distribution Module (Proposal 031).

Two sequencing options:

- **Option A (combined)**: Distribution Module + Slash Commands ship together as one ~15-20 SP feature. Recommended.
- **Option B (sequential)**: Distribution Module Monday-Tuesday, Slash Commands Wednesday as small follow-up.

Both options ship before public flip alongside the queued Quality Hardening Bundle work.

## Open questions

1. Full 7-command catalog for v1, or smaller subset?
2. Default output handling — raw vs Squad-summarized?
3. Naming convention — `/specrew.where` vs `/specrew-where`?
4. Tab completion — built-in or manual catalog?
5. Argument forwarding — pass-through or whitelist?
6. `/specrew.help` integration with Copilot's `/help`?
7. Minimum Specrew version pin for slash-command compatibility?
8. Combined vs sequential with Distribution Module?
9. Cross-platform behavior on Linux/Mac PowerShell?
10. Future expansion path for `/specrew.audit`, `/specrew.metrics`, etc.?

## Risks

- **Skill format complexity**: SKILL.md format must be expressive enough for v1 commands and extensible for future ones. Mitigation: keep v1 schema small; document the extension contract.
- **Output redirection edge cases**: slash commands in Copilot CLI may have different stdout/stderr handling than direct PowerShell invocation. Mitigation: test in fresh Copilot session; document any environment-dependent behavior.
- **Auto-completion friction**: if Copilot CLI doesn't auto-discover `/specrew.*` cleanly, users won't see them in tab completion. Mitigation: explicit registration in agent metadata if needed.

## Cross-references

- Proposal 031 (Specrew Distribution Module) — composes tightly; combined-feature option recommended
- Feature 017 (Velocity Dashboard) — FR-030 natural-language routing remains in place; slash commands are additive
- Feature 016 (Substantive Interaction Model) — slash commands respect boundary discipline
- Spec Kit's `/speckit.*` skills — pattern to match for consistency

## Status history

- 2026-05-16: candidate captured after slash-command UX gap observed during a Squad/Copilot session; rationale strengthened by adoption-equity / identity-equity framing
