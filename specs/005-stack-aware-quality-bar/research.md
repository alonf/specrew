# Research: Stack-Aware Quality Bar (Phase 1 / First Slice)

**Date**: 2026-05-07  
**Spec**: [spec.md](spec.md)  
**Plan**: [plan.md](plan.md)

## Research Tasks

### R1: Where should versioned presets and lens checklists live?

**Decision**: Source presets and lens checklists from `extensions/specrew-speckit/templates/quality/`, then scaffold them into downstream `.specrew/presets/` and `.specrew/lenses/`, with explicit path metadata added to downstream `.specrew/config.yml`.

**Rationale**: The repo already treats `.specrew/` as the downstream governance root via `scaffold-governance.ps1` and `.specrew/config.yml`, while `extensions/specrew-speckit/templates/` is the extension-owned source of truth for generated assets. Keeping quality assets in that same pattern makes them reviewable and discoverable without creating a new storage subsystem.

**Alternatives considered**:

- Storing canonical preset/lens files directly in repo-root `.specrew/`: rejected because this repo is the product source, not the downstream deployed state.
- Embedding preset definitions only inside scripts: rejected because FR-022 through FR-025 require human-reviewable, versioned artifacts.
- Hiding paths behind script constants only: rejected because validation and future tooling need explicit discovery metadata.

---

### R2: What format should Phase 1 use for versioned presets and checklists?

**Decision**: Use semantic-versioned Markdown artifacts with normative tables, required section headers, upgrade guidance, and change logs. The `node-public-ws-service` worked example will be a concrete preset artifact, not an example tucked into prose elsewhere.

**Rationale**: The spec explicitly calls for Markdown tables and reviewable versioned artifacts, and the repo's existing contracts and iteration artifacts are already Markdown-first. Markdown keeps the assets auditable in PR review while still letting scripts validate required headings, versions, and table shapes.

**Alternatives considered**:

- YAML/JSON-only preset definitions: rejected because they are less reviewer-friendly and would drift from current repo conventions.
- Free-form prose checklists: rejected because FR-022 requires line-item execution-ready structure.
- A single monolithic quality handbook: rejected because FR-025 requires independent preset versioning.

---

### R3: How should structured mechanical findings be represented?

**Decision**: Emit one shared JSON envelope for all Phase 1 mechanical checks, with top-level run metadata and a `findings[]` array containing gate ID, rule ID, stack surface, source location, severity, remediation guidance, and traceability fields.

**Rationale**: The evaluation scorer already uses structured PowerShell objects serialized to JSON, and FR-030 explicitly requires machine-readable findings for downstream tooling. A single schema across dead-field, anti-pattern, and test-integrity rules keeps validation simple and prevents each rule family from inventing incompatible output shapes.

**Alternatives considered**:

- One bespoke JSON shape per check type: rejected because downstream validation would become brittle.
- Markdown-only findings: rejected because FR-030 requires machine-readable storage.
- Writing directly to review prose without a schema: rejected because it would make enforcement and tooling integration difficult.

---

### R4: Where should quality evidence be recorded in lifecycle artifacts?

**Decision**: Keep quality evidence additive to the existing feature/iteration artifact model: feature `plan.md` records the inferred quality profile and planned gates, while iteration-level `quality/quality-evidence.md` and `quality/mechanical-findings.json` record execution evidence and exceptions.

**Rationale**: Specrew already enforces lifecycle visibility through feature and iteration artifacts, and the constitution requires process claims to remain tied to real artifacts. Recording quality evidence inside the current lifecycle keeps reviewability high without inventing a separate quality-only process, while still giving machine-readable findings their own JSON sidecar.

**Alternatives considered**:

- A separate repo-wide quality dashboard as the primary source: rejected for Phase 1 because it would create a parallel workflow.
- Only storing evidence in iteration `review.md`: rejected because structured findings need a dedicated machine-readable home and a clearer gate matrix.
- Deferring evidence recording until later phases: rejected because FR-010 through FR-012 are in scope for this slice.
