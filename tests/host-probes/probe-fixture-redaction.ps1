# Feature 202 iteration 003, review round 2: the recorded probe fixtures ship in the repository, and the payload values
# the hosts send carry the user's profile path (cwd, transcript paths, Claude's dash-encoded project folder). The
# probe keeps every other byte of a payload; only the user name inside a profile path is replaced, with 'probe-user'.
# Dot-sourced by host-payload-capture-probe.ps1 (when it writes fixtures) and by the suites that check the fixtures.

$script:ProbeFixtureUserPlaceholder = 'probe-user'

function ConvertTo-ProbeRedactedFixtureText {
    # The payload text with the user name in every profile path replaced: C:\Users\<name> in its JSON-escaped, plain
    # and forward-slash forms, and C--Users-<name>- as Claude encodes a project folder. -UserName is the account the
    # capture ran under; the separator forms are replaced for any account name, the dash form only for that one,
    # because a dash cannot tell where a name ends.
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Text, [string]$UserName = [Environment]::UserName)
    $placeholder = $script:ProbeFixtureUserPlaceholder
    $redacted = [regex]::Replace($Text, '(?i)(\b[A-Za-z]:(?:\\\\|\\|/)Users(?:\\\\|\\|/))(?!' + $placeholder + '(?:\\|/|"|$))[^\\/"]+', ('$1' + $placeholder))
    if (-not [string]::IsNullOrWhiteSpace($UserName)) {
        $redacted = [regex]::Replace($redacted, '(?i)(\b[A-Za-z]--Users-)' + [regex]::Escape($UserName) + '(?=-)', ('$1' + $placeholder))
    }
    return $redacted
}

function Test-ProbeFixtureTextHasUserPath {
    # $true when the text still names a user profile other than the placeholder.
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Text, [string]$UserName = [Environment]::UserName)
    $placeholder = $script:ProbeFixtureUserPlaceholder
    if ($Text -match ('(?i)\b[A-Za-z]:(?:\\\\|\\|/)Users(?:\\\\|\\|/)(?!' + $placeholder + '(?:\\|/|"|$))[^\\/"]+')) { return $true }
    if (-not [string]::IsNullOrWhiteSpace($UserName) -and $Text -match ('(?i)\b[A-Za-z]--Users-' + [regex]::Escape($UserName) + '-')) { return $true }
    return $false
}
