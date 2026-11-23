# The Squad install command, built in one place.
#
# squad-cli 0.11.0 declares "@bradygaster/squad-sdk": "*", so an install of the CLI alone takes the newest SDK.
# squad-sdk 2.0.0 (published 2026-11-19) dropped exports the 0.11.0 CLI imports, and the CLI then fails at start.
# A global install uses the SDK named beside the CLI only when both are named in the same `npm install -g`, so every
# Squad install Specrew runs or prints names the paired SDK in that same command.
#
# The paired SDK version is `squad.sdk` in supported-versions.yml, next to the CLI version it was tested with
# (`squad.max_tested`). It is named only for that CLI version: any other CLI version installs the CLI alone and gets
# whatever SDK it resolves. Remove `squad.sdk`, and the pairing below with it, when Specrew moves to a squad release
# whose CLI and SDK agree.
#
# validate-versions.ps1 prints the same command from its -SquadSdkVersion parameter, because it is also deployed into
# projects and cannot load this file. tests/unit/squad-install-pair.tests.ps1 holds the two texts equal.

Set-StrictMode -Version Latest

function Get-SquadSdkPin {
    # The paired versions from supported-versions.yml: CliVersion (squad.max_tested) and SdkVersion (squad.sdk).
    # $null when the file, the squad section or either key is absent.
    param(
        [string]$Path = (Join-Path $PSScriptRoot 'supported-versions.yml')
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return $null
    }

    $inSquad = $false
    $cli = $null
    $sdk = $null
    foreach ($line in (Get-Content -LiteralPath $Path -Encoding UTF8)) {
        if ($line -match '^\s*(?:#.*)?$') { continue }
        if ($line -match '^(?<section>[A-Za-z_][A-Za-z0-9_]*):') {
            $inSquad = ($Matches['section'] -ceq 'squad')
            continue
        }
        if ($inSquad -and ($line -match '^\s+(?<key>max_tested|sdk):\s*"?(?<value>[^"#\r\n]*?)"?\s*(?:#.*)?$')) {
            if ($Matches['key'] -ceq 'max_tested') { $cli = $Matches['value'].Trim() } else { $sdk = $Matches['value'].Trim() }
        }
    }

    if ([string]::IsNullOrWhiteSpace($cli) -or [string]::IsNullOrWhiteSpace($sdk)) {
        return $null
    }

    return [pscustomobject]@{ CliVersion = $cli; SdkVersion = $sdk }
}

function Get-SquadSdkVersionFor {
    # The SDK version to name beside the given CLI version, or $null to install the CLI alone.
    param(
        [Parameter(Mandatory = $true)]
        [string]$CliVersion,

        [string]$Path = (Join-Path $PSScriptRoot 'supported-versions.yml')
    )

    $pin = Get-SquadSdkPin -Path $Path
    if ($null -eq $pin) {
        return $null
    }

    if ($CliVersion.Trim().TrimStart('v', 'V') -cne $pin.CliVersion.TrimStart('v', 'V')) {
        return $null
    }

    return $pin.SdkVersion
}

function Get-SquadInstallArguments {
    # npm arguments for the Squad install: the CLI, and the paired SDK when one is given.
    param(
        [Parameter(Mandatory = $true)]
        [string]$CliVersion,

        [AllowNull()]
        [AllowEmptyString()]
        [string]$SdkVersion
    )

    $arguments = @('install', '-g', ('@bradygaster/squad-cli@{0}' -f $CliVersion))
    if (-not [string]::IsNullOrWhiteSpace($SdkVersion)) {
        $arguments += ('@bradygaster/squad-sdk@{0}' -f $SdkVersion)
    }

    return $arguments
}

function Get-SquadInstallCommandText {
    # The same install as a command line a person can run.
    param(
        [Parameter(Mandatory = $true)]
        [string]$CliVersion,

        [AllowNull()]
        [AllowEmptyString()]
        [string]$SdkVersion
    )

    $text = 'npm install -g "@bradygaster/squad-cli@{0}"' -f $CliVersion
    if (-not [string]::IsNullOrWhiteSpace($SdkVersion)) {
        $text += ' "@bradygaster/squad-sdk@{0}"' -f $SdkVersion
    }

    return $text
}
