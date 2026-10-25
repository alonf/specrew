# PRED-BETA4-034 / PRED-BETA4-036: A FRESH PROJECT'S CHARTERS ARE SPECREW'S, A REAL EDIT IS STILL A REAL EDIT,
# A CANONICAL CHANGE REACHES THE RUNTIME, AND THE NOTICE'S OWN REMEDIES CLEAR IT.
#
# The stage-demo audit of the installed ef80591d: init followed by two starts printed five "Preserving
# user-edited file" warnings for crew charters nobody had edited. The sidecar now carries the SHA-256 of what
# Specrew wrote; init writes it; a mismatch is a genuine user edit, reported and preserved (PRED-BETA4-034).
# The auditor's recheck of 4a7585d8 found the fix's two missing halves (PRED-BETA4-036): an untouched runtime
# charter was never compared with its canonical, so a canonical change never reached the crew; and the notice's
# remedy - delete the sidecar - brought the notice straight back. Now the text before the directives block must
# equal the canonical charter or the charter is rewritten through one shared writer (block kept, sidecar
# re-stamped); the notice names `specrew team own <role>` and `specrew team resync <role>`, both persisted.
# Found on the way: `squad init` writes ITS OWN charter bodies, and init only appended the block to them - the
# canonical planner never reached a fresh Copilot project at all; init now writes the canonical base.
#
# THIS SUITE RUNS THE REAL init, THE REAL start (-NoLaunch, copilot) AND THE REAL `specrew team` VERBS on a
# scratch project - the audit's and the maintainer's acceptance verbatim: init plus two starts, zero warnings;
# a real edit preserved and reported; change the canonical, start, the runtime carries the new text; edit a
# charter, change its canonical, start, the edit is preserved and reported; follow the notice's own instruction
# and the notice does not return. Mutations (recorded, not switches): the sidecar write removed from
# deploy-squad-runtime.ps1 brings the five warnings back; the current-check removed from the handler reds the
# canonical-change part; the owned disposition ignored reds the follow-the-notice part.

$ErrorActionPreference = 'Stop'
$script:Failures = 0
function Assert-True { param([bool]$Condition, [string]$Message) if ($Condition) { Write-Host ('  PASS: ' + $Message) } else { Write-Host ('  FAIL: ' + $Message); $script:Failures++ } }

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$initScript = Join-Path $repoRoot 'scripts/specrew-init.ps1'
$startScript = Join-Path $repoRoot 'scripts/specrew-start.ps1'
$teamScript = Join-Path $repoRoot 'scripts/specrew-team.ps1'
$cliScript = Join-Path $repoRoot 'scripts/specrew.ps1'
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
    $warn1 = @([regex]::Matches($s1.Out, 'Preserving (user-edited file|your charter)')).Count
    Assert-True ($warn1 -eq 0) ('ZERO "Preserving ..." warnings on the first start (the audit measured five; got ' + $warn1 + ')')
    $afterStart1 = Get-CharterHashes -Root $root
    Assert-True (@($roles | Where-Object { $afterStart1[$_] -ne $afterInit[$_] }).Count -eq 0) 'and the five charters are byte-identical to what init wrote - the composition was kept, not replaced by the canonical body'

    Write-Host '  --- second start ---'
    $s2 = Invoke-Start -Root $root
    $warn2 = @([regex]::Matches($s2.Out, 'Preserving (user-edited file|your charter)')).Count
    Assert-True ($s2.Code -eq 0 -and $warn2 -eq 0) ('zero warnings on the second start too (got ' + $warn2 + ')')
    $afterStart2 = Get-CharterHashes -Root $root
    Assert-True (@($roles | Where-Object { $afterStart2[$_] -ne $afterInit[$_] }).Count -eq 0) 'charters still byte-identical after two starts'

    Write-Host '  --- a real edit: preserved, and reported accurately, once ---'
    $reviewer = Join-Path $root '.squad/agents/reviewer/charter.md'
    [IO.File]::AppendAllText($reviewer, "`n## My team's rule`n`nReview the tests first.`n", [Text.UTF8Encoding]::new($false))
    $editedHash = (Get-FileHash -LiteralPath $reviewer -Algorithm SHA256).Hash
    $s3 = Invoke-Start -Root $root
    $warn3 = @([regex]::Matches($s3.Out, 'Preserving (user-edited file|your charter)')).Count
    Assert-True ($warn3 -eq 1) ('exactly ONE warning after one real edit (got ' + $warn3 + ')')
    Assert-True ($s3.Out -match 'specrew team own reviewer' -and $s3.Out -match 'specrew team resync reviewer') 'the notice names its two remedies: specrew team own reviewer / specrew team resync reviewer'
    Assert-True ($s3.Out -notmatch 'delete the sidecar') 'and no longer recommends deleting the sidecar (which only brought the notice back)'
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
    Assert-True (Test-SpecrewCharterCurrent -Path $planner -CanonicalContent (Get-SpecrewCanonicalCharterContent -ProjectPath $root -RoleName planner)) 'and init''s composition reads as CURRENT against the canonical charter (the base is canonical, not what squad init wrote)'
    Assert-True ((Get-Content -LiteralPath $planner -Raw) -match 'boundary-commit cadence') 'the runtime planner carries the canonical planner''s text (boundary-commit cadence), which squad init''s own body lacks'

    Write-Host '  --- PRED-036 (1): change the canonical charter, start - the runtime charter carries the new text ---'
    $plannerCanonical = Join-Path $root '.specrew/team/agents/planner.md'
    [IO.File]::AppendAllText($plannerCanonical, "`n## Team rule`n`nPlan the tests first.`n", [Text.UTF8Encoding]::new($false))
    $s4 = Invoke-Start -Root $root
    Assert-True ($s4.Code -eq 0) 'the start after a canonical change exits 0'
    $plannerText = Get-Content -LiteralPath $planner -Raw
    Assert-True ($plannerText -match 'Plan the tests first\.') 'the runtime planner charter carries the canonical change'
    Assert-True ($plannerText -match '<!-- >>> specrew-managed directives >>> -->') 'and still carries the directives block'
    Assert-True ($plannerText.IndexOf('Plan the tests first.') -lt $plannerText.IndexOf('<!-- >>> specrew-managed directives >>> -->')) 'canonical text first, the block after it - the shared writer''s composition'
    Assert-True (Test-SpecrewManagedFile -Path $planner) 'the sidecar was re-stamped to the rewritten content'
    Assert-True ($s4.Out -match 'Crew runtime synced: 1 agent file') 'start reports one file synced'
    $warn4 = @([regex]::Matches($s4.Out, 'Preserving (user-edited file|your charter)')).Count
    Assert-True ($warn4 -eq 1) ('and the only notice is still the reviewer edit''s (got ' + $warn4 + ')')
    $afterStart4 = Get-CharterHashes -Root $root
    Assert-True (@($roles | Where-Object { $_ -notin @('planner', 'reviewer') -and $afterStart4[$_] -ne $afterInit[$_] }).Count -eq 0) 'the three untouched charters are byte-identical to what init wrote'
    $s5 = Invoke-Start -Root $root
    $afterStart5 = Get-CharterHashes -Root $root
    Assert-True ($afterStart5['planner'] -eq $afterStart4['planner'] -and $s5.Out -notmatch 'Crew runtime synced') 'the next start rewrites nothing: the rewritten charter reads as current'

    Write-Host '  --- PRED-036 (2): the edited charter, its canonical changed too - preserved, reported once ---'
    $reviewerCanonical = Join-Path $root '.specrew/team/agents/reviewer.md'
    [IO.File]::AppendAllText($reviewerCanonical, "`n## Team rule`n`nVerify refunds before approving.`n", [Text.UTF8Encoding]::new($false))
    $s6 = Invoke-Start -Root $root
    Assert-True ((Get-FileHash -LiteralPath $reviewer -Algorithm SHA256).Hash -eq $editedHash) 'the edit is preserved byte for byte when its canonical changes'
    $warn6 = @([regex]::Matches($s6.Out, 'Preserving (user-edited file|your charter)')).Count
    Assert-True ($warn6 -eq 1 -and $s6.Out -match "reviewer[\\/]charter\.md' \(edited since Specrew wrote it") ('reported once, accurately (got ' + $warn6 + ')')

    Write-Host '  --- PRED-036 (3): follow the notice - specrew team own reviewer - and the notice does not return ---'
    $ownOut = (& pwsh -NoProfile -File $teamScript own reviewer -ProjectPath $root 2>&1 | ForEach-Object { [string]$_ }) -join "`n"
    Assert-True ($LASTEXITCODE -eq 0) ('specrew team own reviewer exits 0 (' + (($ownOut -replace '\s+', ' ')).Substring(0, [Math]::Min(120, ($ownOut -replace '\s+', ' ').Length)) + ')')
    $reviewerSidecar = Get-Content -LiteralPath ($reviewer + '.specrew-managed') -Raw
    Assert-True ($reviewerSidecar -match '(?m)^owner: user\s*$') 'the sidecar persists the disposition: owner: user'
    $s7 = Invoke-Start -Root $root
    $s8 = Invoke-Start -Root $root
    $warn7 = @([regex]::Matches($s7.Out, 'Preserving (user-edited file|your charter)')).Count
    $warn8 = @([regex]::Matches($s8.Out, 'Preserving (user-edited file|your charter)')).Count
    Assert-True ($warn7 -eq 0 -and $warn8 -eq 0) ('ZERO notices on the next two starts (got ' + $warn7 + ', ' + $warn8 + ')')
    Assert-True ((Get-FileHash -LiteralPath $reviewer -Algorithm SHA256).Hash -eq $editedHash) 'and the edit is still preserved byte for byte'

    Write-Host '  --- PRED-036 (3b): the other remedy - specrew team resync reviewer - returns it to canonical ---'
    $resyncOut = (& pwsh -NoProfile -File $teamScript resync reviewer -ProjectPath $root 2>&1 | ForEach-Object { [string]$_ }) -join "`n"
    Assert-True ($LASTEXITCODE -eq 0) ('specrew team resync reviewer exits 0 (' + (($resyncOut -replace '\s+', ' ')).Substring(0, [Math]::Min(120, ($resyncOut -replace '\s+', ' ').Length)) + ')')
    $reviewerText = Get-Content -LiteralPath $reviewer -Raw
    Assert-True ($reviewerText -match 'Verify refunds before approving\.') 'the charter carries the canonical text, including the change made while it was the user''s'
    Assert-True ($reviewerText -notmatch "My team's rule") 'the edit is gone, as the notice said it would be'
    Assert-True ($reviewerText -match '<!-- >>> specrew-managed directives >>> -->') 'the directives block survived the resync'
    $afterResync = (Get-FileHash -LiteralPath $reviewer -Algorithm SHA256).Hash
    $s9 = Invoke-Start -Root $root
    $s10 = Invoke-Start -Root $root
    $warn9 = @([regex]::Matches($s9.Out, 'Preserving (user-edited file|your charter)')).Count
    $warn10 = @([regex]::Matches($s10.Out, 'Preserving (user-edited file|your charter)')).Count
    Assert-True ($warn9 -eq 0 -and $warn10 -eq 0 -and (Get-FileHash -LiteralPath $reviewer -Algorithm SHA256).Hash -eq $afterResync) ('zero notices and no rewrite on the two starts after resync (got ' + $warn9 + ', ' + $warn10 + ')')

    Write-Host '  --- the old advice (a deleted sidecar) leaves an unmarked charter; its notice''s remedy still clears it ---'
    Remove-Item -LiteralPath ($planner + '.specrew-managed') -Force
    $s11 = Invoke-Start -Root $root
    $warn11 = @([regex]::Matches($s11.Out, 'Preserving (user-edited file|your charter)')).Count
    Assert-True ($warn11 -eq 1 -and $s11.Out -match "planner[\\/]charter\.md' \(no Specrew-managed marker") ('an unmarked charter is reported once as such (got ' + $warn11 + ')')
    Assert-True ($s11.Out -notmatch 'delete the sidecar' -and $s11.Out -match 'specrew team own planner') 'and its remedy is the persisted disposition, not the deletion of a file that is gone'
    # through the CLI entry this time, with the option the notice's readers will type: --project-path binds
    $ownOut2 = (& pwsh -NoProfile -File $cliScript team own planner --project-path $root 2>&1 | ForEach-Object { [string]$_ }) -join "`n"
    Assert-True ($LASTEXITCODE -eq 0) ('specrew team own planner --project-path <root>, through specrew.ps1, exits 0 on an unmarked charter (' + (($ownOut2 -replace '\s+', ' ')).Substring(0, [Math]::Min(100, ($ownOut2 -replace '\s+', ' ').Length)) + ')')
    $s12 = Invoke-Start -Root $root
    $warn12 = @([regex]::Matches($s12.Out, 'Preserving (user-edited file|your charter)')).Count
    Assert-True ($warn12 -eq 0) ('and the notice does not return (got ' + $warn12 + ')')
}
finally {
    if (Test-Path -LiteralPath $root) { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    if ($null -eq $priorModulePath) { Remove-Item Env:\SPECREW_MODULE_PATH -ErrorAction SilentlyContinue } else { $env:SPECREW_MODULE_PATH = $priorModulePath }
}

if ($script:Failures -gt 0) { Write-Host ("crew-charter-ownership: {0} FAILED" -f $script:Failures); exit 1 }
Write-Host 'crew-charter-ownership: all cases passed'
exit 0
