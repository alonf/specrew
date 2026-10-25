# Iteration 002, round-3 follow-up (DRIFT-199-I002-029): a refusal must name the thing that actually failed.
#
# FIELD CASE, C:\Temp\ConsoleFractal, 2026-08-30. A workshop was rejected because the binding NAME
# `decomposition_style` contains an underscore. The refusal said "decision '<name>' has value '<value>'",
# printed a value that was PERFECTLY VALID, and offered a CASING example (`ihttpclientfactory`, not
# `IHttpClientFactory`) that has nothing to do with underscores. The agent recovered by trial rather than
# by reading the message.
#
# The cause was upstream of the wording: one `if` combined both checks with `-or`, so the conflict record
# could not say which side failed, and the message had nothing to name and named the wrong thing
# confidently.
#
# THE ASYMMETRY THAT MAKES THIS A TRAP - two patterns differing in exactly the character people reach for:
#     name   ^[a-z][a-z0-9.-]{0,63}$        dot, hyphen, NO UNDERSCORE
#     value  ^[a-z0-9][a-z0-9._-]{0,127}$   dot, hyphen, AND UNDERSCORE
# Pinned below so it cannot drift silently in either direction while the beta4 schema question is open.
#
# Mutations that turn this file red: collapse failed_field back into a single -or; drop failed_rule; let
# the name branch of the refusal carry the casing example; restore positional binding on the lens writer.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $repoRoot 'scripts\internal\bootstrap\ProjectMetadataAccessor.ps1')
$script:failCount = 0
function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; $script:failCount++ }
function Assert-True { param([bool]$Condition, [string]$Message) if ($Condition) { Write-Pass $Message } else { Write-Fail $Message } }

function Test-Binding {
    param([string]$Name, [string]$Value)
    $bindings = [pscustomobject]@{}
    $bindings | Add-Member -NotePropertyName $Name -NotePropertyValue $Value
    $applicability = [pscustomobject]@{
        selected = @('architecture-core')
        workshop = [pscustomobject]@{ 'architecture-core' = [pscustomobject]@{ moved_on = $true; bindings = $bindings } }
    }
    return (Test-SpecrewWorkshopDecisionBindings -Applicability $applicability)
}

Write-Host 'Case 1: the FIELD case - an underscore in the NAME is attributed to the name'
$r1 = Test-Binding -Name 'decomposition_style' -Value 'layered'
Assert-True (-not $r1.valid) 'the binding is rejected, as it was in the field'
Assert-True ([string]$r1.conflict.failed_field -eq 'name') 'the failure is attributed to the NAME, not the value'
Assert-True ([string]$r1.conflict.failed_text -eq 'decomposition_style') 'and the offending text is the name itself, not the value that was fine'
Assert-True ([string]$r1.conflict.failed_rule -match 'underscores are NOT allowed in a decision name') 'the rule that failed is named, in the terms that explain THIS rejection'

Write-Host 'Case 2: a casing problem in the VALUE is attributed to the value'
$r2 = Test-Binding -Name 'http-client' -Value 'IHttpClientFactory'
Assert-True (-not $r2.valid) 'the binding is rejected'
Assert-True ([string]$r2.conflict.failed_field -eq 'value') 'the failure is attributed to the VALUE'
Assert-True ([string]$r2.conflict.failed_text -eq 'IHttpClientFactory') 'and names the value that failed'

Write-Host 'Case 3: the asymmetry itself, pinned so it cannot drift silently while beta4 decides it'
$r3 = Test-Binding -Name 'http-client' -Value 'ihttp_client_factory'
Assert-True ($r3.valid) 'an underscore IS legal in a value - the exact character that is illegal in a name'
$r4 = Test-Binding -Name 'decomposition.style' -Value 'layered'
Assert-True ($r4.valid) 'a dot is legal in a name, so the name rule is not simply stricter about everything'

Write-Host 'Case 4: the refusal wording - the name branch must not carry the casing advice'
# A SOURCE-SHAPE CHECK, and labelled as one: the message is composed inside the provider's Stop path and
# is not reachable as a function. It asserts the two properties the field case turned on - that a name
# failure has its own branch, and that the casing example lives only where casing is the problem.
$provider = Get-Content -LiteralPath (Join-Path $repoRoot 'extensions\specrew-speckit\scripts\specrew-conformance-provider.ps1') -Raw -Encoding UTF8
$nameBranch = [regex]::Match($provider, "if \(\`$failedField -eq 'name'\) \{(?<body>.*?)\n                    \}", [Text.RegularExpressions.RegexOptions]::Singleline)
Assert-True ($nameBranch.Success) 'the refusal has a branch for a NAME failure'
Assert-True ($nameBranch.Groups['body'].Value -notmatch 'IHttpClientFactory') 'and that branch does NOT offer the casing example - the advice that sent the field agent looking at a valid value'
Assert-True ($nameBranch.Groups['body'].Value -match 'decision NAME') 'it says plainly that the NAME is what is not usable'
Assert-True ($nameBranch.Groups['body'].Value -match 'value you recorded is fine') 'and tells the reader the value needs no change, which is the sentence that would have saved the trial-and-error'

Write-Host 'Case 5: the lens writer refuses positional binding, so a mis-shaped call cannot masquerade'
# A six-element -Agenda array was absorbed across the positional parameters and one of its strings landed
# in -Confirmation. The ValidateSet caught it LOUDLY, which is right - but it named Confirmation while the
# cause was Agenda. With positional binding refused the failure is reported where it happened.
$lensSource = Get-Content -LiteralPath (Join-Path $repoRoot 'extensions\specrew-speckit\scripts\confirm-workshop-lens.ps1') -Raw -Encoding UTF8
Assert-True ($lensSource -match '\[CmdletBinding\(PositionalBinding = \$false\)\]') 'every parameter must be named, so a stray positional argument cannot land in another parameter'
Assert-True ($lensSource -match '\[Parameter\(Mandatory\)\]\[string\[\]\] \$Agenda') 'and Agenda is explicitly a string array'

$writer = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\confirm-workshop-lens.ps1'
$positional = (& pwsh -NoProfile -File $writer 'some-root' 'some-feature' 'architecture-core' 2>&1 | ForEach-Object { [string]$_ }) -join ' '
$plain = [regex]::Replace($positional, "`e\[[0-9;]*m", '')
Assert-True ($plain -match 'positional parameter cannot be found|Cannot process argument|Missing an argument') ('a positional call fails as a positional problem: ' + $plain.Substring(0, [Math]::Min(120, $plain.Length)))
Assert-True ($plain -notmatch 'Confirmation') 'and never as a Confirmation validation error, which is what sent the field agent to the wrong parameter'

if ($script:failCount -gt 0) { throw ("refusal-names-what-failed: {0} assertion(s) failed" -f $script:failCount) }
Write-Host 'refusal-names-what-failed: all assertions passed' -ForegroundColor Green
