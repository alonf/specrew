# boundary-reader-conformance.Tests.ps1
#
# Fix 1 (iter-007 real-host dogfood): the start-context v1->v2 schema migration stranded FOUR boundary readers
# on the dead v1 field (session_state.boundary_type). On a v2 project (boundary_enforcement.last_authorized_
# boundary, NO session_state) they read $null -> silent no-op: the navigator never fired AND the handover
# hollowed (boundary:null). The CANONICAL reader is Get-SpecrewStartContextBoundary (shared-governance.ps1).
# The self-contained hot-path providers (refocus / hook-dispatcher / navigator) cannot load shared-governance,
# so each carries a THIN LOCAL MIRROR. This is the drift guardrail that was MISSING when the bug shipped:
# it pins every mirror identical to the canonical across v1, v2, and the no-boundary edge. If a future schema
# change (or a careless edit) updates only some readers, THIS test fails before it ships.

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path

# Canonical + Normalize from the REAL shared-governance (dot-source-safe; other tests load it the same way).
. (Join-Path $repoRoot 'extensions\specrew-speckit\scripts\shared-governance.ps1')

# The provider scripts are ENTRY scripts (they execute their main block on run), so extract JUST the named
# function via an AST parse - no main-block execution, no subprocess.
function Get-NamedFunctionText {
    param([string]$Path, [string]$Name)
    $t = $null; $e = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path $Path).Path, [ref]$t, [ref]$e)
    $fn = $ast.FindAll({ param($n) ($n -is [System.Management.Automation.Language.FunctionDefinitionAst]) -and $n.Name -eq $Name }, $true) | Select-Object -First 1
    if (-not $fn) { throw "function '$Name' not found in $Path" }
    return $fn.Extent.Text
}
# Dot-source each extracted function at SCRIPT scope (top level) so it is visible inside Describe/It.
. ([scriptblock]::Create((Get-NamedFunctionText (Join-Path $repoRoot 'scripts\internal\refocus.ps1') 'Get-RefocusCurrentBoundary')))
. ([scriptblock]::Create((Get-NamedFunctionText (Join-Path $repoRoot 'scripts\internal\specrew-hook-dispatcher.ps1') 'Get-BoundaryCursor')))
. ([scriptblock]::Create((Get-NamedFunctionText (Join-Path $repoRoot 'scripts\internal\continuous-co-review\continuous-co-review-navigator.ps1') 'Get-ContinuousCoReviewNavigatorImplementStage')))

Describe 'boundary-reader conformance: canonical == every self-contained-provider mirror' {
    $cases = @(
        @{ name = 'v1 before-implement';  json = '{"session_state":{"boundary_type":"before-implement"}}';                          expect = 'before-implement'; stage = 'implement' }
        @{ name = 'v2 before-implement';  json = '{"schema":"v2","boundary_enforcement":{"last_authorized_boundary":"before-implement"}}'; expect = 'before-implement'; stage = 'implement' }
        @{ name = 'v1 review-signoff';    json = '{"session_state":{"boundary_type":"review-signoff"}}';                            expect = 'review-signoff';   stage = '' }
        @{ name = 'v2 review-signoff';    json = '{"schema":"v2","boundary_enforcement":{"last_authorized_boundary":"review-signoff"}}';   expect = 'review-signoff';   stage = '' }
        @{ name = 'neither field present'; json = '{"schema":"v2","boundary_enforcement":{}}';                                       expect = '';                 stage = '' }
    )
    foreach ($c in $cases) {
        Context $c.name {
            $root = Join-Path $env:TEMP ('brc-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
            New-Item -ItemType Directory -Path (Join-Path $root '.specrew') -Force | Out-Null
            $c.json | Set-Content -LiteralPath (Join-Path $root '.specrew/start-context.json') -Encoding UTF8
            $obj = $c.json | ConvertFrom-Json
            $canonical = [string](Get-SpecrewStartContextBoundary -StartContext $obj)
            $refocus = [string](Get-RefocusCurrentBoundary -StartContext $obj)
            $disp = [string]((Get-BoundaryCursor -ProjectRoot $root).Cursor)
            $nav = [string](Get-ContinuousCoReviewNavigatorImplementStage -RepoRoot $root)
            $expect = [string]$c.expect
            $expectStage = [string]$c.stage
            Remove-Item $root -Recurse -Force -ErrorAction SilentlyContinue

            It 'canonical reads the expected boundary' { $canonical | Should -Be $expect }
            It 'refocus mirror == canonical' { $refocus | Should -Be $canonical }
            It 'dispatcher mirror == canonical' { $disp | Should -Be $canonical }
            It 'navigator stage maps from the same boundary' { $nav | Should -Be $expectStage }
        }
    }
}
