# Feature Specification: Make Resume-Mode Visible in Specrew Onboarding

**Feature Branch**: `[010-onboarding-resume-visibility]`  
**Created**: 2026-05-10  
**Status**: Approved  
**Approved By**: Alon Fliess (human developer) on 2026-05-09 to authorize before-plan readiness.  
**Input**: User description: "Make resume-mode visible in Specrew onboarding so new users understand that every session, including resumes, must start with `specrew start`, and that running `copilot` directly breaks the supported handoff contract."

## Problem Statement

The canonical Specrew workflow assumes that every session — including resumes — runs through `specrew start`. That contract matters because `specrew start` regenerates the transient runtime handoff (`.specrew/last-start-prompt.md`, `.specrew/start-context.json`, `.specrew/start-summary.md`) from the current tracked state before launching Copilot, and it carries the launch contract into startup. If onboarding presents `specrew start` as a first-launch-only step, users can reasonably conclude that later sessions should begin with plain `copilot`, which breaks the intended workflow.

This feature closes that onboarding gap by making the resume contract explicit in the primary onboarding surfaces without changing runtime behavior.

## Relationship to Existing Features

- This feature carries forward spec 001 FR-024 and the follow-up session clarifications that `specrew start` is the canonical entry point for both first launch and resume sessions.
- This feature complements `009-project-path-resolution` by improving the clarity of the documented workflow without changing the workflow itself.
- This feature is limited to documentation and bootstrap banner copy. It does not change runtime behavior, lifecycle rules, or governance behavior.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - New user resumes correctly (Priority: P1)

A first-time Specrew user completes bootstrap, starts their first session with `specrew start`, and later returns to continue the same feature. By reading only the onboarding surfaces, they correctly understand that they must run `specrew start` again for the next session and must not begin with plain `copilot`.

**Why this priority**: This is the first repeat-use moment every successful user reaches. If the onboarding text teaches the wrong day-two behavior, users silently break the handoff contract immediately after their first session.

**Independent Test**: Read `README.md`, `docs/getting-started.md`, and the bootstrap completion banner after a successful setup. Verify each surface explicitly states that resume sessions run through `specrew start`, explains that it regenerates the runtime handoff, and warns that running `copilot` directly is not the supported path.

**Acceptance Scenarios**:

1. **Given** the recommended onboarding flow in `README.md`, **When** a new user reads it end-to-end, **Then** it explicitly states that resume sessions also begin with `specrew start`.
2. **Given** `docs/getting-started.md`, **When** a new user reads the onboarding guidance, **Then** it includes a prominent "Resuming work later" subsection that names `specrew start` as the resume command, explains what it regenerates, and warns against running `copilot` directly.
3. **Given** the bootstrap completion banner, **When** a new user reads the next-steps guidance, **Then** it includes a "Resuming work later" line stating that every subsequent session runs through `specrew start` because it regenerates the runtime handoff before launch.
4. **Given** any of the three onboarding surfaces, **When** a reader looks for the supported and unsupported launch paths, **Then** the surface explicitly names `specrew start` as the supported path and plain `copilot` as unsupported, with a short reason.

---

### User Story 2 - Cross-machine resumes stay understandable (Priority: P2)

A user returns after a restart, shell change, or machine switch and needs to know that `specrew start` is still the correct way to resume. They also need to understand that the transient runtime handoff files are regenerated per machine from tracked project state rather than being carried across machines.

**Why this priority**: The transient-versus-tracked distinction is already part of the product contract, but it is not obvious to a new user unless onboarding spells it out.

**Independent Test**: Read the same onboarding surfaces and verify they make clear that `specrew start` remains the correct command after a restart or machine switch, and that at least one surface explains the per-machine runtime handoff regeneration.

**Acceptance Scenarios**:

1. **Given** a user who switched machines and pulled the latest project state, **When** they read the onboarding guidance, **Then** at least one onboarding surface explains that `specrew start` regenerates the per-machine runtime handoff from tracked iteration state.
2. **Given** the "Resuming work later" subsection in `docs/getting-started.md`, **When** the user reads it, **Then** it briefly distinguishes transient per-machine runtime files from tracked project state that travels with the repository.

### Edge Cases

- A power user wants to skip the launch step and run `copilot` directly. The onboarding text must state that this is unsupported and briefly explain the cost of bypassing the handoff regeneration and launch contract.
- A user is still inside a live Squad session that was already launched by `specrew start`. The guidance must make clear that resuming means starting a new later session, not re-running `specrew start` inside an already active conversation.
- A user resumes on macOS or Linux. The resume guidance must stay platform-neutral.
- A user resumes on a different machine after pulling the latest repository state. The onboarding guidance must explain that `specrew start` rebuilds the local runtime handoff from tracked state.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001: README resume guidance**: `README.md` MUST include resume-mode guidance in its recommended flow or equivalent quickstart section that states later sessions also begin with `specrew start` and warns against running `copilot` directly, with a brief reason.
- **FR-002: Getting started resume subsection**: `docs/getting-started.md` MUST include a dedicated "Resuming work later" subsection, or an equally prominent equivalent, that (a) names `specrew start` as the command for every subsequent session, (b) explains that it regenerates `.specrew/last-start-prompt.md`, `.specrew/start-context.json`, and `.specrew/start-summary.md`, (c) explicitly warns against running `copilot` directly, and (d) covers the cross-machine case where those transient runtime files do not travel with git.
- **FR-003: Bootstrap banner resume guidance**: The bootstrap completion banner emitted by `scripts/specrew-init.ps1` MUST include a "Resuming work later" line in its next-steps guidance stating that every subsequent session runs through `specrew start` because it regenerates the runtime handoff before launch.
- **FR-004: Anti-pattern statement**: All three named onboarding surfaces (`README.md`, `docs/getting-started.md`, and the bootstrap completion banner) MUST explicitly state that running `copilot` directly is not the supported path for Specrew-managed projects, with a one-sentence rationale.
- **FR-005: User guide consistency review**: `docs/user-guide.md` MUST be reviewed and updated only if needed so it does not contradict the resume-every-session contract. If no change is needed, that finding MUST be recorded during implementation review.
- **FR-006: Documentation-only scope**: This feature MUST NOT change runtime behavior, lifecycle rules, governance behavior, or any non-banner code path. Its scope is limited to documentation and bootstrap banner wording.

### Traceability & Governance Requirements *(mandatory)*

- **TG-001**: User Story 1 MUST be covered by FR-001 through FR-004.
- **TG-002**: User Story 2 MUST be covered by FR-002 together with the regeneration language required by FR-001 and FR-003.
- **TG-003**: The feature MUST remain visibly additive to the previously established `specrew start` entry-point contract and the transient-versus-tracked runtime file clarification.
- **TG-004**: Reviewers MUST verify the rendered output of all three onboarding surfaces and confirm that the new resume guidance is visible without requiring readers to search through unrelated content.
- **TG-005**: Implementation MUST preserve the existing path-resolution behavior and keep the path-resolution regression coverage green while making the onboarding copy changes.

### Key Entities

- **Resume-Mode Language**: The set of onboarding statements that name `specrew start` as the command for every new and resumed session, explain the handoff regeneration, and warn against running `copilot` directly.
- **Bootstrap Complete Banner**: The terminal output shown after successful bootstrap that guides users through next steps, including how to resume later sessions.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of the three named onboarding surfaces contain explicit resume-mode guidance aligned with FR-001 through FR-003.
- **SC-002**: 100% of the three named onboarding surfaces contain the explicit anti-pattern warning against running `copilot` directly, aligned with FR-004.
- **SC-003**: In onboarding-comprehension review using any one of the three surfaces in isolation, at least 90% of new readers correctly identify `specrew start` as the correct resume command.
- **SC-004**: `docs/user-guide.md` either contains no contradictory first-launch-only language about `specrew start` or has any conflicting phrasing corrected before release.
- **SC-005**: The added bootstrap completion banner resume guidance is visible without scrolling on a standard terminal width of at least 100 columns.
- **SC-006**: The validation lane for this feature remains green at commit boundaries, and the existing path-resolution regression coverage remains unchanged.

## Clarifications

### Session 2026-05-10

- Q: Is this a runtime-behavior change or a documentation change? → A: Documentation and bootstrap banner wording only. No runtime contract or governance behavior changes are in scope.
- Q: Does this feature require modifying spec 001? → A: No. Spec 001 already establishes the resume contract. This feature only makes that contract visible in user-facing onboarding text.
- Q: Should the anti-pattern warning name `copilot` directly, or just describe what to avoid? → A: Name `copilot` directly so the unsupported path is unambiguous.
- Q: Should this feature ship before or after returning to feature 008? → A: Before. Land this feature first, then return `feature.json` to 008 in a later session when 008 resumes.

## Assumptions

- The existing bootstrap completion banner is the correct place to surface resume guidance; no new onboarding surface is required.
- `README.md` and `docs/getting-started.md` are the primary onboarding documents for new users, while `docs/user-guide.md` is a consistency check surface.
- The resume contract is platform-neutral and should be described without Windows-only wording.
- The project already has an established `specrew start` contract, so this feature focuses on visibility rather than redefining the workflow.

## Non-Goals

- Changing the runtime behavior of `specrew start`, `specrew init`, or `specrew update`.
- Adding new entry-point commands, new documentation files, or new bootstrap phases.
- Backporting these onboarding wording changes to historical releases.
- Modifying specs 008 or 009 as part of this feature.

## Governance Alignment *(mandatory)*

- **Spec Steward**: Alon Fliess
- **Iteration Facilitator**: Specrew documentation maintainers
- **Capacity Model**: One small documentation-and-banner slice covering three onboarding surfaces and one consistency review.
- **Drift Signals**: Any onboarding surface that implies `specrew start` is only for first launch, presents plain `copilot` as a valid Specrew launch path, omits resume guidance from bootstrap next steps, or expands scope beyond documentation and banner wording.
- **Human Oversight Points**: Human review of the rendered onboarding documents and human inspection of the live bootstrap completion banner output to confirm the resume guidance is visible and clear.
