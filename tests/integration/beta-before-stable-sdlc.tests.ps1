[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass {
    param([string]$Message)
    Write-Host "PASS: $Message" -ForegroundColor Green
}

function Write-Fail {
    param([string]$Message)
    Write-Host "FAIL: $Message" -ForegroundColor Red
    throw $Message
}

function Assert-Match {
    param(
        [Parameter(Mandatory = $true)][string]$Text,
        [Parameter(Mandatory = $true)][string]$Pattern,
        [Parameter(Mandatory = $true)][string]$Message
    )

    if ($Text -notmatch $Pattern) {
        Write-Fail $Message
    }
}

function Assert-NotMatch {
    param(
        [Parameter(Mandatory = $true)][string]$Text,
        [Parameter(Mandatory = $true)][string]$Pattern,
        [Parameter(Mandatory = $true)][string]$Message
    )

    if ($Text -match $Pattern) {
        Write-Fail $Message
    }
}

function Assert-FeatureCloseoutSdlcSurface {
    param(
        [Parameter(Mandatory = $true)][string]$Label,
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $false)][string[]]$AdditionalPaths = @()
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        Write-Fail "Missing SDLC surface: $Path"
    }

    # F-174 iter-006 (T035) relocated Get-StartPrompt and its launch-contract prose out of
    # specrew-start.ps1 into scripts\internal\launch-contract.ps1, which specrew-start dot-sources
    # at runtime. The coordinator-prompt handoff contract is the combined content of both files, so
    # this assertion searches them together (matching boundary-authorization-prompt-truth.tests.ps1).
    $content = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
    foreach ($extraPath in $AdditionalPaths) {
        if (-not (Test-Path -LiteralPath $extraPath -PathType Leaf)) {
            Write-Fail "Missing SDLC surface companion: $extraPath"
        }
        $content += "`n" + (Get-Content -LiteralPath $extraPath -Raw -Encoding UTF8)
    }

    Assert-Match -Text $content -Pattern '(?is)AGENT NEXT ACTION:' -Message "$Label is missing AGENT NEXT ACTION ownership row."
    Assert-Match -Text $content -Pattern '(?is)HUMAN ACTION NEEDED:' -Message "$Label is missing HUMAN ACTION NEEDED ownership row."

    Assert-Match -Text $content -Pattern '(?is)(resolved release-model|resolved feature-closeout|recorded release model)' -Message "$Label does not route closeout through the resolved release model."
    Assert-Match -Text $content -Pattern '(?is)(N/A|non-N/A|applicable)' -Message "$Label does not preserve applicability or named N/A behavior."
    Assert-Match -Text $content -Pattern '(?is)beta-stable' -Message "$Label does not scope staged release teaching to beta-stable projects."
    Assert-NotMatch -Text $content -Pattern "(?is)Specrew's own instantiation|Find-Module\s+Specrew|Install-Module\s+Specrew|gh\s+pr\s+create" -Message "$Label still embeds Specrew-specific delivery instructions."

    Write-Pass "$Label delegates feature closeout to the resolved model with split ownership and applicability."
}

function Assert-ReleaseDisciplineDocumentation {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        Write-Fail "Missing release discipline documentation: $Path"
    }

    $content = Get-Content -LiteralPath $Path -Raw -Encoding UTF8

    $lastIndex = -1
    foreach ($step in 5..14) {
        $pattern = "(?is)Step\s+{0}\b" -f $step
        $match = [regex]::Match($content, $pattern)
        if (-not $match.Success) {
            Write-Fail "release-discipline.md is missing Step $step."
        }
        if ($match.Index -lt $lastIndex) {
            Write-Fail "release-discipline.md Steps are out of order. Step $step match index ($($match.Index)) is before previous step match index ($lastIndex)."
        }
        $lastIndex = $match.Index
    }

    $coverageChecks = @(
        @{
            Pattern = '(?is)(explicit\s+PASS|PASS\s+verdict).{0,240}(stable|publication|promotion)'
            Message = 'release-discipline.md must state that stable publication is blocked until an explicit PASS verdict.'
        },
        @{
            Pattern = '(?is)(proposal-only|proposal\s+only).{0,240}(exempt|no\s+beta|no\s+publish|does\s+not\s+publish)'
            Message = 'release-discipline.md must document proposal-only exemptions.'
        },
        @{
            Pattern = '(?is)(locked-main|protected\s+main).{0,320}(trailing|one-file).{0,240}PR'
            Message = 'release-discipline.md must document the locked-main trailing one-file PR audit path.'
        },
        @{
            Pattern = '(?is)release_audit_direct_to_main:\s*true'
            Message = 'release-discipline.md must document the direct-main opt-in flag.'
        },
        @{
            Pattern = '(?is)(Step\s+14|stop).{0,240}(before|without).{0,120}new\s+feature'
            Message = 'release-discipline.md must document stopping before new feature work.'
        },
        @{
            Pattern = '(?is)(FAIL|failed).{0,260}(beta\.2|beta\.N|repeat|loop)'
            Message = 'release-discipline.md must document the beta fail-loop.'
        },
        @{
            Pattern = '(?is)Step\s+9\b.{0,420}(PASS-candidate|looping|fix\s+commit)'
            Message = 'release-discipline.md must state that Step 9 tags the merge commit or the PASS-candidate fix commit.'
        },
        @{
            Pattern = '(?is)Step\s+13\b.{0,420}(passing\s+beta|PASS-validated\s+commit)'
            Message = 'release-discipline.md must state that stable tags the commit that produced the passing beta.'
        },
        @{
            Pattern = '(?is)Install-Module\s+Specrew.{0,160}AllowPrerelease'
            Message = 'release-discipline.md must include the prerelease install command.'
        },
        @{
            Pattern = '(?is)Find-Module\s+Specrew.{0,160}AllowPrerelease'
            Message = 'release-discipline.md must include prerelease package verification.'
        }
    )

    foreach ($check in $coverageChecks) {
        Assert-Match -Text $content -Pattern $check.Pattern -Message $check.Message
    }

    Write-Pass 'release-discipline.md covers Steps 5-14, PASS gating, exemptions, audit modes, and beta fail-loop.'
}

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path

$surfaces = @(
    @{
        Label           = 'specrew-start coordinator prompt handoff block'
        Path            = Join-Path $repoRoot 'scripts\specrew-start.ps1'
        AdditionalPaths = @(Join-Path $repoRoot 'scripts\internal\launch-contract.ps1')
    },
    @{
        Label = 'coordinator response guidance'
        Path  = Join-Path $repoRoot 'extensions\specrew-speckit\prompts\coordinator-response.md'
    },
    @{
        Label = 'source coordinator governance template'
        Path  = Join-Path $repoRoot 'extensions\specrew-speckit\squad-templates\coordinator\specrew-governance.md'
    },
    @{
        Label = 'deployed coordinator governance mirror'
        Path  = Join-Path $repoRoot '.specify\extensions\specrew-speckit\squad-templates\coordinator\specrew-governance.md'
    }
)

foreach ($surface in $surfaces) {
    $additional = if ($surface.ContainsKey('AdditionalPaths')) { $surface.AdditionalPaths } else { @() }
    Assert-FeatureCloseoutSdlcSurface -Label $surface.Label -Path $surface.Path -AdditionalPaths $additional
}

Assert-ReleaseDisciplineDocumentation -Path (Join-Path $repoRoot 'docs\release-discipline.md')

Write-Host ''
Write-Host 'All beta-before-stable SDLC tests passed.' -ForegroundColor Green
