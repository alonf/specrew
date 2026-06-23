# Requirements and NFRs — Feature 200

## Priority P0

### Safety and Ownership

- `scripts/internal/bootstrap/ConversationCaptureAccessor.ps1` is unchanged.
- Shared core contains no Devin-specific branch.
- Managed deployment preserves user-owned hook, instruction, and agent content.

### Clean Extensibility

- `hosts/_registry.ps1` is the only runtime host catalog.
- Production code has no independent hardcoded host list.
- An ordinary future host requires its package folder plus machine-generated output.
- The five in-scope production firewall exceptions are removed; no new exception is added.

### Compatibility

- The existing five hosts remain green across registry, launch, hooks, instructions,
  Crew-runtime, packaging, and firewall coverage.
- The unchanged transcript parser and its existing goldens remain green.
- `specrew update` discovers newly shipped supported/coordinator-capable hosts through the
  registry and idempotently migrates the managed `agents:` block while preserving project
  choices.
- Feature 200 migration handles an absent block, the legacy three-host block, a partial
  block, and the registry-derived block in one update run.
- Update-time hook and instruction refresh remains generic and registry-driven.
- Independent emergency/fallback host catalogs are forbidden because they omit future hosts.

### Honest Handover

- The real Devin Stop-payload spike runs before handover implementation.
- Outcome 1 or 2 requires real-host handover evidence.
- Outcome 3 reports degraded handover explicitly and defers Slice B.

## Priority P1

### Determinism

- Re-running host-package FileList generation produces no diff.
- Parity checks detect missing, stale, or manually divergent host entries.
- Iteration-config migration is idempotent and preserves unrelated settings.

### Host Correctness

- Devin launch, flags, detection, hooks, instructions, Crew deployment, SessionStart, and
  boundary Stop behavior are tested against pinned build `2026.7.23 (3bd47f77)`.

### Maintainability

- Existing owning components absorb generic changes where practical.
- New manifest capabilities are documented and validated.
- No speculative module is introduced without actual variation or reuse.

## Volatile Dependency Monitoring

Proposal 187 remains unimplemented. Proposal 194 currently describes a hardcoded four-host
nightly transcript canary and omits Devin.

Feature 200 must update Proposal 194, or its implementation if it lands first, so Devin's
version, hooks, Stop payload, export/ATIF surface, and handover behavior are monitored.
Future monitor selection must derive hosts and monitor metadata from registry/manifests
rather than adding another hardcoded host roster.

Implementing the complete daily monitor is outside Feature 200.

General convergence and validation across arbitrary historical Specrew versions is also
outside Feature 200. It requires a separate proposal and PR; Feature 200 records the
follow-up but does not author or implement it.
