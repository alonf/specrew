# ONE TIMESTAMP READER, because three sites were bitten by the same thing in one batch.
#
# ConvertFrom-Json coerces an ISO-8601 string into a [datetime] on the way back. Every site that then did
# something reasonable-looking with the result was wrong in a different way:
#
#   1. the design-decision record's read-back verify checked `recorded_at -is [string]` and failed on a
#      record the script had just written;
#   2. the turn-token listing re-parsed the coerced value through a string, lost the sub-second part, and
#      two tokens issued 30 ms apart compared EQUAL - the (since retired) newest-wins sort went arbitrary;
#   3. the in-flight render cooldown cast the coerced [datetime] to a string, which dropped the UTC
#      designator and the fraction, then parsed it as LOCAL time - a render 0.5 s old read as ~3 hours old
#      on this machine's zone and the cooldown was bypassed.
#
# Three instances is a pattern, and the pattern is "a type surviving JSON". So every timestamp field is read
# through this one function, which accepts whatever JSON handed back - a string, a [datetime], a
# [DateTimeOffset], or a unix-millisecond number - and returns a UTC [DateTimeOffset] or $null. It never
# goes through a string it did not receive as a string, and it never assumes local time.

function ConvertTo-SpecrewUtcTimestamp {
    [OutputType([Nullable[DateTimeOffset]])]
    param([AllowNull()]$Value)

    if ($null -eq $Value) { return $null }
    try {
        if ($Value -is [DateTimeOffset]) { return ([DateTimeOffset]$Value).ToUniversalTime() }
        if ($Value -is [datetime]) {
            # The JSON coercion hands back Kind Local for a string carrying a designator (already shifted to this
            # machine's zone - the cast to [DateTimeOffset] below undoes that correctly) and Kind Unspecified for
            # a bare one. Treating Unspecified as local is the site-3 mistake: nothing here was written in a
            # local zone, so a bare stamp is UTC.
            $dt = [datetime]$Value
            if ($dt.Kind -eq [DateTimeKind]::Unspecified) { $dt = [DateTime]::SpecifyKind($dt, [DateTimeKind]::Utc) }
            return ([DateTimeOffset]$dt).ToUniversalTime()
        }
        if ($Value -is [long] -or $Value -is [int] -or $Value -is [double] -or $Value -is [decimal]) {
            # Unix milliseconds. A number cannot be coerced into something else by JSON, which is why the
            # ordering and cooldown fields are written as numbers alongside their ISO strings.
            return [DateTimeOffset]::FromUnixTimeMilliseconds([long]$Value)
        }
        $text = ([string]$Value).Trim()
        if ([string]::IsNullOrWhiteSpace($text)) { return $null }
        if ($text -match '^\d{10,}$') { return [DateTimeOffset]::FromUnixTimeMilliseconds([long]$text) }
        # Invariant culture, and AssumeUniversal for a string that carries no designator: nothing here was
        # ever written in a local zone, so a bare timestamp is UTC, not "wherever this machine is".
        return [DateTimeOffset]::Parse($text, [System.Globalization.CultureInfo]::InvariantCulture,
            ([System.Globalization.DateTimeStyles]::AssumeUniversal -bor [System.Globalization.DateTimeStyles]::AdjustToUniversal))
    }
    catch { return $null }
}

function Get-SpecrewUtcNowMilliseconds {
    # The write-side twin: the number a timestamp field carries beside its ISO string, so the read side
    # never has to depend on a type surviving JSON.
    [OutputType([long])]
    param()
    return [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
}
