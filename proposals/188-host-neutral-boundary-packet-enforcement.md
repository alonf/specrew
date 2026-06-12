---
proposal: 188
title: Host-Neutral Boundary Packet Enforcement
status: candidate
phase: phase-2
estimated-sp: 12-18
priority-tier: 1
type: governance-host-hook
discussion: surfaced 2026-06-12 after maintainer observed that the six-section boundary packet rule survives refocus generally but is still prompt/skill-cooperative unless enforced by host runtime hooks or host-specific stop surfaces
composes-with:
  - 024  # Multi-Host Runtime Abstraction
  - 069  # Multi-Host Launch Path
  - 104  # Multi-Host Onboarding and Selection Flow
  - 105  # Host-Native Hook Deployment for Runtime Boundary Enforcement
  - 145  # Structured Multi-Phase Reviewer
  - 151  # Boundary Handoff Contract Unification
  - 154  # Boundary Authorization Prompt Truth
  - 155  # Typed Boundary Gate Packets
  - 157  # Verdict-Menu Instruction-Text Capture
  - 165  # PreToolUse Render-Gate Hook
  - 168  # Claude Boundary Packet Stop Hook
  - 172  # Hook-Driven Session Bootstrap
  - 181  # Live Cross-Host E2E Automation
  - 187  # Volatile Runtime Dependency Monitoring
audience: maintainers, host-adapter authors, Crew agents
---

# Host-Neutral Boundary Packet Enforcement

## Why

Specrew's human-judgment boundary packet is now a hard user-experience and
governance contract: a stop must render the six-section human re-entry packet,
name why the Crew stopped, point to review artifacts, describe what happens next,
and ask for exactly one boundary verdict.

The current implementation stack is layered but still incomplete:

1. Coordinator governance and role charters teach the packet.
2. Refocus digests preserve the rule after compaction.
3. The Claude `specrew-gate-stop` skill removes the verdict picker for one
   important host path.
4. Proposal 168 designs a Claude `Stop` hook that can inspect
   `last_assistant_message` and block once when the packet is missing.

That still leaves the requirement host-fragile. Some hosts have a `Stop` hook,
some have only prompt-submit or tool hooks, some can inject context but not block,
and some have no hook surface at all. A mandatory Specrew boundary rule cannot be
defined as "Claude has a Stop hook." The invariant must be host-neutral, with
per-host enforcement adapters and explicit degraded modes.

This proposal makes the six-section packet mandatory as a Specrew runtime
contract. Proposal 168 remains the Claude-first adapter slice. This proposal
owns the cross-host architecture and the rule that every supported host must
either enforce, correct, or clearly report its inability to enforce the packet.

## What

Add a host-neutral Boundary Packet Enforcement layer that validates the visible
boundary-stop output and routes enforcement through the strongest mechanism each
host supports.

### Pillar 1: Host-Neutral Packet Contract

Define one canonical packet contract for lifecycle boundary stops:

1. `What I Just Did`
2. `Why I Stopped`
3. `What Needs Your Review`
4. `What Happens Next`
5. `Discussion Prompts`
6. `What I Need From You`

The contract must also require, when applicable:

- the exact boundary being stopped at;
- the next boundary being requested;
- local artifacts as `file:///` URLs;
- validation, lint, test, branch, upstream, and dirty-state claims;
- explicit allowed verdicts;
- constraints such as no push, PR, merge, tag, publish, or release when those
  actions are not authorized.

The packet detector should be shared across hosts. It should distinguish a real
human-judgment boundary stop from ordinary progress updates, review comments, and
non-boundary conversation.

### Pillar 2: Capability-Based Enforcement Matrix

Create a host capability model for packet enforcement:

| Capability | Meaning | Enforcement posture |
| --- | --- | --- |
| `final-message-block` | Host can inspect the final assistant message and block once | Hardest layer; validate final visible text |
| `final-message-context` | Host can inject corrective context after final draft but cannot block | Corrective layer; warn and guide |
| `pre-verdict-tool-gate` | Host can intercept verdict/menu tools before rendering | Prevent menu-only stops |
| `prompt-submit-context` | Host can inject discipline before the next human turn | Recovery layer after a missed stop |
| `session-start-context` | Host can inject refocus at launch/compaction | Preventive layer only |
| `no-runtime-hook` | Host has no usable hook surface | Prompt/skill/refocus only, with visible limitation |

Specrew must pick the strongest available layer per host, not assume all hosts
share Claude's `Stop` shape.

### Pillar 3: Per-Host Enforcement Adapters

Implement per-host adapters behind one contract:

- `Get-Capabilities`
- `Install-Enforcement`
- `Validate-Deployment`
- `Handle-Event`
- `Report-DegradedMode`

The first adapters should classify current hosts honestly:

- Claude Code: use Proposal 168 `Stop` enforcement as the first hard adapter.
- Codex: use available prompt/session injection surfaces; add hard enforcement
  only if a final-message blocking hook exists and is documented.
- Cursor: use documented hook/context surfaces if available; otherwise degrade.
- Copilot: if no hook surface exists, report cooperative-only enforcement.
- Antigravity and other hosts: bind only after hook contracts are documented or
  accepted as empirical/private under Proposal 187.

Adapters must never silently claim hard enforcement when the host only supports
cooperative prompting.

### Pillar 4: Refocus and Compaction Hardening

Strengthen `refocus.ps1 --compact-instructions` so compacted sessions explicitly
preserve the six-section boundary packet requirement. This is not enough by
itself, but it closes the current weak wording where the requirement is only
implied by "binding constraints."

Add tests that prove:

- regular refocus output includes the packet rule;
- compact instructions explicitly preserve the packet requirement;
- boundary-specific refocus does not drop the packet rule.

### Pillar 5: Runtime Evidence and Diagnostics

Packet enforcement must be observable:

- deployments report which hosts have hard, corrective, preventive, or
  cooperative-only enforcement;
- blocked/corrected events are logged under runtime-local state, not feature
  artifacts;
- feature closeout can cite the enforcement posture without reading transcripts;
- degraded hosts show an explicit warning in `specrew where`, launch context, or
  a similar status surface.

This evidence is separate from proving the packet's claims. Proposal 145 remains
the review/evidence layer; this proposal proves the packet was present and not
collapsed.

### Pillar 6: Live Host Regression Coverage

Connect this work to Proposal 181's live cross-host E2E lane. Static fixtures can
prove packet detector behavior and settings merges. They cannot prove that a real
host actually passes `last_assistant_message`, preserves the injected context, or
honors a block decision.

The closeout standard must include at least one live or manual dogfood proof for
each host adapter that claims hard enforcement.

## How

Suggested implementation slices:

| Slice | Scope | Estimate |
| --- | --- | --- |
| 1 | Shared packet detector, compact-instruction hardening, and fixture tests | 3-4 SP |
| 2 | Capability model and deployment/status reporting | 2-3 SP |
| 3 | Claude hard adapter by implementing or absorbing Proposal 168 | 5-7 SP |
| 4 | Non-Claude adapter classification and degraded-mode reporting | 2-3 SP |
| 5 | Live-host evidence hooks and Proposal 181 integration | 2-3 SP |

The minimal useful release is Slices 1-3: shared contract, explicit compaction
preservation, and one real hard adapter. Slices 4-5 prevent that release from
being misrepresented as "all hosts hard-enforced."

## Acceptance Criteria

- **AC1**: Specrew has one shared packet detector for the six-section boundary
  packet and associated review/verdict content.
- **AC2**: The detector accepts a complete boundary packet and rejects a menu-only
  or section-incomplete stop.
- **AC3**: `refocus.ps1 --compact-instructions` explicitly preserves the
  six-section boundary packet requirement.
- **AC4**: Each supported host reports a packet-enforcement capability state:
  hard, corrective, preventive, or cooperative-only.
- **AC5**: Claude Code hard enforcement is delivered through Proposal 168's
  `Stop`-hook shape or a compatible successor.
- **AC6**: Hosts without a final-message blocking hook are not described as hard
  enforced.
- **AC7**: Degraded-mode status is visible to the user at launch or status time.
- **AC8**: Hook/settings deployment preserves existing user hooks and can be
  removed or disabled through the existing opt-out pattern.
- **AC9**: Runtime diagnostics for enforcement actions live under ignored
  runtime-local state and are not staged into feature work.
- **AC10**: At least one live or manual host proof validates every adapter that
  claims hard enforcement before that claim ships.

## Out of Scope

- Replacing Proposal 155 typed boundary packets.
- Proving that the packet's claims are true; Proposal 145 and validators own
  evidence truth.
- Making hosts with no hook surface behave like hosts with a final-message
  blocking hook.
- Rewriting Proposal 168 into a multi-host proposal; 168 remains the Claude
  adapter slice.
- General lifecycle entry enforcement; Proposal 180 owns first-source-write entry
  gates.
- General host hook deployment unrelated to boundary packet output; Proposal 105
  owns the broader hook framework.

## Composition

| Proposal | Relationship |
| --- | --- |
| [024](024-multi-host-runtime-abstraction.md) | Architectural endgame for host-neutral runtime contracts. |
| [069](069-multi-host-launch-path.md) | Supplies host selection and launch paths. |
| [104](104-multi-host-onboarding-and-selection-flow.md) | Supplies host history and selected-host context. |
| [105](105-host-native-hook-deployment.md) | General hook deployment ancestor; this proposal specializes it for boundary packet output. |
| [145](145-structured-multi-phase-reviewer.md) | Verifies evidence truth after the packet exists. |
| [151](151-boundary-handoff-contract-unification.md) | Defines the handoff unification lineage. |
| [154](154-boundary-authorization-prompt-truth.md) | Supplies authorization-truth constraints. |
| [155](155-typed-boundary-gate-packets.md) | Future authoritative packet source; this proposal can validate rendered packets from it. |
| [157](157-verdict-menu-instruction-text-capture.md) | Owns instruction text capture; this proposal ensures verdict menus do not replace the packet. |
| [165](165-pretooluse-render-gate-hook.md) | Claude render-before-menu sibling; narrower than final packet enforcement. |
| [168](168-claude-boundary-packet-stop-hook.md) | First concrete hard-enforcement adapter for Claude. |
| [172](172-hook-driven-session-bootstrap.md) | Shares session-start and hook deployment machinery. |
| [181](181-live-cross-host-e2e-automation.md) | Provides the live host proof lane. |
| [187](187-volatile-runtime-dependency-monitoring.md) | Tracks undocumented/private host hook contracts used by adapters. |

## Risks

- **False positives**: non-boundary messages could be blocked. Mitigate with
  conservative boundary detection and allow-on-uncertainty outside explicit
  boundary states.
- **False confidence**: a packet can be present but wrong. Mitigate by keeping
  Proposal 145 and validator evidence checks separate and mandatory.
- **Host API drift**: hook payloads and event names can change. Mitigate through
  Proposal 187 classification plus canaries/manual smoke checks.
- **Uneven host support**: some hosts may never support hard enforcement. Mitigate
  with explicit degraded-mode reporting rather than over-claiming.
- **Looping**: final-message hooks can block repeatedly. Mitigate with
  per-host loop guards such as Claude's `stop_hook_active` and one-correction
  limits.

## Status History

- 2026-06-12: Created as the host-neutral umbrella after maintainer direction
  that mandatory boundary packet enforcement must apply to all hosts, not only
  Claude Code.

## Cross-References

- file:///C:/Dev/Specrew/extensions/specrew-speckit/refocus/general.md
- file:///C:/Dev/Specrew/extensions/specrew-speckit/scripts/refocus.ps1
- file:///C:/Dev/Specrew/extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md
- file:///C:/Dev/Specrew/extensions/specrew-speckit/squad-templates/skills/gate-stop.md
- file:///C:/Dev/Specrew/proposals/105-host-native-hook-deployment.md
- file:///C:/Dev/Specrew/proposals/168-claude-boundary-packet-stop-hook.md
- file:///C:/Dev/Specrew/proposals/187-volatile-runtime-dependency-monitoring.md
- file:///C:/Dev/Specrew/proposals/INDEX.md
