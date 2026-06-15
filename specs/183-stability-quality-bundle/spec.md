# Feature Specification: Stability and Quality Bundle

**Feature Branch**: `183-stability-quality-bundle`
**Created**: 2026-06-15
**Status**: Draft
**Input**: Temporary intake collection at `file:///C:/Dev/183-stability-quality-bundle/.scratch/183-intake-collection.md`, plus workshop amendments through 2026-06-16.

## Clarifications

### Session 2026-06-15

- Q: Product scope for the stability bundle? → A: Confirmed. This is a focused
  software-feature stability/quality bundle with bug-bash conduct per item. The
  original scope is the six named FRs from the intake, with Proposal 191,
  Proposal 165 / Issue #2081, Proposal 168, Issue #78, Proposal 159 Tier 2,
  Proposal 123, and Issue #1761 red #1 excluded.
- Q: Release target beta? → A: Beta-before-stable remains binding, but the exact
  beta tag is not hard-coded. At release time, inspect current local tags,
  origin tags, and published release/package state, then choose the next valid
  `0.37.0-beta<N>`.

### Session 2026-06-16

- Q: What happens when Copilot, Claude, and Codex are open side by side in the
  same VS Code worktree? → A: Specrew does not lock other hosts out. Same-worktree
  multi-host concurrency is advisory only; already-open hosts can have stale chat
  context; disk artifacts are authoritative; rolling handover is
  latest-writer-wins, not a lock; true parallel implementation should use
  separate worktrees.
- Q: Does Antigravity now support hooks, and should this feature include it? → A:
  Yes, add **FR-007 — Antigravity hook support** after maintainer-provided
  upstream evidence showed Antigravity now documents hooks while current Specrew
  registry/deploy tests still exclude Antigravity from hook provisioning. Bind it
  honestly: use project-scoped `.agents/hooks.json`, verify Antigravity schema,
  events, and output semantics before claiming parity, and keep
  `specrew start --host antigravity` as fallback.
- Q: Are any additional clarify questions required before planning? → A: No.
  The specify workshop already resolved the material scope, release-target,
  multi-host concurrency, Antigravity hook-scope, fallback, and capacity-split
  decisions. Planning may proceed with the current FR/SC set, with the explicit
  guard that any capacity split or deferral still requires human approval.

## User Scenarios & Testing

### User Story 1 - Governed SessionStart survives hook delivery failures (Priority: P1)

A Specrew user launches a hook-capable host and still receives a governed
bootstrap path when the normal SessionStart composite is over cap or a provider
fails.

**Why this priority**: SessionStart delivery is the anchor for the bundle. If the
bootstrap banner or fallback disappears, the governed lifecycle can be silently
lost.

**Independent Test**: Use synthetic SessionStart fixtures to force over-cap and
provider-failure paths, then validate that bootstrap remains visible, fallback
is non-empty and under cap, and diagnostics explain degraded behavior.

**Acceptance Scenarios**:

1. **Given** a SessionStart composite that would exceed the host cap, **When** the
   dispatcher assembles output, **Then** it preserves the bootstrap fragment and
   drops or shrinks lower-priority refocus content.
2. **Given** a provider throws during hook execution, **When** the dispatcher
   handles the failure, **Then** it emits a minimal degraded-but-governed fallback
   directive on stdout and exits 0.

---

### User Story 2 - Hook session state stays per-session and diagnosable (Priority: P1)

A Specrew user can run side-by-side hosts without missing host session IDs causing
all hook state to collapse into a global `unknown` bucket.

**Why this priority**: Collapsed session state corrupts dedupe, breaker, status,
and journal behavior, especially in the multi-host dogfood path.

**Independent Test**: Feed missing, blank, and malformed host session IDs into
the hook dispatcher path and verify state/journal keys use a per-launch fallback
token, not global `unknown`.

**Acceptance Scenarios**:

1. **Given** a hook event with no usable host session ID, **When** the dispatcher
   resolves the session key, **Then** it creates a filesystem-safe per-launch
   fallback token.
2. **Given** multiple side-by-side hosts in one worktree, **When** session markers
   are fresh, **Then** concurrency remains advisory and non-blocking, with disk
   artifacts treated as source of truth.

---

### User Story 3 - Closeout state and local tests reflect reality (Priority: P2)

A maintainer running closeout or local green-baseline tests sees classification,
dashboard, and test results that reflect the current repo state instead of stale
or ambient-machine state.

**Why this priority**: Stable promotion depends on trustworthy closeout and local
test evidence.

**Independent Test**: Run closeout sync fixtures for `.specify` dirty surfaces,
no-upstream branches, and auto-detect dashboard generation; run the two #1761
mechanical tests in isolated scratch contexts.

**Acceptance Scenarios**:

1. **Given** `.specify/extensions/` and companion `.specify` config/state files
   are dirty, **When** feature closeout classification runs, **Then** it treats the
   dirty surface coherently rather than partially committing one side.
2. **Given** a branch has no upstream remote, **When** closeout sync renders its
   message, **Then** it does not say the commit “must be pushed.”
3. **Given** closeout auto-detect is used, **When** dashboard output is required,
   **Then** the dashboard is regenerated from current artifacts.
4. **Given** local test fixtures create dirty git state, **When** the tests run,
   **Then** they act on scratch repos or module-internal files, not the real
   worktree.

---

### User Story 4 - Antigravity participates in verified hook support (Priority: P2)

A Specrew user who uses Antigravity can benefit from Antigravity hooks where
Specrew has verified the configuration and event semantics, while retaining clear
fallback guidance where parity is not proven.

**Why this priority**: Antigravity is a supported host, and upstream now documents
hooks; Specrew should support verified bindings instead of preserving the old
no-hooks assumption.

**Independent Test**: Provision Antigravity hooks into project-scoped
`.agents/hooks.json`, verify merge/remove/opt-out behavior, then run real-host
validation for the mapped events before claiming stable parity.

**Acceptance Scenarios**:

1. **Given** an Antigravity project with existing user hooks, **When** Specrew
   installs hooks, **Then** Specrew-owned entries are added or refreshed without
   clobbering user entries.
2. **Given** an Antigravity event whose injection/capture behavior is not
   verified, **When** docs or status render capability, **Then** Specrew does not
   claim parity and keeps `specrew start --host antigravity` as fallback.

### Edge Cases

- Hook provider throws before producing output.
- Combined SessionStart output exceeds the host cap.
- Host hook payload omits, blanks, or malforms the session ID.
- Multiple hosts are open in one worktree and one resumes from stale chat
  context.
- `.specify/extensions/` is dirty while companion `.specify` files are also dirty.
- Feature closeout runs on a local branch with no upstream.
- Auto-detect closeout path has a stale dashboard from a prior run.
- Antigravity hook schema changes or an unsupported shape is found.
- Hook config parse/merge is unsafe; user config must be preserved.

## Requirements

### Functional Requirements

- **FR-001**: When the SessionStart composite would exceed the host hook-output
  cap, the dispatcher MUST keep the bootstrap fragment intact and drop or shrink
  the lower-priority refocus fragment so the lifecycle banner survives.
  **Owner**: Implementer. **Delivery window**: stability bundle.
- **FR-002**: When the bootstrap/refocus provider fails, the hook MUST emit a
  minimal under-cap fallback directive on stdout, exit 0, and tell the agent this
  is degraded but governed.
  **Owner**: Implementer. **Delivery window**: stability bundle.
- **FR-003**: SessionStart journal/status/dedupe/breaker state MUST NOT collapse
  under global `unknown`; missing or malformed session IDs MUST get a
  filesystem-safe per-launch fallback token.
  **Owner**: Implementer. **Delivery window**: stability bundle.
- **FR-004**: The delivery-cap test MUST measure a synthetic shipped
  SessionStart composite, not ambient developer-machine refocus state.
  **Owner**: Implementer, Reviewer. **Delivery window**: stability bundle.
- **FR-005**: Closeout sync MUST handle `.specify` dirty surfaces coherently,
  say “must be pushed” only when a remote/upstream exists, and refresh the
  closeout dashboard on auto-detect paths.
  **Owner**: Implementer. **Delivery window**: stability bundle.
- **FR-006**: The two in-scope #1761 local tests MUST stop failing because of
  dirty real-tree context or assertions against the wrong sync script copy.
  **Owner**: Implementer, Reviewer. **Delivery window**: stability bundle.
- **FR-007**: Specrew MUST add Antigravity to the hook-capable host path using
  the current official Antigravity project hook configuration surface, provision
  Specrew-owned hook entries without clobbering user hooks, map only verified
  Antigravity events to Specrew behavior, and remove stale user-facing
  Antigravity-no-hooks wording.
  **Owner**: Implementer, Reviewer. **Delivery window**: stability bundle unless
  capacity planning explicitly splits/defer it.

### Traceability & Governance Requirements

- **TG-001**: Each task MUST map to at least one FR or SC.
- **TG-002**: Each FR and SC MUST map to at least one task or explicit deferral.
- **TG-003**: Mirror parity MUST be recorded for touched extension/runtime files.
- **TG-004**: Any Antigravity hook parity claim MUST cite the verified event and
  output/capture behavior; unsupported events must be labeled degraded or
  deferred.
- **TG-005**: Feature closeout MUST link fixing commits to issues #2446, #1627,
  and #1761; proposals are referenced but not silently edited.

### Lens-Informed Requirements

- **LIR-001 (Architecture)**: Planning MUST keep this as one governed
  software-feature with bug-bash FR slices unless capacity forces an explicit
  split.
- **LIR-002 (Component Design)**: Planning MUST preserve separation among cap
  policy, fallback text, session ID resolution, journal state, closeout
  classification, dashboard rendering, test fixtures, and Antigravity hook
  schema adapters.
- **LIR-003 (Data)**: Runtime state remains local-file and best-effort; side-by-
  side same-worktree hosts are advisory concurrency only, not lock-based
  serialization.
- **LIR-004 (Security)**: Hook inputs are untrusted host payloads and must be
  validated/sanitized; hook config writes must preserve user config on unsafe
  parse/merge.
- **LIR-005 (Integration)**: Antigravity Specrew hooks use project-scoped
  `.agents/hooks.json`; global Antigravity config is not used for this feature.
- **LIR-006 (DevOps)**: Release target selection MUST inspect current local
  tags, origin tags, and published release/package state before choosing
  `0.37.0-beta<N>`.
- **LIR-007 (Observability)**: Diagnostics MUST distinguish cap handling,
  provider failure, session ID fallback, hook config failure, Antigravity partial
  support, and real-host validation failure.
- **LIR-008 (UI/UX)**: User-visible fallback wording MUST state governance is
  still active and point to `specrew where`, `/specrew-refocus`,
  `specrew hooks status`, and `specrew start --host <host>` where relevant.
- **LIR-009 (Code Implementation)**: Use existing PowerShell/Pester patterns and
  no new runtime dependency unless a new decision is approved.

## Success Criteria

### Measurable Outcomes

- **SC-001**: A deterministic test proves an over-cap SessionStart composite
  preserves the bootstrap fragment and prevents the host from dropping the whole
  payload.
- **SC-002**: A deterministic test proves provider failure emits a non-empty
  under-cap fallback directive on stdout, exits 0, and includes recovery
  instructions to run `specrew where` or `/specrew-refocus`.
- **SC-003**: Tests prove blank/missing/malformed host session IDs no longer
  write or report under global `refocus-state-unknown.json`, and per-session
  dedupe/breaker behavior keys by a per-launch token.
- **SC-004**: `tests/bootstrap/DirectiveDeliveryCap.Tests.ps1` passes using a
  synthetic startup SessionStart event and does not depend on ambient refocus
  state.
- **SC-005**: Tests prove `.specify/extensions/` and companion `.specify`
  config/state files are classified coherently, no-upstream paths do not say
  “must be pushed,” and auto-detect closeout regenerates the dashboard.
- **SC-006**: The two in-scope #1761 tests pass for the intended reasons:
  scratch git isolation and module-internal ValidateSet assertion.
- **SC-007**: For touched extension/runtime files, source and `.specify` mirror
  remain byte-aligned; release readiness records the next actual beta target only
  after checking current tags and published state.
- **SC-008**: Before stable promotion, a real host run confirms the
  SessionStart bootstrap/fallback behavior reaches the agent and does not
  silently degrade.
- **SC-009**: Tests and at least one Antigravity real-host validation prove
  Specrew provisions Antigravity hooks, preserves user hook entries, invokes the
  Specrew dispatcher/provider path for verified events, and does not claim
  SessionStart/Stop parity for any Antigravity event whose injection/capture
  behavior is unverified.

## Key Entities

- **Hook Fragment**: A string payload produced by a provider for a host hook
  event. Fragments have priority; bootstrap outranks refocus for SessionStart
  delivery.
- **Fallback Directive**: Minimal governed text emitted when a provider fails,
  instructing the agent/user how to recover without losing lifecycle discipline.
- **Session Key**: Filesystem-safe identifier used for hook runtime state,
  journal, dedupe, breaker, and status behavior.
- **Closeout Dirty Surface**: The repo-state classification used by
  feature-closeout sync to decide what must be committed or pushed before a gate
  can close.
- **Mirror**: The deployed project copy of Specrew extension files under
  `.specify/extensions/specrew-speckit/`, which must match touched source files
  under `extensions/specrew-speckit/`.
- **Antigravity Hook Binding**: Specrew-owned entries in project-scoped
  `.agents/hooks.json`, mapped only to verified Antigravity hook events and
  output/capture semantics.

## Assumptions

- The current worktree is the dogfood runtime via `SPECREW_MODULE_PATH`.
- No global module upgrade or PSGallery dependency is required during
  implementation.
- Antigravity upstream hook support exists, but the current Specrew
  implementation must verify the exact config schema, event names, and
  output/capture semantics before claiming parity.
- Existing `specrew start --host antigravity` remains the governed fallback even
  after Antigravity hook support is added.
- Historical local `refocus-state-unknown.json` files do not require migration.
- The amended FR set fits under the 20 SP cap only if planning confirms it; if
  not, the split/defer decision requires explicit human approval.

## Out of Scope

- Proposal 191 payload-size optimization spike and durable reduction.
- Proposal 165 / Issue #2081 Claude workshop picker/render residual.
- Proposal 168 Claude boundary-packet Stop hook.
- Issue #78 Squad hardening-gate handoff.
- Proposal 159 Tier 2 optional self-update.
- Proposal 123 verdict-history atomic single-write refactor.
- Issue #1761 red #1 feature-closeout SDLC wording/design row.
- New parser package, new CLI dependency, new test framework, or new release
  mechanism.

## Governance Alignment

- **Spec Steward**: Maintains spec authority, scope boundary, and Antigravity
  amendment honesty.
- **Iteration Facilitator**: Keeps the plan within the 20 SP cap or forces an
  explicit split/defer decision.
- **Capacity Model**: Story points, 20 SP maximum per iteration.
- **Drift Signals**: `iterations/001/drift-log.md`, traceability checks,
  mirror-parity checks, runtime evidence, and review evidence.
- **Human Oversight Points**: Human approval required at specify, clarify,
  design-analysis, plan, tasks, before-implement, review, retro,
  iteration-closeout, feature-closeout, and release validation.
