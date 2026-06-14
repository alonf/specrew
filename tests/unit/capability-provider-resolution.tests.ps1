[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Feature 182 iteration 004 (T407, FR-026 / DF-004): capability detection reads the canonical forge
# provider (provider.name), NOT the CI-system field (ci.provider, e.g. gitlab-ci), with a fallback for
# older/simpler schema shapes.

function Write-Pass { param([string]$m) Write-Host "PASS: $m" -ForegroundColor Green }
function Write-Fail { param([string]$m) Write-Host "FAIL: $m" -ForegroundColor Red; exit 1 }

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $repoRoot 'extensions/specrew-speckit/scripts/work-kind-common.ps1')
. (Join-Path $repoRoot 'extensions/specrew-speckit/scripts/provider-adapter.ps1')
. (Join-Path $repoRoot 'extensions/specrew-speckit/scripts/provider-generic.ps1')
. (Join-Path $repoRoot 'extensions/specrew-speckit/scripts/capability-detector.ps1')

function New-GovFixture {
    param([string[]]$Lines)
    $dir = Join-Path ([System.IO.Path]::GetTempPath()) ("pv-" + [System.IO.Path]::GetRandomFileName())
    New-Item -ItemType Directory -Force (Join-Path $dir '.specrew') | Out-Null
    Set-Content -LiteralPath (Join-Path $dir '.specrew/repository-governance.yml') -Value $Lines -Encoding UTF8
    return $dir
}

$cases = @(
    @{ Name = 'rich shape provider.name=gitlab with ci.provider=gitlab-ci (DF-004)'; Expect = 'gitlab';
       Lines = @('provider:', '  name: gitlab', '  remote_url: gitlab.com/x', 'ci:', '  provider: gitlab-ci') }
    @{ Name = 'canonical template repository_governance.provider=github'; Expect = 'github';
       Lines = @('repository_governance:', '  provider: github', '  branch_model:', '    style: trunk') }
    @{ Name = 'simplest scalar provider: github'; Expect = 'github';
       Lines = @('provider: github') }
    @{ Name = 'rich shape provider.name=azure-devops, no ci block'; Expect = 'azure-devops';
       Lines = @('provider:', '  name: azure-devops') }
)

foreach ($c in $cases) {
    $dir = New-GovFixture -Lines $c.Lines
    try {
        $got = Resolve-SpecrewGovernanceProvider -ProjectPath $dir
        if ($got -ne $c.Expect) { Write-Fail ("{0}: expected forge provider '{1}', got '{2}'" -f $c.Name, $c.Expect, $got) }
    }
    finally { Remove-Item -Recurse -Force $dir -ErrorAction SilentlyContinue }
}
Write-Pass ("FR-026: Resolve-SpecrewGovernanceProvider reads the canonical forge provider across {0} schema shapes — provider.name wins, ci.provider is NEVER read (DF-004 fixed)." -f $cases.Count)

# end-to-end: the capability report for the DF-004 fixture now reports 'gitlab', not 'gitlab-ci'
$dir = New-GovFixture -Lines @('provider:', '  name: gitlab', 'ci:', '  provider: gitlab-ci')
try {
    $cap = Invoke-SpecrewCapabilityDetection -ProjectPath $dir
    if ([string]$cap.provider -ne 'gitlab') { Write-Fail ("capability report provider should be 'gitlab', got '{0}'" -f $cap.provider) }
}
finally { Remove-Item -Recurse -Force $dir -ErrorAction SilentlyContinue }
Write-Pass "FR-026: the capability report for the DF-004 fixture reports provider 'gitlab' (not 'gitlab-ci')."

Write-Host "`nCapability provider resolution (FR-026 / DF-004): all assertions pass" -ForegroundColor Green
