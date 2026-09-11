# PRED-BETA4-034: A FRESH PROJECT'S CHARTERS ARE SPECREW'S, AND A REAL EDIT IS STILL A REAL EDIT.
#
# The stage-demo audit of the installed ef80591d: init followed by two starts printed five "Preserving
# user-edited file" warnings for crew charters nobody had edited. Init composes `.squad/agents/<role>/charter.md`
# (shipped charter + managed directives block) and wrote no sidecar; the Copilot handler at start decides
# ownership by the sidecar's presence, and would replace the composition with the shorter canonical body if it
# were merely marked. Now the sidecar carries the SHA-256 of what Specrew wrote; init writes it; a mismatch is a
# genuine user edit, reported once and preserved.
#
# THIS SUITE RUNS THE REAL init AND THE REAL start (-NoLaunch, copilot) on a scratch project - the audit's own
# acceptance: init plus two starts, zero warnings for untouched generated files; a real edit still preserved
# and reported. Mutation (recorded, not a switch): the sidecar write removed from deploy-squad-runtime.ps1
# brings the five warnings back on the first start.

$ErrorActionPreference = 'Stop'
$script:Failures = 0
function Assert-True { param([bool]$Condition, [string]$Message) if ($Condition) { Write-Host ('  PASS: ' + $Message) } else { Write-Host ('  FAIL: ' + $Message); $script:Failures++ } }

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$initScript = Join-Path $repoRoot 'scripts/specrew-init.ps1'
$startScript = Join-Path $repoRoot 'scripts/specrew-start.ps1'
$priorModulePath = $env:SPECREW_MODULE_PATH
$env:SPECREW_MODULE_PATH = $repoRoot
$roles = @('spec-steward', 'planner', 'implementer', 'reviewer', 'retro-facilitator')

function Invoke-Start {
    param([string]$Root)
    $out = (& pwsh -NoProfile -File $startScript -ProjectPath $Root -NoLaunch -HostKind copilot -SkipUpdateCheck 2>&1 | ForEach-Object { [string]$_ }) -join "`n"
    return [pscustomobject]@{ Code = $LASTEXITCODE; Out = ($out -replace '\x1b\[[0-9;]*m', '') }
}
function Get-CharterHashes { param([string]$Root) $h = @{}; foreach ($r in $roles) { $p = Join-Path $Root ".squad/agents/$r/charter.md"; $h[$r] = if (Test-Path -LiteralPath $p) { (Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash } else { '' } }; return $h }

Write-Host 'crew-charter-ownership'
$root = Join-Path ([IO.Path]::GetTempPath()) ('cco-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Path $root -Force | Out-Null
try {
    Write-Host '  --- init ---'
    $initOut = (& pwsh -NoProfile -File $initScript -ProjectPath $root -Agents copilot -SkipUpdateCheck -BrownfieldBootstrapCommit decline 2>&1 | ForEach-Object { [string]$_ }) -join "`n"
    $initCode = $LASTEXITCODE
    Assert-True ($initCode -eq 0) ('the real init exits 0 (tail: ' + (($initOut -replace '\s+', ' ')).Substring([Math]::Max(0, ($initOut -replace '\s+', ' ').Length - 160)) + ')')
    $charters = @($roles | Where-Object { Test-Path -LiteralPath (Join-Path $root ".squad/agents/$_/charter.md") })
    Assert-True ($charters.Count -eq 5) ('init wrote the five crew charters (' + $charters.Count + ')')
    $sidecars = @($roles | Where-Object { Test-Path -LiteralPath (Join-Path $root ".squad/agents/$_/charter.md.specrew-managed") })
    Assert-True ($sidecars.Count -eq 5) ('and a sidecar beside each, carrying the ownership hash (' + $sidecars.Count + ')')
    $plannerSidecar = Join-Path $root '.squad/agents/planner/charter.md.specrew-managed'
    $sidecarText = if (Test-Path -LiteralPath $plannerSidecar) { Get-Content -LiteralPath $plannerSidecar -Raw } else { '' }
    $plannerHash = (Get-FileHash -LiteralPath (Join-Path $root '.squad/agents/planner/charter.md') -Algorithm SHA256).Hash.ToLowerInvariant()
    Assert-True ($sidecarText -match ('sha256:\s*' + $plannerHash)) 'the sidecar records the hash of the charter as written'
    Assert-True ((Get-Content -LiteralPath (Join-Path $root '.squad/agents/planner/charter.md') -Raw) -match 'specrew-managed directives') 'the charter carries init''s directives block'
    $afterInit = Get-CharterHashes -Root $root

    Write-Host '  --- first start ---'
    $s1 = Invoke-Start -Root $root
    Assert-True ($s1.Code -eq 0) ('the first start exits 0 (tail: ' + (($s1.Out -replace '\s+', ' ')).Substring([Math]::Max(0, ($s1.Out -replace '\s+', ' ').Length - 160)) + ')')
    $warn1 = @([regex]::Matches($s1.Out, 'Preserving user-edited file')).Count
    Assert-True ($warn1 -eq 0) ('ZERO "Preserving user-edited file" warnings on the first start (the audit measured five; got ' + $warn1 + ')')
    $afterStart1 = Get-CharterHashes -Root $root
    Assert-True (@($roles | Where-Object { $afterStart1[$_] -ne $afterInit[$_] }).Count -eq 0) 'and the five charters are byte-identical to what init wrote - the composition was kept, not replaced by the canonical body'

    Write-Host '  --- second start ---'
    $s2 = Invoke-Start -Root $root
    $warn2 = @([regex]::Matches($s2.Out, 'Preserving user-edited file')).Count
    Assert-True ($s2.Code -eq 0 -and $warn2 -eq 0) ('zero warnings on the second start too (got ' + $warn2 + ')')
    $afterStart2 = Get-CharterHashes -Root $root
    Assert-True (@($roles | Where-Object { $afterStart2[$_] -ne $afterInit[$_] }).Count -eq 0) 'charters still byte-identical after two starts'

    Write-Host '  --- a real edit: preserved, and reported accurately, once ---'
    $reviewer = Join-Path $root '.squad/agents/reviewer/charter.md'
    [IO.File]::AppendAllText($reviewer, "`n## My team's rule`n`nReview the tests first.`n", [Text.UTF8Encoding]::new($false))
    $editedHash = (Get-FileHash -LiteralPath $reviewer -Algorithm SHA256).Hash
    $s3 = Invoke-Start -Root $root
    $warn3 = @([regex]::Matches($s3.Out, 'Preserving user-edited file')).Count
    Assert-True ($warn3 -eq 1) ('exactly ONE warning after one real edit (got ' + $warn3 + ')')
    Assert-True ($s3.Out -match "reviewer[\\/]charter\.md' \(edited since Specrew wrote it") 'naming the edited charter and saying why accurately: edited since Specrew wrote it'
    Assert-True ((Get-FileHash -LiteralPath $reviewer -Algorithm SHA256).Hash -eq $editedHash) 'the edit is preserved byte for byte'
    $afterStart3 = Get-CharterHashes -Root $root
    Assert-True (@($roles | Where-Object { $_ -ne 'reviewer' -and $afterStart3[$_] -ne $afterInit[$_] }).Count -eq 0) 'and no other charter was touched'

    Write-Host '  --- the two sidecar writers agree byte for byte ---'
    . (Join-Path $repoRoot 'hosts/_team-canonical.ps1')
    $planner = Join-Path $root '.squad/agents/planner/charter.md'
    $initSidecar = if (Test-Path -LiteralPath ($planner + '.specrew-managed')) { Get-Content -LiteralPath ($planner + '.specrew-managed') -Raw } else { '' }
    Assert-True ($initSidecar -ceq (Get-SpecrewManagedSidecarContent -Path $planner)) 'init''s sidecar text is exactly what the host module''s writer would produce for the same file'
    Assert-True (Test-SpecrewManagedFile -Path $planner) 'and the ownership test reads an untouched charter as Specrew''s'
    Assert-True (-not (Test-SpecrewManagedFile -Path $reviewer)) 'and the edited one as the user''s'
}
finally {
    if (Test-Path -LiteralPath $root) { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    if ($null -eq $priorModulePath) { Remove-Item Env:\SPECREW_MODULE_PATH -ErrorAction SilentlyContinue } else { $env:SPECREW_MODULE_PATH = $priorModulePath }
}

if ($script:Failures -gt 0) { Write-Host ("crew-charter-ownership: {0} FAILED" -f $script:Failures); exit 1 }
Write-Host 'crew-charter-ownership: all cases passed'
exit 0
