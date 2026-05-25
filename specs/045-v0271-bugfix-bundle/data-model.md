# Data Model — v0.27.1 Bug-Fix Bundle

## Entity: RuntimeEntryPointContext

- **Purpose**: Captures invocation context for `specrew` top-level + lifecycle entrypoints.
- **Fields**:
  - `command` (enum: `root-version-alias`, `version`, `start`, `init`)
  - `projectPath` (string)
  - `isSpecrewProject` (boolean)
  - `isForceMode` (boolean, init-only)
  - `warningState` (enum: `none`, `unknown-version`, `invalid-arg`)
- **Validation Rules**:
  - `root-version-alias` must map to version command parity output.
  - `unknown-version` warning only valid when installed and baseline versions are unresolved.

## Entity: SkillCatalogState

- **Purpose**: Represents required catalog-directory presence and repair action.
- **Fields**:
  - `requiredRoots` (set: `.claude/skills`, `.github/skills`, `.agents/skills`)
  - `missingRoots` (set)
  - `repairAttempted` (boolean)
  - `repairStatus` (enum: `not-needed`, `repaired`, `failed`)
  - `repairSource` (enum: `start-auto-repair`, `init-deploy-flow`)
- **Validation Rules**:
  - On `start`, any non-empty `missingRoots` triggers auto-repair before normal continuation.
  - On `init` (force and non-force), missing roots are deployable gaps and must not short-circuit as success.

## Entity: BrownfieldOwnershipSignal

- **Purpose**: Decides canonical ownership vs conflict classification in brownfield merge.
- **Fields**:
  - `hasSelfHostingExtension` (boolean; from `extensions/specrew-speckit/`)
  - `hasExistingSquadAgentsPath` (boolean; from `.squad/agents/`)
  - `classification` (enum: `canonical-source`, `conflict-candidate`)
  - `classificationReason` (string)
- **Validation Rules**:
  - If `hasSelfHostingExtension=true` and `.squad/agents/` exists, classification must be `canonical-source`.
  - If self-hosting signal absent, standard conflict rules apply.

## Entity: PatchFindingRecord

- **Purpose**: Tracks each of the 7 post-release findings through closure.
- **Fields**:
  - `findingId` (string: `F1..F7`)
  - `storyRef` (enum: `US1`, `US2`, `US3`)
  - `requirementRefs` (set: FR-001..FR-008)
  - `findingType` (enum: `actionable-defect`, `stale-review-artifact`)
  - `closureStatus` (enum: `planned`, `fixed`, `documented-stale-close`)
  - `evidenceRefs` (list of command outputs and/or file paths)
- **State Transitions**:
  - `planned -> fixed` for actionable defects.
  - `planned -> documented-stale-close` for stale findings with explicit disposition.

## Entity: UpdateGuidanceDecisionPath

- **Purpose**: Encodes operator-facing update and redeployment decisions.
- **Fields**:
  - `updateMode` (enum: `normal-update`, `force-update`, `install-with-skip-publisher-check`)
  - `riskNote` (string)
  - `requiresRedeploy` (boolean)
  - `redeployTrigger` (string; e.g., missing skill catalogs, stale runtime surfaces)
  - `docLocation` (string)
- **Validation Rules**:
  - Guidance must explicitly state when `specrew init` rerun is required post-update.
  - Force/publisher-check semantics must include safe-use boundaries.
