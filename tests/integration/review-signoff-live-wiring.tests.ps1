$ErrorActionPreference = 'Stop'

$script:Failures = 0
function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; $script:Failures++ }
function Assert-Contains {
    param(
        [Parameter(Mandatory)]
        [string] $Content,

        [Parameter(Mandatory)]
        [string] $Pattern,

        [Parameter(Mandatory)]
        [string] $FailureMessage
    )

    if ($Content -match $Pattern) {
        Write-Pass $FailureMessage
    } else {
        Write-Fail $FailureMessage
    }
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path

$sourcePairs = @(
    @{
        Name = 'canonical review-signoff refocus'
        Path = Join-Path $repoRoot 'extensions\specrew-speckit\refocus\review-signoff.md'
    },
    @{
        Name = 'deployed review-signoff refocus mirror'
        Path = Join-Path $repoRoot '.specify\extensions\specrew-speckit\refocus\review-signoff.md'
    },
    @{
        Name = 'canonical review ceremony'
        Path = Join-Path $repoRoot 'extensions\specrew-speckit\squad-templates\ceremonies\review-demo.md'
    },
    @{
        Name = 'deployed review ceremony mirror'
        Path = Join-Path $repoRoot '.specify\extensions\specrew-speckit\squad-templates\ceremonies\review-demo.md'
    },
    @{
        Name = 'canonical reviewer charter'
        Path = Join-Path $repoRoot 'extensions\specrew-speckit\squad-templates\agents\reviewer\charter.md'
    },
    @{
        Name = 'deployed reviewer charter mirror'
        Path = Join-Path $repoRoot '.specify\extensions\specrew-speckit\squad-templates\agents\reviewer\charter.md'
    },
    @{
        Name = 'active reviewer agent canonical'
        Path = Join-Path $repoRoot '.specrew\team\agents\reviewer.md'
    },
    @{
        Name = 'active Claude reviewer agent'
        Path = Join-Path $repoRoot '.claude\agents\reviewer.md'
    },
    @{
        Name = 'active generic reviewer agent'
        Path = Join-Path $repoRoot '.agents\agents\reviewer.md'
    },
    @{
        Name = 'active squad review ceremony'
        Path = Join-Path $repoRoot '.squad\ceremonies.md'
    }
)

foreach ($source in $sourcePairs) {
    if (-not (Test-Path -LiteralPath $source.Path -PathType Leaf)) {
        Write-Fail "$($source.Name) exists"
        continue
    }

    $content = Get-Content -LiteralPath $source.Path -Raw -Encoding UTF8
    Assert-Contains -Content $content -Pattern '(?s)(/specrew-review|specrew review)\s+--live\s+--baseline-ref' -FailureMessage "$($source.Name) requires live review invocation"
    Assert-Contains -Content $content -Pattern '(?s)\.specrew[\\/]+review[\\/]+inline[\\/]+<run-id>[\\/]+gate-verdict\.json|\.specrew\\review\\inline\\<run-id>\\gate-verdict\.json' -FailureMessage "$($source.Name) names gate-verdict live evidence"
    Assert-Contains -Content $content -Pattern '(?s)\.specrew[\\/]+review[\\/]+inline[\\/]+<run-id>[\\/]+review-run\.json|\.specrew\\review\\inline\\<run-id>\\review-run\.json' -FailureMessage "$($source.Name) names review-run live evidence"
}

$codeLensPairs = @(
    @{
        Name = 'canonical code-implementation lens'
        Path = Join-Path $repoRoot 'extensions\specrew-speckit\knowledge\design-lenses\code-implementation.md'
    },
    @{
        Name = 'deployed code-implementation lens mirror'
        Path = Join-Path $repoRoot '.specify\extensions\specrew-speckit\knowledge\design-lenses\code-implementation.md'
    }
)

foreach ($source in $codeLensPairs) {
    if (-not (Test-Path -LiteralPath $source.Path -PathType Leaf)) {
        Write-Fail "$($source.Name) exists"
        continue
    }

    $content = Get-Content -LiteralPath $source.Path -Raw -Encoding UTF8
    Assert-Contains -Content $content -Pattern 'which continuous co-review harness and model should review the code' -FailureMessage "$($source.Name) asks for reviewer harness and model during the code lens"
    Assert-Contains -Content $content -Pattern '(?s)auto-select.*Codex/ChatGPT.*Claude/Opus 4\.8 1M.*rank-85.*Copilot.*rank 80' -FailureMessage "$($source.Name) documents fallback auto-selection ranking"
}

if ($script:Failures -gt 0) {
    Write-Host "review-signoff live wiring tests: $script:Failures failure(s)" -ForegroundColor Red
    exit 1
}

Write-Host 'review-signoff live wiring tests: all passed' -ForegroundColor Green
exit 0
