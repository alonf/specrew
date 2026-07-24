# Contract: 0.40.0-beta2 Hardening Bundle Public Surface

**Feature**: 198-beta2-hardening
**Stability**: pre-1.0 (additive evolution per the I3 asymmetric package)

## SelfLeakDenyList (shipped data file) — iteration 001

Versioned JSON read by the repo lint lane and (iteration 004) the
consumer-side checks.

### Exported surface

| Symbol | Signature | Purpose | Errors |
| --- | --- | --- | --- |
| `self-leak-deny-list.json` | `{ schema_version, entries: DenyListEntry[] }` | single truth for what counts as a self-leak | repo-side: version-locked; consumer-side mismatch: fail-open WARN |

### Invariants

- The lint scans EXACTLY the deploy allowlist surface — scanned == shipped
  by construction (surface derived from the manifest source).
- A deny-listed term without an adjacent `specrew-self-ok: <reason>`
  annotation is a red build; an annotation without reason text is
  unannotated.
- Adding a field-found leak is a one-entry change; both prevention and
  detection read the same file, so they cannot disagree.

## Self-leak lint (script CLI) — iteration 001

| Symbol | Signature | Purpose | Errors |
| --- | --- | --- | --- |
| `lint-self-leak.ps1` | `-ProjectRoot <path> [-DenyListPath <path>]` → exit 0 clean / exit 1 findings | author-time firewall lane | exit 2 on unreadable deny-list (repo lane fails loud, never silently green) |

Red output names: file, matched term, class, the annotation escape syntax,
and the parameterization-rule doc. Exit codes are contract; CI keys off
them.

## ReviewerHostCatalog column — iteration 002

| Symbol | Signature | Purpose | Errors |
| --- | --- | --- | --- |
| `default_timeout_seconds` | int per host row | per-host review budget default | absent → 600 floor (tolerant reader; never throws) |

Resolution order (contract): explicit flag → project config
(`co_review_timeout_seconds`) → catalog per-host default → 600 floor.
Explicit lower value stays accepted (explicit-beats-config) and draws the
W14 warning at resolution time, keyed off the RESOLVED value.

## Boundary authorization primitive — iteration 002

| Symbol | Signature | Purpose | Errors |
| --- | --- | --- | --- |
| `Test-SpecrewBoundaryAuthorization` | `(position, cursor) → delta result` | THE shared skipped-boundary check for sync / validator / resume / hard gates | pure check; never mutates |
| sync ratchet refusal | exit + message naming skipped boundary + both doors | makes a second unapproved advance impossible | refusal is loud; no cursor/state advances |

### Invariants

- One approval advances at most one boundary; retroactive approvals are
  recorded distinctly; reversion targets the recorded AuthCommitHash and
  runs only after explicit human confirmation.
- No enforcement behavior depends on a host hook firing.

## Tracker honesty bypass (gate-level) — iteration 002

| Symbol | Signature | Purpose | Errors |
| --- | --- | --- | --- |
| honesty check | `(tracker delta, accepted review + runs) → grant \| decline` | earn the evidence bypass for reconcile-toward-truth tracker edits | parse ambiguity → decline (fail-closed = stale as today) |

### Invariants

- The digest identity formula is UNCHANGED (mechanism b); the bypass is a
  gate decision and is ANNOUNCED in gate output.
- Claims comparison is subset-only; claims-increasing edits always stale.
- Scope: `specs/*/iterations/*/state.md` + `tasks-progress.yml` only.

## Release-model resolver — iteration 004

| Symbol | Signature | Purpose | Errors |
| --- | --- | --- | --- |
| resolver | `(repository-governance.yml \| inference) → local-only \| push-only \| pr-flow \| beta-stable` | closeout teaching renders ONLY applicable steps | no governance file + no repo signals → local-only (never invents a forge) |

## Toolchain pin surface — iteration 001

| Symbol | Signature | Purpose | Errors |
| --- | --- | --- | --- |
| `SPEC_KIT_VERSION` / `SQUAD_VERSION` (CI env), version-check supported-versions, extension.yml `requires`/`min_speckit` (+ `.specify` mirror), `Get-SpecKitGitReference`, dependency-install minimum, validate-versions defaults | all agree on 0.12.9 / 0.11.0 | single tested pin (I2) | version-check WARNs non-pinned with the exact update instruction |

`specify init` invocation contract after migration:
`--integration <key> --script ps --ignore-agent-tools` (key confirmed by
the recorded probe; opt-in extensions added only with recorded dependency
evidence).

## Controlled external review contract — iterations 006/007

### Public authority selection

| Symbol | Signature | Purpose | Errors |
| --- | --- | --- | --- |
| review authority mode | `{ schema_version: "1.0", mode: "legacy / disabled / campaign" }` | select exactly one promotion path | missing/malformed/unknown/unsupported → neither path enabled |
| `specrew review` campaign delegation | existing public CLI surface → one synchronous `ReviewCampaign` / `ReviewRun` operation | preserve user surface while replacing authority internals | no fallback from campaign failure to legacy promotion |

Cutover order is `legacy -> disabled -> campaign`. Legacy artifacts remain readable historical evidence but are
never imported into campaign authority. Repository code is mutated only by the repository owner/implementer;
reviewers operate on an external frozen target and write only run-owned candidate data.

### Versioned process/file exchange

| Contract | Required fields | Authority |
| --- | --- | --- |
| `ReviewInvocation` | `schema_version`, `campaign_id`, `run_id`, `target_digest`, `snapshot_path`, `review_scope`, `prompt_path`, `candidate_result_path`, `candidate_report_path`, `deadline` | controller-authored immutable request |
| `ReviewerCandidate` | `schema_version`, `run_id`, `target_digest`, `completion`, `verdict`, `summary`, `findings[]` | untrusted staged input only |
| `ReviewResult` | campaign/run/digest/harness identity; completion/verdict/runtime; termination/containment/currentness/validation; approval flag; bounded failure/summary/findings; timestamps/duration | sole controller-published terminal authority |

All five harness adapters implement the same exchange. The candidate file contains only one raw JSON object—no
prose, fences, or trailing material. Stdout/stderr are telemetry and are never parsed, salvaged, or extracted into
authority. Candidate limits are closed and bounded: unknown fields, wrong identity, malformed/wrapped JSON,
oversize payloads, illegal state combinations, or unsupported versions fail closed.

### Runtime and timeout

| Platform | Production mechanism | Terminal invariant |
| --- | --- | --- |
| Windows | Job Object | all descendants assigned/terminated; death and streams verified |
| Linux | cgroup | membership bounded to the run; complete cgroup killed and verified |
| macOS | process group | isolated group signaled/killed and verified |

A timeout result is published only after descendant death and stream closure are verified. Valid partial findings
may be retained with the timeout/failure reason, but are advisory and require a complete separately authorized
run before approval. Every invoked run publishes exactly one terminal result or a loud reconciliation state;
pre-invocation failures release rather than spend their slot.

### Progress, cost, and reruns

Progress/heartbeat and safe usage metrics are informational projections, never result authority. Finding counts
are shown only from complete valid checkpoints. Every actual provider invocation consumes one visible allowance
slot and uses a unique run ID. No adapter retries invisibly; findings, invalid output, timeout, or infrastructure
failure return control for a new human grant.

### Support claim

Beta2 may claim production code review only after deterministic conformance for all five adapters on Windows,
Linux, and macOS plus one paid live smoke per harness distributed across all three operating systems. An
unavailable harness/OS combination remains unproven. Generic gate/artifact adapters remain Beta3 scope.
