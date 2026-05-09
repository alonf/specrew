# Research: Project Path Resolution in Specrew Entry-Point Scripts

**Date**: 2026-05-09
**Spec**: [spec.md](spec.md)  
**Plan**: [plan.md](plan.md)

## Decisions

### R1: Should feature 009 preserve the interim `Resolve-ProjectPath` helper or replace it with a new abstraction?

**Decision**: Preserve the interim `Resolve-ProjectPath` helper in `extensions/specrew-speckit/scripts/shared-governance.ps1` as the canonical implementation and reuse it across in-scope call sites.

**Rationale**: The spec clarification explicitly blesses the current helper as the reference implementation for FR-001. Reusing it keeps absolute/UNC handling unchanged, minimizes behavioral drift, and concentrates the relative-path fix in one reviewable place.

**Alternatives considered**:

- Introduce a second helper name or abstraction layer: rejected because it adds indirection without solving a new problem.
- Inline custom `(Get-Location)` logic everywhere: rejected because it would duplicate the same bug-prone logic across many scripts.

---

### R2: Which call sites must be treated as the authoritative audit scope for feature 009?

**Decision**: Treat the five user entry points plus the mirrored governance scripts that resolve user-supplied `ProjectPath`, `FeaturePath`, `SpecPath`, `IterationPath`, or `DispositionPath` values as the in-scope audit list.

**Rationale**: The bug is user-visible first in the entry points, but the same broken idiom persists in internal scripts that are invoked by those entry points or by governance lanes. Both `extensions/` and `.specify/extensions/` must stay aligned, otherwise the source tree and deployed extension tree would drift.

**Alternatives considered**:

- Fix only `specrew-init`, `specrew-team`, and `specrew-review`: rejected because internal helper scripts would still behave inconsistently.
- Replace every `GetFullPath` use in the repository: rejected because many URI/diff helpers operate on already rooted paths and are outside the feature’s defect model.

### Audit Matrix

| File | Path parameter(s) | Decision |
| --- | --- | --- |
| `scripts/specrew-start.ps1` | `ProjectPath` | Already compliant; keep current helper usage |
| `scripts/specrew-update.ps1` | `ProjectPath` | Already compliant; keep current helper usage |
| `scripts/specrew-init.ps1` | `ProjectPath` | Migrate to shared helper |
| `scripts/specrew-team.ps1` | `ProjectPath` (5 call sites) | Migrate all call sites to shared helper/equivalent |
| `scripts/specrew-review.ps1` | `ProjectPath` | Migrate to shared helper |
| `extensions/specrew-speckit/scripts/resolve-quality-profile.ps1` | `ProjectPath`, `FeaturePath`, `SpecPath` | Migrate in source extension |
| `extensions/specrew-speckit/scripts/run-hardening-gate.ps1` | `ProjectPath`, `FeaturePath`, `IterationPath`, `SpecPath` | Migrate in source extension |
| `extensions/specrew-speckit/scripts/run-mechanical-checks.ps1` | `ProjectPath`, `FeaturePath`, `IterationPath`, `SpecPath`, `DispositionPath` | Migrate in source extension |
| `extensions/specrew-speckit/scripts/validate-governance.ps1` | iteration/spec path joins based on user input | Normalize relative-path handling consistently |
| `extensions/specrew-speckit/scripts/brownfield-merge.ps1` | `ProjectPath` | Migrate in source extension |
| `extensions/specrew-speckit/scripts/deploy-speckit-extension.ps1` | `ProjectPath` | Migrate in source extension |
| `extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1` | `ProjectPath` | Migrate in source extension |
| `extensions/specrew-speckit/scripts/drift-diff.ps1` | `SpecPath`, `ImplementationPath` | Migrate in source extension |
| `extensions/specrew-speckit/scripts/scaffold-governance.ps1` | `ProjectPath` | Migrate in source extension |
| `extensions/specrew-speckit/scripts/scaffold-iteration-plan.ps1` | `SpecPath`, `IterationConfigPath` | Migrate in source extension |
| mirrored `.specify/extensions/specrew-speckit/scripts/*` copies | same as source extension | Apply the same changes to preserve deployment parity |

---

### Audit Findings (Entry Points, Pre-Change)

- `scripts/specrew-start.ps1` and `scripts/specrew-update.ps1` already dot-source `shared-governance.ps1` and call `Resolve-ProjectPath` for `ProjectPath`. No change required beyond verification.
- `scripts/specrew-init.ps1` resolves `ProjectPath` with `[System.IO.Path]::GetFullPath($ProjectPath)` and does not load the shared helper.
- `scripts/specrew-team.ps1` contains five `GetFullPath($ProjectPath)` call sites across add/update/remove/list flows and does not load the shared helper.
- `scripts/specrew-review.ps1` resolves `ProjectPath` via `GetFullPath($ProjectPath)` (other `GetFullPath` usage is limited to review-path diff helpers and is not part of the user-supplied project-path defect model).

### Audit Findings (Internal Governance Scripts, Pre-Change)

- `extensions/specrew-speckit/scripts/resolve-quality-profile.ps1` resolves `ProjectPath`, `FeaturePath`, and `SpecPath` via `GetFullPath` without loading the shared helper.
- `extensions/specrew-speckit/scripts/run-hardening-gate.ps1` loads `shared-governance.ps1` but resolves `FeaturePath`, `IterationPath`, and `SpecPath` via `GetFullPath` when user-supplied.
- `extensions/specrew-speckit/scripts/run-mechanical-checks.ps1` resolves `ProjectPath`, `FeaturePath`, `IterationPath`, `SpecPath`, and `DispositionPath` via `GetFullPath` without the shared helper.
- `extensions/specrew-speckit/scripts/validate-governance.ps1` resolves `ProjectPath` via `Resolve-Path`, but still normalizes iteration/spec paths using `GetFullPath` helpers tied to user inputs.
- `extensions/specrew-speckit/scripts/brownfield-merge.ps1`, `deploy-speckit-extension.ps1`, and `deploy-squad-runtime.ps1` resolve `ProjectPath` via `GetFullPath` without the shared helper.
- `extensions/specrew-speckit/scripts/drift-diff.ps1` resolves `SpecPath` and `ImplementationPath` via `GetFullPath` without the shared helper.
- `extensions/specrew-speckit/scripts/scaffold-governance.ps1` resolves `ProjectPath` via `GetFullPath` without the shared helper.
- `extensions/specrew-speckit/scripts/scaffold-iteration-plan.ps1` resolves `SpecPath` and `IterationConfigPath` via `GetFullPath` without the shared helper.

### Mirrored Extension Parity (Pre-Change)

- The `.specify/extensions/specrew-speckit/scripts/*` mirrors reflect the same `GetFullPath` patterns as the source extension scripts for the in-scope files, so any path-resolution fix must be applied in both trees.

---

### Migration Matrix (Post-Change)

| File | Path parameter(s) | Resolution method | Notes |
| --- | --- | --- | --- |
| `scripts/specrew-start.ps1` | `ProjectPath` | `Resolve-ProjectPath` (shared helper) | Verified existing helper-backed behavior; no change required |
| `scripts/specrew-update.ps1` | `ProjectPath` | `Resolve-ProjectPath` (shared helper) | Verified existing helper-backed behavior; no change required |
| `scripts/specrew-init.ps1` | `ProjectPath` | `Resolve-ProjectPath` (shared helper) | Shared helper now imported from `extensions/specrew-speckit/scripts/shared-governance.ps1` |
| `scripts/specrew-team.ps1` | `ProjectPath` (5 call sites) | `Resolve-ProjectPath` (shared helper) | Shared helper imported; all call sites updated |
| `scripts/specrew-review.ps1` | `ProjectPath` | `Resolve-ProjectPath` (shared helper) | Shared helper imported; review diff helpers unchanged |
| `extensions/specrew-speckit/scripts/resolve-quality-profile.ps1` | `ProjectPath`, `FeaturePath`, `SpecPath` | `Resolve-ProjectPath` (shared helper) | Shared helper imported |
| `extensions/specrew-speckit/scripts/run-hardening-gate.ps1` | `ProjectPath`, `FeaturePath`, `IterationPath`, `SpecPath` | `Resolve-ProjectPath` (shared helper) | Shared helper already present; path normalization updated |
| `extensions/specrew-speckit/scripts/run-mechanical-checks.ps1` | `ProjectPath`, `FeaturePath`, `IterationPath`, `SpecPath`, `DispositionPath` | `Resolve-ProjectPath` (shared helper) | Shared helper imported; disposition path normalization updated |
| `extensions/specrew-speckit/scripts/validate-governance.ps1` | `ProjectPath`, `IterationPath` | `Resolve-ProjectPath` + `Resolve-Path` for existence checks | Artifact joins remain rooted to resolved project/iteration roots |
| `extensions/specrew-speckit/scripts/brownfield-merge.ps1` | `ProjectPath` | `Resolve-ProjectPath` (shared helper) | Shared helper imported |
| `extensions/specrew-speckit/scripts/deploy-speckit-extension.ps1` | `ProjectPath` | `Resolve-ProjectPath` (shared helper) | Shared helper imported |
| `extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1` | `ProjectPath` | `Resolve-ProjectPath` (shared helper) | Shared helper imported |
| `extensions/specrew-speckit/scripts/drift-diff.ps1` | `SpecPath`, `ImplementationPath` | `Resolve-ProjectPath` (shared helper) | Shared helper imported |
| `extensions/specrew-speckit/scripts/scaffold-governance.ps1` | `ProjectPath` | `Resolve-ProjectPath` (shared helper) | Shared helper imported |
| `extensions/specrew-speckit/scripts/scaffold-iteration-plan.ps1` | `SpecPath`, `IterationConfigPath` | `Resolve-ProjectPath` (shared helper) | Shared helper imported |
| mirrored `.specify/extensions/specrew-speckit/scripts/*` copies | same as source extension | `Resolve-ProjectPath` (shared helper) | Source and mirror kept in sync; no exemptions recorded |

No in-scope exemptions remain; any future exceptions must be recorded in `.specrew/quality/known-traps.md` per FR-008.

---

### R3: What is the minimum regression strategy that will fail closed for this bug?

**Decision**: Add one deterministic integration lane that deliberately diverges `[Environment]::CurrentDirectory` from `(Get-Location).Path`, invokes representative entry points with `-ProjectPath '.'`, and includes a static scan for the historical anti-pattern outside the shared helper.

**Rationale**: The bug is both behavioral and mechanical. Dynamic regression alone would miss copied idioms in dormant scripts, while a static scan alone would not prove that the user-visible symptom is fixed. Combining both in a deterministic PowerShell lane gives one authoritative fail-closed signal for FR-006 and FR-007.

**Alternatives considered**:

- Only add a static `rg`-style scan: rejected because it would not prove the corrected runtime behavior.
- Only add runtime regression coverage for `specrew start`: rejected because the defect has already spread beyond one entry point and beyond one script tree.

---

### R4: How should feature 009 handle the known-traps corpus when `.specrew/quality/known-traps.md` does not yet exist?

**Decision**: Treat `.specrew/quality/known-traps.md` as an implementation-created artifact and seed feature 009’s path-resolution defect as the first corpus entry if the file is absent.

**Rationale**: FR-008 requires corpus seeding before closure, and the active repository currently has no `known-traps.md` file. Creating the file during implementation is consistent with the spec assumption that the corpus may need its first row seeded by this feature.

**Alternatives considered**:

- Defer trap seeding until another feature creates the corpus: rejected because FR-008 makes trap seeding part of this feature’s measurable outcome.
- Store the trap only in feature-local docs: rejected because it would not satisfy the cross-feature corpus requirement from feature 005.

---

### R5: What validation baseline must remain green while feature 009 is implemented?

**Decision**: Keep the existing governance lanes green unchanged and add the new path-resolution regression lane alongside them.

**Rationale**: The current repository already passes `quality-profile-foundation`, `hardening-gate-contract`, `quality-evidence-governance`, `validation-contract-lane`, and `validate-governance.ps1 -ProjectPath .`. Feature 009 must be additive to that baseline instead of trading one quality contract for another.

**Alternatives considered**:

- Replace older lanes with the new regression lane: rejected because the existing lanes validate broader governance contracts that must not regress.
- Treat feature 009 as documentation-only planning with no runtime validation: rejected because the defect is executable behavior in PowerShell scripts.
