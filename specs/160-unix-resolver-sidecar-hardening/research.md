# Research: Unix Resolver Sidecar Hardening Investigations

**Feature**: `160-unix-resolver-sidecar-hardening`
**Date**: 2026-06-03

## Decisions

### Prefer Real Unix/macOS Evidence, Then Deterministic Fixture Fallback

**Decision**: Resolver path behavior should be proven on real Unix/macOS
PowerShell first when available. If that environment is not available, a
deterministic cross-platform fixture may stand in only when it proves the same
separator semantics that the suspected Unix/macOS failure depends on.

**Rationale**: The suspected resolver bug is platform-specific. Real platform
evidence is strongest, but a deterministic fixture can still prove whether an
embedded backslash is interpreted as a separator or literal path text.

**Alternatives Considered**:

- Fix path construction immediately: rejected because the feature explicitly
  forbids blind-fixing shipped behavior.
- Require macOS-only proof: rejected because it could block useful deterministic
  evidence in a Windows-hosted development session.

### Prefer Direct Deploy-Logic Fixture for Managed Refresh

**Decision**: Start with direct deploy-logic fixtures against host runtime
handlers and `deploy-squad-runtime.ps1`; escalate to broader init/update/start
fixtures only if direct tests cannot prove the marker behavior.

**Rationale**: The suspected failure is marker creation/read semantics. Direct
fixtures isolate that contract, run quickly, and avoid unrelated lifecycle side
effects.

**Alternatives Considered**:

- Full init/update/start from the start: rejected as broader and more brittle
  for the first proof.
- Unit-test private helper functions only: rejected because the symptom is
  observable deploy/refresh behavior, not only helper return values.

### Treat Marker Semantics as Authoritative Until Proven Otherwise

**Decision**: `.specrew-managed` sidecars and inline `Specrew-managed` markers
remain the authority for safe overwrite decisions unless the investigation
proves the current contract is wrong or inconsistently implemented.

**Rationale**: Preserving user edits is a safety feature. Any change that makes
more files refresh from canonical must be backed by a fixture proving those
files were intended to be managed.

## Source Surfaces Reviewed for Planning

- `Specrew.psm1` sets `SPECREW_MODULE_PATH`, maps exported commands, and
  invokes scripts from module-root-relative paths.
- `scripts/specrew.ps1` contains Unix start redispatch logic that imports the
  local manifest by path to avoid stale installed module resolution.
- `hosts/_team-canonical.ps1` defines `Test-SpecrewManagedFile` and
  `Write-SpecrewManagedSidecar`.
- `hosts/copilot/handlers.ps1` deploys `.squad/agents/<role>/charter.md` and
  writes a sidecar marker.
- `hosts/claude/handlers.ps1`, `hosts/codex/handlers.ps1`,
  `hosts/cursor/handlers.ps1`, and `hosts/antigravity/handlers.ps1` deploy
  host-native files with inline `Specrew-managed` markers.
- `extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1` deploys legacy
  Squad runtime surfaces and slash-command skills, including `.specrew-managed`
  skill directory markers.

## Open Research Questions for Implementation

- Which exact resolver path expression, if any, treats embedded backslashes as
  literal characters on Unix/macOS PowerShell?
- Does the direct sidecar fixture reproduce the preserve notice for a file that
  should have had a managed marker?
- Are deployed mirrors diverging from source behavior, or is the observed notice
  expected for user-owned charters?
