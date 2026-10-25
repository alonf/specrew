# PRED-BETA4-046 / B4F-088: `specrew update` REFRESHES THE REFOCUS DIGESTS.
#
# Found verifying the router-skill project's update to 79ab618d: integrity read 0 drifted, and the project's
# `.specify/extensions/specrew-speckit/refocus/general.md` was the digest of its init day - the deploy's copy
# list had every extension item but `refocus/`, so no update ever refreshed the digests the refocus hook reads
# (Get-RefocusDigestRoot takes the project's copy). A fresh init got them whole through `specify extension add`;
# every updated project ran stale rules. The deploy is run for real onto a scratch `.specify`.
# Mutation (recorded, not a switch): the `refocus` row removed from $itemsToCopy reds case 1 - the
# reproduction of B4F-088, 0 files under refocus/.

$ErrorActionPreference = 'Stop'
$script:Failures = 0
function Assert-True { param([bool]$Condition, [string]$Message) if ($Condition) { Write-Host ('  PASS: ' + $Message) } else { Write-Host ('  FAIL: ' + $Message); $script:Failures++ } }

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$deploy = Join-Path $repoRoot 'extensions/specrew-speckit/scripts/deploy-speckit-extension.ps1'
$moduleDigests = Join-Path $repoRoot 'extensions/specrew-speckit/refocus'
. (Join-Path $repoRoot 'extensions/specrew-speckit/scripts/shared-governance.ps1')

Write-Host 'extension-deploy-refocus-digests'
$root = Join-Path ([IO.Path]::GetTempPath()) ('edr-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Path (Join-Path $root '.specify') -Force | Out-Null
try {
    $expected = @(Get-ChildItem -LiteralPath $moduleDigests -Filter '*.md' -File | Sort-Object Name)
    Assert-True ($expected.Count -ge 5 -and ($expected.Name -contains 'general.md')) ('the module carries the digests ({0}, general.md among them)' -f $expected.Count)

    Write-Host '  --- case 1: the deploy lands the refocus digests (B4F-088 reproduction: it landed none) ---'
    $null = @(& pwsh -NoProfile -File $deploy -ProjectPath $root -PassThru 2>&1)
    $deployedDir = Join-Path $root '.specify/extensions/specrew-speckit/refocus'
    $deployed = @(if (Test-Path -LiteralPath $deployedDir -PathType Container) { Get-ChildItem -LiteralPath $deployedDir -Filter '*.md' -File | Sort-Object Name })
    Assert-True ($deployed.Count -eq $expected.Count) ('every digest the module carries is deployed ({0} of {1})' -f $deployed.Count, $expected.Count)
    $general = Join-Path $deployedDir 'general.md'
    Assert-True ((Test-Path -LiteralPath $general) -and ((Get-FileHash -LiteralPath $general -Algorithm SHA256).Hash -eq (Get-FileHash -LiteralPath (Join-Path $moduleDigests 'general.md') -Algorithm SHA256).Hash)) 'general.md is byte-identical to the module''s'
    Assert-True ((Get-Content -LiteralPath $general -Raw) -match 'A captured approval is the instruction') 'and carries rule 1''s captured-approval sentence (B4F-086''s digest half reaches the project)'

    Write-Host '  --- case 2: a stale deployed digest is refreshed by the next deploy (the update path: -RefreshExisting, as specrew-update.ps1 invokes it) ---'
    [IO.File]::WriteAllText($general, "# stale digest from an earlier build`n", [Text.UTF8Encoding]::new($false))
    $null = @(& pwsh -NoProfile -File $deploy -ProjectPath $root -RefreshExisting -PassThru 2>&1)
    Assert-True ((Get-FileHash -LiteralPath $general -Algorithm SHA256).Hash -eq (Get-FileHash -LiteralPath (Join-Path $moduleDigests 'general.md') -Algorithm SHA256).Hash) 'a changed deployed digest is refreshed back to the module''s bytes'
    $integrity = Test-SpecrewDeployedExtensionIntegrity -ProjectRoot $root
    Assert-True (@($integrity.drifted).Count -eq 0 -and @($integrity.missing).Count -eq 0) ('and the deployed marker reads 0 drifted / 0 missing afterwards (drifted: {0})' -f (@($integrity.drifted) -join ','))
}
finally {
    if (Test-Path -LiteralPath $root) { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
}

if ($script:Failures -gt 0) { Write-Host ("extension-deploy-refocus-digests: {0} FAILED" -f $script:Failures); exit 1 }
Write-Host 'extension-deploy-refocus-digests: all cases passed'
exit 0
