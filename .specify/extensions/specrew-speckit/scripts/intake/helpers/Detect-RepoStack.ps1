<#
.SYNOPSIS
Detect repository technology stack from manifest files.

.DESCRIPTION
Scans project root for technology stack indicators:
  - .csproj → dotnet
  - pyproject.toml or setup.py → python
  - package.json → nodejs
  - Cargo.toml → rust
  - go.mod → go
  - pom.xml or build.gradle → java
  - Gemfile → ruby
  - composer.json → php

Returns stack identifier for auto-decision default selection.

Implements FR-031, TG-013 for Feature 049 Iteration 003.

.PARAMETER ProjectRoot
Project root directory to scan. Defaults to current location.

.EXAMPLE
$stack = Detect-RepoStack -ProjectRoot "."

.NOTES
Mirror parity: This file must remain functionally identical to:
  .specify/extensions/specrew-speckit/scripts/intake/helpers/Detect-RepoStack.ps1
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ProjectRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrEmpty($ProjectRoot)) {
    $ProjectRoot = Get-Location
}

# Stack detection patterns (priority order)
$stackPatterns = @(
    @{ Pattern = '*.csproj'; Stack = 'dotnet' },
    @{ Pattern = 'pyproject.toml'; Stack = 'python' },
    @{ Pattern = 'setup.py'; Stack = 'python' },
    @{ Pattern = 'package.json'; Stack = 'nodejs' },
    @{ Pattern = 'Cargo.toml'; Stack = 'rust' },
    @{ Pattern = 'go.mod'; Stack = 'go' },
    @{ Pattern = 'pom.xml'; Stack = 'java' },
    @{ Pattern = 'build.gradle'; Stack = 'java' },
    @{ Pattern = 'Gemfile'; Stack = 'ruby' },
    @{ Pattern = 'composer.json'; Stack = 'php' }
)

# Check for patterns in order
foreach ($stackPattern in $stackPatterns) {
    $matches = Get-ChildItem -Path $ProjectRoot -Filter $stackPattern.Pattern -File -ErrorAction SilentlyContinue
    if ($matches) {
        Write-Verbose "Detected stack '$($stackPattern.Stack)' from pattern: $($stackPattern.Pattern)"
        return $stackPattern.Stack
    }
}

# No stack detected, return generic
Write-Verbose "No specific stack detected, returning 'generic'"
return 'generic'
