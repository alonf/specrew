# B4F-060 (PRED-BETA4-033): THE MECHANICAL CHECKS ON A PROJECT WITH NOTHING TO SCAN.
#
# The stage-demo audit of the installed ef80591d ran run-mechanical-checks.ps1 on a project with no
# discoverable source and got `Cannot bind argument to parameter 'SourceFiles' because it is an empty array`.
# The audit's acceptance list is this suite: valid JS and PowerShell projects; documentation-only work; source
# with no tests; invalid/unreadable roots; and a plan that REQUIRES a gate with nothing to check, which stays a
# failure readiness can read. Applicability is per gate and per input set, said on stderr and persisted in the
# evidence rows; the findings JSON keeps its v1 schema.
# Mutation (recorded, not a switch): [AllowEmptyCollection()] removed from Get-DeadFieldFindings' SourceFiles
# parameter reproduces the audit's exact error on the empty-source cases.

$ErrorActionPreference = 'Stop'
$script:Failures = 0
function Assert-True { param([bool]$Condition, [string]$Message) if ($Condition) { Write-Host ('  PASS: ' + $Message) } else { Write-Host ('  FAIL: ' + $Message); $script:Failures++ } }

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$checker = Join-Path $repoRoot 'extensions/specrew-speckit/scripts/run-mechanical-checks.ps1'
$schemaSource = Join-Path $repoRoot 'templates/specify/templates/contracts/mechanical-findings.schema.json'
if (-not (Test-Path -LiteralPath $schemaSource)) { $schemaSource = @(Get-ChildItem -LiteralPath $repoRoot -Recurse -Filter 'mechanical-findings.schema.json' -File | Where-Object { $_.FullName -notmatch '[\\/]\.scratch[\\/]|[\\/]node_modules[\\/]' } | Select-Object -First 1).FullName }

function New-Project {
    param([string[]]$Source = @(), [string[]]$Tests = @(), [string]$GatesTable = '', [switch]$WithContract)
    $root = Join-Path ([IO.Path]::GetTempPath()) ('mca-' + [guid]::NewGuid().ToString('N').Substring(0, 10))
    $feature = Join-Path $root 'specs/001-fixture'; $iter = Join-Path $feature 'iterations/001'
    New-Item -ItemType Directory -Path (Join-Path $feature 'contracts') -Force | Out-Null
    New-Item -ItemType Directory -Path $iter -Force | Out-Null
    Copy-Item -LiteralPath $schemaSource -Destination (Join-Path $feature 'contracts/mechanical-findings.schema.json') -Force
    if ($WithContract) { [IO.File]::WriteAllText((Join-Path $feature 'contracts/quality-governance-artifacts.md'), "# Quality governance artifacts`n", [Text.UTF8Encoding]::new($false)) }
    [IO.File]::WriteAllText((Join-Path $feature 'spec.md'), "# Feature Specification: Fixture`n", [Text.UTF8Encoding]::new($false))
    $plan = "# Iteration Plan: 001`n`n**Status**: implementing`n`n## Tasks`n`n| Task | Requirement | Title | Story | Effort |`n| ---- | ----------- | ----- | ----- | ------ |`n| T-001 | FR-001 | Do the thing | S-1 | 2 |`n"
    if (-not [string]::IsNullOrWhiteSpace($GatesTable)) { $plan += "`n### Required Quality Gates`n`n" + $GatesTable + "`n" }
    [IO.File]::WriteAllText((Join-Path $iter 'plan.md'), $plan, [Text.UTF8Encoding]::new($false))
    foreach ($s in $Source) { $p = Join-Path $root $s; New-Item -ItemType Directory -Path (Split-Path -Parent $p) -Force | Out-Null; [IO.File]::WriteAllText($p, "export function add(a, b) { return a + b; }`n", [Text.UTF8Encoding]::new($false)) }
    foreach ($t in $Tests) { $p = Join-Path $root $t; New-Item -ItemType Directory -Path (Split-Path -Parent $p) -Force | Out-Null; [IO.File]::WriteAllText($p, "import { add } from '../src/app.js';`nif (add(1, 2) !== 3) { throw new Error('add'); }`n", [Text.UTF8Encoding]::new($false)) }
    return [pscustomobject]@{ Root = $root; Iteration = $iter }
}
function Invoke-Checker {
    param([string]$Root, [string]$Iteration)
    $errFile = Join-Path ([IO.Path]::GetTempPath()) ('mca-err-' + [guid]::NewGuid().ToString('N') + '.txt')
    $out = (& pwsh -NoProfile -File $checker -ProjectPath $Root -IterationPath $Iteration -OutputFormat Json 2>$errFile | ForEach-Object { [string]$_ }) -join "`n"
    $code = $LASTEXITCODE
    $err = if (Test-Path -LiteralPath $errFile) { Get-Content -LiteralPath $errFile -Raw } else { '' }
    Remove-Item -LiteralPath $errFile -Force -ErrorAction SilentlyContinue
    return [pscustomobject]@{ Code = $code; Out = [string]$out; Err = ([string]$err -replace '\x1b\[[0-9;]*m', '') }
}
function Read-Evidence { param([string]$Iteration) $p = Join-Path $Iteration 'quality/quality-evidence.md'; if (Test-Path -LiteralPath $p) { return (Get-Content -LiteralPath $p -Raw) } else { return '' } }
function Get-Status { param([string]$Evidence, [string]$Gate) $m = [regex]::Match($Evidence, ('(?m)^\|\s*`?' + [regex]::Escape($Gate) + '`?\s*\|[^|]*\|[^|]*\|\s*`?([a-z-]+)`?\s*\|')); if ($m.Success) { return $m.Groups[1].Value } else { return '' } }

$defaultGates = "| Required Quality Gate | Category | Evidence Source | Phase 1 Status |`n| --- | --- | --- | --- |`n| [gate ID] | [mechanical/tooling/manual-evidence] | [command or artifact path] | [planned] |"
$requiredGates = "| Required Quality Gate | Category | Evidence Source | Phase 1 Status |`n| --- | --- | --- | --- |`n| dead-field | mechanical | specs/001-fixture/iterations/001/quality/mechanical-findings.json | planned |`n| anti-pattern | mechanical | specs/001-fixture/iterations/001/quality/mechanical-findings.json | planned |`n| test-integrity | mechanical | specs/001-fixture/iterations/001/quality/mechanical-findings.json | planned |"

Write-Host 'mechanical-checks-applicability'
Assert-True (-not [string]::IsNullOrWhiteSpace($schemaSource) -and (Test-Path -LiteralPath $schemaSource)) ('precondition: the v1 findings schema is available (' + $schemaSource + ')')
if ($script:Failures -gt 0) { Write-Host 'INCONCLUSIVE'; exit 1 }
$roots = New-Object System.Collections.Generic.List[string]
try {
    Write-Host '  --- 1. a valid JS project (source + test) ---'
    $p1 = New-Project -Source @('src/app.js') -Tests @('tests/app.test.js') -WithContract; $roots.Add($p1.Root) | Out-Null
    $r1 = Invoke-Checker -Root $p1.Root -Iteration $p1.Iteration
    Assert-True ($r1.Code -eq 0 -and $r1.Out -match '"findings"') 'exit 0 with a findings payload'
    $e1 = Read-Evidence -Iteration $p1.Iteration
    Assert-True ((Get-Status $e1 'dead-field') -eq 'passed' -and (Get-Status $e1 'anti-pattern') -eq 'passed' -and (Get-Status $e1 'test-integrity') -eq 'passed') 'the three mechanical gates read passed'
    Assert-True ($r1.Err -notmatch '\[mechanical\]') 'nothing to say about applicability - every gate ran'

    Write-Host '  --- 2. a valid PowerShell project ---'
    $p2 = New-Project -WithContract; $roots.Add($p2.Root) | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $p2.Root 'src') -Force | Out-Null; New-Item -ItemType Directory -Path (Join-Path $p2.Root 'tests') -Force | Out-Null
    [IO.File]::WriteAllText((Join-Path $p2.Root 'src/app.ps1'), "function Add-Two { param([int]`$a, [int]`$b) return `$a + `$b }`n", [Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText((Join-Path $p2.Root 'tests/app.tests.ps1'), ". `$PSScriptRoot/../src/app.ps1`nif ((Add-Two 1 2) -ne 3) { throw 'add' }`n", [Text.UTF8Encoding]::new($false))
    $r2 = Invoke-Checker -Root $p2.Root -Iteration $p2.Iteration
    $e2 = Read-Evidence -Iteration $p2.Iteration
    Assert-True ($r2.Code -eq 0 -and (Get-Status $e2 'dead-field') -eq 'passed' -and (Get-Status $e2 'test-integrity') -eq 'passed') 'a PowerShell project: exit 0, gates passed'

    Write-Host '  --- 3. documentation-only work: nothing to scan, the plan silent on mechanical gates ---'
    $p3 = New-Project -GatesTable $defaultGates -WithContract; $roots.Add($p3.Root) | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $p3.Root 'docs') -Force | Out-Null
    [IO.File]::WriteAllText((Join-Path $p3.Root 'docs/guide.md'), "# Guide`n", [Text.UTF8Encoding]::new($false))
    $r3 = Invoke-Checker -Root $p3.Root -Iteration $p3.Iteration
    $err3 = ($r3.Err -replace '\s+', ' ')
    Assert-True ($r3.Code -eq 0) ('docs-only work exits 0 (err: ' + $err3.Substring(0, [Math]::Min(120, $err3.Length)) + ')')
    Assert-True ($r3.Out -match '"findings":\s*\[\s*\]') 'with a valid, empty findings payload'
    $e3 = Read-Evidence -Iteration $p3.Iteration
    Assert-True ((Get-Status $e3 'dead-field') -eq 'not-applicable' -and (Get-Status $e3 'anti-pattern') -eq 'not-applicable' -and (Get-Status $e3 'test-integrity') -eq 'not-applicable') 'the three gates read not-applicable in the evidence'
    Assert-True ($e3 -match 'no source files found under the project root' -and $e3 -match '\.ps1' -and $e3 -match '\.js') 'each naming what was searched: the roots and the extensions'
    Assert-True ($r3.Err -match '\[mechanical\] dead-field: not-applicable' -and $r3.Err -match '\[mechanical\] test-integrity: not-applicable') 'and said on stderr, stdout kept for the payload'

    Write-Host '  --- 4. source with no tests: applicability kept separate ---'
    $p4 = New-Project -Source @('src/app.js') -WithContract; $roots.Add($p4.Root) | Out-Null
    $r4 = Invoke-Checker -Root $p4.Root -Iteration $p4.Iteration
    $e4 = Read-Evidence -Iteration $p4.Iteration
    Assert-True ($r4.Code -eq 0 -and (Get-Status $e4 'dead-field') -eq 'passed' -and (Get-Status $e4 'anti-pattern') -eq 'passed') 'the source gates ran and passed'
    Assert-True ((Get-Status $e4 'test-integrity') -eq 'not-applicable' -and $e4 -match 'no test files found: files under test/, tests/ or __tests__/') 'the test gate is not-applicable, naming the test pattern'
    Assert-True ($r4.Err -match 'test-integrity: not-applicable' -and $r4.Err -notmatch 'dead-field: not-applicable') 'stderr names only the gate that did not run'

    Write-Host '  --- 5. an invalid root is a distinct error, never an empty success ---'
    $missing = Join-Path ([IO.Path]::GetTempPath()) ('mca-missing-' + [guid]::NewGuid().ToString('N'))
    $r5 = Invoke-Checker -Root $missing -Iteration (Join-Path $missing 'specs/001-fixture/iterations/001')
    Assert-True ($r5.Code -ne 0 -and $r5.Err -match 'does not exist') 'a project path that does not exist throws by name'
    Assert-True ([string]::IsNullOrWhiteSpace($r5.Out)) 'and writes no payload'

    Write-Host '  --- 6. the plan REQUIRES the mechanical gates and there is nothing to check ---'
    $p6 = New-Project -GatesTable $requiredGates -WithContract; $roots.Add($p6.Root) | Out-Null
    $r6 = Invoke-Checker -Root $p6.Root -Iteration $p6.Iteration
    $e6 = Read-Evidence -Iteration $p6.Iteration
    Assert-True ($r6.Code -eq 0) 'the scan itself runs (exit 0)'
    Assert-True ((Get-Status $e6 'dead-field') -eq 'failed' -and (Get-Status $e6 'anti-pattern') -eq 'failed' -and (Get-Status $e6 'test-integrity') -eq 'failed') 'but the required gates read FAILED - the plan required an implementation that is not there'
    Assert-True ($e6 -match 'required by the plan and nothing to check: no source files found') 'naming the requirement and what was searched, so readiness reads a failure, not a pass'

    Write-Host '  --- 7. the audit''s own empty-source fixture shape: a gates table in another shape, no contract ---'
    $p7 = New-Project -GatesTable "| Gate | Command |`n| --- | --- |`n| Unit tests | node tests/app.test.js |"; $roots.Add($p7.Root) | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $p7.Root 'src') -Force | Out-Null
    $r7 = Invoke-Checker -Root $p7.Root -Iteration $p7.Iteration
    Assert-True ($r7.Code -eq 0 -and $r7.Out -match '"findings":\s*\[\s*\]') 'exit 0 with an empty payload (the audit measured exit 1 and no payload)'
    Assert-True ($r7.Err -match 'dead-field: not-applicable - no source files found under src') 'the applicability is said even when no evidence table is written'
}
finally { foreach ($r in $roots) { if (Test-Path -LiteralPath $r) { Remove-Item -LiteralPath $r -Recurse -Force -ErrorAction SilentlyContinue } } }

if ($script:Failures -gt 0) { Write-Host ("mechanical-checks-applicability: {0} FAILED" -f $script:Failures); exit 1 }
Write-Host 'mechanical-checks-applicability: all cases passed'
exit 0
