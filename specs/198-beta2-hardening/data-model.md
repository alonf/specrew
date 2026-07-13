# Data Model: 0.40.0-beta2 Hardening Bundle

**Feature**: 198-beta2-hardening
**Date**: 2026-07-10
**Purpose**: Define the entities, attributes, validation rules, and
relationships for the bundle's data seams. No database is introduced; all
entities are versioned files or structured records in existing stores.

## Entity: DenyListEntry (SelfLeakDenyList)

**Purpose**: one self-fact pattern the firewall prevents from shipping.

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| pattern | string (regex) | yes | compiles as .NET regex | the self-fact matcher |
| class | enum | yes | release-model \| dev-path \| feature-id \| maintainer-id \| registry \| repo-ref \| decision-ref | leak taxonomy |
| reason | string | yes | non-empty | why this is a self-fact |
| source | string | yes | non-empty | field report / proposal ref that added it |
| added | date | yes | ISO date | when the term joined the list |

File-level: `schema_version` (string, required). Consumer-side version
mismatch = fail-open WARN; repo-side is version-locked (I3). Annotation
escape: `specrew-self-ok: <reason>` — HTML comment for `.md`, `#` line
comment for `.ps1`/`.psd1`/`.yml`; same line or the line immediately above
the hit; an escape without reason text is treated as unannotated.

### Lifecycle / Relationships

Created in iteration 001 with the proposal-205 seed; grows one entry per
field-found leak (W6 makes that a one-line fix). Read by SelfLeakLintLane
(repo CI), and in iteration 004 by the gateway advisory, the update heal
surface, and PromptFixtureTest — always the same shipped file.

## Entity: MachineryPathEntry (MachineryPathList) — iteration 003

**Purpose**: one path-granular glob machinery-stripped from BOTH the digest
and the reviewer worktree (S2).

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| glob | string | yes | non-empty path glob | e.g. `.claude/**`, `.github/prompts/**` |
| side | const | yes | always `both` | one list, both strips — divergence impossible by construction |
| reason | string | yes | non-empty | why this is machinery |

### Lifecycle / Relationships

Consumed by DigestIdentity and WorktreeMaterializer. Every change ships a
reviewer-can-still-see-it regression test (FR-012).

## Entity: ReviewerHostCatalogRow (extended) — iteration 002

**Purpose**: per-host harness data; the ONLY harness-data seam.

### Attributes (added)

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| default_timeout_seconds | int | no | > 0 when present | per-host review budget; absent → 600 floor (tolerant reader) |

Shipped values (clarify 2026-07-09): antigravity 900, claude 600; codex +
copilot rows added from consumer-test-project measurements during
iteration 002.

## Entity: ReleaseModelRecord — iteration 004

**Purpose**: the project's release model, recorded once at init, resolved
at feature-closeout (FR-030).

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| release_model | enum | yes | local-only \| push-only \| pr-flow \| beta-stable | drives closeout teaching |
| provenance | enum | yes | recorded \| inferred | ask-once at init, infer as default |

Lives in `.specrew/repository-governance.yml`. Inference: no remote →
local-only; remote without forge config → push-only; forge → pr-flow;
publish target → beta-stable.

## Entity: BoundaryVerdictRecord (extended) — iteration 002

**Purpose**: the authorization truth for one boundary crossing (#2906).

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| boundary | enum | yes | canonical boundary names | the crossing |
| auth_commit_hash | string | yes | git short/long hash | the anchor reversion targets |
| kind | enum | yes | standard \| retroactive | retroactive approvals are recorded distinctly (FR-005) |

`last_authorized_boundary` + `verdict_history` in
`.specrew/start-context.json` stay the single cursor truth.

## Entity: TrackerClaims (parsed, transient) — iteration 002

**Purpose**: the deterministic parse of `state.md` + `tasks-progress.yml`
the honesty check compares against the accepted review record (FR-020).

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| task_statuses | map | yes | canonical enums only (planned/in-progress/done/needs-rework/deferred/blocked) | per-task claim |
| capacity | string | no | `<consumed>/<cap> <unit>` shape | capacity-line claim |
| test_counts | ints | no | non-negative | claimed totals |

Parse failure of any claim → fail-closed (digest stales as today). A
claims comparison is subset-only: any claim increasing beyond the accepted
review verdict + run records → stale.

## Entity: ContainmentRecord — iteration 003

**Purpose**: origin-side durable evidence of an observed reviewer escape
(FR-011).

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| run_id | string | yes | existing run-id scheme | correlation key |
| process / command_line / path | strings | yes | non-empty | what was observed |
| observed_at | timestamp | yes | ISO | when |

Never enters reviewer-visible artifacts (W2-consistent).

## Entity: RunRecord (extended) — iterations 002/003

**Purpose**: existing durable review run evidence under
`.specrew/review/**`, gaining: `independence_source`
(flag \| env \| unverified, FR-023), frozen fire-time tree id +
stale-vs-current label (FR-017), last-reviewed checkpoint identity
(FR-016), and runner-observed verification evidence via the universal
recorded-run runner (FR-015; command-execution facts + OPTIONAL schema-valid
`SpecrewTestResult`; caller-supplied counts FORBIDDEN).

## Entity: RecordedRunEvidence — iteration 003 (T018, FR-015 amended 2026-07-13)

**Purpose**: language/framework-NEUTRAL runner-observed verification evidence for the EXACT
reviewed-tree digest, written by the universal runner `Invoke-ContinuousCoReviewRecordedRun`
under `.specrew/review/test-evidence/<digest>.json` (digest-EXCLUDED runtime state, so recording
never changes the tree it certifies).

**Fields (per recorded run entry)** — DIRECTLY observed only:

- `command`: `{ executable, arguments[], working_directory }` — the reviewer's cheap re-run handle.
- `reviewed_digest_tree_id`: the exact tree the command ran against (record keyed + bound to it).
- `started_at`, `ended_at`, `duration_seconds`.
- `exit_code`, `timed_out` (bool), `command_succeeded` (exit 0 AND not timed out).
- `stdout_meta`, `stderr_meta`: `{ byte_count, sha256, truncated_tail }` — BOUNDED/REDACTED, never raw/full.
- `artifacts[]`: `{ path, sha256, byte_count }` — output-artifact digests.
- `test_result`: OPTIONAL. When the command PRODUCED a schema-valid `SpecrewTestResult` during the run
  (bound to the same digest): `{ result, counts: { passed, failed, skipped }, source: "specrew-test-result" }`.
  Otherwise `counts_available = false` and NO counts are inferred (exit 0 is `command_succeeded`, NOT
  "all tests passed"). A REQUESTED but missing/malformed/stale/schema-invalid result FAILS the run LOUDLY.

**Invariants**: never parse human-readable console output for counts; caller-supplied counts are
FORBIDDEN; rich counts come ONLY from a run-produced schema-valid SpecrewTestResult. Evidence-only —
injection, scheduling, cross-digest collision, and stale-result handling are T019.

## Contract: SpecrewTestResult — iteration 003 (T018, universal result contract)

**Purpose**: the ONE optional, framework-NEUTRAL JSON a downstream command MAY emit so its counts gain
evidence standing, WITHOUT Specrew knowing the framework (Pester/pytest/Jest/Vitest/dotnet test/Maven/
Gradle/Go/Rust/custom). Schema: `contracts/specrew-test-result.schema.json`.

**Shape**:

```json
{ "schema_version": "1.0", "result": "passed|failed|errored|skipped", "counts": { "passed": 42, "failed": 0, "skipped": 3 } }
```

Specrew VALIDATES this against the schema and records it verbatim; an invalid, or requested-but-absent,
result fails LOUDLY (never degrades to a richer pass claim).

## Contract: VerificationPlan + VerificationCommand — iteration 003 (T019, FR-048, amended 2026-07-13)

**Purpose**: the framework-NEUTRAL, ORDERED, provenance-tagged verification plan a downstream
command-plan SUPPLIER produces; the universal T018 runner (`Invoke-ContinuousCoReviewVerificationPlan`)
EXECUTES it in DECLARED order and T019 injects the matching digest+command_id-bound evidence. Neither
T018 nor T019 EVER selects, discovers, or invents a command — they run EXACTLY what the plan declares.
Schema: `contracts/verification-plan.schema.json`. Contract layer: `verification-plan-contract.ps1`
(pure, except a filesystem symlink check in path-safety); executor: `verification-plan-runner.ps1`.

**VerificationPlan fields**:

- `schema_version` (string, "1.0").
- `plan_id` (string, REQUIRED) — stable plan identity.
- `commands` (VerificationCommand[], ORDERED — never sorted). `command_id` values MUST be unique.

**VerificationCommand fields**:

- `command_id` (string, REQUIRED, UNIQUE within the plan) — recorded evidence joins on
  `command_id` + reviewed-tree digest.
- `executable` (string, REQUIRED non-empty) — resolved via PATH; framework-neutral (pytest / cargo /
  dotnet / bash / pwsh / anything).
- `arguments` (string[], default []) — a STRICT string ARRAY. NEVER a single shell string: shell
  behaviour is an explicit interpreter invocation (`pwsh -File …`, `bash -lc …`). A single-string
  `arguments` is REJECTED.
- `working_directory` (string, optional) — repository-RELATIVE + canonical; REJECTED if rooted, if it
  escapes via `..`, or if a symlink/junction resolves outside RepoRoot.
- `timeout_seconds` (int, default 0) — ENGINE-BOUNDED: 0/absent → engine DEFAULT (900s), over the
  engine MAX (3600s) → clamped. A supplier can NEVER request an unlimited run.
- `result_path` (string, optional) — repository-RELATIVE + canonical (same path-safety); where the
  command WRITES its `SpecrewTestResult`.
- `require_result` (bool, default false) — when true the command MUST produce a schema-valid
  `SpecrewTestResult` at `result_path`; an absent/invalid result is a VERIFICATION FAILURE for that
  command (`command_succeeded=false`, reason `required-result-missing-or-invalid`), never a richer
  clean claim. When false, process evidence stays valid with counts unavailable.
- `provenance` (object, REQUIRED) — AUDITABLE, not a bare enum:
  `{ kind (one of project-config | project-detected | profile-selected | provider-gated), source
  (required — the config path / detection signal / profile / provider id), provider (required when
  kind=provider-gated), profile (required when kind=profile-selected) }`.
- `env_refs` (string[], optional) — allowlist of env var NAMES to pass through. NAMES ONLY — a literal
  `env`/`environment` value map is FORBIDDEN (no secret values in a plan or its recorded evidence).
- `label` (string, optional).

**Invariants**: ORDER is preserved and never sorted; provenance kind is one of the four values;
`command_id` is required and unique; `arguments` is a string array; paths are repo-relative and
non-escaping; timeouts are engine-bounded; no secret env values appear. An EMPTY plan (or a plan with
no valid command) is the EXPLICIT `verification-not-configured` state — NEVER a silent success or a
fabricated pass. The executor RECORDS AN EVIDENCE RECORD FOR EVERY ATTEMPTED COMMAND (successes AND
failures, in order): a non-zero exit / timeout / structurally-un-runnable / required-result miss is
recorded with `command_succeeded=false` — never dropped, never promoted to clean; the plan result
exposes `all_succeeded` (false if any command failed, and false when nothing ran). Each record binds to
the reviewed-tree digest AND its `command_id`; env values are redacted (only NAMES recorded). The T019
join validator (`Test-ContinuousCoReviewPlanEvidenceInjectable`) REJECTS evidence that is
digest-mismatched, DUPLICATE (a `command_id` appearing twice), or UNJOINABLE (a `command_id` with no
matching plan command).

## Entity: ReviewIdentitySet — iteration 003 (T019, characterization 2026-07-13)

**Purpose**: the five identities a review run and its findings are bound by, unified so evidence, lineage,
staleness, and the verdict gate cannot disagree. Characterization-only in the current slice (the resolver
`review-identity-contracts.ps1` is PURE + UNWIRED); the runtime wiring is T019 step 6. Full current→target
detail in `iterations/003/research/t019-review-identity-and-artifact-lifecycle.md`.

### Attributes

| Identity | Type | Current key(s) / source | Contract (corrected 2026-07-13) |
| --- | --- | --- | --- |
| baseline | tree-id + commit refs | `baseline_ref` (merge-base/empty-tree today); last-reviewed `reviewed_ref` computed but not threaded | auto-fire DIFF baseline = `baseline_tree_id` (last ACCEPTED reviewed TREE, max `run_id`); git ancestry uses commit refs SEPARATELY; merge-base fallback (FR-016) |
| reviewed digest | tree-id | `reviewed_digest_tree_id` / `reviewed_tree_id` / `tree_id` (three spellings) | FR-017: ONE identity stamped into EVERY run-record surface incl. findings |
| evidence digest | tree-id | `.specrew/review/test-evidence/<digest>.json` `reviewed_digest_tree_id` | DRIFT-002: injectable ONLY when the envelope AND every embedded run/suite digest equal the reviewed digest; full/partial/embedded mismatch is named + refused |
| run lineage | id chain + lease | run-id `yyyyMMddTHHmmssfff-<8hex>`; `baseline_ref`+`reviewed_ref` chain; pending registry `status` | FR-017: DETERMINISTIC lineage id (CANONICALIZED resolved anchor commit + target); ≤1 in-flight per lineage; out-of-order superseded; same-digest authority = atomically-acquired LEASE/generation (only the owner is authoritative; conflicts fail closed; a clean result never erases blocking by timestamp) |
| per-finding identity | tuple | `(source_run_id, finding_id)` + `fingerprint`; no tree/baseline in schema | FAIL CLOSED: `source_run_id` == `run_id` AND reviewed tree + `baseline_tree_id` present; else `valid=false` |

Validation: an empty/unknown digest never matches (fail-closed); digest-mismatch precedence is ABSOLUTE across
every review outcome (a stale result never blocks/decides/authorizes); `launch_review` is never asserted on the
Stop path (the navigator owns firing).

## Entity: StopIntent — iteration 003 (T019 piece 4b, FR-045a, 2026-07-13)

**Purpose**: classify each host Stop as `intermediate` (an operational YIELD while Specrew-OWNED work is in
flight and the agent intends to continue) or `real` (a genuine handoff), so an intermediate yield gets ONE
progress sentence + the marker instead of the five-part material-work packet, while real stops keep the
existing boundary / non-boundary packet rules unchanged. PURE + DETERMINISTIC (`stop-intent-contract.ps1`
`Resolve-ContinuousCoReviewStopIntent`); the Stop hook computes the inputs (the marker in THIS turn's assistant
message, the T019 in-flight registry, the pending-verdict state, message heuristics). NOT a per-host capability
matrix — a host with no background execution never produces an in-flight signal and behaves exactly as before.

### Attributes

| Attribute | Type | Source | Contract |
| --- | --- | --- | --- |
| intermediate signal | bool | `MarkerPresent`+`MarkerFromAssistant` OR `OwnedWorkInFlight` (T019 registry) | intermediate requires ALL of: work started; still running/pending; agent retains ownership + intends to continue; no user decision/auth/external/review needed |
| marker | assistant-only | `<!-- SPECREW-STOP-INTENT: intermediate -->` in the assistant's CURRENT turn | a portable FALLBACK, never sole authority; a marker from USER content is not authority |
| contradiction | bool | `LifecycleBoundaryPending` / `RuntimeWorkTerminalOrAbsent` / `MessageRequestsUserAction` / `AgentBlockedOrHandingBack` / marker-from-user | ANY forces `real` + normal enforcement, overriding the marker |
| result | { intent; enforce_packet; reason } | the classifier | `intermediate` → `enforce_packet=$false` (one progress sentence + marker; no packet, no verdict-boundary marker); `real` → `enforce_packet=$true` (existing rules) |

Validation: "needs nothing from the user" is NOT sufficient for intermediate (final completion also needs
nothing, yet is `real`); the defining condition is OWNED WORK REMAINS ACTIVE + intent to continue. On ANY
contradiction, classify `real`. Repeated intermediate messages are rate-limited to one per unchanged in-flight
work generation (a runtime-wiring concern, not part of this pure contract).

## Entity: ReviewArtifactClass — iteration 003 (T019)

**Purpose**: the lifecycle class of every review artifact family, so retention (machine-local vs durable vs
pruned/archived) is decidable. Base class is path-static; disposition is digest-driven; the archive-vs-prune
window is a T019-owned policy knob (step 6). Carried here with DRIFT-198-I003-002 (maintainer 2026-07-13).

### Attributes

| Attribute | Type | Validation Rules | Description |
| --- | --- | --- | --- |
| base_class | enum | `transient` \| `durable` \| `unknown` | from the on-disk family; `unknown` is a contract gap, never silently durable |
| git_tracked | bool | matches shipped `.gitignore` | inline/test-evidence/signoff-gate tracked; pending/runtime/.review ephemeral |
| disposition | enum | `transient`→`transient`\|`prunable`; `durable`→`durable`\|`superseded`\|`archived`\|`prunable` | a transient record is prunable ONLY after its owning run is terminal/reaped/abandoned (never while running); obsolete durable records await an archive/prune policy decision |

Lifecycle: a durable record whose digest is no longer the latest for its lineage becomes `superseded`, then
`archived` (forensic value) or `prunable` (past retention). No shipped code prunes durable records today
(the accumulation gap); the retention runtime is T019 step 6.
