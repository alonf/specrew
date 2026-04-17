# Work Routing

How to decide who handles what in Specrew's spec-governed workflow.

## Routing Table

| Work Type | Route To | Examples |
|-----------|----------|----------|
| Spec alignment and drift control | Picard | Requirement tracing, plan/task/output alignment, tracked changes |
| Iteration planning | Data | Break requirements into tasks, assign owners, estimate effort |
| Implementation work | La Forge | Markdown/YAML/PowerShell asset changes, extension structure updates |
| Task review and demo readiness | Worf | Requirement verdicts, demo gate, pass / needs-work / blocked outcomes |
| Retrospectives and process improvement | Troi | Retro facilitation, drift-event analysis, estimation accuracy |
| Architecture and final reviewer gate | Alon | Architectural direction, reviewer overrides, final acceptance |
| Session logging | Scribe | Automatic — never needs routing |
| Backlog monitoring | Ralph | Queue health, follow-up scans, idle-watch |

## Issue Routing

| Label | Action | Who |
|-------|--------|-----|
| `squad` | Triage: analyze issue, map it to the right phase and member | Picard |
| `squad:{name}` | Pick up issue and complete the work | Named member |

### How Issue Assignment Works

1. When a GitHub issue gets the `squad` label, **Picard** triages it — analyzing content, mapping it to the right requirement or iteration, and assigning the right `squad:{member}` label.
2. When a `squad:{member}` label is applied, that member picks up the issue in their next session.
3. Members can reassign by removing their label and adding another member's label.
4. The `squad` label is the inbox for untriaged work waiting on spec-aware routing.

## Rules

1. **The spec is authoritative.** No route, task, or implementation overrides it without a tracked change.
2. **Work follows the iteration lifecycle:** planning ceremony -> execution routing -> review/demo ceremony -> retrospective ceremony.
3. **Drift detection happens after each task.** Route suspected drift to Picard first, then to the right owner.
4. **Worf and Alon are reviewer gates.** If work is rejected, the original author does not produce the next revision.
5. **Quick facts -> coordinator answers directly.** Use agents for judgment-heavy work.
6. **Scribe always runs** after substantial work and records decisions from the inbox.
7. **Ralph keeps the queue moving** once activated and idles only when the board is clear.
