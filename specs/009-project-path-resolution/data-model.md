# Data Model: Project Path Resolution in Specrew Entry-Point Scripts

**Date**: 2026-05-09
**Spec**: [spec.md](spec.md)  
**Plan**: [plan.md](plan.md)

## Entities

### Resolve-ProjectPath Helper

Canonical path-normalization function for user-supplied relative project-like paths.

**Location**: `extensions/specrew-speckit/scripts/shared-governance.ps1` and mirrored `.specify/extensions/specrew-speckit/scripts/shared-governance.ps1`

| Field | Type | Description |
| --- | --- | --- |
| `input_path` | string | User-supplied path argument such as `.` or `specs/009-project-path-resolution` |
| `is_rooted` | boolean | Whether the input is already absolute/UNC |
| `powershell_cwd` | path | `(Get-Location).Path` at call time |
| `resolved_path` | path | Absolute path returned to the caller |
| `resolution_mode` | enum | `rooted-pass-through` or `relative-against-pwd` |

**Validation**:

- Rooted inputs keep prior `GetFullPath` behavior.
- Relative inputs are resolved against `powershell_cwd`, not `.NET CurrentDirectory`.
- Non-existent relative inputs still normalize to the correct attempted absolute path for error reporting.

---

### Path Resolution Call Site

One script location that accepts a user-supplied path-like parameter and normalizes it before use.

| Field | Type | Description |
| --- | --- | --- |
| `script_path` | path | PowerShell script containing the call site |
| `parameter_name` | enum | `ProjectPath`, `FeaturePath`, `SpecPath`, `IterationPath`, `DispositionPath`, or equivalent |
| `surface_type` | enum | `entry-point`, `internal-source-extension`, `internal-mirrored-extension` |
| `current_resolution` | enum | `shared-helper`, `inline-equivalent`, `raw-getfullpath`, `exempt` |
| `target_resolution` | enum | `shared-helper`, `inline-equivalent`, or `exempt` |
| `exemption_rationale` | string? | Required if the call site remains exempt |

**Validation**:

- Every in-scope call site must end in `shared-helper` or `inline-equivalent`, unless an explicit exemption is documented.
- Entry-point call sites should prefer the shared helper for consistency.
- Source extension and mirrored extension call sites must stay behaviorally aligned.

---

### Path Resolution Regression Case

Deterministic integration scenario proving that the bug is fixed for a representative command.

**Location**: `tests/integration/project-path-resolution-regression.ps1`

| Field | Type | Description |
| --- | --- | --- |
| `command_label` | string | Human-readable name such as `specrew start` or `specrew review` |
| `script_path` | path | Invoked PowerShell script |
| `project_path_argument` | string | Usually `.` or omitted for default behavior |
| `powershell_location` | path | Actual project directory set with `Set-Location` |
| `dotnet_current_directory` | path | Intentionally different non-project directory |
| `expected_outcome` | enum | `passes-bootstrap-gate`, `passes-info-gate`, `preserves-error-message` |
| `observed_output_assertions[]` | string[] | Strings or predicates used to verify behavior |

**Validation**:

- At least the representative entry points from User Stories 1 and 2 must be exercised.
- The test must fail if the script resolves `.` against the wrong absolute directory.
- The same lane must include the static anti-pattern scan for disallowed raw `GetFullPath($SomePathParam)` usage.

---

### Static Anti-Pattern Rule

Machine-checkable definition of the historical bug pattern.

| Field | Type | Description |
| --- | --- | --- |
| `rule_id` | string | Stable identifier, e.g. `raw-relative-getfullpath` |
| `disallowed_patterns[]` | string[] | Raw `GetFullPath($ProjectPath/$FeaturePath/$SpecPath/$IterationPath/$DispositionPath)` forms outside the helper |
| `allowed_locations[]` | path[] | Shared helper file and any explicitly justified inline equivalents |
| `failure_message` | string | Actionable output explaining the remediation path |
| `evidence_command` | string | Command or lane that runs the scan |

**Validation**:

- The rule must produce zero findings on a compliant tree.
- Any new violation must point maintainers to `Resolve-ProjectPath` or the equivalent inline fix pattern.

---

### Known Trap Entry

Reusable quality-governance record for the path-resolution defect.

**Location**: `.specrew/quality/known-traps.md`

| Field | Type | Description |
| --- | --- | --- |
| `category` | string | `path-resolution` |
| `broken_pattern` | string | Concrete example of raw `GetFullPath($ProjectPath)` against a relative user path |
| `detection_method` | string | Static anti-pattern scan from feature 009 |
| `remediation_guidance` | string | Point to `Resolve-ProjectPath` or equivalent inline relative-to-PWD resolution |
| `discovery_date` | date | `2026-05-09` |
| `reapplication_result` | string | Link or summary of trap reapplication before closure |

**Validation**:

- All five required fields from FR-008 must be populated.
- Trap reapplication must scan the current codebase before the feature closes.

## Relationships

- `Resolve-ProjectPath Helper` is the source of truth for `Path Resolution Call Site` migration.
- Each `Path Resolution Regression Case` proves one or more migrated `Path Resolution Call Site` records.
- `Static Anti-Pattern Rule` guards the repository against future non-compliant call sites.
- `Known Trap Entry` records the defect pattern and links back to the scan/remediation path.
