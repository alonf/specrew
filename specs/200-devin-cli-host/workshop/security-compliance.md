# Security and Compliance — Feature 200

**Decision**: Reuse the existing cross-host security model.

```text
User / Specrew
      |
      | abstract launch permissions
      v
Devin host handler
      |
      | auto | smart | dangerous
      v
Devin CLI --------------------------> provider authentication/service
      |
      +-- project-local tool access
      +-- .devin/hooks.v1.json
      +-- optional bounded export
      |
      v
Shared Specrew dispatcher
      |
      +-- validated project paths
      +-- managed configuration entries
      +-- bounded handover evidence
```

## Existing Controls Reused

- Host-local translation from abstract Specrew permission intent.
- Hook deployment merges Specrew-owned entries and preserves user configuration.
- Instruction deployment replaces only the delimited managed section.
- Crew-runtime deployment overwrites only marked Specrew-managed files.
- Shared dispatcher validates project/runtime paths and bounds captured content.
- CI and real-host tests receive credentials through secret stores.

## Devin-Specific Verification

- Normal launch maps to `auto`.
- Autopilot maps to `smart`.
- Allow-all maps to `dangerous` and takes precedence when combined with autopilot.
- `.devin/hooks.v1.json` merge/remove behavior preserves user-owned entries.
- Tests target pinned build `2026.7.23 (3bd47f77)`.

## Sensitive Transcript/Export Handling

- Treat exports and hook payloads as sensitive local conversation data.
- Do not persist credentials or complete conversations in CI artifacts.
- Keep capture bounded.
- Use controlled runtime paths and cleanup for temporary exports.
- Report structural drift without publishing conversation content.

Devin owns service authentication. Feature 200 adds no new compliance regime.
