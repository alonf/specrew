[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

function Write-Pass {
    param([string]$Message)
    Write-Host "PASS: $Message" -ForegroundColor Green
}

function Write-Fail {
    param([string]$Message)
    Write-Host "FAIL: $Message" -ForegroundColor Red
}

function Assert-True {
    param(
        [Parameter(Mandatory = $true)][bool]$Condition,
        [Parameter(Mandatory = $true)][string]$Message
    )

    if (-not $Condition) {
        Write-Fail $Message
        exit 1
    }
}

function Assert-Match {
    param(
        [AllowNull()][string]$Text,
        [Parameter(Mandatory = $true)][string]$Pattern,
        [Parameter(Mandatory = $true)][string]$Message
    )

    Assert-True -Condition ([string]$Text -match $Pattern) -Message $Message
}

function Assert-NotMatch {
    param(
        [AllowNull()][string]$Text,
        [Parameter(Mandatory = $true)][string]$Pattern,
        [Parameter(Mandatory = $true)][string]$Message
    )

    Assert-True -Condition (-not ([string]$Text -match $Pattern)) -Message $Message
}

$script:repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
$script:postShipFixtureRoot = Join-Path $script:repoRoot 'tests\unit\fixtures\168-post-ship-proposal-amendment-discipline'
$script:scratchRoot = Join-Path $script:repoRoot '.scratch\validate-governance-post-ship-proposal'
$script:validatorScripts = @(
    @{ Name = 'extension'; ScriptPath = Join-Path $script:repoRoot 'extensions\specrew-speckit\scripts\validate-governance.ps1' }
)

function Get-ProposalFixtureText {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Status
    )

    $text = Get-Content -LiteralPath (Join-Path $script:postShipFixtureRoot $Name) -Raw -Encoding UTF8
    return $text.Replace('__STATUS__', $Status)
}

function Invoke-TestGit {
    param(
        [Parameter(Mandatory = $true)][string]$Workspace,
        [Parameter(Mandatory = $true)][string[]]$Arguments
    )

    $output = @(& git -C $Workspace @Arguments 2>&1)
    if ($LASTEXITCODE -ne 0) {
        throw "git $($Arguments -join ' ') failed in $Workspace`: $($output -join "`n")"
    }

    return @($output)
}

function Set-SyntheticProposal {
    param(
        [Parameter(Mandatory = $true)][string]$Workspace,
        [Parameter(Mandatory = $true)][string]$Text
    )

    $proposalDirectory = Join-Path $Workspace 'proposals'
    if (-not (Test-Path -LiteralPath $proposalDirectory -PathType Container)) {
        $null = New-Item -ItemType Directory -Path $proposalDirectory -Force
    }

    Set-Content -LiteralPath (Join-Path $proposalDirectory '900-synthetic-post-ship.md') -Value $Text -Encoding UTF8
}

function New-MinimalValidatorWorkspace {
    param([Parameter(Mandatory = $true)][string]$Workspace)

    $iterationDirectory = Join-Path $Workspace 'specs\168-post-ship-fixture\iterations\001'
    $teamDirectory = Join-Path $Workspace '.squad'
    $null = New-Item -ItemType Directory -Path $iterationDirectory -Force
    $null = New-Item -ItemType Directory -Path $teamDirectory -Force

    @'
# Iteration Plan: 001

**Schema**: v1
**Spec**: specs/168-post-ship-fixture/spec.md
**Status**: planning
**Capacity**: 0.25/20 story_points
**Started**: 2026-06-06

## Tasks

| Task | Requirement | Story | Effort | Owner | Status |
|---|---|---|---|---|---|
| T001 | FR-001 | US1 | 0.25 | Implementer | planned |

## Effort Model

| Setting | Value | Notes |
|---|---|---|
| Effort Unit | story_points | Fixture unit. |
| Planned Effort | 0.25 | Fixture planned effort. |
| Capacity per Iteration | 20 | Fixture capacity. |
| Iteration Bounding | scope | Fixture bounding. |
| Time Limit (hours) | n/a | Scope-bounded fixture. |
| Overcommit Threshold | 1.0 | Fixture threshold. |
| Defer Strategy | manual | Fixture strategy. |
| Calibration Enabled | true | Fixture calibration setting. |

## Concurrency Rationale

All fixture work is serial.
'@ | Set-Content -LiteralPath (Join-Path $iterationDirectory 'plan.md') -Encoding UTF8

    @'
# Fixture Spec

## Requirements

- FR-001: Fixture requirement.
'@ | Set-Content -LiteralPath (Join-Path $Workspace 'specs\168-post-ship-fixture\spec.md') -Encoding UTF8

    @'
# Team

## Specrew Baseline Roles

| Role | Owner |
|---|---|
| Spec Steward | Spec Steward |
| Planner | Planner |
| Implementer | Implementer |
| Reviewer | Reviewer |
| Retro Facilitator | Retro Facilitator |
'@ | Set-Content -LiteralPath (Join-Path $teamDirectory 'team.md') -Encoding UTF8
}

function New-TestWorkspace {
    param(
        [Parameter(Mandatory = $true)][string]$WorkspaceName,
        [Parameter(Mandatory = $true)][string]$BaseFixture,
        [string]$ChangedFixture,
        [Parameter(Mandatory = $true)][string]$Status,
        [string]$ChangedStatus,
        [switch]$DeleteInsteadOfChange
    )

    if (-not $DeleteInsteadOfChange -and [string]::IsNullOrWhiteSpace($ChangedFixture)) {
        throw "New-TestWorkspace: -ChangedFixture is required unless -DeleteInsteadOfChange is set (the non-delete path always consumes it)."
    }

    $destination = Join-Path $script:scratchRoot $WorkspaceName
    if (Test-Path -LiteralPath $destination) {
        Remove-Item -LiteralPath $destination -Recurse -Force
    }

    $null = New-Item -ItemType Directory -Path $destination -Force
    New-MinimalValidatorWorkspace -Workspace $destination

    Invoke-TestGit -Workspace $destination -Arguments @('init') | Out-Null
    Invoke-TestGit -Workspace $destination -Arguments @('checkout', '-B', 'main') | Out-Null
    Invoke-TestGit -Workspace $destination -Arguments @('config', 'user.email', 'specrew-test@example.invalid') | Out-Null
    Invoke-TestGit -Workspace $destination -Arguments @('config', 'user.name', 'Specrew Test') | Out-Null

    Set-SyntheticProposal -Workspace $destination -Text (Get-ProposalFixtureText -Name $BaseFixture -Status $Status)
    Invoke-TestGit -Workspace $destination -Arguments @('add', '.') | Out-Null
    Invoke-TestGit -Workspace $destination -Arguments @('commit', '-m', 'base fixture') | Out-Null
    Invoke-TestGit -Workspace $destination -Arguments @('update-ref', 'refs/remotes/origin/main', 'HEAD') | Out-Null
    Invoke-TestGit -Workspace $destination -Arguments @('checkout', '-B', 'feature/post-ship-amendment') | Out-Null

    if ($DeleteInsteadOfChange) {
        # Find 5 (#1761): exercise the deletion-bypass path (proposal removed entirely).
        Invoke-TestGit -Workspace $destination -Arguments @('rm', 'proposals/900-synthetic-post-ship.md') | Out-Null
    }
    else {
        # Find 5 (#1761): an explicit ChangedStatus exercises the downgrade-bypass path
        # (baseline status differs from the current status).
        $effectiveChangedStatus = if ([string]::IsNullOrWhiteSpace($ChangedStatus)) { $Status } else { $ChangedStatus }
        Set-SyntheticProposal -Workspace $destination -Text (Get-ProposalFixtureText -Name $ChangedFixture -Status $effectiveChangedStatus)
        Invoke-TestGit -Workspace $destination -Arguments @('add', 'proposals/900-synthetic-post-ship.md') | Out-Null
    }
    Invoke-TestGit -Workspace $destination -Arguments @('commit', '-m', 'changed fixture') | Out-Null

    return $destination
}

function Invoke-ValidatorScript {
    param(
        [Parameter(Mandatory = $true)][string]$ScriptPath,
        [Parameter(Mandatory = $true)][string]$ProjectPath
    )

    $iterationPath = Join-Path $ProjectPath 'specs\168-post-ship-fixture\iterations\001'
    $output = @(& pwsh -NoProfile -ExecutionPolicy Bypass -File $ScriptPath -ProjectPath $ProjectPath -IterationPath $iterationPath -NoCacheRead -NoParallel 2>&1)
    return [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Output   = @($output)
        Text     = ($output -join "`n")
    }
}

if (Test-Path -LiteralPath $script:scratchRoot) {
    Remove-Item -LiteralPath $script:scratchRoot -Recurse -Force
}
$null = New-Item -ItemType Directory -Path $script:scratchRoot -Force

try {
    foreach ($case in $script:validatorScripts) {
        foreach ($status in @('shipped', 'superseded')) {
            $workspace = New-TestWorkspace -WorkspaceName ("unsafe-{0}-{1}" -f $case.Name, $status) -BaseFixture 'base-proposal.md' -ChangedFixture 'unsafe-body-edit.md' -Status $status
            $result = Invoke-ValidatorScript -ScriptPath $case.ScriptPath -ProjectPath $workspace

            Assert-True -Condition ($result.ExitCode -eq 0) -Message "Unsafe $status fixture unexpectedly failed for $($case.Name): $($result.Text)"
            Assert-Match -Text $result.Text -Pattern 'WARN \[post-ship-proposal\] normative-body-edit' -Message "Unsafe $status fixture did not warn for $($case.Name)."
            Assert-Match -Text $result.Text -Pattern 'proposals/900-synthetic-post-ship\.md' -Message "Unsafe $status warning did not name proposal for $($case.Name)."
            Assert-Match -Text $result.Text -Pattern 'what' -Message "Unsafe $status warning did not name changed section for $($case.Name)."
            Assert-Match -Text $result.Text -Pattern 'Post-Ship Amendments' -Message "Unsafe $status warning did not name amendment path for $($case.Name)."
        }

        foreach ($fixtureCase in @(
                @{ Workspace = 'valid-amendment'; Fixture = 'valid-amendment-edit.md' },
                @{ Workspace = 'allowed-correction'; Fixture = 'allowed-correction-edit.md' }
            )) {
            $workspace = New-TestWorkspace -WorkspaceName ("{0}-{1}" -f $fixtureCase.Workspace, $case.Name) -BaseFixture 'base-proposal.md' -ChangedFixture $fixtureCase.Fixture -Status 'shipped'
            $result = Invoke-ValidatorScript -ScriptPath $case.ScriptPath -ProjectPath $workspace

            Assert-True -Condition ($result.ExitCode -eq 0) -Message "$($fixtureCase.Workspace) fixture unexpectedly failed for $($case.Name): $($result.Text)"
            Assert-NotMatch -Text $result.Text -Pattern 'WARN \[post-ship-proposal\] normative-body-edit' -Message "$($fixtureCase.Workspace) fixture emitted body-edit warning for $($case.Name)."
            Assert-NotMatch -Text $result.Text -Pattern 'WARN \[post-ship-proposal\] malformed-amendment' -Message "$($fixtureCase.Workspace) fixture emitted malformed warning for $($case.Name)."
        }

        foreach ($status in @('candidate', 'draft', 'active')) {
            $workspace = New-TestWorkspace -WorkspaceName ("mutable-{0}-{1}" -f $case.Name, $status) -BaseFixture 'base-proposal.md' -ChangedFixture 'unsafe-body-edit.md' -Status $status
            $result = Invoke-ValidatorScript -ScriptPath $case.ScriptPath -ProjectPath $workspace

            Assert-True -Condition ($result.ExitCode -eq 0) -Message "$status fixture unexpectedly failed for $($case.Name): $($result.Text)"
            Assert-NotMatch -Text $result.Text -Pattern 'WARN \[post-ship-proposal\] normative-body-edit' -Message "$status fixture emitted body-edit warning for $($case.Name)."
            Assert-NotMatch -Text $result.Text -Pattern 'WARN \[post-ship-proposal\] malformed-amendment' -Message "$status fixture emitted malformed warning for $($case.Name)."
        }

        $workspace = New-TestWorkspace -WorkspaceName ("malformed-{0}" -f $case.Name) -BaseFixture 'base-proposal.md' -ChangedFixture 'malformed-amendment-edit.md' -Status 'shipped'
        $result = Invoke-ValidatorScript -ScriptPath $case.ScriptPath -ProjectPath $workspace

        Assert-True -Condition ($result.ExitCode -eq 0) -Message "Malformed fixture unexpectedly failed for $($case.Name): $($result.Text)"
        Assert-Match -Text $result.Text -Pattern 'WARN \[post-ship-proposal\] malformed-amendment' -Message "Malformed fixture did not emit malformed warning for $($case.Name)."
        Assert-Match -Text $result.Text -Pattern 'missing required fields' -Message "Malformed fixture did not name missing fields for $($case.Name)."
        Assert-Match -Text $result.Text -Pattern "invalid status 'parked'" -Message "Malformed fixture did not name invalid status for $($case.Name)."
        Assert-NotMatch -Text $result.Text -Pattern 'WARN \[post-ship-proposal\] normative-body-edit' -Message "Malformed fixture emitted body-edit warning for $($case.Name)."

        # Find 5 (#1761) downgrade-bypass: a shipped/superseded proposal downgraded to a mutable
        # status in the SAME change must not slip a body edit past the gate (baseline status governs).
        $workspace = New-TestWorkspace -WorkspaceName ("downgrade-bypass-{0}" -f $case.Name) -BaseFixture 'base-proposal.md' -ChangedFixture 'unsafe-body-edit.md' -Status 'shipped' -ChangedStatus 'draft'
        $result = Invoke-ValidatorScript -ScriptPath $case.ScriptPath -ProjectPath $workspace
        Assert-True -Condition ($result.ExitCode -eq 0) -Message "Downgrade-bypass fixture unexpectedly failed for $($case.Name): $($result.Text)"
        Assert-Match -Text $result.Text -Pattern 'WARN \[post-ship-proposal\] normative-body-edit' -Message "Downgrade-bypass (shipped->draft + body edit) was not caught for $($case.Name)."
        Assert-Match -Text $result.Text -Pattern 'proposals/900-synthetic-post-ship\.md' -Message "Downgrade-bypass warning did not name the proposal for $($case.Name)."

        # Find 5 (#1761) deletion-bypass: deleting a shipped/superseded proposal must warn (the
        # diff-filter previously excluded deletions). Supersede via a new proposal, do not remove.
        $workspace = New-TestWorkspace -WorkspaceName ("deletion-bypass-{0}" -f $case.Name) -BaseFixture 'base-proposal.md' -Status 'shipped' -DeleteInsteadOfChange
        $result = Invoke-ValidatorScript -ScriptPath $case.ScriptPath -ProjectPath $workspace
        Assert-True -Condition ($result.ExitCode -eq 0) -Message "Deletion-bypass fixture unexpectedly failed for $($case.Name): $($result.Text)"
        Assert-Match -Text $result.Text -Pattern 'WARN \[post-ship-proposal\] normative-body-edit' -Message "Deletion-bypass (deleted shipped proposal) was not caught for $($case.Name)."
        Assert-Match -Text $result.Text -Pattern 'was deleted' -Message "Deletion-bypass warning did not explain the deletion for $($case.Name)."

        # Find 5 / Codex C2 (#1761) invalid-status-downgrade bypass: a shipped/superseded baseline
        # downgraded to a missing/unknown current status (e.g. 'parked') in the SAME change must NOT
        # slip a body edit past the gate -- the invalid-status guard previously `continue`d before the
        # baseline-governance check. The baseline status still governs.
        $workspace = New-TestWorkspace -WorkspaceName ("invalid-status-bypass-{0}" -f $case.Name) -BaseFixture 'base-proposal.md' -ChangedFixture 'unsafe-body-edit.md' -Status 'shipped' -ChangedStatus 'parked'
        $result = Invoke-ValidatorScript -ScriptPath $case.ScriptPath -ProjectPath $workspace
        Assert-True -Condition ($result.ExitCode -eq 0) -Message "Invalid-status-bypass fixture unexpectedly failed for $($case.Name): $($result.Text)"
        Assert-Match -Text $result.Text -Pattern 'WARN \[post-ship-proposal\] normative-body-edit' -Message "Invalid-status-bypass (shipped->parked + body edit) was not caught for $($case.Name)."
        Assert-Match -Text $result.Text -Pattern 'proposals/900-synthetic-post-ship\.md' -Message "Invalid-status-bypass warning did not name the proposal for $($case.Name)."
        Assert-Match -Text $result.Text -Pattern 'baseline status' -Message "Invalid-status-bypass did not surface that the baseline status governs for $($case.Name)."
    }

    $proposalDiscipline = Get-Content -LiteralPath (Join-Path $script:repoRoot 'docs\methodology\proposal-discipline.md') -Raw -Encoding UTF8
    $reviewInstructions = Get-Content -LiteralPath (Join-Path $script:repoRoot 'docs\methodology\review-instructions.md') -Raw -Encoding UTF8
    $proposalIndex = Get-Content -LiteralPath (Join-Path $script:repoRoot 'proposals\INDEX.md') -Raw -Encoding UTF8
    $fixtureIndex = Get-Content -LiteralPath (Join-Path $script:postShipFixtureRoot 'proposals-index-status-surface.md') -Raw -Encoding UTF8

    foreach ($status in @('candidate', 'draft', 'active', 'shipped', 'superseded', 'withdrawn')) {
        Assert-Match -Text $proposalDiscipline -Pattern ([regex]::Escape($status)) -Message "Proposal discipline is missing status '$status'."
    }

    foreach ($field in @('amendment-id', 'date', 'status', 'delta-summary', 'implementation-owner', 'preserve', 'tests-required')) {
        Assert-Match -Text $proposalDiscipline -Pattern $field -Message "Proposal discipline is missing amendment field '$field'."
    }

    foreach ($status in @('proposed', 'accepted-unimplemented', 'active', 'implemented', 'rejected', 'superseded')) {
        Assert-Match -Text $proposalDiscipline -Pattern $status -Message "Proposal discipline is missing amendment status '$status'."
    }

    foreach ($pattern in @('amendment-id', 'superseding proposal', 'preserve list', 'tests-required', 'unrelated shipped-scope reimplementation', 'FR-006 and FR-015 are release-blocking')) {
        Assert-Match -Text $reviewInstructions -Pattern ([regex]::Escape($pattern)) -Message "Review instructions are missing '$pattern'."
    }

    foreach ($pattern in @('Post-Ship Amendment Backlog', 'accepted-unimplemented', 'active', '`implemented`, `rejected`, and `superseded`')) {
        Assert-Match -Text $proposalIndex -Pattern ([regex]::Escape($pattern)) -Message "Proposal index is missing '$pattern'."
    }

    Assert-Match -Text $fixtureIndex -Pattern 'A1 \| accepted-unimplemented' -Message 'Fixture index is missing A1 accepted-unimplemented.'
    Assert-Match -Text $fixtureIndex -Pattern 'A2 \| active' -Message 'Fixture index is missing A2 active.'
    Assert-NotMatch -Text $fixtureIndex -Pattern 'A3 \| implemented' -Message 'Fixture index incorrectly shows implemented backlog.'
    Assert-NotMatch -Text $fixtureIndex -Pattern 'A4 \| rejected' -Message 'Fixture index incorrectly shows rejected backlog.'
    Assert-NotMatch -Text $fixtureIndex -Pattern 'A5 \| superseded' -Message 'Fixture index incorrectly shows superseded backlog.'

    $extensionText = Get-Content -LiteralPath (Join-Path $script:repoRoot 'extensions\specrew-speckit\scripts\validate-governance.ps1') -Raw -Encoding UTF8
    $specifyText = Get-Content -LiteralPath (Join-Path $script:repoRoot '.specify\extensions\specrew-speckit\scripts\validate-governance.ps1') -Raw -Encoding UTF8
    Assert-True -Condition ($extensionText -eq $specifyText) -Message 'Mirrored validate-governance scripts differ.'
}
finally {
    if (Test-Path -LiteralPath $script:scratchRoot) {
        Remove-Item -LiteralPath $script:scratchRoot -Recurse -Force
    }
}

Write-Pass 'Feature 168 post-ship proposal amendment validator, docs, status, and mirror coverage'
exit 0
