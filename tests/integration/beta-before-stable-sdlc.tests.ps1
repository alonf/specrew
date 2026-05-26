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
        [Parameter(Mandatory = $true)][string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        Write-Fail "Missing SDLC surface: $Path"
    }

    $content = Get-Content -LiteralPath $Path -Raw -Encoding UTF8

    Assert-Match -Text $content -Pattern '(?is)AGENT NEXT ACTION:' -Message "$Label is missing AGENT NEXT ACTION ownership row."
    Assert-Match -Text $content -Pattern '(?is)HUMAN ACTION NEEDED:' -Message "$Label is missing HUMAN ACTION NEEDED ownership row."

    $stepChecks = @(
        @{ Step = 5;  Pattern = '(?is)Step\s+5\b.{0,240}push' },
        @{ Step = 6;  Pattern = '(?is)Step\s+6\b.{0,240}(gh\s+pr\s+create|open\s+a\s+PR|create\s+PR)' },
        @{ Step = 7;  Pattern = '(?is)Step\s+7\b.{0,280}(self-review|automated\s+PR\s+review|review)' },
        @{ Step = 8;  Pattern = '(?is)Step\s+8\b.{0,240}merge' },
        @{ Step = 9;  Pattern = '(?is)Step\s+9\b.{0,280}(beta\.1|-beta\.N|beta\s+tag|prerelease\s+tag)' },
        @{ Step = 10; Pattern = '(?is)Step\s+10\b.{0,320}(Find-Module|AllowPrerelease|verify.{0,80}prerelease|prerelease.{0,80}published)' },
        @{ Step = 11; Pattern = '(?is)Step\s+11\b.{0,360}(PASS|FAIL).{0,240}(Install-Module|AllowPrerelease|manual\s+test|clean\s+shell)' },
        @{ Step = 12; Pattern = '(?is)Step\s+12\b.{0,360}(FAIL|failed).{0,240}(beta\.2|beta\.N|repeat|loop)' },
        @{ Step = 13; Pattern = '(?is)Step\s+13\b.{0,360}(PASS|stable).{0,240}(stable|v<next-version>|publish)' },
        @{ Step = 14; Pattern = '(?is)Step\s+14\b.{0,240}(stop|new\s+feature)' }
    )

    $lastIndex = -1
    foreach ($check in $stepChecks) {
        $match = [regex]::Match($content, $check.Pattern)
        if (-not $match.Success) {
            Write-Fail ("{0} is missing feature-closeout SDLC Step {1}." -f $Label, $check.Step)
        }
        if ($match.Index -lt $lastIndex) {
            Write-Fail ("{0} feature-closeout SDLC Steps are out of order. Step {1} match index ({2}) is before previous step match index ({3})." -f $Label, $check.Step, $match.Index, $lastIndex)
        }
        $lastIndex = $match.Index
    }

    $humanSectionPattern = '(?is)HUMAN ACTION NEEDED:.{0,900}'
    Assert-Match -Text $content -Pattern '(?is)HUMAN ACTION NEEDED:.{0,900}(approve|approval)' -Message "$Label human row must ask for approval, not execution."
    Assert-Match -Text $content -Pattern '(?is)HUMAN ACTION NEEDED:.{0,900}(PASS|FAIL)' -Message "$Label human row must ask for the Step 11 PASS/FAIL verdict."
    Assert-Match -Text $content -Pattern '(?is)Step\s+13\b.{0,420}PASS-validated\s+commit' -Message "$Label Step 13 must tag the PASS-validated commit, not an earlier failed-beta commit."
    Assert-NotMatch -Text $content -Pattern '(?is)HUMAN ACTION NEEDED:.{0,900}push\s+the\s+branch,\s*open\s+a\s+PR,\s*address\s+automated\s+PR\s+review,\s*then\s+merge' -Message "$Label still assigns agent-owned push/PR/merge work to the human row."

    Write-Pass "$Label contains split agent/human ownership and Steps 5-14."
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
        Label = 'specrew-start coordinator prompt handoff block'
        Path  = Join-Path $repoRoot 'scripts\specrew-start.ps1'
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
    Assert-FeatureCloseoutSdlcSurface -Label $surface.Label -Path $surface.Path
}

Assert-ReleaseDisciplineDocumentation -Path (Join-Path $repoRoot 'docs\release-discipline.md')

Write-Host ''
Write-Host 'All beta-before-stable SDLC tests passed.' -ForegroundColor Green
