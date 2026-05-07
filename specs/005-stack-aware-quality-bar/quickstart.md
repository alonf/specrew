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

After implementation, execute the new deterministic mechanical-check runner against a fixture or feature workspace:

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
- per-finding severity
- source file/line
- remediation guidance
- gate and requirement references

## 5. Enforce the artifact contract

Run governance validation:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath .
```

Expected result after implementation:

- PASS when all required Phase 1 quality gates have evidence or approved exceptions
- FAIL when the plan declares required quality gates but evidence artifacts are missing or incomplete

## 6. Run deterministic integration coverage

Execute the existing regression checks plus the new Phase 1 fixture coverage:

```powershell
pwsh -NoProfile -File .\tests\integration\quality-profile-foundation.ps1
pwsh -NoProfile -File .\tests\integration\mechanical-findings-contract.ps1
pwsh -NoProfile -File .\tests\integration\process-quality-scorer.ps1
pwsh -NoProfile -File .\tests\integration\process-quality-report.ps1
```

## Validation Outcome

The Phase 1 slice is ready for task generation and implementation when:

1. scaffolded preset/lens assets are present and versioned
2. planning artifacts show the inferred quality profile and tool bundle
3. mechanical findings emit valid JSON
4. quality evidence is visible in iteration artifacts
5. governance validation fails closed on missing evidence
