# Feature Specification: Full Antigravity Refocus

**Feature Branch**: `184-full-antigravity-refocus`  
**Created**: 2026-06-17  
**Status**: Draft - iteration 002 specify approved; awaiting plan boundary
**Input**: User description: "Complete Antigravity refocus support as the continuation of F-183"

## Product-Domain Summary

- **Depth**: standard (feature_standalone)
- **users_stakeholders**: Primary users are downstream Specrew users running Antigravity via `agy`, plus Specrew maintainers validating host parity.
- **pain_job**: Antigravity has bounded Specrew support but not full refocus parity; known carry-forward edges are the self-marker concurrency false-positive and missing per-session refocus state/anchor.
- **mvp**: Fix both known edges, map B3 boundary-cross refocus onto Antigravity `PreInvocation`, preserve F-183 behavior, run manual `agy` validation including exit and re-entry, then proceed through beta and stable release gates if evidence passes.
- **out_of_scope**: No unrelated host parity fixes; no parallel Antigravity-only refocus system unless discovery proves reuse cannot work; no parity claim without real-host proof.
- **constraints**: Reuse existing refocus machinery and preserve F-183 bootstrap, Stop handover, resume, and real conversation-id behavior.
- **Follow-up research**: Discovery spike must confirm whether Antigravity `PreInvocation` has a fresh enough boundary cursor before a turn and whether B3 can be mapped without a larger host-model rewrite.
- Full record: see `workshop/product-domain.md` and `workshop/product-domain.yml`.

## Clarifications

### Session 2026-06-17

- **Docs parity sequencing**: FR-008 means documentation depth parity, not an
  unearned support-status flip. Antigravity docs may be authored to the same
  depth and discoverability level as other hosts before final proof, but every
  host matrix/status/release label MUST remain evidence-gated by FR-009 until
  real-host `agy` validation passes.
- **Falsifiable split guard**: The discovery spike must produce a PASS/FAIL row
  for each split-guard trigger. The feature MUST stop for a human split/defer
  verdict if any trigger fails: `PreInvocation` cannot see or derive a fresh
  enough lifecycle boundary cursor before the model turn; B3 cannot be emitted
  exactly once through `PreInvocation` `injectSteps` using existing dedupe and
  breaker behavior; or the implementation requires changing shared host-model
  contracts in a way that alters non-Antigravity host behavior rather than a
  bounded Antigravity manifest/adapter/state/helper change.
- **Branch and release topology**: F-184 stacks on the accepted F-183 work and
  releases together with it. There is no standalone F-183 beta or stable
  release; the next beta covers the combined F-183 + F-184 Antigravity support
  after F-184 review evidence passes, and stable remains blocked by the
  legacy-upgrade/config-migration release gate.
- **Governance validation**: The specify packet for `specs/184` has passed the
  local specify preflight checks: lens records complete, product-domain record
  valid, implementation-rules manifest valid, Markdown clean for the feature
  packet, placeholder scan clean, whitespace diff check clean, and the
  feature-specific specify-boundary lens gate returned valid.

## Design Workshop Summary

The specify workshop completed these lenses:

- **product-domain**: F-184 completes F-183 Antigravity support; the MVP fixes
  the two known edges, maps B3 onto `PreInvocation`, and requires real `agy`
  proof before any full parity claim.
- **architecture-core**: Reuse the existing refocus architecture; isolate
  Antigravity behavior in bounded host adapter/state changes; stop if B3
  requires a broad host-model refactor.
- **component-design**: Reuse dispatcher, host manifest, state accessor,
  classification, B3, dedupe, breaker, bootstrap, and handover components; add
  only a small focused helper if needed.
- **data-storage**: Use `.specrew/runtime/refocus-state-<session>.json` through
  `SessionStateAccessor`, keyed by the real sanitized Antigravity
  `conversationId`; never global `unknown`.
- **integration-api**: Use `.agents/hooks.json`; `PreInvocation` is the primary
  bootstrap/B3 injection carrier; `Stop` is the handover carrier; `PostToolUse`
  is observed but not injection-safe with `injectSteps`.
- **observability-resilience**: Fail open, warn loudly, record bounded evidence,
  and avoid full prompt/transcript logging.
- **devops-operations**: Users run `agy`; Specrew deploys/removes hooks through
  `deploy-refocus-hooks.ps1 -HostKind antigravity`; docs include
  `/permissions` and `enableTerminalSandbox`.
- **requirements-nfr**: Full support requires measurable real-host proof, state
  correctness, B3 precision, config preservation, docs parity, and
  beta-before-stable release discipline.
- **ui-ux**: No app UI; user-facing UX is docs, host matrix, status/help,
  permission, disable, recovery, and evidence wording.
- **code-implementation**: Use existing Specrew PowerShell/JSON/YAML/Pester
  patterns and no new dependency by default.

Full records are under `workshop/`; implementation craft rules are captured in
`implementation-rules.yml`.

## Iteration 002 Amendment: Persistent Host Instructions and Workshop Speedup

### Context

Iteration 001 delivered Antigravity refocus behavior and was closed at
`abf18b99`. Manual dogfood after the retro showed that Antigravity full parity
is not yet achieved. The remaining parity slice is not more B3 plumbing; it is
the durable host-instruction and weak-model-driving path that makes a raw host
session follow Specrew before the model starts improvising.

### Product-Domain Delta

- **Users and stakeholders**: Same as F-184 overall: downstream Specrew users
  launching Antigravity/Codex-style hosts directly, plus maintainers validating
  host parity.
- **Pain/job**: AI host agents are not focused on the Specrew process,
  especially the workshop. Multiple manual tests showed hosts doing raw Spec Kit
  work instead of the governed Specrew workshop, and it takes too much prompt
  time and effort for the host to discover the correct next step. Weak models
  are especially sensitive: Opus reached the workshop slowly; Gemini Flash was
  effectively undrivable in the manual dogfood.
- **MVP**: Deploy a persistent Specrew coordinator instruction section to each
  host's manifest-declared `InstructionsFile` during `specrew init`; front-load
  the bootstrap with the immediate action; place a prominent anti-raw-Spec-Kit
  guard in both the persistent file and bootstrap; preserve user-owned
  instruction-file content; refresh/heal through `specrew update` and
  `specrew start`; keep host-neutral shared core; validate with real
  Antigravity Opus and Flash runs.
- **Out of scope**: Feature-closeout, release, beta/stable promotion, general
  host-instruction overhaul beyond the manifest-driven file path, and any new
  release claim before iteration 002 evidence lands.

Full iteration-local workshop records are under
`iterations/002/workshop/`, with applicability captured in
`iterations/002/lens-applicability.json`.

### User Stories Added For Iteration 002

#### User Story 6 - Persistent Host Instructions Exist After Init (Priority: P1)

As a downstream Specrew user who runs a host directly after `specrew init`, I
want the host's persistent instruction file to contain the Specrew coordinator
contract so the model knows to drive the governed lifecycle even on the
hook-only path.

**Independent Test**: Run `specrew init` in a scratch project with host
manifests declaring `InstructionsFile` paths. Verify the Specrew-owned section
exists in the correct file, includes the coordinator and anti-raw-workflow
guard, and preserves pre-existing user content.

#### User Story 7 - Bootstrap Front-Loads The Governed Next Action (Priority: P1)

As a Specrew maintainer validating weak hosts, I want the bootstrap to lead with
the immediate Specrew action and explicit "do not run raw Spec Kit workflow"
guard so weaker models reach the workshop quickly and do not shell out to
`specify.exe workflow`.

**Independent Test**: Launch real-host Antigravity with Opus 4.6 and Gemini
Flash after the change. Opus should reach workshop faster than the iter-001
manual dogfood path; Flash should follow the governed workshop and not run
`specify.exe workflow`. If Flash still cannot drive the lifecycle, the evidence
must keep the weak-model caveat explicit.

#### User Story 8 - Host-Neutral Instruction Delivery Stays Bounded (Priority: P2)

As a Specrew maintainer, I want persistent instruction delivery to read host
locations from host manifests and merge Specrew-owned sections without
hardcoding Antigravity or `agy` in shared core so the host-coupling firewall
remains meaningful.

**Independent Test**: Run the host-coupling firewall plus focused instruction
deployment tests. Shared core must use manifest-declared `InstructionsFile`
data, and user-owned instruction-file content must survive init/update/start
heal.

### Functional Requirements Added For Iteration 002

- **FR-011**: `specrew init` MUST deploy a persistent Specrew coordinator
  instruction section to every supported host's manifest-declared
  `InstructionsFile`, including `AGENTS.md` for Codex/Cursor/Antigravity CLI,
  `CLAUDE.md` for Claude, and `.github/copilot-instructions.md` for Copilot.
- **FR-012**: Persistent instruction deployment MUST preserve user-owned file
  content by merging a clearly delimited Specrew-owned section instead of
  clobbering the whole file.
- **FR-013**: The persistent instruction section and bootstrap text MUST
  prominently include: "You are the Specrew Crew coordinator. Drive the
  lifecycle via the design-workshop skill and the per-boundary speckit
  slash-commands. Do NOT run the raw specify.exe workflow / bundled SDD engine
  - it bypasses the governed boundary gates."
- **FR-014**: Bootstrap orientation MUST front-load the immediate next Specrew
  lifecycle action before broader explanatory context, with special attention to
  getting a new feature request to the product-domain/design-workshop path
  quickly.
- **FR-015**: Instruction delivery MUST remain host-neutral in shared core:
  file locations come from host manifests, not shared-core Antigravity or `agy`
  literals.
- **FR-016**: `specrew update` MUST refresh the managed instruction section from
  the packaged source, and `specrew start` MUST be able to heal or refresh a
  missing/stale managed section without becoming the only deployment path.
- **FR-017**: Real-host Antigravity validation MUST rerun the manual dogfood on
  Opus 4.6 and Gemini Flash. Opus evidence must compare time-to-workshop against
  iter-001 behavior; Flash evidence must verify it follows the workshop and does
  not shell out to `specify.exe workflow`, or explicitly preserve the weak-model
  caveat if it still cannot.
- **FR-018**: Persistent instruction content MUST come from one packaged static
  Specrew coordinator template or fragment included in the module package list,
  so host instruction files and bootstrap guard wording do not drift.

### Success Criteria Added For Iteration 002

- **SC-011**: A scratch `specrew init` creates or updates each supported host's
  manifest-declared `InstructionsFile` with the Specrew-owned coordinator
  section.
- **SC-012**: Pre-existing user-authored content in `AGENTS.md`, `CLAUDE.md`,
  `.github/copilot-instructions.md`, or another manifest-declared instruction
  file remains byte-for-byte unchanged outside the Specrew-owned section after
  init/update/start-heal.
- **SC-013**: The coordinator section and bootstrap contain the exact anti-raw
  `specify.exe workflow` guard from FR-013.
- **SC-014**: Tests prove shared core reads `InstructionsFile` from host
  manifests and the host-coupling firewall remains green for `agy` and
  Antigravity shared-core literals.
- **SC-015**: Bootstrap content places the immediate lifecycle action above
  slower context, and regression tests pin that ordering.
- **SC-016**: Opus 4.6 real-host evidence reaches the design workshop faster
  than the iter-001 manual path or records a concrete reason it could not be
  measured.
- **SC-017**: Gemini Flash real-host evidence follows the governed workshop and
  does not invoke `specify.exe workflow`; if not achieved, the evidence and
  status text keep the weak-model caveat.
- **SC-018**: Feature status and release text continue to say full Antigravity
  parity is caveated until iteration 002 evidence lands, and release
  carry-forwards remain open: beta-before-stable,
  `MigrateLegacyTopLevelEventMap`, and reproducible or explicitly machine-local
  `agy` evidence.
- **SC-019**: `specrew update` refreshes changed managed instruction content,
  and `specrew start` heals a missing or stale managed section without
  clobbering user content.
- **SC-020**: `Specrew.psd1` `FileList` includes any new instruction
  template/fragment and deploy helper, and package validation proves those files
  exist.

### Iteration 002 Traceability Summary

| Story | Functional Requirements | Success Criteria |
| --- | --- | --- |
| US6 | FR-011, FR-012, FR-016, FR-018 | SC-011, SC-012, SC-019, SC-020 |
| US7 | FR-013, FR-014, FR-017, FR-018 | SC-013, SC-015, SC-016, SC-017, SC-018 |
| US8 | FR-015, FR-012, FR-016, FR-018 | SC-012, SC-014, SC-018, SC-019, SC-020 |

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Antigravity Uses Real Per-Session Refocus State (Priority: P1)

As a downstream Specrew user running `agy`, I want Antigravity to use the same
per-session refocus state and anchor model as other hosts so that exit/re-entry
and refocus decisions do not collapse into a global or stale state key.

**Why this priority**: This closes Edge 2 from F-183 and is foundational for
all other full-refocus behavior.

**Independent Test**: Run a real `agy` session, exit, resume with
`agy --conversation <id>`, and verify the same sanitized conversation identity
uses a per-session refocus state file with no global `unknown`.

**Acceptance Scenarios**:

1. **Given** an Antigravity `PreInvocation` payload with `conversationId`, **When**
   Specrew normalizes the event, **Then** the refocus state key is the sanitized
   real conversation id and not `unknown`.
2. **Given** an Antigravity session has an existing refocus anchor, **When** the
   user exits and resumes with the same conversation, **Then** the anchor remains
   associated with that conversation and is available before the next turn.

---

### User Story 2 - B3 Refocus Fires Only On Real Boundary Crossings (Priority: P1)

As a downstream Specrew user, I want Antigravity to inject B3 refocus at the
right lifecycle boundary so that I get the mandatory context when crossing a
boundary, but not on every ordinary turn.

**Why this priority**: This is the core "full refocus" behavior missing from the
bounded F-183 Antigravity support.

**Independent Test**: Run a real-host `agy` scenario that crosses a Specrew
boundary and one that does not; verify `PreInvocation` injects only for the real
boundary crossing.

**Acceptance Scenarios**:

1. **Given** an Antigravity session crosses a Specrew lifecycle boundary,
   **When** the next `PreInvocation` hook fires, **Then** Specrew injects the B3
   refocus payload once through Antigravity `injectSteps`.
2. **Given** an Antigravity session continues without a boundary change,
   **When** `PreInvocation` fires, **Then** Specrew does not inject B3 and does
   not advance dedupe/breaker state incorrectly.

---

### User Story 3 - Antigravity No Longer Reports Its Own Marker As Competition (Priority: P2)

As a downstream Specrew user, I want same-worktree concurrency warnings to
distinguish a real competing session from Antigravity's own session marker so
that normal `agy` turns do not produce false advisory noise.

**Why this priority**: This closes Edge 1 from F-183 and removes a visible
trust issue from normal Antigravity usage.

**Independent Test**: Run a real `agy` session with the session marker present
and verify no self-marker concurrency advisory appears; then simulate or run a
real competing session and verify the advisory still appears.

**Acceptance Scenarios**:

1. **Given** the current Antigravity session owns the active marker, **When**
   `PreInvocation` checks same-worktree state, **Then** no concurrency advisory
   is emitted for that marker.
2. **Given** a different active session owns the worktree marker, **When**
   Antigravity starts a turn, **Then** Specrew emits the existing concurrency
   advisory.

---

### User Story 4 - F-183 Antigravity Bootstrap, Stop, And Resume Continue To Work (Priority: P2)

As a downstream Specrew user, I want the existing Antigravity bootstrap, Stop
handover, and welcome-back resume behavior to keep working while full refocus is
added.

**Why this priority**: F-184 is a completion of F-183, not a replacement; it
must not regress the bounded behavior already manually proven.

**Independent Test**: Run a real `agy` session that verifies bootstrap
injection, `Stop` handover, exit, and resume after the F-184 changes.

**Acceptance Scenarios**:

1. **Given** a fresh Antigravity session in a Specrew project, **When** `agy`
   starts and `PreInvocation` fires, **Then** Specrew bootstrap context is still
   available.
2. **Given** an Antigravity session stops, **When** the `Stop` hook fires,
   **Then** handover is saved through the existing handover path.
3. **Given** the user resumes an Antigravity conversation, **When** the session
   restarts, **Then** Specrew presents welcome-back/resume context without
   provider launch errors.

---

### User Story 5 - Antigravity Is Documented And Released At Host-Parity Level (Priority: P3)

As a Specrew maintainer or downstream user, I want Antigravity docs, host matrix,
disable/permissions guidance, and release evidence to match other hosts so that
the support claim is understandable and honest.

**Why this priority**: Full support is incomplete if users cannot discover,
enable, disable, or verify it at the same level as other hosts.

**Independent Test**: Review README/getting-started/host docs and release
artifacts for `agy`, deploy/remove commands, `/permissions`,
`enableTerminalSandbox`, evidence labels, beta-before-stable, and legacy-upgrade
validation.

**Acceptance Scenarios**:

1. **Given** a user reads the host matrix, **When** they look for Antigravity,
   **Then** it appears at the same level as other hosts with accurate verified
   status.
2. **Given** a user wants to disable Specrew Antigravity hooks, **When** they
   follow docs, **Then** they can remove Specrew hooks without losing user-owned
   `.agents/hooks.json` entries.
3. **Given** maintainers prepare a release, **When** they reach the release
   gate, **Then** beta occurs before stable and stable remains blocked until
   legacy-upgrade/release validation passes.

### Edge Cases

- Antigravity omits or changes `conversationId`: Specrew must fail loud through
  bounded warnings, avoid global `unknown`, and refuse full parity evidence.
- `PreInvocation` fires before the boundary cursor is fresh: stop for a human
  split/defer decision if B3 cannot be mapped within the bounded adapter/state
  slice.
- `PostToolUse` fires and sees `injectSteps`: Specrew must not use this path
  unless a valid output schema is separately proven.
- Existing `.agents/hooks.json` contains user hooks: deploy/remove must preserve
  non-Specrew entries.
- Hook launcher or dispatcher fails: Antigravity must continue running,
  warnings must be actionable, and users should be directed to `specrew start`
  or hook redeploy where appropriate.
- Same-worktree marker belongs to the current Antigravity session: no
  concurrency advisory should appear.
- Same-worktree marker belongs to another session: the existing concurrency
  advisory should still appear.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Antigravity hook input MUST normalize the real `conversationId`
  into the existing Specrew session identity model and MUST NOT use a global
  `unknown` state key.
- **FR-002**: Antigravity refocus MUST use the existing `SessionStateAccessor`
  and `.specrew/runtime/refocus-state-<session>.json` model for boundary cursor,
  anchor/context metadata, dedupe, breaker, and journal data.
- **FR-003**: Antigravity B3 refocus MUST be mapped onto `PreInvocation`
  `injectSteps` and MUST fire only on real lifecycle boundary crossings.
- **FR-004**: Specrew MUST distinguish Antigravity's own active marker from a
  real competing same-worktree session while preserving real concurrency
  advisory behavior.
- **FR-005**: F-184 MUST preserve F-183 Antigravity bootstrap injection, `Stop`
  handover, exit/re-entry welcome-back resume, and real conversation-id behavior.
- **FR-006**: Antigravity hook failures MUST fail open for the host session and
  emit bounded, actionable diagnostics without logging full prompts,
  transcripts, or large model responses.
- **FR-007**: Antigravity hook deploy/remove MUST preserve user-owned
  `.agents/hooks.json` entries and replace/remove only Specrew-owned hook
  definitions.
- **FR-008**: Documentation MUST place Antigravity at the same content depth
  and discoverability level as other hosts and include `agy`, deploy/remove
  commands, `/permissions`, `enableTerminalSandbox`, fail-open recovery,
  `specrew start` re-entry, and evidence/status labels. Documentation depth may
  reach parity before final proof, but status labels MUST remain candidate,
  pending-validation, machine-local, beta, stable, or verified according to
  evidence.
- **FR-009**: Full, verified, stable, or parity-equivalent Antigravity support
  status MUST NOT be claimed until manual real-host `agy` evidence proves hook
  firing, B3 injection correctness, Stop handover, exit/re-entry, stable
  conversation identity, and absence of self-marker false concurrency.
- **FR-010**: The implementation MUST reuse existing Specrew refocus machinery
  and stop for a human split/defer decision if B3-on-`PreInvocation` hits any
  falsifiable split-guard trigger: no fresh-enough boundary cursor before turn,
  no exactly-once `PreInvocation` `injectSteps` B3 delivery with existing
  dedupe/breaker behavior, or any required shared host-model contract change
  that alters non-Antigravity host behavior beyond the bounded Antigravity
  manifest/adapter/state/helper slice.

### Traceability & Governance Requirements *(mandatory)*

- **TG-001**: Each user story MUST map to one or more functional requirements.
- **TG-002**: Each requirement MUST identify expected owner role(s).
- **TG-003**: Each requirement MUST identify intended iteration or delivery
  window.
- **TG-004**: Any known spec/implementation conflict MUST include an explicit
  reconciliation path.
- **TG-005**: Manual real-host Antigravity evidence MUST be labeled as
  repo-reproducible or machine-local before review/release claims rely on it.
- **TG-006**: Release MUST proceed beta before stable; F-184 stacks on F-183 and
  releases together with it; stable promotion MUST be blocked until legacy
  upgrade/config migration and release validation pass.

### Traceability Summary

| Story | Functional Requirements | Governance |
| --- | --- | --- |
| US1 | FR-001, FR-002, FR-005 | TG-001, TG-002, TG-003 |
| US2 | FR-002, FR-003, FR-006, FR-010 | TG-001, TG-004, TG-005 |
| US3 | FR-004, FR-006 | TG-001, TG-004 |
| US4 | FR-005, FR-006 | TG-001, TG-005 |
| US5 | FR-007, FR-008, FR-009 | TG-001, TG-005, TG-006 |

### Key Entities *(include if feature involves data)*

- **AntigravityHookEvent**: Normalized representation of Antigravity hook input;
  includes event name, conversation id, invocation number, transcript path,
  workspace paths, and tool/step metadata where present.
- **RefocusSessionState**: Existing per-session Specrew runtime state keyed by
  sanitized session id; contains boundary cursor, anchor/context metadata,
  dedupe, breaker, and bounded evidence/journal data.
- **ConcurrencyMarker**: Existing active-session marker used to warn about
  competing same-worktree sessions; F-184 must classify own vs other markers for
  Antigravity.
- **HostManifestBinding**: Host-level metadata that describes Antigravity hook
  deployment, event binding, command shape, and owned hook entries.
- **ValidationEvidence**: Review/release evidence record for automated tests and
  real-host `agy` runs, labeled repo-reproducible or machine-local.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In automated tests, Antigravity session normalization never writes
  or reads a global `unknown` refocus-state key when a real `conversationId` is
  present.
- **SC-002**: In a manual real-host `agy --conversation <id>` run, exit/re-entry
  preserves the same sanitized conversation identity and per-session refocus
  anchor.
- **SC-003**: In manual real-host `agy` evidence, B3 refocus injects once on a
  real lifecycle boundary crossing and does not inject on ordinary non-boundary
  turns.
- **SC-004**: In automated or manual evidence, Antigravity's own marker does not
  emit a same-worktree concurrency advisory, while a different session marker
  still does.
- **SC-005**: In manual real-host `agy` evidence, bootstrap injection, `Stop`
  handover, and welcome-back resume still work with no provider/launch errors.
- **SC-006**: Deploy/remove tests prove non-Specrew `.agents/hooks.json` entries
  are preserved.
- **SC-007**: Negative-path tests prove hook/provider/state failures fail open
  with bounded warning text and no full prompt/transcript logging.
- **SC-008**: Documentation review proves README/getting-started/host matrix
  include Antigravity at documentation-depth parity with `agy`, hook
  deploy/remove, `/permissions`, `enableTerminalSandbox`, recovery, and
  evidence/status wording, while no status text claims full/verified/stable
  support before FR-009 evidence exists.
- **SC-009**: Discovery spike evidence contains explicit PASS/FAIL rows for the
  fresh boundary cursor, exactly-once B3 `injectSteps` delivery, and bounded
  host-model-change triggers; any FAIL stops for a human split/defer verdict.
- **SC-010**: Release evidence includes beta-before-stable plus F-183/F-184
  combined-release topology and legacy
  upgrade/config migration validation before stable promotion.

## Assumptions

- Antigravity `conversationId` remains stable across `agy --conversation`
  resume, as observed in the real-host spike.
- Antigravity `PreInvocation` remains injection-safe for `injectSteps`; if this
  changes, full support cannot be claimed without a new design decision.
- `PostToolUse` fires but is not injection-safe with `injectSteps`; F-184 will
  not use it as a refocus injection carrier.
- Existing Specrew dispatcher/state/classification/refocus functions can be
  reused with bounded Antigravity adapter/state extension.
- Manual real-host `agy` validation is available before review/release claims.

## Governance Alignment *(mandatory)*

- **Spec Steward**: Product/Spec steward, with human verdict required at every
  Specrew boundary.
- **Iteration Facilitator**: Crew coordinator.
- **Capacity Model**: Story points in the upcoming plan; discovery spike must
  size the B3-on-`PreInvocation` uncertainty before implementation planning.
- **Drift Signals**: `drift-log.md`, traceability checks, implementation vs
  spec/plan/tasks review, evidence labels, and split-guard checks.
- **Human Oversight Points**: specify, clarify, plan, tasks, before-implement,
  review-signoff, retro, feature-closeout, and release gates. One approval
  advances exactly one boundary.
- **Split Guard**: If B3-on-Antigravity requires a broad host-model rewrite
  beyond bounded adapter/state/helper changes, or fails any of the falsifiable
  discovery-spike triggers in FR-010/SC-009, stop for a human split/defer
  verdict.
- **Release Discipline**: Beta is required before stable; stable is blocked
  until legacy upgrade/config migration and release validation pass. F-184
  stacks on F-183, and the next beta/release covers the combined work rather
  than a standalone F-183 release.
