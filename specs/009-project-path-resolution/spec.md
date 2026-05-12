# Feature Specification: Project Path Resolution in Specrew Entry-Point Scripts

**Feature Branch**: `009-project-path-resolution`  
**Created**: 2026-05-09  
**Status**: Draft  
**Input**: User description: "Specrew's user-invoked PowerShell entry-point scripts (`specrew-start.ps1`, `specrew-update.ps1`, `specrew-init.ps1`, `specrew-team.ps1`, `specrew-review.ps1`) resolve their `-ProjectPath` argument with `[System.IO.Path]::GetFullPath($ProjectPath)`, which on Windows resolves against the .NET process CurrentDirectory instead of PowerShell's current location. The two values diverge whenever the user has navigated with `Set-Location`/`cd`, causing every script that defaults to `-ProjectPath '.'` to falsely report 'Project is not Specrew-managed' or 'Project is not fully bootstrapped' even when the user is sitting in the project root. An interim fix has been applied for `specrew-start.ps1` and `specrew-update.ps1` via a `Resolve-ProjectPath` helper in `extensions/specrew-speckit/scripts/shared-governance.ps1`, but the same bug remains in the other entry-point scripts and in many internal scripts that take `-ProjectPath` / `-IterationPath` / `-SpecPath` and use the same broken resolution."

## Problem Statement

Specrew's PowerShell entry-point scripts treat `-ProjectPath '.'` as the canonical default for "the current project," and downstream Specrew documentation, dogfooding workflows, and the Squad coordinator handoff all assume that running the scripts from the project root works without further argument.

However, every entry-point script resolves the relative path with the same idiom:

```powershell
$resolvedProjectPath = [System.IO.Path]::GetFullPath($ProjectPath)
```

The problem: `[System.IO.Path]::GetFullPath('.')` resolves against the **.NET process `CurrentDirectory`**, not PowerShell's `$PWD`. On Windows, the two diverge because PowerShell's `Set-Location` / `cd` updates only its own location stack; the .NET process current directory remains pinned to the shell's startup directory (commonly `$HOME` such as `C:\Users\<name>`).

This bug consistently fires when a user does the obvious thing — opens a shell, `cd`s into the project, and runs `./scripts/specrew-start.ps1` or `./scripts/specrew-update.ps1`.

**Observed During Dogfooding (2026-05-09)**:

```text
PS C:\Dev\Specrew> .\scripts\specrew-update.ps1 -Specrew -ProjectPath .
Write-Error: Project is not Specrew-managed. Missing 'C:\Users\alon.HOME\.specrew\config.yml'.

PS C:\Dev\Specrew> .\scripts\specrew-start.ps1
ERROR: Project is not fully bootstrapped for Specrew start.
ERROR: Missing required paths: .specrew\config.yml, .specify, .squad, .github\agents\squad.agent.md
ERROR: Run 'specrew init' first.
```

The project at `C:\Dev\Specrew` **is** fully bootstrapped — all required markers exist. The script checks for them under the user's home directory because of the broken resolution.

**Impact on Spec 001 Workflows**:

This bug breaks the canonical dogfooding workflow from spec 001 (Sessions 2026-05-04 and 2026-05-05): "downstream users SHOULD start work with `specrew start`" and "no-argument `specrew start` MUST launch Squad in intake/resume mode rather than fail." It also breaks the dogfooding self-modification loop where Specrew is being developed using Specrew, because the human cannot reliably run `specrew update` to redeploy source-to-installed assets between iterations.

## Relationship to Existing Features

- This bug affects every spec 001 user-invoked CLI entrypoint: `specrew start` (FR-024), `specrew update` (FR-035), `specrew init` (the bootstrap orchestration), and the team/review management scripts.
- The fix integrates cleanly with the Phase 2 known-traps corpus from `specs/005-stack-aware-quality-bar/spec.md` FR-034 through FR-037: this defect pattern (PowerShell `$PWD` vs .NET `CurrentDirectory` divergence) belongs in the corpus as a trap row so trap reapplication per FR-037 can scan for further occurrences.
- The fix should also be representable as a mechanical-check rule under `specs/005-stack-aware-quality-bar/spec.md` FR-027 / FR-028 / FR-030, because the bad pattern (`[System.IO.Path]::GetFullPath($SomePathParam)` against an unrooted user-supplied path) is statically detectable.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - User-invoked entry-point scripts work with the canonical `-ProjectPath '.'` default (Priority: P1)

A human developer in a fully bootstrapped Specrew project runs `specrew start` or `specrew update` from the project root with no arguments and expects them to work, exactly as the canonical workflow in spec 001 describes.

**Why this priority**: This is the canonical entry pattern for every downstream user. Without this story, the published workflow is broken on Windows whenever the .NET process current directory differs from the PowerShell location.

**Independent Test**: From a fresh PowerShell session, `cd` into a Specrew-managed project and run `specrew-start.ps1` (or `specrew-update.ps1` with `--info`) without `-ProjectPath`. Verify that the script resolves the project path against the current PowerShell location and proceeds past the bootstrap-state check.

**Acceptance Scenarios**:

1. **Given** a Specrew-managed project at `C:\Dev\MyProject`, **When** the user runs `cd C:\Dev\MyProject` followed by `.\scripts\specrew-start.ps1`, **Then** the script resolves the project path to `C:\Dev\MyProject` and continues into the launch flow without reporting missing bootstrap state.
2. **Given** a Specrew-managed project, **When** the user runs `.\scripts\specrew-update.ps1 --info`, **Then** the script resolves the project path against the PowerShell working directory and reports current/latest versions without reporting "Project is not Specrew-managed."
3. **Given** the user is in a directory that is not a Specrew project, **When** they run an entry-point script with no `-ProjectPath`, **Then** the script reports a clear "Project path does not exist" or "Project is not Specrew-managed" error against the actual current PowerShell directory, not against an unrelated absolute path.

---

### User Story 2 - Path resolution remains consistent across all Specrew entry-point and helper scripts (Priority: P1)

A human developer wants the same path-resolution behavior across every Specrew script that accepts a `-ProjectPath`, `-IterationPath`, `-SpecPath`, or similar relative-path argument, so the dogfooding loop and downstream workflows are not silently inconsistent.

**Why this priority**: Splitting the fix between only some entry points (e.g., `specrew-start` and `specrew-update`) but not others (e.g., `specrew-init`, `specrew-team`, `specrew-review`, plus the internal scripts under `extensions/specrew-speckit/scripts/`) leaves recurrence traps that surface only when the user reaches a less-common workflow.

**Independent Test**: Audit every script that resolves a user-supplied path with `[System.IO.Path]::GetFullPath`, run each at least once with a relative-path argument from a non-`$HOME` directory, and verify each resolves against the PowerShell working directory.

**Acceptance Scenarios**:

1. **Given** a code search for `[System.IO.Path]::GetFullPath($ProjectPath)`, `[System.IO.Path]::GetFullPath($IterationPath)`, `[System.IO.Path]::GetFullPath($SpecPath)`, **When** the audit runs, **Then** every occurrence in a script that accepts the corresponding argument from the command line is replaced with the shared resolution helper.
2. **Given** the helper exists in `extensions/specrew-speckit/scripts/shared-governance.ps1`, **When** scripts dot-source it, **Then** they call the helper instead of inlining the broken pattern.
3. **Given** a script chooses not to dot-source the helper, **When** it resolves a user-supplied relative path, **Then** it includes an inline equivalent that resolves against `(Get-Location).Path` rather than `[System.IO.Path]::GetFullPath` alone.

---

### User Story 3 - Future regressions are caught by deterministic test coverage (Priority: P2)

A human maintainer wants a regression suite that fails closed if any future entry-point script reintroduces the .NET vs PowerShell working-directory divergence, so the fix cannot silently rot.

**Why this priority**: Without explicit regression coverage, future contributors copying the historical idiom will reintroduce the bug.

**Independent Test**: Run a deterministic integration script that places the .NET process `CurrentDirectory` at a non-project directory, then invokes each entry-point script with `-ProjectPath '.'` from a `Set-Location`'d project, and asserts the script resolves to the PowerShell location.

**Acceptance Scenarios**:

1. **Given** an integration test sets `[Environment]::CurrentDirectory` to a temporary unrelated directory and the PowerShell location to a Specrew-managed project, **When** each entry-point script runs with `-ProjectPath '.'`, **Then** the script proceeds past the bootstrap check or info reporting without error.
2. **Given** the audit list of `[System.IO.Path]::GetFullPath` call sites that should not exist, **When** a static scan runs, **Then** any reintroduction of `[System.IO.Path]::GetFullPath($ProjectPath)` against an unresolved relative path is reported as a finding by the same scan.

---

### Edge Cases

- The user passes an absolute path explicitly (e.g., `-ProjectPath C:\Dev\Specrew`). The fix MUST preserve absolute-path behavior unchanged.
- The user passes a UNC path (e.g., `\\server\share\proj`). The fix MUST handle UNC paths the same way `Resolve-Path` and `[System.IO.Path]::GetFullPath` already do for absolute UNC inputs.
- The user passes a non-existent path. The fix MUST still resolve the relative path against `$PWD` so the existing "Project path does not exist" error message reports the correct attempted location.
- The user invokes the script via `pwsh -File` from a wrapper task or scheduler that did not execute a `Set-Location`. The fix MUST still produce a sensible result — either the .NET CurrentDirectory and PowerShell PWD will agree, or the wrapper will have set PWD explicitly before invoking the script.
- A script invokes another Specrew script via call operator with explicit `-ProjectPath $resolvedPath`. The fix MUST not double-resolve; absolute paths pass through `[System.IO.Path]::GetFullPath` unchanged.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001: Shared Resolution Helper**: Specrew MUST expose a shared `Resolve-ProjectPath` helper in `extensions/specrew-speckit/scripts/shared-governance.ps1` that resolves a user-supplied path argument against PowerShell's current location when the path is relative, and against `[System.IO.Path]::GetFullPath` when the path is already rooted. An interim version of this helper has already been applied locally and MUST be preserved or replaced equivalently.

- **FR-002: Entry-Point Script Adoption**: Every user-invoked entry-point script under `scripts/` (`specrew-start.ps1`, `specrew-update.ps1`, `specrew-init.ps1`, `specrew-team.ps1`, `specrew-review.ps1`) MUST call the shared helper to resolve its `-ProjectPath` argument. Inlined `[System.IO.Path]::GetFullPath($ProjectPath)` calls in those scripts MUST be removed.

- **FR-003: Internal Script Audit**: Every internal script under `extensions/specrew-speckit/scripts/` and `.specify/extensions/specrew-speckit/scripts/` that accepts a relative-path argument from the command line (`-ProjectPath`, `-IterationPath`, `-SpecPath`, `-FeaturePath`, `-DispositionPath`, etc.) MUST either call the shared helper or apply the equivalent inline resolution. A migration audit MUST list every call site that needs updating, and each MUST be either fixed or explicitly justified for exemption.

- **FR-004: Absolute Path Pass-Through**: When the supplied path is already rooted (absolute Windows path or UNC path), the resolution behavior MUST be unchanged from the prior implementation.

- **FR-005: Error Message Fidelity**: When the resolved path does not exist or does not contain expected bootstrap markers, the existing error messages ("Project path does not exist", "Project is not Specrew-managed", "Project is not fully bootstrapped") MUST be preserved verbatim, and the absolute path printed in those messages MUST reflect the corrected resolution.

- **FR-006: Deterministic Regression Coverage**: A new deterministic integration script under `tests/integration/` MUST exercise the corrected resolution by setting `[Environment]::CurrentDirectory` to a non-project directory and invoking representative entry-point scripts with `-ProjectPath '.'` from a `Set-Location`'d Specrew-managed fixture, asserting each proceeds past the bootstrap or info gate without error.

- **FR-007: Static Audit Check**: The deterministic regression coverage MUST include a static scan that flags any future reintroduction of `[System.IO.Path]::GetFullPath($ProjectPath)`, `[System.IO.Path]::GetFullPath($IterationPath)`, `[System.IO.Path]::GetFullPath($SpecPath)`, or equivalent unrooted-relative-path resolution outside the shared helper, so the fix does not silently rot.

- **FR-008: Known-Traps Corpus Seeding**: When the project's known-traps corpus per `specs/005-stack-aware-quality-bar/spec.md` FR-034 is populated, this defect MUST be added as a trap entry with: category `path-resolution`, concrete example showing the broken pattern, detection method (the static scan from FR-007), remediation guidance pointing at the shared helper, and discovery date 2026-05-09. Trap reapplication per FR-037 MUST scan existing code for the pattern before this feature closes.

- **FR-009: Mechanical-Check Mapping (Optional)**: The bad pattern SHOULD also be representable as a mechanical anti-pattern check per `specs/005-stack-aware-quality-bar/spec.md` FR-028 once Phase 2 mechanical lens execution lands. This is OPTIONAL for the initial slice; the static audit in FR-007 is sufficient to close this feature.

### Traceability & Governance Requirements *(mandatory)*

- **TG-001**: User Story 1 MUST be covered by FR-001, FR-002, FR-004, FR-005.
- **TG-002**: User Story 2 MUST be covered by FR-002, FR-003.
- **TG-003**: User Story 3 MUST be covered by FR-006, FR-007.
- **TG-004**: Trap-corpus integration MUST be covered by FR-008 and SHOULD be covered by FR-009 once spec 005 Phase 2 mechanical-check execution exists.
- **TG-005**: This feature MUST remain visibly additive to spec 001 FR-024 (`specrew start`), FR-035 (`specrew update`), and the entry-point scripts under `scripts/`. It MUST NOT change documented argument names, error messages, or default values beyond what FR-005 requires for absolute-path correctness.

### Key Entities

- **Resolve-ProjectPath Helper**: Shared PowerShell function that resolves a path argument against `(Get-Location).Path` when relative and `[System.IO.Path]::GetFullPath` when rooted. Source of truth: `extensions/specrew-speckit/scripts/shared-governance.ps1`.
- **Entry-Point Script**: A PowerShell script under `scripts/` invoked directly by the user from the command line (`specrew-start.ps1`, `specrew-update.ps1`, `specrew-init.ps1`, `specrew-team.ps1`, `specrew-review.ps1`).
- **Internal Script**: A PowerShell script under `extensions/specrew-speckit/scripts/` or `.specify/extensions/specrew-speckit/scripts/` invoked indirectly by Squad or by an entry-point script. Accepts relative-path arguments such as `-ProjectPath`, `-IterationPath`, `-SpecPath`, `-FeaturePath`, `-DispositionPath`.
- **Static Audit Check**: A deterministic scan that flags reintroduction of the broken `[System.IO.Path]::GetFullPath($SomePathParam)` pattern outside the shared helper.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: After rollout, in 100% of representative user sessions (Windows PowerShell with `cd` into a Specrew-managed project), every user-invoked entry-point script with `-ProjectPath '.'` or no `-ProjectPath` at all resolves correctly to the PowerShell working directory.

- **SC-002**: After rollout, in 100% of audited call sites listed in FR-003, the broken `[System.IO.Path]::GetFullPath($ProjectPath)` (and equivalent for `IterationPath`/`SpecPath`/`FeaturePath`/`DispositionPath`) idiom has been replaced with the shared helper or equivalent inline resolution, or has been explicitly exempted with rationale recorded in `.specrew/quality/known-traps.md`.

- **SC-003**: After rollout, the static audit check from FR-007 produces zero findings on the codebase, and the deterministic regression script from FR-006 exits zero.

- **SC-004**: After rollout, the project's known-traps corpus contains the path-resolution trap entry described in FR-008 with all five required fields populated.

- **SC-005**: After rollout, no entry-point script reports "Project is not fully bootstrapped" or "Project is not Specrew-managed" against an unrelated absolute path (e.g., the user's `$HOME`) when the user is in fact inside a Specrew-managed project.

## Assumptions

- The user runs PowerShell 7+ on Windows, where `[Environment]::CurrentDirectory` and `(Get-Location).Path` may diverge after `Set-Location`. Linux and macOS PowerShell hosts behave the same way symbolically; the fix applies equally without special-casing.
- The current spec 005 known-traps corpus surface (`.specrew/quality/known-traps.md` per FR-035) is available for FR-008 seeding. If the corpus is not yet populated, this feature MAY seed the entry as the first corpus row.
- The Spec Kit and Squad integration surfaces remain unchanged. This feature only modifies Specrew-owned PowerShell scripts and adds a new test under `tests/integration/`.
- The interim fix already in the working tree is a faithful starting point for the formal implementation.

## Non-Goals

- Replacing `[System.IO.Path]::GetFullPath` everywhere it appears in Specrew. Many call sites already operate on already-rooted paths and do not need to change.
- Introducing a new path-resolution abstraction layer beyond the single `Resolve-ProjectPath` helper.
- Changing argument names, defaults, or documented usage of any entry-point script.
- Backporting the fix to historical Specrew releases. Only the current development line is in scope.
- Adding cross-platform behavioral changes beyond what FR-001 already covers symmetrically.

## Clarifications

### Session 2026-05-09

- Q: Is the interim fix in `shared-governance.ps1` sufficient as-is, or will it be revised before formal adoption? → A: Interim fix is preserved and used as the canonical `Resolve-ProjectPath` helper; no revision required before adoption. The helper becomes the reference implementation for FR-001 and is directly adopted across all call sites per FR-002 and FR-003.

- Q: When is the known-traps corpus entry seeded relative to feature closure? → A: Known-traps corpus entry (FR-008) is part of feature closure and validated by SC-004 as a measurable outcome; seeding occurs during implementation, not deferred.

---

## Governance Alignment *(mandatory)*

- **Spec Steward**: Alon Fliess, as the maintainer who hit the bug during 2026-05-09 dogfooding and who owns the policy boundary that "downstream users SHOULD start work with `specrew start`" must remain a true statement on Windows.

- **Iteration Facilitator**: Specrew lifecycle and routing maintainers responsible for keeping the entry-point scripts and their tests aligned with the documented user workflow.

- **Capacity Model**: One bounded fix slice covering the shared helper, entry-point migration, internal-script audit, deterministic regression coverage, static audit check, and known-traps corpus entry. No new toolchain or runtime dependency is introduced.

- **Drift Signals**: Any future `[System.IO.Path]::GetFullPath($SomePathParam)` against an unrooted relative path outside the shared helper; any user report that `specrew start` or `specrew update` fails with "Project is not Specrew-managed" while the user is in a real Specrew project; any internal script that resolves a user-supplied relative path against `[Environment]::CurrentDirectory` instead of PowerShell's `$PWD`.

- **Human Oversight Points**: Human approval of the final audit list of call sites and any exemptions; human approval of the trap entry text seeded into the known-traps corpus per FR-008; human review of the regression script to confirm it actually exercises the bug before the fix and would catch reintroduction.
