---
proposal: 168
title: Claude Boundary Packet Stop Hook
status: candidate
phase: phase-2
estimated-sp: 6-10
priority-tier: 1
type: governance-host-hook
discussion: surfaced 2026-06-06 after side-by-side Codex and Claude dogfooding showed Codex reliably follows the Specrew boundary packet instructions while Claude Code can stop on an MCQ/verdict menu without rendering the full human re-entry packet and file URLs
composes-with:
  - 105  # Host-Native Hook Deployment for Runtime Boundary Enforcement
  - 145  # Structured Multi-Phase Reviewer
  - 151  # Boundary Handoff Contract Unification
  - 154  # Boundary Authorization Prompt Truth
  - 155  # Typed Boundary Gate Packets
  - 157  # Verdict-Menu Instruction-Text Capture
  - 165  # PreToolUse Render-Gate Hook
  - 167  # Post-Ship Proposal Amendment Discipline
  - 188  # Host-Neutral Boundary Packet Enforcement
audience: maintainers, Claude Code users, Crew agents
---

# Claude Boundary Packet Stop Hook

## Why

Specrew already teaches boundary handoff behavior in the Claude agent charters,
the generic agent charters, and the coordinator governance template. Representative
local surfaces include:

- file:///C:/Dev/Specrew/.claude/agents/spec-steward.md
- file:///C:/Dev/Specrew/.claude/agents/planner.md
- file:///C:/Dev/Specrew/.claude/agents/implementer.md
- file:///C:/Dev/Specrew/.claude/agents/reviewer.md
- file:///C:/Dev/Specrew/.claude/agents/retro-facilitator.md
- file:///C:/Dev/Specrew/.specify/extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md

Those instruction files are not enough. Live dogfooding showed a host-specific
failure mode:

1. Codex follows the Specrew handoff instructions well, including local
   `file:///` review links and explicit "I stopped because..." prose.
2. Claude Code often routes boundary interaction through the MCQ/verdict menu
   mechanism, and the menu can become the visible output instead of an
   artifact-rich Specrew re-entry packet.
3. Prompt edits alone are fragile because they live inside the model context.
   Compaction, host-specific tool gravity, and menu rendering can still produce
   a thin approval prompt.

This is exactly the class of problem Specrew should not leave to exhortation:
the user-facing boundary packet is a governance object. If the host has a
runtime hook that can inspect or block the final answer, Specrew should use it.

## What

Add a Claude Code Stop hook that enforces, or at least one-turn-corrects, the
human-visible Specrew boundary packet before Claude ends a boundary turn.

The hook is Claude-only in v1. It must not affect Codex, Copilot, Cursor, or
other hosts. Proposal 188 owns the host-neutral enforcement architecture; this
proposal remains the Claude adapter/slice because Claude Code exposes the
`Stop` hook fields this design depends on.

### Primary mechanism: Stop hook

Install a Claude Code `Stop` hook for Specrew-enabled projects. At the end of a
turn, the hook:

1. Reads Claude Code hook input from stdin.
2. Checks `last_assistant_message` for the canonical Specrew packet.
3. Resolves current Specrew state from artifacts and git, not from chat memory.
4. If the turn is not a lifecycle boundary stop, no-ops.
5. If the boundary packet is present and complete, no-ops.
6. If the boundary packet is missing or incomplete, blocks once and supplies
   concise corrective context so Claude appends the packet before the turn ends.
7. If `stop_hook_active` is already true, avoids another block and records a
   diagnostic rather than looping.

The important design point is that Claude Code exposes `last_assistant_message`
to Stop hooks. The hook does not need to parse the full transcript just to avoid
repeating a packet that Claude already rendered.

### Secondary mechanism: PreToolUse guard

Add, or leave as a follow-up slice, a narrow `PreToolUse` guard for
`AskUserQuestion` boundary verdict menus:

- If Claude asks a boundary verdict MCQ before rendering the packet, deny or
  ask with a reason that tells Claude to render the packet first.
- If the packet is already rendered, allow the menu.
- Keep this separate from Proposal 165's workshop render-gate. Proposal 165
  gates design workshop confirm menus; this proposal gates lifecycle boundary
  packets.

The Stop hook is the primary fix because it sees the final assistant text and can
repair the actual user-visible boundary stop. PreToolUse is a useful early guard,
but it is not enough by itself because a boundary packet can be omitted without
any specific tool call being the sole cause.

### MessageDisplay is not an authority

Claude Code `MessageDisplay` hooks may be useful for capture or display-only
formatting, but they must not be the enforcement authority. The official hook
contract says MessageDisplay can replace displayed text but cannot block the
message, change the transcript, or change what Claude sees. Specrew governance
must not rely on display-only rewriting as proof that the agent actually emitted
the packet.

## Canonical Boundary Packet

The hook validates the six-section human re-entry packet from Proposals 154 and
155:

1. `What I Just Did`
2. `Why I Stopped`
3. `What Needs Your Review`
4. `What Happens Next`
5. `Discussion Prompts`
6. `What I Need From You`

Required content depends on boundary state, but the hook should check for:

- the exact boundary being stopped at;
- the next lifecycle boundary being requested;
- local artifact links as `file:///...` URLs when local artifacts exist;
- branch hygiene: current branch, HEAD, upstream parity when a feature branch is
  active, and dirty-state classification;
- validation status and known warnings when validation was run;
- explicit allowed human responses: approve as-is, approve with instructions,
  send back, or discuss a prompt;
- "no release / no tag / no merge / no push to main" constraints when those were
  part of the active boundary context.

The detector should tolerate harmless capitalization differences in headings but
must reject menu-only output that lacks artifact review targets or the reason for
the stop.

## State Resolution

The hook must treat repository artifacts as source of truth. It should read only
the minimum required state:

- `.specify/feature.json`
- `.specrew/start-context.json`
- `.specrew/config.yml`
- the active feature `spec.md`, `plan.md`, `tasks.md`, and closeout files when
  present
- active iteration `state.md`, `dashboard.md`, `plan.md`, `quality/hardening-gate.md`,
  and `quality/quality-evidence.md` when present
- latest validator summary if one exists
- `git status --short --branch`
- `git rev-parse HEAD`
- `git rev-parse origin/<feature-branch>` when an upstream branch exists

The hook may use `transcript_path` as secondary evidence, but must not require
full transcript parsing for normal duplicate suppression because
`last_assistant_message` already supplies the final response text.

## Loop And Duplicate Control

The hook must be conservative and must not trap Claude in a repeated correction
loop.

Rules:

- If `last_assistant_message` already contains a complete packet, no-op.
- If the packet is incomplete and `stop_hook_active` is false, return
  `decision: "block"` with a short reason and corrective context.
- If the packet is incomplete and `stop_hook_active` is true, do not block again.
  Record a diagnostic and allow the turn to end.
- Do not write normal repo files while enforcing. If a diagnostic is needed, use
  a runtime-local log/cache location that is excluded from feature work, or emit
  hook output only.
- Tests must prove that the hook does not duplicate a packet that Claude already
  rendered.

This "one corrective continuation" posture avoids Claude Code's documented
consecutive-block override and prevents the hook from becoming another source of
boundary friction.

## Functional Requirements

- **FR-001**: Specrew MUST deploy the boundary packet hook only for Claude Code
  projects or Claude-selected host profiles.
- **FR-002**: The Stop hook MUST inspect `last_assistant_message` before deciding
  whether to intervene.
- **FR-003**: The Stop hook MUST no-op when the final message already contains a
  complete Specrew boundary packet.
- **FR-004**: The Stop hook MUST block once when a lifecycle boundary stop is
  missing required packet sections, local artifact `file:///` links, or explicit
  human verdict instructions.
- **FR-005**: The Stop hook MUST avoid repeated blocking when `stop_hook_active`
  indicates Claude is already continuing because of a Stop hook.
- **FR-006**: The hook's boundary-state summary MUST be derived from Specrew
  artifacts and git state, not from the agent's free-form report.
- **FR-007**: The hook MUST distinguish lifecycle boundary stops from ordinary
  conversation and implementation progress updates.
- **FR-008**: The hook MUST preserve existing user Claude settings by merging hook
  entries non-destructively.
- **FR-009**: The hook MUST be read-only with respect to source and governance
  artifacts during enforcement.
- **FR-010**: A narrow `PreToolUse` guard MAY be added for Claude
  `AskUserQuestion` boundary verdict menus, but it MUST not replace the Stop
  hook.
- **FR-011**: MessageDisplay MUST NOT be used as the governance authority for
  boundary packet compliance.
- **FR-012**: Hook tests MUST include complete-packet, missing-packet,
  menu-only, non-boundary, and already-stop-hook-active fixtures.

## Acceptance Criteria

- **AC1**: Given a simulated Claude Stop input whose `last_assistant_message`
  already has all six packet sections and file URLs, the hook exits without a
  block decision.
- **AC2**: Given a simulated Stop input with only an MCQ/verdict menu and no
  boundary packet, the hook returns a single block decision with corrective
  context.
- **AC3**: Given the same incomplete message while `stop_hook_active` is true,
  the hook does not block again.
- **AC4**: A simulated non-boundary development update is allowed even if it does
  not contain boundary packet headings.
- **AC5**: A packet that asks the user to review local artifacts but omits
  `file:///` URLs is rejected.
- **AC6**: A packet that includes branch or validation claims inconsistent with
  git/artifact state is rejected or marked incomplete.
- **AC7**: The hook can build a corrective packet context from active feature and
  iteration artifacts without reading chat history.
- **AC8**: Claude settings deployment preserves pre-existing user hooks and
  permissions.
- **AC9**: The test fixture set documents the official Claude hook fields used:
  `last_assistant_message`, `stop_hook_active`, `transcript_path`,
  `tool_name`, and `tool_input`.
- **AC10**: The implementation records the Claude Code documentation URLs used
  in hook contract tests or docs so future maintainers can re-check API drift.

## Expected Implementation Surfaces

Likely files, subject to spec/plan confirmation:

| Surface | Purpose |
| --- | --- |
| `extensions/specrew-speckit/scripts/hooks/stop-boundary-packet.ps1` | Claude Stop hook handler |
| `.specify/extensions/specrew-speckit/scripts/hooks/stop-boundary-packet.ps1` | Generated mirror |
| `extensions/specrew-speckit/scripts/hooks/pretool-boundary-verdict.ps1` | Optional narrow AskUserQuestion guard |
| `extensions/specrew-speckit/scripts/shared-boundary-packet.ps1` | Packet detector and state resolver |
| Claude host settings template/deploy code | Non-destructive `.claude/settings.json` hook merge |
| `tests/unit` or `tests/integration` hook fixtures | Simulated Claude hook input/output tests |
| `docs` or methodology guidance | Maintainer-facing description and fallback behavior |

Implementation must prefer synthetic hook input fixtures over live Claude sessions
for regression tests, with one manual/dogfood evidence run before closeout if
feasible.

## Out Of Scope

- Replacing Proposal 155's typed boundary gate packet system.
- Implementing a multi-host hook framework beyond Claude Code. Proposal 188 owns
  the cross-host packet-enforcement contract and degraded-mode model.
- Changing lifecycle boundary authorization semantics.
- Changing the verdict vocabulary.
- Solving free-form instruction text capture; Proposal 157 owns that.
- Solving workshop confirm-menu rendering; Proposal 165 owns that.
- Relying on MessageDisplay as a governance proof.

## Knowledge And URL Ledger

This proposal intentionally records the external and local knowledge used to
avoid losing the research trail.

### Official Claude Code hook documentation

- <https://docs.anthropic.com/en/docs/claude-code/hooks>
- <https://docs.anthropic.com/en/docs/claude-code/hooks.md>

Knowledge used:

- Hooks can be shell commands, HTTP endpoints, or LLM prompts.
- Hook cadences include once-per-session events, once-per-turn events, and
  per-tool-call events.
- `Stop` runs when the main Claude Code agent has finished responding.
- `Stop` input includes `stop_hook_active` and `last_assistant_message`.
- `last_assistant_message` contains Claude's final response text, so the hook can
  inspect it without parsing the transcript.
- `stop_hook_active` is true when Claude is already continuing because of a Stop
  hook; the docs warn to use it or transcript processing to avoid unresolvable
  loops.
- `Stop` and `SubagentStop` can return `decision: "block"` with a required
  reason, or use `hookSpecificOutput.additionalContext` for non-error context.
- `PreToolUse` runs after Claude has produced tool parameters and before the tool
  executes.
- `PreToolUse` can allow, deny, ask, defer, and modify tool input with
  `updatedInput`.
- `PreToolUse` receives `tool_name`, `tool_input`, and `tool_use_id`.
- `MessageDisplay` can replace displayed deltas with `displayContent`, but has no
  decision control and does not change the transcript or what Claude sees.

### Local Specrew evidence

- file:///C:/Dev/Specrew/.claude/agents/spec-steward.md
- file:///C:/Dev/Specrew/.claude/agents/planner.md
- file:///C:/Dev/Specrew/.claude/agents/implementer.md
- file:///C:/Dev/Specrew/.claude/agents/reviewer.md
- file:///C:/Dev/Specrew/.claude/agents/retro-facilitator.md
- file:///C:/Dev/Specrew/.agents/agents/spec-steward.md
- file:///C:/Dev/Specrew/.agents/agents/planner.md
- file:///C:/Dev/Specrew/.agents/agents/implementer.md
- file:///C:/Dev/Specrew/.agents/agents/reviewer.md
- file:///C:/Dev/Specrew/.agents/agents/retro-facilitator.md
- file:///C:/Dev/Specrew/.specify/extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md

Knowledge used:

- Agent charters already instruct boundary stops to use Specrew handoff sections.
- Coordinator governance already names the richer human re-entry packet and
  branch hygiene expectations.
- Therefore the missing behavior is not primarily "write more prompt text"; it is
  runtime enforcement or correction when Claude's host interaction path skips the
  packet.

### Related Specrew proposals

- file:///C:/Dev/Specrew/proposals/105-host-native-hook-deployment.md
- file:///C:/Dev/Specrew/proposals/145-structured-multi-phase-reviewer.md
- file:///C:/Dev/Specrew/proposals/151-boundary-handoff-contract-unification.md
- file:///C:/Dev/Specrew/proposals/154-boundary-authorization-prompt-truth.md
- file:///C:/Dev/Specrew/proposals/155-typed-boundary-gate-packets.md
- file:///C:/Dev/Specrew/proposals/157-verdict-menu-instruction-text-capture.md
- file:///C:/Dev/Specrew/proposals/165-pretooluse-render-gate-hook.md
- file:///C:/Dev/Specrew/proposals/167-post-ship-proposal-amendment-discipline.md
- file:///C:/Dev/Specrew/proposals/188-host-neutral-boundary-packet-enforcement.md

Knowledge used:

- Proposal 105 supplies the general host-native hook deployment direction.
- Proposal 145 supplies the evidence posture: agent reports are artifacts under
  test, not testimony.
- Proposals 151 and 154 define the boundary handoff and human re-entry packet
  shape.
- Proposal 155 is the deeper typed-packet future; this proposal is a targeted
  Claude enforcement layer that can later validate or render from typed packets.
- Proposal 157 remains the owner of instruction text capture inside verdict
  menus.
- Proposal 165 remains the owner of PreToolUse render-before-menu enforcement for
  workshop confirm menus.
- Proposal 167 is why this is a new proposal instead of silently editing shipped
  or already-implemented proposal bodies.
- Proposal 188 generalizes the mandatory boundary-packet rule across hosts; this
  proposal remains the Claude-specific hard-enforcement adapter.

## Effort

Estimated 6-10 SP:

| Work item | Estimate |
| --- | --- |
| Stop hook handler and output contract | 1.5-2 SP |
| Boundary packet detector | 1.5-2 SP |
| Artifact/git state resolver | 1-1.5 SP |
| Claude settings merge/deploy | 1-1.5 SP |
| Synthetic hook fixtures and tests | 1.5-2 SP |
| Optional PreToolUse boundary verdict guard | 1-2 SP |
| Docs and dogfood evidence | 0.5-1 SP |

The implementation should split if Stop-hook enforcement exceeds one iteration;
ship the Stop hook first and defer the PreToolUse guard.

## Risks

- **False positives**: a legitimate non-boundary turn could be blocked. Mitigate
  with conservative boundary detection and no-op defaults.
- **Looping**: repeated Stop blocks could frustrate the user. Mitigate with
  `stop_hook_active` and one corrective continuation per turn.
- **Host API drift**: Claude Code hook schemas may change. Mitigate by recording
  documentation URLs in tests and keeping hook contract fixtures small.
- **Settings collision**: user `.claude/settings.json` may contain existing
  hooks. Mitigate with non-destructive merge and explicit tests.
- **False confidence**: hook-compliant prose still needs Proposal 145 evidence
  verification. The hook improves packet presence; it does not prove the packet's
  claims by itself.

## Status History

- 2026-06-06: Created as a high-priority candidate after maintainer observed that
  Claude Code's MCQ path can omit Specrew's full boundary packet even though
  Codex follows the same Specrew instructions reliably.
- 2026-06-12: Related to Proposal 188 as the Claude-specific hard-enforcement
  slice under the host-neutral packet-enforcement umbrella.
