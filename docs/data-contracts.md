# Data Contracts

## Schema evolution

- `v0` is implicit legacy state: the file omits a top-level `schema` marker.
- `v1` is the explicit baseline contract: state writers may emit `schema: v1` (YAML/frontmatter) or `"schema": "v1"` (JSON).
- `v2` is the current explicit contract introduced by F-039 (Launch-Mode Boundary Enforcement, v0.25.0). State writers must emit `schema: v2` when the artifact carries F-039's `boundary_enforcement` section.
- Future schema upgrades must preserve reader tolerance for older fixtures and add a new current-version fixture under `tests/fixtures/legacy-versions/`.

## `.specrew/start-context.json` field inventory (schema v2)

The start-context.json artifact written by `specrew start` has grown additive fields across F-039 (v2 boundary_enforcement section) and F-040 (v0.26.0 multi-host launch path). All fields below are part of schema v2:

| Field | Type | Source | Notes |
|---|---|---|---|
| `schema` | string | Set by writer | `"v2"` since F-039 |
| `mode` | string | Set by writer | `intake` / `feature` / `resume` |
| `feature_request` | string | --feature-request flag | nullable |
| `feature_path` | string | resolved path | nullable |
| `agent` | string | --agent flag | Crew runtime agent label (default `Squad`); required for Copilot --agent surface; non-Squad hosts ignore |
| `approval_mode` | string | runtime computed | `allow-all` / `prompt-approvals` |
| `launch_mode` | string | --new-window/--same-window | `same-window` (default) / `new-window` / `none` |
| `copilot_autopilot` | bool | --autopilot flag | Backwards-compat field name; reflects Specrew's --autonomous lifecycle-gate posture (historical naming) |
| `boundary_enforcement` | object | F-039 schema v2 | Per-boundary verdict-integrity state; see the verdict-integrity sub-schema below |
| `selected_host` | string | **F-040 (v0.26.0)** | `copilot` / `claude` / `cursor` / `codex` / `antigravity`; reflects the active --host kind (default copilot). Cursor added in F-050; Antigravity graduated to supported in v0.27.0 (F-044). |
| `available_hosts` | object | **F-040 (v0.26.0)** | Map of host kind → bool (PATH probe result) |
| `crew_runtime_status` | string | **F-040 (v0.26.0)** | `squad-runtime` (Copilot+Squad) or `bootstrap_only` (non-Copilot host without per-host Crew runtime deployed yet) |
| `host_resolution` | string | **F-043 (v0.27.0)** | How the active host was resolved: `flag` / `last-selected` / `first-run-prompt` / `auto-single-available`. Shipped — not planned. |
| `delegated_routing` / `delegated_routing_evidence` | object | runtime computed | Delegated-agent routing plan (orthogonal to --host launch selection) |
| `squad_model_overrides` | object | runtime computed | F-019 `Set-SquadModelOverrides` snapshot (Copilot host's per-role model selection) |
| `prompt_path`, `summary_path` | string | runtime computed | Resolved paths to companion artifacts |
| `generated_at_utc` | string | runtime computed | ISO8601 timestamp |
| `session_state` | object | runtime computed | Last-known boundary + feature + iteration state from `.squad/identity/now.md` |
| `recovery_session` | object | runtime computed | Active recovery-mode metadata (nullable) |

**Field additivity contract**: F-040's `selected_host`/`available_hosts`/`crew_runtime_status` were added without bumping schema beyond v2 because they are purely additive — pre-F-040 readers that don't know about these fields keep working (reader tolerance per Proposal 059). New readers should treat them as optional with defaults: `selected_host` defaults to `copilot`, `available_hosts` defaults to `null`, `crew_runtime_status` defaults to `squad-runtime`.

### `boundary_enforcement` verdict-integrity sub-schema

The `boundary_enforcement` object carries the auditable record of which boundaries a human has authorized. It is the durable source the resume bootstrap consults: a committed boundary is **not** an authorized one, so a committed-but-unauthorized boundary surfaces `=== AWAITING YOUR VERDICT ===` on the next session's resume — the agent must not auto-advance on a bare "continue", one approval advances at most one boundary, and the recorded approver is never fabricated.

| Field | Type | Notes |
|---|---|---|
| `enabled` | bool | Whether boundary enforcement is active for this project |
| `last_authorized_boundary` | string (canonical boundary) | The highest boundary a human has actually authorized; advanced ONLY by a captured human verdict |
| `pending_next_boundary` | string (canonical boundary) / null | The boundary an advance has been requested for but not yet authorized; `null` once authorized |
| `policy_classes` | object | Per-boundary policy-class map (project-scoped) |
| `verdict_history` | array | Append-only audit of authorized advances (see entry shape below) |
| `bypass_history` | array | Append-only audit of recorded bypasses (see entry shape below) |

Each `verdict_history[]` entry is an object with: `from_boundary`, `to_boundary` (both canonical boundary types), `verdict_text`, `authorizing_human` (the recorded approver, never fabricated), `recorded_at` (ISO8601), `auth_commit_hash`, and `evidence_source` (how the verdict was captured; defaults to `unspecified`).

Each `bypass_history[]` entry is an object with: `session_id`, `reason` (must be non-blank), `recorded_at`, `boundary` (canonical), `launch_mode`, `agent_response_snippet` (200 chars or fewer), and `auth_commit_hash`.

## Writer contract

Writers must emit an explicit schema marker for Specrew state artifacts. `.specrew/start-context.json` carries `schema: v2` whenever it includes the F-039 `boundary_enforcement` section — which `specrew start` always writes today (see the schema-v2 field inventory above). The following artifacts carry the `v1` baseline marker:

- `.specrew/config.yml`
- `.specrew/last-validator-summary.json`
- `.specrew/handover/session-handover.md` (the rolling session handover; `schema: v1` frontmatter — see the handover file contract below)
- `.specify/feature.json`
- `.specify/extensions/specrew-speckit/extension.yml` (`schema` is distinct from `extension.version`)
- `.squad/identity/now.md`

Writers should preserve unrelated existing fields when refreshing an artifact, and must normalize the schema marker to the artifact's current contract version (`v2` for `start-context.json`, `v1` for the others) rather than downgrading it.

## `.specrew/handover/session-handover.md` file contract (schema v1)

The rolling session handover is a single always-latest markdown file overwritten in place at end-of-turn (Claude `Stop`, Codex `Stop`, Copilot `agentStop`, Cursor `stop`, and Antigravity `Stop` when the project `.agents/hooks.json` slice fires) and, on Claude only, mid-turn (`PostToolUse`). The next session's SessionStart or equivalent bootstrap reads it and surfaces a resume reconciliation, so work auto-resumes where it stopped. It is host-agnostic (written by F-174's handover provider regardless of host) and **gitignored** (`.specrew/handover/` — local session-bridge context, never pushed).

It is written **atomically**: content goes to a per-process sidecar, then promotes via `[System.IO.File]::Replace`, which swaps the file and keeps the previous version as `session-handover.md.old` in one call. That `.old` file is the crash backup the reader falls back to if the live file is missing, mid-write, or unparseable.

**Frontmatter** (YAML, `schema: v1`). Always emitted: `schema`, `source`, `from_host`, `recorded_at`, `from_commit`, `active_feature`, `active_boundary`. Emitted only when present (kept quiet outside the intake / verdict window): `last_authorized_boundary`, `last_verdict`, `workshop_done`, `workshop_remaining`.

**Body**: eight fixed `##` sections, always in this order:

1. `## What I just did (last 3-5 turns or last boundary work)`
2. `## Why I'm stopping (the switch trigger)`
3. `## Open questions / pending clarifications`
4. `## Agent's working hypothesis / mental model`
5. `## Recommended next-immediate-step`
6. `## Context the receiving host needs that artifacts don't carry`
7. `## Recent conversation (last few exchanges, hook-captured)`
8. `## Authored boundary packet (captured at stop)`

Ownership splits across the eight: the mechanical sections (1, 2, 5, 6) are refreshed every material stop from the git/filesystem delta; the interpretive sections (3, 4) are agent-authored via `specrew handover author` and preserved across stops within a boundary; section 7 is hook-captured from the transcript tail; section 8 is the verbatim boundary verdict packet captured by the Stop hook (preserved by the clobber guard, never refreshed every stop).

**Placeholder convention**: a section whose body starts with `(placeholder` is **not** agent-authored — the hook writes that marker when the agent has not authored an interpretive section for the current boundary, so the next session knows to fall back to the artifact-derived orientation rather than treating the placeholder as real context.

## Reader contract

- JSON state readers must use `ConvertFrom-Json -AsHashtable`.
- Access optional fields through hashtable indexers (`$state['field']`) or `.Contains(...)` checks.
- Missing top-level `schema` means `v0`; emit `schema-implied-v0` on the debug stream when that fallback is taken.
- Unsupported explicit schemas must fail fast instead of silently rewriting unknown formats.
- Missing files and malformed optional state should return `$null` where the caller expects an optional artifact, not a `PropertyNotFoundException`.
- The canonical schema-version extraction helper is `Get-SpecrewStateSchemaVersion` in `extensions/specrew-speckit/scripts/shared-governance.ps1`. New readers must call it rather than re-implementing the v0/v1 detection.

## Fixture maintenance

When a feature changes any state-file schema or reader behavior:

1. Preserve older fixture directories as historical evidence.
2. Add or refresh the current Specrew version fixture in `tests/fixtures/legacy-versions/<current-version>/`.
3. Include only representative state artifacts: hand-curated when drift matters, generated when the format is deterministic, snapshot-based when the real lifecycle output is the contract.
4. Extend both Windows and Linux validation to exercise the new fixture.

- The regression contract that exercises the corpus is `tests/integration/Test-LegacyStateReaders.Tests.ps1`. Any new fixture file or reader migration must be reflected there.
- See the fixture coverage matrix in `specs/023-legacy-state-read-tolerance/checklists/state-reader-audit.md` for the current per-version presence/absence rationale.

## Cross-platform rules

- Run regression scripts with `pwsh -NoProfile -File`.
- Do not assume Windows path separators; normalize with `Join-Path` and repo-relative paths.
- Write UTF-8 artifacts without relying on platform-specific defaults.
- Keep fixture assertions insensitive to line-ending differences unless line endings are the contract under test.
