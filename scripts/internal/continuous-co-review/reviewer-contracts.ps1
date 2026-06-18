$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Get-ContinuousCoReviewContractRoot {
    param(
        [string] $SchemaRoot
    )

    if ($SchemaRoot) {
        return (Resolve-Path -LiteralPath $SchemaRoot).Path
    }

    $repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../../..')).Path
    return (Join-Path $repoRoot 'specs/197-continuous-co-review/contracts')
}

function Get-ReviewerContractNames {
    return @(
        'ReviewRequest'
        'FindingsResult'
        'ReviewThread'
        'GateVerdict'
        'InfrastructureFailure'
        'SpawnInvocation'
    )
}

function Get-ReviewerContractFileName {
    param(
        [Parameter(Mandatory)]
        [string] $ContractName
    )

    switch ($ContractName.ToLowerInvariant()) {
        'reviewrequest' { return 'review-request.schema.json' }
        'review-request' { return 'review-request.schema.json' }
        'findingsresult' { return 'findings-result.schema.json' }
        'findings-result' { return 'findings-result.schema.json' }
        'reviewthread' { return 'review-thread.schema.json' }
        'review-thread' { return 'review-thread.schema.json' }
        'gateverdict' { return 'gate-verdict.schema.json' }
        'gate-verdict' { return 'gate-verdict.schema.json' }
        'infrastructurefailure' { return 'infrastructure-failure.schema.json' }
        'infrastructure-failure' { return 'infrastructure-failure.schema.json' }
        'spawninvocation' { return 'spawn-invocation.schema.json' }
        'spawn-invocation' { return 'spawn-invocation.schema.json' }
        default { throw "Unknown reviewer contract '$ContractName'." }
    }
}

function Get-ReviewerContractSchemaPath {
    param(
        [Parameter(Mandatory)]
        [string] $ContractName,

        [string] $SchemaRoot
    )

    $root = Get-ContinuousCoReviewContractRoot -SchemaRoot $SchemaRoot
    return (Join-Path $root (Get-ReviewerContractFileName -ContractName $ContractName))
}

function Get-ReviewerContractSchema {
    param(
        [Parameter(Mandatory)]
        [string] $ContractName,

        [string] $SchemaRoot
    )

    $schemaPath = Get-ReviewerContractSchemaPath -ContractName $ContractName -SchemaRoot $SchemaRoot
    if (-not (Test-Path -LiteralPath $schemaPath -PathType Leaf)) {
        throw "Reviewer contract schema not found: $schemaPath"
    }

    return (Get-Content -LiteralPath $schemaPath -Raw | ConvertFrom-Json -Depth 100)
}

function ConvertFrom-ReviewerContractJson {
    param(
        [Parameter(Mandatory)]
        [string] $Json
    )

    try {
        return ($Json | ConvertFrom-Json -Depth 100)
    }
    catch {
        throw "Invalid reviewer contract JSON: $($_.Exception.Message)"
    }
}

function Read-ReviewerContractJson {
    param(
        [Parameter(Mandatory)]
        [string] $Path
    )

    return ConvertFrom-ReviewerContractJson -Json (Get-Content -LiteralPath $Path -Raw)
}

function Test-ReviewerContractValueType {
    param(
        [AllowNull()]
        $Value,

        [Parameter(Mandatory)]
        [object] $ExpectedType
    )

    $expectedTypes = @($ExpectedType)
    foreach ($expected in $expectedTypes) {
        switch ($expected) {
            'null' {
                if ($null -eq $Value) { return $true }
            }
            'string' {
                if (($Value -is [string]) -or ($Value -is [datetime])) { return $true }
            }
            'integer' {
                if (($Value -is [byte] -or $Value -is [int16] -or $Value -is [int] -or $Value -is [long]) -and $Value -isnot [bool]) { return $true }
            }
            'boolean' {
                if ($Value -is [bool]) { return $true }
            }
            'object' {
                if (($null -ne $Value) -and (($Value -is [System.Collections.IDictionary]) -or ($Value -is [pscustomobject]))) { return $true }
            }
            'array' {
                if (($Value -is [System.Collections.IEnumerable]) -and ($Value -isnot [string]) -and ($Value -isnot [System.Collections.IDictionary]) -and ($Value -isnot [pscustomobject])) { return $true }
            }
            default {
                throw "Unsupported JSON schema type '$expected'."
            }
        }
    }

    return $false
}

function Get-ReviewerContractPropertyNames {
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        $Object
    )

    if ($Object -is [System.Collections.IDictionary]) {
        return @($Object.Keys)
    }

    return @($Object.PSObject.Properties.Name)
}

function Test-ReviewerContractPropertyExists {
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        $Object,

        [Parameter(Mandatory)]
        [string] $Name
    )

    return ((Get-ReviewerContractPropertyNames -Object $Object) -contains $Name)
}

function Get-ReviewerContractPropertyValue {
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        $Object,

        [Parameter(Mandatory)]
        [string] $Name
    )

    if ($Object -is [System.Collections.IDictionary]) {
        return $Object[$Name]
    }

    return $Object.PSObject.Properties[$Name].Value
}

function Test-ReviewerContractSchemaNode {
    param(
        [AllowNull()]
        $Value,

        [Parameter(Mandatory)]
        $Schema,

        [Parameter(Mandatory)]
        [string] $Path,

        [System.Collections.Generic.List[string]] $Errors
    )

    if ($Schema.PSObject.Properties.Name -contains 'type') {
        if (-not (Test-ReviewerContractValueType -Value $Value -ExpectedType $Schema.type)) {
            $Errors.Add("$Path has the wrong JSON type.")
            return
        }
    }

    if ($Schema.PSObject.Properties.Name -contains 'const') {
        if ($Value -ne $Schema.const) {
            $Errors.Add("$Path must equal '$($Schema.const)'.")
        }
    }

    if ($Schema.PSObject.Properties.Name -contains 'enum') {
        if (@($Schema.enum) -notcontains $Value) {
            $Errors.Add("$Path has value '$Value' outside the allowed enum.")
        }
    }

    if (($null -ne $Value) -and ($Value -is [string]) -and ($Schema.PSObject.Properties.Name -contains 'minLength')) {
        if ($Value.Length -lt [int] $Schema.minLength) {
            $Errors.Add("$Path is shorter than minLength $($Schema.minLength).")
        }
    }

    if (($null -ne $Value) -and ($Value -isnot [string]) -and ($Schema.PSObject.Properties.Name -contains 'minimum')) {
        if ($Value -lt $Schema.minimum) {
            $Errors.Add("$Path is below minimum $($Schema.minimum).")
        }
    }

    if (($null -ne $Value) -and ($Value -isnot [string]) -and ($Schema.PSObject.Properties.Name -contains 'maximum')) {
        if ($Value -gt $Schema.maximum) {
            $Errors.Add("$Path is above maximum $($Schema.maximum).")
        }
    }

    if (($Schema.PSObject.Properties.Name -contains 'type') -and (@($Schema.type) -contains 'object') -and ($null -ne $Value)) {
        $schemaPropertyNames = @()
        if ($Schema.PSObject.Properties.Name -contains 'properties') {
            $schemaPropertyNames = @($Schema.properties.PSObject.Properties.Name)
        }

        if (($Schema.PSObject.Properties.Name -contains 'additionalProperties') -and ($Schema.additionalProperties -eq $false)) {
            foreach ($actualProperty in (Get-ReviewerContractPropertyNames -Object $Value)) {
                if ($schemaPropertyNames -notcontains $actualProperty) {
                    $Errors.Add("$Path.$actualProperty is not an allowed property.")
                }
            }
        }

        if ($Schema.PSObject.Properties.Name -contains 'required') {
            foreach ($requiredProperty in @($Schema.required)) {
                if (-not (Test-ReviewerContractPropertyExists -Object $Value -Name $requiredProperty)) {
                    $Errors.Add("$Path.$requiredProperty is required.")
                }
            }
        }

        foreach ($schemaPropertyName in $schemaPropertyNames) {
            if (Test-ReviewerContractPropertyExists -Object $Value -Name $schemaPropertyName) {
                if ($Value -is [System.Collections.IDictionary]) {
                    $propertyValue = $Value[$schemaPropertyName]
                }
                else {
                    $propertyValue = $Value.PSObject.Properties[$schemaPropertyName].Value
                }
                $propertySchema = $Schema.properties.PSObject.Properties[$schemaPropertyName].Value
                if (($propertySchema.PSObject.Properties.Name -contains 'type') -and (@($propertySchema.type) -contains 'array')) {
                    $isJsonArray = (($propertyValue -is [System.Collections.IEnumerable]) -and
                        ($propertyValue -isnot [string]) -and
                        ($propertyValue -isnot [System.Collections.IDictionary]) -and
                        ($propertyValue -isnot [pscustomobject]))
                    if (-not $isJsonArray) {
                        $Errors.Add("$Path.$schemaPropertyName has the wrong JSON type.")
                        continue
                    }

                    Test-ReviewerContractSchemaNode -Value (, $propertyValue) -Schema $propertySchema -Path "$Path.$schemaPropertyName" -Errors $Errors
                }
                else {
                    Test-ReviewerContractSchemaNode -Value $propertyValue -Schema $propertySchema -Path "$Path.$schemaPropertyName" -Errors $Errors
                }
            }
        }
    }

    if (($Schema.PSObject.Properties.Name -contains 'type') -and (@($Schema.type) -contains 'array') -and ($null -ne $Value)) {
        $valueItems = @($Value)
        if (($valueItems.Count -eq 1) -and ($valueItems[0] -is [array])) {
            $items = @($valueItems[0])
        }
        else {
            $items = @($valueItems)
        }
        if (($Schema.PSObject.Properties.Name -contains 'minItems') -and ($items.Count -lt [int] $Schema.minItems)) {
            $Errors.Add("$Path has fewer items than minItems $($Schema.minItems).")
        }

        if ($Schema.PSObject.Properties.Name -contains 'items') {
            for ($index = 0; $index -lt $items.Count; $index++) {
                Test-ReviewerContractSchemaNode -Value $items[$index] -Schema $Schema.items -Path "$Path[$index]" -Errors $Errors
            }
        }
    }
}

function Test-ReviewerContractSchemaVersion {
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        $InputObject,

        [System.Collections.Generic.List[string]] $Errors,

        [string] $ContractName
    )

    if (-not (Test-ReviewerContractPropertyExists -Object $InputObject -Name 'schema_version')) {
        return
    }

    $schemaVersion = if ($InputObject -is [System.Collections.IDictionary]) {
        $InputObject['schema_version']
    }
    else {
        $InputObject.PSObject.Properties['schema_version'].Value
    }
    if ($schemaVersion -isnot [string]) {
        $Errors.Add('$.schema_version must be a string.')
        return
    }

    $major = ($schemaVersion -split '\.')[0]
    $allowedMajors = if ($ContractName -eq 'ReviewRequest') { @('1', '2') } else { @('1') }
    if ($allowedMajors -notcontains $major) {
        $Errors.Add("Unknown schema major version '$major'.")
    }
}

function Test-ReviewerContractObject {
    param(
        [Parameter(Mandatory)]
        [string] $ContractName,

        [Parameter(Mandatory)]
        [AllowNull()]
        $InputObject,

        [string] $SchemaRoot
    )

    $errors = [System.Collections.Generic.List[string]]::new()
    $schema = Get-ReviewerContractSchema -ContractName $ContractName -SchemaRoot $SchemaRoot

    Test-ReviewerContractSchemaVersion -InputObject $InputObject -Errors $errors -ContractName $ContractName
    Test-ReviewerContractSchemaNode -Value $InputObject -Schema $schema -Path '$' -Errors $errors

    return [pscustomobject]@{
        Valid  = ($errors.Count -eq 0)
        Errors = @($errors)
    }
}

function Test-ReviewerContractJson {
    param(
        [Parameter(Mandatory)]
        [string] $ContractName,

        [Parameter(Mandatory)]
        [string] $Json,

        [string] $SchemaRoot
    )

    try {
        $inputObject = ConvertFrom-ReviewerContractJson -Json $Json
    }
    catch {
        return [pscustomobject]@{
            Valid  = $false
            Errors = @($_.Exception.Message)
        }
    }

    return Test-ReviewerContractObject -ContractName $ContractName -InputObject $inputObject -SchemaRoot $SchemaRoot
}

function Assert-ReviewerContractObject {
    param(
        [Parameter(Mandatory)]
        [string] $ContractName,

        [Parameter(Mandatory)]
        [AllowNull()]
        $InputObject,

        [string] $SchemaRoot
    )

    $result = Test-ReviewerContractObject -ContractName $ContractName -InputObject $InputObject -SchemaRoot $SchemaRoot
    if (-not $result.Valid) {
        throw "Reviewer contract '$ContractName' failed validation: $($result.Errors -join '; ')"
    }

    return $InputObject
}

function Get-ReviewerContractSha256Hex {
    param(
        [Parameter(Mandatory)]
        [string] $Text
    )

    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
    $hashBytes = [System.Security.Cryptography.SHA256]::HashData($bytes)
    return ([System.BitConverter]::ToString($hashBytes) -replace '-', '').ToLowerInvariant()
}

function ConvertTo-ReviewerContractCanonicalJson {
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        $InputObject
    )

    return ($InputObject | ConvertTo-Json -Depth 100 -Compress)
}

function ConvertTo-ReviewerContractText {
    param(
        [AllowNull()]
        $Value
    )

    if ($null -eq $Value) {
        return $null
    }

    return ([string] $Value).Trim()
}

function Get-ReviewerFindingDispositionValues {
    return @(
        'open'
        'accepted_fix_pending'
        'resolved'
        'rejected_with_rationale'
        'escalated_to_human'
    )
}

function Get-ReviewerFindingValidDispositionValues {
    return Get-ReviewerFindingDispositionValues
}

function Test-ReviewerFindingDispositionValue {
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string] $Disposition
    )

    return ((Get-ReviewerFindingDispositionValues) -contains $Disposition)
}

function Test-ReviewerFindingDisposition {
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string] $Disposition
    )

    return Test-ReviewerFindingDispositionValue -Disposition $Disposition
}

function Get-ReviewerFindingResolutionStateValues {
    return @(
        'unresolved'
        'resolved'
        'rejected'
        'escalated'
    )
}

function Get-ReviewerFindingValidResolutionStateValues {
    return Get-ReviewerFindingResolutionStateValues
}

function Test-ReviewerFindingResolutionStateValue {
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string] $State
    )

    return ((Get-ReviewerFindingResolutionStateValues) -contains $State)
}

function Test-ReviewerFindingResolutionState {
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string] $State
    )

    return Test-ReviewerFindingResolutionStateValue -State $State
}

function Get-ReviewerFindingLocationFingerprintFields {
    param(
        [AllowNull()]
        $Location
    )

    $path = $null
    $lineStart = $null
    $lineEnd = $null
    if ($null -ne $Location) {
        if (Test-ReviewerContractPropertyExists -Object $Location -Name 'path') {
            $path = ConvertTo-ReviewerContractText -Value (Get-ReviewerContractPropertyValue -Object $Location -Name 'path')
            if ($null -ne $path) {
                $path = ($path -replace '\\', '/').ToLowerInvariant()
            }
        }
        if (Test-ReviewerContractPropertyExists -Object $Location -Name 'line_start') {
            $lineStart = Get-ReviewerContractPropertyValue -Object $Location -Name 'line_start'
        }
        if (Test-ReviewerContractPropertyExists -Object $Location -Name 'line_end') {
            $lineEnd = Get-ReviewerContractPropertyValue -Object $Location -Name 'line_end'
        }
    }

    return [ordered]@{
        path       = $path
        line_start = $lineStart
        line_end   = $lineEnd
    }
}

function New-ReviewerFindingFingerprint {
    param(
        [AllowNull()]
        $Finding,

        [AllowNull()]
        $Location,

        [AllowNull()]
        [string] $Severity,

        [AllowNull()]
        [string] $Kind,

        [AllowNull()]
        [string] $DesignReference,

        [AllowNull()]
        [string] $Comment
    )

    if ($null -ne $Finding) {
        if (Test-ReviewerContractPropertyExists -Object $Finding -Name 'location') {
            $Location = Get-ReviewerContractPropertyValue -Object $Finding -Name 'location'
        }
        if (Test-ReviewerContractPropertyExists -Object $Finding -Name 'severity') {
            $Severity = Get-ReviewerContractPropertyValue -Object $Finding -Name 'severity'
        }
        if (Test-ReviewerContractPropertyExists -Object $Finding -Name 'kind') {
            $Kind = Get-ReviewerContractPropertyValue -Object $Finding -Name 'kind'
        }
        if (Test-ReviewerContractPropertyExists -Object $Finding -Name 'design_reference') {
            $DesignReference = Get-ReviewerContractPropertyValue -Object $Finding -Name 'design_reference'
        }
        if (Test-ReviewerContractPropertyExists -Object $Finding -Name 'comment') {
            $Comment = Get-ReviewerContractPropertyValue -Object $Finding -Name 'comment'
        }
    }

    $fingerprintFields = [ordered]@{
        location         = Get-ReviewerFindingLocationFingerprintFields -Location $Location
        severity         = ConvertTo-ReviewerContractText -Value $Severity
        kind             = ConvertTo-ReviewerContractText -Value $Kind
        design_reference = ConvertTo-ReviewerContractText -Value $DesignReference
        comment          = ConvertTo-ReviewerContractText -Value $Comment
    }
    $canonicalJson = ConvertTo-ReviewerContractCanonicalJson -InputObject $fingerprintFields
    return "sha256:$(Get-ReviewerContractSha256Hex -Text $canonicalJson)"
}

function Get-ReviewerFindingFingerprint {
    param(
        [AllowNull()]
        $Finding,

        [AllowNull()]
        $Location,

        [AllowNull()]
        [string] $Severity,

        [AllowNull()]
        [string] $Kind,

        [AllowNull()]
        [string] $DesignReference,

        [AllowNull()]
        [string] $Comment
    )

    return New-ReviewerFindingFingerprint -Finding $Finding -Location $Location -Severity $Severity -Kind $Kind -DesignReference $DesignReference -Comment $Comment
}

function Get-ReviewerInfrastructureFailureCategoryValues {
    return @(
        'missing-provider'
        'unauthorized-provider'
        'unavailable-requested-model'
        'timeout'
        'nonzero-exit'
        'empty-stdout'
        'invalid-json'
        'schema-mismatch'
        'command-invocation-failure'
        'malformed-durable-state'
        'fallback-exhausted'
        'cleanup-failed'
    )
}

function Test-ReviewerInfrastructureFailureCategory {
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string] $Category
    )

    return ((Get-ReviewerInfrastructureFailureCategoryValues) -contains $Category)
}

function Test-ReviewerInfrastructureSafeDetailName {
    param(
        [Parameter(Mandatory)]
        [string] $Name
    )

    $unsafeNamePattern = '(?i)(stdout|stderr|std[_-]?out|std[_-]?err|prompt|transcript|env|environment|token|secret|password|credential|api[_-]?key|private[_-]?key|machine|hostname|computername|userprofile|home|path|pwd|cwd|working[_-]?directory)'
    return ($Name -notmatch $unsafeNamePattern)
}

function ConvertTo-ReviewerInfrastructureSafeString {
    param(
        [AllowNull()]
        [string] $Value
    )

    if ($null -eq $Value) {
        return $null
    }

    $secretValuePatterns = @(
        '(?i)\bbearer\s+[a-z0-9._~+/=-]+'
        '(?i)\b(token|secret|password|credential|api[_-]?key)\s*[:=]\s*\S+'
        '\bghp_[A-Za-z0-9_]{20,}\b'
        '\bgithub_pat_[A-Za-z0-9_]{20,}\b'
        '\bsk-[A-Za-z0-9]{20,}\b'
    )
    foreach ($pattern in $secretValuePatterns) {
        if ($Value -match $pattern) {
            return '[redacted]'
        }
    }

    return $Value
}

function ConvertTo-ReviewerInfrastructureSafeDetailValue {
    param(
        [AllowNull()]
        $Value
    )

    if ($null -eq $Value) {
        return $null
    }

    if ($Value -is [string]) {
        return ConvertTo-ReviewerInfrastructureSafeString -Value $Value
    }

    if (($Value -is [bool]) -or ($Value -is [byte]) -or ($Value -is [int16]) -or ($Value -is [int]) -or ($Value -is [long]) -or ($Value -is [decimal]) -or ($Value -is [double])) {
        return $Value
    }

    if (($Value -is [System.Collections.IEnumerable]) -and ($Value -isnot [string]) -and ($Value -isnot [System.Collections.IDictionary]) -and ($Value -isnot [pscustomobject])) {
        return @($Value | ForEach-Object { ConvertTo-ReviewerInfrastructureSafeDetailValue -Value $_ })
    }

    if (($Value -is [System.Collections.IDictionary]) -or ($Value -is [pscustomobject])) {
        return ConvertTo-ReviewerInfrastructureSafeDetails -SafeDetails $Value
    }

    return (ConvertTo-ReviewerInfrastructureSafeString -Value ([string] $Value))
}

function ConvertTo-ReviewerInfrastructureSafeDetails {
    param(
        [AllowNull()]
        $SafeDetails
    )

    $details = [ordered]@{}
    if ($null -eq $SafeDetails) {
        return [pscustomobject] $details
    }

    foreach ($propertyName in (Get-ReviewerContractPropertyNames -Object $SafeDetails)) {
        if (-not (Test-ReviewerInfrastructureSafeDetailName -Name $propertyName)) {
            continue
        }

        $details[$propertyName] = ConvertTo-ReviewerInfrastructureSafeDetailValue -Value (Get-ReviewerContractPropertyValue -Object $SafeDetails -Name $propertyName)
    }

    return [pscustomobject] $details
}

function Get-ReviewerInfrastructureFailureDefaultRetryable {
    param(
        [Parameter(Mandatory)]
        [string] $Category
    )

    return (@(
            'missing-provider'
            'timeout'
            'nonzero-exit'
            'empty-stdout'
            'invalid-json'
            'command-invocation-failure'
        ) -contains $Category)
}

function Get-ReviewerInfrastructureFailureDefaultFallbackAllowed {
    param(
        [Parameter(Mandatory)]
        [string] $Category
    )

    return (@(
            'missing-provider'
            'timeout'
            'nonzero-exit'
            'empty-stdout'
            'invalid-json'
            'command-invocation-failure'
            'unavailable-requested-model'
        ) -contains $Category)
}

function New-ReviewerInfrastructureFailureId {
    param(
        [Parameter(Mandatory)]
        [string] $RunId,

        [AllowNull()]
        [string] $InvocationId,

        [Parameter(Mandatory)]
        [string] $Category,

        [Parameter(Mandatory)]
        [string] $Message
    )

    $idFields = [ordered]@{
        run_id        = $RunId
        invocation_id = $InvocationId
        category      = $Category
        message       = $Message
    }
    $hash = Get-ReviewerContractSha256Hex -Text (ConvertTo-ReviewerContractCanonicalJson -InputObject $idFields)
    return "failure-$($hash.Substring(0, 16))"
}

function New-ReviewerInfrastructureFailure {
    param(
        [Parameter(Mandatory)]
        [string] $RunId,

        [Parameter(Mandatory)]
        [string] $Category,

        [Parameter(Mandatory)]
        [string] $Message,

        [AllowNull()]
        [string] $InvocationId,

        [AllowNull()]
        [string] $FailureId,

        [AllowNull()]
        $SafeDetails,

        [AllowNull()]
        [System.Nullable[bool]] $Retryable,

        [AllowNull()]
        [System.Nullable[bool]] $FallbackAllowed,

        [datetime] $CreatedAt = [datetime]::MinValue
    )

    if (-not (Test-ReviewerInfrastructureFailureCategory -Category $Category)) {
        throw "Unknown infrastructure failure category '$Category'."
    }

    $safeMessage = ConvertTo-ReviewerInfrastructureSafeString -Value $Message
    $resolvedInvocationId = if ([string]::IsNullOrWhiteSpace($InvocationId)) {
        $null
    }
    else {
        $InvocationId
    }
    $resolvedCreatedAt = if ($CreatedAt -eq [datetime]::MinValue) {
        [datetime]::UtcNow
    }
    else {
        $CreatedAt.ToUniversalTime()
    }
    $resolvedRetryable = if ($PSBoundParameters.ContainsKey('Retryable')) {
        [bool] $Retryable
    }
    else {
        Get-ReviewerInfrastructureFailureDefaultRetryable -Category $Category
    }
    $resolvedFallbackAllowed = if ($PSBoundParameters.ContainsKey('FallbackAllowed')) {
        [bool] $FallbackAllowed
    }
    else {
        Get-ReviewerInfrastructureFailureDefaultFallbackAllowed -Category $Category
    }
    $resolvedFailureId = if ([string]::IsNullOrWhiteSpace($FailureId)) {
        New-ReviewerInfrastructureFailureId -RunId $RunId -InvocationId $resolvedInvocationId -Category $Category -Message $safeMessage
    }
    else {
        $FailureId
    }

    $failure = [ordered]@{
        schema_version   = '1.0'
        failure_id       = $resolvedFailureId
        run_id           = $RunId
        invocation_id    = $resolvedInvocationId
        category         = $Category
        message          = $safeMessage
        safe_details     = ConvertTo-ReviewerInfrastructureSafeDetails -SafeDetails $SafeDetails
        retryable        = $resolvedRetryable
        fallback_allowed = $resolvedFallbackAllowed
        created_at       = $resolvedCreatedAt.ToString('yyyy-MM-ddTHH:mm:ssZ', [System.Globalization.CultureInfo]::InvariantCulture)
    }

    return [pscustomobject] $failure
}

function New-ReviewerContractInfrastructureFailure {
    param(
        [Parameter(Mandatory)]
        [string] $RunId,

        [Parameter(Mandatory)]
        [string] $Category,

        [Parameter(Mandatory)]
        [string] $Message,

        [AllowNull()]
        [string] $InvocationId,

        [AllowNull()]
        [string] $FailureId,

        [AllowNull()]
        $SafeDetails,

        [AllowNull()]
        [System.Nullable[bool]] $Retryable,

        [AllowNull()]
        [System.Nullable[bool]] $FallbackAllowed,

        [datetime] $CreatedAt = [datetime]::MinValue
    )

    $parameters = @{
        RunId    = $RunId
        Category = $Category
        Message  = $Message
    }
    foreach ($optionalName in @('InvocationId', 'FailureId', 'SafeDetails', 'Retryable', 'FallbackAllowed', 'CreatedAt')) {
        if ($PSBoundParameters.ContainsKey($optionalName)) {
            $parameters[$optionalName] = $PSBoundParameters[$optionalName]
        }
    }

    return New-ReviewerInfrastructureFailure @parameters
}

function Get-ContinuousCoReviewFindingDispositionValues {
    return Get-ReviewerFindingDispositionValues
}

function Get-ContinuousCoReviewFindingResolutionStates {
    return Get-ReviewerFindingResolutionStateValues
}

function New-ContinuousCoReviewFindingFingerprint {
    param(
        [AllowNull()]
        $Finding,

        [AllowNull()]
        $Location,

        [AllowNull()]
        [string] $Severity,

        [AllowNull()]
        [string] $Kind,

        [AllowNull()]
        [string] $DesignReference,

        [AllowNull()]
        [string] $Comment
    )

    return New-ReviewerFindingFingerprint -Finding $Finding -Location $Location -Severity $Severity -Kind $Kind -DesignReference $DesignReference -Comment $Comment
}

function New-ContinuousCoReviewInfrastructureFailure {
    param(
        [Parameter(Mandatory)]
        [string] $RunId,

        [Parameter(Mandatory)]
        [string] $Category,

        [Parameter(Mandatory)]
        [string] $Message,

        [AllowNull()]
        [string] $InvocationId,

        [AllowNull()]
        [string] $FailureId,

        [AllowNull()]
        $SafeDetails,

        [AllowNull()]
        [System.Nullable[bool]] $Retryable,

        [AllowNull()]
        [System.Nullable[bool]] $FallbackAllowed,

        [datetime] $CreatedAt = [datetime]::MinValue
    )

    $parameters = @{
        RunId    = $RunId
        Category = $Category
        Message  = $Message
    }
    foreach ($optionalName in @('InvocationId', 'FailureId', 'SafeDetails', 'Retryable', 'FallbackAllowed', 'CreatedAt')) {
        if ($PSBoundParameters.ContainsKey($optionalName)) {
            $parameters[$optionalName] = $PSBoundParameters[$optionalName]
        }
    }

    return New-ReviewerInfrastructureFailure @parameters
}
