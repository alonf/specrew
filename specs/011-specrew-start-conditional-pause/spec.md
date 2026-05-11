# Feature Specification: Conditional Pause on specrew-start When Session-Loaded Files Changed

**Feature Branch**: `[NNN-specrew-start-conditional-pause]`
**Created**: 2026-05-11
**Status**: Draft
**Input**: User description: "During feature 007 dogfooding on 2026-05-11, the user restarted Copilot to load updated `.github/agents/squad.agent.md` between iteration 002 implementation and review/closeout. Squad's startup-handoff (`.specrew/last-start-prompt.md`) auto-continued the lifecycle and started running the reviewer before the user could send a post-restart directive (specifically: a small iter 001 stale-status fix and a plain-language-format reminder). The auto-continue behavior is correct per spec 001 Session 2026-05-04 for routine resumes, but it bypasses the user's ability to inject directives in exactly the case where they most often matter — when the restart was forced by a session-loaded behavioral file change."

## Problem Statement

Specrew's `specrew-start.ps1` handoff behavior follows the Session 2026-05-04 auto-continue clarification from spec 001: when a session resumes (detected by `.specrew/last-start-prompt.md` existing), the regenerated handoff includes an auto-continue directive so the Squad coordinator runs immediately without waiting for user input. This behavior is correct for routine resumes where nothing structural has changed.

However, the user frequently restarts Copilot or the Squad session specifically to **reload session-loaded files** (behavioral files like `.github/agents/squad.agent.md`, `charter.md`, `.github/copilot-instructions.md`, or Spec Kit extension templates). In these cases, the auto-continue behavior bypasses the user's ability to issue a first-message directive (e.g., a status clarification, iteration-plan override, or scope reframing) that would apply to the restarted session. The user must manually kill the auto-running coordinator and restart, adding friction to an otherwise routine workflow.

Concretely observed during dogfooding on 2026-05-11:

1. User is in feature 007 iteration 002 implementation.
2. User identifies that `.github/agents/squad.agent.md` has stale guidance for the reviewer.
3. User updates `.github/agents/squad.agent.md` and commits.
4. User restarts Copilot to pick up the updated agent.
5. `specrew-start.ps1` regenerates `.specrew/last-start-prompt.md` with an auto-continue directive.
6. Squad's coordinator immediately resumes the lifecycle and starts running the reviewer.
7. User loses the opportunity to send a first-message directive (the stale-status fix, or a plain-language reminder).
8. User must manually kill the session and restart, or issue directives in parallel, causing workflow friction.

The root cause: `specrew-start.ps1` cannot distinguish between a routine auto-resume (where auto-continue is correct) and a session-reload forced by a session-loaded file change (where the user almost always wants to inject a directive before the lifecycle continues).

## Relationship to Existing Features

- **Spec 001 Session 2026-05-04 auto-continue clarification**: The Session 2026-05-04 decision documented that `specrew-start.ps1` SHOULD auto-continue when a session resumes. This feature does not override that decision; it refines it to apply only when session-loaded files have not changed.
- **Spec 001 FR-024 specrew-start contract**: This feature remains strictly additive to the documented contract. Entry arguments, defaults, and error messages are unchanged.
- **Session 2026-05-06 transient-vs-tracked runtime file split**: That session clarified the distinction between transient session state (`.specrew/last-start-prompt.md`, managed by `specrew-start.ps1`) and tracked governance files (`.specify/`, `.squad/`, feature specs). This feature uses that boundary to detect whether tracked files have changed.
- **Spec 005 Phase 2 known-traps corpus**: This feature references the test-integrity corpus row for scaffold-replay-path testing (noted below under FR-003), and the feature must seed a new corpus entry for the "auto-handoff bypass" pattern when the spec lands.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Auto-continue behavior is preserved for routine resumes (Priority: P1)

A human developer who has not changed any session-loaded files between sessions runs `specrew-start.ps1` when resuming a session and expects the auto-continue behavior to proceed as documented in spec 001.

**Why this priority**: Breaking the auto-continue behavior for routine resumes would regress the Session 2026-05-04 design intent and add friction to the common case.

**Independent Test**: Run `specrew-start.ps1` multiple times in the same session state (no commits to session-loaded paths between runs) and verify that the regenerated `.specrew/last-start-prompt.md` contains an auto-continue directive both times.

**Acceptance Scenarios**:

1. **Given** a Specrew-managed project with `.specrew/last-start-prompt.md` already present, **When** the user runs `specrew-start.ps1` without having committed any changes to session-loaded paths, **Then** the regenerated `.specrew/last-start-prompt.md` includes an auto-continue directive and Squad's coordinator launches immediately.
2. **Given** the user has not modified any of `.github/agents/*`, `.github/copilot-instructions.md`, `extensions/specrew-speckit/squad-templates/coordinator/*`, `.specify/extensions/specrew-speckit/squad-templates/coordinator/*`, or `charter.md` files, **When** `specrew-start.ps1` runs, **Then** the handoff detector finds zero changes and auto-continue behavior is preserved.
3. **Given** the user has issued untracked modifications (uncommitted changes) to session-loaded files, **When** `specrew-start.ps1` runs, **Then** the detector checks committed-state changes only and auto-continue behavior is preserved (uncommitted changes do not trigger the pause).

---

### User Story 2 - Session-loaded file changes trigger pause-and-confirm, allowing user directives (Priority: P1)

A human developer who has committed changes to session-loaded files between Copilot/session restarts runs `specrew-start.ps1` and can issue a first-message directive (status fix, scope reframing, etc.) before the lifecycle auto-continues.

**Why this priority**: This is the gap that caused the friction observed on 2026-05-11. Closing this gap is the core reason for the feature.

**Independent Test**: Commit a change to `.github/agents/squad.agent.md`, run `specrew-start.ps1`, verify that the regenerated `.specrew/last-start-prompt.md` contains a PAUSE-AND-CONFIRM directive instead of auto-continue, and that the user can read and respond to the prompt before Squad continues.

**Acceptance Scenarios**:

1. **Given** a Specrew-managed project with committed changes to `.github/agents/squad.agent.md` since the last `specrew-start.ps1` run, **When** the user runs `specrew-start.ps1`, **Then** the detector identifies the change and the regenerated `.specrew/last-start-prompt.md` includes a PAUSE-AND-CONFIRM directive that shows the user which files changed.
2. **Given** a PAUSE-AND-CONFIRM directive is active in the handoff, **When** the user is presented with the handoff at the start of the session, **Then** the user sees a clear message explaining why the pause occurred (e.g., "Session-loaded files changed: .github/agents/squad.agent.md") and is asked to confirm or provide a directive before Squad's coordinator auto-continues.
3. **Given** the user has committed changes to `charter.md` or Spec Kit extension template files, **When** `specrew-start.ps1` runs, **Then** the pause-and-confirm behavior is triggered the same way as for agent changes.

---

### User Story 3 - User can prepend custom post-restart directives via `-PostRestartDirective` parameter (Priority: P2)

A power user who wants to include a specific first-message directive (e.g., "focus on reviewer performance validation") can supply it on the `specrew-start.ps1` command line, and the directive is prepended to the regenerated handoff.

**Why this priority**: This is additive opt-in functionality for power users who already know they want a directive. P2 because it is strictly optional and can be omitted in the initial slice if needed.

**Independent Test**: Run `specrew-start.ps1 -PostRestartDirective "Focus on reviewer performance validation."`, verify that the regenerated `.specrew/last-start-prompt.md` includes the supplied text as the first directive before any PAUSE-AND-CONFIRM or auto-continue logic.

**Acceptance Scenarios**:

1. **Given** a user invokes `specrew-start.ps1 -PostRestartDirective "Validate the reviewer escalation contract."`, **When** the regenerated `.specrew/last-start-prompt.md` is produced, **Then** the user's directive appears as the first instruction in the handoff prompt, followed by any pause-and-confirm or auto-continue behavior.
2. **Given** the user supplies `-PostRestartDirective` but session-loaded files have NOT changed, **When** the regenerated handoff is produced, **Then** the custom directive is prepended and the auto-continue behavior follows, so the user's directive is injected before auto-continuation.
3. **Given** the user supplies `-PostRestartDirective` AND session-loaded files HAVE changed, **When** the regenerated handoff is produced, **Then** the custom directive is prepended, followed by the PAUSE-AND-CONFIRM messaging and change list.

---

### Edge Cases

- The prior session did not create `.specrew/last-start-prompt.md` (e.g., first-time bootstrap or after manual cleanup). The detector still runs, and if session-loaded files have changed since HEAD~1, the pause behavior is triggered. If this is the very first run, the pause is skipped (no prior baseline to compare against).
- The prior session itself was a bootstrap session (`specrew-init`) with no prior commit baseline. The detector gracefully handles this by comparing against HEAD only; no pause is triggered because there is no historical baseline to detect changes against.
- The user has uncommitted modifications to session-loaded files. The detector uses `git diff --name-only HEAD` (committed state only), not the working tree, so uncommitted changes do not trigger the pause. This preserves routine work-in-progress patterns where the user has unsaved edits that are not yet committed.
- A session-loaded file has been modified and then reverted to its prior state (modified, then committed a revert). The detector runs `git diff --name-only` between the last-committed handoff baseline and HEAD, so a revert commit is still detected as a change (the file appears in the diff even though the final state matches the baseline). This is acceptable because the revert itself is evidence of behavioral change (the user did something intentional to the file).
- The user specifies both `-PostRestartDirective` and manually passes `-ForceAutoContinue`. The `-ForceAutoContinue` flag is explicitly rejected (see Clarifications below).
- The user's session-loaded file change is purely whitespace or comment-only (no functional change). The detector still reports the file as changed. This is acceptable because the user committed the change intentionally, and a pause prompt gives them a chance to clarify if needed.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001: Change Detector Implementation**: `specrew-start.ps1` MUST detect whether the previous session committed changes to any session-loaded path. The detector MUST:
  - Run `git diff --name-only` between a baseline commit (see FR-002) and HEAD.
  - Check the following session-loaded paths: `.github/agents/*`, `.github/copilot-instructions.md`, `extensions/specrew-speckit/squad-templates/coordinator/*`, `.specify/extensions/specrew-speckit/squad-templates/coordinator/*`, and any `charter.md` file in the project root or subdirectories.
  - Return a list of changed files, or an empty list if no session-loaded files have changed.
  - Handle the bootstrap case gracefully (no prior commits) by treating it as a first-run with zero changes detected.

- **FR-002: Baseline Commit Tracking**: `specrew-start.ps1` MUST track a baseline commit for the change detector. The baseline MUST be:
  - The commit timestamp or hash recorded in the last `.specrew/last-start-prompt.md` file (if it exists).
  - If `.specrew/last-start-prompt.md` does not exist or does not contain a baseline marker, the baseline defaults to HEAD (compare HEAD against HEAD, detecting zero changes on first run).
  - Updated in the regenerated `.specrew/last-start-prompt.md` to the current HEAD so the next `specrew-start.ps1` run uses the correct baseline.

- **FR-003: Pause-and-Confirm Directive Injection**: When the detector reports one or more changed session-loaded files, the regenerated `.specrew/last-start-prompt.md` MUST include a PAUSE-AND-CONFIRM directive instead of the auto-continue directive. The PAUSE-AND-CONFIRM message MUST:
  - Clearly state that session-loaded files have changed.
  - List the changed file paths (from the `git diff --name-only` output).
  - Ask the user to confirm or provide a directive before Squad's coordinator continues (e.g., "Please review the changes below and provide any additional context needed. Type CONFIRM or a directive to continue.").
  - Be formatted as a visible prompt that Squad's coordinator will render when resuming the session, using the existing scaffold-replay-path testing mechanism per `specs/005-stack-aware-quality-bar/spec.md` test-integrity corpus row (visibility output must be tested through scaffold-replay-path assertions, not just runtime state files).

- **FR-004: Auto-Continue Preservation**: When the detector reports zero changed session-loaded files, the regenerated `.specrew/last-start-prompt.md` MUST include the auto-continue directive exactly as it would without this feature (per spec 001 Session 2026-05-04).

- **FR-005: PostRestartDirective Parameter**: `specrew-start.ps1` MUST accept a `-PostRestartDirective` parameter (string, optional, default empty). When supplied:
  - The parameter value is prepended to the regenerated `.specrew/last-start-prompt.md` as the first directive.
  - If the parameter is empty, no prepended text is added.
  - The prepended text MUST appear verbatim with no modification.
  - Prepending happens before any PAUSE-AND-CONFIRM or auto-continue logic, so the user's custom directive takes priority in the rendered handoff.

- **FR-006: Routine Auto-Continue Not Compromised**: This feature MUST NOT change the signature, defaults, or documented behavior of `specrew-start.ps1`. The `-ProjectPath` argument and all existing documented entry points MUST remain unchanged.

- **FR-007: Error Message Fidelity**: All existing error messages ("Project is not fully bootstrapped", "Session state invalid", etc.) MUST be preserved. New pause-and-confirm messages MUST be added without modifying existing error paths.

- **FR-008: Known-Traps Corpus Seeding**: When this feature's plan.md is created, the feature plan MUST explicitly note that the source spec requires seeding the known-traps corpus with a new row documenting the "auto-handoff bypass when session-loaded files change" pattern (discovery date 2026-05-11, category: governance). The feature plan MUST assign a task (TR-*) to seed this corpus entry during the feature lifecycle. The corpus entry MUST include:
  - Category: `governance`
  - Broken Pattern: "`specrew-start.ps1` auto-handoff bypasses the user's ability to issue first-message directives in the new session when session-loaded files are committed between restarts."
  - Detection Method: Code review and user-reported friction observed on 2026-05-11; deterministic test coverage in integration tests.
  - Remediation Guidance: See feature `[NNN-specrew-start-conditional-pause]` implementation and FR-001 through FR-005.
  - Discovery Date: 2026-05-11
  - If the row does not yet exist in `.specrew/quality/known-traps.md`, the feature plan MUST explicitly designate creating it as part of the closure criteria.

- **FR-009: Detector Visibility in Handoff**: The regenerated `.specrew/last-start-prompt.md` MUST include a line item or structured field showing the detector's result (e.g., `## Session-Loaded Files Changed: .github/agents/squad.agent.md`) so the user can see at a glance why a pause was triggered. This field MUST be visible in the handoff prompt and MUST be testable via scaffold-replay-path assertions.

- **FR-010: Validator and Integration Test Coverage**: The feature MUST include:
  - A deterministic integration test that exercises the detector with committed changes to session-loaded files and verifies the pause-and-confirm directive is injected.
  - A deterministic integration test that exercises the detector with no changes to session-loaded files and verifies auto-continue behavior is preserved.
  - A deterministic integration test that exercises the `-PostRestartDirective` parameter and verifies the custom directive is prepended.
  - All visibility output (pause-and-confirm messages, file lists, custom directives) MUST be tested through scaffold-replay-path assertions per test-integrity corpus guidance, not just runtime state inspection.

### Traceability & Governance Requirements *(mandatory)*

- **TG-001**: User Story 1 MUST be covered by FR-004, FR-006, FR-007.
- **TG-002**: User Story 2 MUST be covered by FR-001, FR-002, FR-003, FR-009.
- **TG-003**: User Story 3 MUST be covered by FR-005.
- **TG-004**: Known-traps integration MUST be covered by FR-008. The feature plan MUST explicitly designate seeding the corpus entry as a closure criterion.
- **TG-005**: This feature MUST remain strictly additive to spec 001 FR-024 (specrew-start contract). No documented entry points, arguments, or default behaviors change beyond what FR-005 adds (the optional `-PostRestartDirective` parameter).
- **TG-006**: All visibility output added (pause-and-confirm messages, file lists) MUST be tested through scaffold-replay-path assertions per `specs/005-stack-aware-quality-bar/spec.md` test-integrity corpus row, not just runtime state inspection.

### Key Entities

- **Change Detector**: Logic inside `specrew-start.ps1` that runs `git diff --name-only` to identify committed changes to session-loaded paths.
- **Session-Loaded Paths**: The set of behavioral files that control Squad's behavior: `.github/agents/*`, `.github/copilot-instructions.md`, `extensions/specrew-speckit/squad-templates/coordinator/*`, `.specify/extensions/specrew-speckit/squad-templates/coordinator/*`, and `charter.md` files.
- **Baseline Commit**: The commit hash or timestamp recorded in the prior `.specrew/last-start-prompt.md` (or HEAD if no prior handoff exists) used to determine the starting point for the change detector's diff.
- **PAUSE-AND-CONFIRM Directive**: A sentinel message prepended to the regenerated `.specrew/last-start-prompt.md` when session-loaded files have changed, indicating to Squad's coordinator that the user has the opportunity to inject a first-message directive before auto-continuing.
- **Auto-Continue Directive**: The existing behavior from spec 001 Session 2026-05-04, preserved when session-loaded files have not changed, that tells Squad's coordinator to immediately resume the lifecycle.
- **PostRestartDirective Parameter**: An optional string argument supplied on the `specrew-start.ps1` command line that is prepended to the regenerated handoff prompt.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: After rollout, 100% of user sessions that restart Copilot/Squad after committing changes to session-loaded files receive a PAUSE-AND-CONFIRM prompt listing the changed files.
- **SC-002**: After rollout, 100% of user sessions that restart Copilot/Squad without committing changes to session-loaded files auto-continue immediately per spec 001 Session 2026-05-04 behavior.
- **SC-003**: After rollout, the user can use the `-PostRestartDirective` parameter to prepend a custom first-message directive to the regenerated handoff.
- **SC-004**: After rollout, all visibility output (pause-and-confirm messages, changed-file lists) is verified by deterministic integration tests using scaffold-replay-path assertions, per test-integrity corpus guidance.
- **SC-005**: After rollout, the known-traps corpus `.specrew/quality/known-traps.md` contains a row documenting the "auto-handoff bypass" pattern discovered on 2026-05-11.
- **SC-006**: After rollout, running `specrew-start.ps1` from a Specrew-managed project reproduces the friction-reduced workflow observed on 2026-05-11 (commit a session-loaded file change, restart, receive pause-and-confirm, inject a directive, confirm).

## Clarifications

### Session 2026-05-11

- Q: What is the default behavior when `.specrew/last-start-prompt.md` does not exist (first-time bootstrap)? → A: On first run (no prior handoff), the baseline defaults to HEAD and the detector compares HEAD against HEAD, finding zero changes. Auto-continue behavior proceeds as normal. No pause is triggered on bootstrap because there is no meaningful historical baseline to compare against.

- Q: What happens if the prior session is itself a bootstrap (`specrew-init`) with no prior commits? → A: The detector gracefully handles this by using HEAD as the baseline. If this is the very first run of a newly initialized Specrew project, the detector runs but finds zero changes (comparing HEAD against HEAD). No pause is triggered because there is no historical baseline. If the user has committed changes to session-loaded files since the bootstrap, the next `specrew-start.ps1` run will detect those changes and trigger a pause.

- Q: Can the pause behavior be overridden by a `-ForceAutoContinue` flag? → A: No. The `-ForceAutoContinue` flag is explicitly not supported. If the user needs to force auto-continue despite session-loaded file changes, they can omit calling `specrew-start.ps1` entirely and directly invoke the squad coordinator, or they can revert the session-loaded file change. The pause is intentional and protective; overriding it would undermine the feature's purpose.

- Q: Are uncommitted modifications to session-loaded files treated as changes? → A: No. The detector uses `git diff --name-only HEAD` (committed state only) and does not inspect the working tree. Uncommitted work-in-progress changes do not trigger the pause. The pause is triggered only by committed changes, which are deliberate and shareable.

- Q: What paths are considered "session-loaded"? → A: The definitive list is `.github/agents/*`, `.github/copilot-instructions.md`, `extensions/specrew-speckit/squad-templates/coordinator/*`, `.specify/extensions/specrew-speckit/squad-templates/coordinator/*`, and `charter.md` files (in the project root or subdirectories). These are the files that control Squad's behavior and require the user to restart/reload Copilot to take effect.

- Q: What baseline commit is used for the initial diff? → A: The baseline is recorded in the prior `.specrew/last-start-prompt.md` file (a structured field that tracks the commit hash or timestamp). If no prior handoff exists, the baseline defaults to HEAD. After the new handoff is generated, the baseline is updated to the current HEAD so the next `specrew-start.ps1` run has the correct reference point.

- Q: How is the pause-and-confirm message formatted and rendered? → A: The message is part of the regenerated `.specrew/last-start-prompt.md` and is rendered by Squad's coordinator when the session resumes. The message MUST include a clear statement like "Session-loaded files changed: .github/agents/squad.agent.md" and a prompt asking the user to confirm or provide a directive before continuing. The exact formatting and rendering are testable via scaffold-replay-path assertions per test-integrity corpus guidance.

## Assumptions

- The user's Specrew repository is a Git repository with commit history. The detector relies on `git diff --name-only` and assumes commits are available.
- The user is running PowerShell 7+ on Windows or a compatible POSIX PowerShell host where Git commands are available.
- The Spec Kit and Squad integration surfaces remain unchanged. This feature only modifies `specrew-start.ps1` and adds integration test coverage.
- The Session 2026-05-04 auto-continue clarification from spec 001 remains the authoritative baseline. This feature refines it; it does not override it.
- The `.specrew/quality/known-traps.md` file exists and is available for corpus seeding when the feature plan is created. If the corpus does not yet exist, this feature may seed it as the first entry.

## Non-Goals

- Changing the signature, defaults, or documented behavior of `specrew-start.ps1` beyond adding the optional `-PostRestartDirective` parameter.
- Pausing on uncommitted file changes. The detector operates on committed state only.
- Pausing on trivial (whitespace or comment-only) changes. The detector reports any file appearing in `git diff --name-only` as changed, regardless of content magnitude.
- Introducing a `-ForceAutoContinue` flag to override the pause. The pause is intentional and protective.
- Modifying Squad's coordinator or other downstream components beyond the handoff prompt format.
- Backporting to historical Specrew releases. Only the current development line is in scope.

## Governance Alignment *(mandatory)*

- **Spec Steward**: Alon Fliess, as the owner of the spec 001 Session 2026-05-04 auto-continue clarification and as the human who observed the friction on 2026-05-11, must approve the final detector logic and pause-and-confirm message formatting.
- **Iteration Facilitator**: Specrew lifecycle and test-integrity maintainers responsible for keeping `specrew-start.ps1` aligned with the documented user workflow and for ensuring integration test coverage exercises scaffold-replay-path assertions per test-integrity corpus guidance.
- **Capacity Model**: One bounded iteration covering the change detector, pause-and-confirm injection, `-PostRestartDirective` parameter, integration test coverage (including scaffold-replay-path assertions), and known-traps corpus seeding. No new toolchain or runtime dependency is introduced beyond existing Git and PowerShell.
- **Drift Signals**: Any user report that `specrew-start.ps1` fails to pause when session-loaded files change; any future modification to `specrew-start.ps1` that reintroduces unconditional auto-continue behavior without checking session-loaded file state; any visibility output added that is not covered by scaffold-replay-path test assertions.
- **Human Oversight Points**: Human approval of the baseline-commit tracking mechanism (how `.specrew/last-start-prompt.md` records the baseline); human approval of the pause-and-confirm message wording and formatting; human review of the integration test suite to confirm it exercises the detector and pause behavior under realistic conditions; human approval of the known-traps corpus entry seeded by this feature.
