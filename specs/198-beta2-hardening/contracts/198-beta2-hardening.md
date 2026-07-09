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
