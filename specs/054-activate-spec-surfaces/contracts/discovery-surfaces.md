# Contract: Discovery Surfaces

## Purpose

Define the user-facing surfaces that must treat `/speckit.checklist` and `/speckit.analyze` as first-class Specrew capabilities while keeping `/speckit.taskstoissues` deferred.

## Surface matrix

| Surface | Audience | Required command guidance | Non-negotiable contract |
| --- | --- | --- | --- |
| `README.md` | New and returning users | Surface checklist before-plan, analyze before-implement, and deferred taskstoissues status in plain language | Must describe these commands as Specrew capabilities discoverable from the standard lifecycle overview |
| `docs/user-guide.md` | Operators following the lifecycle | Explain where each active command belongs and what artifacts/prerequisites make it relevant | Must preserve the clarified timing and additive-governance framing |
| `.github/agents/speckit.plan.agent.md` + `.github/prompts/speckit.checklist.prompt.md` | Copilot-host planning boundary | Before-plan surfaces must tell users why checklist adds value before planning starts | Must not imply checklist is always mandatory |
| `.github/agents/speckit.tasks.agent.md` + `.github/prompts/speckit.analyze.prompt.md` | Copilot-host tasks/before-implement boundary | Surface analyze only once the spec/plan/tasks artifact set is complete | Must point users back to the correct stage if `tasks.md` is missing |
| `.github/agents/speckit.taskstoissues.agent.md` + `.github/prompts/speckit.taskstoissues.prompt.md` | Maintainers and advanced users | Mention taskstoissues only as a deferred capability for a later version unless a future slice re-scopes it | Must not present taskstoissues as part of the default lifecycle |

## Consistency requirements

1. Every updated surface must use the same lifecycle placement:
   - `/speckit.checklist` → `before-plan`
   - `/speckit.analyze` → `before-implement` after complete `tasks.md`
   - `/speckit.taskstoissues` → deferred
2. Every surface must keep `/speckit.analyze` additive to Specrew governance.
3. Every surface that mentions checklist must preserve proportional wording for low-risk slices.
4. No updated surface may contradict the feature spec, checklist, or this plan.
