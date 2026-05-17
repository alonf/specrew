# Specrew Quickstart Guide

**Feature**: 019-specrew-distribution-module  
**Date**: 2026-05-16  
**Purpose**: User-facing guide for installing and using Specrew via PowerShell Gallery

---

## Overview

Specrew is a specification-driven development workflow system designed for AI-augmented teams. This guide covers:
- **One-line installation** via PowerShell Gallery
- **Project bootstrapping** with `specrew init`
- **Template updates** with `specrew update`
- **Troubleshooting** common issues

**Estimated Time**: Under 5 minutes from install to first `specrew start` session.

> **Iteration 001 truth note**: the module packaging, bundled bootstrap/update flow, and publish workflow are implemented, but the **first live PSGallery publish is still a maintainer-owned manual gate**. Until that publish happens, use the clone-and-PATH workflow at the end of this guide.

---

## Prerequisites

Before installing Specrew, ensure your environment meets these requirements:

✅ **PowerShell 7.0 or higher** (cross-platform support)
- Check version: `$PSVersionTable.PSVersion`
- Install PowerShell 7: [Download from GitHub](https://github.com/PowerShell/PowerShell/releases)

✅ **Internet connectivity** (for PowerShell Gallery access)

✅ **Git** (recommended for version control, but not strictly required for Specrew usage)

---

## Installation

### Step 1: Install Specrew Module

Once the maintainer completes the first manual-gated PSGallery publish, install Specrew with:

```powershell
Install-Module Specrew -Scope CurrentUser
```

If the gallery package is not live yet, PowerShell will return "Cannot find module 'Specrew' in the gallery" — that is expected before the first public publish and the fallback path is documented in [Alternative Installation](#alternative-installation-clone-and-path).

**What happens**:
- PowerShell downloads the Specrew module from PowerShell Gallery
- Module installs to your user profile (no admin privileges required)
- Specrew commands become available in your PATH

**Verification**:
```powershell
# Check that Specrew is installed
Get-Module -ListAvailable Specrew

# Check installed version
(Get-Module -ListAvailable Specrew).Version
```

**Expected Output**:
```
ModuleType Version    Name                   ExportedCommands
---------- -------    ----                   ----------------
Script     0.18.0     Specrew                {specrew, specrew-init, specrew-start, specrew-update, ...}
```

---

### Step 2: Verify Installation

Confirm Specrew commands are available:

```powershell
specrew help
```

**Expected Output**:
```
specrew <command> [options]

Commands:
  init      Bootstrap Specrew in a project directory
  start     Begin a Specrew session
  update    Refresh templates from latest module version
  review    Review changes and generate insights
  team      Manage team configuration
  where     Show Specrew paths and configuration

Run 'specrew <command> --help' for command-specific options.
```

---

## Project Bootstrapping

### Step 3: Bootstrap Your Project

Navigate to your project directory and run `specrew init`:

```powershell
cd C:\Projects\MyProject  # Or any project directory
specrew init
```

**What happens**:
- Specrew detects it's running from an installed module (not a cloned repo)
- Templates are copied from the module installation directory to your project:
  - `.specify/` — Spec Kit templates (spec, plan, tasks templates)
  - `.squad/` — Squad agent configurations
  - `.github/` — GitHub workflow templates and the Squad coordinator prompt
- Per-project files are generated:
  - `.squad/decisions.md` — Session decision log
  - `.squad/identity/now.md` — Current project state
  - `.specrew/config.yml` — Specrew/Spec Kit/Squad version baseline
  - `.specrew/iteration-config.yml` — Iteration defaults
  - `.specrew/role-assignments.yml` — Runtime role routing

**Verification**:
```powershell
# Check that directories were created
Test-Path .specify/, .squad/, .github/

# Check that start-ready artifacts exist
Test-Path .github\agents\squad.agent.md, .github\workflows\specrew-ci.yml
```

**Expected Output**: All three directories should exist (unless you skipped GitHub workflows).

---

### Step 4: Start Your First Session

Run `specrew start` to begin a specification-driven session:

```powershell
specrew start
```

**What happens**:
- Specrew loads project state from `.squad/identity/now.md`
- Specrew writes `.specrew\last-start-prompt.md`, `.specrew\start-context.json`, and `.specrew\start-summary.md`
- Copilot (or your configured AI agent) receives the generated project context
- You're prompted to describe what you want to build or change

**Example Session Flow**:
1. You describe a feature: "I want to add user authentication with JWT tokens"
2. Copilot generates a specification (`specs/001-user-authentication/spec.md`)
3. You review and approve the spec
4. Copilot generates an implementation plan (`specs/001-user-authentication/plan.md`)
5. Copilot generates tasks (`specs/001-user-authentication/tasks.md`)
6. You iterate on implementation with AI assistance

---

## Updating Specrew

### Step 5: Update to Latest Version

When a new Specrew module version is released, update via:

```powershell
# Update the module
Update-Module Specrew

# Refresh templates in your project
cd C:\Projects\MyProject
specrew update
```

**What happens**:
- `Update-Module Specrew`: Downloads new module version from PowerShell Gallery; new scripts and extensions take effect immediately
- `specrew update`: Compares your project's templates with new module templates; detects conflicts if you modified templates locally

**Conflict Resolution**:
If `specrew update` detects conflicts (you modified a template that also changed in the new module version), it:
1. Preserves your local template with conflict markers (Git-style: `<<<<<<<`, `=======`, `>>>>>>>`)
2. Writes `.specrew/template-conflicts/<filename>.conflict` artifacts with full diff
3. Next `specrew start` prompts you to resolve conflicts manually

**Resolving Conflicts**:
1. Review diff in `.specrew/template-conflicts/<filename>.conflict`
2. Edit conflicted template file (e.g., `.specify/templates/spec-template.md`)
3. Remove conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`)
4. Delete `.conflict` artifact file
5. Run `specrew start` to confirm resolution

---

## Common Workflows

### Check Specrew Paths

See where Specrew is installed and where your project files live:

```powershell
specrew where
```

**Example Output**:
```
Specrew Module Path: C:\Users\YourName\Documents\PowerShell\Modules\Specrew\0.18.0
Project Root: C:\Projects\MyProject
Spec Directory: C:\Projects\MyProject\specs
Squad Directory: C:\Projects\MyProject\.squad
```

---

### Re-Bootstrap (Idempotent Init)

Running `specrew init` multiple times in the same project is safe:
- Existing templates are preserved (not overwritten)
- Missing templates are added
- User-modified templates are not touched

```powershell
specrew init  # Safe to run again
```

---

### Uninstall Specrew

If you need to uninstall the module:

```powershell
Uninstall-Module Specrew
```

**Note**: This only removes the module installation. Your project's `.specify/`, `.squad/`, and `.github/` directories remain intact (they are user-owned after `specrew init`).

---

## Troubleshooting

### Issue: "The term 'specrew' is not recognized"

**Cause**: PowerShell hasn't refreshed its command cache after module installation.

**Solution**: Close and reopen PowerShell, or run:
```powershell
Import-Module Specrew -Force
```

---

### Issue: "Install-Module: Cannot find module 'Specrew' in the gallery"

**Cause**: The first manual-gated PSGallery publish has not happened yet, or the new version has not propagated.

**Solution**: Wait for the maintainer to complete the live publish, or use clone-and-PATH workflow (see "Alternative Installation" below).

---

### Issue: "This module requires PowerShell 7.0 or higher"

**Cause**: You're running PowerShell 5.1 (Windows PowerShell).

**Solution**: Install PowerShell 7+ from [GitHub](https://github.com/PowerShell/PowerShell/releases) and retry.

---

### Issue: "specrew init" fails with path errors on Linux/Mac

**Cause**: Cross-platform parity is still deferred beyond Iteration 001.

**Solution**: Report issue to [GitHub Issues](https://github.com/alonf/specrew/issues) with error message and platform details.

---

### Issue: Templates not copied during "specrew init"

**Cause**: Module installation may be incomplete or corrupted.

**Solution**: Reinstall module:
```powershell
Uninstall-Module Specrew
Install-Module Specrew -Scope CurrentUser -Force
```

---

## Alternative Installation (Clone-and-PATH)

If you prefer to run Specrew from a cloned repository (e.g., for development or testing):

1. **Clone Repository**:
   ```bash
   git clone https://github.com/alonf/specrew.git
   cd specrew
   ```

2. **Add to PATH** (Windows):
   ```powershell
   $env:PATH += ";C:\path\to\specrew\scripts"
   ```

   **Add to PATH** (Linux/Mac):
   ```bash
   export PATH="$PATH:/path/to/specrew/scripts"
   ```

3. **Bootstrap Project**:
   ```powershell
   cd /path/to/your/project
   specrew-init.ps1  # Note: .ps1 extension required for clone-and-PATH
   ```

**Note**: Both installation methods coexist. Clone-and-PATH users can continue using this workflow; PSGallery module installation is optional.

---

## Next Steps

After bootstrapping your project with `specrew init`:

1. **Read the Dashboard Guide**: See `docs/dashboard-guide.md` in the module installation directory (or on GitHub)
2. **Explore Spec Kit Templates**: Review `.specify/templates/` to understand specification structure
3. **Configure Squad Agents**: Edit `.squad/agents/copilot.md` to customize AI agent behavior
4. **Start Your First Feature**: Run `specrew start` and describe what you want to build

---

## Support and Feedback

- **Documentation**: [GitHub Repository](https://github.com/alonf/specrew)
- **Issues**: [GitHub Issues](https://github.com/alonf/specrew/issues)
- **Discussions**: [GitHub Discussions](https://github.com/alonf/specrew/discussions)
- **Maintainer**: Alon Fliess

---

## Version History

- **v0.18.0** (2026-05-16): Module packaging, bundled init/update flow, and manual-gated publish workflow are ready; first live PSGallery publish is still pending maintainer follow-up
- **Earlier versions**: Available via clone-and-PATH only (no PSGallery distribution)

---

**You're all set!** Run `specrew start` in your project directory and begin building with specification-driven AI workflows.
