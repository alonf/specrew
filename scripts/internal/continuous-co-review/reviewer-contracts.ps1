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

        [System.Collections.Generic.List[string]] $Errors
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
    if ($major -ne '1') {
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

    Test-ReviewerContractSchemaVersion -InputObject $InputObject -Errors $errors
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
