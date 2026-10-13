# Feature Specification: beta4.1 UX stabilization

**Feature Branch**: `202-beta4-1-ux-stabilization` (branched from `24e5701a` on the beta4 line, not main)
**Created**: 2026-10-13
**Status**: Draft
**Input**: Maintainer intake of the beta4.1 findings, in two tiers (2026-10-13). Discovery and design decisions come from the completed design workshop: product-domain plus seven lenses, each closed by a typed maintainer reply with a recorded receipt. The records are under `specs/202-beta4-1-ux-stabilization/workshop/`.

## Governing UX principle

This principle ranks above every requirement below. It is the maintainer's wording, verbatim, from the ui-ux lens:

> The human provides intent (problem domain, constraints, limits), reasons with the agents about the solution, and directs and decides. The system analyzes, suggests, recommends, implements, validates, and diagnoses its own failures. The human is in the loop for approvals and on the loop for understanding, but does not run the process. A stop message is justified only when the system needs a human decision to proceed AND the human lacks the context for it. A question gets an answer, not a stop. Unchanged context needs no packet. Needing nothing from the human means no message. The packet's size follows the size of the context gap (new session, resume, compaction, external state change, long gap). Verdicts stay explicit typed replies: the system decides when to ask, only the human decides what is approved.

Quality priority for conflicts, highest first: authority integrity, cross-host parity, diagnosability, friction, latency.

## Scope

- **Tier 1 (iteration 1):** B4F-108, B4F-104, B4F-106, B4F-096, B4F-107, B4F-100, B4F-102, B4F-105, B4F-109, B4F-089, B4F-101. B4F-109 was added by the maintainer after the workshop, on 2026-10-13, when 202's own specify stop could open no crossing.
- **Tier 2 (iteration 2):** starts only after the maintainer accepts Tier 1 at the iteration-1 closeout. Green tests do not start it. It covers the narrow review-ordering slices of B4F-054/056/058/061, bounded by B4F-074 and B4F-093, and the B4F-103 package-comparison correction (no beta4 republish).
- **Out of scope (beta5):** both B4F-039 sub-findings; B4F-090; B4F-091 band semantics (B4F-107 changes presentation only); any broader review redesign; any redesign of the hook dispatcher or stores; B5F-004 (Stop reasons outside Tier 1 audited against the substance-only rule); B5F-005 (refusals that name the wrong cause when a path does not resolve); every other beta5 item.

## Host support tiers

**Context.** Specrew supports five agent hosts: Claude, Codex, Copilot, Cursor and Antigravity. Claude, Codex and Copilot cover the large majority of developers. Validating every host live on every release multiplies acceptance cost. A host claimed as supported and never validated is worse than no support, and B4F-108 is exactly that case: Codex was listed as supported, and its workshop capture was broken for five weeks without anyone noticing. Dropping Cursor and Antigravity would also be wrong. Under the architecture-core placement rule, adapters do host mechanics only and all logic runs once in the shared path, so a thin adapter is cheap to keep. More than three hosts also keeps the adapter seam honest, which is the extensibility argument behind Proposal 200, and Antigravity has real investment behind it (feature 184). This decision was agreed with the maintainer outside the workshop and added on 2026-10-13, before the specify verdict.

| Tier | Hosts | What 202 commits to |
|---|---|---|
| **Validated** | Claude, Codex, Copilot | All 202 cross-host acceptance applies: the cross-host tests through each host's real adapter with recorded real payloads (FR-024), and the live installed walk at the Tier 1 acceptance (SC-001). |
| **Experimental** (beta4.1) | Cursor, Antigravity | They keep working through the shared path. They get the adapter-contract test on recorded payloads only if such payloads already exist; otherwise they are listed as **unvalidated**. No live walk and no added scope in 202. |

- **Experimental means experimental.** This spec, and the Tier 1 acceptance evidence presented at the iteration-1 closeout, state Cursor and Antigravity as experimental, never as supported-and-validated.
- **Recorded payloads today:** no recorded hook-event payloads exist for Cursor or Antigravity. A Cursor *conversation transcript* fixture exists (`tests/bootstrap/fixtures/conversation/cursor.jsonl`), but it is not a hook payload. Both hosts are therefore listed as unvalidated for 202 unless FR-024's capture task records their payloads as a by-product. That capture is not required.
- **Coding host and reviewer host are separate roles.** Cursor and Antigravity also appear as reviewer hosts. Reviewing is a much smaller surface: run headless and deliver findings. A host can therefore later be validated as a reviewer while it is still experimental as a coding host. This is noted only; there is no 202 work on it.
- **Beta5 candidate, not 202 scope:** support tiers defined in the user docs and the installer output; coding-host and reviewer-host validation separated; a promotion rule (a host moves to Validated when someone owns its live walk and it passes two consecutive releases). Recorded as B4F-110 in docs/beta4-findings.md.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - My typed workshop replies count on every host (Priority: P1)

B4F-108: a transient journal-lock failure silently blocked every workshop receipt for five weeks. The maintainer answers workshop questions by typing on Claude, Codex or Copilot. Each typed reply is recorded as theirs, and each checkpoint closes after the same number of replies on every host. If recording cannot happen safely, they learn it in the same turn, together with whether their reply was consumed. The system recovers on its own, or asks one plain decision. Specrew's own hook text never counts as the maintainer's reply, in any state.

**Why this priority**: authority integrity and cross-host parity are the two highest quality attributes. Without this story the workshop cannot run on Codex at all, and it deadlocked silently from 2026-09-09 to 2026-10-13.

**Independent Test**: run the same workshop flow (product-domain, agenda, one lens) through each host's real adapter using recorded real hook payloads, then run the fault-injection cases a-e.

**Acceptance Scenarios**:

1. **Given** a healthy project, **When** the maintainer completes product-domain, agenda confirmation and one lens on Claude, Codex and Copilot, **Then** each host produces 3 receipts and needs exactly 1 typed reply per checkpoint.
2. **Given** another process holds the hook-output journal briefly, within the retry window, **When** the maintainer replies, **Then** the reply is recorded normally and nothing is disclosed.
3. **Given** the journal stays unavailable beyond the retry window, **When** the maintainer replies, **Then** that same turn discloses the degraded state and whether the reply was consumed. 0 turns are consumed silently.
4. **Given** a degraded state, **When** the journal accepts its next append, **Then** the degraded state clears itself, the recovery time is recorded, and the next typed reply produces a receipt.
5. **Given** two real hook processes append to the journal at the same moment, on Windows, macOS and Linux, **When** both finish, **Then** both appends succeed, lines are intact, and nothing degrades.
6. **Given** any state, healthy or degraded, **When** hook text, a Stop continuation or a host's replay of hook text arrives as a user prompt, **Then** it never produces a receipt.
7. **Given** a project upgraded with an unhealthy state left by an older version, **When** the next append succeeds, **Then** that state clears like any other degraded state.
8. **Given** self-recovery fails, **When** the system needs the maintainer, **Then** it asks one decision in plain project terms that never implies loss when nothing is lost (reference wording: "Specrew couldn't record your reply safely. May I clear the stuck error so it can record again? Nothing is deleted."), and records the receipt of the approving reply with the recovery action.

---

### User Story 2 - Stops only when I have a decision to make (Priority: P1)

B4F-104, B4F-106, B4F-096, B4F-100. The maintainer sees a boundary packet when a context gap means they need it, not on every turn. A question they ask gets an answer. A missing deterministic line, such as the dials line, is filled in by the system and never costs them a cycle. The orientation always comes before the first question of a session. Tightening a sentence in a saved packet never blocks a reply.

**Why this priority**: these are the measured friction findings. Each produced stops or corrective exchanges that carried no decision.

**Independent Test**: replay each recorded trigger through the real adapters and count real decisions, corrective exchanges and extra stops before and after.

**Acceptance Scenarios**:

1. **Given** a pending crossing presented once this session, **When** the maintainer asks a side question, gives a wrong verdict or asks for orientation (the three recorded B4F-104 triggers), **Then** the reply answers them. The pending decision appears at most as a brief mention, with 0 packet repaints and 0 `Stop hook error` lines.
2. **Given** an unchanged pending crossing, **When** a context gap occurs (new session, resume, compaction, external state change, long gap), **Then** the packet is presented again, sized to that gap.
3. **Given** a reply omits the dials line or other deterministic orientation facts, **When** the turn ends, **Then** the system supplies them as marked system output, records them in the hook-output journal, and blocks nothing (B4F-106: 0 human-visible cycles).
4. **Given** a new session whose first message carries a request, **When** the first question is asked, **Then** the orientation has already been shown (B4F-096: the maintainer never answers a question before seeing it).
5. **Given** a saved turn draft, **When** the agent tightens wording but keeps every declared meaning-bearing line (headings, review-target links, question line, approval line, verdict options, marker), **Then** the turn is not blocked (B4F-100).
6. **Given** a declared meaning-bearing line is missing from the reply, **When** the turn ends, **Then** the check names that line. Substance is still enforced.

---

### User Story 3 - The same adaptation text on every host (Priority: P2)

B4F-107: the maintainer sees the same plain sentence about how Specrew adapts to them, whatever the host. It never shows numbers or internal keys.

**Why this priority**: it is a cross-host parity defect with a readability cost. There is no separate stop cost.

**Independent Test**: render the adaptation text through each real adapter for the same profile and compare the bytes.

**Acceptance Scenarios**:

1. **Given** one user profile, **When** Claude, Codex and Copilot render the adaptation text, **Then** the sentence is byte-identical, except for the host's own reference to the correction command.
2. **Given** any host, **When** the adaptation is shown, **Then** no numeric value or internal key such as `software_architecture=10` appears.

---

### User Story 4 - One answer to "what are we working on", and a resume from disk (Priority: P2)

B4F-105, B4F-109, B4F-089: status, orientation and resume name the same current feature. A new feature's specify boundary opens normally after a previous feature closed in the same worktree. A resume says where the work stands from what is on disk, not from an older narrative.

**Why this priority**: during this intake, four records gave four different answers, and the session had to ignore two of them.

**Independent Test**: build project states with a branch switch, a stale pointer and an interrupted session, then compare status, orientation and resume output.

**Acceptance Scenarios**:

1. **Given** a pointer written for the current branch, **When** status, orientation or resume run, **Then** all three name that feature.
2. **Given** a pointer written for a different branch, **When** a reader runs, **Then** it treats the pointer as stale, reconciles from the branch and the in-flight work, and says which record won and why.
3. **Given** a Shipped or closed feature and an in-flight one, **When** status runs, **Then** the Shipped feature is never shown as active.
4. **Given** two in-flight features that genuinely compete, **When** a reader cannot choose from evidence, **Then** it asks the maintainer, and only then.
5. **Given** a handover narrative older than the ledger, or naming another feature, **When** a session resumes, **Then** the "where we are / starting now" lines come from the pending crossing, the commits since the handover's `from_commit`, and progress. The narrative is shown only as context with its age, and is flagged.
6. **Given** any writer that creates or advances a feature, **When** it completes, **Then** the pointer names that feature and the branch.
7. **Given** a worktree whose last authorized boundary is a previous feature's feature-closeout, **When** a new feature's specify sync runs, **Then** a scoped specify crossing for the new feature is opened. The maintainer's typed `approved for specify` is captured through the normal path, and the closed feature's history neither authorizes nor blocks the new feature (B4F-109).

---

### User Story 5 - A refusal tells the agent the step that fixes it (Priority: P2)

B4F-102: when a gate refuses because an artifact is missing, the refusal names the step that produces it, and the system performs that step where it can.

**Why this priority**: in the 2026-09-14 walk the coordinator spent four minutes reading module internals before drafting the artifact.

**Independent Test**: trigger the design-analysis gate with the artifact missing, and assert that the refusal names the producing step.

**Acceptance Scenarios**:

1. **Given** a plan-stage gate refusal for a missing `design-analysis.md`, **When** it is shown, **Then** it names the action that produces the artifact, not only the missing path.

---

### User Story 6 - Turn drafts never leak into commits (Priority: P3)

B4F-101: the agent's saved reply drafts live in an ignored per-session location, which the saving script resolves itself.

**Why this priority**: it is internal mechanics with a small but real risk that a draft is swept into a boundary commit.

**Independent Test**: save drafts from two concurrent sessions, then check git status and confirm that neither overwrote the other.

**Acceptance Scenarios**:

1. **Given** two concurrent sessions, **When** each saves a draft without passing a path, **Then** the drafts land in separate ignored per-session locations and neither is overwritten.
2. **Given** any host, **When** the agent saves a draft, **Then** it never needs to know its session id or folder name.

---

### User Story 7 - Review ordering stops making the human accept twice (Priority: P3, Tier 2)

B4F-054/056/058/061, bounded by B4F-074 and B4F-093, plus B4F-103. Specrew's own records, such as the iteration seal and the reviewer scaffold output, are not counted as product changes that invalidate review coverage. The package comparison checks only the declared content scope.

**Why this priority**: it is Tier 2 and starts only after the maintainer accepts Tier 1.

**Independent Test**: defined at iteration-2 design analysis, within the bounds stated here.

**Acceptance Scenarios**:

1. **Given** an iteration seal or other Specrew-owned record written after review, **When** coverage is evaluated, **Then** it is not counted as uncovered source drift (B4F-093).
2. **Given** the exact-byte package check, **When** it compares a published package, **Then** it compares only the declared content scope: NuGet-dropped zero-byte placeholders and the publish-stamped manifest lines are excluded, or the package stops shipping placeholders. No beta4 republish (B4F-103).

### Edge Cases

- The journal stays unavailable and the outage-buffer write also fails. Only that one turn fails closed, and it is disclosed in the same turn with its consumed status.
- A host replays hook text with no distinguishing field (for example Copilot 1.0.79). Origin is `unknown`, so it cannot produce a receipt, and the journal and buffer match still applies to every reply. Each adapter's `unknown` rule is verified against captured payloads so that typed replies on that host are not all blocked.
- Product records exist before any receipt (the line-485 refusal observed in B4F-108). This is preserved as an observation. Recovery uses the governed path, never hand edits.
- A branch switch in a worktree whose untracked pointer was written for another branch.
- A resume after an interrupted turn whose Stop never rewrote the handover narrative.
- A context gap from an external state change while a crossing is pending.
- A host cannot resolve the per-session draft path reliably. This is raised at design-analysis and never becomes a run-time stop.

## Requirements *(mandatory)*

### Functional Requirements

**Tier 1 - authority capture and parity (B4F-108)**

- **FR-001**: The hook-output journal MUST accept concurrent appends from separate hook processes without failure or torn lines. A share mode that permits concurrent appends is preferred. A per-write cross-process lock on that journal only is permitted when fault-injection case (e) shows the share mode alone is insufficient.
- **FR-002**: A failed journal append MUST be retried within a bounded window as a backup. Only a failure that persists past it enters a degraded state.
- **FR-003**: The degraded state MUST clear on the next successful append and record its recovery time. An unhealthy state left by an older version MUST be treated the same way.
- **FR-004**: While degraded, hook output that cannot be journaled MUST be recorded as hashes in per-process outage-buffer files. The integrity check MUST read them before the next prompt decision, and they MUST be flushed into the journal and removed on recovery.
- **FR-005**: A typed reply MUST be refused as authority only when it matches journaled or buffered hook output. If the buffer write itself fails, only that turn fails closed.
- **FR-006**: Each host adapter MUST normalize its host's payload into a standard turn record (event, typed user text, host, origin) under a declared, tested contract. Origin MUST be one of typed-user, host-injected or unknown. Only typed-user can produce a receipt, and the journal and buffer match MUST apply to every reply.
- **FR-007**: A degraded state MUST be disclosed in the affected turn, stating whether the reply was consumed. It MUST also appear in `specrew status` / `where` while degraded, and in session-start orientation.
- **FR-008**: A health journal MUST record each transition (class, error text, first-seen, count, recovered-at) with hashes only and no user text.
- **FR-009**: When self-recovery fails, the system MUST ask the maintainer one decision, in project terms that pass the banned-noun check and never imply loss when nothing is lost. The recovery action MUST record the receipt of the approving reply.
- **FR-010**: A refusal MUST name the actual cause and never attribute a reply to a channel the maintainer did not use.

**Tier 1 - stops and presentation (B4F-104, B4F-106, B4F-096, B4F-100)**

- **FR-011**: An unchanged pending crossing MUST be presented in full once per session and again only after a context gap. In between, the pending decision MAY appear at most as a brief mention inside a reply that answers the maintainer, and MUST NOT produce a `Stop hook error`.
- **FR-012**: The Stop hook MUST NOT block a reply over formatting. It checks substance only: that a needed decision is clear, and that authority is intact.
- **FR-013**: Deterministic text the system can supply, such as the dials line and orientation facts, MUST be filled in by the system, marked as system output, and recorded in the hook-output journal, with 0 human-visible cycles.
- **FR-014**: The orientation MUST reach the maintainer before the first question of a session. The mechanism is chosen at design-analysis.
- **FR-015**: The "presented" check MUST compare a meaning-bearing line set declared once in the shared path: headings, review-target links, question line, approval line, verdict options and marker. It MUST NOT compare the whole draft.

**Tier 1 - adaptation, context, refusals, drafts (B4F-107, B4F-105, B4F-089, B4F-102, B4F-101)**

- **FR-016**: The adaptation text MUST be one shared sentence, identical on every host and with no numbers or keys. Only the correction-command reference comes from the adapter.
- **FR-017**: `.specrew/start-context.json` MUST be the single current-feature pointer, MUST record the branch it was written for, and MUST be updated by every writer that creates or advances a feature.
- **FR-018**: When the pointer's branch differs from the current branch, readers MUST treat it as stale, reconcile from the branch and the in-flight work, and disclose the reconciliation. They MUST ask only when two in-flight features genuinely compete. A Shipped or closed feature MUST never be shown as active while one is in flight.
- **FR-019**: The resume "where we are / starting now" lines MUST come from disk only: the pending crossing, `from_commit..HEAD`, and progress. The handover narrative MUST be shown only as context with its age, and flagged when it is stale or names another feature.
- **FR-020**: A gate refusal for a missing artifact MUST name the step that produces it.
- **FR-021**: Turn drafts MUST be saved to an ignored per-session location that the saving script resolves itself. The three skills MUST name it.
- **FR-026**: `feature-closeout -> specify` for a new feature MUST be treated as a cycle reset, like `iteration-closeout -> plan`, in both the crossing calculation and the authorization writer. The new feature's specify sync MUST open a scoped specify crossing, and a closed feature's history MUST NOT authorize or block another feature's boundaries (B4F-109).

**Tier 2 (iteration 2, after Tier 1 acceptance)**

- **FR-022**: Specrew-owned records written after review, such as the iteration seal and the reviewer scaffold output, MUST NOT count as uncovered source drift. The exact review-ordering slices of B4F-054/056/058/061 are set at iteration-2 design analysis, within the bounds of B4F-074 and B4F-093, and approved there. No broader review redesign.
- **FR-023**: The exact-byte package check MUST compare only the declared content scope (B4F-018's rule). No beta4 republish.

**Test evidence**

- **FR-024**: Real hook payloads from Claude, Codex and Copilot MUST be captured as test fixtures, in scratch directories only and never in a governed worktree. The cross-host tests MUST run through each host's real adapter with those payloads, never by calling the shared path directly.
- **FR-025**: The B4F-108 fault-injection suite MUST cover cases a-e (a: lock released within the retry window; b: lock held beyond it; c: recovery; d: hook output never counts; e: two real processes appending at once), with case (e) on Windows, macOS and Linux.

### Traceability & Governance Requirements *(mandatory)*

- **TG-001**: Each user story MUST map to one or more functional requirements (table below).
- **TG-002**: Each requirement MUST identify expected owner role(s) (table below).
- **TG-003**: Each requirement MUST identify intended iteration or delivery window (table below).
- **TG-004**: Any known spec/implementation conflict MUST include an explicit reconciliation path. The known conflicts are:
  - the 199 concurrency rule, reconciled by the scoped exception in implementation-rules.yml;
  - the ruled B4F-101 single draft path, superseded by the per-session path in the data-storage lens;
  - B4F-100's original line set, which now includes the verdict options.

| Story | Findings | Requirements | Owner roles | Iteration |
|---|---|---|---|---|
| US1 | B4F-108 | FR-001 to FR-010, FR-024, FR-025 | Implementer; Reviewer (codex); maintainer for the live walk | 1 |
| US2 | B4F-104, B4F-106, B4F-096, B4F-100 | FR-011 to FR-015, FR-024 | Implementer; Reviewer | 1 |
| US3 | B4F-107 | FR-016, FR-024 | Implementer; Reviewer | 1 |
| US4 | B4F-105, B4F-109, B4F-089 | FR-017 to FR-019, FR-026 | Implementer; Spec Steward (pointer and cycle-reset contract) | 1 |
| US5 | B4F-102 | FR-020 | Implementer | 1 |
| US6 | B4F-101 | FR-021 | Implementer | 1 |
| US7 | B4F-054/056/058/061 (bounded by 074, 093), B4F-103 | FR-022, FR-023 | Implementer; Reviewer; maintainer approves the slice | 2 |

### Key Entities

- **Standard turn record**: what an adapter produces from a host event. Fields: event, typed user text, host, origin (typed-user / host-injected / unknown).
- **Hook-output journal**: hashes of Specrew's own output, used to keep that output from counting as a human reply.
- **Outage buffer**: per-process files of hook-output hashes written while the journal is unavailable. Flushed and removed on recovery.
- **Health journal**: one record per degraded/recovered transition. Hashes only.
- **Workshop receipt**: the hook-owned record that a typed reply answered a specific workshop question.
- **Current-feature pointer**: `start-context.json`. The active feature, last authorized boundary, pending item, and the branch it was written for.
- **Meaning-bearing line set**: the declared lines the "presented" check compares.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: On Claude, Codex and Copilot, the flow of product-domain, agenda and one lens yields 3 receipts and exactly 1 typed reply per checkpoint, in tests through real adapters and in a live installed walk. Codex is walked on a healthy worktree.
- **SC-002**: Under every injected journal fault, 0 hook outputs count as a human reply, and 0 turns are consumed without same-turn disclosure.
- **SC-003**: Every Tier 1 scenario shows 0 corrective exchanges and 0 extra stops after the fix, with the number of real decisions unchanged. Baselines:
  - B4F-106: 1 corrective cycle.
  - B4F-096: 1 corrective exchange and 1 extra stop.
  - B4F-108 Codex: the checkpoint never closed.
  - B4F-108 Claude: 1 corrective round.
  - The 2026-09-09 to 2026-10-13 outage: not captured.

  A missing measurement is recorded as not captured, never zero, and after-fix values come only from real runs.
- **SC-004**: For B4F-104, after the first presentation in a session, each of the three recorded triggers produces 0 packet repaints and 0 `Stop hook error` lines.
- **SC-005**: The adaptation text is byte-identical across the three hosts, apart from the correction-command reference.
- **SC-006**: Status, orientation and resume name the same feature in every constructed state, including a branch switch and a stale pointer. A second feature's specify sync in a worktree whose previous feature closed opens a crossing, and the verdict is captured with 0 out-of-band authorizations.
- **SC-007**: Every Tier 1 refusal path names its actual cause and one recovery action.
- **SC-008**: The validator run at iteration-1 closeout shows no new failures in the known-baseline categories below.

## Known validator baseline

These historical validator failures pre-date 202 and are not caused by it:

- review-evidence findings;
- defer-provenance findings;
- the 198/011 needs-rework verdict.

New failures in those categories are compared against this baseline. Any failure outside it is a regression owned by 202.

## Assumptions

- The stack is unchanged: PowerShell 7.x, Markdown, YAML and JSON. No new dependency is added (code-implementation lens).
- The craft rules are inherited from the 199 manifest, with the 202 amendments in `implementation-rules.yml`. Before each implement phase the branch is synced with the beta4 line `origin/201-first-run-experience`, not main. The main merge is a separate maintainer decision.
- The existing layered hook structure is kept: adapters, dispatcher, shared engines, stores. Fixes live in the shared path, and adapters own only input normalization and output emission.
- Codex has not yet been tested on a healthy worktree (research-needed, not load-bearing). Its parity is unproven, not shown broken.
- The retry window, attempt count and orientation-ordering mechanism are tuning and design choices for the plan and design-analysis.
- Reviews run on codex in disposable external worktrees. Its file-delivery quirk (empty stdout, findings in `.review/findings.jsonl`, a possible partial label) is not a review failure.

## Governance Alignment *(mandatory)*

- **Spec Steward**: the spec-steward role. The maintainer owns scope.
- **Iteration Facilitator**: the coordinator session for 202, under the maintainer's boundary verdicts.
- **Capacity Model**: two iterations, one per tier. Iteration 2 starts only after the maintainer's explicit Tier 1 acceptance at the iteration-1 closeout.
- **Drift Signals**: the intake drift log (`workshop/intake-drift-log.md`), then the feature drift log from plan onward; workshop bindings reconciled across lenses; the validator compared against the known baseline; continuous co-review on codex.
- **Human Oversight Points**: every lifecycle boundary needs an explicit typed `approved for <boundary>`. The iteration-1 closeout verdict is the Tier 1 acceptance. Every recovery action that needs a decision is asked as one plain question.
