# Feature Specification: Devin CLI Host — Clean-Extensibility Proof

**Feature Branch**: `200-devin-cli-host`
**Created**: 2026-06-24
**Status**: Draft
**Input**: Implement Proposal 200 by adding Devin for Terminal as a Specrew host while completing the generic host abstractions needed to prove that ordinary future hosts are added by a package folder rather than shared-core host literals.

## Product-Domain Summary

- **Users and stakeholders**: Specrew maintainers, developers running Specrew through Devin CLI, and future host-package authors.
- **Problem**: The host package architecture is mostly registry-driven, but three input validators, package FileList membership, coordinator eligibility/configuration, and the firewall proof still contain or permit shared host coupling.
- **MVP**: Deliver Proposal 200 Slices A, C, and D: registry-driven validation; generated host-package FileList entries; host-addition purity enforcement; the Devin package; an empirical transcript/handover spike; coordinator eligibility; and managed iteration-config migration.
- **Primary constraint**: Do not modify `scripts/internal/bootstrap/ConversationCaptureAccessor.ps1`. Slice B remains deferred until Feature 197 merges.
- **Host-specific ownership**: Devin runtime behavior belongs under `hosts/devin/`. Shared source changes must be generic for all hosts. Generated artifacts, tests, proposals, and documentation may identify Devin where their purpose requires it.
- **Pinned tested build**: `devin 2026.7.23 (3bd47f77)` is a tested-build identifier using Devin's date-style versioning; it is not a claim about release chronology.
- Full workshop records are under `workshop/`; implementation constraints are in `implementation-rules.yml`.

## Scope and Dispositions

### In scope now

- **Slice A**: Replace the three allow-listed host `[ValidateSet]` callsites with registry-driven validation; generate host-package FileList membership; add a permanent host-addition purity assertion; shrink the firewall allow-list.
- **Slice C**: Add `hosts/devin/` with its manifest, five contract handlers, coordinator rules, hook/instruction/skill/subagent integration, tested-build metadata, and real-host validation.
- **Slice D**: Add manifest-driven coordinator eligibility and migrate the Specrew-managed `agents:` projection in `.specrew/iteration-config.yml`.
- Preserve `specrew start` as a supported backward-compatible launch surface and add Devin support to it.
- Update README, user/host documentation, architecture/add-host guidance, changelog/release notes, relevant test documentation, Proposal 194, and GitHub Actions where required by the accepted design.

### Deferred

- **Slice B**: Transcript-turn-shape contract extraction and migration of existing host shapes.
- Any new transcript parser shape or edit to `scripts/internal/bootstrap/ConversationCaptureAccessor.ps1`.
- Devin session `--continue` / `--resume` support, because the current host launch contract has no resume-session input.
- Generic Spec Kit `--ai` versus `--integration` version selection owned by Proposal 198.

### Separate follow-up work

- A proposal and separate PR for validating and converging updates across arbitrary historical Specrew versions. Feature 200 records this follow-up but does not author or implement it.
- Implementation of the scheduled cross-host compatibility/transcript drift monitor in Proposals 187/194. Feature 200 amends the proposal and supplies Devin metadata/evidence requirements, but does not build the scheduled workflow.

### Explicitly out of scope

- Devin Desktop, Cascade, Windsurf IDE integration, or legacy `.windsurf/` paths.
- A second host catalog, a host-specific shared-core branch, or a new authentication/security subsystem.
- Automatic host CLI upgrades.

## User Scenarios & Testing

### User Story 1 - Run a governed Specrew session in Devin CLI (Priority: P1)

As a developer, I want `specrew start --host devin` to launch an interactive Devin terminal session with Specrew instructions, hooks, skills, and Crew agents, so I can use the normal governed lifecycle from Devin.

**Why this priority**: Devin is the user-visible capability. A package that is discoverable but cannot complete a real governed session is not a host integration.

**Independent Test**: Install the prerelease package, run `specrew start --host devin` against the pinned tested build, and verify interactive launch, SessionStart bootstrap, a human-judgment boundary Stop, instructions, and Crew-runtime deployment.

**Acceptance Scenarios**:

1. **Given** the pinned Devin CLI is installed, **when** a user runs `specrew start --host devin`, **then** Specrew launches an interactive Devin session with the bootstrap prompt and does not use print/headless mode for the normal session.
2. **Given** Specrew permission mode is normal, autopilot, or allow-all, **when** the launch invocation is built, **then** Devin receives `auto`, `smart`, or `dangerous` respectively, with dangerous precedence and an explicit notice.
3. **Given** Devin is not installed, **when** it is selected, **then** Specrew reports actionable manifest-provided install guidance without changing another host's behavior.
4. **Given** canonical Crew agent charters exist, **when** Devin Crew runtime is installed, **then** host-native agents are deployed under `.devin/agents/` without modifying canonical team files.

---

### User Story 2 - Add hosts without shared-core host literals (Priority: P1)

As a Specrew maintainer, I want runtime host discovery, validation, packaging, and coordinator projections to derive from host packages, so adding an ordinary host does not require adding its name to shared production code.

**Why this priority**: This is the clean-extensibility proof and the reason Devin is more than another catalog entry.

**Independent Test**: Run the registry, package parity, launch, coordinator, and firewall suites against the installed host folders; verify the five production firewall exceptions in scope are removed and no new exception is added.

**Acceptance Scenarios**:

1. **Given** a registered host kind, **when** any of the three host input boundaries validates it, **then** validation uses the live registry rather than a hardcoded host enum.
2. **Given** a host package containing the three required package files, **when** package metadata is generated, **then** all required paths are included deterministically without a hand-authored per-host FileList entry.
3. **Given** a production source file outside `hosts/`, **when** the purity assertion scans it, **then** a planted Devin-specific routing literal fails the test while manifest-driven code passes.
4. **Given** the completed feature tree, **when** the firewall runs, **then** its allow-list is smaller by the three validator and two coordinator exceptions and contains no new Devin exception.

---

### User Story 3 - Upgrade an existing project to the registry-derived host catalog (Priority: P1)

As an existing Specrew user, I want one `specrew update` run to add newly eligible hosts and refresh generic host assets while preserving my project choices, so I do not need a fresh init or a sequence of version-by-version upgrades for the known Feature 200 migration.

**Why this priority**: Shipping a new coordinator-capable host without migrating existing projects would make support inconsistent between new and upgraded projects.

**Independent Test**: Apply update migration fixtures for absent, legacy three-host, partial, and current managed `agents:` blocks; verify preservation, addition/removal rules, unrelated content preservation, and idempotency.

**Acceptance Scenarios**:

1. **Given** no managed agents block, **when** update runs, **then** it creates a registry-derived block containing coordinator-capable hosts with manifest defaults.
2. **Given** a legacy or partial block, **when** update runs, **then** it preserves mutable values by host key, adds newly eligible hosts, removes only no-longer-eligible entries from the managed block, and preserves unrelated configuration.
3. **Given** the migrated project, **when** update runs again, **then** it produces no managed configuration diff.
4. **Given** Devin is the selected launch host, **when** the projection is generated, **then** Devin may be enabled for that project; otherwise its default is disabled with `host_process` access.
5. **Given** generic hook and instruction assets need refresh, **when** update runs, **then** it discovers host capabilities through the registry and does not use an emergency hardcoded host fallback.

---

### User Story 4 - Receive honest handover behavior from Devin (Priority: P1)

As a developer resuming a governed Devin session, I want handover enrichment to use an empirically proven existing capture path or tell me that transcript enrichment is degraded, so Specrew never claims conversation capture that it did not obtain.

**Why this priority**: Official Devin documentation does not establish that the Stop payload includes the assistant message. Handover feasibility is the main integration risk.

**Independent Test**: Run an early real-host Stop-payload spike and classify the outcome using the required preference order; then replay a real boundary handover on the pinned build.

**Acceptance Scenarios**:

1. **Given** a live Devin Stop hook, **when** the complete payload is captured, **then** the evidence records whether an assistant-message field is actually present rather than trusting the narrower documentation.
2. **Given** the payload carries the assistant message, **when** Stop handover runs, **then** the existing Tier-3 event-payload fallback captures the bounded assistant turn without parser changes.
3. **Given** Tier-3 is unavailable but ATIF export can be normalized inside `hosts/devin/` to an existing parser-supported JSONL shape, **when** Stop handover runs, **then** the unchanged parser consumes that normalized shape.
4. **Given** a genuinely new parser shape is required, **when** Devin ships, **then** handover enrichment is explicitly degraded with a bounded reason code, Slice B is deferred, and `ConversationCaptureAccessor.ps1` remains unchanged.
5. **Given** boundary Stop enforcement cannot fire correctly, **when** prerelease validation runs, **then** release promotion is blocked; handover enrichment degradation alone does not corrupt durable git/artifact truth.

---

### User Story 5 - Preserve user files and existing hosts (Priority: P2)

As a Specrew user with existing host configuration, I want Devin support to merge only Specrew-owned entries and leave existing hosts unchanged, so adopting or updating Specrew does not overwrite my hook, instruction, or agent configuration.

**Why this priority**: Host integration touches executable hooks and shared instruction paths; ownership safety is mandatory.

**Independent Test**: Run hook merge, instruction deduplication, Crew deployment, launch, registry, parser golden, and cross-platform suites for all existing hosts plus Devin.

**Acceptance Scenarios**:

1. **Given** `.devin/hooks.v1.json` contains user entries, **when** Specrew deploys hooks, **then** it merges only Specrew-owned event rows in the root-level direct event map and preserves user content.
2. **Given** the hook file is unreadable or malformed, **when** deployment runs, **then** Specrew fails safely and does not overwrite it.
3. **Given** several hosts share `AGENTS.md`, **when** instructions deploy, **then** the path is deduplicated and user-authored content is preserved by the existing merge contract.
4. **Given** the five existing hosts, **when** the full compatibility suites run, **then** their launch behavior, hook behavior, Crew runtime, registry discovery, and unchanged transcript parser goldens remain green.

---

### User Story 6 - Keep Devin compatibility visible and maintainable (Priority: P2)

As a maintainer, I want Devin's tested build and fragile integration surfaces documented and included in future compatibility monitoring design, so upstream changes can be detected and diagnosed.

**Why this priority**: Devin CLI is new and volatile; hooks, payloads, export format, and launch flags are compatibility-sensitive.

**Independent Test**: Review the manifest metadata, README/host docs, changelog, Proposal 194 amendment, CI workflow gates, and real-host evidence record.

**Acceptance Scenarios**:

1. **Given** the Devin manifest, **when** compatibility metadata is inspected, **then** it identifies `2026.7.23 (3bd47f77)` as the pinned tested build and declares the fragile hook/payload/export surfaces needed by future monitoring.
2. **Given** Proposal 194, **when** Feature 200 documentation changes are reviewed, **then** Devin is included and future host inventory is registry/manifest-driven rather than a hardcoded four-host list.
3. **Given** the current Feature 200 scope, **when** CI/workflows are inspected, **then** deterministic registry, launch, firewall, generation, and migration checks are explicit, while no unapproved scheduled live-monitor implementation is introduced.
4. **Given** a future general historical-upgrade proposal is needed, **when** Feature 200 closes, **then** it is recorded as separate follow-up work and not bundled into this implementation.

### Edge Cases

- Unknown or differently-cased host input must produce registered-host guidance rather than parameter-binding ambiguity.
- An invalid host manifest must not silently enter the catalog or generated package.
- Missing one of the three required host package files must fail FileList parity/package validation.
- Generated package order must be deterministic across Windows and Unix path behavior.
- A future host that introduces a genuinely new capability dimension may extend the contract generically; the folder-only guarantee forbids host-specific shared branches, not all future contract evolution.
- `AGENTS.md` may already be managed for another host; deployment must deduplicate by path.
- Devin hooks use a root-level direct event map, not a nested `hooks` object.
- Devin's installed CLI may expose legacy Windsurf wording or paths; Specrew must not adopt them.
- The Stop payload may omit transcript content, ATIF export may be absent, or ATIF may change shape; the spike outcome controls scope.
- Temporary export data may contain sensitive conversation content; it must use a controlled local runtime path, bounded processing, and cleanup, and must not enter CI artifacts.
- Devin may be installed but newer than the tested build; Feature 200 records evidence honestly and does not invent a semver ordering for date-style versions.
- Existing projects may have comments, unrelated YAML keys, no managed block, duplicated/stale managed entries, or only some coordinator hosts.
- A user may rerun init/update/start-heal; all managed generation and merge behavior must remain idempotent.

## Requirements

### Functional Requirements

- **FR-001 — Registry-driven validation**: The three production host input-validation callsites currently allow-listed by the firewall MUST validate against `Get-RegisteredHostKinds` (or an equivalent registry query), reject unknown values with actionable registered-host guidance, and contain no hardcoded multi-host enum.
- **FR-002 — Generated host package membership**: Host-package FileList entries MUST be generated deterministically from registered `hosts/*/{host.psd1,handlers.ps1,coordinator-rules.psd1}` packages, composed with existing generation/parity machinery, and verified before publish. Hand-authored per-host package paths are not the source of truth.
- **FR-003 — Host-addition purity firewall**: The host-coupling firewall MUST add a steady-state assertion that rejects production shared-core Devin/Windsurf routing literals outside `hosts/devin/`, proves a planted literal fails, exempts generated artifacts and non-production evidence/documentation surfaces deliberately, and prevents allow-list growth.
- **FR-004 — Allow-list reduction**: Feature 200 MUST retire the three validator exceptions and two coordinator-tier exceptions in scope, add no Devin exception, and leave the firewall allow-list smaller than its pre-feature state.
- **FR-005 — Devin package contract**: `hosts/devin/` MUST contain a valid manifest, all five existing contract-handler implementations, and coordinator rules. Registry discovery, manifest validation, handler resolution, and package validation MUST work without a Devin-specific shared-core dispatch branch.
- **FR-006 — Tested-build and status metadata**: The Devin manifest MUST record the pinned tested build `2026.7.23 (3bd47f77)`, current product paths/capabilities, coordinator metadata, and future compatibility-monitor metadata. Devin MUST begin as `experimental` and may become `supported` only after the required prerelease real-host evidence passes.
- **FR-007 — Launch and flag translation**: Normal `specrew start --host devin` MUST launch Devin interactively with the bootstrap prompt as positional input. `devin -p` MUST be reserved for bounded smoke/canary automation. Permission modes MUST map normal -> `auto`, autopilot -> `smart`, and allow-all -> `dangerous`, with dangerous precedence and an explicit notice. Host-session resume support is deferred.
- **FR-008 — Runtime, instructions, skills, and Crew agents**: Devin runtime detection and environment signals MUST use the five-handler contract. Instructions MUST target root `AGENTS.md`; skills MUST support `.devin/skills/` and the documented shared `.agents/skills/` surface; Crew subagents MUST deploy to `.devin/agents/<name>/AGENT.md`; shared paths MUST be deduplicated and user content preserved.
- **FR-009 — Direct event-map hooks**: The hook deployer MUST support a generic manifest-driven direct event-map configuration shape. Devin MUST declare `.devin/hooks.v1.json`, `SessionStart`, `UserPromptSubmit`, and `Stop`, use `DEVIN_PROJECT_DIR` for project resolution, and use the existing decision-block Stop response. Hook merge/remove/status behavior MUST preserve non-Specrew entries and avoid whole-file ownership unless explicitly declared.
- **FR-010 — Spec Kit integration**: The Devin package MUST declare the host's Spec Kit integration identifier as `devin`. Generic version-aware selection between Spec Kit flag names remains Proposal 198 ownership and MUST NOT become a Devin-specific shared-core conditional.
- **FR-011 — Empirical handover gate**: Before handover implementation is planned, a real-host spike on the pinned build MUST capture the complete Stop payload and apply this order: (1) existing Tier-3 assistant-message payload; (2) in-package ATIF export normalization to an existing parser-supported JSONL shape; (3) explicit degraded handover with Slice B deferred.
- **FR-012 — Parser collision boundary**: Feature 200 MUST NOT modify `scripts/internal/bootstrap/ConversationCaptureAccessor.ps1`. If the spike requires a genuinely new parser shape, full transcript handover is out of the current implementation scope and the shipped host MUST surface a bounded degraded-handover reason.
- **FR-013 — Coordinator eligibility**: Host manifests MUST declare coordinator eligibility and coordinator projection defaults. Registry consumers MUST derive the eligible host set from manifests rather than hardcoded host names. Devin MUST be coordinator-capable, use `host_process` access, and default to disabled unless selected for the project.
- **FR-014 — Managed agents migration**: Init/update logic MUST regenerate only the Specrew-managed `agents:` block from coordinator-eligible manifests, preserve existing mutable values by host key, add newly eligible hosts, remove no-longer-eligible entries only from the managed block, preserve unrelated content, and be idempotent.
- **FR-015 — Known one-run update convergence**: One `specrew update` run MUST migrate the Feature 200 known input shapes: absent managed block, legacy three-host block, partial block, and current registry-derived block. Feature 200 MUST NOT claim arbitrary historical-version convergence.
- **FR-016 — Generic update/start support**: `specrew update`, init, start, and start-heal paths that refresh hosts, hooks, instructions, Crew runtime, or managed coordinator configuration MUST discover capabilities through the registry and MUST not rely on a hardcoded emergency host list. `specrew start` remains backward compatible for existing hosts.
- **FR-017 — Security and diagnostics**: Devin authentication remains host-owned. Specrew MUST preserve user-owned files, keep transcript/export data local and bounded, redact prompts/full transcripts/credentials from logs and CI artifacts, and report tested build, OS, event, hook path, selected handover mechanism, result, and bounded reason code.
- **FR-018 — Existing-host compatibility**: The five existing hosts and the unchanged transcript parser goldens MUST remain compatible. Registry, launch, hooks, instructions, Crew runtime, coordinator projection, and packaging tests MUST cover existing behavior.
- **FR-019 — CI and prerelease evidence**: GitHub CI MUST explicitly run registry/manifest, multi-host launch, host-coupling firewall, generated FileList parity, and managed-agent migration/idempotency gates. The prepublish FileList-faithful harness MUST include generated host packages. Generic path/argument behavior MUST be tested on Windows and at least one Unix environment.
- **FR-020 — Documentation and monitoring proposal**: Feature 200 MUST update README, host/user documentation, architecture/add-host guidance, changelog/release notes, relevant test documentation, and Proposal 194. Proposal 194 MUST include Devin's version, hook contract, Stop payload, ATIF/export, and handover canary and MUST derive future host inventory from registry/manifest metadata rather than a fixed host list. No scheduled monitor is implemented in this feature.
- **FR-021 — Real-host promotion gate**: Promotion from experimental to supported MUST require prerelease evidence on the actual pinned CLI for interactive `specrew start`, SessionStart bootstrap, UserPromptSubmit context delivery, boundary Stop enforcement, permission translation, hook merge safety, and the handover outcome required by FR-011.
- **FR-022 — Follow-up recording**: Feature closeout MUST record the need for a separate proposal/PR covering arbitrary multi-version update validation and convergence, without creating or implementing that proposal in Feature 200.

### Traceability & Governance Requirements

- **TG-001**: Each user story MUST map to one or more FRs and measurable success criteria.
- **TG-002**: Each FR MUST have an owner role and intended delivery window in the ownership matrix below.
- **TG-003**: Tasks MUST map to FRs/SCs, and every FR/SC MUST have at least one task before implementation begins.
- **TG-004**: Any conflict with Feature 197 ownership, folder-only purity, unchanged parser behavior, or the 20 story-point iteration cap MUST be recorded in `drift-log.md` and stopped for a human split/defer verdict.
- **TG-005**: Automated evidence and real-host evidence MUST be labeled separately. File presence, mocked payloads, or frozen fixtures alone cannot satisfy FR-011 or FR-021.
- **TG-006**: The committed diff before feature closeout MUST be reviewed by ownership class: Devin-specific package changes, generic abstraction changes, generated artifacts, tests, and documentation/proposals.

### Requirement Ownership and Delivery Window

| Requirements | Owner role(s) | Intended window |
|---|---|---|
| FR-001–FR-004 | Implementer, Reviewer | Slice A |
| FR-005–FR-012 | Implementer, Security Reviewer, Reviewer | Slice C; FR-011 spike is the first gating task |
| FR-013–FR-016 | Implementer, Data/Integration Reviewer | Slice D |
| FR-017–FR-019 | Implementer, Security Reviewer, DevOps Reviewer | Across slices; finalized before prerelease |
| FR-020, FR-022 | Spec Steward, Implementer, Reviewer | Documentation/closeout |
| FR-021 | Implementer, Reviewer, human maintainer | Prerelease promotion gate |

### Traceability Summary

| Story | Functional requirements | Success criteria |
|---|---|---|
| US1 | FR-005–FR-010, FR-016, FR-021 | SC-001, SC-007 |
| US2 | FR-001–FR-005, FR-013, FR-018–FR-019 | SC-002–SC-005 |
| US3 | FR-013–FR-016 | SC-006 |
| US4 | FR-011–FR-012, FR-017, FR-021 | SC-007–SC-008 |
| US5 | FR-008–FR-009, FR-017–FR-019 | SC-005, SC-009 |
| US6 | FR-006, FR-017, FR-019–FR-022 | SC-010–SC-012 |

### Key Entities

- **Host manifest**: Canonical package metadata for identity, status, runtime capabilities, hook bindings, coordinator eligibility/defaults, tested build, and compatibility-monitor declarations.
- **Host registry**: Runtime discovery and validation authority that scans installed host packages and dispatches the five existing handlers.
- **Host package**: The three required per-host files plus optional host documentation; Devin-specific runtime behavior is owned here.
- **Generated host FileList projection**: Deterministic package metadata derived from host package folders and checked for parity.
- **Managed agents projection**: Project-specific coordinator settings derived from eligible host manifests while preserving mutable project choices.
- **Handover mechanism verdict**: Spike outcome identifying Tier-3 payload, in-package export normalization, or degraded/deferred handover.
- **Real-host evidence record**: Bounded record of tested build, operating system, events, paths, mechanism, result, and reason code without conversation bodies or credentials.

## Success Criteria

### Measurable Outcomes

- **SC-001**: The pinned Devin CLI completes a real interactive `specrew start` session that surfaces SessionStart bootstrap and reaches a correctly enforced human-judgment boundary Stop. **Evidence**: prerelease real-host run.
- **SC-002**: All three validation allow-list entries and both coordinator allow-list entries are removed; no new Devin exception is added. **Evidence**: firewall output and committed allow-list count.
- **SC-003**: The host-addition purity test fails on a planted Devin-specific shared-core routing literal and passes on registry/manifest-driven code. **Evidence**: deterministic automated negative and positive tests.
- **SC-004**: A host package added to the fixture catalog is discovered, validated, packaged, and projected without changing an independent shared host list. **Evidence**: automated fixture-host test and FileList parity.
- **SC-005**: All existing-host registry, launch, hook, instruction, Crew runtime, coordinator, package, and transcript golden tests remain green. **Evidence**: automated compatibility suite.
- **SC-006**: Each known iteration-config input shape migrates correctly in one run and a second run produces no diff. **Evidence**: four fixture classes plus idempotency assertions.
- **SC-007**: Real-host evidence records interactive launch, permission translation, SessionStart, UserPromptSubmit, Stop enforcement, hook merge safety, and the selected handover outcome on `2026.7.23 (3bd47f77)`. **Evidence**: bounded prerelease evidence artifact.
- **SC-008**: The handover spike produces exactly one classified outcome: Tier-3 success, export-normalization success, or degraded/deferred. Outcomes 1–2 include a real captured handover; outcome 3 includes visible degradation and zero parser changes. **Evidence**: spike report plus source diff.
- **SC-009**: Hook merge tests preserve user entries and refuse to overwrite unreadable configuration; logs/artifacts contain no prompt, full transcript, or credential fixture content. **Evidence**: automated security tests.
- **SC-010**: The prerelease package passes FileList-faithful validation and explicit CI gates on Windows plus at least one Unix runner. **Evidence**: GitHub Actions and prepublish harness.
- **SC-011**: README/host docs, architecture/add-host guidance, changelog/release notes, test docs, and Proposal 194 consistently describe Devin and the registry-driven extension model. **Evidence**: documentation review.
- **SC-012**: The final committed diff contains Devin-specific production logic only under `hosts/devin/`; shared production edits are generic, generated package output is reproducible, and the forbidden accessor has no diff. **Evidence**: final diff classification plus firewall/parity output.

## Assumptions

- The installed `devin 2026.7.23 (3bd47f77)` binary is available for the early spike and prerelease evidence; the identifier is treated as date-style opaque version text.
- Devin owns user authentication and provider credentials; Specrew does not add an authentication flow.
- Current official Devin contracts are `.devin/hooks.v1.json`, `DEVIN_PROJECT_DIR`, root `AGENTS.md`, `.devin/skills/`, `.devin/agents/`, and ATIF export.
- The existing host registry, five-handler contract, hook dispatcher/provider path, instruction merge, canonical Crew team source, and package parity machinery remain the architectural foundation.
- A genuinely new host capability dimension may require a future generic contract extension; this does not weaken the prohibition on host-specific shared-core routing.
- General arbitrary-version upgrade convergence is not currently proven and remains separate work.

## Governance Alignment

- **Spec Steward**: Maintains scope and ensures workshop decisions, Proposal 200, and implementation remain reconciled.
- **Iteration Facilitator**: Applies the 20 story-point capacity cap, schedules the handover spike first, and splits slices rather than silently overcommitting.
- **Capacity Model**: Story points with a 20 SP maximum per iteration. Planning must estimate Slices A, C, D, evidence, and documentation; any over-cap plan requires a human split/defer decision.
- **Drift Signals**: Any edit to `ConversationCaptureAccessor.ps1`; a Devin/Windsurf production literal outside `hosts/devin/`; a growing firewall allow-list; a second host catalog; hand-authored host package paths; unapproved scheduled monitoring; or unsupported claims of arbitrary update convergence.
- **Human Oversight Points**: Every Specrew lifecycle boundary, the design-analysis option verdict, the pre-implementation gate, the transcript spike verdict if it changes scope, prerelease promotion from experimental to supported, and feature closeout.
- **Release Discipline**: Beta/prerelease evidence precedes supported status or stable release. Real-host behavior is required; deterministic tests alone are insufficient.
