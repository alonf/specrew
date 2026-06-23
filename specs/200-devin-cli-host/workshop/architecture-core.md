# Architecture Core — Feature 200

**Decision**: Preserve and complete the existing modular host-package architecture.

```text
                   Installed host packages
                   hosts/*/host.psd1
                            |
             +--------------+--------------+
             |                             |
             v                             v
   Runtime discovery authority      Build-time derivation
   hosts/_registry.ps1              host FileList generator
             |                             |
             v                             v
   +----------------------+       Specrew.psd1 host entries
   | Generic consumers    |       + parity enforcement
   | validation           |
   | host selection       |
   | coordinator routing  |
   | hook deployment      |
   | handler dispatch     |
   +----------------------+
             |
             v
       Per-host handlers

Forbidden:
  generic consumer -> independent hardcoded host catalog
  shared core      -> Devin-specific branch or literal
```

## Binding Decisions

- `hosts/_registry.ps1` is the single runtime discovery authority.
- Core consumers query the registry for registered hosts, status, capabilities,
  coordinator eligibility, paths, and handler dispatch.
- No core consumer maintains an independent host list.
- Build-time packaging derives host entries from the same package folders and
  parity-checks the generated artifact.
- `hosts/devin/` owns all Devin-specific behavior.
- Shared edits only complete generic abstractions.
- Transcript handover uses an existing event-payload/parser contract or degrades.
- `scripts/internal/bootstrap/ConversationCaptureAccessor.ps1` is unchanged.
- New transcript parser shapes remain deferred to Slice B after Feature 197.

## Smallest Architectural Proof

Add Devin through its package folder while retiring the three validation exceptions and
two coordinator exceptions, generating package entries, and passing a permanent purity
assertion with a smaller firewall allow-list.
