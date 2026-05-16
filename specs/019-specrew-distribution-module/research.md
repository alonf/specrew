# Phase 0 Research: Specrew Distribution Module

**Feature**: 019-specrew-distribution-module  
**Date**: 2026-05-16  
**Objective**: Resolve design unknowns before Phase 1 design artifacts and Phase 2 implementation

---

## R1: PSGallery Module Packaging Best Practices

### Investigation Scope
Research PSGallery module structure, file list management, and metadata conventions to inform Pillar 1 (Module Packaging) and Pillar 2 (Resource Bundling) implementation.

### Findings

**Key Patterns from Existing Modules** (Pester, PSReadLine, PowerShellGet):

1. **Module Manifest Structure**:
   - `ModuleVersion`: Semantic versioning (MAJOR.MINOR.PATCH); required
   - `PowerShellVersion`: Minimum PowerShell version (e.g., '7.0'); enforces compatibility
   - `GUID`: Unique module identifier; generated once, never changes
   - `Author`: Human-readable author name or organization
   - `Description`: One-line summary for PSGallery listing
   - `FunctionsToExport`: Explicit list of exported functions (wildcards discouraged for performance)
   - `PrivateData`: Metadata for PSGallery (tags, release notes URL, project URL, icon URL)

2. **File List Management**:
   - **Explicit FileList**: Recommended for production modules to avoid accidental inclusions (e.g., test files, dev artifacts)
   - **Exclusion Pattern**: Exclude specs/, tests/, proposals/, .git/, .vscode/, *.log, *.tmp
   - **Inclusion Pattern**: Include scripts/, extensions/, templates/, docs/, manifest, module loader

3. **Module Loader (`*.psm1`) Patterns**:
   - **Explicit Dot-Sourcing**: Most common; transparent and debuggable
   - **Dynamic Discovery**: Less common; uses `Get-ChildItem` + `Import-Module` loop
   - **Recommendation for Specrew**: Explicit dot-sourcing for simplicity and debuggability

4. **PSGallery Size Limit**:
   - Hard limit: 2 GB (not a concern for Specrew; estimated <5 MB)
   - Soft guideline: Keep under 50 MB for fast downloads

### Decision: Specrew Module Manifest Structure

**Recommended Fields**:
```powershell
@{
    ModuleVersion = '0.18.0'  # Stamped from .specrew/config.yml at build time
    PowerShellVersion = '7.0'  # Minimum PS7 for cross-platform support
    GUID = '[generate-once]'  # Unique identifier
    Author = 'Alon Fliess'
    Description = 'Specrew: Specification-driven development workflow for AI-augmented teams'
    FunctionsToExport = @('specrew', 'specrew-init', 'specrew-start', 'specrew-update', 'specrew-review', 'specrew-team', 'specrew-where')
    FileList = @(
        'Specrew.psd1',
        'Specrew.psm1',
        'scripts/*.ps1',
        'scripts/internal/*.ps1',
        'extensions/specrew-speckit/**/*',
        'templates/**/*',
        'docs/*.md'
    )
    PrivateData = @{
        PSData = @{
            Tags = @('specrew', 'specification', 'squad', 'ai-workflow', 'governance')
            ProjectUri = 'https://github.com/alonf/specrew'
            LicenseUri = 'https://github.com/alonf/specrew/blob/main/LICENSE'
            ReleaseNotes = 'https://github.com/alonf/specrew/blob/main/CHANGELOG.md'
        }
    }
}
```

**Rationale**:
- Explicit FileList avoids accidental inclusion of specs/, proposals/, tests/
- FunctionsToExport lists all Specrew CLI commands for performance and clarity
- PrivateData.PSData provides PSGallery metadata for discoverability

---

## R2: PowerShell Module Loader Patterns

### Investigation Scope
Choose between explicit dot-sourcing vs. dynamic discovery for `Specrew.psm1` module loader.

### Findings

**Pattern A: Explicit Dot-Sourcing**
```powershell
# Specrew.psm1
$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

. (Join-Path $PSScriptRoot 'scripts\specrew.ps1')
. (Join-Path $PSScriptRoot 'scripts\specrew-init.ps1')
. (Join-Path $PSScriptRoot 'scripts\specrew-start.ps1')
. (Join-Path $PSScriptRoot 'scripts\specrew-update.ps1')
. (Join-Path $PSScriptRoot 'scripts\specrew-review.ps1')
. (Join-Path $PSScriptRoot 'scripts\specrew-team.ps1')
. (Join-Path $PSScriptRoot 'scripts\specrew-where.ps1')

Export-ModuleMember -Function 'specrew', 'specrew-init', 'specrew-start', 'specrew-update', 'specrew-review', 'specrew-team', 'specrew-where'
```

**Pattern B: Dynamic Discovery**
```powershell
# Specrew.psm1
$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$scriptsPath = Join-Path $PSScriptRoot 'scripts'

Get-ChildItem -Path $scriptsPath -Filter '*.ps1' -Recurse | ForEach-Object {
    . $_.FullName
}

Export-ModuleMember -Function '*'
```

**Trade-offs**:

| Criterion | Explicit Dot-Sourcing | Dynamic Discovery |
| --- | --- | --- |
| Transparency | High (visible file list) | Low (implicit discovery) |
| Debuggability | High (clear load order) | Medium (harder to trace issues) |
| Maintenance Burden | Medium (must update on new files) | Low (automatic) |
| Performance | Fast (no directory scan) | Slightly slower (directory scan) |
| Risk | Low (only listed files loaded) | Medium (accidental loads if *.ps1 in scripts/) |

### Decision: Explicit Dot-Sourcing

**Rationale**: Transparency and debuggability outweigh maintenance burden. Specrew has a small, stable set of entry-point scripts (~7 files); adding a new entry point is rare and explicit listing reduces risk of accidental loads.

---

## R3: Template-Refresh Conflict Resolution Protocol

### Investigation Scope
Define crew-framework-agnostic conflict marker format that Squad coordinator can parse for `specrew update` conflict resolution.

### Findings

**Conflict Scenario**: User modifies `.specify/templates/spec-template.md` locally. Module v0.22 ships an updated `spec-template.md`. `specrew update` detects the conflict.

**Approved Iteration 001 verdict (T002, 2026-05-16)**:
- **Option A selected**: Git-style markers (`<<<<<<<`, `=======`, `>>>>>>>`)
- **Why**: universal text-conflict standard; best fit for Iteration 001 text-template-only scope; IDE diff tooling and `git mergetool` compatibility; zero training cost; no custom parser needed in Iteration 001; unresolved artifacts remain plain text

**Conflict Resolution Flow** (Template-Refresh Pattern B from the approved T002 decision):

1. **Conflict Detection**: `specrew update` compares the user's local template with the new module template.
2. **Preserve-and-Flag Artifact**:
   - `specrew update` writes `.specrew/template-conflicts/<filename>.conflict`.
   - The artifact preserves both versions in plain text using the approved Git-style marker block.
   - The artifact records the preserved-at UTC timestamp, module version, and source template path inline in the marker labels.
3. **Crew-Mediated Resolution on Next `specrew start`**:
   - Squad parses each `.conflict` artifact.
   - Squad walks the user through `accept-new`, `keep-user`, or `manual-resolve`.
   - After the user chooses or completes a manual merge, Squad writes the resolved destination file and removes the artifact.
4. **Iteration 2 Hardening Follow-Up**:
   - Verify Linux/macOS clean reading with LF and no BOM during the later cross-platform hardening pass.

**Approved Conflict Artifact Format** (`.specrew/template-conflicts/<filename>.conflict`):

```text
<<<<<<< user-version (preserved at: <iso8601-utc-timestamp>)
{user's modified content}
=======
{new module-template content}
>>>>>>> module-version (specrew_version: <module-version>, source: templates/<path>)
```

**Alternative Formats Considered**:
- Custom markers (`<<<< USER`, `==== MODULE`, `>>>> END`): clearer labels, but requires custom parser behavior and adds training/documentation cost
- Structured comments (language-aware): powerful in theory, but too complex for Iteration 001
- Git-style markers: **APPROVED** — universal convention, IDE tooling support, `git mergetool` compatibility, and no Iteration 001 parser design burden

### Decision: Git-Style Conflict Artifacts with Next-Start Squad Mediation

**Rationale**: The approved format keeps unresolved conflicts in plain text and preserves both versions without inventing a custom syntax. The sidecar artifact gives Squad a crew-framework-agnostic payload to parse on the next `specrew start`, while deferring cross-platform line-ending/BOM hardening to Iteration 2.

---

## R4: Cross-Platform Path Handling Verification

### Investigation Scope
Validate `Join-Path` enforcement across all scripts and design WSL verification task.

### Findings

**Path Delimiter Issue**:
- Windows: `\` (backslash)
- Linux/macOS: `/` (forward slash)
- PowerShell `Join-Path`: Automatically uses correct delimiter for current platform

**Audit Strategy**:
1. **Static Analysis**: Grep for hardcoded path delimiters (`\`, `/`) in string literals
2. **Enforcement**: Replace all path construction with `Join-Path`
3. **Verification Task**: Manual WSL test + Ubuntu/macOS test

**WSL Verification Task Design**:

```powershell
# Test script: tests/wsl-verification.ps1
# Run in WSL (Windows Subsystem for Linux) to validate cross-platform correctness

# 1. Install module in WSL
Install-Module Specrew -Scope CurrentUser

# 2. Bootstrap test project
mkdir ~/specrew-wsl-test
cd ~/specrew-wsl-test
specrew init

# 3. Verify template paths
Test-Path .specify/templates/spec-template.md  # Should be $true
Test-Path .squad/agents/copilot.md             # Should be $true
Test-Path .github/workflows/specrew-review.yml # Should be $true

# 4. Verify no backslash artifacts in copied files
rg '\\\\' .specify/ .squad/ .github/  # Should return no matches

# 5. Verify specrew commands work
specrew where  # Should output project paths with forward slashes
specrew start  # Should not crash on path resolution
```

**Verification Checklist**:
- [ ] `specrew init` succeeds in WSL without errors
- [ ] All template files copied with correct paths (forward slashes)
- [ ] `specrew where` outputs paths with forward slashes
- [ ] `specrew start` does not crash on path resolution
- [ ] Repeat on Ubuntu VM (native Linux, not WSL)
- [ ] Repeat on macOS VM (native macOS)

### Decision: `Join-Path` Everywhere + Dedicated WSL Verification Task

**Rationale**: `Join-Path` is the PowerShell-native solution for cross-platform path handling. Dedicated WSL verification task ensures real-world cross-platform correctness beyond unit tests (WSL is a common Windows+Linux hybrid environment where path issues surface).

---

## R5: GitHub Actions Publish Workflow Design

### Investigation Scope
Design GitHub Actions workflow for automated module publishing on `v*.*` tag push.

### Findings

**Workflow Structure**:

```yaml
# .github/workflows/publish-module.yml
name: Publish Module to PSGallery

on:
  push:
    tags:
      - 'v*.*'

jobs:
  publish:
    runs-on: windows-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Stamp module version from config
        run: |
          $version = (Get-Content .specrew/config.yml | Select-String 'specrew_version:').ToString().Split(':')[1].Trim().Trim('"')
          (Get-Content Specrew.psd1) -replace "ModuleVersion = '.*'", "ModuleVersion = '$version'" | Set-Content Specrew.psd1

      - name: Sign module
        run: |
          # Self-signed certificate from GitHub Actions secret
          $cert = [Convert]::FromBase64String($env:SIGNING_CERT_BASE64)
          $certPath = "$env:TEMP\signing-cert.pfx"
          [IO.File]::WriteAllBytes($certPath, $cert)
          Set-AuthenticodeSignature -FilePath Specrew.psd1 -Certificate (Get-PfxCertificate $certPath -Password (ConvertTo-SecureString $env:SIGNING_CERT_PASSWORD -AsPlainText -Force))
        env:
          SIGNING_CERT_BASE64: ${{ secrets.SIGNING_CERT_BASE64 }}
          SIGNING_CERT_PASSWORD: ${{ secrets.SIGNING_CERT_PASSWORD }}

      - name: Publish to PSGallery
        run: |
          Publish-Module -Path . -NuGetApiKey $env:PSGALLERY_API_KEY -Verbose
        env:
          PSGALLERY_API_KEY: ${{ secrets.PSGALLERY_API_KEY }}

      - name: Log publish result
        if: failure()
        run: |
          Write-Host "Publishing failed. Check PSGallery API key, module manifest, and network connectivity."
```

**GitHub Actions Secrets Required**:
- `PSGALLERY_API_KEY`: PSGallery API key for authentication
- `SIGNING_CERT_BASE64`: Base64-encoded self-signed certificate (PFX format)
- `SIGNING_CERT_PASSWORD`: Password for self-signed certificate

**Error Handling Strategy**:
- Workflow fails visibly if version stamping fails (invalid config.yml)
- Workflow fails visibly if signing fails (invalid certificate or password)
- Workflow fails visibly if `Publish-Module` fails (API key expired, version collision, network issue)
- Logs visible in GitHub Actions UI for maintainer investigation

### Decision: GitHub Actions Workflow with Version Stamping + Self-Signing + Publish

**Rationale**: GitHub Actions provides secure secret storage, cross-platform runners (Windows for PowerShell), and integration with existing Rule 15 feature-closeout workflow (tag push triggers publish). Version stamping from `.specrew/config.yml` ensures single source of truth. Self-signing reduces trust warnings on install.

---

## R6: Module Signing Strategy

### Investigation Scope
Design self-signed certificate generation, storage, and validity period for module signing.

### Findings

**Self-Signed Certificate Generation** (one-time setup):

```powershell
# Generate self-signed certificate (maintainer runs locally or in CI)
$cert = New-SelfSignedCertificate `
    -Subject "CN=Specrew Module Signing" `
    -Type CodeSigningCert `
    -CertStoreLocation Cert:\CurrentUser\My `
    -NotAfter (Get-Date).AddYears(5)

# Export certificate to PFX (with password protection)
$certPath = "C:\Temp\specrew-signing-cert.pfx"
$password = ConvertTo-SecureString "your-secure-password" -AsPlainText -Force
Export-PfxCertificate -Cert $cert -FilePath $certPath -Password $password

# Convert PFX to Base64 for GitHub Actions secret
$pfxBytes = [IO.File]::ReadAllBytes($certPath)
$pfxBase64 = [Convert]::ToBase64String($pfxBytes)
Write-Host $pfxBase64  # Copy to GitHub Actions secret SIGNING_CERT_BASE64
```

**Validity Period Trade-offs**:

| Validity Period | Pros | Cons |
| --- | --- | --- |
| 1 year | Lower risk window if private key leaks | Frequent renewal (annual maintenance burden) |
| 5 years | Balanced security vs. maintenance | Moderate risk window; reasonable renewal cadence |
| 10 years | Minimal maintenance burden | High risk window if private key leaks |

### Decision: 5-Year Validity Period for Self-Signed Certificate

**Rationale**: Balances security (moderate risk window) with maintenance burden (renewal every 5 years). Private key stored as GitHub Actions secret (SIGNING_CERT_BASE64 + SIGNING_CERT_PASSWORD); not exposed in codebase or local machines. Renewal procedure documented in `docs/maintainer-runbook.md`.

---

## Research Summary

**Execution note**: research recommendations exist for all six design questions, but only the human-approved Phase 0 decisions should be treated as binding during implementation.

**Currently approved human decisions**:
1. **T001 — Module Manifest**: Explicit `FileList` allowlist, FunctionsToExport, version stamped from `.specrew/config.yml`
2. **T002 — Conflict Resolution**: Git-style `.conflict` sidecar artifacts with next-session Squad mediation

**Research recommendations still awaiting explicit execution-time approval**:
3. **T003 candidate**: `Join-Path` everywhere + cross-platform verification strategy still needs a human automation-depth decision
4. **T004 candidate**: Explicit dot-sourcing for transparency and debuggability
5. **T006 candidate**: 5-year validity self-signed certificate stored as GitHub Actions secrets

**Next execution boundary**: Phase 0 continues at T003 (Cross-Platform Test Automation Depth).
