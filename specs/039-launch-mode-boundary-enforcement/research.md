# Research: Launch-Mode Boundary Enforcement

**Feature**: F-039  
**Date**: 2026-05-22  
**Status**: Phase 0 complete

This research resolves the six Phase 0 questions from `plan.md` and grounds Phase 1 design in the current Specrew implementation, Proposal 065, and the recorded F-039 boundary-breach incident.

---

## Research Task 1: Boundary Detection Mechanism

### Research questions (verbatim)

- What is the current boundary detection mechanism in `sync-boundary-state.ps1` and how does it signal boundary transitions?
- How does `specrew-start.ps1` currently determine when to prompt for human authorization at boundaries?
- What agent response patterns indicate boundary advancement attempts (e.g., "Continuing to next phase", "Proceeding with implementation")?
- Can we rely on Squad skill completion markers (e.g., `/speckit.clarify` exit) or do we need prose pattern matching?
- What is the failure mode if boundary detection has false-negatives (missed boundary) vs false-positives (unnecessary prompt)?

### Investigation evidence

- `scripts\internal\sync-boundary-state.ps1:187-189, 728-800` defines the canonical persisted boundary order and warns when the next synced boundary is out of sequence.
- `scripts\internal\sync-boundary-state.ps1:486-528` persists only `session_state`; no current `boundary_enforcement` store exists yet.
- `scripts\specrew-start.ps1:3355-3375` decides only whether launch posture is gate-respecting or autopilot; it does not inspect later agent turns.
- `extensions\specrew-speckit\scripts\shared-governance.ps1:1479-1588` already contains a boundary catalog and alias normalizer for interaction-model subjects, but it does not enforce authorization for `specify`, `clarify`, `plan`, `tasks`, or `before-implement`.
- `specs\039-launch-mode-boundary-enforcement\iterations\001\drift-log.md:9-35` records the concrete failure: a single chained response crossed `plan -> tasks` without human authorization.
- Proposal 065 requires two distinct mechanisms: skill-level refusal for actual boundary advancement and prose-aware bypass-attempt detection for audit logging (`proposals\065-launch-mode-boundary-enforcement.md:80-90, 197-217`).
- The current canonical boundary lists omit `before-implement` (`scripts\internal\sync-boundary-state.ps1:188`; `extensions\specrew-speckit\scripts\shared-governance.ps1:862`), while the spec and proposal require nine gated boundaries.

### Answers

- **What is the current boundary detection mechanism in `sync-boundary-state.ps1` and how does it signal boundary transitions?**  
  Today Specrew detects persisted boundaries only after a sync step. It compares the requested boundary against a canonical ordered list, updates `session_state`, and writes a boundary-sync entry to `.squad\decisions.md`. It does not currently gate advancement.
- **How does `specrew-start.ps1` currently determine when to prompt for human authorization at boundaries?**  
  It does not perform runtime boundary authorization. It launches Copilot with either gate-respecting prose guidance or `--autopilot`; any stop behavior today depends on agent compliance with the handoff text.
- **What agent response patterns indicate boundary advancement attempts (e.g., "Continuing to next phase", "Proceeding with implementation")?**  
  The reliable patterns are structured chains that name the next lifecycle command or explicitly narrate advancement (`/speckit.plan -> /speckit.tasks`, "continuing to next phase", "proceeding with implementation", "approved to continue"). These are good evidence for `bypass_attempt_detected`, but not safe as the sole source of truth for actual boundary crossing.
- **Can we rely on Squad skill completion markers (e.g., `/speckit.clarify` exit) or do we need prose pattern matching?**  
  We need a hybrid model: structured boundary context is authoritative; prose pattern matching is advisory. Boundary authorization must key off the current boundary plus requested next boundary inside the invoked skill/hook. Prose scanning is retained only to explain why a block happened and to populate FR-005 logging.
- **What is the failure mode if boundary detection has false-negatives (missed boundary) vs false-positives (unnecessary prompt)?**  
  False-negatives are the stop-ship failure: the tool chain advances without authorization, exactly the plan-to-tasks breach logged in Iteration 001. False-positives are noisy but recoverable: a user is asked for an approval they did not need. Because Specrew is a governance system, the design must bias toward conservative blocking rather than permissive misses.

### Decision

Use **structured boundary authorization with prose-backed bypass evidence**:

1. The authoritative check runs inside each boundary-advancing skill/helper and evaluates `current boundary -> requested boundary` against persisted authorization.
2. The persisted boundary catalog expands to the required nine boundaries, adding `before-implement`.
3. Response-snippet pattern matching remains secondary and only drives `bypass_attempt_detected`, operator context, and audit evidence.

### Rationale

Proposal 065's mechanical guarantee comes from tool-call refusal, not from asking the agent to behave better. The current system already has canonical boundary/state machinery; the safest design is to extend that machinery rather than elevate free-form prose into authority.

### Failure-mode analysis

| Failure mode | Impact | Design response |
| --- | --- | --- |
| Missed boundary because prose did not match | Unauthorized advancement | Do not authorize from prose; authorize only from requested boundary + persisted state |
| Spurious phrase match in ordinary narration | Unnecessary block or noisy logging | Treat prose as evidence only; it cannot independently advance or deny a boundary |
| Alias mismatch (`planning` vs `plan`, `implementation` vs `before-implement`) | False negative or incorrect persisted state | Normalize human-facing aliases at parse time, but persist only canonical boundary names |
| Catalog remains eight-boundary only | `before-implement` is never guarded | Extend canonical boundary lists and validators to the nine-boundary contract before implementation starts |

---

## Research Task 2: Hook Intercept Points in specrew-start.ps1

### Research questions (verbatim)

- What is the current `specrew-start.ps1` control flow for launching Copilot CLI and processing agent responses?
- Where does `--autonomous` flag currently enable autopilot behavior, and how does it bypass boundary prompts?
- What is the lifecycle of `.specrew/start-context.json` updates during a feature session (read/write frequency, transaction boundaries)?
- Can we intercept before Copilot CLI reads agent response, or must we post-process after agent completion?
- What is the error handling strategy if hook execution fails (throw exception, log and continue, retry)?

### Investigation evidence

- `scripts\specrew-start.ps1:3196-3467` validates launch options, detects stale state, computes autopilot posture, writes start artifacts, and then calls `Start-CopilotSession`.
- `scripts\specrew-start.ps1:3074-3077, 3114-3125, 3360-3368` is the only place that turns `--autonomous` into `--autopilot`.
- `scripts\internal\sync-boundary-state.ps1:486-528, 728-880` updates `start-context.json` only when explicit boundary-sync scripts run.
- `scripts\specrew-start.ps1:368-409` reads `start-context.json` at launch/resume time, tolerating missing legacy fields.
- Proposal 065 places the real enforcement inside boundary-advancing skills, not solely in the host launcher (`proposals\065-launch-mode-boundary-enforcement.md:49-82, 156-159`).

### Answers

- **What is the current `specrew-start.ps1` control flow for launching Copilot CLI and processing agent responses?**  
  It is a launch/bootstrap script, not a response-loop wrapper. It prepares prompt/context artifacts, decides launch posture, and hands control to Copilot. It does not receive later tool results back in-process.
- **Where does `--autonomous` flag currently enable autopilot behavior, and how does it bypass boundary prompts?**  
  `--autonomous` becomes `$useAutopilot`, which adds `--autopilot` to the Copilot invocation. The bypass occurs because the launched agent keeps chaining turns without a tool-level refusal, not because `specrew-start.ps1` itself approves a boundary.
- **What is the lifecycle of `.specrew/start-context.json` updates during a feature session (read/write frequency, transaction boundaries)?**  
  The file is read at launch/resume and written atomically during explicit boundary-sync operations. There is no current mid-turn update loop in `specrew-start.ps1`; transaction boundaries are individual file writes.
- **Can we intercept before Copilot CLI reads agent response, or must we post-process after agent completion?**  
  The launcher can intercept only **before session start**. It cannot intercept arbitrary later agent responses once Copilot owns the session. Therefore F-039 needs two surfaces: `specrew-start.ps1` preflight for migration/bypass session setup, and skill-level authorization hooks for the actual boundary stop.
- **What is the error handling strategy if hook execution fails (throw exception, log and continue, retry)?**  
  For F-039 enforcement hooks, failure must throw and block. `specrew-start.ps1` can log a directive and exit; skill-level hooks must refuse advancement and bubble the failure back to the agent.

### Decision

Adopt a **two-surface intercept design**:

1. `scripts\specrew-start.ps1` owns boundary-enforcement **preflight**: schema migration check, emergency bypass activation, launch-posture annotation, and recovery handoff.
2. Boundary-advancing skills plus shared governance helpers own the **authoritative intercept** immediately before any boundary transition executes.
3. No design depends on a mythical mid-loop host callback from Copilot CLI.

### Rationale

This matches what the current launcher can actually control. It also aligns with Proposal 065's Pillar 1: if the skill throws, the chain stops at the failed tool call and the agent cannot continue past the boundary.

### Failure-mode analysis

| Failure mode | Impact | Design response |
| --- | --- | --- |
| Preflight-only implementation | Boundaries after launch remain unenforced | Require skill-level gate insertion as the real stop mechanism |
| Attempting to parse later agent output from `specrew-start.ps1` | Impossible integration point; false confidence | Keep launcher responsibilities to migration, bypass, and recovery bootstrap only |
| Hook logs and continues | Silent governance bypass | All enforcement failures are terminating for the boundary path |
| Start-context updates occur only at session start | Authorization state goes stale mid-session | Boundary hooks must update the same store when verdicts/bypasses are recorded |

---

## Research Task 3: Fail-Safe Enforcement Mechanics

### Research questions (verbatim)

- What is the current error handling strategy in `specrew-start.ps1` for script failures?
- How does session state recovery handle corrupted `.specrew/start-context.json` files?
- What happens if enforcement hook throws exception mid-boundary-transition?
- Should fail-safe behavior write a sentinel value to block retry, or rely on exception propagation?
- How do we distinguish between transient failures (network issue) and permanent failures (hook logic bug)?

### Investigation evidence

- `scripts\specrew-start.ps1:220-221` sets strict mode and `Stop` semantics globally.
- `scripts\specrew-start.ps1:3198-3243` exits hard on invalid CLI combinations.
- `scripts\specrew-start.ps1:382-390` currently treats many `start-context.json` parse failures as absent state; that tolerance is good for legacy startup, but unsafe for new authorization state.
- `scripts\internal\sync-boundary-state.ps1:187-221, 383-417, 486-528` uses atomic file writes and throws on write failures.
- Proposal 065 explicitly rejects permissive degradation on corrupt state and requires recovery directives instead (`proposals\065-launch-mode-boundary-enforcement.md:173-176, 207-211`).
- Spec FR-006 requires fail-safe behavior and `.squad\log\enforcement-errors.log` logging (`specs\039-launch-mode-boundary-enforcement\spec.md:83, 104`).

### Answers

- **What is the current error handling strategy in `specrew-start.ps1` for script failures?**  
  The launcher is already fail-fast. Invalid user input exits with code 1, and unexpected failures are surfaced via exceptions or explicit error messages.
- **How does session state recovery handle corrupted `.specrew/start-context.json` files?**  
  Startup currently degrades many parse failures to `$null` session state so old workspaces can still launch. F-039 cannot reuse that permissive behavior for `boundary_enforcement`; corrupt authorization state must instead block with a recovery directive.
- **What happens if enforcement hook throws exception mid-boundary-transition?**  
  The boundary must remain uncrossed. The design must throw before appending verdict history or mutating `pending_next_boundary`, and should best-effort append an error line to `.squad\log\enforcement-errors.log`.
- **Should fail-safe behavior write a sentinel value to block retry, or rely on exception propagation?**  
  Use exception propagation, not sticky sentinel state. The retry barrier is the still-unresolved underlying problem plus the unchanged boundary state, not an extra poison-pill flag.
- **How do we distinguish between transient failures (network issue) and permanent failures (hook logic bug)?**  
  Treat boundary-authorization failures conservatively: malformed boundary state, invalid verdict history, missing mirrored function, or failed atomic write are all blocking. Non-authoritative conveniences such as launch banner decoration may warn, but authorization itself never downgrades to permissive mode.

### Decision

Boundary enforcement is **fail-closed**:

- Read/parse/validation failures in `boundary_enforcement` throw.
- Authorization refusal returns a blocked result plus deterministic directive text.
- Persistence failures throw before advancing the boundary.
- A best-effort error log entry is written, but logging failure never converts the path to allow.

### Rationale

The governance promise is broken by one silent allow. A simple fail-closed rule is easier to test, easier to reason about, and consistent with Proposal 065's "mechanical teeth" framing.

### Failure-mode analysis

| Failure mode | Impact | Design response |
| --- | --- | --- |
| Corrupt `boundary_enforcement` JSON | Could silently disable the gate | Throw, write recovery directive, require repair or emergency bypass |
| Partial write after verdict accepted | State/audit divergence | Use locked atomic writes for every mutation path |
| Sentinel-based retry barrier | Sticky broken sessions and extra migration burden | Avoid sentinels; preserve previous good state and throw |
| Error log path unavailable | Loss of diagnostic detail | Still block; surface console directive that logging also failed |

---

## Research Task 4: Enforcement Event Logging Format

### Research questions (verbatim)

- What is the current `.squad/decisions.md` format (markdown structure, required fields, timestamp format)?
- How do boundary-sync entries from F-020 structure their data (frontmatter vs body)?
- Can enforcement events coexist with user verdicts and agent routing evidence in the same ledger?
- What fields are required for enforcement events (FR-004 specifies: timestamp, boundary_type, enforcement_action, launch_mode, agent_response_snippet)?
- What is the character limit for `agent_response_snippet` (spec says first 200 chars)?

### Investigation evidence

- `extensions\specrew-speckit\scripts\shared-governance.ps1:1270-1310` shows the canonical append-only writer: `## <timestamp> — <title>` followed by bullet metadata.
- `scripts\internal\sync-boundary-state.ps1:563-607` shows current boundary-sync entries using that same ledger format.
- `.squad\decisions.md:1-59` confirms the ledger already mixes incidents, directives, verdicts, and routing evidence safely.
- `specs\039-launch-mode-boundary-enforcement\spec.md:102, 127` requires FR-004 fields and the 200-character snippet cap.
- Proposal 065 adds bypass audit detail (reason, boundary, session id) for every bypassed boundary (`proposals\065-launch-mode-boundary-enforcement.md:140-147`).

### Answers

- **What is the current `.squad/decisions.md` format (markdown structure, required fields, timestamp format)?**  
  It is an append-only markdown ledger. Each entry begins with `## <UTC-seconds timestamp> — <title>`, then bullet metadata, then optional subsections such as `### Context` or `## Verdict`.
- **How do boundary-sync entries from F-020 structure their data (frontmatter vs body)?**  
  They use bullet metadata in the body, not frontmatter. That same body pattern is the right fit for enforcement events.
- **Can enforcement events coexist with user verdicts and agent routing evidence in the same ledger?**  
  Yes. The ledger already carries multiple entry types, and the generic writer is intentionally schema-light.
- **What fields are required for enforcement events (FR-004 specifies: timestamp, boundary_type, enforcement_action, launch_mode, agent_response_snippet)?**  
  Those five are mandatory. F-039 also needs optional diagnostic fields such as `Bypass Attempt Detected`, `Session ID`, `Bypass Reason`, and `Matched Verdict` when applicable.
- **What is the character limit for `agent_response_snippet` (spec says first 200 chars)?**  
  Exactly 200 characters maximum. The writer should truncate deterministically before persistence rather than trust callers.

### Decision

Use a **single structured ledger entry type** for enforcement outcomes and a companion shape for bypass history. The canonical markdown envelope stays unchanged; F-039 only standardizes the field set.

### Example entry

```markdown
## 2026-05-22T14:58:11Z — Boundary enforcement: tasks

- **Timestamp**: 2026-05-22T14:58:11Z
- **Boundary Type**: tasks
- **Enforcement Action**: blocked
- **Launch Mode**: same-window/autonomous
- **Agent Response Snippet**: `/speckit.plan -> /speckit.tasks in one turn...`
- **Bypass Attempt Detected**: true
- **Session ID**: 2026-05-22T14-58-11Z-039-launch-mode-boundary-enforcement

### Context

Boundary authorization was missing for `plan -> tasks`, so the tool call failed closed and surfaced the authorization directive.
```

### Rationale

Reusing the existing ledger keeps audit evidence human-readable, append-only, and consistent with the rest of Specrew governance. It also avoids inventing a second audit surface that would have to be reconciled with `.squad\decisions.md` later.

### Failure-mode analysis

| Failure mode | Impact | Design response |
| --- | --- | --- |
| Missing required field | Incomplete audit trail; validator blind spots | Centralize event writing in one helper that validates required fields before append |
| Snippet exceeds 200 chars | Spec violation and noisy ledger | Truncate in the writer, not at random call sites |
| Separate bypass log diverges from decisions ledger | Reconciliation burden | Keep decisions ledger as the human/audit log; keep `bypass_history` as the machine-readable mirror |

---

## Research Task 5: Emergency Bypass Mechanism

### Research questions (verbatim)

- What is the current parameter parsing strategy in `specrew-start.ps1` for switch flags and string parameters?
- How do we enforce mandatory parameter (reason) for a switch flag (bypass)?
- Should bypass be session-scoped (one flag bypasses entire session) or boundary-scoped (bypass per boundary)?
- What is the user-facing error message if `--bypass-boundary-enforcement` is invoked without `--reason "..."`?
- How do we log bypass events to `.squad/decisions.md` (separate entry type or flag on enforcement event)?

### Investigation evidence

- `scripts\specrew-start.ps1:1-31, 75-184` uses native PowerShell parameters plus `Convert-UnixStyleArguments` to normalize GNU-style flags.
- `scripts\specrew-start.ps1:3225-3243` already enforces invalid option combinations with post-parse validation and `exit 1`.
- Proposal 065 is explicit that bypass is `specrew start --bypass-boundary-enforcement --reason "<text>"` and is **session-scoped, not boundary-scoped** (`proposals\065-launch-mode-boundary-enforcement.md:140-147`).
- Spec FR-010 requires a mandatory reason and logging for emergency recovery use (`specs\039-launch-mode-boundary-enforcement\spec.md:108`).

### Answers

- **What is the current parameter parsing strategy in `specrew-start.ps1` for switch flags and string parameters?**  
  Switches are captured as booleans and string-valued options consume the next token. The same pattern can add `--bypass-boundary-enforcement` and `--reason` cleanly.
- **How do we enforce mandatory parameter (reason) for a switch flag (bypass)?**  
  Perform post-parse validation immediately after the existing option-conflict checks. If bypass is active and `--reason` is blank, print a hard error and exit 1 before any launch or state mutation.
- **Should bypass be session-scoped (one flag bypasses entire session) or boundary-scoped (bypass per boundary)?**  
  Session-scoped. That is the explicit Proposal 065 contract and intentionally discourages casual partial skipping.
- **What is the user-facing error message if `--bypass-boundary-enforcement` is invoked without `--reason "..."`?**  
  `ERROR: --bypass-boundary-enforcement requires --reason "<text>" because it disables lifecycle boundary enforcement for the entire session.`
- **How do we log bypass events to `.squad/decisions.md` (separate entry type or flag on enforcement event)?**  
  Use both layers: append an enforcement event with `Enforcement Action: bypassed` and record a machine-readable row in `boundary_enforcement.bypass_history` so validators can reconcile state to ledger.

### Decision

Implement bypass as a **session-scoped launch option with mandatory reason**:

- CLI syntax: `specrew start --bypass-boundary-enforcement --reason "<text>"`
- Launcher persists a session-level bypass record in `boundary_enforcement.bypass_history`
- Every bypassed boundary also appends a normal enforcement ledger entry showing `bypassed`
- Startup surfaces a deterministic trust-posture marker when bypass is active

### Rationale

This matches the approved proposal, keeps the operator accountable, and gives the validator enough evidence to reconcile bypassed sessions later.

### Failure-mode analysis

| Failure mode | Impact | Design response |
| --- | --- | --- |
| Missing reason | Silent privilege escalation | Hard error before session bootstrap |
| Boundary-scoped bypass | Encourages casual piecemeal skipping | Keep the entire session marked as bypassed |
| Bypass active with no persisted history | Untraceable override | Record bypass in both `start-context.json` and `.squad\decisions.md` |
| Bypass persists into next session unintentionally | Trust-posture drift | New sessions default back to enforcement unless bypass flag is passed again |

---

## Research Task 6: Proposal 038 Integration Planning

### Research questions (verbatim)

- What is the current status of Proposal 038 (candidate, approved, shipped)?
- What is the expected schema for boundary classification policy in `.specrew/config.yml`?
- How should enforcement hooks distinguish between boundary classes (lookup in config vs hardcoded list)?
- What is the MVP behavior for F-039 (all boundaries treated as human-judgment-required) vs future state (per-class policies)?
- What is the backward compatibility strategy if Proposal 038 never ships?

### Investigation evidence

- `proposals\038-adaptive-boundary-discipline.md:1-8` marks Proposal 038 as `status: candidate` and `phase: phase-2`.
- `proposals\038-adaptive-boundary-discipline.md:20-38` defines the three classes: `human-judgment-required`, `mechanical-execution`, and `strategic-progression`.
- `proposals\INDEX.md:88-90` lists 038 in the candidate section.
- `specs\039-launch-mode-boundary-enforcement\spec.md:13, 134-136` places future classification policy in `.specrew\config.yml`.
- Proposal 065 states that the MVP treats all eight/nine gated boundaries as human-judgment-required until 038 ships (`proposals\065-launch-mode-boundary-enforcement.md:189, 221`).

### Answers

- **What is the current status of Proposal 038 (candidate, approved, shipped)?**  
  Candidate; not shipped.
- **What is the expected schema for boundary classification policy in `.specrew/config.yml`?**  
  A project-level block keyed by boundary name with class and behavior, e.g. `boundary_classification_policy.<boundary>.class` plus optional overrides. The plan keeps the persisted contract simple enough that config lookup can be added later without changing verdict history shape.
- **How should enforcement hooks distinguish between boundary classes (lookup in config vs hardcoded list)?**  
  Through a policy lookup adapter. The adapter reads config when present, validates values, and otherwise returns the MVP default.
- **What is the MVP behavior for F-039 (all boundaries treated as human-judgment-required) vs future state (per-class policies)?**  
  MVP: every gated boundary is hard-stop. Future state: config may relax specific boundaries into `mechanical-execution` or `strategic-progression`, but only after Proposal 038 ships and the policy schema is approved.
- **What is the backward compatibility strategy if Proposal 038 never ships?**  
  Keep the adapter, but let its default forever return `human-judgment-required`. F-039 remains fully valid without any config block.

### Decision

Design F-039 with a **policy adapter and conservative default**:

- Persist verdicts/bypasses independently of class policy.
- Introduce a single lookup seam for future class-aware behavior.
- If config is absent, invalid, or Proposal 038 never lands, every boundary remains hard-stop.

### Rationale

This preserves today's governance guarantee while making future composition straightforward. It avoids hard-coding future behavior into the current data model.

### Failure-mode analysis

| Failure mode | Impact | Design response |
| --- | --- | --- |
| Proposal 038 never ships | Dead feature dependency | Default adapter keeps F-039 self-sufficient |
| Invalid policy config | Ambiguous runtime behavior | Fail closed to `human-judgment-required` and log config issue |
| Policy mixed into verdict history shape | Future migration complexity | Keep policy as lookup-only; histories remain stable |

---

## Phase 0 decision summary

| Task | Decision |
| --- | --- |
| Boundary detection | Structured boundary authorization is authoritative; prose is evidence-only |
| Intercept points | `specrew-start.ps1` owns preflight; skills/helpers own real boundary refusal |
| Fail-safe mechanics | Throw before advancement; never degrade to permissive mode |
| Enforcement logging | Reuse `.squad\decisions.md` append-only markdown ledger |
| Emergency bypass | Session-scoped `--bypass-boundary-enforcement --reason "..."` with mandatory audit trail |
| Proposal 038 | Policy adapter now, class-aware behavior later |
