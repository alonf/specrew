# Iteration 001 Drift Log

**Feature**: F-044 | **Iteration**: 001

## Drift #1 — Spec written AFTER implementation

The single largest drift in this iteration: the spec did not exist at implementation time. The work shipped (Phase A through Slice 9, ~24 commits across 2026-05-23 → 2026-05-24) driven by conversational direction + Proposal 108 + user-observed gaps. The spec, plan, and iteration artifacts (this directory) are retroactive backfill at closeout.

**Why it happened**: User explicitly authorized a fast-moving multi-host integration push. The conversation thread is the de facto requirements doc; Proposal 108 captured the design after the first ~half of the work was already committed.

**Methodology impact**: Severe. Without an upfront spec:

- Clarify-boundary never happened — user reviewed scope decisions only at conversational checkpoints
- Plan-boundary never happened — phases A→B→C→D were declared mid-execution
- The standing review-gate ALMOST didn't happen either — 4-agent deep review was dispatched only because the user explicitly asked for it at closeout

**Mitigation**: Two-iteration pattern at closeout — iter-001 closes with the 22 findings + iter-002 addresses them. Demonstrates the review-gate working even on retroactive artifacts. The mitigation does NOT erase the upfront discipline gap; it just contains downstream blast radius.

**Reviewer disposition**: Accepted as documented exception. User flagged the gap themselves: "we work really hard and not so by Specrew methodology since I want available and I let you run. It is time to fix that."

## Drift #2 — Slice 9 design changed mid-flight (canonical source-of-truth)

Original Proposal 108 Slice 9 design called for each host's `Install-<Kind>CrewRuntime` to translate from `.squad/agents/<role>/charter.md` (Squad's existing convention) to each host's native format. During implementation, user pushed back on this design: "we need to be host agnostic in most of the code... in the future, adding a host for Cursor, windsurf or grok code should not open existing files." Slice 9 was redesigned mid-flight to introduce a NEW canonical source at `.specrew/team/agents/<role>.md` — host-neutral, lower in the dependency graph than Squad.

**Schema impact**: Adds a new directory `.specrew/team/`. The shipped baseline copies into this location on init.

**User impact**: Net positive. Users now have a clear "this is the team I edit" location that's not tied to Copilot's npm-shipped Squad CLI.

**Reviewer disposition**: Accepted. The redesign is genuinely better than the original Proposal 108 plan; the post-hoc spec captures the redesigned shape.

## Drift #3 — Antigravity smoke test deferred

The Antigravity host was graduated from "deferred" to "supported" during Phase C.2 / Phase D, but its subagent format (Markdown + YAML frontmatter at `.agents/agents/<role>.md`) was inferred from Gemini CLI documentation. No empirical smoke test against an actual `agy` binary was run during this iteration.

**Schema impact**: None.

**User impact**: Antigravity host is technically "supported" but tagged "medium-confidence" in handlers.ps1 header comments. First real user attempting `specrew start --host antigravity` may surface format errors.

**Reviewer disposition**: Accepted with explicit handler header annotation. Smoke test queued for follow-up post-Gemini-deadline (2026-06-18).

## Drift #4 — Coordinator-overlay translation NOT shipped

Proposal 108 hints at translating the coordinator overlay (`.github/agents/squad.agent.md` for Copilot) to per-host equivalents for Claude/Codex/Antigravity. This work is significantly larger (touches Proposal 024 Category D — the 45 numbered coordinator directives) and was deliberately deferred.

**Schema impact**: None. Only the Copilot host has a working coordinator overlay; other hosts launch without one (the bootstrap prompt at `.specrew/last-start-prompt.md` carries the substantive instructions, mitigating the gap).

**User impact**: `specrew start --host claude` works but the team coordination is prose-driven, not subagent-mediated by a coordinator file. Functional but less polished than Copilot's experience.

**Reviewer disposition**: Accepted as out-of-scope; tracked in [`../../spec.md`](../../spec.md) § "Out-of-scope (deferred)".

## Drift #5 — `specrew team` CLI still writes to legacy `.squad/team.md`

The team-customization CLI (`specrew team add/list/update/remove`) was not rewired during this iteration. It still writes to `.squad/team.md` (Squad's flat-file team manifest), not the new canonical `.specrew/team/agents/<role>.md`.

**Schema impact**: None for this iteration, but post-F-044 the canonical source is the new mechanism; the legacy CLI will diverge silently.

**User impact**: Users who run `specrew team add security-analyst ...` write to `.squad/team.md` only. The new agent does NOT appear at `.specrew/team/agents/security-analyst.md` and therefore does NOT propagate to Claude/Codex/Antigravity on next `specrew start`. Cross-host customization currently requires manually creating the canonical file.

**Reviewer disposition**: Accepted as known limitation. Tracked as a follow-up small-fix slice in [`../../spec.md`](../../spec.md) § "Out-of-scope".
