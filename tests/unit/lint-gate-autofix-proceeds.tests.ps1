# PRED-BETA4-043 / B4F-083: THE PRE-BOUNDARY LINT GATE PROCEEDS AFTER ITS OWN SUCCESSFUL AUTO-FIX.
#
# Measured on the 9154f72b walk as the one unexpected repair prompt: at the specify preflight the gate ran
# `markdownlint --fix` on three agent-written lens records (MD022 x19, MD032 x4 - blank lines around headings
# and lists), repaired them, and then THREW with a four-step manual git sequence and "Boundary-sync HALTED until
# the lint findings are resolved and committed" - a halt for a condition it had already resolved. The coordinator
# rendered that as a commit picker. Now an auto-fix is reported on stderr and the sync proceeds; an UNFIXABLE
# violation still halts, naming file:line. The gate function is extracted from the sync script's AST and run
# against a real repository with a real changed .md; markdownlint-cli must be on PATH (it is on the census
# runner and here); when it is not, the suite says so and skips the two behaviour cases.
# Mutation (recorded, not a switch): the halt-on-auto-fix restored reds case 1.
# The gate runs from the project root, as the sync does: markdownlint-cli honours the CURRENT directory's
# .markdownlintignore and rejects paths outside it, so a gate run from elsewhere reads a dirty file as clean.

$ErrorActionPreference = 'Stop'
$script:Failures = 0
function Assert-True { param([bool]$Condition, [string]$Message) if ($Condition) { Write-Host ('  PASS: ' + $Message) } else { Write-Host ('  FAIL: ' + $Message); $script:Failures++ } }

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$syncScript = Join-Path $repoRoot 'scripts/internal/sync-boundary-state.ps1'
$tokens = $null; $errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile($syncScript, [ref]$tokens, [ref]$errors)
$fn = $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq 'Invoke-PreBoundaryMarkdownLintGate' }, $true) | Select-Object -First 1

Write-Host 'lint-gate-autofix-proceeds'
Assert-True ($null -ne $fn) 'the gate function is present in the sync script'
if ($null -eq $fn) { exit 1 }
. (Join-Path $repoRoot 'extensions/specrew-speckit/scripts/shared-governance.ps1')
Invoke-Expression $fn.Extent.Text

if (-not (Get-Command markdownlint -ErrorAction SilentlyContinue) -and -not (Get-Command npx -ErrorAction SilentlyContinue)) {
    Write-Host '  SKIP: markdownlint-cli is not on PATH here; the gate degrades to a warning and the behaviour cases cannot run'
    Write-Host 'lint-gate-autofix-proceeds: all cases passed'
    exit 0
}

$root = Join-Path ([IO.Path]::GetTempPath()) ('lga-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Path (Join-Path $root 'docs') -Force | Out-Null
try {
    & git -C $root init -q -b main
    & git -C $root config user.email 'f@f'; & git -C $root config user.name 'f'; & git -C $root config core.autocrlf false
    [IO.File]::WriteAllText((Join-Path $root 'README.md'), "# Fixture`n`nBody.`n", [Text.UTF8Encoding]::new($false))
    & git -C $root add -A 2>$null; & git -C $root commit -q -m base 2>$null

    Write-Host '  --- case 1: the walk''s shape - a changed record with MD022/MD032, auto-fixable ---'
    $record = Join-Path $root 'docs/product-domain.md'
    [IO.File]::WriteAllText($record, "# Product`n## Users`nThe maintainer.`n## Pain`nLinks break:`n- silently`n- often`n", [Text.UTF8Encoding]::new($false))
    Push-Location $root
    try {
        $before = @(& markdownlint 'docs/product-domain.md' 2>&1 | ForEach-Object { [string]$_ })
    }
    finally { Pop-Location }
    Assert-True (@($before | Where-Object { $_ -match 'MD022' }).Count -ge 1 -and @($before | Where-Object { $_ -match 'MD032' }).Count -ge 1) ('the fixture is real: markdownlint reports MD022 and MD032 before the gate ({0} finding(s))' -f $before.Count)
    $threw = $null; $stderr = ''
    try {
        $stderrPath = Join-Path $root 'gate.stderr'
        Push-Location $root
        $out = & pwsh -NoProfile -Command ". '$($repoRoot -replace "'", "''")/extensions/specrew-speckit/scripts/shared-governance.ps1'; `$ast = [System.Management.Automation.Language.Parser]::ParseFile('$($syncScript -replace "'", "''")', [ref]`$null, [ref]`$null); `$fn = `$ast.FindAll({ param(`$n) `$n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and `$n.Name -eq 'Invoke-PreBoundaryMarkdownLintGate' }, `$true) | Select-Object -First 1; Invoke-Expression `$fn.Extent.Text; try { Invoke-PreBoundaryMarkdownLintGate -ProjectPath '$($root -replace "'", "''")'; 'GATE-PROCEEDED' } catch { 'GATE-THREW: ' + `$_.Exception.Message }" 2>$stderrPath
        Pop-Location
        $stderr = if (Test-Path -LiteralPath $stderrPath) { Get-Content -LiteralPath $stderrPath -Raw } else { '' }
        $threw = ($out -join "`n")
    }
    catch { $threw = 'HARNESS: ' + $_.Exception.Message }
    Assert-True ($threw -match 'GATE-PROCEEDED') ('the gate PROCEEDS after its own successful auto-fix (got: ' + (($threw -replace '\s+', ' ')).Substring(0, [Math]::Min(160, ($threw -replace '\s+', ' ').Length)) + ')')
    Assert-True ($threw -notmatch 'HALTED' -and $threw -notmatch 'git commit') 'and no longer instructs a manual git sequence for a condition it resolved'
    Assert-True ($stderr -match 'auto-fixed markdownlint violations in 1 file' -and $stderr -match 'product-domain\.md') 'what it fixed is said on stderr, naming the file'
    $after = [IO.File]::ReadAllText($record)
    Assert-True ($after -match "# Product`r?`n`r?`n## Users" -and $after -match "Links break:`r?`n`r?`n- silently") 'the record is repaired on disk - the boundary commit will carry it'
    Push-Location $root
    try { $lint = @(& markdownlint 'docs/product-domain.md' 2>&1 | ForEach-Object { [string]$_ }) } finally { Pop-Location }
    Assert-True ($lint.Count -eq 0) 'and lints clean afterwards'

    Write-Host '  --- case 2: an UNFIXABLE violation still halts, naming file:line ---'
    $bad = Join-Path $root 'docs/bad.md'
    # MD024 is disabled in the repo config; MD001 (heading increment) is not auto-fixable and is enabled.
    [IO.File]::WriteAllText($bad, "# Title`n`n### Jumped a level`n`nText.`n", [Text.UTF8Encoding]::new($false))
    # the repo's own lint config applies to the fixture, as it does in a Specrew project
    Copy-Item -LiteralPath (Join-Path $repoRoot '.markdownlint.json') -Destination (Join-Path $root '.markdownlint.json') -Force
    Push-Location $root
    $out2 = & pwsh -NoProfile -Command ". '$($repoRoot -replace "'", "''")/extensions/specrew-speckit/scripts/shared-governance.ps1'; `$ast = [System.Management.Automation.Language.Parser]::ParseFile('$($syncScript -replace "'", "''")', [ref]`$null, [ref]`$null); `$fn = `$ast.FindAll({ param(`$n) `$n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and `$n.Name -eq 'Invoke-PreBoundaryMarkdownLintGate' }, `$true) | Select-Object -First 1; Invoke-Expression `$fn.Extent.Text; try { Invoke-PreBoundaryMarkdownLintGate -ProjectPath '$($root -replace "'", "''")'; 'GATE-PROCEEDED' } catch { 'GATE-THREW: ' + `$_.Exception.Message }" 2>$null
    Pop-Location
    $text2 = ($out2 -join "`n")
    Assert-True ($text2 -match 'GATE-THREW' -and $text2 -match 'Unfixable markdownlint violations' -and $text2 -match 'bad\.md:\d+') ('an unfixable violation halts the sync and names file:line (got: ' + (($text2 -replace '\s+', ' ')).Substring(0, [Math]::Min(160, ($text2 -replace '\s+', ' ').Length)) + ')')
}
finally {
    if (Test-Path -LiteralPath $root) { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
}

if ($script:Failures -gt 0) { Write-Host ("lint-gate-autofix-proceeds: {0} FAILED" -f $script:Failures); exit 1 }
Write-Host 'lint-gate-autofix-proceeds: all cases passed'
exit 0
