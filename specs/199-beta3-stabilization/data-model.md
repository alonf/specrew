# Data Model: Beta3 Stabilization

**Feature**: 199-beta3-stabilization
**Date**: 2026-08-10
**Purpose**: Define the entities this slice adds or touches. All persisted state lives
in the existing JSON review authority store as immutable facts; no database, no cache.

## Entity: PendingPauseFact (NEW — Option B)

**Purpose**: The recorded state "a round completed on the current tree, the decision
surface was rendered, the human has not yet answered." Read by the renderer (verbatim
re-render on resume) and by the stop governor (the sanctioned quiet state).

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| schema_version | string | yes | known version | additive evolution marker |
| campaign_id | string | yes | `cmp-<slug>-i<iter>` shape | owning campaign |
| run_id | string | yes | existing run | the round that produced the pause |
| tree_state | string | yes | 40-hex | the reviewed tree identity at pause time |
| findings_summary | object | yes | severity buckets with counts + locations | renders the surface |
| cost | object | yes | rounds int >=1, minutes number >=0 | cumulative campaign cost |
| budget | object | yes | used <= total; total default 4 | budget position |
| recommendation | string | yes | non-empty | severity-derived one-liner |
| created_at | string | yes | ISO-8601 UTC | pause creation time |

### Lifecycle / Relationships

Created atomically (FileMode.CreateNew) by the orchestrator's round terminal; never
mutated. Answered by exactly one PauseDecisionFact (human-reply-only, no expiry — the
clarified default). An unanswered PendingPauseFact coexisting with a running round is
an impossible state (object-invariant guard).

## Entity: PauseDecisionFact (NEW)

**Purpose**: The human's numbered answer to a pause — the only continuation authority.

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| schema_version | string | yes | known version | evolution marker |
| campaign_id / run_id | string | yes | matches the pause | binding |
| choice | string | yes | `fix-and-continue \| stop-here \| abandon` | the human's pick |
| decided_at | string | yes | ISO-8601 UTC | decision time |

### Lifecycle / Relationships

Written once when the human replies; `fix-and-continue` authorizes exactly ONE further
round (single-run grant); `stop-here` triggers the composed landing; `abandon` closes
the campaign as abandoned with findings persisted.

## Entity: RoundAllowance (EXISTING — semantics sharpened)

Per-CAMPAIGN spend state (clarified 2026-08-10): default total 4; decremented only by
reviewer-invoked rounds (`invoked-reviewed` / `invoked-failed`); `preflight-failed`,
`claim-contended`, `launch-failed` publish run records but never decrement; reset only
by the explicit human allowance-reset action.

## Entity: SignoffGateDecision (EXISTING — read-only consumer added)

`.specrew/review/signoff-gate/latest.json` + history. Unchanged writer; the stale
classifier becomes a reader and MUST NOT contradict a recorded decision.

## Entity: VerificationPlan (EXISTING — scaffolded by init)

`.specrew/verification-plan.json`: governance validator + dotnet/npm build-test
templates; `env_refs` names-only allowlist defaulting to PATH, PATHEXT, SYSTEMROOT,
COMSPEC, TEMP, TMP, TMPDIR, HOME, USERPROFILE, APPDATA, LOCALAPPDATA, PROGRAMFILES,
PROGRAMFILES(X86), PROGRAMDATA.

## Entity: ReviewerHostRow (EXISTING — one value change)

Catalog row `codex`: `default_timeout_seconds` 600 -> 900. All other rows untouched.

## No other persisted data

The gloss helper, banned-token check, banner composition, and message shapes are
pure rendering; capture writes to the existing verdict-history store unchanged in
schema.

## Iteration 002 additions

## Entity: PendingCrossing (EXISTING - two fields added)

- `owner`: `host|session` identity string or `unknown`; written at mint; read by the conformance
  provider's boundary demand.
- `marker`: the exact marker text the packet must emit, `<from> -> <to> @ <crossing-id>`; the
  capture verifies the identity segment.

## Entity: CrossingMirror (NEW, derived)

- The set of on-disk mirrors of `last_authorized_boundary` for the active iteration: `state.md`
  Current Phase, `state.md` Iteration Status, `plan.md` Status. Written by the authorization
  writer; re-mirrored by the sync; compared by the truth gate. Allowed lead: exactly the pending
  crossing. Never written ahead of the store by anything but the pending crossing's own arrival.

## Entity: LensCheckpoint (NEW, transition)

- Inputs: a phase-`lens` receipt (`workshop-authority.jsonl`), `workshop/<lens>.md`, the lens's
  validator result. Output: the `lens-applicability.json` entry (`moved_on`, `confirmation`,
  `confirmation_scope`). Operation `confirm-lens` in the workshop transition table.

## Entity: GatePreflightCheck (EXISTING - one split)

- `pushed-head` (delivery; closeouts) and `verdict-commit-durable` (durability; every boundary) are
  two named checks with disjoint jobs; neither carries the other's message.

## Entity: IterationSeal (EXISTING - ordering fixed)

- Written last at iteration-closeout, after the dashboard render; hashes the rendered dashboard.
