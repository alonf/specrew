# Plan: F-049 Release Pipeline Hardening + Substantive Intake Slice

**Feature**: `049-pipeline-hardening-intake`  
**Date**: 2026-05-27  
**Status**: Draft  
**Input**: User F-049 scope: Docker pre-publish E2E harness, durable troubleshooting guide, and persona-driven specification intake.

---

## 1. Summary & Goals

Implement critical pipeline hardening and a highly interactive specify intake system for the Specrew ecosystem under target version **`0.27.7`**. 

The feature is split into three substantive iterations:
- **Iteration 001**: Pre-publish Docker E2E verification harness that blocks release on layout or manifest drift. Integrates a "version pin drift detection" assertion from Proposal 134 to detect version configuration discrepancies for free.
- **Iteration 002**: Complete recovery and troubleshooting documentation (`docs/troubleshooting.md`), registered in `Specrew.psd1`'s `FileList` in the same commit, and cross-referenced in other docs.
- **Iteration 003**: Persona-driven specification intake (`/speckit.specify`) with 4 custom personas, a 12-category catalog, dynamic Mode A/B/C branching, multi-choice options with escape hatches, and proactive AI research capabilities.

---

## 2. Clarify Outcome

All clarifications are recorded in `spec.md`. Key design outcomes:
1. **Proposal 134 Scope Incremental Integration**: Approved. We will add a **"manifest pin drift detection"** assertion inside Iteration 1's Docker E2E test suite to prevent config discrepancies for free, while deferring other F-051 features.
2. **Interactive Specify Mode C UX Console Behavior**: Numbered list menus and standard `Read-Host` prompts inside standard PowerShell cross-platform consoles.
3. **Docker Harness CI Image Caching**: Reuse standard `mcr.microsoft.com/powershell:lts-ubuntu-22.04` and reuse cached layers of previous actions.

---

## 3. Substantive Decisions

### Decision 1: Pre-Publish Docker Harness Architecture
Create a Linux-based PowerShell LTS Docker container E2E harness. This harness downloads the candidate `.nupkg`/`.zip` package, bootstraps a fresh project via `specrew init` with the previous stable version (v0.27.6), compares every file against `Specrew.psd1`'s `FileList` to detect missing files, runs `specrew update`, and verifies local layout parity. Wired directly into `.github/workflows/publish-module.yml` as a blocking pre-publish gate.

### Decision 2: FileList Integrity Spot-Checking and Documentation
Author a complete troubleshooting guide `docs/troubleshooting.md` addressing PSGallery side-by-side caching, FileList drops, deploy-script exceptions, stale-state recovery, and clean-reinstalls. Registered in `Specrew.psd1` FileList in the same commit to satisfy our own packaging rule, and cross-referenced in other guides.

### Decision 3: `/speckit.specify` Persona-Driven Intake Flow
Extend the specify phase with 4 personas: Product Manager, UX/UI Specialist, Architect, and AI Researcher / Project Manager. Incorporate a 12-category intake catalog. Dynamically branch into Mode A (Sufficient -> confirmation), Mode B (Partial -> targeted clarification), or Mode C (Vibe -> interactive interview) with `"Other"` and `"I don't know, you decide"` fallback options, triggering proactive AI research.

---

## 4. Pre-Implementation Review Artifacts

- **Data Model**: `specs/049-pipeline-hardening-intake/data-model.md`
- **Quickstart**: `specs/049-pipeline-hardening-intake/quickstart.md`
- **Contract**: `specs/049-pipeline-hardening-intake/contracts/pipeline-hardening-intake.md`
- **Review Diagrams**: `specs/049-pipeline-hardening-intake/review-diagrams.md`

---

## 5. Implementation Slices

### Iteration 001: Docker Pre-Publish Verification

**Slice 1: Docker pre-publish E2E harness (FR-001/002/003/004)**
- **Files**: `scripts/internal/test-publish-harness.ps1`, `tests/Dockerfile.publish-test`, `.github/workflows/publish-module.yml`.
- **Approach**: Create the Dockerfile and test harness. Bootstraps a fresh project via `specrew init` using the previous stable version (v0.27.6), installs the candidate, and checks every item in `Specrew.psd1` FileList. Executes `specrew update` and asserts success.
- **Tests**: Local and CI validation of the Docker test suite running against correct and intentionally corrupt candidates.

**Slice 2: Manifest version pin drift assertion (FR-012 / Prop 134)**
- **Files**: `scripts/internal/test-publish-harness.ps1`.
- **Approach**: Write an assertion checking for version mismatch drift between `.specrew/config.yml` (`specrew_version`), `Specrew.psd1` (`ModuleVersion`), and other versioned manifests.

**Slice 3: CI Pre-Publish integration (FR-005)**
- **Files**: `.github/workflows/publish-module.yml`.
- **Approach**: Add a block executing the Docker harness before the publishing step to PSGallery.

---

### Iteration 002: Troubleshooting Guide & Cross-References

**Slice 4: Durable Troubleshooting documentation (FR-006)**
- **Files**: `docs/troubleshooting.md`.
- **Approach**: Codify standard recovery flows, caching, FileList drops, deployscript exceptions, and clean-reinstall sequences.

**Slice 5: FileList registration and cross-referencing (FR-007)**
- **Files**: `Specrew.psd1`, `README.md`, `docs/getting-started.md`, `docs/user-guide.md`.
- **Approach**: Add the troubleshooting doc to `Specrew.psd1` FileList and add cross-reference links in the markdown files.

---

### Iteration 003: Substantive specify Intake

**Slice 6: Persona-Driven Specify templates (FR-008)**
- **Files**: `extensions/specrew-speckit/prompts/persona-templates.json` or scripts supporting specify persona selection.
- **Approach**: Define the 4 target personas and their governing specify templates.

**Slice 7: Intake Catalog and Modes (FR-009/010/011)**
- **Files**: `/speckit.specify` implementation scripts (or CLI wrapper).
- **Approach**: Build the 12-category intake catalog and implement Mode A/B/C console branching logic with multi-choice escape hatches.

---

## 6. FR to Test Mapping

| FR | Verified by |
| --- | --- |
| FR-001 | Dockerfile uses PowerShell LTS on Ubuntu 22.04 |
| FR-002 | Harness pulls previous v0.27.6 and successfully runs E2E test |
| FR-003 | Test fails if any file declared in `Specrew.psd1` FileList is missing in package |
| FR-004 | Update E2E test verifies clean mirror parity and layout after `specrew update` |
| FR-005 | Publish workflow is blocked and halts if Docker harness fails |
| FR-006 | Troubleshooting guide exists covering standard cache/deploy recovery |
| FR-007 | Integration test asserts `docs/troubleshooting.md` registered in manifest |
| FR-008 | Specify integration test asserts correct spec generation for all 4 personas |
| FR-009 | Specify catalog contains the 12 key software parameter categories |
| FR-010 | Mock tests cover intake branching for Mode A, Mode B, and Mode C |
| FR-011 | Choosing "Other" or "I don't know" successfully auto-derives optimal stack-aware defaults |
| FR-012 | Harness fails E2E validation if there is a version mismatch drift in manifests |

---

## 7. Quality Planning

Resolved profile: `quality-profile.custom-composition.v1`.

### Required Quality Gate
| Required Quality Gate | Category | Evidence Source |
| --- | --- | --- |
| `dead-field` | `mechanical` | `specs/049-pipeline-hardening-intake/iterations/001/quality/mechanical-findings.json` |
| `anti-pattern` | `mechanical` | `specs/049-pipeline-hardening-intake/iterations/001/quality/mechanical-findings.json` |
| `test-integrity` | `mechanical` | `specs/049-pipeline-hardening-intake/iterations/001/quality/mechanical-findings.json` |
| `stack-tooling-evidence` | `tooling` | `specs/049-pipeline-hardening-intake/iterations/001/quality/quality-evidence.md` |
| `quality-lens-review` | `manual-evidence` | `specs/049-pipeline-hardening-intake/iterations/001/quality/quality-evidence.md` |

### Not-Applicable Dimensions and Rationale
| Dimension | Rationale | Omitted Gates |
| --- | --- | --- |
| `concurrency-correctness` | No repository or feature signal shows material shared-state, parallel, or realtime concurrency behavior for this Phase 1 slice. | `concurrency-correctness-review` |
| `resiliency` | The current Phase 1 slice does not materially depend on retries, reconnect, or degraded recovery behavior beyond the baseline robustness expectation. | `resiliency-semantics-review` |
| `retry-idempotency-and-recovery` | Retry, idempotency, and recovery-specific gates are not required because the active feature shape does not present a material retry or recovery workflow in this slice. | `retry-idempotency-review` |

### Explicit Phase 2+ Deferrals
- Pre-implementation hardening gate sign-off and blocking semantics remain deferred to Phase 2+.
- Dedicated bug-hunter lens execution and strongest-class routing remain deferred to Phase 2+.
- Quality-drift logic, mixed-stack override routing, and reference-implementation comparison remain deferred to Phase 2+.

---

## 8. Risks & Mitigations

- **Docker daemon unavailability in CI**: Docker might not be running in GHA.
  - *Mitigation*: Ensure the runner has standard root privileges and is running on a standard Ubuntu host.
- **FileList omissions re-introduced**: Future additions might bypass `FileList`.
  - *Mitigation*: The pre-publish Docker harness guarantees a deterministic layout mismatch block.
- **Specify intake complexity**: Persona branching might become too noisy or long.
  - *Mitigation*: Provide clear numbered options and quick "I don't know, you decide" fallbacks.
- **Metadata versioning drift**: Manual config changes cause release errors.
  - *Mitigation*: Integration of version pin drift check within Iteration 1 E2E harness.
