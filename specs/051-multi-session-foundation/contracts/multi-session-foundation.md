# Contract: Multi-Session Foundation Public Surface

**Feature**: 051-multi-session-foundation
**Stability**: pre-1.0 (Specrew core, PowerShell module)

This contract defines the externally-observable surface F-051 introduces: the CLI commands, the on-disk file formats, and the PowerShell functions other Specrew code depends on. Reviewers verify implementation against these signatures and invariants.

## 1. CLI surface

### `specrew config set session_mode <value>` (FR-001, FR-002)

| Property | Value |
| --- | --- |
| Args | `session_mode` (literal), `<value>` ∈ `{single, multi}` |
| Effect | Writes `session_mode: <value>` to `.specrew/config.yml` |
| Success output | Confirmation line stating new mode |
| Errors | Invalid value → non-zero exit + message listing valid values; file unwritable → error, no partial write |
| Invariant | Idempotent — setting the current value is a no-op success |

### `specrew update [--dry-run] [--force]` (US8 → FR-031 through FR-034)

| Property | Value |
| --- | --- |
| Effect | Writes the installed Specrew module version to `.specrew/config.yml` `specrew_version` (FR-031) |
| `--dry-run` | Prints the proposed version change; modifies nothing (FR-034) |
| `--force` | Proceeds despite a dirty working tree (default: warn + recommend commit/stash) (Edge Case) |
| Source of truth | Installed module version via `Get-Module`/`Get-InstalledModule` (FR-032) |
| Invariant | After a non-dry run, `config.specrew_version` exactly equals the installed module version (SC-005: 0 mismatches) |

### `specrew start` (additive behavior)

`specrew start` gains: session-lock registration (FR-008), concurrent-session collision warning (FR-010), stale-lock auto-clear (FR-011), feature-claim refresh (FR-014), version-drift warning when installed ≠ pinned (FR-033), multi-dev recommendation when signals present and mode is single (FR-021), and brand-new-worktree detection that conditionally skips A/B/C recovery (FR-039 through FR-042).

### Spec-Kit upgrade (US7 → FR-025 through FR-030)

A command/automated process that detects the install method (FR-026), selects the upgrade mechanism (FR-027), upgrades to 0.8.18 preserving local `.specify/` customization (FR-028), writes `speckit_version: "0.8.18"` (FR-029), and runs the governance validator to confirm no compatibility warnings (FR-030). On failure: clear error + troubleshooting + leave prior working state intact; checksums validated pre/post (Edge Case).

## 2. On-disk file formats

### `.specrew/active-sessions.yml` (FR-007)

```yaml
sessions:
  - feature_id: "051-multi-session-foundation"
    user: "alon"
    machine_fingerprint: "HOST-alon-<localhash>"
    session_start_time: "2026-05-31T08:30:40Z"
    last_heartbeat_time: "2026-05-31T08:45:00Z"
```

Invariants: atomic writes (write-temp-rename); corrupt file ⇒ treated as empty + recreated with warning; entry per live session; second entry for same `feature_id` ⇒ collision warning.

### `.squad/active-features.yml` (FR-012)

```yaml
claims:
  - feature_id: "051-multi-session-foundation"
    claimed_by: "alon@HOST"
    claim_start_time: "2026-05-31T06:15:03Z"
    last_refresh_time: "2026-05-31T07:41:44Z"
    branch_name: "051-multi-session-foundation"
```

Invariants: one claim per feature; `last_refresh_time` monotonic non-decreasing; removed at feature-closeout-to-main.

### `.squad/identity/session-state.yml` (gitignored, FR-036)

```yaml
session_state_active: true
session_state_boundary: "tasks"
session_state_feature_path: "C:/Dev/Specrew-051/specs/051-multi-session-foundation"
session_state_iteration: null
session_state_auth_commit: "106e21c3..."
session_state_recorded_at: "2026-05-31T07:41:44Z"
```

Invariant (FR-038): no git-tracked file may contain a `session_state_` token; only this gitignored file holds them.

### `.squad/events/lifecycle-events.jsonl` (FR-018)

One JSON object per line; appends are atomic; invalid historical lines are skipped with a warning rather than crashing readers (SC-006).

```json
{"schema":"v1","recorded_at":"2026-06-01T00:00:00Z","event_type":"boundary-sync","payload":{"boundary_type":"plan","feature_ref":"051-multi-session-foundation","iteration_number":"003"}}
```

### `.squad/decisions/iteration-NNN/decisions.md` (FR-017)

Deterministic markdown mirrors generated from `.squad/decisions.md` entries that carry matching `Iteration Number`, `Affected Iteration`, or `Iteration` metadata. Boundary sync invokes the splitter only when `session_mode: multi`; legacy `.squad/decisions.md` remains readable for backwards compatibility.

### `Specrew.psd1` FileList ordering (FR-019)

The `FileList` array is alphabetically sorted on every boundary-sync write so concurrent branches conflict only on true duplicates, not ordering (SC-006).

## 3. PowerShell function surface (exported / internal)

| Symbol | Signature (intent) | Purpose | Errors |
| --- | --- | --- | --- |
| `Set-SessionMode` | `(value: 'single' or 'multi') -> void` | Persist session_mode to config (FR-001/002) | Throws on invalid value |
| `Get-FileClassification` | `() -> FileClassificationRule[]` | Return the static rule set (FR-004) | never throws |
| `Update-GitignoreForSession` | `(projectPath) -> void` | Merge per-session patterns into .gitignore (FR-005) | preserves existing entries/comments |
| `Remove-TrackedPerSessionFiles` | `(projectPath) -> string[]` | `git rm --cached` per-session paths (FR-006) | returns paths removed; no working-tree deletion |
| `Register-SessionLock` / `Remove-SessionLock` | `(feature_id,...) -> void` | Add/remove active-sessions entry (FR-008/009) | atomic write |
| `Test-SessionCollision` | `(feature_id) -> SessionLockEntry?` | Detect concurrent session (FR-010) | returns colliding entry or null |
| `Clear-StaleSessionLocks` | `(thresholdHours=24) -> int` | Auto-clear stale locks (FR-011) | returns count cleared |
| `Add-FeatureClaim` / `Update-FeatureClaim` / `Remove-FeatureClaim` | `(feature_id,...) -> void` | Claim lifecycle (FR-013/014/016) | atomic write |
| `Split-SpecrewDecisionsByIteration` | `(projectPath) -> {written_count, iteration_numbers}` | Mirror legacy decisions into per-iteration files (FR-017) | missing ledger -> no-op |
| `Add-SpecrewLifecycleEvent` / `Read-SpecrewJsonLines` | `(projectPath,event,payload)` / `(path)` | Append/read JSON Lines lifecycle events (FR-018) | invalid lines skipped with warning |
| `Sort-SpecrewManifestFileList` | `(manifestPath) -> {changed, entry_count}` | Alphabetically sort manifest FileList while preserving membership (FR-019) | throws if FileList shape is unsupported |
| `Get-SpecrewMultiDeveloperSignals` | `(projectPath) -> MultiDevSignal` | Compute aggregate multi-dev signals (FR-020) | degrades to zero counts when git metadata is unavailable |
| `Get-SpecrewMultiDeveloperRecommendation` | `(projectPath) -> string?` | Return Welcome Orientation recommendation when unsuppressed (FR-021/024) | returns null when no signal or session_mode multi |
| `Split-IdentitySessionState` | `(projectPath) -> void` | Migrate now.md → session-state.yml (FR-035/037) | idempotent |
| `Test-TrackedSessionStateLeak` | `() -> string[]` | Grep tracked files for session_state_ (FR-038) | returns offending files |
| `Test-BrandNewWorktree` | `() -> bool` | Brand-new detection heuristics (FR-039) | logs signals to session-start.log |
| `Get-MachineFingerprint` | `() -> string` | Local hostname+user fingerprint (FR-043) | local-only; never networked |

## Invariants (cross-cutting)

- **Atomicity**: every state-file mutation uses write-temp-then-`Move-Item -Force`; no reader ever observes a partial write.
- **Safe-degradation**: any corrupt/missing state file degrades to empty + logged warning; never crashes `specrew start`.
- **Privacy**: machine fingerprints are derived from local identifiers only and are never transmitted over the network (FR-043).
- **Backward compatibility**: with `session_mode: single` (the default), F-051 behavior is inert — existing single-session projects are unaffected.
- **Boundary truth**: claim `last_refresh_time` advances at every boundary; no boundary crossing leaves a claim stale (SC-008).
