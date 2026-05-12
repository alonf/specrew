# Quickstart: Project Path Resolution in Specrew Entry-Point Scripts

This quickstart defines the intended implementation and validation workflow for feature 009. It is a planning artifact; it does **not** claim the code changes already exist.

## Prerequisites

- PowerShell 7+
- A Specrew-managed repository checkout
- Active feature documentation in `specs/009-project-path-resolution/`
- Existing governance validation baseline passing

## 1. Confirm the fix stays bounded

Review `specs/009-project-path-resolution/plan.md` and confirm the work remains limited to:

- preserving/adopting the shared `Resolve-ProjectPath` helper
- migrating the five user entry points
- auditing the in-scope internal scripts in both extension trees
- adding deterministic regression coverage plus the static anti-pattern scan
- seeding `.specrew/quality/known-traps.md` and recording trap reapplication
- preserving command names, defaults, and current error-message text

## 2. Confirm the audit list before editing scripts

Use `specs/009-project-path-resolution/research.md` as the authoritative audit matrix and verify the implementation covers:

- `scripts/specrew-init.ps1`
- all five `scripts/specrew-team.ps1` call sites
- `scripts/specrew-review.ps1`
- the in-scope `extensions/specrew-speckit/scripts/*.ps1` governance helpers, including:
  - `brownfield-merge.ps1`
  - `deploy-speckit-extension.ps1`
  - `deploy-squad-runtime.ps1`
  - `drift-diff.ps1`
  - `scaffold-governance.ps1`
  - `scaffold-iteration-plan.ps1`
- the mirrored `.specify/extensions/specrew-speckit/scripts/*.ps1` copies

Do **not** widen the change into unrelated `GetFullPath` cleanup outside the defect model.

## 3. Implement helper adoption and preserve compatibility

The implementation should ensure:

- relative `-ProjectPath`, `-SpecPath`, `-FeaturePath`, `-IterationPath`, and `-DispositionPath` inputs resolve against `(Get-Location).Path`
- absolute and UNC paths continue to pass through unchanged
- user-visible failures still use the existing messages:
  - `Project path does not exist`
  - `Project is not Specrew-managed`
  - `Project is not fully bootstrapped`

## 4. Add deterministic regression coverage

Create `tests/integration/project-path-resolution-regression.ps1` so it:

- sets `[Environment]::CurrentDirectory` to a non-project directory
- sets the PowerShell location to a Specrew-managed fixture/project
- invokes representative entry points with `-ProjectPath '.'` or default-path behavior, including `specrew start --no-launch` and `specrew init --dry-run`
- asserts the command resolves to the PowerShell working directory
- runs the static anti-pattern scan and fails on any new disallowed raw `GetFullPath($SomePathParam)` use outside the shared helper across all audited scripts

## 5. Seed the known-traps corpus and plan reapplication

During implementation/closure:

- create `.specrew/quality/known-traps.md` if it does not exist
- add the `path-resolution` trap entry with the FR-008 required fields
- record trap reapplication evidence in `specs/009-project-path-resolution/quality/trap-reapplication.md`

## 6. Run the required validation lane

```powershell
pwsh -NoProfile -File .\tests\integration\quality-profile-foundation.ps1
pwsh -NoProfile -File .\tests\integration\hardening-gate-contract.ps1
pwsh -NoProfile -File .\tests\integration\quality-evidence-governance.ps1
pwsh -NoProfile -File .\tests\integration\validation-contract-lane.ps1
pwsh -NoProfile -File .\tests\integration\project-path-resolution-regression.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File .\extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath .
```

Expected outcome:

1. all pre-existing governance lanes stay green
2. the new regression lane exits zero
3. the static anti-pattern scan reports zero in-scope violations
4. no CLI surface or error-message drift is introduced

## 7. Regression Evidence (Execution)

- 2026-05-09: `pwsh -NoProfile -File .\tests\integration\project-path-resolution-regression.ps1` exited 0 after helper adoption and static scan validation.
