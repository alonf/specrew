# Contract: F-049 Release Pipeline Hardening + Substantive Intake Slice Public Surface

**Feature**: `049-pipeline-hardening-intake`  
**Stability**: pre-1.0

---

## Docker E2E Verification Harness (`test-publish-harness.ps1`)

A private test validation utility executed automatically by CI and developers to verify package integrity before public publishing.

### Exported API

| Symbol | Signature | Purpose | Errors |
| --- | --- | --- | --- |
| `Invoke-PackageVerification` | `-PackagePath <string> [-BaselineVersion <string>]` | Installs baseline, unpacks candidate, verifies all `FileList` assets, runs updates | Throws on missing files, manifest drift, or update failure |

### Invariants

- Every item listed in the candidate manifest's `FileList` must exist on the local file system inside the installed container directory.
- `specrew update` must exit with exit code `0` and leave local templates identical to the mirror template baseline.
- If any assertion fails, the test suite must write a clear diagnostics output, exit the shell with exit code `1`, and successfully prevent publication.

---

## Persona-Driven Specify Interface (`specrew specify`)

A new user-facing CLI command interface within the specify phase governed by interactive, branching persona templates.

### Exported API

| Symbol | Signature | Purpose | Errors |
| --- | --- | --- | --- |
| `specrew specify` | `[-Persona <string>] [-Interactive] [-Force]` | Triggers specify intake, launches Mode A/B/C console questions, and compiles the spec.md | Throws on invalid persona input |

### Invariants

- Spec generation must map to one of the **4 custom templates** (Product Manager, UX/UI, Architect, AI Researcher / Project Manager).
- Choosing `Other` or `I don't know` must never throw an exception; it must invoke the AI domain research parser to compute sensible stack-aware defaults.
