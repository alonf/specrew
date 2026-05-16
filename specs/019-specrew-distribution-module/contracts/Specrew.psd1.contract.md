# Module Manifest Contract: Specrew.psd1

**Feature**: 019-specrew-distribution-module  
**Date**: 2026-05-16  
**Purpose**: Define the schema and contract for the Specrew PowerShell module manifest

---

## Overview

The `Specrew.psd1` module manifest is the central contract between the Specrew module and PowerShell Gallery / end users. It declares:
- Module metadata (version, author, description)
- Exported functions (PowerShell commands)
- Bundled files (scripts, extensions, templates, docs)
- Compatibility requirements (minimum PowerShell version)
- PSGallery metadata (tags, project URL, license URL)

This contract ensures consistent module structure across versions and enables automated publishing via GitHub Actions.

---

## Manifest Schema

```powershell
@{
    # === Core Metadata ===
    ModuleVersion = '<VERSION>'          # Semantic version; stamped from .specrew/config.yml at build time
    GUID = '<GUID>'                      # Unique module identifier; generated once, never changes
    Author = 'Alon Fliess'               # Human-readable author name
    Description = 'Specrew: Specification-driven development workflow for AI-augmented teams'
    
    # === Compatibility ===
    PowerShellVersion = '7.0'            # Minimum PowerShell version (cross-platform support)
    PSEdition = 'Core'                   # Enforce PowerShell 7+ (Core edition)
    
    # === Exported Functions ===
    FunctionsToExport = @(
        'specrew',
        'specrew-init',
        'specrew-start',
        'specrew-update',
        'specrew-review',
        'specrew-team',
        'specrew-where'
    )
    
    # === Bundled Files ===
    FileList = @(
        'Specrew.psd1',
        'Specrew.psm1',
        'scripts/*.ps1',
        'scripts/internal/*.ps1',
        'extensions/specrew-speckit/**/*',
        'templates/**/*',
        'docs/*.md'
    )
    
    # === PSGallery Metadata ===
    PrivateData = @{
        PSData = @{
            Tags = @('specrew', 'specification', 'squad', 'ai-workflow', 'governance')
            ProjectUri = 'https://github.com/alonf/specrew'
            LicenseUri = 'https://github.com/alonf/specrew/blob/main/LICENSE'
            ReleaseNotes = 'https://github.com/alonf/specrew/blob/main/CHANGELOG.md'
            IconUri = ''  # Optional: URL to module icon (deferred to post-v1)
        }
    }
}
```

---

## Field Definitions

### Core Metadata

#### `ModuleVersion` (string, required)
- **Format**: Semantic versioning (MAJOR.MINOR.PATCH), e.g., '0.18.0'
- **Source of Truth**: `.specrew/config.yml` → `specrew_version` field
- **Stamping Mechanism**: GitHub Actions workflow reads `specrew_version` from config and updates `Specrew.psd1` before `Publish-Module`
- **Validation**: Must match `specrew_version` at publish time (automated check in GitHub Actions)
- **Example**: `ModuleVersion = '0.18.0'`

#### `GUID` (string, required)
- **Format**: UUID (e.g., 'a1b2c3d4-e5f6-7890-abcd-ef1234567890')
- **Generation**: One-time only; use `New-Guid` PowerShell cmdlet during initial manifest creation
- **Immutability**: **Never changes** across module versions (PSGallery uses GUID for module identity)
- **Validation**: Must be valid UUID format
- **Example**: `GUID = 'e8f7a6b5-c4d3-2e1f-0a9b-8c7d6e5f4a3b'`

#### `Author` (string, required)
- **Format**: Human-readable name or organization
- **Value**: 'Alon Fliess' (feature sponsor and primary maintainer)
- **Validation**: Non-empty string
- **Example**: `Author = 'Alon Fliess'`

#### `Description` (string, required)
- **Format**: One-line summary (max 256 characters recommended for PSGallery listing)
- **Value**: 'Specrew: Specification-driven development workflow for AI-augmented teams'
- **Purpose**: Appears in PSGallery search results and `Find-Module` output
- **Validation**: Non-empty string, no line breaks
- **Example**: `Description = 'Specrew: Specification-driven development workflow for AI-augmented teams'`

---

### Compatibility

#### `PowerShellVersion` (string, required)
- **Format**: Minimum PowerShell version (e.g., '7.0')
- **Value**: '7.0' (enforces cross-platform PowerShell Core)
- **Purpose**: PSGallery enforces this requirement during `Install-Module`; users on PowerShell 5.1 cannot install
- **Validation**: Must be '7.0' or higher (per spec FR-001)
- **Example**: `PowerShellVersion = '7.0'`

#### `PSEdition` (string, required)
- **Format**: 'Core' or 'Desktop'
- **Value**: 'Core' (enforces PowerShell 7+ requirement)
- **Purpose**: Prevents installation on PowerShell 5.1 (Desktop edition)
- **Validation**: Must be 'Core' (per spec FR-032)
- **Example**: `PSEdition = 'Core'`

---

### Exported Functions

#### `FunctionsToExport` (array, required)
- **Format**: Array of function names (strings)
- **Value**: All Specrew CLI commands (see table below)
- **Purpose**: Declares which functions are available to users after `Import-Module Specrew`
- **Performance**: Explicit list is faster than wildcard (`'*'`)
- **Validation**: Each function name must match a corresponding script file in `scripts/`
- **Example**: `FunctionsToExport = @('specrew', 'specrew-init', 'specrew-update')`

**Exported Functions List**:

| Function Name | Script Path | Purpose | Status |
| --- | --- | --- | --- |
| `specrew` | `scripts/specrew.ps1` | Main entry point (delegates to subcommands) | Existing |
| `specrew-init` | `scripts/specrew-init.ps1` | Bootstrap command (copy templates, generate per-project files) | Modified (Pillar 3) |
| `specrew-start` | `scripts/specrew-start.ps1` | Session start command | Existing (no changes) |
| `specrew-update` | `scripts/specrew-update.ps1` | Template-refresh command | NEW (Pillar 4) |
| `specrew-review` | `scripts/specrew-review.ps1` | Review command | Existing (no changes) |
| `specrew-team` | `scripts/specrew-team.ps1` | Team command | Existing (no changes) |
| `specrew-where` | `scripts/specrew-where.ps1` | Path introspection command | Existing (no changes) |

---

### Bundled Files

#### `FileList` (array, required)
- **Format**: Array of file paths or glob patterns (relative to module root)
- **Purpose**: Explicitly declares which files are included in the PSGallery package
- **Rationale**: Explicit list avoids accidental inclusion of dev artifacts (specs/, tests/, .git/)
- **Validation**: Each path must exist in module directory; total package size must be under 5 MB (per spec FR-005)
- **Example**: `FileList = @('Specrew.psd1', 'scripts/*.ps1', 'templates/**/*')`

**T001 Decision (2026-05-16)**:
- **Approved strategy**: Option 1 — explicit `FileList` allowlist for `Specrew.psd1`
- **Why**: FR-010 requires provable exclusion semantics; an allowlist prevents silent drift and accidental shipping of excluded or sensitive repository surfaces
- **Allowed pattern style**: per-directory wildcards are acceptable inside the allowlist (for example `scripts/*.ps1`, `templates/**/*`)
- **Implementation boundary**: only enumerated surfaces may ship; new distributable surfaces must be added deliberately rather than auto-discovered

**Inclusion Rules** (from spec FR-006 through FR-010):

| Category | Glob Pattern | Rationale |
| --- | --- | --- |
| **Module manifest** | `Specrew.psd1` | Required for module identity |
| **Module loader** | `Specrew.psm1` | Loads and exports functions |
| **Entry-point scripts** | `scripts/*.ps1` | Specrew CLI commands (specrew-init.ps1, specrew-update.ps1, etc.) |
| **Internal utilities** | `scripts/internal/*.ps1` | Shared helper functions used by entry points |
| **Validator extension** | `extensions/specrew-speckit/**/*` | Bundled Spec Kit validator extension (validators, coordinator prompts, Squad templates) |
| **User-facing templates** | `templates/**/*` | Copied into user projects by `specrew init` |
| **Reference documentation** | `docs/*.md` | Dashboard guide, roadmap maintenance guide, etc. |

**Exclusion Rules**:

| Category | Example Paths | Rationale |
| --- | --- | --- |
| **Specrew's own specs** | `specs/`, `proposals/` | Repo metadata; not distributed to end users |
| **Test suite** | `tests/` | Dev artifacts; not needed for module usage |
| **Repo metadata** | `CHANGELOG.md`, `LICENSE`, `README.md` | PSGallery listing links to GitHub for these |
| **Version control** | `.git/`, `.gitignore`, `.gitattributes` | Dev artifacts |
| **IDE config** | `.vscode/`, `.copilot/`, `.scratch/` | Dev artifacts |
| **Build artifacts** | `*.log`, `*.tmp`, `validator-output.log` | Temporary files |

---

### PSGallery Metadata

#### `PrivateData.PSData` (object, required)
- **Format**: Nested hashtable with PSGallery-specific metadata
- **Purpose**: Provides additional metadata for PSGallery listing (tags, URLs)
- **Validation**: Each field must be valid URL or array of strings

**Sub-fields**:

##### `Tags` (array)
- **Format**: Array of lowercase strings (e.g., 'specrew', 'governance')
- **Purpose**: Enables `Find-Module -Tag <tag>` discovery
- **Value**: `@('specrew', 'specification', 'squad', 'ai-workflow', 'governance')`
- **Validation**: Each tag must be alphanumeric (hyphens allowed)

##### `ProjectUri` (string)
- **Format**: URL to GitHub repository
- **Purpose**: Appears as "Project Site" link on PSGallery listing
- **Value**: `'https://github.com/alonf/specrew'`
- **Validation**: Must be valid HTTPS URL

##### `LicenseUri` (string)
- **Format**: URL to LICENSE file in GitHub repository
- **Purpose**: Appears as "License" link on PSGallery listing
- **Value**: `'https://github.com/alonf/specrew/blob/main/LICENSE'`
- **Validation**: Must be valid HTTPS URL

##### `ReleaseNotes` (string)
- **Format**: URL to CHANGELOG.md in GitHub repository
- **Purpose**: Appears as "Release Notes" link on PSGallery listing
- **Value**: `'https://github.com/alonf/specrew/blob/main/CHANGELOG.md'`
- **Validation**: Must be valid HTTPS URL

##### `IconUri` (string, optional)
- **Format**: URL to module icon (PNG or SVG)
- **Purpose**: Appears as thumbnail in PSGallery listing
- **Value**: `''` (empty for v1; deferred to post-public-flip)
- **Validation**: Must be valid HTTPS URL pointing to image file

---

## Version Stamping Workflow

**Problem**: Module manifest version must match `.specrew/config.yml` `specrew_version` to maintain single source of truth.

**Solution**: GitHub Actions workflow stamps version at build time (before `Publish-Module`).

**Workflow Steps**:

1. **Trigger**: GitHub Actions workflow runs on `v*.*` tag push (e.g., `v0.18.0`)
2. **Read Config**: Workflow reads `.specrew/config.yml` and extracts `specrew_version` field
3. **Update Manifest**: Workflow modifies `Specrew.psd1` in-place, replacing `ModuleVersion = '...'` with extracted version
4. **Validate Manifest**: Workflow runs `Test-ModuleManifest Specrew.psd1` to ensure validity
5. **Sign Manifest**: Workflow applies self-signed certificate signature
6. **Publish**: Workflow runs `Publish-Module -Path . -NuGetApiKey $env:PSGALLERY_API_KEY`

**Example GitHub Actions Step**:

```yaml
- name: Stamp module version from config
  run: |
    $version = (Get-Content .specrew/config.yml | Select-String 'specrew_version:').ToString().Split(':')[1].Trim().Trim('"')
    Write-Host "Stamping module version: $version"
    (Get-Content Specrew.psd1) -replace "ModuleVersion = '.*'", "ModuleVersion = '$version'" | Set-Content Specrew.psd1
    Test-ModuleManifest Specrew.psd1
```

---

## Exported Function Signatures

> Detailed signatures for each exported function. These serve as implementation contracts.

### `specrew` (Main Entry Point)

```powershell
function specrew {
    [CmdletBinding(PositionalBinding = $false)]
    param(
        [Parameter(Position = 0)]
        [ValidateSet('init', 'start', 'update', 'review', 'team', 'where')]
        [string]$Command,
        
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    # Delegates to subcommands (specrew-init, specrew-start, etc.)
}
```

### `specrew-init` (Bootstrap Command)

```powershell
function specrew-init {
    [CmdletBinding(PositionalBinding = $false)]
    param(
        [Alias('project-path')]
        [string]$ProjectPath = (Get-Location).Path,
        
        [Alias('dry-run')]
        [switch]$DryRun,
        
        [switch]$Force,
        
        [Alias('speckit-version')]
        [string]$SpecKitVersion = '0.8.11',
        
        [Alias('squad-version')]
        [string]$SquadVersion = '0.9.4',
        
        [string]$Agents = 'copilot',
        
        [Alias('no-agents')]
        [switch]$NoAgents,
        
        [switch]$Help
    )
    
    # Detects module-vs-clone context
    # Resolves template paths from $PSScriptRoot/../templates/ (module) or repo root (clone)
    # Copies templates to user project (.specify/, .squad/, .github/)
    # Generates per-project files (feature.json, decisions.md, now.md)
}
```

### `specrew-update` (Template-Refresh Command)

```powershell
function specrew-update {
    [CmdletBinding(PositionalBinding = $false)]
    param(
        [Alias('project-path')]
        [string]$ProjectPath = (Get-Location).Path,
        
        [Alias('dry-run')]
        [switch]$DryRun,
        
        [switch]$Force,
        
        [switch]$Help
    )
    
    # Compares user project templates vs. new module templates
    # Detects conflicts (user modified + module updated)
    # Preserves user templates with conflict markers (Git-style)
    # Writes .specrew/template-conflicts/*.conflict artifacts
    # Updates non-conflicted templates
    # Reports summary (templates updated, conflicts detected)
}
```

### Other Functions

**`specrew-start`, `specrew-review`, `specrew-team`, `specrew-where`**: Existing functions; no signature changes. See current implementations for details.

---

## Validation Requirements

**Pre-Publish Checks** (automated in GitHub Actions):

1. **Manifest Validity**: `Test-ModuleManifest Specrew.psd1` must pass
2. **Version Consistency**: `ModuleVersion` in manifest must match `.specrew/config.yml` `specrew_version`
3. **FileList Existence**: Each file in `FileList` must exist in module directory
4. **Package Size**: Total package size must be under 5 MB (per spec FR-005)
5. **Exported Functions**: Each function in `FunctionsToExport` must exist in `Specrew.psm1`
6. **PowerShell Version**: `PowerShellVersion` must be '7.0' or higher
7. **PSEdition**: `PSEdition` must be 'Core'

**Post-Publish Verification** (manual):

1. **PSGallery Listing**: Verify module appears on PowerShell Gallery with correct metadata
2. **Install Test**: Run `Install-Module Specrew -Scope CurrentUser` on clean machine; verify success
3. **Bootstrap Test**: Run `specrew init` in test project; verify templates copied correctly
4. **Cross-Platform Test**: Repeat install + bootstrap on Windows, Linux, macOS

---

## Backward Compatibility

**Guarantee**: Module manifest schema remains stable across versions. Changes to manifest structure require:
1. Major version bump (e.g., v0.x → v1.x or v1.x → v2.x)
2. Release notes documenting breaking changes
3. Migration guide for existing users

**Exception**: Version stamping and signing are build-time operations; they do not affect published manifest schema.

---

## Next Steps

**Implementation**: Pillar 1 (Module Packaging) will create `Specrew.psd1` and `Specrew.psm1` following this contract.

**Validation**: Integration tests will verify manifest validity and exported function availability.

**Publishing**: GitHub Actions workflow will stamp version, sign manifest, and publish to PSGallery.
