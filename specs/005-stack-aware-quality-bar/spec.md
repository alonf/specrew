# Feature Specification: Stack-Aware Quality Bar

**Feature Branch**: `[005-stack-aware-quality-bar]`  
**Created**: 2026-05-07  
**Status**: Draft  
**Input**: User description: "Specrew should improve delivered code quality by making the quality bar technology-aware, explicit, tool-backed, and enforceable, with stack-aware tool selection and explicit planning/review evidence."

## Clarifications

### Session 2026-05-08

- Q: What format should versioned lens checklists use? → A: Markdown tables.
- Q: How should required bug-hunter lenses bind to reasoning classes? → A: Hard-bind to the strongest available reviewer/reasoning class by default; lower-tier execution requires an explicit recorded override.
- Q: Who can approve hardening-gate deferrals for unresolved security, resilience, or operational concerns? → A: Human developer approval required; agents may recommend only.
- Q: What baseline should quality drift compare against first? → A: The active feature's planned quality baseline first, then prior iteration baselines when they exist.
- Q: Should the quality bar enforce technology-specific best practices when developers lack deep quality expertise? → A: Yes, the quality bar should enforce technology-specific software quality best practices even when the human developer lacks deep quality expertise.
- Q: When should a newly found trap be added to the known-traps corpus? → A: After human approval, immediately; it may then be promoted into a checklist item or mechanical check in the same or next slice.

## Problem Statement

Specrew already improves delivery through specification, planning, governance, and review, but delivered implementations still suffer from recurring defect patterns that cluster around four failure modes:

1. **Ceremonial sophistication without enforcement**: Review processes exist but lack concrete, enforceable checks (e.g., dead revision fields, unused manager objects, test theater that validates nothing).
2. **Security baseline drift**: Security expectations remain tacit senior knowledge rather than explicit, versioned, mechanically-enforced requirements.
3. **Operational and resilience holes**: Retry logic, idempotency, error boundaries, and recovery paths are under-specified and under-reviewed.
4. **Anti-patterns plus test theater**: Known traps (race conditions, silent failures, resource leaks) pass review despite tests that provide coverage metrics without quality validation.

Without concrete, versioned, enforceable quality mechanisms, Specrew's quality bar relies too heavily on model judgment and reviewer intuition. Fast-model implementations especially struggle: they deliver working code but silently omit hardening, skip anti-pattern checks, and generate tests that validate little beyond happy paths.

This feature converts tacit senior-quality knowledge into concrete, versioned, reviewable artifacts. It provides versioned bug-hunter lens checklists with line-item checks, stack profile presets (e.g., `node-public-ws-service`, `react-spa-public`, `node-rest-with-postgres`), a deterministic mechanical-check tier that runs before model-based review lenses (dead-field/dead-symbol detection, targeted anti-pattern heuristics, test-integrity validation), a pre-implementation hardening gate that forces explicit review of silent omissions, project-wide defect memory to learn from past failures, quality-drift detection separate from spec-drift detection, and required binding of lens execution to the strongest available reasoning class or equivalent review path. Optional reference-implementation comparison remains a deferred follow-on companion capability rather than part of the initial delivery slice. It remains additive to the existing Specrew lifecycle: it strengthens review and governance without replacing specification, planning, or task execution.

## Relationship to Existing Requirements

This feature is a **quality-governance strengthening layer** over Specrew's existing specification, planning, review, and traceability direction in `specs/001-specrew-product/spec.md`.

- It preserves Spec Kit and Specrew's existing lifecycle as the authoritative flow for specification, planning, tasks, and review.
- It strengthens the product's review and governance model by making quality expectations explicit and evidence-backed instead of mostly implicit.
- It extends stack and repository inference into quality planning, so the chosen quality bar reflects the actual technology and risk shape of the work.
- It does not create a universal mandatory dependency on any one vendor or paid tool; it governs how Specrew chooses and records the quality toolchain for each feature.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Infer a stack-aware quality profile during planning (Priority: P1)

After a feature has been sufficiently clarified, a human developer wants Specrew to infer the quality profile for the work from the clarified scope, repository signals, chosen stack, and risk areas so that the quality bar is explicit before implementation begins.

**Why this priority**: If Specrew does not make the quality profile explicit during planning, the rest of the lifecycle still depends on generic review behavior and hidden assumptions.

**Independent Test**: Use a clarified feature in a repository with recognizable stack signals and verify that planning artifacts include a quality profile, relevant risk areas, and a stack-appropriate quality tool bundle before implementation starts.

**Acceptance Scenarios**:

1. **Given** a clarified feature in a repository with clear technology signals, **When** Specrew prepares or updates the plan, **Then** it infers a quality profile from the feature scope, repository evidence, chosen stack, and relevant risk areas instead of using only a generic default.
2. **Given** a feature in a supported ecosystem, **When** Specrew records the quality profile, **Then** it selects a stack-appropriate quality tool bundle that covers code quality, design quality, verification confidence, maintainability, security, and robustness.
3. **Given** a feature whose shape materially involves concurrency, resiliency, retries, idempotency, or recovery behavior, **When** Specrew records the quality profile, **Then** it marks those dimensions as required quality concerns rather than treating them as optional reviewer intuition.

---

### User Story 2 - Make quality gates explicit and reviewable across the lifecycle (Priority: P1)

A human developer reviewing Specrew artifacts wants the planned quality bar, selected toolchain, required gates, and review evidence to be visible in the lifecycle so implementation readiness is supported by explicit evidence rather than an informal sense that the code "looks fine."

**Why this priority**: The feature delivers little value if the quality profile is inferred once but not enforced in planning and review.

**Independent Test**: Produce or inspect a plan and review flow for a supported stack and verify that the planned quality gates are explicit, the chosen toolchain is recorded, and review readiness is blocked when required evidence is missing or unjustified.

**Acceptance Scenarios**:

1. **Given** Specrew has selected a quality profile and tool bundle, **When** it generates or updates planning artifacts, **Then** the artifacts show the chosen toolchain, required quality gates, quality expectations, and any risk-specific checks in a reviewable form.
2. **Given** a required quality gate for the active feature, **When** review evidence is missing, failed, or omitted without justification, **Then** Specrew does not present the work as meeting the planned quality bar.
3. **Given** a feature where concurrency correctness or resiliency checks are not materially relevant, **When** Specrew records the quality plan, **Then** it marks those dimensions as not applicable with an explicit rationale rather than requiring irrelevant gates.
4. **Given** a feature where an optional reporting or aggregation layer is useful, **When** Specrew records the quality plan, **Then** it may include a reporting layer such as a community-edition quality dashboard without making that layer a universal mandatory dependency.

---

### User Story 3 - Activate dedicated specialist bug-hunter review when defect classes demand it (Priority: P2)

A human developer wants Specrew to use dedicated specialist review capabilities when the feature or stack carries specific defect risks that broad review alone may miss. Those specialists or review lenses should inspect concrete risk classes such as idempotency, concurrency, error handling, security, dependency health, algorithmic complexity, resource leaks, data integrity, observability, and input-validation or serialization issues when those classes are materially relevant.

**Why this priority**: Free tools and generic review improve quality, but some defect classes still benefit from targeted specialist inspection. Without an explicit specialist-review requirement, these risks remain easy to under-review.

**Independent Test**: Use a risk-tagged feature that materially involves concurrency, retries, dependency risk, security-sensitive data, or similar defect classes and verify that Specrew activates the corresponding specialist review lenses, records them in the quality plan, and requires their evidence or justified omission.

**Acceptance Scenarios**:

1. **Given** a feature whose risk profile materially includes idempotency, concurrency, or retry correctness, **When** Specrew records the quality plan, **Then** it activates a dedicated specialist review lens or equivalent focused review pass for those defect classes rather than leaving them to generic review only.
2. **Given** a feature that materially touches security-sensitive data, unsafe inputs, dependency risk, or operational failure handling, **When** Specrew records the quality plan, **Then** it activates the corresponding specialist review expectations for security, package health, and failure semantics.
3. **Given** a feature whose stack or architecture does not materially justify a given specialist bug-hunter lens, **When** Specrew records the quality plan, **Then** it marks that lens as not applicable with an explicit rationale rather than forcing irrelevant specialist review.
4. **Given** a required bug-hunter review lens is activated, **When** Specrew executes that lens, **Then** it walks the referenced versioned checklist line-by-line and records row-level status or findings rather than relying on an unstructured generic review pass.
5. **Given** both mechanical checks and model-based bug-hunter review lenses apply to a feature, **When** Specrew runs the quality gates, **Then** it completes the deterministic mechanical checks first and uses their findings as inputs to the later lens reviews rather than treating them as the same review tier.

---

### User Story 4 - Handle overrides, mixed stacks, and impractical tooling safely (Priority: P2)

A human developer wants Specrew to stay flexible when a repository uses multiple ecosystems, when a recommended tool is unsafe or impractical to run, or when a project needs a justified override, while still preserving an explicit and reviewable quality bar.

**Why this priority**: A rigid one-size-fits-all quality policy would either break on real projects or encourage teams to bypass the quality workflow entirely.

**Independent Test**: Evaluate a mixed-language or partially unsupported repository and verify that Specrew records per-surface tool choices, justified overrides, and fallback evidence instead of forcing an unsafe or misleading universal toolchain.

**Acceptance Scenarios**:

1. **Given** a repository with multiple materially relevant technology surfaces, **When** Specrew infers the quality profile, **Then** it can assign different quality tools or gates to different surfaces while still presenting one coherent feature-level quality plan.
2. **Given** a recommended quality tool cannot be safely or practically run in the current project context, **When** Specrew records the quality plan, **Then** it records the omission reason, scope, and alternative evidence path instead of silently dropping the gate.
3. **Given** a project wants to override a recommended tool or gate, **When** Specrew accepts the override, **Then** it requires explicit justification and replacement evidence or replacement expectations where applicable.
4. **Given** the repository stack is unsupported or only partially recognized, **When** Specrew prepares the quality plan, **Then** it falls back to a bounded generic quality profile with explicit unknowns and manual review expectations rather than claiming stack-specific confidence it cannot justify.

---

### Edge Cases

- Repository signals conflict with the clarified feature scope, such as a mixed repository where only one stack is active for the current change.
- A single feature spans multiple languages or execution surfaces that need different tools and different risk checks.
- The best stack-specific tool is available only as a paid offering; Specrew should prefer a practical free, open, or community alternative when possible.
- A project wants an optional community-edition reporting layer, but the underlying stack-specific checks still remain the real evidence source.
- Some recommended tools are too slow, unsafe, non-deterministic, network-dependent, or operationally impractical in the current environment.
- Concurrency correctness, retries, idempotency, or recovery behavior are only materially relevant for some feature types and should not become universal noise.
- The repository stack is custom, legacy, or insufficiently recognized for confident tool recommendation.
- A project override removes a recommended tool but does not propose equivalent evidence for the same risk area.
- Multiple specialist bug-hunter lenses may apply to the same feature; Specrew should activate the materially relevant ones without inventing irrelevant specialist work.

## Requirements *(mandatory)*

### Functional Requirements

#### Core Governance

- **FR-001**: This feature MUST remain additive to the current Specrew and Spec Kit lifecycle. It MUST strengthen specification, planning, and review quality governance without replacing the existing lifecycle or introducing a separate mandatory quality workflow outside those artifacts.

#### Versioned Lens Checklists & Stack Presets

- **FR-022**: Specrew MUST provide **Versioned Bug-Hunter Lens Checklists** as concrete, reviewable artifacts using Markdown tables. Each checklist MUST include a semantic version (e.g., `v1.2.0`), line-item checks with concrete acceptance criteria formatted as Markdown tables, row-level execution fields suitable for pass/fail/not-applicable recording, upgrade guidance when new traps are discovered, and a change log documenting what changed between versions.
- **FR-023**: Lens checklists MUST be stored in a versioned, human-readable format (e.g., Markdown) under a designated quality governance directory (e.g., `.specrew/lenses/`) so they remain git-tracked, reviewable, and auditable across iterations.
- **FR-024**: Specrew MUST provide **Stack Profile Presets** that bundle common quality configurations for recognized stacks. At minimum, presets MUST include `node-public-ws-service`, `react-spa-public`, `node-rest-with-postgres`, `python-fastapi-service`, and `dotnet-aspnet-api`. Each preset MUST specify the expected toolchain, required lenses, mechanical checks, and risk dimensions for that stack.
- **FR-024a**: The `node-public-ws-service` preset MUST include a fully-specified worked example showing concrete toolchain selections, lens activations with versioned checklist references, mechanical check configurations, and risk dimension mappings. This worked example MUST be specified in the preset artifact itself (e.g., `.specrew/presets/node-public-ws-service-v1.md`) with sufficient detail that implementers can verify correct preset application without inferring unstated expectations.
- **FR-025**: Stack presets MUST be versioned independently from lens checklists so stack-specific quality expectations can evolve without forcing global lens version changes.
- **FR-026**: When new defect patterns are discovered during iterations, Specrew MUST support a **Lens Upgrade Workflow** that allows project teams to review proposed checklist updates, approve or defer specific line items, and merge approved changes into the active project lens versions.

#### Mechanical Checks (Non-Judgment)

- **FR-027**: Specrew MUST include **Mechanical Dead-Field and Dead-Symbol Detection** as part of the quality toolchain. This check MUST identify declared fields, parameters, configuration keys, or symbols that are defined but never read, assigned but never consumed, or passed to functions that ignore them.
- **FR-028**: Specrew MUST include **Targeted Anti-Pattern Heuristics** that flag known traps without requiring deep model reasoning. Examples MUST include: unchecked array access, unhandled promise rejections, synchronous blocking in async contexts, missing error boundaries, resource acquisition without cleanup, and retry logic without backoff or circuit breaking.
- **FR-029**: Specrew MUST include **Test-Integrity Heuristics** that validate test quality beyond coverage metrics. At minimum, these heuristics MUST detect: tests with no assertions, tests that only validate mocks, tests with overly broad catch-all assertions (e.g., `expect(result).toBeTruthy()`), and tests that silently swallow exceptions.
- **FR-030**: Mechanical checks MUST emit structured, actionable findings with source locations, severity levels (error, warning, info), and remediation guidance. Findings MUST be stored in a machine-readable format (e.g., JSON) for downstream tooling integration.
- **FR-030a**: If a mechanical check rule produces unacceptable false positives or becomes noisy enough to degrade review signal, Specrew MUST support a **Mechanical Check Demotion Workflow** that allows the rule to be demoted back to an advisory lens checklist item or informational warning through an explicit reviewed workflow. Demotions MUST require human approval, include rationale and scope (project-wide or stack-specific), and be recorded in the quality governance change log. Demoted rules remain visible as advisory guidance but no longer block quality gates.

#### Pre-Implementation Hardening Gate

- **FR-031**: Specrew MUST provide a **Pre-Implementation Hardening Gate** that runs after planning but before implementation begins. This gate MUST explicitly review: security surface analysis, error-handling expectations, retry and idempotency requirements, and test-integrity targets. By default, the hardening gate MUST be bound to the strongest available reasoning or review class (per FR-038 routing policy) to maximize detection of silent omissions before implementation starts.
- **FR-032**: The hardening gate MUST require explicit sign-off or recorded rationale for any silent omissions (e.g., "no retry logic needed because operation is read-only and idempotent by nature"). Sign-off MUST be recorded in planning artifacts and remain reviewable.
- **FR-033**: The hardening gate MUST block transition to implementation if critical security, resilience, or operational concerns are marked "TBD" or remain unaddressed without explicit deferral approval. Deferrals for unresolved security, resilience, or operational concerns MUST require human developer approval; agents may recommend deferral but cannot approve it.

#### Defect Memory & Known-Traps Corpus

- **FR-034**: Specrew MUST maintain a **Project-Wide Known-Traps Corpus** that records defect patterns discovered during iterations. Each trap entry MUST include: defect category, concrete example or code snippet, detection method, remediation guidance, and discovery date. The corpus MUST be seeded from existing Specrew dogfooding findings, prior iteration defect logs, and cross-implementation learnings rather than starting empty. Initial corpus construction MAY occur during planning for this feature's first implementation iteration.
- **FR-035**: The known-traps corpus MUST be stored in a versioned, human-readable format (e.g., `known-traps.md`) under the quality governance directory so it persists across iterations and grows with project learning.
- **FR-036**: When a new defect pattern is discovered and confirmed during review, Specrew MUST prompt the team to add it to the known-traps corpus. After human approval, the trap MUST be added immediately. Once added, it MAY be promoted into a lens checklist line item or mechanical check detection rule in the same slice or next slice, depending on implementation readiness and approval.
- **FR-037**: Specrew MUST support **Trap Reapplication**: when a known trap is added to the corpus, Specrew SHOULD offer to scan existing code for similar instances of the pattern to prevent silent propagation.

#### Strongest-Class Review Binding

- **FR-038**: When multiple reasoning classes or review agents are available (e.g., fast model, standard model, premium model, delegated agents like Claude or Codex), Specrew MUST route required bug-hunter lens execution to the **strongest available reasoning class** or equivalent strongest available review path by default, not to a generic or fast model. This binding is mandatory for required lenses unless explicitly overridden.
- **FR-039**: The routing policy MUST be explicit and configurable. Projects MAY override the default to use a lower-tier model for specific lenses, but such overrides MUST be explicitly recorded with justification in quality planning artifacts and MUST require approval before taking effect.
- **FR-040**: Specrew MUST record the requested reasoning class and the effective class used for each lens execution so reviewers can verify that critical checks ran on appropriate reasoning tiers.

#### Quality-Drift Detection

- **FR-041**: Specrew MUST provide **Quality-Drift Detection** separate from spec-drift detection. Quality drift occurs when implementation meets functional requirements but degrades non-functional quality (e.g., security surface expands, error handling weakens, test integrity declines).
- **FR-042**: Quality-drift detection MUST compare the active iteration's quality evidence against the planned quality baseline FIRST, then against previous iteration baselines when they exist. It MUST flag: new mechanical check violations, lens checklist regressions, degraded test-integrity scores, expanded attack surface without corresponding security review, and removed error boundaries or retry logic. Quality-drift detection MUST run at the end of each iteration's review phase, before the iteration can be marked complete, so quality regressions are surfaced in the same iteration that introduced them.
- **FR-043**: Quality-drift events MUST be recorded in a **Quality Gap Ledger** (e.g., `quality-drift-log.md`) separate from the spec-drift log. Each drift event MUST include: drift category, affected component, baseline comparison, severity, and required remediation or approval.

#### Reference-Implementation Companion Mode (Optional, Deferred from Initial Delivery)

- **FR-044**: Specrew MAY provide an optional **Reference-Implementation Companion Mode** where a known-good reference implementation (e.g., a prior iteration, a canonical example, or a manually vetted baseline) is stored alongside the active work for comparison purposes. This companion mode is explicitly deferred from the initial delivery slice for this feature and MUST NOT be required to deliver the initial quality-profile, mechanical-check, hardening-gate, or bug-hunter-lens capabilities.
- **FR-045**: When reference-implementation mode is enabled, Specrew MUST compare the active implementation against the reference for: API contract drift, behavior divergence, quality regression, and missing hardening. Comparison findings MUST be surfaced in review artifacts.
- **FR-046**: Reference-implementation mode MUST remain optional and companion-only; it MUST NOT become a mandatory requirement for every feature or for the first implementation window of this feature. Projects MAY enable it selectively in a later slice for high-risk or security-critical work.
#### Stack-Aware Profile & Tooling

- **FR-002**: Specrew MUST infer a **Quality Profile** for the active feature from the clarified feature scope, repository signals, chosen stack, and identified risk areas rather than relying only on generic review behavior. The profile MUST reference a versioned stack preset when applicable (e.g., `node-public-ws-service v1.3.0`) or compose a custom profile from available lens checklists when no preset matches.
- **FR-003**: The inferred Quality Profile MUST explicitly evaluate, at minimum, code quality, design quality and separation of concerns, verification confidence, maintainability, security, and robustness. It MUST additionally evaluate concurrency correctness and resiliency concerns when the feature shape or repository context makes those dimensions materially relevant.
- **FR-003a**: The Quality Profile and associated tool bundle MUST enforce technology-specific software quality best practices appropriate to the active stack, even when the human developer lacks deep quality expertise in that technology. The quality bar MUST NOT be lowered due to developer unfamiliarity with stack-specific patterns, security requirements, or robustness expectations.
- **FR-004**: Specrew MUST translate the Quality Profile into a stack-aware **Quality Tool Bundle** and quality-gate set appropriate to the active ecosystem or ecosystems. The bundle MUST include mechanical checks (FR-027 through FR-030) as first-class quality gates alongside traditional linting and analysis tools.
- **FR-005**: For supported ecosystems, the Quality Tool Bundle MUST cover the relevant quality categories for that stack, including style or lint enforcement where applicable, static or type analysis where applicable, automated verification evidence, security or dependency-risk scanning where applicable, and specialized checks for resiliency or concurrency risk where materially relevant.
- **FR-006**: Specrew MUST prefer free, open, or community-available quality tools where practical for the active ecosystem. It MUST NOT require a paid or vendor-specific tool as the universal baseline across all projects.
- **FR-007**: Specrew MUST NOT assume that one universal tool is appropriate for every stack. Optional reporting or aggregation layers, including community-edition quality dashboards, MAY be included when useful, but they MUST remain optional layers over stack-appropriate evidence rather than mandatory universal dependencies.
- **FR-008**: When a repository contains multiple materially relevant stacks or execution surfaces, Specrew MUST support a composed Quality Profile that assigns stack-appropriate tools and gates per surface while preserving a coherent feature-level quality plan.
- **FR-009**: When repository signals are weak, conflicting, or unsupported, Specrew MUST fall back to a bounded generic quality profile that explicitly records what could not be inferred, what manual review is still required, and which stack-specific expectations remain unknown.

#### Planning & Review Evidence

- **FR-010**: Specrew MUST record the inferred Quality Profile, chosen Quality Tool Bundle, required quality gates, relevant risk dimensions, versioned lens checklist references, stack preset version (if applicable), and any not-applicable dimensions in planning artifacts for the active feature.
- **FR-011**: Specrew MUST make the chosen quality toolchain and quality expectations visible and reviewable in lifecycle artifacts so a human reviewer can see what was expected, what was run, and what evidence was produced.
- **FR-012**: Specrew MUST require explicit review evidence, or an approved justified exception, for each required quality gate before the feature can be presented as meeting its planned quality bar. This includes mechanical check results (FR-030), lens checklist completion status, and test-integrity validation.
#### Overrides & Flexibility

- **FR-013**: Specrew MUST allow project-level overrides to replace, defer, or omit recommended tools or gates, but every such override MUST include explicit justification, the affected quality concern, and any replacement evidence or compensating review expectation.
- **FR-014**: When a recommended tool is unsafe, impractical, or inapplicable to run in the current context, Specrew MUST record that condition explicitly and require an alternative review path or compensating evidence rather than silently treating the gate as satisfied.
- **FR-015**: Specrew MUST only require concurrency correctness, resiliency, retry, idempotency, and recovery-focused gates when the active feature shape, architecture, or risk profile makes them materially relevant. When those gates are not required, Specrew MUST record the rationale for their omission as not applicable.

#### Bug-Hunter Review Lenses

- **FR-016**: In addition to generic quality gates, Specrew MUST support dedicated **Bug-Hunter Review Lenses** or specialist review capabilities that can be activated when the risk profile materially warrants deeper inspection of specific defect classes. Each lens MUST reference a versioned checklist (FR-022) as its authoritative source of line-item checks.
- **FR-017**: At minimum, the available bug-hunter review lenses MUST be able to cover idempotency and retry safety, concurrency and race-condition risk, error handling and failure semantics, security issues, dependency or package health, algorithmic complexity or performance-path traps, and SHOULD be able to cover related classes such as resource leaks, data integrity, observability defects, configuration or secret-handling issues, input-validation or serialization issues, and state-transition correctness when those risks are materially relevant.
- **FR-018**: Specrew MUST activate the materially relevant bug-hunter review lenses from clarified scope, stack signals, architecture, and risk dimensions, and MUST record which specialist review lenses are required, optional, or not applicable for the active feature.
- **FR-019**: When a required bug-hunter review lens is activated, Specrew MUST require explicit evidence, focused findings, or an approved justified exception for that lens before the feature can be presented as meeting its planned quality bar. Lens execution MUST walk the referenced versioned checklist line-by-line and record row-level status, findings, or justified not-applicable treatment for each applicable item; generic unstructured review is insufficient. Lens execution MUST follow the strongest-class routing policy (FR-038).
- **FR-019a**: Deterministic mechanical checks defined by FR-027 through FR-030 are a separate quality-gate tier from model-based bug-hunter review lenses. Specrew MUST run the applicable mechanical checks first and surface their findings before any required model-based lens execution begins.

#### Reviewability & Traceability

- **FR-020**: The quality plan for a feature MUST remain reviewable without requiring the reviewer to infer hidden policy. At minimum, artifacts MUST show the expected gates, the tool or evidence source for each gate, the result or status, versioned lens and preset references, mechanical check findings, and any approved exceptions.
- **FR-021**: This feature MUST stay bounded to technology-aware quality governance. It MUST NOT redefine implementation methods, replace human review, or require Specrew to standardize every repository onto one universal toolchain.

### Traceability & Governance Requirements *(mandatory)*

- **TG-001**: User Story 1 MUST be covered by FR-002 through FR-010, FR-015, FR-022 through FR-026 (versioned presets and lens checklists including the `node-public-ws-service` worked example per FR-024a), and FR-003a (technology-specific best practices enforcement).
- **TG-002**: User Story 2 MUST be covered by FR-010 through FR-012, FR-020, FR-031 through FR-033 (hardening gate with strongest-class binding per updated FR-031), and FR-041 through FR-043 (quality-drift detection running at iteration review phase per updated FR-042).
- **TG-003**: User Story 3 MUST be covered by FR-016 through FR-019a, FR-022 through FR-023 (versioned lens checklists), FR-027 through FR-030a (mechanical checks including demotion workflow per FR-030a), FR-034 (known-traps corpus seeded from dogfooding per updated FR-034), and FR-038 through FR-040 (strongest-class routing).
- **TG-004**: User Story 4 MUST be covered by FR-006 through FR-009, FR-013 through FR-015, and FR-021.
- **TG-005**: Every required quality gate in a feature plan MUST be traceable to a recorded evidence source or a justified approved exception. This includes mechanical check results, row-level lens checklist completion status, and test-integrity validation.
- **TG-006**: Every omitted or replaced recommended tool MUST identify the affected quality concern, the reason for the exception, and the alternative evidence or review path.
- **TG-007**: Mixed-stack or partially unsupported repositories MUST preserve explicit stack-surface reasoning so reviewers can tell which parts of the quality plan are stack-specific and which parts use generic fallback.
- **TG-008**: The quality-governance layer defined by this feature MUST remain visibly additive to the existing Spec Kit and Specrew lifecycle rather than silently becoming a separate parallel process.
- **TG-009**: Every activated bug-hunter review lens MUST be visible in the quality plan as required, optional, or not applicable, along with its versioned checklist reference, row-level execution record, evidence source or justified exception path, and routing class used.
- **TG-010**: Every versioned lens checklist and stack preset MUST include upgrade guidance and change logs so projects can review and adopt quality improvements without silent regressions.
- **TG-011**: Every mechanical check finding (dead field, anti-pattern, test-integrity issue) MUST include source location, severity, remediation guidance, and traceability to the quality gate that triggered it. If a mechanical check rule is demoted per FR-030a, the demotion MUST be recorded with rationale, scope, and approval in the quality governance change log.
- **TG-012**: Every quality-drift event MUST be recorded in the quality gap ledger with baseline comparison, drift category, affected component, severity, and remediation or approval status.
- **TG-013**: Every pre-implementation hardening gate sign-off MUST be traceable to the specific planning artifact, reviewer identity, and date so silent omissions remain auditable.

### Requirement Ownership & Delivery Windows

| Requirement | Expected owner role(s) | Intended delivery window |
| --- | --- | --- |
| FR-001 to FR-004, FR-003a | Spec Steward, Planner, human developer | Quality-profile definition during active feature planning |
| FR-005 to FR-009 | Planner, Reviewer, stack-aware specialist roles, human developer | Tool-bundle selection and fallback handling during planning |
| FR-010 to FR-015 | Planner, Reviewer, Implementer, human developer | Planning publication and review-readiness evaluation |
| FR-016 to FR-021, FR-019a | Spec Steward, Reviewer, stack-aware specialist roles, Iteration Facilitator, human developer | Specialist bug-hunter activation, mechanical-versus-model review sequencing, exception governance, and ongoing quality-policy enforcement |
| FR-022 to FR-026 | Spec Steward, Planner, human developer | Versioned lens checklists and stack preset definition |
| FR-027 to FR-030 | Implementer, Reviewer, human developer | Mechanical check implementation and integration |
| FR-031 to FR-033 | Spec Steward, Reviewer, human developer | Pre-implementation hardening gate workflow |
| FR-034 to FR-037 | Iteration Facilitator, Reviewer, human developer | Known-traps corpus maintenance and reapplication |
| FR-038 to FR-040 | Spec Steward, Planner, human developer | Strongest-class routing policy configuration |
| FR-041 to FR-043 | Reviewer, Iteration Facilitator, human developer | Quality-drift detection and ledger maintenance |
| FR-044 to FR-046 | Spec Steward, Implementer, human developer | Optional follow-on reference-implementation companion mode after the initial quality-governance slice |

### Phased Implementation Guidance

This feature is structured for phased delivery to manage complexity and establish foundational capabilities before adding advanced workflows. The recommended implementation sequence is:

**Phase 1: Core Quality Profile & Mechanical Checks (Foundation)**
- FR-002 through FR-004, FR-003a: Infer stack-aware quality profiles from clarified features
- FR-022 through FR-026: Define and version lens checklists and stack presets; deliver `node-public-ws-service` worked example
- FR-027 through FR-030, FR-030a: Implement mechanical checks (dead-field, anti-pattern, test-integrity) with demotion workflow
- FR-010 through FR-012: Record quality profiles and tool bundles in planning artifacts
- **Rationale**: Establishes the foundation for stack-aware quality governance and deterministic mechanical checks before layering model-based review.

**Phase 2: Hardening Gate & Bug-Hunter Lenses**
- FR-031 through FR-033: Implement pre-implementation hardening gate with strongest-class binding
- FR-016 through FR-019a: Activate bug-hunter review lenses with versioned checklists and row-level execution
- FR-038 through FR-040: Enforce strongest-class routing policy for lens execution
- FR-034 through FR-037: Seed and maintain known-traps corpus from dogfooding findings
- **Rationale**: Adds specialist review capabilities and explicit hardening checkpoints after mechanical checks are proven.

**Phase 3: Quality-Drift Detection & Advanced Governance**
- FR-041 through FR-043: Implement quality-drift detection with ledger maintenance
- FR-013 through FR-015: Implement override and flexibility workflows
- FR-005 through FR-009: Implement mixed-stack and fallback handling
- **Rationale**: Adds ongoing quality monitoring and exception governance after core gates are operational.

**Phase 4: Optional Reference-Implementation Mode (Deferred)**
- FR-044 through FR-046: Optional reference-implementation companion mode for high-risk features
- **Rationale**: Explicitly deferred from initial delivery; only activated selectively after core quality governance is proven.

Planning and task generation for this feature SHOULD structure work around these phases unless a compelling reason exists to deviate. Each phase builds on the prior phase's capabilities and can be validated independently.

### Non-Goals

- Making any single named tool mandatory for every project.
- Replacing the existing Specrew planning and review lifecycle with a separate quality-management subsystem.
- Forcing irrelevant concurrency or resiliency checks onto every feature regardless of risk.
- Guaranteeing perfect stack inference for every custom or legacy repository.
- Requiring paid tooling when a practical free, open, or community alternative is available.

### Key Entities *(include if feature involves data)*

- **Quality Profile**: The explicit description of the active feature's quality concerns, including stack context, relevant risk dimensions, versioned stack preset reference (if applicable), and which quality categories must be satisfied.
- **Stack Preset**: A versioned, named bundle of quality configurations for a recognized stack (e.g., `node-public-ws-service v1.3.0`, `react-spa-public v2.1.0`). Includes toolchain specification, required lenses, mechanical checks, and risk dimensions.
- **Versioned Lens Checklist**: A concrete, line-item checklist for a specific bug-hunter review lens (e.g., `idempotency-lens v1.2.0`). Includes semantic version, line-item checks with acceptance criteria formatted as Markdown tables, row-level execution status fields, upgrade guidance, and change log.
- **Quality Tool Bundle**: The selected set of stack-appropriate tools, evidence sources, or manual review expectations used to satisfy the Quality Profile for the active feature. Includes mechanical checks as first-class gates.
- **Quality Gate**: A reviewable expectation that must be satisfied, evidenced, or explicitly excepted before the feature can be considered to meet its planned quality bar.
- **Mechanical Check**: A non-judgment quality check that emits structured findings without requiring deep model reasoning. Mechanical checks are a separate tier that runs before model-based bug-hunter review lenses. Examples: dead-field detection, anti-pattern heuristics, test-integrity validation.
- **Mechanical Check Finding**: A structured, actionable report from a mechanical check. Includes source location, severity level, remediation guidance, and traceability to the triggering quality gate.
- **Quality Evidence Record**: The lifecycle-visible record showing which quality gates were run, what evidence was produced, what the status was, versioned lens and preset references, mechanical check findings, and whether any justified exception was approved.
- **Override Justification Record**: The explicit explanation for replacing, omitting, deferring, or marking a recommended tool or gate as not applicable, including the affected concern and any compensating evidence.
- **Stack Surface**: A materially distinct technology area within the same feature, such as a frontend, service, worker, or testable execution boundary that may need a different quality tool bundle.
- **Risk Dimension**: A quality-sensitive concern that materially affects the feature, such as security, concurrency correctness, recovery behavior, retry safety, idempotency, or maintainability risk.
- **Bug-Hunter Review Lens**: A dedicated specialist review capability focused on a specific defect class that generic tooling or broad review may not catch reliably enough, such as concurrency correctness, idempotency, security, dependency health, complexity risk, or failure semantics. References a versioned lens checklist.
- **Known-Traps Corpus**: A project-wide, versioned, human-readable collection of discovered defect patterns. Each trap entry includes category, example, detection method, remediation guidance, and discovery date.
- **Quality Gap Ledger**: A per-iteration log of quality-drift events separate from spec-drift. Each entry includes drift category, affected component, baseline comparison, severity, and remediation or approval status.
- **Hardening Gate Sign-Off**: An explicit approval or recorded rationale for silent omissions identified during pre-implementation hardening review. Includes affected concern, reviewer identity, date, and justification.
- **Lens Upgrade Proposal**: A structured proposal for updating a versioned lens checklist when new defect patterns are discovered. Includes proposed line-item changes, rationale, and approval workflow.
- **Reference Implementation Baseline** (optional): A known-good implementation stored for comparison purposes in reference-implementation mode. Includes API contracts, behavior expectations, and quality benchmarks.

### Quality Planning Examples

- **Supported web application surface**:
  - A frontend or service stack receives stack-appropriate style, static analysis, automated verification, dependency-risk, and security evidence expectations.
  - Type-awareness is required when the active ecosystem normally supports it.
- **Supported managed-service surface**:
  - A service stack receives design-quality, maintainability, automated verification, package-risk, and security evidence expectations, with concurrency and resiliency gates added only when the feature shape warrants them.
- **Risk-heavy specialist review surface**:
  - A concurrency-sensitive or retry-heavy feature activates focused bug-hunter lenses for idempotency, race conditions, ordering, retry safety, and recovery behavior.
  - A security-sensitive or dependency-heavy feature activates focused bug-hunter lenses for security, package health, input validation, secret handling, and failure semantics.
- **Mixed-stack feature**:
  - A repository with a web client and a backend service records different tool choices per surface while still presenting one coherent feature-level quality plan.
- **Unsupported or unsafe-tool scenario**:
  - A legacy or partially recognized stack falls back to a generic quality profile, records unknowns explicitly, and requires manual review expectations for the uncovered risk areas.
  - A tool that is unsafe or impractical to run is omitted only with explicit justification and compensating evidence.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: After a representative supported-stack validation corpus is defined during planning for this feature, at least 90% of features in that corpus receive a non-generic Quality Profile with a versioned stack preset reference and a stack-appropriate Quality Tool Bundle before implementation begins.
- **SC-002**: In 100% of planned features using this capability, planning artifacts show the inferred Quality Profile, selected toolchain or evidence bundle, versioned stack preset and lens checklist references, required quality gates (including mechanical checks), and any approved exceptions.
- **SC-003**: In 100% of review-ready features using this capability, every required quality gate is backed by recorded evidence (including mechanical check findings, lens checklist completion, test-integrity validation) or a justified approved exception; 0 required gates are silently omitted.
- **SC-004**: In representative mixed-stack, unsupported-stack, and unsafe-tool scenarios, 100% of fallback decisions explicitly record unknowns, exceptions, or compensating review expectations instead of presenting false stack-specific confidence.
- **SC-005**: After a representative risk-tagged feature set is defined during planning, 100% of features in that set that materially involve concurrency correctness, retries, idempotency, or recovery behavior include corresponding risk-specific gates or an explicit not-applicable rationale.
- **SC-006**: In representative reviewer validation sessions, at least 85% of reviewers can identify the active quality bar, selected toolchain, versioned preset/lens references, mechanical check findings, and any approved omissions for a feature within 2 minutes by inspecting the lifecycle artifacts alone.
- **SC-007**: After a representative specialist-review validation corpus is defined during planning, 100% of features in that corpus that materially involve dedicated defect classes activate the corresponding bug-hunter review lenses with versioned checklist references and row-level execution records, or record an explicit not-applicable rationale and exception path.
- **SC-008**: In 100% of iterations, mechanical checks (dead-field detection, anti-pattern heuristics, test-integrity validation) execute successfully before model-based bug-hunter review lenses and emit structured findings with source locations, severity levels, and remediation guidance.
- **SC-009**: In 100% of iterations, the pre-implementation hardening gate blocks transition to implementation when critical security, resilience, or operational concerns are marked "TBD" or unaddressed without explicit deferral approval.
- **SC-010**: After the first 3 iterations using this capability, the known-traps corpus contains at least 5 project-specific defect patterns discovered during review, each with category, example, detection method, and remediation guidance.
- **SC-011**: In 100% of iterations with activated bug-hunter lenses, the recorded routing evidence shows that lens execution ran on the strongest available reasoning class or an explicitly approved lower-tier override with justification.
- **SC-012**: In 100% of iterations, quality-drift detection compares the active quality evidence against planned and previous baselines, flags regressions (new violations, degraded scores, expanded attack surface), and records findings in the quality gap ledger.
- **SC-013**: When reference-implementation mode is enabled for a feature, 100% of comparison findings (API drift, behavior divergence, quality regression) are surfaced in review artifacts before implementation is marked complete.

## Assumptions

- Specrew already has enough clarified feature context by planning time to infer likely stack, repository signals, and risk areas for the active feature.
- Different ecosystems legitimately need different quality tools and evidence types even when the business goal is similar.
- Community, open, or free tool options exist for many common ecosystems, but some projects will still require explicit exceptions or fallback review paths.
- Dedicated specialist review lenses may be implemented either as named specialist team members or as focused review passes, as long as their activation, scope, versioned checklist references, and evidence are explicit in the lifecycle artifacts.
- The exact recommended tool names for each supported ecosystem can evolve over time without changing the product requirement that tool selection be stack-aware, explicit, and reviewable.
- This feature governs quality expectations and evidence inside the existing lifecycle; it does not replace human judgment or guarantee full automation for unsupported stacks.
- The representative supported-stack corpus, mixed-stack scenarios, and risk-tagged validation set for success measurement will be defined during planning and implementation of this feature rather than assumed to exist already.
- Versioned lens checklists and stack presets can be maintained as Markdown files in a git-tracked directory without requiring a separate database or registry infrastructure.
- Mechanical checks (dead-field, anti-pattern, test-integrity) can be implemented as static analysis extensions or custom linting rules integrated into the quality toolchain.
- The strongest available reasoning class is determined at runtime based on configured agents and consent settings from Specrew's existing agent-delegation model (FR-021 and FR-022 from spec 001).
- The quality bar enforces technology-specific software quality best practices even when the human developer lacks deep quality expertise in that technology, ensuring consistent quality standards across all stack surfaces.
- Quality-drift detection can reuse comparison logic from spec-drift detection but operates on quality evidence baselines. It MUST compare against the active feature's planned quality baseline first, then prior iteration baselines when they exist.
- Mechanical checks can produce deterministic findings early enough to inform later model-based lens review rather than being merged into the same review pass.
- Reference-implementation mode is an optional follow-on companion capability, not a universal requirement or part of the initial delivery slice; most features will not need it.
- Known-traps corpus and lens upgrade workflows are manual-approval processes in v1; automation can be layered in later iterations. After human approval, newly found traps are added immediately and may be promoted to checklist items or mechanical checks in the same or next slice.

## Governance Alignment *(mandatory)*

- **Spec Steward**: Owns the policy boundary that quality must be explicit, stack-aware, evidence-backed, and mechanically enforceable where possible. Ensures that exceptions remain justified instead of silent, lens checklists remain versioned and reviewable, and quality-drift events are surfaced in review.
- **Iteration Facilitator**: Keeps the slice additive to the current product direction, ensures the pre-implementation hardening gate does not block unnecessarily, flags follow-on work if broader repository analysis or execution changes are discovered, and maintains the known-traps corpus as a living artifact.
- **Capacity Model**: One bounded governance slice that strengthens planning and review artifacts with explicit quality profiles, tool bundles, evidence expectations, versioned checklists and presets, mechanical checks, hardening gates, and quality-drift detection.
- **Drift Signals**: Generic quality plans that ignore stack signals, review approvals without evidence, omitted tools without justification, mixed-stack features forced into a single misleading toolchain, activated specialist bug-hunter lenses that leave no explicit evidence trail, irrelevant concurrency/resiliency gates applied as universal defaults, mechanical checks that emit no structured findings, pre-implementation gates bypassed without sign-off, known traps discovered but not recorded in the corpus, lens executions routed to weak reasoning classes without justification, or quality regressions not flagged in the quality gap ledger.
- **Human Oversight Points**: Human review of inferred quality profiles, approval of material overrides or omissions, review of fallback handling for unsupported stacks or unsafe tools, review of materially activated specialist bug-hunter lenses and their findings or exceptions, final review of evidence before implementation readiness is accepted, approval of pre-implementation hardening gate sign-offs, review of mechanical check findings and remediation plans, approval of lens checklist upgrades and stack preset changes, review of known-traps corpus entries, approval of quality-drift remediation or deferral decisions, and approval of reference-implementation mode activation for high-risk features.
