# Review Diagrams: Iteration 001

**Schema**: v1
**Diagram Format**: mermaid

## Hook Delivery Flow

```mermaid
flowchart TD
  Host[Hook-capable host] --> Manifest[hosts/<kind>/host.psd1 RefocusHookBindings]
  Manifest --> Deploy[deploy-refocus-hooks.ps1]
  Deploy --> Config[Host hook config]
  Config --> Dispatcher[specrew-hook-dispatcher.ps1]
  Dispatcher --> Providers[bootstrap / refocus / handover providers]
  Providers --> Output[Host-shaped governed output]
  Output --> Agent[Agent context or decision]
```

## Antigravity Bounded Support

```mermaid
sequenceDiagram
  participant A as Antigravity
  participant H as .agents/hooks.json
  participant L as per-machine launcher
  participant D as Specrew dispatcher
  participant S as Specrew state
  A->>H: Fire PreInvocation or Stop
  H->>L: Encoded PowerShell command
  L->>D: -HostKind antigravity -Event <verified>
  D->>S: Bootstrap journal / handover update
  D-->>A: injectSteps or allow decision
```

## Review Evidence Flow

```mermaid
flowchart LR
  Commit[b79b59d8] --> Tests[Focused post-commit tests]
  Tests --> Coverage[coverage-evidence.md]
  Commit --> Quality[quality/*.md]
  Coverage --> Review[review.md + review-145.md]
  Quality --> Review
  Review --> Human[Human review-signoff verdict]
```

## Omissions

- Security surface artifact omitted because no security-focused team role and no
  security-keyword task title required a separate security file; security-relevant
  hook input/config behavior is covered in review.md and coverage-evidence.md.
