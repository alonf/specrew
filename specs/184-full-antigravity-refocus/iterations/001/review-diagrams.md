# Review Diagrams: F-184 Iteration 001

## Antigravity Refocus Flow

```mermaid
flowchart TD
    A[Antigravity agy turn] --> B[.agents/hooks.json PreInvocation]
    B --> C[per-machine specrew-hook-launch.ps1]
    C --> D[project specrew-hook-dispatcher.ps1]
    D --> E[HostEventAdapter]
    E --> F[SessionStateAccessor]
    F --> G{Boundary changed?}
    G -- no --> H[No injectSteps]
    G -- yes --> I[Test-B3ShouldInject + dedupe/breaker]
    I --> J[injectSteps refocus payload]
    A --> K[Stop hook]
    K --> L[specrew-handover-provider.ps1]
    L --> M[.specrew/handover/session-handover.md]
```

## T008 Module-Path Repair

```mermaid
flowchart LR
    A[specrew hooks install with SPECREW_MODULE_PATH] --> B[deploy-refocus-hooks.ps1]
    B --> C[encoded Antigravity launcher command]
    C --> D[-ModulePath C:/Dev/183-stability-quality-bundle]
    D --> E[specrew-hook-launch.ps1]
    E --> F[exports env:SPECREW_MODULE_PATH]
    F --> G[project dispatcher/provider loads dev tree]
```

## Evidence Chain

```mermaid
flowchart TD
    A[Spec FR-001..FR-010] --> B[Plan T001..T008]
    B --> C[Runtime and deploy implementation]
    C --> D[Automated tests]
    C --> E[Manual agy run]
    D --> F[coverage-evidence.md]
    E --> G[real-host-antigravity-evidence.md]
    F --> H[review.md]
    G --> H
    H --> I[Human review-signoff verdict]
```

## Review Notes

- `PostToolUse` is intentionally not shown as a B3 injection carrier for
  Antigravity. F-184 maps B3 to `PreInvocation` only.
- Release validation is intentionally outside this diagram. The review accepts
  implementation completion, not stable release promotion.
