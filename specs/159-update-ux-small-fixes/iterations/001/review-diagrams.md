# Review Diagrams: Iteration 001

**Schema**: v1
**Feature**: 159-update-ux-small-fixes

## Downgrade Guard Flow

```mermaid
flowchart TD
    A[specrew update invoked] --> B[Resolve project and read config]
    B --> C[Read running Specrew source version]
    C --> D{Info mode?}
    D -- yes --> I[Continue read-only info flow]
    D -- no --> E{Project specrew_version present and parseable?}
    E -- absent --> H[Continue existing mutating behavior]
    E -- unparsable --> F[Refuse before mutation]
    E -- parseable --> G{Running version older?}
    G -- yes --> F
    G -- no --> H
    F --> J[Print Update-Module and SPECREW_MODULE_PATH remediation]
```

## Review Notes

- The guard is intentionally before validation probes, deployment scripts, template refresh, installs, and config writes.
- No new architecture diagram was required beyond the existing contract flow.
