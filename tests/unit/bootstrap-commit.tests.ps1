[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) {
        throw "FAIL: $Message"
    }
    Write-Host "PASS: $Message" -ForegroundColor Green
}

function Invoke-TestGit {
    param([string]$RepoRoot, [string[]]$Arguments)
    $output = @(& git -C $RepoRoot @Arguments 2>&1)
    if ($LASTEXITCODE -ne 0) {
        throw "git $($Arguments -join ' ') failed: $($output -join [Environment]::NewLine)"
    }
    return @($output | ForEach-Object { [string]$_ })
}

function New-TestRepository {
    param([string]$Path, [switch]$WithBaseline, [switch]$ConfigureIdentity)

    $null = New-Item -ItemType Directory -Path $Path -Force
    Invoke-TestGit -RepoRoot $Path -Arguments @('init', '--quiet') | Out-Null
    if ($ConfigureIdentity -or $WithBaseline) {
        Invoke-TestGit -RepoRoot $Path -Arguments @('config', 'user.name', 'Specrew Test') | Out-Null
        Invoke-TestGit -RepoRoot $Path -Arguments @('config', 'user.email', 'specrew-test@example.invalid') | Out-Null
    }
    if ($WithBaseline) {
        [System.IO.File]::WriteAllText((Join-Path $Path 'existing.txt'), "existing`n", [System.Text.UTF8Encoding]::new($false))
        Invoke-TestGit -RepoRoot $Path -Arguments @('add', '--all') | Out-Null
        Invoke-TestGit -RepoRoot $Path -Arguments @('commit', '--quiet', '-m', 'existing baseline') | Out-Null
    }
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $repoRoot 'scripts\init\_utilities.ps1')
. (Join-Path $repoRoot 'scripts\init\post-bootstrap-output.ps1')

$scratch = Join-Path $repoRoot '.scratch\bootstrap-commit-tests'
if (Test-Path -LiteralPath $scratch) {
    Remove-Item -LiteralPath $scratch -Recurse -Force
}
$null = New-Item -ItemType Directory -Path $scratch -Force

try {
    $greenfield = Join-Path $scratch 'greenfield'
    New-TestRepository -Path $greenfield
    Invoke-TestGit -RepoRoot $greenfield -Arguments @('config', 'user.name', '') | Out-Null
    Invoke-TestGit -RepoRoot $greenfield -Arguments @('config', 'user.email', '') | Out-Null
    [System.IO.File]::WriteAllText((Join-Path $greenfield 'scaffold.md'), "# scaffold`n", [System.Text.UTF8Encoding]::new($false))
    $greenActions = [System.Collections.ArrayList]::new()
    $greenResult = Invoke-SpecrewBootstrapBaseline `
        -ProjectPath $greenfield `
        -BootstrapMode greenfield `
        -BrownfieldDecision offer `
        -Actions $greenActions `
        -PreviewOnly:$false

    $greenHead = (Invoke-TestGit -RepoRoot $greenfield -Arguments @('rev-parse', 'HEAD') | Select-Object -First 1).Trim()
    $greenSubject = (Invoke-TestGit -RepoRoot $greenfield -Arguments @('show', '-s', '--format=%s', 'HEAD') | Select-Object -First 1).Trim()
    $greenAuthor = (Invoke-TestGit -RepoRoot $greenfield -Arguments @('show', '-s', '--format=%an <%ae>', 'HEAD') | Select-Object -First 1).Trim()
    $greenFiles = @(Invoke-TestGit -RepoRoot $greenfield -Arguments @('show', '--pretty=', '--name-only', 'HEAD'))
    $greenRecordPath = Join-Path $greenfield '.specrew\bootstrap-baseline.json'
    $greenRecord = Get-Content -LiteralPath $greenRecordPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $greenStatus = @(Invoke-TestGit -RepoRoot $greenfield -Arguments @('status', '--porcelain=v1', '--untracked-files=all'))

    Assert-True ($greenResult.Commit -eq $greenHead -and $greenHead -match '^[0-9a-f]{40}$') 'Greenfield baseline returns and announces the exact full commit identity'
    Assert-True ($greenSubject -eq 'chore(specrew): bootstrap scaffold') 'Greenfield baseline uses the exact required commit subject'
    Assert-True ($greenAuthor -eq 'Specrew Bootstrap <specrew-bootstrap@example.invalid>') 'Greenfield baseline uses a command-scoped fallback identity when Git identity is unconfigured'
    Assert-True (($greenFiles -contains 'scaffold.md') -and ($greenFiles -contains '.specrew/bootstrap-baseline.json')) 'Greenfield commit contains the scaffold and its automatic-baseline record'
    Assert-True ($greenRecord.decision -eq 'automatic' -and $greenStatus.Count -eq 0) 'Greenfield baseline record is committed and the repository ends clean'
    Assert-True (@($greenActions | Where-Object { $_.Step -eq 'bootstrap-commit' -and $_.Outcome -match 'created and announced' }).Count -eq 1) 'Greenfield summary explicitly records that the commit was announced'

    $brownfield = Join-Path $scratch 'brownfield'
    New-TestRepository -Path $brownfield -WithBaseline
    $brownHeadBefore = (Invoke-TestGit -RepoRoot $brownfield -Arguments @('rev-parse', 'HEAD') | Select-Object -First 1).Trim()
    [System.IO.File]::WriteAllText((Join-Path $brownfield 'specrew-scaffold.md'), "# generated`n", [System.Text.UTF8Encoding]::new($false))
    $brownActions = [System.Collections.ArrayList]::new()
    $brownResult = Invoke-SpecrewBootstrapBaseline `
        -ProjectPath $brownfield `
        -BootstrapMode brownfield `
        -BrownfieldDecision offer `
        -Actions $brownActions `
        -PreviewOnly:$false

    $brownHeadAfter = (Invoke-TestGit -RepoRoot $brownfield -Arguments @('rev-parse', 'HEAD') | Select-Object -First 1).Trim()
    $brownRecord = Get-Content -LiteralPath $brownResult.RecordPath -Raw -Encoding UTF8 | ConvertFrom-Json
    Assert-True ($brownHeadAfter -eq $brownHeadBefore -and $null -eq $brownResult.Commit) 'Brownfield offer never creates a surprise commit'
    Assert-True ($brownRecord.mode -eq 'brownfield' -and $brownRecord.decision -eq 'offered') 'Brownfield offer is recorded as structured repository evidence'
    Assert-True (@($brownActions | Where-Object { $_.Step -eq 'bootstrap-commit' -and $_.Outcome -match 'offered; no commit created' }).Count -eq 1) 'Brownfield summary makes the offer and no-commit posture explicit'

    $declineActions = [System.Collections.ArrayList]::new()
    $declineResult = Invoke-SpecrewBootstrapBaseline `
        -ProjectPath $brownfield `
        -BootstrapMode brownfield `
        -BrownfieldDecision decline `
        -Actions $declineActions `
        -PreviewOnly:$false
    $declineRecord = Get-Content -LiteralPath $declineResult.RecordPath -Raw -Encoding UTF8 | ConvertFrom-Json
    Assert-True ($declineRecord.decision -eq 'declined') 'An explicit brownfield decline replaces the pending offer with a recorded decline'
    Assert-True (((Invoke-TestGit -RepoRoot $brownfield -Arguments @('rev-parse', 'HEAD') | Select-Object -First 1).Trim()) -eq $brownHeadBefore) 'Recording a brownfield decline still creates no commit'

    $repeatActions = [System.Collections.ArrayList]::new()
    $null = Invoke-SpecrewBootstrapBaseline `
        -ProjectPath $brownfield `
        -BootstrapMode brownfield `
        -BrownfieldDecision offer `
        -Actions $repeatActions `
        -PreviewOnly:$false
    $repeatRecord = Get-Content -LiteralPath $declineResult.RecordPath -Raw -Encoding UTF8 | ConvertFrom-Json
    Assert-True ($repeatRecord.decision -eq 'declined') 'A later default offer never erases an already-recorded decline'

    $preview = Join-Path $scratch 'preview'
    New-TestRepository -Path $preview -WithBaseline
    $previewActions = [System.Collections.ArrayList]::new()
    $null = Invoke-SpecrewBootstrapBaseline `
        -ProjectPath $preview `
        -BootstrapMode brownfield `
        -BrownfieldDecision offer `
        -Actions $previewActions `
        -PreviewOnly:$true
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $preview '.specrew\bootstrap-baseline.json'))) 'Dry-run offer writes no baseline record'

    $initContent = Get-Content -LiteralPath (Join-Path $repoRoot 'scripts\specrew-init.ps1') -Raw -Encoding UTF8
    $usageContent = Get-Content -LiteralPath (Join-Path $repoRoot 'scripts\init\preflight.ps1') -Raw -Encoding UTF8
    Assert-True ($initContent -match '\$bootstrapMode\s*=\s*if \(\$blockingEntries\.Count -gt 0 -or \$initialGitHasHead\)') 'Production init classifies existing content or history as brownfield before mutation'
    Assert-True (([regex]::Matches($initContent, 'Invoke-SpecrewBootstrapBaseline')).Count -eq 2) 'Production init wires baseline finalization through normal and already-bootstrapped tails'
    Assert-True ($initContent.IndexOf('Invoke-SpecrewBootstrapBaseline', $initContent.LastIndexOf('Validating bootstrapped project state')) -lt $initContent.LastIndexOf('Write-BootstrapSummary')) 'Production init finalizes the baseline before rendering its summary'
    Assert-True ($usageContent -match 'brownfield-bootstrap-commit <offer\|decline>') 'Init help exposes the recordable brownfield decline surface'
}
finally {
    if (Test-Path -LiteralPath $scratch) {
        Remove-Item -LiteralPath $scratch -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Host ''
Write-Host 'All bootstrap-commit tests passed.' -ForegroundColor Green
exit 0
