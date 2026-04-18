# Specrew Spec Kit Extension

## Overview

This is the **Spec Kit extension** component of Specrew. It provides governance artifacts, templates, and validation scripts that enforce spec authority and traceability within the Spec Kit lifecycle.

## Structure

```
hooks/          # Lifecycle hooks for Spec Kit workflows
templates/      # Governance artifact templates (constitution, iteration config, etc.)
scripts/        # Validation and scaffolding PowerShell scripts
extension.yml   # Extension configuration
```

## Integration

This extension integrates with Spec Kit >= 0.7.3 using documented extension surfaces:
- **Hooks**: Lifecycle hooks that fire during specification workflows
- **Templates**: Markdown templates for governance artifacts
- **Scripts**: PowerShell automation for validation and scaffolding

## Development Status

**Phase**: Foundation (Iteration 0)  
**Status**: Skeleton scaffolded; implementation pending

## Extension Configuration

The extension is configured via `extension.yml`. Configuration details will be finalized during iteration planning.

## License

TBD
