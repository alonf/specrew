[CmdletBinding()]
param()

# B4F-120 / B4F-122 (202): init never writes outside its project folder.
# A project folder inside another repository's work tree is never greenfield-committed, staging is limited to the
# project folder, init classifies such a folder the same way, and `squad init` (which writes at the git top-level it
# discovers) is confined to the project folder. Every fixture lives under the system temp folder, never in this
# repository, so a failure here cannot commit this repository's own work.

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

function Write-TestFile {
    param([string]$Path, [string]$Text)
    $parent = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $parent)) { $null = New-Item -ItemType Directory -Path $parent -Force }
    [System.IO.File]::WriteAllText($Path, $Text, [System.Text.UTF8Encoding]::new($false))
}

function New-OuterRepository {
    # An enclosing repository the owner is working in: optionally with a commit, always with unrelated dirty work.
    param([string]$Path, [switch]$WithCommit)
    $null = New-Item -ItemType Directory -Path $Path -Force
    Invoke-TestGit -RepoRoot $Path -Arguments @('init', '--quiet') | Out-Null
    Invoke-TestGit -RepoRoot $Path -Arguments @('config', 'user.name', 'Outer Owner') | Out-Null
    Invoke-TestGit -RepoRoot $Path -Arguments @('config', 'user.email', 'outer-owner@example.invalid') | Out-Null
    Write-TestFile -Path (Join-Path $Path 'app.txt') -Text "app`n"
    if ($WithCommit) {
        Invoke-TestGit -RepoRoot $Path -Arguments @('add', '--all') | Out-Null
        Invoke-TestGit -RepoRoot $Path -Arguments @('commit', '--quiet', '-m', 'outer baseline') | Out-Null
        Write-TestFile -Path (Join-Path $Path 'app.txt') -Text "app, edited and not yet committed`n"
    }
    Write-TestFile -Path (Join-Path $Path 'UNRELATED-untracked.txt') -Text "the owner's unrelated work in progress`n"
}

function Get-OuterSnapshot {
    param([string]$Path)
    $head = @(& git -C $Path rev-parse --verify -q HEAD 2>$null) -join ''
    return [pscustomobject]@{
        Head   = $head
        Index  = (@(& git -C $Path ls-files --stage 2>$null) -join "`n")
        Status = (@(& git -C $Path status --porcelain --untracked-files=no 2>$null) -join "`n")
    }
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $repoRoot 'scripts\init\_utilities.ps1')
. (Join-Path $repoRoot 'scripts\init\squad-deploy.ps1')
. (Join-Path $repoRoot 'scripts\init\post-bootstrap-output.ps1')

$scratch = Join-Path ([System.IO.Path]::GetTempPath()) ('specrew-init-stays-' + [guid]::NewGuid().ToString('N').Substring(0, 12))
$null = New-Item -ItemType Directory -Path $scratch -Force
$scratch = (Resolve-Path -LiteralPath $scratch).Path
# Fence git discovery at the scratch folder, so a temp folder that happens to sit inside some repository cannot change
# what these cases see. Every repository a case builds is below the fence.
$savedCeiling = $env:GIT_CEILING_DIRECTORIES
$env:GIT_CEILING_DIRECTORIES = Split-Path -Parent $scratch

try {
    # 1. An enclosing repository with NO commits: the reproduced B4F-120 case. Before the fix, the greenfield bootstrap
    #    skipped git init (the folder was inside a work tree) and `add --all` staged the whole enclosing repository.
    $unbornOuter = Join-Path $scratch 'unborn-outer'
    New-OuterRepository -Path $unbornOuter
    $unbornProject = Join-Path $unbornOuter 'newproj'
    Write-TestFile -Path (Join-Path $unbornProject 'scaffold.md') -Text "# scaffold`n"
    $before = Get-OuterSnapshot -Path $unbornOuter
    $actions = [System.Collections.ArrayList]::new()
    $result = Invoke-SpecrewBootstrapBaseline -ProjectPath $unbornProject -BootstrapMode greenfield -BrownfieldDecision offer -Actions $actions -PreviewOnly:$false 6>$null
    $after = Get-OuterSnapshot -Path $unbornOuter
    Assert-True ([string]::IsNullOrEmpty($after.Head)) 'an enclosing repository with no commits still has no commit after a greenfield bootstrap of a folder inside it'
    Assert-True ($after.Index -eq $before.Index) "the enclosing repository's index is untouched (staged before: '$($before.Index)', after: '$($after.Index)')"
    Assert-True ($null -eq $result.Commit) 'no bootstrap commit is reported for a folder inside another repository'
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $unbornProject '.git'))) 'no nested repository is created inside the enclosing work tree'
    $record = Get-Content -LiteralPath (Join-Path $unbornProject '.specrew\bootstrap-baseline.json') -Raw | ConvertFrom-Json
    Assert-True ($record.decision -eq 'offered' -and $record.mode -eq 'brownfield') "the folder is recorded as an offered (not automatic) bootstrap commit (decision='$($record.decision)')"
    $outcome = ($actions | ForEach-Object { [string]$_.Outcome }) -join ' | '
    Assert-True ($outcome -match 'inside the Git repository') "the action log names the enclosing repository as the reason ('$outcome')"

    # 2. An enclosing repository WITH commits, unrelated tracked edits and untracked work: HEAD and index unchanged.
    $bornOuter = Join-Path $scratch 'born-outer'
    New-OuterRepository -Path $bornOuter -WithCommit
    $bornProject = Join-Path $bornOuter 'newproj'
    Write-TestFile -Path (Join-Path $bornProject 'scaffold.md') -Text "# scaffold`n"
    $before = Get-OuterSnapshot -Path $bornOuter
    $null = Invoke-SpecrewBootstrapBaseline -ProjectPath $bornProject -BootstrapMode greenfield -BrownfieldDecision offer -Actions ([System.Collections.ArrayList]::new()) -PreviewOnly:$false 6>$null
    $after = Get-OuterSnapshot -Path $bornOuter
    Assert-True ($after.Head -eq $before.Head) 'an enclosing repository with commits keeps its HEAD after a greenfield bootstrap of a folder inside it'
    Assert-True ($after.Index -eq $before.Index) "the enclosing repository's index is untouched"
    Assert-True ($after.Status -eq $before.Status) "the enclosing repository's tracked status is untouched"

    # 3. A project that is its own repository still gets its greenfield commit, and the commit holds only project files.
    $ownProject = Join-Path $scratch 'own-project'
    $null = New-Item -ItemType Directory -Path $ownProject -Force
    Write-TestFile -Path (Join-Path $ownProject 'scaffold.md') -Text "# scaffold`n"
    Write-TestFile -Path (Join-Path $ownProject 'docs\readme.md') -Text "readme`n"
    $ownResult = Invoke-SpecrewBootstrapBaseline -ProjectPath $ownProject -BootstrapMode greenfield -BrownfieldDecision offer -Actions ([System.Collections.ArrayList]::new()) -PreviewOnly:$false 6>$null
    Assert-True ($ownResult.Commit -match '^[0-9a-f]{40}$') 'a folder that is not inside any repository is initialized and committed as before'
    $ownFiles = @(Invoke-TestGit -RepoRoot $ownProject -Arguments @('ls-tree', '-r', '--name-only', 'HEAD'))
    Assert-True ($ownFiles -contains 'scaffold.md' -and $ownFiles -contains 'docs/readme.md' -and $ownFiles -contains '.specrew/bootstrap-baseline.json') "the greenfield commit holds the project's files ($($ownFiles -join ', '))"

    # 4. Init classifies a folder the same way the bootstrap does.
    $noRepo = Join-Path $scratch 'no-repo'
    $null = New-Item -ItemType Directory -Path $noRepo -Force
    Assert-True ((Get-SpecrewProjectGitScope -ProjectPath $noRepo) -eq 'none') 'a folder outside any repository has git scope none'
    Assert-True ((Get-SpecrewProjectGitScope -ProjectPath $ownProject) -eq 'own') 'a folder that is its own repository top-level has git scope own'
    $nestedEmpty = Join-Path $unbornOuter 'another-new'
    $null = New-Item -ItemType Directory -Path $nestedEmpty -Force
    Assert-True ((Get-SpecrewProjectGitScope -ProjectPath $nestedEmpty) -eq 'enclosed') 'a folder inside an enclosing repository has git scope enclosed'
    Assert-True ((Resolve-SpecrewBootstrapMode -ProjectPath $noRepo -HasBlockingEntries:$false) -eq 'greenfield') 'an empty folder outside any repository is greenfield'
    Assert-True ((Resolve-SpecrewBootstrapMode -ProjectPath $nestedEmpty -HasBlockingEntries:$false) -eq 'brownfield') 'an empty folder inside an enclosing repository with no commits is brownfield, never greenfield'
    $ownUnborn = Join-Path $scratch 'own-unborn'
    $null = New-Item -ItemType Directory -Path $ownUnborn -Force
    Invoke-TestGit -RepoRoot $ownUnborn -Arguments @('init', '--quiet') | Out-Null
    Assert-True ((Resolve-SpecrewBootstrapMode -ProjectPath $ownUnborn -HasBlockingEntries:$false) -eq 'greenfield') 'an empty folder that is its own repository with no commits stays greenfield'
    Assert-True ((Resolve-SpecrewBootstrapMode -ProjectPath $ownProject -HasBlockingEntries:$false) -eq 'brownfield') 'a folder that is its own repository with commits is brownfield'

    # 5. B4F-122: `squad init` writes .github/agents/squad.agent.md at the git top-level it discovers. A stand-in squad
    #    that does the same proves the call is confined to the project folder, for the init call and the probe.
    $fakeBin = Join-Path $scratch 'fake-bin'
    $fakeSquad = Join-Path $fakeBin 'squad.ps1'
    Write-TestFile -Path $fakeSquad -Text @'
$top = @(& git rev-parse --show-toplevel 2>$null) -join ''
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($top)) { $top = (Get-Location).Path }
$agents = Join-Path $top '.github/agents'
$null = New-Item -ItemType Directory -Path $agents -Force
[System.IO.File]::WriteAllText((Join-Path $agents 'squad.agent.md'), "squad`n")
$null = New-Item -ItemType Directory -Path (Join-Path (Get-Location).Path '.squad') -Force
exit 0
'@
    $squadOuter = Join-Path $scratch 'squad-outer'
    New-OuterRepository -Path $squadOuter -WithCommit
    $squadProject = Join-Path $squadOuter 'newproj'
    $null = New-Item -ItemType Directory -Path $squadProject -Force
    $ceilingBefore = $env:GIT_CEILING_DIRECTORIES
    $squadResult = Invoke-SquadInitInProject -ProjectPath $squadProject -ArgumentList @('init', '--non-interactive') -TimeoutSeconds 60 -SquadCommand $fakeSquad
    Assert-True ($squadResult.ExitCode -eq 0) 'the confined squad init call completes'
    # The fence is set on the Squad child process only (ProcessStartInfo.Environment), never on this session.
    Assert-True ($env:GIT_CEILING_DIRECTORIES -ceq $ceilingBefore) "the caller's GIT_CEILING_DIRECTORIES is unchanged after the call ('$env:GIT_CEILING_DIRECTORIES')"
    Assert-True ([Environment]::GetEnvironmentVariable('GIT_CEILING_DIRECTORIES', 'Process') -ceq $ceilingBefore) 'the process environment holds no fence left by the call'
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $squadOuter '.github'))) 'squad init writes nothing at the enclosing repository root'
    Assert-True (Test-Path -LiteralPath (Join-Path $squadProject '.github\agents\squad.agent.md')) "squad init's agent file lands inside the project folder"

    $probeOuter = Join-Path $scratch 'probe-outer'
    New-OuterRepository -Path $probeOuter -WithCommit
    $probeRoot = Join-Path $probeOuter 'install'
    $null = New-Item -ItemType Directory -Path $probeRoot -Force
    $supports = Test-SquadInitSupportsNonInteractive -ProbeRoot $probeRoot -TimeoutSeconds 60 -SquadCommand $fakeSquad
    Assert-True $supports 'the capability probe still detects --non-interactive support'
    Assert-True ($env:GIT_CEILING_DIRECTORIES -ceq $ceilingBefore) "the probe leaves the caller's GIT_CEILING_DIRECTORIES unchanged"
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $probeOuter '.github'))) 'the capability probe writes nothing at the enclosing repository root'

    Write-Host "`nAll init-stays-in-project tests passed." -ForegroundColor Green
}
finally {
    $env:GIT_CEILING_DIRECTORIES = $savedCeiling
    Remove-Item -LiteralPath $scratch -Recurse -Force -ErrorAction SilentlyContinue
}
