# Component Design — Feature 200

**Decision**: Reuse existing components and add only the minimum generic mechanisms.

```text
Existing runtime components

hosts/*/host.psd1
        |
        v
hosts/_registry.ps1 --------------------+
        |                               |
        v                               v
3 existing validation callsites   existing coordinator/config code
  direct registry validation        + CanCoordinate consumption

Existing build/proof components

hosts/* --> existing generation flow --> generated host FileList entries
                                         |
                                         v
                                existing parity enforcement

existing host-coupling firewall
        |
        +--> smaller allow-list
        +--> host-addition purity assertion

New host package

hosts/devin/
  host.psd1
  handlers.ps1
  coordinator-rules.psd1
```

## Existing Components Modified

- `hosts/_registry.ps1` remains the runtime catalog and exposes coordinator-capable hosts.
- Existing manifest validation recognizes `CanCoordinate`.
- The three existing validation callsites query the registry directly.
- Existing coordinator-selection and iteration-config writing logic becomes registry-driven.
- Existing generation and FileList parity machinery gains host-package derivation.
- The existing coupling firewall gains the purity invariant and loses five exceptions.

## New Generic Mechanisms

- Deterministic host-package FileList derivation.
- `CanCoordinate` manifest capability and registry query.
- Registry-driven iteration-config host entry generation/migration.
- Permanent host-addition purity assertion.

These mechanisms should normally be implemented within the existing owning scripts and tests,
not as speculative new modules.

## New Devin Components

- `host.psd1` — identity, capabilities, paths, hooks, status, and tested-build metadata.
- `handlers.ps1` — the five existing host-contract handlers.
- `coordinator-rules.psd1` — declarative coordinator rules, which may be empty.

Transcript normalization is conditional. It may exist inside `hosts/devin/` only when the
spike proves a legitimate existing or generic declared invocation seam and an output shape
already supported by the unchanged parser. Otherwise it is deferred with Slice B.
