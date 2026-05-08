# Quickstart: Stack-Aware Quality Bar (Phase 1 / First Slice)

This quickstart describes how to validate the Phase 1 slice after implementation lands.

## Prerequisites

- PowerShell 7+
- Existing Specrew bootstrap in the target repo
- A feature spec with clarified scope

## 1. Scaffold downstream quality governance assets

Run the existing governance scaffold in dry-run mode first:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\extensions\specrew-speckit\scripts\scaffold-governance.ps1 -ProjectPath . -DryRun
```

After implementation, confirm the dry-run or real scaffold includes:

```text
.specrew/
├── config.yml
├── presets/
└── lenses/
```

The scaffold is the source of the downstream Phase 1 quality assets. `config.yml` must include the `quality` discovery block so later commands can resolve `.specrew/presets`, `.specrew/lenses`, and the iteration-local `quality/` evidence directory without extra setup.

## 2. Verify the worked preset and lens sources

Confirm the scaffolded assets include at minimum:

- `.specrew/presets/node-public-ws-service-v1.md`
- one or more `.specrew/lenses/*-v1.md` checklists

Review each artifact for:

- semantic version
- required tables
- upgrade guidance
- change log
- explicit mechanical check list

## 3. Generate or inspect a Phase 1 plan

Run the normal Specrew planning flow for a supported stack fixture, then confirm the resulting feature `plan.md` includes:

- a Phase 1 / first-slice marker
- inferred quality profile
- selected preset reference or explicit custom composition
- quality tool bundle
- required mechanical gates
- not-applicable dimensions with rationale

## 4. Run mechanical checks and inspect findings

After implementation, execute the deterministic mechanical-check runner against a fixture or feature workspace:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\extensions\specrew-speckit\scripts\run-mechanical-checks.ps1 -ProjectPath .
```

Confirm it produces:

```text
specs/<feature>/iterations/<NNN>/quality/
├── mechanical-findings.json
└── quality-evidence.md
```

Check `mechanical-findings.json` for:

- top-level schema version
- generator metadata
- per-finding severity
- source file/line
- remediation guidance
- gate and requirement references
- `dispositionRef` on every demoted finding

Check `quality-evidence.md` for:

- `Profile Ref`, `Preset Refs`, `Findings Ref`, `Reviewed By`, and `Reviewed At`
- a `Gate Matrix` row for every required Phase 1 gate declared by the plan
- `failed` rows staying visible until resolved
- `excepted` rows carrying an explicit exception or demotion reference instead of silently hiding the gate

## 5. Enforce the artifact contract

Run governance validation:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath .
```

Expected result after implementation:

- PASS when every declared required Phase 1 gate is present in `quality-evidence.md`, no required gate is still `planned`, required mechanical gates have `mechanical-findings.json`, and any `excepted` or demoted gate stays visible with an explicit reference
- FAIL when a declared required gate is missing, still `planned`, lacks its evidence artifact, is marked `excepted` without an exception reference, or hides demoted findings instead of citing `dispositionRef` / excepted rows

## 6. Run deterministic integration coverage

Execute the existing regression checks plus the new Phase 1 fixture coverage:

```powershell
pwsh -NoProfile -File .\tests\integration\quality-profile-foundation.ps1
pwsh -NoProfile -File .\tests\integration\mechanical-findings-contract.ps1
pwsh -NoProfile -File .\tests\integration\quality-evidence-governance.ps1
pwsh -NoProfile -File .\tests\integration\process-quality-scorer.ps1
pwsh -NoProfile -File .\tests\integration\process-quality-report.ps1
```

## Validation Outcome

The Phase 1 slice is ready for task generation and implementation when:

1. scaffolded preset/lens assets are present and versioned
2. planning artifacts show the inferred quality profile and tool bundle
3. mechanical findings emit valid JSON
4. quality evidence is visible in iteration artifacts, including explicit exception visibility for demoted findings
5. governance validation fails closed on missing, still-planned, or unsupported required-gate evidence
