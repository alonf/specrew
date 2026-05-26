# Data Model: Release Pipeline Hardening + Substantive Intake Slice

**Feature**: `049-pipeline-hardening-intake`  
**Date**: 2026-05-27  
**Purpose**: Define entities, attributes, relationships, and validation rules for F-049.

## Entity: SpecifyIntakeSession

**Purpose**: Represents the interactive state of a `/speckit.specify` intake session, captured dynamically during console prompts.

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| `Persona` | Enum | Yes | `product-manager`, `ux-designer`, `architect`, `project-manager` | Governs Specify template rendering and interview questions |
| `IntakeCatalog` | Dict | Yes | Must contain up to 12 categories | Stores user choices across the 12 intake categories |
| `Mode` | Enum | Yes | `ModeA`, `ModeB`, `ModeC` | Branching logic computed from input completeness |
| `Status` | Enum | Yes | `in-progress`, `sufficient`, `incomplete` | Active state of the intake process |
| `CreatedAt` | DateTime | Yes | UTC ISO 8601 | Capture initialization timestamp |

### Lifecycle / Relationships

Created when `/speckit.specify` is invoked; mutated step-by-step as the user responds to console prompts; destroyed or persisted to `.specify/feature.json` once `spec.md` is successfully compiled.

---

## Entity: DockerTestConfiguration

**Purpose**: Defines parameters governing the pre-publish E2E layout and manifest parity check execution.

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| `BaselineVersion` | String | Yes | Valid SemVer format (e.g. `0.27.6`) | Previous stable version installed as test base |
| `CandidatePackagePath` | String | Yes | Path to candidate package | NuPkg or Zip module package tested for omissions |
| `VerificationState` | Enum | Yes | `untested`, `running`, `passed`, `failed` | Current status of pre-publish E2E checks |
| `ManifestVersionMatches` | Boolean | Yes | True only when versions match in config + manifest | Prop 134 version pin drift assertion result |

### Lifecycle / Relationships

Created at the start of a pre-publish pipeline step; executed entirely in-memory within the Linux PowerShell test runner container; results in a GHA block if `VerificationState` equals `failed`.
