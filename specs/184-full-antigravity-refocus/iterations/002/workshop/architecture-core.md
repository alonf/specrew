# Architecture Core Lens: Iteration 002

**Depth**: light  
**Confirmation**: human-confirmed / lens-question

## Decision

Persistent host instructions are a host-manifest capability, not an
Antigravity-specific behavior. The architecture should read each supported
host's declared `InstructionsFile`, deploy a Specrew-owned section during
`specrew init`, and reuse or share the bootstrap coordinator wording so the
durable file and one-turn bootstrap cannot drift.

The maintainer confirmed upfront per-host deployment is safer than waiting for a
future startup-hook migration path, because a newly installed host should still
inherit durable Specrew governance before its first raw session.

## Diagram

```text
specrew init
    |
    v
Host manifest registry
    |
    +--> host.InstructionsFile
    |
    v
Persistent instruction deployer
    |
    +--> merge Specrew-owned section
    |       preserve user content
    |
    v
AGENTS.md / host equivalent

Bootstrap prompt builder
    |
    +--> same coordinator + anti-raw-workflow guard
```

## Boundaries

- Shared code consumes manifest data.
- Host-specific binaries or names remain in host manifests/handlers/tests, not
  generic shared core.
- Feature-closeout and release remain outside iteration 002.
