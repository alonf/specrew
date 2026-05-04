---
name: "upstream-blocker-documentation"
description: "How to document known upstream blockers in user-facing guides with verification steps and actionable recovery paths"
domain: "documentation, user-guidance, error-handling"
confidence: "high"
source: "earned (getting-started docs revision revealed pattern for communicating Spec Kit asset dependency blocker)"
tools: []
---

## Context

When an external dependency (upstream library, CLI, or service) has a known issue that blocks user workflows, user-facing documentation must guide users through:

1. **Awareness**: What the blocker is and when they'll hit it
2. **Verification**: How to confirm they've hit the specific issue (not a different error)
3. **Recovery**: Immediate workarounds (downgrade, retry in different environment) and future path (monitor upstream issue)

Without this structure, users fail mid-workflow with cryptic errors and no recovery guidance.

## Patterns

### 1. **Tier-1 Blocker Placement in Prerequisites**

Place known blockers **upfront in the Prerequisites section**, not buried in Known Limitations. Users need to know *before* they start, not fail mid-bootstrap.

**Example from docs/getting-started.md**:
```markdown
- **Spec Kit CLI** (installed via `uv`): Must be operational in your environment. 
  ⚠️ **Known blocker**: Spec Kit CLI may fail with `No matching release asset found for copilot` 
  due to a copilot asset dependency issue. If this occurs, see Known Limitations below.
```

### 2. **Verification Step** (confirm vs. different error)

Provide a specific command that reproduces the blocker. Users can confirm they hit *this* issue, not a different failure mode.

**Example**:
```powershell
# User runs this to check if they hit the asset blocker:
specify init --here --ai copilot --script ps --ignore-agent-tools --force
```

If they see `No matching release asset found for copilot`, it's this blocker. If they see something else, they have a different issue.

### 3. **Immediate Workaround** (pinned version or alternate environment)

Provide a workaround users can apply *now*, not "wait for upstream fix":

**Example**:
```powershell
# Downgrade to known-working version:
uv tool install --upgrade "specify-cli==0.7.3"
pwsh -File C:\Dev\Specrew\scripts\specrew-init.ps1 -ProjectPath . -Force
```

Or: "Try running in Windows Terminal instead of PowerShell 5.x" (environment change)

### 4. **Future Path** (upstream monitoring)

Point users to the upstream repo/issue tracker so they know when the blocker is fixed:

**Example**:
```markdown
2. **Recommended next step**: Check the [Spec Kit repository](https://github.com/github/spec-kit) 
for release notes. If the issue persists in the latest version:
   - Use an earlier version of Spec Kit if available (e.g., 0.7.3 in the CI environment)
   - Follow the Spec Kit issue tracker for availability updates
```

### 5. **Document in Named Section** (not generic "Troubleshooting")

Create a dedicated section for each tier-1 blocker with consistent structure:

```markdown
#### Blocker: {Name of Blocker}

**Current Status (Version X.Y.Z)**: {What goes wrong}

```
{Example error message}
```

**Impact**: {What users cannot do without resolution}

**How to resolve this**:
1. {Verification command}
2. {Immediate workaround}
3. {Future path / upstream monitoring}
```

## Examples

- **docs/getting-started.md**: "Blocker: Spec Kit CLI Asset Dependency Issue" section documents the `No matching release asset found for copilot` error with verification command, workaround (downgrade to 0.7.3), and upstream link
- **docs/getting-started.md**: "Environment-Specific Blocker: Spec Kit CLI Encoding (Windows Only)" section documents Unicode encoding error with environment retry guidance and manual init workaround

## Anti-Patterns

❌ **Bury blockers in Known Limitations**: Users won't see them until they fail mid-workflow  
❌ **Omit verification step**: Users can't confirm they hit *this* blocker vs. a different error  
❌ **No immediate workaround**: Users are stuck waiting for upstream fix  
❌ **No upstream link**: Users don't know how to monitor for a fix  
❌ **Generic error message in docs**: Doesn't help users recognize the specific blocker  
❌ **"Try clearing cache / reinstalling" workaround without pinning version**: Not actionable; may not actually help  

## Related Skills

- `powershell-cli-contract-review`: Reviewing CLI contracts for error cases
- `bootstrap-cli-probes`: Testing CLI health and behavior in different environments
